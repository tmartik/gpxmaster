#ifndef GPXPARSER_H
#define GPXPARSER_H

#include "fileparserbase.h"

#include <QXmlStreamReader>
#include <QJsonObject>

/*
 * This class reads in a GPX-formatted string and returns the contents as a stringified JSON object.
 */
class GpxParser : public FileParserBase
{
    Q_OBJECT
public:
    explicit GpxParser(const QString& input, QObject *parent = nullptr);

    void parse();
    QString json() const;

private:
    enum Mode {
        ParsingRoot,
        ParsingTrk,
        ParsingTrkSeg,
        ParsingTrkPt,
        ParsingWpt
    };
    QXmlStreamReader mXml;
    int mMode;

    QJsonObject mJson;
};

#endif // GPXPARSER_H
