import QtQuick 2.15
import QtQuick.Controls 1.4

Menu {
    property var coordinate
    property bool documentSelected: false
    property bool segmentSelected: false

    signal addWaypoint()
    signal addTrackPoint(var lat, var lon)
    signal splitSegment()

    MenuItem {
        text: "Add waypoint"
        enabled: documentSelected
        onTriggered: addWaypoint()
    }
    MenuItem {
        text: "Add trackpoint"
        enabled: segmentSelected
        onTriggered: addTrackPoint(coordinate.latitude, coordinate.longitude)
    }

    function showMenu(c) {
        coordinate = c
        popup()
    }
}
