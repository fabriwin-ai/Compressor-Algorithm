@echo off
setlocal
chcp 65001 >nul
title FFmpeg Compressor - Music and Videos

rem ============================================================
rem  CONFIG (edit if needed)
rem ============================================================
set "FFMPEG=C:\ffmpeg\bin\ffmpeg.exe"
set "SRC=C:\Users\Fabricio\#Downloads"
rem Video encoder speed: ultrafast superfast veryfast faster fast medium slow slower veryslow
rem (slower = smaller file for the same quality, but takes longer)
set "ENC_PRESET=medium"
rem Player used by the PLAY menu (ships with the full ffmpeg download)
set "FFPLAY=C:\ffmpeg\bin\ffplay.exe"
rem File types handled by the compressor and by the PLAY menu
set "AUD_EXTS=mp3 wav flac m4a aac ogg opus wma aif aiff"
set "VID_EXTS=mp4 mkv avi mov wmv flv webm m4v mpg mpeg ts m2ts 3gp"
rem ============================================================
rem
rem  DECISION TREES
rem
rem  MUSIC : format, then audio type, then bitrate (options depend
rem          on the audio type), then channels (voice only)
rem  VIDEO : codec, then rate control, then max resolution, then
rem          quality level (CRF mode) or bitrate (bitrate mode,
rem          options depend on the resolution), then audio bitrate
rem
rem  PLAY  : music or videos, then compressed or original files,
rem          then play all or choose a file from a numbered list
rem
rem  Every step has [0] Back (the first step has [0] Cancel).
rem  A summary is shown at the end and you confirm before starting.
rem ============================================================

rem Tip: drag and drop a folder onto this .bat to use it as the source instead
if not "%~1"=="" set "SRC=%~1"

set "OUT_ROOT=%SRC%\Compressed"
set "OUT_MUSIC=%OUT_ROOT%\Music"
set "OUT_VIDEO=%OUT_ROOT%\Videos"

if not exist "%FFMPEG%" goto err_ffmpeg
if not exist "%SRC%\" goto err_src

:MAIN
cls
echo ============================================================
echo   FFmpeg Compressor
echo ============================================================
echo   Source : %SRC%
echo   Output : %OUT_ROOT%
echo   (originals are never modified or deleted)
echo.
echo   [1] Compress MUSIC
echo   [2] Compress VIDEOS
echo   [3] Compress BOTH (music first, then videos)
echo   [4] PLAY music or videos
echo   [5] Open output folder
echo   [0] Exit
echo.
choice /c 123450 /n /m "Select an option: "
set "SEL=%errorlevel%"
if %SEL%==6 goto :EOF
if %SEL%==5 goto OPEN_OUT
if %SEL%==4 goto PLAY_MENU
if %SEL%==3 goto DO_BOTH
if %SEL%==2 goto DO_VIDEO
goto DO_MUSIC

:DO_MUSIC
set "MODE=M"
call :PICK_MUSIC
if defined CANCEL goto MAIN
call :CONFIRM
if defined CANCEL goto MAIN
call :RUN_MUSIC
goto DONE

:DO_VIDEO
set "MODE=V"
call :PICK_VIDEO
if defined CANCEL goto MAIN
call :CONFIRM
if defined CANCEL goto MAIN
call :RUN_VIDEO
goto DONE

:DO_BOTH
set "MODE=B"
call :PICK_MUSIC
if defined CANCEL goto MAIN
call :PICK_VIDEO
if defined CANCEL goto MAIN
call :CONFIRM
if defined CANCEL goto MAIN
call :RUN_MUSIC
call :RUN_VIDEO
goto DONE

:DONE
echo.
echo All done. Files are in: %OUT_ROOT%
pause
goto MAIN

:OPEN_OUT
if not exist "%OUT_ROOT%" mkdir "%OUT_ROOT%"
start "" "%OUT_ROOT%"
goto MAIN

:err_ffmpeg
echo [ERROR] ffmpeg not found at: %FFMPEG%
pause
goto :EOF

:err_src
echo [ERROR] Source folder not found: %SRC%
pause
goto :EOF


rem ============================================================
rem  CONFIRM SCREEN
rem ============================================================

