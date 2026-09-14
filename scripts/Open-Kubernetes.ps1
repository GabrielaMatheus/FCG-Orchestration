$ErrorActionPreference='Stop'
$context='kind-fcg-fase3'
kubectl --context $context -n fcg get deployments
if($LASTEXITCODE -ne 0){throw 'Cluster fcg-fase3 indisponivel.'}
# Os encaminhamentos sao encerrados junto com esta sessao. Portas distintas preservam o Compose.
$processes=@()
try {
    foreach($item in @(@('kong','18000:8000'),@('grafana','13000:3000'),@('prometheus','19090:9090'),@('loki','13100:3100'),@('rabbitmq','5673:5672'))) {
        $processes+=Start-Process kubectl -ArgumentList @('--context',$context,'-n','fcg','port-forward',"service/$($item[0])",$item[1]) -WindowStyle Hidden -PassThru
    }
    Write-Host 'Gateway http://localhost:18000 | Grafana http://localhost:13000 | Prometheus http://localhost:19090'
    Write-Host 'Loki http://localhost:13100 | RabbitMQ localhost:5673'
    Write-Host 'Mantenha este terminal aberto. Ctrl+C encerra os encaminhamentos.'
    while($true) {
        foreach($process in $processes){if($process.HasExited){throw 'Um encaminhamento encerrou; verifique o cluster e as portas.'}}
        Start-Sleep -Seconds 2
    }
} finally {
    foreach($process in $processes){if(-not $process.HasExited){Stop-Process -Id $process.Id}}
}
