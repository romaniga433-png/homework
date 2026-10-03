@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

REM --- 1. Проверка на вызов справки ---
if "%~1"=="/?" goto show_help
if "%~1"=="-?" goto show_help

REM --- 2. Проверка количества аргументов ---
if "%~1"=="" goto err_args
if "%~2"=="" goto err_args
if "%~3"=="" goto err_args
if not "%~4"=="" goto err_args

set "TARGET_DIR=%~1"
set "ENC_FROM=%~2"
set "ENC_TO=%~3"

REM --- 3. Проверка существования каталога ---
if not exist "%TARGET_DIR%\" (
    echo [ERROR] Каталог "%TARGET_DIR%" не найден.
    exit /b 1
)

REM --- 4. Проверка и маппинг исходной кодировки ---
set "ICONV_FROM="
if /i "%ENC_FROM%"=="ascii" set "ICONV_FROM=ASCII"
if /i "%ENC_FROM%"=="cp866" set "ICONV_FROM=CP866"
if /i "%ENC_FROM%"=="koi8"  set "ICONV_FROM=KOI8-R"
if /i "%ENC_FROM%"=="utf8"  set "ICONV_FROM=UTF-8"
if /i "%ENC_FROM%"=="utf16" set "ICONV_FROM=UTF-16LE"

if "%ICONV_FROM%"=="" (
    echo [ERROR] Недопустимая исходная кодировка: %ENC_FROM%
    echo Разрешенные кодировки: ascii, cp866, koi8, utf8, utf16
    exit /b 1
)

REM --- 5. Проверка и маппинг целевой кодировки ---
set "ICONV_TO="
if /i "%ENC_TO%"=="ascii" set "ICONV_TO=ASCII"
if /i "%ENC_TO%"=="cp866" set "ICONV_TO=CP866"
if /i "%ENC_TO%"=="koi8"  set "ICONV_TO=KOI8-R"
if /i "%ENC_TO%"=="utf8"  set "ICONV_TO=UTF-8"
if /i "%ENC_TO%"=="utf16" set "ICONV_TO=UTF-16LE"

if "%ICONV_TO%"=="" (
    echo [ERROR] Недопустимая целевая кодировка: %ENC_TO%
    echo Разрешенные кодировки: ascii, cp866, koi8, utf8, utf16
    exit /b 1
)

REM --- 6. Основной блок обработки ---
set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

echo === Конвертация файлов в каталоге: %TARGET_DIR% ===
echo === Из %ENC_FROM% в %ENC_TO% ===
echo.

REM Рекурсивный обход всех .txt файлов в каталоге и подкаталогах
for /r "%TARGET_DIR%" %%F in (*.txt) do (
    echo Обработка: "%%~fF"
    
    REM Генерируем имя временного файла
    set "TMPFILE=%%~dpnF_temp_!random!.tmp"
    
    if exist "!TMPFILE!" (
        echo [ERROR] Временный файл уже существует: "!TMPFILE!"
        set /a ERROR_COUNT+=1
    ) else (
        
        REM Вызов iconv. Обрати внимание: мы убрали 2>nul, чтобы видеть реальные ошибки DLL
        iconv.exe -f !ICONV_FROM! -t !ICONV_TO! "%%~fF" > "!TMPFILE!"
        
        if errorlevel 1 (
            echo [ERROR] Ошибка конвертации файла: "%%~fF"
            set /a ERROR_COUNT+=1
            if exist "!TMPFILE!" del /f /q "!TMPFILE!"
        ) else (
            REM Заменяем исходный файл временным
            move /y "!TMPFILE!" "%%~fF" >nul 2>&1
            if errorlevel 1 (
                echo [ERROR] Не удалось заменить исходный файл: "%%~fF"
                set /a ERROR_COUNT+=1
                if exist "!TMPFILE!" del /f /q "!TMPFILE!"
            ) else (
                echo [OK] Успешно сконвертирован
                set /a SUCCESS_COUNT+=1
            )
        )
    )
    echo.
)

echo === Обработка завершена ===
echo Успешно сконвертировано: %SUCCESS_COUNT% файлов
echo Ошибок: %ERROR_COUNT% файлов
exit /b 0

REM --- Блоки ошибок и справки ---
:err_args
echo [ERROR] Неверное количество аргументов.
echo Использование: enconvert.cmd ^<каталог^> ^<исходная_кодировка^> ^<целевая_кодировка^>
echo Справка: enconvert.cmd /?
exit /b 1

:show_help
echo Справка по скрипту enconvert.cmd
echo.
echo Назначение: Рекурсивная конвертация текстовых файлов (.txt)
echo Использование: enconvert.cmd ^<каталог^> ^<исходная_кодировка^> ^<целевая_кодировка^>
echo.
echo Разрешенные кодировки: ascii, cp866, koi8, utf8, utf16
echo.
echo Пример:
echo   enconvert.cmd "C:\texts" cp866 utf8
exit /b 0