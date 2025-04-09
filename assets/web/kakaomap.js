let map = null;
let ps = null;
let infoWindow = null;
let marker = null;

let markers = [];
let polylines = [];
let circles = [];
let polygons = [];

// ======= Overlay Clear Functions =======
function clearMarker() {
  markers.forEach(m => m.setMap(null));
  if (infoWindow) infoWindow.close();
  markers = [];
}
function clearPolyline() {
  polylines.forEach(p => p.setMap(null));
  polylines = [];
}
function clearCircle() {
  circles.forEach(c => c.setMap(null));
  circles = [];
}
function clearPolygon() {
  polygons.forEach(p => p.setMap(null));
  polygons = [];
}
function clear() {
  clearMarker();
  clearPolyline();
  clearCircle();
  clearPolygon();
}

// ======= Polyline / Circle / Polygon =======
function addPolyline(callId, points, color, opacity = 1.0, width = 4) {
  const list = JSON.parse(points);
  const paths = list.map(p => new kakao.maps.LatLng(p.latitude, p.longitude));
  const polyline = new kakao.maps.Polyline({
    path: paths,
    strokeWeight: width,
    strokeColor: color,
    strokeOpacity: opacity,
    strokeStyle: 'solid'
  });
  polyline.setMap(map);
  polylines.push(polyline);
}

function addCircle(callId, center, radius, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
  center = JSON.parse(center);
  const circle = new kakao.maps.Circle({
    center: new kakao.maps.LatLng(center.latitude, center.longitude),
    radius,
    strokeWeight,
    strokeColor,
    strokeOpacity,
    strokeStyle,
    fillColor,
    fillOpacity
  });
  circle.setMap(map);
  circles.push(circle);
}

function addPolygon(callId, points, holes, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
  const outer = JSON.parse(points).map(p => new kakao.maps.LatLng(p.latitude, p.longitude));
  const holePaths = JSON.parse(holes).map(h => h.map(p => new kakao.maps.LatLng(p.latitude, p.longitude)));
  const polygon = new kakao.maps.Polygon({
    path: [outer, ...holePaths],
    strokeWeight,
    strokeColor,
    strokeOpacity,
    strokeStyle,
    fillColor,
    fillOpacity
  });
  polygon.setMap(map);
  polygons.push(polygon);
}

// ======= Marker & InfoWindow =======
function addMarker(markerId, latLng, imageSrc, width = 24, height = 30, offsetX = 0, offsetY = 0, infoWindowText) {
  const imageSize = new kakao.maps.Size(width, height);
  const imageOption = { offset: new kakao.maps.Point(offsetX, offsetY) };
  const markerImage = empty(imageSrc) ? null : new kakao.maps.MarkerImage(imageSrc, imageSize, imageOption);

  latLng = JSON.parse(latLng);
  const position = new kakao.maps.LatLng(latLng.latitude, latLng.longitude);
  const newMarker = new kakao.maps.Marker({
    position,
    image: markerImage
  });

  newMarker.setMap(map);
  markers.push(newMarker);

  if (!empty(infoWindowText)) {
    kakao.maps.event.addListener(newMarker, 'click', function () {
      if (infoWindow) infoWindow.close();
      showInfoWindow(newMarker, latLng.latitude, latLng.longitude, infoWindowText);
    });
  }
}

function showInfoWindow(marker, latitude, longitude, contents = '') {
  const iwContent = `<div style="padding:5px;">${contents}</div>`;
  const iwPosition = new kakao.maps.LatLng(latitude, longitude);
  infoWindow = new kakao.maps.InfoWindow({
    map: map,
    position: iwPosition,
    content: iwContent,
    removable: true
  });
  infoWindow.open(map, marker);
}

// ======= Map Control =======
function setCenter(latitude, longitude) {
  map.setCenter(new kakao.maps.LatLng(latitude, longitude));
}
function panTo(latitude, longitude) {
  map.panTo(new kakao.maps.LatLng(latitude, longitude));
}
function moveCamera(lat, lng, zoomLevel) {
  map.setLevel(zoomLevel);
  map.setCenter(new kakao.maps.LatLng(lat, lng));
}
function fitBounds(points) {
  const list = JSON.parse(points);
  const bounds = new kakao.maps.LatLngBounds();
  list.forEach(p => bounds.extend(new kakao.maps.LatLng(p.latitude, p.longitude)));
  map.setBounds(bounds);
}
function displayLevel() {
  const levelEl = document.getElementById('result');
  if (levelEl && map) {
    levelEl.innerHTML = '현재 지도 레벨은 ' + map.getLevel() + ' 레벨입니다.';
  }
}

