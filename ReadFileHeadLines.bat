@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
d:
cd d:\ptest

set i=0
for /f "delims=#" %%a in (cif.xml) do (
    if !i!==5 goto end

    echo %%a
    set /a i=!i!+1

)

:end
@pause
