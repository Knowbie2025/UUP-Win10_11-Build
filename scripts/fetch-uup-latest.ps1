# fetch-uup-latest.ps1
# 环境变量读取
$targetBuild = $env:TARGET_BUILD
$arch = $env:ARCH
$lang = $env:LANG

# 双域名容错，主站失败自动切备用镜像
$apiDomains = @(
    "https://uupdump.net",
    "https://uupdump.myshell.xyz"
)
$response = $null
# 循环尝试域名，最多2次
foreach ($domain in $apiDomains) {
    try {
        $apiUrl = "$domain/api/getknownbuilds.php?search=$targetBuild"
        Write-Host "尝试访问接口: $apiUrl"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -TimeoutSec 30
        break
    }
    catch {
        Write-Warning "当前域名访问失败，10秒后切换备用域名重试：$_"
        Start-Sleep 10
        continue
    }
}
# 全部域名都失败直接终止构建
if (-not $response) {
    Write-Error "所有UUP Dump API域名访问全部404/超时，构建终止"
    exit 1
}

# 筛选对应架构，按修订号从新到旧排序取第一条
$latestBuild = $response.builds | Where-Object { $_.arch -eq $arch } | Sort-Object buildrev -Descending | Select-Object -First 1
if (-not $latestBuild) {
    Write-Error "未找到对应Build:$targetBuild 架构:$arch 的镜像资源"
    exit 1
}
$env:LATEST_SUB_BUILD = $latestBuild.buildrev
$updateId = $latestBuild.updatedid

Write-Host "检测到最新版本: $targetBuild.$($latestBuild.buildrev)"
Write-Host "Update ID: $updateId"

# 2. 严格对应截图所有勾选的POST参数
$postData = @{
    id                     = $updateId
    lang                   = "zh-cn"
    download               = 3 # 模式3：下载+集成全部虚拟SKU生成ISO
    edition                = "pro,homechina" # 基础勾选：专业版、家庭中文版，不勾选普通家庭版
    include_updates        = 1
    cleanup                = 1
    net35                  = 1
    esd_compress           = 0 # 不勾选ESD固实压缩
    add_edition_proworkstation = 1
    add_edition_proeducation   = 1
    add_edition_education      = 1
    add_edition_enterprise     = 1
    add_edition_entmulti       = 1
    add_edition_iotent         = 1
    add_edition_iotentsub      = 1
}

# 3. 请求API下载自定义脚本压缩包，同样双域名重试
$downloadSuccess = $false
foreach ($domain in $apiDomains) {
    try {
        $downloadUrl = "$domain/api/getdownloadpackage.php"
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
        Write-Warning "脚本包下载失败，切换备用域名重试：$_"
        Start-Sleep 10
        continue
    }
}
if (-not $downloadSuccess) {
    Write-Error "所有域名均无法下载UUP脚本包，任务退出"
    exit 1
}

# 解压脚本包到uup-work目录
if (Test-Path "uup-work") { Remove-Item "uup-work" -Recurse -Force }
7z x uup-package.zip -ouup-work -y
Write-Host "UUP脚本包下载解压完成"
