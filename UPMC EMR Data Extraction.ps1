# Script for extracting data out of UPMC's EPIC instance

<#
.SYNOPSIS
  Extracts data from an EMR SQL Server database and exports to CSV.

.DESCRIPTION
  Connects using either Windows Integrated Security or SQL Authentication,
  runs one or more parameterized queries, and exports results to CSV files.

.PARAMETER Server
  SQL Server name (optionally instance), e.g., "SQL01\EMR".

.PARAMETER Database
  Database name, e.g., "EMR_Prod".

.PARAMETER Credential
  (Optional) PSCredential for SQL auth. If omitted, uses Integrated Security.

.PARAMETER OutputFolder
  Folder where result files and logs are written.

.PARAMETER DaysBack
  Optional rolling window for date filters (applied to queries that support it).

.PARAMETER QueryPreset
  Logical set of queries to run (e.g., "CoreClinical", "RevenueCycle").
  You can also use -QueryFile for custom SQL.

.PARAMETER QueryFile
  Path to a single .sql file to execute (overrides QueryPreset).

.PARAMETER MaxRetry
  Number of connection execution retries on failure.

.NOTES
  Author: Your Name
  Version: 1.0
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$Server,

  [Parameter(Mandatory=$true)]
  [string]$Database,

  [Parameter(Mandatory=$false)]
  [System.Management.Automation.PSCredential]$Credential,

  [Parameter(Mandatory=$true)]
  [string]$OutputFolder,

  [Parameter(Mandatory=$false)]
  [int]$DaysBack = 0,

  [Parameter(Mandatory=$false)]
  [ValidateSet("CoreClinical","RevenueCycle","Scheduling","All")]
  [string]$QueryPreset = "CoreClinical",

  [Parameter(Mandatory=$false)]
  [string]$QueryFile,

  [Parameter(Mandatory=$false)]
  [int]$CommandTimeoutSeconds = 600,

  [Parameter(Mandatory=$false)]
  [int]$MaxRetry = 2
)

begin {
  # Ensure output folder exists
  if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
  }

  $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
  $logPath   = Join-Path $OutputFolder "Export_EMR_$timestamp.log"

  function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "{0} [{1}] {2}" -f (Get-Date -Format o), $Level.ToUpper(), $Message
    $entry | Tee-Object -FilePath $logPath -Append
  }

  Write-Log "Starting EMR data export. Server=$Server; DB=$Database; Preset=$QueryPreset; DaysBack=$DaysBack"

  # Utility: Execute a query and stream results to CSV
  function Invoke-SqlQueryToCsv {
    param(
      [Parameter(Mandatory=$true)][string]$Query,
      [Parameter(Mandatory=$true)][string]$OutputCsv,
      [Parameter(Mandatory=$false)][hashtable]$SqlParameters
    )

    # We'll use System.Data.SqlClient for broad compatibility
    Add-Type -AssemblyName "System.Data"