:CONFIRM
cls
echo ============================================================
echo   READY TO START
echo ============================================================
echo   Source : %SRC%
echo.
if "%MODE%"=="V" goto cf_video
echo   MUSIC  : %ML1% / %ML2% / %ABR% kbps %ML3%
if "%MODE%"=="M" goto cf_ask
:cf_video
echo   VIDEOS : %VL1% / %VL2% / %VL3% / %VL4% / audio %ABRV% kbps
:cf_ask
echo.
choice /c YN /n /m "Start now? [Y/N]: "
if errorlevel 2 set "CANCEL=1"
goto :EOF


rem ============================================================
rem  MUSIC DECISION TREE
rem ============================================================

:PICK_MUSIC
set "CANCEL="

rem ---------- Step 1: output format ----------
:pm1
cls
echo ============================================================
echo   MUSIC  -  step 1: output format
echo ============================================================
echo.
echo   [1] MP3   - most compatible
echo   [2] M4A   - AAC, better than MP3 at the same bitrate
echo   [3] OPUS  - best quality per kbps (modern players only)
echo   [0] Cancel
echo.
choice /c 1230 /n /m "Format: "
set "SEL=%errorlevel%"
if %SEL%==4 goto pm_cancel
if %SEL%==3 set "AEXT=opus" & set "ML1=OPUS" & goto pm2
if %SEL%==2 set "AEXT=m4a" & set "ML1=M4A" & goto pm2
set "AEXT=mp3"
set "ML1=MP3"
goto pm2

rem ---------- Step 2: audio type ----------
:pm2
cls
echo ============================================================
echo   MUSIC  -  step 2: what kind of audio is it?
echo ============================================================
echo   Path: MUSIC / %ML1%
echo.
echo   [1] Voice   - podcasts, audiobooks, lectures
echo   [2] Music   - everyday listening
echo   [3] Hi-fi   - critical listening, archiving
echo   [0] Back
echo.
choice /c 1230 /n /m "Type: "
set "SEL=%errorlevel%"
if %SEL%==4 goto pm1
if %SEL%==3 goto pm2_hifi
if %SEL%==2 goto pm2_music
set "ML2=Voice"
set "MVOICE=1"
set "B1=48"
set "B2=64"
set "B3=96"
set "D1=smallest, still clear speech"
set "D2=recommended for speech"
set "D3=speech with light music or jingles"
goto pm_rate
:pm2_music
set "ML2=Music"
set "MVOICE=0"
set "B1=128"
set "B2=160"
set "B3=192"
set "D1=good for phone and casual listening"
set "D2=balanced"
set "D3=very good quality"
goto pm_rate
:pm2_hifi
set "ML2=Hi-fi"
set "MVOICE=0"
set "B1=224"
set "B2=256"
set "B3=320"
set "D1=high quality"
set "D2=near transparent"
set "D3=maximum (best for MP3)"
goto pm_rate

rem ---------- Step 3: bitrate (options depend on step 2) ----------
:pm_rate
cls
echo ============================================================
echo   MUSIC  -  step 3: bitrate
echo ============================================================
echo   Path: MUSIC / %ML1% / %ML2%
echo.
echo   [1] %B1% kbps  -  %D1%
echo   [2] %B2% kbps  -  %D2%
echo   [3] %B3% kbps  -  %D3%
echo   [0] Back
echo.
echo   Tip: pick a bitrate LOWER than your source files, otherwise
echo   the output can end up bigger than the original.
echo.
choice /c 1230 /n /m "Bitrate: "
set "SEL=%errorlevel%"
if %SEL%==4 goto pm2
if %SEL%==3 set "ABR=%B3%" & goto pm_after_rate
if %SEL%==2 set "ABR=%B2%" & goto pm_after_rate
set "ABR=%B1%"

:pm_after_rate
if "%MVOICE%"=="1" goto pm4
set "ACH="
set "ML3="
goto pm_build

rem ---------- Step 4 (voice only): channels ----------
:pm4
cls
echo ============================================================
echo   MUSIC  -  step 4: channels
echo ============================================================
echo   Path: MUSIC / %ML1% / %ML2% / %ABR% kbps
echo.
echo   [1] Mono            - best speech clarity at low bitrates
echo   [2] Keep channels   - leave stereo or mono as in the source
echo   [0] Back
echo.
choice /c 120 /n /m "Channels: "
set "SEL=%errorlevel%"
if %SEL%==3 goto pm_rate
if %SEL%==1 set "ACH=-ac 1" & set "ML3=Mono" & goto pm_build
set "ACH="
set "ML3=original channels"
goto pm_build

