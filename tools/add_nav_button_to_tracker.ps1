[CmdletBinding()]
param(
    [switch]$Force,
    [string]$OutputPath,
    [string]$BaseTrackerPath
)

$ErrorActionPreference = 'Stop'
$workspace = Join-Path $PSScriptRoot '..'
$sourceTracker = if ($BaseTrackerPath) {
    [System.IO.Path]::GetFullPath($BaseTrackerPath)
} else {
    Join-Path $workspace 'mfHouse_SK_RK_Tracker_Filled.xlsx'
}
$sourceWorkbook = Join-Path $workspace 'mfHouse.xlsx'
$outputFile = if ($OutputPath) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    Join-Path $workspace 'mfHouse_SK_RK_Tracker_NAV.xlsm'
}
if ((Test-Path $outputFile) -and !$Force) {
    throw "Output already exists; use -Force to replace it: $outputFile"
}

$securityPath = 'HKCU:\Software\Microsoft\Office\16.0\Excel\Security'
$securityKeyExisted = Test-Path $securityPath
$accessVBOMExisted = $false
$accessVBOMOriginal = $null
if ($securityKeyExisted) {
    $securityValues = Get-ItemProperty $securityPath
    $accessVBOMExisted = $securityValues.PSObject.Properties.Name -contains 'AccessVBOM'
    if ($accessVBOMExisted) { $accessVBOMOriginal = $securityValues.AccessVBOM }
}

$excel = $null
$trackerBook = $null
$sourceBook = $null
try {
    if (!$securityKeyExisted) { New-Item -Path $securityPath -Force | Out-Null }
    Set-ItemProperty -Path $securityPath -Name AccessVBOM -Value 1 -Type DWord

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.AskToUpdateLinks = $false
    $excel.AutomationSecurity = 1
    $trackerBook = $excel.Workbooks.Open((Resolve-Path $sourceTracker).Path, 0, $false)
    $sourceBook = $excel.Workbooks.Open((Resolve-Path $sourceWorkbook).Path, 0, $true)
    $sourceSheet = $sourceBook.Worksheets.Item('Main')

    foreach ($owner in @('SK', 'RK')) {
        $ownerSheet = $trackerBook.Worksheets.Item($owner)
        $table = $ownerSheet.ListObjects.Item("${owner}_Valuations")
        $planColumn = $table.ListColumns.Add()
        $planColumn.Name = 'Plan/Option'
        $plans = [Array]::CreateInstance([object], [int[]]@($table.ListRows.Count, 1))
        for ($index = 1; $index -le $table.ListRows.Count; $index++) {
            $sourceRow = $table.DataBodyRange.Cells.Item($index, 11).Value2
            if ($sourceRow -is [double] -and $sourceRow -ge 2) {
                $plans.SetValue(([string]$sourceSheet.Cells.Item([int]$sourceRow, 7).Value2).Trim(), $index - 1, 0)
            }
        }
        $planColumn.DataBodyRange.Value2 = $plans
        $ownerSheet.Columns.Item(12).ColumnWidth = 20
    }

    $navSheet = $trackerBook.Worksheets.Add($trackerBook.Worksheets.Item('SK'))
    $navSheet.Name = 'NAV Lookup'
    $navSheet.Range('A1:H1').Merge()
    $navSheet.Range('A1').Value2 = 'Moneycontrol | Latest Mutual Fund NAV'
    $navSheet.Range('A2:H2').Merge()
    $navSheet.Range('A2').Value2 = 'Click Fetch Latest NAV to update every unique fund-house, scheme, and plan found in SK and RK. NAV As Of may differ from Current Date on weekends or holidays.'
    $navSheet.Range('A1:H1').Interior.Color = 3289650
    $navSheet.Range('A1:H1').Font.Color = 16777215
    $navSheet.Range('A1:H1').Font.Bold = $true
    $navSheet.Range('A1:H1').Font.Size = 16
    $navSheet.Range('A2:H2').WrapText = $true
    $navSheet.Range('A2:H2').Font.Italic = $true
    $navSheet.Rows.Item(2).RowHeight = 34
    $navSheet.Range('A3').Value2 = 'Last refresh: not fetched yet'
    $navHeaders = @('Current Date', 'Fund House', 'Scheme', 'Plan/Option', 'Latest NAV Price', 'NAV As Of', 'Status', 'Moneycontrol ISIN')
    $headerMatrix = [Array]::CreateInstance([object], [int[]]@(1, $navHeaders.Count))
    for ($column = 0; $column -lt $navHeaders.Count; $column++) {
        $headerMatrix.SetValue($navHeaders[$column], 0, $column)
    }
    $navSheet.Range('A5:H5').Value2 = $headerMatrix
    $navSheet.Range('A5:H5').Interior.Color = 5663715
    $navSheet.Range('A5:H5').Font.Color = 16777215
    $navSheet.Range('A5:H5').Font.Bold = $true
    $navSheet.Columns.Item(1).ColumnWidth = 16
    $navSheet.Columns.Item(2).ColumnWidth = 24
    $navSheet.Columns.Item(3).ColumnWidth = 56
    $navSheet.Columns.Item(4).ColumnWidth = 20
    $navSheet.Columns.Item(5).ColumnWidth = 20
    $navSheet.Columns.Item(6).ColumnWidth = 16
    $navSheet.Columns.Item(7).ColumnWidth = 38
    $navSheet.Columns.Item(8).Hidden = $true
    $navSheet.Columns.Item(1).NumberFormat = 'dd-mmm-yyyy'
    $navSheet.Columns.Item(5).NumberFormat = '0.0000'
    $navSheet.Columns.Item(6).NumberFormat = 'dd-mmm-yyyy'

    $button = $navSheet.Buttons().Add(720, 20, 250, 36)
    $button.Caption = 'Fetch Latest NAV from Moneycontrol'
    $button.OnAction = 'RefreshLatestNAV'

    $module = $trackerBook.VBProject.VBComponents.Add(1)
    $module.Name = 'MoneycontrolNAV'
    $module.CodeModule.AddFromString((Get-Content (Join-Path $PSScriptRoot 'RefreshMoneycontrolNAV.bas') -Raw))

    $trackerBook.SaveAs($outputFile, 52)
    $trackerBook.Save()
    Write-Output "CREATED: $outputFile"
    Write-Output "NAV sheet added with refresh button; SK and RK tables now include Plan/Option."
    Write-Output 'Click Fetch Latest NAV from Moneycontrol to populate current date, latest NAV, NAV date, and status.'
}
finally {
    if ($sourceBook) { $sourceBook.Close($false) }
    if ($trackerBook) { $trackerBook.Close($false) }
    if ($excel) {
        $excel.Quit()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
    }
    if ($accessVBOMExisted) {
        Set-ItemProperty -Path $securityPath -Name AccessVBOM -Value $accessVBOMOriginal -Type DWord
    } else {
        Remove-ItemProperty -Path $securityPath -Name AccessVBOM -ErrorAction SilentlyContinue
        if (!$securityKeyExisted -and !(Get-ItemProperty $securityPath -ErrorAction SilentlyContinue)) {
            Remove-Item $securityPath -ErrorAction SilentlyContinue
        }
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
