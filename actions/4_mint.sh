echo $ICRC7_CANISTER

# Mint 4 NFTs
dfx canister call nft_taxlien_backend icrcX_mint "(
  vec {
    record {
      token_id = 0 : nat;
      owner = opt record { owner = principal \"$II_CANISTER\"; subaccount = null;};
      metadata = variant {
        Map = vec {
          record { \"icrc97:metadata\"; variant { Map = vec {
            record { \"name\"; variant { Text = \"Image 1\" } };
            record { \"description\"; variant { Text = \"NFT for Tax Lien, USA, FL, POLK, ID:12345\" } };
            record { \"assets\"; variant { Array = vec {
              variant { Map = vec {
                record { \"url\"; variant { Text = \"https://taxlien.online/image/PIA18249/12345.jpg\" } };
                record { \"mime\"; variant { Text = \"image/jpeg\" } };
                record { \"purpose\"; variant { Text = \"icrc97:image\" } }
              }}
            }}}
            record { \"State\"; variant { Text = \"Florida\" } };
            record { \"County\"; variant { Text = \"Polk\" } };
            record { \"Parcel_ID\"; variant { Text = \"12345\" } };
            record { \"Face_Amount\"; variant { Text = \"10000\" } };
            record { \"Property_Amount\"; variant { Text = \"9500\" } };
            record { \"APR\"; variant { Text = \"5%\" } };
            record { \"Issue_Date\"; variant { Text = \"2024-11-09\" } };
            record { \"Status\"; variant { Text = \"Active\" } }
          }}}
        }
      };
      memo = opt blob \"\00\01\";
      override = true;
      created_at_time = null;
    };
  }
)"

