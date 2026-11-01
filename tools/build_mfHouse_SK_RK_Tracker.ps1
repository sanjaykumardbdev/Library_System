[CmdletBinding()]
param(
    [switch]$Force,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$sourcePath = Join-Path $PSScriptRoot '..\mfHouse.xlsx' | Resolve-Path
$outputPath = if ($OutputPath) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    Join-Path $PSScriptRoot '..\mfHouse_SK_RK_Tracker_NAV.xlsm'
}
if ((Test-Path $outputPath) -and !$Force) {
    throw "Output already exists; refusing to overwrite: $outputPath"
}

function Get-FundHouse([string]$scheme) {
    switch -Regex ($scheme.Trim()) {
        '^Axis\b' { return 'Axis' }
        '^Kotak\b' { return 'Kotak' }
        '^(Technology Fund|Banking and Financial Services Fund|Flexicap Fund|Liquid Fund)\b' { return 'ICICI Prudential' }
        '^ICICI Prudential\b' { return 'ICICI Prudential' }
        '^(NIPPON|Nippon India)\b' { return 'Nippon' }
        '^Quant\b' { return 'Quant' }
        '^Bandhan\b' { return 'Bandhan' }
        '^Parag Parikh\b' { return 'Parag Parikh' }
        '^Motilal Oswal\b' { return 'Motilal Oswal' }
        '^HDFC\b' { return 'HDFC' }
        default { return 'Unclassified - verify' }
    }
}

