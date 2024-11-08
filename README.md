# NFT fot Tax Liens
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


Based on https://internetcomputer.org/docs/current/developer-docs/defi/nfts/nft-collections https://github.com/PanIndustrial-Org/icrc_nft.mo.git

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
