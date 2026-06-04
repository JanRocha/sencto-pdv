@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\19.0\bin\rsvars.bat"
cd /d "d:\Desenvolvimento\Sencto PDV\SanctoFMX\PDV"
msbuild SanctoPDV_PDV.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /nologo /v:minimal
