import QtQuick 2.15
import QtQuick.Controls 1.4

Rectangle {
    id: root
    property var model: []

    property int selectedIndex: selection.length > 0 ? selection[0] : -1      // This is selected root document // TODO: change to use selection-property
    property var selection: []

    signal fitToview(var documentIndex, var trackIndex, var segmentIndex)
    signal newTrack(var documentIndex)
    signal newSegment(var documentIndex, var trackIndex)
    signal renameTrack(var documentIndex, var trackIndex)
    signal moveToNewTrack(var documentIndex, var trackIndex, var segmentIndex)
    signal compress(var documentIndex, var trackIndex, var segmentIndex)
    signal reverse(var documentIndex, var trackIndex, var segmentIndex)
    signal cut(var documentIndex, var trackIndex, var segmentIndex)
    signal copy(var documentIndex, var trackIndex, var segmentIndex)
    signal paste(var documentIndex, var trackIndex, var segmentIndex)
    signal deleteTrack(var documentIndex, var trackIndex)
    signal deleteSegment(var documentIndex, var trackIndex, var segmentIndex)
    signal removeDocument(var index)

    // Scrollable tree view
    ScrollView {
        anchors.fill: parent
        Item {
            width: root.width
            height: treeView.height
            SimpleTreeView {
                id: treeView
                anchors.left: parent.left
                anchors.right: parent.right
                property string selectedPath
                model: ({
                    nodes: buildTreeViewModel(root.model)
                })
                onClicked: {
                    if(event.button === Qt.LeftButton) {
                        root.selection = indices

                        if(indices.length >= 4) {
                            selection = indices
                        }

                        selectedPath = '/' + indices.join('/')
                    } else if(event.button === Qt.RightButton) {
                        contextMenu.selection = indices
                        contextMenu.popup()
                    }
                }
            }
        }
    }

    function buildTreeViewModel(docs) {
        return docs.map(d => {
                     return {
                         name: d.file.name,
                         nodes: [{
                                 name: "Tracks",
                                 nodes: d.tracks.map((t, trackIndex) => {
                                                         return {
                                                             name: t.name || "Track %1".arg(trackIndex + 1),
                                                             nodes: t.segments.map((s, index) => {
                                                                                       return {
                                                                                           name: "Segment %1".arg(index + 1),
                                                                                           nodes: []
                                                                                       }
                                                                                   })
                                                         }
                                                     })
                             }, {
                                name: "Routes",
                                nodes: []
                             }, {
                                name: "Waypoints",
                                nodes: (d.waypoints || []).map(w => {
                                                           return {
                                                               name: w.name
                                                           }
                                                       })
                             }
                         ]
                     }
                 })
    }

    Menu {
        id: contextMenu
        property var selection: []
        MenuItem {
            text: "Fit to view"
            enabled: contextMenu.selection[1] === 0 && contextMenu.selection.length === 4
            onTriggered: fitToview(contextMenu.selection[0], contextMenu.selection[2], contextMenu.selection[3])
        }
        MenuItem {
            text: "New track"
            enabled: contextMenu.selection.length === 2 && contextMenu.selection[1] === 0
            onTriggered: newTrack(contextMenu.selection[0])
        }
        MenuItem {
            text: "New segment"
            enabled: contextMenu.selection.length === 3 && contextMenu.selection[1] === 0
            onTriggered: newSegment(contextMenu.selection[0], contextMenu.selection[2])
        }
        MenuItem {
            text: "Rename"
            enabled: contextMenu.selection.length === 3 && contextMenu.selection[1] === 0
            onTriggered: renameTrack(contextMenu.selection[0], contextMenu.selection[2])
        }
        MenuItem {
            text: "Move to new track"
            enabled: contextMenu.selection[1] === 0 && contextMenu.selection.length === 4
            onTriggered: moveToNewTrack(contextMenu.selection[0], contextMenu.selection[2], contextMenu.selection[3])
        }
        MenuSeparator { }
        MenuItem {
            text: "Compress"
            // TODO FIX: enabled: documentsView.selection.length === 4 && documentsView.selection[1] === 0   // A segment selected
            onTriggered: compress(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3])
        }
        MenuItem {
            text: "Reverse"
            // TODO: enabled:
            onTriggered: reverse(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3])
        }
        MenuSeparator { }
        MenuItem {
            text: "Cut"
            onTriggered: cut(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3])
        }
        MenuItem {
            text: "Copy"
            onTriggered: copy(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3])
        }
        MenuItem {
            text: "Paste"
            onTriggered: paste(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3])
        }
        MenuSeparator { }
        MenuItem {
            text: "Delete"
            enabled: (contextMenu.selection.length === 4 || contextMenu.selection.length === 3)
            onTriggered: {
                if(contextMenu.selection[1] === 0 && contextMenu.selection.length === 3) {
                    // Track selected
                    deleteTrack(contextMenu.selection[0], contextMenu.selection[2])
                } else if (contextMenu.selection[1] === 0 && contextMenu.selection.length === 4) {
                    // Segment selected
                    deleteSegment(contextMenu.selection[0], contextMenu.selection[2], contextMenu.selection[3])
                }
            }
        }
        MenuItem {
            text: "Close"
            enabled: contextMenu.selection.length === 1
            onTriggered: removeDocument(contextMenu.selection[0])
        }
    }
}
