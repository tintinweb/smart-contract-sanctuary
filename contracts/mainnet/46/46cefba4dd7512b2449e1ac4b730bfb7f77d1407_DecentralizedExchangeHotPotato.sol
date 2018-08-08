pragma solidity ^0.4.21;

/// @author MinakoKojima (https://github.com/lychees)
contract DecentralizedExchangeHotPotato {
  address private owner;
  mapping (address => bool) private admins;
  
  struct Order {
    address creator;    
    address owner;
    address issuer;    
    uint256 tokenId;    
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }  
  Order[] private orderBook;
  uint256 private orderBookSize;

  function DecentralizedExchangeHotPotato() public {
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

  /* Withdraw */
  function withdrawAll () onlyAdmins() public {
   msg.sender.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }

  /* ERC721 */
  function name() public pure returns (string _name) {
    return "dapdap.io | HotPotatoExchange";
  }

  /* Read */
  function isAdmin(address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }
  function totalOrder() public view returns (uint256 _totalOrder) {
    return orderBookSize;
  }  
  function allOf (uint256 _id) public view returns (address _creator, address _owner, address _issuer, uint256 _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime) {
    return (orderBook[_id].creator, orderBook[_id].owner, orderBook[_id].issuer, orderBook[_id].tokenId, orderBook[_id].price, orderBook[_id].startTime, orderBook[_id].endTime);
  }  
  
  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }

  function getNextPrice (uint256 _price) public pure returns (uint256 _nextPrice) {
    return _price * 123 / 100;
  }  

  /* Buy */
  function put(address _issuer, uint256 _tokenId, uint256 _price,
               uint256 _startTime, uint256 _endTime) public {
    require(_startTime <= _endTime);                 
    Issuer issuer = Issuer(_issuer);
    require(issuer.ownerOf(_tokenId) == msg.sender);
    issuer.transferFrom(msg.sender, address(this), _tokenId);
    if (orderBookSize == orderBook.length) {
      orderBook.push(Order(msg.sender, msg.sender,  _issuer, _tokenId, _price, _startTime, _endTime));
    } else {    
      orderBook[orderBookSize] = Order(msg.sender, msg.sender,  _issuer, _tokenId, _price, _startTime, _endTime);
    }
    orderBookSize += 1;
  }
  function buy(uint256 _id) public payable{
    require(msg.value >= orderBook[_id].price);
    require(msg.sender != orderBook[_id].owner);
    require(!isContract(msg.sender));
    require(orderBook[_id].startTime <= now && now <= orderBook[_id].endTime);
    orderBook[_id].owner.transfer(orderBook[_id].price*24/25); // 96%
    orderBook[_id].creator.transfer(orderBook[_id].price/50);  // 2%    
    if (msg.value > orderBook[_id].price) {
        msg.sender.transfer(msg.value - orderBook[_id].price);
    }
    orderBook[_id].owner = msg.sender;
    orderBook[_id].price = getNextPrice(orderBook[_id].price);
  }
  function revoke(uint256 _id) public {
    require(msg.sender == orderBook[_id].owner);
    require(orderBook[_id].endTime <= now);
    
    Issuer issuer = Issuer(orderBook[_id].issuer);
    issuer.transfer(msg.sender, orderBook[_id].tokenId);    
    orderBook[_id] = orderBook[orderBookSize-1];
    orderBookSize -= 1;
  }
}

interface Issuer {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;  
  function transfer(address _to, uint256 _tokenId) external;
  function ownerOf (uint256 _tokenId) external view returns (address _owner);
}