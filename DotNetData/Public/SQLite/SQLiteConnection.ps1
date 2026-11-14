<# DotNetData/Public/SQLite/SQLiteConnection.ps1

Uses System.Data.SQLite for Desktop / Legacy, Microsoft.Data.Sqlite for Core

System.Data.SQLite

   Install-Package -Name 'System.Data.SQLite' -RequiredVersion '1.0.119' -Scope 'AllUsers' -Force

System.Data.SQLite.SQLiteConnection properties:
PoolCount:                 0
ConnectionString:          DataSource=C:\Users\robsimpson\AppData\Local\Devolutions\RemoteDesktopManager\WebView2.Cache\UI\EBWebView\GPUPersistentCache\DawnGraphiteCache\TLVJWQT6NJWKNBUVMWJ4BCR6DK7MJALX\cache.db
DataSource: 
FileName: 
Database:                  main
GetPasswordCallback: 
DefaultTimeout:            30
DefaultMaximumSleepTime:   150
BusyTimeout:               0
WaitTimeout:               30000
PrepareRetries:            3
StepRetries:               40
ProgressOps:               0
ParseViaFramework:         False
Flags:                     Default
DefaultDbType: 
DefaultTypeName: 
VfsName: 
OwnHandle: 
ServerVersion:             3.46.1
LastInsertRowId: 
Changes: 
AutoCommit: 
MemoryUsed: 
MemoryHighwater: 
Tag: 
State:                     Closed
TraceFlags:                SQLITE_TRACE_NONE
ConnectionTimeout:         15
Site: 
Container: 

SQLiteConnectionStringBuilder properties:
DataSource: 
FileName: 
Version:                   3
SyncMode:                  Normal
UseUTF16Encoding: 
Pooling:                   False
BinaryGUID: 
DataSource: 
Uri: 
FullUri: 
DefaultTimeout:            30
DefaultMaximumSleepTime:   0
BusyTimeout:               0
WaitTimeout:               0
PrepareRetries:            0
StepRetries:               0
ProgressOps:               0
Enlist:                    True
FailIfMissing: 
LegacyFormat:              False
ReadOnly:                  False
Password: 
HexPassword: 
TextPassword: 
TextHexPassword: 
PageSize:                  4096
MaxPageCount:              0
CacheSize:                 -2000
DateTimeFormat:            ISO8601
DateTimeKind:              Unspecified
DateTimeFormatString: 
BaseSchemaName: 
JournalMode:               Default
DefaultIsolationLevel: 
DefaultDbType:             -1
DefaultTypeName: 
VfsName: 
ForeignKeys:               False
RecursiveTriggers:         False
ZipVfsVersion: 
Flags:                     Default
SetDefaults: 
ToFullPath: 
NoDefaultFlags: 
NoSharedFlags: 
BrowsableConnectionString: True
ConnectionString:          datasource=C:\Users\robsimpson\AppData\Local\Devolutions\RemoteDesktopManager\WebView2.Cache\UI\EBWebView\GPUPersistentCache\DawnGraphiteCache\TLVJWQT6NJWKNBUVMWJ4BCR6DK7MJALX\cache.db
Count:                     1
IsReadOnly:                False
IsFixedSize:               False
Keys:                      datasource
Values:                    C:\Users\robsimpson\AppData\Local\Devolutions\RemoteDesktopManager\WebView2.Cache\UI\EBWebView\GPUPersistentCache\DawnGraphiteCache\TLVJWQT6NJWKNBUVMWJ4BCR6DK7MJALX\cache.db
SyncRoot:                  System.Object
IsSynchronized:            False

#>


[Boolean] $Script:firstSQLiteConn = $true

[Data.Common.DbConnectionStringBuilder] $Script:slcsb1 = $NULL

#[int] $Script:DefaultCommandTimeout = 300 # default is 30

<# Test-SQLite

Call before New-SQLiteConnection to load types needed for parameters there.

#>

function Test-SQLite {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([bool])]
   Param(
   )

# Load System.Data.SQLite.dll or Microsoft.Data.Sqlite.dll

   if ($Script:firstSQLiteConn) {
      $Script:firstSQLiteConn = $false

#      [Object] $sqliteConfig = Get-DotNetDataConfiguration -DBMS 'SQLite'

   # Load the DLLs for SQLite

      Import-Dll -UsingAddType -DllDirPath 'C:\Program Files\PackageManagement\NuGet\Packages\Stub.System.Data.SQLite.Core.NetFramework.1.0.119.0\lib\net46' -DllName 'System.Data.SQLite.dll' -Verbose

   } # if ($Script:firstSQLiteConn)

   return $true

}


