let map = null;
let polylines = [];
let circles = [];
let polygons = [];
let markers = [];
let marker = null; // 클릭용 마커 전역 선언

function clearPolyline() {
    for (let i = 0; i < polylines.length; i++) {
        polylines[i].setMap(null);
    }
    polylines = [];
}

function clearCircle() {
    for (let i = 0; i < circles.length; i++) {
        circles[i].setMap(null);
    }
    circles = [];
}

function clearPolygon() {
    for (let i = 0; i < polygons.length; i++) {
        polygons[i].setMap(null);
    }
    polygons = [];
}

function clearMarker() {
    for (let i = 0; i < markers.length; i++) {
        markers[i].setMap(null);
    }
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

function addPolygonWithoutHole(callId, points, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
    let polygon = new kakao.maps.Polygon({
        path: points,
        strokeWeight: strokeWeight,
        strokeColor: strokeColor,
        strokeOpacity: strokeOpacity,
        strokeStyle: strokeStyle,
        fillColor: fillColor,
        fillOpacity: fillOpacity
    });
    polygons.push(polygon);
    polygon.setMap(map);
}

function addPolygonWithHole(callId, points, holes, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
    let polygon = new kakao.maps.Polygon({
        map: map,
        path: [points, ...holes],
        strokeWeight: strokeWeight,
        strokeColor: strokeColor,
        strokeOpacity: strokeOpacity,
        strokeStyle: strokeStyle,
        fillColor: fillColor,
        fillOpacity: fillOpacity
    });
    polygons.push(polygon);
}

function addMarker(markerId, latLng, imageSrc, width = 24, height = 30, offsetX = 0, offsetY = 0, infoWindowText) {
    let imageSize = new kakao.maps.Size(width, height);
    let imageOption = { offset: new kakao.maps.Point(offsetX, offsetY) };
    let markerImage = null;
    if (!empty(imageSrc)) {
        markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize, imageOption);
    }
    latLng = JSON.parse(latLng);
    let markerPosition = new kakao.maps.LatLng(latLng.latitude, latLng.longitude);
    let marker = new kakao.maps.Marker({
        position: markerPosition,
        image: markerImage
    });
    marker.setMap(map);
    markers.push(marker);
    kakao.maps.event.addListener(marker, 'click', function () {
        if (!empty(infoWindowText)) {
            if (infoWindow != null) infoWindow.close();
            showInfoWindow(marker, latLng.latitude, latLng.longitude, infoWindowText);
        }
    });
}

let infoWindow = null;

function showInfoWindow(marker, latitude, longitude, contents = '') {
    let iwContent = '<div style="padding:5px;">' + contents + '</div>',
        iwPosition = new kakao.maps.LatLng(latitude, longitude),
        iwRemovable = true;
    infoWindow = new kakao.maps.InfoWindow({
        map: map,
        position: iwPosition,
        content: iwContent,
        removable: iwRemovable
    });
    infoWindow.open(map, marker);
}

function setCenter(latitude, longitude) {
    let moveLatLon = new kakao.maps.LatLng(latitude, longitude);
    map.setCenter(moveLatLon);
}

function panTo(latitude, longitude) {
    let moveLatLon = new kakao.maps.LatLng(latitude, longitude);
    map.panTo(moveLatLon);
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

window.cameraIdle = {
    postMessage: function (message) {
        console.log("Flutter로 전송:", message);
    }
};

window.onload = function () {
    let container = document.getElementById('map');
    let options = {
        center: new kakao.maps.LatLng(37.3626138, 126.9264801),
        level: 3
    };
    map = new kakao.maps.Map(container, options);

    // 클릭용 마커 초기화
    marker = new kakao.maps.Marker({
        position: map.getCenter()
    });
    marker.setMap(map);

    const zoomControl = new kakao.maps.ZoomControl();
    map.addControl(zoomControl, kakao.maps.ControlPosition.RIGHT);

    displayLevel();

    kakao.maps.event.addListener(map, 'zoom_changed', function () {
        displayLevel();
    });

    kakao.maps.event.addListener(map, 'dragstart', function () {
        displayLevel();
    });

    kakao.maps.event.addListener(map, 'idle', function () {
        const latLng = map.getCenter();
        const idleLatLng = {
            latitude: latLng.getLat(),
            longitude: latLng.getLng(),
            zoomLevel: map.getLevel(),
        };
        console.log("카메라 이동 완료:", idleLatLng);
        if (typeof cameraIdle !== 'undefined') {
            cameraIdle.postMessage(JSON.stringify(idleLatLng));
        } else {
            console.warn("cameraIdle이 정의되지 않음");
        }
    });

    kakao.maps.event.addListener(map, 'click', function (mouseEvent) {
        let latLng = mouseEvent.latLng;
        let currentCenter = map.getCenter();

        let distance = Math.sqrt(
            Math.pow(latLng.getLat() - currentCenter.getLat(), 2) +
            Math.pow(latLng.getLng() - currentCenter.getLng(), 2)
        );
        if (distance > 0.0001) {
            map.panTo(latLng);
        }

        marker.setPosition(latLng);

        let message = '클릭한 위치의 위도는 ' + latLng.getLat() + ' 이고, ';
        message += '경도는 ' + latLng.getLng() + ' 입니다';
        let resultDiv = document.getElementById('clickLatlng');
        console.log("resultDiv:", resultDiv);
        if (resultDiv) {
            resultDiv.innerHTML = message;
            console.log("메시지 업데이트됨:", message);
        } else {
            console.warn("clickLatlng div를 찾을 수 없음");
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
};

if (typeof zoomChanged === 'undefined') {
    window.zoomChanged = {
        postMessage: function (msg) {
            console.log("Flutter로 보낼 zoomChanged 메시지:", msg);
        }
    };
}

if (typeof onMapTap === 'undefined') {
    window.onMapTap = {
        postMessage: function (msg) {
            console.log("Flutter로 보낼 onMapTap 메시지:", msg);
        }
    };
}

const empty = (value) => {
    if (value === null) return true;
    if (typeof value === 'undefined') return true;
    if (typeof value === 'string' && (value === '' || value === 'null')) return true;
    if (Array.isArray(value) && value.length < 1) return true;
    if (typeof value === 'object' && value.constructor.name === 'Object' && Object.keys(value).length < 1) return true;
    if (typeof value === 'object' && value.constructor.name === 'String' && Object.keys(value).length < 1) return true;
    return false;
};
