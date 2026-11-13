<# Public/SqlServer/PublicFunctionsForSSIDB.ps1

Integration Services Catalog (SSISDB) Views
   https://learn.microsoft.com/en-us/sql/integration-services/system-views/views-integration-services-catalog

   catalog.catalog_properties (SSISDB Database)
      Displays the properties of the Integration Services catalog.

 X catalog.effective_object_permissions (SSISDB Database)
      Displays the effective permissions for the current principal for all objects in the Integration Services catalog.

   catalog.environment_variables (SSISDB Database)
      Displays the environment variable details for all environments in the Integration Services catalog.

   catalog.environments (SSISDB Database)
      Displays the environment details for all environments in the Integration Services catalog. Environments contain variables that can be referenced by Integration Services projects.

   catalog.execution_parameter_values (SSISDB Database)
      Displays the actual parameter values that are used by Integration Services packages during an instance of execution.

   catalog.executions (SSISDB Database)
      Displays the instances of package execution in the Integration Services catalog. Packages that are executed with the Execute Package task run in the same instance of execution as the parent package.

   catalog.explicit_object_permissions (SSISDB Database)
      Displays only the permissions that have been explicitly assigned to the user.

   catalog.extended_operation_info (SSISDB Database)
      Displays extended information for all operations in the Integration Services catalog.

   catalog.folders (SSISDB Database)
      Displays the folders in the Integration Services catalog.

   catalog.object_parameters (SSISDB Database)
      Displays the parameters for all packages and projects in the Integration Services catalog.

   catalog.object_versions (SSISDB Database)
      Displays the versions of objects in the Integration Services catalog. In this release, only versions of projects are supported in this view.

   catalog.operation_messages (SSISDB Database)
      Displays messages that are logged during operations in the Integration Services catalog.

   catalog.operations (SSISDB Database)
      Displays the details of all operations in the Integration Services catalog.

   catalog.packages (SSISDB Database)
      Displays the details for all packages that appear in the Integration Services catalog.

   catalog.environment_references (SSISDB Database)
      Displays the environment references for all projects in the Integration Services catalog.

   catalog.projects (SSISDB Database)
      Displays the details for all projects that appear in the Integration Services catalog.

   catalog.validations (SSISDB Database)
      Displays the details of all project and package validations in the Integration Services catalog.

   catalog.master_properties (SSISDB Database)
      Displays the properties of the Integration Services Scale Out Master.

   catalog.worker_agents (SSISDB Database)
      Displays the information of Integration Services Scale Out Worker.

Relationships

-- Configuration

   catalog.catalog_properties

   catalog.master_properties - SQL Server 2017+

   catalog.worker_agents

-- Objects / Environments

   folders
      -> projects
         -> packages
         -> object_versions
         -> object_parameters
         -> environment_references
            -> environments

   environments
      -> environment_variables

-- Permissions

   catalog.explicit_object_permissions
   catalog.catalog_users
   catalog.catalog_groups
   sys.database_principals

-- Executions

   executions.execution_id
      execution_parameter_values.execution_id

-- Validations / Operations

   validations.validation_id
      operations.operation_id
         operation_messages.operation_id

-- Event Messages

   event_messages.event_message_id
      event_message_context.event_message_id

-- Performance

   executions
      -> executable_statistics
         -> execution_data_statistics
            -> execution_component_phases

   catalog.execution_data_taps
   
   catalog.execution_property_override_values

#>


[int] $Script:DefaultCommandTimeout = 30
[int] $Script:LongCommandTimeout = 600


function Test-WriteError {
   [CmdletBinding()]
   [OutputType([string])]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateCount(2, 2)]
      [string[]] $InputObject
   )

   Begin {
   }

   Process {
      $InputObject | % {
         [string] $str = $_
         if ($str -eq 'Error') {
            [Management.Automation.ErrorRecord] $errorRecord = [System.Management.Automation.ErrorRecord]::new(
               [Exception]::new("Test error"),
               'TestId',
               [Management.Automation.ErrorCategory]::NotSpecified,
               $null
            )
            $PSCmdlet.WriteError($errorRecord)
         }
         Write-Warning -Message $str
      }
   }

   End {
      return 'Test'
   }

}


<# catalog_properties and master_properties
#>

