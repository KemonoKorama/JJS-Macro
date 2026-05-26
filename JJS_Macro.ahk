#Requires AutoHotkey v2.0
#SingleInstance Force

; Declare DPI awareness — avoid Windows automatically scaling and distorting GUI coordinates.
DllCall("SetProcessDPIAware")
SetKeyDelay(-1)

;==============================================
;=============== GLOBAL VARIABLES =============
;==============================================

Global INI_FILE       := "JJS Macro Setting.ini"
Global isChatting     := false
Global CurrentIndex   := IniRead(INI_FILE, "Settings", "LastChar", 1)
Global LastActionTime := A_TickCount

if !IniRead(INI_FILE, "Settings", "FwdKey", "")
    IniWrite("XButton2", INI_FILE, "Settings", "FwdKey")
if !IniRead(INI_FILE, "Settings", "BwdKey", "")
    IniWrite("XButton1", INI_FILE, "Settings", "BwdKey")

Global FwdKey        := IniRead(INI_FILE, "Settings", "FwdKey", "XButton2")
Global BwdKey        := IniRead(INI_FILE, "Settings", "BwdKey", "XButton1")
Global g_listenWhich := ""
Global g_listenStart := 0
Global g_listenIH    := 0
Global g_bsCount     := 0
Global g_bsDown      := false

; --- AUTO UPDATE SETTINGS ---
Global LOCAL_VERSION := "1.0.0" ; Mặc định trong script nếu chưa có version.txt
Global VERSION_FILE  := A_ScriptDir "\version.txt"
if FileExist(VERSION_FILE) {
    LOCAL_VERSION := StrTrim(FileRead(VERSION_FILE))
} else {
    FileAppend(LOCAL_VERSION, VERSION_FILE)
}
Global UPDATE_VERSION_URL := "https://raw.githubusercontent.com/KemonoKorama/JJS-Macro/main/version.txt"
Global UPDATE_EXE_URL     := "https://github.com/KemonoKorama/JJS-Macro/releases/latest/download/JJS_Macro.exe"
Global UPDATE_SCRIPT_URL  := "https://raw.githubusercontent.com/KemonoKorama/JJS-Macro/main/JJS_Macro.ahk"
Global AUTO_UPDATE_CHECK  := true
Global AUTO_UPDATE_DELAY  := 15000

