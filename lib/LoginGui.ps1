<#
SSH Auto Login Tool（GUI）

■ 概要
Tera Termを利用したSSH接続用GUIツール。

■ 前提
- Windows + PowerShell 5.1以上
- Tera Term インストール済み

■ 拡張
- ボタン追加：NewBtn関数を利用
- 入力追加：TableLayoutPanelへ行追加
#>

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ============================================================
# TeraTerm確認
# ============================================================
$ttmacro = "C:\Program Files (x86)\teraterm\ttpmacro.exe"

if (-not (Test-Path $ttmacro)) {
    $cmd = Get-Command ttpmacro.exe -ErrorAction SilentlyContinue
    if ($cmd) { $ttmacro = $cmd.Source } else { $ttmacro = $null }
}

$ttermpro = $null
if ($ttmacro) {
    $ttermpro = $ttmacro -replace "ttpmacro.exe", "ttermpro.exe"
}

if ([string]::IsNullOrWhiteSpace($ttermpro) -or -not (Test-Path $ttermpro)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Tera Termが見つかりません",
        "エラー",
        "OK",
        "Error"
    )
    exit
}

# ============================================================
# 設定読込
# ============================================================
$basePath = Split-Path $PSScriptRoot -Parent
$confPath = Join-Path $basePath "conf"
$logPath  = Join-Path $basePath "log"

$ipList = @()
$ipFile = "$confPath\IpList.csv"
if (Test-Path $ipFile) {
    $ipList = Get-Content $ipFile | Where-Object { $_ -and $_.Trim() -ne "" }
}

$accFile = "$confPath\DefaultAccount.csv"
if (Test-Path $accFile) {
    $accData = Import-Csv $accFile -Header "user", "pass" | Select-Object -First 1
    if ($accData) {
        $defaultUser = $accData.user
        $defaultPass = $accData.pass
    }
}

# ============================================================
# フォーム
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSH Auto Login"
$form.StartPosition = "CenterScreen"
$form.AutoSize = $true
$form.AutoSizeMode = "GrowAndShrink"

$font = New-Object System.Drawing.Font("メイリオ", 10)

# ============================================================
# ToolTip
# ============================================================
$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.InitialDelay = 200

# ============================================================
# メインレイアウト
# ============================================================
$mainPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$mainPanel.FlowDirection = "TopDown"
$mainPanel.WrapContents = $false
$mainPanel.AutoSize = $true
$mainPanel.Padding = [System.Windows.Forms.Padding]::new(10)

$form.Controls.Add($mainPanel)

# ============================================================
# 接続情報
# ============================================================
$table = New-Object System.Windows.Forms.TableLayoutPanel
$table.RowCount = 3
$table.ColumnCount = 2
$table.AutoSize = $true

$lblIp = New-Object System.Windows.Forms.Label
$lblIp.Text = "IP:"
$lblIp.Font = $font

$cmbIp = New-Object System.Windows.Forms.ComboBox
$cmbIp.Font = $font
$cmbIp.Width = 180
if ($ipList.Count -gt 0) { $cmbIp.Items.AddRange($ipList) }

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "User:"
$lblUser.Font = $font

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Font = $font
$txtUser.Text = $defaultUser

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "Pass:"
$lblPass.Font = $font

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Font = $font
$txtPass.PasswordChar = '*'
$txtPass.Text = $defaultPass

$table.Controls.Add($lblIp, 0, 0)
$table.Controls.Add($cmbIp, 1, 0)
$table.Controls.Add($lblUser, 0, 1)
$table.Controls.Add($txtUser, 1, 1)
$table.Controls.Add($lblPass, 0, 2)
$table.Controls.Add($txtPass, 1, 2)

# --- Panelでラップ（重なり防止）
$innerInput = New-Object System.Windows.Forms.Panel
$innerInput.AutoSize = $true
$innerInput.Location = New-Object System.Drawing.Point(10,20)
$innerInput.Controls.Add($table)

$grpInput = New-Object System.Windows.Forms.GroupBox
$grpInput.Text = "接続情報"
$grpInput.AutoSize = $true
$grpInput.Controls.Add($innerInput)

$mainPanel.Controls.Add($grpInput)

# ============================================================
# 操作
# ============================================================
$panel = New-Object System.Windows.Forms.FlowLayoutPanel
$panel.AutoSize = $true

function Is-ValidIP($ip) {
    return [System.Net.IPAddress]::TryParse($ip, [ref]$null)
}

function Start-Login {

    # 引数でマクロ名を指定可能にする
    param([string]$ttlName = "Main.ttl")

    $server = $cmbIp.Text.Trim()
    $user   = $txtUser.Text.Trim()
    $pass   = $txtPass.Text

    # --- バリデーション ---
    if (-not (Is-ValidIP $server)) {
        [System.Windows.Forms.MessageBox]::Show("IP形式が不正です")
        return
    }

    if ([string]::IsNullOrWhiteSpace($user)) {
        [System.Windows.Forms.MessageBox]::Show("ユーザー名を入力してください")
        return
    }

    # --- TTLパス ---
    $ttlPath = Join-Path $PSScriptRoot $ttlName

    if (-not (Test-Path $ttlPath)) {
        [System.Windows.Forms.MessageBox]::Show("$ttlName が見つかりません")
        return
    }

    # --- 引数生成 ---
    $macroArgs = @(
        "`"$ttlPath`"",
        "`"$server`"",
        "`"$user`"",
        "`"$pass`""
    ) -join " "

    # --- 起動 ---
    Start-Process -FilePath $ttmacro -ArgumentList $macroArgs

}

function NewBtn($text, $action, $tip) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Width = 120
    $btn.Margin = [System.Windows.Forms.Padding]::new(3)
    $btn.Add_Click($action)
    $tooltip.SetToolTip($btn, $tip)
    return $btn
}

$panel.Controls.AddRange(@(
    (NewBtn "ログイン" { Start-Login } "サーバへ接続"),
    (NewBtn "サンプル実行" {Start-Login "SampleCommand.ttl"} "サンプルコマンドを実行"),
    (NewBtn "ログ確認" { Start-Process explorer.exe $logPath } "ログを開く"),
    (NewBtn "終了" { $form.Close() } "ツールを終了")
))

# --- Panelでラップ（重なり防止）
$innerAction = New-Object System.Windows.Forms.Panel
$innerAction.AutoSize = $true
$innerAction.Location = New-Object System.Drawing.Point(10,20)
$innerAction.Controls.Add($panel)

$grpAction = New-Object System.Windows.Forms.GroupBox
$grpAction.Text = "操作"
$grpAction.AutoSize = $true
$grpAction.Controls.Add($innerAction)

$mainPanel.Controls.Add($grpAction)

# ============================================================
# ToolTip
# ============================================================
$tooltip.SetToolTip($cmbIp, "IPアドレスを入力または選択")
$tooltip.SetToolTip($txtUser, "ログインユーザー名")
$tooltip.SetToolTip($txtPass, "ログインパスワード")

# ============================================================
# 初期フォーカス
# ============================================================
$form.Add_Shown({ $cmbIp.Focus() })

# ============================================================
# 表示
# ============================================================
[void]$form.ShowDialog()