import QtQuick 2.0
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/*
	This element defines a treeview child's visual appearance.
*/
Item {
    id: delegateRoot

    property alias text: text.text
    property bool selected: false
    property int margins: 0

    signal clicked(var event)

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? mouseArea.containsPress ? 'lightgray' : 'gainsboro' : 'white'
    }
    Rectangle {
        anchors.fill: text
        anchors.margins: -4  // TODO: fix!
        radius: height
        visible: selected
        color: 'lightblue'
    }
    Text {
        id: text
        anchors.fill: parent
        anchors.margins: margins
        verticalAlignment: Qt.AlignVCenter
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: delegateRoot.clicked(mouse)
    }
}
