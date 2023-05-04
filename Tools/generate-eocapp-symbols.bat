@echo off
set %SR%= & call get-solution-dir.bat %SR%

"%SR%\x64\Release\SymbolTableGenerator.exe" "%~dp0\EoCApp.pdb" "%SR%\ScriptExtender\GameHooks\EoCApp.symtab"