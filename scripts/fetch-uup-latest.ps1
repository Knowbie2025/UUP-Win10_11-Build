# fetch-uup-latest.ps1
# 环境变量读取
$targetBuild = $env:TARGET_BUILD
$arch = $env:ARCH
$lang = $env:LANG

# 1. 查询uupdump获取该Build下最新amd64版本ID
$apiUrl = "https://uupdump.net/api/getknownbuilds.php?search=$targetBuild"
$response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

# 筛选对应架构，按修订号从新到旧排序取第一条
$latestBuild = $response.builds | Where-Object { $_.arch -eq $arch } | Sort-Object buildrev -Descending | Select-Object -First 1
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

# 3. 请求API下载自定义脚本压缩包
Invoke-WebRequest `
    -Uri "https://uupdump.net/api/getdownloadpackage.php" `
    -Method Post `
    -Body $postData `
    -OutFile "uup-package.zip" `
    -UseBasicParsing

# 解压脚本包到uup-work目录
if (Test-Path "uup-work") { Remove-Item "uup-work" -Recurse -Force }
7z x uup-package.zip -ouup-work -y
Write-Host "UUP脚本包下载解压完成"