rem ---------- Build the ffmpeg audio arguments ----------
:pm_build
if /i "%AEXT%"=="opus" goto pmb_opus
if /i "%AEXT%"=="m4a" goto pmb_m4a
set "ACODEC=-c:a libmp3lame -b:a %ABR%k %ACH%"
set "ACOVER=-c:v copy -id3v2_version 3"
goto :EOF
:pmb_m4a
set "ACODEC=-c:a aac -b:a %ABR%k %ACH%"
set "ACOVER=-c:v copy -disposition:v:0 attached_pic"
goto :EOF
:pmb_opus
set "ACODEC=-c:a libopus -b:a %ABR%k -vbr on %ACH%"
set "ACOVER="
goto :EOF

:pm_cancel
set "CANCEL=1"
goto :EOF


rem ============================================================
rem  MUSIC RUN
rem ============================================================

:RUN_MUSIC
set "OK=0"
set "SKIP=0"
set "FAIL=0"
if not exist "%OUT_MUSIC%" mkdir "%OUT_MUSIC%"
echo.
echo --- Compressing MUSIC: %ML1% / %ML2% / %ABR% kbps %ML3% ---
for %%E in (%AUD_EXTS%) do (
    for %%F in ("%SRC%\*.%%E") do (
        set "CUR=%%~fF"
        call :AUDIO_ONE
    )
)
call :SUMMARY
goto :EOF

:AUDIO_ONE
for %%I in ("%CUR%") do set "NAME=%%~nI"& set "NAMEX=%%~nxI"
set "OUTFILE=%OUT_MUSIC%\%NAME%.%AEXT%"
if exist "%OUTFILE%" goto ao_skip
echo [ENC ] "%NAMEX%"
if /i "%AEXT%"=="opus" goto ao_plain
rem First try keeping the cover art
"%FFMPEG%" -hide_banner -loglevel error -y -i "%CUR%" -map 0:a:0 -map 0:v:0? -map_metadata 0 %ACODEC% %ACOVER% "%OUTFILE%"
if not errorlevel 1 goto ao_ok
:ao_plain
rem Fallback (or opus): audio only, no cover art
"%FFMPEG%" -hide_banner -loglevel error -y -i "%CUR%" -vn -map 0:a:0 -map_metadata 0 %ACODEC% "%OUTFILE%"
if errorlevel 1 goto ao_fail
:ao_ok
set /a OK+=1
goto :EOF
:ao_skip
echo [SKIP] "%NAMEX%" already exists in output
set /a SKIP+=1
goto :EOF
:ao_fail
echo [FAIL] "%NAMEX%"
if exist "%OUTFILE%" del "%OUTFILE%"
set /a FAIL+=1
goto :EOF


rem ============================================================
rem  VIDEO DECISION TREE
rem ============================================================

:PICK_VIDEO
set "CANCEL="

rem ---------- Step 1: codec ----------
:pv1
cls
echo ============================================================
echo   VIDEOS  -  step 1: codec
echo ============================================================
echo.
echo   [1] H.264  - most compatible (TV, phone, any player)
echo   [2] H.265  - about 40 percent smaller at the same quality,
echo                slower to encode, less compatible
echo   [0] Cancel
echo.
choice /c 120 /n /m "Codec: "
set "SEL=%errorlevel%"
if %SEL%==3 goto pv_cancel
if %SEL%==2 set "VCODEC=265" & set "VL1=H.265" & goto pv2
set "VCODEC=264"
set "VL1=H.264"
goto pv2

rem ---------- Step 2: rate control ----------
:pv2
cls
echo ============================================================
echo   VIDEOS  -  step 2: how should the size be controlled?
echo ============================================================
echo   Path: VIDEO / %VL1%
echo.
echo   [1] Quality-based (CRF)  - constant quality, size adapts to the
echo                              video. Recommended.
echo   [2] Target bitrate       - predictable size, quality varies by scene
echo   [0] Back
echo.
choice /c 120 /n /m "Mode: "
set "SEL=%errorlevel%"
if %SEL%==3 goto pv1
if %SEL%==2 set "RMODE=BR" & set "VL2=Target bitrate" & goto pv3
set "RMODE=CRF"
set "VL2=CRF quality"
goto pv3

