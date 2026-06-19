# xDiff

`xDiff` is a lightweight **AutoHotkey v2 (AHK v2)** script that integrates **Meld** (or any file comparison tool) directly into the Windows File Explorer right-click context menu. It mimics the behavior of professional diff tools like *Beyond Compare*.

You can select one file/folder as the "Left" comparison target and then compare it with a "Right" target in another location with just two clicks.

## Features

- **No Admin Privileges Required**: Registers context menu entries under `HKEY_CURRENT_USER` (HKCU).
- **Multi-language Support**: Automatically detects and switches between English and Chinese (Simplified/Traditional) UI/Menu text based on system locale settings.
- **Meld Integration**: Automatically invokes Meld (`C:\Program Files\Meld\Meld.exe`) to perform comparisons on files or directories.
- **Silent Left Item Selection**: Selecting the left item is done silently without annoying popups or system notifications.
- **Context Menu Icons**: Automatically sets the Meld icon for context menu items if installed, with a clean system fallback.
- **Management GUI**: Simply run the script without arguments to open a clean GUI to register/unregister the shell menu easily.
- **Debug Trace Support**: Traces compared filenames to system debugging output (`OutputDebug`) for development troubleshooting.

## Requirements

- [AutoHotkey v2](https://www.autohotkey.com/)
- [Meld for Windows](https://meldmerge.org/) (Default installation directory assumed: `C:\Program Files\Meld\Meld.exe`)

## Usage

### 1. Register the Context Menu
Double-click `xDiff.ahk` to launch the settings GUI. Click **"添加右键菜单" (Add Context Menu)**. This registers the right-click shell extensions for both files (`*`) and directories.

### 2. Compare Files or Directories
1. Right-click any file or folder and select **"选择左边进行比较" (Select Left to Compare)**. The script will quietly record its path.
2. Navigate to another location, right-click the file or folder you want to compare it with, and click **"与左边进行比较" (Compare)**.
3. Meld will be launched automatically to compare the two items.

### 3. Remove the Context Menu
If you want to remove the context menu, run `xDiff.ahk` again and click **"移除右键菜单" (Remove Context Menu)**.

## File Structure

- `xDiff.ahk`: The main AutoHotkey script containing argument parsing, registry actions, and the configuration GUI.
- `config.ini`: Automatically created to store the state (e.g. the path of the selected left file/folder).
