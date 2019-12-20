@echo off
SET THEFILE=D:\__develop2019\delphi\__project_delphi\PnHttpServer\dmustache\dll\libdmustache.so
echo Linking %THEFILE%
C:\fpcupdeluxe\cross\bin\x86_64-linux\x86_64-linux-ld.exe -b elf64-x86-64 -m elf_x86_64  -init FPC_SHARED_LIB_START -fini FPC_LIB_EXIT -soname libdmustache.so  -shared --gc-sections -L. -o D:\__develop2019\delphi\__project_delphi\PnHttpServer\dmustache\dll\libdmustache.so -T D:\__develop2019\delphi\__project_delphi\PnHttpServer\dmustache\dll\link.res
if errorlevel 1 goto linkend
SET THEFILE=D:\__develop2019\delphi\__project_delphi\PnHttpServer\dmustache\dll\libdmustache.so
echo Linking %THEFILE%
C:\fpcupdeluxe\cross\bin\x86_64-linux\x86_64-linux-strip.exe --discard-all --strip-debug D:\__develop2019\delphi\__project_delphi\PnHttpServer\dmustache\dll\libdmustache.so
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
