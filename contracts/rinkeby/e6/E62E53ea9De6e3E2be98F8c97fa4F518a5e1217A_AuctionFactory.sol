// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import { Auction } from './Auction.sol';

contract AuctionFactory {
    address[] public auctions;

    event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

    constructor() {
    }

    function createAuction(uint bidIncrement, uint startBlock, uint endBlock, address tokenAddress, uint tokenId) public {
        Auction newAuction = new Auction(msg.sender, bidIncrement, startBlock, endBlock, tokenAddress, tokenId);
        auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender, auctions.length, auctions);
    }

    function allAuctions() public returns (address[] memory) {
        return auctions;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Auction {
    // static
    address public owner;
    uint public bidIncrement;
    uint public startTimestamp;
    uint public endTimestamp;

    address public tokenAddress;
    uint public tokenId;

    // state
    bool public canceled;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

    constructor(address _owner, uint _bidIncrement, uint _startTimestamp, uint _endTimestamp, address _tokenAddress, uint _tokenId) {
        require(_startTimestamp < _endTimestamp);
        require(_startTimestamp >= block.timestamp);
        require(owner != address(0));

        owner = _owner;
        bidIncrement = _bidIncrement;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        tokenAddress = _tokenAddress;
        tokenId = _tokenId;
    }

    function placeBid()
    public
    payable
    onlyAfterStart
    onlyBeforeEnd
    onlyNotCanceled
    onlyNotOwner
    returns (bool success)
    {
        require(msg.value != 0);
        uint newBid = fundsByBidder[msg.sender] + msg.value;
        uint highestBid = fundsByBidder[highestBidder];
        require(newBid > highestBid);

        fundsByBidder[msg.sender] = newBid;
        highestBidder = msg.sender;
        highestBid = newBid;

        emit LogBid(msg.sender, newBid, highestBidder, highestBid);
        return true;
    }

    function cancelAuction()
    public
    onlyOwner
    onlyBeforeEnd
    onlyNotCanceled
    returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }

    function withdraw()
    public
    onlyEndedOrCanceled
    returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
        } else {
            if (msg.sender == owner) {
                withdrawalAccount = highestBidder;
                withdrawalAmount = fundsByBidder[highestBidder];
                ownerHasWithdrawn = true;
            } else {
                require(msg.sender != highestBidder);
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }
        require(withdrawalAmount != 0);
        fundsByBidder[withdrawalAccount] -= withdrawalAmount;
        require(payable(msg.sender).send(withdrawalAmount));
        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != owner);
        _;
    }

    modifier onlyAfterStart {
        require(block.timestamp >= startTimestamp);
        _;
    }

    modifier onlyBeforeEnd {
        require(block.timestamp < endTimestamp);
        _;
    }

    modifier onlyNotCanceled {
        require(!canceled);
        _;
    }

    modifier onlyEndedOrCanceled {
        require(block.timestamp >= endTimestamp || canceled);
        _;
    }
}