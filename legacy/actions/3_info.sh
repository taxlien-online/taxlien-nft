

echo $ICRC7_CANISTER

#init the canister
dfx canister call icrc7 init

# Get Name
dfx canister call icrc7 icrc7_name  --query 

# Get Symbol
dfx canister call icrc7 icrc7_symbol  --query 

# Get Description
dfx canister call icrc7 icrc7_description  --query 

# Get Logo
dfx canister call icrc7 icrc7_logo  --query 

