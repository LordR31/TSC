::========================================================================================
call clean.bat
::========================================================================================
call build.bat
::========================================================================================
cd ../sim
@REM vsim -gui -do run.do
vsim "-%6" -do "do run.do %1 %2 %3 %4 %5"
@REM echo %0 %1 %2 %3 %4 %5
@REM vsim -c -do run.do

cd ../tools
