import QtQuick 2.15
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.15
import QtLocation 5.15
import QtPositioning 5.15


Map {
    id: map

    property var appStyle

    property bool useImperialUnits: false
    property alias markersModel: markerLayer.model
    property alias dotModel: dotLayer.model

    property alias dropEnabled: dropArea.enabled
    property bool dragEnabled: false
    property string baseUrl: "http://localhost:5555/"           // TODO: read port from the server.

    property int selectedDotIndex: -1
    property var selection: []          // TODO: remove

    property int selectedTrack: -1
    property int selectedPath: -1

    property var layerItemViews: ({})

    property var selectedLayerName
    property var mapItemViews: []

    signal dropped(var name, var content, var coordinate)
    signal openFile(var url)
    signal wptClicked(var index, var wpt)
    signal rightClick(var coordinate)
    signal leftClick(var coordinate)
    signal keyPressed(var key, var coordinate)
    signal keyReleased(var key, var coordinate)
    signal pointLeftClicked(var index)
    signal pointRightClicked(var index)
    signal moved(var index, var coordinate)

    focus: true
    activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

    // Data provider; SEE: https://doc.qt.io/qt-5/qtlocation-index.html
    plugin: Plugin {
        name: "osm"
        PluginParameter { name: "osm.useragent"; value: "My test application" }
        PluginParameter { name: "osm.mapping.custom.host"; value: baseUrl }
        PluginParameter { name: "osm.mapping.cache.memory.cost_strategy"; value: "unitary" }
        PluginParameter { name: "osm.mapping.cache.memory.size"; value: "500" }
    }

    Keys.onPressed: keyPressed(event.key, toCoordinate(Qt.point(mouseArea.mouseX, mouseArea.mouseY), false))
    Keys.onReleased: {
        var c = toCoordinate(Qt.point(mouseArea.mouseX, mouseArea.mouseY), false)
        keyReleased(event.key, c)
    }

    onSelectionChanged: {
        for(var layerName of Object.keys(layerItemViews)) {
            var layerMapItemView = layerItemViews[layerName]
            if(layerMapItemView.selected !== undefined) {
                layerMapItemView.selected = layerName === 'route:' + selectedLayerName
                layerMapItemView.selectedIndex = selection[3]
            }
        }
    }
    onSelectedTrackChanged: updateSelections()
    onSelectedPathChanged: updateSelections()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: {
            var c = toCoordinate(Qt.point(mouse.x, mouse.y), false)
            if (mouse.button === Qt.RightButton) {
                rightClick(c)
            } else if(mouse.button === Qt.LeftButton) {
                leftClick(c)
            }
        }
    }

    // Route dots
    MapItemView {
        id: dotLayer
        add: null
        remove: null
        delegate: MapQuickItem {
            property bool isFirstPoint: index === 0
            property int size: isFirstPoint ? 30 : selectedDotIndex === index ? 15 : 10
            coordinate: QtPositioning.coordinate(modelData.lat, modelData.lon)
            anchorPoint.x: size / 2
            anchorPoint.y: size / 2

            sourceItem: Rectangle {
                id: handleDelegate
                width: size
                height: size
                radius: size
                color: isFirstPoint ? 'green' : dotDelegatemouseArea.containsMouse ? 'blue' : 'white'
                border.color: isFirstPoint ? 'green' : 'red'
                border.width: 2
                visible: map.zoomLevel >= 13

                Drag.active: dragEnabled && dotDelegatemouseArea.drag.active

                MouseArea {
                    id: dotDelegatemouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true
                    drag.target: dragEnabled && pressedButtons === Qt.LeftButton ? parent : null
                    onEntered: selectedDotIndex = index
                    onExited: selectedDotIndex = -1
                    onClicked: {
                        console.log('POINT CLICKED: ' + index)

                        if(mouse.button === Qt.LeftButton) {
                            pointLeftClicked(index)
                        } else if(mouse.button === Qt.RightButton) {
                            pointRightClicked(index)
                        }
                    }
                    onReleased: {
                        if(dragEnabled && mouse.button === Qt.LeftButton) {
                            // Set new coordinate
                            console.log('DRAGGED: ' + index)

                            var p = mapToItem(map, x, y)
                            var c = toCoordinate(Qt.point(p.x + size / 2, p.y + size / 2), false)

                            Qt.callLater(function() {
                                moved(index, c)
                            })
                        }
                    }
                }
            }
        }
    }

    // Distance markers
    MapItemView {
        id: markerLayer
        add: null
        remove: null
        delegate: MapQuickItem {
            id: marker
            property int size: 18
            coordinate: QtPositioning.coordinate(modelData.lat, modelData.lon)
            anchorPoint.x: size / 2
            anchorPoint.y: size / 2

            sourceItem: Rectangle {
                width: Math.max(size, Math.max(markerText.width, markerText.height) + appStyle.margin)
                height: width
                radius: width
                color: 'white'
                border.color: 'black'
                border.width: 1
                Text {
                    id: markerText
                    property bool terminus: modelData.final === true
                    property real distance: modelData.distance / (useImperialUnits ? appStyle.imperialUnitFactor * 1000 : 1000)
                    anchors.centerIn: parent
                    font.pixelSize: appStyle.textPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    text: terminus ? qsTr("%1\n%2").arg(distance.toFixed(1)).arg(useImperialUnits ? "ml" : "km") : distance.toFixed(0)
                }
            }
        }
    }

    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        text: "ZOOM: " + map.zoomLevel
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: {
            var name = ""
            var content = ""

            if(drop.hasUrls) {
                for(var u of drop.urls) {
                    console.log('URL: ' + u)

                    if(u.startsWith('file://')) {
                        // Local file dropped
                        openFile(u)
                        return
                    } else if(!name) {
                        var p = u.split("/")
                        do {
                            name = p.pop()
                        } while(!name)
                    }
                }

                content = drop.urls.join("\n")
            }

            if(drop.hasText && !name && !content) {
                name = drop.text.split(" ")[0] || "unnamed"
                content = drop.text
            }

            var c = map.toCoordinate(Qt.point(drop.x, drop.y), false)
            map.dropped(name, content, c)
            drop.accept()
        }
    }

    function updateSelections() {
        for(var i in mapItemViews) {
            var view = mapItemViews[i]
            view.selected = selectedTrack === parseInt(i)
            view.selectedIndex = view.selected ? selectedPath : -1
        }
    }

    function addPlaceLayer(name, places) {
        var component = Qt.createComponent("PlaceLayerMapItemView.qml")
        var layer = component.createObject(map, {
                                                   style: map.appStyle,
                                                   model: places,
                                               })
        layer.clicked.connect(function(index, data) {
            console.log('CLICK: ' + index)
            wptClicked(index, data)
        })
        addLayer('place:' + name, layer)
    }


    function addRouteLayer(name, paths, style) {        // This one track with several segments
        var component = Qt.createComponent("LayerMapItemView.qml")
        var newObject = component.createObject(map, {
                                                   style: style,
                                                   model: paths,
                                               })
        mapItemViews.push(newObject)
        addMapItemView(newObject)
        addMapItemView(markerLayer)
    }

    function addLayer(name, object) {
        if (object === null) {
            // Error Handling
            console.log("Error creating object")
            return
        }

        // Remove existing layer
        var existingLayer = layerItemViews[name]
        if(existingLayer) {
            removeMapItemView(layerItemViews[name])
        }

        addMapItemView(object)
        layerItemViews[name] = object

        // Preserve Z-order    // TODO: placeLayer + dotLayer
        map.removeMapItemView(markerLayer)
        map.addMapItemView(markerLayer)
    }

    function resetLayers() {
        for(var name of Object.keys(layerItemViews)) {
            removeMapItemView(layerItemViews[name])
        }

        while(mapItemViews.length > 0) {
            removeMapItemView(mapItemViews.pop())
        }

        layerItemViews = ({})
    }

    function gotoCoordinate(lat, lon, z) {
        center = QtPositioning.coordinate(lat, lon)
        zoomLevel = z
    }
}
