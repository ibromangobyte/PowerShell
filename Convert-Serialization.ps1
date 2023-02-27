<#

.SYNOPSIS
Automates the configuration of content serialization configuration files.

.DESCRIPTION
Reads Unicorn XML configuration files and converts them into SCS-compliant configuration files.

#>

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

class SerialzationItem {
    
    [System.String]
    $Name

    [System.String]
    $Path

    [System.String]
    $Database

    [System.Enum]
    $Scope = [Scope]::Item + [Scope]::Descendants

    [System.Collections.ArrayList]
    $Rules = @()

    SerialzationItem(){}
    
    SerialzationItem([System.String] $name, [System.String] $path, [System.String] $database)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
    }

    SerialzationItem([System.String] $name, [System.String] $path, [System.String] $database, [System.String] $scope)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
        $this.Scope = $scope
    }

    SerialzationItem([System.String] $name, [System.String] $path, [System.String] $database, [System.String] $scope, [System.Collections.ArrayList] $rules)
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

    SerializationRules([System.String] $path, [System.String] $scope, [System.String] $alias)
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
        
    [System.Object]
    $Namespace
    
    [System.Collections.ArrayList]
    $References = @()

    [System.Collections.ArrayList]
    $Items = @()
    
    SerializationModule(){}
    
    SerializationModule([System.String] $namespace, [System.Collections.ArrayList] $references, [System.Collections.ArrayList] $items)
    {
        $this.Namespace = $namespace
        $this.References = $references
        $this.Items = $items
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
        $Path
    )

    Write-Information "Reading serialization file at $($Path)..." -InformationAction Continue

    return (Select-Xml -Path $Path -XPath /)

}

function Write-Serialization {
    param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    Write-Information "Writing serialization file to $($Path)..." -InformationAction Continue

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
        $Path
    )

    begin 
    {
        <# Tasks that are completed once #>
        Read-Serialization | ForEach -Parallel {

        }

    }

    process
    {
        <# Routine tasks #>

    }


}


class Constants {
    
    static [System.String] 
    $PathRegexPattern = "(^/[a-z0-9\s]+)(/[a-z0-9-\s]+)*([a-z0-9\s])$"
}
