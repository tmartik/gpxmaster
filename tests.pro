QT += core quick widgets location network
CONFIG += qmltestcase

SOURCES += \
    test/test.cpp \
    cpp/gpxparser.cpp \
    cpp/kmlparser.cpp \
    cpp/gpxwriter.cpp \
    cpp/httpserver.cpp \
    cpp/utility.cpp \
    cpp/clipboard.cpp

HEADERS += \
    cpp/gpxparser.h \
    cpp/kmlparser.h \
    cpp/gpxwriter.h \
    cpp/httpserver.h \
    cpp/utility.h \
    cpp/clipboard.h

INCLUDEPATH=cpp