rem ---------- Step 3: max resolution ----------
:pv3
cls
echo ============================================================
echo   VIDEOS  -  step 3: maximum resolution
echo ============================================================
echo   Path: VIDEO / %VL1% / %VL2%
echo.
echo   [1] 480p   - smallest, for sharing or old devices
echo   [2] 720p   - good for phones and small screens
echo   [3] 1080p  - Full HD
echo   [4] Keep original resolution
echo   [0] Back
echo.
echo   Resolutions are caps: smaller videos are never upscaled.
echo.
choice /c 12340 /n /m "Resolution: "
set "SEL=%errorlevel%"
if %SEL%==5 goto pv2
if %SEL%==4 goto pv3_orig
if %SEL%==3 goto pv3_1080
if %SEL%==2 goto pv3_720
set "VHEIGHT=480"
set "VL3=480p max"
set "B1=500"
set "B2=800"
set "B3=1200"
goto pv3_done
:pv3_720
set "VHEIGHT=720"
set "VL3=720p max"
set "B1=1000"
set "B2=1800"
set "B3=2800"
goto pv3_done
:pv3_1080
set "VHEIGHT=1080"
set "VL3=1080p max"
set "B1=2500"
set "B2=4500"
set "B3=7000"
goto pv3_done
:pv3_orig
set "VHEIGHT=0"
set "VL3=original resolution"
set "B1=4000"
set "B2=8000"
set "B3=12000"

:pv3_done
if "%RMODE%"=="CRF" goto pv4_crf
rem Bitrate mode: H.265 needs about 40 percent less bitrate for the same quality
if "%VCODEC%"=="265" set /a B1=B1*60/100 & set /a B2=B2*60/100 & set /a B3=B3*60/100
goto pv4_rate

rem ---------- Step 4a (CRF mode): quality level ----------
:pv4_crf
cls
echo ============================================================
echo   VIDEOS  -  step 4: quality level
echo ============================================================
echo   Path: VIDEO / %VL1% / %VL2% / %VL3%
echo.
echo   [1] Small file    - lower quality, softer detail
echo   [2] Balanced      - good quality, big size saving (recommended)
echo   [3] High quality  - near-original look, larger files
echo   [0] Back
echo.
choice /c 1230 /n /m "Quality: "
set "SEL=%errorlevel%"
if %SEL%==4 goto pv3
if %SEL%==3 set "CRFV=20" & set "VL4=High quality" & goto pv5
if %SEL%==2 set "CRFV=23" & set "VL4=Balanced" & goto pv5
set "CRFV=26"
set "VL4=Small file"
goto pv5

rem ---------- Step 4b (bitrate mode): video bitrate (depends on step 3) ----------
:pv4_rate
cls
echo ============================================================
echo   VIDEOS  -  step 4: video bitrate
echo ============================================================
echo   Path: VIDEO / %VL1% / %VL2% / %VL3%
echo.
echo   [1] %B1% kbps  -  small file
echo   [2] %B2% kbps  -  balanced (recommended)
echo   [3] %B3% kbps  -  high quality
echo   [0] Back
echo.
echo   Values are already adjusted for the codec you picked.
echo.
choice /c 1230 /n /m "Bitrate: "
set "SEL=%errorlevel%"
if %SEL%==4 goto pv3
if %SEL%==3 set "VBR=%B3%" & set "VL4=%B3% kbps" & goto pv5
if %SEL%==2 set "VBR=%B2%" & set "VL4=%B2% kbps" & goto pv5
set "VBR=%B1%"
set "VL4=%B1% kbps"
goto pv5

rem ---------- Step 5: audio bitrate ----------
:pv5
cls
echo ============================================================
echo   VIDEOS  -  step 5: audio bitrate
echo ============================================================
echo   Path: VIDEO / %VL1% / %VL2% / %VL3% / %VL4%
echo.
echo   [1]  96 kbps  -  speech, smallest size
echo   [2] 128 kbps  -  good for most videos
echo   [3] 192 kbps  -  music videos, concerts
echo   [0] Back
echo.
choice /c 1230 /n /m "Audio: "
set "SEL=%errorlevel%"
if %SEL%==4 goto pv5_back
if %SEL%==3 set "ABRV=192" & goto pv_build
if %SEL%==2 set "ABRV=128" & goto pv_build
set "ABRV=96"
goto pv_build
:pv5_back
if "%RMODE%"=="CRF" goto pv4_crf
goto pv4_rate

