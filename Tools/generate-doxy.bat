@echo off
set "DOXY=%~dp0\doxygen\doxygen.exe"
set %SR%= & call get-solution-dir.bat %SR%

call python doxy_make_root.py %SR%\ScriptExtender %SR%\ScriptExtenderTypeGen
pushd %SR%\ScriptExtenderTypeGen
call %DOXY%
popd
call python doxy_parse.py %SR%\ScriptExtenderTypeGen\Doxygen\xml %SR%\ScriptExtender\LuaScripts\Libs\IdeHelpersNativeData.lua