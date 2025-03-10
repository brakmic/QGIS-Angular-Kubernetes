let map;
let qgisServerUrl = '/qgis/qgis_mapserv.fcgi';
let debugMode = true;

document.addEventListener('DOMContentLoaded', function() {
    initMap();
    
    // Add layer selection change handler
    document.getElementById('layer-select').addEventListener('change', function() {
        updateMap(this.value);
    });
    
    // Initialize with the default layer
    updateMap(document.getElementById('layer-select').value);
});

function initMap() {
    // Create OSM base layer
    const osmLayer = new ol.layer.Tile({
        source: new ol.source.OSM(),
        visible: true,
        title: 'OpenStreetMap'
    });
    
    // Initialize map with OSM layer
    map = new ol.Map({
        target: 'map',
        layers: [osmLayer],
        view: new ol.View({
            center: ol.proj.fromLonLat([0, 0]),
            zoom: 2
        })
    });
}

function updateMap(layerName) {
    if (debugMode) {
        console.log(`Switching to layer: ${layerName}`);
    }
    
    // Remove any existing WMS layers
    map.getLayers().getArray()
        .filter(layer => layer.get('title') !== 'OpenStreetMap')
        .forEach(layer => map.removeLayer(layer));
    
    // If OSM is selected, we're done (base layer is always there)
    if (layerName === 'OSM') {
        return;
    }
    
    // Add the selected layer as WMS
    const wmsUrl = qgisServerUrl;
    
    if (debugMode) {
        console.log(`WMS URL: ${wmsUrl}`);
        console.log(`Adding layer: ${layerName}`);
    }
    
    const wmsLayer = new ol.layer.Tile({
        source: new ol.source.TileWMS({
            url: wmsUrl,
            params: {
                'LAYERS': layerName,
                'TILED': true,
                'FORMAT': 'image/png',
                'TRANSPARENT': true,
                'SERVICE': 'WMS',
                'VERSION': '1.3.0',
                'REQUEST': 'GetMap',
                'STYLES': '',
                'CRS': 'EPSG:3857'
            },
            serverType: 'qgis'
        }),
        visible: true,
        title: layerName
    });
    
    map.addLayer(wmsLayer);
}
