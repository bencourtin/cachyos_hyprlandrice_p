// Isla de calendario del rice — se abre con SUPER+SHIFT+C (o el toggle
// CalendarIsland.sh). Grilla mensual con hoy resaltado, navegación ‹ ›, y una
// tira de clima de hoy leída de ~/.cache/waybar-clima/state.json (la escribe
// ClimaClock.sh; si no está, la tira no aparece).
// Cierra: Esc, mouse fuera 2.5 s (tras haber entrado), o 60 s hard.
// Colores: colors.json (matugen, mismas claves que la isla de clima).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: {
        const xc = Quickshell.env("XDG_CACHE_HOME");
        return (xc && xc.length ? xc : home + "/.cache") + "/waybar-clima";
    }

    // offset de mes respecto al actual (0 = mes de hoy)
    property int monthOffset: 0
    // se recalcula a medianoche para que "hoy" no quede viejo si la isla queda abierta
    property var today: new Date()

    // ---------- ventana ----------
    anchors { top: true; left: true }
    margins { top: 44; left: 10 }
    implicitWidth: 320
    implicitHeight: card.implicitHeight
    color: "transparent"
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // ---------- colores (matugen) ----------
    FileView {
        path: Qt.resolvedUrl("colors.json").toString().replace("file://", "")
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: c
            property string surface: "#0f1417"
            property string surfaceContainer: "#1b2023"
            property string surfaceContainerHigh: "#262b2e"
            property string fg: "#dfe3e7"
            property string fgDim: "#c0c8cd"
            property string primary: "#8bd0ef"
            property string secondary: "#b4cad6"
            property string tertiary: "#c6c2ea"
            property string outline: "#8a9297"
        }
    }

    // ---------- clima de hoy (opcional) ----------
    property var wx: ({})
    property bool wxReady: false
    FileView {
        id: wxFile
        path: root.cacheDir + "/state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.wx = JSON.parse(wxFile.text()); root.wxReady = true; } catch (e) {}
        }
    }
    function wj(path, dflt) {
        let o = root.wx;
        for (const k of path.split(".")) {
            if (o === undefined || o === null) return dflt;
            o = o[k];
        }
        return (o === undefined || o === null) ? dflt : o;
    }
    function tC(x) { return (x === undefined || x === null) ? "--" : Math.round(x) + "°"; }

    // ---------- fechas ----------
    readonly property var esLocale: Qt.locale("es_CL")
    readonly property var weekdays: ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]

    function cap(s) { return s && s.length ? s[0].toUpperCase() + s.slice(1) : s; }

    // primer día del mes mostrado
    function monthBase() {
        return new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1);
    }

    function monthTitle() {
        return root.cap(root.monthBase().toLocaleDateString(root.esLocale, "MMMM 'de' yyyy"));
    }
    function todayLong() {
        return root.cap(root.today.toLocaleDateString(root.esLocale, "dddd d 'de' MMMM"));
    }

    // 42 celdas (6 semanas), lunes primero
    function buildGrid() {
        const base = root.monthBase();
        const year = base.getFullYear();
        const month = base.getMonth();
        const firstDow = (base.getDay() + 6) % 7;                 // lun=0
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrev = new Date(year, month, 0).getDate();
        const n = root.today;
        const cells = [];
        for (let i = 0; i < 42; i++) {
            const dayNum = i - firstDow + 1;
            let d, thisMonth;
            if (dayNum < 1) { d = daysInPrev + dayNum; thisMonth = false; }
            else if (dayNum > daysInMonth) { d = dayNum - daysInMonth; thisMonth = false; }
            else { d = dayNum; thisMonth = true; }
            const isToday = thisMonth
                && year === n.getFullYear() && month === n.getMonth() && d === n.getDate();
            cells.push({ day: d, thisMonth: thisMonth, isToday: isToday, weekend: (i % 7) >= 5 });
        }
        return cells;
    }
    property var grid: buildGrid()
    onMonthOffsetChanged: grid = buildGrid()
    onTodayChanged: grid = buildGrid()

    // refresco de "hoy" a medianoche
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: {
            const now = new Date();
            if (now.getDate() !== root.today.getDate()) root.today = now;
        }
    }

    // ---------- autocierre ----------
    Timer { id: leaveTimer; interval: 2500; onTriggered: Qt.quit() }
    Timer { interval: 60000; running: true; onTriggered: Qt.quit() }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 32
        radius: 18
        color: c.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        focus: true
        Keys.onEscapePressed: Qt.quit()
        Keys.onLeftPressed: root.monthOffset--
        Keys.onRightPressed: root.monthOffset++
        Keys.onUpPressed: root.monthOffset = 0
        Keys.onDownPressed: root.monthOffset = 0
        Keys.onPressed: (e) => { if (e.key === Qt.Key_T || e.key === Qt.Key_Home) root.monthOffset = 0; }

        property bool everHovered: false
        HoverHandler {
            onHoveredChanged: {
                if (hovered) { card.everHovered = true; leaveTimer.stop(); }
                else if (card.everHovered) leaveTimer.restart();
            }
        }

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 16 }
            spacing: 10

            // ----- cabecera: mes + navegación -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.monthTitle()
                    color: c.primary
                    font.pixelSize: 17
                    font.weight: Font.Black
                    Layout.fillWidth: true
                }

                Text {
                    text: "hoy"
                    visible: root.monthOffset !== 0
                    color: c.fgDim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    padding: 4
                    TapHandler { onTapped: root.monthOffset = 0 }
                }

                Repeater {
                    model: [{ g: "‹", d: -1 }, { g: "›", d: 1 }]
                    Rectangle {
                        required property var modelData
                        width: 24; height: 24; radius: 12
                        color: navHover.hovered ? c.surfaceContainerHigh : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.g
                            color: c.fg
                            font.pixelSize: 16
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        HoverHandler { id: navHover }
                        TapHandler { onTapped: root.monthOffset += parent.modelData.d }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- días de la semana -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: root.weekdays
                    Text {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index >= 5 ? c.tertiary : c.fgDim
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            // ----- grilla del mes -----
            Grid {
                id: dayGrid
                Layout.fillWidth: true
                columns: 7
                readonly property real cell: (col.width - 0) / 7

                Repeater {
                    model: root.grid
                    Rectangle {
                        required property var modelData
                        width: dayGrid.cell
                        height: 30
                        radius: 9
                        color: modelData.isToday ? c.primary : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            font.pixelSize: 12
                            font.weight: modelData.isToday ? Font.Black : Font.Normal
                            color: modelData.isToday
                                   ? c.surface
                                   : (!modelData.thisMonth ? Qt.rgba(1, 1, 1, 0.20)
                                      : (modelData.weekend ? c.tertiary : c.fg))
                        }
                    }
                }
            }

            // ----- pie: fecha larga + clima de hoy -----
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            Text {
                text: root.todayLong()
                color: c.secondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.wxReady && root.wj("home.wx.current.temperature_2m", null) !== null
                Text {
                    text: root.wj("home.icon", "")
                    color: root.wj("home.hex", c.secondary)
                    font.pixelSize: 20
                    font.family: "JetBrainsMono Nerd Font"
                }
                Text {
                    text: root.tC(root.wj("home.wx.current.temperature_2m", null))
                    color: c.fg
                    font.pixelSize: 14
                    font.weight: Font.Black
                }
                Text {
                    text: root.wj("home.desc", "")
                    color: c.fgDim
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: "↑ " + root.tC(root.wj("home.wx.daily.temperature_2m_max.0", null))
                          + "  ↓ " + root.tC(root.wj("home.wx.daily.temperature_2m_min.0", null))
                    color: c.fgDim
                    font.pixelSize: 11
                }
            }
        }
    }
}
