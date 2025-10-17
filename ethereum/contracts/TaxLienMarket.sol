// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaxLienMarket
 * @dev Marketplace for trading Tax Lien NFTs
 * @author NativeMind.net
 */
contract TaxLienMarket is ReentrancyGuard, Ownable {
    
    IERC721 public immutable taxLienNFT;
    
    // Market fee (2.5%)
    uint256 public constant MARKET_FEE_PERCENT = 250; // 2.5% in basis points
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    address public feeRecipient;
    uint256 public totalFeesCollected;

    // Listing structure
    struct Listing {
        address seller;
        uint256 price;
        uint256 listedAt;
        bool active;
    }

    // Offer structure
    struct Offer {
        address buyer;
        uint256 amount;
        uint256 expiresAt;
        bool active;
    }

    // Mappings
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Offer[]) public offers;
    mapping(address => uint256[]) private _userListings;

    // Events
    event Listed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 timestamp
    );

    event Unlisted(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 timestamp
    );

    event Sold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    event OfferMade(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amount,
        uint256 expiresAt
    );

    event OfferAccepted(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 amount
    );

    event OfferCancelled(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 offerIndex
    );

    event PriceUpdated(
        uint256 indexed tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );

    /**
     * @dev Constructor
     * @param _taxLienNFT Address of TaxLienNFT contract
     * @param _feeRecipient Address to receive marketplace fees
     */
    constructor(address _taxLienNFT, address _feeRecipient) {
        require(_taxLienNFT != address(0), "Invalid NFT address");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        
        taxLienNFT = IERC721(_taxLienNFT);
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev List NFT for sale
     * @param tokenId Token ID to list
     * @param price Listing price in wei
     */
    function listForSale(uint256 tokenId, uint256 price) external {
        require(taxLienNFT.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(price > 0, "Price must be > 0");
        require(!listings[tokenId].active, "Already listed");

        // Transfer NFT to marketplace
        taxLienNFT.transferFrom(msg.sender, address(this), tokenId);

        // Create listing
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            listedAt: block.timestamp,
            active: true
        });

        _userListings[msg.sender].push(tokenId);

        emit Listed(tokenId, msg.sender, price, block.timestamp);
    }

    /**
     * @dev Unlist NFT (cancel sale)
     * @param tokenId Token ID to unlist
     */
    function unlist(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        
        require(listing.active, "Not listed");
        require(listing.seller == msg.sender, "Not seller");

        listing.active = false;

        // Return NFT to seller
        taxLienNFT.transferFrom(address(this), msg.sender, tokenId);

        emit Unlisted(tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Buy listed NFT
     * @param tokenId Token ID to buy
     */
    function buyNFT(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[tokenId];
        
        require(listing.active, "Not listed");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Cannot buy own NFT");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate fee
        uint256 fee = (price * MARKET_FEE_PERCENT) / FEE_DENOMINATOR;
        uint256 sellerProceeds = price - fee;

        // Mark as inactive
        listing.active = false;

        // Transfer NFT to buyer
        taxLienNFT.transferFrom(address(this), msg.sender, tokenId);

        // Transfer funds
        (bool sellerSuccess, ) = seller.call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller transfer failed");

        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");

        totalFeesCollected += fee;

        // Refund excess
        if (msg.value > price) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - price}("");
            require(refundSuccess, "Refund failed");
        }

        emit Sold(tokenId, seller, msg.sender, price, fee, block.timestamp);
    }

    /**
     * @dev Update listing price
     * @param tokenId Token ID
     * @param newPrice New price
     */
    function updatePrice(uint256 tokenId, uint256 newPrice) external {
        Listing storage listing = listings[tokenId];
        
        require(listing.active, "Not listed");
        require(listing.seller == msg.sender, "Not seller");
        require(newPrice > 0, "Price must be > 0");

        uint256 oldPrice = listing.price;
        listing.price = newPrice;

        emit PriceUpdated(tokenId, oldPrice, newPrice);
    }

    /**
     * @dev Make offer on NFT
     * @param tokenId Token ID
     * @param duration Offer duration in seconds
     */
    function makeOffer(uint256 tokenId, uint256 duration) 
        external 
        payable 
    {
        require(msg.value > 0, "Offer must be > 0");
        require(duration >= 1 hours && duration <= 30 days, "Invalid duration");
        require(taxLienNFT.ownerOf(tokenId) != msg.sender, "Cannot offer on own NFT");

        uint256 expiresAt = block.timestamp + duration;

        offers[tokenId].push(Offer({
            buyer: msg.sender,
            amount: msg.value,
            expiresAt: expiresAt,
            active: true
        }));

        emit OfferMade(tokenId, msg.sender, msg.value, expiresAt);
    }

    /**
     * @dev Accept offer
     * @param tokenId Token ID
     * @param offerIndex Index of offer to accept
     */
    function acceptOffer(uint256 tokenId, uint256 offerIndex) 
        external 
        nonReentrant 
    {
        require(taxLienNFT.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(offerIndex < offers[tokenId].length, "Invalid offer index");

        Offer storage offer = offers[tokenId][offerIndex];
        
        require(offer.active, "Offer not active");
        require(block.timestamp <= offer.expiresAt, "Offer expired");

        address buyer = offer.buyer;
        uint256 amount = offer.amount;

        // Mark offer as inactive
        offer.active = false;

        // Calculate fee
        uint256 fee = (amount * MARKET_FEE_PERCENT) / FEE_DENOMINATOR;
        uint256 sellerProceeds = amount - fee;

        // Transfer NFT
        taxLienNFT.transferFrom(msg.sender, buyer, tokenId);

        // Transfer funds
        (bool sellerSuccess, ) = msg.sender.call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller transfer failed");

        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");

        totalFeesCollected += fee;

        // Refund other offers
        _refundOtherOffers(tokenId, offerIndex);

        emit OfferAccepted(tokenId, msg.sender, buyer, amount);
    }

    /**
     * @dev Cancel offer
     * @param tokenId Token ID
     * @param offerIndex Offer index
     */
    function cancelOffer(uint256 tokenId, uint256 offerIndex) 
        external 
        nonReentrant 
    {
        require(offerIndex < offers[tokenId].length, "Invalid offer index");

        Offer storage offer = offers[tokenId][offerIndex];
        
        require(offer.buyer == msg.sender, "Not offer maker");
        require(offer.active, "Offer not active");

        uint256 refundAmount = offer.amount;
        offer.active = false;

        // Refund
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        require(success, "Refund failed");

        emit OfferCancelled(tokenId, msg.sender, offerIndex);
    }

    /**
     * @dev Refund expired or rejected offers
     */
    function _refundOtherOffers(uint256 tokenId, uint256 acceptedIndex) 
        private 
    {
        Offer[] storage tokenOffers = offers[tokenId];
        
        for (uint256 i = 0; i < tokenOffers.length; i++) {
            if (i != acceptedIndex && tokenOffers[i].active) {
                Offer storage offer = tokenOffers[i];
                offer.active = false;
                
                (bool success, ) = offer.buyer.call{value: offer.amount}("");
                require(success, "Refund failed");
            }
        }
    }

    /**
     * @dev Get active listings
     */
    function getActiveListing(uint256 tokenId) 
        external 
        view 
        returns (Listing memory) 
    {
        require(listings[tokenId].active, "Not listed");
        return listings[tokenId];
    }

    /**
     * @dev Get all offers for token
     */
    function getOffers(uint256 tokenId) 
        external 
        view 
        returns (Offer[] memory) 
    {
        return offers[tokenId];
    }

    /**
     * @dev Get user's active listings
     */
    function getUserListings(address user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return _userListings[user];
    }

    /**
     * @dev Owner: Update fee recipient
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
    }

    /**
     * @dev Owner: Emergency withdraw (only fees)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}

