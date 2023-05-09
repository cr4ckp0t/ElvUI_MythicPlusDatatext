# https://www.wowhead.com/affixes
$content = ((Invoke-WebRequest -Uri "https://www.wowhead.com/affixes").Content -split "\n")[183]
$affixes = @()
while ($content -match '"id"\:([0-9]{1,3}),"name"\:"([A-Za-z\s]+)",') {
    $affixes += [PSCustomObject]@{
        id   = $Matches[1];
        name = $Matches[2];
    }
    $content = $content -replace $Matches[0]
}
$affixes | Sort-Object -Property id | ForEach-Object {
    ('[{0}] = L["{1}"],' -f ($_.id, $_.name))
}