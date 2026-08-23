Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("C:\Users\great\.gemini\antigravity\brain\d824c89a-8089-4255-a36f-5df55f81741e\lion_grabber_1787491857669.jpg")
$bmp = New-Object System.Drawing.Bitmap(64, 64)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($img, 0, 0, 64, 64)
$g.Dispose()
$bmp.Save("c:\My Data\Projects\AntiGravity\Godot Projects\ThroneBound Chess\assets\textures\ui\lion_grabber.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
$bmp.Dispose()
$img.Dispose()

Copy-Item "C:\Users\great\.gemini\antigravity\brain\d824c89a-8089-4255-a36f-5df55f81741e\switch_on_1787491869945.jpg" "c:\My Data\Projects\AntiGravity\Godot Projects\ThroneBound Chess\assets\textures\ui\switch_on.jpg"
Copy-Item "C:\Users\great\.gemini\antigravity\brain\d824c89a-8089-4255-a36f-5df55f81741e\switch_off_1787491881890.jpg" "c:\My Data\Projects\AntiGravity\Godot Projects\ThroneBound Chess\assets\textures\ui\switch_off.jpg"
Copy-Item "C:\Users\great\.gemini\antigravity\brain\d824c89a-8089-4255-a36f-5df55f81741e\brass_cartouche_1787491892594.jpg" "c:\My Data\Projects\AntiGravity\Godot Projects\ThroneBound Chess\assets\textures\ui\brass_cartouche.jpg"
