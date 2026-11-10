<?php
// NPCH Frontend Deploy Webhook
// Triggered by GitHub Actions after each push to main

$token = getenv('DEPLOY_TOKEN') ?: ''; 
$receivedToken = $_SERVER['HTTP_X_DEPLOY_TOKEN'] ?? '';

if (empty($token) || !hash_equals($token, $receivedToken)) {
    http_response_code(403);
    die(json_encode(['error' => 'Unauthorized']));
}

$output = [];
$repo = 'https://github.com/NPCH-dev/npch-ops-hub-frontend';
$cloneDir = '/tmp/npch-frontend-' . time();
$webroot = '/www/wwwroot/dev.processengine.de';

// Clone fresh copy
exec("git clone --depth 1 {$repo} {$cloneDir} 2>&1", $out, $code);
$output[] = implode("\n", $out);

if ($code !== 0) {
    http_response_code(500);
    die(json_encode(['error' => 'Clone failed', 'output' => $output]));
}

// Copy HTML files and assets to webroot
exec("cp {$cloneDir}/*.html {$webroot}/ 2>&1", $out); $output[] = implode("\n", $out);
exec("cp {$cloneDir}/*.png {$webroot}/ 2>&1", $out);  $output[] = implode("\n", $out);
exec("rm -rf {$cloneDir}", $out);

echo json_encode(['status' => 'deployed', 'time' => date('c'), 'output' => $output]);
