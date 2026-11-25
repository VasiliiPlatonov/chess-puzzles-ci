# Учебный кластер Docker Swarm из трёх узлов docker-in-docker (Windows + Docker Desktop).
# Запуск из каталога swarm\ репозитория:
#   powershell -ExecutionPolicy Bypass -File .\cluster-up.ps1
$ErrorActionPreference = "Continue"   # ошибки docker проверяются по $LASTEXITCODE
Set-Location $PSScriptRoot
$Root = Split-Path $PSScriptRoot -Parent   # корень репозитория монтируется в менеджер

$Net = "ci-nodes"
$Img = "docker:27-dind"

function Run([string[]]$a) {            # docker с проверкой кода возврата
    & docker @a
    if ($LASTEXITCODE -ne 0) { throw "Ошибка: docker $($a -join ' ')" }
}
function Ok([string[]]$a) {             # true, если команда docker завершилась успешно
    & docker @a *> $null
    return ($LASTEXITCODE -eq 0)
}
function Mgr([string[]]$a) { Run (@("exec", "ci-manager", "docker") + $a) }

Write-Host ">> 1. Сеть узлов 192.168.56.0/24"
if (-not (Ok @("network", "inspect", $Net))) {
    Run @("network", "create", "--subnet", "192.168.56.0/24", $Net) | Out-Null
}

function Start-Node([string]$name, [string]$ip, [string[]]$extra) {
    if (Ok @("inspect", $name)) {
        Run @("start", $name) | Out-Null
    } else {
        Run (@("run", "-d", "--privileged", "--name", $name, "--hostname", $name,
               "--network", $Net, "--ip", $ip, "-e", "DOCKER_TLS_CERTDIR=",
               "-v", "$name-docker:/var/lib/docker") + $extra + @($Img)) | Out-Null
    }
}

Write-Host ">> 2. Узлы ci-manager, ci-worker-1, ci-worker-2"
Start-Node "ci-manager"  "192.168.56.10" @("-p", "80:80", "-v", "${Root}:/opt/ci")
Start-Node "ci-worker-1" "192.168.56.11" @()
Start-Node "ci-worker-2" "192.168.56.12" @()
foreach ($n in "ci-manager", "ci-worker-1", "ci-worker-2") {
    while (-not (Ok @("exec", $n, "docker", "info"))) { Start-Sleep 2 }
}
Run @("exec", "ci-manager", "apk", "add", "--no-cache", "bash", "curl", "coreutils") | Out-Null

Write-Host ">> 3. Инициализация Swarm"
$state = & docker exec ci-manager docker info --format "{{.Swarm.LocalNodeState}}"
if ($state -ne "active") { Mgr @("swarm", "init", "--advertise-addr", "192.168.56.10") | Out-Null }
$token = (& docker exec ci-manager docker swarm join-token -q worker).Trim()
foreach ($w in "ci-worker-1", "ci-worker-2") {
    $s = & docker exec $w docker info --format "{{.Swarm.LocalNodeState}}"
    if ($s -ne "active") {
        Run @("exec", $w, "docker", "swarm", "join", "--token", $token, "192.168.56.10:2377") | Out-Null
    }
}
Mgr @("node", "update", "--label-add", "ci.jenkins=true", "ci-manager") | Out-Null
Mgr @("node", "update", "--label-add", "ci.storage=true", "ci-worker-1") | Out-Null

Write-Host ">> 4. Секреты"
function Make-Secret([string]$name, [string]$prompt) {
    if (Ok @("exec", "ci-manager", "docker", "secret", "inspect", $name)) { return }
    $sec = Read-Host -AsSecureString $prompt
    $val = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
           [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
    Run @("exec", "-e", "SECRET_VAL=$val", "ci-manager", "sh", "-c",
          "printf '%s' `"`$SECRET_VAL`" | docker secret create $name -") | Out-Null
}
Make-Secret "jenkins_admin_password" "Пароль администратора Jenkins"
Make-Secret "telegram_bot_token"     "Токен Telegram-бота"
Make-Secret "telegram_chat_id"       "ID чата Telegram"

Write-Host ">> 5. Развёртывание (сборка образа Jenkins займёт 20-60 минут)"
Run @("exec", "-w", "/opt/ci/swarm", "ci-manager", "bash", "./deploy.sh")

Write-Host ""
Write-Host "Готово. Добавьте в C:\Windows\System32\drivers\etc\hosts строку:"
Write-Host "  127.0.0.1 jenkins.ci.local apk.ci.local portainer.ci.local traefik.ci.local"
Write-Host "Состояние Jenkins: docker exec ci-manager docker service ps ci_jenkins"
