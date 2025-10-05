function Test-PrtgLogin {

    if(Get-PrtgClient){
        #Do nothing, already connected to PRTG server
        Write-Verbose "Already connected to PRTG server"
    }else{
        Write-Verbose "Not yet connected, propmting for connection details"
        Connect-PrtgServer
    }

}