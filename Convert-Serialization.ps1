<#

.SYNOPSIS
Automates the configuration of content serialization configuration files.

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
        
        Write-Information "Reading serialization file at $($_.Directory.FullName) ..." -InformationAction Continue
        
        [System.Xml.XmlElement] 
        $configurationElement = (Select-Xml -Path $_.FullName -XPath /configuration/descendant::configuration).Node

        [SerializationModule] 
        $serializationModule = [SerializationModule]::new($configurationElement.Name, $configurationElement.Dependencies)


        [System.Object[]] $configurationElement.Predicate.Include | ForEach-Object {
                    
            [SerializationItem] 
            $serializationItem = [SerializationItem]::new($_.Name, $_.Path, $_.Database)
             
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
        $Items
    )

    Write-Information "Writing serialization file to $($DestinationPath)..." -InformationAction Continue

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

        Read-Serialization -SourcePath $SourcePath -Filter $Filter

    }

    process
    {
        Write-Serialization -DestinationPath $DestinationPath
    }

}


class Constants {
    
    static [System.String] 
    $PathRegexPattern = "(^/[a-z0-9\s]+)(/[a-z0-9-\s]+)*([a-z0-9\s])$"

    static [System.Collections.Hashtable]
    $Delimiter = @{Default = [System.Char]0x002C}
}
