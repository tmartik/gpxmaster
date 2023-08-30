import QtQuick 2.0
import QtLocation 5.15
import QtPositioning 5.15

import QtQuick.Shapes 1.15

MapItemView {
    id: root

    property var style
    property real margin: style.margin

    signal clicked(var index, var data)

    add: null
    remove: null

    delegate: MapQuickItem {
        coordinate: QtPositioning.coordinate(modelData.lat, modelData.lon)
        anchorPoint.x: margin
        anchorPoint.y: sourceItem.height

        sourceItem: Item {
            width: itemText.width
            height: itemText.height + itemIcon.height

            // Text
            Rectangle {
                id: itemText
                property bool expanded: false
                width: expanded ? margin * 50 : waypointText.width + margin
                height: expanded ? margin * 50 : waypointText.height + margin
                radius: margin
                color: waypointMouseArea.containsPress ? 'gray' : waypointMouseArea.containsMouse ? 'lightgray' : 'white'
                border.color: 'black'
                border.width: 1
                Text {
                    id: waypointText
                    anchors.centerIn: parent.expanded ? undefined : parent
                    anchors.fill: parent.expanded ? parent : undefined
                    font.pixelSize: style.textPixelSize * style.mediumTextFactor
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.name
                }
                MouseArea {
                    id: waypointMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.clicked(index, modelData)
                }
            }

            // Arrow
            Shape {
                id: itemIcon
                anchors.top: itemText.bottom
                anchors.left: itemText.left
                anchors.leftMargin: margin
                width: 10
                height: 20

                ShapePath {
                    strokeColor: "black"
                    fillColor: "red"
                    // Must be drawn anti-clockwise
                    startX: 0; startY: 0
                    PathLine { x: itemIcon.width / 2; y: itemIcon.height}
                    PathLine { x: itemIcon.width; y: 0 }
                    PathLine { x: 0; y: 0 }
                }
            }
        }
    }
}
