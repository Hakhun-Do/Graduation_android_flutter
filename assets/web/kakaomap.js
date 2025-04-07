// ✅ Kakao 지도 검색 기능 + Flutter 연동 통합 최종 버전

let map = null;
let polylines = [];
let circles = [];
let polygons = [];
let markers = [];
let marker = null;
let infoWindow = null;
let ps = null;

function clearPolyline() {
  polylines.forEach(line => line.setMap(null));
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

function clearMarker() {
  markers.forEach(m => m.setMap(null));
  if (infoWindow != null) infoWindow.close();
  markers = [];
}

function clear() {
  clearPolyline();
  clearCircle();
  clearPolygon();
  clearMarker();
}

function addPolyline(callId, points, color, opacity = 1.0, width = 4) {
  let list = JSON.parse(points);
  let paths = list.map(p => new kakao.maps.LatLng(p.latitude, p.longitude));
  let polyline = new kakao.maps.Polyline({
    path: paths,
    strokeWeight: width,
    strokeColor: color,
    strokeOpacity: opacity,
    strokeStyle: 'solid'
  });
  polylines.push(polyline);
  polyline.setMap(map);
}

function addCircle(callId, center, radius, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
  center = JSON.parse(center);
  let circle = new kakao.maps.Circle({
    center: new kakao.maps.LatLng(center.latitude, center.longitude),
    radius: radius,
    strokeWeight: strokeWeight,
    strokeColor: strokeColor,
    strokeOpacity: strokeOpacity,
    strokeStyle: strokeStyle,
    fillColor: fillColor,
    fillOpacity: fillOpacity
  });
  circles.push(circle);
  circle.setMap(map);
}

function addPolygon(callId, points, holes, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
  points = JSON.parse(points);
  let paths = points.map(p => new kakao.maps.LatLng(p.latitude, p.longitude));
  holes = JSON.parse(holes);
  if (!empty(holes)) {
    let holePaths = holes.map(h => h.map(p => new kakao.maps.LatLng(p.latitude, p.longitude)));
    return addPolygonWithHole(callId, paths, holePaths, strokeWeight, strokeColor, strokeOpacity, strokeStyle, fillColor, fillOpacity);
  }
  return addPolygonWithoutHole(callId, paths, strokeWeight, strokeColor, strokeOpacity, strokeStyle, fillColor, fillOpacity);
}

function addPolygonWithoutHole(callId, points, strokeWeight, strokeColor, strokeOpacity, strokeStyle, fillColor, fillOpacity) {
  let polygon = new kakao.maps.Polygon({
    path: points,
    strokeWeight,
    strokeColor,
    strokeOpacity,
    strokeStyle,
    fillColor,
    fillOpacity
  });
  polygons.push(polygon);
  polygon.setMap(map);
}

function addPolygonWithHole(callId, points, holes, strokeWeight, strokeColor, strokeOpacity, strokeStyle, fillColor, fillOpacity) {
  let polygon = new kakao.maps.Polygon({
    path: [points, ...holes],
    strokeWeight,
    strokeColor,
    strokeOpacity,
    strokeStyle,
    fillColor,
    fillOpacity
  });
  polygons.push(polygon);
  polygon.setMap(map);
}

function addMarker(markerId, latLng, imageSrc, width = 24, height = 30, offsetX = 0, offsetY = 0, infoWindowText) {
  let imageSize = new kakao.maps.Size(width, height);
  let imageOption = { offset: new kakao.maps.Point(offsetX, offsetY) };
  let markerImage = empty(imageSrc) ? null : new kakao.maps.MarkerImage(imageSrc, imageSize, imageOption);

  latLng = JSON.parse(latLng);
  let position = new kakao.maps.LatLng(latLng.latitude, latLng.longitude);
  let marker = new kakao.maps.Marker({
    position: position,
    image: markerImage
  });

  marker.setMap(map);
  markers.push(marker);

  if (!empty(infoWindowText)) {
    kakao.maps.event.addListener(marker, 'click', function () {
      if (infoWindow != null) infoWindow.close();
      showInfoWindow(marker, latLng.latitude, latLng.longitude, infoWindowText);
    });
  }
}

function showInfoWindow(marker, latitude, longitude, contents = '') {
  let iwContent = '<div style="padding:5px;">' + contents + '</div>';
  let iwPosition = new kakao.maps.LatLng(latitude, longitude);
  infoWindow = new kakao.maps.InfoWindow({
    map: map,
    position: iwPosition,
    content: iwContent,
    removable: true
  });
  infoWindow.open(map, marker);
}

function setCenter(latitude, longitude) {
  map.setCenter(new kakao.maps.LatLng(latitude, longitude));
}

function panTo(latitude, longitude) {
  map.panTo(new kakao.maps.LatLng(latitude, longitude));
}

function fitBounds(points) {
  let list = JSON.parse(points);
  let bounds = new kakao.maps.LatLngBounds();
  list.forEach(p => bounds.extend(new kakao.maps.LatLng(p.latitude, p.longitude)));
  map.setBounds(bounds);
}

function displayLevel() {
  const levelEl = document.getElementById('result');
  if (levelEl && map) {
    levelEl.innerHTML = '현재 지도 레벨은 ' + map.getLevel() + ' 레벨입니다.';
  }
}

function moveCamera(lat, lng, zoomLevel) {
  map.setLevel(zoomLevel);
  map.setCenter(new kakao.maps.LatLng(lat, lng));
}

// 🔍 키워드 장소 검색
function searchPlaces(keyword) {
  if (!ps) {
    console.warn("검색 객체가 아직 초기화되지 않았습니다.");
    return;
  }

  infoWindow = new kakao.maps.InfoWindow({ zIndex: 1 });

  ps.keywordSearch(keyword, function (data, status, pagination) {
    if (status === kakao.maps.services.Status.OK) {
      clearMarker();
      let bounds = new kakao.maps.LatLngBounds();
      for (let i = 0; i < data.length; i++) {
        displaySearchMarker(data[i]);
        bounds.extend(new kakao.maps.LatLng(data[i].y, data[i].x));
      }
      map.setBounds(bounds);
    } else {
      console.warn("검색 실패 또는 결과 없음:", status);
    }
  });
}

function displaySearchMarker(place) {
  let marker = new kakao.maps.Marker({
    map: map,
    position: new kakao.maps.LatLng(place.y, place.x)
  });

  kakao.maps.event.addListener(marker, 'click', function () {
    infoWindow.setContent('<div style="padding:5px;font-size:12px;">' + place.place_name + '</div>');
    infoWindow.open(map, marker);
  });

  markers.push(marker);
}

// ✅ Flutter → JS 키워드 검색 브릿지
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

// ✅ 카카오 지도 초기화 - 반드시 maps.load 안에서 실행
window.onload = function () {
  kakao.maps.load(function () {
    let container = document.getElementById('map');
    let options = {
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
      let latLng = mouseEvent.latLng;
      marker.setPosition(latLng);

      let message = '클릭한 위치의 위도는 ' + latLng.getLat() + ' 이고, ';
      message += '경도는 ' + latLng.getLng() + ' 입니다';
      let resultDiv = document.getElementById('clickLatlng');
      if (resultDiv) {
        resultDiv.innerHTML = message;
      }

      const clickLatLng = {
        latitude: latLng.getLat(),
        longitude: latLng.getLng(),
        zoomLevel: map.getLevel(),
      };
      if (typeof onMapTap !== 'undefined') {
        onMapTap.postMessage(JSON.stringify(clickLatLng));
      }
    });

    // ✅ maps.load 완료 후 Flutter에 알림
    if (window.flutterWebViewReady !== undefined) {
      console.log("🟢 JS 초기화 완료, Flutter에 신호 보냄");
      window.flutterWebViewReady.postMessage('ready');
    }
  });
};

const empty = (value) => {
  return (
    value === null ||
    value === undefined ||
    (typeof value === 'string' && (value.trim() === '' || value === 'null')) ||
    (Array.isArray(value) && value.length === 0) ||
    (typeof value === 'object' && Object.keys(value).length === 0)
  );
};