// ======= 장소 검색 =======
function searchPlaces(keyword) {
  if (!ps) return console.warn("검색 객체 초기화 안됨");
  infoWindow = new kakao.maps.InfoWindow({ zIndex: 1 });

  ps.keywordSearch(keyword, function (data, status, pagination) {
    if (status === kakao.maps.services.Status.OK) {
      clearMarker();
      const bounds = new kakao.maps.LatLngBounds();
      data.forEach(place => {
        displaySearchMarker(place);
        bounds.extend(new kakao.maps.LatLng(place.y, place.x));
      });
      map.setBounds(bounds);
    } else {
      console.warn("검색 실패 또는 결과 없음:", status);
    }
  });
}

function displaySearchMarker(place) {
  const newMarker = new kakao.maps.Marker({
    map: map,
    position: new kakao.maps.LatLng(place.y, place.x)
  });

  kakao.maps.event.addListener(newMarker, 'click', function () {
    infoWindow.setContent(`<div style="padding:5px;font-size:12px;">${place.place_name}</div>`);
    infoWindow.open(map, newMarker);
  });

  markers.push(newMarker);
}

// ======= Flutter Bridge =======
window.searchKeywordFlutterBridge = {
  postMessage: function (keyword) {
    console.log("Flutter에서 받은 검색어:", keyword);
    searchPlaces(keyword);
  }
};

window.cameraIdle = {
  postMessage: function (message) {
    console.log("Flutter로 전송:", message);
  }
};

// ======= Map Init =======
window.onload = function () {
  kakao.maps.load(function () {
    const container = document.getElementById('map');
    const options = {
      center: new kakao.maps.LatLng(37.3626138, 126.9264801),
      level: 3
    };

    map = new kakao.maps.Map(container, options);
    ps = new kakao.maps.services.Places();
    infoWindow = new kakao.maps.InfoWindow({ zIndex: 1 });

    marker = new kakao.maps.Marker({ position: map.getCenter() });
    marker.setMap(map);

    const zoomControl = new kakao.maps.ZoomControl();
    map.addControl(zoomControl, kakao.maps.ControlPosition.RIGHT);

    displayLevel();

    kakao.maps.event.addListener(map, 'zoom_changed', displayLevel);
    kakao.maps.event.addListener(map, 'dragstart', displayLevel);

    kakao.maps.event.addListener(map, 'idle', function () {
      const latLng = map.getCenter();
      const idleLatLng = {
        latitude: latLng.getLat(),
        longitude: latLng.getLng(),
        zoomLevel: map.getLevel(),
      };
      if (typeof cameraIdle !== 'undefined') {
        cameraIdle.postMessage(JSON.stringify(idleLatLng));
      }
    });

    kakao.maps.event.addListener(map, 'click', function (mouseEvent) {
      const latLng = mouseEvent.latLng;
      marker.setPosition(latLng);

      const message = `클릭한 위치의 위도는 ${latLng.getLat()} 이고, 경도는 ${latLng.getLng()} 입니다`;
      const resultDiv = document.getElementById('clickLatlng');
      if (resultDiv) resultDiv.innerHTML = message;

      const clickLatLng = {
        latitude: latLng.getLat(),
        longitude: latLng.getLng(),
        zoomLevel: map.getLevel()
      };
      if (typeof onMapTap !== 'undefined') {
        onMapTap.postMessage(JSON.stringify(clickLatLng));
      }
    });

    if (window.flutter_inappwebview) {
          console.log("🟢 JS 초기화 완료, Flutter에 신호 보냄");
          window.flutter_inappwebview.callHandler('flutterWebViewReady', 'ready');
        } else if (window.flutterWebViewReady) {
          console.log("🟢 JS 초기화 완료, flutterWebViewReady 채널로 신호 보냄");
          window.flutterWebViewReady.postMessage("ready");
        } else {
          console.warn("❗️ Flutter 브리지가 존재하지 않음");
        }
  });
};

// ======= Empty Check =======
function empty(value) {
  return (
    value === null ||
    value === undefined ||
    (typeof value === 'string' && (value.trim() === '' || value === 'null')) ||
    (Array.isArray(value) && value.length === 0) ||
    (typeof value === 'object' && Object.keys(value).length === 0)
  );
}
