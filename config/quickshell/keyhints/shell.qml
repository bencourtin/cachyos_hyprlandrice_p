// Cheatsheet de atajos de teclado del rice — se abre con SUPER + K
// (bind → ~/.config/hypr/scripts/KeyHints.sh, toggle). Diseño calcado del
// launcher rofi (~/.config/rofi/config.rasi): ventana 1000px centrada, borde
// redondeado, panel izquierdo con el wallpaper + barra de búsqueda + botones
// tipo mode-switcher (acá filtran por sección), panel derecho con la lista de
// elementos. Cierra con Esc o click fuera.
// La lista es estática, espejando ~/.config/hypr/config/binds.lua.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    readonly property string home: Quickshell.env("HOME")

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ---------- colores (matugen, mismas claves que rofi) ----------
    FileView {
        path: Qt.resolvedUrl("colors.json").toString().replace("file://", "")
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: c
            property string primary: "#8bd0ef"
            property string primaryFixed: "#bde9ff"
            property string barBg: "#003546"
            property string winBg: "#001f2a"
            property string secondary: "#b4cad6"
            property string selFg: "#1f333c"
            property string secondaryContainer: "#354a53"
            property string tertiary: "#c6c2ea"
            property string fg: "#dfe3e7"
            property string fgDim: "#c0c8cd"
            property string surface: "#0f1417"
            property string surfaceContainer: "#1b2023"
            property string surfaceContainerHigh: "#262b2e"
            property string outline: "#8a9297"
        }
    }

    // ---------- datos (espejo de binds.lua) ----------
    readonly property var sections: [
        { title: "Ventanas", items: [
            { k: "SUPER + Q",             d: "Cerrar ventana" },
            { k: "SUPER + Escape",        d: "Matar ventana (forzar)" },
            { k: "SUPER + F",             d: "Pantalla completa" },
            { k: "SUPER + D",             d: "Maximizar (mantener barra)" },
            { k: "SUPER + J",             d: "Alternar split del tiling" },
            { k: "SUPER + ALT + Space",   d: "Ventana flotante on/off" },
            { k: "SUPER + ← ↑ ↓ →",       d: "Mover el foco" },
            { k: "SUPER + SHIFT + ← ↑ ↓ →", d: "Mover la ventana" },
            { k: "ALT + Tab",             d: "Ciclar ventanas" },
            { k: "SUPER + Tab",           d: "Selector de ventanas (rofi)" },
            { k: "SUPER + arrastrar izq", d: "Mover ventana con el mouse" },
            { k: "SUPER + arrastrar der", d: "Redimensionar con el mouse" },
            { k: "SUPER + - / +",         d: "Zoom de pantalla" },
        ]},
        { title: "Waybar", items: [
            { k: "SUPER + Z",             d: "Mostrar/ocultar la barra" },
            { k: "SUPER + CONTROL + B",   d: "Cambiar estilo de waybar" },
            { k: "SUPER + ALT + B",       d: "Cambiar layout de waybar" },
            { k: "SUPER + SHIFT + R",     d: "Reiniciar waybar" },
        ]},
        { title: "Lanzar apps", items: [
            { k: "SUPER + Return",        d: "Terminal (kitty)" },
            { k: "SUPER + Space",         d: "Launcher de apps (rofi)" },
            { k: "SUPER + E",             d: "Archivos (yazi)" },
            { k: "SUPER + W",             d: "Navegador (firefox)" },
            { k: "SUPER + T",             d: "Editor de texto" },
            { k: "SUPER + C",             d: "Calculadora" },
            { k: "SUPER + period",        d: "Selector de emojis" },
            { k: "SUPER + V",             d: "Historial de portapapeles" },
            { k: "SUPER + K",             d: "Esta ayuda de atajos" },
            { k: "CONTROL + SHIFT + Escape", d: "Monitor de sistema (btop)" },
        ]},
        { title: "Sesión / sistema", items: [
            { k: "SUPER + L",             d: "Bloquear pantalla" },
            { k: "SUPER + ALT + C",       d: "Menú de sesión (wlogout)" },
            { k: "SUPER + X",             d: "Centro de notificaciones" },
            { k: "SUPER + A",             d: "No molestar on/off" },
        ]},
        { title: "Escritorios", items: [
            { k: "SUPER + SHIFT + 1…0",   d: "Ir al escritorio 1–10" },
            { k: "SUPER + ALT + 1…5",     d: "Ir al escritorio (absoluto)" },
            { k: "SUPER + CONTROL + 1…5", d: "Ir al escritorio (del monitor)" },
            { k: "SUPER + SHIFT + CONTROL + 1…0", d: "Llevar la ventana al escritorio N" },
            { k: "SUPER + CONTROL + ← →", d: "Escritorio anterior / siguiente" },
            { k: "SUPER + CONTROL + ↓",   d: "Siguiente escritorio vacío" },
            { k: "SUPER + scroll",        d: "Cambiar de escritorio" },
            { k: "SUPER + S",             d: "Scratchpad on/off" },
            { k: "SUPER + SHIFT + S",     d: "Llevar la ventana al scratchpad" },
        ]},
        { title: "Captura / color", items: [
            { k: "Print",                 d: "Captura de región → satty" },
            { k: "SUPER + Print",         d: "Captura de pantalla → satty" },
            { k: "SUPER + P",             d: "Cuentagotas de color" },
        ]},
        { title: "Fondo / tema", items: [
            { k: "SUPER + SHIFT + W",     d: "Selector visual de wallpaper" },
            { k: "SUPER + ALT + W",       d: "Selector de wallpaper (rofi)" },
        ]},
        { title: "Multimedia", items: [
            { k: "Vol +/− / Mute",        d: "Volumen (swayosd)" },
            { k: "Play · Next · Prev",    d: "Control de reproducción" },
            { k: "Brillo +/−",            d: "Brillo (swayosd)" },
        ]},
    ]

    property int filter: 0                       // 0 = Todos ; 1..N = sección i-1
    readonly property string query: searchInput.text

    readonly property var rows: {
        const q = root.query.trim().toLowerCase();
        const f = root.filter;
        const secs = (f === 0) ? root.sections : [root.sections[f - 1]];
        let out = [];
        for (const s of secs) {
            const matches = s.items.filter(function (it) {
                return q === "" || (it.k + " " + it.d).toLowerCase().indexOf(q) !== -1;
            });
            if (matches.length === 0) continue;
            if (f === 0) out.push({ type: "header", text: s.title });
            for (const it of matches) out.push({ type: "item", k: it.k, d: it.d });
        }
        return out;
    }

    // ---------- backdrop ----------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.28)
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
    }

    // ---------- ventana (rofi `window`) ----------
    Rectangle {
        id: win
        anchors.centerIn: parent
        width: 1000
        height: Math.min(parent.height - 100, 800)
        radius: 15
        color: c.winBg
        border.width: 2
        border.color: c.secondaryContainer

        MouseArea { anchors.fill: parent }   // traga clicks (no cierra por backdrop)

        RowLayout {
            anchors { fill: parent; margins: 6 }
            spacing: 0

            // ================= imagebox (izquierda) =================
            Rectangle {
                Layout.preferredWidth: 360
                Layout.fillHeight: true
                radius: 11
                clip: true
                color: c.winBg

                Image {
                    anchors.fill: parent
                    source: "file://" + root.home + "/.config/hypr/current_wallpaper"
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                }
                Rectangle { anchors.fill: parent; color: c.winBg; opacity: 0.45 }

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 18

                    // ----- barra de búsqueda (rofi `inputbar`) -----
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 58
                        radius: 12
                        color: c.barBg

                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            spacing: 12

                            Text {
                                text: ""                       //
                                color: c.fgDim
                                font.pixelSize: 17
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    focus: true
                                    color: c.fg
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                    selectByMouse: true
                                    selectionColor: c.primary
                                    selectedTextColor: c.selFg
                                    clip: true
                                    Keys.onEscapePressed: Qt.quit()

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: searchInput.text.length === 0
                                        text: "Buscar atajo…"
                                        color: c.fgDim
                                        font: searchInput.font
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.fillHeight: true }   // dummy

                    // ----- mode-switcher (acá: filtro por sección) -----
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        Repeater {
                            model: 1 + root.sections.length   // "Todos" + secciones
                            delegate: Rectangle {
                                required property int index
                                readonly property bool sel: root.filter === index
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: 12
                                color: sel ? c.primary : c.barBg

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.filter = parent.index
                                }
                                Text {
                                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                    verticalAlignment: Text.AlignVCenter
                                    text: parent.index === 0 ? "Todos"
                                                             : root.sections[parent.index - 1].title
                                    color: parent.sel ? c.selFg : c.primaryFixed
                                    font.pixelSize: 15
                                    font.weight: parent.sel ? Font.Bold : Font.Normal
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // ================= listbox (derecha) =================
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: flick
                    anchors { fill: parent; margins: 24 }
                    contentWidth: width
                    contentHeight: listCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: listCol
                        width: flick.width
                        spacing: 9

                        Text {
                            visible: root.rows.length === 0
                            text: "Sin resultados"
                            color: c.fgDim
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            topPadding: 6
                        }

                        Repeater {
                            model: root.rows
                            delegate: Loader {
                                required property var modelData
                                Layout.fillWidth: true
                                sourceComponent: modelData.type === "header" ? headerC : itemC

                                Component {
                                    id: headerC
                                    Text {
                                        text: modelData.text
                                        color: c.primaryFixed
                                        font.pixelSize: 15
                                        font.weight: Font.Black
                                        font.family: "JetBrainsMono Nerd Font"
                                        topPadding: 12
                                        bottomPadding: 3
                                    }
                                }

                                Component {
                                    id: itemC
                                    Rectangle {
                                        implicitHeight: elrow.implicitHeight + 18
                                        radius: 10
                                        color: elh.hovered ? c.primary : "transparent"
                                        HoverHandler { id: elh }

                                        RowLayout {
                                            id: elrow
                                            anchors { fill: parent; leftMargin: 12; rightMargin: 14; topMargin: 9; bottomMargin: 9 }
                                            spacing: 16

                                            RowLayout {
                                                spacing: 4
                                                Layout.alignment: Qt.AlignVCenter
                                                Repeater {
                                                    model: modelData.k.split(" + ")
                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        implicitHeight: 26
                                                        implicitWidth: kc.implicitWidth + 16
                                                        radius: 6
                                                        color: elh.hovered ? c.selFg : c.surfaceContainerHigh
                                                        border.width: 1
                                                        border.color: Qt.rgba(1, 1, 1, 0.08)
                                                        Text {
                                                            id: kc
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            color: elh.hovered ? c.primaryFixed : c.fg
                                                            font.pixelSize: 13
                                                            font.weight: Font.DemiBold
                                                            font.family: "JetBrainsMono Nerd Font"
                                                        }
                                                    }
                                                }
                                            }

                                            Text {
                                                text: modelData.d
                                                color: elh.hovered ? c.selFg : c.fg
                                                font.pixelSize: 15
                                                font.family: "JetBrainsMono Nerd Font"
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
