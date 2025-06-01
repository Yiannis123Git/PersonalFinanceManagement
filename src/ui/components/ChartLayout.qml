pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var appController
    property var appWindow
    property color foregroundColor
    Layout.fillHeight: true
    Layout.preferredWidth: parent.width * 0.78

    Flickable {
        id: scrollArea
        anchors.fill: parent
        contentWidth: chartsGrid.implicitWidth
        contentHeight: chartsGrid.implicitHeight
        clip: true

        ColumnLayout {
            id: layoutColumn
            width: parent.width
            spacing: 20
            GridLayout {
                id: chartsGrid
                width: scrollArea.width
                columns: root.appWindow.width > 1300 ? 2 : 1  // change between 2x2 and single view
                rowSpacing: 20
                columnSpacing: 120

                // Chart 1 Loader
                Loader {
                    id: chart1Loader
                    active: root.appController.init_status
                    asynchronous: true
                    sourceComponent: chart1Component
                    onLoaded: {
                        item.imageSource = root.appController.chart_paths["monthlyChart"];
                    }
                }

                // Chart 2 Loader
                Loader {
                    id: chart2Loader
                    active: root.appController.init_status === true
                    asynchronous: true
                    sourceComponent: chart2Component
                    onLoaded: {
                        item.imageSource = root.appController.chart_paths["dailyChart"];
                    }
                }

                // Chart 3 Loader
                Loader {
                    id: chart3Loader
                    active: root.appController.init_status === true
                    asynchronous: true
                    sourceComponent: chart3Component
                    onLoaded: {
                        item.imageSource = root.appController.chart_paths["incomeVsExpense"];
                    }
                }

                // Chart 4 Loader
                Loader {
                    id: chart4Loader
                    active: root.appController.init_status === true
                    asynchronous: true
                    sourceComponent: chart4Component
                    onLoaded: {
                        item.imageSource = root.appController.chart_paths["expenseDistribution"];
                    }
                }
            }
        }
    }

    // Chart 1 Component
    Component {
        id: chart1Component
        ChartComponent {
            id: chart1
            title: "Income&Expenses for Year in Months"
            foregroundColor: root.foregroundColor
            populateYearModel: true
            includeMonths: false
            onGenerateRequested: function () {
                root.appController.plot_monthly_trend(comboModels[0][selectedIndices[0]]);
                chart1.reloadImage();
            }
        }
    }

    // Chart 2 Component
    Component {
        id: chart2Component
        ChartComponent {
            id: chart2
            title: "Income&Expenses for Month in Days"
            foregroundColor: root.foregroundColor
            populateYearModel: true
            includeMonths: true
            onGenerateRequested: function () {
                root.appController.plot_daily_transactions(comboModels[0][selectedIndices[0]], comboModels[1][selectedIndices[1]]);
                chart2.reloadImage();
            }
        }
    }

    // Chart 3 Component
    Component {
        id: chart3Component
        ChartComponent {
            id: chart3
            title: "Total Income&Expenses for Year"
            foregroundColor: root.foregroundColor
            populateYearModel: true
            includeMonths: false
            onGenerateRequested: function () {
                root.appController.plot_income_vs_expense(comboModels[0][selectedIndices[0]]);
                chart3.reloadImage();
            }
        }
    }

    // Chart 4 Component
    Component {
        id: chart4Component
        ChartComponent {
            id: chart4
            title: "Expense Distribution by Category"
            foregroundColor: root.foregroundColor
            populateYearModel: true
            includeMonths: false
            onGenerateRequested: function () {
                root.appController.plot_expense_distribution(comboModels[0][selectedIndices[0]]);
                chart4.reloadImage();
            }
        }
    }
}
