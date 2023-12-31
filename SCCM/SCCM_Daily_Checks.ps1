#************************************************************************************************************************
# Created 12/04/21 Gavin Pickles
# Last Modified 12/12/23 Gavin Pickles
#************************************************************************************************************************
$ErrorActionPreference = "SilentlyContinue"
Set-ExecutionPolicy remotesigned -Force $ErrorActionPreference
Clear-Host
Write-Host "*******************************************************************************"   -foregroundcolor "Green"
Write-Host "File Name	: SCCM_Daily_Checks"              	                                   -foregroundcolor "Green"
Write-Host "Purpose 	: ConfigMgr Daily Checks" 			                                   -foregroundcolor "Green"                        
Write-Host "Version		: 01.190219"           									               -foregroundcolor "Green"
Write-Host "Please ensure account used to run script has administrative rights to DB Server"   -foregroundcolor "Green" 
Write-Host "Enable/Disable Checks by modifying ConfigFile.XML"                                 -foregroundcolor "Green" 
Write-Host "*******************************************************************************"   -foregroundcolor "Green"
#**************************** Output Standard Color Code and Output Path Information ****
$OKColor = "Green"
$WarningColor = "Orange"
$CriticalColor = "Red"
$OfflineColor = "DarkRed"
$ToolName = "SCCM_Daily_Checks"
#$OutputPath = split-path -parent $MyInvocation.MyCommand.Definition
$OutputPath = "C:\Scripts\$ToolName"
#************** Check and Create Historical Folder Structure **********
$HistoricalReportsDir = "$OutputPath\Historical_Reports"
If(-Not(Test-Path $HistoricalReportsDir))
{
    New-Item $HistoricalReportsDir -type directory | Out-null
}
#****************************************************************************************
#**************************** Config File Creation and Others Information ***************
#$OutputPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Add-Type -AssemblyName System.Windows.Forms
$ConfigFile = "$OutputPath\ConfigFile.xml"
$LogDir = "$OutputPath"
If(-Not(Test-Path -path $LogDir))
{
    New-Item $LogDir -type directory | Out-null
}
If(Test-Path -path $ConfigFile)
{
    [xml]$ConfigFile = Get-Content "$OutputPath\ConfigFile.xml"
}
Else
{
	$ErrorConfigfile = "$Outputpath\Log\Error_Config_File_Missing.log"
	Write-Host "Error: No ConfigXML File exists on Script Path :$OutputPath"
	Add-Content $ErrorConfigfile -Value "Error: No ConfigXML File exists on Script Path :$OutputPath"
	$Value = Read-Host "Do you want to create default ConfigXML File ? (Y/N)"
	$Value = $Value.toupper()
	If ($Value -eq "Y")
	{
		$ConfigFile = "$OutputPath\ConfigFile.xml"
		Write-Host "Information: Default ConfigXML File is created on Script Path :$OutputPath"
		Add-Content $ErrorConfigfile -Value "Information: Default ConfigXML File is created on Script Path :$OutputPath"
		Write-Host "Information: Please change the ConfigXML File values as per Requirements"
		Add-Content $ErrorConfigfile -Value "Information: Please change the ConfigXML File values as per Requirements" 
		$ConfigValue = @"
<Settings>
	<CentralSettings>
		<SCCMCentralDBName>SCCM_Central_DB_Name</SCCMCentralDBName>
		<SCCMCentralDBServerName>SCCM_Central_DB_ServerName</SCCMCentralDBServerName>
	</CentralSettings>

	<SCCMSettings>
		<ProjectName>Customer_Name</ProjectName>	
		<OutputFileName>SCCM_Daily_Checks</OutputFileName>
		<strServers>Server1,Server2</strServers>
		<strMPServers>Server1,Server2</strMPServers>
		<strServicesServers>Server1,Server2</strServicesServers>
		<SiteCode>SiteCode</SiteCode>
		<SMSProviderServerName>SMS_Provider_ServerName</SMSProviderServerName>
		<SMSDBServerName>SCCM_DB_ServerName</SMSDBServerName>		
	</SCCMSettings>

	<EmailSettings>
		<TriggerMail>No</TriggerMail>
		<SMTPServer>SMTP_Server_Name</SMTPServer>
		<FromAddress>sccmhealthcheckalert@domainname.com</FromAddress>
		<ToAddress></ToAddress>
		<CCAddress></CCAddress>
		<BCCAddress></BCCAddress>
	</EmailSettings>

	<HealthCheckCustomSettings>
		<CheckServersAvailabilityRpt>Yes</CheckServersAvailabilityRpt>
		<CheckServersDiskSpaceRpt>Yes</CheckServersDiskSpaceRpt>
		<CheckServersMPRpt>Yes</CheckServersMPRpt>
		<CheckSiteServersServicesRpt>Yes</CheckSiteServersServicesRpt>
		<CheckSQLServerServicesRpt>Yes</CheckSQLServerServicesRpt>
		<CheckBackupsRpt>Yes</CheckBackupsRpt>
		<CheckInboxRpt>Yes</CheckInboxRpt>
		<CheckIssueSiteServersRpt>Yes</CheckIssueSiteServersRpt>
		<CheckCompRpt>Yes</CheckCompRpt>
		<CheckOverviewContentRpt>Yes</CheckOverviewContentRpt>
		<CheckWaitingContentRpt>Yes</CheckWaitingContentRpt>
        <CheckInactiveClientsRpt>Yes</CheckInactiveClientsRpt>
        <CheckADRsRpt>Yes</CheckADRsRpt>        
        <CheckMWsRpt>Yes</CheckMWsRpt>
        <CheckWSUSsyncRpt>Yes</CheckWSUSsyncRpt>
		<CheckMonitoredCol>Yes</CheckMonitoredCol>
		<CheckMonitoredColNames></CheckMonitoredColNames>
        <GenerateCSVRpt>Yes</GenerateCSVRpt>	    
	</HealthCheckCustomSettings>

	<DefaultSettings>
		<InboxWarningCount>1000</InboxWarningCount>
		<InboxCriticalCount>5000</InboxCriticalCount>
		<WarningDiskSpacePercentage>10</WarningDiskSpacePercentage>
		<CriticalDiskSpacePercentage>5</CriticalDiskSpacePercentage>
		<CheckSiteBackup>Yes</CheckSiteBackup>
		<CheckDBBackup>Yes</CheckDBBackup>	
		<HistoryRpt>-30</HistoryRpt>
	</DefaultSettings>

	<HTMLSettings>
		<HeaderBGColor>#425563</HeaderBGColor>
		<FooterBGColor>#425563</FooterBGColor>
		<TableHeaderBGColor>#01A982</TableHeaderBGColor>
		<TableHeaderRowBGColor>#CCCCCC</TableHeaderRowBGColor>
		<TextColor>white</TextColor>
	</HTMLSettings>		
</Settings>
"@
		Add-Content $ConfigFile -Value "$ConfigValue"
	}	
    Exit 1
}  
#****************************************************************************************
$SCCMCentralDBName = $ConfigFile.Settings.CentralSettings.SCCMCentralDBName
$SCCMCentralDBServerName = $ConfigFile.Settings.CentralSettings.SCCMCentralDBServerName
#****************************************************************************************
$ProjectName = $ConfigFile.Settings.SCCMSettings.ProjectName
$OutputFileName = $ConfigFile.Settings.SCCMSettings.OutputFileName
$strServers = $ConfigFile.Settings.SCCMSettings.strServers
$strMPServers = $ConfigFile.Settings.SCCMSettings.strMPServers
$strServicesServers = $ConfigFile.Settings.SCCMSettings.strServicesServers                              
$SiteCode = $ConfigFile.Settings.SCCMSettings.SiteCode
$SMSProviderServerName = $ConfigFile.Settings.SCCMSettings.SMSProviderServerName
$SMSDBServerName = $ConfigFile.Settings.SCCMSettings.SMSDBServerName
#****************************************************************************************  
$TriggerMail = $ConfigFile.Settings.EmailSettings.TriggerMail
$SMTPServer = $ConfigFile.Settings.EmailSettings.SMTPServer
$FromAddress = $ConfigFile.Settings.EmailSettings.FromAddress
$ToAddress = $ConfigFile.Settings.EmailSettings.ToAddress
$CCAddress = $ConfigFile.Settings.EmailSettings.CCAddress
$BCCAddress = $ConfigFile.Settings.EmailSettings.BCCAddress
#****************************************************************************************  
$CheckServersAvailabilityRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckServersAvailabilityRpt
$CheckServersDiskSpaceRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckServersDiskSpaceRpt
$CheckServersMPRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckServersMPRpt
$CheckSiteServersServicesRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckSiteServersServicesRpt
$CheckSQLServerServicesRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckSQLServerServicesRpt
$CheckBackupsRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckBackupsRpt
$CheckInboxRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckInboxRpt
$CheckIssueSiteServersRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckIssueSiteServersRpt
$CheckCompRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckCompRpt
$CheckOverviewContentRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckOverviewContentRpt
$CheckWaitingContentRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckWaitingContentRpt
$CheckInactiveClientsRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckInactiveClientsRpt
$CheckADRsRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckADRsRpt
$CheckMWsRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckMWSRpt
$CheckWSUSsyncRpt = $ConfigFile.Settings.HealthCheckCustomSettings.CheckWSUSsyncRpt
$CheckMonitoredCol = $ConfigFile.Settings.HealthCheckCustomSettings.CheckMonitoredCol
$CheckMonitoredColNames = $ConfigFile.Settings.HealthCheckCustomSettings.CheckMonitoredColNames
$GenerateCSVRpt = $ConfigFile.Settings.HealthCheckCustomSettings.GenerateCSVRpt
#****************************************************************************************  
$InboxWarningCount = $ConfigFile.Settings.DefaultSettings.InboxWarningCount
$InboxCriticalCount = $ConfigFile.Settings.DefaultSettings.InboxCriticalCount
$WarningDiskSpacePercentage = $ConfigFile.Settings.DefaultSettings.WarningDiskSpacePercentage
$CriticalDiskSpacePercentage = $ConfigFile.Settings.DefaultSettings.CriticalDiskSpacePercentage
$CheckSiteBackup = $ConfigFile.Settings.DefaultSettings.CheckSiteBackup
$CheckDBBackup = $ConfigFile.Settings.DefaultSettings.CheckDBBackup
$HistoryRpt = $ConfigFile.Settings.DefaultSettings.HistoryRpt
#****************************************************************************************
$HeaderBGColor = $ConfigFile.Settings.HTMLSettings.HeaderBGColor
$FooterBGColor = $ConfigFile.Settings.HTMLSettings.FooterBGColor
$TableHeaderBGColor = $ConfigFile.Settings.HTMLSettings.TableHeaderBGColor
$TableHeaderRowBGColor = $ConfigFile.Settings.HTMLSettings.TableHeaderRowBGColor
$TextColor = $ConfigFile.Settings.HTMLSettings.TextColor  
#**************************** Adjust Services Infromation **************************************************************
$SCCMServices = "IISADMIN","W3SVC","Winmgmt","CcmExec","SMS_EXECUTIVE","SMS_SITE_COMPONENT_MANAGER","SMS_SITE_VSS_WRITER"
$SQLServices = "Winmgmt","CcmExec","SMS_EXECUTIVE","SMS_REPORTING_POINT","ReportServer","MSSQLSERVER"
#****************************************************************************************
$New_OutputFileName = "$OutputFileName-$(get-date -format MM-dd-yyyy_HH-mm).html"
Rename-Item "$OutputPath\$OutputFileName.html" -newname "$OutputPath\$New_OutputFileName.html" -Force
Move-Item "$OutputPath\$New_OutputFileName.html" -destination "$HistoricalReportsDir\$New_OutputFileName" -Force
Remove-Item -path "$OutputPath\*.html" -Force
$New_OutputFileName = "$OutputFileName-$(get-date -format MM-dd-yyyy_HH-mm).CSV"
Rename-Item "$OutputPath\$OutputFileName.CSV" -newname "$OutputPath\$New_OutputFileName.CSV" -Force
Move-Item "$OutputPath\$New_OutputFileName.CSV" -destination "$HistoricalReportsDir\$New_OutputFileName" -Force
Remove-Item -path "$OutputPath\*.CSV" -Force
Start-sleep -milliseconds 500
$CurrentDate = Get-Date
$DateToDelete = $CurrentDate.AddDays($HistoryRpt)
Get-ChildItem $HistoricalReportsDir | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
#****************************************************************************************
$Report = "$OutputPath\SCCM_Daily_Checks.html"
$CSVReport = "$OutputPath\SCCM_Daily_Checks.CSV"
$Logfile = "$OutputPath\SCCM_Daily_Checks.log"
#****************************************** Start ***********************************************
#$StartTime = "00:00:00 AM"
#$EndTime = "00:00:00 PM"
#$StartTime = "00:00:00"
#$EndTime = "23:59:00"
#~THIS WORKS
#$a = (Get-Date).adddays(-1).GetDateTimeFormats()[0]
 
