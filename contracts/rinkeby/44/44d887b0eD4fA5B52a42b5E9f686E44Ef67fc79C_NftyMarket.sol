/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;


interface ERC721 {

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;


    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);


    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract NftyMarket {

    address public owner;
    uint protocolFeeBps; // (1/10000)

    string public standard = 'NftyMarket';

    struct Asset {
        ERC721 collection;
        uint index;
    }

    struct Offer {
        Asset asset;
        bool isForSale;
        address seller;
        uint minValue;
        address onlySellTo;
    }

    struct Bid {
        Asset asset;
        bool hasBid;
        address bidder;
        uint value;
    }

    // A record of assets that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (ERC721 => mapping(uint => Offer)) offersForSale;

    // A record of the highest asset bid
    mapping (ERC721 => mapping(uint => Bid)) bids;

    mapping (address => uint) public pendingWithdrawals;

    event AssetOffered(ERC721 indexed collection, uint indexed index, address indexed toAddress, uint minValue);
    event AssetBidEntered(ERC721 indexed collection, uint indexed index, address indexed fromAddress, uint value);
    event AssetBidWithdrawn(ERC721 indexed collection, uint indexed index, address indexed fromAddress, uint value);
    event AssetBought(ERC721 indexed collection, uint indexed index, address indexed toAddress, address fromAddress, uint value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint protocolFees) payable {
        protocolFeeBps = protocolFees;
        owner = msg.sender;
    }
    
    function updateFees(uint protocolFees) public {
        require(msg.sender == owner,"Only owner can update fees");
        protocolFeeBps = protocolFees;
    }
    
    function getOfferPrice(ERC721 collection,uint index) public view returns(uint) {
        Offer storage offer = offersForSale[collection][index];
        return offer.isForSale ? offer.minValue : 0;
    }
    
    function getBidPrice(ERC721 collection,uint index) public view returns(uint) {
        Bid storage bid = bids[collection][index];
        return bid.hasBid ? bid.value : 0;
    }
    
    function settleAmount(address buyer,address seller,uint amount) private {
        require(pendingWithdrawals[buyer] >= amount);
        uint fees = (amount / 10000) * protocolFeeBps;
        pendingWithdrawals[buyer] -= amount;
        pendingWithdrawals[seller] += (amount - fees);
        pendingWithdrawals[owner] += fees;
    }

    function withdrawOffer(ERC721 collection,uint index) public {
        require (collection.ownerOf(index) == msg.sender,"Only owner can withdraw offer");
        offersForSale[collection][index] = Offer(Asset(collection,index),false,msg.sender,0,address(0));   
    }

    function offerForSale(ERC721 collection, uint index, uint minSalePriceInWei,address toAddress) public {
        require (collection.ownerOf(index) == msg.sender,"Only owner can offer for sale");
        require(
            collection.getApproved(index) == address(this) ||
            collection.isApprovedForAll(msg.sender,address(this)),"Owner hasn't approved marketplace");
        offersForSale[collection][index] = Offer(Asset(collection,index),true,msg.sender,minSalePriceInWei,toAddress);
        emit AssetOffered(collection,index,toAddress,minSalePriceInWei);
    }

    function acceptOffer(ERC721 collection, uint index) payable public {
        Offer storage offer = offersForSale[collection][index];
        require(collection.ownerOf(index) == offer.seller,"Invalid owner for offer");
        require(
            collection.getApproved(index) == address(this) ||
            collection.isApprovedForAll(offer.seller,address(this)),"Owner hasn't approved marketplace");

        require(offer.isForSale,"Asset not on offer");
        require(offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender,"Offer not available to user");
        require(msg.value + pendingWithdrawals[msg.sender] >= offer.minValue,"Offer & balance not sufficient");

        address seller = offer.seller;
        uint amount = offer.minValue;

        offersForSale[collection][index] = Offer(Asset(collection,index),false,msg.sender,0,address(0));
        
        collection.safeTransferFrom(seller,msg.sender,index);
        pendingWithdrawals[msg.sender] += msg.value;
        settleAmount(msg.sender,seller,amount);
        emit AssetBought(collection, index, msg.sender, seller,msg.value);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid storage bid = bids[collection][index];
        if (bid.bidder == msg.sender) {
            bids[collection][index] = Bid(Asset(collection,index),false, address(0), 0);
        }
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBid(ERC721 collection, uint index,uint256 amount) payable public {
        require(collection.ownerOf(index) != msg.sender,"Owner cannot bid");
        require(amount > 0, "Need non-zero bid");
        Bid storage existing = bids[collection][index];
        require(amount > existing.value || pendingWithdrawals[existing.bidder] < existing.value,"Can only increase on a valid bid");
        
        pendingWithdrawals[msg.sender] += msg.value;
        require(pendingWithdrawals[msg.sender] >= amount,"Not enough balance for bid");
        
        bids[collection][index] = Bid(Asset(collection,index),true, msg.sender, amount);
        emit AssetBidEntered(collection,index, msg.sender,amount);
    }

    function acceptBid(ERC721 collection,uint index, uint minPrice) public {
        require(collection.ownerOf(index) == msg.sender,"Only owner can accept bids");
        require(
            collection.getApproved(index) == address(this) ||
            collection.isApprovedForAll(msg.sender,address(this)),"Owner hasn't approved marketplace");

        address seller = msg.sender;
        Bid storage bid = bids[collection][index];
        address bidder = bid.bidder;
        uint amount = bid.value;
        require(amount > 0, "Bid should be non-zero");
        require(amount >= minPrice, "Bid below seller limit");

        offersForSale[collection][index] = Offer(Asset(collection,index),false, bidder, 0, address(0));
        bids[collection][index] = Bid(Asset(collection,index),false, address(0), 0);
        
        collection.safeTransferFrom(msg.sender,bidder,index);
        settleAmount(bidder,seller,amount);
        emit AssetBought(collection,index, bidder,seller,amount);
    }

    function withdrawBid(ERC721 collection, uint index) public {
        Bid storage bid = bids[collection][index];
        require(bid.bidder == msg.sender,"Only bidder can withdraw");
        emit AssetBidWithdrawn(collection,index,msg.sender,bid.value);
        bids[collection][index] = Bid(Asset(collection,index),false, address(0), 0);
    }

}