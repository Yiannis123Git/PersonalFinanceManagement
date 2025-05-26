pragma Singleton

import QtQuick
import QtQuick.Controls.Material

// Handles the chromatic theme of the application

QtObject {
    id: themes

    // List of available themes
    readonly property var themesList: {
        "Light": {
            name: "Light theme",
            theme: Material.Light,
            accent: Material.Cyan,
            primary: Material.LightBlue,
            elevation: 6
        },
        "Dark": {
            name: "Dark theme",
            theme: Material.Dark,
            accent: Material.Indigo,
            primary: Material.DeepPurple,
            elevation: 6
        }
    }

    // Default theme
    property string defaultTheme: "Light"

    // Current theme internal property
    property string _currentTheme: "Light"

    // Public read-only property for external access
    readonly property string currentTheme: _currentTheme

    readonly property var current: themesList[_currentTheme] // qml will update this value and push updates when currentTheme changes

    // Function to set the theme (error handling)
    function setTheme(themeKey) {
        // Check if themeKey is valid
        if (!themesList[themeKey]) {

            // theme is invalid, fallback to default theme:
            console.error("Invalid theme key: " + themeKey + ". Falling back to default theme: " + themesList[defaultTheme].name);
            _currentTheme = defaultTheme;

            return false;
        }

        // Set current theme
        _currentTheme = themeKey;

        return true;
    }
}
