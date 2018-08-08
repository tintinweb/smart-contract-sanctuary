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

contract CellTokens {
  using SafeMath for uint256;

  uint8 private constant MAX_COLS = 64;
  uint8 private constant MAX_ROWS = 160;
  uint8 private Reserved_upRow = 8;
  uint8 private Reserved_downRow = 39;
  uint8 private max_merge_size = 2;
  
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  mapping (address => bool) private admins;
  bool private erc721Enabled = false;
  bool private mergeEnabled = false;
  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;
  uint256 private startingPrice = 0.001 ether;
  
  uint256[] private listedItems;
  
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (address => string) private usernameOfAddress;
  
  
  function CellTokens () public {
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
  modifier onlyMergeEnable(){
      require(mergeEnabled);
    _;
  }

  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
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
  function enableMerge (bool status) onlyAdmins() public {
    mergeEnabled = status;
  }
  function setReserved(uint8 _up,uint8 _down) onlyAdmins() public{
      Reserved_upRow = _up;
      Reserved_downRow = _down;
  }
  function setMaxMerge(uint8 num)onlyAdmins() external{
      max_merge_size = num;
  }  
  /* Withdraw */
  /*
  */
  function withdrawAll () onlyOwner() public {
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }
   /* Buying */
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
  
  function requestMerge(uint256[] ids)onlyMergeEnable() external {
      require(ids.length == 4);
      require(ids[0]%(10**8)/(10**4)<max_merge_size);
      require(ids[0]%(10**8)/(10**4)<max_merge_size);
      require(ids[0]%(10**8)/(10**4)<max_merge_size);
      require(ids[0]%(10**8)/(10**4)<max_merge_size);
      require(ownerOfItem[ids[0]] == msg.sender);
      require(ownerOfItem[ids[1]] == msg.sender);
      require(ownerOfItem[ids[2]] == msg.sender);
      require(ownerOfItem[ids[3]] == msg.sender);
      require(ids[0]+ (10**12) == ids[1]);
      require(ids[0]+ (10**8) == ids[2]);
      require(ids[0]+ (10**8) + (10**12) == ids[3]);
      
      uint256 newPrice = priceOfItem[ids[0]]+priceOfItem[ids[1]]+priceOfItem[ids[2]]+priceOfItem[ids[3]];
      uint256 newId = ids[0] + ids[0]%(10**8);
      listedItems.push(newId);
      priceOfItem[newId] = newPrice;
      ownerOfItem[newId] = msg.sender;
      ownerOfItem[ids[0]] = address(0);
      ownerOfItem[ids[1]] = address(0);
      ownerOfItem[ids[2]] = address(0);
      ownerOfItem[ids[3]] = address(0);
  } 
  
  function checkIsOnSale(uint256 _ypos)public view returns(bool isOnSale){
      if(_ypos<Reserved_upRow||_ypos>Reserved_downRow){
          return false;
      }else{
          return true;
      }
  }
  function generateId(uint256 _xpos,uint256 _ypos,uint256 _size)internal pure returns(uint256 _id){
      uint256 temp= _xpos *  (10**12) + _ypos * (10**8) + _size*(10**4);
      return temp;
  }
  function parseId(uint256 _id)internal pure returns(uint256 _x,uint256 _y,uint256 _size){
      uint256 xpos = _id / (10**12);
      uint256 ypos = (_id-xpos*(10**12)) / (10**8);
      uint256 size = _id % (10**5) / (10**4);
      return (xpos,ypos,size);
  }

  function setUserName(string _name)payable public{
      require(msg.value >= 0.01 ether);
      usernameOfAddress[msg.sender] = _name;
      uint256 excess = msg.value - 0.01 ether;
      if (excess > 0) {
          msg.sender.transfer(excess);
      }
  }
  function getUserName()public view returns(string name){
      return usernameOfAddress[msg.sender];
  }
  function getUserNameOf(address _user)public view returns(string name){
      return usernameOfAddress[_user];
  }
    function buyOld (uint256 _index) payable public {
        require(_index!=0);
        require(msg.value >= priceOf(_index));
        require(ownerOf(_index) != msg.sender);
        require(ownerOf(_index) != address(0));

        uint256 price = priceOf(_index);
        address oldOwner = ownerOfItem[_index];
        priceOfItem[_index] = calculateNextPrice(price);

        uint256 excess = msg.value.sub(price);
        address newOwner = msg.sender;
    
    	ownerOfItem[_index] = newOwner;
        uint256 devCut = calculateDevCut(price);
        oldOwner.transfer(price.sub(devCut));
    
        if (excess > 0) {
          newOwner.transfer(excess);
        }
    }
    function buyNew (uint256 _xpos,uint256 _ypos,uint256 _size) payable public {
        require(checkIsOnSale(_ypos) == true);
        require(_size == 1);
        require(_xpos + _size <= MAX_COLS);
        uint256 _itemId = generateId(_xpos,_ypos,_size);
        require(priceOf(_itemId)==0);
        uint256 price =startingPrice;
        address oldOwner = owner;

        listedItems.push(_itemId);
        priceOfItem[_itemId] = calculateNextPrice(price);
        uint256 excess = msg.value.sub(price);
        address newOwner = msg.sender;
    
    	ownerOfItem[_itemId] = newOwner;
        uint256 devCut = calculateDevCut(price);
        oldOwner.transfer(price.sub(devCut));
    
        if (excess > 0) {
          newOwner.transfer(excess);
        }
    }

    function MergeStatus() public view returns (bool _MergeOpen) {
        return mergeEnabled;
    }
  /* ERC721 */
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

  function name() public pure returns (string _name) {
    return "Crypto10K.io";
  }

  function symbol() public pure returns (string _symbol) {
    return "cells";
  }
  
  function totalSupply() public view returns (uint256 _totalSupply) {
      uint256 total = 0;
      for(uint8 i=0; i<listedItems.length; i++){
          if(ownerOf(listedItems[i])!=address(0)){
              total++;
          }
      }
    return total;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;
    for (uint8 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
          counter++;
      }
    }
    return counter;
  }
  
  function ownerOf (uint256 _itemId) public view returns (address _owner) {
    return ownerOfItem[_itemId];
  }
  
  function cellsOf (address _owner) public view returns (uint256[] _tokenIds) {
    uint256[] memory items = new uint256[](balanceOf(_owner));
    uint256 itemCounter = 0;
    for (uint8 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
        items[itemCounter] = listedItems[i];
        itemCounter += 1;
      }
    }
    return items;
  }
    function getAllCellIds () public view returns (uint256[] _tokenIds) {
        uint256[] memory items = new uint256[](totalSupply());
        uint256 itemCounter = 0;
        for (uint8 i = 0; i < listedItems.length; i++) {
            if (ownerOfItem[listedItems[i]] != address(0)) {
                items[itemCounter] = listedItems[i];
                itemCounter += 1;
            }
        }
        return items;
    }

    /* Read */
    function isAdmin (address _admin) public view returns (bool _isAdmin) {
        return admins[_admin];
    }
    
    function startingPriceOf () public view returns (uint256 _startingPrice) {
        return startingPrice;
    }
    
    function priceOf (uint256 _itemId) public view returns (uint256 _price) {
        return priceOfItem[_itemId];
    }
    
    function nextPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
        return calculateNextPrice(priceOf(_itemId));
    }

    function allOf (uint256 _itemId) external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice, uint256 _xpos, uint256 _ypos, uint256 _size) {
        uint256 xpos;
        uint256 ypos;
        uint256 size;
        (xpos,ypos,size) = parseId(_itemId);
        return (ownerOfItem[_itemId],startingPriceOf(),priceOf(_itemId),nextPriceOf(_itemId),xpos,ypos,size);
    }
    
    function getAllCellInfo()external view returns(uint256[] _tokenIds,uint256[] _prices, address[] _owners){
        uint256[] memory items = new uint256[](totalSupply());
        uint256[] memory prices = new uint256[](totalSupply());
        address[] memory owners = new address[](totalSupply());
        uint256 itemCounter = 0;
        for (uint8 i = 0; i < listedItems.length; i++) {
            if (ownerOf(listedItems[i]) !=address(0)) {
                items[itemCounter] = listedItems[i];
                prices[itemCounter] = priceOf(listedItems[i]);
                owners[itemCounter] = ownerOf(listedItems[i]);
                itemCounter += 1;
            }
        }
        return (items,prices,owners);
    }
    function getMaxMerge()external view returns(uint256 _maxMergeSize){
      return max_merge_size;
    }
    function showBalance () onlyAdmins() public view returns (uint256 _ProfitBalance) {
        return this.balance;
    }
}