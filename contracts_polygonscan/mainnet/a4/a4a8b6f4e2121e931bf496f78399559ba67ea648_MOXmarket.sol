/***
 *
 * 
 *  Project: XXX
 *  Website: XXX
 *  Contract: MOX market
 *  
 *  Description: Manages the selling of MOX NFTs via a simple bidding mechanism  
 * 
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IMOX.sol"; 
import "./IMOXshares.sol"; 
import "./IMOXbucks.sol";

contract MOXmarket {
    
    address private _nftContractAddress;
    
    // Fired when a new bid is placed
    event BidSuccess(address _from, uint _auctionId);

    // Fired when a new auction is created
    event AuctionCreated(address _owner, uint _auctionId);

    // Fired when an auction is canceled
    event AuctionCanceled(address _owner, uint _auctionId);
    
    // Fired when an auction is completed
    event AuctionCompleted(address _owner, uint _auctionId);
    
    // Auction struct which holds all the required info
    struct Auction {
        string name;
        uint256 startPrice;
        uint256 nftId;
        address payable owner;
        bool active;
    }
    
    // Bid struct to hold bidder address and amount
    struct Bid {
        address payable from;
        uint256 amount;
    }
    
    // Array with all auctions
    Auction[] public auctions;

    // Mapping from auction index to user bids
    mapping(uint256 => Bid[]) public auctionBids;

    // Mapping from owner to a list of owned auctions
    mapping(address => uint[]) public auctionOwner;

    IMOXbucks private bucksContract;
    
    /**
    * @dev Guarantees msg.sender is owner of the given auction
    * 
    */
    modifier isOwner(uint _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }
    
     /**
    * @dev Guarantees msg.sender is the owner of the given NFT id
    * 
    */
    modifier isNFTOwner(uint _nftId) {
        require(IMOX(_nftContractAddress).ownerOf(_nftId) == msg.sender);
        _;
    }

    /**
    * @dev Guarantees this contract is owner of the given deed/token
    * 
    */
    modifier contractIsNFTOwner(uint256 _nftId) {
        address nftOwner = IMOX(_nftContractAddress).ownerOf(_nftId);
        require(nftOwner == address(this));
        _;
    }
    
    
    constructor (address nftContract, address MOXbucksContract) {
        _nftContractAddress = nftContract;
        bucksContract = IMOXbucks(MOXbucksContract); 
    }
    
    
     /**
    * @dev Gets the auction count
    * 
    */
    function getCount() public view returns(uint) {
        return auctions.length;
    }

    /**
    * @dev Gets the bid counts of a given auction
    * 
    */
    function getBidsCount(uint _auctionId) public view returns(uint) {
        return auctionBids[_auctionId].length;
    }

    /**
    * @dev Gets an array of owned auctions
    * 
    */
    function getAuctionsOf(address _owner) public view returns(uint[] memory) {
        uint[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }
    
    /**
    * @dev Gets the total number of auctions owned by an address
    * 
    */
    function getAuctionsCountOfOwner(address _owner) public view returns(uint) {
        return auctionOwner[_owner].length;
    }

    /**
    * @dev Gets the last bid amount and the address of the last bidder
    * 
    */
    function getCurrentBid(uint _auctionId) public view returns(uint256, address) {
        uint bidsLength = auctionBids[_auctionId].length;
       
        if( bidsLength > 0 ) {
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from);
        }
        return (uint256(0), address(0));
    }
    
    /**
    * @dev Gets the info of a given auction 
    * 
    */
    function getAuctionById(uint _auctionId) public view returns(
        string memory name,
        uint256 startPrice,
        uint256 nftId,
        address owner,
        bool active) {

        Auction memory auc = auctions[_auctionId];
        return (
            auc.name, 
            auc.startPrice, 
            auc.nftId, 
            auc.owner, 
            auc.active
            );
    }
    
    /**
    * @dev Creates an auction and sends the NFT to the contract
    *  
    */
    function createAuction(uint256 _nftId, string memory _auctionTitle, uint256 _startPrice) public isNFTOwner(_nftId) returns(bool) {
        uint auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.name = _auctionTitle;
        newAuction.startPrice = _startPrice;
        newAuction.nftId = _nftId;
        newAuction.owner = payable(msg.sender);
        newAuction.active = true;
        
        auctions.push(newAuction);        
        auctionOwner[msg.sender].push(auctionId);
        
        IMOX(_nftContractAddress).superSafeTransferFrom(msg.sender, address(this), _nftId); 
         
        emit AuctionCreated(msg.sender, auctionId);
        return true;
    }
    
    /**
    * @dev  Bidder sends bid on an auction in MOX bucks
    *       Auction should be active and not ended
    *       Refund previous bidder if a new bid is valid and placed
    *       
    */
    function bidOnAuction(uint _auctionId, uint bidAmount) public {
        Auction memory myAuction = auctions[_auctionId];
        require(myAuction.active == true, "Auction not active");
        require(myAuction.owner != msg.sender, "Owners can't bid on their auctions");
        
        uint256 currentBid;
        address currentBidder;
        (currentBid, currentBidder) = getCurrentBid(_auctionId);
        require(bucksContract.balanceOf(msg.sender) >= currentBid, "Not enough tokens");
        
       
        uint bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        // there are previous bids
        if( bidsLength > 0 ) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.amount;
        }
        
        require(bidAmount > tempAmount, "Can't bid lower than previous bid");

        // refund the last bidder
        if( bidsLength > 0 ) {
            bucksContract.transferFrom(address(this), lastBid.from, lastBid.amount);
        }

        // insert bid 
        Bid memory newBid;
        newBid.from = payable(msg.sender);
        newBid.amount = bidAmount;
        auctionBids[_auctionId].push(newBid);
        emit BidSuccess(msg.sender, _auctionId);
        
        bucksContract.transferFrom(msg.sender, address(this), bidAmount); 
    }
    
    
    /**
    * @dev  Auction owner accepts bid
    *       Auction owner receive bid amount
    *       First owner and share holders receive royalty
    *       Bidder receives NFT
    */
    
    function acceptLastBid(uint _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        require(myAuction.active == true, "Auction not active");
        require(myAuction.owner == msg.sender, "Only owners can accept bids on their auctions");
        uint256 currentBid;
        address currentBidder;
        (currentBid, currentBidder) = getCurrentBid(_auctionId);
        
        // Auction owner receives bid amount. First owner and share holders gets royalties
        bucksContract.transferFromMarket(address(this), msg.sender, currentBid, IMOX(_nftContractAddress).getFirstOwner(myAuction.nftId)); 
        
        //Bidder receives NFT
        IMOX(_nftContractAddress).superSafeTransferFrom(address(this), msg.sender, myAuction.nftId); 
        
        
    }
    
}