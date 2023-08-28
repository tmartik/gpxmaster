import QtQuick 2.15
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4

/*
 * Dialog for editing map providers.
 */
Dialog {
    property alias model: listView.model

    visible: false
    title: qsTr("Map Management")
    standardButtons: /*StandardButton.Save |*/ StandardButton.Cancel

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
            delegate: Item {
                width: listView.width
                height: 24
                Text {
                    anchors.fill: parent
                    text: modelData.name
                    verticalAlignment: Qt.AlignVCenter
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: listView.currentIndex = index
                }
            }


        }

        // Map provider settings
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Text {
                text: qsTr("Service name:")
            }
            TextField {
                Layout.fillWidth: true
                text: model[listView.currentIndex].name
                //onTextChanged: mapName = text
            }
            Text {
                text: qsTr("Tile Map Service URL (e.g. http://localhost/%Z/%X/%Y):")
            }
            TextField  {
                Layout.fillWidth: true
                text: model[listView.currentIndex].url
                //onTextChanged: mapUrl = text
            }
            Text {
                text: qsTr("Relative cache folder name:")
            }
            TextField  {
                Layout.fillWidth: true
                text: model[listView.currentIndex].cacheName
                //onTextChanged: cacheName = text
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
