Option Explicit

Private Const MONEYCONTROL_SEARCH As String = "https://api.moneycontrol.com/swiftapi/v1/mutualfunds/get-mf-list?&str="
Private Const MONEYCONTROL_NAV As String = "https://api.moneycontrol.com/swiftapi/v1/mutualfunds/graph-nav?&isin="

Public Sub RefreshLatestNAV(Optional ByVal silent As Boolean = False)
    Dim ws As Worksheet
    Dim owners As Variant
    Dim owner As Variant
    Dim sourceTable As ListObject
    Dim rowIndex As Long
    Dim outputRow As Long
    Dim oldLastRow As Long
    Dim cache As Object
    Dim holdings As Object
    Dim navResults As Object
    Dim recordKey As String
    Dim isin As String
    Dim navValue As Double
    Dim navDate As Date
    Dim statusText As String
    Dim record As Variant
    Dim httpStatus As Long
    Dim key As Variant

    On Error GoTo RefreshFailed
    Application.ScreenUpdating = False
    Application.StatusBar = "Reading SK and RK holdings..."
    Set ws = ThisWorkbook.Worksheets("NAV Lookup")
    Set cache = CreateObject("Scripting.Dictionary")
    Set holdings = CreateObject("Scripting.Dictionary")
    Set navResults = CreateObject("Scripting.Dictionary")

    oldLastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row
    For rowIndex = 6 To oldLastRow
        recordKey = MakeKey(CStr(ws.Cells(rowIndex, 2).Value2), _
                            CStr(ws.Cells(rowIndex, 3).Value2), _
                            CStr(ws.Cells(rowIndex, 4).Value2))
        If Len(recordKey) > 2 And Len(CStr(ws.Cells(rowIndex, 8).Value2)) > 0 Then
            cache(recordKey) = CStr(ws.Cells(rowIndex, 8).Value2)
        End If
    Next rowIndex

    owners = Array("SK", "RK")
    For Each owner In owners
        Set sourceTable = ThisWorkbook.Worksheets(CStr(owner)).ListObjects(CStr(owner) & "_Valuations")
        For rowIndex = 1 To sourceTable.ListRows.Count
            With sourceTable.DataBodyRange.Rows(rowIndex)
                If Len(Trim$(CStr(.Cells(1, 2).Value2))) > 0 And _
                   Len(Trim$(CStr(.Cells(1, 3).Value2))) > 0 Then
                    recordKey = MakeKey(CStr(.Cells(1, 2).Value2), _
                                        CStr(.Cells(1, 3).Value2), _
                                        CStr(.Cells(1, 12).Value2))
                    If Not holdings.Exists(recordKey) Then
                        holdings.Add recordKey, Array(CStr(.Cells(1, 2).Value2), _
                                                      CStr(.Cells(1, 3).Value2), _
                                                      CStr(.Cells(1, 12).Value2))
                    End If
                End If
            End With
        Next rowIndex
    Next owner

    If ws.ListObjects.Count > 0 Then ws.ListObjects(1).Unlist
    If oldLastRow < 6 Then oldLastRow = 6
    ws.Range("A6:H" & oldLastRow).ClearContents
    ws.Cells(5, 1).Resize(1, 8).Value = Array("Current Date", "Fund House", "Scheme", _
                                              "Plan/Option", "Latest NAV Price", "NAV As Of", _
                                              "Status", "Moneycontrol ISIN")

    outputRow = 6
    For Each key In holdings.Keys
        record = holdings(key)
        statusText = vbNullString
        ws.Cells(outputRow, 1).Value = Date
        ws.Cells(outputRow, 2).Value = record(0)
        ws.Cells(outputRow, 3).Value = record(1)
        ws.Cells(outputRow, 4).Value = record(2)
        ws.Cells(outputRow, 8).NumberFormat = "@"

        Application.StatusBar = "Fetching Moneycontrol NAV " & (outputRow - 5) & _
                                " of " & holdings.Count & "..."
        If cache.Exists(CStr(key)) Then
            isin = CStr(cache(key))
        Else
            isin = FindMoneycontrolISIN(CStr(record(0)), CStr(record(1)), _
                                        CStr(record(2)), statusText)
        End If

        If Len(isin) = 0 Then
            ws.Cells(outputRow, 7).Value = statusText
        Else
            ws.Cells(outputRow, 8).Value = isin
            If GetLatestMoneycontrolNAV(isin, navValue, navDate, statusText, httpStatus) Then
                ws.Cells(outputRow, 5).Value = navValue
                ws.Cells(outputRow, 6).Value = navDate
                ws.Cells(outputRow, 7).Value = "Updated from Moneycontrol"
                navResults(CStr(key)) = Array(navValue, navDate, isin)
            Else
                ws.Cells(outputRow, 7).Value = statusText
            End If
        End If
        outputRow = outputRow + 1
    Next key

    If outputRow > 6 Then
        Set sourceTable = ws.ListObjects.Add(xlSrcRange, ws.Range("A5:H" & outputRow - 1), , xlYes)
        sourceTable.Name = "MoneycontrolNAV"
        sourceTable.TableStyle = "TableStyleMedium2"
    End If

    UpdateOwnerValuations navResults
    Application.CalculateFull

    ws.Columns("A").NumberFormat = "dd-mmm-yyyy"
    ws.Columns("E").NumberFormat = "0.0000"
    ws.Columns("F").NumberFormat = "dd-mmm-yyyy"
    ws.Columns("A").ColumnWidth = 16
    ws.Columns("B").ColumnWidth = 23
    ws.Columns("C").ColumnWidth = 54
    ws.Columns("D").ColumnWidth = 20
    ws.Columns("E").ColumnWidth = 19
    ws.Columns("F").ColumnWidth = 16
    ws.Columns("G").ColumnWidth = 32
    ws.Columns("H").Hidden = True
    ws.Range("A3").Value = "Last refresh: " & Format$(Now, "dd-mmm-yyyy hh:mm")
    ws.Range("A3").Font.Italic = True
    ws.Activate
    ws.Range("A6").Select
    If Not ActiveWindow.FreezePanes Then ActiveWindow.FreezePanes = True
    Application.StatusBar = False
    Application.ScreenUpdating = True
    If Not silent Then
        MsgBox "NAV refresh complete. " & holdings.Count & _
               " fund-house/scheme/plan rows checked. Review Status for unmatched schemes.", _
               vbInformation, "Moneycontrol NAV"
    End If
    Exit Sub

