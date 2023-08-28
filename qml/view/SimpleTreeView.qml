import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

/*
	This element implements a tree view with foldable children.
*/
ColumnLayout {
    id: treeView
    property int indent: 32
    property var model

    property var selection: []

    property string path
    property var expanded: ({})

    signal clicked(var event, var indices)

    Repeater {
        model: treeView.model ? treeView.model.nodes : 0
        delegate: ColumnLayout {
            Layout.fillWidth: true
            property string name: path + "/" + index
            property bool checked: expanded[name] === true
            RowLayout {
                spacing: 0
                Layout.fillWidth: true
                // Expand/collapse button
                Rectangle {
                    width: indent
                    height: width
                    radius: width
                    color: mouseArea.containsMouse ? mouseArea.containsPress ? 'lightgray' : 'gainsboro' : 'white'
                    Text {
                        anchors.centerIn: parent
                        visible: mouseArea.enabled
                        text: checked ? "-" : "+"
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: modelData.nodes > ""
                        onClicked: {
                            if(checked) {
                                collapse()
                            } else {
                                expand()
                            }
                        }
                    }
                }
                // Leaf
                TreeViewDelegate {
                    margins: 5
                    text: modelData.name
                    Layout.fillWidth: true
                    height: indent
                    selected: selectedPath === name
                    onClicked: treeView.clicked(event, [index])
                }
            }
            Loader {
                id: loader
                Layout.leftMargin: indent
            }
            Connections {
                target: treeView
                function onWidthChanged() {
                    if(loader.item) {
                        loader.item.width = treeView.width - indent
                    }
                }
            }

            function expand() {
                expanded[name] = true
                expandedChanged()
                loader.visible = true
                loader.setSource(
                    "SimpleTreeView.qml", {
                        width: treeView.width - indent,
                        model: modelData,
                        path: name, //+ '/' + index,
                        expanded: expanded,
                        selection: selection[0] === index ? selection.slice(1, selection.length) : []
                })
            }

            function collapse() {
                expanded[name] = false
                loader.source = ""
                loader.visible = false
                expandedChanged()
            }

            Connections {
                target: loader.item
                function onClicked(event, indices) {
                    indices.unshift(index)
                    treeView.clicked(event, indices)
                }
            }

            Component.onCompleted: {
                if(expanded[name]) {
                    expand()
                }
            }
        }
    }
}
