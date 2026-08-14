# Acrescenta ludmilaedyego no hosts (nao apaga o restante). Rode como Administrador.
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$entry = '207.180.243.108 ludmilaedyego ludmilaedyego.com www.ludmilaedyego.com'

if (-not (Test-Path $hostsPath)) {
    throw "Arquivo hosts nao encontrado: $hostsPath"
}

$raw = Get-Content $hostsPath -Raw -ErrorAction Stop
if ($null -eq $raw) { $raw = '' }
if ($raw -match 'ludmilaedyego') {
    $raw = ($raw -split "`r?`n" | Where-Object { $_ -notmatch 'ludmilaedyego' }) -join "`r`n"
    if ($raw -and -not $raw.EndsWith("`n")) { $raw += "`r`n" }
    $raw += "$entry`r`n"
    Set-Content -Path $hostsPath -Value $raw -Encoding ASCII -NoNewline
    Write-Host 'Atualizado. Abra http://ludmilaedyego'
    exit 0
}

Add-Content -Path $hostsPath -Value "`r`n$entry" -Encoding ASCII
Write-Host 'Pronto. Abra http://ludmilaedyego'
