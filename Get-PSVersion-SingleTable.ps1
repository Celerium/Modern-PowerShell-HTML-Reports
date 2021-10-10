#Region    [ Script Paramters ]
param(

        [Parameter(Mandatory=$false)]
        [ValidateSet('None','Audit')]
        [String]$Audit = 'None',

        [Parameter(Mandatory=$false)]
        [ValidateSet('All','CSV','HTML')]
        [String]$Report = 'CSV',

        [Parameter(Mandatory=$false)]
        [Switch]$ShowReport
    )
#EndRegion [ Script Paramters ]

#Region    [ PowerShell Function ]
    ''
    Write-Output "START - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
    ''

        Write-Output " - (1/3) - $(Get-Date -Format MM-dd-HH:mm) - Gathering PowerShell Versions"

    Function Get-PSVersion{
        <#
            .SYNOPSIS
            Provides PowerShell version information

            .Description
            Provides both Both PowerShell and PowerShell Core version information

            .Link
            https://celerium.org

            .EXAMPLE
            Get-PSVersion

            .Notes
            This is a proof of concept script to see If I could create better HTML reports
        #>
            Try{
                $PSInfo = $PSVersionTable
                $PowerShell7 = (Test-Path -Path "C:\Program Files\PowerShell\7\pwsh.exe")
                $OSInformation = Get-CimInstance -ClassName Win32_Operatingsystem

                $ParameterSplat =
                        @{Name='Computer';Expression={($OSInformation).CSName}}, `
                        @{Name='OperatingSystem';Expression={($OSInformation).Caption}}, `
                        @{Name='PSVersion';Expression={($_.PSVersion).ToString()}}, `
                        @{Name='PSCLRVersion';Expression={If($Null -eq $_.CLRVersion){([System.Reflection.Assembly]::GetExecutingAssembly().ImageRuntimeVersion).Replace("v","")}Else{($_.CLRVersion).ToString()}}}, `
                        @{Name='PSWSManStackVersion';Expression={($_.WSManStackVersion).ToString()}}, `
                        @{Name='PSRemotingProtocolVersion';Expression={($_.PSRemotingProtocolVersion).ToString()}}, `
                        @{Name='PSSerializationVersion';Expression={($_.SerializationVersion).ToString()}}, `
                        @{Name='PSBuildVersion';Expression={If($Null -eq $_.BuildVersion){'N\A'}Else{($_.BuildVersion).ToString()}}}, `
                        @{Name='PSEdition';Expression={$_.PSEdition}}, `
                        @{Name='PSOS';Expression={If($Null -eq $_.OS){(($OSInformation).Caption -replace "(?<=Microsoft Windows).*")+" "+($OSInformation).Version}Else{$_.OS}}}, ` #positive reverse lookup
                        @{Name='PSPlatform';Expression={If($Null -eq $_.Platform){"Win32NT"}Else{$_.Platform}}},`
                        @{Name='PSCompatibleVersions';Expression={$_.PSCompatibleVersions -Join(',')}}

                If ($PowerShell7 -eq $False){
                        #PSVersion 1-5
                        $PSInfo | Select-Object $ParameterSplat
                }
                ElseIf($PowerShell7 -eq $True){
                    #PSVersion 1-5
                        $PSInfo = powershell.exe -nologo -noprofile -command {$PSVersionTable}
                            $PSInfo | Select-Object $ParameterSplat

                        #PSVersion 7+
                        $PSInfo = pwsh -nologo -noprofile -command {$PSVersionTable}
                            $PSInfo | Select-Object $ParameterSplat
                }
                Else{$PSVersionTable | Select-Object $ParameterSplat
                }
            }
            Catch{
                    $ErrorMessage = $_ | Out-String
                    Write-Host ($ErrorMessage).Trim() -ForegroundColor Red -BackgroundColor Black
                }
            Finally{
                    #Future Use
                }
            }

#EndRegion [ PowerShell Function ]

#Region    [ Report\Script Variables ]

    $PSVersion = Get-PSVersion

    #$ScriptName = $MyInvocation.MyCommand.Name
    $ScriptName = 'Get-PSVersion'
    $ReportFolderName = "$ScriptName-Report"
    $FileDate = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $HTMLDate = (Get-Date -Format 'yyyy-MM-dd h:mmtt').ToLower()

    $FQDN = ((Get-CimInstance -ClassName Win32_ComputerSystem).Domain).Split('.')[0]
    $ShortFQDN = ($FQDN).Split('.')[0]
    $DomainController = ($env:LOGONSERVER).Replace('\\','')

    #Define Logging Location
    Try{
        If ($Audit -eq 'None'){
            $Log = "C:\Audits\Logs\$ReportFolderName"
        }
        If ($Audit -eq 'Audit'){
            $Log = "C:\Audits\Logs\$ShortFQDN-$Audit-Audit-Reports\$ReportFolderName"
        }
    }
    Catch{
        $ErrorMessage = $_ | Out-String
        Write-Host ($ErrorMessage).Trim() -ForegroundColor Red -BackgroundColor Black
        break
    }

    #Create Logging Location
    Try{
        If (Test-Path -Path $Log -PathType Container){$Null}
        Else{
            New-Item -Path $Log -ItemType Directory | Out-Null
        }
    }
    Catch{
        $ErrorMessage = $_ | Out-String
        Write-Host ($ErrorMessage).Trim() -ForegroundColor Red -BackgroundColor Black
        break
    }

    #Log Names
    $CSVReport  = "$Log\$ShortFQDN-$ScriptName-Report-$($FileDate).csv"
    $HTMLReport = "$Log\$ShortFQDN-$ScriptName-Report-$($FileDate).html"


#EndRegion [ Report\Script Variables ]

#Region     [ CSV Report ]
    Try{
        If($Report -eq 'All' -or $Report -eq 'CSV'){
            Write-Output " - (2/3) - $(Get-Date -Format MM-dd-HH:mm) - Generating CSV"
            $PSVersion | Sort-Object Computer | Select-Object $Scriptname,* | Export-Csv $CSVReport -NoTypeInformation
        }
    }
    Catch{
        $ErrorMessage = $_ | Out-String
        Write-Host ($ErrorMessage).Trim() -ForegroundColor Red -BackgroundColor Black
        break
    }

#EndRegion  [ CSV Report ]

#Region    [ HTML Report]

    Try{
        If($Report -eq 'All' -or $Report -eq 'HTML'){
            Write-Output " - (3/2) - $(Get-Date -Format MM-dd-HH:mm) - Generating HTML"
    #Region    [ HTML Report Building Blocks ]

        # Build the HTML header
        # This grabs the raw text from files to shorten the amount of lines in the PSScript
        # General idea is that the HTML assets would infrequently be changed once set
            $Meta = Get-Content -Path "$PSScriptRoot\Assets\Meta.html" -Raw
            $Meta = $Meta -replace 'xTITLECHANGEx',"$ScriptName"
            $CSS = Get-Content -Path "$PSScriptRoot\Assets\Styles.css" -Raw
            $JavaScript = Get-Content -Path "$PSScriptRoot\Assets\JavaScriptHeader.html" -Raw
            $Head = $Meta + ("<style>`n") + $CSS + ("`n</style>") + $JavaScript

        # HTML Body Building Blocks (In order)
            $TopNav = Get-Content -Path "$PSScriptRoot\Assets\TopBar.html" -Raw
            $DivMainStart = '<div id="layoutSidenav">'
            $SideBar = Get-Content -Path "$PSScriptRoot\Assets\SideBar.html" -Raw
            $SideBar = $SideBar -replace ('xTIMESETx',"$HTMLDate")
            $DivSecondStart = '<div id="layoutSidenav_content">'
            $PreLoader = Get-Content -Path "$PSScriptRoot\Assets\PreLoader.html" -Raw
            $MainStart = '<main>'

        #Base Table Container
            $BaseTableContainer = Get-Content -Path "$PSScriptRoot\Assets\TableContainer.html" -Raw

        #Summary Header
            $SummaryTableContainer = $BaseTableContainer
            $SummaryTableContainer = $SummaryTableContainer -replace ('xHEADERx',"$ScriptName - Summary")
            $SummaryTableContainer = $SummaryTableContainer -replace ('xBreadCrumbx',"Data gathered from $DomainController")

        #Summary Cards
        #HTML in Summary.html would be edited depending on the report and summary info you want to show
            $SummaryCards = Get-Content -Path "$PSScriptRoot\Assets\Summary.html" -Raw
            $SummaryCards = $SummaryCards -replace ('xCARD1Valuex','$100.00')
            $SummaryCards = $SummaryCards -replace ('xCARD2Valuex','$125,525.00')
            $SummaryCards = $SummaryCards -replace ('xCARD3Valuex','80%')

        #Body table headers, would be duplicated\adjusted depending on how many tables you want to show
            $BodyTableContainer = $BaseTableContainer
            $BodyTableContainer = $BodyTableContainer -replace ('xHEADERx',"$ScriptName - Details")
            $BodyTableContainer = $BodyTableContainer -replace ('xBreadCrumbx',"Data gathered from $DomainController")

        #Ending HTML
            $DivEnd = '</div>'
            $MainEnd = '</main>'
            $JavaScriptEnd = Get-Content -Path "$PSScriptRoot\Assets\JavaScriptEnd.html" -Raw

    #EndRegion [ HTML Report Building Blocks ]
    #Region    [ Example HTML Report Data\Structure ]

        #Temp data filler to simulate large tables of data
        #Used just an an example
        $PSVersion = [Array]$PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion +
                            $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion +
                            $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion +
                            $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion +
                            $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion + $PSVersion

        #Creates an HTML table from PowerShell function results without any extra HTML tags
        $TableResults = $PSVersion | ConvertTo-Html -As Table -Fragment -Property Computer,OperatingSystem,PSVersion,PSBuildVersion,PSEdition,PSOS `
                                        -PostContent    '   <ul>
                                                                <li>Note: SAMPLE 1 = Only applies stuff and things</li>
                                                                <li>Note: SAMPLE 2 = Only applies stuff and things</li>
                                                                <li>Note: SAMPLE 3 = Only applies stuff and things</li>
                                                            </ul>
                                                        '

        #Table section segragation
        #PS doesnt create a <thead> tag so I have find the first row and make it so
        $TableHeader = $TableResults -split "`r`n" | Where-Object {$_ -match '<th>'}
        #Unsure why PS makes empty <colgroup> as it contains no data
        $TableColumnGroup = $TableResults -split "`r`n" | Where-Object {$_ -match '<colgroup>'}

        #Table ModIfications
        #Replacing empty html table tags with simple replacable names
        #It was annoying me that empty rows showed in the raw HTML and I couldnt delete them as they were not $NUll but were empty
        $TableResults = $TableResults -replace ($TableHeader,'xblanklinex')
        $TableResults = $TableResults -replace ($TableColumnGroup,'xblanklinex')
        $TableResults = $TableResults | Where-Object {$_ -ne 'xblanklinex'} | ForEach-Object {$_.Replace('xblanklinex','')}

        #Inject Modifyied data back into the table
        #Makes the table have a <thead> tag
        $TableResults = $TableResults -replace '<Table>',"<Table>`n<thead>$TableHeader</thead>"
        $TableResults = $TableResults -replace '<table>','<table class="dataTable-table" style="width: 100%;">'

        #Mark Focus Data to draw attention\talking points
        #Need to understand RegEx more as this doesnt scale at all
        $TableResults = $TableResults -replace '<td>7.1.4</td>','<td class="GoodStatus">7.1.4</td>'
        $TableResults = $TableResults -replace '<td>5.1.19041.1237</td>','<td class="BadStatus">5.1.19041.1237</td>'
        $TableResults = $TableResults -replace '<td>N\\A</td>','<td class="WarningStatus">N\A</td>' # RegEx \ to escape the other \
        $TableResults = $TableResults -replace '<td>Core</td>','<td class="InfoStatus">Core</td>'


        #Building the final HTML report using the various ordered HTML building blocks from above.
        #This is injecting html\css\javascript in a certain order into a file to make an HTML report
        $HTML = ConvertTo-HTML -Head $Head -Body "  $TopNav $DivMainStart $SideBar $DivSecondStart $PreLoader $MainStart
                                                    $SummaryTableContainer $SummaryCards $DivEnd $DivEnd $DivEnd
                                                    $BodyTableContainer $TableResults $DivEnd $DivEnd $DivEnd
                                                    $MainEnd $DivEnd $DivEnd $JavaScriptEnd
                                                "
        $HTML = $HTML -replace '<body>','<body class="sb-nav-fixed">'
        $HTML | Out-File $HTMLReport -Encoding utf8

    }
}
Catch{
    $ErrorMessage = $_ | Out-String
    Write-Host ($ErrorMessage).Trim() -ForegroundColor Red -BackgroundColor Black
    break
}
    #EndRegion [ Example HTML Report Data\Structure ]
#EndRegion [ HTML Report ]

#Region    [ Show Report]

#Open File Explorer to show log output
    If ($ShowReport){

        Invoke-Item $Log

    }

''
Write-Output "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
''
#EndRegion [ Show Report]