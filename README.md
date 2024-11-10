# NFT Wallet for ICP.NINJA + Implementation: Tax Lien NFT

## NFT Wallet

- There are implementations for ICRC-1 tokens at ICP.Ninja, but there is no anything for ICRC-7



## 📜🏠 Tax Lien NFT

A **Lien** is a legal right to keep possession of property belonging to another person until a debt owed by that person is discharged.  
A **Tax Lien** is imposed by law on a property to secure the payment of taxes.

## 💡 Key Features 

- 🏛️🔗 **Deployer**: Acts as a proxy public company between the **Tax Department** and **Private Crypto Investors**. 
- 💎💰 **NFT Issuance**: On-demand NFTs are issued for investing in any available Tax Lien from the **Tax Department**.
- 🔥💸 **NFT Burn Mechanism**: The NFT can be burned to claim **investments and rewards** ONLY after the **Tax Payer** has paid their debts. 
- 🏡⏳ **Real Estate Claim**: The NFT can also be burned to acquire the **Real Estate property** if the **Tax Payer** fails to pay their debts on time.

## 🛠️ Architecture of Solution 

The solution consists of 6 canisters:
- 📈 **nft_taxlien_backend** - Custom canister for ICRC-7/NFT implementation (based on `icrc7.mo`)
- 🗂️ **business_backend** - Custom canister for business logic, will be parcels database in the future (based on `Hello World` sample)
- 💵 **payment_backend** - Custom canister for payment operations in ICRC-1 (based on `token_transfer_from`)
- 🎉 **nft_taxlien_frontend** - Custom canister for users frontend
- 🚀 **admin_frontend** - Custom canister for admin frontend
- 🔑 **internet_identity** - Standard implementation for authorization
- 📒 **icrc1_ledger_canister** - Standard implementation of ICRC-1 


## 🔄 Canister Interactions
- Canisters can interact with each other
Example canister payment_backend sends command to nft_taxlien_backend for issue NFT after successfull payment
```
    result = await NFTTaxLienBackend.LienMint(memo);
    result = await NFTTaxLienBackend.transfer(memo);
    debug_show(result);
```


## 💡 ICRC-7/NFT implementation (canister nft_taxlien_backend)
- 🔥 Can store and _update_ additional information im memo field using _nfts_update_ 
- 💎 Can use non-standart commands: LienCancel(), LienPay(), LienFail(), LienInvest(), Redeem()
- 🔥 Can use can use standart commands: icrcX_mint(), icrcX_burn()

- Canisters can have some internal logic
Example canister nft_taxlien_backend can use standart Mint(), Burn() commands and non-standart LienCancel, LienPay, LienFail, LienInvest, Redeem
```
  public shared(msg) func LienCancel(token_id : Nat) : async [ICRC7.UpdateNFTResult] {
    //TODO: Change -> Only Deployer
    //Only Deployer
    //if(msg.caller != icrc7().get_state().deployer) D.trap("Unauthorized (only deployer)");

    //TOO: Only status==Pending 

    //TODO: Set status=Cancelled


    switch(icrc7().update_nfts<system>(msg.caller, get_memo(token_id))){
      case(#ok(updateNftResultArray)) updateNftResultArray;
      case(#err(err)) D.trap(err);
    }    
  };
```


