# failsafe
break

 #----------------------------------------------------------------------------# 
 #                    Chapter 1: Implementation & Concepts                    # 
 #----------------------------------------------------------------------------# 

# 1. The basics
class DateTimeParamA {
    [DateTime] $Value

    DateTimeParamA([DateTime] $Value) {
        $this.Value = $Value
    }
}
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamA]$Timestamp
    )
    $Timestamp.Value
}
Get-Test -Timestamp (Get-Date)

# 2. Adding second constructor
# a) Stringing out the datetime
class DateTimeParamB {
    [DateTime] $Value

    DateTimeParamB([DateTime] $Value) {
        $this.Value = $Value
    }

    DateTimeParamB([string] $Value) {
        $this.Value = $this.ParseDateTime($Value)
    }

    [DateTime] ParseDateTime([string] $Value)
    {
        if (-not $Value) {
            throw "Cannot parse empty string!"
        }

        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::CurrentCulture) }
        catch { }
        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture) }
        catch { }

        throw "Could not parse input!"
    }
}
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamB]$Timestamp
    )
    $Timestamp.Value
}
Get-Test -Timestamp (Get-Date)
Get-Test -Timestamp (Get-Date).ToString()

# b) Adding user convenience
class DateTimeParamC {
    [DateTime] $Value

    DateTimeParamC([DateTime] $Value) {
        $this.Value = $Value
    }

    DateTimeParamC([string] $Value) {
        $this.Value = $this.ParseDateTime($Value)
    }

    [DateTime] ParseDateTime([string] $Value)
    {
        if (-not $Value) {
            throw "Cannot parse empty string!"
        }

        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::CurrentCulture) }
        catch { }
        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture) }
        catch { }

        [bool]$positive = -not $Value.Contains('-')
        [string]$tempValue = $Value.Replace("-", "").Trim()
        [bool]$date = $tempValue -like "D *"
        if ($date) { $tempValue = $tempValue.Substring(2) }

        [TimeSpan]$timeResult = New-Object System.TimeSpan

        foreach ($element in $tempValue.Split(' '))
        {
            if ($element -match "^\d+$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, $element)))
            }
            elseif ($element -match "^\d+ms$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, 0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+s$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+m$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0)))
            }
            elseif ($element -match "^\d+h$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0)))
            }
            elseif ($element -match "^\d+d$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0, 0)))
            }
            else { throw "Failed to parse as timespan: $Value at $element" }
        }

        [DateTime]$result = [DateTime]::MinValue
        if (-not $positive) { $result = [DateTime]::Now.Add($timeResult.Negate()) }
        else { $result = [DateTime]::Now.Add($timeResult) }

        if ($date) { return $result.Date }
        return $result
    }
}
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamC]$Timestamp
    )
    $Timestamp.Value
}
Get-Test -Timestamp (Get-Date)
Get-Test -Timestamp "1d 8h"
Get-Test -Timestamp "-8h 30m"
Get-Test -Timestamp "D -8h 30m"

# 3. Passing along the input
class DateTimeParamD {
    [DateTime] $Value
    [object] $InputObject

    DateTimeParamD([DateTime] $Value) {
        $this.Value = $Value
        $this.InputObject = $Value
    }

    DateTimeParamD([string] $Value) {
        $this.Value = $this.ParseDateTime($Value)
        $this.InputObject = $Value
    }

    [DateTime] ParseDateTime([string] $Value)
    {
        if (-not $Value) {
            throw "Cannot parse empty string!"
        }

        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::CurrentCulture) }
        catch { }
        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture) }
        catch { }

        [bool]$positive = -not $Value.Contains('-')
        [string]$tempValue = $Value.Replace("-", "").Trim()
        [bool]$date = $tempValue -like "D *"
        if ($date) { $tempValue = $tempValue.Substring(2) }

        [TimeSpan]$timeResult = New-Object System.TimeSpan

        foreach ($element in $tempValue.Split(' '))
        {
            if ($element -match "^\d+$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, $element)))
            }
            elseif ($element -match "^\d+ms$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, 0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+s$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+m$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0)))
            }
            elseif ($element -match "^\d+h$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0)))
            }
            elseif ($element -match "^\d+d$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0, 0)))
            }
            else { throw "Failed to parse as timespan: $Value at $element" }
        }

        [DateTime]$result = [DateTime]::MinValue
        if (-not $positive) { $result = [DateTime]::Now.Add($timeResult.Negate()) }
        else { $result = [DateTime]::Now.Add($timeResult) }

        if ($date) { return $result.Date }
        return $result
    }
}
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamD]$Timestamp
    )
    $Timestamp
}
Get-Test -Timestamp (Get-Date).AddHours(-8).AddMinutes(-30)
Get-Test -Timestamp "-8h 30m"