######
#$b = (get-date).AddDays(1)
#$b = $b.ToShortDateString()
#$c = (Get-Date) 
#$c = $c.ToShortDateString()
#$after = $b + " " + $StartTime
#$before = $c + " " + $EndTime
#$after = [datetime]$after
#$before = [datetime]$before
$after =  (Get-date).AddDays(-1).GetDateTimeFormats()[15]
$before =  (Get-date).GetDateTimeFormats()[15]

#****************************************** End ***********************************************
$SMSProvider = "\\$SMSProviderServerName\SMS_$SiteCode"
If(-Not(Test-Path "$SMSProvider"))
{
	Write-Host "Error: SMS Provider ServerName or Sitecode is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
    Add-Content $logfile -Value "Error: SMS Provider ServerName or Sitecode is not properly mentioned in Config XML File or Your Account does not have sufficient Access" 
    Add-Content $logfile -Value "****************** End Time: $(Get-Date) *******************"
    Write-Host "****************** End Time: $(Get-Date) *******************"
	Copy-Item -Path $logfile -Destination "C:\Windows\Temp\$OutputFileName.log" -Force
	Exit 1
}
#**************************** Script Path Validation End **************************************


#Report Title
$ReportTitle = "$ProjectName - SCCM Daily Checks"

#************************************************************************************************************************
Function NoResults($value1,$Report)
{#If No Results found
            If (!$value1)
            {
            $rpt = @"  
			
				<tr align='Center'>
			    <td width='80%' align='center'><h3> <Font color ='White'> NO RESULTS </Font></h3> </td>
				</tr>    
			
"@
				Add-Content "$Report" $rpt
                Add-Content "$Report" "</table>"
             }
}
Function Get-DailyHTMLReport
{
	Add-Content $logfile -Value "****************** Start Time: $(Get-Date) *******************"
    Write-Host "****************** Start Time: $(Get-Date) *******************"
	#Create a new report file to be emailed out
	New-Item -ItemType File -Name $Report -Force | Out-Null
	New-Item -ItemType File -Name $CSVReport -Force | Out-Null
	#Write the HTML header information to file
	writeHtmlHeader "$Path\$Report"
    #Checking Servers Details Status
    If ($CheckServersAvailabilityRpt -eq "Yes")
    {
        Add-Content $logfile -Value "01. $(Get-Date) - Checking Servers Availability Details"
        Write-Host "01. $(Get-Date) - Checking Servers Availability  Details"
        $rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Servers Availability Details Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
        <td width='5%'>SNo</td>
        <td width='25%'>ServerName</td>
        <td width='15%'>IPAddress</td>
        <td width='25%'>Operating System</td>
	    <td width='25%'>Domain</td>
	    <td width='5%'>Status</td>
	    </tr>
        </table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Servers Availability Details Status"
			Add-Content $CSVReport -Value "SNo,ServerName,IPAddress,Operating System,Domain,Status"
		}
        $i = 0
        $strServers = $strServers.Split(",")
        foreach ($Server in $strServers)
        {
            $i++
            $Server = $Server.toupper()
            $IP = [System.Net.Dns]::GetHostEntry($Server).AddressList | %{$_.IPAddressToString}
            $IP | %{$HostName = [System.Net.Dns]::GetHostEntry($_).HostName}
		    $Ping = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Server'"
		    $IP = $Ping.IPV4Address
            If ($IP)
            {
                if (Test-Connection -ComputerName $Server -Quiet -Count 3)
                {
                    if (Test-Path \\$Server\admin`$ )#Test to make sure computer is up and that you are using the proper credentials
                    {
                        $wmi = Get-WmiObject -ComputerName $Server -Namespace root\cimv2 -class Win32_OperatingSystem
                        If ($wmi)
                        {
                            $OS = (Get-WmiObject Win32_OperatingSystem -computername $Server).caption
                            $SystemInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $Server | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory
                            $ModelInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Server | Select-Object Manufacturer, Model,DNSHostName,Domain
                            $TotalRAM = $SystemInfo.TotalVisibleMemorySize/1MB
                            $FreeRAM = $SystemInfo.FreePhysicalMemory/1MB
                            $UsedRAM = $TotalRAM - $FreeRAM
                            $RAMPercentFree = ($FreeRAM / $TotalRAM) * 100
                            $TotalRAM = [Math]::Round($TotalRAM, 2)
                            $FreeRAM = [Math]::Round($FreeRAM, 2)
                            $UsedRAM = [Math]::Round($UsedRAM, 2)
                            $RAMPercentFree = [Math]::Round($RAMPercentFree, 2)
                            $Made = $ModelInfo.manufacturer
                            $Model = $ModelInfo.model
                            $Domain = $ModelInfo.Domain
                            $SystemUptime = Get-HostUptime -ComputerName $Server
                            $Status = "Ok"
                            $color = "$OkColor"
                            $Rpt=@"
                            <table width='100%' border = 0 > <tbody>
	                        <tr>
                            <td width='5%' align='center' >$i</td>
                            <td width='25%' align='left'>&nbsp$Server</td>
                            <td width='15%' align='center'>$IP</td>
                            <td width='25%' align='center'>$OS</td>
	                        <td width='25%' align='center'>$Domain</td>
	                        <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                        </tr>
                            </table>
"@
                            Add-Content "$Report" $Rpt 
							If ($GenerateCSVRpt -eq "Yes")
							{
								Add-Content $CSVReport -Value "$i,$Server,$IP,$OS,$Domain,$Status"
							}							
                        }
                        else
                        {
                            $Status = "WMI_Issue"
                            $color = "$WarningColor"
                            $Rpt=@"
                            <table width='100%' border = 0 > <tbody>
	                        <tr>
                            <td width='5%' align='center'>$i</td>
                            <td width='25%' align='left'>&nbsp$Server</td>
                            <td width='15%' align='center'>$IP</td>
                            <td width='25%' align='center'>NA</td>
	                        <td width='25%' align='center'>NA</td>
	                        <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                        </tr>
                            </table>
"@
                            Add-Content "$Report" $Rpt 
							If ($GenerateCSVRpt -eq "Yes")
							{
								Add-Content $CSVReport -Value "$i,$Server,$IP,NA,NA,$Status"
							}							
                        }
                    }
                    else
                    {
                        $Status = "ADM_Issue"
                        $color = "$WarningColor"
                        $Rpt=@"
                        <table width='100%' border = 0 > <tbody>
	                    <tr>
                        <td width='5%' align='center' >$i</td>
						<td width='25%' align='left'>&nbsp$Server</td>
                        <td width='15%' align='center'>$IP</td>
                        <td width='25%' align='center'>NA</td>
	                    <td width='25%' align='center'>NA</td>
	                    <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                    </tr>
                        </table>
"@
                        Add-Content "$Report" $Rpt  
						If ($GenerateCSVRpt -eq "Yes")
						{
							Add-Content $CSVReport -Value "$i,$Server,$IP,NA,NA,$Status"
						}
                    }
                }
                else
                {
                    $Status = "Offline"
                    $color = "$Offlinecolor"
                    $Rpt=@"
                    <table width='100%' border = 0 > <tbody>
	                <tr>
                    <td width='5%' align='center' >$i</td>
					<td width='25%' align='left'>&nbsp$Server</td>
                    <td width='15%' align='center'>$IP</td>
                    <td width='25%' align='center'>NA</td>
	                <td width='25%' align='center'>NA</td>
	                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                </tr>
                    </table>
"@
                    Add-Content "$Report" $Rpt 
					If ($GenerateCSVRpt -eq "Yes")
					{
						Add-Content $CSVReport -Value "$i,$Server,$IP,NA,NA,$Status"
					}					
                }
            }
            else
            {
                $Status = "DNS_Issue"
                $color = "$CriticalColor"
                $Rpt=@"
                <table width='100%' border = 0 > <tbody>
	            <tr>
                <td width='5%' align='center' >$i</td>
				<td width='25%' align='left'>&nbsp$Server</td>
                <td width='15%' align='center'>$IP</td>
                <td width='25%' align='center'>NA</td>
	            <td width='25%' align='center'>NA</td>
	            <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	            </tr>
                </table>
"@
                Add-Content "$Report" $Rpt 
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$Server,$IP,NA,NA,$Status"
				}				
            }
        }
    }
    Else
    {
        Add-Content $logfile -Value "01. $(Get-Date) - Skipping Servers Availability Details"
        Write-Host "01. $(Get-Date) - Skipping Servers Availability Details"
    }
    #Checking Servers Disk Space Details Status
    If ($CheckServersDiskSpaceRpt -eq "Yes")
    {
        Add-Content $logfile -Value "02. $(Get-Date) - Checking Servers Disk Space Details"
        Write-Host "02. $(Get-Date) - Checking Servers Disk Space Details"
        $rptheader=@"
        <table width='100%'><tbody>
		<tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Servers Disk Space Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
        <td width='5%'>SNo</td>
        <td width='20%'>ServerName</td> 
        <td width='5%'>Drive</td> 
        <td width='15%'>VolName</td>    
        <td width='15%'>Total Capacity(GB)</td>
	    <td width='15%'>Used Capacity(GB)</td>
        <td width='15%'>Free Space(GB)</td>
	    <td width='5%'>Free Space%</td>
        <td width='5%'>Status</td>
	    </tr>
        </table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Servers Disk Space Details"
			Add-Content $CSVReport -Value "SNo,ServerName,Drive,VolName,Total_Capacity(GB),Used_Capacity(GB),Free_Space(GB),Free_Space%,Status"
		}
        $i = 0
        foreach ($Server in $strServers)
        {
            $Server = $Server.toupper()
            $IP = [System.Net.Dns]::GetHostEntry($Server).AddressList | %{$_.IPAddressToString}
            $IP | %{$HostName = [System.Net.Dns]::GetHostEntry($_).HostName}
		    $Ping = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Server'"
		    $IP = $Ping.IPV4Address
            If ($IP)
            {
                if (Test-Connection -ComputerName $Server -Quiet -Count 1)
                {
                    if (Test-Path \\$Server\admin`$ )#Test to make sure computer is up and that you are using the proper credentials
                    {
                        $wmi = Get-WmiObject -ComputerName $Server -Namespace root\cimv2 -class Win32_OperatingSystem
                        If ($wmi)
                        {
                            $disks = Get-WmiObject -ComputerName $Server -Class Win32_LogicalDisk -Filter "DriveType = 3"
                            $Server = $Server.toupper()
                            foreach($disk in $disks)
                            {        
                                $i++
		                        $deviceID = $disk.DeviceID
                                $volName = $disk.VolumeName
		                        [float]$size = $disk.Size
		                        [float]$freespace = $disk.FreeSpace;		                        
		                        $sizeGB = [Math]::Round($size / 1073741824, 2)
		                        $FreeSpaceGB = [Math]::Round($freespace / 1073741824, 2)
								$FreeSpacePercentage = [Math]::Round(($FreeSpace / $size) * 100, 2)
                                $UsedSpaceGB = $sizeGB - $FreeSpaceGB
                                # Set background color to $WarningColor if just a Warning
    	                        If($FreeSpacePercentage -lt $WarningDiskSpacePercentage)  
								#If($FreeSpaceGB -lt $WarningDiskSpacePercentage)  								
                                {
                                    $status = "Warning"
                                    $color = "$WarningColor"
                                    # Set background color to $WarningColor if space is Critical 
									If($FreeSpacePercentage -lt $CriticalDiskSpacePercentage)									
                                    #If($FreeSpaceGB -lt $CriticalDiskSpacePercentage)
                                    {
                                        $status = "Critical"
                                        $color = "$CriticalColor"
                                    }  
                                }  
                                else
                                {
                                    $status = "Ok"
                                    $color = "$OkColor"
                                }
                                $Rpt=@"
                                <table width='100%' border = 0 > <tbody>
                                <tr align= 'center'>
                                <td width='5%' align='center' >$i</td> 
								<td width='20%' align='left'>&nbsp$Server</td>
                                <td width='5%'>$deviceID</td>    
                                <td width='15%'>$volName</td> 
                                <td width='15%'>$sizeGB</td>
                                <td width='15%'>$UsedSpaceGB</td>
	                            <td width='15%'>$FreeSpaceGB</td>
                                <td width='5%'>$FreeSpacePercentage</td>
	                            <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                            </tr>
                                </table>
"@
                                Add-Content "$Report" $Rpt
								If ($GenerateCSVRpt -eq "Yes")
								{
									Add-Content $CSVReport -Value "$i,$Server,$deviceID,$volName,$sizeGB,$UsedSpaceGB,$FreeSpaceGB,$FreeSpacePercentage,$Status"
								}
                            }
                        }
                        else
                        {
                            $i++
                            $Status = "WMI_Issue"
                            $color = "$WarningColor"
                            $Rpt=@"
                            <table width='100%' border = 0 > <tbody>
                            <tr align= 'center'>
                            <td width='5%' align='center' >$i</td>
                            <td width='20%' align='left'>&nbsp$Server</td>  
                            <td width='5%'>NA</td>    
                            <td width='15%'>NA</td> 
                            <td width='15%'>NA</td>
                            <td width='15%'>NA</td>
	                        <td width='15%'>NA</td>
                            <td width='5%'>NA</td>
	                        <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                        </tr>
                            </table>
"@
                            Add-Content "$Report" $Rpt 
							If ($GenerateCSVRpt -eq "Yes")
							{
								Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,NA,NA,NA,$Status"
							}							
                        }
                    }
                    else
                    {
                        $i++
                        $Status = "ADM_Issue"
                        $color = "$WarningColor"
                        $Rpt=@"
                        <table width='100%' border = 0 > <tbody>
                        <tr align= 'center'>
                        <td width='5%' align='center' >$i</td>
                        <td width='20%' align='left'>&nbsp$Server</td> 
                        <td width='5%'>NA</td>    
                        <td width='15%'>NA</td> 
                        <td width='15%'>NA</td>
                        <td width='15%'>NA</td>
	                    <td width='15%'>NA</td>
                        <td width='5%'>NA</td>
	                    <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                    </tr>
                        </table>
"@
                        Add-Content "$Report" $Rpt 
						If ($GenerateCSVRpt -eq "Yes")
						{
							Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,NA,NA,NA,$Status"
						}						
                    }
                }
                else
                {
                    $i++
                    $Status = "Offline"
                    $color = "$CriticalColor"
                    $Rpt=@"
                    <table width='100%' border = 0 > <tbody>
                    <tr align= 'center'>
                    <td width='5%' align='center' >$i</td>
                    <td width='20%' align='left'>&nbsp$Server</td>  
                    <td width='5%'>NA</td>    
                    <td width='15%'>NA</td> 
                    <td width='15%'>NA</td>
                    <td width='15%'>NA</td>
	                <td width='15%'>NA</td>
                    <td width='5%'>NA</td>
	                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                </tr>
                    </table>
"@
                    Add-Content "$Report" $Rpt  
					If ($GenerateCSVRpt -eq "Yes")
					{
						Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,NA,NA,NA,$Status"
					}
                }
            }
            else
            {
                $i++
                $Status = "DNS_Issue"
                $color = "$CriticalColor"
                $Rpt=@"
                <table width='100%' border = 0 > <tbody>
                <tr align= 'center'>
                <td width='5%' align='center' >$i</td>
                <td width='20%' align='left'>&nbsp$Server</td>  
                <td width='5%'>NA</td>    
                <td width='15%'>NA</td> 
                <td width='15%'>NA</td>
                <td width='15%'>NA</td>
	            <td width='15%'>NA</td>
                <td width='5%'>NA</td>
	            <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	            </tr>
                </table>
"@
                Add-Content "$Report" $Rpt  
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,NA,NA,NA,$Status"
				}
            }
        }
    }
    Else
    {
        Add-Content $logfile -Value "02. $(Get-Date) - Skipping Servers Disk Space Details"
        Write-Host "02. $(Get-Date) - Skipping Servers Disk Space Details"
    }
    #Checking Servers MP Details Status Report
    If($CheckServersMPRpt -eq "Yes")
    {
        Add-Content $logfile -Value "03. $(Get-Date) - Checking Servers MP Details"
        Write-Host "03. $(Get-Date) - Checking Servers MP Details"
        $rptheader=@"
        <table width='100%'><tbody>
		<tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Servers Management Point Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>    
        <td width='5%'>SNo</td>    
        <td width='20%'>ServerName</td>
        <td width='10%'>Site Code</td>
        <td width='15%'>MPCert Status</td>
	    <td width='15%'>MPCert Code</td>
        <td width='15%'>MPList Status</td>
        <td width='15%'>MPList Code</td>	   
        <td width='5%'>Status</td>
	    </tr>
        </table>
"@
        Add-Content "$Report" $rptheader 
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Servers Management Point Status"
			Add-Content $CSVReport -Value "SNo,ServerName,Site_Code,MPCert_Status,MPCert_Code,MPList_Status,MPList_Code,Status"
		}
        $i = 0
        $strMPServers = $strMPServers.Split(",")
        foreach ($Server in $strMPServers)
        {
            $i++
            $Server = $Server.toupper()
            $URL1 = "http://$Server/sms_mp/.sms_aut?mpcert"
            $URL2 = "http://$Server/sms_mp/.sms_aut?mplist"
            $WEBObject1 = [system.net.WebRequest]::Create($URL1)
            $WEBObject2 = [system.net.WebRequest]::Create($URL2)
            $WEBObject1.AuthenticationLevel = "None"
            $WEBObject2.AuthenticationLevel = "None"
            $WEBObject1.Timeout = 7000
            $WEBObject2.Timeout = 7000
            Try
            {
                $WEBResponse1 = $WEBObject1.GetResponse()
                $MpcertStatus = $WEBResponse1.StatusCode            
                $MpcertStatusCode = ($WEBResponse1.Statuscode -as [int])  
                $WEBResponse1.Close()
                $WEBResponse2 = $WEBObject2.GetResponse()
                $MplistStatus = $WEBResponse2.StatusCode            
                $MplistStatusCode = ($WEBResponse2.Statuscode -as [int])  
                $WEBResponse2.Close()        
                if (($MpcertStatusCode -eq "200") -and ($MplistStatusCode -eq "200"))
                {
                    $t = 1
                    $color ="$OkColor"
                    $status ="Ok"
                }
                else
                {          
                    $t = 1
                    $color ="$WarningColor"
                    $status ="Warning"
                }
            }
            Catch
            {
                $MpcertStatus =  $_.Exception.Response.StatusCode
                $MpcertStatusCode = ( $_.Exception.Response.StatusCode -as [int])
                $MplisttStatus =  $_.Exception.Response.StatusCode
                $MplisttStatusCode = ( $_.Exception.Response.StatusCode -as [int])
                $t = 1
                $color ="$CriticalColor"
                $status ="Critical"
            }
            if ($t -eq 1)
            {
                $Rpt=@"
                <table width='100%' border = 0 > <tbody>
    	        <tr align= 'center'>    
                <td width='5%'>$i</td>
                <td width='20%' align='left'>&nbsp$Server</td>      
                <td width='10%'>$Sitecode</td>    
                <td width='15%'>$MpcertStatus</td>
    	        <td width='15%'>$MpcertStatusCode</td>
                <td width='15%'>$MplistStatus</td>
                <td width='15%'>$MplistStatusCode</td>
    	        <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
    	        </tr>
            </table>
"@
                Add-Content "$Report" $Rpt
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$Server,$Sitecode,$MpcertStatus,$MpcertStatusCode,$MplistStatus,$MplistStatusCode,$Status"
				}
            }
   
        }
    }
    Else
    {
        Add-Content $logfile -Value "03. $(Get-Date) - Skipping Servers MP Details"
        Write-Host "03. $(Get-Date) - Skipping Servers MP Details"
    }
    #Checking Components Servers Services Details Status Report
    If ($CheckSiteServersServicesRpt -eq "Yes")
    {
        Add-Content $logfile -Value "04. $(Get-Date) - Checking Components Servers Services Details"
        Write-Host "04. $(Get-Date) - Checking Components Servers Services Details"
        $rptheader=@"
        <table width='100%'><tbody>
		<tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Servers Components Services Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
        <td width='5%'>SNo</td>
        <td width='30%'>ServerName</td>
        <td width='30%'>Display Name</td>
        <td width='25%'>Name</td>
	    <td width='5%'>StartMode</td>
	    <td width='5%'>Status</td>
	    </tr>
        </table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Components Servers Services Details"
			Add-Content $CSVReport -Value "SNo,ServerName,DisplayName,Name,StartMode,Status"
		}
        $i = 0
        $strServicesServers = $strServicesServers.Split(",")
        foreach ($Server in $strServicesServers)
        {
            $Server = $Server.toupper()
            $IP = [System.Net.Dns]::GetHostEntry($Server).AddressList | %{$_.IPAddressToString}
            $IP | %{$HostName = [System.Net.Dns]::GetHostEntry($_).HostName}
		    $Ping = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Server'"
		    $IP = $Ping.IPV4Address
            If ($IP)
            {
                if (Test-Connection -ComputerName $Server -Quiet -Count 1)
                {
                    if (Test-Path \\$Server\admin`$ )#Test to make sure computer is up and that you are using the proper credentials
                    {
                        $wmi = Get-WmiObject -ComputerName $Server -Namespace root\cimv2 -class Win32_OperatingSystem
                        If ($wmi)
                        {
                             Foreach ($Service in $SCCMServices) 
	                        {
	                            $SiteService = Get-WmiObject -Class Win32_Service -ComputerName $Server | Where {$_.Name -eq $Service}                            
                                $DisplayName = $SiteService.DisplayName
                                $Name = $SiteService.Name
                                $Status = $SiteService.State
                                $StartMode = $SiteService.StartMode
                                If ($StartMode -eq "Disabled")
                                {
                                    $color = "$CriticalColor"
                                    $status = "Critical"           
                                }
                                else
                                {
                                    $color = "$OkColor"
                                    $status = "Ok"
                                }
                                If ($StartMode -eq "Manual")
                                {
                                    $color = "$WarningColor"
                                    $status = "Warning"           
                                }

                                If ($DisplayName)
                                {
                                    $i++
                                    $rpt=@"
                                    <table width='100%' border = 0> <tbody>
	                                <tr align='Left'>
                                    <td width='5%' align='center'>$i</td>
                                    <td width='30%' align='left'>&nbsp$Server</td>
                                    <td width='30%'>$DisplayName</td>
                                    <td width='25%'>$Name</td>
	                                <td width='5%'>$StartMode</td>
	                                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                                </tr>
                                    </table>
"@
                                    Add-Content "$Report" $rpt  
									If ($GenerateCSVRpt -eq "Yes")
									{
										Add-Content $CSVReport -Value "$i,$Server,$DisplayName,$Name,$StartMode,$Status"
									}
                                }
                            }                      
                        }
                        else
                        {
                            $i++
                            $Status = "WMI_Issue"
                            $color = "$WarningColor"
                            $Rpt=@"
                            <table width='100%' border = 0 > <tbody>
	                        <tr align='Left'>
                            <td width='5%' align='center' >$i</td>
                            <td width='30%'>$Server</td>
                            <td width='30%'>NA</td>
                            <td width='25%'>NA</td>
	                        <td width='5%'>NA</td>
	                        <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                        </tr>
                            </table>
"@
                            Add-Content "$Report" $Rpt   
							If ($GenerateCSVRpt -eq "Yes")
							{
								Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
							}							
                        }
                    }
                    else
                    {
                        $i++
                        $Status = "ADM_Issue"
                        $color = "$WarningColor"
                        $Rpt=@"
                        <table width='100%' border = 0 > <tbody>
	                    <tr align='Left'>
                        <td width='5%' align='center' >$i</td>
                        <td width='30%' align='left'>&nbsp$Server</td>
                        <td width='30%'>NA</td>
                        <td width='25%'>NA</td>
	                    <td width='5%'>NA</td>
	                    <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                    </tr>
                        </table>
"@
                        Add-Content "$Report" $Rpt 
						If ($GenerateCSVRpt -eq "Yes")
						{
							Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
						}						
                    }
                }
                else
                {
                    $i++
                    $Status = "Offline"
                    $color = "$CriticalColor"
                    $Rpt=@"
                    <table width='100%' border = 0 > <tbody>
	                <tr align='Left'>
                    <td width='5%' align='center' >$i</td>
                    <td width='30%' align='left'>&nbsp$Server</td>
                    <td width='30%'>NA</td>
                    <td width='25%'>NA</td>
	                <td width='5%'>NA</td>
	                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                </tr>
                    </table>
"@
                    Add-Content "$Report" $Rpt  
					If ($GenerateCSVRpt -eq "Yes")
					{
						Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
					}	
                }
            }
            else
            {
                $i++
                $Status = "DNS_Issue"
                $color = "$CriticalColor"
                $Rpt=@"
                <table width='100%' border = 0 > <tbody>
	            <tr align= 'Left'>
                <td width='5%' align='center' >$i</td>
                <td width='30%' align='left'>&nbsp$Server</td>
                <td width='30%'>NA</td>
                <td width='25%'>NA</td>
                <td width='5%'>NA</td>
	            <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	            </tr>
                </table>
"@
                Add-Content "$Report" $Rpt
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
				}				
            }
        }
    }
    Else
    {
        Add-Content $logfile -Value "04. $(Get-Date) - Skipping Components Servers Services Details"
        Write-Host "04. $(Get-Date) - Skipping Components Servers Services Details"
    }
    #Checking SQL Server Services Details Status Report
    If ($CheckSQLServerServicesRpt -eq "Yes")
    {
        Add-Content $logfile -Value "05. $(Get-Date) - Checking SQL Server Services Details"
        Write-Host "05. $(Get-Date) - Checking SQL Server Services Details"
        $rptheader=@"
        <table width='100%'><tbody>
		<tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> SQL Server Services Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
        <td width='5%'>SNo</td>
        <td width='30%'>ServerName</td> 
        <td width='30%'>Display Name</td>
        <td width='25%'>Name</td>
	    <td width='5%'>StartMode</td>
	    <td width='5%'>Status</td>
	    </tr>
        </table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "SQL Servers Services Details"
			Add-Content $CSVReport -Value "SNo,ServerName,DisplayName,Name,StartMode,Status"
		}
        $i = 0
        foreach ($Server in $SMSDBServerName)
        {
            $Server = $Server.toupper()
            $IP = [System.Net.Dns]::GetHostEntry($Server).AddressList | %{$_.IPAddressToString}
            $IP | %{$HostName = [System.Net.Dns]::GetHostEntry($_).HostName}
		    $Ping = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Server'"
		    $IP = $Ping.IPV4Address
            If ($IP)
            {
                if (Test-Connection -ComputerName $Server -Quiet -Count 1)
                {
                    if (Test-Path \\$Server\admin`$ )#Test to make sure computer is up and that you are using the proper credentials
                    {
                        $wmi = Get-WmiObject -ComputerName $Server -Namespace root\cimv2 -class Win32_OperatingSystem
                        If ($wmi)
                        {
                             Foreach ($Service in $SQLServices) 
	                        {
	                            $SiteService = Get-WmiObject -Class Win32_Service -ComputerName $Server | Where {$_.Name -eq $Service}                            
                                $DisplayName = $SiteService.DisplayName
                                $Name = $SiteService.Name
                                $Status = $SiteService.State
                                $StartMode = $SiteService.StartMode
                                If ($StartMode -eq "Disabled")
                                {
                                    $color = "$CriticalColor"
                                    $status = "Critical"           
                                }
                                else
                                {
                                    $color = "$OkColor"
                                    $status = "Ok"
                                }
                                If ($StartMode -eq "Manual")
                                {
                                    $color = "$WarningColor"
                                    $status = "Warning"           
                                }

                                If ($DisplayName)
                                {
                                    $i++
                                    $rpt=@"
                                    <table width='100%' border = 0 > <tbody>
	                                <tr align= 'Left'>
                                    <td width='5%' align='center' >$i</td>
                                    <td width='30%' align='left'>&nbsp$Server</td>
                                    <td width='30%'>$DisplayName</td>
                                    <td width='25%'>$Name</td>
	                                <td width='5%'>$StartMode</td>
	                                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                                </tr>
                                    </table>
"@
                                    Add-Content "$Report" $rpt 
									If ($GenerateCSVRpt -eq "Yes")
									{
										Add-Content $CSVReport -Value "$i,$Server,$DisplayName,$Name,$StartMode,$Status"
									}
                                }
                            }                      
                        }
                        else
                        {
                            $i++
                            $Status = "WMI_Issue"
                            $color = "$WarningColor"
                            $Rpt=@"
                            <table width='100%' border = 0 > <tbody>
	                        <tr align='Left'>
                            <td width='5%' align='center' >$i</td>
                            <td width='30%' align='left'>&nbsp$Server</td>
                            <td width='30%'>NA</td>
                            <td width='25%'>NA</td>
	                        <td width='5%'>NA</td>
	                        <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                        </tr>
                            </table>
"@
                            Add-Content "$Report" $Rpt 
							If ($GenerateCSVRpt -eq "Yes")
							{
								Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
							}							
                        }
                    }
                    else
                    {
                        $i++
                        $Status = "ADM_Issue"
                        $color = "$WarningColor"
                        $Rpt=@"
                        <table width='100%' border = 0 > <tbody>
	                    <tr align='Left'>
                        <td width='5%' align='center' >$i</td>
                        <td width='30%' align='left'>&nbsp$Server</td>
                        <td width='30%'>NA</td>
                        <td width='25%'>NA</td>
	                    <td width='5%'>NA</td>
	                    <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                    </tr>
                        </table>
"@
                        Add-Content "$Report" $Rpt 
						If ($GenerateCSVRpt -eq "Yes")
						{
							Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
						}						
                    }
                }
                else
                {
                    $i++
                    $Status = "Offline"
                    $color = "$CriticalColor"
                    $Rpt=@"
                    <table width='100%' border = 0 > <tbody>
	                <tr align='Left'>
                    <td width='5%' align='center' >$i</td>
                    <td width='30%' align='left'>&nbsp$Server</td>
                    <td width='30%'>NA</td>
                    <td width='25%'>NA</td>
	                <td width='5%'>NA</td>
	                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	                </tr>
                    </table>
"@
                    Add-Content "$Report" $Rpt  
					If ($GenerateCSVRpt -eq "Yes")
					{
						Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
					}
                }
            }
            else
            {
                $i++
                $Status = "DNS_Issue"
                $color = "$CriticalColor"
                $Rpt=@"
                <table width='100%' border = 0 > <tbody>
	            <tr align='Left'>
                <td width='5%' align='center' >$i</td>
                <td width='30%' align='left'>&nbsp$Server</td>
                <td width='30%'>NA</td>
                <td width='25%'>NA</td>
	            <td width='5%'>NA</td>
	            <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
	            </tr>
                </table>
"@
                Add-Content "$Report" $Rpt
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$Server,NA,NA,NA,$Status"
				}				
            }
        }
    }
    Else
    {
        Add-Content $logfile -Value "05. $(Get-Date) - Skipping SQL Server Services Details"
        Write-Host "05. $(Get-Date) - Skipping SQL Server Services Details"
    }
    #Checking Backup Details Status Report
    If ($CheckBackupsRpt -eq "Yes")
    {
        Add-Content $logfile -Value "06. $(Get-Date) - Checking Backup Details"
        Write-Host "06. $(Get-Date) - Checking Backup Details"       
        BackupRpt    
    }
    Else
    {
        Add-Content $logfile -Value "06. $(Get-Date) - Skipping Backup Details"
        Write-Host "06. $(Get-Date) - Skipping Backup Details"  
    }
    #Checking Inbox Details Status Report
    If($CheckInboxRpt -eq "Yes")
    {
        Add-Content $logfile -Value "07. $(Get-Date) - Checking Inbox Details"
        Write-Host "07. $(Get-Date) - Checking Inbox Details"                    
        InboxRpt  
    }
    Else
    {
        Add-Content $logfile -Value "07. $(Get-Date) - Skipping Inbox Details"
        Write-Host "07. $(Get-Date) - Skipping Inbox Details" 
    }
    #Checking Issue Site Servers Report
	If ($CheckIssueSiteServersRpt -eq "Yes")
	{
		Add-Content $logfile -Value "08. $(Get-Date) - Checking ConfigMgr Issue Servers Status"
		Write-Host "08. $(Get-Date) - Checking ConfigMgr Issue Servers Status"	
		 #****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		#$con = "Provider=SQLOLEDB.1;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
        $con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
        #$objConnection = New-Object System.Data.SQLClient.SQLConnection
        #$objRecordset = New-Object 	System.Data.DataSet
        #$objConnection.ConnectionString = "server=$SCCMCentralDBServerName;database=$SCCMCentralDBName;trusted_connection=true;"
        #$objConnection.Open()
		$strSQL = @"
select 
SiteCode,
SUBSTRING(SiteSystem,13,29) AS SiteSystem,
Role,
timereported,

Case Status When 0 Then 'OK' When 1 Then 'Warning' When 2 Then 'Critical' Else ' ' End AS 'Status'
 from v_SiteSystemSummarizer
 --where Status like '1' or status like '2'
 order by Status, SiteCode

"@	
		$objConnection.Open($con)
		#$objConnection.Open()
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Issue Site Servers Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
        <td width='5%'>SiteCode</td>    
        <td width='40%'>ServerName</td>
        <td width='30%'>Role</td>
        <td width='20%'>TimeStamp</td>
	    <td width='5%'>Status</td>	
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Issue Site Servers Status"
			Add-Content $CSVReport -Value "SiteCode,ServerName,Role,TimeStamp,Status"
		}
		$z = 0
		$i = 1  
		$y = 0
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
		do 
		{
			$value1 = $objRecordset.Fields.Item(0).Value
            $ReFormatValue2 = $objRecordset.Fields.Item(1).Value
			$value2 = $reformatValue2.Split("\"" ", 2)[0]
			$value3 = $objRecordset.Fields.Item(2).Value
			$value4 = $objRecordset.Fields.Item(3).Value
			$value5 = $objRecordset.Fields.Item(4).Value

			If ($value1)
			{
            If ($value5 -eq "Critical")
            {
                $color = "$CriticalColor"        
            }
            else
            {
                $color = "$OkColor"
            }
            If ($value5 -eq "Warning")
            {
                $color = "$WarningColor"       
            }
				$rpt = @"    
				<tr align='Center'>
				<td width='5%'>$value1</td>   
			    <td width='40%' align='left'>&nbsp&nbsp$value2</td>	
			    <td width='30%'>$value3</td>
                <td width='20%'>$value4</td>
			    <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $value5 </Font> </td>
				</tr>    
"@
				Add-Content "$Report" $rpt
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$value1,$value2,$value3,$value4,$value5"
				}
				$i++
			}
#If No Results found

NoResults $value1 $Report

#end no results
   
			$objRecordset.MoveNext()
		} 
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
    	Add-Content $logfile -Value "08. $(Get-Date) - Skipping ConfigMgr Issue Servers Status"
		Write-Host "08. $(Get-Date) - Skipping ConfigMgr Issue Servers Status"	
    }

    #Checking Components Report
	If ($CheckCompRpt -eq "Yes")
	{
		Add-Content $logfile -Value "09. $(Get-Date) - Checking Components Status"
        Write-Host "09. $(Get-Date) - Checking Components Status"	
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
SELECT distinct  SiteCode , 
MachineName 'ServerName', 
ComponentName ,
Case v_componentSummarizer.State When 0 Then 'Stopped' When 1 Then 'Started' When 2 Then 'Paused' When 3 Then 'Installing' When 4 Then 'Re-Installing' When 5 Then 'De-Installing' Else ' ' END AS 'Thread State',
Errors,
Warnings,
Infos,
Case v_componentSummarizer.Type When 0 Then 'Autostarting' When 1 Then 'Scheduled' When 2 Then 'Manual' ELSE ' ' END AS 'StartupType',
CASE AvailabilityState When 0 Then 'Online' When 3 Then 'Offline' ELSE ' ' END AS 'State',
Case v_ComponentSummarizer.Status When 0 Then 'OK' When 1 Then 'Warning' When 2 Then 'Critical' Else ' ' End As 'Status' 
from v_ComponentSummarizer Where TallyInterval = '0001128000100008' 
and (v_ComponentSummarizer.Status = 2 or v_ComponentSummarizer.Status = 1)
Order By ComponentName,SiteCode
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Component Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SiteCode</td>    
        <td width='20%'>ServerName</td>
        <td width='20%'>ComponentName</td>
        <td width='10%'>Thread</td>
	    <td width='10%'>Errors</td>
        <td width='10%'>Warns</td>
        <td width='5%'>Infos</td>
        <td width='10%'>StartupType</td>	       
        <td width='5%'>State</td>
        <td width='5%'>Status</td>
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Component Status"
			Add-Content $CSVReport -Value "SiteCode,ServerName,ComponentName,Thread,Errors,Warns,Infos,StartupType,State,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
		do 
		{
			#$status = "Critical"
		    $value1 = $objRecordset.Fields.Item(0).Value
		    $value2 = $objRecordset.Fields.Item(1).Value
		    $value3 = $objRecordset.Fields.Item(2).Value
		    $value4 = $objRecordset.Fields.Item(3).Value
		    $value5 = $objRecordset.Fields.Item(4).Value
		    $value6 = $objRecordset.Fields.Item(5).Value
		    $value7 = $objRecordset.Fields.Item(6).Value
		    $value8 = $objRecordset.Fields.Item(7).Value
		    $value9 = $objRecordset.Fields.Item(8).Value
		    $value10 = $objRecordset.Fields.Item(9).Value
			#If ($value10 -eq "Critical")

            If ($value10)
			{
            If ($value10 -eq "Critical")
            {
                $color = "$CriticalColor"        
            }
            else
            {
                $color = "$OkColor"
            }
            If ($value10 -eq "Warning")
            {
                $color = "$WarningColor"       
            }

				$rpt = @"    
				<tr align='Center'>
				<td width='5%'>$value1</td>
			    <td width='20%' align='left'>&nbsp&nbsp$value2</td>
			    <td width='20%'>$value3</td>
			    <td width='10%'>$value4</td>
			    <td width='10%'>$value5</td>
			    <td width='10%'>$value6</td>
			    <td width='5%'>$value7</td>
			    <td width='10%'>$value8</td>
			    <td width='5%'>$value9</td>	   
			    <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $value10 </Font> </td>
              
				</tr>    
"@
				Add-Content "$Report" $rpt
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$value1,$value2,$value3,$value4,$value5,$value6,$value7,$value8,$value9,$value10"
				}
				$i++
			}

NoResults $value1 $Report

    
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "09. $(Get-Date) - Skipping Components Status"
		Write-Host "09. $(Get-Date) - Skipping Components Status"		
    }
	###START SECTION
	 #Content Distribution Overview
	If ($CheckOverviewContentRpt -eq "Yes")
	{
		Add-Content $logfile -Value "10. $(Get-Date) - Checking All Content Distribtion Status Accross All Distribution Points"
        Write-Host "10. $(Get-Date) - Checking All Content Distribtion Status Accross All Distribution Points"
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
select v_SystemResourceList.ServerName as 'ServerName',

v_SystemResourceList.SiteCode,

(select count(*)from v_PackageStatusDistPointsSumm where servernalpath = nalpath) as 'Targetted',

(select count(*)from v_PackageStatusDistPointsSumm where installstatus ='Package Installation complete'and servernalpath = nalpath) as 'Installed',

(select count(*)from v_PackageStatusDistPointsSumm where (installstatus ='Content updating' or installstatus ='Waiting to install package' or installstatus ='Content monitoring') and servernalpath = nalpath) as 'Waiting',

(select count(*)from v_PackageStatusDistPointsSumm where installstatus like'%Retry%'and servernalpath = nalpath) as 'Retrying',

(select count(*)from v_PackageStatusDistPointsSumm where installstatus ='Waiting to remove package' and servernalpath = nalpath) as 'Removing',

(select count(*)from v_PackageStatusDistPointsSumm where installstatus like'%Fail%' and servernalpath = nalpath) as 'Failed',

(select ROUND((100 * (select count(*)from v_PackageStatusDistPointsSumm where installstatus ='Package Installation complete' and servernalpath = nalpath)/(select count(*)from v_PackageStatusDistPointsSumm where servernalpath = nalpath)),2)) as 'Compliance %'

from v_SystemResourceList join v_PackageStatusDistPointsSumm

on v_SystemResourceList.nalpath = v_PackageStatusDistPointsSumm.servernalpath

where v_SystemResourceList.RoleName = 'SMS Distribution Point'

group by v_SystemResourceList.SiteCode, v_SystemResourceList.servername, v_SystemResourceList.nalpath order by 1
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Content Distribution Overview </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='20%'>ServerName</td>
		<td width='5%'>SiteCode</td>		
        <td width='10%'>Targetted</td>
        <td width='10%'>Installed</td>    
    	<td width='10%'>Waiting</td> 
        <td width='10%'>Retrying</td>    
        <td width='10%'>Removing</td>
		<td width='10%'>Failed</td>
		<td width='5%'>Compliance %</td>
        <td width='5%'>Status</td>
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Content Distribution Detailed Status"
			Add-Content $CSVReport -Value "SNo,ServerName,SiteCode,Targetted,Installed,Waiting,Retrying,Removing,Failed,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{
		If ($objRecordset.Fields.Item(8).Value -lt "100")
            {
            $color = $WarningColor
            $status = "Warning" 
            }
		If ($objRecordset.Fields.Item(8).Value -eq "100")
            {
            $color = $OKColor
            $status = "Ok" 
            }
		If ($objRecordset.Fields.Item(7).Value -gt "0")
            {
            $color = $CriticalColor
            $status = "Critical" 
            }

            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
            $value4 = $objRecordset.Fields.Item(3).Value
            $value5 = $objRecordset.Fields.Item(4).Value       
            $value6 = $objRecordset.Fields.Item(5).Value    
            $value7 = $objRecordset.Fields.Item(6).Value 
            $value8 = $objRecordset.Fields.Item(7).Value    
            $value9 = $objRecordset.Fields.Item(8).Value 
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='20%' align='Left'>&nbsp&nbsp$value1</td>
                <td width='5%'>$value2</td>
                <td width='10%'>$value3</td>
                <td width='10%' align='center'>$value4</td>    
	            <td width='10%'>$value5</td> 
                <td width='10%'>$value6</td>    
                <td width='10%'>$value7</td>
				<td width='10%'>$value8</td>
				<td width='5%'>$value9</td>
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$value4,$value5,$value6,$value7,$value8,$value9,$Status"
			    }
			    $i++
            }
            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "10. $(Get-Date) - Skipping - Checking Content Distribution Overview"
		Write-Host "10. $(Get-Date) - Skipping - Checking Content Distribution Overview"	
    }
	
	
	###END SECTION

    #Checking Waiting Packages Report
	If ($CheckWaitingContentRpt -eq "Yes")
	{
		Add-Content $logfile -Value "11. $(Get-Date) - Checking Waiting to Distribute Content Status"
        Write-Host "11. $(Get-Date) - Checking Waiting to Distribute Content Status"
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
Select 
SubString(dp.ServerNALPath, CHARINDEX('\\', dp.ServerNALPath)+2,(CHARINDEX('"]', dp.ServerNALPath) - CHARINDEX('\\', dp.ServerNALPath))-3) as ServerName,
dp.SiteCode as 'SiteCode', 
dp.PackageID as 'PackageID',
p.Name as 'PackageName', 
P.SourceVersion as 'SourceVersion',
P.LastRefreshTime as 'LastRefreshTime',
stat.InstallStatus as 'InstallStatus'
from v_DistributionPoint dp left join v_PackageStatusDistPointsSumm stat on 
dp.ServerNALPath=stat.ServerNALPath and dp.PackageID=stat.PackageID 
left join v_PackageStatus pstat on dp.ServerNALPath=pstat.PkgServer and 
dp.PackageID=pstat.PackageID left outer join v_Package p on dp.packageid = p.packageid 
where stat.InstallStatus not in ('Package Installation complete')
ORDER BY 1
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Content Distribution Waiting </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='20%'>ServerName</td>
		<td width='10%'>SiteCode</td>		
        <td width='10%'>PackageID</td>
        <td width='20%'>PackageName</td>    
    	<td width='5%'>SourceVer</td> 
        <td width='10%'>LastRefreshTime</td>    
        <td width='15%'>InstallStatus</td>  
        <td width='5%'>Status</td>
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Content Distribution Detailed Status"
			Add-Content $CSVReport -Value "SNo,ServerName,SiteCode,PackageID,PackageName,SourceVer,LastRefreshTime,InstallStatus,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{
            $color = $WarningColor
            $status = "Warning" 
            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
            $value4 = $objRecordset.Fields.Item(3).Value
            $value5 = $objRecordset.Fields.Item(4).Value       
            $value6 = $objRecordset.Fields.Item(5).Value    
            $value7 = $objRecordset.Fields.Item(6).Value 
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='20%' align='Left'>&nbsp&nbsp$value1</td>
                <td width='10%'>$value2</td>
                <td width='10%'>$value3</td>
                <td width='20%' align='center'>$value4</td>    
	            <td width='5%'>$value5</td> 
                <td width='10%'>$value6</td>    
                <td width='15%'>$value7</td> 
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$value4,$value5,$value6,$value7,$Status"
			    }
			    $i++
            }
            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "11. $(Get-Date) - Skipping Waiting to Distribute Content Status"
		Write-Host "11. $(Get-Date) - Skipping Waiting to Distribute Content Status"	
    }
    
    # Checking for inactive clients
    
	If ($CheckInactiveClientsRpt -eq "Yes")
	{
		Add-Content $logfile -Value "12. $(Get-Date) - Checking for inactive clients"
        Write-Host "12. $(Get-Date) - Checking for inactive clients"
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
select v_R_System.Netbios_Name0 AS [Computer Name],
convert(datetime,lastHWScan) AS [Last Hardware Scan],
v_R_System.Client_Version0 AS [Client Version],
v_R_System.Full_Domain_Name0 AS [Domain],
Case when CS.ClientActiveStatus='1' then 'Active' When CS.ClientActiveStatus='0' then 'Inactive' end as 'Client Active Status'
FROM v_R_System inner Join v_CH_ClientSummary CS on v_R_System.ResourceId=CS.ResourceID
LEFT JOIN v_GS_WORKSTATION_STATUS WS ON v_R_System.ResourceID = WS.ResourceID 
where CS.ClientActiveStatus='0' and v_R_System.Netbios_Name0 not like '%AT-%'
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Inactive Clients </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='20%'>ComputerName</td>
		<td width='20%'>LastHWScan</td>
        <td width='20%'>Client Version</td>
        <td width='20%'>Domain</td>		
        <td width='10%'>Activity</td>		
        <td width='5%'>Status</td>
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Client Activity Status"
			Add-Content $CSVReport -Value "SNo,ComputerName,LastHWScan,Client Version,Domain,Activity,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{
            $color = $CriticalColor
            $status = "Critical" 
            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
            $value4 = $objRecordset.Fields.Item(3).Value
            $value5 = $objRecordset.Fields.Item(4).Value
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='20%' align='Left'>&nbsp&nbsp$value1</td>
                <td width='20%'>$value2</td>
                <td width='20%'>$value3</td>
                <td width='20%'>$value4</td>
                <td width='10%'>$value5</td>
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$value4,$value5,$Status"
			    }
			    $i++
            }
            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "12. $(Get-Date) - Skipping Client Activity Check"
		Write-Host "12. $(Get-Date) - Skipping Client Activity Check"	
    }    
    
    #End Section
    # Check for ADR issues
    
	If ($CheckADRsRpt -eq "Yes")
	{
		Add-Content $logfile -Value "13. $(Get-Date) - Checking for ADR issues"
        Write-Host "13. $(Get-Date) - Checking for ADR issues"
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
        select
        Name,
        Description,
        case AutoDeploymentEnabled
        When '0' Then 'No'
        When '1' Then 'Yes'
        end as AutoDeploymentEnabled,
        LastRunTime,
        LastErrorCode,
        LastErrorTime
        from vSMS_AutoDeployments
        Where LastErrorTime is not null
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> ADR Issues </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='20%'>ADR Name</td>
		<td width='20%'>Description</td>
        <td width='10%'>Enabled</td>
        <td width='20%'>LastRunTime</td>		
        <td width='10%'>ErrorCode</td>
        <td width='10%'>ErrorTime</td>		
        <td width='5%'>Status</td>
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "ADR issues"
			Add-Content $CSVReport -Value "SNo,ADRName,Description,Enabled,LastRunTime,ErrorCode,ErrorTime,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{
            $color = $CriticalColor
            $status = "Critical" 
            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
            $value4 = $objRecordset.Fields.Item(3).Value
            $value5 = $objRecordset.Fields.Item(4).Value
            $value6 = $objRecordset.Fields.Item(5).Value
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='20%' align='Left'>&nbsp&nbsp$value1</td>
                <td width='20%'>$value2</td>
                <td width='10%'>$value3</td>
                <td width='20%'>$value4</td>
                <td width='10%'>$value5</td>
                <td width='10%'>$value6</td>
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$value4,$value5,$value6,$Status"
			    }
			    $i++
            }
            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "13. $(Get-Date) - Skipping ADR Issue Check"
		Write-Host "13. $(Get-Date) - Skipping ADR Issue Check"	
    }    
    
    #End Section
    # Check for Enabled maintenance windows
    
	If ($CheckMWsRpt -eq "Yes")
	{
		Add-Content $logfile -Value "14. $(Get-Date) - Checking for enabled maintenance windows < 1 month"
        Write-Host "14. $(Get-Date) - Checking for enabled maintenance windows < 1 month"
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
        select 
        --*
        --C.SiteID,
        C.CollectionName as [Collection],
        Name,
        Description,
        StartTime,
        Duration
        from vSMS_ServiceWindow
        inner join v_Collections C on vSMS_ServiceWindow.SiteID=C.SiteID
        where StartTime <= dateadd(MONTH,+1,GETDATE())
        and Enabled = '1'
        order by StartTime
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Enabled maintenance windows (Excluding > 1 month) </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='20%'>Collection</td>
		<td width='20%'>Name</td>
        <td width='20%'>Description</td>
        <td width='15%'>StartTime</td>		
        <td width='15%'>Duration</td>
        <td width='5%'>Status</td>
	    </tr>
        </table>
        <table>
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Enabled MW"
			Add-Content $CSVReport -Value "SNo,Collection,Name,Description,StartTime,Duration,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{
            $color = $WarningColor
            $status = "Warning" 
            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
            $value4 = $objRecordset.Fields.Item(3).Value
            $value5 = $objRecordset.Fields.Item(4).Value
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='20%' align='Left'>&nbsp&nbsp$value1</td>
                <td width='20%'>$value2</td>
                <td width='20%'>$value3</td>
                <td width='15%'>$value4</td>
                <td width='15%'>$value5</td>
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$value4,$value5,$Status"
			    }
			    $i++
            }
            
            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "14. $(Get-Date) - Skipping Enabled MW Check"
		Write-Host "14. $(Get-Date) - Skipping Enabled MW Check"	
    }    
    
    #End Section
	
    # Check for WSUS Sync Status
    
	If ($CheckWSUSsyncRpt -eq "Yes")
	{
		Add-Content $logfile -Value "15. $(Get-Date) - Checking for WSUS Sync errors"
        Write-Host "15. $(Get-Date) - Checking for WSUS Sync errors"
		#****************************************** End ***********************************************
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
        select 
        --*
        SiteCode,
        WSUSServerName,
        WSUSSourceServer,
        case
        when LastSyncState = '6700' Then 'WSUS Sync Manager Error'
        when LastSyncState = '6701' Then 'WSUS Synchronization Started'
        when LastSyncState = '6702' Then 'WSUS Synchronization Done'
        when LastSyncState = '6703' Then 'WSUS Synchronization Failed'
        when LastSyncState = '6704' Then 'WSUS Synchronization In Progress Phase Synchronizing WSUS Server'
        when LastSyncState = '6705' Then 'WSUS Synchronization In Progress Phase Synchronizing SMS Database'
        when LastSyncState = '6706' Then 'WSUS Synchronization In Progress Phase Synchronizing Internet facing WSUS Server'
        when LastSyncState = '6707' Then 'Content of WSUS Server is out of sync with upstream server'
        else 'Unkown Code Review SQL Query'
        end as SyncStateDescription,
        LastSyncStateTime,
        case
        when LastSyncState = '6700' Then 'Critical'
        when LastSyncState = '6701' Then 'Warning'
        when LastSyncState = '6702' Then 'Ok'
        when LastSyncState = '6703' Then 'Ok'
        when LastSyncState = '6704' Then 'Ok'
        when LastSyncState = '6705' Then 'Ok'
        when LastSyncState = '6706' Then 'Ok'
        when LastSyncState = '6707' Then 'Ok'
        else 'Critical'
        end as Status
        --LastSyncErrorCode,
        from vSMS_SUPSyncStatus
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> WSUS Sync Status </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='5%'>SiteCode</td>
		<td width='21.25%'>WSUSServerName</td>
        <td width='21.25%'>WSUSSource</td>
        <td width='21.25%'>SyncState</td>		
        <td width='21.25%'>LastSync</td>
        <td width='5%'>Status</td>
	    </tr>
        
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "WSUS Sync Status"
			Add-Content $CSVReport -Value "SNo,SiteCode,WSUSServerName,WSUSSource,SyncState,LastSync,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{

            If ($objRecordset.Fields.Item(5).Value -eq "Ok")
            {
            
            $color = "$OkColor"  
            }
            If ($objRecordset.Fields.Item(5).Value -eq "Warning")
            {
            
            $color = "$WarningColor"  
            }
            if ($objRecordset.Fields.Item(5).Value -eq "Critical")
            {
            $color = "$CriticalColor"
            }

            $status = $objRecordset.Fields.Item(5).Value
            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
            $value4 = $objRecordset.Fields.Item(3).Value
            $value5 = $objRecordset.Fields.Item(4).Value
        
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='5%' align='Left'>$value1</td>
                <td width='21.25%'>$value2</td>
                <td width='21.25%'>$value3</td>
                <td width='21.25%'>$value4</td>
                <td width='21.25%'>$value5</td>
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$value4,$value5,$Status"
			    }
			    $i++
            }
            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "15. $(Get-Date) - Skipping WSUS Sync Check"
		Write-Host "15. $(Get-Date) - Skipping WSUS Sync Check"	
    }    
    
    #End Section
	 # Check monitored collections
    
	If ($CheckMonitoredCol -eq "Yes")
	{
		Add-Content $logfile -Value "16. $(Get-Date) - Checking Monitored Collections"
        Write-Host "16. $(Get-Date) - Checking Monitored Collections"
		#****************************************** End ***********************************************
		$CheckMonitoredColNames = $ConfigFile.Settings.HealthCheckCustomSettings.CheckMonitoredColNames
		$strColID = $CheckMonitoredColNames
		$StrColID2 = @()
		$i = 0
				$strColID = $strColID.Split(",")
				foreach ($ColID in $strColID)
				{
					$i++
					$ColID = ",'"+$ColID+"'"
					$StrColID2 += $ColID
					
					
				}
		$StrColID2 = ($StrColID2 -join '')
		$StrColID2 = "(''"+$StrColID2+")"
		$Status = "Warning"
		$objConnection = New-Object -comobject ADODB.Connection
		$objRecordset = New-Object -comobject ADODB.Recordset
		$con = "Provider=MSOLEDBSQL;Integrated Security=SSPI;Initial Catalog=$SCCMCentralDBName;Data Source=$SCCMCentralDBServerName"
		$strSQL = @"
        select 
sys.netbios_name0 [Computer Name], fcm.CollectionID, coll.Name[Collection Name]
from v_R_System sys
join v_GS_COMPUTER_SYSTEM csys on csys.ResourceID=sys.resourceid
join v_FullCollectionMembership fcm on fcm.ResourceID=csys.ResourceID
join v_collection coll on coll.collectionid=fcm.collectionid
where fcm.CollectionID in $StrColID2
group by sys.Netbios_Name0, fcm.CollectionID, coll.Name
order by coll.Name
"@
		$objConnection.Open($con)
		$objConnection.CommandTimeout = 0
		# *********** Check If connection is open *******************
		If($objConnection.state -eq 0)
		{
			Write-Host "Error: SCCM Central DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Add-Content $logfile -Value "Error: Central SCCM DB ServerName or Central SCCM DB Name is not properly mentioned in Config XML File or Your Account does not have sufficient Access"
			Exit 1        
		}
		$rptheader=@"
        <table width='100%'><tbody>
   	    <tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Monitored Collections </Font> </b> </td> </tr>
        </table>
        <table width='100%' border = 0 > <tbody>
	    <tr bgcolor=$TableHeaderRowBGColor>
	    <td width='5%'>SNo</td> 
        <td width='30%'>ComputerName</td>
		<td width='30%'>CollectionID</td>
        <td width='30%'>CollectionName</td>
        <td width='5%'>Status</td>
	    </tr>
		</table>
		<table>
        
"@
        Add-Content "$Report" $rptheader
		If ($GenerateCSVRpt -eq "Yes")
		{
			Add-Content $CSVReport -Value "Monitored Collections"
			Add-Content $CSVReport -Value "SNo,ComputerName,CollectionID,CollectionName,Status"
		}
		$objRecordset.Open($strSQL,$objConnection)
		$objRecordset.MoveFirst()
		$rows=$objRecordset.RecordCount
        $i = 1
		do
		{

            If ($Status -eq "Ok")
            {
            
            $color = "$OkColor"  
            }
            If ($Status -eq "Warning")
            {
            
            $color = "$WarningColor"  
            }
            if ($Status -eq "Critical")
            {
            $color = "$CriticalColor"
            }

            $Status = "Warning"
            $value1 = $objRecordset.Fields.Item(0).Value
            $value2 = $objRecordset.Fields.Item(1).Value
            $value3 = $objRecordset.Fields.Item(2).Value
        
            If ($value1)
			{
				$rpt = @"    
			    <tr align='Center'>
			    <td width='5%'>$i</td>    
                <td width='30%'>$value1</td>
                <td width='30%'>$value2</td>
                <td width='30%'>$value3</td>
                <td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
			    </tr>    
"@
			    Add-Content "$Report" $rpt
			    If ($GenerateCSVRpt -eq "Yes")
			    {
				    Add-Content $CSVReport -Value "$i,$value1,$value2,$value3,$Status"
			    }
			    $i++
            }

            NoResults $value1 $Report
			$objRecordset.MoveNext()
		}
		until ($objRecordset.EOF -eq $TRUE)
		Add-Content "$Report" "</table>"
	}
    Else
    {
		Add-Content $logfile -Value "16. $(Get-Date) - Skipping Monitored Collections Check"
		Write-Host "16. $(Get-Date) - Skipping Monitored Collections Check"	
    }    
    
    #End Section
    # Create table at end of report showing legend of colors for the Critical and Warning
	$tableDescription = "
    <table width='30%'>
    <tr bgcolor='White'> 
	<td width='10%' align='center' bgcolor='$OkColor'> <Font color = 'white'> <b> Normal </b> </Font> </td>  
	<td width='10%' align='center' bgcolor='$WarningColor'> <Font color = 'white'> <b> Warning below 10 % </b> </Font> </td>  
	<td width='10%' align='center' bgcolor='$CriticalColor'> <Font color = 'white'> <b> Critical below 5 % </b> </Font> </td>  
    </tr>
    </table>
    
   " 
   ##### FOOTER####


    Add-Content $Report $tableDescription	
	$RptFooter1 = @"
    <table width='100%' bgcolor = '$FooterBGColor'><tbody>
   	<tr> <td align='center'> <b> <Font color = 'white'> Last Run $(get-date -Format F)  from $([system.environment]::MachineName)</Font> </b> </td> </tr>
    </table>