* Canister->LienCancel(NFT), Sets Status=Cancelled DeployerOnly
* Canister->LienPay(NFT), ReleaseUSDT, Sets Status-Payed, DeployerOnly
* Canister->LienFail(NFT), ReleaseUSDT, Sets Status=Failed, Payable(GETS USDT), DeployerOnly
* Canister->LienInvest(NFT), Sets Status=Invested, DeployerOnly
* Canister->LienRedeem(

 
```
Name of team: NativeMind.net
Name of track:-
Repo link: https://github.com/Ananta-Shakti/icp_taxlien
Team participants: Anton Dodonov
Describe the project: NFT for USA Tax Liens
What problem it is solving:

Make NFT tokens for buy and sell tax liens.
Right now it is possible only by offline and online methods. But if buy taxlien and owner didn't pay for long time, money are freezed. So NFT Tokens give possibility to sell tax lien to different person and don't freeze money for a long time
What unique features of ICP it is using

OISY wallet Principal: 2646156
Mainnet canister link frontend:-
Mainnet canister link backend: https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.icp0.io/?id=hf4gy-eiaaa-aaaao-qezba-cai
Demo video link:-
```


TODO list:
* Statuses of NFT: Pending, Payed, Cancelled, Invested, Redeemed
* After User chose Tax Lien with unique Parcel_Id, that is available in online database, he execute BuyLien smart contract and invest Face_Amount in USDT.
* If Pacrel_Id is unavailable, Deployer runs Cancel(), get Cancelled status. Smart contract send USDT back to payer.
* Deployer gets Parcel_Id and Face_amount. Makes action Pay(), get unblocked USDT to Deployer account.  Making real cash payment to government and waiting for documents. Status changed to Payed.
* On documents received, action Invest()
* If documents not received, sets Cancel()
* On Tax Lien redeem, Deployers sets Redeem(), 
* NFT with Status==Invested can be traded through MarketPlaces

Data Structure:
* State
* County
* Parcel_ID
* Face_Amount
* Property_Amount
* APR
* Issue_Date
* Status

NFT Actions:
* Canister->LienMint (State,County, Parcel_ID, Face_Amount, Property_Amount, APR,Issue_date), Payable(GETS USDT), Makes new NFT, Public, from Mint
* Canister->LienCancel(NFT), Sets Status=Cancelled DeployerOnly
* Canister->LienPay(NFT), ReleaseUSDT, Sets Status-Payed, DeployerOnly
* Canister->LienFail(NFT), ReleaseUSDT, Sets Status=Failed, Payable(GETS USDT), DeployerOnly
* Canister->LienInvest(NFT), Sets Status=Invested, DeployerOnly
* Canister->LienRedeem(NFT), Payable(GETS USDT),Sets Status=Redeemed, Release(USDT to owner), DeployerOnly
* Canister->LienBurn(NFT) Release(USDT to owner), OwnerOnly

USER:
LienMint
LienBurn

ADMIN:
LienCancel
LienPay
LienFail
LienInvest
LienRedeem


Simplifications:
* In this iteration lets say that information (State,County, Parcel_ID, Face_Amount, Property_Amount, APR,Issue_date) will



TODO:

Documentation of code -> high ligh + give high level explanation in video
Walking through main, walking quickly, Frontend logic
Go step-by-step from small scope to extended
Full-fill formalities: on mainnet
 

Based on https://internetcomputer.org/docs/current/developer-docs/defi/nfts/nft-collections https://github.com/PanIndustrial-Org/icrc_nft.mo.git

Documentation:
https://internetcomputer.org/docs/current/tutorials/hackathon-prep-course/exploring-the-frontend/
https://internetcomputer.org/docs/current/tutorials/developer-journey/level-3/3.4-intro-to-agents/
https://internetcomputer.org/docs/current/developer-docs/developer-tools/off-chain/agents/javascript-agent

## Install
```
mops add icrc_nft-mo
```

## Deployment

The simplest deployment is to provide null arguments to each ICRC(3,7,30) component.

Edit the files in /example/initial_state for each ICRC.

```
dfx deploy icrc7 --argument 'record {icrc7_args = null; icrc37_args =null; icrc3_args =null;}' --mode reinstall
```

This will produce an NFT canister with the default config.  For more fine grained control, please consult the documentation for each project:

- ICRC3 - Transaction Log and Archive - https://github.com/PanIndustrial-Org/icrc37.mo
- ICRC7 - Base NFT - https://github.com/PanIndustrial-Org/icrc7.mo
- ICRC37 - Approval workflow - https://github.com/PanIndustrial-Org/icrc37.mo

A sample deployment/functional script is provided in deploy.sh in the example folder.

## Provided functions

For sample minting, burning, approval, transfer functions, please see the deploy.sh file in the examples folder.

Further availability of functionality can be referenced in earlier referenced documentation.

## Documentation

Pre-compiled docs can be found on mops.one at:

- ICRC3 - Transaction Log and Archive - https://mops.one/icrc3-mo/docs/lib
- ICRC7 - Base NFT - https://mops.one/icrc7-mo/docs
- ICRC37 - Approval workflow - https://mops.one/icrc37-mo/docs
