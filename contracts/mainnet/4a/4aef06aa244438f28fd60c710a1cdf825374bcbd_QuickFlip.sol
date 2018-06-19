pragma solidity ^0.4.18;

contract QuickFlip {
  using SafeMath for uint256;

  address public owner;
  address private cardOwner;
  uint256 public cardPrice;
  uint256 public startTime = 1520899200;
  uint256 public purchaseRound;

  uint256 public constant STARTING_PRICE = 0.025 ether;

  function QuickFlip() public {
    owner = msg.sender;
    cardOwner = msg.sender;
    cardPrice = STARTING_PRICE;
  }

  function buy() public payable {
    uint256 price;
    address oldOwner;

    (price, oldOwner) = getCard();

    require(msg.value >= price);

    address newOwner = msg.sender;
    uint256 purchaseExcess = msg.value - price;

    cardOwner = msg.sender;
    cardPrice = price.mul(12).div(10); // increase by 20%
    purchaseRound = currentRound();

    oldOwner.transfer(price);
    newOwner.transfer(purchaseExcess);
  }

  function currentRound() public view returns (uint256) {
    return now.sub(startTime).div(1 days);
  }

  function getCard() public view returns (uint256 _price, address _owner) {
    if (currentRound() > purchaseRound) {
      _price = STARTING_PRICE;
      _owner = owner;
    } else {
      _price = cardPrice;
      _owner = cardOwner;
    }
  }
}


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