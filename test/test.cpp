#include <QtQuickTest>
#include <QQmlEngine>
#include <QQmlContext>

#include "utility.h"


class Setup : public QObject
{
    Q_OBJECT

public:
    Setup() {}

public slots:
    void qmlEngineAvailable(QQmlEngine *engine) {
        Utility* utility = new Utility(this);
        engine->rootContext()->setContextProperty("Utility", utility);
    }
};


QUICK_TEST_MAIN_WITH_SETUP(gpx-master, Setup)

#include "test.moc"
