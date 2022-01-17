// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OutlandOperator {
  address public owner = msg.sender;

  event AuctionCreated(uint auctionId, address owner, uint startTimestamp, uint endTimestamp, address tokenAddress, uint tokenId);
  event AuctionBid(uint auctionId, address bidder, uint bid, address highestBidder, uint highestBid);
  event AuctionWithdrawal(uint auctionId, address withdrawer, address withdrawalAccount, uint amount);
  event AuctionCanceled(uint auctionId);

  struct Auction {
    uint startTimestamp;
    uint endTimestamp;
    uint tokenId;
    bool canceled;
    bool ownerHasWithdrawn;
    address owner;
    address highestBidder;
    address tokenAddress;
    mapping(address => uint256) fundsByBidder;
  }

  Auction[] public auctions;

  function createAuction(uint _startTimestamp, uint _endTimestamp, address _tokenAddress, uint _tokenId) public {
    require(_startTimestamp < _endTimestamp);
    require(_startTimestamp >= block.timestamp);
    require(msg.sender != address(0));

    uint index = auctions.length;
    auctions.push();

    Auction storage auction = auctions[index];
    auction.tokenAddress = _tokenAddress;
    auction.tokenId = _tokenId;
    auction.startTimestamp = _startTimestamp;
    auction.endTimestamp = _endTimestamp;
    auction.owner = msg.sender;

    emit AuctionCreated(index, msg.sender, _startTimestamp, _endTimestamp, _tokenAddress, _tokenId);
  }

  function placeBid(uint auctionId)
  public
  payable
  onlyAfterStart(auctionId)
  onlyBeforeEnd(auctionId)
  onlyNotCanceled(auctionId)
  onlyNotOwner(auctionId)
  returns (bool success)
  {
    Auction storage auction = auctions[auctionId];
    require(auction.startTimestamp != 0);
    require(msg.value != 0);
    uint newBid = auction.fundsByBidder[msg.sender] + msg.value;
    uint highestBid = auction.fundsByBidder[auction.highestBidder];
    require(newBid > highestBid);

    auction.fundsByBidder[msg.sender] = newBid;
    auction.highestBidder = msg.sender;
    highestBid = newBid;

    emit AuctionBid(auctionId, msg.sender, newBid, auction.highestBidder, highestBid);
    return true;
  }

  function cancelAuction(uint auctionId)
  public
  onlyOwner(auctionId)
  onlyBeforeEnd(auctionId)
  onlyNotCanceled(auctionId)
  returns (bool success)
  {
    Auction storage auction = auctions[auctionId];
    require(auction.startTimestamp != 0);
    auction.canceled = true;
    emit AuctionCanceled(auctionId);
    return true;
  }

  function withdraw(uint auctionId)
  public
  onlyEndedOrCanceled(auctionId)
  returns (bool success)
  {
    Auction storage auction = auctions[auctionId];
    require(auction.startTimestamp != 0);
    address withdrawalAccount;
    uint withdrawalAmount;

    if (auction.canceled) {
      withdrawalAccount = msg.sender;
      withdrawalAmount = auction.fundsByBidder[withdrawalAccount];
    } else {
      if (msg.sender == auction.owner) {
        withdrawalAccount = auction.highestBidder;
        withdrawalAmount = auction.fundsByBidder[auction.highestBidder];
        auction.ownerHasWithdrawn = true;
      } else {
        require(msg.sender != auction.highestBidder);
        withdrawalAccount = msg.sender;
        withdrawalAmount = auction.fundsByBidder[withdrawalAccount];
      }
    }
    require(withdrawalAmount != 0);
    auction.fundsByBidder[withdrawalAccount] -= withdrawalAmount;
    require(payable(msg.sender).send(withdrawalAmount));
    emit AuctionWithdrawal(auctionId, msg.sender, withdrawalAccount, withdrawalAmount);
    return true;
  }

  modifier onlyOwner (uint auctionId) {
    require(msg.sender == auctions[auctionId].owner);
    _;
  }

  modifier onlyNotOwner (uint auctionId) {
    require(msg.sender != auctions[auctionId].owner);
    _;
  }

  modifier onlyAfterStart (uint auctionId) {
    require(block.timestamp >= auctions[auctionId].startTimestamp);
    _;
  }

  modifier onlyBeforeEnd (uint auctionId) {
    require(block.timestamp < auctions[auctionId].endTimestamp);
    _;
  }

  modifier onlyNotCanceled (uint auctionId) {
    require(!auctions[auctionId].canceled);
    _;
  }

  modifier onlyEndedOrCanceled (uint auctionId) {
    require(block.timestamp >= auctions[auctionId].endTimestamp || auctions[auctionId].canceled);
    _;
  }

}