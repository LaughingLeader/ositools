@echo off
set %SR%= & call get-solution-dir.bat %SR%
set "SE=%SR%\ScriptExtender"
set "CMD=%SR%\External\x64-windows\tools\protobuf\protoc"

call :GenProto "%SE%\Extender\Shared" "ScriptExtensions.proto"
call :GenProto "%SE%\Lua\Debugger" "LuaDebug.proto"
call :GenProto "%SE%\Osiris\Debugger" "osidebug.proto"

cd %~dp0
EXIT /B 0

:GenProto
cd %~1
%CMD% --cpp_out=. %~2
popd
EXIT /B 0