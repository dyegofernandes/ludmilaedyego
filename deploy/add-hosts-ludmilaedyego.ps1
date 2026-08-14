# Aponta ludmilaedyego para o servidor (porta 80). Rode como Administrador.
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$entry = '207.180.243.108 ludmilaedyego ludmilaedyego.com www.ludmilaedyego.com'

if (-not (Test-Path $hostsPath)) {
    throw "Arquivo hosts nao encontrado: $hostsPath"
}

$current = Get-Content $hostsPath -ErrorAction Stop
$filtered = $current | Where-Object { $_ -notmatch 'ludmilaedyego' }
$filtered + $entry | Set-Content $hostsPath -Encoding ASCII -ErrorAction Stop
Write-Host 'Pronto. Abra http://ludmilaedyego'
Write-Host 'O nome aponta para o servidor 207.180.243.108'
