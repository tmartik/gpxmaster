import QtQuick 2.3
import QtTest 1.0

import "../qml"

TestCase {
    name: "Map provider tests"

    function test_createMainViewModel() {
        var model = createTemporaryObject(testMainViewModel)
        verify(model)
    }

    function test_addMapProvider() {
        var testProvider = {
            name: "testmap",
            url: "http://server.com/z/x/y",
            cacheName: "cache"
        }

        var model = createTemporaryObject(testMainViewModel)

        compare(model.mapProviders.length, 0, "addMapProvider() does not have any map providers by default")

        model.addMapProvider(testProvider.name, testProvider.url, testProvider.cacheName)

        compare(model.mapProviders.length, 1, "addMapProvider() adds exactly one new map provider")
        compare(JSON.stringify(model.mapProviders[0]), JSON.stringify(testProvider), "addMapProvider() adds a new map provider")
    }

    Component {
        id: testMainViewModel
        MainViewModel {}
    }
}
