$caminhoBackup = ""; 
$nomeServidor = ""; 
$usuarioBanco = '';
$senha = ''; 
 # Cria a pasta se não existir 
 if (-not (Test-Path $caminhoBackup)) { 
    New-Item -ItemType Directory -Path $caminhoBackup | Out-Null 
 } 
 ##select para pegar todos os databases diferente dos databases do s
 $listaBancos = sqlcmd -S $nomeServidor -U $usuarioBanco -P $senha -Q "set nocount on; select name from sys.databases where name not in ('master','tempdb','model','msdb')" -h -1 -W; 
 
 ##a cada database que passar fará um backup dele
 foreach($Banco in $listaBancos){ 
    $arquivoBackupSQL = "$caminhoBackup\$Banco.bak";
    $sql = "BACKUP DATABASE [$Banco] TO DISK = N'$arquivoBackupSQL'" 
    Write-Host "Fazendo backup do banco: $Banco" 
    try {
        sqlcmd -S $nomeServidor -U $usuarioBanco -P $senha -Q $sql 
    }catch {
        Write-Host ("Erro ao restaurar o banco {0}: {1}" -f $nomeBanco, $_)
    }
 }