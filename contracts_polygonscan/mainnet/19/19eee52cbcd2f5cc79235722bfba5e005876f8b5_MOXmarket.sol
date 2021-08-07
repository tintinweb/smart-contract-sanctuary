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

    constructor (address nftContract) {
        _nftContractAddress = nftContract;
    }
    
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
    * @dev Creates an auction 
    * 
    */
    function createAuction(uint256 _nftId, string memory _auctionTitle, uint256 _startPrice) public contractIsNFTOwner(_nftId) returns(bool) {
        uint auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.name = _auctionTitle;
        newAuction.startPrice = _startPrice;
        newAuction.nftId = _nftId;
        newAuction.owner = payable(msg.sender);
        newAuction.active = true;
        
        auctions.push(newAuction);        
        auctionOwner[msg.sender].push(auctionId);
        
        IMOX(_nftContractAddress).transferFrom(msg.sender, address(this), _nftId);
        
        emit AuctionCreated(msg.sender, auctionId);
        return true;
    }
    
}