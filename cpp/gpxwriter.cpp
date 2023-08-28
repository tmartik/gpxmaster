#include "gpxwriter.h"
#include "qdebug.h"

#include <QXmlStreamWriter>


GpxWriter::GpxWriter(QObject *parent) :
    QObject(parent)
{
}

QString GpxWriter::write(const QVariantMap json)
{
    QString result;
    QXmlStreamWriter stream(&result);
    stream.setAutoFormatting(true);

    stream.writeStartDocument();
    stream.writeStartElement("gpx");


    QVariantList tracks = json["tracks"].toList();
    foreach(QVariant track, tracks) {
        stream.writeStartElement("trk");

        QVariantMap t = track.toMap();
        QString trackName = t["name"].toString();
        stream.writeTextElement("name", trackName);

        QVariantList segments = t["segments"].toList();

        foreach(QVariant segmentVariant, segments) {
            stream.writeStartElement("trkseg");

            QVariantList segment = segmentVariant.toList();

            foreach(QVariant c, segment) {
                stream.writeStartElement("trkpt");

                QVariantMap coordinate = c.toMap();
                QString lat = coordinate["lat"].toString();
                QString lon = coordinate["lon"].toString();

                stream.writeAttribute("lat", lat);
                stream.writeAttribute("lon", lon);

                stream.writeEndElement();       // trkpt
            }

            stream.writeEndElement();       // trkseg
        }

        stream.writeEndElement();       // trk
    }

    // Waypoints
    QVariantList waypoints = json["waypoints"].toList();
    foreach(QVariant c, waypoints) {
        stream.writeStartElement("wpt");

        QVariantMap coordinate = c.toMap();
        QString lat = coordinate["lat"].toString();
        QString lon = coordinate["lon"].toString();
        QString name = coordinate["name"].toString();
        QString cmt = coordinate["cmt"].toString();

        stream.writeAttribute("lat", lat);
        stream.writeAttribute("lon", lon);

        stream.writeTextElement("name", name);
        stream.writeTextElement("cmt", cmt);

        stream.writeEndElement();       // wpt
    }

    stream.writeEndElement();       // gpx
    stream.writeEndDocument();

    return result;
}
