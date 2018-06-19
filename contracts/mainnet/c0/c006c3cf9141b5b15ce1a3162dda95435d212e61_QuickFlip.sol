pragma solidity ^0.4.18;

contract QuickFlip {
  using SafeMath for uint256;

  address public owner;
  address private cardOwner;
  uint256 public cardPrice;
  uint256 public startTime = 1520899200;

  uint256 public constant PRIMARY_START_PRICE = 0.05 ether;
  uint256 public constant STARTING_PRICE = 0.005 ether;

  Card[] public cards;

  struct Card {
    address owner;
    uint256 price;
    uint256 purchaseRound;
  }

  function QuickFlip() public {
    owner = msg.sender;
    cards.push(Card({ owner: owner, price: PRIMARY_START_PRICE, purchaseRound: 0 }));
    cards.push(Card({ owner: owner, price: STARTING_PRICE, purchaseRound: 0 }));
    cards.push(Card({ owner: owner, price: STARTING_PRICE, purchaseRound: 0 }));
    cards.push(Card({ owner: owner, price: STARTING_PRICE, purchaseRound: 0 }));
  }

  function buy(uint256 _cardId) public payable {
    require(_cardId >= 0 && _cardId <= 3);

    uint256 price;
    address oldOwner;

    (price, oldOwner) = getCard(_cardId);

    require(msg.value >= price);

    address newOwner = msg.sender;
    uint256 purchaseExcess = msg.value - price;

    Card storage card = cards[_cardId];
    card.owner = msg.sender;
    card.price = price.mul(13).div(10); // increase by 30%
    card.purchaseRound = currentRound();

    uint256 fee = price.mul(5).div(100);
    uint256 profit = price.sub(fee);

    cards[0].owner.transfer(fee);
    oldOwner.transfer(profit);
    newOwner.transfer(purchaseExcess);
  }

  function currentRound() public view returns (uint256) {
    return now.sub(startTime).div(1 days);
  }

  function getCard(uint256 _cardId) public view returns (uint256 _price, address _owner) {
    Card memory card = cards[_cardId];

    if (currentRound() > card.purchaseRound) {
      if (_cardId == 0) {
        _price = PRIMARY_START_PRICE;
        _owner = owner;
      } else {
        _price = STARTING_PRICE;
        _owner = owner;
      }
    } else {
      _price = card.price;
      _owner = card.owner;
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