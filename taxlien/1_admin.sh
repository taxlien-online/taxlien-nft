set -ex

dfx identity new alice --storage-mode=plaintext || true

dfx identity use alice

ALICE_PRINCIPAL=$(dfx identity get-principal)

dfx identity new bob --storage-mode=plaintext || true

dfx identity use bob

BOB_PRINCIPAL=$(dfx identity get-principal)

dfx identity new icrc7_deployer --storage-mode=plaintext || true

dfx identity use icrc7_deployer

ADMIN_PRINCIPAL=$(dfx identity get-principal)