# 4. The String is the Thing
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamD]$Timestamp
    )
    Write-Host "It is now $Timestamp"
}
Get-Test -Timestamp "-8h 30m"

class DateTimeParamE {
    [DateTime] $Value
    [object] $InputObject

    DateTimeParamE([DateTime] $Value) {
        $this.Value = $Value
        $this.InputObject = $Value
    }

    DateTimeParamE([string] $Value) {
        $this.Value = $this.ParseDateTime($Value)
        $this.InputObject = $Value
    }

    [DateTime] ParseDateTime([string] $Value)
    {
        if (-not $Value) {
            throw "Cannot parse empty string!"
        }

        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::CurrentCulture) }
        catch { }
        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture) }
        catch { }

        [bool]$positive = -not $Value.Contains('-')
        [string]$tempValue = $Value.Replace("-", "").Trim()
        [bool]$date = $tempValue -like "D *"
        if ($date) { $tempValue = $tempValue.Substring(2) }

        [TimeSpan]$timeResult = New-Object System.TimeSpan

        foreach ($element in $tempValue.Split(' '))
        {
            if ($element -match "^\d+$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, $element)))
            }
            elseif ($element -match "^\d+ms$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, 0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+s$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+m$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0)))
            }
            elseif ($element -match "^\d+h$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0)))
            }
            elseif ($element -match "^\d+d$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0, 0)))
            }
            else { throw "Failed to parse as timespan: $Value at $element" }
        }

        [DateTime]$result = [DateTime]::MinValue
        if (-not $positive) { $result = [DateTime]::Now.Add($timeResult.Negate()) }
        else { $result = [DateTime]::Now.Add($timeResult) }

        if ($date) { return $result.Date }
        return $result
    }

    [string] ToString()
    {
        return $this.Value.ToString()
    }
}
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamE]$Timestamp
    )
    Write-Host "It is now $Timestamp"
}
Get-Test -Timestamp (Get-Date).AddHours(-8).AddMinutes(-30)
Get-Test -Timestamp "-8h 30m"

# 5. Let's have some fun with this
class DateTimeParamF {
    [DateTime] $Value
    [object] $InputObject

    DateTimeParamF([DateTime] $Value) {
        $this.Value = $Value
        $this.InputObject = $Value
    }

    DateTimeParamF([string] $Value) {
        $this.Value = $this.ParseDateTime($Value)
        $this.InputObject = $Value
    }

    DateTimeParamF([System.IO.FileSystemInfo] $Value) {
        $this.Value = $Value.LastWriteTime
        $this.InputObject = $Value
    }

    [DateTime] ParseDateTime([string] $Value)
    {
        if (-not $Value) {
            throw "Cannot parse empty string!"
        }

        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::CurrentCulture) }
        catch { }
        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture) }
        catch { }

        [bool]$positive = -not $Value.Contains('-')
        [string]$tempValue = $Value.Replace("-", "").Trim()
        [bool]$date = $tempValue -like "D *"
        if ($date) { $tempValue = $tempValue.Substring(2) }

        [TimeSpan]$timeResult = New-Object System.TimeSpan

        foreach ($element in $tempValue.Split(' '))
        {
            if ($element -match "^\d+$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, $element)))
            }
            elseif ($element -match "^\d+ms$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, 0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+s$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+m$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0)))
            }
            elseif ($element -match "^\d+h$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0)))
            }
            elseif ($element -match "^\d+d$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0, 0)))
            }
            else { throw "Failed to parse as timespan: $Value at $element" }
        }

        [DateTime]$result = [DateTime]::MinValue
        if (-not $positive) { $result = [DateTime]::Now.Add($timeResult.Negate()) }
        else { $result = [DateTime]::Now.Add($timeResult) }

        if ($date) { return $result.Date }
        return $result
    }

    [string] ToString()
    {
        return $this.Value.ToString()
    }
}
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamF]$Timestamp
    )
    Write-Host "It is now $Timestamp"
}
Get-Item F:\Code\Github\P2018-PowerShellSummit-ParameterClasses\powershell\presentation.ps1 | ft Name, LastWriteTime
Get-Test -Timestamp (Get-Item F:\Code\Github\P2018-PowerShellSummit-ParameterClasses\powershell\presentation.ps1)

# A good idea?

# 6. Passing the reins to the user
class DateTimeParamG {
    [DateTime] $Value
    [object] $InputObject

    static [HashTable] $PropertyMapping = @{}

    DateTimeParamG([DateTime] $Value) {
        $this.Value = $Value
        $this.InputObject = $Value
    }

    DateTimeParamG([string] $Value) {
        $this.Value = $this.ParseDateTime($Value)
        $this.InputObject = $Value
    }

