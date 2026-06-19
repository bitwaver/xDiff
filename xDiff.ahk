#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================
; Localization Configuration
; ==========================================
Global IsZH := (SubStr(A_Language, -2) = "04")

Global Lang := {
    MenuSelectLeft: IsZH ? "xDiff-选择左边文件" : "xDiff-Select Left File",
    MenuCompare: IsZH ? "xDiff-比较" : "xDiff-Compare",
    
    ErrPathNotExists: IsZH ? "选择的路径不存在：" : "Selected path does not exist: ",
    ErrRightNotExists: IsZH ? "右侧路径不存在：" : "Right path does not exist: ",
    ErrLeftNotSelected: IsZH ? "尚未选择左侧文件/文件夹。请先右键选择一个项并点击“选择左边文件”。" : "No Left file/folder selected. Please right-click an item and click 'Select Left File' first.",
    ErrLeftNotExists: IsZH ? "记录的左侧路径已不存在：`n`n" : "Recorded Left path no longer exists: `n`n",
    ErrLeftReSelect: IsZH ? "`n`n请重新选择左侧。" : "`n`nPlease re-select Left.",
    ErrTitle: IsZH ? "xDiff 错误" : "xDiff Error",
    HintTitle: IsZH ? "xDiff 提示" : "xDiff Hint",
    SuccessTitle: IsZH ? "xDiff 成功" : "xDiff Success",
    
    DebugTitle: IsZH ? "【对比调试信息】" : "[Comparison Debug Info]",
    DebugLeftName: IsZH ? "左侧名称: " : "Left Name: ",
    DebugLeftPath: IsZH ? "左侧路径: " : "Left Path: ",
    DebugRightName: IsZH ? "右侧名称: " : "Right Name: ",
    DebugRightPath: IsZH ? "右侧路径: " : "Right Path: ",
    DebugTitleBox: IsZH ? "xDiff 调试输出" : "xDiff Debug Output",
    
    TrayComparing: IsZH ? "正在调用 Meld 进行对比..." : "Calling Meld for comparison...",
    TrayCompareTitle: IsZH ? "xDiff - 对比中" : "xDiff - Comparing",
    ErrMeldLaunchFailed: IsZH ? "启动 Meld 失败：`n" : "Failed to launch Meld: `n",
    ErrMeldNotFound: IsZH ? "未在指定路径找到 Meld：`n" : "Meld not found at specified path: `n",
    ErrMeldFallbackMsg: IsZH ? "`n`n将通过调试弹窗展示对比路径：`n`n" : "`n`nWill show comparison paths in debug window: `n`n",
    
    RegSuccess: IsZH ? "右键菜单注册成功（已配置图标）！`n您现在可以右键点击文件或文件夹进行对比了。" : "Context menu registered successfully (with icons)!`nYou can now right-click files or folders to compare.",
    RegFailed: IsZH ? "注册失败：`n" : "Registration failed: `n",
    RegFailedAdmin: IsZH ? "`n`n请尝试以管理员身份运行此脚本。" : "`n`nPlease try running this script as administrator.",
    UnregSuccess: IsZH ? "右键菜单已成功注销！" : "Context menu unregistered successfully!",
    UnregFailed: IsZH ? "注销失败：`n" : "Unregistration failed: `n",
    
    GuiTitle: IsZH ? "xDiff 右键对比工具管理器" : "xDiff Context Menu Manager",
    GuiConfigGroup: IsZH ? "对比工具配置" : "Diff Tool Configuration",
    GuiBrowseBtn: IsZH ? "浏览..." : "Browse...",
    GuiSupportLabel: IsZH ? "支持工具：Beyond Compare, WinMerge, VS Code, Meld 等。" : "Supported Tools: Beyond Compare, WinMerge, VS Code, Meld, etc.",
    GuiMenuGroup: IsZH ? "右键菜单管理" : "Context Menu Management",
    GuiRegBtn: IsZH ? "添加右键菜单" : "Add Context Menu",
    GuiUnregBtn: IsZH ? "移除右键菜单" : "Remove Context Menu",
    
    SelectToolTitle: IsZH ? "选择对比工具的可执行文件" : "Select Diff Tool Executable",
    SelectToolFilter: IsZH ? "程序 (*.exe)" : "Programs (*.exe)"
}

; ==========================================
; Config & Data File Paths
; ==========================================
Global ConfigFile := A_ScriptDir "\config.ini"

; Initialize config if not exists
If !FileExist(ConfigFile) {
    IniWrite("", ConfigFile, "Settings", "DiffTool")
    IniWrite("", ConfigFile, "Settings", "History")
    IniWrite("", ConfigFile, "State", "LeftPath")
}