;==============================================
;=============== CHARACTER DATA ===============
;==============================================
; n    = Character name shown in UI
; t    = Name color:  "b"=Blue  "r"=Red  ""=Gray(none)
; ↑ TO CHANGE A CHARACTER COLOR: edit the t field here
; f    = Forward label  ("-" = no action)
; fc   = Forward label color override  "b"/"r"/"" (auto)
; b    = Backward label ("-" = no action)
; bc   = Backward label color override "b"/"r"/"" (auto)
; info = Text shown when you HOLD \ on this character
; New line = use `n   Example:  "Line 1`nLine 2`nLine 3"
;==============================================

Global CharData := [
    {n: "Honored One",      t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Vessel",           t: "b", f: "Black Flash",   fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Restless Gambler", t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Ten Shadows",      t: "b", f: "R",             fc: "",  b: "G",            bc: "",  info: "(Placeholder)"},
    {n: "Perfection",       t: "b", f: "Pull Item",     fc: "",  b: "GG (ULT)",     bc: "",  info: "(Placeholder)"},
    {n: "Blood Manipulator",t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Switcher",         t: "b", f: "R (500ms) LMB", fc: "",  b: "R (250ms) LMB",bc: "",  info: "(Placeholder)"},
    {n: "Defense Attorney", t: "b", f: "3R (Dash)",     fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Cursed Partners",  t: "b", f: "3",             fc: "",  b: "Copy Wheels",  bc: "",  info: "(Placeholder)"},
    {n: "Puppet Master",    t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Head of the Hei",  t: "b", f: "Q",             fc: "",  b: "R",            bc: "",  info: "(Placeholder)"},
    {n: "Salaryman",        t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Disaster Plants",  t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "True Cannon",      t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Locust Guy",       t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Star Rage",        t: "r", f: "HOLD! (ULT)",   fc: "r", b: "Quick Reset",  bc: "b", info: "(Placeholder)"},
    {n: "Aspiring Mangaka", t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Lucky Coward",     t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"},
    {n: "Crow Charmer",     t: "",  f: "-",             fc: "",  b: "-",            bc: "",  info: "(Placeholder)"}
]

;==============================================
;============= GUI: MAIN INFO PANEL ===========
;==============================================

MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound", "JJS_Main")
MyGui.BackColor := "EEEEEE"
WinSetTransparent(217, MyGui)

; ── TOP: Character carousel ──
MyGui.SetFont("s9  cAAAAAA Bold w700", "Segoe UI"), Text_FarUp    := MyGui.Add("Text", "x0 y8   w320 Center", "")
MyGui.SetFont("s12 c888888 Bold w700", "Segoe UI"), Text_NearUp   := MyGui.Add("Text", "x0 y28  w320 Center", "")
MyGui.SetFont("s18 c000000 Bold w700", "Segoe UI"), Text_Main     := MyGui.Add("Text", "x0 y52  w320 Center", "")
MyGui.SetFont("s12 c888888 Bold w700", "Segoe UI"), Text_NearDown := MyGui.Add("Text", "x0 y88  w320 Center", "")
MyGui.SetFont("s9  cAAAAAA Bold w700", "Segoe UI"), Text_FarDown  := MyGui.Add("Text", "x0 y110 w320 Center", "")

; ── SEPARATOR ──
MyGui.Add("Text", "x10 y130 w300 h1 BackgroundAAAAAA", "")

; ── BOTTOM: Forward / Backward ──
MyGui.SetFont("s9 c555555 Bold w700", "Segoe UI")
Text_F_Label := MyGui.Add("Text", "x14 y140 w68", GetBindLabel(FwdKey, "Forward"))
Text_B_Label := MyGui.Add("Text", "x14 y160 w68", GetBindLabel(BwdKey, "Backward"))

; Vertical separator between label and action
MyGui.Add("Text", "x83 y140 w1 h36 BackgroundAAAAAA", "")

MyGui.SetFont("s9 c0066CC Bold w700", "Segoe UI")
Text_F_Desc  := MyGui.Add("Text", "x90 y140 w216", "")
Text_B_Desc  := MyGui.Add("Text", "x90 y160 w216", "")

MyGui.SetFont("s7 cAAAAAA w400", "Segoe UI")
MyGui.Add("Text", "x0 y182 w320 Center", "(By: Kemono)")

UpdateGUI()
Global GuiW := 320, GuiH := 200
SetWindowRgn(MyGui.Hwnd, 0, 0, GuiW, GuiH, 20, 20)

;==============================================
;============= GUI: CHAT INDICATOR ============
;==============================================

ChatGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound", "JJS_Chat")
ChatGui.BackColor := "FF4444"
ChatGui.SetFont("s11 cWhite Bold w700", "Segoe UI")
ChatGui.Add("Text", "x0 y0 w160 h35 Center +0x200", "Chat mode: ON")
WinSetTransparent(230, ChatGui)
SetWindowRgn(ChatGui.Hwnd, 0, 0, 160, 35, 15, 15)

;==============================================
;======== GUI: HELP PANEL (hold \) ============
;==============================================
; Content comes from the "info" field in CharData
; Edit info: "Line1`nLine2`nLine3"

Global HelpW := 300, helpActive := false
HelpGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound", "JJS_Help")
HelpGui.BackColor := "EEEEEE"
WinSetTransparent(217, HelpGui)
HelpGui.SetFont("s10 Bold w700 c0066CC", "Segoe UI")
HelpHeader  := HelpGui.Add("Text", "x0 y0 w" HelpW " h34 Center +0x200", "")
HelpGui.Add("Text", "x10 y32 w" (HelpW-20) " h1 BackgroundAAAAAA", "")
HelpGui.SetFont("s9 w400 c555555", "Segoe UI")
HelpContent := HelpGui.Add("Text", "x14 y44 w" (HelpW-28) " h60", "")

;==============================================
;============= GUI: WELCOME SCREEN ============
;==============================================
; 5 pages: Welcome | Keybinds | Controls Setup | Color Legend | All Set

Global WelPage := 1, WelW := 600, WelH := 360
WelGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "JJS_Welcome")
WelGui.BackColor := "EEEEEE"
WinSetTransparent(217, WelGui)

; --- Page 1: Welcome ---
WelGui.SetFont("s26 Bold w900 c2D2D2D", "Segoe UI")
P1_Title := WelGui.Add("Text", "x20 y48 w560 Center", "WELCOME")
WelGui.SetFont("s12 Bold w700 c0066CC", "Segoe UI")
P1_Sub   := WelGui.Add("Text", "x20 y88 w560 Center", "Kemono Macro")
WelGui.SetFont("s10 w400 c888888", "Segoe UI")
P1_Body  := WelGui.Add("Text", "x80 y128 w440 Center", "Your personal macro assistant for Jujutsu Shenanigans.`nWe'll get you set up in just a moment — let's go!")
WelGui.SetFont("s8 w400 cBBBBBB", "Segoe UI")
P1_By    := WelGui.Add("Text", "x20 y270 w560 Center", "(By: Kemono)")

