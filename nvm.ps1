# Config
$Script:root = Split-Path $MyInvocation.MyCommand.Definition
$Script:target = "$root\current"
$Script:arch = if ([Environment]::Is64BitOperatingSystem ) { "x64" } else { "x86" }
$Script:node_mirror = "https://nodejs.org/dist"
$Script:LinkType = "Junction"

# Util
function Script:Parse_Version {
  param (
    [string]$Private:version
  )
  if ($version.StartsWith("V")) {
    $version = $version.Substring(1)
  }
  if (!$version.StartsWith("v")) {
    $version = 'v' + $version
  }
  return $version
}

# Download and Install Node.js
function Script:Install_Node {
  param (
    [string]$Private:version
  )
  $version = Parse_Version $version  

  $Private:fileName = "node-$version-win-$arch.zip"
  $Private:url = "$node_mirror/$version/$fileName"
  $Private:file = "$root\.cache\$fileName"
  $Private:folder = "$root\$version"
  try {
    # Download Node.js Runtime package
    if (!(Test-Path "$root\.cache")) {
      New-Item -ItemType Directory -Path "$root\.cache" | Out-Null
    }
    if ((Test-Path $file)) {
      Remove-Item -Recurse -Force $file
    }
    # Invoke-WebRequest -Uri $url -OutFile $file
    # Invoke-RestMethod -Uri $url -OutFile $file
    Start-BitsTransfer -Source $url -Destination $file
    # Expand Archive
    if ((Test-Path $folder)) {
      Remove-Item -Recurse -Force $folder
    }
    Expand-Archive -Path $file -DestinationPath $folder
    $Private:tmpdir = (Get-ChildItem $folder)[0]
    Get-ChildItem $tmpdir | Move-Item -Destination $folder
    Remove-Item -Recurse -Force $tmpdir
  }
  catch {
    Write-Error $Error
  }
}

# Uninstall Node.js
function Script:UnInstall_Node {
  param (
    [string]$Private:version
  )
  $version = Parse_Version $version  

  $Private:folder = "$root\$version"

  if ((Test-Path $folder)) {
    Remove-Item -Recurse -Force $folder
  }
}

# 
function Script:List_LocalNode {
  Get-ChildItem | Where-Object -Property Mode -Like "d*" | Where-Object -Property Name -Like "v*" | Select-Object Name
  if (Test-Path $target) {
    & "$target\node" "-v" | Write-Host -ForegroundColor Green
  }
}

# Switch Node.js Version
function Script:Use_Node {
  param (
    [string]$Private:version
  )
  $version = Parse_Version $version

  $Private:source = "$root\$version"

  if (!(Test-Path $source)) {
    Write-Host "$version is not be installed." -ForegroundColor Red
    return
  }
  Disable_Node

  New-Item -ItemType $LinkType -Path $target -Value $source | Out-Null
}

# Disable 
function Script:Disable_Node {
  if ((Test-Path $target)) {
    Remove-Item -Recurse -Force $target
  }
}

# Write Help Message
function Script:Help {
  Write-Host "nvm for Windows PowerShell Script v0.0.1"
  Write-Host ""
  Write-Host "Usage:"
  Write-Host ""
  Write-Host "    i or install <version>       : The version can be a node.js version."
  Write-Host "    un or uninstall <version>    : The version must be a specific version."
  Write-Host "    use <version>                : Switch to use the specified version."
  Write-Host "    list                         : List the node.js installations."
  Write-Host "    off                          : Disable node.js version management."
  Write-Host ""
}



# ==Main==
if ($args.Length -le 0) {
  Help
  return
}

if (Test-Path ".\config.conf") {
  $Private:arr = Get-Content .\config.conf
  foreach ($item in $arr) {
    if ($item.StartsWith("#")) {
      continue
    }
    $Private:kv = $item -split "="
    switch ($kv[0].Trim().ToUpper()) {
      "ARCH" { 
        $arch = $kv[1].Trim()
      }
      "NODE_MIRROR" { 
        $node_mirror = $kv[1].Trim()
      }
      # "NPM_MIRROR" { 
      #   $arch = $kv[1].Trim()
      # }
      "TARGET" { 
        $target = $kv[1].Trim()
      }
      "ROOT" { 
        $root = $kv[1].Trim()
      }
      "LinkType" { 
        $LinkType = $kv[1].Trim()
      }
    }
  }
}
switch ($args[0]) {
  "i" { 
    Install_Node $args[1]
  }
  "un" { 
    UnInstall_Node $args[1]
  }
  "install" { 
    Install_Node $args[1]
  }
  "uninstall" { 
    UnInstall_Node $args[1]
  }
  "use" { 
    UnInstall_Node $args[1]
  }
  "list" { 
    List_LocalNode
  }
  "off" { 
    Disable_Node
  }
  Default {
    Help
  }
}