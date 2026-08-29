$srcDir = "c:\casamento\apps\web\public\welcome"
$outWeb = "c:\casamento\apps\web\public\welcome\slides"
$outMobile = "c:\casamento\apps\mobile\assets\welcome\slides"
New-Item -ItemType Directory -Force -Path $outWeb, $outMobile | Out-Null

Add-Type -AssemblyName System.Drawing

$dateLabel = '17 de outubro de 2026'

$slides = @(
  @{ file = '01.jpg'; phrase = 'Bem-vindos ao nosso casamento'; eyebrow = 'Ludmila & Dyego' },
  @{ file = '02.jpg'; phrase = 'Ludmila & Dyego'; eyebrow = $null },
  @{ file = '03.jpg'; phrase = 'Com alegria, convidamos voces a celebrar conosco'; eyebrow = $null },
  @{ file = '04.jpg'; phrase = 'Um dia para lembrar e compartilhar o amor'; eyebrow = $null },
  @{ file = '05.jpg'; phrase = 'Sua presenca e o nosso maior presente'; eyebrow = $null },
  @{ file = '06.jpg'; phrase = 'Que este momento fique no coracao de todos'; eyebrow = $null },
  @{ file = '07.jpg'; phrase = 'Celebremos juntos o inicio da nossa historia'; eyebrow = $null },
  @{ file = '08.jpg'; phrase = 'Obrigado por fazer parte deste sonho'; eyebrow = $null }
)

$utf = New-Object System.Text.UTF8Encoding $false
$slides[2].phrase = $utf.GetString([byte[]](0x43,0x6F,0x6D,0x20,0x61,0x6C,0x65,0x67,0x72,0x69,0x61,0x2C,0x20,0x63,0x6F,0x6E,0x76,0x69,0x64,0x61,0x6D,0x6F,0x73,0x20,0x76,0x6F,0x63,0xC3,0xAA,0x73,0x20,0x61,0x20,0x63,0x65,0x6C,0x65,0x62,0x72,0x61,0x72,0x20,0x63,0x6F,0x6E,0x6F,0x73,0x63,0x6F))
$slides[3].phrase = $utf.GetString([byte[]](0x55,0x6D,0x20,0x64,0x69,0x61,0x20,0x70,0x61,0x72,0x61,0x20,0x6C,0x65,0x6D,0x62,0x72,0x61,0x72,0x20,0xE2,0x80,0x94,0x20,0x65,0x20,0x63,0x6F,0x6D,0x70,0x61,0x72,0x74,0x69,0x6C,0x68,0x61,0x72,0x20,0x6F,0x20,0x61,0x6D,0x6F,0x72))
$slides[4].phrase = $utf.GetString([byte[]](0x53,0x75,0x61,0x20,0x70,0x72,0x65,0x73,0x65,0x6E,0xC3,0xA7,0x61,0x20,0xC3,0xA9,0x20,0x6F,0x20,0x6E,0x6F,0x73,0x73,0x6F,0x20,0x6D,0x61,0x69,0x6F,0x72,0x20,0x70,0x72,0x65,0x73,0x65,0x6E,0x74,0x65))
$slides[5].phrase = $utf.GetString([byte[]](0x51,0x75,0x65,0x20,0x65,0x73,0x74,0x65,0x20,0x6D,0x6F,0x6D,0x65,0x6E,0x74,0x6F,0x20,0x66,0x69,0x71,0x75,0x65,0x20,0x6E,0x6F,0x20,0x63,0x6F,0x72,0x61,0xC3,0xA7,0xC3,0xA3,0x6F,0x20,0x64,0x65,0x20,0x74,0x6F,0x64,0x6F,0x73))
$slides[6].phrase = $utf.GetString([byte[]](0x43,0x65,0x6C,0x65,0x62,0x72,0x65,0x6D,0x6F,0x73,0x20,0x6A,0x75,0x6E,0x74,0x6F,0x73,0x20,0x6F,0x20,0x69,0x6E,0xC3,0xAD,0x63,0x69,0x6F,0x20,0x64,0x61,0x20,0x6E,0x6F,0x73,0x73,0x61,0x20,0x68,0x69,0x73,0x74,0xC3,0xB3,0x72,0x69,0x61))
$dateLabel = $utf.GetString([byte[]](0x31,0x37,0x20,0x64,0x65,0x20,0x6F,0x75,0x74,0x75,0x62,0x72,0x6F,0x20,0x64,0x65,0x20,0x32,0x30,0x32,0x36))

$canvasW = 1080
$canvasH = 1920
$gold = [System.Drawing.Color]::FromArgb(255, 183, 151, 94)
$white = [System.Drawing.Color]::White

$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 88L)

