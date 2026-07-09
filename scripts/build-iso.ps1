# build-iso.ps1
# 进入脚本工作目录
Set-Location "uup-work"

# 执行官方下载转换脚本，自动拉取微软UUP源并生成ISO
.\uup_download_windows.cmd

# 创建输出目录，移动生成好的ISO
if (-not (Test-Path "../output")) { New-Item "../output" -ItemType Directory -Force | Out-Null }
$isoFile = Get-ChildItem -Filter *.iso | Select-Object -First 1
if ($isoFile) {
    Move-Item $isoFile.FullName "../output/" -Force
    Write-Host "ISO镜像构建完成，已移至output目录: $($isoFile.Name)"
} else {
    Write-Error "未生成ISO镜像，构建失败"
    exit 1
}
Set-Location ../
