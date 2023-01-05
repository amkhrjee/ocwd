<p align="center">
<!--<img src="scoop.png" alt="Long live Scoop!"/>-->
    <h1 align="center">ocwd</h1>
</p>
<p align="center" >
   <img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/amkhrjee/ocwd">
    <img alt="GitHub" src="https://img.shields.io/github/license/amkhrjee/ocwd">
    <img alt="platform" src="https://img.shields.io/powershellgallery/p/ocwd.svg">
    <img alt="PowerShell Gallery Version" src="https://img.shields.io/powershellgallery/v/ocwd">
    <img alt="PowerShell Gallery" src="https://img.shields.io/powershellgallery/dt/ocwd">
</p>

## What does `ocwd` do?
`ocwd` is a command line utility that downloads resources from any [MIT OCW](https://ocw.mit.edu/) course to any storage path provided by you. The resources are available under the creative commons license and MIT reserves all rights to the content. This tool simply scrapes the OCW website for resources and offers a simple and easy way for downloading any course resource for offline use.
## Installation Guide
> This script only works on 🪟Windows.

`ocwd` requires Microsoft's cross-platform [PowerShell-Core](https://github.com/PowerShell/PowerShell/), if you don't have it already installed, read their [installation guide](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3).

This tool works best with PowerShell-Core `v7.x.x`. That means, it is recommended to update your PS installation to the latest available version. 

If you are installing a script for the first time, the following instructions will help you get started, otherwise you can skip ahead to the installation script. 

With the latest version available, we need to set the `ExecutionPolicy` to `RemoteSigned` as the default one is unsuitable for running user downloaded script. 
Next, we need to set [PSGallery](https://www.powershellgallery.com/packages/ocwd) as a trusted source for our scripts, as `ocwd` is hosted at PSGallery repository. 

To do this, start PowerShell 7 in *Administartor Mode* and type/paste the following:
```ps1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

Finally, paste the following in your PowerShell terminal to install `ocwd` to your system.
```ps1
Install-Script -Name ocwd
```
## Demo 
<img src="https://i.imgur.com/ODutHXm.gif" />

![demo image](https://i.imgur.com/1yPPAng.png)

If the GIF is not working, you can watch this demo  video instead: https://www.youtube.com/watch?v=9Oe9vrEQY28
