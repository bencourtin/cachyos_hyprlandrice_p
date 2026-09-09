// Isla de reproductores del rice — se abre con click en el now-playing de waybar
// (módulo custom/playerctl → MediaIsland.sh). Lista todos los players MPRIS
// (Spotify, Firefox, mpv, …) y deja pausar/reanudar cada uno por separado.
// Cierra al salir el mouse, con Esc, o a los 20 s. Colores: colors.json (matugen).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // lista viva de reproductores
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property int playerCount: players.length

    // ---------- ventana ----------
    // Alineada al borde izquierdo de la píldora del reproductor en la barra
    // (medido con el layout actual: clima + tray de 2 iconos). Si cambia la
    // cantidad de iconos del tray, reajustar margins.left.
    anchors { top: true; left: true }
    margins { top: 44; left: 180 }
    implicitWidth: 340
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

    // ---------- helpers ----------
    function glyphFor(identity) {
        const s = (identity || "").toLowerCase();
        if (s.indexOf("spotify") !== -1) return "";        //
        if (s.indexOf("firefox") !== -1 || s.indexOf("librewolf") !== -1
            || s.indexOf("zen") !== -1) return "";         //
        if (s.indexOf("chrom") !== -1 || s.indexOf("brave") !== -1
            || s.indexOf("vivaldi") !== -1) return "";     //
        if (s.indexOf("mpv") !== -1) return "󰔜";      // 󰐜
        if (s.indexOf("vlc") !== -1) return "󰵼";      // 󰕼
        return "󰝚";                                   // 󰝚
    }
    function prettyName(p) {
        if (p.identity && p.identity.length) return p.identity;
        return (p.dbusName || "").replace("org.mpris.MediaPlayer2.", "");
    }
    function subtitle(p) {
        const t = p.trackTitle || "";
        const a = p.trackArtist || "";
        if (t && a) return a + " – " + t;
        if (t) return t;
        return p.isPlaying ? "reproduciendo" : "en pausa";
    }
    function toggle(p) {
        if (p.canTogglePlaying) p.togglePlaying();
        else if (p.isPlaying) p.pause();
        else p.play();
    }
    function pauseAll() {
        for (const p of root.players) if (p.canPause || p.canControl) p.pause();
    }
    function pauseOthers() {
        let keep = null;
        for (const p of root.players) if (p.isPlaying) { keep = p; break; }
        for (const p of root.players) if (p !== keep && (p.canPause || p.canControl)) p.pause();
    }

    // ---------- autocierre ----------
    Timer { id: leaveTimer; interval: 2000; onTriggered: Qt.quit() }
    Timer { interval: 20000; running: true; onTriggered: Qt.quit() }

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

            // ----- cabecera -----
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Reproductores"
                    color: c.primary
                    font.pixelSize: 15
                    font.weight: Font.Black
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.fillWidth: true
                }
                Text {
                    text: root.playerCount
                    color: c.fgDim
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- sin reproductores -----
            Text {
                visible: root.playerCount === 0
                text: "No hay nada sonando ahora."
                color: c.fgDim
                font.pixelSize: 12
                font.italic: true
                Layout.fillWidth: true
            }

            // ----- filas por reproductor -----
            Repeater {
                model: root.players
                delegate: Rectangle {
                    id: rowBg
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: rowLay.implicitHeight + 16
                    radius: 12
                    color: rowHover.hovered ? c.surfaceContainerHigh : "transparent"

                    HoverHandler { id: rowHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggle(rowBg.modelData)
                    }

                    RowLayout {
                        id: rowLay
                        anchors { fill: parent; leftMargin: 10; rightMargin: 12; topMargin: 8; bottomMargin: 8 }
                        spacing: 12

                        Text {
                            // mismo criterio que el botón toggle de la barra:
                            // suena → glifo "pausar"; en pausa → glifo "reanudar"
                            text: rowBg.modelData.isPlaying ? "󰏤" : "󰐊"
                            color: rowBg.modelData.isPlaying ? c.primary : c.fgDim
                            font.pixelSize: 22
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: root.glyphFor(rowBg.modelData.identity)
                                    color: c.secondary
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    text: root.prettyName(rowBg.modelData)
                                    color: c.fg
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                            Text {
                                text: root.subtitle(rowBg.modelData)
                                color: c.fgDim
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: rowBg.modelData.isPlaying ? "pausar" : "reanudar"
                            color: c.fgDim
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            // ----- acciones globales -----
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
                visible: root.playerCount > 1
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.playerCount > 1

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 10
                    color: b1h.hovered ? c.surfaceContainerHigh : c.surface
                    HoverHandler { id: b1h }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pauseOthers() }
                    Text {
                        anchors.centerIn: parent
                        text: "Pausar los demás"
                        color: c.fg; font.pixelSize: 11; font.weight: Font.DemiBold
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 10
                    color: b2h.hovered ? c.surfaceContainerHigh : c.surface
                    HoverHandler { id: b2h }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pauseAll() }
                    Text {
                        anchors.centerIn: parent
                        text: "Pausar todo"
                        color: c.fg; font.pixelSize: 11; font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
