# powerAPS-UI

[![Windows](https://img.shields.io/badge/Platform-Windows-lightgray.svg)](https://www.microsoft.com/en-us/windows/)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20|%207.4-blue.svg)](https://microsoft.com/PowerShell/)
[![coolOrange powerJobs](https://img.shields.io/badge/powerJobs%20Processor-26.0.4+-orange.svg)](https://doc.coolorange.com/projects/powerjobsprocessor/en/stable/)
[![coolOrange powerEvents](https://img.shields.io/badge/powerJobs%20Client-26.0.7+-orange.svg)](https://doc.coolorange.com/projects/powerevents/en/stable/)
[![Autodesk Platform Services](https://img.shields.io/badge/Autodesk%20Platform%20Services-API-blue.svg)](https://aps.autodesk.com/)

![powerAPS-UI](https://github.com/user-attachments/assets/34d4cf6c-feab-4fd5-bad1-2ab74cde9331)

## Disclaimer

THE SAMPLE CODE ON THIS REPOSITORY IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

THE USAGE OF THIS SAMPLE IS AT YOUR OWN RISK AND **THERE IS NO SUPPORT** RELATED TO IT.

---

## Description

This repository provides the **User Interface component** of the powerAPS ecosystem for **Autodesk Vault Professional**. It delivers comprehensive UI dialogs and menu extensions that enable users to configure and interact with **Autodesk Platform Services (APS)** directly from within the Vault client.

The powerAPS-UI component provides the front-end interface for connecting Autodesk Vault with cloud services including **Autodesk Construction Cloud (ACC)**, **BIM 360**, and **Fusion**. It offers intuitive dialogs for authentication, project mapping, and content management.

---

## Prerequisites

> **Note**: powerEvents version **26.0.7** or greater is required for this UI component to function properly.

This UI component requires:

- **powerAPS-Modules** - Core PowerShell modules for APS communication
- **powerEvents (powerJobs Client)** installed on each Autodesk Vault **Client machine**
- Autodesk Vault Professional 2023 or later

---

## Related Repositories

- **[powerAPS-Modules](https://github.com/coolOrange-Public/powerAPS-Modules)** - Core PowerShell modules for APS API communication

The **powerAPS-UI** component depends on **powerAPS-Modules** for APS connectivity.

---

## Installation

> **Important**: Files downloaded from GitHub may be blocked by Windows. You must **unblock all files** before installation:
> 1. Right-click each downloaded file → **Properties**
> 2. Check **"Unblock"** at the bottom → **Apply** → **OK**
> 3. Or use PowerShell: `Get-ChildItem -Recurse | Unblock-File`
> 

1. **Close** Autodesk Vault Explorer completely
2. **Download or clone** this repository
3. **Unblock all downloaded files** (see important note above)
4. **Install powerAPS-Modules** first (this is a required dependency)
5. **Copy all files** from this repository to:  
   `C:\ProgramData\coolOrange\Client Customizations\`
6. **Restart** Vault Explorer to load the new UI components

---

## Feature Overview

The powerAPS-UI component adds comprehensive cloud integration capabilities to Autodesk Vault through intuitive user interface elements.

---

### Tools Menu Features

The following configuration options are available in the **Tools** menu under **"Autodesk Cloud Settings"**:

#### **Authentication Settings...**
- Configure APS API credentials (Client ID, Client Secret)
- Set up OAuth callback URL and scopes
- Enable/disable PKCE (Proof Key for Code Exchange) authentication

#### **Vault Folder Settings...**
- Define default project mapping behaviors
- Set category assignments for cloud-connected folders
- Configure hub, project, and folder associations

#### **Default Account...**
- Select the default ACC/BIM 360 hub for new connections
- Streamline project selection workflow

---

### Folder Context Menu Features

Right-click any Vault folder to access **"ACC"** submenu options:

#### **Assign ACC Project to Folder...**
- Link a Vault folder to a specific ACC project
- Browse and select from available hubs and projects
- Automatically apply configured category and properties to link the ACC project to the selected Vault folder

#### **Edit Attribute Mappings...**
- Configure how Vault file properties map to ACC attributes
- Define custom mapping rules per folder

#### **Go To ACC Docs Project...**
- Quick navigation to linked ACC Docs project
- Opens web browser directly to project files

#### **Go To ACC Build Project...**
- Direct access to linked ACC Build project
- Opens web browser to project build interface

---

### Authentication Flow

The UI component provides a seamless OAuth 2.0 authentication experience:

1. **Initial Configuration**: Set up APS credentials in Tools menu
2. **Automatic Login**: Integration with Vault's Autodesk ID authentication  
3. **Token Management**: Transparent token refresh and validation

---

### Dialog Components

The repository includes sophisticated WPF dialogs:

- **Authentication Dialog**: OAuth setup and credential management
- **Project Settings Dialog**: Vault folder configuration to tell Vault how to identify linked ACC projects 
- **Content Selection Dialog**: Hierarchical folder browsing
- **Attribute Mapping Dialog**: Property mapping configuration
- **Hub and Project Selection Dialogs**: Dialogs to select Hubs and ACC projects from within Vault

---

## End-to-End Integration

This UI component enables users to:

1. **Configure cloud connections** through intuitive settings dialogs
2. **Map Vault folder structures** to ACC/BIM 360 projects  
3. **Set up property synchronization** between Vault and cloud platforms
4. **Navigate seamlessly** between Vault and cloud interfaces
5. **Prepare folders** for automated publishing workflows (requires powerAPS-Jobs)

---

## Support and Documentation

For additional information:
- **COOLORANGE Documentation**: https://doc.coolorange.com
- **powerAPS Reference**: https://doc.coolorange.com/projects/poweraps/en/stable/  
- **APS Developer Portal**: https://aps.autodesk.com/