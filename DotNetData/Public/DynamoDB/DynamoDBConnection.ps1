<# DotNetData/Public/DynamoDB/DynamoDBConnection.ps1
#>


[Boolean] $Script:firstDynamoDBConn = $true

$Script:ddcsb = $NULL

#[int] $Script:DefaultCommandTimeout = 300 # default is 30

function New-DynamoDBConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $Server,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateRange(-1,65535)]
      [int] $Port = -1,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $DatabaseName = 'DynamoDB',
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CallStackCount = -1
   )

   Begin {

      [Management.Automation.ErrorRecord] $ex = $null
         # prevent variable from being optimized in nested scopes

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      if ($CallStackCount -eq -1) {
         $CallStackCount = 2
      }
      else {
         $CallStackCount += 1
      }

   # Load DynamoDB.Data.dll

      if ($Script:firstDynamoDBConn) {
         $firstDynamoDBConn = $false

         [Object] $DynamoDBConfig = Get-DotNetDataConfiguration -DBMS 'DynamoDB'

      # Load the DLL for DynamoDB Connector for .NET

         try {
            Import-Dll -DllPath $DynamoDBConfig.DllPath
         }
         catch {
            return $null
         }

      } # if ($Script:firstDynamoDBConn)

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:ddcsb -eq $NULL) {
         [DynamoDB.Data.DynamoDBClient.DynamoDBConnectionStringBuilder] $Script:ddcsb = New-Object -TypeName 'DynamoDB.Data.DynamoDBClient.DynamoDBConnectionStringBuilder'
      }

   }

   Process {

   # When $Server is from "-Server" parameter, each item in [String[]] $Server list is processed separately
   # for each item, return a single connection for just one name in $queue (vs. adding all $Server items to $queue at once)

      foreach ($aServer in $Server) {

         if ($Script:ddcsb -eq $null) {
            Write-Output -InputObject ([Data.Common.DbConnection] $null)
         } # if ($Script:ddcsb -eq $null)
         else { # $Script:ddcsb -ne $null

            Initialize-DynamoDBConnectionStringBuilder -ConnectionStringBuilder $Script:ddcsb

            $Script:ddcsb['Server'] = $Server
            if ($Port -ge 0) {
               $Script:ddcsb['Port'] = $Port
            }
            $Script:ddcsb['Database'] = $DatabaseName
            $Script:ddcsb['UserID'] = $UserName
            [Management.Automation.PSCredential] $Credential = Get-CredentialForUserName -UserName $UserName -Server $aServer -CallStackFrame $CallStackFrame
            if ($Credential -eq $NULL) {
               return $null
            }
            $Script:ddcsb['UserID'] = $Credential.UserName
            $Script:ddcsb['Password'] = $Credential.GetNetworkCredential().Password
            [string] $connstr = $Script:ddcsb.ToString()

         # Connect to DynamoDB instance

            [DynamoDB.Data.DynamoDBClient.DynamoDBConnection] $conn = New-Object -TypeName 'DynamoDB.Data.DynamoDBClient.DynamoDBConnection' ($connstr)

            [String] $server = $connstr.Substring($connstr.IndexOf('server=') + 7, $connstr.IndexOf(';', $connstr.IndexOf('server=')) - $connstr.IndexOf('server=') - 7)
            Try {
               $conn.Open()
               if ($conn.State -ne 'Open') {
                  [String[]] $msgs = @(
                     "$($MyInvocation.MyCommand.Name): conn.Open() with Data Source=${server}"
                     "Connection.Type             = $($conn.GetType().FullName)"
                     "Connection.State            = $($conn.State)"
                     "Connection.DataSource       = $($conn.DataSource)"
                     "Connection.Database         = $($conn.Database)"
                     "Connection.ConnectionString = $($conn.ConnectionString)"
                  )
                  Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ConnectionError) -CategoryReason 'DynamoDBConnection.Open failed' -CategoryTargetName $server -CategoryTargetType 'Server'
               }
            }
            Catch {
               [Management.Automation.ErrorRecord] $er = $_
               Write-Error -ErrorRecord $er -CategoryTargetName $server -CategoryTargetType 'Server'
            }

         # Return the Connection regardless of State 'Open' or not

            Write-Output -InputObject $conn

         } # else ($Script:ddcsb -ne $null)

      } # foreach ($aServer in $Server)

   } # Process

   End {
   }

}
