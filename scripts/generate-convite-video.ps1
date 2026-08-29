# Gera o vídeo único do slide de convite (MP4) a partir dos slides JPEG + logo + música.
# Requer ffmpeg no PATH ou em WinGet Packages.
#
# Música: apps/web/public/welcome/bg-music.mp3
# Logo:   apps/web/public/logo_ludmila_dyego.png

$ErrorActionPreference = "Stop"
$slidesDir = "c:\casamento\apps\web\public\welcome\slides"
$music = "c:\casamento\apps\web\public\welcome\bg-music.mp3"
$logo = "c:\casamento\apps\web\public\logo_ludmila_dyego.png"
$outWeb = "c:\casamento\apps\web\public\welcome\convite-slide.mp4"
$outMobile = "c:\casamento\apps\mobile\assets\welcome\convite-slide.mp4"
$outMusicMobile = "c:\casamento\apps\mobile\assets\welcome\bg-music.mp3"

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $ffmpeg) {
  $ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ffmpeg) { throw "ffmpeg nao encontrado" }
if (-not (Test-Path $music)) { throw "Musica nao encontrada: $music" }
if (-not (Test-Path $logo)) { throw "Logo nao encontrada: $logo" }

$slideSecs = 3.5
$nSlides = 8
$videoDur = $slideSecs * $nSlides
$fadeOutStart = [Math]::Max(0, $videoDur - 2.5)

$inputs = @()
for ($i = 1; $i -le $nSlides; $i++) {
  $n = "{0:D2}" -f $i
  $inputs += "-loop", "1", "-t", "$slideSecs", "-i", (Join-Path $slidesDir "$n-slide.jpg")
}
# Logo (imagem estática pelo tempo do vídeo)
$inputs += "-loop", "1", "-t", "$videoDur", "-i", $logo
$inputs += "-i", $music

$filters = @()
for ($i = 0; $i -lt $nSlides; $i++) {
  $filters += "[${i}:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p[v$i]"
}
$concatIn = (0..($nSlides - 1) | ForEach-Object { "[v$_]" }) -join ""
$logoIdx = $nSlides
$audioIdx = $nSlides + 1

# Concatena slides → logo no topo (centro), fundo branco removido + sombra suave
$fc = ($filters -join ";") +
  ";${concatIn}concat=n=${nSlides}:v=1:a=0[base]" +
  ";[${logoIdx}:v]scale=400:-1,colorkey=0xFFFFFF:0.38:0.1,format=rgba,fade=t=in:st=0:d=1.2:alpha=1,fade=t=out:st=${fadeOutStart}:d=2.5:alpha=1,split[lg0][lg1]" +
  ";[lg0]colorchannelmixer=aa=0.45,boxblur=10:2[shadow]" +
  ";[base][shadow]overlay=(W-w)/2:52[tmp]" +
  ";[tmp][lg1]overlay=(W-w)/2:48:format=auto[v]" +
  ";[${audioIdx}:a]atrim=0:${videoDur},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=1.5,afade=t=out:st=${fadeOutStart}:d=2.5,volume=0.55[a]"

& $ffmpeg @inputs -filter_complex $fc -map "[v]" -map "[a]" `
  -c:v libx264 -profile:v baseline -level 3.1 -pix_fmt yuv420p `
  -c:a aac -b:a 160k -ar 44100 -ac 2 `
  -movflags +faststart -shortest -y $outWeb

Copy-Item $outWeb $outMobile -Force
Copy-Item $music $outMusicMobile -Force
Get-Item $outWeb | Format-List FullName, Length
