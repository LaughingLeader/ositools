@echo off

CALL :GetRoot SR
EXIT /B 0

:GetRoot
set REL_PATH=..\
set %~1=
pushd %REL_PATH%
set %~1=%CD%
popd
EXIT /B 0