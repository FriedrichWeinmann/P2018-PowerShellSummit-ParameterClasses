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