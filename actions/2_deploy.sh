#Deploy the canister
dfx deploy icrc7 --argument 'record {icrc7_args = null; icrc37_args =null; icrc3_args =null;}' --mode reinstall

ICRC7_CANISTER=$(dfx canister id icrc7)