RefreshFailed:
    Application.StatusBar = False
    Application.ScreenUpdating = True
    If Not silent Then MsgBox "NAV refresh stopped: " & Err.Description, _
                              vbExclamation, "Moneycontrol NAV"
End Sub

Private Sub UpdateOwnerValuations(ByVal navResults As Object)
    Dim owners As Variant
    Dim owner As Variant
    Dim sourceTable As ListObject
    Dim rowIndex As Long
    Dim recordKey As String
    Dim navRecord As Variant
    Dim unitsValue As Variant

    owners = Array("SK", "RK")
    For Each owner In owners
        Set sourceTable = ThisWorkbook.Worksheets(CStr(owner)).ListObjects(CStr(owner) & "_Valuations")
        For rowIndex = 1 To sourceTable.ListRows.Count
            With sourceTable.DataBodyRange.Rows(rowIndex)
                If Len(Trim$(CStr(.Cells(1, 2).Value2))) > 0 And _
                   Len(Trim$(CStr(.Cells(1, 3).Value2))) > 0 Then
                    recordKey = MakeKey(CStr(.Cells(1, 2).Value2), _
                                        CStr(.Cells(1, 3).Value2), _
                                        CStr(.Cells(1, 12).Value2))
                    If navResults.Exists(recordKey) Then
                        navRecord = navResults(recordKey)
                        .Cells(1, 10).Value = navRecord(0)
                        unitsValue = .Cells(1, 9).Value2
                        If IsNumeric(unitsValue) And CDbl(unitsValue) <> 0 Then
                            .Cells(1, 1).Value = Date
                            .Cells(1, 6).Value = CDbl(unitsValue) * CDbl(navRecord(0))
                        End If
                    End If
                End If
            End With
        Next rowIndex
    Next owner
