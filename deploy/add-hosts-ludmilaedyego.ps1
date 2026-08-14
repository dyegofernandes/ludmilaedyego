# Associa o nome ludmilaedyego a este computador (precisa de PowerShell como Administrador).
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$entry = '127.0.0.1 ludmilaedyego ludmilaedyego.local www.ludmilaedyego'

if (-not (Test-Path $hostsPath)) {
    throw "Arquivo hosts nao encontrado: $hostsPath"
}

$current = Get-Content $hostsPath -ErrorAction Stop
if ($current | Where-Object { $_ -match 'ludmilaedyego' }) {
    Write-Host 'O nome ludmilaedyego ja esta no arquivo hosts.'
    exit 0
}

Add-Content -Path $hostsPath -Value "`r`n$entry" -ErrorAction Stop
Write-Host 'Pronto. Acesse http://ludmilaedyego'
Write-Host 'No celular da mesma rede, use o IP deste PC ou cadastre o mesmo nome no hosts do aparelho.'