function New-SQLiteConnection {
   [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'ReadWrite')]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $DataSource,
      [Parameter(ParameterSetName = 'ReadWriteCreate', Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $ReadWriteCreate,
      [Parameter(ParameterSetName = 'ReadWrite', Mandatory = $false, ValueFromPipeline = $false)]
      [Switch] $ReadWrite,
      [Parameter(ParameterSetName = 'ReadOnly', Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $ReadOnly,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CallStackCount = -1
   )

   Begin {

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      if ($CallStackCount -eq -1) {
         $CallStackCount = 2
      }
      else {
         $CallStackCount += 1
      }

      [bool] $ok = Test-SQLite

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:slcsb1 -eq $NULL) {
         [System.Data.SQLite.SQLiteConnectionStringBuilder] $Script:slcsb1 = New-Object -TypeName 'System.Data.SQLite.SQLiteConnectionStringBuilder'
      }

      Initialize-SQLiteConnectionStringBuilder -ConnectionStringBuilder $Script:slcsb1
#      Initialize-MicrosoftSqliteConnectionStringBuilder -ConnectionStringBuilder $Script:slcsb2

         [Management.Automation.CallStackFrame] $csf0 = (gcs)[0]; switch -Exact ($PSCmdlet.ParameterSetName) {

         'ReadWriteCreate' {
#            $Script:slcsb1['ReadOnly'] = $false
         }

         'ReadWrite' {
#            $Script:slcsb1['ReadOnly'] = $false
         }

         'ReadOnly' {
#            $Script:slcsb1['ReadOnly'] = $true
         }

         default {
         # Error Message with location in this module
            [String[]] $msgs = @(
               "ParameterSetName '$($PSCmdlet.ParameterSetName)' not recognized"
               Get-CallStackFunctionAndLocation -CallStackFrame $csf0 -CallStackCount $CallStackCount
            )
            [String] $activity = "switch ('$($PSCmdlet.ParameterSetName)')"
            Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
         }

      }

      [Management.Automation.ErrorRecord] $er = $null
      [string] $activity = [NullString]::Value
      [string[]] $msgs = [string[]]::new(0)

   } # Begin

   Process {

   # When $DataSource is from "-DataSource" parameter, each item in [String[]] $DataSource list is processed separately
   # for each item, return a single connection for just one name in $queue (vs. adding all $DataSource items to $queue at once)

      foreach ($aDataSource in $DataSource) {

         if ($Script:slcsb1 -eq $null) {
            Write-Output -InputObject ([Data.Common.DbConnection] $null)
         } # if ($Script:slcsb1 -eq $null)
         else { # $Script:slcsb1 -ne $null

            $Script:slcsb1['DataSource'] = $aDataSource

            [String] $connstr = $Script:slcsb1.ToString()

            [Management.Automation.CallStackFrame] $csfTry = (gcs)[0]; try {

               [int] $gec = $Global:Error.Count
               [System.Data.SQLite.SQLiteConnection] $conn = New-Object -TypeName 'System.Data.SQLite.SQLiteConnection' ($connstr)

            } # try
            catch [System.TypeInitializationException] {
               [Management.Automation.ErrorRecord] $er = $_
               [String[]] $msgs = @(
                  "New-Object -TypeName 'System.Data.SQLite.SQLiteConnection' ($connstr)"
                  "Exception.InnerException: $($er.Exception.InnerException)"
                  Get-CallStackFunctionAndLocation -CallStackFrame $csfTry -CallStackCount $CallStackCount
               )
               Write-Error -Exception $er.Exception.InnerException -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ConnectionError) -ErrorId 'ErrorId' -TargetObject $connstr -RecommendedAction 'RecommendedAction' -CategoryActivity 'CategoryActivity' -CategoryReason 'CategoryReason' -CategoryTargetName 'CategoryTargetName' -CategoryTargetType 'CategoryTargetType'
               Write-Error -ErrorRecord $er -CategoryActivity $er.CategoryInfo.Activity -CategoryTargetName $er.CategoryInfo.TargetName -CategoryTargetType $er.CategoryInfo.TargetType
               return $null
            }
            catch {
               [Management.Automation.ErrorRecord] $er = $_
               [String[]] $msgs = @(
                  "New-Object -TypeName 'System.Data.SQLite.SQLiteConnection' ($connstr)"
                  "Exception.InnerException: $($er.Exception.InnerException)"
                  Get-CallStackFunctionAndLocation -CallStackFrame $csfTry -CallStackCount $CallStackCount
               )
               Write-Warning -Message ($msgs -join "$([Environment]::NewLine)         ")
               Write-Error -ErrorRecord $er -CategoryActivity $er.CategoryInfo.Activity -CategoryTargetName $er.CategoryInfo.TargetName -CategoryTargetType $er.CategoryInfo.TargetType
               return $null
            } # catch

            try {
               $conn.Open()
               if ($conn.State -ne 'Open') {
                  [String[]] $msgs = @(
                     "conn.Open() with Data Source=${aDataSource}"
                     "Connection.Type             = $($conn.GetType().FullName)"
                     "Connection.State            = $($conn.State)"
                     "Connection.DataSource       = $($conn.DataSource)"
                     "Connection.Database         = $($conn.Database)"
                     "Connection.ConnectionString = $($conn.ConnectionString)"
                     Get-CallStackFunctionAndLocation -CallStackFrame $csf0 -CallStackCount $CallStackCount
                  )
                  Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::OpenError) -CategoryReason 'SQLiteConnection.Open failed' -CategoryTargetName $aDataSource -CategoryTargetType 'DataSource'
               }
            } # try
            catch {
               [Management.Automation.ErrorRecord] $er = $_
               $msgs = @(
                  "[System.Data.SQLite.SQLiteConnection].Open() threw an error"
                  "DataSource: ${aDataSource}"
                  Get-CallStackFunctionAndLocation -CallStackCount $CallStackCount
               )
               [Management.Automation.CallStackFrame] $csf2 = (gcs)[2]
                  # (gcs)[1] is % $DataSource above
               Write-Warning -Message ($msgs -join "$([Environment]::NewLine)         ")
               Write-Error -ErrorRecord $er -CategoryActivity $er.CategoryInfo.Activity -CategoryTargetName $er.CategoryInfo.TargetName -CategoryTargetType $er.CategoryInfo.TargetType
            } # catch

         # Return the Connection regardless of State 'Open' or not

            Write-Output -InputObject $conn

         } # else ($Script:slcsb1 -ne $null)

      } # foreach ($aDataSource in $DataSource)

   } # Process

   End {
   } # End

} # function New-SQLiteConnection
