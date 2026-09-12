// Isla de clima del rice — se abre con click en el módulo custom/clima de waybar.
// Lee ~/.cache/waybar-clima/state.json (lo genera ClimaClock.sh) y colors.json (matugen).
// Cierra al salir el mouse, con Esc, con click, o a los 15 s.
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

    property var state: ({})
    property bool ready: false

    // ---------- ventana ----------
    anchors { top: true; left: true }
    margins { top: 44; left: 10 }
    implicitWidth: 390
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

    // ---------- datos ----------
    FileView {
        id: stateFile
        path: root.cacheDir + "/state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseState()
    }
    function parseState() {
        try {
            root.state = JSON.parse(stateFile.text());
            root.ready = true;
        } catch (e) {}
    }

    // refresca al abrir (respeta el TTL interno del script)
    Process {
        running: true
        command: ["bash", root.home + "/.config/hypr/UserScripts/ClimaClock.sh"]
    }

    // ---------- helpers ----------
    function j(path, dflt) {
        let o = root.state;
        for (const k of path.split(".")) {
            if (o === undefined || o === null) return dflt;
            o = o[k];
        }
        return (o === undefined || o === null) ? dflt : o;
    }
    function tC(x) { return (x === undefined || x === null) ? "--" : Math.round(x) + "°"; }
    function hm(iso) { return iso ? String(iso).split("T")[1].slice(0, 5) : "--:--"; }

    // ---------- autocierre ----------
    Timer { id: leaveTimer; interval: 1800; onTriggered: Qt.quit() }
    Timer { interval: 15000; running: true; onTriggered: Qt.quit() }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 36
        radius: 18
        color: c.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        focus: true
        Keys.onEscapePressed: Qt.quit()

        // sólo autocierra por "mouse fuera" DESPUÉS de que el mouse entró al menos una vez
        // (si no, se cerraría sola al abrirla desde la barra antes de llegar con el cursor)
        property bool everHovered: false
        HoverHandler {
            onHoveredChanged: {
                if (hovered) { card.everHovered = true; leaveTimer.stop(); }
                else if (card.everHovered) leaveTimer.restart();
            }
        }
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 18 }
            spacing: 12

            // ----- cabecera: reloj + fecha -----
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: root.j("clock", "--:--")
                    color: c.primary
                    font.pixelSize: 30
                    font.weight: Font.Black
                    font.family: "JetBrainsMono Nerd Font"
                }
                Text {
                    text: root.j("date_header", "")
                    color: c.fgDim
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- clima local -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Text {
                    text: root.j("home.icon", "")
                    color: root.j("home.hex", c.secondary)
                    font.pixelSize: 46
                    font.family: "JetBrainsMono Nerd Font"
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 8
                        Text {
                            text: root.tC(root.j("home.wx.current.temperature_2m", null))
                            color: c.fg
                            font.pixelSize: 34
                            font.weight: Font.Black
                        }
                        Text {
                            text: root.j("home.desc", "")
                            color: c.fgDim
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 4
                        }
                    }
                    Text {
                        text: {
                            const g = root.j("home.geo", {});
                            return (g.city || "?") + (g.country ? ", " + g.country : "");
                        }
                        color: c.fgDim
                        font.pixelSize: 11
                    }
                }
            }

            GridLayout {
                columns: 2
                columnSpacing: 18
                rowSpacing: 4
                Layout.fillWidth: true
                Text {
                    text: "  ↑ " + root.tC(root.j("home.wx.daily.temperature_2m_max.0", null))
                          + "   ↓ " + root.tC(root.j("home.wx.daily.temperature_2m_min.0", null))
                    color: c.fg; font.pixelSize: 12
                }
                Text {
                    text: "  " + Math.round(root.j("home.wx.current.relative_humidity_2m", 0)) + "% hum"
                    color: c.fg; font.pixelSize: 12
                }
                Text {
                    text: "  " + Math.round(root.j("home.wx.current.wind_speed_10m", 0)) + " km/h"
                    color: c.fg; font.pixelSize: 12
                }
                Text {
                    text: "  ST " + root.tC(root.j("home.wx.current.apparent_temperature", null))
                    color: c.fg; font.pixelSize: 12
                }
                Text {
                    text: "  " + root.hm(root.j("home.wx.daily.sunrise.0", "")) + " ↑sol"
                    color: c.fgDim; font.pixelSize: 12
                }
                Text {
                    text: "  " + root.hm(root.j("home.wx.daily.sunset.0", "")) + " ↓sol"
                    color: c.fgDim; font.pixelSize: 12
                }
            }

            // ----- 2ª ciudad -----
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
                visible: root.j("city.wx", null) !== null
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.j("city.wx", null) !== null
                Text {
                    text: {
                        const g = root.j("city.geo", {});
                        return g.city || "?";
                    }
                    color: c.fg; font.pixelSize: 13; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Text {
                    text: root.tC(root.j("city.wx.current.temperature_2m", null))
                    color: c.fg; font.pixelSize: 13
                }
                Text {
                    text: root.hm(root.j("city.wx.daily.sunrise.0", "")) + " / "
                          + root.hm(root.j("city.wx.daily.sunset.0", ""))
                    color: c.fgDim; font.pixelSize: 11
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- luna -----
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: root.j("moon.label", "🌙 Luna") + "   "
                          + Math.round(root.j("moon.illum", 0)) + "%  "
                          + (root.j("moon.waxing", true) ? "(creciente)" : "(menguante)")
                    color: c.tertiary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text {
                    text: {
                        const alt = root.j("moon.alt", -99);
                        const dir = root.j("moon.dir", "");
                        const tr = root.j("moon.trend", "");
                        let s = (alt > 0) ? (Math.round(alt) + "° sobre el horizonte") : "bajo el horizonte";
                        if (dir) s += " · rumbo " + dir;
                        if (tr) s += " · " + tr;
                        return s;
                    }
                    color: c.fgDim
                    font.pixelSize: 12
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- eventos -----
            ColumnLayout {
                spacing: 3
                Layout.fillWidth: true
                Text {
                    text: "📌 Hoy"
                    color: c.secondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Repeater {
                    model: {
                        const ev = root.j("events", []);
                        return (ev && ev.length) ? ev : [];
                    }
                    Text {
                        required property var modelData
                        text: "  " + modelData
                        color: c.fg
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
                Text {
                    visible: !(root.j("events", []).length)
                    text: "  sin calendario configurado"
                    color: c.fgDim
                    font.pixelSize: 12
                    font.italic: true
                }
            }
        }
    }
}