rem ---------- Build the ffmpeg video arguments ----------
:pv_build
rem Video filter: optional downscale (never upscale) plus a safe pixel format
if "%VHEIGHT%"=="0" goto pvb_keep
set "VF=scale=-2:'min(%VHEIGHT%,ih)',format=yuv420p"
goto pvb_codec
:pvb_keep
set "VF=format=yuv420p"
:pvb_codec
if "%VCODEC%"=="265" goto pvb_265
set "VENC=-c:v libx264 -preset %ENC_PRESET%"
goto pvb_rate
:pvb_265
set "VENC=-c:v libx265 -preset %ENC_PRESET% -tag:v hvc1 -x265-params log-level=error"
rem x265 CRF scale is about 5 points higher than x264 for the same look
if "%RMODE%"=="CRF" set /a CRFV=CRFV+5
:pvb_rate
if "%RMODE%"=="CRF" goto pvb_crf
set /a MAXR=VBR*3/2
set /a BUFS=VBR*2
set "VRATE=-b:v %VBR%k -maxrate %MAXR%k -bufsize %BUFS%k"
goto :EOF
:pvb_crf
set "VRATE=-crf %CRFV%"
goto :EOF

:pv_cancel
set "CANCEL=1"
goto :EOF


rem ============================================================
rem  VIDEO RUN
rem ============================================================

:RUN_VIDEO
set "OK=0"
set "SKIP=0"
set "FAIL=0"
if not exist "%OUT_VIDEO%" mkdir "%OUT_VIDEO%"
echo.
echo --- Compressing VIDEOS: %VL1% / %VL2% / %VL3% / %VL4% / audio %ABRV% kbps ---
for %%E in (%VID_EXTS%) do (
    for %%F in ("%SRC%\*.%%E") do (
        set "CUR=%%~fF"
        call :VIDEO_ONE
    )
)
call :SUMMARY
goto :EOF

:VIDEO_ONE
for %%I in ("%CUR%") do set "NAME=%%~nI"& set "NAMEX=%%~nxI"
set "OUTFILE=%OUT_VIDEO%\%NAME%.mp4"
if exist "%OUTFILE%" goto vo_skip
echo [ENC ] "%NAMEX%"
"%FFMPEG%" -hide_banner -loglevel error -stats -y -i "%CUR%" -map 0:v:0 -map 0:a? -sn -dn -map_metadata 0 %VENC% %VRATE% -vf "%VF%" -c:a aac -b:a %ABRV%k -movflags +faststart "%OUTFILE%"
if errorlevel 1 goto vo_fail
set /a OK+=1
goto :EOF
:vo_skip
echo [SKIP] "%NAMEX%" already exists in output
set /a SKIP+=1
goto :EOF
:vo_fail
echo [FAIL] "%NAMEX%"
if exist "%OUTFILE%" del "%OUTFILE%"
set /a FAIL+=1
goto :EOF


rem ============================================================
rem  PLAY MENU
rem ============================================================

:PLAY_MENU
set "LIST=%TEMP%\ffc_playlist.txt"

rem ---------- Step 1: music or videos ----------
:pl1
cls
echo ============================================================
echo   PLAY  -  step 1: what do you want to play?
echo ============================================================
if not exist "%FFPLAY%" echo   ffplay.exe not found, the default Windows player will be used.
echo.
echo   [1] Music
echo   [2] Videos
echo   [0] Back to main menu
echo.
choice /c 120 /n /m "Play: "
set "SEL=%errorlevel%"
if %SEL%==3 goto pl_exit
if %SEL%==2 set "PKIND=V" & set "PL1=Videos" & set "PEXTS=%VID_EXTS%" & goto pl2
set "PKIND=M"
set "PL1=Music"
set "PEXTS=%AUD_EXTS%"
goto pl2

rem ---------- Step 2: compressed or original files ----------
:pl2
cls
echo ============================================================
echo   PLAY  -  step 2: which files?
echo ============================================================
echo   Path: PLAY / %PL1%
echo.
echo   [1] Compressed files   - the output of this tool
echo   [2] Original files     - your source folder
echo   [0] Back
echo.
choice /c 120 /n /m "Files: "
set "SEL=%errorlevel%"
if %SEL%==3 goto pl1
if %SEL%==2 set "PL2=Originals" & set "PDIR=%SRC%" & goto pl3
set "PL2=Compressed"
set "PDIR=%OUT_MUSIC%"
if "%PKIND%"=="V" set "PDIR=%OUT_VIDEO%"
goto pl3

