import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat16 "mo:base/Nat16";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

actor TaxLienNFT {
    
    // Types
    type TokenId = Nat;
    type Address = Principal;
    
    type Status = {
        #Pending;
        #Invested;
        #Redeemed;
        #Claimed;
        #Cancelled;
    };
    
    type TaxLien = {
        id: TokenId;
        state: Text;
        county: Text;
        parcelId: Text;
        faceAmount: Nat;
        propertyValue: Nat;
        apr: Nat16;
        issueDate: Int;
        status: Status;
        investor: Address;
        investedAmount: Nat;
        redemptionDate: ?Int;
    };
    
    type TaxLienInput = {
        state: Text;
        county: Text;
        parcelId: Text;
        faceAmount: Nat;
        propertyValue: Nat;
        apr: Nat16;
    };
    
    type MintResult = Result.Result<TokenId, Text>;
    type UpdateResult = Result.Result<(), Text>;
    type RedeemResult = Result.Result<Nat, Text>;
    
    // Constants
    private let MIN_INVESTMENT : Nat = 10_000_000; // 0.01 ICP (in e8s)
    private let MAX_INVESTMENT : Nat = 1_000_000_000_000; // 1000 ICP
    private let SERVICE_FEE_PERCENT : Nat = 3;
    private let MIN_APR : Nat16 = 800; // 8%
    private let MAX_APR : Nat16 = 2400; // 24%
    private let SECONDS_PER_YEAR : Int = 31_536_000; // 365 days
    
    // State
    private stable var nextTokenId : TokenId = 0;
    private stable var owner : Principal = Principal.fromText("aaaaa-aa");
    private stable var treasury : Principal = Principal.fromText("aaaaa-aa");
    private stable var totalFeesCollected : Nat = 0;
    
    // Storage
    private var taxLiens = HashMap.HashMap<TokenId, TaxLien>(10, Nat.equal, Hash.hash);
    private var owners = HashMap.HashMap<TokenId, Address>(10, Nat.equal, Hash.hash);
    private var balances = HashMap.HashMap<Address, Nat>(10, Principal.equal, Principal.hash);
    private var usedParcelIds = HashMap.HashMap<Text, Bool>(10, Text.equal, Text.hash);
    private var userTokens = HashMap.HashMap<Address, [TokenId]>(10, Principal.equal, Principal.hash);
    
    // Roles
    private var admins = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);
    private var deployers = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);
    
    // Events (for logging)
    private stable var eventLog : [Text] = [];
    
    // Initialize
    public shared(msg) func init(_treasury: Principal) : async () {
        owner := msg.caller;
        treasury := _treasury;
        admins.put(msg.caller, true);
        deployers.put(msg.caller, true);
    };
    
    // === CORE NFT FUNCTIONS ===
    
    /**
     * Mint new Tax Lien NFT
     */
    public shared(msg) func mintTaxLien(input: TaxLienInput, payment: Nat) : async MintResult {
        
        // Validations
        if (Text.size(input.state) == 0) {
            return #err("State required");
        };
        
        if (Text.size(input.county) == 0) {
            return #err("County required");
        };
        
        if (Text.size(input.parcelId) == 0) {
            return #err("Parcel ID required");
        };
        
        switch (usedParcelIds.get(input.parcelId)) {
            case (?true) { return #err("Parcel already used"); };
            case _ {};
        };
        
        if (input.faceAmount < MIN_INVESTMENT) {
            return #err("Investment too low");
        };
        
        if (input.faceAmount > MAX_INVESTMENT) {
            return #err("Investment too high");
        };
        
        if (input.propertyValue <= input.faceAmount) {
            return #err("Invalid property value");
        };
        
        if (input.apr < MIN_APR or input.apr > MAX_APR) {
            return #err("Invalid APR");
        };
        
        // Calculate service fee
        let serviceFee = (input.faceAmount * SERVICE_FEE_PERCENT) / 100;
        let totalRequired = input.faceAmount + serviceFee;
        
        if (payment < totalRequired) {
            return #err("Insufficient payment");
        };
        
        // Create token
        let tokenId = nextTokenId;
        nextTokenId += 1;
        
        let taxLien : TaxLien = {
            id = tokenId;
            state = input.state;
            county = input.county;
            parcelId = input.parcelId;
            faceAmount = input.faceAmount;
            propertyValue = input.propertyValue;
            apr = input.apr;
            issueDate = Time.now();
            status = #Pending;
            investor = msg.caller;
            investedAmount = payment;
            redemptionDate = null;
        };
        
        // Store
        taxLiens.put(tokenId, taxLien);
        owners.put(tokenId, msg.caller);
        usedParcelIds.put(input.parcelId, true);
        
        // Update balance
        let currentBalance = Option.get(balances.get(msg.caller), 0);
        balances.put(msg.caller, currentBalance + 1);
        
        // Update user tokens
        let currentTokens = Option.get(userTokens.get(msg.caller), []);
        userTokens.put(msg.caller, Array.append(currentTokens, [tokenId]));
        
        // Update fees
        totalFeesCollected += serviceFee;
        
        // Log event
        _logEvent("TaxLienMinted: " # Nat.toText(tokenId) # " by " # Principal.toText(msg.caller));
        
        #ok(tokenId)
    };
    
    /**
     * Update NFT status (Admin/Deployer only)
     */
    public shared(msg) func updateStatus(tokenId: TokenId, newStatus: Status) : async UpdateResult {
        
        // Check permissions
        if (not _isDeployer(msg.caller)) {
            return #err("Unauthorized: deployer role required");
        };
        
        // Get tax lien
        switch (taxLiens.get(tokenId)) {
            case null { return #err("Token does not exist"); };
            case (?lien) {
                
                // Validate status transition
                if (not _isValidStatusTransition(lien.status, newStatus)) {
                    return #err("Invalid status transition");
                };
                
                // Update status
                let updatedLien : TaxLien = {
                    id = lien.id;
                    state = lien.state;
                    county = lien.county;
                    parcelId = lien.parcelId;
                    faceAmount = lien.faceAmount;
                    propertyValue = lien.propertyValue;
                    apr = lien.apr;
                    issueDate = lien.issueDate;
                    status = newStatus;
                    investor = lien.investor;
                    investedAmount = lien.investedAmount;
                    redemptionDate = switch (newStatus) {
                        case (#Redeemed) { ?Time.now() };
                        case _ { lien.redemptionDate };
                    };
                };
                
                taxLiens.put(tokenId, updatedLien);
                
                // Handle cancellation
                if (newStatus == #Cancelled) {
                    // In real implementation, would refund here
                    usedParcelIds.put(lien.parcelId, false);
                };
                
                _logEvent("StatusUpdated: " # Nat.toText(tokenId) # " to " # _statusToText(newStatus));
                
                #ok()
            };
        };
    };
    
    /**
     * Redeem NFT and receive returns
     */
    public shared(msg) func redeemNFT(tokenId: TokenId) : async RedeemResult {
        
        // Check ownership
        switch (owners.get(tokenId)) {
            case null { return #err("Token does not exist"); };
            case (?tokenOwner) {
                if (tokenOwner != msg.caller) {
                    return #err("Not token owner");
                };
            };
        };
        
        // Get tax lien
        switch (taxLiens.get(tokenId)) {
            case null { return #err("Token does not exist"); };
            case (?lien) {
                
                // Check status
                switch (lien.status) {
                    case (#Redeemed) {};
                    case _ { return #err("Not redeemable"); };
                };
                
                // Calculate returns
                let redemptionTime = Option.get(lien.redemptionDate, Time.now());
                let duration = redemptionTime - lien.issueDate;
                let durationInYears = duration / SECONDS_PER_YEAR;
                
                let annualReturn = (lien.faceAmount * Nat16.toNat(lien.apr)) / 10000;
                let returns = (annualReturn * durationInYears) / 1;
                let payout = lien.faceAmount + returns;
                
                // Burn NFT
                taxLiens.delete(tokenId);
                owners.delete(tokenId);
                usedParcelIds.put(lien.parcelId, false);
                
                // Update balance
                let currentBalance = Option.get(balances.get(msg.caller), 0);
                if (currentBalance > 0) {
                    balances.put(msg.caller, currentBalance - 1);
                };
                
                _logEvent("NFTRedeemed: " # Nat.toText(tokenId) # " payout: " # Nat.toText(payout));
                
                #ok(payout)
            };
        };
    };
    
    /**
     * Claim property (when tax not paid)
     */
    public shared(msg) func claimProperty(tokenId: TokenId) : async UpdateResult {
        
        // Check ownership
        switch (owners.get(tokenId)) {
            case null { return #err("Token does not exist"); };
            case (?tokenOwner) {
                if (tokenOwner != msg.caller) {
                    return #err("Not token owner");
                };
            };
        };
        
        // Get tax lien
        switch (taxLiens.get(tokenId)) {
            case null { return #err("Token does not exist"); };
            case (?lien) {
                
                // Check status
                switch (lien.status) {
                    case (#Claimed) {};
                    case _ { return #err("Not claimable"); };
                };
                
                // Burn NFT (property transfer happens off-chain)
                taxLiens.delete(tokenId);
                owners.delete(tokenId);
                usedParcelIds.put(lien.parcelId, false);
                
                // Update balance
                let currentBalance = Option.get(balances.get(msg.caller), 0);
                if (currentBalance > 0) {
                    balances.put(msg.caller, currentBalance - 1);
                };
                
                _logEvent("PropertyClaimed: " # Nat.toText(tokenId) # " by " # Principal.toText(msg.caller));
                
                #ok()
            };
        };
    };
    
    // === QUERY FUNCTIONS ===
    
    /**
     * Get tax lien details
     */
    public query func getTaxLien(tokenId: TokenId) : async ?TaxLien {
        taxLiens.get(tokenId)
    };
    
    /**
     * Get owner of token
     */
    public query func ownerOf(tokenId: TokenId) : async ?Address {
        owners.get(tokenId)
    };
    
    /**
     * Get balance of address
     */
    public query func balanceOf(addr: Address) : async Nat {
        Option.get(balances.get(addr), 0)
    };
    
    /**
     * Get all tokens owned by address
     */
    public query func getUserTokens(addr: Address) : async [TokenId] {
        Option.get(userTokens.get(addr), [])
    };
    
    /**
     * Get user's tax liens
     */
    public query func getUserTaxLiens(addr: Address) : async [TaxLien] {
        let tokens = Option.get(userTokens.get(addr), []);
        let liens = Array.mapFilter<TokenId, TaxLien>(
            tokens,
            func (tokenId) { taxLiens.get(tokenId) }
        );
        liens
    };
    
    /**
     * Get total supply
     */
    public query func totalSupply() : async Nat {
        nextTokenId
    };
    
    /**
     * Get statistics
     */
    public query func getStats() : async {
        totalMinted: Nat;
        totalActive: Nat;
        totalFeesCollected: Nat;
        treasury: Principal;
    } {
        {
            totalMinted = nextTokenId;
            totalActive = taxLiens.size();
            totalFeesCollected = totalFeesCollected;
            treasury = treasury;
        }
    };
    
    // === ADMIN FUNCTIONS ===
    
    /**
     * Add admin
     */
    public shared(msg) func addAdmin(addr: Principal) : async UpdateResult {
        if (msg.caller != owner) {
            return #err("Unauthorized: owner only");
        };
        admins.put(addr, true);
        #ok()
    };
    
    /**
     * Add deployer
     */
    public shared(msg) func addDeployer(addr: Principal) : async UpdateResult {
        if (not _isAdmin(msg.caller)) {
            return #err("Unauthorized: admin only");
        };
        deployers.put(addr, true);
        #ok()
    };
    
    /**
     * Set treasury
     */
    public shared(msg) func setTreasury(addr: Principal) : async UpdateResult {
        if (msg.caller != owner) {
            return #err("Unauthorized: owner only");
        };
        treasury := addr;
        #ok()
    };
    
    /**
     * Get event log
     */
    public query func getEventLog(offset: Nat, limit: Nat) : async [Text] {
        let start = if (offset < eventLog.size()) { offset } else { eventLog.size() };
        let end = if (start + limit < eventLog.size()) { start + limit } else { eventLog.size() };
        
        Array.tabulate<Text>(
            end - start,
            func (i) { eventLog[start + i] }
        )
    };
    
    // === PRIVATE HELPERS ===
    
    private func _isAdmin(addr: Principal) : Bool {
        addr == owner or Option.get(admins.get(addr), false)
    };
    
    private func _isDeployer(addr: Principal) : Bool {
        _isAdmin(addr) or Option.get(deployers.get(addr), false)
    };
    
    private func _isValidStatusTransition(from: Status, to: Status) : Bool {
        switch (from, to) {
            case (#Pending, #Invested) { true };
            case (#Pending, #Cancelled) { true };
            case (#Invested, #Redeemed) { true };
            case (#Invested, #Claimed) { true };
            case _ { false };
        }
    };
    
    private func _statusToText(status: Status) : Text {
        switch (status) {
            case (#Pending) { "Pending" };
            case (#Invested) { "Invested" };
            case (#Redeemed) { "Redeemed" };
            case (#Claimed) { "Claimed" };
            case (#Cancelled) { "Cancelled" };
        }
    };
    
    private func _logEvent(event: Text) : () {
        eventLog := Array.append(eventLog, [event]);
    };
    
    // === UPGRADE HOOKS ===
    
    system func preupgrade() {
        // Stable storage handled automatically
    };
    
    system func postupgrade() {
        // Reinitialize hash maps if needed
    };
}

