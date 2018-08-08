pragma solidity ^0.4.24;

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

contract CryptoBeauty {
  using SafeMath for uint256;

  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  bool private erc721Enabled = false;

  uint256 private increaseLimit1 = 0.2 ether;
  uint256 private increaseLimit2 = 5 ether;
  uint256 private increaseLimit3 = 30 ether;
  uint256 private increaseLimit4 = 90 ether;

  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => address) private approvedOfItem;
  mapping (address => string) private ownerNameOfItem;

  constructor() public {
    owner = msg.sender;
  }

  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }

  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
  function enableERC721 () onlyOwner() public {
    erc721Enabled = true;
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll () onlyOwner() public {
    owner.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

  function getCurrentBalance() public view returns (uint256 balance) {
      return address(this).balance;
  }

  function listItem (uint256 _itemId, uint256 _price, address _owner) onlyOwner() public {
    require(_price > 0);
    require(priceOfItem[_itemId] == 0);
    require(ownerOfItem[_itemId] == address(0));

    ownerOfItem[_itemId] = _owner;
    priceOfItem[_itemId] = _price;
    listedItems.push(_itemId);
  }

  function setOwnerName (address _owner, string _name) public {
    require(keccak256(abi.encodePacked(ownerNameOfItem[_owner])) != keccak256(abi.encodePacked(_name)));
    ownerNameOfItem[_owner] = _name;
  }

  function getOwnerName (address _owner) public view returns (string _name) {
    return ownerNameOfItem[_owner];
  }

  /* Buying */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(98);
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(97);
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(96);
    } else if (_price < increaseLimit4) {
      return _price.mul(117).div(95);
    } else {
      return _price.mul(115).div(95);
    }
  }

  function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < increaseLimit1) {
      return _price.mul(8).div(100); // 8%
    } else if (_price < increaseLimit2) {
      return _price.mul(7).div(100); // 7%
    } else if (_price < increaseLimit3) {
      return _price.mul(6).div(100); // 6%
    } else if (_price < increaseLimit4) {
      return _price.mul(5).div(100); // 5%
    } else {
      return _price.mul(5).div(100); // 5%
    }
  }

  /*
     Buy a country directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All militaries that
     have been listed can be bought by this method. User funds are sent
     directly to the previous owner and are never stored in the contract.
  */
  function buy (uint256 _itemId) payable public {
    require(priceOf(_itemId) > 0);
    require(ownerOf(_itemId) != address(0));
    require(msg.value >= priceOf(_itemId));
    require(ownerOf(_itemId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));

    address oldOwner = ownerOf(_itemId);
    address newOwner = msg.sender;
    uint256 price = priceOf(_itemId);
    uint256 excess = msg.value.sub(price);

    _transfer(oldOwner, newOwner, _itemId);
    priceOfItem[_itemId] = nextPriceOf(_itemId);

    emit Bought(_itemId, newOwner, price);
    emit Sold(_itemId, oldOwner, price);

    // Devevloper&#39;s cut which is left in contract and accesed by
    // `withdrawAll` and `withdrawAmountTo` methods.
    uint256 devCut = calculateDevCut(price);

    // Transfer payment to old owner minus the developer&#39;s cut.
    oldOwner.transfer(price.sub(devCut));

    if (excess > 0) {
      newOwner.transfer(excess);
    }
  }

  /* ERC721 */
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

  function name() public pure returns (string _name) {
    return "CryptoBeauty";
  }

  function symbol() public pure returns (string _symbol) {
    return "CRBT";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return listedItems.length;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;

    for (uint256 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf (uint256 _itemId) public view returns (address _owner) {
    return ownerOfItem[_itemId];
  }

  function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
    uint256[] memory items = new uint256[](balanceOf(_owner));

    uint256 itemCounter = 0;
    for (uint256 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
        items[itemCounter] = listedItems[i];
        itemCounter += 1;
      }
    }

    return items;
  }

  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    return priceOf(_itemId) > 0;
  }

  function approvedFor(uint256 _itemId) public view returns (address _approved) {
    return approvedOfItem[_itemId];
  }

  /* Transferring a beauty to another owner will entitle the new owner the profits from `buy` */
  function transfer(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function _transfer(address _from, address _to, uint256 _itemId) internal {
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfItem[_itemId] = _to;
    approvedOfItem[_itemId] = 0;

    emit Transfer(_from, _to, _itemId);
  }

  /* Read */
  function priceOf (uint256 _itemId) public view returns (uint256 _price) {
    return priceOfItem[_itemId];
  }

  function nextPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_itemId));
  }

  function allOf (uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice) {
    return (ownerOf(_itemId),priceOf(_itemId), nextPriceOf(_itemId));
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
}