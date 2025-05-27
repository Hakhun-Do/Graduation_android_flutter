let map = null;
let ps = null;
let infoWindow = null;
let marker = null;
let markers = [];
let polylines = [];
let circles = [];
let polygons = [];
let clusterer = null;

let hydrantcommentOverlay = null;
let firetruckcommentOverlay = null;

function clearMarker() {
  markers.forEach(m => m.setMap(null));
  if (infoWindow) infoWindow.close();
  markers = [];
  if (clusterer) clusterer.clear();
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

function addMarker(markerId, latLng, imageSrc, width = 24, height = 30, offsetX = 0, offsetY = 0, infoWindowText) {
  const imageSize = new kakao.maps.Size(width, height);
  const imageOption = { offset: new kakao.maps.Point(offsetX, offsetY) };
  const markerImage = empty(imageSrc) ? null : new kakao.maps.MarkerImage(imageSrc, imageSize, imageOption);

  latLng = JSON.parse(latLng);
  const position = new kakao.maps.LatLng(latLng.latitude, latLng.longitude);
  const newMarker = new kakao.maps.Marker({ position, image: markerImage });
  markers.push(newMarker);

  if (!empty(infoWindowText)) {
    kakao.maps.event.addListener(newMarker, 'click', function () {
      if (infoWindow) infoWindow.close();
      showInfoWindow(newMarker, latLng.latitude, latLng.longitude, infoWindowText);
    });
  }

  if (clusterer) clusterer.addMarkers([newMarker]);
}

function addMarkersFromList(markerListJson) {
  const markerList = typeof markerListJson === 'string' ? JSON.parse(markerListJson) : markerListJson;
  const newMarkers = [];
  markers.forEach(m => m.setMap(null));
  markers = [];
  if (clusterer) clusterer.clear();

  markerList.forEach(item => {
    const latLng = new kakao.maps.LatLng(item.latitude, item.longitude);
    let imageSrc;

    // ✅ 마커 종류에 따라 이미지 변경
    if (item.type === 'firetruck') {
      imageSrc = 'firetruck.png';
    } else if (item.type === 'hydrant') {
      imageSrc = 'fireplug.png';
    } else if (item.type === 'problem') {
      imageSrc = 'problem.png';
    } else if (item.type === 'breakdown') {
      imageSrc = 'breakdown.png';
    } else if (item.type === 'hydrantAdd') {
      imageSrc = 'fireplug_add.png';
    } else if (item.type === 'truckAdd') {
      imageSrc = 'firetruck_add.png';
    }

    const markerImage = new kakao.maps.MarkerImage(
      imageSrc,
      new kakao.maps.Size(24, 24),
      { offset: new kakao.maps.Point(12, 30) }
    );

    const marker = new kakao.maps.Marker({ position: latLng, image: markerImage });

    kakao.maps.event.addListener(marker, 'click', function () {
      if (infoWindow) infoWindow.close();
      showInfoWindow(
        marker,
        item.latitude,
        item.longitude,
        item,
        item.id,
        item.type
      );
    });

    newMarkers.push(marker);
    markers.push(marker);
  });

  if (clusterer) clusterer.addMarkers(newMarkers);
}

function showInfoWindow(marker, latitude, longitude, item = {}, markerId = null, type = '') {
  // 기존 InfoWindow 및 코멘트창 닫기
  if (infoWindow) infoWindow.close();
  if (hydrantcommentOverlay) hydrantcommentOverlay.setMap(null);

  // 타입별 콘텐츠 생성
  let iwContent = '';
  if (type === 'hydrant') {
    iwContent = `
      <div style="padding:8px; min-width:220px; font-family: Arial, sans-serif;">
        <b style="font-size:16px; color:#2c3e50;">소화전 상세정보</b>
        <hr style="margin:6px 0; border-color:#eee;">
        <div style="font-size:14px; line-height:1.5;">
          <b>📍 소재지지번주소:</b> ${item.lnmadr || '-'}<br>
          <b>📌 상세위치:</b> ${item.descLc || '-'}<br>
          <b>🛡️ 보호틀유무:</b> ${item.prtcYn === 'Y' ? '있음' : (item.prtcYn === 'N' ? '없음' : '-')}<br>
          <b>🏢 관할기관명:</b> ${item.institutionNm || '-'}<br>
          <b>📞 전화번호:</b> ${item.institutionPhoneNumber || '-'}<br>
          <b>📅 데이터기준일자:</b> ${item.referenceDate || '-'}
        </div>
      </div>
    `;
  } else if (type === 'firetruck') {
     iwContent = `
       <div style="padding:5px;">
         🚒 <b>소방차 전용구역</b>
         <hr style="margin:4px 0;">
          <div style="font-size:14px; line-height:1.5;">
            <b>📍 소재지지번주소:</b> ${item.lnmadr || '-'}<br>
            <b>🅿️ 전용주차구획:</b> ${item.prkcmprt || '-'}개<br>
            <b>🏢 공동주택명:</b> ${item.copertnHouseNm || '-'}<br>
            <b>🔢 동번호:</b> ${item.dongNo || '-'}<br>
            <b>📞 관리소 연락처:</b> ${item.aphusPhoneNumber || '-'}<br>
            <b>🚒 관할소방서:</b> ${item.institutionNm || '-'}<br>
            <b>☎️ 소방서 전화:</b> ${item.institutionPhoneNumber || '-'}<br>
            <b>📅 데이터 기준일:</b> ${item.referenceDate || '-'}
          </div>
          <div style="margin-top:8px; text-align:right;">
            <button id="reportBtn">신고</button>
          </div>
        </div>
      `;
    } else if (type === 'problem') {
    iwContent = `
      <div style="padding:5px;">
        <b>통행불가 위치</b><br>${contents}
      </div>
    `;
  } else if (type === 'breakdown') {
    iwContent = `
      <div style="padding:5px;">
        <b>고장/이상 위치</b><br>${contents}
      </div>
    `;
  } else if (type === 'hydrantAdd') {
    iwContent = `
      <div style="padding:5px;">
        <b>소화전 추가 요청</b><br>${contents}
      </div>
    `;
  } else if (type === 'truckAdd') {
    iwContent = `
      <div style="padding:5px;">
        <b>소방차구역 추가 요청</b><br>${contents}
      </div>
    `;
  } else {
    iwContent = `
      <div style="padding:5px;">
        ${contents}
      </div>
    `;
  }

  const iwPosition = new kakao.maps.LatLng(latitude, longitude);
  infoWindow = new kakao.maps.InfoWindow({
    map: map,
    position: iwPosition,
    content: iwContent,
    removable: true
  });
  infoWindow.open(map, marker);

  // 코멘트창 띄우기
  if (type === 'hydrant') {
    showHydrantCommentOverlay(latitude, longitude, `
      <div style="background:#fff3cd;border:1px solid #ffeeba;padding:10px 18px;border-radius:8px;font-size:15px;box-shadow:0 2px 8px #aaa;">
        💬 이 소화전에 대한 의견을 남겨주세요
      </div>
      <div>
        <button>추가</button>
        <button>수정</button>
        <button>삭제</button>
      </div>
    `);
  } else if (type === 'firetruck') {
    showFiretruckCommentOverlay(latitude, longitude, `
      <div style="background:#d9edf7;border:1px solid #bce8f1;padding:10px 18px;border-radius:8px;font-size:15px;box-shadow:0 2px 8px #aaa;">
        🚒 이 소방차 전용구역에 대한 의견을 남겨주세요
      </div>
      <div>
        <button>추가</button>
        <button>수정</button>
        <button>삭제</button>
      </div>
    `);
  }


  // closeclick 이벤트 리스너 등록 (X 버튼 클릭 시)
  kakao.maps.event.addListener(infoWindow, 'closeclick', function () {
    if (hydrantcommentOverlay) hydrantcommentOverlay.setMap(null);
    if (firetruckcommentOverlay) firetruckcommentOverlay.setMap(null);
      infoWindow = null;
    });

  // 타입별 버튼 이벤트 연결
  setTimeout(() => {
    if (type === 'hydrant') {
      const editBtn = document.getElementById('editBtn');
      const deleteBtn = document.getElementById('deleteBtn');
      if (editBtn) editBtn.onclick = function() {
        infoWindow.close();
        onEditMarker(markerId, latitude, longitude);
      };
      if (deleteBtn) deleteBtn.onclick = function() {
        infoWindow.close();
        onDeleteMarker(markerId, latitude, longitude);
      };
    }
    if (type === 'firetruck') {
      const reportBtn = document.getElementById('reportBtn');
      if (reportBtn) reportBtn.onclick = function() {
        infoWindow.close();
        onReportFiretruck(markerId, latitude, longitude);
      };
    }
    if (type === 'problem') {
      const problemBtn = document.getElementById('problemBtn');
      if (problemBtn) problemBtn.onclick = function() {
        infoWindow.close();
        onReportProblem(markerId, latitude, longitude);
      };
    }
    if (type === 'breakdown') {
      const breakdownBtn = document.getElementById('breakdownBtn');
      if (breakdownBtn) breakdownBtn.onclick = function() {
        infoWindow.close();
        onReportBreakdown(markerId, latitude, longitude);
      };
    }
    if (type === 'hydrantAdd') {
      const approveBtn = document.getElementById('approveBtn');
      const rejectBtn = document.getElementById('rejectBtn');
      if (approveBtn) approveBtn.onclick = function() {
        infoWindow.close();
        onApproveHydrantAdd(markerId, latitude, longitude);
      };
      if (rejectBtn) rejectBtn.onclick = function() {
        infoWindow.close();
        onRejectHydrantAdd(markerId, latitude, longitude);
      };
    }
    if (type === 'truckAdd') {
      const approveBtn = document.getElementById('approveTruckBtn');
      const rejectBtn = document.getElementById('rejectTruckBtn');
      if (approveBtn) approveBtn.onclick = function() {
        infoWindow.close();
        onApproveTruckAdd(markerId, latitude, longitude);
      };
      if (rejectBtn) rejectBtn.onclick = function() {
        infoWindow.close();
        onRejectTruckAdd(markerId, latitude, longitude);
      };
    }
  }, 100);
}

function showHydrantCommentOverlay(lat, lng, contentHtml) {
  // 기존 코멘트창 닫기
  if (hydrantcommentOverlay) hydrantcommentOverlay.setMap(null);

  // 새 코멘트창 생성
  hydrantcommentOverlay = new kakao.maps.CustomOverlay({
    position: new kakao.maps.LatLng(lat, lng),
    content: contentHtml,
    yAnchor: 0.1,  // 마커 위쪽에 위치
    xAnchor: 0.5,
    zIndex: 20
  });
  hydrantcommentOverlay.setMap(map);
}

function showFiretruckCommentOverlay(lat, lng, contentHtml) {

    if(firetruckcommentOverlay) firetruckcommentOverlay.setMap(null);

    firetruckcommentOverlay = new kakao.maps.CustomOverlay({
        position: new kakao.maps.LatLng(lat, lng),
        content : contentHtml,
        yAnchor: 0.1,
        xAnchor: 0.5,
        zIndex : 20
    });
    firetruckcommentOverlay.setMap(map);
}



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
  if (!map) return;
  const level = map.getLevel();
  console.log('📏 현재 지도 레벨:', level);
}