"@
    
    Add-Content $Report $RptFooter1
	Add-Content "$Report" "</div></div></body></html>"
    # Finish up Report
    #Checking SMPT Mail Sent Details
    If ($TriggerMail -eq "Yes")
    {
        Add-Content $logfile -Value "99. $(Get-Date) - Sending SMTP Mail Sent Details"
        Write-Host "99. $(Get-Date) - Sending SMTP Mail Sent Details"
        $Subject = "$ReportTitle"
        $body = get-content "$Report"   
        $message = new-object System.Net.Mail.MailMessage 
        $message.From = $Fromaddress 
        $message.To.Add($Toaddress)
        $message.Cc.Add($CCAddress)
        $message.Bcc.Add($BCCAddress)
        $message.IsBodyHtml = $true
        $message.Subject = $Subject 
        #$attach = new-object Net.Mail.Attachment($Report) 
        #$message.Attachments.Add($attach) 
		#If ($GenerateCSVRpt -eq "Yes")
		#{
		#	$attach = new-object Net.Mail.Attachment($CSVReport) 
		#	$message.Attachments.Add($attach) 
		#}
        $message.body = $body 
        $smtp = new-object Net.Mail.SmtpClient($smtpserver) 
        $smtp.Send($message) 
    }
    Else
    {
        Add-Content $logfile -Value "99. $(Get-Date) - Skipping SMTP Mail Sent Details"
        Write-Host "99. $(Get-Date) - Skipping SMTP Mail Sent Details"
    }
    Add-Content $logfile -Value "****************** End Time: $(Get-Date) *******************"
    Write-Host "****************** End Time: $(Get-Date) *******************"
}

