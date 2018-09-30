pragma solidity ^0.4.23;

contract OpenAuction {
  // contract params
  address public beneficiary;
  uint public auctionEnd; //time period in seconds
  uint256 public minValue;
  uint256 public stepValue;

  // current state of auction
  address public highestBidder;
  uint public highestBid;

  // previous bids
  mapping(address => uint) penddingReturns;

  // check auction end, == true when auction end
  bool ended;

  // Events that will be fired on changes.
  event HighestBidIncreased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);

  /// Create a simple auction with `_biddingTime`
  /// seconds bidding time on behalf of the
  /// beneficiary address `_beneficiary`.
  constructor(
    uint _biddingTime,
    address _beneficiary,
    uint256 _minValue,
    uint256 _stepValue
  ) public {
    beneficiary = _beneficiary;
    auctionEnd = now + _biddingTime; // with biddingTime is seconds from now
    minValue = _minValue;
    stepValue = _stepValue;
  }

  /// Bid on the auction with the value sent
  /// together with this transaction.
  /// The value will only be refunded if the
  /// auction is not won.
  function bid() public payable {
    // require auction not end
    require(now <= auctionEnd, "Auction already ended.");
    // require value > step value
    // require(msg.value >= stepValue, "Value smaller than step value.");
    // check new value of sender > highestBid
    // require(penddingReturns[msg.sender] + msg.value >= minValue, "Value smaller than min value.");
    require(msg.value > highestBid, "There already is a higher bid.");

    if (highestBid != 0) {
      penddingReturns[highestBidder] = highestBid;
    }
    highestBidder = msg.sender;
    highestBid = penddingReturns[msg.sender] + msg.value;
    penddingReturns[msg.sender] = 0;
    emit HighestBidIncreased(msg.sender, msg.value);
  }

  function withdraw() public returns (bool) {
    uint amount = penddingReturns[msg.sender];
    if (amount > 0) {
      penddingReturns[msg.sender] = 0;
      if (!msg.sender.send(amount)) {
        penddingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  function endAuction() public {
    require(now >= auctionEnd, "Auction not end yet!");
    require(!ended, "endAuction already called.");

    ended = true;
    emit AuctionEnded(highestBidder, highestBid);
  }
}