function Set-RowValues($range, [object[]]$values) {
    $matrix = [Array]::CreateInstance([object], [int[]]@(1, $values.Count))
    for ($column = 0; $column -lt $values.Count; $column++) {
        $matrix.SetValue($values[$column], 0, $column)
    }
    $range.Value2 = $matrix
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
$ownerTableCapacity = 2000
$sourceBook = $null
$book = $null

try {
    if (!$securityKeyExisted) { New-Item -Path $securityPath -Force | Out-Null }
    Set-ItemProperty -Path $securityPath -Name AccessVBOM -Value 1 -Type DWord
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.AskToUpdateLinks = $false
    $excel.AutoCorrect.AutoFillFormulasInLists = $true
    $excel.AutomationSecurity = 1
    $sourceBook = $excel.Workbooks.Open($sourcePath.Path, 0, $true)
    $sourceSheet = $sourceBook.Worksheets.Item('Main')
    $valuationDate = [double]$sourceSheet.Range('N1').Value2
    $records = [System.Collections.Generic.List[object]]::new()

    for ($row = 2; $row -le $sourceSheet.UsedRange.Rows.Count; $row++) {
        $owner = ([string]$sourceSheet.Cells.Item($row, 2).Value2).Trim().ToUpperInvariant()
        $investmentDate = $sourceSheet.Cells.Item($row, 3).Value2
        $scheme = ([string]$sourceSheet.Cells.Item($row, 4).Value2).Trim()
        if ($owner -notin @('SK', 'RK') -or $investmentDate -isnot [double] -or !$scheme -or $scheme -eq 'Scheme') {
            continue
        }

        $invested = $sourceSheet.Cells.Item($row, 8).Value2
        $currentValue = $sourceSheet.Cells.Item($row, 17).Value2
        $units = $sourceSheet.Cells.Item($row, 11).Value2
        $nav = $sourceSheet.Cells.Item($row, 14).Value2
        $planOption = ([string]$sourceSheet.Cells.Item($row, 7).Value2).Trim()
        $records.Add([pscustomobject]@{
            Owner = $owner
            House = Get-FundHouse $scheme
            Scheme = $scheme
            InvestmentDate = [double]$investmentDate
            ValuationDate = $valuationDate
            Invested = if ($invested -is [double] -or $invested -is [int]) { [double]$invested } else { $null }
            CurrentValue = if ($currentValue -is [double] -or $currentValue -is [int]) { [double]$currentValue } else { $null }
            Units = if ($units -is [double] -or $units -is [int]) { [double]$units } else { $null }
            NAV = if ($nav -is [double] -or $nav -is [int]) { [double]$nav } else { $null }
            PlanOption = $planOption
            SourceRow = $row
        })
    }

    $sourceBook.Close($false)
    $sourceBook = $null

    $book = $excel.Workbooks.Add()
    while ($book.Worksheets.Count -lt 3) {
        $null = $book.Worksheets.Add()
    }
    while ($book.Worksheets.Count -gt 3) {
        $book.Worksheets.Item($book.Worksheets.Count).Delete()
    }
    $summary = $book.Worksheets.Item(1)
    $summary.Name = 'Summary'
    $skSheet = $book.Worksheets.Item(2)
    $skSheet.Name = 'SK'
    $rkSheet = $book.Worksheets.Item(3)
    $rkSheet.Name = 'RK'
    $navSheet = $book.Worksheets.Add($skSheet)
    $navSheet.Name = 'NAV Lookup'
    $charts = $book.Worksheets.Add()
    $charts.Name = 'Charts'
    $chartData = $book.Worksheets.Add()
    $chartData.Name = 'Chart Data'

    $headers = @('Valuation Date', 'Fund House', 'Scheme', 'Investment Date', 'Invested Amount', 'Current Value', 'Gain/Loss', 'P&L %', 'Units', 'Current NAV', 'Source Row', 'Plan/Option')
    $tables = @{}
    foreach ($owner in @('SK', 'RK')) {
        $sheet = if ($owner -eq 'SK') { $skSheet } else { $rkSheet }
        $sheet.Range('A1:L1').Merge()
        $sheet.Range('A1').Value2 = "$owner Mutual Fund Valuation History"
        $sheet.Range('A2:L2').Merge()
        $sheet.Range('A2').Value2 = 'Append one row per fund holding per valuation date. Enter date, fund house, scheme, invested amount, and current value; gain/loss and P&L % calculate automatically.'
        $sheet.Range('A1:L1').Interior.Color = 3289650
        $sheet.Range('A1:L1').Font.Color = 16777215
        $sheet.Range('A1:L1').Font.Bold = $true
        $sheet.Range('A1:L1').Font.Size = 16
        $sheet.Range('A2:L2').WrapText = $true
        $sheet.Range('A2:L2').Font.Italic = $true
        $sheet.Rows.Item(2).RowHeight = 32
        Set-RowValues $sheet.Range('A4:L4') $headers

        $ownerRows = @($records | Where-Object Owner -eq $owner)
        $tableRows = $ownerTableCapacity
        $matrix = [Array]::CreateInstance([object], [int[]]@($tableRows, $headers.Count))
        for ($index = 0; $index -lt $ownerRows.Count; $index++) {
            $item = $ownerRows[$index]
            $values = @($item.ValuationDate, $item.House, $item.Scheme, $item.InvestmentDate, $item.Invested, $item.CurrentValue, $null, $null, $item.Units, $item.NAV, $item.SourceRow, $item.PlanOption)
            for ($column = 0; $column -lt $values.Count; $column++) {
                $matrix.SetValue($values[$column], $index, $column)
            }
        }
        $lastRow = 4 + $tableRows
        $sheet.Range("A5:L$lastRow").Value2 = $matrix
        $table = $sheet.ListObjects.Add(1, $sheet.Range("A4:L$lastRow"), $null, 1)
        $table.Name = "${owner}_Valuations"
        $table.TableStyle = 'TableStyleMedium2'
        $table.ListColumns.Item(7).DataBodyRange.FormulaR1C1 = '=IF(OR(RC[-2]="",RC[-1]=""),"",RC[-1]-RC[-2])'
        $table.ListColumns.Item(8).DataBodyRange.FormulaR1C1 = '=IFERROR(RC[-1]/RC[-3],"")'

        $widths = @(16, 23, 58, 16, 20, 20, 20, 14, 14, 14, 12, 20)
        for ($column = 1; $column -le $widths.Count; $column++) {
            $sheet.Columns.Item($column).ColumnWidth = $widths[$column - 1]
        }
        $sheet.Columns.Item(1).NumberFormat = 'dd-mmm-yyyy'
        $sheet.Columns.Item(4).NumberFormat = 'dd-mmm-yyyy'
        foreach ($column in 5..7) {
            $sheet.Columns.Item($column).NumberFormat = '"INR "#,##0.00;[Red]-"INR "#,##0.00'
        }
        $sheet.Columns.Item(8).NumberFormat = '0.00%;[Red]-0.00%'
        $sheet.Columns.Item(9).NumberFormat = '#,##0.000'
        $sheet.Columns.Item(10).NumberFormat = '0.0000'
        $sheet.Activate()
        $sheet.Range('A5').Select() | Out-Null
        $excel.ActiveWindow.FreezePanes = $true
        $tables[$owner] = $table
    }

    $summary.Range('A1:G1').Merge()
    $summary.Range('A1').Value2 = 'MF House | SK + RK Performance'
    $summary.Range('A2:G2').Merge()
    $summary.Range('A2').Value2 = "Starting snapshot: $([DateTime]::FromOADate($valuationDate).ToString('dd-MMM-yyyy')) from source current values. New rows are dated valuation snapshots; P&L uses invested amount including stamp duty."
    $summary.Range('A1:G1').Interior.Color = 3289650
    $summary.Range('A1:G1').Font.Color = 16777215
    $summary.Range('A1:G1').Font.Bold = $true
    $summary.Range('A1:G1').Font.Size = 18
    $summary.Range('A2:G2').WrapText = $true
    $summary.Range('A2:G2').Font.Italic = $true
    $summary.Rows.Item(2).RowHeight = 32
    Set-RowValues $summary.Range('A4:G4') @('Owner', 'Fund House', 'Invested Amount', 'Current Value', 'Gain/Loss', 'P&L %', 'Records')

    $combinations = @()
    foreach ($owner in @('SK', 'RK')) {
        foreach ($house in @($records | Where-Object Owner -eq $owner | Select-Object -ExpandProperty House -Unique | Sort-Object)) {
            $combinations += ,([pscustomobject]@{ Owner = $owner; House = $house })
        }
    }

    $summaryRow = 5
    foreach ($combination in $combinations) {
        $owner = $combination.Owner
        $tableName = "${owner}_Valuations"
        $summary.Cells.Item($summaryRow, 1).Value2 = $owner
        $summary.Cells.Item($summaryRow, 2).Value2 = $combination.House
        $summary.Cells.Item($summaryRow, 3).Formula = "=SUMIFS(${tableName}[Invested Amount],${tableName}[Fund House],B$summaryRow)"
        $summary.Cells.Item($summaryRow, 4).Formula = "=SUMIFS(${tableName}[Current Value],${tableName}[Fund House],B$summaryRow)"
        $summary.Cells.Item($summaryRow, 5).Formula = "=D$summaryRow-C$summaryRow"
        $summary.Cells.Item($summaryRow, 6).Formula = "=IFERROR(E$summaryRow/C$summaryRow,0)"
        $summary.Cells.Item($summaryRow, 7).Formula = '=COUNTIFS(' + $tableName + '[Fund House],B' + $summaryRow + ',' + $tableName + '[Scheme],"<>")'
        $summaryRow++
    }
    $combinationEnd = $summaryRow - 1
    $skTotalRow = $summaryRow + 1
    $rkTotalRow = $skTotalRow + 1
    $combinedRow = $rkTotalRow + 1

    $summary.Cells.Item($skTotalRow, 1).Value2 = 'SK TOTAL'
    $summary.Cells.Item($rkTotalRow, 1).Value2 = 'RK TOTAL'
    $summary.Cells.Item($combinedRow, 1).Value2 = 'COMBINED TOTAL'
    foreach ($row in @(@{ Number = $skTotalRow; Owner = 'SK' }, @{ Number = $rkTotalRow; Owner = 'RK' })) {
        $owner = $row.Owner
        $tableName = "${owner}_Valuations"
        $summary.Cells.Item($row.Number, 3).Formula = '=SUM(' + $tableName + '[Invested Amount])'
        $summary.Cells.Item($row.Number, 4).Formula = '=SUM(' + $tableName + '[Current Value])'
        $summary.Cells.Item($row.Number, 5).Formula = "=D$($row.Number)-C$($row.Number)"
        $summary.Cells.Item($row.Number, 6).Formula = "=IFERROR(E$($row.Number)/C$($row.Number),0)"
        $summary.Cells.Item($row.Number, 7).Formula = '=COUNTA(' + $tableName + '[Scheme])'
    }
    $summary.Cells.Item($combinedRow, 3).Formula = "=C$skTotalRow+C$rkTotalRow"
    $summary.Cells.Item($combinedRow, 4).Formula = "=D$skTotalRow+D$rkTotalRow"
    $summary.Cells.Item($combinedRow, 5).Formula = "=D$combinedRow-C$combinedRow"
    $summary.Cells.Item($combinedRow, 6).Formula = "=IFERROR(E$combinedRow/C$combinedRow,0)"
    $summary.Cells.Item($combinedRow, 7).Formula = "=G$skTotalRow+G$rkTotalRow"
    $summary.Range("A4:G$combinationEnd").Borders.LineStyle = 1
    $summary.Range("A$skTotalRow:G$combinedRow").Font.Bold = $true
    $summary.Range("A$skTotalRow:G$combinedRow").Interior.Color = 15132390
    $summary.Range('A4:G4').Interior.Color = 5663715
    $summary.Range('A4:G4').Font.Color = 16777215
    $summary.Range('A4:G4').Font.Bold = $true
    $summary.Columns.Item(1).ColumnWidth = 17
    $summary.Columns.Item(2).ColumnWidth = 24
    foreach ($column in 3..5) { $summary.Columns.Item($column).ColumnWidth = 19 }
    $summary.Columns.Item(6).ColumnWidth = 14
    $summary.Columns.Item(7).ColumnWidth = 12
    foreach ($column in 3..5) { $summary.Columns.Item($column).NumberFormat = '"INR "#,##0.00;[Red]-"INR "#,##0.00' }
    $summary.Columns.Item(6).NumberFormat = '0.00%;[Red]-0.00%'
    if ($combinationEnd -ge 5) {
        $summary.ListObjects.Add(1, $summary.Range("A4:G$combinationEnd"), $null, 1).Name = 'HouseSummary'
        $summary.ListObjects.Item('HouseSummary').TableStyle = 'TableStyleMedium4'
    }
    $summary.Activate()
    $summary.Range('A4').Select() | Out-Null
    $excel.ActiveWindow.FreezePanes = $true

    $navSheet.Range('A1:H1').Merge()
    $navSheet.Range('A1').Value2 = 'Moneycontrol | Latest Mutual Fund NAV'
    $navSheet.Range('A2:H2').Merge()
    $navSheet.Range('A2').Value2 = 'Refresh fetches the latest published NAV for each fund-house, scheme, and plan found in SK and RK. NAV As Of may differ from Current Date on weekends or holidays.'
    $navSheet.Range('A1:H1').Interior.Color = 3289650
    $navSheet.Range('A1:H1').Font.Color = 16777215
    $navSheet.Range('A1:H1').Font.Bold = $true
    $navSheet.Range('A1:H1').Font.Size = 16
    $navSheet.Range('A2:H2').WrapText = $true
    $navSheet.Range('A2:H2').Font.Italic = $true
    $navSheet.Rows.Item(2).RowHeight = 32
    Set-RowValues $navSheet.Range('A5:H5') @('Current Date', 'Fund House', 'Scheme', 'Plan/Option', 'Latest NAV Price', 'NAV As Of', 'Status', 'Moneycontrol ISIN')
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
    $navSheet.Range('A3').Value2 = 'Last refresh: not fetched yet'
    $navButton = $navSheet.Buttons().Add(720, 20, 245, 34)
    $navButton.Caption = 'Fetch Latest NAV from Moneycontrol'
    $navButton.OnAction = 'RefreshLatestNAV'

    $houseHeaders = @('Owner', 'Valuation Date', 'Investment Date', 'Fund House', 'Scheme', 'Invested Amount', 'Current Value', 'Gain/Loss', 'P&L %', 'Units', 'Current NAV', 'Source Index')
    $houses = @($records | Select-Object -ExpandProperty House -Unique | Sort-Object)
    foreach ($house in $houses) {
        $houseSheet = $book.Worksheets.Add()
        $houseSheet.Name = $house
        $lastHouseRow = 4 + (2 * $ownerTableCapacity)
        $houseSheet.Range('A1:L1').Merge()
        $houseSheet.Range('A1').Value2 = "$house | SK + RK Holdings"
        $houseSheet.Range('A2:L2').Merge()
        $houseSheet.Range('A2').Value2 = 'Linked view of the SK and RK entry tables. Add or update records only on SK or RK. The chart plots each investment date against gain/loss at the latest valuation snapshot.'
        $houseSheet.Range('A1:K1').Interior.Color = 3289650
        $houseSheet.Range('A1:K1').Font.Color = 16777215
        $houseSheet.Range('A1:K1').Font.Bold = $true
        $houseSheet.Range('A1:K1').Font.Size = 16
        $houseSheet.Range('A2:K2').WrapText = $true
        $houseSheet.Range('A2:K2').Font.Italic = $true
        $houseSheet.Rows.Item(2).RowHeight = 32
        Set-RowValues $houseSheet.Range('A4:L4') $houseHeaders
        $houseSheet.Range('A4:L4').Interior.Color = 5663715
        $houseSheet.Range('A4:L4').Font.Color = 16777215
        $houseSheet.Range('A4:L4').Font.Bold = $true

        $blockStart = 5
        $blockEnd = 4 + (2 * $ownerTableCapacity)
        $skHouseRange = 'SK!R5C2:R' + (4 + $ownerTableCapacity) + 'C2'
        $rkHouseRange = 'RK!R5C2:R' + (4 + $ownerTableCapacity) + 'C2'
        $ordinal = 'ROWS(R5C12:RC12)'
        $skCount = 'COUNTIF(' + $skHouseRange + ',"' + $house + '")'
        $skIndex = 'AGGREGATE(15,6,(ROW(' + $skHouseRange + ')-ROW(SK!R5C2)+1)/(' + $skHouseRange + '="' + $house + '"),' + $ordinal + ')'
        $rkOrdinal = '(' + $ordinal + '-' + $skCount + ')'
        $rkIndex = 'AGGREGATE(15,6,(ROW(' + $rkHouseRange + ')-ROW(RK!R5C2)+1)/(' + $rkHouseRange + '="' + $house + '"),' + $rkOrdinal + ')'
        $houseSheet.Range("L${blockStart}:L${blockEnd}").FormulaR1C1 = '=IFERROR(IF(' + $ordinal + '<=' + $skCount + ',' + $skIndex + ',-' + $rkIndex + '),"")'
        $houseSheet.Range("A${blockStart}:A${blockEnd}").FormulaR1C1 = '=IF(RC[11]="","",IF(RC[11]>0,"SK","RK"))'
        $sourceColumns = @('Valuation Date', 'Investment Date', 'Fund House', 'Scheme', 'Invested Amount', 'Current Value', 'Gain/Loss', 'P&L %', 'Units', 'Current NAV')
        for ($index = 0; $index -lt $sourceColumns.Count; $index++) {
            $column = $index + 2
            $sourceColumn = $sourceColumns[$index]
            $relativeOwner = 'RC[-' + ($column - 1) + ']'
            $relativeIndex = 'ABS(RC[' + (12 - $column) + '])'
            $formula = '=IF(' + $relativeOwner + '="","",IFERROR(IF(' + $relativeOwner + '="SK",INDEX(SK_Valuations[' + $sourceColumn + '],' + $relativeIndex + '),INDEX(RK_Valuations[' + $sourceColumn + '],' + $relativeIndex + ')),""))'
            $columnName = [string][char](64 + $column)
            $houseSheet.Range("${columnName}${blockStart}:${columnName}${blockEnd}").FormulaR1C1 = $formula
        }

        $houseSheet.Columns.Item(1).ColumnWidth = 12
        $houseSheet.Columns.Item(2).ColumnWidth = 16
        $houseSheet.Columns.Item(3).ColumnWidth = 16
        $houseSheet.Columns.Item(4).ColumnWidth = 24
        $houseSheet.Columns.Item(5).ColumnWidth = 58
        foreach ($column in 6..8) { $houseSheet.Columns.Item($column).ColumnWidth = 20 }
        $houseSheet.Columns.Item(9).ColumnWidth = 14
        $houseSheet.Columns.Item(10).ColumnWidth = 14
        $houseSheet.Columns.Item(11).ColumnWidth = 14
        $houseSheet.Columns.Item(12).Hidden = $true
        $houseSheet.Range('N4:Q4').Value2 = @(@('SK Investment Date', 'SK Gain/Loss', 'RK Investment Date', 'RK Gain/Loss'))
        $houseSheet.Range("N5:N$blockEnd").FormulaR1C1 = '=IF(RC[-13]="SK",RC[-11],NA())'
        $houseSheet.Range("O5:O$blockEnd").FormulaR1C1 = '=IF(RC[-14]="SK",RC[-7],NA())'
        $houseSheet.Range("P5:P$blockEnd").FormulaR1C1 = '=IF(RC[-15]="RK",RC[-13],NA())'
        $houseSheet.Range("Q5:Q$blockEnd").FormulaR1C1 = '=IF(RC[-16]="RK",RC[-9],NA())'
        $houseSheet.Columns('N:Q').Hidden = $true
        $houseSheet.Columns.Item(2).NumberFormat = 'dd-mmm-yyyy'
        $houseSheet.Columns.Item(3).NumberFormat = 'dd-mmm-yyyy'
        foreach ($column in 6..8) { $houseSheet.Columns.Item($column).NumberFormat = '"INR "#,##0.00;[Red]-"INR "#,##0.00' }
        $houseSheet.Columns.Item(9).NumberFormat = '0.00%;[Red]-0.00%'
        $houseSheet.Columns.Item(10).NumberFormat = '#,##0.000'
        $houseSheet.Columns.Item(11).NumberFormat = '0.0000'
        $houseSheet.Activate()
        $houseSheet.Range('A5').Select() | Out-Null
        $excel.ActiveWindow.FreezePanes = $true

        $houseChartObject = $houseSheet.ChartObjects().Add(1740, 70, 650, 380)
        $houseChart = $houseChartObject.Chart
        $houseChart.ChartType = -4169
        $houseChart.HasTitle = $true
        $houseChart.ChartTitle.Text = "$house | Investment Date vs Gain/Loss"
        $houseChart.HasLegend = $true
        $houseChart.PlotVisibleOnly = $false
        while ($houseChart.SeriesCollection().Count -gt 0) {
            $houseChart.SeriesCollection().Item(1).Delete()
        }
        foreach ($owner in @('SK', 'RK')) {
            $series = $houseChart.SeriesCollection().NewSeries()
            $series.Name = $owner
            $dateColumn = if ($owner -eq 'SK') { 'N' } else { 'P' }
            $gainColumn = if ($owner -eq 'SK') { 'O' } else { 'Q' }
            $series.XValues = $houseSheet.Range("${dateColumn}5:${dateColumn}${blockEnd}")
            $series.Values = $houseSheet.Range("${gainColumn}5:${gainColumn}${blockEnd}")
            $series.MarkerStyle = 8
            $series.Format.Line.Visible = $false
        }
        $houseChart.Axes(1).HasTitle = $true
        $houseChart.Axes(1).AxisTitle.Text = 'Investment Date'
        $houseChart.Axes(1).TickLabels.NumberFormat = 'dd-mmm-yy'
        $houseChart.Axes(2).HasTitle = $true
        $houseChart.Axes(2).AxisTitle.Text = 'Gain / Loss (INR)'
        $houseChart.Axes(2).TickLabels.NumberFormat = '"INR "#,##0;[Red]-"INR "#,##0'
    }

    $charts.Range('A1:N1').Merge()
    $charts.Range('A1').Value2 = 'Dated P&L % Trends by Owner and Fund House'
    $charts.Range('A1:N1').Interior.Color = 3289650
    $charts.Range('A1:N1').Font.Color = 16777215
    $charts.Range('A1:N1').Font.Bold = $true
    $charts.Range('A1:N1').Font.Size = 16
    $chartData.Cells.Item(1, 1).Value2 = 'Expandable chart calculations'

    $chartBlocks = [System.Collections.Generic.List[object]]::new()
    $base = 2
    $chartIndex = 0
    $dateCapacity = 2000
    foreach ($combination in $combinations) {
        $owner = $combination.Owner
        $house = $combination.House
        $tableName = "${owner}_Valuations"
        $headerRow = $base
        $firstData = $headerRow + 2
        $lastData = $firstData + $dateCapacity - 1
        $chartData.Cells.Item($headerRow, 1).Value2 = "$owner | $house"
        $chartData.Cells.Item($headerRow + 1, 1).Value2 = 'Valuation Date'
        $chartData.Cells.Item($headerRow + 1, 2).Value2 = 'P&L %'
        $sourceOffset = 5 - $firstData
        $sourceRow = if ($sourceOffset -eq 0) { 'R' } else { "R[$sourceOffset]" }
        $dateFormula = '=IF(AND(' + $owner + '!' + $sourceRow + 'C2="' + $house + '",' + $owner + '!' + $sourceRow + 'C1<>""),' + $owner + '!' + $sourceRow + 'C1,"")'
        $pnlFormula = '=IF(RC[-1]="","",IFERROR(' + $owner + '!' + $sourceRow + 'C8,""))'
        $chartData.Range("A${firstData}:A${lastData}").FormulaR1C1 = $dateFormula
        $chartData.Range("B${firstData}:B${lastData}").FormulaR1C1 = $pnlFormula
        $chartData.Range("A${firstData}:A${lastData}").NumberFormat = 'dd-mmm-yyyy'
        $chartData.Range("B${firstData}:B${lastData}").NumberFormat = '0.00%'

        $chartIndex++
        $columnSlot = ($chartIndex - 1) % 2
        $rowSlot = [math]::Floor(($chartIndex - 1) / 2)
        $chartObject = $charts.ChartObjects().Add(20 + ($columnSlot * 520), 45 + ($rowSlot * 300), 500, 270)
        $chart = $chartObject.Chart
        $chart.ChartType = 65
        $chart.HasTitle = $true
        $chart.ChartTitle.Text = "$owner - $house | P&L %"
        $chart.HasLegend = $false
        $chart.PlotVisibleOnly = $false
        $series = $chart.SeriesCollection().NewSeries()
        $series.Name = 'P&L %'
        $series.XValues = $chartData.Range("A${firstData}:A${lastData}")
        $series.Values = $chartData.Range("B${firstData}:B${lastData}")
        $series.Formula = '=SERIES("P&L %",''Chart Data''!$A$' + $firstData + ':$A$' + $lastData + ',''Chart Data''!$B$' + $firstData + ':$B$' + $lastData + ',1)'
        $chart.Axes(1).HasTitle = $true
        $chart.Axes(1).AxisTitle.Text = 'Valuation Date'
        $chart.Axes(1).TickLabels.NumberFormat = 'dd-mmm-yy'
        $chart.Axes(2).HasTitle = $true
        $chart.Axes(2).AxisTitle.Text = 'P&L %'
        $chart.Axes(2).TickLabels.NumberFormat = '0%'
        $chartBlocks.Add([pscustomobject]@{ Owner = $owner; House = $house; Start = $firstData; End = $lastData })
        $base = $lastData + 3
    }

    if (!$chartData.Range('A4').HasFormula -or !$chartData.Range('B4').HasFormula) {
        throw 'Chart data formulas were not created in the expandable source ranges.'
    }
    Write-Output "Chart data check: A4=$($chartData.Range('A4').FormulaR1C1); B4=$($chartData.Range('B4').FormulaR1C1)"
    $chartData.Visible = 2
    $book.ForceFullCalculation = $true
    $macroSource = Get-Content (Join-Path $PSScriptRoot 'RefreshMoneycontrolNAV.bas') -Raw
    $macroModule = $book.VBProject.VBComponents.Add(1)
    $macroModule.Name = 'MoneycontrolNAV'
    $macroModule.CodeModule.AddFromString($macroSource)
    $book.SaveAs($outputPath, 52)
    $excel.Run("'" + $book.Name + "'!RefreshLatestNAV", $true)
    $book.Save()
    Write-Output "CREATED: $outputPath"
    Write-Output "Imported dated records: $($records.Count); SK=$(@($records | Where-Object Owner -eq 'SK').Count); RK=$(@($records | Where-Object Owner -eq 'RK').Count)"
    Write-Output "Fund-house combinations/charts: $($combinations.Count); initial valuation date: $([DateTime]::FromOADate($valuationDate).ToString('dd-MMM-yyyy'))"
}
finally {
    if ($sourceBook) { $sourceBook.Close($false) }
    if ($book) { $book.Close($false) }
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