# Write HTML Header information to our Report & Use CSS to make report more readable
Function writeHtmlHeader
{
    $date = (get-date -Format F)
    $header = @"
   <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>$ReportTitle</title>
    <style type="text/css">
    <!--
    body {
            font: 100%/1.4 Verdana, Arial, Helvetica, sans-serIf;
            background: #FFFFFF;
            margin: 0;
            padding: 0;
            color: #000;
         }
    .container {
            width: 100%;
            margin: 0 auto;
            }
    h1 {
            font-size: 18px;
        }
    h2 {
            color: #FFF;
            padding: 0px;
            margin: 0px;
            font-size: 14px;
            background-color: #006400;
        }
    h3 {
            color: #FFF;
            padding: 0px;
            margin: 0px;
            font-size: 14px;
            background-color: #191970;
        }
    h4 {
            color: #348017;
            padding: 0px;
            margin: 0px;
            font-size: 10px;
            font-style: italic;
        }
    .header {
            text-align: center;
        }
    .container table {
            width: 100%;
            font-family: Verdana, Geneva, sans-serIf;
            font-size: 12px;
            font-style: normal;
            font-weight: bold;
            font-variant: normal;
            text-align: center;
            border: 0px solid black;
            padding: 0px;
            margin: 0px;
        }
    td {
            font-weight: normal;
            border: 1px solid grey;
            width='25%'
        }
    th {
            font-weight: bold;
            border: 1px solid grey;
            text-align: center;
        }
    -->
    </style></head>
    <body>
    <div class="container">
    <div class="content">	
"@
    Add-Content "$Report" $header	
	$RptHeaderSME1 = @"
	<table width='100%'><tbody>
	<tr bgcolor = '$HeaderBGColor'> <td align='center'> <b> 
	<Font color = 'white'> $ReportTitle </Font>
	</b> </td> </tr>
	</table>
"@
    Add-Content $Report $RptHeaderSME1
}

