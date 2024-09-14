@echo off
goto:$main

:$error
exit /b 1

:$build
setlocal EnableExtensions
    set "SOURCE_DIR=%~1"
    :: remove trailing slash if there is one
    if "%SOURCE_DIR:~-1%"=="\" set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"

    rye run meson setup ^
        -Dbackend_max_links=1 ^
        -Ddebug=false ^
        -Dmedia-gstreamer=disabled ^
        -Dvulkan=disabled "%SOURCE_DIR%\_build" "%SOURCE_DIR%"
    if errorlevel 1 goto :$build_error

    ninja -C _build
    if errorlevel 1 goto :$build_error

    :$build_error
    echo Build error.
    goto:$build_done

    :$build_done
endlocal & exit /b %ERRORLEVEL%

:$main
setlocal EnableExtensions
    :: vcvarsall.bat sets various env vars like PATH, INCLUDE, LIB, LIBPATH for the
    :: specified build architecture
    call "C:\Program Files\Microsoft Visual Studio\2022\Preview\VC\Auxiliary\Build\vcvarsall.bat" x64
    call :$build "%~dp0\..\"
endlocal & (
    exit /b %ERRORLEVEL%
)
