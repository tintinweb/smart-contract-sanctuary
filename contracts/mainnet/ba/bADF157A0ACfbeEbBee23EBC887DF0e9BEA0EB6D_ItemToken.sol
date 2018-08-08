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

contract ItemToken {
  using SafeMath for uint256;

  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  mapping (address => bool) private admins;
  bool private erc721Enabled = false;

  uint256 private L = 500;
  uint256 private itemIdCounter = 0;
  uint256 private pointsDecayFactor = 1209600000; // half-time: week

  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => string) private nameOfItem;
  mapping (uint256 => string) private descOfItem;
  mapping (uint256 => string) private URLOfItem;
  mapping (uint256 => uint256) private pointOfItem;
  mapping (uint256 => uint256) private timeOfItem;
  mapping (uint256 => address) private approvedOfItem;

  mapping (uint256 => uint256[]) private pointArrayOfArray;
  mapping (uint256 => uint256[]) private timeArrayOfArray;

  function ItemToken () public {
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

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }
  
  function adjustL (uint256 _L) onlyOwner() public {
    L = _L;
  }
  
  function adjustPointsDecayFactor (uint256 _pointsDecayFactor) onlyOwner() public {
    pointsDecayFactor = _pointsDecayFactor;
  }

  // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
  function enableERC721 () onlyOwner() public {
    erc721Enabled = true;
  }

  /* Withdraw */
  function withdrawAll () onlyOwner() public {
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

  /* Listing */
  function Time_call() returns (uint256 _now){
    return now;
  }

  function listDapp (string _itemName, string _itemDesc, string _itemURL) public {
    require(bytes(_itemName).length > 2);
    require(bytes(_itemDesc).length > 2);
    require(bytes(_itemURL).length > 2);
    
    uint256 _itemId = itemIdCounter;
    itemIdCounter = itemIdCounter + 1;

    ownerOfItem[_itemId] = msg.sender;
    nameOfItem[_itemId] = _itemName;
    descOfItem[_itemId] = _itemDesc;
    URLOfItem[_itemId] = _itemURL;
    pointOfItem[_itemId] = 10; //This is 10 free token for whom sign-up
    timeOfItem[_itemId] = Time_call();
    listedItems.push(_itemId);
    
    pointArrayOfArray[_itemId].push(10);
    timeArrayOfArray[_itemId].push(Time_call());
  }

  /* Buying */
  function buyPoints (uint256 _itemId) payable public {
    require(msg.value > 0);
    require(ownerOf(_itemId) == msg.sender);
    require(!isContract(msg.sender));
    
    uint256 point = msg.value.mul(L).div(1000000000000000000);
    
    pointOfItem[_itemId] = point;
    timeOfItem[_itemId] = Time_call();
    
    owner.transfer(msg.value);
    
    pointArrayOfArray[_itemId].push(point);
    timeArrayOfArray[_itemId].push(Time_call());
  }

  /* ERC721 */
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

  function name() public pure returns (string _name) {
    return "DappTalk.org";
  }

  function symbol() public pure returns (string _symbol) {
    return "DTC";
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
    return bytes(nameOf(_itemId)).length > 2;
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

  function nameOf (uint256 _itemId) public view returns (string _itemName) {
    return nameOfItem[_itemId];
  }
  
  function descOf (uint256 _itemId) public view returns (string _itemDesc) {
    return descOfItem[_itemId];
  }
  
  function URLOf (uint256 _itemId) public view returns (string _itemURL) {
    return URLOfItem[_itemId];
  }
  
  function pointOf (uint256 _itemId) public view returns (uint256 _itemPoint) {
    return pointOfItem[_itemId];
  }
  
  function pointArrayOf (uint256 _itemId) public view returns (uint256[] _pointArray) {
    return pointArrayOfArray[_itemId];
  }
  
  function timeArrayOf (uint256 _itemId) public view returns (uint256[] _timeArray) {
    return timeArrayOfArray[_itemId];
  }

  function initTimeOf (uint256 _itemId) public view returns (uint256 _initTime) {
    return timeArrayOfArray[_itemId][0];
  }

  function timeOf (uint256 _itemId) public view returns (uint256 _itemTime) {
    return timeOfItem[_itemId];
  }

  function getPointOf (uint256 _itemId) public view returns (uint256 _getPoint) {
    uint256 t = Time_call();
    _getPoint = 0;
    uint256 temp = 0;

    for (uint256 i = 0; i < pointArrayOfArray[_itemId].length; i++) {
        if (timeArrayOfArray[_itemId][i] + pointsDecayFactor > t) {
            temp = timeArrayOfArray[_itemId][i];
            temp = temp - t;
            temp = temp + pointsDecayFactor;
            temp = temp.mul(pointArrayOfArray[_itemId][i]);
            temp = temp.div(pointsDecayFactor);
            _getPoint = temp.add(_getPoint);
        }
    }
    
    return _getPoint;
  }

  function allOf (uint256 _itemId) public view returns (address _owner, string _itemName, string _itemDesc, string _itemURL, uint256[] _pointArray, uint256[] _timeArray, uint256 _curPoint) {
    return (ownerOf(_itemId), nameOf(_itemId), descOf(_itemId), URLOf(_itemId), pointArrayOf(_itemId), timeArrayOf(_itemId), getPointOf(_itemId));
  }
  
  function getAllDapps () public view returns (address[] _owners, bytes32[] _itemNames, bytes32[] _itemDescs, bytes32[] _itemURL, uint256[] _points, uint256[] _initTime, uint256[] _lastTime) {
      _owners = new address[](itemIdCounter);
      _itemNames = new bytes32[](itemIdCounter);
      _itemDescs = new bytes32[](itemIdCounter);
      _itemURL = new bytes32[](itemIdCounter);
      _points = new uint256[](itemIdCounter);
      _initTime = new uint256[](itemIdCounter);
      _lastTime = new uint256[](itemIdCounter);
      for (uint256 i = 0; i < itemIdCounter; i++) {
          _owners[i] = ownerOf(i);
          _itemNames[i] = stringToBytes32(nameOf(i));
          _itemDescs[i] = stringToBytes32(descOf(i));
          _itemURL[i] = stringToBytes32(URLOf(i));
          _points[i] = getPointOf(i);
          _initTime[i] = initTimeOf(i);
          _lastTime[i] = timeOf(i);
      }
      return (_owners, _itemNames, _itemDescs, _itemURL, _points, _initTime, _lastTime);
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
  
  function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
}