End Sub

Private Function MakeKey(ByVal fundHouse As String, ByVal scheme As String, _
                         ByVal planOption As String) As String
    MakeKey = NormalizeScheme(fundHouse) & "|" & NormalizeScheme(scheme) & "|" & _
              NormalizeScheme(planOption)
End Function

Private Function FindMoneycontrolISIN(ByVal fundHouse As String, _
                                      ByVal scheme As String, _
                                      ByVal planOption As String, _
                                      ByRef statusText As String) As String
    Dim body As String
    Dim requestUrl As String
    Dim regex As Object
    Dim matches As Object
    Dim candidateName As String
    Dim candidateISIN As String
    Dim target As String
    Dim candidate As String
    Dim score As Double
    Dim bestScore As Double
    Dim secondScore As Double
    Dim bestISIN As String
    Dim i As Long

    requestUrl = MONEYCONTROL_SEARCH & UrlEncode(scheme) & _
                 "&limit=20&deviceType=W&responseType=json"
    If Not HttpGet(requestUrl, body, statusText) Then Exit Function

    Set regex = CreateObject("VBScript.RegExp")
    regex.Global = True
    regex.IgnoreCase = True
    regex.MultiLine = True
    regex.Pattern = "\{[^{}]*""schemeName""\s*:\s*""([^""]+)""[^{}]*""isin""\s*:\s*""([^""]+)""[^{}]*\}"
    Set matches = regex.Execute(body)
    target = NormalizeScheme(fundHouse & " " & scheme & " " & planOption)

    For i = 0 To matches.Count - 1
        candidateName = matches(i).SubMatches(0)
        candidateISIN = matches(i).SubMatches(1)
        candidate = NormalizeScheme(candidateName)
        score = MatchScore(target, candidate)
        If HasPlanMismatch(planOption, candidateName) Then score = 0
        If score > bestScore Then
            secondScore = bestScore
            bestScore = score
            bestISIN = candidateISIN
        ElseIf score > secondScore Then
            secondScore = score
        End If
    Next i

    If bestScore < 0.65 Then
        statusText = "No confident Moneycontrol scheme match"
    ElseIf bestScore - secondScore < 0.08 Then
        statusText = "Ambiguous scheme match; review Direct/Regular plan"
    Else
        FindMoneycontrolISIN = bestISIN
        statusText = vbNullString
    End If
End Function

