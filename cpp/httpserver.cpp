#include "httpserver.h"

#include <QTcpSocket>
#include <QDateTime>
#include <QFile>

#include <QDataStream>
#include <QDir>
#include <QElapsedTimer>
#include <QNetworkReply>


HttpServer::HttpServer(QObject* parent) : QTcpServer(parent), mMapName("default"), mCachePath("")
{
}

void HttpServer::incomingConnection(int socket)
{
    // When a new client connects, the server constructs a QTcpSocket and all
    // communication with the client is done over this QTcpSocket. QTcpSocket
    // works asynchronously, this means that all the communication is done
    // in the two slots readClient() and discardClient().
    QTcpSocket* s = new QTcpSocket(this);
    connect(s, SIGNAL(readyRead()), this, SLOT(readClient()));
    connect(s, SIGNAL(disconnected()), this, SLOT(discardClient()));
    s->setSocketDescriptor(socket);
}

void HttpServer::readClient()
{
    // We received a request from the client
    QTcpSocket* socket = (QTcpSocket*) sender();
    if (socket->canReadLine()) {
        // Read in the first line of the HTTP request
        QStringList tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));
        if (tokens[0] == "GET") {
            // Extract the resource path
            QString path = tokens[1];

            // Extract the requested tile from the path
            const QStringList tile = path.split(QRegExp("/|\\.")).filter(QRegExp("^\\d+$"));
            if(tile.size() == 3) {
                const int z = tile[0].toInt();
                const int x = tile[1].toInt();
                const int y = tile[2].toInt();

                // Make sure the corresponding folder exists on the local filesystem
                const QString localTilePath = QString("%1/%2/%3/%4/%5").arg(mCachePath).arg(mMapName).arg(z).arg(x).arg(y);
                QFile tileFile(localTilePath);

                if(tileFile.exists() && tileFile.open(QIODevice::ReadOnly)) {
                    // Cached tile exists; load it from file and send it to the client
                    QElapsedTimer timer;
                    timer.start();

                    QByteArray bytes = tileFile.readAll();
                    qDebug() << "Loading took" << timer.elapsed() << "ms";

                    if(bytes.size() > 0) {
                        qDebug() << "FILE:" << localTilePath;
                        sendFile(socket, &bytes);
                    } else {
                        qDebug() << localTilePath << "FAILED!";
                    }
                } else if(!mFlightMode) {
                    // Online mode; request the tile from the server
                    QString baseurl(mURL);
                    baseurl = baseurl.replace("%Z", QString::number(z));
                    baseurl = baseurl.replace("%X", QString::number(x));
                    baseurl = baseurl.replace("%Y", QString::number(y));
                    QUrl url = QUrl(baseurl);

                    QNetworkRequest request(url);

                    if(mReferer.length() > 0) {
                        request.setRawHeader("Referer", mReferer.toLatin1());
                    }
                    request.setRawHeader("Host", url.host().toLatin1());
                    QObject* metadata = new QObject(this);  // 'this' will delete it eventually.
                    metadata->setProperty("localUrl", path);
                    request.setOriginatingObject(metadata);

                    qDebug() << "REQUEST" << request.url();

                    // Send the request to the server
                    QNetworkReply* reply = mNam.get(request);
                    connect(reply, &QNetworkReply::readyRead, this, &HttpServer::httpReadyRead);
                    connect(reply, &QNetworkReply::finished, this, &HttpServer::httpFinished);
                    connect(this, &HttpServer::cancel, reply, &QNetworkReply::abort);
                    files.insert(reply, new QByteArray());
                    sockets.insert(reply, socket);
                } else {
                    replyStatusCode(socket, 404);
                }
            } // TODO: drop client or return error.
        }
    }

    qDebug() << "sockets" << sockets.size();
}

void HttpServer::discardClient()
{
    QTcpSocket* socket = (QTcpSocket*)sender();
    closeSocket(socket);
}

int HttpServer::getPortNumber()
{
    return serverPort();
}

void HttpServer::setCacheFolder(QString cacheFolder)
{
    mCachePath = cacheFolder;
}

void HttpServer::setURL(QString url, QString name, QString referer)
{
    emit cancel();

    mURL = url;
    mMapName = name;
    mReferer = referer;
}

