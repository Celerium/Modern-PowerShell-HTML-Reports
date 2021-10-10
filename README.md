<img src="https://wp.me/aapwpb-kU" width="1080" height="167">

# Modern PowerShell HTML Reports

This project is aimed at trying to generate more modern HTML reports from PowerShell.

##### Everything in here is a proof of concept right now.

## Goals for this Project:

- Goal 1: Create a modern HTML report using PowerShell
- Goal 2: Reports will not require a webserver
- Goal 3: Reports should be mobile friendly
- Goal 4: Reports should be easily adaptable
- Goal 5: A report should look the same when accessed offline

## How-To:
As of 2021-10, this proof of concept gathers the PowerShell version installed on a Windows computer and sends the results to a CSV and or an HTML file. Tested and it works on PowerShell 5+.

1. Download the [GitHub repo](https://github.com/Celerium/Modern-HTML-Reports/archive/refs/heads/main.zip)
2. Open PowerShell & run either Get-PSVersion-*.ps1 scripts
3. ``` .\Get-PSVersion-MultiTable.ps1 -Report All -ShowReport ```
   - Note: Both scripts are identical and the only difference is that the "MultiTable" script shows how a report would look if you generated multiple tables in the same HTML report.
   - [ -Report ] All,CSV, HTML
     - Gives you the option to generate a report in a CSV, HTML, or both.
   - [ -ShowReport ] This opens the report folder located at "C:\Audits\Logs" that is created when the script is run


## Example:

-Command ``` .\Get-PSVersion-MultiTable.ps1 -Report All -ShowReport ```

<img src="https://celerium.org/wp-content/uploads/2021/10/Celerium-HTMLCSSJS-Example.png">

`