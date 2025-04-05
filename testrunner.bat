@echo off
setlocal enabledelayedexpansion

REM === SCRIPT DIR ===
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM === APP EXE ===
set "APP_EXE=%SCRIPT_DIR%\..\PointCloudConverter\bin\x64\Release\net8.0-windows10.0.22621.0\PointCloudConverter.exe"

REM === COLOR CODES ===
set "C_RESET=[0m"
set "C_PASS=[32m"
set "C_FAIL=[31m"
set "C_INFO=[36m"
set "C_WARN=[33m"

echo %C_INFO%======================================%C_RESET%
echo %C_INFO%   POINTCLOUD CONVERTER TEST RUNNER   %C_RESET%
echo %C_INFO%======================================%C_RESET%
echo.

set /a passed=0
set /a failed=0

REM === TEMP FILES ===
set "TEMP_EXPECTED_LIST=%TEMP%\expected_list_%RANDOM%.txt"
set "TEMP_OUTPUT_LIST=%TEMP%\output_list_%RANDOM%.txt"

for %%f in (configs\*.bat) do (
    set "testname=%%~nf"
    echo %C_INFO%Running test: !testname!...%C_RESET%

    set "outdir=%SCRIPT_DIR%\output\!testname!"
    set "expdir=%SCRIPT_DIR%\expected\!testname!"

    if exist "!outdir!" rmdir /S /Q "!outdir!"
    mkdir "!outdir!"

    call "%%f" "!APP_EXE!" "!outdir!"

    if not exist "!expdir!\" (
        echo %C_FAIL%[ ERROR ] Expected folder missing for !testname!%C_RESET%
        set /a failed+=1
        echo.
        goto NextTest
    )

    set "failedThisTest=0"

    REM === Create directory listings ===
pushd "!expdir!"
dir /b /a-d | sort > "!TEMP_EXPECTED_LIST!" 2>nul
popd

pushd "!outdir!"
dir /b /a-d | find /v /i "expected_list.txt" | find /v /i "output_list.txt" | sort > "!TEMP_OUTPUT_LIST!" 2>nul
popd


    REM === Compare directory listings ===
    fc "!TEMP_EXPECTED_LIST!" "!TEMP_OUTPUT_LIST!" >nul
    if !errorlevel! NEQ 0 (
        echo %C_FAIL%[ DIR DIFF ] Folder structure differs for !testname!%C_RESET%
        type "!TEMP_EXPECTED_LIST!" > con
        echo ----
        type "!TEMP_OUTPUT_LIST!" > con
        set "failedThisTest=1"
    )

    REM === Compare file contents ===
for /f "delims=" %%x in ('type "!TEMP_EXPECTED_LIST!"') do (
    set "relativePath=%%x"
    set "expectedFile=!expdir!\!relativePath!"
    set "outputFile=!outdir!\!relativePath!"

    if not exist "!outputFile!" (
        echo %C_FAIL%[ MISSING ] !relativePath! %C_RESET%
        set "failedThisTest=1"
    ) else (
		fc /b "!expectedFile!" "!outputFile!" >nul 2>&1
		if !errorlevel! NEQ 0 (
			echo %C_FAIL%[ DIFFER ] !relativePath! %C_RESET%
			
			REM === File size check ===
			for %%s in ("!expectedFile!") do set "expectedSize=%%~zs"
			for %%s in ("!outputFile!") do set "outputSize=%%~zs"

			echo %C_WARN%Expected size: !expectedSize! bytes%C_RESET%
			echo %C_WARN%Output size  : !outputSize! bytes%C_RESET%

			set "failedThisTest=1"
		)

    )
)


    REM === Check for unexpected files in output folder ===
for /f "delims=" %%y in ('type "!TEMP_OUTPUT_LIST!"') do (
    set "relativePath=%%y"
    set "outputFile=!outdir!\!relativePath!"

    if not exist "!expdir!\!relativePath!" (
        echo %C_FAIL%[ UNKNOWN FILE ] !relativePath! %C_RESET%
        set "failedThisTest=1"
    )
)


    if !failedThisTest! EQU 0 (
        echo %C_PASS%[ PASS ] !testname!%C_RESET%
        set /a passed+=1
    ) else (
        echo %C_FAIL%[ FAIL ] !testname!%C_RESET%
        set /a failed+=1
    )

:NextTest
    echo.
)

REM === CLEAN UP TEMP FILES ===
del /f /q "!TEMP_EXPECTED_LIST!" >nul 2>&1
del /f /q "!TEMP_OUTPUT_LIST!" >nul 2>&1

echo %C_INFO%======================================%C_RESET%
echo %C_INFO% Total Tests Passed: %C_PASS%%passed%%C_RESET%
echo %C_INFO% Total Tests Failed: %C_FAIL%%failed%%C_RESET%
echo %C_INFO%======================================%C_RESET%
echo.

if !failed! GTR 0 (
    echo %C_FAIL%Some tests FAILED. Check the outputs manually.%C_RESET%
    exit /b 1
) else (
    echo %C_PASS%All tests PASSED successfully!%C_RESET%
    exit /b 0
)
