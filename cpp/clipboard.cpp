#include "clipboard.h"

#include <QGuiApplication>
#include <QMimeData>


Clipboard::Clipboard(QObject* parent) : QObject(parent)
{
    clipboard = QGuiApplication::clipboard();
}

void Clipboard::setText(QString text)
{
    QMimeData* mimeData = new QMimeData();
    mimeData->setData("application/json", text.toLocal8Bit());
    clipboard->setMimeData(mimeData);
}

QString Clipboard::getText()
{
    const QMimeData* mimeData = clipboard->mimeData();
    QByteArray data = mimeData->data("application/json");
    QString text = QString::fromLocal8Bit(data);
    return text;
}
