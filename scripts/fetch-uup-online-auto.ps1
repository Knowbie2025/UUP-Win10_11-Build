# fetch-uup-online-auto.ps1 在线全自动CF绕过版
$targetBuild = $env:TARGET_BUILD
$arch = $env:ARCH
$lang = $env:LANG
$apiBase = "https://uup.rg-adguard.net"

# Step1：调用node无头浏览器过CF验证，获取有效访问凭证
$nodeScript = @"
const puppeteer = require('puppeteer-core');
const cfBypass = require('chrome-cf-bypass');
(async () => {
    const browser = await puppeteer.launch({
        headless: "new",
        executablePath: await cfBypass.getChromePath()
    });
    const page = await browser.newPage();
    await page.goto('$apiBase');
    await cfBypass.waitCfClearance(page, 30000);
    const cookies = await page.cookies();
    const userAgent = await page.evaluate(() => navigator.userAgent);
    await browser.close();
    console.log(JSON.stringify({cookies,userAgent}));
})();
"@
$nodeScript | Out-File "cf-bypass-tmp.js" -Encoding utf8
$cfResultRaw = node cf-bypass-tmp.js
Remove-Item "cf-bypass-tmp.js" -Force
$cfResult = $cfResultRaw | ConvertFrom-Json

# 拼接请求头
$cookieHeader = $cfResult.cookies | ForEach-Object { "$($_.name)=$($_.value)" } -Join "; "
$headers = @{
    "User-Agent" = $cfResult.userAgent
    "Cookie" = $cookieHeader
}

# Step2：携带CF凭证查询Build列表
$apiUrl = "$apiBase/api/v1/builds?search=$targetBuild&arch=$arch"
$response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing -TimeoutSec 40

# 筛选最新版本
$latestBuild = $response | Sort-Object buildrev -Descending | Select-Object -First 1
if (-not $latestBuild) {
    Write-Error "未找到对应Build:$targetBuild 架构:$arch"
    exit 1
}
$env:LATEST_SUB_BUILD = $latestBuild.buildrev
$updateId = $latestBuild.updatedid
Write-Host "✅ 获取在线最新版本: $targetBuild.$($latestBuild.buildrev)"

# 下载包参数（全SKU简体中文）
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

# Step3：在线下载UUP脚本压缩包
$downloadUrl = "$apiBase/api/v1/downloadpackage"
Invoke-WebRequest `
    -Uri $downloadUrl `
    -Method Post `
    -Headers $headers `
    -Body $postData `
    -OutFile "uup-package.zip" `
    -UseBasicParsing `
    -TimeoutSec 60

# Step4：解压脚本包
if (Test-Path "uup-work") { Remove-Item "uup-work" -Recurse -Force }
7z x uup-package.zip -ouup-work -y
Write-Host "✅ 在线下载UUP脚本包解压完成"
