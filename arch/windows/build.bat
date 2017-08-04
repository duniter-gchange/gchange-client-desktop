
set NW_VERSION=0.22.3
set NW_RELEASE=v%NW_VERSION%
set NW=nwjs-%NW_RELEASE%-win-x64
set NW_GZ=%NW%.zip
echo %NW%
echo %NW_GZ%
echo %NW_RELEASE%
node -v

REM NPM
set PATH="C:\Users\vagrant\AppData\Roaming\npm";%PATH%
REM InnoSetup
set PATH="C:\Program Files (x86)\Inno Setup 5";%PATH%

cd C:\Users\vagrant
REM echo "Suppression des anciennes sources..."
rd /s /q gchange
rd /s /q gchange_release
echo "Clonage de Gchange..."
git clone https://github.com/duniter/gchange.git
cd gchange

for /f "delims=" %%a in ('git rev-list --tags --max-count=1') do @set GCHANGE_REV=%%a
for /f "delims=" %%a in ('git describe --tags %GCHANGE_REV%') do @set GCHANGE_TAG=%%a
set GCHANGE=gchange-%GCHANGE_TAG%-web
set GCHANGE_ZIP=%GCHANGE%.zip
echo %GCHANGE_TAG%
echo %GCHANGE%
echo %GCHANGE_ZIP%

cd ..

if not exist C:\vagrant\%NW_GZ% (
  echo "Telechargement de %NW%.zip..."
  REM powershell -Command "Invoke-WebRequest -Uri https://dl.nwjs.io/v%NW_VERSION%/%NW%.zip -OutFile C:\vagrant\%NW_GZ%"
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile(\"https://dl.nwjs.io/v%NW_VERSION%/%NW%.zip\", \"C:\vagrant\%NW_GZ%\")"
)

if not exist C:\vagrant\%GCHANGE_ZIP% (
  echo "Telechargement de %GCHANGE_ZIP%..."
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile(\"https://github.com/duniter/gchange/releases/download/%GCHANGE_TAG%/%GCHANGE_ZIP%\", \"C:\vagrant\%GCHANGE_ZIP%\")"
)

call 7z x C:\vagrant\%NW_GZ%
move %NW% gchange_release
cd gchange_release
mkdir gchange
cd gchange
call 7z x C:\vagrant\%GCHANGE_ZIP%

cd ..
xcopy C:\vagrant\LICENSE.txt .\ /s /e
xcopy C:\vagrant\package.json .\ /s /e
xcopy C:\vagrant\node.js .\gchange\ /s /e
call npm install

cd C:\Users\vagrant\gchange_release\gchange
powershell -Command "(Get-Content C:\Users\vagrant\gchange_release\gchange\index.html) | foreach-object {$_ -replace '<script src=\"config.js\"></script>','<script src=\"config.js\"></script><script src=\"node.js\"></script>' } | Set-Content C:\Users\vagrant\gchange_release\gchange\index.txt"
powershell -Command "(Get-Content C:\Users\vagrant\gchange_release\gchange\debug.html) | foreach-object {$_ -replace '<script src=\"config.js\"></script>','<script src=\"config.js\"></script><script src=\"node.js\"></script>' } | Set-Content C:\Users\vagrant\gchange_release\gchange\debug.txt"

move index.txt index.html
move debug.txt debug.html
cd ..

iscc C:\vagrant\gchange.iss /DROOT_PATH=%cd%
move %cd%\Gchange.exe C:\vagrant\gchange-desktop-%GCHANGE_TAG%-windows-x64.exe
echo "Build done: binary available at gchange-desktop-%GCHANGE_TAG%-windows-x64.exe"
