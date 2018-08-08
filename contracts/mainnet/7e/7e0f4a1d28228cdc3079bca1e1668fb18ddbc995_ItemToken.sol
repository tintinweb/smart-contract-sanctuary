pragma solidity ^0.4.21;

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

contract ItemToken {
  using SafeMath for uint256; // Loading the SafeMath library

  // Events of the contract
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);


  address private owner; // owner of the contract
  address private charityAddress; // address of the charity
  mapping (address => bool) private admins; // admins of the contract
  IItemRegistry private itemRegistry; // Item registry
  bool private erc721Enabled = false;

  // limits for devcut
  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;

  uint256[] private listedItems; // array of items
  mapping (uint256 => address) private ownerOfItem; // owner of the item
  mapping (uint256 => uint256) private startingPriceOfItem; // starting price of the item
  mapping (uint256 => uint256) private previousPriceOfItem; // previous price of the item
  mapping (uint256 => uint256) private priceOfItem; // actual price of the item
  mapping (uint256 => uint256) private charityCutOfItem; // charity cut of the item
  mapping (uint256 => address) private approvedOfItem; // item is approved for this address

  // constructor
  constructor() public {
    owner = msg.sender;
    admins[owner] = true;
  }

  // modifiers
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

  // contract owner
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  // Set charity address
  function setCharity (address _charityAddress) onlyOwner() public {
    charityAddress = _charityAddress;
  }

  // Set item registry
  function setItemRegistry (address _itemRegistry) onlyOwner() public {
    itemRegistry = IItemRegistry(_itemRegistry);
  }

  // Add admin
  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  // Remove admin
  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }

  // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
  function enableERC721 () onlyOwner() public {
    erc721Enabled = true;
  }

  // Withdraw
  function withdrawAll () onlyOwner() public {
    owner.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

  // Listing
  function populateFromItemRegistry (uint256[] _itemIds) onlyOwner() public {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      if (charityCutOfItem[_itemIds[i]] > 0 || priceOfItem[_itemIds[i]] > 0 || itemRegistry.priceOf(_itemIds[i]) == 0) {
        continue;
      }

      listItemFromRegistry(_itemIds[i]);
    }
  }

  function listItemFromRegistry (uint256 _itemId) onlyOwner() public {
    require(itemRegistry != address(0));
    require(itemRegistry.ownerOf(_itemId) != address(0));
    require(itemRegistry.priceOf(_itemId) > 0);
    require(itemRegistry.charityCutOf(_itemId) > 0);

    uint256 price = itemRegistry.priceOf(_itemId);
    uint256 charityCut = itemRegistry.charityCutOf(_itemId);
    address itemOwner = itemRegistry.ownerOf(_itemId);
    listItem(_itemId, price, itemOwner, charityCut);
  }

  function listMultipleItems (uint256[] _itemIds, uint256 _price, address _owner, uint256 _charityCut) onlyAdmins() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      listItem(_itemIds[i], _price, _owner, _charityCut);
    }
  }

  function listItem (uint256 _itemId, uint256 _price, address _owner, uint256 _charityCut) onlyAdmins() public {
    require(_price > 0);
    require(_charityCut >= 10);
    require(_charityCut <= 100);
    require(priceOfItem[_itemId] == 0);
    require(ownerOfItem[_itemId] == address(0));
    require(charityCutOfItem[_itemId] == 0);

    ownerOfItem[_itemId] = _owner;
    priceOfItem[_itemId] = _price;
    startingPriceOfItem[_itemId] = _price;
    charityCutOfItem[_itemId] = _charityCut;
    previousPriceOfItem[_itemId] = 0;
    listedItems.push(_itemId);
  }

  // Buy
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(95);
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(96);
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(97);
    } else if (_price < increaseLimit4) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

  // Dev cut
  function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < increaseLimit1) {
      return _price.mul(5).div(100); // 5%
    } else if (_price < increaseLimit2) {
      return _price.mul(4).div(100); // 4%
    } else if (_price < increaseLimit3) {
      return _price.mul(3).div(100); // 3%
    } else if (_price < increaseLimit4) {
      return _price.mul(3).div(100); // 3%
    } else {
      return _price.mul(2).div(100); // 2%
    }
  }

  // Buy function
  function buy (uint256 _itemId, uint256 _charityCutNew) payable public {
    require(priceOf(_itemId) > 0); // price of the token has to be greater than zero
    require(_charityCutNew >= 10); // minimum charity cut is 10%
    require(_charityCutNew <= 100); // maximum charity cut is 100%
    require(charityCutOf(_itemId) >= 10); // minimum charity cut is 10%
    require(charityCutOf(_itemId) <= 100); // maximum charity cut is 100%
    require(ownerOf(_itemId) != address(0)); // owner is not 0x0
    require(msg.value >= priceOf(_itemId)); // msg.value has to be greater than the price of the token
    require(ownerOf(_itemId) != msg.sender); // the owner cannot buy her own token
    require(!isContract(msg.sender)); // message sender is not a contract
    require(msg.sender != address(0)); // message sender is not 0x0

    address oldOwner = ownerOf(_itemId); // old owner of the token
    address newOwner = msg.sender; // new owner of the token
    uint256 price = priceOf(_itemId); // price of the token
    uint256 previousPrice = previousPriceOf(_itemId); // previous price of the token (oldOwner bought it for this price)
    uint256 charityCut = charityCutOf(_itemId); // actual charity cut of the token (oldOwner set this value)
    uint256 excess = msg.value.sub(price); // excess
    
    charityCutOfItem[_itemId] = _charityCutNew; // update the charity cut array
    previousPriceOfItem[_itemId] = priceOf(_itemId); // update the previous price array
    priceOfItem[_itemId] = nextPriceOf(_itemId); // update price of item

    _transfer(oldOwner, newOwner, _itemId); // transfer token from oldOwner to newOwner

    emit Bought(_itemId, newOwner, price); // bought event
    emit Sold(_itemId, oldOwner, price); // sold event

    // Devevloper&#39;s cut which is left in contract and accesed by
    // `withdrawAll` and `withdrawAmountTo` methods.
    uint256 devCut = calculateDevCut(price); // calculate dev cut
    // Charity contribution
    uint256 charityAmount = ((price.sub(devCut)).sub(previousPrice)).mul(charityCut).div(100); // calculate the charity cut
    
    charityAddress.transfer(charityAmount); // transfer payment to the address of the charity
    oldOwner.transfer((price.sub(devCut)).sub(charityAmount)); // transfer payment to old owner minus the dev cut and the charity cut

    
    if (excess > 0) {
      newOwner.transfer(excess); // transfer the excess
    }
  }

  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

  function name() public pure returns (string _name) {
    return "Tokenimals";
  }

  function symbol() public pure returns (string _symbol) {
    return "TKS";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return listedItems.length;
  }

  // balance of an address
  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;

    for (uint256 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  // owner of token
  function ownerOf (uint256 _itemId) public view returns (address _owner) {
    return ownerOfItem[_itemId];
  }

  // tokens of an address
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

  // token exists
  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    return priceOf(_itemId) > 0;
  }

  // approved for
  function approvedFor(uint256 _itemId) public view returns (address _approved) {
    return approvedOfItem[_itemId];
  }

  // approve
  function approve(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender != _to);
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == msg.sender);

    if (_to == 0) {
      if (approvedOfItem[_itemId] != 0) {
        delete approvedOfItem[_itemId];
        emit Approval(msg.sender, 0, _itemId);
      }
    } else {
      approvedOfItem[_itemId] = _to;
      emit Approval(msg.sender, _to, _itemId);
    }
  }

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

    emit Transfer(_from, _to, _itemId);
  }

  // read
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  function startingPriceOf (uint256 _itemId) public view returns (uint256 _startingPrice) {
    return startingPriceOfItem[_itemId];
  }

  function priceOf (uint256 _itemId) public view returns (uint256 _price) {
    return priceOfItem[_itemId];
  }

  function previousPriceOf (uint256 _itemId) public view returns (uint256 _previousPrice) {
    return previousPriceOfItem[_itemId];
  }

  function charityCutOf (uint256 _itemId) public view returns (uint256 _charityCut) {
    return charityCutOfItem[_itemId];
  }

  function nextPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_itemId));
  }

  function readCharityAddress () public view returns (address _charityAddress) {
    return charityAddress;
  }

  function allOf (uint256 _itemId) external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice, uint256 _charityCut) {
    return (ownerOf(_itemId), startingPriceOf(_itemId), priceOf(_itemId), nextPriceOf(_itemId), charityCutOf(_itemId));
  }

  // selfdestruct
  function ownerkill() public onlyOwner {
        selfdestruct(owner);
  }

  function itemsForSaleLimit (uint256 _from, uint256 _take) public view returns (uint256[] _items) {
    uint256[] memory items = new uint256[](_take);

    for (uint256 i = 0; i < _take; i++) {
      items[i] = listedItems[_from + i];
    }

    return items;
  }

  // util
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }

}

interface IItemRegistry {
  function itemsForSaleLimit (uint256 _from, uint256 _take) external view returns (uint256[] _items);
  function ownerOf (uint256 _itemId) external view returns (address _owner);
  function priceOf (uint256 _itemId) external view returns (uint256 _price);
  function charityCutOf (uint256 _itemId) external view returns (uint256 _charityCut);
}