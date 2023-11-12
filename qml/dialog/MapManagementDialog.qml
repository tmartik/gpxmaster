import QtQuick 2.15
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4

/*
 * Dialog for editing map providers.
 */
Dialog {
    id: dialog
    property var model: []
    property var selectedMapProvider

    signal save(var index, var mapProvider)
    signal remove(var index)

    visible: false
    title: qsTr("Map Management")
    standardButtons: Dialog.Close

    RowLayout {
        anchors.fill: parent

        // Map providers list
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            width: 200
            highlight: highlightComponent
            model: dialog.model.length
            delegate: Item {
                property var mapProvider: dialog.model[modelData]
                width: listView.width
                height: 24
                Text {
                    anchors.fill: parent
                    text: mapProvider.name
                    verticalAlignment: Qt.AlignVCenter
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: listView.currentIndex = index
                }
            }
            onCurrentIndexChanged: selectedMapProvider = JSON.parse(JSON.stringify(dialog.model[currentIndex]))
        }

        // Map provider settings
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            MapProviderView {
                id: mapProviderView
                mapProvider: selectedMapProvider
            }
            RowLayout {
                Button {
                    text: qsTr("Delete")
                    onClicked: remove(listView.currentIndex)
                }
                Button {
                    text: qsTr("Revert")
                    onClicked: selectedMapProvider = JSON.parse(JSON.stringify(dialog.model[currentIndex]))
                }
                Button {
                    text: qsTr("Save")
                    onClicked: save(listView.currentIndex, mapProviderView.mapProvider)
                }
            }
        }
    }

    Component {
        id: highlightComponent
        Rectangle {
            width: 180; height: 40
            color: "lightsteelblue"; radius: 5
            y: listView.currentItem.y
            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }
}
