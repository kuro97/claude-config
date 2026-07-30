# Notification hook: всплывающее окно «Claude Code ждёт ввод».
# Вынесено из settings.json в файл: powershell.exe искажает кириллицу,
# переданную через -Command (проверено 2026-07-30). Из .ps1 с BOM читается верно.
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('Claude Code ждёт ввод', 'Claude Code', 'OK', 'Information') | Out-Null