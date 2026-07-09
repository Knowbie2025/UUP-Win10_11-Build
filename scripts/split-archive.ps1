# split-archive.ps1
$outputDir = "./output"
$isoFile = Get-ChildItem -Path $outputDir -Filter *.iso | Select-Object -First 1
if (-not $isoFile) {
    Write-Error "output目录未找到ISO文件"
    exit 1
}

$baseName = $isoFile.BaseName
$zipFullPath = Join-Path $outputDir "$baseName.zip"

# 分卷大小4GB，生成 xxx.zip.001 .002 .003 ...
7z a -v4g "$zipFullPath" $isoFile.FullName -y
Write-Host "ISO分卷打包完成，分卷存放于 $outputDir"
