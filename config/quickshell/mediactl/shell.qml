// Isla de reproductores del rice — se abre con click en el now-playing de waybar
// (módulo custom/playerctl → MediaIsland.sh).
//
// v2 (2026-09-10): además de la lista de players MPRIS, muestra el player activo
// en grande: carátula, fondo blureado con la propia arte, barra de progreso con
// scrub (arrastrar para saltar) y controles ⏮ ⏯ ⏭. Click en una fila de la lista
// = pasar a controlar ese player. "Pausar los demás / todo" siguen abajo.
// Cierra al salir el mouse, con Esc, o a los 30 s. Colores: colors.json (matugen).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

PanelWindow {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // lista viva de reproductores
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property int playerCount: players.length

    // player que se controla en grande
    property int activeIdx: 0
    readonly property var active: (root.players.length > 0)
        ? (root.players[Math.min(root.activeIdx, root.players.length - 1)] || null)
        : null
    readonly property string artUrl: (root.active && root.active.trackArtUrl) ? root.active.trackArtUrl : ""

    // posición reproducida (MprisPlayer.position no "tickea" solo)
    property real livePos: 0
    function syncPos() { root.livePos = root.active ? (root.active.position || 0) : 0; }

    function pickActive() {
        for (let i = 0; i < root.players.length; i++)
            if (root.players[i].isPlaying) { root.activeIdx = i; return; }
        root.activeIdx = 0;
    }
    Component.onCompleted: { pickActive(); syncPos(); }
    onPlayerCountChanged: { pickActive(); syncPos(); }
    onActiveChanged: syncPos()

    Timer {
        interval: 1000; repeat: true
        running: root.active && root.active.isPlaying
        onTriggered: {
            if (root.active && root.active.positionChanged) root.active.positionChanged();
            root.syncPos();
        }
    }

    // ---------- ventana ----------
    // Alineada al borde izquierdo de la píldora del reproductor en la barra
    // (medido con el layout actual: clima + tray de 2 iconos). Si cambia la
    // cantidad de iconos del tray, reajustar margins.left.
    anchors { top: true; left: true }
    margins { top: 44; left: 180 }
    implicitWidth: 360
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
        if (s.indexOf("spotify") !== -1) return "";
        if (s.indexOf("firefox") !== -1 || s.indexOf("librewolf") !== -1
            || s.indexOf("zen") !== -1) return "";
        if (s.indexOf("chrom") !== -1 || s.indexOf("brave") !== -1
            || s.indexOf("vivaldi") !== -1) return "";
        if (s.indexOf("mpv") !== -1) return "󰔜";
        if (s.indexOf("vlc") !== -1) return "󰵼";
        return "󰝚";
    }
    function prettyName(p) {
        if (!p) return "";
        if (p.identity && p.identity.length) return p.identity;
        return (p.dbusName || "").replace("org.mpris.MediaPlayer2.", "");
    }
    function subtitle(p) {
        if (!p) return "";
        const t = p.trackTitle || "";
        const a = p.trackArtist || "";
        if (t && a) return a + " – " + t;
        if (t) return t;
        return p.isPlaying ? "reproduciendo" : "en pausa";
    }
    function toggle(p) {
        if (!p) return;
        if (p.canTogglePlaying) p.togglePlaying();
        else if (p.isPlaying) p.pause();
        else p.play();
    }
    function pauseAll() {
        for (const p of root.players) if (p.canPause || p.canControl) p.pause();
    }
    function pauseOthers() {
        const keep = root.active;
        for (const p of root.players) if (p !== keep && (p.canPause || p.canControl)) p.pause();
    }
    function fmt(sec) {
        sec = Math.max(0, Math.floor(sec || 0));
        const m = Math.floor(sec / 60), s = sec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ---------- autocierre ----------
    Timer { id: leaveTimer; interval: 2500; onTriggered: Qt.quit() }
    Timer { interval: 30000; running: true; onTriggered: Qt.quit() }

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

        // ----- fondo: arte blureada y atenuada, recortada al radio de la tarjeta -----
        // layer.enabled:true es necesario en los dos: un Item visible:false NO se
        // renderiza en absoluto por defecto (ni a una textura offscreen), así que
        // MultiEffect no tiene nada que muestrear y queda en blanco sin este flag.
        Rectangle { id: cardMask; anchors.fill: parent; radius: card.radius; visible: false; layer.enabled: true }
        Image {
            id: bgArt
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; cache: true
            visible: false
            layer.enabled: true
        }
        MultiEffect {
            anchors.fill: parent
            source: bgArt
            blurEnabled: true
            blur: 1.0
            blurMax: 40
            saturation: 0.15
            brightness: -0.10
            opacity: 0.20
            maskEnabled: true
            maskSource: cardMask
            visible: bgArt.status === Image.Ready
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

            // ===== player activo en grande =====
            RowLayout {
                Layout.fillWidth: true
                visible: root.active !== null
                spacing: 14

                // --- carátula ---
                Item {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 76; implicitHeight: 76
                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                        visible: false
                        layer.enabled: true
                    }
                    Rectangle { id: artMask; anchors.fill: parent; radius: 14; visible: false; layer.enabled: true }
                    MultiEffect {
                        anchors.fill: parent
                        source: artImg
                        maskEnabled: true
                        maskSource: artMask
                        visible: artImg.status === Image.Ready
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: c.surfaceContainerHigh
                        visible: artImg.status !== Image.Ready
                        Text {
                            anchors.centerIn: parent
                            text: root.glyphFor(root.active ? root.active.identity : "")
                            color: c.secondary
                            font.pixelSize: 30
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }

                // --- título / artista / controles ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: (root.active && root.active.trackTitle) ? root.active.trackTitle : "Sin título"
                        color: c.fg
                        font.pixelSize: 14
                        font.weight: Font.Black
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: (root.active && root.active.trackArtist) ? root.active.trackArtist : root.prettyName(root.active)
                        color: c.fgDim
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.topMargin: 6
                        spacing: 10
                        Repeater {
                            model: [
                                { g: "󰒮", act: "prev" },
                                { g: (root.active && root.active.isPlaying) ? "󰏤" : "󰐊", act: "toggle" },
                                { g: "󰒭", act: "next" }
                            ]
                            Rectangle {
                                required property var modelData
                                implicitWidth: modelData.act === "toggle" ? 34 : 28
                                implicitHeight: modelData.act === "toggle" ? 34 : 28
                                radius: width / 2
                                color: modelData.act === "toggle"
                                       ? c.primary
                                       : (btnHover.hovered ? c.surfaceContainerHigh : "transparent")
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.g
                                    color: parent.modelData.act === "toggle" ? c.surface : c.fg
                                    font.pixelSize: parent.modelData.act === "toggle" ? 17 : 15
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                HoverHandler { id: btnHover }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const p = root.active;
                                        if (!p) return;
                                        if (parent.modelData.act === "toggle") root.toggle(p);
                                        else if (parent.modelData.act === "prev") { if (p.canGoPrevious) p.previous(); }
                                        else { if (p.canGoNext) p.next(); }
                                        root.syncPos();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ----- barra de progreso -----
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.active !== null && (root.active.length || 0) > 0
                spacing: 3

                Item {
                    id: seek
                    Layout.fillWidth: true
                    implicitHeight: 16
                    readonly property real total: (root.active && root.active.length) ? root.active.length : 0
                    property bool dragging: false
                    property real dragFrac: 0
                    readonly property real frac: total > 0
                        ? Math.max(0, Math.min(1, dragging ? dragFrac : root.livePos / total))
                        : 0

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Qt.rgba(1, 1, 1, 0.14)
                        Rectangle {
                            width: parent.width * seek.frac
                            height: parent.height; radius: 2
                            color: c.primary
                        }
                    }
                    Rectangle {
                        width: 11; height: 11; radius: 6
                        color: c.primary
                        anchors.verticalCenter: parent.verticalCenter
                        x: (parent.width - width) * seek.frac
                        visible: root.active && root.active.canSeek
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: root.active && root.active.canSeek && seek.total > 0
                        cursorShape: Qt.PointingHandCursor
                        function fracAt(mx) { return Math.max(0, Math.min(1, mx / seek.width)); }
                        onPressed: (m) => { seek.dragging = true; seek.dragFrac = fracAt(m.x); }
                        onPositionChanged: (m) => { if (seek.dragging) seek.dragFrac = fracAt(m.x); }
                        onReleased: (m) => {
                            const f = fracAt(m.x);
                            if (root.active) root.active.position = f * seek.total;
                            root.livePos = f * seek.total;
                            seek.dragging = false;
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.fmt(seek.dragging ? seek.dragFrac * seek.total : root.livePos)
                        color: c.fgDim; font.pixelSize: 10
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.fmt(seek.total)
                        color: c.fgDim; font.pixelSize: 10
                    }
                }
            }

            // ===== lista de players (para cambiar de activo) =====
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
                visible: root.playerCount > 1
            }
            Repeater {
                model: root.playerCount > 1 ? root.players : []
                delegate: Rectangle {
                    id: rowBg
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: rowLay.implicitHeight + 12
                    radius: 10
                    color: rowBg.index === root.activeIdx
                           ? c.surfaceContainerHigh
                           : (rowHover.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

                    HoverHandler { id: rowHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.activeIdx = rowBg.index; root.syncPos(); }
                    }

                    RowLayout {
                        id: rowLay
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 6; bottomMargin: 6 }
                        spacing: 10

                        Text {
                            text: rowBg.modelData.isPlaying ? "󰏤" : "󰐊"
                            color: rowBg.modelData.isPlaying ? c.primary : c.fgDim
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            text: root.glyphFor(rowBg.modelData.identity)
                            color: c.secondary
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            text: root.prettyName(rowBg.modelData)
                            color: c.fg
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: rowBg.modelData.trackTitle || ""
                            color: c.fgDim
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ----- acciones globales -----
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8
                visible: root.playerCount > 1

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 10
                    color: b1h.hovered ? c.surfaceContainerHigh : Qt.rgba(1, 1, 1, 0.05)
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
                    color: b2h.hovered ? c.surfaceContainerHigh : Qt.rgba(1, 1, 1, 0.05)
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