Function BackupRpt
{
    $rptheader=@"
    <table width='100%'><tbody>
	<tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Backup Status </Font> </b> </td> </tr>
    </table>
    <table width='100%' border = 0 > <tbody>
	<tr bgcolor=$TableHeaderRowBGColor >
    <td width='5%'>SNo</td>
    <td width='40%'>ServerName</td>
    <td width='40%'>Backup Checking Time</td>
    <td width='5%'>SiteBKP</td>
    <td width='5%'>DBBKP</td>	
	<td width='5%'>Status</td>
	</tr>
    </table>
"@
    #Add-Content "$Report" $rptheader
    $z = 0
    $i = 0
	$j = 1
	$y = 0
	$siteevent = (Get-EventLog -ComputerName $SMSProviderServerName -LogName Application -EntryType Information -after $after -before $before -Source "SMS Server"|?{$_.EventID -eq 6833})
    $dbevent = (Get-EventLog -ComputerName $SMSDBServerName -LogName Application -EntryType Information -after $after -before $before -Source "MSSQL`$D01" |?{$_.EventID -eq 18264})
    If($siteevent)
    {
	    $sitebackup = "Success"
    	$Sitestatus = "Ok"
		$Sitecolor = "$OkColor"
		$i++
		$t = "Yes"
		$tt = "Yes"	
    }
    else
    {
        $sitebackup = "Failed"
		$Sitestatus = "Critical"
        $Sitecolor = "$CriticalColor"
		$i++
        $t = "Yes"
		$tt = "Yes"	
    }
    If($dbevent)
    {
		$dbbackup = "Success" 
		$Dbstatus = "Ok"
		$Dbcolor = "$OkColor"
		$j++
		$t = "Yes"
		$ttt = "Yes"		
    }
    else
    {
        $dbbackup = "Failed"
		$Dbstatus = "Critical"
        $Dbcolor = "$CriticalColor"
		$j++
        $t = "Yes"	
		$ttt = "Yes"
	}
    If ($t -eq "Yes")
    {
        $z++
        If ($z -eq 1)
        {
			If ($tt -eq "Yes" -and $z -eq 1)
			{
				Add-Content "$Report" $rptheader
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "Backup Status"
					Add-Content $CSVReport -Value "SNo,ServerName,Backup Checking Time,SiteBKP,DBBKP,Status"
				}
				$z++
			}
			If ($ttt -eq "Yes" -and $z -eq 1)
			{
				Add-Content "$Report" $rptheader
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "Backup Status"
					Add-Content $CSVReport -Value "SNo,ServerName,Backup Checking Time,SiteBKP,DBBKP,Status"
				}
				$z++
			}
		}
        $rpt = @"
        <table width='100%' border = 0> <tbody>
    	<tr align='Center'>
        <td width='5%' align='center'>$i</td>
        <td width='40%' align='left'>&nbsp&nbsp$SMSProviderServerName</td>
        <td width='40%'>Between $after and $before</td>
        <td width='5%'>$sitebackup</td>
        <td width='5%'>NA</td>	
    	<td width='5%' align='center' bgcolor='$Sitecolor'> <Font color ='$TextColor'> $Sitestatus </Font> </td>
    	</tr>
        </table>
