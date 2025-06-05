<div align="center">

# Personal Finance Management
**A simple app for keeping track of personal finances.**

![thumbnail](./Thumbnail.png)
</div>

## About
Personal Finance Management, or PFM for short, is a straightforward application designed for managing personal finances. The app enables users to track their financial transactions and visualize financial patterns through graphical representation. 

This project was built as a first-year HOU university assignment. The project topic, requirements, and the main language used have been dictated by the university. While we aimed to maintain professional development standards, we adopted a more beginner-friendly approach suitable for first-year students. Due to time constraints and academic deadlines, certain non required features and complexities have been omitted.

## Running from source 
This requires some technical expertise. Alternatively, you can use the compiled executable from the [latest release](https://github.com/Yiannis123Git/PersonalFinanceManagement/releases/latest).

### Prerequisites
- **Python 3.13** must be installed on your system. Download it from [python.org](https://www.python.org/downloads/)
- **Git** must be installed on your device. Download it from [git-scm.com](https://git-scm.com/downloads)

### Clone the repository
```bash
git clone https://github.com/Yiannis123Git/PersonalFinanceManagement.git
cd PersonalFinanceManagement
```

### Installing dependencies
This project uses [Poetry](https://python-poetry.org/) for dependency management. Installing Poetry via pipx is recommended but there are other available methods as well. For more info take a look at the [Poetry documentation page](https://python-poetry.org/docs/) installation instructions.

After installing Poetry, run `poetry install` on the cloned repository.

### Generate qml_rc.py file
After installing the project's dependencies you can generate a qml python resource file by running the following at the project's root

```bash
poetry run pyside6-rcc ./src/ui/qml.qrc -o ./src/ui/qml_rc.py
```

### Running the program
Once you have completed the previous steps, you can run the application using the following command:
```bash
poetry run python ./src/main.py  
```