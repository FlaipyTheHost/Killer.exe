
Write-Host " ██╗  ██╗██╗██╗     ██╗     ███████╗██████╗    ███████╗██╗  ██╗███████╗ "   -ForegroundColor Green
Write-Host " ██║ ██╔╝██║██║     ██║     ██╔════╝██╔══██╗   ██╔════╝╚██╗██╔╝██╔════╝ "   -ForegroundColor Green
Write-Host " █████╔╝ ██║██║     ██║     █████╗  ██████╔╝   █████╗   ╚███╔╝ █████╗   "   -ForegroundColor Green
Write-Host " ██╔═██╗ ██║██║     ██║     ██╔══╝  ██╔══██╗   ██╔══╝   ██╔██╗ ██╔══╝   "   -ForegroundColor Green
Write-Host " ██║  ██╗██║███████╗███████╗███████╗██║  ██║██╗███████╗██╔╝ ██╗███████╗  (By Carlos)"  -ForegroundColor Green
Write-Host " ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝  v3.8"   -ForegroundColor Green

function LogoffUsuario {
    param(
        [string[]]$usuarios
    )

    foreach ($usuario in $usuarios) {
        $idSessao = (quser | Where-Object { $_ -match $usuario } | ForEach-Object { ($_ -split '\s+')[2] })

        if ($idSessao -ne $null) {
            logoff $idSessao
            Write-Host "Logoff realizado para o usuario: $usuario"
        } else {
            Write-Host "Usuario $usuario nao encontrado."
        }
    }
}

function LogoffDesconectados {
    $usuariosDesconectados = quser | Where-Object { $_ -match "Disc" } | ForEach-Object { ($_ -split '\s+')[1] }

    # entao, aqui ele vai tirar o administrador da lista
    $usuariosDesconectados = $usuariosDesconectados | Where-Object { $_ -ne "Administrador" }

    if ($usuariosDesconectados) {
        LogoffUsuario -usuarios $usuariosDesconectados
    } else {
        Write-Host "Nao ha usuarios desconectados para fazer logoff, exceto o Administrador."
    }
}

function MatarProcesso {
    param(
        [string]$entrada,
        [string[]]$ips
    )

    $processosMortos = @{}
    $processoPCSIS = "PCSIS$entrada.exe"
    $processoPCNOV = "PCNOV$entrada.exe"


    foreach ($ip in $ips) {
        $processosMortos[$ip] = 0
        
        $processos = Get-WmiObject Win32_Process -ComputerName $ip -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $processoPCSIS -or $_.Name -eq $processoPCNOV }

        if ($processos) {
            try {
                $processos | ForEach-Object {
                    $null = Invoke-WmiMethod -InputObject $_ -Name Terminate
                    $processosMortos[$ip]++
                }
                Write-Host "$($processosMortos[$ip]) processos foram mortos no servidor $ip."
            }
            catch {
                Write-Host "Erro ao tentar matar os processos em $ip. Motivo: $($_.Exception.Message)"
            }
        } else {
            Write-Host "Nenhum processo '$processoPCSIS' ou '$processoPCNOV' encontrado em $ip."
        }
    }
}



do {
    $entrada = Read-Host -Prompt "Digite a rotina, usuarios ou argumentos, em caso de duvida digite ""manual"""

    if ($entrada -match '^\d+$') { # Verifica se a entrada contem apenas numeros
        MatarProcesso -entrada $entrada -ips "192.168.1.1", "192.168.1.2", "192.168.1.3", "192.168.1.4", "192.168.1.5"
    }
    elseif ($entrada -eq "desconectados") {
        LogoffDesconectados
    } elseif ($entrada -eq "todos") {
        $senha = Read-Host "Digite a senha para prosseguir"
        if ($senha -eq "S3nh4P0d3r0s4") {
            # aqui ele vai desconecta todos os usuarios exceto o Administrador
            $todosExcetoAdmin = quser | ForEach-Object { $usuario = ($_ -split '\s+')[0] 
            if ($usuario -ne "USERNAME") { $usuario } }
            Write-Host $todosExcetoAdmin
            $confirmacao = Read-Host "Serao desconectados, deseja REALMENTE prosseguir? (s/N)"
            if ($confirmacao -eq "S" -or $confirmacao -eq "s") {
                LogoffUsuario -usuarios $todosExcetoAdmin
            }
            else
            {
                Write-Host "Operacao cancelada pelo usuario."
            }
        }
        else 
        {
            Write-Host "Senha incorreta. Voce nao tem permissao para isto!"
        }
    } elseif ($entrada -eq "manual") {
        Write-Host ""
        Write-Host "Insira o numero da rotina que ela sera encerrada em todos os usuarios:"
        Write-Host "    > 1709"
        Write-Host ""
        Write-Host "Insira o nome de um usuario que ele buscara por correspondencia mais proxima e deslogara:"
        Write-Host "    > felipe.martins"
        Write-Host ""
        Write-Host "Insira varios seguidos de "";"" para poder deslogar em massa:"
        Write-Host "    > thais.monteiro;rafael.bonfim;joao.pereira"
        Write-Host ""
        Write-Host "Insira ""desconectados"" que todos os usuarios desconectados irao fazer logoff"
        Write-Host "    > desconectados"
        Write-Host ""
        Write-Host "Insira ""todos"" que todos os usuarios com excecao do Administrador irao fazer logoff:"
        Write-Host "    > todos"
    } else {
        $listaUsuarios = $entrada -split ';'
        LogoffUsuario -usuarios $listaUsuarios
    }

    $continuar = Read-Host "Deseja fazer mais alguma operacao? (S/N)"
} while ($continuar -eq "S" -or $continuar -eq "s")