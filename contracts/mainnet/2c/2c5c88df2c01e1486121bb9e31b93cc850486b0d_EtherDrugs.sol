pragma solidity ^0.4.18;

///EtherDrugs

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d3b7b6a7b693b2abbabcbea9b6bdfdb0bc">[email&#160;protected]</a>> (https://github.com/dete)
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

contract EtherDrugs is ERC721 {

  /*** EVENTS ***/
  event Birth(uint256 tokenId, bytes32 name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, bytes32 name);
  event Transfer(address from, address to, uint256 tokenId);

  /*** STRUCTS ***/
  struct Drug {
    bytes32 name;
    address owner;
    uint256 price;
    uint256 last_price;
    address approve_transfer_to;
  }

  /*** CONSTANTS ***/
  string public constant NAME = "EtherDrugs";
  string public constant SYMBOL = "DRUG";
  
  bool public gameOpen = false;

  /*** STORAGE ***/
  mapping (address => uint256) private ownerCount;
  mapping (uint256 => address) public lastBuyer;

  address public ceoAddress;
  mapping (uint256 => address) public extra;
  
  uint256 drug_count;
 
  mapping (uint256 => Drug) private drugs;

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
  function EtherDrugs() public {
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

  function createDrug(bytes32 _name, uint256 _price) public onlyCEO {
    require(msg.sender != address(0));
    _create_drug(_name, address(this), _price, 0);
  }

  function createPromoDrug(bytes32 _name, address _owner, uint256 _price, uint256 _last_price) public onlyCEO {
    require(msg.sender != address(0));
    require(_owner != address(0));
    _create_drug(_name, _owner, _price, _last_price);
  }

  function openGame() public onlyCEO {
    require(msg.sender != address(0));
    gameOpen = true;
  }

  function totalSupply() public view returns (uint256 total) {
    return drug_count;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerCount[_owner];
  }
  function priceOf(uint256 _drug_id) public view returns (uint256 price) {
    return drugs[_drug_id].price;
  }

  function getDrug(uint256 _drug_id) public view returns (
    uint256 id,
    bytes32 drug_name,
    address owner,
    uint256 price,
    uint256 last_price
  ) {
    id = _drug_id;
    drug_name = drugs[_drug_id].name;
    owner = drugs[_drug_id].owner;
    price = drugs[_drug_id].price;
    last_price = drugs[_drug_id].last_price;
  }
  
  function getDrugs() public view returns (uint256[], bytes32[], address[], uint256[]) {
    uint256[] memory ids = new uint256[](drug_count);
    bytes32[] memory names = new bytes32[](drug_count);
    address[] memory owners = new address[](drug_count);
    uint256[] memory prices = new uint256[](drug_count);
    for(uint256 _id = 0; _id < drug_count; _id++){
      ids[_id] = _id;
      names[_id] = drugs[_id].name;
      owners[_id] = drugs[_id].owner;
      prices[_id] = drugs[_id].price;
    }
    return (ids, names, owners, prices);
  }
  
  function purchase(uint256 _drug_id) public payable {
    require(gameOpen == true);
    Drug storage drug = drugs[_drug_id];

    require(drug.owner != msg.sender);
    require(msg.sender != address(0));  
    require(msg.value >= drug.price);

    uint256 excess = SafeMath.sub(msg.value, drug.price);
    uint256 half_diff = SafeMath.div(SafeMath.sub(drug.price, drug.last_price), 2);
    uint256 reward = SafeMath.add(half_diff, drug.last_price);
  
    lastBuyer[1].send(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 69))); //69% goes to last buyer
    lastBuyer[6].send(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 2)));  //2% goes to 6th last buyer, else ceo
    lastBuyer[9].send(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 2)));  //2% goes to 9th last buyer, else ceo

    if(drug.owner == address(this)){
      ceoAddress.send(reward);
    } else {
      drug.owner.send(reward);
    }
    
    
    drug.last_price = drug.price;
    address _old_owner = drug.owner;
    
    if(drug.price < 1690000000000000000){ // 1.69 eth
        drug.price = SafeMath.mul(SafeMath.div(drug.price, 100), 169); // 1.69x
    } else {
        drug.price = SafeMath.mul(SafeMath.div(drug.price, 100), 125); // 1.2x
    }
    drug.owner = msg.sender;

    lastBuyer[9] = lastBuyer[8];
    lastBuyer[8] = lastBuyer[7];
    lastBuyer[7] = lastBuyer[6];
    lastBuyer[6] = lastBuyer[5];
    lastBuyer[5] = lastBuyer[4];
    lastBuyer[4] = lastBuyer[3];
    lastBuyer[3] = lastBuyer[2];
    lastBuyer[2] = lastBuyer[1];
    lastBuyer[1] = msg.sender;

    Transfer(_old_owner, drug.owner, _drug_id);
    TokenSold(_drug_id, drug.last_price, drug.price, _old_owner, drug.owner, drug.name);

    msg.sender.send(excess);
  }

  function payout() public onlyCEO {
    ceoAddress.send(this.balance);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 resultIndex = 0;
      for (uint256 drugId = 0; drugId <= totalSupply(); drugId++) {
        if (drugs[drugId].owner == _owner) {
          result[resultIndex] = drugId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /*** ERC-721 compliance. ***/

  function approve(address _to, uint256 _drug_id) public {
    require(msg.sender == drugs[_drug_id].owner);
    drugs[_drug_id].approve_transfer_to = _to;
    Approval(msg.sender, _to, _drug_id);
  }
  function ownerOf(uint256 _drug_id) public view returns (address owner){
    owner = drugs[_drug_id].owner;
    require(owner != address(0));
  }
  function takeOwnership(uint256 _drug_id) public {
    address oldOwner = drugs[_drug_id].owner;
    require(msg.sender != address(0));
    require(drugs[_drug_id].approve_transfer_to == msg.sender);
    _transfer(oldOwner, msg.sender, _drug_id);
  }
  function transfer(address _to, uint256 _drug_id) public {
    require(msg.sender != address(0));
    require(msg.sender == drugs[_drug_id].owner);
    _transfer(msg.sender, _to, _drug_id);
  }
  function transferFrom(address _from, address _to, uint256 _drug_id) public {
    require(_from == drugs[_drug_id].owner);
    require(drugs[_drug_id].approve_transfer_to == _to);
    require(_to != address(0));
    _transfer(_from, _to, _drug_id);
  }

  /*** PRIVATE METHODS ***/

  function _create_drug(bytes32 _name, address _owner, uint256 _price, uint256 _last_price) private {
    // Params: name, owner, price, is_for_sale, is_public, share_price, increase, fee, share_count,
    drugs[drug_count] = Drug({
      name: _name,
      owner: _owner,
      price: _price,
      last_price: _last_price,
      approve_transfer_to: address(0)
    });
    
    Drug storage drug = drugs[drug_count];
    
    Birth(drug_count, _name, _owner);
    Transfer(address(this), _owner, drug_count);
    drug_count++;
  }

  function _transfer(address _from, address _to, uint256 _drug_id) private {
    drugs[_drug_id].owner = _to;
    drugs[_drug_id].approve_transfer_to = address(0);
    ownerCount[_from] -= 1;
    ownerCount[_to] += 1;
    Transfer(_from, _to, _drug_id);
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