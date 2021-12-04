/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

contract NFTMarketplace {

    uint256 private _tokenID;
    uint256 private _openingTime;
    uint256 private _closingTime;

    mapping(uint256 => address) private _originalCreater;
    mapping(address => uint256) private _amountBidded;

    bool private _ownerWithdrawn;

    address private _auctionOwner;

    uint256 private _tokenOnAuction;
    uint256 private _minimumBiddingAmount;

    struct Bid {
        address _bidderAddress;
        uint256 _biddingAmount;
    }

    Bid _currentBid;

    constructor(string memory name, string memory symbol, string memory baseURI) public {
        _tokenID = 0;
    }

    modifier checkBid {
        require(msg.sender != _auctionOwner);
        require(msg.value >= _minimumBiddingAmount);
        require(block.timestamp >= _openingTime && block.timestamp <= _closingTime);
        require(_currentBid._biddingAmount < msg.value);
        _;
    }

    modifier checkWithdraw {
        require(block.timestamp > _closingTime);
        _;
    }

    function createNFT(address to, string memory tokenURI) public {
        _originalCreater[_tokenID] = to;
        _tokenID += 1;
    }

    function startAuction(uint256 tokenID, uint256 openingTime, uint256 closingTime, uint256 minBid) public {
        require(openingTime <= closingTime);
        _currentBid = Bid(msg.sender, minBid);
        _auctionOwner = msg.sender;
        _minimumBiddingAmount = minBid;
        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    function placeBid() public payable checkBid {
        _amountBidded[msg.sender] += msg.value;
        _currentBid._bidderAddress = msg.sender;
        _currentBid._biddingAmount = msg.value;
    }

    function withdraw() public payable checkWithdraw {
        require(_currentBid._bidderAddress != _auctionOwner);
        address payable withdrawerAddress = payable(msg.sender);
        if(withdrawerAddress == _auctionOwner && _ownerWithdrawn == false) {
            withdrawerAddress.transfer(_currentBid._biddingAmount);
            _ownerWithdrawn = true;
        }
        else if (withdrawerAddress == _currentBid._bidderAddress) {
            withdrawerAddress.transfer(_amountBidded[withdrawerAddress]-_currentBid._biddingAmount);
            _amountBidded[withdrawerAddress] = 0;
        }
        else {
            withdrawerAddress.transfer(_amountBidded[withdrawerAddress]);
            _amountBidded[withdrawerAddress] = 0;
        }
    }

    function currentHighestBid() public view returns(uint256) {
        return _currentBid._biddingAmount;
    }

    function minimumBid() public view returns(uint256) {
        return _minimumBiddingAmount;
    }

}