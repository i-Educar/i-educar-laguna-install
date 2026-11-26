#!/usr/bin/env php
<?php

/**
 * Garante path repositories + require @dev dos pacotes Laguna no composer.json do core.
 * Uso: php wire-composer.php /caminho/para/i-educar
 */

declare(strict_types=1);

$root = $argv[1] ?? '';
if ($root === '' || ! is_dir($root) || ! is_file($root.'/composer.json')) {
    fwrite(STDERR, "Uso: php wire-composer.php /caminho/para/i-educar\n");
    exit(1);
}

$composerFile = $root.'/composer.json';
$json = json_decode((string) file_get_contents($composerFile), true);
if (! is_array($json)) {
    fwrite(STDERR, "composer.json inválido\n");
    exit(1);
}

/** @var list<array{name:string,path:string,autoload?:array<string,string>}> $packages */
$packages = [
    ['name' => 'buriti/i-educar-exportacao-unificada-package', 'path' => 'packages/buriti/i-educar-exportacao-unificada-package', 'autoload' => ['iEducar\\Packages\\BuritiExportacaoUnificada\\' => 'src/']],
    ['name' => 'buriti/i-educar-escolar-aderencia-package', 'path' => 'packages/buriti/i-educar-escolar-aderencia-package', 'autoload' => ['iEducar\\Packages\\BuritiEscolarAderencia\\' => 'src/']],
    ['name' => 'buriti/i-educar-transporte-escolar-v2', 'path' => 'packages/buriti/i-educar-transporte-escolar-v2', 'autoload' => ['iEducar\\Packages\\BuritiTransporteEscolar\\' => 'src/']],
    ['name' => 'portabilis/pre-matricula-digital', 'path' => 'packages/portabilis/pre-matricula-digital'],
    ['name' => 'buriti/i-educar-educacenso-import-package', 'path' => 'packages/buriti/i-educar-educacenso-import-package', 'autoload' => ['iEducar\\Packages\\BuritiEducacensoImport\\' => 'src/']],
    ['name' => 'buriti/i-educar-alimentacao-escolar-package', 'path' => 'packages/buriti/i-educar-alimentacao-escolar-package', 'autoload' => ['iEducar\\Packages\\BuritiAlimentacaoEscolar\\' => 'src/']],
    ['name' => 'buriti/i-educar-almoxarifado-escolar-package', 'path' => 'packages/buriti/i-educar-almoxarifado-escolar-package', 'autoload' => ['iEducar\\Packages\\BuritiAlmoxarifadoEscolar\\' => 'src/']],
    ['name' => 'buriti/i-educar-servidor-educacional-package', 'path' => 'packages/buriti/i-educar-servidor-educacional-package', 'autoload' => ['iEducar\\Packages\\BuritiServidorEducacional\\' => 'src/']],
    ['name' => 'buriti/i-educar-contratacoes-temporarias-package', 'path' => 'packages/buriti/i-educar-contratacoes-temporarias-package', 'autoload' => ['iEducar\\Packages\\BuritiContratacoesTemporarias\\' => 'src/']],
    ['name' => 'buriti/i-educar-horario-automatico-package', 'path' => 'packages/buriti/i-educar-horario-automatico-package', 'autoload' => ['iEducar\\Packages\\BuritiHorarioAutomatico\\' => 'src/']],
    ['name' => 'buriti/i-educar-eventos-formacao-package', 'path' => 'packages/buriti/i-educar-eventos-formacao-package', 'autoload' => ['iEducar\\Packages\\BuritiEventosFormacao\\' => 'src/']],
    ['name' => 'buriti/i-educar-atendimento-estudante-package', 'path' => 'packages/buriti/i-educar-atendimento-estudante-package', 'autoload' => ['iEducar\\Packages\\BuritiAtendimentoEstudante\\' => 'src/']],
    ['name' => 'buriti/i-educar-biblioteca-package', 'path' => 'packages/buriti/i-educar-biblioteca-package', 'autoload' => ['iEducar\\Packages\\BuritiBiblioteca\\' => 'src/']],
    ['name' => 'buriti/i-educar-solicitacao-servicos-package', 'path' => 'packages/buriti/i-educar-solicitacao-servicos-package', 'autoload' => ['iEducar\\Packages\\BuritiSolicitacaoServicos\\' => 'src/']],
    ['name' => 'buriti/i-educar-apps-api-package', 'path' => 'packages/buriti/i-educar-apps-api-package', 'autoload' => ['iEducar\\Packages\\BuritiAppsApi\\' => 'src/']],
    ['name' => 'buriti/i-educar-busca-ativa-package', 'path' => 'packages/buriti/i-educar-busca-ativa-package', 'autoload' => ['iEducar\\Packages\\BuritiBuscaAtiva\\' => 'src/']],
    ['name' => 'buriti/i-educar-rh-educacional-package', 'path' => 'packages/buriti/i-educar-rh-educacional-package', 'autoload' => ['iEducar\\Packages\\BuritiRhEducacional\\' => 'src/']],
    ['name' => 'buriti/i-educar-laguna-ambiente-package', 'path' => 'packages/buriti/i-educar-laguna-ambiente-package', 'autoload' => ['iEducar\\Packages\\BuritiLagunaAmbiente\\' => 'src/']],
    ['name' => 'buriti/i-educar-setup-package', 'path' => 'packages/buriti/i-educar-setup-package', 'autoload' => [
        'iEducar\\Packages\\BuritiSetup\\' => 'src/',
        'iEducar\\Packages\\BuritiSetup\\Database\\Seeders\\' => 'database/seeders/',
    ]],
];

