
# Get total supply
dfx canister call icrc7 icrc7_total_supply  --query 

# Get supply cap
dfx canister call icrc7 icrc7_supply_cap  --query

# Get max query batch size
dfx canister call icrc7 icrc7_max_query_batch_size  --query

# Get max update size
dfx canister call icrc7 icrc7_max_update_batch_size  --query

# Get default take value
dfx canister call icrc7 icrc7_default_take_value  --query

# Get max take value
dfx canister call icrc7 icrc7_max_take_value  --query

# Get max memo size
dfx canister call icrc7 icrc7_max_memo_size  --query

# Get collection metadata
dfx canister call icrc7 icrc7_collection_metadata  --query

# Get suported standards
dfx canister call icrc7 icrc10_supported_standards  --query


# Get max approvals per token or collection
dfx canister call icrc7 icrc37_max_approvals_per_token_or_collection  --query

#Get a max revoke approvals
dfx canister call icrc7 icrc37_max_revoke_approvals '(null, null)'

#All tokens should be owned by the canister
dfx canister call icrc7 icrc7_tokens_of "(record { owner = principal \"$ICRC7_CANISTER\"; subaccount = null;},null,null)"

#Should be approved to transfer
dfx canister call icrc7 icrc37_is_approved "(vec{record { spender=record {owner = principal \"$ADMIN_PRINCIPAL\"; subaccount = null;}; from_subaccount=null; token_id=0;}})" --query

#Check that the owner is spender
dfx canister call icrc7 icrc37_get_collection_approvals "(record { owner = principal \"$ICRC7_CANISTER\"; subaccount = null;},null, null)" --query

