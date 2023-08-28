import QtQuick 2.15
import QtQuick.Dialogs 1.3

Dialog {
    property alias model: listView.model

    visible: false
    title: qsTr("Select a map")
    standardButtons: StandardButton.Ok | StandardButton.Cancel

    property int selectedIndex: (dialogData || {}).selectedIndex || -1

    ListView {
        id: listView
        anchors.fill: parent
        implicitHeight: 256
        clip: true
        delegate: Rectangle {
            width: listView.width
            height: 16
            color: selectedIndex === index ? 'blue' : index % 2 > 0 ? 'lightgray' : 'gray'
            Text {
                text: modelData.name
            }
            MouseArea {
                anchors.fill: parent
                onClicked: selectedIndex = index
            }
        }
    }

}
