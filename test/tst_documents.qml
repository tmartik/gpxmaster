import QtQuick 2.3
import QtTest 1.0

import "../qml"

TestCase {
    name: "Documents"

    property string testFile1: "file:///D:/Projects/qt/GPXMaster/git/test/test.gpx"     // TODO: fix absolute paths !
    property string testFile2: "file:///D:/Projects/qt/GPXMaster/git/test/test2.gpx"

    function test_createMainViewModel() {
        initModel()

        verify(model, "Model creation")
        verify(spy.valid, "Model signal connected")
    }

    function test_createDocument() {
        var testDocument = getTestDocument()

        initModel()

        compare(model.documents.length, 0, "The model does not have any documents by default")

        model.createDocument()

        spy.wait(500)

        compare(spy.count, 1, "createDocument() emitted a signal")
        compare(model.documents.length, 1, "createDocument() adds exactly one new document")
        compare(JSON.stringify(model.documents[0]), JSON.stringify(testDocument), "createDocument() adds a new document")
    }

    function test_openDocument() {
        initModel()

        model.openDocument(testFile1)

        spy.wait(5000)

        compare(spy.count, 1, "openDocument() emitted a signal")
        verify(model.documents.length === 1, "openDocument() opens exactly one document")
        verify(model.documents[0].tracks[0].name === "Test Track", "openDocument() opens a track")
        verify(model.documents[0].tracks[0].segments.length === 2, "openDocument() opens a track with segments")
        verify(model.documents[0].tracks[0].segments[0].length === 3, "openDocument() opens a segment with 3 coordinates")
        verify(model.documents[0].tracks[0].segments[1].length === 2, "openDocument() opens a segment with 2 coordinates")
        verify(model.documents[0].tracks[0].segments[0][0].lat > 0 && model.documents[0].tracks[0].segments[0][0].lon > 0, "openDocument() opens a segment with valid coordinate objects")
        verify(!isNaN(parseFloat(model.documents[0].tracks[0].segments[0][0].lat)) && !isNaN(model.documents[0].tracks[0].segments[0][0].lon), "openDocument() opens a segment with valid coordinates")

        verify(model.documents[0].waypoints.length === 1, "openDocument() opens waypoints")
        verify(model.documents[0].waypoints[0].lat > "", "openDocument() opens waypoints with valid lat field")
        verify(model.documents[0].waypoints[0].lon > "", "openDocument() opens waypoints with valid lon field")
        verify(model.documents[0].waypoints[0].name > "", "openDocument() opens waypoints with valid name field")
    }

    function test_removeDocument() {
        initModel()

        model.openDocument(testFile1)
        spy.wait(5000)
        compare(spy.count, 1, "removeDocument() emitted a signal")

        verify(model.documents.length === 1, "openDocument() opens exactly one document")

        model.openDocument(testFile1)
        verify(model.documents.length === 1,  "removeDocument() did not open the same document twice")

        model.openDocument(testFile2)
        spy.wait(5000)

        compare(spy.count, 2, "openDocument() emitted a signal")
        verify(model.documents.length === 2, "openDocument() can open multiple documents")

        model.removeDocument(0)

        spy.wait(5000)
        compare(spy.count, 3, "removeDocument() emitted a signal")

        verify(model.documents.length === 1, "openDocument() closes exactly one document")
    }

    function test_createNewTrack() {
        initModel()

        model.createDocument()

        var d = model.documents[0]

        verify(d.tracks.length === 0, "createDocument() does not create any tracks")
        verify(d.waypoints.length === 0, "createDocument() does not create any waypoints")

        model.createNewTrack(d)

        spy.wait(5000)
        compare(spy.count, 2, "createNewTrack() emitted a signal")

        verify(d.tracks.length === 1, "createNewTrack() creates exactly one track")
        verify(d.waypoints.length === 0, "createNewTrack() does not create any waypoints")
    }

    function test_addSegment() {
        initModel()

        model.createDocument()
        var d = model.documents[0]
        model.createNewTrack(d)

        verify(d.tracks[0].segments.length === 0, "createNewTrack() does not create any segments")

        model.addSegment(0, 0)

        spy.wait(5000)
        compare(spy.count, 3, "addSegment() emitted a signal")

        verify(d.tracks[0].segments.length === 1, "addSegment() creates exactly one segment")
        verify(d.tracks[0].segments[0].length === 0, "addSegment() creates a segment of zero points")
    }

    function test_insertPoint() {
        initModel()

        model.createDocument()
        var d = model.documents[0]
        model.createNewTrack(d)
        model.addSegment(0, 0)
        model.insertPoint(0, 0, 0, 25, 90)

        spy.wait(5000)
        compare(spy.count, 4, "insertPoint() emitted a signal")

        verify(d.tracks[0].segments[0].length === 1, "insertPoint() adds exactly one coordinate")
    }

    function test_removePoint() {
        initModel()

        model.createDocument()
        var d = model.documents[0]
        model.createNewTrack(d)
        model.addSegment(0, 0)
        model.insertPoint(0, 0, 0, 25, 90)
        model.insertPoint(0, 0, 0, 26, 91)
        model.removePoint(0, 0, 0, 0)

        spy.wait(5000)
        compare(spy.count, 6, "removePoint() emitted a signal")

        verify(d.tracks[0].segments[0].length === 1, "removePoint() remomes exactly one coordinate")
    }

    function test_renameTrack() {
        // TODO:
    }

    function initModel() {
        spy.clear()
        model = createTemporaryObject(testMainViewModel)
    }

    function getTestDocument() {
        var testDocument = {
            file: {
                fullpath: "",
                name: "New file",
                type: "gpx"
            },
            tracks: [],
            waypoints: []
        }

        return testDocument
    }

    property var model

    SignalSpy {
        id: spy
        target: model
        signalName: "documentsChanged"
    }

    Component {
        id: testMainViewModel
        MainViewModel {}
    }
}
