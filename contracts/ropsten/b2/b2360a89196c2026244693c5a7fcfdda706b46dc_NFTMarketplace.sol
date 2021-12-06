// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC721.sol";

contract NFTMarketplace is ERC721 {

    uint256 private _tokenID;
    uint256 private _auctionID;

    address contractOwner;

    mapping(uint256 => uint256) private _openingTime;
    mapping(uint256 => uint256) private _closingTime;
    mapping(uint256 => uint256) private _tokenOnAuction;
    mapping(uint256 => uint256) private _minimumBiddingAmount;

    mapping(uint256 => address) private _originalCreater;
    mapping(uint256 => address) private _auctionOwner;

    mapping(uint256 => bool) private _ownerWithdrawn;
    mapping(uint256 => bool) private _auctionRunning;

    mapping(uint256 => mapping(address => uint256)) private _amountBidded;

    struct Bid {
        address _bidderAddress;
        uint256 _biddingAmount;
    }

    mapping(uint256 => Bid) _currentBid;

    event AuctionCreated(uint256 _auctionID, uint256 _startingTime, uint256 _endingTime, uint256 _minimumBid);
    event Winner(address _winnerAddress, uint256 _winningBid);

    constructor(string memory name, string memory symbol, string memory baseURI) public ERC721(name, symbol) {
        ERC721._setBaseURI(baseURI);
        contractOwner = msg.sender;
        _tokenID = 0;
        _auctionID = 0;
    }

    modifier startingAuction(uint256 tokenID, uint256 openingTime, uint256 closingTime) {
        require(msg.sender == ownerOf(tokenID), "Not authorised to conduct auction");
        require(openingTime <= closingTime, "Opening time of bid should be smaller than closing time");
        _;
    }

    modifier checkBid(uint256 auctionID) {
        require(auctionID < _auctionID, "Not such Auction");
        require(msg.sender != _auctionOwner[auctionID], "Owner can not bid in Auction");
        require(msg.value >= _minimumBiddingAmount[auctionID], "Bidding amount smaller than minimum bidding amount");
        require(block.timestamp >= _openingTime[auctionID] && block.timestamp <= _closingTime[auctionID], "Time to bid has not started or already over");
        require(_currentBid[auctionID]._biddingAmount < msg.value, "Current bid smaller than current highest bid");
        _;
    }

    modifier checkWithdraw(uint256 auctionID) {
        require(auctionID < _auctionID, "No such Auction");
        require(block.timestamp > _closingTime[auctionID], "Auction not finished yet");
        require(_currentBid[auctionID]._bidderAddress != _auctionOwner[auctionID], "No bid with at least minimum value placed");
        _;
    }

    function createNFT(address to, string memory tokenURI) public {
        require(msg.sender == contractOwner, "Only contract owner can create NFT and can make owner anyone");
        ERC721._safeMint(to, _tokenID);
        _originalCreater[_tokenID] = to;
        _setTokenURI(_tokenID, tokenURI);
        _tokenID += 1;
    }

    function startAuction(uint256 tokenID, uint256 openingTime, uint256 closingTime, uint256 minBid) public startingAuction(tokenID, openingTime, closingTime) returns(uint256) {
        _currentBid[_auctionID] = Bid(msg.sender, 0);
        _auctionOwner[_auctionID] = msg.sender;
        _minimumBiddingAmount[_auctionID] = minBid;
        _openingTime[_auctionID] = openingTime;
        _closingTime[_auctionID] = closingTime;
        _tokenOnAuction[_auctionID] = tokenID;
        _auctionRunning[_auctionID] = true;
        emit AuctionCreated(_auctionID, openingTime, closingTime, minBid);
        _auctionID += 1;
        return _auctionID-1;
    }

    function placeBid(uint256 auctionID) public payable checkBid(auctionID) {
        _amountBidded[auctionID][msg.sender] += msg.value;
        _currentBid[auctionID]._bidderAddress = msg.sender;
        _currentBid[auctionID]._biddingAmount = msg.value;
        _amountBidded[auctionID][_originalCreater[_tokenOnAuction[auctionID]]] = uint256(msg.value/10);
    }

    function withdraw(uint256 auctionID) public payable checkWithdraw(auctionID) {
        _auctionRunning[auctionID] = false;
        address payable withdrawerAddress = payable(msg.sender);
        if(withdrawerAddress == _auctionOwner[auctionID] && _ownerWithdrawn[auctionID] == false) {
            ERC721.safeTransferFrom(_auctionOwner[auctionID], _currentBid[auctionID]._bidderAddress, _tokenOnAuction[auctionID]);
            withdrawerAddress.transfer(_currentBid[auctionID]._biddingAmount-_amountBidded[auctionID][_originalCreater[_tokenOnAuction[auctionID]]]);
            _ownerWithdrawn[auctionID] = true;
        }
        else if (withdrawerAddress == _currentBid[auctionID]._bidderAddress) {
            withdrawerAddress.transfer(_amountBidded[auctionID][withdrawerAddress]-_currentBid[auctionID]._biddingAmount);
            _amountBidded[auctionID][withdrawerAddress] = 0;
            emit Winner(_currentBid[auctionID]._bidderAddress, _currentBid[auctionID]._biddingAmount);
        }
        else {
            withdrawerAddress.transfer(_amountBidded[auctionID][withdrawerAddress]);
            _amountBidded[auctionID][withdrawerAddress] = 0;
        }
    }

    function auctionClosingTime(uint256 auctionID) public view returns(uint256) {
        return _closingTime[auctionID];
    }

    function currentHighestBid(uint256 auctionID) public view returns(address, uint256) {
        return (_currentBid[auctionID]._bidderAddress, _currentBid[auctionID]._biddingAmount);
    }

    function minimumBid(uint256 auctionID) public view returns(uint256) {
        return _minimumBiddingAmount[auctionID];
    }
}