; ==========================================
; Argument Parsing
; ==========================================
If A_Args.Length >= 2 {
    Action := A_Args[1]
    TargetPath := A_Args[2]
    
    If (Action = "select") {
        SelectLeft(TargetPath)
    } Else If (Action = "compare") {
        CompareWithLeft(TargetPath)
    }
    ExitApp
} Else {
    ; No arguments: Show Management GUI
    ShowGUI()
}

; ==========================================
; Core Functions
; ==========================================

; Record the left path for comparison
SelectLeft(Path) {
    If !FileExist(Path) {
        MsgBox(Lang.ErrPathNotExists Path, Lang.ErrTitle, "Iconx")
        Return
    }
    
    IniWrite(Path, ConfigFile, "State", "LeftPath")
}

; Compare the current path with the recorded left path
CompareWithLeft(RightPath) {
    If !FileExist(RightPath) {
        MsgBox(Lang.ErrRightNotExists RightPath, Lang.ErrTitle, "Iconx")
        Return
    }
    
    LeftPath := IniRead(ConfigFile, "State", "LeftPath", "")
    
    If (LeftPath = "") {
        MsgBox(Lang.ErrLeftNotSelected, Lang.HintTitle, "Icon!")
        Return
    }
    
    If !FileExist(LeftPath) {
        MsgBox(Lang.ErrLeftNotExists LeftPath Lang.ErrLeftReSelect, Lang.ErrTitle, "Iconx")
        Return
    }
    
    ; Extract file/folder names
    SplitPath(LeftPath, &LeftName)
    SplitPath(RightPath, &RightName)
    
    ; Debug output of the two paths
    DebugMsg := Lang.DebugTitle "`n`n" .
                Lang.DebugLeftName LeftName "`n" .
                Lang.DebugLeftPath LeftPath "`n`n" .
                Lang.DebugRightName RightName "`n" .
                Lang.DebugRightPath RightPath
    OutputDebug(DebugMsg "`n")
    
    ; Launch diff tool
    DiffTool := IniRead(ConfigFile, "Settings", "DiffTool", "")
    
    ; If not configured or not found, try default Meld locations
    If (DiffTool = "" || !FileExist(DiffTool)) {
        If FileExist("E:\Program Files\Meld\Meld.exe") {
            DiffTool := "E:\Program Files\Meld\Meld.exe"
        } Else If FileExist("C:\Program Files\Meld\Meld.exe") {
            DiffTool := "C:\Program Files\Meld\Meld.exe"
        } Else {
            DiffTool := "E:\Program Files\Meld\Meld.exe" ; Fallback label reference
        }
    }
    
    If FileExist(DiffTool) {
        Try {
            Run('"' DiffTool '" "' LeftPath '" "' RightPath '"')
        } Catch Error as err {
            MsgBox(Lang.ErrMeldLaunchFailed err.Message, Lang.ErrTitle, "Iconx")
        }
    } Else {
        MsgBox(Lang.ErrMeldNotFound DiffTool Lang.ErrMeldFallbackMsg DebugMsg, Lang.ErrTitle, "Iconx")
    }
}

