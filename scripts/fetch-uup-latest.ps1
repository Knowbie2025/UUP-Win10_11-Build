# fetch-uup-latest.ps1 新版API重试版
$targetBuild = $env:TARGET_BUILD
$arch = $env:ARCH
$lang = $env:LANG

# 更换为当前可用UUP镜像新域名
$apiDomains = @(
    "https://uup.rg-adguard.net"
)
$response = $null

foreach ($domain in $apiDomains) {
    try {
        # rg-adguard使用全新接口，不再使用旧getknownbuilds.php
        $apiUrl = "$domain/api/v1/builds?search=$targetBuild&arch=$arch"
        Write-Host "正在尝试新版接口：$apiUrl"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -TimeoutSec 30
        break
    }
    catch {
        Write-Warning "当前域名访问失败，10秒后重试：$_"
        Start-Sleep 10
        continue
    }
}

if (-not $response) {
    Write-Error "所有新版UUP域名访问全部失败，任务终止"
    exit 1
}

# 筛选最新build
$latestBuild = $response | Sort-Object buildrev -Descending | Select-Object -First 1
if (-not $latestBuild) {
    Write-Error "未找到 Build:$targetBuild 架构:$arch 的镜像资源"
    exit 1
}
$env:LATEST_SUB_BUILD = $latestBuild.buildrev
$updateId = $latestBuild.updatedid

Write-Host "检测到最新版本：$targetBuild.$($latestBuild.buildrev)"
Write-Host "Update ID：$updateId"

# POST生成下载包参数不变
$postData = @{
    id                     = $updateId
    lang                   = "zh-cn"
    download               = 3
    edition                = "pro,homechina"
    include_updates        = 1
    cleanup                = 1
    net35                  = 1
    esd_compress           = 0
    add_edition_proworkstation = 1
    add_edition_proeducation   = 1
    add_edition_education      = 1
    add_edition_enterprise     = 1
    add_edition_entmulti       = 1
    add_edition_iotent         = 1
    add_edition_iotentsub      = 1
}

# 新版下载接口
$downloadSuccess = $false
foreach ($domain in $apiDomains) {
    try {
        $downloadUrl = "$domain/api/v1/downloadpackage"
        Write-Host "开始下载UUP脚本包：$downloadUrl"
        Invoke-WebRequest `
            -Uri $downloadUrl `
            -Method Post `
            -Body $postData `
            -OutFile "uup-package.zip" `
            -UseBasicParsing `
            -TimeoutSec 60
        $downloadSuccess = $true
        break
    }
    catch {
        Write-Warning "脚本包下载失败，重试：$_"
        Start-Sleep 10
        continue
    }
}
if (-not $downloadSuccess) {
    Write-Error "新版域名无法下载UUP脚本包，任务退出"
    exit 1
}

# 解压脚本到工作目录
if (Test-Path "uup-work") { Remove-Item "uup-work" -Recurse -Force }
7z x uup-package.zip -ouup-work -y
Write-Host "UUP脚本包下载解压完成"
