pragma solidity ^0.4.13;

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

contract CryptoSanguoToken {
  using SafeMath for uint256;

  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  mapping (address => bool) private admins;
  IItemRegistry private itemRegistry;
  bool private erc721Enabled = false;

  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;
  uint256 private min_value = 0.01 ether;

  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private startingPriceOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => address) private approvedOfItem;

  function CryptoSanguoToken () public {
    owner = msg.sender;
    admins[owner] = true;
    issueCard(1, 7, 5);
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

  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }
  
  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function setItemRegistry (address _itemRegistry) onlyOwner() public {
    itemRegistry = IItemRegistry(_itemRegistry);
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
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
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

  /* Listing */
  function populateFromItemRegistry (uint256[] _itemIds) onlyOwner() public {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      if (priceOfItem[_itemIds[i]] > 0 || itemRegistry.priceOf(_itemIds[i]) == 0) {
        continue;
      }

      listItemFromRegistry(_itemIds[i]);
    }
  }

  function listItemFromRegistry (uint256 _itemId) onlyOwner() public {
    require(itemRegistry != address(0));
    require(itemRegistry.ownerOf(_itemId) != address(0));
    require(itemRegistry.priceOf(_itemId) > 0);

    uint256 price = itemRegistry.priceOf(_itemId);
    address itemOwner = itemRegistry.ownerOf(_itemId);
    listItem(_itemId, price, itemOwner);
  }

  function listMultipleItems (uint256[] _itemIds, uint256 _price, address _owner) onlyAdmins() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      listItem(_itemIds[i], _price, _owner);
    }
  }

  function listItem (uint256 _itemId, uint256 _price, address _owner) onlyAdmins() public {
    require(_price > 0);
    require(priceOfItem[_itemId] == 0);
    require(ownerOfItem[_itemId] == address(0));

    ownerOfItem[_itemId] = _owner;
    priceOfItem[_itemId] = _price * min_value;
    startingPriceOfItem[_itemId] = _price * min_value;
    listedItems.push(_itemId);
  }

  /* Buying */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(92);
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(93);
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(94);
    } else if (_price < increaseLimit4) {
      return _price.mul(117).div(94);
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
      return _price.mul(6).div(100); // 6%
    } else {
      return _price.mul(5).div(100); // 5%
    }
  }

  /*
     Buy a country directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All countries that
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

    Bought(_itemId, newOwner, price);
    Sold(_itemId, oldOwner, price);

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
    return "CryptoSanguo.io";
  }

  function symbol() public pure returns (string _symbol) {
    return "CSG";
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

  function approve(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender != _to);
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == msg.sender);

    if (_to == 0) {
      if (approvedOfItem[_itemId] != 0) {
        delete approvedOfItem[_itemId];
        Approval(msg.sender, 0, _itemId);
      }
    } else {
      approvedOfItem[_itemId] = _to;
      Approval(msg.sender, _to, _itemId);
    }
  }

  /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
  function transfer(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint256 _itemId) onlyERC721() public {
    require(approvedFor(_itemId) == msg.sender);
    _transfer(_from, _to, _itemId);
  }

  function _transfer(address _from, address _to, uint256 _itemId) internal {
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfItem[_itemId] = _to;
    approvedOfItem[_itemId] = 0;

    Transfer(_from, _to, _itemId);
  }

  /* Read */
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  function startingPriceOf (uint256 _itemId) public view returns (uint256 _startingPrice) {
    return startingPriceOfItem[_itemId];
  }

  function priceOf (uint256 _itemId) public view returns (uint256 _price) {
    return priceOfItem[_itemId];
  }

  function nextPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_itemId));
  }

  function allOf (uint256 _itemId) external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice) {
    return (ownerOf(_itemId), startingPriceOf(_itemId), priceOf(_itemId), nextPriceOf(_itemId));
  }

  function itemsForSaleLimit (uint256 _from, uint256 _take) public view returns (uint256[] _items) {
    uint256[] memory items = new uint256[](_take);

    for (uint256 i = 0; i < _take; i++) {
      items[i] = listedItems[_from + i];
    }

    return items;
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
  
  function changePrice(uint256 _itemId, uint256 _price) public onlyAdmins() {
    require(_price > 0);
    require(admins[ownerOfItem[_itemId]]);
    priceOfItem[_itemId] = _price * min_value;
  }
  
  function issueCard(uint256 l, uint256 r, uint256 price) onlyAdmins() public {
    for (uint256 i = l; i <= r; i++) {
      ownerOfItem[i] = msg.sender;
      priceOfItem[i] = price * min_value;
      listedItems.push(i);
    }      
  }  
}

interface IItemRegistry {
  function itemsForSaleLimit (uint256 _from, uint256 _take) public view returns (uint256[] _items);
  function ownerOf (uint256 _itemId) public view returns (address _owner);
  function priceOf (uint256 _itemId) public view returns (uint256 _price);
}