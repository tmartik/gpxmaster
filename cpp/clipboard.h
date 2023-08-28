#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <QClipboard>

class Clipboard : public QObject
{
    Q_OBJECT;
public:
    Clipboard(QObject* parent);

public slots:
    void setText(QString text);
    QString getText();

private:
    QClipboard* clipboard;
};

#endif // CLIPBOARD_H
