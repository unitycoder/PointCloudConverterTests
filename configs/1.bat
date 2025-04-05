@echo off
REM Usage: test1.bat [app.exe path] [output folder]

set app=%~1
set outputdir=%~2

REM Automatically detect current directory (tests root folder)
set testRoot=%~dp0
set testRoot=%testRoot:~0,-1%
for %%I in ("%testRoot%") do set testRoot=%%~dpI

REM Now testRoot points to Tests\ parent directory

set inputfile=%testRoot%data\laz12_rgb.laz

REM Example execution using automatically determined paths
%app% -importformat=LAS ^
      -input="%inputfile%" ^
      -exportformat=GLB ^
      -output="%outputdir%\laz12_rgb.glb" ^
      -offset=True ^
      -offsetmode=min ^
      -rgb=True ^
      -intensity=False ^
      -classification=False ^
      -swap=True ^
      -invertZ=True ^
      -randomize=False ^
      -maxthreads=6 ^
      -usegrid=false
