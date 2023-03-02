<#

.SYNOPSIS
Automates the conversion of serialization configuration files to Sitecore Content Serialization configuration files.

.DESCRIPTION
Reads Unicorn XML configuration files and converts them into SCS-compliant configuration files.

#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[Flags()] enum Scope
{
    Ignored = 0
    Item = 1 -shl 0
    Children = 1 -shl 1
    Descendants = 1 -shl 2
}

class EnumExtensions {
    
    static [System.Int32] Add([System.Int32] $opI, [System.Int32] $opII)
    {
        while ($opII -ne 0)
        {
            [System.Int32] $c = $opI -band $opII

            $opI = $opI -bxor $opII

            $opII = $c -shl 1
        }
        return $opI
    }

}

class SerializationItem {
    
    [System.String]
    $Name

    [System.String]
    $Path

    [System.String]
    $Database

    [System.Enum]
    $Scope

    [System.Collections.ArrayList]
    $Rules = [System.Collections.ArrayList]@()

    SerializationItem(){}
    
    SerializationItem([System.String] $name, [System.String] $path, [System.String] $database)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
        $this.Scope = [Scope]([EnumExtensions]::Add([Scope]::Item, [Scope]::Descendants))
    }

    SerializationItem([System.String] $name, [System.String] $path, [System.String] $database, [System.Enum] $scope)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
        $this.Scope = $scope
    }

    SerializationItem([System.String] $name, [System.String] $path, [System.String] $database, [System.Enum] $scope, [System.Collections.ArrayList] $rules)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
        $this.Scope = $scope
        $this.Rules = $rules
    }

    static [System.String] GetScope([System.Enum] $scopeEnum)
    {
        [System.String]
        $scopeString = [System.String]::Empty

        switch ($scopeEnum)
        {
            {($scopeEnum) -eq [Scope]::Ignored}
            {
                $scopeString = "Ignored"
                break
            }
            {($scopeEnum) -eq [Scope]::Item}
            {
                $scopeString = "SingleItem"
                break
            }
            {($scopeEnum) -eq [Scope]::Descendants}
            {
                $scopeString = "DescendantsOnly"
                break
            }
            {(($scopeEnum -band [Scope]::Descendants) -eq [Scope]::Descendants) -and  (($scopeEnum -band [Scope]::Item) -eq [Scope]::Item)}
            {
                $scopeString = "ItemAndDescendants"
                break
            }
            {(($scopeEnum -band [Scope]::Children) -eq [Scope]::Children) -and  (($scopeEnum -band [Scope]::Item) -eq [Scope]::Item)}
            {
                $scopeString = "ItemAndChildren"
                break
            }
            default
            {
                $scopeString = "ItemAndDescendants"
            }
        }

        return $scopeString

    }

    [System.Boolean] IsValidPath([System.String] $path)
    {
        if ($null -ne $path)
        {
            return ($path -match [Constants]::PathRegexPattern)
        }

        return $false;
    }
}

class SerializationRules {
    
    [System.String]
    $Path

    [System.Enum]
    $Scope

    [System.String]
    $Alias = [System.String]::Empty

    SerializationRules(){}
    
    SerializationRules([System.String] $path, [System.String] $scope)
    {
        $this.Path = $path
        $this.Scope = $scope
    }

    SerializationRules([System.String] $path, [System.Enum] $scope, [System.String] $alias)
    {
        $this.Path = $path
        $this.Scope = $scope
        $this.Alias = $alias
    }

    [System.Boolean] IsValidPath([System.String] $path)
    {
        if ($null -ne $path)
        {
            return ($path -match [Constants]::PathRegexPattern)
        }

        return $false;
    }

}

class SerializationModule {
        
    [System.String]
    $Namespace
    
    [System.Collections.ArrayList]
    $References = [System.Collections.ArrayList]@()

    [System.Collections.ArrayList]
    $Items = [System.Collections.ArrayList]@()

    [System.String]
    $FileProperties
    
    SerializationModule(){}
    
    SerializationModule([System.String] $namespace, [System.String] $references)
    {
        $this.Namespace = $namespace
        $this.References = $references.Split([Constants]::Delimiter.Default)
    }
    
    [System.Boolean] IsNotNullAndEmpty([System.Collections.ArrayList] $items)
    {
        if ($null -ne $items -and @($items).count -gt 0)
        {
            return $true;
        }

        return $false;
    }
}

class FileExtensions {

    [System.String]
    $Name

    [System.String]
    $FullName

    [System.String]
    $DirectoryName
    
    FileExtensions(){}
    
    FileExtensions([System.String] $name, [System.String] $fullName, [System.String] $directoryName)
    {
        $this.Name = $name
        $this.FullName = $fullName
        $this.DirectoryName = $directoryName
    }

    static [System.String] CreateFileName([System.String] $name, [System.String] $fullName)
    {
        return (Split-Path -Parent $fullName) + "\" + ($name -replace ".config", ".json")
    }
    
}


