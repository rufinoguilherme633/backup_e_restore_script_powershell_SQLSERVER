$caminho = ""
$nomeServidor = ""
$usuarioBanco = ''
$senha = ''

# Cria a pasta se não existir
if (-not (Test-Path $caminho)) {
    return
}


$bancos = Get-ChildItem -Path $caminho -File -Filter *.bak -Recurse

foreach ($arquivo in $bancos) {
    $arquivoBackupSQL = $arquivo.FullName
    $nomeBanco = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)
    Write-Host "Fazendo restore do banco: $nomeBanco"

    # Script T-SQL com loop para matar todas as conexões
    $sql = @"
DECLARE @spid INT;
 BEGIN TRY
-- Loop que mata todas as conexões existentes no banco, exceto a sessão atual
WHILE EXISTS (SELECT 1 FROM sys.dm_exec_sessions WHERE database_id = DB_ID('$nomeBanco') AND session_id <> @@SPID)
BEGIN
    SELECT TOP 1 @spid = session_id
    FROM sys.dm_exec_sessions
    WHERE database_id = DB_ID('$nomeBanco') AND session_id <> @@SPID;

    EXEC('KILL ' + @spid);
END;

-- Coloca o banco em SINGLE_USER
ALTER DATABASE [$nomeBanco] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- Faz o restore
RESTORE DATABASE [$nomeBanco] FROM DISK = N'$arquivoBackupSQL' WITH REPLACE, RECOVERY;

-- Volta para MULTI_USER
ALTER DATABASE [$nomeBanco] SET MULTI_USER;
END TRY 
BEGIN CATCH

    DECLARE @msg NVARCHAR(4000);
    SET @msg = 'Erro: ' + ERROR_MESSAGE();
 
    DECLARE @cmd NVARCHAR(4000);
    SET @cmd = 'echo ' + CONVERT(VARCHAR(19), GETDATE(), 120) + ' - ' + @msg + ' >> C:\logs\meu_log.txt';
 
    EXEC xp_cmdshell @cmd;
 
END CATCH
"@

    try {
        sqlcmd -S $nomeServidor -U $usuarioBanco -P $senha -Q $sql
        Write-Host "Restore do banco $nomeBanco concluído com sucesso."
    } catch {
        Write-Host ("Erro ao executar o restore do {0}: {1}" -f $nomeBanco, $_)
    }
}


