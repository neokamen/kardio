import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: aboutPage

    ColumnLayout {
        id: aboutCol
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        // ═══════════════════════════════════════════════════════════════════
        // 1. BRAND HERO BANNER CARD
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(160, Math.round(width * (640 / 1280)))
            Layout.maximumHeight: 260
            radius: Kirigami.Units.smallSpacing * 1.5
            clip: true
            color: "#101a24"
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
            border.width: 1

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("../icons/kardio-banner.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                cache: false
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 2. PROJECT IDENTITY & AUTHOR
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true

            header: RowLayout {
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Icon {
                    source: Qt.resolvedUrl("../icons/kardio-symbolic.svg")
                    implicitWidth: 32
                    implicitHeight: 32
                    color: Kirigami.Theme.highlightColor
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Label {
                            text: "Kardio"
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4
                            color: Kirigami.Theme.textColor
                        }

                        Rectangle {
                            radius: 4
                            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                            implicitWidth: versionBadgeLabel.implicitWidth + 12
                            implicitHeight: versionBadgeLabel.implicitHeight + 4

                            Label {
                                id: versionBadgeLabel
                                anchors.centerIn: parent
                                text: "v0.4.0"
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.weight: Font.Bold
                                color: Kirigami.Theme.highlightColor
                            }
                        }
                    }

                    Label {
                        text: i18n("The Next-Gen KDE Plasma Telemetry Monitor")
                        font: Kirigami.Theme.smallFont
                        opacity: 0.8
                    }
                }

                Button {
                    icon.name: "globe"
                    text: i18n("GitHub")
                    onClicked: Qt.openUrlExternally("https://github.com/neokamen/kardio")
                }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                GridLayout {
                    columns: width > 500 ? 2 : 1
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Label {
                            text: i18n("Autor:")
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: "AlexMC \"neokamen\""
                            color: Kirigami.Theme.textColor
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Label {
                            text: i18n("Licencia:")
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: "GPL-3.0-or-later"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Label {
                            text: i18n("Plataforma:")
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: "KDE Plasma 6 (Qt Quick & Kirigami)"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Label {
                            text: i18n("Repositorio:")
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: "https://github.com/neokamen/kardio"
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                Label {
                    text: i18n("Monitor modular y ligero de telemetría del sistema diseñado especialmente para Linux y KDE Plasma 6. Monitoriza en tiempo real CPU (por núcleo, carga, frecuencia y temperatura), GPU (uso, VRAM, Hotspot, temperatura de memoria, relojes), RAM y SWAP (con soporte DDR5 SPD5118 y unidades inteligentes), discos NVMe/SATA, ancho de banda de red, ventiladores, voltajes y estado de batería.")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    opacity: 0.85
                }
            }
        }
    }
}
