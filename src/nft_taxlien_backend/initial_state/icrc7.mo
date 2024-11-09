import ICRC7 "mo:icrc7-mo";

module{
  public let defaultConfig = func(caller: Principal) : ICRC7.InitArgs{
      ?{
        symbol = ?"LIEN";
        name = ?"Tax Lien";
        description = ?"NFT for Tax Lien of Real Estate Property";
        logo = ?"https://4098413308-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FRRg5KdkJjv4kDW5pXK42%2Fuploads%2FBLEGBSCOFRILpZlDtsDL%2Ftaxlien.png?alt=media&token=7d2f6a2e-2feb-4e98-8afa-61b210973624";
        supply_cap = null;
        allow_transfers = null;
        max_query_batch_size = ?100;
        max_update_batch_size = ?100;
        default_take_value = ?1000;
        max_take_value = ?10000;
        max_memo_size = ?512;
        permitted_drift = null;
        tx_window = null;
        burn_account = null; //burned nfts are deleted
        deployer = caller;
        supported_standards = null;
      };
  };
};