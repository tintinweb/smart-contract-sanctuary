pragma solidity ^0.4.11;

contract ERC20Token {
  function balanceOf(address _who) constant returns (uint balance);
  function transferFrom(address _from, address _to, uint _value);
  function transfer(address _to, uint _value);
}

contract UnicornRanch {
  enum VisitType { Spa, Afternoon, Day, Overnight, Week, Extended }
  enum VisitState { InProgress, Completed, Repossessed }
  function getBooking(address _who, uint _index) constant returns (uint _unicornCount, VisitType _type, uint _startBlock, uint _expiresBlock, VisitState _state, uint _completedBlock, uint _completedCount);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract UnicornRefunds {
  using SafeMath for uint;

  address public cardboardUnicornTokenAddress;
  address public unicornRanchAddress;
  address public owner = msg.sender;
  uint public pricePerUnicorn = 1 finney;
  uint public rewardUnicornAmount = 100;
  mapping(address => uint) allowedAmounts;
  mapping(address => bool) rewardClaimed;

  event RewardClaimed(address indexed _who, uint _bookingIndex);
  event UnicornsSold(address indexed _who, uint _unicornCount, uint _unicornCost, uint _paymentTotal);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  function claimReward(uint _bookingIndex) {
    UnicornRanch ranch = UnicornRanch(unicornRanchAddress);
    var (unicornCount, visitType, , , state, , completedCount) = ranch.getBooking(msg.sender, _bookingIndex);
    require(state == UnicornRanch.VisitState.Completed); // Must be a visit that&#39;s completed (not in progress or repossessed)
    require(visitType != UnicornRanch.VisitType.Spa); // Must be longer than a Spa visit
    require(completedCount > unicornCount); // Must have triggered the "birth" conditions so the user went home with more than what they send in
    require(rewardClaimed[msg.sender] == false); // Must not have already claimed the reward
      
    rewardClaimed[msg.sender] = true;
    allowedAmounts[msg.sender] = allowedAmounts[msg.sender].add(rewardUnicornAmount);
      
    RewardClaimed(msg.sender, _bookingIndex);
  }
  
  /**
   * Sell back a number of unicorn tokens, in exchange for ether.
   */
  function sell(uint _unicornCount) {
    require(_unicornCount > 0);
    allowedAmounts[msg.sender] = allowedAmounts[msg.sender].sub(_unicornCount);
    ERC20Token cardboardUnicorns = ERC20Token(cardboardUnicornTokenAddress);
    cardboardUnicorns.transferFrom(msg.sender, owner, _unicornCount); // Transfer the actual asset
    uint total = pricePerUnicorn.mul(_unicornCount);
    msg.sender.transfer(total);
    UnicornsSold(msg.sender, _unicornCount, pricePerUnicorn, total);
  }
  
  function() payable {
    // Thanks for the donation!
  }
  
  /**
   * Change ownership
   */
  function changeOwner(address _newOwner) onlyOwner {
    owner = _newOwner;
  }

  /**
   * Change the outside contracts used by this contract
   */
  function changeCardboardUnicornTokenAddress(address _newTokenAddress) onlyOwner {
    cardboardUnicornTokenAddress = _newTokenAddress;
  }
  function changeUnicornRanchAddress(address _newAddress) onlyOwner {
    unicornRanchAddress = _newAddress;
  }
  
  /**
   * Update unicorn price
   */
  function changePricePerUnicorn(uint _newPrice) onlyOwner {
    pricePerUnicorn = _newPrice;
  }
  
  /**
   * Update reward amount
   */
  function changeRewardAmount(uint _newAmount) onlyOwner {
    rewardUnicornAmount = _newAmount;
  }
  
  function setAllowance(address _who, uint _amount) onlyOwner {
    allowedAmounts[_who] = _amount;
  }
  
  function withdraw() onlyOwner {
    owner.transfer(this.balance); // Send all ether in this contract to this contract&#39;s owner
  }
  function withdrawForeignTokens(address _tokenContract) onlyOwner {
    ERC20Token token = ERC20Token(_tokenContract);
    token.transfer(owner, token.balanceOf(address(this))); // Send all owned tokens to this contract&#39;s owner
  }
  
}