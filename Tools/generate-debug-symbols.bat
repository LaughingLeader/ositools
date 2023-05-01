@echo off
set %SR%= & call get-solution-dir.bat %SR%

%SR%\x64\Release\SymbolTableGenerator.exe  "%SR%\x64\Game Release\OsiExtenderEoCApp.pdb" "%SR%\ScriptExtender\GameHooks\OsiExtenderEoCApp.symtab"