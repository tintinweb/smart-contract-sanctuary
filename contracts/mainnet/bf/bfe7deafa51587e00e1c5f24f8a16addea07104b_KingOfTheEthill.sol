pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract KingOfTheEthill {
  using SafeMath for uint256;  
  address public owner;
  address public king;
  string public kingsMessage;
  uint256 public bidExpireBlockLength = 12;
  uint256 public nextBidExpireBlockLength;
  uint256 public devFeePercent = 1;
  uint256 public rolloverPercent = 5;
  uint256 public lastBidAmount;
  uint256 public lastBidBlock;
  uint256 public currentRoundNumber;
  uint256 public currentBidNumber;
  uint256 public maxMessageChars = 140;
  mapping(uint256 => address) roundToKing;
  mapping(uint256 => uint256) roundToWinnings;
  mapping(uint256 => uint256) roundToFinalBid;
  mapping(uint256 => string) roundToFinalMessage;

  event NewKing(
    uint256 indexed roundNumber,
    address kingAddress,
    string kingMessage,
    uint256 bidAmount,
    uint256 indexed bidNumber,
    uint256 indexed bidBlockNumber
  );

  function KingOfTheEthill () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }
  
  function setDevFee (uint256 _n) onlyOwner() public {
	  require(_n >= 0 && _n <= 10);
    devFeePercent = _n;
  }

  function setRollover (uint256 _n) onlyOwner() public {
	  require(_n >= 1 && _n <= 30);
    rolloverPercent = _n;
  }

  function setNextBidExpireBlockLength (uint256 _n) onlyOwner() public {
	  require(_n >= 10 && _n <= 10000);
    nextBidExpireBlockLength = _n;
  }

  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function bid (uint256 _roundNumber, string _message) payable public {
    require(!isContract(msg.sender));
    require(bytes(_message).length <= maxMessageChars);
    require(msg.value > 0);
    
    if (_roundNumber == currentRoundNumber && !roundExpired()) {
      // bid in active round
      require(msg.value > lastBidAmount);
    }else if (_roundNumber == (currentRoundNumber+1) && roundExpired()) {
      // first bid of new round, process old round
      var lastRoundPotBalance = this.balance.sub(msg.value);
      uint256 devFee = lastRoundPotBalance.mul(devFeePercent).div(100);
      owner.transfer(devFee);
      uint256 winnings = lastRoundPotBalance.sub(devFee).mul(100 - rolloverPercent).div(100);
      king.transfer(winnings);

      // save previous round data
      roundToKing[currentRoundNumber] = king;
      roundToWinnings[currentRoundNumber] = winnings;
      roundToFinalBid[currentRoundNumber] = lastBidAmount;
      roundToFinalMessage[currentRoundNumber] = kingsMessage;

      currentBidNumber = 0;
      currentRoundNumber++;

      if (nextBidExpireBlockLength != 0) {
        bidExpireBlockLength = nextBidExpireBlockLength;
        nextBidExpireBlockLength = 0;
      }
    }else {
      require(false);
    }

    // new king
    king = msg.sender;
    kingsMessage = _message;
    lastBidAmount = msg.value;
    lastBidBlock = block.number;

    NewKing(currentRoundNumber, king, kingsMessage, lastBidAmount, currentBidNumber, lastBidBlock);

    currentBidNumber++;
  }

  function roundExpired() public view returns (bool) {
    return blocksSinceLastBid() >= bidExpireBlockLength;
  }

  function blocksRemaining() public view returns (uint256) {
    if (roundExpired()) {
      return 0;
    }else {
      return bidExpireBlockLength - blocksSinceLastBid();
    }
  }

  function blocksSinceLastBid() public view returns (uint256) {
    return block.number - lastBidBlock;
  }

  function estimateNextPotSeedAmount() public view returns (uint256) {
      return this.balance.mul(100 - devFeePercent).div(100).mul(rolloverPercent).div(100);
  }

  function getRoundState() public view returns (bool _currentRoundExpired, uint256 _nextRoundPotSeedAmountEstimate, uint256 _roundNumber, uint256 _bidNumber, address _king, string _kingsMessage, uint256 _lastBidAmount, uint256 _blocksRemaining, uint256 _potAmount, uint256 _blockNumber, uint256 _bidExpireBlockLength) {
    _currentRoundExpired = roundExpired();
    _nextRoundPotSeedAmountEstimate = estimateNextPotSeedAmount();
    _roundNumber = currentRoundNumber;
    _bidNumber = currentBidNumber;
    _king = king;
    _kingsMessage = kingsMessage;
    _lastBidAmount = lastBidAmount;
    _blocksRemaining = blocksRemaining();
    _potAmount = this.balance;
    _blockNumber = block.number;
    _bidExpireBlockLength = bidExpireBlockLength;
  }

  function getPastRound(uint256 _roundNum) public view returns (address _kingAddress, uint256 _finalBid, uint256 _kingWinnings, string _finalMessage) {
    _kingAddress = roundToKing[_roundNum]; 
    _kingWinnings = roundToWinnings[_roundNum];
    _finalBid = roundToFinalBid[_roundNum];
    _finalMessage = roundToFinalMessage[_roundNum];
  }

  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}