#ifndef FILEPARSERBASE_H
#define FILEPARSERBASE_H

#include <QObject>


/*
 * Base class for file parsers.
 */
class FileParserBase : public QObject
{
public:
    explicit FileParserBase(QObject* parent = nullptr);

public:
    // Parse the file.
    virtual void parse() = 0;

    // Get the parse result as JSON string.
    virtual QString json() const = 0;
};

#endif // FILEPARSERBASE_H
