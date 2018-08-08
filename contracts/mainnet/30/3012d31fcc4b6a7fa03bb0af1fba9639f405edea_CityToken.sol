pragma solidity ^0.4.24;
/* CryptoCountries.io Cities */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Managed {
  event DeclareEmergency (string _reason);
  event ResolveEmergency ();

  address private addressOfOwner;
  address[] private addressesOfAdmins;
  bool private isInEmergency;

  constructor () public {
    addressOfOwner = msg.sender;
    isInEmergency = false;
  }

  /* Modifiers */
  modifier onlyOwner () {
    require(addressOfOwner == msg.sender);
    _;
  }

  modifier onlyAdmins () {
    require(isAdmin(msg.sender));
    _;
  }

  modifier notEmergency () {
    require(!isInEmergency);
    _;
  }

  /* Admin */
  function transferOwnership (address _owner) onlyOwner() public {
    clearAdmins();
    addressOfOwner = _owner;
  }

  function addAdmin (address _admin) onlyOwner() public {
    addressesOfAdmins.push(_admin);
  }

  function removeAdmin (address _admin) onlyOwner() public {
    require(isAdmin(_admin));

    uint256 length = addressesOfAdmins.length;
    address swap = addressesOfAdmins[length - 1];
    uint256 index = 0;

    for (uint256 i = 0; i < length; i++) {
      if (addressesOfAdmins[i] == _admin) {
        index = i;
      }
    }

    addressesOfAdmins[index] = swap;
    delete addressesOfAdmins[length - 1];
    addressesOfAdmins.length--;
  }

  function clearAdmins () onlyOwner() public {
    require(addressesOfAdmins.length > 0);
    addressesOfAdmins.length = 0;
  }

  /* Emergency protocol */
  function declareEmergency (string _reason) onlyOwner() public {
    require(!isInEmergency);
    isInEmergency = true;
    emit DeclareEmergency(_reason);
  }

  function resolveEmergency () onlyOwner() public {
    require(isInEmergency);
    isInEmergency = false;
    emit ResolveEmergency();
  }

  /* Read */
  function owner () public view returns (address _owner) {
    return addressOfOwner;
  }

  function admins () public view returns (address[] _admins) {
    return addressesOfAdmins;
  }

  function emergency () public view returns (bool _emergency) {
    return isInEmergency;
  }

  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    if (_admin == addressOfOwner) {
      return true;
    }

    for (uint256 i = 0; i < addressesOfAdmins.length; i++) {
      if (addressesOfAdmins[i] == _admin) {
        return true;
      }
    }

    return false;
  }
}

interface ICountryToken {
  function ownerOf (uint256) external view returns (address);
  function priceOf (uint256) external view returns (uint256);
}

