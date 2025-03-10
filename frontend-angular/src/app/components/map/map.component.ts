import { Component, OnInit, OnDestroy, AfterViewInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import OSMSource from 'ol/source/OSM';
import TileWMS from 'ol/source/TileWMS';
import { fromLonLat } from 'ol/proj';
import { selectedLayer } from '@signals/layer.signal';
import { AppConfigService } from '@app/config/app-config.service';

@Component({
  standalone: true,
  selector: 'app-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.css'],
  imports: [CommonModule]
})
export class MapComponent implements AfterViewInit, OnDestroy {
  private map?: Map;
  private appConfig: AppConfigService = inject(AppConfigService);
  
  // Track initialization state to avoid double initialization
  private initialized = false;
  
  // Track if the component is destroyed to avoid updating after destruction
  private isDestroyed = false;

  ngAfterViewInit(): void {
    // Initialize the map when the view is ready
    if (!this.initialized) {
      this.initialized = true;
      
      console.log('Map component view initialized');
      this.initMap();
      
      // Wait a tick to make sure the map is rendered
      setTimeout(() => {
        let currentLayer = selectedLayer() || 'OSM';
        console.log(`Initial layer: ${currentLayer}`);
        this.updateMap(currentLayer);
        
        // Watch for layer changes
        const watchLayer = () => {
          if (this.isDestroyed) return;
          
          const layer = selectedLayer();
          if (layer !== currentLayer) {
            console.log(`Layer changed from ${currentLayer} to ${layer}`);
            currentLayer = layer;
            this.updateMap(layer);
          }
          
          // Continue watching
          requestAnimationFrame(watchLayer);
        };
        requestAnimationFrame(watchLayer);
      }, 0);
    }
  }

  ngOnDestroy(): void {
    this.isDestroyed = true;
  }

  private initMap(): void {
    console.log('Initializing map with settings:', this.appConfig.settings);
    
    // Create base layer
    const osmLayer = new TileLayer({
      source: new OSMSource(),
      visible: true
    });
    osmLayer.set('title', 'OpenStreetMap');
    
    // Get center and zoom
    const center = this.appConfig.settings?.initialView?.center || [10, 50];
    const zoom = this.appConfig.settings?.initialView?.zoom || 4;
    
    // Create map
    this.map = new Map({
      target: 'map',
      layers: [osmLayer],
      view: new View({
        center: fromLonLat(center),
        zoom: zoom
      })
    });
    
    console.log('Map initialized');
  }

  private updateMap(layerName: string): void {
    if (!this.map || !layerName) {
      return;
    }
    
    // Remove all non-base layers
    const layersToRemove = this.map.getLayers().getArray()
      .filter(layer => layer.get('title') !== 'OpenStreetMap');
    
    layersToRemove.forEach(layer => {
      console.log(`Removing layer: ${layer.get('title')}`);
      this.map?.removeLayer(layer);
    });
    
    // OSM is already the base layer, so nothing more to do
    if (layerName === 'OSM') {
      return;
    }
    
    const wmsLayer = new TileLayer({
      source: new TileWMS({
        url: this.appConfig.settings?.qgisServerUrl,
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
        serverType: 'qgis',
      }),
      visible: true
    });
    wmsLayer.set('title', layerName);
    
    console.log('Adding WMS layer to map');
    this.map.addLayer(wmsLayer);
    wmsLayer.getSource()?.refresh();
    
    // Force map update
    setTimeout(() => {
      this.map?.updateSize();
    }, 100);
  }
}