function New-DataAdapterForSSISProperties {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.Common.DbDataAdapter[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:DefaultCommandTimeout,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      if ($CallStackFrame -eq $NULL) {
         $CallStackFrame = (gcs)[1]
      }

      [Collections.Generic.List[Data.Common.DbDataAdapter]] $dataAdapterList = New-Object -TypeName 'Collections.Generic.List[Data.Common.DbDataAdapter]'
      [bool] $first = $true
      [string] $firstConnType = [NullString]::Value
      [bool] $allConnectionsAreSameType = $true

   } # Begin

   Process {

      if ($first) {
         $firstConnType = $Connection.GetType()
         $first = $false
      }
      elseif ($Connection.GetType() -ne $firstConnType) {
         $allConnectionsAreSameType = $false
      }

      $Connection | % {
         [Data.Common.DbConnection] $conn = $_

      # [SSISDB].[catalog].[master_properties] was added in SQL Server 2017 (version 14)

<#
         [Management.Automation.CallStackFrame] $csf0 = (gcs)[0]; [int] $majorVersion = ([version]$conn.ServerVersion).Major
         if ($majorVersion -lt 14) {
            [string[]] $msgs = @(
               "$($MyInvocation.MyCommand.Name): [SSISDB].[catalog].[master_properties] does not exist in $(Get-DBMSWithVersion -InputObject $conn)"
               "in $($csf0.FunctionName) at $($csf0.ScriptName): $($csf0.ScriptLineNumber)"
               "in $($CallStackFrame.FunctionName) at $($CallStackFrame.ScriptName): $($CallStackFrame.ScriptLineNumber)"
            )
            [Management.Automation.ErrorRecord] $errorRecord = [Management.Automation.ErrorRecord]::new(
               [NotSupportedException]::new($msgs -join "$([Environment]::NewLine)         "),
               'UnsupportedSQLServerVersion',
               [System.Management.Automation.ErrorCategory]::InvalidOperation,
               $Connection
            )
            $PSCmdlet.WriteError($errorRecord)
         }
#>

# SCHEMA_BUILD version might not be the same as SQL Server Version

         [string] $version = Get-Scalar -Connection $conn -Query "select cp.[property_value] from [SSISDB].[catalog].[catalog_properties] cp where cp.[property_name] = N'SCHEMA_BUILD';"

         [Management.Automation.CallStackFrame] $csf0 = (gcs)[0]; [int] $majorVersion = ([version] $version).Major
         if ($majorVersion -lt 14) {
            [Data.Common.DbDataAdapter] $da = New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select cast(ServerProperty(N'ServerName') as nvarchar(128)) [ServerName],
   p.[property_type],
   p.[property_name],
   p.[property_value],
   case
      when p.[property_type] = N'CATALOG' and p.[property_name] = N'SCHEMA_BUILD' and p.[property_value] != cast(ServerProperty(N'ProductVersion') as nvarchar(11))
      then N'SSIS Schema not upgraded!'
      else N''
   end [ALERT]
from (
   select N'CATALOG' [property_type],
      cp.[property_name],
      cp.[property_value]
   from [SSISDB].[catalog].[catalog_properties] cp
) p
order by p.[property_type] collate Latin1_General_BIN asc,
   p.[property_name] collate Latin1_General_BIN asc;
'@
         } # if ($majorVersion -lt 14)
         else { # $majorVersion -ge 14
            [Data.Common.DbDataAdapter] $da = New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select cast(ServerProperty(N'ServerName') as nvarchar(128)) [ServerName],
   p.[property_type],
   p.[property_name],
   p.[property_value],
   case
      when p.[property_type] = N'CATALOG' and p.[property_name] = N'SCHEMA_BUILD' and p.[property_value] != cast(ServerProperty(N'ProductVersion') as nvarchar(11))
      then N'SSIS Schema not upgraded!'
      else N''
   end [ALERT]
from (
   select N'CATALOG' [property_type],
      cp.[property_name],
      cp.[property_value]
   from [SSISDB].[catalog].[catalog_properties] cp
   union all
   select N'MASTER' [property_type],
      mp.[property_name],
      mp.[property_value]
   from [SSISDB].[catalog].[master_properties] mp
) p
order by p.[property_type] collate Latin1_General_BIN asc,
   p.[property_name] collate Latin1_General_BIN asc;
'@
         } # else { # $majorVersion -ge 14

         $dataAdapterList.Add($da)

      }

   } # Process

   End {

      [string[]] $matchColumns = 'property_type', 'property_name'
      [string[]] $compareColumns = , 'property_value'

      if ($allConnectionsAreSameType) {
         return $dataAdapterList, $matchColumns, $compareColumns
      }
      else {
         return $dataAdapterList
      }

   } # End

}


