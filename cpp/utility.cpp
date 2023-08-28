#include "gpxparser.h"
#include "kmlparser.h"
#include "utility.h"

#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QUrl>


Utility::Utility(QObject *parent)
{

}

void Utility::saveTextToFile(const QString& path, const QString& data)
{
    QUrl url(path);
    QString localPath = url.toLocalFile();
    QFile file(localPath);


    bool re = file.open(QIODevice::WriteOnly /*| QIODevice::Text*/);

    if(re)
    {
        /*
        QTextStream out(&file);
        out << data;
        */

        QByteArray ar = data.toUtf8();
        file.write(ar);
        file.close();
    }
}

QString Utility::loadTextFromFile(const QString& path)
{
    /*
    {
        QUrl url(path);
        QString localPath = url.toLocalFile();
        QFile file(localPath);


        bool re = file.open(QIODevice::WriteOnly | QIODevice::Text);

        if(re)
        {
            QTextStream out(&file);
            out << data;
            file.close();
        }
*/
}

QString Utility::parseGpx(const QString& data)
{
    GpxParser parser(data);
    parser.parse();
    return parser.json();
}

QString Utility::parseKml(const QString& data)
{
    KmlParser parser(data);
    parser.parse();
    return parser.json();
}

QString Utility::pwd()
{
    return QDir::currentPath();
}
