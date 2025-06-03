pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: overview
    property real switcherSize: 0.08
    property real listMargins: 15
    property int currentEditorContext: Overview.EditorContext.Create
    property int currentlySelectedTransactionId: -1
    property real monthSwitchDebounce: 100 // Debounce time for month switching
    property bool monthSwitchDebounceActive: false

    required property ApplicationWindow window // we use this to avoid null errors during model deletions
    required property var transactionModel
    required property var monthlyTransactionModel

    enum EditorContext {
        Create = 0,
        Edit = 1
    }

    function isBlank(str) {
        return !str || str.trim() === "";
    }

    function checkAmount(str) {
        if (isBlank(str)) {
            return qsTr("Transaction amount cannot be blank");
        } else {
            // Validate amount as a number
            let amount = parseFloat(str);
            let validCharacterPattern = /^[0-9.]+$/; // QML double validator does not handle this

            if (isNaN(amount) || !validCharacterPattern.test(str)) {
                return qsTr("Transaction amount must be a valid number");
            } else {
                // Check if amount is within range (problems might occur if billionares use the app)
                if (amount < 0.01 || amount > 1000000.00) {
                    return qsTr("Transaction amount must be between 0.01 and 1,000,000.00");
                }
            }
        }
    }

    function checkDate(dateDict) {
        let dateProblems = [];

        // Check if year is valid
        let yearIsValid = true;

        if (isBlank(dateDict.year)) {
            dateProblems.push(qsTr("Year cannot be blank"));
            yearIsValid = false;
        } else {
            let year = parseInt(dateDict.year);
            let currentYear = new Date().getFullYear();
            let yearCap = currentYear + 1;
            let yearMin = currentYear - 25;

            if (isNaN(year)) {
                dateProblems.push(qsTr("Year must be a valid number"));
                yearIsValid = false;
            } else if (year < yearMin || year > yearCap) {
                dateProblems.push(qsTr("Year must be between %1 and %2").arg(yearMin).arg(yearCap));
                yearIsValid = false;
            }
        }

        // Check if day is valid
        if (isBlank(dateDict.day)) {
            dateProblems.push(qsTr("Day cannot be blank"));
        } else {
            let day = parseInt(dateDict.day);

            if (isNaN(day)) {
                dateProblems.push(qsTr("Day must be a valid number"));
            } else if (yearIsValid) {
                // passing 0 as the day parameter will return the last day of the previous month
                let daysInMonth = new Date(parseInt(dateDict.year), parseInt(dateDict.month + 1), 0).getDate();

                if (day < 1 || day > daysInMonth) {
                    dateProblems.push(qsTr("Day must be between 1 and %1").arg(daysInMonth));
                }
            }
        }

        // Pack problems into a string and return them
        if (dateProblems.length > 0) {
            return dateProblems.join(", ");
        }
    }

    Timer {
        id: monthSwitchDebounceTimer
        interval: overview.monthSwitchDebounce
        repeat: false
        onTriggered: {
            overview.monthSwitchDebounceActive = false;
        }
    }

    // Error dialog
    DialogBase {
        id: errorDialog

        title: qsTr("Something went wrong")
        acceptButtonText: qsTr("OK")

        contentItem: Text {
            id: errorText

            width: 350
            wrapMode: Text.WordWrap
            color: "crimson"
        }

        onAcceptButtonClicked: {
            errorDialog.close();
        }
    }

    // Transaction Delete Dialog
    DialogBase {
        id: transactionDeleteDialog

        acceptButtonText: qsTr("Delete")
        rejectButtonText: qsTr("Cancel")

        contentItem: Text {
            text: qsTr("Are you sure you want to delete this transaction? This action cannot be undone.")
            wrapMode: Text.WordWrap
            color: Material.foreground
        }

        onAcceptButtonClicked: function () {
            let result = overview.transactionModel.remove(overview.currentlySelectedTransactionId);

            transactionDeleteDialog.close();

            // Display error depending on the result
            if (result.success == false) {
                errorText.text = result.error;
                errorDialog.open();
            }
        }
    }

    // Monthly Transaction Delete Dialog
    DialogBase {
        id: monthlyTransactionDeleteDialog

        acceptButtonText: qsTr("Delete")
        rejectButtonText: qsTr("Cancel")

        contentItem: Item {
            ColumnLayout {
                Text {
                    text: qsTr("Are you sure you want to delete this monthly recurring transaction? This action cannot be undone.")
                    wrapMode: Text.WordWrap
                    color: Material.foreground
                }

                CheckBox {
                    id: deleteAssociatedTransactionsCheckBox
                    text: qsTr("Delete associated transactions as well?")
                }
            }
        }

        onVisibleChanged: function () {
            // Reset the checkbox state when the dialog is opened
            deleteAssociatedTransactionsCheckBox.checked = false;
        }

        onAcceptButtonClicked: function () {
            let deleteAssociatedTransactions = deleteAssociatedTransactionsCheckBox.checked;
            let result = overview.monthlyTransactionModel.remove(overview.currentlySelectedTransactionId, deleteAssociatedTransactions);

            monthlyTransactionDeleteDialog.close();

            // Display error depending on the result
            if (result.success == false) {
                errorText.text = result.error;
                errorDialog.open();
            } else if (deleteAssociatedTransactions) {
                overview.transactionModel.update_model();
            }
        }
    }

    // Transaction Edtior window
    EditorWindow {
        id: transactionEditor

        fieldComponent: TransactionFields {
            onCategoryDeleted: {
                overview.transactionModel.update_model();
                overview.monthlyTransactionModel.update_model();
            }

            onCategoryEdited: {
                overview.transactionModel.update_model();
                overview.monthlyTransactionModel.update_model();
            }
        }

        validator: function (fieldData) {
            let isBlank = overview.isBlank;
            let checkAmount = overview.checkAmount;
            let checkDate = overview.checkDate;

            let problems = {};

            // Check if transaction name is blank
            if (isBlank(fieldData.name)) {
                problems.name = qsTr("Transaction name cannot be blank");
            }

            // Check if transaction amount is blank
            let amountProblem = checkAmount(fieldData.amount);

            if (amountProblem) {
                problems.amount = amountProblem;
            }

            // Check if execution date is valid (note: month is always valid given how the field is handled)
            let dateProblems = checkDate(fieldData.executionDate, true);

            // Pack date problems (if any)
            if (dateProblems) {
                problems.executionDate = dateProblems;
            }

            // Check if category is valid
            if (fieldData.category === null) {
                problems.category = qsTr("Please select a category");
            }

            // Conclude validation
            if (Object.keys(problems).length > 0) {
                return problems;
            }

            return true;
        }

        onConcluded: function (fieldData) {
            // Convert field data date values to Date object
            let executionDate = fieldData.executionDate;
            let date = new Date(parseInt(executionDate.year), parseInt(executionDate.month), parseInt(executionDate.day));

            let result = null;

            if (overview.currentEditorContext === Overview.EditorContext.Create) {
                // Create new transaction
                result = overview.transactionModel.append(fieldData.name, fieldData.amount, date, fieldData.category, fieldData.type);
            }

            if (overview.currentEditorContext === Overview.EditorContext.Edit) {
                // Edit existing transaction
                result = overview.transactionModel.edit(overview.currentlySelectedTransactionId, fieldData.name, fieldData.amount, date, fieldData.category, fieldData.type);
            }

            // Display error depending on the result
            if (result.success == false) {
                errorText.text = result.error;
                errorDialog.open();
            }
        }
    }

    // Monthly transaction editor
    EditorWindow {
        id: monthlyTransactionEditor

        fieldComponent: MTransactionFields {
            onCategoryDeleted: {
                overview.transactionModel.update_model();
                overview.monthlyTransactionModel.update_model();
            }
            onCategoryEdited: {
                overview.transactionModel.update_model();
                overview.monthlyTransactionModel.update_model();
            }
        }

        validator: function (fieldData) {
            let isBlank = overview.isBlank;
            let checkAmount = overview.checkAmount;
            let checkDate = overview.checkDate;

            let problems = {};

            // Check if transaction name is blank
            if (isBlank(fieldData.name)) {
                problems.name = qsTr("Transaction name cannot be blank");
            }

            // Check if transaction amount is blank
            let amountProblem = checkAmount(fieldData.amount);

            if (amountProblem) {
                problems.amount = amountProblem;
            }

            // Check if start date is valid
            let startDateProblems = checkDate(fieldData.startDate);

            if (startDateProblems) {
                problems.startDate = startDateProblems;
            }

            // Check if end date is valid
            if (fieldData.endDate) {
                let endDateProblems = checkDate(fieldData.endDate);

                if (endDateProblems) {
                    problems.endDate = endDateProblems;
                }
            }

            // Validate both start and end date in relation to each other
            if (fieldData.endDate && fieldData.startDate && !problems.startDate && !problems.endDate) {
                let startDate = new Date(parseInt(fieldData.startDate.year), parseInt(fieldData.startDate.month), parseInt(fieldData.startDate.day));
                let endDate = new Date(parseInt(fieldData.endDate.year), parseInt(fieldData.endDate.month), parseInt(fieldData.endDate.day));

                if (endDate <= startDate) {
                    problems.endDate = qsTr("End date must be after start date");
                }
            }

            // Check if day of month is valid
            if (isBlank(fieldData.dayOfMonth)) {
                problems.dayOfMonth = qsTr("Transaction day cannot be blank");
            } else {
                let dayOfMonth = parseInt(fieldData.dayOfMonth);

                if (isNaN(dayOfMonth)) {
                    problems.dayOfMonth = qsTr("Transaction day must be a valid number");
                } else if (dayOfMonth < 1 || dayOfMonth > 31) {
                    problems.dayOfMonth = qsTr("Transaction day must be between 1 and 31");
                }
            }

            // Check if category is valid
            if (fieldData.category === null) {
                problems.category = qsTr("Please select a category");
            }

            // Conclude validation
            if (Object.keys(problems).length > 0) {
                return problems;
            }

            return true;
        }

        onConcluded: function (fieldData) {
            let startDate = new Date(parseInt(fieldData.startDate.year), parseInt(fieldData.startDate.month), parseInt(fieldData.startDate.day));

            // Package end date (This is a hacky way to include an optional QDate value)
            let endDate = {
                endDate: fieldData.endDate ? new Date(parseInt(fieldData.endDate.year), parseInt(fieldData.endDate.month), parseInt(fieldData.endDate.day)) : null
            };

            let result;

            if (overview.currentEditorContext === Overview.EditorContext.Create) {
                // Create new monthly transaction
                result = overview.monthlyTransactionModel.append(fieldData.name, fieldData.amount, fieldData.category, fieldData.type, startDate, endDate, parseInt(fieldData.dayOfMonth));
            }

            if (overview.currentEditorContext === Overview.EditorContext.Edit) {
                // Edit existing monthly transaction
                result = overview.monthlyTransactionModel.edit(overview.currentlySelectedTransactionId, fieldData.name, fieldData.amount, fieldData.category, fieldData.type, startDate, endDate, parseInt(fieldData.dayOfMonth));
            }

            // Display error depending on the result
            if (result.success == false) {
                errorText.text = result.error;
                errorDialog.open();
            } else {
                // Update transaction data model to reflect monthly changes
                overview.transactionModel.update_model();
            }
        }
    }

    GradientBackground {}

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Month switcher
        Rectangle {
            id: monthSwitcher

            property real edgeOffset: 0.3
            property real arrowSize: 0.5
            property real buttonHeight: 0.8
            property real buttonWidth: 0.1

            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * overview.switcherSize

            z: 11
            color: Material.theme === Material.Light ? Qt.darker(Material.background, 1.05) : Qt.lighter(Material.background, 1.05)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: parent.width * monthSwitcher.edgeOffset
                anchors.rightMargin: parent.width * monthSwitcher.edgeOffset

                // Previous month button
                Button {
                    id: prevMonthButton
                    Layout.preferredWidth: parent.width * monthSwitcher.buttonWidth
                    Layout.preferredHeight: parent.height * monthSwitcher.buttonHeight
                    flat: true

                    contentItem: Text {
                        text: "❮"
                        font.pixelSize: Math.max(16, Math.min(monthSwitcher.width, monthSwitcher.height) * monthSwitcher.arrowSize)
                        color: prevMonthButton.hovered ? Material.accent : Material.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    ToolTip {
                        visible: prevMonthButton.hovered
                        text: qsTr("Switch to previous month")
                        delay: 1000
                        timeout: 5000
                        y: -height - 5
                    }

                    onClicked: {
                        // Debounce because for some reason the button sometimes is actived twise in a short period
                        if (overview.monthSwitchDebounceActive === true) {
                            return;
                        }
                        overview.monthSwitchDebounceActive = true;
                        monthSwitchDebounceTimer.restart();

                        overview.transactionModel.previous_month();
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        id: currentMonthLabel
                        anchors.centerIn: parent
                        text: overview.transactionModel ? overview.transactionModel.current_month.toLocaleDateString(Qt.locale(), "MMMM yyyy") : ""
                        font.pointSize: Math.max(10, Math.min(parent.width, parent.height) * 0.25)
                        font.weight: Font.StyleItalic
                        color: Material.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Next month button
                Button {
                    id: nextMonthButton
                    Layout.preferredWidth: parent.width * monthSwitcher.buttonWidth
                    Layout.preferredHeight: parent.height * monthSwitcher.buttonHeight
                    flat: true

                    contentItem: Text {
                        text: "❯"
                        font.pixelSize: Math.max(16, Math.min(monthSwitcher.width, monthSwitcher.height) * monthSwitcher.arrowSize)
                        color: nextMonthButton.hovered ? Material.accent : Material.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    ToolTip {
                        visible: nextMonthButton.hovered
                        text: qsTr("Switch to next month")
                        delay: 1000
                        timeout: 5000
                        y: -height - 5
                    }

                    onClicked: {
                        // Debounce because for some reason the button sometimes is actived twise in a short period
                        if (overview.monthSwitchDebounceActive === true) {
                            return;
                        }
                        overview.monthSwitchDebounceActive = true;
                        monthSwitchDebounceTimer.restart();

                        overview.transactionModel.next_month();
                    }
                }
            }
        }

        // Overview main content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            radius: 8
            border.width: 1
            border.color: Material.dividerColor

            // Use gradient background
            color: "Transparent"
            GradientBackground {
                radius: 8
            }

            // Shadow effect
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: -2
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: "#30000000"
            }

            // Transaction List, Monthly List
            ColumnLayout {
                anchors.fill: parent

                // Transaction List
                ScrollingList {
                    Layout.alignment: Qt.AlignTop
                    Layout.margins: overview.listMargins
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.55

                    model: overview.transactionModel
                    headerText: qsTr("Click the plus icon to add a new transaction")

                    delegate: TransactionDelegate {
                        window: overview.window

                        onTransactionEdit: function (transactionData) {
                            transactionEditor.resetFields();

                            // Sync category field
                            transactionEditor.syncCategoryField();

                            // Set the editor context to Edit
                            overview.currentEditorContext = Overview.EditorContext.Edit;

                            // Set the transaction ID to edit
                            overview.currentlySelectedTransactionId = transactionData.index;

                            // Set fields to match transaction data
                            transactionEditor.setFields({
                                name: transactionData.name,
                                amount: transactionData.amount,
                                executionDate: {
                                    year: transactionData.date.getFullYear(),
                                    month: transactionData.date.getMonth(),
                                    day: transactionData.date.getDate()
                                },
                                category: transactionData.category,
                                type: transactionData.type
                            });

                            // Set editor window text
                            transactionEditor.windowTitle = qsTr("Edit Transaction");
                            transactionEditor.finalazationText = qsTr("Apply changes");
                            transactionEditor.actionText = qsTr("Edit transaction properties for '%1'").arg(transactionData.name);

                            // Show the editor window
                            transactionEditor.show();
                        }

                        onTransactionDelete: function (transactionData) {
                            // Set the transaction ID to delete
                            overview.currentlySelectedTransactionId = transactionData.index;

                            // Set delete dialog title
                            transactionDeleteDialog.title = qsTr("Delete Transaction: %1").arg(transactionData.name);

                            // Open the delete confirmation dialog
                            transactionDeleteDialog.open();
                        }
                    }

                    onCreateButtonClicked: function () {
                        overview.currentEditorContext = Overview.EditorContext.Create;

                        transactionEditor.resetFields();

                        // Sync category field
                        transactionEditor.syncCategoryField();

                        let currentDate = new Date();
                        let displayedDate = overview.transactionModel.current_month;

                        if (displayedDate.getFullYear() === currentDate.getFullYear() && displayedDate.getMonth() === currentDate.getMonth()) {
                            transactionEditor.setFields({
                                executionDate: {
                                    year: currentDate.getFullYear(),
                                    month: currentDate.getMonth(),
                                    day: currentDate.getDate()
                                }
                            });
                        } else {
                            transactionEditor.setFields({
                                executionDate: {
                                    year: displayedDate.getFullYear(),
                                    month: displayedDate.getMonth()
                                }
                            });
                        }

                        transactionEditor.windowTitle = qsTr("Create New Transaction");
                        transactionEditor.finalazationText = qsTr("Create");
                        transactionEditor.actionText = qsTr("Create a new transaction");

                        transactionEditor.show();
                    }
                }

                // Monthly List
                ScrollingList {
                    Layout.leftMargin: overview.listMargins
                    Layout.rightMargin: overview.listMargins
                    Layout.bottomMargin: overview.listMargins
                    Layout.alignment: Qt.AlignBottom
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    fontScaleFactor: 0.055
                    headerHeightFactor: 0.07
                    gradientOpacity: 0.8 // Fix gradient not displaying properly
                    headerText: qsTr("Click the plus icon to add a monthly recurring transaction")
                    model: overview.monthlyTransactionModel

                    delegate: MTransactionDelegate {
                        window: overview.window

                        onMonthlyTransactionEdit: function (monthlyTransactionData) {
                            monthlyTransactionEditor.resetFields();

                            // Sync category field
                            monthlyTransactionEditor.syncCategoryField();

                            // Set the editor context to Edit
                            overview.currentEditorContext = Overview.EditorContext.Edit;

                            // Set the transaction ID to edit
                            overview.currentlySelectedTransactionId = monthlyTransactionData.index;

                            monthlyTransactionEditor.setFields({
                                name: monthlyTransactionData.name,
                                amount: monthlyTransactionData.amount,
                                startDate: {
                                    year: monthlyTransactionData.startDate.getFullYear(),
                                    month: monthlyTransactionData.startDate.getMonth(),
                                    day: monthlyTransactionData.startDate.getDate()
                                },
                                endDate: monthlyTransactionData.endDate ? {
                                    year: monthlyTransactionData.endDate.getFullYear(),
                                    month: monthlyTransactionData.endDate.getMonth(),
                                    day: monthlyTransactionData.endDate.getDate()
                                } : null,
                                category: monthlyTransactionData.category,
                                type: monthlyTransactionData.type,
                                dayOfMonth: monthlyTransactionData.dayOfMonth
                            });

                            // Set editor window text
                            monthlyTransactionEditor.windowTitle = qsTr("Edit Monthly Recurring Transaction");
                            monthlyTransactionEditor.finalazationText = qsTr("Apply changes");
                            monthlyTransactionEditor.actionText = qsTr("Edit monthly recurring transaction properties for '%1'").arg(monthlyTransactionData.name);

                            // Set editor window size/constraints
                            monthlyTransactionEditor.minimumWidth = 500;
                            monthlyTransactionEditor.minimumHeight = 550;

                            monthlyTransactionEditor.maximumWidth = 1000;
                            monthlyTransactionEditor.maximumHeight = 750;

                            monthlyTransactionEditor.initialWidth = 800;
                            monthlyTransactionEditor.initialHeight = 600;

                            // Set field edit mode to false (this disables date related modification while editing)
                            monthlyTransactionEditor.setEditMode(true);

                            // Show the editor window
                            monthlyTransactionEditor.show();
                        }

                        onMonthlyTransactionDelete: function (monthlyTransactionData) {
                            // Set the transaction ID to delete
                            overview.currentlySelectedTransactionId = monthlyTransactionData.index;

                            // Set delete dialog title
                            monthlyTransactionDeleteDialog.title = qsTr("Delete Monthly Recurring Transaction: %1").arg(monthlyTransactionData.name);

                            // Open the delete confirmation dialog
                            monthlyTransactionDeleteDialog.open();
                        }
                    }

                    onCreateButtonClicked: {
                        // Set editor contex
                        overview.currentEditorContext = Overview.EditorContext.Create;

                        // Reset fields
                        monthlyTransactionEditor.resetFields();

                        // Sync category field
                        monthlyTransactionEditor.syncCategoryField();

                        // Set editor window size/constraints
                        monthlyTransactionEditor.minimumWidth = 500;
                        monthlyTransactionEditor.minimumHeight = 900;

                        monthlyTransactionEditor.maximumWidth = 1000;
                        monthlyTransactionEditor.maximumHeight = 1000;

                        monthlyTransactionEditor.initialWidth = 1000;
                        monthlyTransactionEditor.initialHeight = 900;

                        // Set field edit mode to false (this enables date related modification upon creation)
                        monthlyTransactionEditor.setEditMode(false);

                        // Set start date to current date
                        let currentDate = new Date();

                        monthlyTransactionEditor.setFields({
                            startDate: {
                                year: currentDate.getFullYear(),
                                month: currentDate.getMonth(),
                                day: currentDate.getDate()
                            }
                        });

                        monthlyTransactionEditor.windowTitle = qsTr("Create New Monthly Recurring Transaction");
                        monthlyTransactionEditor.finalazationText = qsTr("Create");
                        monthlyTransactionEditor.actionText = qsTr("Create a new monthly recurring transaction");

                        monthlyTransactionEditor.show();
                    }
                }
            }
        }
    }
}
