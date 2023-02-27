<#

.SYNOPSIS

Automates the installation of Hyper-V. Works on either Pro or Home editions

.DESCRIPTION

This will force an automatic reboot and will pick up where it left off to
complete the configuration.

#>

enum Scopes
{
    SingleItem = 0
    ItemAndChildren = 1
    ItemAndDescendants = 2
    DescendantsOnly = 3
    Ignored = 4
}

class SerialzationItem {
    
    [System.String]
    $Name

    [System.String]
    $Path

    [System.String]
    $Database

    [System.String]
    $Scope = [System.String]::Empty

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

    [System.Boolean] IsValidPath([System.String] $path)
    {
        if ($null -ne $path)
        {
            return ($path -match [Constants]::PathRegexPattern)
        }

        return false;
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
            return true;
        }

        return false;
    }
}


function Convert-Serialization {
    param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Path
    )

}

Begin
{
}

Process 
{
}

class Constants {
    
    static [System.String] 
    $PathRegexPattern = "(^/[a-z0-9\s]+)(/[a-z0-9-\s]+)*([a-z0-9\s])$"
}
