#ifndef KMLPARSER_H
#define KMLPARSER_H

#include <QXmlStreamReader>
#include <QJsonObject>

class KmlParser : public QObject
{
    Q_OBJECT
public:
    explicit KmlParser(const QString& input, QObject *parent = nullptr);

    void parse();
    QString json() const;

private:
    void parsePlacemark();

private:
    enum Mode {
        ParsingDocument,
        ParsingFolder,
        ParsingPlacemark,
    };
    QXmlStreamReader mXml;
    int mMode;

    QJsonObject mJson;
};

#endif // KMLPARSER_H