function Read-Serialization {
    param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourcePath,
        
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty]
        [System.String]
        $Filter
    )

    [System.Collections.ArrayList] 
    $serializationItems = [System.Collections.ArrayList]@()

    Get-ChildItem -Path $SourcePath -Filter $Filter -Recurse | ForEach-Object {
        
        Write-Information -MessageData "Reading serialization file at $($_.Directory.FullName) ..." -InformationAction Continue
        
        [System.Xml.XmlElement] 
        $configurationElement = (Select-Xml -Path $_.FullName -XPath /configuration/descendant::configuration).Node

        [SerializationModule] 
        $serializationModule = [SerializationModule]::new($configurationElement.Name, $configurationElement.Dependencies)

        $serializationModule.FileProperties = [FileExtensions]::CreateFileName($_.Name, $_.FullName, $_.DirectoryName)

        [System.Object[]] $configurationElement.Predicate.Include | ForEach-Object {
                    
            [SerializationItem] 
            $serializationItem = [SerializationItem]::new($_.Name, $_.Path, $_.Database)

            if ($null -ne $_.Exclude)
            {
                $serializationItem.Scope = [Scope]::Item
            }
            else
            {
                $serializationItem.Scope = [EnumExtensions]::Add([System.Int32] [Scope]::Item, [System.Int32] [Scope]::Descendants)
            }
             
            [System.Collections.ArrayList] 
            $serializationModule.Items.Add($serializationItem)
        
        }

        [System.Collections.ArrayList] 
        $serializationItems.Add($serializationModule)

    }

    return $serializationItems

}

function Write-Serialization {
    param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DestinationPath,

        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList]
        $SerializationItems
    )

    Write-Information "Writing serialization file(s) to $($DestinationPath)..." -InformationAction Continue

    [System.Collections.ArrayList] $SerializationItems | ForEach-Object {
        
        $serializationObject = New-Object -TypeName PSObject
        
        $serializationObject | Add-Member -MemberType NoteProperty -Name namespace -Value $_.Namespace

        $serializationObject | Add-Member -MemberType NoteProperty -Name references -Value $_.References

        $serializationItems = New-Object -TypeName System.Collections.ArrayList

        foreach ($item in $SerializationItems.Items)
        {
            $serializationItem = New-Object -TypeName PSObject

            $serializationItem | Add-Member -MemberType NoteProperty -Name name -Value $_.Name
            $serializationItem | Add-Member -MemberType NoteProperty -Name path -Value $_.Path
            $serializationItem | Add-Member -MemberType NoteProperty -Name database -Value $_.Database
            
            if ($null -ne $_.Scope)
            {
                $serializationItem | Add-Member -MemberType NoteProperty -Name scope -Value [SerializationItem]::GetScope($_.Scope)
            }

            $serializationItems.Add($serializationItem)
        }
        
        $serializationPredicates = New-Object -TypeName PSObject

        $serializationPredicates | Add-Member -MemberType NoteProperty -Name includes -Value $serializationItems

        $serializationObject | Add-Member -MemberType NoteProperty -Name items -Value $serializationPredicates

        $serializationObject | ConvertTo-Json -Depth 5 | Out-File $_.FileProperties
    }
}


function Convert-Serialization {
    [CmdletBinding(DefaultParameterSetName='Path',
                   PositionalBinding=$false,
                   SupportShouldProcess,
                   ConfirmImpact='High')]
    param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DestinationPath,
        
        [Parameter(Mandatory=$true,
                   Position=2,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty]
        [System.String]
        $Filter
    )

    begin 
    {
        $Error.Clear()

        try
        {
            if (-not [bool](Resolve-Path -Path $SourcePath -ErrorAction Ignore))
            {
                throw (New-Object -TypeName System.IO.DirectoryNotFoundException -ArgumentList "Could not find path: $($SourcePath)")
            }
            if (-not [bool](Resolve-Path -Path $DestinationPath -ErrorAction Ignore))
            {
                throw (New-Object -TypeName System.IO.DirectoryNotFoundException -ArgumentList "Could not find path: $($DestinationPath)")
            }

        }
        catch [System.IO.DirectoryNotFoundException]
        {
            Write-Error "The path or file was not found: $($PSItem.Exception)" -RecommendedAction "Enter valid path." -ErrorAction Stop
        }

    }

    process
    {
        Read-Serialization -SourcePath $SourcePath -Filter $Filter | Write-Serialization -DestinationPath $DestinationPath -Items $_
    }

    end
    {
        Write-Information -MessageData "Completed: See serialization files at the destination path:$($DestinationPath)." -InformationAction Stop
    }

}

class Constants {
    
    static [System.String] 
    $PathRegexPattern = "(^/[a-z0-9\s]+)(/[a-z0-9-\s]+)*([a-z0-9\s])$"

    static [System.Collections.Hashtable]
    $Delimiter = @{Default = [System.Char]0x002C}
}
