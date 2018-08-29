pragma solidity ^0.4.24;
/* Crypto SuperGirlfriend */

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
    uint256 c = a / b;    
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

  

contract CryptoSuperGirlfriend {
  using SafeMath for uint256;

  address private addressOfOwner;  
 
  event Add (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  
  
  uint256 private priceInit = 0.01 ether;
  uint256 private idStart = 10001;
  uint256 private idMax = 10191;

  struct OwnerInfo{      
        string ownerName;
        string ownerWords;  
        string ownerImg; 
        string ownerNation;     
  }

  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => uint256) private sellPriceOfItem;
  mapping (uint256 => OwnerInfo) private ownerInfoOfItem;
  mapping (uint256 => string) private nameOfItem; 
  mapping (uint256 => address) private approvedOfItem;

  
  /* Modifiers */
  modifier onlyOwner () {
    require(addressOfOwner == msg.sender);
    _;
  }   

  /* Initilization */
  constructor () public {
    addressOfOwner = msg.sender;   
  }

  /* Admin */
  function transferOwnership (address _owner) onlyOwner() public {   
    addressOfOwner = _owner;
  }  
  
  /* Read */
  function owner () public view returns (address _owner) {
    return addressOfOwner;
  } 
  
  /* Listing */  
  function addItem (uint256 _itemId, string _name, uint256 _sellPrice) onlyOwner() external { 
       newItem(_itemId, _name, _sellPrice);
  }

  function newItem (uint256 _itemId, string _name, uint256 _sellPrice) internal {
    require(_checkItemId(_itemId));
    require(tokenExists(_itemId) == false);
    
    ownerOfItem[_itemId] = address(0);
    priceOfItem[_itemId] = 0;
    sellPriceOfItem[_itemId] = _sellPrice;
    nameOfItem[_itemId] = _name;
    OwnerInfo memory oi = OwnerInfo("", "", "", "");  
    ownerInfoOfItem[_itemId] = oi;    

    listedItems.push(_itemId);    

    emit Add(_itemId, address(0), _sellPrice);
  }
  
  /* Market */  
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {    
    
    // Update prices
    if (_price == 0 ether) {
      // first stage
      return priceInit;
    } else if (_price < 1 ether) {
      // first stage
      return _price.mul(2);
    } else if (_price < 10 ether) {
      // second stage
      return _price.mul(150).div(100);
    } else {
      // third stage
      return _price.mul(120).div(100);
    }

  }
  
  function buy (uint256 _itemId, uint256 _sellPrice, string _name, string _ownerName, string _ownerWords, string _ownerImg, string _ownerNation) payable public returns (bool _result) {
    require(_checkItemId(_itemId));
    require(ownerOf(_itemId) != msg.sender);
    require(msg.sender != address(0)); 
    require(_sellPrice == 0 || _sellPrice.sub(priceInit) >= 0);
    require(msg.value.sub(sellPriceOf(_itemId)) >= 0);
    require(msg.value.mul(2).sub(_sellPrice) >= 0);   
   
    if(_sellPrice == 0)
       _sellPrice = calculateNextPrice(msg.value);  
    
    if(tokenExists(_itemId) == false)
       newItem(_itemId, _name, priceInit);

    address oldOwner = ownerOf(_itemId);
    address newOwner = msg.sender;      
    
    if(oldOwner != address(0))    
    {
      if(msg.value > priceOf(_itemId))
      {
         uint256 tradeCut;
         tradeCut = msg.value.sub(priceOf(_itemId));
         tradeCut = tradeCut.mul(10).div(100); 
         oldOwner.transfer(msg.value.sub(tradeCut)); 
      }
      else
         oldOwner.transfer(msg.value); 
    }    
      
    priceOfItem[_itemId] = msg.value;    
    sellPriceOfItem[_itemId] = _sellPrice;
    OwnerInfo memory oi = OwnerInfo(_ownerName, _ownerWords, _ownerImg, _ownerNation);  
    ownerInfoOfItem[_itemId] = oi;    
    
    _transfer(oldOwner, newOwner, _itemId); 
    emit Bought(_itemId, newOwner, msg.value);
    emit Sold(_itemId, oldOwner, msg.value);   
    owner().transfer(address(this).balance);  

    return true;
    
  }
  
  function changeItemName (uint256 _itemId, string _name) onlyOwner() public returns (bool _result) {    
    require(_checkItemId(_itemId));
    nameOfItem[_itemId] = _name;
    
    return true;    
  } 
  
  function changeOwnerInfo (uint256 _itemId, uint256 _sellPrice, string _ownerName, string _ownerWords, string _ownerImg, string _ownerNation) public returns (bool _result) {    
    require(_checkItemId(_itemId));
    require(ownerOf(_itemId) == msg.sender);
    require(_sellPrice.sub(priceInit) >= 0);
    require(priceOfItem[_itemId].mul(2).sub(_sellPrice) >= 0); 
    
    sellPriceOfItem[_itemId] = _sellPrice;    
    OwnerInfo memory oi = OwnerInfo(_ownerName, _ownerWords, _ownerImg, _ownerNation);  
    ownerInfoOfItem[_itemId] = oi;       

    return true;    
  }

  function setIdRange (uint256 _idStart, uint256 _idMax) onlyOwner() public {    
   
    idStart = _idStart;    
    idMax = _idMax;
    
  } 

  /* Read */
  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    require(_checkItemId(_itemId));     
    bool bExist = false;
    for(uint256 i=0; i<listedItems.length; i++)
    {
       if(listedItems[i] == _itemId)
       {
          bExist = true;  
          break;
       } 
    }
    return bExist;
  }
  
  function priceOf (uint256 _itemId) public view returns (uint256 _price) {
    require(_checkItemId(_itemId)); 
    return priceOfItem[_itemId];
  }
  
  function sellPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
    require(_checkItemId(_itemId));    
    if(sellPriceOfItem[_itemId] == 0)
        return priceInit; 
    else 
        return sellPriceOfItem[_itemId];
  }
  
  function ownerInfoOf (uint256 _itemId) public view returns (uint256, string, string, string, string) {
    require(_checkItemId(_itemId));    
    return (_itemId, ownerInfoOfItem[_itemId].ownerName, ownerInfoOfItem[_itemId].ownerWords, ownerInfoOfItem[_itemId].ownerImg, ownerInfoOfItem[_itemId].ownerNation);
  }

  function itemOf (uint256 _itemId) public view returns (uint256, string, address, uint256, uint256) {
    require(_checkItemId(_itemId));
    return (_itemId, nameOfItem[_itemId], ownerOf(_itemId), priceOf(_itemId), sellPriceOf(_itemId));
  }

  function itemsRange (uint256 _from, uint256 _take) public view returns (uint256[], uint256[], uint256[]) {
    require(idMax.add(1) >= idStart.add(_from.add(_take)));    

    uint256[] memory items = new uint256[](_take);    
    uint256[] memory prices = new uint256[](_take);
    uint256[] memory sellPrices = new uint256[](_take);    

    for (uint256 i = _from; i < _from.add(_take); i++) {  
      uint256 j = i - _from;    
      items[j] = idStart + i;      
      prices[j] = priceOf(idStart + i);
      sellPrices[j] = sellPriceOf(idStart + i);     
    }
   
    return (items, prices, sellPrices);
    
  }
 
  function tokensOf (address _owner) public view returns (uint256[], address[], uint256[], uint256[]) {   
    uint256 num = balanceOf(_owner);
    uint256[] memory items = new uint256[](num);
    address[] memory owners = new address[](num);
    uint256[] memory prices = new uint256[](num);
    uint256[] memory sellPrices = new uint256[](num);
    uint256 k = 0;

    for (uint256 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
          items[k] = listedItems[i];
          owners[k] = ownerOf(listedItems[i]);
          prices[k] = priceOf(listedItems[i]);
          sellPrices[k] = sellPriceOf(listedItems[i]);
          k++;
      }
    }
   
    return (items, owners, prices, sellPrices);
  }

  /* ERC721 */
  function implementsERC721 () public pure returns (bool _implements) {
    return true;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    require(_owner != address(0));
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

  function transfer(address _to, uint256 _itemId) public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint256 _itemId) public {
    require(getApproved(_itemId) == msg.sender);
    _transfer(_from, _to, _itemId);
  }

  function approve(address _to, uint256 _itemId) public {
    require(msg.sender != _to);
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == msg.sender);

    if (_to == address(0)) {
      if (approvedOfItem[_itemId] != address(0)) {
        delete approvedOfItem[_itemId];
        emit Approval(msg.sender, address(0), _itemId);
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
    return "Crypto Super Girlfriend";
  }

  function symbol () public pure returns (string _symbol) {
    return "CSGF";
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

  function _checkItemId(uint256 _itemId) internal view returns (bool) {
   if(_itemId.sub(idStart) >= 0 && idMax.sub(_itemId) >= 0) return true; 
   return false;
  }
  
}