<#

.SYNOPSIS

Automates the configuration of content serialization configuration files.

.DESCRIPTION

This will find an existing Unicorn XML configuration file and convert it to an SCS-complaint configuration file.

#>

[Flags()] enum Scope
{
    Ignored = 0
    Item = 1 -shl 0
    Children = 1 -shl 1
    Descendants = 1 -shl 2
}

class SerialzationItem {
    
    [System.String]
    $Name

    [System.String]
    $Path

    [System.String]
    $Database

    [System.Enum]
    $Scope = [Scope]::Item -band [Scope]::Descendants

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

        return false;
    }
}

class SerializationRules {
    
    [System.String]
    $Path

    [System.Enum]
    $Scope

    [System.String]
    $Alias

    SerializationRules(){}
    
    SerializationRules([System.String] $name, [System.String] $path, [System.String] $database)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
    }

    SerializationRules([System.String] $name, [System.String] $path, [System.String] $database, [System.Collections.ArrayList] $rules)
    {
        $this.Name = $name
        $this.Path = $path
        $this.Database = $database
        $this.Rules = $rules
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