; ==========================================
; Registry Registration
; ==========================================
RegisterMenu() {
    ; Define command line
    If A_IsCompiled {
        CmdSelect := '"' A_ScriptFullPath '" "select" "%1"'
        CmdCompare := '"' A_ScriptFullPath '" "compare" "%1"'
    } Else {
        CmdSelect := '"' A_AhkPath '" "' A_ScriptFullPath '" "select" "%1"'
        CmdCompare := '"' A_AhkPath '" "' A_ScriptFullPath '" "compare" "%1"'
    }
    
    Classes := ["*", "Directory"]
    
    ; Determine icon path
    IconPath := IniRead(ConfigFile, "Settings", "DiffTool", "")
    If (IconPath = "" || !FileExist(IconPath)) {
        If FileExist("E:\Program Files\Meld\Meld.exe") {
            IconPath := "E:\Program Files\Meld\Meld.exe"
        } Else If FileExist("C:\Program Files\Meld\Meld.exe") {
            IconPath := "C:\Program Files\Meld\Meld.exe"
        } Else {
            IconPath := "shell32.dll,22" ; Fallback system icon
        }
    }
    
    Try {
        For Cls in Classes {
            ; Select Left
            RegWrite(Lang.MenuSelectLeft, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft")
            RegWrite(IconPath, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft", "Icon")
            RegWrite(CmdSelect, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft\command")
            
            ; Compare
            RegWrite(Lang.MenuCompare, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare")
            RegWrite(IconPath, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare", "Icon")
            RegWrite(CmdCompare, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare\command")
        }
        MsgBox(Lang.RegSuccess, Lang.SuccessTitle, "Iconi")
    } Catch Error as err {
        MsgBox(Lang.RegFailed err.Message Lang.RegFailedAdmin, Lang.ErrTitle, "Iconx")
    }
}

UnregisterMenu() {
    Classes := ["*", "Directory"]
    
    Try {
        For Cls in Classes {
            Try RegDeleteKey("HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft")
            Try RegDeleteKey("HKCU\Software\Classes\" Cls "\shell\xDiffCompare")
        }
        MsgBox(Lang.UnregSuccess, Lang.SuccessTitle, "Iconi")
    } Catch Error as err {
        MsgBox(Lang.UnregFailed err.Message, Lang.ErrTitle, "Iconx")
    }
}

; ==========================================
; GUI Interface
; ==========================================
ShowGUI() {
    MyGui := Gui("+Resize", Lang.GuiTitle)
    MyGui.SetFont("s10", "Microsoft YaHei")
    
    MyGui.Add("GroupBox", "w450 h120", Lang.GuiConfigGroup)
    
    CurrentTool := IniRead(ConfigFile, "Settings", "DiffTool", "")
    HistoryStr := IniRead(ConfigFile, "Settings", "History", "")
    
    ; Parse history list
    HistoryList := []
    If (HistoryStr != "") {
        Loop Parse, HistoryStr, "|" {
            If (A_LoopField != "") {
                HistoryList.Push(A_LoopField)
            }
        }
    }
    
    ; Ensure current tool is in the list
    HasCurrent := False
    For Item in HistoryList {
        If (Item = CurrentTool) {
            HasCurrent := True
            Break
        }
    }
    If (!HasCurrent && CurrentTool != "") {
        HistoryList.Push(CurrentTool)
    }
    
    ; Add ComboBox instead of Edit
    ToolCombo := MyGui.Add("ComboBox", "xp+20 yp+30 w320 r5 vToolCombo", HistoryList)
    ToolCombo.Text := CurrentTool
    ToolCombo.OnEvent("Change", (Ctrl, *) => OnComboChange(Ctrl))
    
    BrowseBtn := MyGui.Add("Button", "x+10 yp w80", Lang.GuiBrowseBtn)
    
    MyGui.Add("Text", "xs+20 yp+45 cGray", Lang.GuiSupportLabel)
    
    MyGui.Add("GroupBox", "xs w450 h90", Lang.GuiMenuGroup)
    RegBtn := MyGui.Add("Button", "xp+20 yp+30 w190 h40", Lang.GuiRegBtn)
    UnregBtn := MyGui.Add("Button", "x+20 yp w190 h40", Lang.GuiUnregBtn)
    
    ; Define button callbacks
    BrowseBtn.OnEvent("Click", (*) => OnBrowse(ToolCombo))
    RegBtn.OnEvent("Click", (*) => RegisterMenu())
    UnregBtn.OnEvent("Click", (*) => UnregisterMenu())
    
    MyGui.OnEvent("Close", (*) => ExitApp())
    MyGui.Show("w490")
}

OnComboChange(Ctrl) {
    SelectedFile := Ctrl.Text
    If (SelectedFile != "") {
        IniWrite(SelectedFile, ConfigFile, "Settings", "DiffTool")
        UpdateRegistryIcon(SelectedFile)
    }
}

OnBrowse(Ctrl) {
    SelectedFile := FileSelect(3, , Lang.SelectToolTitle, Lang.SelectToolFilter)
    If (SelectedFile != "") {
        ; Load current history
        HistoryStr := IniRead(ConfigFile, "Settings", "History", "")
        HistoryList := []
        If (HistoryStr != "") {
            Loop Parse, HistoryStr, "|" {
                If (A_LoopField != "") {
                    HistoryList.Push(A_LoopField)
                }
            }
        }
        
        ; Check if it already exists
        Exists := False
        For Item in HistoryList {
            If (Item = SelectedFile) {
                Exists := True
                Break
            }
        }
        
        If (!Exists) {
            HistoryList.Push(SelectedFile)
            ; Build history string
            NewHistoryStr := ""
            For Item in HistoryList {
                NewHistoryStr .= (NewHistoryStr = "" ? "" : "|") . Item
            }
            IniWrite(NewHistoryStr, ConfigFile, "Settings", "History")
            
            ; Re-populate ComboBox
            Ctrl.Delete()
            Ctrl.Add(HistoryList)
        }
        
        Ctrl.Text := SelectedFile
        IniWrite(SelectedFile, ConfigFile, "Settings", "DiffTool")
        UpdateRegistryIcon(SelectedFile)
    }
}

UpdateRegistryIcon(IconPath) {
    If (IconPath = "" || !FileExist(IconPath))
        Return
        
    Classes := ["*", "Directory"]
    For Cls in Classes {
        Try {
            ; Check if registered by reading command subkey
            RegRead("HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft\command")
            ; Update the Icon value
            RegWrite(IconPath, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft", "Icon")
            RegWrite(IconPath, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare", "Icon")
        }
    }
}
