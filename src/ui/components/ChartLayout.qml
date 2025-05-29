import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var appController
    property var appWindow
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

                // Chart 1
                ChartComponent {
                    id: chart1
                    title: "Income&Expenses for Year in Months"
                    populateYearModel: true
                    includeMonths: false
                    imageSource: "../../data/graphs/monthlychart.png"
                    onGenerateRequested: function () {
                        root.appController.plot_monthly_trend(comboModels[0][selectedIndices[0]]);
                        chart1.reloadImage();
                    }
                }

                // Chart 2
                ChartComponent {
                    id: chart2
                    title: "Income&Expenses for Month in Days"
                    populateYearModel: true
                    includeMonths: true
                    imageSource: "../../data/graphs/dailychart.png"
                    onGenerateRequested: function () {
                        console.log("Generate button clicked for chart 2");
                        root.appController.plot_daily_transactions(comboModels[0][selectedIndices[0]], comboModels[1][selectedIndices[1]]);
                        chart2.reloadImage();
                    }
                }

                // Chart 3
                ChartComponent {
                    id: chart3
                    title: "Total Income&Expenses for Year"
                    populateYearModel: true
                    includeMonths: false
                    imageSource: "../../data/graphs/income_vs_expense.png"
                    onGenerateRequested: function () {
                        root.appController.plot_income_vs_expense(comboModels[0][selectedIndices[0]]);
                        chart3.reloadImage();
                    }
                }

                // Chart 4
                ChartComponent {
                    id: chart4
                    title: "Expense Distribution by Category"
                    populateYearModel: true
                    includeMonths: false
                    imageSource: "../../data/graphs/expense_distribution.png"
                    onGenerateRequested: function () {
                        root.appController.plot_expense_distribution(comboModels[0][selectedIndices[0]]);
                        chart4.reloadImage();
                    }
                }
            }
        }
    }
}
