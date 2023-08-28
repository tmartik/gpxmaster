#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "gpxwriter.h"
#include "httpserver.h"
#include "utility.h"
#include "clipboard.h"


int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;

    Utility* utility = new Utility(&app);
    engine.rootContext()->setContextProperty("Utility", utility);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    HttpServer* httpServer = new HttpServer(&app);
    engine.rootContext()->setContextProperty("HttpServer", httpServer);

    httpServer->listen(QHostAddress::Any, 5555);

    qDebug() << "Server listening at port" << httpServer->serverPort();

    // GPX writer
    GpxWriter* gpxWriter = new GpxWriter(&app);
    engine.rootContext()->setContextProperty("GpxWriter", gpxWriter);

    // Clipboard
    Clipboard* clipboard = new Clipboard(&app);
    engine.rootContext()->setContextProperty("Clipboard", clipboard);


    return app.exec();
}
