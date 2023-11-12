import QtQuick 2.15
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4

Dialog {
    property string mapName
    property string mapUrl
    property string cacheName

    property string referer

    visible: false
    title: qsTr("Add a map server")
    standardButtons: StandardButton.Save | StandardButton.Cancel

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Text {
            text: qsTr("Service name:")
        }
        TextField  {
            Layout.fillWidth: true
            onTextChanged: mapName = text
        }
        Text {
            text: qsTr("Tile Map Service URL (e.g. http://localhost/%Z/%X/%Y):")
        }
        TextField  {
            Layout.fillWidth: true
            onTextChanged: mapUrl = text
        }
        Text {
            text: qsTr("Relative cache folder name:")
        }
        TextField  {
            Layout.fillWidth: true
            onTextChanged: cacheName = text
        }
        Text {
            text: qsTr("Referer Header:")
        }
        TextField  {
            Layout.fillWidth: true
            onTextChanged: referer = text
        }
    }
}
