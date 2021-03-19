((exports) => {
  exports.Decidim = exports.Decidim || {};

  const MapController = exports.Decidim.MapController;

  class MapDragMarkerController extends MapController {
    start() {
      if (this.config.marker) {
        this.addMarker(this.config.marker);
      } else {
        this.map.fitWorld();
      }
    }

    addMarker(markerData) {
      const coordinates = {
        lat: markerData.latitude,
        lng: markerData.longitude
      };
      this.triggerEvent("coordinates", [coordinates]);

      this.marker = L.marker(coordinates, {
        icon: this.createIcon(),
        keyboard: true,
        title: markerData.title,
        draggable: true
      });
      this.marker.on("drag", (ev) => {
        this.triggerEvent("coordinates", [ev.target.getLatLng()]);
      });
      this.marker.addTo(this.map);

      const zoom = parseInt(this.config.zoom, 10) || 14;
      this.map.setView(coordinates, zoom);
    }

    getMarker() {
      return this.marker;
    }

    removeMarker() {
      if (this.marker) {
        this.marker.remove();
        this.marker = null;
      }
    }
  }

  exports.Decidim.MapDragMarkerController = MapDragMarkerController;
})(window);
