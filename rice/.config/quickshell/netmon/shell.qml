// Isla de tráfico de red — se abre con click izquierdo en el módulo "network"
// de waybar (group/connections) -> NetworkIsland.sh. A la derecha, como el
// centro de notificaciones (a diferencia de clima/calendario/mediactl/mixerctl
// que cuelgan de la izquierda).
//
// Fuentes de datos, ambas por Quickshell.Io.Process (sin archivos de cache):
// - NetTrafficSample.sh: loop de 1s, imprime una línea JSON con down/up
//   bytes/seg de la interfaz de la ruta default. Proceso persistente mientras
//   la isla está abierta (running:true fijo).
// - NetPorts.sh: dump de una vez (ss -tulnp) de puertos TCP/UDP en escucha +
//   proceso dueño. Se relanza cada 4s con un Timer (running toggled).
//
// Cierra al salir el mouse, con Esc, o a los 45 s (un poco más largo que el
// resto: acá el interés es justamente ver el tráfico un rato). Colores:
// colors.json (matugen).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ---------- tráfico en vivo ----------
    property string iface: "…"
    property real downBps: 0
    property real upBps: 0
    property real rxTotal: 0
    property real txTotal: 0
    property var history: []      // últimas ~40 muestras de downBps, para el sparkline
    readonly property real historyMax: {
        let m = 1;
        for (const v of root.history) if (v > m) m = v;
        return m;
    }

    function fmtRate(bps) {
        const units = ["B/s", "KB/s", "MB/s", "GB/s"];
        let v = Math.max(0, bps), i = 0;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return (i > 0 ? v.toFixed(v < 10 ? 1 : 0) : Math.round(v)) + " " + units[i];
    }
    function fmtBytes(b) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let v = Math.max(0, b), i = 0;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return (i > 0 ? v.toFixed(2) : Math.round(v)) + " " + units[i];
    }

    Process {
        id: trafficProc
        command: ["bash", root.home + "/.config/hypr/scripts/NetTrafficSample.sh"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (!line || line.trim().length === 0) return;
                try {
                    const d = JSON.parse(line);
                    root.iface = d.iface || root.iface;
                    root.downBps = d.down_bps || 0;
                    root.upBps = d.up_bps || 0;
                    root.rxTotal = d.rx_total || 0;
                    root.txTotal = d.tx_total || 0;
                    const h = root.history.concat([root.downBps]);
                    if (h.length > 40) h.shift();
                    root.history = h;
                } catch (e) { /* línea parcial o basura, ignorar */ }
            }
        }
    }

    // ---------- puertos en escucha ----------
    property var ports: []
    property var _portsBuf: []
    Process {
        id: portsProc
        command: ["bash", root.home + "/.config/hypr/scripts/NetPorts.sh"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (!line || line.trim().length === 0) return;
                try { root._portsBuf.push(JSON.parse(line)); } catch (e) {}
            }
        }
        onExited: {
            const arr = root._portsBuf.slice();
            arr.sort((a, b) => parseInt(a.port) - parseInt(b.port));
            root.ports = arr;
            root._portsBuf = [];
        }
    }
    Component.onCompleted: portsProc.running = true
    Timer { interval: 4000; repeat: true; running: true; onTriggered: portsProc.running = true }

    // ---------- ventana ----------
    // A la derecha, como el centro de notificaciones. Cerca del ícono de red
    // (group/connections, a la derecha del audio) — reajustar margins.right
    // si cambia el layout de modules-right.
    anchors { top: true; right: true }
    margins { top: 44; right: 10 }
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

    // ---------- autocierre ----------
    Timer { id: leaveTimer; interval: 2500; onTriggered: Qt.quit() }
    Timer { interval: 45000; running: true; onTriggered: Qt.quit() }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: Math.min(col.implicitHeight + 32, 560)
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
                    text: "Red"
                    color: c.primary
                    font.pixelSize: 15
                    font.weight: Font.Black
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.fillWidth: true
                }
                Text {
                    text: root.iface
                    color: c.fgDim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- velocidad en vivo -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 18

                ColumnLayout {
                    spacing: 1
                    RowLayout {
                        spacing: 5
                        Text { text: "󰇚"; color: c.primary; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font" }
                        Text { text: "Bajada"; color: c.fgDim; font.pixelSize: 10 }
                    }
                    Text {
                        text: root.fmtRate(root.downBps)
                        color: c.fg
                        font.pixelSize: 18
                        font.weight: Font.Black
                    }
                }
                ColumnLayout {
                    spacing: 1
                    RowLayout {
                        spacing: 5
                        Text { text: "󰕒"; color: c.secondary; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font" }
                        Text { text: "Subida"; color: c.fgDim; font.pixelSize: 10 }
                    }
                    Text {
                        text: root.fmtRate(root.upBps)
                        color: c.fg
                        font.pixelSize: 18
                        font.weight: Font.Black
                    }
                }
                Item { Layout.fillWidth: true }
            }

            // ----- sparkline de bajada (últimas ~40 muestras) -----
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 2
                Repeater {
                    model: root.history
                    delegate: Rectangle {
                        required property real modelData
                        readonly property real frac: root.historyMax > 0 ? modelData / root.historyMax : 0
                        width: Math.max(1, (300 - 39 * 2) / 40)
                        height: Math.max(2, 28 * frac)
                        anchors.bottom: parent.bottom
                        radius: 1
                        color: c.primary
                        opacity: 0.35 + 0.65 * frac
                    }
                }
            }

            Text {
                text: "Total: 󰇚 " + root.fmtBytes(root.rxTotal) + "   󰕒 " + root.fmtBytes(root.txTotal) + "  (desde el arranque)"
                color: c.fgDim
                font.pixelSize: 10
                Layout.fillWidth: true
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

            // ----- puertos habilitados -----
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Puertos habilitados"
                    color: c.fg
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Text {
                    text: root.ports.length
                    color: c.fgDim
                    font.pixelSize: 11
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(portsCol.implicitHeight, 260)
                contentWidth: width
                contentHeight: portsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: portsCol
                    width: parent.width
                    spacing: 4

                    Text {
                        visible: root.ports.length === 0
                        text: "Buscando puertos…"
                        color: c.fgDim
                        font.pixelSize: 11
                        font.italic: true
                    }

                    Repeater {
                        model: root.ports
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: modelData.proto
                                color: modelData.proto === "TCP" ? c.primary : c.tertiary
                                font.pixelSize: 10
                                font.weight: Font.Black
                                Layout.preferredWidth: 32
                            }
                            Text {
                                text: modelData.port
                                color: c.fg
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: 46
                            }
                            Text {
                                text: modelData.proc !== "-" ? modelData.proc : "(sistema)"
                                color: modelData.proc !== "-" ? c.fgDim : c.outline
                                font.pixelSize: 11
                                font.italic: modelData.proc === "-"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
