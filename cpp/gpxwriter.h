#ifndef GPXWRITER_H
#define GPXWRITER_H

#include <QObject>
#include <QVariantMap>


/*
 * This class converts the given JSON object to a GPX-formatted string.
 *
 */
class GpxWriter : public QObject
{
    Q_OBJECT
public:
    explicit GpxWriter(QObject *parent = nullptr);

public slots:
    QString write(const QVariantMap json);
};

#endif // GPXWRITER_H
