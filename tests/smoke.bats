#!/usr/bin/env bash

# Smoke tests pour install-terminal.sh
# Usage : bash tests/smoke.bats   (nécessite bats)
# Ou    : bash tests/smoke.sh    (sans bats)

set -euo pipefail

SCRIPT="${SCRIPT:-./install-terminal.sh}"

@test "syntaxe valide" {
    bash -n "${SCRIPT}"
}

@test "--help affiche l'aide et sort avec 0" {
    run "${SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "--dry-run option 4 ne modifie pas le système" {
    run "${SCRIPT}" --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "--user-only skip apt checks" {
    run "${SCRIPT}" --dry-run --yes --user-only
    [ "$status" -eq 0 ]
    [[ "$output" == *"[user-only]"* ]]
}

@test "option invalide retourne 1" {
    run "${SCRIPT}" --inconnu
    [ "$status" -eq 1 ]
}