; --- Page 2: Keybinds ---
WelGui.SetFont("s16 Bold w900 c2D2D2D", "Segoe UI")
P2_Title := WelGui.Add("Text", "x20 y22 w560 Center", "KEYBINDS")
WelGui.SetFont("s10 Bold w700 c0066CC", "Segoe UI")
P2_KeyL  := WelGui.Add("Text", "x70 y60 w160", "[ and ]`nHold \`n\ \ \")
WelGui.SetFont("s10 w400 c333333", "Segoe UI")
P2_KeyR  := WelGui.Add("Text", "x240 y60 w310", "Switch character`nCharacter info`nOpen bind settings")
P2_Sep   := WelGui.Add("Text", "x50 y122 w500 h1 BackgroundCCCCCC", "")
WelGui.SetFont("s9 w400 c555555", "Segoe UI")
P2_Note1 := WelGui.Add("Text", "x50 y134 w500", "💬  Chat mode  —  Macros pause automatically while you're in chat. Type freely.")
P2_Note2 := WelGui.Add("Text", "x50 y158 w500", "🎮  Roblox only  —  Won't interfere with any other window.")
P2_Note3 := WelGui.Add("Text", "x50 y182 w500", "💾  Last save  —  Remembers your last selected character when you reopen.")
P2_Sep2  := WelGui.Add("Text", "x50 y206 w500 h1 BackgroundCCCCCC", "")
WelGui.SetFont("s9 w400 c888888", "Segoe UI")
P2_Note4 := WelGui.Add("Text", "x50 y214 w500", "📝  Message Emote users  —  Press / before typing to activate chat mode.")

; --- Page 3: Controls Setup ---
WelGui.SetFont("s16 Bold w900 c2D2D2D", "Segoe UI")
P3_Title   := WelGui.Add("Text", "x20 y22 w560 Center", "CONTROLS SETUP")
WelGui.SetFont("s9 w400 c888888", "Segoe UI")
P3_Sub     := WelGui.Add("Text", "x20 y56 w560 Center", "Click Set, then press any key or button.")
WelGui.SetFont("s10 Bold w600 c333333", "Segoe UI")
P3_FwdLbl  := WelGui.Add("Text", "x70 y108 w150", "Forward macro:")
WelGui.SetFont("s10 Bold w700 c0066CC", "Segoe UI")
P3_FwdDisp := WelGui.Add("Text", "x230 y108 w130", TitleKey(FwdKey))
P3_FwdBtn  := WelGui.Add("Button", "x390 y103 w100 h28", "Set")
WelGui.SetFont("s10 Bold w600 c333333", "Segoe UI")
P3_BwdLbl  := WelGui.Add("Text", "x70 y148 w150", "Backward macro:")
WelGui.SetFont("s10 Bold w700 c0066CC", "Segoe UI")
P3_BwdDisp := WelGui.Add("Text", "x230 y148 w130", TitleKey(BwdKey))
P3_BwdBtn  := WelGui.Add("Button", "x390 y143 w100 h28", "Set")
WelGui.SetFont("s8 w400 cAAAAAA", "Segoe UI")
P3_Note    := WelGui.Add("Text", "x50 y220 w500 Center", "Default: XButton2 (Forward)  /  XButton1 (Backward)")
SetWindowRgn(P3_FwdBtn.Hwnd, 0, 0, 100, 28, 8, 8)
SetWindowRgn(P3_BwdBtn.Hwnd, 0, 0, 100, 28, 8, 8)
P3_FwdBtn.OnEvent("Click", (*) => StartListen("Fwd"))
P3_BwdBtn.OnEvent("Click", (*) => StartListen("Bwd"))

; --- Page 4: Color Legend ---
WelGui.SetFont("s15 Bold w900 c2D2D2D", "Segoe UI")
P4_PTitle := WelGui.Add("Text", "x20 y18 w560 Center", "COLOR LEGEND")
P4_SepV1  := WelGui.Add("Text", "x196 y52 w1 h220 BackgroundCCCCCC", "")
P4_SepV2  := WelGui.Add("Text", "x396 y52 w1 h220 BackgroundCCCCCC", "")
P4_LineA  := WelGui.Add("Text", "x24 y52 w160 h4 Background333333", "")
WelGui.SetFont("s10 Bold w700 c333333", "Segoe UI")
P4_TA     := WelGui.Add("Text", "x24 y64 w160", "No Macro")
WelGui.SetFont("s9 w400 c666666", "Segoe UI")
P4_DA     := WelGui.Add("Text", "x24 y84 w160", "No macro assigned.`nPlaceholder or`nmanual play.")
P4_LineR  := WelGui.Add("Text", "x210 y52 w175 h4 BackgroundCC2222", "")
WelGui.SetFont("s10 Bold w700 cCC2222", "Segoe UI")
P4_TR     := WelGui.Add("Text", "x210 y64 w175", "Glitch Macro")
WelGui.SetFont("s9 w400 c666666", "Segoe UI")
P4_DR     := WelGui.Add("Text", "x210 y84 w175", "Exploit-based technique.`nHold \ in-game for`ndetailed usage info.")
P4_LineB  := WelGui.Add("Text", "x410 y52 w166 h4 Background0066CC", "")
WelGui.SetFont("s10 Bold w700 c0066CC", "Segoe UI")
P4_TB     := WelGui.Add("Text", "x410 y64 w166", "Has Macro")
WelGui.SetFont("s9 w400 c666666", "Segoe UI")
P4_DB     := WelGui.Add("Text", "x410 y84 w166", "Has a dedicated macro`nassigned and ready.")

; --- Page 5: All Set ---
WelGui.SetFont("s20 Bold w700 c2D2D2D", "Segoe UI")
P5_Title := WelGui.Add("Text", "x20 y60 w560 Center", "You're all set!")
WelGui.SetFont("s10 Bold w700 c0066CC", "Segoe UI")
P5_Sub   := WelGui.Add("Text", "x20 y100 w560 Center", "Tool active in Roblox.")
WelGui.SetFont("s10 w400 c555555", "Segoe UI")
P5_Body  := WelGui.Add("Text", "x80 y130 w440 Center", "Press  [ or ]  to pick your character,`nthen use your macro keys in-game.")

; --- Navigation buttons ---
WelBack := WelGui.Add("Button", "x40 y308 w120 h36", "← Back")
WelNext := WelGui.Add("Button", "x240 y308 w120 h36", "Next →")
WelBack.OnEvent("Click", WelNav.Bind(-1))
WelNext.OnEvent("Click", WelNav.Bind(1))
SetWindowRgn(WelGui.Hwnd, 0, 0, WelW, WelH, 20, 20)
SetWindowRgn(WelBack.Hwnd, 0, 0, 120, 36, 10, 10)
SetWindowRgn(WelNext.Hwnd, 0, 0, 120, 36, 10, 10)

P1_Ctrls := [P1_Title, P1_Sub, P1_Body, P1_By]
P2_Ctrls := [P2_Title, P2_KeyL, P2_KeyR, P2_Sep, P2_Note1, P2_Note2, P2_Note3, P2_Sep2, P2_Note4]
P3_Ctrls := [P3_Title, P3_Sub, P3_FwdLbl, P3_FwdDisp, P3_FwdBtn, P3_BwdLbl, P3_BwdDisp, P3_BwdBtn, P3_Note]
P4_Ctrls := [P4_PTitle, P4_SepV1, P4_SepV2, P4_LineA, P4_TA, P4_DA, P4_LineR, P4_TR, P4_DR, P4_LineB, P4_TB, P4_DB]
P5_Ctrls := [P5_Title, P5_Sub, P5_Body]

WelNav(dir, *) {
    Global WelPage
    if (WelPage = 5 && dir = 1) {
        IniWrite(1, INI_FILE, "Settings", "Welcomed")
        WelGui.Hide()
        return
    }
    WelPage := Max(1, Min(5, WelPage + dir))
    for i, group in [P1_Ctrls, P2_Ctrls, P3_Ctrls, P4_Ctrls, P5_Ctrls]
        for ctrl in group
            ctrl.Visible := (i = WelPage)
    WelBack.Visible := WelPage > 1
    if WelPage = 5 {
        WelNext.Text := "Let's Go!  ✓"
        WelNext.Move(WelW//2 - 60, 308)
    } else if WelPage = 1 {
        WelNext.Text := "Next →"
        WelNext.Move(WelW//2 - 60, 308)
    } else {
        WelNext.Text := "Next →"
        WelNext.Move(WelW - 160, 308)
    }
}

if !IniRead(INI_FILE, "Settings", "Welcomed", "") {
    WelNav(0)
    WelGui.Show("x" (A_ScreenWidth//2 - WelW//2) " y" (A_ScreenHeight//2 - WelH//2))
}

;==============================================
;============== LISTEN MODE ===================
;==============================================

StartListen(which) {
    Global g_listenWhich, g_listenStart, g_listenIH
    g_listenWhich := which
    g_listenStart := A_TickCount
    btn := (which = "Fwd") ? P3_FwdBtn : P3_BwdBtn
    btn.Text    := "Listening..."
    btn.Enabled := false
    SetTimer ListenMousePoll, 16
    ih := InputHook("L1 T10", "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}"
        . "{Escape}{Tab}{Space}{Backspace}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}"
        . "{Up}{Down}{Left}{Right}"
        . "{Numpad0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}{Numpad6}{Numpad7}{Numpad8}{Numpad9}")
    ih.OnEnd := OnListenEnd
    ih.Start()
    g_listenIH := ih
}

ListenMousePoll() {
    Global g_listenWhich, g_listenStart, g_listenIH
    if (g_listenWhich = "")
        return
    if (A_TickCount - g_listenStart < 300)
        return
    for k in ["LButton", "RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"] {
        if GetKeyState(k, "P") {
            SetTimer ListenMousePoll, 0
            g_listenIH.Stop()
            ApplyListen(k)
            return
        }
    }
}

OnListenEnd(ih) {
    SetTimer ListenMousePoll, 0
    if (ih.EndReason = "Stopped")
        return
    key := (ih.EndReason = "EndKey") ? ih.EndKey : ih.Input
    if (key != "")
        ApplyListen(key)
    else
        ResetListenBtn()
}

ApplyListen(rawKey) {
    Global g_listenWhich, FwdKey, BwdKey
    stored  := StrLower(rawKey)
    display := TitleKey(rawKey)
    
    ; Ép context vào Roblox trước khi gỡ key cũ
    HotIfWinActive("ahk_exe RobloxPlayerBeta.exe")
    
    if (g_listenWhich = "Fwd") {
        try Hotkey FwdKey, MacroForward, "Off"
        FwdKey := stored
        P3_FwdDisp.Value := display
        IniWrite(stored, INI_FILE, "Settings", "FwdKey")
    } else {
        try Hotkey BwdKey, MacroBackward, "Off"
        BwdKey := stored
        P3_BwdDisp.Value := display
        IniWrite(stored, INI_FILE, "Settings", "BwdKey")
    }
    
    HotIfWinActive() ; Reset context
    
    ResetListenBtn()
    g_listenWhich := ""
    RegisterMacroKeys()
    Text_F_Label.Value := GetBindLabel(FwdKey, "Forward")
    Text_B_Label.Value := GetBindLabel(BwdKey, "Backward")
}

ResetListenBtn() {
    Global g_listenWhich
    btn := (g_listenWhich = "Fwd") ? P3_FwdBtn : P3_BwdBtn
    btn.Text    := "Set"
    btn.Enabled := true
}

;==============================================
;========= SYSTEM: UTILITY FUNCTIONS ==========
;==============================================

ShowHelpPanel() {
    Data := CharData[CurrentIndex]

    nameColor := GetCharColor(Data.t)
    HelpHeader.SetFont("c" (nameColor != "" ? nameColor : "0066CC"))
    HelpHeader.Value := Data.n
    HelpContent.Value := Data.info

    lineCount := 1
    loop parse Data.info, "`n"
        lineCount++
    contentH := lineCount * 17 + 4
    totalH   := 34 + 1 + 10 + contentH + 8
    HelpContent.Move(, 44, , contentH)
    HelpGui.Move(,, HelpW, totalH)
    SetWindowRgn(HelpGui.Hwnd, 0, 0, HelpW, totalH, 15, 15)

    WinGetPos(&WX, &WY, &WW, &WH, "ahk_exe RobloxPlayerBeta.exe")
    HelpX := Max(0, Min(A_ScreenWidth  - HelpW, WX + WW - HelpW - 30))
    HelpY := Max(0, Min(A_ScreenHeight - totalH, WY + WH - totalH - 40))
    HelpGui.Show("x" HelpX " y" HelpY " NoActivate")
}

ResetBsCount() {
    Global g_bsCount := 0
}

OpenBindMode() {
    Global WelPage := 3
    for i, group in [P1_Ctrls, P2_Ctrls, P3_Ctrls, P4_Ctrls, P5_Ctrls]
        for ctrl in group
            ctrl.Visible := (i = 3)
    WelBack.Visible := true
    WelNext.Text := "Next →"
    WelNext.Move(WelW - 160, 308)
    WelGui.Show("x" (A_ScreenWidth//2 - WelW//2) " y" (A_ScreenHeight//2 - WelH//2))
}

SetWindowRgn(hWnd, x1, y1, x2, y2, w, h) {
    Region := DllCall("gdi32\CreateRoundRectRgn", "Int", x1, "Int", y1, "Int", x2, "Int", y2, "Int", w, "Int", h)
    DllCall("user32\SetWindowRgn", "Ptr", hWnd, "Ptr", Region, "Int", True)
}

RegisterMacroKeys() {
    HotIfWinActive("ahk_exe RobloxPlayerBeta.exe")
    try Hotkey FwdKey, MacroForward, "Off"
    try Hotkey BwdKey, MacroBackward, "Off"
    Hotkey FwdKey, MacroForward, "On"
    Hotkey BwdKey, MacroBackward, "On"
    HotIfWinActive()
}

MacroForward(*) {
    if WinActive("ahk_exe RobloxPlayerBeta.exe") && !isChatting
        ExecuteMacro("Forward")
}

MacroBackward(*) {
    if WinActive("ahk_exe RobloxPlayerBeta.exe") && !isChatting
        ExecuteMacro("Backward")
}

RegisterMacroKeys()

;==============================================
;========= SYSTEM: STATE CHECKER ==============
;==============================================

SetTimer(CheckState, 100)
CheckState() {
    Global isChatting, helpActive
    if !WinActive("ahk_exe RobloxPlayerBeta.exe") {
        isChatting := false
        helpActive := false
        MyGui.Hide()
        ChatGui.Hide()
        HelpGui.Hide()
        return
    }
    if helpActive
        return
    Try {
        WinGetPos(&WX, &WY, &WW, &WH, "ahk_exe RobloxPlayerBeta.exe")
        ChatX := Max(0, Min(A_ScreenWidth - 160, WX + (WW / 2) - 80))
        ChatY := Max(0, WY + 40)
        MainX := Max(0, Min(A_ScreenWidth  - GuiW, WX + WW - GuiW - 30))
        MainY := Max(0, Min(A_ScreenHeight - GuiH, WY + WH - GuiH - 40))
        ChatGui.Show(isChatting ? "x" ChatX " y" ChatY " NoActivate" : "Hide")
        if (A_TickCount - LastActionTime > 5000) {
            MyGui.Hide()
        } else {
            MyGui.Show("x" MainX " y" MainY " NoActivate")
        }
    }
}

;==============================================
;============= INPUT CONTROL ==================
;==============================================

#u::CheckForUpdate(true)

#HotIf WinActive("ahk_exe RobloxPlayerBeta.exe")

; F + LMB interrupt: holding F then clicking releases F during click
~LButton:: {
    Global isChatting := false
    if (GetKeyState("f", "P") && !isChatting)
        Send("{f up}")
}

~LButton up:: {
    if (GetKeyState("f", "P") && !isChatting) {
        Sleep(16)
        Send("{f down}")
    }
}

; Chat mode
~Enter::
~Esc:: {
    Global isChatting := false
}

~/:: {
    Global isChatting := true
}

; ── BLOCK 2: Chỉ active khi KHÔNG trong chat ──
#HotIf WinActive("ahk_exe RobloxPlayerBeta.exe") and !isChatting

; Hold \ = info panel | Triple tap \ = bind mode
\:: {
    if g_bsDown
        return
    Global g_bsDown := true

    Global g_bsCount += 1
    SetTimer ResetBsCount, -500
    if g_bsCount >= 3 {
        Global g_bsCount := 0
        Global g_bsDown  := false   ; reset ngay vì \ up có thể ko fire khi WelGui steal focus
        SetTimer ResetBsCount, 0
        Global helpActive := false
        HelpGui.Hide()
        OpenBindMode()
        return
    }

    if helpActive
        return
    Global helpActive := true
    MyGui.Hide()
    ChatGui.Hide()
    ShowHelpPanel()
}

\ up:: {
    Global g_bsDown  := false
    Global isChatting := false
    if helpActive {
        Global helpActive := false
        HelpGui.Hide()
    }
}

; Character switcher
[:: {
    if (CurrentIndex > 1) {
        Global CurrentIndex -= 1, LastActionTime := A_TickCount
        UpdateGUI(), SaveSettings()
    }
}

]:: {
    if (CurrentIndex < CharData.Length) {
        Global CurrentIndex += 1, LastActionTime := A_TickCount
        UpdateGUI(), SaveSettings()
    }
}

; Forward/Backward handled entirely via RegisterMacroKeys()

#HotIf

;==============================================
;=============== MACRO ENGINE =================
;==============================================
; Add new character macros here.
; Check name:  if (Name == "Character Name") { ... }
; Send a key:  Send("r")
; Wait:        Sleep(100)   ← milliseconds

ExecuteMacro(Mode) {
    Data := CharData[CurrentIndex]
    Name := Data.n
    CurrentAction := (Mode == "Forward") ? Data.f : Data.b

    if (CurrentAction == "-")
        return

    if (Name == "Ten Shadows") {
        if (Mode == "Forward")
            Send("r")
        else
            Send("g")

    } else if (Name == "Head of the Hei") {
        if (Mode == "Forward")
            Send("q")
        else
            Send("r")

    } else if (Name == "Vessel") {
        Send("3"), Sleep(300), Send("3")

    } else if (Name == "Perfection") {
        if (Mode == "Forward") {
            Send("{f down}")
            Sleep(16)
            Send("{LButton down}")
            Sleep(50)
            Send("{LButton up}")
            Send("{f up}")
            if GetKeyState("f", "P")
                Send("{f down}")
        } else {
            Send("gg")
        }

    } else if (Name == "Switcher") {
        if (Mode == "Forward")
            Send("r"), Sleep(500), Click()
        else
            Send("r"), Sleep(250), Click()

    } else if (Name == "Cursed Partners") {
 	if (Mode == "Forward") {
       	    Send("{3 down}")
            KeyWait(RegExReplace(A_ThisHotkey, "[~$*!^+#]"))
            Send("{3 up}")
    } else {
        Send("r")
        Sleep(120)
        Send("4")
    }

    } else if (Name == "Defense Attorney") {
        if (Mode == "Forward")
            Send("3"), Send("r")

    } else if (Name == "Star Rage") {
        if (Mode == "Forward") {
            HotkeyKey := RegExReplace(A_ThisHotkey, "[~$\*!^+#]")
            while GetKeyState(HotkeyKey, "P") {
                Send("{r down}")
                Sleep(20)
                Send("{r up}")
            }
        } else {
            Send("{Escape}")
            Sleep(75)
            Send("r")
            Sleep(75)
            Send("{Enter}")
        }
    }
}

;==============================================
;============== COLOR HELPERS =================
;==============================================

TitleKey(key) {
    return StrUpper(SubStr(key, 1, 1)) . SubStr(key, 2)
}

GetBindLabel(key, default) {
    return (StrLower(key) = "xbutton2" || StrLower(key) = "xbutton1")
        ? default
        : TitleKey(key)
}

GetCharColor(t) {
    return (t = "b") ? "0066CC" : (t = "r") ? "CC2222" : ""
}

GetItemColor(t, fc, val) {
    if (val = "-")
        return "AAAAAA"
    if (fc = "b")
        return "0066CC"
    if (fc = "r")
        return "CC2222"
    c := GetCharColor(t)
    return (c != "") ? c : "777777"
}

;==============================================
;================ GUI UPDATE ==================
;==============================================
; Character name colors → controlled by  t  field in CharData
; "" = gray  |  "b" = blue  | "r" = red

UpdateGUI() {
    Size := CharData.Length
    GetName(offset) {
        idx := CurrentIndex + offset
        return (idx < 1 || idx > Size) ? "" : CharData[idx].n
    }
    GetColor(offset) {
        idx := CurrentIndex + offset
        if (idx < 1 || idx > Size)
            return ""
        return GetCharColor(CharData[idx].t)
    }

    Data    := CharData[CurrentIndex]
    fColor  := GetItemColor(Data.t, Data.fc, Data.f)
    bColor  := GetItemColor(Data.t, Data.bc, Data.b)
    Text_F_Desc.SetFont("c" fColor), Text_F_Desc.Value := Data.f
    Text_B_Desc.SetFont("c" bColor), Text_B_Desc.Value := Data.b

    defaultC := ["AAAAAA", "888888", "000000", "888888", "AAAAAA"]
    offsets  := [-2, -1, 0, 1, 2]
    ctrls    := [Text_FarUp, Text_NearUp, Text_Main, Text_NearDown, Text_FarDown]
    for i, ctrl in ctrls {
        c := GetColor(offsets[i])
        ctrl.SetFont("c" (c != "" ? c : defaultC[i]))
        ctrl.Value := (i = 3) ? "[ " GetName(0) " ]" : GetName(offsets[i])
    }
}

;==============================================
;================= SETTINGS ===================
;==============================================

CheckForUpdate(manual := false) {
    Global AUTO_UPDATE_CHECK, UPDATE_VERSION_URL, LOCAL_VERSION, UPDATE_EXE_URL, UPDATE_SCRIPT_URL
    if (!manual && !AUTO_UPDATE_CHECK)
        return

    if UPDATE_VERSION_URL = "" {
        if manual
            MsgBox("Chưa cài đặt UPDATE_VERSION_URL. Hãy chỉnh URL GitHub trong mã.")
        return
    }

    tempVersionFile := A_Temp "\JJS_Macro_update_version.txt"
    remoteVersion := ""
    try {
        UrlDownloadToFile(UPDATE_VERSION_URL, tempVersionFile)
        remoteVersion := StrTrim(FileRead(tempVersionFile))
        FileDelete(tempVersionFile)
    } catch {
        if manual
            MsgBox("Không thể kiểm tra update. Kiểm tra kết nối mạng và URL GitHub.")
        return
    }

    if (remoteVersion = "") {
        if manual
            MsgBox("Phiên bản update không hợp lệ từ GitHub.")
        return
    }

    if (!VersionIsNewer(remoteVersion, LOCAL_VERSION)) {
        if (manual)
            MsgBox("Đang dùng phiên bản mới nhất: v" LOCAL_VERSION)
        return
    }

    downloadUrl := A_IsCompiled ? UPDATE_EXE_URL : UPDATE_SCRIPT_URL
    if (downloadUrl = "") {
        if manual
            MsgBox("Chưa cài đặt đường dẫn tải về cho loại file này.")
        return
    }

    if (MsgBox("Đã có phiên bản mới: v" remoteVersion ".\nBạn có muốn tải về và cập nhật không?", "Auto Update", 4) != "Yes")
        return

    DownloadAndInstallUpdate(downloadUrl)
}

VersionIsNewer(remoteVersion, localVersion) {
    remoteParts := StrSplit(remoteVersion, ".")
    localParts := StrSplit(localVersion, ".")
    maxParts := Max(remoteParts.Length, localParts.Length)
    Loop maxParts {
        r := (A_Index <= remoteParts.Length) ? remoteParts[A_Index] : "0"
        l := (A_Index <= localParts.Length) ? localParts[A_Index] : "0"
        r := 0 + r
        l := 0 + l
        if (r > l)
            return true
        if (r < l)
            return false
    }
    return false
}

DownloadAndInstallUpdate(downloadUrl) {
    targetPath := A_ScriptFullPath
    tmpFile := A_Temp "\JJS_Macro_update" . (A_IsCompiled ? ".exe" : ".ahk")

    try {
        UrlDownloadToFile(downloadUrl, tmpFile)
    } catch {
        MsgBox("Tải file update không thành công.")
        return
    }

    if !FileExist(tmpFile) {
        MsgBox("Tải file update thất bại.")
        return
    }

    updaterBat := A_Temp "\JJS_Macro_updater.bat"
    batText := "@echo off`n"
        . "setlocal`n"
        . "set ""target=" targetPath ""`n"
        . "set ""source=" tmpFile ""`n"
        . ":retry`n"
        . "timeout /t 1 /nobreak >nul`n"
        . "del ""%target%"" 2>nul`n"
        . "if exist ""%target%"" goto retry`n"
        . "move /y ""%source%"" ""%target%""`n"
        . "start """" ""%target%""`n"
        . "del ""%~f0""`n"

    FileDelete(updaterBat)
    FileAppend(batText, updaterBat)
    Run(updaterBat, "", "Hide")
    ExitApp()
}

SaveSettings() {
    IniWrite(CurrentIndex, INI_FILE, "Settings", "LastChar")
}