# fetch-uup-proxy-online.ps1 在线中转代理绕过CF，全自动在线
$targetBuild = $env:TARGET_BUILD
$arch = $env:ARCH
$lang = $env:LANG
$originApi = "https://uup.rg-adguard.net"
# 公开CF中转代理，转发请求绕过人机验证
$proxyApi = "https://corsproxy.io/?"

# 1. 查询Build列表（走中转代理）
$queryUrl = "$proxyApi$originApi/api/v1/builds?search=$targetBuild&arch=$arch"
try {
    Write-Host "通过CF中转代理查询Build列表：$queryUrl"
    $response = Invoke-RestMethod -Uri $queryUrl -UseBasicParsing -TimeoutSec 45
}
catch {
    Write-Error "代理查询Build失败，终止任务：$_"
    exit 1
}

# 筛选最新子版本
$latestBuild = $response | Sort-Object buildrev -Descending | Select-Object -First 1
if (-not $latestBuild) {
    Write-Error "未找到 Build:$targetBuild 架构:$arch 的资源"
    exit 1
}
$env:LATEST_SUB_BUILD = $latestBuild.buildrev
$updateId = $latestBuild.updatedid
Write-Host "✅ 在线获取最新版本：$targetBuild.$($latestBuild.buildrev)"

# 2. 完整SKU下载参数
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

# 3. 中转代理下载UUP脚本压缩包
$downloadOriginUrl = "$originApi/api/v1/downloadpackage"
$downloadProxyUrl = "$proxyApi$downloadOriginUrl"
try {
    Write-Host "通过CF中转代理下载UUP脚本包"
    Invoke-WebRequest `
        -Uri $downloadProxyUrl `
        -Method Post `
        -Body $postData `
        -OutFile "uup-package.zip" `
        -UseBasicParsing `
        -TimeoutSec 90
}
catch {
    Write-Error "代理下载脚本包失败：$_"
    exit 1
}

# 解压脚本工作目录
if (Test-Path "uup-work") { Remove-Item "uup-work" -Recurse -Force }
7z x uup-package.zip -ouup-work -y
Write-Host "✅ UUP脚本包在线下载解压完成"
