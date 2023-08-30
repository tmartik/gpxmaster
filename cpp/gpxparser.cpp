#include "gpxparser.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QList>


GpxParser::GpxParser(const QString& input, QObject *parent)
    : FileParserBase(parent), mXml(input)
{
    QJsonArray trksJson;
    mJson.insert("tracks", trksJson);
}

void GpxParser::parse()
{
    // SEE: https://www.walletfox.com/course/qxmlstreamreaderexample.php

    QList<QJsonObject> trkSeg;          // A segment: Contains multiple points
    QList<QJsonArray> trk;              // A track: Contains multiple segmets
    QString trkName;

    while(!mXml.atEnd()) {
        mXml.readNext();

        if(mXml.isStartElement() && mXml.name() == "wpt") {
            // Waypoint
            mMode = ParsingWpt;

            QJsonObject wptJson;
            wptJson.insert("lat", mXml.attributes().value("lat").toString().toDouble());
            wptJson.insert("lon", mXml.attributes().value("lon").toString().toDouble());

            QJsonArray wptsJson = mJson.value("waypoints").toArray();
            wptsJson.append(wptJson);
            mJson.insert("waypoints", wptsJson);
        }
        if(mXml.isStartElement() && mXml.name() == "trk") {
            // Track started
            qDebug() << "TRACK START";
            mMode = ParsingTrk;
            trk.clear();
        }
        if(mXml.isStartElement() && mXml.name() == "trkseg") {
            // Track segment started
            qDebug() << "SEGMENT START";
            mMode = ParsingTrkSeg;
            trkSeg.clear();
        }
        if(mMode == ParsingWpt && mXml.isStartElement()) {
            if(mXml.name() == "name") {
                // Waypoint name
                QString wptName = mXml.readElementText();
                qDebug() << "WPT NAME:" << wptName;

                QJsonArray wptsJson = mJson.value("waypoints").toArray();
                QJsonObject wptJson = wptsJson.last().toObject();
                wptsJson.removeLast();

                wptJson.insert("name", wptName);
                wptsJson.append(wptJson);
                mJson.insert("waypoints", wptsJson);
            }
            if(mXml.name() == "cmt") {
                // Waypoint comment
                QString wptCmt = mXml.readElementText();
                qDebug() << "WPT CMT:" << wptCmt;

                QJsonArray wptsJson = mJson.value("waypoints").toArray();
                QJsonObject wptJson = wptsJson.last().toObject();
                wptsJson.removeLast();

                wptJson.insert("cmt", wptCmt);
                wptsJson.append(wptJson);
                mJson.insert("waypoints", wptsJson);
            }
        }
        if(mMode == ParsingTrk) {
            if(mXml.name() == "name") {
                trkName = mXml.readElementText();
                qDebug() << "TRACK NAME:" << trkName;
            }
        }
        if(mMode == ParsingTrkSeg) {
            if(mXml.isStartElement() && mXml.name() == "trkpt") {
                mMode = ParsingTrkPt;

                QJsonObject trkPtJson;
                trkPtJson.insert("lat", mXml.attributes().value("lat").toString().toDouble());
                trkPtJson.insert("lon", mXml.attributes().value("lon").toString().toDouble());
                trkSeg.append(trkPtJson);
            }
        }
        if(mXml.isEndElement()) {
            if(mXml.name() == "trk") {
                // Track ended
                QJsonObject trkJson;
                QJsonArray segmentsJson;
                foreach(QJsonArray trkSegJson, trk) {
                    segmentsJson.push_back(trkSegJson);
                }
                trkJson.insert("name", trkName);
                trkJson.insert("segments", segmentsJson);

                QJsonArray trksJson = mJson.value("tracks").toArray();
                trksJson.append(trkJson);
                mJson.insert("tracks", trksJson);
                mMode = ParsingRoot;
            }
            if(mXml.name() == "trkseg") {
                // Track segment ended
                QJsonArray trkSegJson;
                foreach(QJsonObject trkPtJson, trkSeg) {
                    trkSegJson.push_back(trkPtJson);
                }
                trk.append(trkSegJson);
                mMode = ParsingTrk;
            }
            if(mXml.name() == "trkpt") {
                // Track pt ended;
                mMode = ParsingTrkSeg;
            }
        }

    }
    if(mXml.hasError()) {
        // TODO: error handling
    }
}

QString GpxParser::json() const
{
    QJsonDocument jsonDoc;
    jsonDoc.setObject(mJson);
    return jsonDoc.toJson();
}
