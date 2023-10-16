<p align="center">
    <h1 align="center">ocwd</h1>
    <p align = "center">Bulk download courses at a press of a button 🗃️</p>
</p>
<p align="center" >
   <img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/amkhrjee/ocwd">
    <img alt="GitHub" src="https://img.shields.io/github/license/amkhrjee/ocwd">
    <img alt="PowerShell Gallery" src="https://img.shields.io/powershellgallery/p/ocwd?color=white">
    <img alt="PowerShell Gallery Version" src="https://img.shields.io/powershellgallery/v/ocwd">
    <img alt="PowerShell Gallery" src="https://img.shields.io/powershellgallery/dt/ocwd">
</p>

## What does `ocwd` do?
`ocwd` is a command line utility that downloads resources at bulk from any [MIT OCW](https://ocw.mit.edu/) course to any storage path provided by you, with just one key press! 

The resources are available under the creative commons license and MIT reserves all rights to the content. This tool simply scrapes the OCW website for resources and offers a simple and easy way for downloading any course resource for offline use.
## Installation Guide

### Windows
`ocwd` works with both [Windows PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7.3) and the cross-platform [PowerShell-Core](https://learn.microsoft.com/en-us/powershell/scripting/overview?view=powershell-7.3). 

All recent versions of Windows 10 & 11 already come with Windows PowerShell installed (search for `PowerShell` using Windows Search to find out whether you have it or not). However, you can also follow the installation guides provided here in case you don't have PowerShell installed. 

<details>
<summary>
 <h3>PowerShell Installation Guide for Windows</h3> 
</summary>
PowerShell comes in two flavours - PowerShell Windows and PowerShell-Core. You are recommened to download PS-Core, as it is the one in active development by Microsoft and thus have the latest features. `ocwd` downloads work faster with PS-Core (thanks to multi-threading!)

<br>

### PowerShell Core Installation Guide
You can read the official installtion guide here.

PowerShell Core is a cross-platform version of PowerShell that is open-source and available on Windows, macOS, and Linux. Here is a guide to install PowerShell Core on your system:

1. First, visit the following link to download the latest version of PowerShell Core: https://github.com/powershell/powershell/releases

2. Select the appropriate download link for your system. For example, if you are running Windows, select the MSI installer link. If you are running macOS or Linux, select the appropriate package for your system.

3. Once the download is complete, open the installer file and follow the prompts to install PowerShell Core on your system.

4. Once the installation is complete, you can launch PowerShell Core by opening a terminal window and typing `pwsh`.

To verify that PowerShell Core has been installed correctly, you can run the following command:

```ps1
$PSVersionTable
```
This should display information about the version of PowerShell Core that you have installed.

That's it! You have now installed PowerShell Core on your system. You can start using PowerShell Core by typing commands into the terminal window.

### Windows PowerShell Installation Guide

Windows PowerShell is a command-line shell and scripting language that is included with Windows by default. Here is a guide to install Windows PowerShell:

1. Check if Windows PowerShell is already installed on your system. To do this, open the Start menu and search for "PowerShell". If PowerShell is installed, you should see it listed in the search results.

2. If Windows PowerShell is not installed on your system, you can install it by following these steps:

#### On Windows 10/11:

- Go to the Start menu and select "Settings".
- Select "Apps" from the settings menu.
- Click on "Apps & features" from the left menu.
- Click on the "Manage optional features" button.
- Click on the "Add a feature" button.
- Scroll down the list of features and select "Windows PowerShell".
- Click the "Install" button to begin the installation process.

#### On Windows 7:

- Go to the following link to download the Windows Management Framework (WMF) installer: https://www.microsoft.com/en-us/download/details.aspx?id=54616
- Once the download is complete, open the installer file and follow the prompts to install WMF on your system. This will install Windows PowerShell on your system.

3. Once the installation is complete, you can launch Windows PowerShell by opening the Start menu and searching for "PowerShell".

4. To verify that Windows PowerShell has been installed correctly, you can run the following command:
```ps1
$PSVersionTable
```

This should display information about the version of Windows PowerShell that you have installed.

That's it! You have now installed Windows PowerShell on your system. You can start using Windows PowerShell by typing commands into the terminal window.
</details>

### Linux
The cross-platform PowerShell-Core is required for this. The official and detailed installation guide can be found [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3). 

### MacOS
The detailed installation guide for PowerShell-Core is given [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.3) by Microsoft.

<hr>

If you have PowerShell installed, we can proceed to install `ocwd`.

`ocwd` is currently available via Microsoft's [PSGallery](https://www.powershellgallery.com/packages/ocwd/2.5.0). If you have installed external scripts before, you can skip to the installation script, otherwise, open PowerShell in Administrator Mode and paste the following in order: 

```ps1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```
```ps1
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```
This will install `ocwd` to your system:
```ps1
Install-Script -Name ocwd
```

After the installation is over, you are suggested to close and reopen your terminal for reloading the shell.



## Usage
There are two ways to use `ocwd`:
```ps1
ocwd your_link_here
```
or just type in the command:
```ps1
ocwd
```
## Demo 
<!-- <img src="https://i.imgur.com/ODutHXm.gif" /> -->

![demo image](https://i.imgur.com/1yPPAng.png)

If the GIF is not working, you can watch this demo  video instead: https://www.youtube.com/watch?v=9Oe9vrEQY28
