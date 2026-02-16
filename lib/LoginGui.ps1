# ============================================================
# LoginGui.ps1 - SSHログイン用GUIツール
# ============================================================

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- 1. 動作環境・パスの設定 ---
$basePath = Split-Path $PSScriptRoot -Parent
$confPath = Join-Path $basePath "conf"
$logPath  = Join-Path $basePath "log"
$ttlPath  = Join-Path $PSScriptRoot "Main.ttl"

# ログ保存フォルダの自動作成
if (-not (Test-Path $logPath)) {
    New-Item $logPath -ItemType Directory | Out-Null
}

# ttpmacro.exeの場所を特定
$ttmacro = "C:\Program Files (x86)\teraterm\ttpmacro.exe"
if (-not (Test-Path $ttmacro)) {
    $ttmacro = (Get-Command ttpmacro.exe -ErrorAction SilentlyContinue).Source
}

# ttpmacro.exeのパスを基に ttermpro.exe（本体）のパスを導出
if ($ttmacro) {
    $ttermpro = $ttmacro.Replace("ttpmacro.exe", "ttermpro.exe")
}

# 【重要】ttermpro.exe が存在しない場合はエラーを表示して終了
if (-not $ttermpro -or -not (Test-Path $ttermpro)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Tera Term本体 (ttermpro.exe) が見つかりませんでした。`nインストールパスを確認してください。",
        "実行エラー",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}

# --- 2. 設定ファイルの読み込み ---
$ipList = if (Test-Path "$confPath\IpList.csv") {
    Get-Content "$confPath\IpList.csv"
} else {
    @()
}

$default = if (Test-Path "$confPath\DefaultAccount.csv") {
    (Get-Content "$confPath\DefaultAccount.csv").Split(',')
} else {
    "", ""
}

# --- 3. GUI（フォーム）の定義 ---
$font = New-Object System.Drawing.Font("メイリオ", 10)

$form = New-Object System.Windows.Forms.Form -Property @{
    Text = "SSH Auto Login"
    Size = "300,280"
    StartPosition = "CenterScreen"
    FormBorderStyle = "FixedDialog"
    MaximizeBox = $false
    MinimizeBox = $false
}

# ラベルと入力欄の配置
$controls = @(
    @{ Type="Label"; Text="IPアドレス:"; Y=25 },
    @{ Type="Combo"; Name="cmbIp"; Y=22; Items=$ipList },
    @{ Type="Label"; Text="ユーザー:"; Y=75 },
    @{ Type="Text"; Name="txtUser"; Y=72; Text=$default[0] },
    @{ Type="Label"; Text="パスワード:"; Y=125 },
    @{ Type="Text"; Name="txtPass"; Y=122; Text=$default[1]; Password=$true }
)

# コントロールの一括生成
$fields = @{}

foreach ($c in $controls) {

    if ($c.Type -eq "Label") {

        $obj = New-Object System.Windows.Forms.Label -Property @{
            Text = $c.Text
            Location = "20,$($c.Y)"
            AutoSize = $true
        }

    }
    elseif ($c.Type -eq "Combo") {

        $obj = New-Object System.Windows.Forms.ComboBox -Property @{
            Location = "110,$($c.Y)"
            Size = "140,25"
            Font = $font
        }

        $c.Items | ForEach-Object { [void]$obj.Items.Add($_) }
        $fields[$c.Name] = $obj
    }
    else {

        $obj = New-Object System.Windows.Forms.TextBox -Property @{
            Location = "110,$($c.Y)"
            Size = "140,25"
            Font = $font
            Text = $c.Text
        }

        if ($c.Password) {
            $obj.PasswordChar = '*'
        }

        $fields[$c.Name] = $obj
    }

    $form.Controls.Add($obj)
}

# --- 4. 実行アクション ---
$btnOk = New-Object System.Windows.Forms.Button -Property @{
    Text = "ログイン"
    Location = "40,185"
    Size = "100,35"
}

$btnOk.Add_Click({

    if ([string]::IsNullOrWhiteSpace($fields["cmbIp"].Text)) {
        [System.Windows.Forms.MessageBox]::Show("IPアドレスを選択してください。")
        return
    }

    # Tera Term本体 (ttermpro) を起動
    # /Mオプションでマクロを指定し、マクロ側へ引数として接続情報を渡す
    $server = $fields["cmbIp"].Text
    $user   = $fields["txtUser"].Text
    $pass   = $fields["txtPass"].Text

    $ttermArgs = "`"$server`" /ssh /2 /auth=password /user=`"$user`" /passwd=`"$pass`" /M=`"$ttlPath`""

    Start-Process -FilePath $ttermpro -ArgumentList $ttermArgs

    $form.Close()
})

$form.Controls.Add($btnOk)
$form.AcceptButton = $btnOk

[void]$form.ShowDialog()
