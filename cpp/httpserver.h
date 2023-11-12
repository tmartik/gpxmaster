#ifndef HTTPSERVER_H
#define HTTPSERVER_H

#include <QFile>
#include <QNetworkAccessManager>
#include <QTcpServer>

/**
 * @brief This class works as a caching HTTP proxy server between QML's Map view and your map server.
 * @param parent
 */
class HttpServer : public QTcpServer
{
    Q_OBJECT;
public:
    HttpServer(QObject* parent = nullptr);

public slots:   // exposed to QML
    int getPortNumber();
    void setCacheFolder(QString cacheFolder);
    void setURL(QString url, QString cacheFolder, QString referer);
    void setZoomLevels(int minZoom, int maxZoom);
    void setFlightMode(bool enabled);

signals:
    void cancel();

private slots:
    void readClient();
    void discardClient();

    void httpReadyRead();
    void httpFinished();


protected:
    void incomingConnection(int socket);

    void saveToFile(QString filename, const QByteArray* bytes);
    void sendFile(QTcpSocket* socket, const QByteArray* bytes);
    void closeSocket(QTcpSocket* socket);
    void closeReply(QNetworkReply* reply);

    void replyStatusCode(QTcpSocket* socket, int statusCode);

private:
    void setMapName(QString name);
    QString mapLayer();

private:
    bool mFlightMode = false;
    QString mURL;
    QString mMapName;
    QString mUserAgent;
    QString mReferer;
    int mZoomMax;
    int mZoomMin;

    QString mCachePath;

    QNetworkAccessManager mNam;
    QHash<QNetworkReply*, QByteArray*> files;
    QHash<QNetworkReply*, QTcpSocket*> sockets;
};

#endif // HTTPSERVER_H
