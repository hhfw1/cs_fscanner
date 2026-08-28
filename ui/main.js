const State = {
    isScanning: false,
    history: [],
    currentProfile: null,
    isTarget: false,
    isDragging: false
};

const $app = $('#app');
const $dragBtn = $('#drag-handle-btn');
const $dragInfo = $('#drag-info-text');

const loadSavedPosition = () => {
    const savedPos = localStorage.getItem('fp_scanner_pos');
    if (savedPos) {
        try {
            const pos = JSON.parse(savedPos);
            $app.css({
                left: pos.left,
                top: pos.top,
                transform: 'none'
            });
        } catch (e) {}
    }
};

loadSavedPosition();

const stopDragging = () => {
    State.isDragging = false;
    $app.removeClass('is-dragging');
    $dragInfo.addClass('hidden');

    const offset = $app.offset();
    const posData = {
        left: offset.left + 'px',
        top: offset.top + 'px'
    };
    localStorage.setItem('fp_scanner_pos', JSON.stringify(posData));
};

$dragBtn.on('click', function (e) {
    e.stopPropagation();
    if (!State.isDragging) {
        State.isDragging = true;
        $app.addClass('is-dragging');
        $dragInfo.removeClass('hidden');
    } else {
        stopDragging();
    }
});

$(document).on('mousedown', function (e) {
    if (!State.isDragging) return;
    if ($(e.target).is($dragBtn)) return;
    stopDragging();
});

$(document).on('mousemove', function (e) {
    if (!State.isDragging) return;

    const appWidth = $app.outerWidth();
    const appHeight = $app.outerHeight();

    let newX = e.clientX - (appWidth / 2);
    let newY = e.clientY - (appHeight * 0.895);

    newX = Math.max(10, Math.min(window.innerWidth - appWidth - 10, newX));
    newY = Math.max(10, Math.min(window.innerHeight - appHeight - 10, newY));

    $app.css({
        left: newX + 'px',
        top: newY + 'px',
        transform: 'none'
    });
});

const switchView = (targetId) => {
    if (State.isScanning) return;

    $('.nav-btn').each(function () {
        $(this).toggleClass('active', $(this).data('target') === targetId);
    });

    $('.view').each(function () {
        if ($(this).attr('id') === targetId) {
            $(this).removeClass('hidden').addClass('active');
        } else {
            $(this).addClass('hidden').removeClass('active');
        }
    });
};

const showNotification = (msg) => {
    $('#notification').text(msg).removeClass('hidden');
    setTimeout(() => {
        $('#notification').addClass('hidden');
    }, 2000);
};

function copyToClipboard(text) {
    if (!text || text === "---") return;
    var textArea = document.createElement("textarea");
    textArea.value = text;

    textArea.style.top = "0";
    textArea.style.left = "0";
    textArea.style.position = "fixed";

    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        document.execCommand("copy");
        showNotification("Copied");
    } catch (err) {
        showNotification("Unable to copy");
    }

    document.body.removeChild(textArea);
}

const renderResult = (data) => {
    $('#res-id').text(data.id || "UNKNOWN");
    $('#res-name').text(data.name || "UNKNOWN");
    $('#res-dob').text(data.dob || "UNKNOWN");
    $('#res-gender').text(data.gender || "UNKNOWN");
    if (data.image) {
        $('#res-image').attr('src', data.image);
    }
};

const renderLogs = () => {
    const $logList = $('#log-list').empty();
    State.history.forEach((log) => {
        const $entry = $(`
            <div class="log-entry">
                <span>${log.name}</span>
                <span class="log-id">${log.id}</span>
            </div>
        `);

        $entry.on('click', function () {
            if (!State.isTarget && !State.isDragging) {
                renderResult(log);
                switchView('view-result');
            }
        });

        $logList.append($entry);
    });
};

const addLog = (data) => {
    State.history.unshift(data);
    if (State.history.length > 10) State.history.pop();
    renderLogs();
};

const closeUI = () => {
    $app.addClass('hidden');
    $('#lock-screen').removeClass('fade-out');
    $('#physical-scan-btn').removeClass('scanning-active');
    $('#scan-laser').addClass('hidden');
    switchView('view-scan');
    State.isScanning = false;
    State.isTarget = false;

    if (State.isDragging) {
        State.isDragging = false;
        $app.removeClass('is-dragging');
        $dragInfo.addClass('hidden');
    }

    $.post(`https://${GetParentResourceName()}/closeUI`);
};

$('#physical-scan-btn').on('click', function (e) {
    if (State.isDragging) return;
    if (State.isScanning) return;

    const isScanViewActive = $('#view-scan').hasClass('active') && !$('#view-scan').hasClass('hidden');
    if (!isScanViewActive) return;

    if (State.isTarget) {
        $(this).addClass('scanning-active');
        $.post(`https://${GetParentResourceName()}/targetConfirmScan`);
    } else {
        if (!$('#lock-screen').hasClass('fade-out')) return;
        $.post(`https://${GetParentResourceName()}/startScan`);
    }
});

$('#lock-screen').on('click', function () {
    if (!State.isTarget && !State.isDragging) {
        $(this).addClass('fade-out');
    }
});

$('.nav-btn').on('click', function () {
    if (!State.isTarget && !State.isDragging) {
        switchView($(this).data('target'));
    }
});

$('#res-id').on('click', function () {
    if (!State.isDragging) {
        const fingerID = $(this).text().trim().replace(/\s/g, "").replace("ClickToCopy", "");
        copyToClipboard(fingerID);
    }
});

$('#btn-clear-logs').on('click', function () {
    if (!State.isTarget && !State.isDragging) {
        State.history = [];
        renderLogs();
    }
});

$(document).on('keydown', function (e) {
    if (e.key === 'Escape' && !State.isScanning && !$app.hasClass('hidden')) {
        closeUI();
    }
});

window.addEventListener('message', function (event) {
    const data = event.data;

    switch (data.action) {
        case 'openScanner':
            State.isTarget = data.isTarget || false;
            $app.removeClass('hidden');

            if (State.isTarget) {
                $('#lock-screen').addClass('fade-out');
                $('.screen-nav').addClass('hidden');
                $('#drag-handle-btn').addClass('hidden');
                $dragInfo.addClass('hidden');
                switchView('view-scan');
                $('#scan-status')
                    .text("TOUCH SENSOR TO SCAN")
                    .removeClass('text-muted')
                    .addClass('text-success');
            } else {
                $('.screen-nav').removeClass('hidden');
                $('#drag-handle-btn').removeClass('hidden');
                $('#scan-status')
                    .text("AWAITING FINGERPRINT")
                    .addClass('text-muted')
                    .removeClass('text-success');
            }
            break;

        case 'setScanningAnimation':
            State.isScanning = true;
            switchView('view-scan');
            $('#physical-scan-btn').addClass('scanning-active');
            $('#scan-laser').removeClass('hidden');
            $('#scan-status')
                .text("ANALYZING FINGERPRINT...")
                .removeClass('text-muted')
                .addClass('text-success');
            break;

        case 'showResult':
            State.isScanning = false;
            $('#physical-scan-btn').removeClass('scanning-active');
            $('#scan-laser').addClass('hidden');
            $('#scan-status')
                .text("AWAITING FINGERPRINT")
                .addClass('text-muted')
                .removeClass('text-success');

            State.currentProfile = data.profile;
            renderResult(data.profile);
            addLog(data.profile);
            switchView('view-result');
            break;

        case 'close':
            closeUI();
            break;
    }
});