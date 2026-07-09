# build-iso.ps1
Set-Location "uup-work"

# 执行UUP官方转换脚本生成ISO
.\uup_download_windows.cmd

# 创建输出目录并移动镜像
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