function searchPlaces(keyword) {
  if (!ps) return console.warn("검색 객체 초기화 안됨");
  infoWindow = new kakao.maps.InfoWindow({ zIndex: 1 });

  ps.keywordSearch(keyword, function (data, status, pagination) {
    if (status === kakao.maps.services.Status.OK) {
      clearMarker();
      const bounds = new kakao.maps.LatLngBounds();
      data.forEach(place => {
        bounds.extend(new kakao.maps.LatLng(place.y, place.x));
      });
      map.setBounds(bounds);
      map.setLevel(5);
      if (data.length > 0) {
        const firstPlace = data[0];
        map.panTo(new kakao.maps.LatLng(firstPlace.y, firstPlace.x));
      }
    } else {
      console.warn("검색 실패 또는 결과 없음:", status);
    }
  });
}

function moveToCurrentLocation(lat, lng) {
  if (map) {
    map.panTo(new kakao.maps.LatLng(lat, lng));
    if (marker) marker.setPosition(new kakao.maps.LatLng(lat, lng));
  }
}

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

// ✅ 이 시점에 SDK가 로드됐을 때만 지도 초기화
window.onload = function () {
  kakao.maps.load(function () {
    const container = document.getElementById('map');
    const options = {
      center: new kakao.maps.LatLng(37.3626138, 126.9264801),
      level: 5
    };
    map = new kakao.maps.Map(container, options);

    ps = new kakao.maps.services.Places();
    infoWindow = new kakao.maps.InfoWindow({ zIndex: 1 });

    clusterer = new kakao.maps.MarkerClusterer({
      map: map,
      averageCenter: true,
      minLevel: 5
    });

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
        zoomLevel: map.getLevel()
      };
      if (typeof cameraIdle !== 'undefined') {
        cameraIdle.postMessage(JSON.stringify(idleLatLng));
      }
    });

    if (window.flutterWebViewReady) {
      window.flutterWebViewReady.postMessage("map_ready");
    }
  });
};

function empty(value) {
  return (
    value === null ||
    value === undefined ||
    (typeof value === 'string' && (value.trim() === '' || value === 'null')) ||
    (Array.isArray(value) && value.length === 0) ||
    (typeof value === 'object' && Object.keys(value).length === 0)
  );
}