Private Function GetLatestMoneycontrolNAV(ByVal isin As String, _
                                           ByRef navValue As Double, _
                                           ByRef navDate As Date, _
                                           ByRef statusText As String, _
                                           ByRef httpStatus As Long) As Boolean
    Dim body As String
    Dim requestUrl As String
    Dim regex As Object
    Dim matches As Object
    Dim match As Object

    requestUrl = MONEYCONTROL_NAV & UrlEncode(isin) & _
                 "&dur=1Y&deviceType=W&responseType=json"
    If Not HttpGet(requestUrl, body, statusText, httpStatus) Then Exit Function

    Set regex = CreateObject("VBScript.RegExp")
    regex.Global = True
    regex.IgnoreCase = True
    regex.Pattern = """navDate""\s*:\s*""(\d{4}-\d{2}-\d{2})""\s*,\s*""navValue""\s*:\s*([0-9]+(?:\.[0-9]+)?)"
    Set matches = regex.Execute(body)
    If matches.Count = 0 Then
        statusText = "No NAV returned by Moneycontrol"
        Exit Function
    End If

    Set match = matches(matches.Count - 1)
    navDate = DateSerial(CInt(Left$(match.SubMatches(0), 4)), _
                         CInt(Mid$(match.SubMatches(0), 6, 2)), _
                         CInt(Right$(match.SubMatches(0), 2)))
    navValue = CDbl(match.SubMatches(1))
    GetLatestMoneycontrolNAV = True
End Function

Private Function HttpGet(ByVal requestUrl As String, _
                         ByRef responseText As String, _
                         ByRef statusText As String, _
                         Optional ByRef statusCode As Long = 0) As Boolean
    Dim request As Object

    On Error GoTo RequestFailed
    Set request = CreateObject("WinHttp.WinHttpRequest.5.1")
    request.SetTimeouts 5000, 5000, 10000, 15000
    request.Open "GET", requestUrl, False
    request.SetRequestHeader "User-Agent", "Mozilla/5.0 Excel NAV Tracker"
    request.Send
    statusCode = request.Status
    If statusCode < 200 Or statusCode >= 300 Then
        statusText = "Moneycontrol HTTP " & statusCode
        Exit Function
    End If
    responseText = request.ResponseText
    HttpGet = True
    Exit Function

RequestFailed:
    statusText = "Moneycontrol request failed: " & Err.Description
End Function

Private Function UrlEncode(ByVal value As String) As String
    Dim i As Long
    Dim code As Long
    Dim character As String
    Dim result As String

    For i = 1 To Len(value)
        character = Mid$(value, i, 1)
        code = AscW(character)
        If (code >= 48 And code <= 57) Or _
           (code >= 65 And code <= 90) Or _
           (code >= 97 And code <= 122) Or _
           character = "-" Or character = "_" Or character = "." Or character = "~" Then
            result = result & character
        Else
            result = result & "%" & Right$("0" & Hex$(code And &HFF&), 2)
        End If
    Next i
    UrlEncode = result
End Function

Private Function NormalizeScheme(ByVal value As String) As String
    Dim regex As Object
    Dim text As String

    text = LCase$(value)
    text = Replace(text, "mid cp", "mid cap")
    text = Replace(text, "sm cp", "small cap")
    text = Replace(text, "dir gr", "direct growth")
    text = Replace(text, " dir ", " direct ")
    text = Replace(text, " gr ", " growth ")
    text = Replace(text, " reg ", " regular ")
    text = Replace(text, " pl ", " plan ")
    Set regex = CreateObject("VBScript.RegExp")
    regex.Global = True
    regex.IgnoreCase = True
    regex.Pattern = "[^a-z0-9]+"
    text = regex.Replace(text, " ")
    regex.Pattern = "\b(fund|plan|option|scheme)\b"
    text = regex.Replace(text, " ")
    regex.Pattern = "\s+"
    text = Trim$(regex.Replace(text, " "))
    NormalizeScheme = text
End Function

Private Function MatchScore(ByVal target As String, ByVal candidate As String) As Double
    Dim tokens As Variant
    Dim token As Variant
    Dim total As Long
    Dim found As Long

    tokens = Split(target, " ")
    For Each token In tokens
        If Len(CStr(token)) > 0 Then
            total = total + 1
            If InStr(1, " " & candidate & " ", " " & CStr(token) & " ", vbTextCompare) > 0 Then
                found = found + 1
            End If
        End If
    Next token
    If total > 0 Then MatchScore = found / total
End Function

Private Function HasPlanMismatch(ByVal planOption As String, _
                                ByVal candidateName As String) As Boolean
    Dim planText As String
    Dim candidateText As String

    planText = LCase$(planOption)
    candidateText = NormalizeScheme(candidateName)
    If InStr(planText, "direct") > 0 And InStr(candidateText, "direct") = 0 Then
        HasPlanMismatch = True
    ElseIf InStr(planText, "regular") > 0 And InStr(candidateText, "regular") = 0 Then
        HasPlanMismatch = True
    End If
End Function