contract CityToken is Managed {
  using SafeMath for uint256;

  event List (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  ICountryToken private countryToken;
  bool private erc721Enabled = false;

  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => uint256) private countryOfItem;
  mapping (uint256 => uint256[]) private itemsOfCountry;
  mapping (uint256 => address) private approvedOfItem;

  /* Constructor */
  constructor () public {
  }

  /* Modifiers */
  modifier hasCountryToken () {
    require(countryToken != address(0));
    _;
  }

  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }

  /* Initilization */
  function setCountryToken (address _countryToken) onlyOwner() public {
    countryToken = ICountryToken(_countryToken);
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll () onlyOwner() public {
    owner().transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner().transfer(_amount);
  }

  // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
  function enableERC721 () onlyOwner() public {
    erc721Enabled = true;
  }

  /* Listing */
  function listMultipleItems (uint256[] _itemIds, uint256[] _countryIds, uint256 _price, address _owner) onlyAdmins() notEmergency() hasCountryToken() external {
    require(_itemIds.length == _countryIds.length);

    for (uint256 i = 0; i < _itemIds.length; i++) {
      listItem(_itemIds[i], _countryIds[i], _price, _owner);
    }
  }

  function listItem (uint256 _itemId, uint256 _countryId, uint256 _price, address _owner) onlyAdmins() notEmergency() hasCountryToken() public {
    require(countryToken != address(0));
    require(_price > 0);
    require(priceOf(_itemId) == 0);
    require(ownerOf(_itemId) == address(0));
    require(countryToken.ownerOf(_countryId) != address(0));
    require(countryToken.priceOf(_countryId) > 0);

    ownerOfItem[_itemId] = _owner;
    priceOfItem[_itemId] = _price;
    countryOfItem[_itemId] = _countryId;

    listedItems.push(_itemId);
    itemsOfCountry[_countryId].push(_itemId);

    emit List(_itemId, _owner, _price);
  }

  /* Market */
  function calculateNextPrice (uint256 _price) public pure returns (uint256 _nextPrice) {
    return _price.mul(120).div(94);
  }

  function calculateDevCut (uint256 _price) public pure returns (uint256 _devCut) {
    return _price.mul(3).div(100); // 3%
  }

  function calculateCountryCut (uint256 _price) public pure returns (uint256 _countryCut) {
    return _price.mul(3).div(100); // 3%
  }

  function buy (uint256 _itemId) notEmergency() hasCountryToken() payable public {
    require(priceOf(_itemId) > 0);
    require(ownerOf(_itemId) != address(0));
    require(msg.value >= priceOf(_itemId));
    require(ownerOf(_itemId) != msg.sender);
    require(msg.sender != address(0));
    require(countryToken.ownerOf(countryOf(_itemId)) != address(0));

    address oldOwner = ownerOf(_itemId);
    address newOwner = msg.sender;
    address countryOwner = countryToken.ownerOf(countryOf(_itemId));
    uint256 price = priceOf(_itemId);
    uint256 excess = msg.value.sub(price);

    _transfer(oldOwner, newOwner, _itemId);
    priceOfItem[_itemId] = nextPriceOf(_itemId);

    emit Bought(_itemId, newOwner, price);
    emit Sold(_itemId, oldOwner, price);

    uint256 devCut = calculateDevCut(price);
    uint256 countryCut = calculateCountryCut(price);
    uint256 totalCut = devCut + countryCut;

    countryOwner.transfer(countryCut);
    oldOwner.transfer(price.sub(totalCut));

    if (excess > 0) {
      newOwner.transfer(excess);
    }
  }

  /* Read */
  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    return priceOf(_itemId) > 0;
  }

  function countrySupply (uint256 _countryId) public view returns (uint256 _countrySupply) {
    return itemsOfCountry[_countryId].length;
  }

  function priceOf (uint256 _itemId) public view returns (uint256 _price) {
    return priceOfItem[_itemId];
  }

  function nextPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_itemId));
  }

  function countryOf (uint256 _itemId) public view returns (uint256 _countryId) {
    return countryOfItem[_itemId];
  }

  function allOf (uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice, uint256 _countryId) {
    return (ownerOf(_itemId), priceOf(_itemId), nextPriceOf(_itemId), countryOf(_itemId));
  }

  function allItems (uint256 _from, uint256 _take) public view returns (uint256[] _items) {
    if (totalSupply() == 0) {
      return new uint256[](0);
    }

    uint256[] memory items = new uint256[](_take);

    for (uint256 i = 0; i < _take; i++) {
      items[i] = listedItems[_from + i];
    }

    return items;
  }

  function countryItems (uint256 _countryId, uint256 _from, uint256 _take) public view returns (uint256[] _items) {
    if (countrySupply(_countryId) == 0) {
      return new uint256[](0);
    }

    uint256[] memory items = new uint256[](_take);

    for (uint256 i = 0; i < _take; i++) {
      items[i] = itemsOfCountry[_countryId][_from + i];
    }

    return items;
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

  /* ERC721 */
  function implementsERC721 () public view returns (bool _implements) {
    return erc721Enabled;
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

  function transfer(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint256 _itemId) onlyERC721() public {
    require(getApproved(_itemId) == msg.sender);
    _transfer(_from, _to, _itemId);
  }

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

  function getApproved (uint256 _itemId) public view returns (address _approved) {
    require(tokenExists(_itemId));
    return approvedOfItem[_itemId];
  }

  function name () public pure returns (string _name) {
    return "CryptoCountries.io Cities";
  }

  function symbol () public pure returns (string _symbol) {
    return "CC2";
  }

  function tokenURI (uint256 _itemId) public pure returns (string) {
    return _concat("https://cryptocountries.io/api/metadata/city/", _uintToString(_itemId));
  }

  function totalSupply () public view returns (uint256 _totalSupply) {
    return listedItems.length;
  }

  function tokenByIndex (uint256 _index) public view returns (uint256 _itemId) {
    require(_index < totalSupply());
    return listedItems[_index];
  }

  function tokenOfOwnerByIndex (address _owner, uint256 _index) public view returns (uint256 _itemId) {
    require(_index < balanceOf(_owner));

    uint count = 0;
    for (uint i = 0; i < listedItems.length; i++) {
      uint itemId = listedItems[i];
      if (ownerOf(itemId) == _owner) {
        if (count == _index) { return itemId; }
        count += 1;
      }
    }

    assert(false);
  }

  /* Internal */
  function _transfer(address _from, address _to, uint256 _itemId) internal {
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfItem[_itemId] = _to;
    approvedOfItem[_itemId] = 0;

    emit Transfer(_from, _to, _itemId);
  }

  function _uintToString (uint i) internal pure returns (string) {
		if (i == 0) return "0";

		uint j = i;
		uint len;
		while (j != 0){
			len++;
			j /= 10;
		}

		bytes memory bstr = new bytes(len);

		uint k = len - 1;
		while (i != 0) {
			bstr[k--] = byte(48 + i % 10);
			i /= 10;
		}

		return string(bstr);
  }

  function _concat(string _a, string _b) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory bab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }
}