    DateTimeParamG([object] $Value) {
        if ($null -eq $Value) { throw 'Hey Gringo, you try converting $null to DateTime!' }

        $this.InputObject = $Value
        $this.Value = $this.ProcessObject($Value)
    }

    hidden [DateTime] ParseDateTime([string] $Value) {
        if (-not $Value) {
            throw "Cannot parse empty string!"
        }

        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::CurrentCulture) }
        catch { }
        try { return [DateTime]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture) }
        catch { }

        [bool]$positive = -not $Value.Contains('-')
        [string]$tempValue = $Value.Replace("-", "").Trim()
        [bool]$date = $tempValue -like "D *"
        if ($date) { $tempValue = $tempValue.Substring(2) }

        [TimeSpan]$timeResult = New-Object System.TimeSpan

        foreach ($element in $tempValue.Split(' '))
        {
            if ($element -match "^\d+$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, $element)))
            }
            elseif ($element -match "^\d+ms$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, 0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+s$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, 0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)))))
            }
            elseif ($element -match "^\d+m$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(0, ([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0)))
            }
            elseif ($element -match "^\d+h$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0)))
            }
            elseif ($element -match "^\d+d$") {
                $timeResult = $timeResult.Add((New-Object System.TimeSpan(([int]([Regex]::Match($element, "(\d+)", "IgnoreCase").Groups[1].Value)), 0, 0, 0)))
            }
            else { throw "Failed to parse as timespan: $Value at $element" }
        }

        [DateTime]$result = [DateTime]::MinValue
        if (-not $positive) { $result = [DateTime]::Now.Add($timeResult.Negate()) }
        else { $result = [DateTime]::Now.Add($timeResult) }

        if ($date) { return $result.Date }
        return $result
    }

    hidden [DateTime] ProcessObject([object] $Value) {
        [PSObject] $object = New-Object PSObject($Value)
        foreach ($name in $object.PSObject.TypeNames) {
            if ([DateTimeParamG]::PropertyMapping.ContainsKey($name)) {
                foreach ($property in [DateTimeParamG]::PropertyMapping[$name]) {
                    try { return (New-Object DateTimeParamG($Value.$property)).Value }
                    catch {}
                }
            }
        }

        throw 'Failed to parse {0} of type <{1}>' -f $Value,$Value.GetType().Name
    }

    [string] ToString() {
        return $this.Value.ToString()
    }
}
[DateTimeParamG]::PropertyMapping["System.IO.FileSystemInfo"] = @("LastWriteTime")
function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamG]$Timestamp
    )
    Write-Host "It is now $Timestamp"
}
Get-Test -Timestamp (Get-Item F:\Code\Github\P2018-PowerShellSummit-ParameterClasses\powershell\presentation.ps1)

# 7. Custom Design
$obj = [PSCustomObject]@{
    PSTypeName = "Foo.Bar"
    Name = "Foo"
    TimeStamp = Get-Date
}
$obj | Get-Member

[DateTimeParamG]::PropertyMapping["Foo.Bar"] = @("TimeStamp")
Get-Test -Timestamp $obj

# All well, is it?
# Not quite ...

 #----------------------------------------------------------------------------# 
 #                       Chapter 2: It's a Sharp world                        # 
 #----------------------------------------------------------------------------# 

Start-RSJob -ScriptBlock {
    function Get-Test {
        [CmdletBinding()]
        param (
            [DateTimeParamG]$Timestamp
        )
        Write-Host "It is now $Timestamp"
    }
    Get-Test -Timestamp (Get-Item F:\Code\Github\P2018-PowerShellSummit-ParameterClasses\powershell\presentation.ps1)
}
Get-RSJob | Receive-RSJob
Get-RSJob | Remove-RSJob

# --> Only in local runspace where defined

<#
C# benefits:
- Process wide
- Better performance
- More language tools!
- Compatible with PowerShell v1+
- ...
#>

# --> Compare the code
code "$presentationRoot\PowerShell\DateTimeSharpA.cs"

function Get-Test {
    [CmdletBinding()]
    param (
        [DateTimeParamG]$Timestamp
    )
    $Timestamp
}
function Get-SharpTest {
    [CmdletBinding()]
    param (
        [DateTimeSharpA]$Timestamp
    )
    $Timestamp
}

# Teach the C# class our awesome new object
#[DateTimeSharpA]::PropertyMapping["Foo.Bar"] = @("TimeStamp")
#TODO: Debug Parameter Class!
Get-Test -Timestamp $obj
Get-SharpTest -Timestamp $obj

<#
Section 2) The world of C#
# 1. Show issues in using PowerShell
2. Parameter class converted
3. Add InFuture property
4. Add operators
#>

<#
Addendum:
1) The design philosophy
2) The contract attributes
3) PSFramework Parameter classes
#>