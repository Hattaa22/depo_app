@echo off
:: Klik kanan file ini -> Run as administrator
echo Menambahkan aturan firewall untuk port 3000...
netsh advfirewall firewall delete rule name="Depo Air API 3000" >nul 2>&1
netsh advfirewall firewall add rule name="Depo Air API 3000" dir=in action=allow protocol=TCP localport=3000
if %errorlevel%==0 (
    echo Berhasil. HP sekarang bisa akses http://IP-PC:3000/v1/health
) else (
    echo Gagal. Pastikan Run as Administrator.
)
pause
