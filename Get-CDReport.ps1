#requires -version 5.1
#requires -module VMware.VimAutomation.Core
Function Get-CDReport {

  <#
      .DESCRIPTION
        Returns a report of VMware virtual machines that have a CD attached. 
        You should already be connected to vCenter before running this.
        Supports all Get-VM input parameters.

      .Notes
        Script:     Get-CDReport.ps1
        Author:     Mike Nisk
        Prior Art:  Based on Get-VM by VMware, Inc.

      .EXAMPLE
      Get-CDReport -Name TestVM001
      This example returns information for one virtual machine.
      
      .EXAMPLE
      $report = Get-CDReport -Location (Get-Folder 'QA Test')
      This example returns information for all VMs in the 'QA Test' folder.

      .EXAMPLE
      $report = Get-CDReport -Datastore (Get-Datastore '*ISO*')
      This example returns information for all virtual machines that are using the provided datastore.
      This works good for ISO volumes or similar.

  #>

  [CmdletBinding(DefaultParameterSetName='Default')]
  Param(

    [Parameter(ParameterSetName='Default', Position=0)]
    [Parameter(ParameterSetName='DistributedSwitch', Position=0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Name,

    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='DistributedSwitch')]
    [Parameter(ParameterSetName='ById')]
    [VMware.VimAutomation.ViCore.Types.V1.VIServer[]]$Server,

    [Parameter(ParameterSetName='Default', ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.StorageResource[]]$Datastore,

    [Parameter(ParameterSetName='DistributedSwitch', ValueFromPipeline=$true)]
    [Alias('DistributedSwitch')]
    [ValidateNotNullOrEmpty()]
    [VMware.VimAutomation.ViCore.Types.V1.Host.Networking.VirtualSwitchBase[]]$VirtualSwitch,

    [Parameter(ParameterSetName='Default', ValueFromPipeline=$true)]
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.VIContainer[]]$Location,

    [Parameter(ParameterSetName='RelatedObject', Mandatory=$true, ValueFromPipeline=$true)]
    [VMware.VimAutomation.ViCore.Types.V1.RelatedObject.VmRelatedObjectBase[]]$RelatedObject,

    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='DistributedSwitch')]
    [VMware.VimAutomation.ViCore.Types.V1.Tagging.Tag[]]$Tag,

    [Parameter(ParameterSetName='ById')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Id,

    [Parameter(ParameterSetName='Default')]
    [switch]$NoRecursion

  )

  Process {
  
    ## Get virtual machines
    $VMs = Get-VM @PSBoundParameters
    
    ## Get CD Report
    $report = @()
    foreach($vm in $VMs){
      
      try{
        $CDReport = $vm | Get-CDDrive -ErrorAction Stop
      }
      catch{
         Write-Error -Message $Error[0].exception.Message
      }
      
      $result = New-Object -TypeName PSCustomObject -Property @{
        Name           = $vm.Name
        Datastore      = $vm | Get-Datastore | Select-Object -ExpandProperty Name
        IsoPath        = $CDReport.IsoPath       #most common
        HostDevice     = $CDReport.HostDevice    #If any
        RemoteDevice   = $CDReport.RemoteDevice  #If any
        Tags           = ((Get-TagAssignment -Entity $vm | Select-Object -ExpandProperty Tag).Name -join ',')
      }
      $report += $result
    }
  } #End Process

  End {     
    If($report){
      return $report
    }
  } #End End
} #End Function
