// Isla de mezcla de volumen del rice — se abre con click en el módulo de sonido
// de waybar (group/audio -> pulseaudio -> MixerIsland.sh).
//
// Usa el servicio nativo Quickshell.Services.Pipewire (sin pactl/pavucontrol):
// salida por defecto, entrada (mic) por defecto, y una fila por cada stream de
// aplicación (isStream + AudioOutStream, equivalente a un "sink-input" de
// pulseaudio) — eso es el mezclador por-app. Clon estructural de mediactl
// (misma tarjeta, mismo estilo de barra tipo scrub que su progreso de pista).
// Cierra al salir el mouse, con Esc, o a los 30 s. Colores: colors.json (matugen).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // lista de streams de app (recalculada por timer: UntypedObjectModel no
    // emite un "changed" de propiedad QML normal, así que un binding directo
    // sobre Pipewire.nodes.values no se refresca solo)
    property var appStreams: []
    readonly property int streamCount: root.appStreams.length
    function isAppStream(n) {
        // Los streams de reproducción de apps vienen con isSink=true también
        // (no es exclusivo de los sinks de hardware) — no filtrar por eso.
        // Y el chequeo tiene que ser IGUALDAD, no AND bit a bit: los flags
        // compuestos de PwNodeType comparten bits entre sí (AudioOutStream y
        // AudioInStream comparten Audio|Stream), así que un AND contra
        // AudioOutStream matchea también los streams de entrada (mic).
        return !!(n && n.audio && n.type === PwNodeType.AudioOutStream);
    }
    function recomputeStreams() {
        const arr = Pipewire.nodes ? Pipewire.nodes.values : [];
        const matched = [];
        for (const n of arr) if (root.isAppStream(n)) matched.push(n);
        root.appStreams = matched;
    }
    Component.onCompleted: root.recomputeStreams()
    Timer { interval: 1000; repeat: true; running: true; onTriggered: root.recomputeStreams() }

    // Mantiene vivas las bindings de audio: salida/entrada por defecto + cada
    // stream de app visible. SIN esto un PwNode nunca queda "bound" (node.ready
    // se queda en false) y su .audio.volume lee/escribe 0 en silencio, sin error
    // — así se ven todas las filas de apps en 0% y arrastrar el slider no hace
    // nada aunque la fila esté ahí. Confirmado con un dump manual de Pipewire.nodes.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(x => x).concat(root.appStreams)
    }

    // El nombre "de fábrica" de un stream suele ser el motor de audio interno
    // de la app (ej. Discord reporta application.name="WEBRTC VoiceEngine",
    // War Thunder reporta "FMOD Audio"), no la app en sí. `application.process
    // .binary` sí es el ejecutable real — más confiable, se usa como clave
    // primaria acá. Agregar entradas nuevas a mano si aparece algo sin mapear.
    readonly property var friendlyNames: ({
        "discord": "Discord",
        "aces": "War Thunder",
        "firefox": "Firefox",
        "firefox-bin": "Firefox",
        "librewolf": "LibreWolf",
        "zen": "Zen Browser",
        "chrome": "Chrome",
        "chromium": "Chromium",
        "brave": "Brave",
        "vivaldi-bin": "Vivaldi",
        "spotify": "Spotify",
        "steam": "Steam",
        "steamwebhelper": "Steam",
        "mpv": "mpv",
        "vlc": "VLC",
        "obs": "OBS Studio",
    })
    readonly property var friendlyGlyphs: ({
        "discord": "󰙯",
        "aces": "󰊴",
        "firefox": "",
        "firefox-bin": "",
        "librewolf": "",
        "zen": "",
        "chrome": "",
        "chromium": "",
        "brave": "",
        "vivaldi-bin": "",
        "spotify": "",
        "steam": "",
        "steamwebhelper": "",
        "mpv": "󰔜",
        "vlc": "󰵼",
        "obs": "󰑋",
    })
    // Clave de lookup: preferir application.process.binary (el ejecutable
    // real); si viene vacío (ej. Spotify no lo reporta) caer a application.name.
    // Así una sola tabla cubre los dos casos, sin lista de fallback duplicada.
    function identityKey(n) {
        const props = n ? (n.properties || {}) : {};
        const bin = (props["application.process.binary"] || "").toLowerCase();
        if (bin) return bin;
        return ((props["application.name"] || (n ? n.name : "") || "") + "").toLowerCase();
    }
    function appName(n) {
        if (!n) return "Aplicación";
        const props = n.properties || {};
        const key = root.identityKey(n);
        if (key && root.friendlyNames[key]) return root.friendlyNames[key];
        return props["application.process.binary"] || props["application.name"]
            || props["node.description"] || n.description || n.name || "Aplicación";
    }
    function glyphFor(n) {
        const key = root.identityKey(n);
        if (key && root.friendlyGlyphs[key]) return root.friendlyGlyphs[key];
        return "󰕾";
    }

    // ---------- ventana ----------
    // Alineado bajo el módulo de sonido en modules-right (group/audio, antes de
    // custom/power). Ancla a la derecha; reajustar margins.right si cambia lo
    // que hay a la derecha del audio en la barra.
    anchors { top: true; right: true }
    margins { top: 44; right: 40 }
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
            property string surface: "#0f1416"
            property string surfaceContainer: "#1b2022"
            property string surfaceContainerHigh: "#252b2d"
            property string fg: "#dee3e6"
            property string fgDim: "#bfc8cc"
            property string primary: "#86d1e9"
            property string secondary: "#b2cad3"
            property string tertiary: "#c1c4eb"
            property string outline: "#899296"
        }
    }

    // ---------- fila reutilizable: glifo/mute + slider + % ----------
    component VolRow: RowLayout {
        id: vr
        required property string label
        required property string glyph
        property var audioObj: null   // PwNodeAudioIface (volume, muted)
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            implicitWidth: 26; implicitHeight: 26; radius: 13
            color: muteHover.hovered ? c.surfaceContainerHigh : "transparent"
            Text {
                anchors.centerIn: parent
                text: (vr.audioObj && vr.audioObj.muted) ? "󰝟" : vr.glyph
                color: (vr.audioObj && vr.audioObj.muted) ? c.fgDim : c.primary
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font"
            }
            HoverHandler { id: muteHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: vr.audioObj !== null
                onClicked: if (vr.audioObj) vr.audioObj.muted = !vr.audioObj.muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: vr.label
                color: c.fg
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Item {
                id: track
                Layout.fillWidth: true
                implicitHeight: 14
                property bool dragging: false
                property real dragFrac: 0
                readonly property real curVol: vr.audioObj ? vr.audioObj.volume : 0
                readonly property real frac: Math.max(0, Math.min(1, track.dragging ? track.dragFrac : track.curVol))

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 5; radius: 2.5
                    color: Qt.rgba(1, 1, 1, 0.14)
                    Rectangle {
                        width: parent.width * track.frac
                        height: parent.height; radius: 2.5
                        color: (vr.audioObj && vr.audioObj.muted) ? c.fgDim : c.primary
                    }
                }
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: c.primary
                    anchors.verticalCenter: parent.verticalCenter
                    x: (parent.width - width) * track.frac
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: vr.audioObj !== null
                    cursorShape: Qt.PointingHandCursor
                    function fracAt(mx) { return Math.max(0, Math.min(1, mx / track.width)); }
                    onPressed: (m) => { track.dragging = true; track.dragFrac = fracAt(m.x); }
                    onPositionChanged: (m) => { if (track.dragging) { track.dragFrac = fracAt(m.x); if (vr.audioObj) vr.audioObj.volume = track.dragFrac; } }
                    onReleased: (m) => {
                        const f = fracAt(m.x);
                        if (vr.audioObj) vr.audioObj.volume = f;
                        track.dragging = false;
                    }
                }
            }
        }

        Text {
            text: Math.round((vr.audioObj ? vr.audioObj.volume : 0) * 100) + "%"
            color: c.fgDim
            font.pixelSize: 11
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
        }
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

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 16 }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Sonido"
                    color: c.primary
                    font.pixelSize: 15
                    font.weight: Font.Black
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.fillWidth: true
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            VolRow {
                label: "Salida" + (root.sink && root.sink.description ? " · " + root.sink.description : "")
                glyph: "󰕾"
                audioObj: root.sink ? root.sink.audio : null
            }
            VolRow {
                label: "Micrófono" + (root.source && root.source.description ? " · " + root.source.description : "")
                glyph: ""
                audioObj: root.source ? root.source.audio : null
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Aplicaciones"
                    color: c.fg
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Text {
                    text: root.streamCount
                    color: c.fgDim
                    font.pixelSize: 11
                }
            }

            Text {
                visible: root.streamCount === 0
                text: "Ninguna app está reproduciendo audio ahora."
                color: c.fgDim
                font.pixelSize: 11
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: Pipewire.nodes
                delegate: VolRow {
                    id: appRow
                    required property var modelData
                    readonly property bool isApp: root.isAppStream(appRow.modelData)
                    visible: appRow.isApp
                    label: appRow.isApp ? root.appName(appRow.modelData) : ""
                    glyph: appRow.isApp ? root.glyphFor(appRow.modelData) : "󰕾"
                    audioObj: appRow.isApp ? appRow.modelData.audio : null
                }
            }
        }
    }
}
