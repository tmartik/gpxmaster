import QtQuick 2.15
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4

Dialog {
    property string name
    property string cmt
    property bool editable: false

    visible: false
    title: qsTr("Edit waypoint")
    standardButtons: editable ? StandardButton.Save | StandardButton.Cancel : StandardButton.Close

    width: 480

    ColumnLayout {
        anchors.fill: parent
        Text {
            text: qsTr("Name:")
        }
        TextField  {
            Layout.fillWidth: true
            readOnly: !editable
            text: dialogData.wpt.name
            onTextChanged: name = text
        }
        Text {
            text: qsTr("Comment:")
        }
        TextArea {
            id: textArea
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            readOnly: !editable
            text: dialogData.wpt.cmt
            onTextChanged: cmt = text

            DropArea {
                anchors.fill: parent
                onDropped: {
                    if(drop.hasUrls) {
                        for(var u of drop.urls) {
                            textArea.append(u)
                        }
                    } else if(drop.hasText) {
                        textArea.append(drop.text)
                    }
                }
            }
        }
    }
}
