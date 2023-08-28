#ifndef UTILITY_H
#define UTILITY_H

#include <QObject>

class Utility : public QObject
{
    Q_OBJECT

public:
    explicit  Utility(QObject *parent = nullptr);

public slots:
    void saveTextToFile(const QString& path, const QString& data);
    QString loadTextFromFile(const QString& path);
    QString parseGpx(const QString& data);
    QString parseKml(const QString& data);
    QString pwd();
};

#endif // UTILITY_H
