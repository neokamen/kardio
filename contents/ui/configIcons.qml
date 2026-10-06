import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes
import "models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: iconsPage

    function resolveIcon(name) {
        if (!name) return "configure";
        var str = String(name);
        if (MetricDefinitions.isBundledIcon(str)) {
            return Qt.resolvedUrl("../icons/" + str + ".svg");
        }
        return name;
    }

    property string cfg_disabledIcons: ""
    property string cfg_cpuIcon: "cpu-symbolic"
    property string cfg_ramIcon: "memory-symbolic"
    property string cfg_swapIcon: "swap-symbolic"
    property string cfg_tempIcon: "temperature-symbolic"
    property string cfg_gpuIcon: "gpu-symbolic"
    property string cfg_batteryIcon: "battery-symbolic"
    property string cfg_powerIcon: "voltage-symbolic"
    property string cfg_networkIcon: "network-symbolic"
    property string cfg_netDownIcon: "network-download-symbolic"
    property string cfg_netUpIcon: "network-upload-symbolic"
    property string cfg_diskIcon: "storage-symbolic"
    property string cfg_fanIcon: "fan-symbolic"
    property string cfg_uptimeIcon: "system-symbolic"

    function isIconActive(id) {
        if (!cfg_disabledIcons) return true;
        var list = cfg_disabledIcons.split(",").map(function(s){ return s.trim(); });
        return list.indexOf(id) === -1;
    }

    function setIconActive(id, active) {
        var list = cfg_disabledIcons ? cfg_disabledIcons.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; }) : [];
        var idx = list.indexOf(id);
        if (active && idx !== -1) {
            list.splice(idx, 1);
        } else if (!active && idx === -1) {
            list.push(id);
        }
        cfg_disabledIcons = list.join(",");
    }

    KIconThemes.IconDialog {
        id: cpuIconDialog
        onIconNameChanged: if (iconName) cfg_cpuIcon = iconName
    }
    KIconThemes.IconDialog {
        id: ramIconDialog
        onIconNameChanged: if (iconName) cfg_ramIcon = iconName
    }
    KIconThemes.IconDialog {
        id: swapIconDialog
        onIconNameChanged: if (iconName) cfg_swapIcon = iconName
    }
    KIconThemes.IconDialog {
        id: tempIconDialog
        onIconNameChanged: if (iconName) cfg_tempIcon = iconName
    }
    KIconThemes.IconDialog {
        id: gpuIconDialog
        onIconNameChanged: if (iconName) cfg_gpuIcon = iconName
    }
    KIconThemes.IconDialog {
        id: batteryIconDialog
        onIconNameChanged: if (iconName) cfg_batteryIcon = iconName
    }
    KIconThemes.IconDialog {
        id: powerIconDialog
        onIconNameChanged: if (iconName) cfg_powerIcon = iconName
    }
    KIconThemes.IconDialog {
        id: networkIconDialog
        onIconNameChanged: if (iconName) cfg_networkIcon = iconName
    }
    KIconThemes.IconDialog {
        id: netDownIconDialog
        onIconNameChanged: if (iconName) cfg_netDownIcon = iconName
    }
    KIconThemes.IconDialog {
        id: netUpIconDialog
        onIconNameChanged: if (iconName) cfg_netUpIcon = iconName
    }
    KIconThemes.IconDialog {
        id: diskIconDialog
        onIconNameChanged: if (iconName) cfg_diskIcon = iconName
    }
    KIconThemes.IconDialog {
        id: fanIconDialog
        onIconNameChanged: if (iconName) cfg_fanIcon = iconName
    }
    KIconThemes.IconDialog {
        id: uptimeIconDialog
        onIconNameChanged: if (iconName) cfg_uptimeIcon = iconName
    }

    Kirigami.FormLayout {
        id: formLayout

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Activa o desactiva iconos individualmente para cada sensor o sub-métrica del panel, o cámbialos por iconos personalizados de tu tema.")
            visible: true
        }

        // 1. CPU
        RowLayout {
            Kirigami.FormData.label: i18n("CPU (Procesador):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("cpu")
                onToggled: iconsPage.setIconActive("cpu", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_cpuIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("cpu") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("cpu")
                onClicked: cpuIconDialog.open()
            }
        }

        // 2. RAM
        RowLayout {
            Kirigami.FormData.label: i18n("RAM (Memoria):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("ram")
                onToggled: iconsPage.setIconActive("ram", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_ramIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("ram") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("ram")
                onClicked: ramIconDialog.open()
            }
        }

        // 3. SWAP
        RowLayout {
            Kirigami.FormData.label: i18n("SWAP (Intercambio):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("swap")
                onToggled: iconsPage.setIconActive("swap", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_swapIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("swap") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("swap")
                onClicked: swapIconDialog.open()
            }
        }

        // 4. Temperatura
        RowLayout {
            Kirigami.FormData.label: i18n("Temperatura:")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("temp")
                onToggled: iconsPage.setIconActive("temp", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_tempIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("temp") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("temp")
                onClicked: tempIconDialog.open()
            }
        }

        // 5. GPU
        RowLayout {
            Kirigami.FormData.label: i18n("GPU (Gráficos):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("gpu")
                onToggled: iconsPage.setIconActive("gpu", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_gpuIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("gpu") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("gpu")
                onClicked: gpuIconDialog.open()
            }
        }

        // 6. Batería
        RowLayout {
            Kirigami.FormData.label: i18n("Batería:")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("bat")
                onToggled: iconsPage.setIconActive("bat", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_batteryIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("bat") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("bat")
                onClicked: batteryIconDialog.open()
            }
        }

        // 7. Potencia / Watts
        RowLayout {
            Kirigami.FormData.label: i18n("Potencia (Watts):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("power")
                onToggled: iconsPage.setIconActive("power", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_powerIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("power") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("power")
                onClicked: powerIconDialog.open()
            }
        }

        // 8. Red General
        RowLayout {
            Kirigami.FormData.label: i18n("Red (General):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("net")
                onToggled: iconsPage.setIconActive("net", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_networkIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("net") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("net")
                onClicked: networkIconDialog.open()
            }
        }

        // 9. Red Descarga
        RowLayout {
            Kirigami.FormData.label: i18n("Red Descarga (↓):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("net/down")
                onToggled: iconsPage.setIconActive("net/down", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_netDownIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("net/down") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("net/down")
                onClicked: netDownIconDialog.open()
            }
        }

        // 10. Red Subida
        RowLayout {
            Kirigami.FormData.label: i18n("Red Subida (↑):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("net/up")
                onToggled: iconsPage.setIconActive("net/up", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_netUpIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("net/up") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("net/up")
                onClicked: netUpIconDialog.open()
            }
        }

        // 11. Discos
        RowLayout {
            Kirigami.FormData.label: i18n("Discos (Almacenamiento):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("disk")
                onToggled: iconsPage.setIconActive("disk", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_diskIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("disk") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("disk")
                onClicked: diskIconDialog.open()
            }
        }

        // 12. Ventiladores
        RowLayout {
            Kirigami.FormData.label: i18n("Ventiladores (Fans):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("fan")
                onToggled: iconsPage.setIconActive("fan", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_fanIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("fan") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("fan")
                onClicked: fanIconDialog.open()
            }
        }

        // 13. Uptime
        RowLayout {
            Kirigami.FormData.label: i18n("Tiempo Encendido (Uptime):")
            spacing: Kirigami.Units.smallSpacing

            Switch {
                checked: iconsPage.isIconActive("uptime")
                onToggled: iconsPage.setIconActive("uptime", checked)
            }
            Kirigami.Icon {
                source: iconsPage.resolveIcon(cfg_uptimeIcon)
                isMask: true
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                opacity: iconsPage.isIconActive("uptime") ? 1.0 : 0.25
            }
            Button {
                text: i18n("Cambiar...")
                icon.name: "document-edit"
                enabled: iconsPage.isIconActive("uptime")
                onClicked: uptimeIconDialog.open()
            }
        }

        Button {
            icon.name: "edit-undo"
            text: i18n("Restablecer todos a valores por defecto")
            Kirigami.FormData.label: " "
            onClicked: {
                cfg_disabledIcons = "";
                cfg_cpuIcon = "cpu-symbolic";
                cfg_ramIcon = "memory-symbolic";
                cfg_swapIcon = "swap-symbolic";
                cfg_tempIcon = "temperature-symbolic";
                cfg_gpuIcon = "gpu-symbolic";
                cfg_batteryIcon = "battery-symbolic";
                cfg_powerIcon = "voltage-symbolic";
                cfg_networkIcon = "network-symbolic";
                cfg_netDownIcon = "network-download-symbolic";
                cfg_netUpIcon = "network-upload-symbolic";
                cfg_diskIcon = "storage-symbolic";
                cfg_fanIcon = "fan-symbolic";
                cfg_uptimeIcon = "system-symbolic";
            }
        }
    }
}