function Compare-SSISProperties {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.DataRow[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateCount(2, 2)]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:DefaultCommandTimeout,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      if ($CallStackFrame -eq $NULL) {
         $CallStackFrame = (gcs)[1]
      }

      [Collections.Generic.List[Data.Common.DbConnection]] $dbConnList = New-Object -TypeName 'Collections.Generic.List[Data.Common.DbConnection]'

   } # Begin

   Process {

      $Connection | % {
         $dbConnList.Add($_)
      }

   }

   End {
   
      [Data.Common.DbDataAdapter[]] $dataAdapters, [string[]] $matchColumns, [string[]] $compareColumns = New-DataAdapterForSSISProperties -Connection $dbConnList -CommandTimeout $CommandTimeout -CallStackFrame $CallStackFrame -ErrorAction 'Continue'
      if ($?) {

      [Collections.Generic.List[object]] $objList = New-Object -TypeName 'Collections.Generic.List[object]'

      Compare-DataFromTwoDataAdapters -DatabaseName 'SSISDB' -DataAdapters $dataAdapters -MatchColumns $matchColumns -CompareColumns $compareColumns `
         -WhenMatched {
            param([Data.DataRow] $row1, [Data.DataRow] $row2, [int] $same, [int] $diff)
            if ($diff -eq 0) {
               [string] $match = 'Match - Same'
               [string] $comparison = "all ${same} same, none different"
            }
            else {
               [string] $match = 'Match - Diffs'
               [string] $comparison = "${same} same, ${diff} different"
            }
            [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
               'MatchStatus'                        = $match
               'Server_1'                           = $servers[0]
               'ServerName_1'                       = $row1['ServerName']
               'property_type_1'                    = $row1['property_type']
               'property_name_1'                    = $row1['property_name']
               'property_value_1'                   = $row1['property_value']
               'Alert_1'                            = $row1['ALERT']
               'property_type_2'                    = $row2['property_type']
               'property_name_2'                    = $row2['property_name']
               'property_value_2'                   = $row2['property_value']
               'Alert_2'                            = $row2['ALERT']
               'ServerName_2'                       = $row2['ServerName']
               'Server_2'                           = $servers[1]
               'Comparison'                         = $comparison
            })
            $objList.Add($obj)
         } `
         -WhenNotMatched {
            param([int] $which, [Data.DataRow] $row)
            if ($which -eq 1) {
               [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                  'MatchStatus'                        = 'Extra / Missing'
                  'Server_1'                           = $servers[0]
                  'ServerName_1'                       = $row1['ServerName']
                  'property_type_1'                    = $row1['property_type']
                  'property_name_1'                    = $row1['property_name']
                  'property_value_1'                   = $row1['property_value']
                  'Alert_1'                            = $row1['ALERT']
                  'property_type_2'                    = ''
                  'property_name_2'                    = ''
                  'property_value_2'                   = ''
                  'Alert_2'                            = ''
                  'ServerName_2'                       = ''
                  'Server_2'                           = $servers[1]
                  'Comparison'                         = ''
               })
            }
            else { # $which -eq 2
               [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                  'MatchStatus'                        = 'Missing / Extra'
                  'Server_1'                           = $servers[0]
                  'ServerName_1'                       = ''
                  'property_type_1'                    = ''
                  'property_name_1'                    = ''
                  'property_value_1'                   = ''
                  'Alert_1'                            = ''
                  'property_type_2'                    = $row2['property_type']
                  'property_name_2'                    = $row2['property_name']
                  'property_value_2'                   = $row2['property_value']
                  'Alert_2'                            = $row2['ALERT']
                  'ServerName_2'                       = $row['ServerName']
                  'Comparison'                         = ''
               })
            }
            $objList.Add($obj)
         } # -WhenNotMatched

      $dataAdapters | % {
         $_.Dispose()
      }

      } # if ($?)

      return $objList

   } # End

}
