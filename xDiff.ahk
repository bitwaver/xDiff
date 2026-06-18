#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================
; Config & Data File Paths
; ==========================================
Global ConfigFile := A_ScriptDir "\config.ini"

; Initialize config if not exists
If !FileExist(ConfigFile) {
    IniWrite("", ConfigFile, "Settings", "DiffTool")
    IniWrite("", ConfigFile, "State", "LeftPath")
}

; ==========================================
; Argument Parsing
; ==========================================
If A_Args.Length >= 2 {
    Action := A_Args[1]
    ; Reconstruct target path in case of spaces if A_Args split them, though OS passing %1 usually keeps it as one arg.
    ; AHK v2's A_Args[2] contains the fully resolved path from %1.
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
        MsgBox("选择的路径不存在：" Path, "xDiff 错误", "Iconx")
        Return
    }
    
    IniWrite(Path, ConfigFile, "State", "LeftPath")
}

; Compare the current path with the recorded left path
CompareWithLeft(RightPath) {
    If !FileExist(RightPath) {
        MsgBox("右侧路径不存在：" RightPath, "xDiff 错误", "Iconx")
        Return
    }
    
    LeftPath := IniRead(ConfigFile, "State", "LeftPath", "")
    
    If (LeftPath = "") {
        MsgBox("尚未选择左侧文件/文件夹。请先右键选择一个项并点击“选择左边进行比较”。", "xDiff 提示", "Icon!")
        Return
    }
    
    If !FileExist(LeftPath) {
        MsgBox("记录的左侧路径已不存在：`n`n" LeftPath "`n`n请重新选择左侧。", "xDiff 错误", "Iconx")
        Return
    }
    

    
    ; Extract file/folder names
    SplitPath(LeftPath, &LeftName)
    SplitPath(RightPath, &RightName)
    
    ; Debug output of the two paths
    DebugMsg := "【对比调试信息】`n`n" .
                "左侧名称: " LeftName "`n" .
                "左侧路径: " LeftPath "`n`n" .
                "右侧名称: " RightName "`n" .
                "右侧路径: " RightPath
    OutputDebug(DebugMsg "`n")
    
    ; Launch Meld diff tool
    MeldPath := "E:\Program Files\Meld\Meld.exe"
    If FileExist(MeldPath) {
        TrayTip("正在调用 Meld 进行对比...", "xDiff - 对比中")
        Try {
            Run('"' MeldPath '" "' LeftPath '" "' RightPath '"')
        } Catch Error as err {
            MsgBox("启动 Meld 失败：`n" err.Message, "xDiff 错误", "Iconx")
        }
    } Else {
        MsgBox("未在指定路径找到 Meld：`n" MeldPath "`n`n将通过调试弹窗展示对比路径：`n`n" DebugMsg, "xDiff 错误", "Iconx")
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
    IconPath := "E:\Program Files\Meld\Meld.exe"
    If !FileExist(IconPath) {
        IconPath := "shell32.dll,22" ; Fallback system icon
    }
    
    Try {
        For Cls in Classes {
            ; Select Left
            RegWrite("xDiff-选择左边文件", "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft")
            RegWrite(IconPath, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft", "Icon")
            RegWrite(CmdSelect, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft\command")
            
            ; Compare
            RegWrite("xDiff-比较", "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare")
            RegWrite(IconPath, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare", "Icon")
            RegWrite(CmdCompare, "REG_SZ", "HKCU\Software\Classes\" Cls "\shell\xDiffCompare\command")
        }
        MsgBox("右键菜单注册成功（已配置图标）！`n您现在可以右键点击文件或文件夹进行对比了。", "xDiff 成功", "Iconi")
    } Catch Error as err {
        MsgBox("注册失败：`n" err.Message "`n`n请尝试以管理员身份运行此脚本。", "xDiff 错误", "Iconx")
    }
}

UnregisterMenu() {
    Classes := ["*", "Directory"]
    
    Try {
        For Cls in Classes {
            Try RegDeleteKey("HKCU\Software\Classes\" Cls "\shell\xDiffSelectLeft")
            Try RegDeleteKey("HKCU\Software\Classes\" Cls "\shell\xDiffCompare")
        }
        MsgBox("右键菜单已成功注销！", "xDiff 成功", "Iconi")
    } Catch Error as err {
        MsgBox("注销失败：`n" err.Message, "xDiff 错误", "Iconx")
    }
}

; ==========================================
; GUI Interface
; ==========================================
ShowGUI() {
    MyGui := Gui("+Resize", "xDiff 右键对比工具管理器")
    MyGui.SetFont("s10", "Microsoft YaHei")
    
    MyGui.Add("GroupBox", "w450 h120", "对比工具配置")
    
    CurrentTool := IniRead(ConfigFile, "Settings", "DiffTool", "")
    ToolEdit := MyGui.Add("Edit", "xp+20 yp+30 w320 r1 ReadOnly", CurrentTool)
    BrowseBtn := MyGui.Add("Button", "x+10 yp w80", "浏览...")
    
    MyGui.Add("Text", "xs+20 yp+45 cGray", "支持工具：Beyond Compare, WinMerge, VS Code, Meld 等。")
    
    MyGui.Add("GroupBox", "xs w450 h90", "右键菜单管理")
    RegBtn := MyGui.Add("Button", "xp+20 yp+30 w190 h40", "添加右键菜单")
    UnregBtn := MyGui.Add("Button", "x+20 yp w190 h40", "移除右键菜单")
    
    ; Define button callbacks
    BrowseBtn.OnEvent("Click", (*) => OnBrowse(ToolEdit))
    RegBtn.OnEvent("Click", (*) => RegisterMenu())
    UnregBtn.OnEvent("Click", (*) => UnregisterMenu())
    
    MyGui.OnEvent("Close", (*) => ExitApp())
    MyGui.Show("w490")
}

OnBrowse(EditCtrl) {
    SelectedFile := FileSelect(3, , "选择对比工具的可执行文件", "程序 (*.exe)")
    If (SelectedFile != "") {
        EditCtrl.Text := SelectedFile
        IniWrite(SelectedFile, ConfigFile, "Settings", "DiffTool")
    }
}


