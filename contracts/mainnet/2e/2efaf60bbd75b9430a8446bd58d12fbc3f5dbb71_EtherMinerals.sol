pragma solidity ^0.4.18;

///EtherMinerals

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7c181908193c1d04151311061912521f13">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract EtherMinerals is ERC721 {

  /*** EVENTS ***/
  event Birth(uint256 tokenId, bytes32 name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, bytes32 name);
  event Transfer(address from, address to, uint256 tokenId);

  /*** STRUCTS ***/
  struct Mineral {
    bytes32 name;
    address owner;
    uint256 price;
    uint256 last_price;
    address approve_transfer_to;
  }

  /*** CONSTANTS ***/
  string public constant NAME = "EtherMinerals";
  string public constant SYMBOL = "MINERAL";
  
  uint256 private startingPrice = 0.01 ether;
  uint256 private firstStepLimit =  0.15 ether;
  uint256 private secondStepLimit = 0.564957 ether;
  
  bool public gameOpen = false;

  /*** STORAGE ***/
  mapping (address => uint256) private ownerCount;
  mapping (uint256 => address) public lastBuyer;

  address public ceoAddress;
  mapping (uint256 => address) public extra;
  
  uint256 mineral_count;
 
  mapping (uint256 => Mineral) private minerals;

  /*** ACCESS MODIFIERS ***/
  modifier onlyCEO() { require(msg.sender == ceoAddress); _; }

  /*** ACCESS MODIFIES ***/
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setLast(uint256 _id, address _newExtra) public onlyCEO {
    require(_newExtra != address(0));
    lastBuyer[_id] = _newExtra;
  }

  /*** DEFAULT METHODS ***/
  function symbol() public pure returns (string) { return SYMBOL; }
  function name() public pure returns (string) { return NAME; }
  function implementsERC721() public pure returns (bool) { return true; }

  /*** CONSTRUCTOR ***/
  function EtherMinerals() public {
    ceoAddress = msg.sender;
    lastBuyer[1] = msg.sender;
    lastBuyer[2] = msg.sender;
    lastBuyer[3] = msg.sender;
    lastBuyer[4] = msg.sender;
    lastBuyer[5] = msg.sender;
    lastBuyer[6] = msg.sender;
    lastBuyer[7] = msg.sender;
    lastBuyer[8] = msg.sender;
    lastBuyer[9] = msg.sender;
  }

  /*** INTERFACE METHODS ***/

  function createMineral(bytes32 _name, uint256 _price) public onlyCEO {
    require(msg.sender != address(0));
    _create_mineral(_name, address(this), _price, 0);
  }

  function createPromoMineral(bytes32 _name, address _owner, uint256 _price, uint256 _last_price) public onlyCEO {
    require(msg.sender != address(0));
    require(_owner != address(0));
    _create_mineral(_name, _owner, _price, _last_price);
  }

  function openGame() public onlyCEO {
    require(msg.sender != address(0));
    gameOpen = true;
  }

  function totalSupply() public view returns (uint256 total) {
    return mineral_count;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerCount[_owner];
  }
  function priceOf(uint256 _mineral_id) public view returns (uint256 price) {
    return minerals[_mineral_id].price;
  }

  function getMineral(uint256 _mineral_id) public view returns (
    uint256 id,
    bytes32 mineral_name,
    address owner,
    uint256 price,
    uint256 last_price
  ) {
    id = _mineral_id;
    mineral_name = minerals[_mineral_id].name;
    owner = minerals[_mineral_id].owner;
    price = minerals[_mineral_id].price;
    last_price = minerals[_mineral_id].last_price;
  }
  
  function getMinerals() public view returns (uint256[], bytes32[], address[], uint256[]) {
    uint256[] memory ids = new uint256[](mineral_count);
    bytes32[] memory names = new bytes32[](mineral_count);
    address[] memory owners = new address[](mineral_count);
    uint256[] memory prices = new uint256[](mineral_count);
    for(uint256 _id = 0; _id < mineral_count; _id++){
      ids[_id] = _id;
      names[_id] = minerals[_id].name;
      owners[_id] = minerals[_id].owner;
      prices[_id] = minerals[_id].price;
    }
    return (ids, names, owners, prices);
  }
  
  function getBalance() public onlyCEO view returns(uint){
      return address(this).balance;
  }
  

  
  function purchase(uint256 _mineral_id) public payable {
    require(gameOpen == true);
    Mineral storage mineral = minerals[_mineral_id];

    require(mineral.owner != msg.sender);
    require(msg.sender != address(0));  
    require(msg.value >= mineral.price);

    uint256 excess = SafeMath.sub(msg.value, mineral.price);
    uint256 reward = uint256(SafeMath.div(SafeMath.mul(mineral.price, 90), 100));
  

    if(mineral.owner != address(this)){
      mineral.owner.transfer(reward);
    }
    
    
    mineral.last_price = mineral.price;
    address _old_owner = mineral.owner;
    
    if (mineral.price < firstStepLimit) {
      // first stage
      mineral.price = SafeMath.div(SafeMath.mul(mineral.price, 200), 90);
    } else if (mineral.price < secondStepLimit) {
      // second stage
      mineral.price = SafeMath.div(SafeMath.mul(mineral.price, 118), 90);
    } else {
      // third stage
      mineral.price = SafeMath.div(SafeMath.mul(mineral.price, 113), 90);
    }
    mineral.owner = msg.sender;

    emit Transfer(_old_owner, mineral.owner, _mineral_id);
    emit TokenSold(_mineral_id, mineral.last_price, mineral.price, _old_owner, mineral.owner, mineral.name);

    msg.sender.transfer(excess);
  }

  function payout() public onlyCEO {
    ceoAddress.transfer(address(this).balance);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 resultIndex = 0;
      for (uint256 mineralId = 0; mineralId <= totalSupply(); mineralId++) {
        if (minerals[mineralId].owner == _owner) {
          result[resultIndex] = mineralId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /*** ERC-721 compliance. ***/

  function approve(address _to, uint256 _mineral_id) public {
    require(msg.sender == minerals[_mineral_id].owner);
    minerals[_mineral_id].approve_transfer_to = _to;
    emit Approval(msg.sender, _to, _mineral_id);
  }
  function ownerOf(uint256 _mineral_id) public view returns (address owner){
    owner = minerals[_mineral_id].owner;
    require(owner != address(0));
  }
  function takeOwnership(uint256 _mineral_id) public {
    address oldOwner = minerals[_mineral_id].owner;
    require(msg.sender != address(0));
    require(minerals[_mineral_id].approve_transfer_to == msg.sender);
    _transfer(oldOwner, msg.sender, _mineral_id);
  }
  function transfer(address _to, uint256 _mineral_id) public {
    require(msg.sender != address(0));
    require(msg.sender == minerals[_mineral_id].owner);
    _transfer(msg.sender, _to, _mineral_id);
  }
  function transferFrom(address _from, address _to, uint256 _mineral_id) public {
    require(_from == minerals[_mineral_id].owner);
    require(minerals[_mineral_id].approve_transfer_to == _to);
    require(_to != address(0));
    _transfer(_from, _to, _mineral_id);
  }
 
  function createAllTokens() public onlyCEO{
    createMineral("Emerald", 10000000000000000);
    createMineral("Opal", 10000000000000000);
    createMineral("Diamond", 10000000000000000);
    createMineral("Bismuth", 10000000000000000);
    createMineral("Amethyst", 10000000000000000);
    createMineral("Gold", 10000000000000000);
    createMineral("Fluorite", 10000000000000000);
    createMineral("Ruby", 10000000000000000);
    createMineral("Sapphire", 10000000000000000);
    createMineral("Pascoite", 10000000000000000);
    createMineral("Karpatite", 10000000000000000);
    createMineral("Uvarovite", 10000000000000000);
    createMineral("Kryptonite", 10000000000000000);
    createMineral("Good ol&#39; Rock", 10000000000000000);
    createMineral("Malachite", 10000000000000000);
    createMineral("Silver", 10000000000000000);
    createMineral("Burmese Tourmaline" ,10000000000000000);
    }

  /*** PRIVATE METHODS ***/

  function _create_mineral(bytes32 _name, address _owner, uint256 _price, uint256 _last_price) private {
    // Params: name, owner, price, is_for_sale, is_public, share_price, increase, fee, share_count,
    minerals[mineral_count] = Mineral({
      name: _name,
      owner: _owner,
      price: _price,
      last_price: _last_price,
      approve_transfer_to: address(0)
    });
    

    
    
    emit Birth(mineral_count, _name, _owner);
    emit Transfer(address(this), _owner, mineral_count);
    mineral_count++;
  }

  function _transfer(address _from, address _to, uint256 _mineral_id) private {
    minerals[_mineral_id].owner = _to;
    minerals[_mineral_id].approve_transfer_to = address(0);
    ownerCount[_from] -= 1;
    ownerCount[_to] += 1;
    emit Transfer(_from, _to, _mineral_id);
  }
}

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