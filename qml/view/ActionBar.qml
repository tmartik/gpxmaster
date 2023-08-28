import QtQuick 2.15
import QtQuick.Layouts 1.15


GridLayout {
    property bool vertical: false
    property var actions: []
    property int selectedAction: -1
    property int size: 32
    property int widthFactor: 0

    columns: vertical ? 1 : actions.length
    rows: vertical ? actions.length : 1

    rowSpacing: 1
    columnSpacing: 1

    Repeater {
        model: actions

        Rectangle {
            width: widthFactor > 0 ? widthFactor * size : size
            height: size
            color: mouseArea.containsMouse ? mouseArea.containsPress ? 'gray' : 'gainsboro' : index === selectedAction ? 'lightblue' : 'lightslategray'
            enabled: index !== selectedAction
            border.width: 1
            border.color: 'black'
            Text {
                anchors.fill: parent
                text: modelData.title
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    selectedAction = index
                    actions[index].action()
                }
            }
        }
    }
}