"@
		If ($CheckSiteBackup -eq "Yes")
		{
			If ($tt -eq "Yes")
			{
				Add-Content "$Report" $rpt
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$SMSProviderServerName,$after and $before,$sitebackup,NA,$Sitestatus"
				}
			}			
		}
		$rpt1 = @"
		<table width='100%' border = 0 > <tbody>
    	<tr align='Center'>
        <td width='5%' align='center'>$j</td>
        <td width='40%' align='left'>&nbsp&nbsp$SMSDBServerName</td>
        <td width='40%'>Between $after and $before</td>
        <td width='5%'>NA</td>
        <td width='5%'>$dbbackup</td>	
    	<td width='5%' align='center' bgcolor='$Dbcolor'> <Font color ='$TextColor'> $Dbstatus </Font> </td>
    	</tr>
		</table>
"@
		If ($CheckDBBackup -eq "Yes")
		{
			If ($ttt -eq "Yes")
			{
				Add-Content "$Report" $rpt1	
				If ($GenerateCSVRpt -eq "Yes")
				{
					Add-Content $CSVReport -Value "$i,$SMSDBServerName,$after and $before,NA,$dbbackup,$Dbstatus"
				}
			}
		}
	}	
	$t = "No"
	$tt = "No"
	$ttt = "No"
	$i++
	#******************************** Start *********************************
}
  
