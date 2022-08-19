using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
#region auth
if ($env:MSI_SECRET) { $token = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/").Token }
else {
  Disable-AzContextAutosave -Scope Process | Out-Null
  $cred = New-Object System.Management.Automation.PSCredential $env:AppID, ($env:ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
  Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $env:TenantID
  $token = (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token
  $authHeader = @{Authorization = "Bearer $token"}
}
#region main process
$params = @{
    Method = 'Get'
    Uri = 'https://graph.microsoft.com/beta/devices'
    Headers = @{Authorization = "Bearer $token"}
    ContentType = 'Application/Json'
}
$restCall = Invoke-RestMethod @params
Write-Output "Devices Found: $($restCall.value.count)"
$resp = $restCall.value | ConvertTo-Json -Depth 100
$statusCode = [HttpStatusCode]::OK
$body = $resp
#endregion
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode    
        Body = $body
    })