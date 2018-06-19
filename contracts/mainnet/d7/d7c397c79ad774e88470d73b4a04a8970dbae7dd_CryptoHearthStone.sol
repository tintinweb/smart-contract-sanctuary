pragma solidity ^0.4.19;

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



contract CryptoHearthStone {
  using SafeMath for uint256;
  struct Card {
        uint attribute; // Card occupational attributes
        uint256 price;// Card price
        address delegate; // person delegated to
        bool isSale;//Is the card sold?
  }

  Card[] private cards;

  mapping (address => uint) private ownershipCardCount;

  event Transfer(address from, address to, uint256 cardId);

  event CardSold(uint256 cardId, uint256 price, address prevOwner, address newOwner);

  event userSell(uint256 cardId, uint256 price, address owner);

  event CancelCardSell(uint256 cardId, address owner);

  uint constant private DEFAULT_START_PRICE = 0.01 ether;
  uint constant private FIRST_PRICE_LIMIT =  0.5 ether;
  uint constant private SECOND_PRICE_LIMIT =  2 ether;
  uint constant private THIRD_PRICE_LIMIT =  5 ether;

  uint constant private FIRST_COMMISSION_LEVEL = 6;
  uint constant private SECOND_COMMISSION_LEVEL = 5;
  uint constant private THIRD_COMMISSION_LEVEL = 4;
  uint constant private FOURTH_COMMISSION_LEVEL = 3;

  address private owner;
  mapping (address => bool) private admins;

  function CryptoHearthStone () public {
    owner = msg.sender;
    admins[owner] = true;
  }
   /* Modifiers */
   modifier onlyOwner() {
     require(owner == msg.sender);
     _;
   }

   modifier onlyAdmins() {
     require(admins[msg.sender]);
     _;
   }

   function addAdmin (address _admin) onlyOwner() public {
     admins[_admin] = true;
   }

   function removeAdmin (address _admin) onlyOwner() public {
     delete admins[_admin];
   }

   function withdrawAll () onlyAdmins() public {
     msg.sender.transfer(this.balance);
   }

  function withdrawAmount (uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }

  function initCards (uint _attribut) onlyAdmins() public {
      for(uint i=0;i<10;i++)
      {
          createCard(_attribut,20800000000000000);
      }
  }

  function createCard (uint _attribute, uint256 _price) onlyAdmins() public {
    require(_price > 0);

    Card memory _card = Card({
      attribute: _attribute,
      price: _price,
      delegate: msg.sender,
      isSale: true
    });
    cards.push(_card);
  }

  function getCard(uint _id) public view returns (uint attribute, uint256 price,address delegate,bool isSale,bool isWoner) {
    require(_id < cards.length);
    require(_addressNotNull(msg.sender));
    Card memory _card=cards[_id];
    isWoner=false;
    if(_card.delegate==msg.sender) isWoner=true;
    return (_card.attribute,_card.price,_card.delegate,_card.isSale,isWoner);
  }

  function getMyCards(address _owner) public view returns (uint[] userCards) {
    require(_addressNotNull(_owner));
    uint cardCount = ownershipCardCount[_owner];
    userCards = new uint[](cardCount);
    if(_owner==owner)return userCards;
    uint totalTeams = cards.length;
    uint resultIndex = 0;
    if (cardCount > 0) {
      for (uint pos = 0; pos < totalTeams; pos++) {
        if (cardOwnerOf(pos) == _owner) {
          userCards[resultIndex] = pos;
          resultIndex++;
        }
      }
    }
  }

  function purchase(uint _cardId) public payable {
    address oldOwner = cardOwnerOf(_cardId);
    address newOwner = msg.sender;

    uint sellingPrice = cards[_cardId].price;
    require(newOwner != owner);

    require(oldOwner != newOwner);

    require(_addressNotNull(newOwner));

    require(cards[_cardId].isSale == true);

    require(msg.value >= sellingPrice);

    uint payment =  _calculatePaymentToOwner(sellingPrice);
    uint excessPayment = msg.value.sub(sellingPrice);

    _transfer(oldOwner, newOwner, _cardId);
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    newOwner.transfer(excessPayment);

    CardSold(_cardId, sellingPrice, oldOwner, newOwner);
  }

  function sell(uint _cardId, uint256 _price) public {
      require(_price > 0);
      address oldOwner = cardOwnerOf(_cardId);
      require(_addressNotNull(oldOwner));
      require(oldOwner == msg.sender);
      cards[_cardId].price=_price;
      cards[_cardId].isSale=true;
      userSell(_cardId, _price,oldOwner);
  }

  function CancelSell(uint _cardId) public {
      address oldOwner = cardOwnerOf(_cardId);
      require(_addressNotNull(oldOwner));
      require(oldOwner == msg.sender);
      cards[_cardId].isSale=false;
      CancelCardSell(_cardId,oldOwner);
  }

  function _calculatePaymentToOwner(uint _sellingPrice) private pure returns (uint payment) {
    if (_sellingPrice < FIRST_PRICE_LIMIT) {
      payment = uint256(_sellingPrice.mul(100-FIRST_COMMISSION_LEVEL).div(100));
    }
    else if (_sellingPrice < SECOND_PRICE_LIMIT) {
      payment = uint256(_sellingPrice.mul(100-SECOND_COMMISSION_LEVEL).div(100));
    }
    else if (_sellingPrice < THIRD_PRICE_LIMIT) {
      payment = uint256(_sellingPrice.mul(100-THIRD_COMMISSION_LEVEL).div(100));
    }
    else {
      payment = uint256(_sellingPrice.mul(100-FOURTH_COMMISSION_LEVEL).div(100));
    }
  }

  function cardOwnerOf(uint _cardId) public view returns (address cardOwner) {
    require(_cardId < cards.length);
    cardOwner = cards[_cardId].delegate;
  }

  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  function _transfer(address _from, address _to, uint _cardId) private {
    ownershipCardCount[_to]++;
    cards[_cardId].delegate=_to;
    cards[_cardId].isSale=false;
    if (_from != address(0)) {
      ownershipCardCount[_from]--;
    }

    Transfer(_from, _to, _cardId);
  }
}