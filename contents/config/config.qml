import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Panel Items")
        icon: "format-list-ordered"
        source: "configPanelOrder.qml"
    }
    ConfigCategory {
        name: i18n("Sensores & Hardware")
        icon: "preferences-system-hardware"
        source: "configMetrics.qml"
    }
    ConfigCategory {
        name: i18n("Explorador de Sensores")
        icon: "system-search"
        source: "SensorExplorer.qml"
    }
    ConfigCategory {
        name: i18n("Colores & Alertas")
        icon: "color-management"
        source: "configColors.qml"
    }
    ConfigCategory {
        name: i18n("Iconos")
        icon: "preferences-desktop-icons"
        source: "configIcons.qml"
    }
    ConfigCategory {
        name: i18n("Perfiles")
        icon: "user-identity"
        source: "configProfiles.qml"
    }
    ConfigCategory {
        name: i18n("Acerca de")
        icon: "help-about"
        source: "configAbout.qml"
    }
}
