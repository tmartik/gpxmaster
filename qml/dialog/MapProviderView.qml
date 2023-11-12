import QtQuick 2.0
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4

Item {
    property alias editable: layout.enabled
    property var mapProvider

    // Map provider fields
    property var fields: [
        {
            label: qsTr("Service name:"),
            prop: "name",
        },
        {
            label: qsTr("Tile Map Service URL (e.g. http://localhost/%Z/%X/%Y):"),
            prop: "url",
        },
        {
            label: qsTr("Relative cache folder name:"),
            prop: "cacheName",
        },
        {
            label: qsTr("Referer Header:"),
            prop: "referer",
        },        {
            label: qsTr("Zoom levels (e.g. 10-15):"),
            prop: "zoomLevels",
        },
    ]

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            model: fields
            delegate: ColumnLayout {
                Text {
                    text: modelData.label
                }
                TextField  {
                    id: nameEdit
                    Layout.fillWidth: true
                    text: (mapProvider || {})[modelData.prop] || ""
                    onTextChanged: mapProvider[modelData.prop] = text
                }
            }
        }
    }
}