$json['repositories'] = $json['repositories'] ?? [];
$json['require'] = $json['require'] ?? [];
$json['autoload'] = $json['autoload'] ?? [];
$json['autoload']['psr-4'] = $json['autoload']['psr-4'] ?? [];

$existingPaths = [];
foreach ($json['repositories'] as $repo) {
    if (($repo['type'] ?? '') === 'path' && isset($repo['url'])) {
        $existingPaths[$repo['url']] = true;
    }
}

$addedRepo = 0;
$addedReq = 0;
$addedAuto = 0;

foreach ($packages as $pkg) {
    $path = $pkg['path'];
    if (! is_dir($root.'/'.$path)) {
        fwrite(STDOUT, "SKIP (pasta ausente) {$path}\n");
        continue;
    }

    if (empty($existingPaths[$path])) {
        $json['repositories'][] = [
            'type' => 'path',
            'url' => $path,
            'options' => ['symlink' => true],
        ];
        $existingPaths[$path] = true;
        $addedRepo++;
    }

    if (! isset($json['require'][$pkg['name']])) {
        $json['require'][$pkg['name']] = '@dev';
        $addedReq++;
    }

    foreach (($pkg['autoload'] ?? []) as $ns => $rel) {
        $map = $path.'/'.ltrim($rel, '/');
        if (! isset($json['autoload']['psr-4'][$ns])) {
            $json['autoload']['psr-4'][$ns] = $map;
            $addedAuto++;
        }
    }
}

if ($addedRepo === 0 && $addedReq === 0 && $addedAuto === 0) {
    fwrite(STDOUT, "OK composer.json já contém os pacotes Laguna (nada a alterar)\n");
    exit(0);
}

ksort($json['require']);

$encoded = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
if ($encoded === false) {
    fwrite(STDERR, "Falha ao serializar composer.json\n");
    exit(1);
}

$backup = $composerFile.'.laguna-bak';
if (! copy($composerFile, $backup)) {
    fwrite(STDERR, "Não foi possível criar backup {$backup}\n");
    exit(1);
}

file_put_contents($composerFile, $encoded."\n");
fwrite(STDOUT, "OK composer.json atualizado (+{$addedRepo} repos, +{$addedReq} require, +{$addedAuto} autoload)\n");
fwrite(STDOUT, "    backup: {$backup}\n");
exit(0);