rem ---------- Step 3: play all or choose a file ----------
:pl3
call :BUILD_LIST
if %N%==0 goto pl3_empty
cls
echo ============================================================
echo   PLAY  -  step 3: how?
echo ============================================================
echo   Path   : PLAY / %PL1% / %PL2%
echo   Folder : %PDIR%
echo   Found  : %N% file(s)
echo.
echo   [1] Play all, one after another
echo   [2] Choose a file from a numbered list
echo   [0] Back
echo.
echo   Controls: q = stop current file, SPACE = pause,
echo   LEFT/RIGHT = seek 10 s, f = fullscreen (videos).
echo   To abort a whole playlist press Ctrl+C and then Y.
echo.
choice /c 120 /n /m "How: "
set "SEL=%errorlevel%"
if %SEL%==3 goto pl2
if %SEL%==2 goto pl_choose
echo.
for /f "usebackq delims=" %%L in ("%LIST%") do (
    set "CUR=%%~L"
    call :PLAY_ONE
)
echo.
echo Playlist finished.
pause
goto pl3

:pl3_empty
echo.
echo   No %PL1% files found in: %PDIR%
pause
goto pl2

rem ---------- Choose a single file ----------
:pl_choose
cls
echo ============================================================
echo   PLAY  -  choose a file
echo ============================================================
echo   Path: PLAY / %PL1% / %PL2%
echo.
if %N% GTR 25 goto pl_more
call :LIST_SHOW
goto pl_ask
:pl_more
call :LIST_SHOW | more

:pl_ask
echo.
set "PICK="
set /p "PICK=  Enter a file number (0 = back): "
if not defined PICK goto pl_ask
if "%PICK%"=="0" goto pl3
set "NONNUM="
for /f "delims=0123456789" %%X in ("%PICK%") do set "NONNUM=%%X"
if defined NONNUM goto pl_ask
if %PICK% LSS 1 goto pl_ask
if %PICK% GTR %N% goto pl_ask
set "IDX=0"
set "SELFILE="
for /f "usebackq delims=" %%L in ("%LIST%") do (
    set /a IDX+=1
    set "CUR=%%~L"
    call :PICK_CHECK
)
set "CUR=%SELFILE%"
call :PLAY_ONE
goto pl_ask

:pl_exit
if exist "%LIST%" del "%LIST%"
goto MAIN

rem ---------- Play helpers ----------

:BUILD_LIST
if exist "%LIST%" del "%LIST%"
set "N=0"
if not exist "%PDIR%\" goto :EOF
for %%E in (%PEXTS%) do (
    for %%F in ("%PDIR%\*.%%E") do (
        set /a N+=1
        >>"%LIST%" echo "%%~fF"
    )
)
goto :EOF

:LIST_SHOW
set "SHOWN=0"
for /f "usebackq delims=" %%L in ("%LIST%") do (
    set /a SHOWN+=1
    set "CUR=%%~L"
    call :SHOW_ITEM
)
goto :EOF

:SHOW_ITEM
for %%I in ("%CUR%") do echo   [%SHOWN%] %%~nxI
goto :EOF

:PICK_CHECK
if %IDX% EQU %PICK% set "SELFILE=%CUR%"
goto :EOF

:PLAY_ONE
for %%I in ("%CUR%") do echo [PLAY] %%~nxI
if not exist "%FFPLAY%" goto po_default
if "%PKIND%"=="M" goto po_audio
"%FFPLAY%" -hide_banner -loglevel error -autoexit "%CUR%"
goto :EOF
:po_audio
"%FFPLAY%" -hide_banner -nodisp -autoexit "%CUR%"
goto :EOF
:po_default
start "" /wait "%CUR%"
goto :EOF


rem ============================================================
rem  SHARED
rem ============================================================

:SUMMARY
echo.
echo   Compressed: %OK%    Skipped: %SKIP%    Failed: %FAIL%
set /a TOTAL=OK+SKIP+FAIL
if %TOTAL%==0 echo   No matching files found in the source folder.
goto :EOF
