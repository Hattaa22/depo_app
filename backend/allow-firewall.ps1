# Izinkan koneksi masuk ke API Depo Air (port 3000) dari HP di jaringan WiFi
# Jalankan PowerShell sebagai Administrator:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\allow-firewall.ps1

$port = 3000
$ruleName = "Depo Air API $port"

# Hapus rule lama (Allow maupun Block) untuk Node.js di port 3000
Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

# Hapus rule Block bawaan Windows untuk Node.js yang mungkin konflik
Get-NetFirewallRule -DisplayName "Node.js JavaScript Runtime" -ErrorAction SilentlyContinue |
    Where-Object { $_.Action -eq 'Block' } |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Buat rule Allow khusus untuk port 3000
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port

Write-Host "✅ Firewall: port $port diizinkan untuk koneksi dari HP." -ForegroundColor Green
Write-Host "✅ Rule Block Node.js yang konflik sudah dihapus." -ForegroundColor Green
Write-Host ""
Write-Host "Sekarang jalankan backend: node server.js" -ForegroundColor Yellow
