// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title TaxLienNFT
 * @dev NFT contract for US Tax Lien investments
 * @author NativeMind.net
 */
contract TaxLienNFT is 
    ERC721, 
    ERC721Enumerable, 
    ERC721URIStorage,
    ReentrancyGuard, 
    Pausable, 
    AccessControl 
{
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    // Counter for token IDs
    Counters.Counter private _tokenIdCounter;

    // Tax Lien Status
    enum Status {
        Pending,     // Awaiting verification
        Invested,    // Funds deployed to government
        Redeemed,    // Tax paid, returns available
        Claimed,     // Property claimed by investor
        Cancelled    // Invalid lien, funds returned
    }

    // Tax Lien Data Structure
    struct TaxLien {
        string state;              // US State (e.g., "Texas")
        string county;             // County (e.g., "Harris County")
        string parcelId;           // Unique parcel identifier
        uint256 faceAmount;        // Investment amount required (wei)
        uint256 propertyValue;     // Assessed property value (wei)
        uint16 apr;                // Annual percentage rate (basis points, 1200 = 12%)
        uint64 issueDate;          // Unix timestamp
        Status status;             // Current status
        address investor;          // Current owner/investor
        uint256 investedAmount;    // Amount actually invested
        uint64 redemptionDate;     // Date when redeemed (if applicable)
    }

    // Minting constraints
    uint256 public constant MIN_INVESTMENT = 0.01 ether;
    uint256 public constant MAX_INVESTMENT = 1000 ether;
    uint256 public constant SERVICE_FEE_PERCENT = 3; // 3% service fee
    uint256 public constant MIN_APR = 800;  // 8% minimum
    uint256 public constant MAX_APR = 2400; // 24% maximum

    // Mappings
    mapping(uint256 => TaxLien) public taxLiens;
    mapping(string => bool) private _usedParcelIds; // Prevent duplicate parcels
    mapping(address => uint256[]) private _userNFTs;

    // Treasury
    address public treasury;
    uint256 public totalFeesCollected;

    // Events
    event TaxLienMinted(
        uint256 indexed tokenId,
        address indexed investor,
        string parcelId,
        uint256 faceAmount,
        uint16 apr
    );

    event StatusUpdated(
        uint256 indexed tokenId,
        Status oldStatus,
        Status newStatus,
        uint64 timestamp
    );

    event NFTRedeemed(
        uint256 indexed tokenId,
        address indexed investor,
        uint256 payout,
        uint256 returns
    );

    event PropertyClaimed(
        uint256 indexed tokenId,
        address indexed investor,
        uint256 propertyValue
    );

    event FundsWithdrawn(
        address indexed recipient,
        uint256 amount
    );

    /**
     * @dev Constructor
     */
    constructor(address _treasury) ERC721("TaxLien NFT", "TXLN") {
        require(_treasury != address(0), "Invalid treasury address");
        
        treasury = _treasury;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEPLOYER_ROLE, msg.sender);
    }

    /**
     * @dev Mint a new Tax Lien NFT
     * @param state US State
     * @param county County name
     * @param parcelId Unique parcel identifier
     * @param faceAmount Investment amount
     * @param propertyValue Property assessed value
     * @param apr Annual percentage rate (basis points)
     */
    function mintTaxLien(
        string memory state,
        string memory county,
        string memory parcelId,
        uint256 faceAmount,
        uint256 propertyValue,
        uint16 apr
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        // Validations
        require(bytes(state).length > 0, "State required");
        require(bytes(county).length > 0, "County required");
        require(bytes(parcelId).length > 0, "Parcel ID required");
        require(!_usedParcelIds[parcelId], "Parcel already used");
        require(faceAmount >= MIN_INVESTMENT, "Investment too low");
        require(faceAmount <= MAX_INVESTMENT, "Investment too high");
        require(propertyValue > faceAmount, "Invalid property value");
        require(apr >= MIN_APR && apr <= MAX_APR, "Invalid APR");

        // Calculate service fee
        uint256 serviceFee = (faceAmount * SERVICE_FEE_PERCENT) / 100;
        uint256 totalRequired = faceAmount + serviceFee;
        
        require(msg.value >= totalRequired, "Insufficient payment");

        // Mint token
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(msg.sender, tokenId);

        // Store tax lien data
        taxLiens[tokenId] = TaxLien({
            state: state,
            county: county,
            parcelId: parcelId,
            faceAmount: faceAmount,
            propertyValue: propertyValue,
            apr: apr,
            issueDate: uint64(block.timestamp),
            status: Status.Pending,
            investor: msg.sender,
            investedAmount: msg.value,
            redemptionDate: 0
        });

        // Mark parcel as used
        _usedParcelIds[parcelId] = true;
        _userNFTs[msg.sender].push(tokenId);

        // Transfer service fee to treasury
        totalFeesCollected += serviceFee;
        (bool success, ) = treasury.call{value: serviceFee}("");
        require(success, "Fee transfer failed");

        // Refund excess
        if (msg.value > totalRequired) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - totalRequired}("");
            require(refundSuccess, "Refund failed");
        }

        emit TaxLienMinted(tokenId, msg.sender, parcelId, faceAmount, apr);

        return tokenId;
    }

    /**
     * @dev Update NFT status (Admin/Deployer only)
     * @param tokenId Token ID
     * @param newStatus New status
     */
    function updateStatus(
        uint256 tokenId,
        Status newStatus
    ) external onlyRole(DEPLOYER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        
        TaxLien storage lien = taxLiens[tokenId];
        Status oldStatus = lien.status;
        
        require(oldStatus != newStatus, "Status unchanged");
        require(_isValidStatusTransition(oldStatus, newStatus), "Invalid status transition");

        lien.status = newStatus;

        // Handle status-specific logic
        if (newStatus == Status.Cancelled) {
            _handleCancellation(tokenId);
        } else if (newStatus == Status.Redeemed) {
            lien.redemptionDate = uint64(block.timestamp);
        }

        emit StatusUpdated(tokenId, oldStatus, newStatus, uint64(block.timestamp));
    }

    /**
     * @dev Redeem NFT and receive investment + returns
     * @param tokenId Token ID to redeem
     */
    function redeemNFT(uint256 tokenId) external nonReentrant returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        TaxLien storage lien = taxLiens[tokenId];
        require(lien.status == Status.Redeemed, "Not redeemable");

        // Calculate returns
        uint256 returns = _calculateReturns(
            lien.faceAmount,
            lien.apr,
            lien.issueDate,
            lien.redemptionDate
        );

        uint256 payout = lien.faceAmount + returns;
        
        require(address(this).balance >= payout, "Insufficient contract balance");

        // Burn NFT
        _burn(tokenId);
        _usedParcelIds[lien.parcelId] = false;

        // Transfer funds
        (bool success, ) = msg.sender.call{value: payout}("");
        require(success, "Payout transfer failed");

        emit NFTRedeemed(tokenId, msg.sender, payout, returns);

        return payout;
    }

    /**
     * @dev Claim property (when tax not paid)
     * @param tokenId Token ID
     */
    function claimProperty(uint256 tokenId) external nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        TaxLien storage lien = taxLiens[tokenId];
        require(lien.status == Status.Claimed, "Not claimable");

        // Burn NFT (property transfer happens off-chain)
        _burn(tokenId);
        _usedParcelIds[lien.parcelId] = false;

        emit PropertyClaimed(tokenId, msg.sender, lien.propertyValue);
    }

    /**
     * @dev Calculate investment returns
     */
    function _calculateReturns(
        uint256 principal,
        uint16 apr,
        uint64 startDate,
        uint64 endDate
    ) private pure returns (uint256) {
        uint256 duration = endDate - startDate;
        uint256 annualReturn = (principal * apr) / 10000;
        uint256 returns = (annualReturn * duration) / 365 days;
        return returns;
    }

    /**
     * @dev Handle cancellation refund
     */
    function _handleCancellation(uint256 tokenId) private {
        TaxLien storage lien = taxLiens[tokenId];
        address investor = lien.investor;
        uint256 refundAmount = lien.faceAmount;

        if (address(this).balance >= refundAmount) {
            (bool success, ) = investor.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Validate status transitions
     */
    function _isValidStatusTransition(Status from, Status to) private pure returns (bool) {
        if (from == Status.Pending) {
            return to == Status.Invested || to == Status.Cancelled;
        }
        if (from == Status.Invested) {
            return to == Status.Redeemed || to == Status.Claimed;
        }
        return false;
    }

    /**
     * @dev Get all NFTs owned by user
     */
    function getUserNFTs(address user) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }
        
        return tokenIds;
    }

    /**
     * @dev Get tax lien details
     */
    function getTaxLien(uint256 tokenId) external view returns (TaxLien memory) {
        require(_exists(tokenId), "Token does not exist");
        return taxLiens[tokenId];
    }

    /**
     * @dev Admin: Withdraw contract balance
     */
    function withdrawFunds(address recipient, uint256 amount) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(recipient != address(0), "Invalid recipient");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(recipient, amount);
    }

    /**
     * @dev Admin: Pause contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Admin: Unpause contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Emergency: Receive ETH
     */
    receive() external payable {}

    // Required overrides

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) 
        internal 
        override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

