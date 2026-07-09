# split-archive.ps1
$outputDir = "./output"
$isoFile = Get-ChildItem -Path $outputDir -Filter *.iso | Select-Object -First 1
if (-not $isoFile) {
    Write-Error "output目录未找到ISO文件"
    exit 1
}

$baseName = $isoFile.BaseName
$zipFullPath = Join-Path $outputDir "$baseName.zip"

# -v2g 代表单分卷最大2000MB
7z a -v2g "$zipFullPath" $isoFile.FullName -y
Write-Host "ISO分卷打包完成，单卷2000MB，分卷存放于 $outputDir"
