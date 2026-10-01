# Baixa todas as imagens do site antigo (Wix) para a pasta "img"
# e troca os links nos arquivos .html para usar as imagens locais.
# Como usar: clique com o botao direito neste arquivo > "Executar com o PowerShell".

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
New-Item -ItemType Directory -Force -Path "img" | Out-Null

$prefixo = "https://static.wixstatic.com/media/"
$arquivosHtml = Get-ChildItem -Filter *.html
$nomes = @()
foreach ($f in $arquivosHtml) {
    $conteudo = Get-Content $f.FullName -Raw -Encoding UTF8
    $achados = [regex]::Matches($conteudo, [regex]::Escape($prefixo) + '([^"\s)]+)')
    foreach ($m in $achados) { $nomes += $m.Groups[1].Value }
}
$nomes = $nomes | Sort-Object -Unique

$erros = 0
foreach ($n in $nomes) {
    $destino = Join-Path "img" $n
    if (Test-Path $destino) { continue }
    try {
        Invoke-WebRequest -Uri ($prefixo + $n) -OutFile $destino -UseBasicParsing
        Write-Host "OK  $n"
    } catch {
        Write-Host "ERRO ao baixar $n" -ForegroundColor Red
        $erros++
    }
}

if ($erros -gt 0) {
    Write-Host "`n$erros imagem(ns) nao baixaram. Os links NAO foram trocados. Rode o script de novo." -ForegroundColor Yellow
} else {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    foreach ($f in $arquivosHtml) {
        $conteudo = Get-Content $f.FullName -Raw -Encoding UTF8
        [System.IO.File]::WriteAllText($f.FullName, $conteudo.Replace($prefixo, "img/"), $utf8)
    }
    Write-Host "`nPronto! $($nomes.Count) imagens salvas em img\ e links atualizados." -ForegroundColor Green
}
Read-Host "Pressione Enter para fechar"
