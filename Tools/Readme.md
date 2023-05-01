# Extender Generator Scripts

These scripts are required to be able to ultimately build the solution.

## Additional Requirements  

You'll need these additional files to run specific scripts.

### generate-eocapp-symbols  

*Requirements: EoCApp.pdb*

This script required to generate the necessary game symbols, which the ScriptExtender csproj needs in order to build. 
`EoCApp.pdb` should be placed in the Tools folder.

### generate-eocapp-symbols  

*Requirements: [doxygen](https://github.com/doxygen/)*

doxygen is required to ultimately generate new information for `ExtIdeHelpers.lua`.

#### Instructions  

Grab the latest doxygen binary from the Github Actions section here:  
[Doxygen Actions](https://github.com/doxygen/doxygen/actions)

1. Click the top-most workflow with a green checkmark.
2. Scroll down to the "Artifacts" section.
3. Click "Windows Latest MSVC Release build artifacts" to download the latest release.
4. Unzip the downloaded file and place the contents within `Tools/doxygen`, so the file structure looks like this:
```
ositools/Tools/doxygen/doxygen.exe
ositools/Tools/doxygen/doxygen.exe.manifest
ositools/Tools/doxygen/doxywizard.exe
ositools/Tools/doxygen/doxywizard.exe.manifest
```
