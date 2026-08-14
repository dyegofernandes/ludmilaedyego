# Restaura o hosts e aponta ludmilaedyego ao servidor. Rode como Administrador.
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$src = 'c:\casamento\deploy\hosts-ludmilaedyego.txt'
Copy-Item -Path $src -Destination $hostsPath -Force
Write-Host 'Hosts restaurado. Abra http://ludmilaedyego'