void HttpServer::setMapName(QString name)
{
    mMapName = name;
}

QString HttpServer::mapLayer()
{
    return mMapName;
}

void HttpServer::setFlightMode(bool enabled)
{
    mFlightMode = enabled;
}

void HttpServer::httpReadyRead()
{
    // We received reply from the server
    QNetworkReply* reply = (QNetworkReply*) sender();

    // Read the reply content and save it for later
    QByteArray content = reply->readAll();
    QByteArray* c = files.value(reply);
    c->append(content);
}

void HttpServer::httpFinished()
{
    // Server request finished; process the reply content
    QNetworkReply* reply = (QNetworkReply*) sender();

    const QByteArray* bytes = files.value(reply);
    if(sockets.contains(reply)) {
        QTcpSocket* socket = sockets.value(reply);

        QObject* metadata = reply->request().originatingObject();
        QUrl url(metadata->property("localUrl").toString());
        delete metadata;
        const QStringList tile = url.path().split(QRegExp("/|\\.")).filter(QRegExp("^\\d+$"));
        QVariant statusCode = reply->attribute( QNetworkRequest::HttpStatusCodeAttribute );
        if(tile.size() == 3 && statusCode.toInt() == 200) {
            // We received a tile; now save it to the cache folder
            const int z = tile[0].toInt();
            const int x = tile[1].toInt();
            const int y = tile[2].toInt();
            const QString localTilePath = QString("%1/%2/%3/%4/%5").arg(mCachePath).arg(mMapName).arg(z).arg(x).arg(y);

            // Create all necessary folders for the tile
            QDir dir(localTilePath);
            dir.setPath(QDir::cleanPath(dir.filePath(QStringLiteral(".."))));
            dir.mkpath(dir.absolutePath());

            saveToFile(localTilePath, bytes);

            if(socket->state() == QTcpSocket::ConnectedState) {
                // The client is still connected; send the received tile to the client
                sendFile(socket, bytes);
            } else {
                qDebug() << "SOCKET NOT OPEN!";
                closeSocket(socket);
            }
        } else {
            qDebug() << "Received unexpected data from the server!";
            closeSocket(socket);
        }

    } else {
        qDebug() << "SOCKET not found!";
    }
}

void HttpServer::saveToFile(QString filename, const QByteArray* bytes)
{
    QElapsedTimer timer;
    timer.start();

    qDebug() << "Saving to:" << filename;

    QFile file(filename);
    if(file.open(QIODevice::WriteOnly)) {
        file.write(*bytes);
    }

    qDebug() << "Saving took" << timer.elapsed() << "ms";
}

void HttpServer::sendFile(QTcpSocket* socket, const QByteArray* bytes)
{
    QTextStream tos(socket);
    tos.setAutoDetectUnicode(true);
    tos << "HTTP/1.0 200 OK\r\n"
        "Content-Type: image/png\r\n"
        "Content-Length: "
        << QString::number(bytes->length()) <<
        "\r\n"
        "\r\n";
    tos.flush();

    QDataStream os(socket);
    os.writeRawData(bytes->constData(), bytes->length());

    socket->close();
}

void HttpServer::replyStatusCode(QTcpSocket* socket, int statusCode)
{
    QTextStream tos(socket);
    tos.setAutoDetectUnicode(true);
    tos << "HTTP/1.0 "
        << statusCode <<
        " OK\r\n"
        "Content-Type: image/png\r\n"
        "Content-Length: 0"
        "\r\n"
        "\r\n";
    tos.flush();

    socket->close();
}

void HttpServer::closeSocket(QTcpSocket* socket)
{
    QHash<QNetworkReply*, QTcpSocket*>::const_iterator i = sockets.constBegin();
    while(i != sockets.constEnd()) {
        QTcpSocket* s = i.value();
        if(s == socket) {
            QNetworkReply* reply = i.key();
            sockets.remove(reply);
            closeReply(reply);
            break;
        }
        i++;
    }
    socket->deleteLater();
}

void HttpServer::closeReply(QNetworkReply* reply)
{
    QByteArray* file = files.value(reply);
    files.remove(reply);
    delete file;
    reply->abort();
    reply->deleteLater();

    QTcpSocket* s = sockets.value(reply);
    sockets.remove(reply);
    s->deleteLater();
}
