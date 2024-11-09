#Deploy the canister
#dfx deploy icrc7 --argument 'record {icrc7_args = null; icrc37_args =null; icrc3_args =null;}' --mode reinstall
# dfx deploy internet_identity --argument 'record {icrc7_args = null; icrc37_args =null; icrc3_args =null;}' --mode reinstall

dfx deploy

ICRC7_CANISTER=$(dfx canister id internet_identity)

