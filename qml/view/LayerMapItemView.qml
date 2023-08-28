import QtQuick 2.0
import QtLocation 5.15

MapItemView {
    property bool selected: false
    property int selectedIndex: -1
    property var style: ({})

    add: null
    remove: null

    delegate: MapPolyline {
        property int lineWidth: map.zoomLevel / 2
        line.width: selected ? 2 * lineWidth : lineWidth
        line.color: index === selectedIndex ? 'red' : 'blue'
        path: modelData.path
        opacity: map.zoomLevel > 12 ? 0.5 : 1
    }
}
