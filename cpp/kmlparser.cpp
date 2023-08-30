#include "kmlparser.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QList>


KmlParser::KmlParser(const QString& input, QObject *parent)
    : QObject{parent}, mXml(input)
{
    QJsonArray trksJson;
    mJson.insert("tracks", trksJson);
}

void KmlParser::parse()
{
    // SEE: https://www.walletfox.com/course/qxmlstreamreaderexample.php

    QList<QJsonObject> trkSeg;          // A segment: Contains multiple points
    QList<QJsonArray> trk;              // A track: Contains multiple segmets
    QString trkName;

    while(!mXml.atEnd()) {
        mXml.readNext();
        auto name = mXml.name();

        if(mXml.isStartElement() && mXml.name() == "Document") {
            // Document
            mMode = ParsingDocument;
        }
        if(mXml.isStartElement() && mXml.name() == "Folder") {
            // Folder started
            qDebug() << "FOLDER START";
            mMode = ParsingFolder;
        }
        if(mXml.isStartElement() && mXml.name() == "Placemark") {
            // Placemark started
            qDebug() << "Placemark START";
            mMode = ParsingPlacemark;
            parsePlacemark();
        }
        if(mXml.isEndElement()) {
            if(mXml.name() == "Point") {
                mMode = ParsingPlacemark;
            }
            if(mXml.name() == "Folder") {
                mMode = ParsingFolder;
            }
        }

    }
    if(mXml.hasError()) {
        // TODO: error handling
    }
}

void KmlParser::parsePlacemark() {
    QJsonObject wptJson;

    while(!(mXml.isEndElement() && mXml.name() == "Placemark")) {
        mXml.readNext();

        if(mMode == ParsingPlacemark && mXml.isStartElement()) {
            if(mXml.name() == "name") {
                // Waypoint name
                QString wptName = mXml.readElementText();
                qDebug() << "WPT NAME:" << wptName;

                wptJson.insert("name", wptName);
            }
        }
        if(mMode == ParsingPlacemark && mXml.isStartElement()) {
            if(mXml.name() == "description") {
                // Waypoint name
                QString wptDescription = mXml.readElementText();
                qDebug() << "DESCRIPTION:" << wptDescription;

                wptJson.insert("cmt", wptDescription);
            }
        }
        if(mMode == ParsingPlacemark && mXml.isStartElement()) {
            if(mXml.name() == "coordinates") {
                // Waypoint coordinates
                QString coordinateString = mXml.readElementText();
                coordinateString = coordinateString.trimmed();
                qDebug() << "coodrinateString:" << coordinateString;

                QStringList coordinateParts = coordinateString.split(',');

                double lon = coordinateParts[0].toDouble();
                double lat = coordinateParts[1].toDouble();
                // TODO: alt!

                wptJson.insert("lat", lat);
                wptJson.insert("lon", lon);
            }
        }
    }


    QJsonArray wptsJson = mJson.value("waypoints").toArray();
    wptsJson.append(wptJson);
    mJson.insert("waypoints", wptsJson);
}

QString KmlParser::json() const
{
    QJsonDocument jsonDoc;
    jsonDoc.setObject(mJson);
    return jsonDoc.toJson();
}
