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


contract ParallelWorld {
  using SafeMath for uint256;

  event TransactionOccured(uint256 indexed _itemId, uint256 _price, address indexed _oldowner, address indexed _newowner);
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  address public referraltokencontract;
  mapping (address => bool) private admins;
  IItemRegistry private itemRegistry;
  bool private erc721Enabled = false;

  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;

  uint256 public enddate = 1531673100; //World Cup Finals game end date/time

  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private startingPriceOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => address) private approvedOfItem;
  mapping (uint256 => bytes32) private nameofItem;

  mapping (address => bytes32) private ownerAlias;
  mapping (address => bytes32) private ownerEmail;
  mapping (address => bytes32) private ownerPhone;

  function ParallelWorld () public {
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

  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }

  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function getOwner() public view returns (address){
    return owner;
  }

  function setReferralTokenContract (address _referraltokencontract) onlyOwner() public {
    referraltokencontract = _referraltokencontract;
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


  //award prize to winner, and developer already took 10% from individual transactions
  function awardprize(uint256 _itemId) onlyOwner() public{
    uint256 winneramount;

    winneramount = this.balance;

    if (ownerOf(_itemId) != address(this))
    {
      //winner gets the prize amount minus developer cut
      ownerOf(_itemId).transfer(winneramount);
    }
    

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
    require(itemRegistry.nameOf(_itemId).length > 0 );

    uint256 price = itemRegistry.priceOf(_itemId);
    address itemOwner = itemRegistry.ownerOf(_itemId);
    bytes32 nameofItemlocal = itemRegistry.nameOf(_itemId);
    listItem(_itemId, price, itemOwner, nameofItemlocal);
  }

  function listMultipleItems (uint256[] _itemIds, uint256[] _price, address _owner, bytes32[] _nameofItem) onlyAdmins() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      listItem(_itemIds[i], _price[i], _owner, _nameofItem[i]);
    }
  }

  function listItem (uint256 _itemId, uint256 _price, address _owner, bytes32 _nameofItem) onlyAdmins() public {
    require(_price > 0);
    require(priceOfItem[_itemId] == 0);
    require(ownerOfItem[_itemId] == address(0));
    

    ownerOfItem[_itemId] = this; //set the contract as original owner of teams
    priceOfItem[_itemId] = _price;
    startingPriceOfItem[_itemId] = _price;
    nameofItem[_itemId] = _nameofItem;
    listedItems.push(_itemId);
  }

  function addItem(uint256 _itemId, uint256 _price) onlyAdmins() public returns (uint256 _pricereturn){
    priceOfItem[_itemId] = _price;
    return priceOfItem[_itemId];
  }

  /* Buying */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(210).div(100); //added 110%
    } else if (_price < increaseLimit2) {
      return _price.mul(140).div(100); //added 40%
    } else if (_price < increaseLimit3) {
      return _price.mul(128).div(100); //added 28%
    } else if (_price < increaseLimit4) {
      return _price.mul(120).div(100); //added 20%
    } else {
      return _price.mul(117).div(100); //added 17%
    }
  }

  function calculatePrizeCut (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < increaseLimit1) {
      return _price.mul(26).div(100); // 26%
    } else if (_price < increaseLimit2) {
      return _price.mul(14).div(100); // 14%
    } else if (_price < increaseLimit3) {
      return _price.mul(10).div(100); // 10%
    } else if (_price < increaseLimit4) {
      return _price.mul(8).div(100); // 8%
    } else {
      return _price.mul(7).div(100); // 7%
    }
  }

  function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
    return _price.mul(10).div(100); //10%
  }


  function buy (uint256 _itemId) payable public {
    require(priceOf(_itemId) > 0);
    require(ownerOf(_itemId) != address(0));
    require(msg.value >= nextPriceOf(_itemId));
    require(ownerOf(_itemId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    require(now < enddate); //team buying can only happen before end date

    address oldOwner = ownerOf(_itemId);
    address newOwner = msg.sender;
    uint256 price = priceOf(_itemId);
    
    _transfer(oldOwner, newOwner, _itemId);
    priceOfItem[_itemId] = nextPriceOf(_itemId);
    
    uint256 excess = msg.value.sub(priceOfItem[_itemId]);

    TransactionOccured(_itemId, priceOfItem[_itemId], oldOwner, newOwner);

    // Transfer payment to old owner minus the cut for the final prize.  Don&#39;t transfer funds though if old owner is this contract
    if (oldOwner != address(this))
    {
      uint256 pricedifference = priceOfItem[_itemId].sub(price);
      //send to old owner,the original amount they paid, plus 20% of the price difference between what they paid and new owner pays
      uint256 oldOwnercut = priceOfItem[_itemId].sub(pricedifference.mul(80).div(100));
      oldOwner.transfer(oldOwnercut);
      
      //send to developer, 10% of price diff
      owner.transfer(calculateDevCut(pricedifference));
    
    }
    else
    {
      //first transaction to purchase from contract, send 10% of tx to dev
      owner.transfer(calculateDevCut(msg.value));
    
    }

    if (excess > 0) {
      newOwner.transfer(excess);
    }
    
  }

  /* ERC721 */
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

  function name() public pure returns (string _name) {
    return "Parallel World Cup";
  }

  function symbol() public pure returns (string _symbol) {
    return "PWC";
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

  /* Transferring a team to another owner will entitle the new owner the profits from `buy` */
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

  function setownerInfo(address _ownerAddress, bytes32 _ownerAlias, bytes32 _ownerEmail, bytes32 _ownerPhone) public
  {
      ownerAlias[_ownerAddress] = _ownerAlias;
      ownerEmail[_ownerAddress] = _ownerEmail;
      ownerPhone[_ownerAddress] = _ownerPhone;
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

  function nameOf (uint256 _itemId) public view returns (bytes32 _name) {
    return nameofItem[_itemId];
  }

  function allOf (uint256 _itemId) external view returns (uint256 _itemIdreturn, address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice, bytes32 _name) {
    return (_itemId, ownerOf(_itemId), startingPriceOf(_itemId), priceOf(_itemId), nextPriceOf(_itemId), nameOf(_itemId));
  }

  function getenddate () public view returns (uint256 _enddate) {
    return enddate;
  }

  function getlistedItems() external view returns(uint256[] _listedItems){
    return(listedItems);
  }

  function itemsForSaleLimit (uint256 _from, uint256 _take) public view returns (uint256[] _items) {
    uint256[] memory items = new uint256[](_take);

    for (uint256 i = 0; i < _take; i++) {
      items[i] = listedItems[_from + i];
    }

    return items;
  }

  function getprizeamount() public view returns(uint256 _prizeamount)
  {
    return this.balance;
  }

  function getownerInfo (address _owner) public view returns (bytes32 _name, bytes32 _email, bytes32 _phone) {
    return (ownerAlias[_owner], ownerEmail[_owner], ownerPhone[_owner]);
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }

  
}

interface IItemRegistry {
  function itemsForSaleLimit (uint256 _from, uint256 _take) public view returns (uint256[] _items);
  function ownerOf (uint256 _itemId) public view returns (address _owner);
  function priceOf (uint256 _itemId) public view returns (uint256 _price);
  function nameOf (uint256 _itemId) public view returns (bytes32 _nameofItemlocal);
}