#Checking Space Report
Function InboxRpt
{
    $Server = $SMSProviderServerName
    $Server = $Server.toupper()
    $i = 0
    $rptheader=@"
    <table width='100%'><tbody>
	<tr bgcolor=$TableHeaderBGColor> <td> <b> <Font color = 'white'> Inbox Detail Status </Font> </b> </td> </tr>
    </table>
    <table width='100%' border = 0 > <tbody>
	<tr bgcolor=$TableHeaderRowBGColor>
    <td width='5%'>SNo</td>
    <td width='40%'>Folder Name</td>
    <td width='40%'>Folder Path</td>
    <td width='5%'>File Count</td>
	<td width='5%'>Folder Size</td>
	<td width='5%'>Status</td>
	</tr>
    </table>
"@
    Add-Content "$Report" $rptheader
	If ($GenerateCSVRpt -eq "Yes")
	{
		Add-Content $CSVReport -Value "Inbox Detail Status"
		Add-Content $CSVReport -Value "SNo,FolderName,Folder Path,File Count,Folder Size,Status"
	}
    $server_dir = 
    "\\$Server\SMS_$SiteCode\inboxes\adsrv.box",
    "\\$Server\SMS_$SiteCode\inboxes\aikbmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\aikbmgr.box\BAD",
    "\\$Server\SMS_$SiteCode\inboxes\aikbmgr.box\BADREPL",
    "\\$Server\SMS_$SiteCode\inboxes\aikbmgr.box\RETRY",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\BAD",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\disc.box",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\mtn.box",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\om.box",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\prov.box",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\temp",
    "\\$Server\SMS_$SiteCode\inboxes\amtproxymgr.box\wol.box",
    "\\$Server\SMS_$SiteCode\inboxes\auth",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\BADMIFS",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\BADMIFS\DeltaMismatch",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\BADMIFS\MajorMismatch",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\BADMIFS\MissingSystemClass",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\BADMIFS\NonExistentRow",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\BADMIFS\Outdated",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\process",
    "\\$Server\SMS_$SiteCode\inboxes\auth\dataldr.box\retry",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\BAD_DDRS",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\regreq",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\regreq\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\regreq\BAD_DDRS",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\userddrsonly",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\userddrsonly\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\ddm.box\userddrsonly\BAD_DDRS",
    "\\$Server\SMS_$SiteCode\inboxes\auth\sinv.box",
    "\\$Server\SMS_$SiteCode\inboxes\auth\sinv.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\sinv.box\Orphans",
    "\\$Server\SMS_$SiteCode\inboxes\auth\sinv.box\Retry",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\corrupt",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\incoming",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\incoming\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\incoming\high",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\incoming\high\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\incoming\low",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\incoming\low\bad",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\outgoing",
    "\\$Server\SMS_$SiteCode\inboxes\auth\statesys.box\process",
    "\\$Server\SMS_$SiteCode\inboxes\bgb.box",
    "\\$Server\SMS_$SiteCode\inboxes\bgb.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\businessappprocess.box",
    "\\$Server\SMS_$SiteCode\inboxes\businessappprocess.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\ccr.box",
    "\\$Server\SMS_$SiteCode\inboxes\ccr.box\inproc",
    "\\$Server\SMS_$SiteCode\inboxes\ccrretry.box",
    "\\$Server\SMS_$SiteCode\inboxes\certmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\clifiles.src",
    "\\$Server\SMS_$SiteCode\inboxes\clifiles.src\hinv",
    "\\$Server\SMS_$SiteCode\inboxes\CLOUDMGR.box",
    "\\$Server\SMS_$SiteCode\inboxes\cmupdate.box",
    "\\$Server\SMS_$SiteCode\inboxes\colfile.box",
    "\\$Server\SMS_$SiteCode\inboxes\coll_out.box",
    "\\$Server\SMS_$SiteCode\inboxes\COLLEVAL.box",
    "\\$Server\SMS_$SiteCode\inboxes\COLLEVAL.box\RETRY",
    "\\$Server\SMS_$SiteCode\inboxes\CompSumm.Box",
    "\\$Server\SMS_$SiteCode\inboxes\dataldr.box",
    "\\$Server\SMS_$SiteCode\inboxes\dataldr.box\process",
    "\\$Server\SMS_$SiteCode\inboxes\ddm.box",
    "\\$Server\SMS_$SiteCode\inboxes\ddm.box\BAD_DDRS",
    "\\$Server\SMS_$SiteCode\inboxes\ddm.box\data.col",
    "\\$Server\SMS_$SiteCode\inboxes\ddmnotif.box",
    "\\$Server\SMS_$SiteCode\inboxes\despoolr.box",
    "\\$Server\SMS_$SiteCode\inboxes\despoolr.box\receive",
    "\\$Server\SMS_$SiteCode\inboxes\distmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\distmgr.box\incoming",
    "\\$Server\SMS_$SiteCode\inboxes\distmgr.box\incoming\bad",
    "\\$Server\SMS_$SiteCode\inboxes\epmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\epmgr.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\epmgr.box\corrupt",
    "\\$Server\SMS_$SiteCode\inboxes\epmgr.box\process",
    "\\$Server\SMS_$SiteCode\inboxes\failovermgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\CFD",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\ForwardingMsg",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\ForwardingMsg\bad",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\INTL.LPK",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\ISM",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\pubkey",
    "\\$Server\SMS_$SiteCode\inboxes\hman.box\SiteReassign",
    "\\$Server\SMS_$SiteCode\inboxes\inventry.box",
    "\\$Server\SMS_$SiteCode\inboxes\inventry.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\invproc.box",
    "\\$Server\SMS_$SiteCode\inboxes\invproc.box\history",
    "\\$Server\SMS_$SiteCode\inboxes\licensemgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\mmctrl.box",
    "\\$Server\SMS_$SiteCode\inboxes\notictrl.box",
    "\\$Server\SMS_$SiteCode\inboxes\objmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\offermgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\offermgr.box\INCOMING",
    "\\$Server\SMS_$SiteCode\inboxes\offermgr.box\TMPCACHE",
    "\\$Server\SMS_$SiteCode\inboxes\OfferSum.Box",
    "\\$Server\SMS_$SiteCode\inboxes\pkginfo.box",
    "\\$Server\SMS_$SiteCode\inboxes\PkgTransferMgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\policypv.box",
    "\\$Server\SMS_$SiteCode\inboxes\polreq.box",
    "\\$Server\SMS_$SiteCode\inboxes\polreq.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\rcm.box",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\history",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\incoming",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\outbound",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\outbound\high",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\outbound\low",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\outbound\normal",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\process",
    "\\$Server\SMS_$SiteCode\inboxes\replmgr.box\ready",
    "\\$Server\SMS_$SiteCode\inboxes\RuleEngine.box",
    "\\$Server\SMS_$SiteCode\inboxes\schedule.box",
    "\\$Server\SMS_$SiteCode\inboxes\schedule.box\outboxes",
    "\\$Server\SMS_$SiteCode\inboxes\schedule.box\outboxes\LAN",
    "\\$Server\SMS_$SiteCode\inboxes\schedule.box\requests",
    "\\$Server\SMS_$SiteCode\inboxes\schedule.box\tosend",
    "\\$Server\SMS_$SiteCode\inboxes\schedule.box\UID",
    "\\$Server\SMS_$SiteCode\inboxes\sinv.box",
    "\\$Server\SMS_$SiteCode\inboxes\sinv.box\BADSinv",
    "\\$Server\SMS_$SiteCode\inboxes\sinv.box\FileCol",
    "\\$Server\SMS_$SiteCode\inboxes\sinv.box\Orphans",
    "\\$Server\SMS_$SiteCode\inboxes\sinv.box\Retry",
    "\\$Server\SMS_$SiteCode\inboxes\sinv.box\Temp",
    "\\$Server\SMS_$SiteCode\inboxes\sitecomp.box",
    "\\$Server\SMS_$SiteCode\inboxes\sitectrl.box",
    "\\$Server\SMS_$SiteCode\inboxes\sitectrl.box\incoming",
    "\\$Server\SMS_$SiteCode\inboxes\sitestat.box",
    "\\$Server\SMS_$SiteCode\inboxes\sitestat.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\smsbkup.box",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\futureq",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\outgoing",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\queue",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\retry",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\statmsgs",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\statmsgs\bad",
    "\\$Server\SMS_$SiteCode\inboxes\statmgr.box\temp",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\corrupt",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\discard",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\process",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\retry",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\temp",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\usage",
    "\\$Server\SMS_$SiteCode\inboxes\swmproc.box\usage\bad",
    "\\$Server\SMS_$SiteCode\inboxes\WSUSMgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\wsyncmgr.box",
    "\\$Server\SMS_$SiteCode\inboxes\wsyncmgr.box\bad",
    "\\$Server\SMS_$SiteCode\inboxes\wsyncmgr.box\outbox"

  
    foreach ($srvdir in $server_dir)
    {
    	if(Test-Path $srvdir)
    	{
            if((Get-ChildItem $srvdir -Recurse | where {!$_.PSIsContainer} | Measure-Object -property length -sum).sum -gt 0 -and (where {!$_.PSIsContainer} | Measure-Object | Select-Object -Expand Count).count -gt 0)
            {
            $i++
            $fname = (Get-Item -path $srvdir).Name
            $fpath = (Get-Item -path $srvdir).FullName
            $fcount = Get-ChildItem $srvdir | where {!$_.PSIsContainer} | Measure-Object | Select-Object -Expand Count
            $fsize = (Get-ChildItem $srvdir -Recurse | where {!$_.PSIsContainer} | Measure-Object -property length -sum)
            $fsize = "{0:N2}" -f ($fsize.sum / 1MB)
            $color="$OkColor"            
    		if (($fcount -gt $InboxWarningCount))# -or ($fsize -gt 1000))
            {
                $status = "Warning"
                $color="$WarningColor"
                if (($fcount -gt $InboxCriticalCount))# -or  ($fsize -gt 5000))
                {
                        $status = "Critical"
                        $color="$CriticalColor"
                }
            }
            else
            {
                $status = "Ok"
            }
            $Rpt=@"
            <table width='100%' border = 0 > <tbody>
        	<tr align='center'>
            <td width='5%' >$i</td>
            <td width='40%' align='left' >&nbsp$fname</td>
            <td width='40%' align='left' ><a href="$fpath">$fpath</td>
            <td width='5%'>$fcount</td>
        	<td width='5%'>$fsize MB</td>
        	<td width='5%' align='center' bgcolor='$color'> <Font color ='$TextColor'> $Status </Font> </td>
        	</tr>
            </table>
"@
            Add-Content "$Report" $Rpt   
			If ($GenerateCSVRpt -eq "Yes")
			{
				Add-Content $CSVReport -Value "$i,$fname,$fpath,$fcount,$fsize MB,$Status"
			}
            }			
        }
    }
}
# Run Main Report
Get-DailyHTMLReport $args[0]