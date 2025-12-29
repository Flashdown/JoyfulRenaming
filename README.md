# JoyfulRenaming

A PowerShell script with GUI for advanced mass renaming of files or folders within a specific folder. Supports case-sensitivity, regular expressions, exclusion of file extensions, insert before/after match, simulation with preview, undo function, multilingual interface (English/German), and CLI mode.

![GUI Screenshot](https://github.com/Flashdown/JoyfulRenaming/blob/main/JoyfulRenaming.png)

## Features

- **GUI Interface**: User-friendly Windows Forms GUI for easy operation, with multilingual support (English as default, German available).
- **Search and Replace**: Replace strings in file or folder names, with option for case sensitivity.
- **Regex Support**: Use regular expressions for complex searches and replacements, including capture groups ($1, etc.).
- **Insert Before/After Match**: Insert text before or after a regex match (instead of replacing).
- **Exclude File Extension**: Change only the base name, leave the extension unchanged.
- **Rename Folders**: Option to rename folders instead of files.
- **Simulation**: Preview changes with customizable number of examples (default 5, 0 for all), colored highlighting (red for matches, green for changes).
- **Undo**: Undo the last renaming action.
- **CLI Support**: Full execution via command-line parameters, including simulate mode with GUI preview.
- **Encoding**: UTF-8 support for correct handling of special characters.
- **Additional GUI Features**: Provides the full CLI script parameters for the last executed simulation.

## Installation

1. Download and unpack the ZIP Release
2. Execute run.cmd (for GUI mode)

## Usage

### GUI Mode

Run the script without parameters: `.\JoyfulRenaming.ps1`

- Select language (English or German).
- Enter the folder path (or select via "Browse").
- Define "Search for" and "Replace/Insert with".
- Select options like Case Sensitive, Regex, Exclude Extension, Insert before/after, Rename Folders.
- Adjust number of simulation examples (0 for all).
- Click "Simulate" for preview.
- Click "Execute" to rename.
- "Undo" to revert.
- CLI parameters for the current setup are displayed after simulation for easy scripting.

### CLI Mode

Use parameters for automated execution:
```console
.\JoyfulRenaming.ps1 -FolderPath "C:\Path\To\Folder" -Search "old" -Replace "new" [-CaseSensitive] [-Regex] [-ExcludeExt] [-InsertAfter] [-InsertBefore] [-RenameFolders] [-Simulate]
```
- **-FolderPath**: Path to the folder (required).
- **-Search**: Search string (required).
- **-Replace**: Replacement or insertion string (required).
- **-CaseSensitive**: Respect case sensitivity.
- **-Regex**: Use regex.
- **-ExcludeExt**: Exclude file extension (relevant only for files).
- **-InsertAfter**: Insert after match (only with regex).
- **-InsertBefore**: Insert before match (only with regex).
- **-RenameFolders**: Rename folders instead of files.
- **-Simulate**: Simulate changes and show preview in GUI (for checking CLI parameters).

#### Examples

- Replace "old" with "new" in file names (case-insensitive, exclude ext):
```console
.\JoyfulRenaming.ps1 -FolderPath "C:\Test" -Search "old" -Replace "new" -ExcludeExt
```
- Regex replacement with capture group:
```console
.\JoyfulRenaming.ps1 -FolderPath "C:\Test" -Search "(\d+)" -Replace "Num$1" -Regex
```
- Simulate insert after match in folder names:
```console
.\JoyfulRenaming.ps1 -FolderPath "C:\Test" -Search "Project" -Replace "_v2" -Regex -InsertAfter -RenameFolders -Simulate
```
With `-Simulate`, the GUI opens with filled fields and automatically runs the simulation to verify the parameters.

## Notes

- The script skips files/folders if the new name already exists.

## License

This program is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License v3.0 for more details.


If issues arise or features are desired, create an issue in the repo.
