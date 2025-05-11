//두번째 버전(마커 초기화, 일반 위치 누르면 작동못함), 마커 다 안찍힘
let map = null;
let ps = null;  // 검색 객체
let infoWindow = null;
let marker = null;

let markers = [];
let polylines = [];
let circles = [];
let polygons = [];

// 클러스터러를 초기화, 지도가 로딩된 후에 클러스터러를 적용
let clusterer = null;

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

  // 클러스터러에 마커 추가
  if (clusterer) {
    clusterer.addMarkers([newMarker]);
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

      // 지도 범위를 확장하여 모든 마커가 보이도록 함
      map.setBounds(bounds);

      // 줌 레벨을 적절히 조정 (지도가 너무 확대되지 않도록)
      map.setLevel(5);

      // ✅ 첫 번째 검색 결과로 이동
      if (data.length > 0) {
        const firstPlace = data[0];
        map.panTo(new kakao.maps.LatLng(firstPlace.y, firstPlace.x));
      }
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

// ======= 현재 위치로 이동 함수 추가 =======
function moveToCurrentLocation(lat, lng) {
  if (map) {
    map.panTo(new kakao.maps.LatLng(lat, lng));
    if (marker) {
      marker.setPosition(new kakao.maps.LatLng(lat, lng));
    }
  }
}

// ======= Flutter Bridge에 함수 노출 =======
window.moveToCurrentLocationBridge = {
  postMessage: function (message) {
    try {
      const data = JSON.parse(message);
      moveToCurrentLocation(data.latitude, data.longitude);
    } catch (e) {
      console.warn("moveToCurrentLocationBridge 파싱 오류:", e);
    }
  }
};

window.searchKeywordFlutterBridge = {
  postMessage: function (keyword) {
    console.log("Flutter에서 받은 검색어:", keyword);
    searchPlaces(keyword);
  }
};

// ======= Map Init =======
window.onload = function () {
  kakao.maps.load(function () {
    const container = document.getElementById('map');
    const options = {
      center: new kakao.maps.LatLng(37.3626138, 126.9264801),
      level: 5  // 지도의 기본 줌 레벨을 적당히 설정
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
