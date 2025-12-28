# JoyfulRenaming v0.1 Copyright (C) 2025 Enrico Heine https://github.com/Flashdown/JoyfulRenaming

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License Version 3 as
# published by the Free Software Foundation Version 3 of the License.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

param(
    [string]$FolderPath,
    [string]$Search,
    [string]$Replace,
    [switch]$CaseSensitive,
    [switch]$Regex,
    [switch]$ExcludeExt,
    [switch]$InsertAfter,
    [switch]$InsertBefore,
    [switch]$RenameFolders,
    [switch]$Simulate
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Globale Variable für Undo
$undoList = @()

#Version
$JoyfulRenaming_version= "v0.1"

# Übersetzungen definieren
$translations = @{
    "English" = @{
        "FormTitle" = "JoyfulRenaming" + " " + $JoyfulRenaming_version
        "FolderLabel" = "Folder Path:"
        "BrowseButton" = "Browse"
        "SearchLabel" = "Search for:"
        "ReplaceLabel" = "Replace/Insert with:"
        "CaseSensitiveCheck" = "Case Sensitive"
        "RegexCheck" = "Use Regex"
        "ExcludeExtCheck" = "Exclude File Extension (do not change)"
        "InsertAfterCheck" = "Insert after Match (only with Regex, instead of replace)"
        "InsertBeforeCheck" = "Insert before Match (only with Regex, instead of replace)"
        "RenameFoldersCheck" = "Rename Folders (instead of Files)"
        "ExecuteButton" = "Execute"
        "SimulateButton" = "Simulate"
        "UndoButton" = "Undo"
        "SimulateCountLabel" = "Simulations (0=all):"
        "BeforeLabel" = "Before (Original, Match red):"
        "AfterLabel" = "After (Changed, Change green):"
        "CLILabel" = "CLI Parameters for this Simulation (to copy):"
        "FolderNotExist" = "Folder does not exist!"
        "SearchEmpty" = "Search string cannot be empty!"
        "InsertOnlyRegex" = "Insert before/after Match only possible with Regex!"
        "OnlyOneInsert" = "Select only one insert option (before or after)!"
        "FileExistsWarning" = "File/Folder '{0}' already exists. Skipping '{1}'."
        "RenameComplete" = "Renaming completed!"
        "NothingToUndo" = "Nothing to undo!"
        "FileNotFoundWarning" = "File/Folder '{0}' not found. Skipping."
        "UndoComplete" = "Undo completed!"
        "NoChanges" = "No changes found."
        "PreviewGenerated" = "Preview for {0} examples generated."
        "PreviewAllGenerated" = "Preview for all {0} changed items generated."
        "Error" = "Error"
        "Warning" = "Warning"
        "Info" = "Info"
        "Success" = "Success"
        "LanguageLabel" = "Language:"
    }
    "Deutsch" = @{
        "FormTitle" = "JoyfulRenaming" + " " + $JoyfulRenaming_version
        "FolderLabel" = "Ordnerpfad:"
        "BrowseButton" = "Durchsuchen"
        "SearchLabel" = "Suchen nach:"
        "ReplaceLabel" = "Ersetzen/Einfügen durch:"
        "CaseSensitiveCheck" = "Groß-/Kleinschreibung beachten (Case Sensitive)"
        "RegexCheck" = "Regex verwenden"
        "ExcludeExtCheck" = "Dateierweiterung ausnehmen (nicht ändern)"
        "InsertAfterCheck" = "Einfügen nach Match (nur mit Regex, statt Ersetzen)"
        "InsertBeforeCheck" = "Einfügen vor Match (nur mit Regex, statt Ersetzen)"
        "RenameFoldersCheck" = "Ordner umbenennen (statt Dateien)"
        "ExecuteButton" = "Ausführen"
        "SimulateButton" = "Simulieren"
        "UndoButton" = "Undo"
        "SimulateCountLabel" = "Simulationen (0=alle):"
        "BeforeLabel" = "Vorher (Original, Match rot):"
        "AfterLabel" = "Nachher (Geändert, Änderung grün):"
        "CLILabel" = "CLI-Parameter für diese Simulation (zum Kopieren):"
        "FolderNotExist" = "Ordner existiert nicht!"
        "SearchEmpty" = "Suchstring darf nicht leer sein!"
        "InsertOnlyRegex" = "Einfügen vor/nach Match nur mit Regex möglich!"
        "OnlyOneInsert" = "Nur eine Einfüge-Option (vor oder nach) auswählen!"
        "FileExistsWarning" = "Datei/Ordner '{0}' existiert bereits. Überspringe '{1}'."
        "RenameComplete" = "Umbenennung abgeschlossen!"
        "NothingToUndo" = "Nichts zum Rückgängigmachen!"
        "FileNotFoundWarning" = "Datei/Ordner '{0}' nicht gefunden. Überspringe."
        "UndoComplete" = "Undo abgeschlossen!"
        "NoChanges" = "Keine Änderungen gefunden."
        "PreviewGenerated" = "Vorschau für {0} Beispiele generiert."
        "PreviewAllGenerated" = "Vorschau für alle {0} geänderten Elemente generiert."
        "Error" = "Fehler"
        "Warning" = "Warnung"
        "Info" = "Info"
        "Success" = "Erfolg"
        "LanguageLabel" = "Sprache:"
    }
}

# Default Sprache
$currentLanguage = "English"

# Funktion zur Verarbeitung der Umbenennung (wird in GUI und CLI verwendet)
function Perform-Rename {
    param(
        [string]$folderPath,
        [string]$search,
        [string]$replace,
        [bool]$caseSensitive,
        [bool]$useRegex,
        [bool]$excludeExt,
        [bool]$insertAfter,
        [bool]$insertBefore,
        [bool]$renameFolders
    )

    $lang = $translations[$currentLanguage]

    if (-not (Test-Path $folderPath)) {
        Write-Error $lang["FolderNotExist"]
        return
    }
    if ([string]::IsNullOrEmpty($search)) {
        Write-Error $lang["SearchEmpty"]
        return
    }
    if (($insertAfter -or $insertBefore) -and -not $useRegex) {
        Write-Error $lang["InsertOnlyRegex"]
        return
    }
    if ($insertAfter -and $insertBefore) {
        Write-Error $lang["OnlyOneInsert"]
        return
    }

    $items = if ($renameFolders) { Get-ChildItem -Path $folderPath -Directory } else { Get-ChildItem -Path $folderPath -File }

    foreach ($item in $items) {
        $originalName = $item.Name
        $newName = $originalName
        if ($renameFolders) {
            $baseName = $originalName
            $extension = ""
        } else {
            if ($excludeExt) {
                $baseName = $item.BaseName
                $extension = $item.Extension
            } else {
                $baseName = $originalName
                $extension = ""
            }
        }

        if ($useRegex) {
            $regexOptions = if ($caseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
            if ($insertAfter) {
                $newBaseName = [regex]::Replace($baseName, $search, { param($match) $match.Value + $replace }, $regexOptions)
            } elseif ($insertBefore) {
                $newBaseName = [regex]::Replace($baseName, $search, { param($match) $replace + $match.Value }, $regexOptions)
            } else {
                $newBaseName = [regex]::Replace($baseName, $search, $replace, $regexOptions)
            }
        } else {
            if ($caseSensitive) {
                $newBaseName = $baseName -creplace [regex]::Escape($search), $replace
            } else {
                $newBaseName = $baseName -ireplace [regex]::Escape($search), $replace
            }
        }
        $newName = $newBaseName + $extension

        if ($newName -ne $originalName) {
            $newPath = Join-Path -Path $folderPath -ChildPath $newName
            if (Test-Path $newPath) {
                Write-Warning ($lang["FileExistsWarning"] -f $newName, $originalName)
                continue
            }
            $script:undoList += @{OriginalFullName = $item.FullName; NewFullName = $newPath}
            Rename-Item -Path $item.FullName -NewName $newName
        }
    }
    Write-Host $lang["RenameComplete"]
}

# Funktion zur Simulation (für GUI und CLI)
function Perform-Simulate {
    param(
        [string]$folderPath,
        [string]$search,
        [string]$replace,
        [bool]$caseSensitive,
        [bool]$useRegex,
        [bool]$excludeExt,
        [bool]$insertAfter,
        [bool]$insertBefore,
        [bool]$renameFolders,
        [int]$countLimit,
        [System.Windows.Forms.RichTextBox]$rtbBefore = $null,
        [System.Windows.Forms.RichTextBox]$rtbAfter = $null
    )

    $lang = $translations[$currentLanguage]

    if (-not (Test-Path $folderPath)) {
        if ($rtbBefore) { [System.Windows.Forms.MessageBox]::Show($lang["FolderNotExist"], $lang["Error"]) }
        else { Write-Error $lang["FolderNotExist"] }
        return
    }
    if ([string]::IsNullOrEmpty($search)) {
        if ($rtbBefore) { [System.Windows.Forms.MessageBox]::Show($lang["SearchEmpty"], $lang["Error"]) }
        else { Write-Error $lang["SearchEmpty"] }
        return
    }
    if (($insertAfter -or $insertBefore) -and -not $useRegex) {
        if ($rtbBefore) { [System.Windows.Forms.MessageBox]::Show($lang["InsertOnlyRegex"], $lang["Error"]) }
        else { Write-Error $lang["InsertOnlyRegex"] }
        return
    }
    if ($insertAfter -and $insertBefore) {
        if ($rtbBefore) { [System.Windows.Forms.MessageBox]::Show($lang["OnlyOneInsert"], $lang["Error"]) }
        else { Write-Error $lang["OnlyOneInsert"] }
        return
    }

    $regexOptions = if ($caseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
    $effectiveSearch = if ($useRegex) { $search } else { [regex]::Escape($search) }
    $regex = New-Object System.Text.RegularExpressions.Regex $effectiveSearch, $regexOptions

    $items = if ($renameFolders) { Get-ChildItem -Path $folderPath -Directory } else { Get-ChildItem -Path $folderPath -File }

    $previewBefore = @()
    $count = 0
    $effectiveLimit = if ($countLimit -eq 0) { [int]::MaxValue } else { $countLimit }
    foreach ($item in $items) {
        if ($count -ge $effectiveLimit) { break }
        $originalName = $item.Name
        $newName = $originalName
        if ($renameFolders) {
            $target = $originalName
            $extension = ""
        } else {
            if ($excludeExt) {
                $target = $item.BaseName
                $extension = $item.Extension
            } else {
                $target = $originalName
                $extension = ""
            }
        }

        # Manuelle Verarbeitung für Highlighting
        $matches = $regex.Matches($target)
        $newTarget = $target
        $offset = 0
        $highlightPositionsAfter = @()
        foreach ($match in $matches) {
            if ($insertAfter) {
                $insertion = $match.Value + $replace
                $newTarget = $newTarget.Substring(0, $match.Index + $offset) + $insertion + $newTarget.Substring($match.Index + $match.Length + $offset)
                $highlightPositionsAfter += @{Start = $match.Index + $match.Length + $offset; Length = $replace.Length}
                $offset += $replace.Length
            } elseif ($insertBefore) {
                $insertion = $replace + $match.Value
                $newTarget = $newTarget.Substring(0, $match.Index + $offset) + $insertion + $newTarget.Substring($match.Index + $match.Length + $offset)
                $highlightPositionsAfter += @{Start = $match.Index + $offset; Length = $replace.Length}
                $offset += $replace.Length
            } else {
                $replacement = $match.Result($replace) # Expandet $1, $2 etc.
                $newTarget = $newTarget.Substring(0, $match.Index + $offset) + $replacement + $newTarget.Substring($match.Index + $match.Length + $offset)
                $highlightPositionsAfter += @{Start = $match.Index + $offset; Length = $replacement.Length}
                $offset += $replacement.Length - $match.Length
            }
        }
        $newName = $newTarget + $extension

        if ($newName -ne $originalName) {
            $previewBefore += @{Name = $originalName; Matches = $matches; HighlightAfter = $highlightPositionsAfter; NewName = $newName}
            $count++
        }
    }

    if ($rtbBefore -and $rtbAfter) {
        # GUI-Modus: Highlighting in RichTextBoxes
        $rtbBefore.Text = ""
        $rtbAfter.Text = ""
        foreach ($item in $previewBefore) {
            $originalName = $item.Name
            $newName = $item.NewName
            $matches = $item.Matches
            $highlightPositionsAfter = $item.HighlightAfter

            # Vorher: Highlight Matches rot
            $startPosBefore = $rtbBefore.TextLength
            $rtbBefore.AppendText($originalName + "`n")
            foreach ($match in $matches) {
                $rtbBefore.SelectionStart = $startPosBefore + $match.Index
                $rtbBefore.SelectionLength = $match.Length
                $rtbBefore.SelectionColor = [System.Drawing.Color]::Red
            }

            # Nachher: Highlight geänderte Teile grün
            $startPosAfter = $rtbAfter.TextLength
            $rtbAfter.AppendText($newName + "`n")
            foreach ($pos in $highlightPositionsAfter) {
                $rtbAfter.SelectionStart = $startPosAfter + $pos.Start
                $rtbAfter.SelectionLength = $pos.Length
                $rtbAfter.SelectionColor = [System.Drawing.Color]::Green
            }
        }
        if ($count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show($lang["NoChanges"], $lang["Info"])
        } else {
            $msg = if ($countLimit -eq 0) { $lang["PreviewAllGenerated"] -f $count } else { $lang["PreviewGenerated"] -f $count }
            [System.Windows.Forms.MessageBox]::Show($msg, $lang["Success"])
        }
    } else {
        # CLI-Modus: Textausgabe
        if ($count -eq 0) {
            Write-Host $lang["NoChanges"]
        } else {
            Write-Host ($lang["PreviewGenerated"] -f $count)
            foreach ($item in $previewBefore) {
                Write-Host "Before: $($item.Name)"
                Write-Host "After: $($item.NewName)"
                Write-Host ""
            }
        }
    }
    return $count
}

# Funktion zum Generieren des CLI-Strings
function Generate-CLIString {
    param(
        [string]$folderPath,
        [string]$search,
        [string]$replace,
        [bool]$caseSensitive,
        [bool]$useRegex,
        [bool]$excludeExt,
        [bool]$insertAfter,
        [bool]$insertBefore,
        [bool]$renameFolders,
        [bool]$simulate
    )

    $cli = ".\FileRenamer.ps1 -FolderPath `"$folderPath`" -Search `"$search`" -Replace `"$replace`""
    if ($caseSensitive) { $cli += " -CaseSensitive" }
    if ($useRegex) { $cli += " -Regex" }
    if ($excludeExt) { $cli += " -ExcludeExt" }
    if ($insertAfter) { $cli += " -InsertAfter" }
    if ($insertBefore) { $cli += " -InsertBefore" }
    if ($renameFolders) { $cli += " -RenameFolders" }
    if ($simulate) { $cli += " -Simulate" }
    return $cli
}

# Prüfen, ob Kommandozeilen-Parameter angegeben sind
if ($PSBoundParameters.Count -gt 0) {
    # CLI-Modus
    if ($Simulate) {
        # Simulate mit GUI-Vorschau: Öffne GUI und fülle Felder
        $guiMode = $true
        $autoSimulate = $true
    } else {
        # Direkte Ausführung ohne GUI
        Perform-Rename -folderPath $FolderPath -search $Search -replace $Replace -caseSensitive $CaseSensitive.IsPresent -useRegex $Regex.IsPresent -excludeExt $ExcludeExt.IsPresent -insertAfter $InsertAfter.IsPresent -insertBefore $InsertBefore.IsPresent -renameFolders $RenameFolders.IsPresent
        exit
    }
} else {
    # Normaler GUI-Modus
    $guiMode = $true
    $autoSimulate = $false
}

if ($guiMode) {
    # GUI erstellen
    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(800, 900)  # Erhöht auf 800 für mehr Platz
    $form.StartPosition = "CenterScreen"
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    # Sprache-Auswahl (ComboBox)
    $labelLanguage = New-Object System.Windows.Forms.Label
    $labelLanguage.Location = New-Object System.Drawing.Point(540, 325)
    $labelLanguage.Size = New-Object System.Drawing.Size(70, 20)
    $form.Controls.Add($labelLanguage)

    $comboLanguage = New-Object System.Windows.Forms.ComboBox
    $comboLanguage.Location = New-Object System.Drawing.Point(620, 320)
    $comboLanguage.Size = New-Object System.Drawing.Size(80, 20)
    $comboLanguage.Items.AddRange(@("English", "Deutsch"))
    $comboLanguage.SelectedIndex = 0  # Default English
    $form.Controls.Add($comboLanguage)

    # Funktion zum Aktualisieren der GUI-Texte
    function Update-GUIText {
        $currentLanguage = $comboLanguage.SelectedItem
        $lang = $translations[$currentLanguage]

        $form.Text = $lang["FormTitle"]
        $labelFolder.Text = $lang["FolderLabel"]
        $btnBrowse.Text = $lang["BrowseButton"]
        $labelSearch.Text = $lang["SearchLabel"]
        $labelReplace.Text = $lang["ReplaceLabel"]
        $chkCaseSensitive.Text = $lang["CaseSensitiveCheck"]
        $chkRegex.Text = $lang["RegexCheck"]
        $chkExcludeExt.Text = $lang["ExcludeExtCheck"]
        $chkInsertAfter.Text = $lang["InsertAfterCheck"]
        $chkInsertBefore.Text = $lang["InsertBeforeCheck"]
        $chkRenameFolders.Text = $lang["RenameFoldersCheck"]
        $btnExecute.Text = $lang["ExecuteButton"]
        $btnSimulate.Text = $lang["SimulateButton"]
        $btnUndo.Text = $lang["UndoButton"]
        $labelSimulateCount.Text = $lang["SimulateCountLabel"]
        $labelBefore.Text = $lang["BeforeLabel"]
        $labelAfter.Text = $lang["AfterLabel"]
        $labelCLI.Text = $lang["CLILabel"]
        $labelLanguage.Text = $lang["LanguageLabel"]
    }

    # Event für Sprachwechsel
    $comboLanguage.Add_SelectedIndexChanged({
        Update-GUIText
    })

    # Label und Textbox für Ordnerpfad
    $labelFolder = New-Object System.Windows.Forms.Label
    $labelFolder.Location = New-Object System.Drawing.Point(10, 20)
    $labelFolder.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($labelFolder)

    $textFolder = New-Object System.Windows.Forms.TextBox
    $textFolder.Location = New-Object System.Drawing.Point(120, 20)
    $textFolder.Size = New-Object System.Drawing.Size(570, 20)
    $textFolder.Add_KeyDown({
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::A) {
            $this.SelectAll()
            $_.SuppressKeyPress = $true
        }
    })
    $form.Controls.Add($textFolder)

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(700, 20)
    $btnBrowse.Size = New-Object System.Drawing.Size(90, 20)
    $btnBrowse.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $textFolder.Text = $folderBrowser.SelectedPath
        }
    })
    $form.Controls.Add($btnBrowse)

    # Label und Textbox für Suchstring
    $labelSearch = New-Object System.Windows.Forms.Label
    $labelSearch.Location = New-Object System.Drawing.Point(10, 60)
    $labelSearch.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($labelSearch)

    $textSearch = New-Object System.Windows.Forms.TextBox
    $textSearch.Location = New-Object System.Drawing.Point(120, 60)
    $textSearch.Size = New-Object System.Drawing.Size(670, 20)
    $textSearch.Add_KeyDown({
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::A) {
            $this.SelectAll()
            $_.SuppressKeyPress = $true
        }
    })
    $form.Controls.Add($textSearch)

    # Label und Textbox für Ersetzungs-/Einfügestring
    $labelReplace = New-Object System.Windows.Forms.Label
    $labelReplace.Location = New-Object System.Drawing.Point(10, 100)
    $labelReplace.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($labelReplace)

    $textReplace = New-Object System.Windows.Forms.TextBox
    $textReplace.Location = New-Object System.Drawing.Point(170, 100)
    $textReplace.Size = New-Object System.Drawing.Size(620, 20)
    $textReplace.Add_KeyDown({
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::A) {
            $this.SelectAll()
            $_.SuppressKeyPress = $true
        }
    })
    $form.Controls.Add($textReplace)

    # Checkbox für Case Sensitive
    $chkCaseSensitive = New-Object System.Windows.Forms.CheckBox
    $chkCaseSensitive.Location = New-Object System.Drawing.Point(10, 140)
    $chkCaseSensitive.Size = New-Object System.Drawing.Size(300, 20)
    $chkCaseSensitive.Checked = $false
    $form.Controls.Add($chkCaseSensitive)

    # Checkbox für Regex
    $chkRegex = New-Object System.Windows.Forms.CheckBox
    $chkRegex.Location = New-Object System.Drawing.Point(10, 170)
    $chkRegex.Size = New-Object System.Drawing.Size(300, 20)
    $chkRegex.Checked = $false
    $form.Controls.Add($chkRegex)

    # Checkbox für Exclude Extension
    $chkExcludeExt = New-Object System.Windows.Forms.CheckBox
    $chkExcludeExt.Location = New-Object System.Drawing.Point(10, 200)
    $chkExcludeExt.Size = New-Object System.Drawing.Size(300, 20)
    $chkExcludeExt.Checked = $true
    $form.Controls.Add($chkExcludeExt)

    # Checkbox für Insert after Match
    $chkInsertAfter = New-Object System.Windows.Forms.CheckBox
    $chkInsertAfter.Location = New-Object System.Drawing.Point(10, 230)
    $chkInsertAfter.Size = New-Object System.Drawing.Size(350, 20)
    $chkInsertAfter.Checked = $false
    $form.Controls.Add($chkInsertAfter)

    # Checkbox für Insert before Match
    $chkInsertBefore = New-Object System.Windows.Forms.CheckBox
    $chkInsertBefore.Location = New-Object System.Drawing.Point(10, 260)
    $chkInsertBefore.Size = New-Object System.Drawing.Size(350, 20)
    $chkInsertBefore.Checked = $false
    $form.Controls.Add($chkInsertBefore)

    # Checkbox für Rename Folders
    $chkRenameFolders = New-Object System.Windows.Forms.CheckBox
    $chkRenameFolders.Location = New-Object System.Drawing.Point(10, 290)
    $chkRenameFolders.Size = New-Object System.Drawing.Size(300, 20)
    $chkRenameFolders.Checked = $false
    $form.Controls.Add($chkRenameFolders)

    # Button zum Ausführen
    $btnExecute = New-Object System.Windows.Forms.Button
    $btnExecute.Location = New-Object System.Drawing.Point(10, 320)
    $btnExecute.Size = New-Object System.Drawing.Size(100, 30)
    $btnExecute.Add_Click({
        $script:undoList = @()
        $folderPath = $textFolder.Text
        $search = $textSearch.Text
        $replace = $textReplace.Text
        $caseSensitive = $chkCaseSensitive.Checked
        $useRegex = $chkRegex.Checked
        $excludeExt = $chkExcludeExt.Checked
        $insertAfter = $chkInsertAfter.Checked
        $insertBefore = $chkInsertBefore.Checked
        $renameFolders = $chkRenameFolders.Checked

        Perform-Rename -folderPath $folderPath -search $search -replace $replace -caseSensitive $caseSensitive -useRegex $useRegex -excludeExt $excludeExt -insertAfter $insertAfter -insertBefore $insertBefore -renameFolders $renameFolders

        if ($script:undoList.Count -gt 0) {
            $btnUndo.Enabled = $true
        }
    })
    $form.Controls.Add($btnExecute)

    # Button zum Simulieren
    $btnSimulate = New-Object System.Windows.Forms.Button
    $btnSimulate.Location = New-Object System.Drawing.Point(120, 320)
    $btnSimulate.Size = New-Object System.Drawing.Size(100, 30)
    $btnSimulate.Add_Click({
        $folderPath = $textFolder.Text
        $search = $textSearch.Text
        $replace = $textReplace.Text
        $caseSensitive = $chkCaseSensitive.Checked
        $useRegex = $chkRegex.Checked
        $excludeExt = $chkExcludeExt.Checked
        $insertAfter = $chkInsertAfter.Checked
        $insertBefore = $chkInsertBefore.Checked
        $renameFolders = $chkRenameFolders.Checked
        $countLimit = $numSimulate.Value

        Perform-Simulate -folderPath $folderPath -search $search -replace $replace -caseSensitive $caseSensitive -useRegex $useRegex -excludeExt $excludeExt -insertAfter $insertAfter -insertBefore $insertBefore -renameFolders $renameFolders -countLimit $countLimit -rtbBefore $rtbBefore -rtbAfter $rtbAfter

        # Generiere und zeige CLI-Parameter für Simulation
        $cliString = Generate-CLIString -folderPath $folderPath -search $search -replace $replace -caseSensitive $caseSensitive -useRegex $useRegex -excludeExt $excludeExt -insertAfter $insertAfter -insertBefore $insertBefore -renameFolders $renameFolders -simulate $true
        $rtbCLI.Text = $cliString
    })
    $form.Controls.Add($btnSimulate)

    # Undo-Button
    $btnUndo = New-Object System.Windows.Forms.Button
    $btnUndo.Location = New-Object System.Drawing.Point(230, 320)
    $btnUndo.Size = New-Object System.Drawing.Size(100, 30)
    $btnUndo.Enabled = $false
    $btnUndo.Add_Click({
        $lang = $translations[$currentLanguage]
        if ($script:undoList.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show($lang["NothingToUndo"], $lang["Info"])
            return
        }
        foreach ($item in $script:undoList) {
            $originalName = Split-Path $item.OriginalFullName -Leaf
            $newFullName = $item.NewFullName
            if (Test-Path $newFullName) {
                Rename-Item -Path $newFullName -NewName $originalName
            } else {
                [System.Windows.Forms.MessageBox]::Show(($lang["FileNotFoundWarning"] -f $newFullName), $lang["Warning"])
            }
        }
        [System.Windows.Forms.MessageBox]::Show($lang["UndoComplete"], $lang["Success"])
        $script:undoList = @()
        $btnUndo.Enabled = $false
    })
    $form.Controls.Add($btnUndo)

    # Label für Simulationsanzahl
    $labelSimulateCount = New-Object System.Windows.Forms.Label
    $labelSimulateCount.Location = New-Object System.Drawing.Point(340, 325)
    $labelSimulateCount.Size = New-Object System.Drawing.Size(130, 20)
    $form.Controls.Add($labelSimulateCount)

    # NumericUpDown für Simulationsanzahl
    $numSimulate = New-Object System.Windows.Forms.NumericUpDown
    $numSimulate.Location = New-Object System.Drawing.Point(480, 320)
    $numSimulate.Size = New-Object System.Drawing.Size(50, 30)
    $numSimulate.Minimum = 0
    $numSimulate.Maximum = 999
    $numSimulate.Value = 5
    $form.Controls.Add($numSimulate)

    # Label für Vorschau Vorher
    $labelBefore = New-Object System.Windows.Forms.Label
    $labelBefore.Location = New-Object System.Drawing.Point(10, 360)
    $labelBefore.Size = New-Object System.Drawing.Size(780, 20)
    $form.Controls.Add($labelBefore)

    # RichTextBox für Vorher
    $rtbBefore = New-Object System.Windows.Forms.RichTextBox
    $rtbBefore.Location = New-Object System.Drawing.Point(10, 380)
    $rtbBefore.Size = New-Object System.Drawing.Size(780, 150)
    $rtbBefore.ReadOnly = $true
    $rtbBefore.ScrollBars = "Both"
    $form.Controls.Add($rtbBefore)

    # Label für Vorschau Nachher
    $labelAfter = New-Object System.Windows.Forms.Label
    $labelAfter.Location = New-Object System.Drawing.Point(10, 540)
    $labelAfter.Size = New-Object System.Drawing.Size(780, 20)
    $form.Controls.Add($labelAfter)

    # RichTextBox für Nachher
    $rtbAfter = New-Object System.Windows.Forms.RichTextBox
    $rtbAfter.Location = New-Object System.Drawing.Point(10, 560)
    $rtbAfter.Size = New-Object System.Drawing.Size(780, 150)
    $rtbAfter.ReadOnly = $true
    $rtbAfter.ScrollBars = "Both"
    $form.Controls.Add($rtbAfter)

    # Label für CLI-Parameter
    $labelCLI = New-Object System.Windows.Forms.Label
    $labelCLI.Location = New-Object System.Drawing.Point(10, 720)
    $labelCLI.Size = New-Object System.Drawing.Size(780, 20)
    $form.Controls.Add($labelCLI)

    # RichTextBox für CLI-Parameter
    $rtbCLI = New-Object System.Windows.Forms.RichTextBox
    $rtbCLI.Location = New-Object System.Drawing.Point(10, 740)
    $rtbCLI.Size = New-Object System.Drawing.Size(780, 50)
    $rtbCLI.ReadOnly = $true
    $rtbCLI.ScrollBars = "Horizontal"
    $form.Controls.Add($rtbCLI)

    # Initiale Texte setzen
    Update-GUIText

    # Wenn Simulate aus CLI, Felder füllen
    if ($Simulate) {
        $textFolder.Text = $FolderPath
        $textSearch.Text = $Search
        $textReplace.Text = $Replace
        $chkCaseSensitive.Checked = $CaseSensitive.IsPresent
        $chkRegex.Checked = $Regex.IsPresent
        $chkExcludeExt.Checked = $ExcludeExt.IsPresent
        $chkInsertAfter.Checked = $InsertAfter.IsPresent
        $chkInsertBefore.Checked = $InsertBefore.IsPresent
        $chkRenameFolders.Checked = $RenameFolders.IsPresent

        # Automatisch simulieren
        if ($autoSimulate) {
            $btnSimulate.PerformClick()
        }
    }

    # GUI anzeigen
    $form.ShowDialog()
}