function Get-WrappedLines {
  param($g, [string]$text, $font, [float]$maxWidth)
  $words = $text -split '\s+'
  $lines = New-Object System.Collections.Generic.List[string]
  $cur = ''
  foreach ($w in $words) {
    $test = if ($cur) { "$cur $w" } else { $w }
    $sz = $g.MeasureString($test, $font)
    if ($sz.Width -le $maxWidth) {
      $cur = $test
    } else {
      if ($cur) { [void]$lines.Add($cur) }
      $cur = $w
    }
  }
  if ($cur) { [void]$lines.Add($cur) }
  return ,$lines.ToArray()
}

$idx = 0
foreach ($s in $slides) {
  $idx++
  $imgPath = Join-Path $srcDir $s.file
  $img = [System.Drawing.Image]::FromFile($imgPath)
  $canvas = New-Object System.Drawing.Bitmap $canvasW, $canvasH
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear([System.Drawing.Color]::Black)

  $scale = [Math]::Min(($canvasW / [double]$img.Width), ($canvasH / [double]$img.Height))
  $dw = [int]($img.Width * $scale)
  $dh = [int]($img.Height * $scale)
  $dx = [int](($canvasW - $dw) / 2)
  $dy = [int](($canvasH - $dh) / 2)
  $g.DrawImage($img, $dx, $dy, $dw, $dh)

  $gradTop = [int]($canvasH * 0.48)
  $gradH = $canvasH - $gradTop
  $rect = New-Object System.Drawing.Rectangle 0, $gradTop, $canvasW, $gradH
  $c0 = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
  $c1 = [System.Drawing.Color]::FromArgb(220, 0, 0, 0)
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c0, $c1, ([System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
  $g.FillRectangle($brush, $rect)
  $brush.Dispose()

  $maxTextW = $canvasW - 120
  $isNames = ($s.phrase -eq 'Ludmila & Dyego')
  $phraseFontSize = if ($isNames) { 64 } else { 46 }
  $phraseFont = New-Object System.Drawing.Font 'Georgia', $phraseFontSize, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $lines = Get-WrappedLines $g ([string]$s.phrase) $phraseFont $maxTextW
  $lineH = $g.MeasureString('Ay', $phraseFont).Height
  $blockH = $lines.Count * $lineH
  $y = $canvasH - 340 - $blockH

  if ($s.eyebrow) {
    $eyeFont = New-Object System.Drawing.Font 'Georgia', 28, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
    $eyeSz = $g.MeasureString([string]$s.eyebrow, $eyeFont)
    $eyeBrush = New-Object System.Drawing.SolidBrush $gold
    $g.DrawString([string]$s.eyebrow, $eyeFont, $eyeBrush, (($canvasW - $eyeSz.Width) / 2), ($y - 52))
    $eyeBrush.Dispose()
    $eyeFont.Dispose()
  }

  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = [System.Drawing.StringAlignment]::Center
  $textBrush = New-Object System.Drawing.SolidBrush $white
  $yy = $y
  foreach ($line in $lines) {
    $r = New-Object System.Drawing.RectangleF 60, $yy, ($canvasW - 120), ($lineH + 10)
    $g.DrawString([string]$line, $phraseFont, $textBrush, $r, $sf)
    $yy += $lineH
  }
  $textBrush.Dispose()
  $phraseFont.Dispose()

  $pen = New-Object System.Drawing.Pen $gold, 2.5
  $ruleY = $yy + 20
  $g.DrawLine($pen, (($canvasW / 2) - 40), $ruleY, (($canvasW / 2) + 40), $ruleY)
  $pen.Dispose()

  $dateFont = New-Object System.Drawing.Font 'Georgia', 30, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $dateBrush = New-Object System.Drawing.SolidBrush $gold
  $dateSz = $g.MeasureString($dateLabel, $dateFont)
  $g.DrawString($dateLabel, $dateFont, $dateBrush, (($canvasW - $dateSz.Width) / 2), ($ruleY + 22))
  $dateBrush.Dispose()
  $dateFont.Dispose()

  $dotY = $canvasH - 100
  $total = $slides.Count
  $gap = 16
  $startX = ($canvasW / 2) - (($total * $gap) / 2)
  for ($d = 0; $d -lt $total; $d++) {
    $active = ($d -eq ($idx - 1))
    $dotW = if ($active) { 20 } else { 8 }
    $dotH = 8
    $bx = $startX + ($d * $gap)
    if ($active) { $bx = $bx - 6 }
    $col = if ($active) { $gold } else { [System.Drawing.Color]::FromArgb(130, 255, 255, 255) }
    $dotBrush = New-Object System.Drawing.SolidBrush $col
    $g.FillEllipse($dotBrush, $bx, $dotY, $dotW, $dotH)
    $dotBrush.Dispose()
  }

  $outName = ('{0:D2}-slide.jpg' -f $idx)
  $pathWeb = Join-Path $outWeb $outName
  $canvas.Save($pathWeb, $encoder, $ep)
  Copy-Item $pathWeb (Join-Path $outMobile $outName) -Force
  $g.Dispose()
  $canvas.Dispose()
  $img.Dispose()
  Write-Host "$outName ok"
}

Write-Host 'SLIDES DONE'
