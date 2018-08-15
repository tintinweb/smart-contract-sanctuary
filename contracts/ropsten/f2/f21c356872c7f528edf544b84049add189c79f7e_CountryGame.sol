pragma solidity ^0.4.18;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
    uint256 c = a * b;
    assert(c / a == b);
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

contract IPGToken {

   function transferInGame (address _from, address _to, uint256 _value) public returns (bool success);
   function GetBuyPrice() public view returns (uint256);
   function GetSellPrice() public view returns (uint256);
   mapping (address => uint256) public balanceOf;
}

contract CountryGame {
//string public version = "test1.0";
using SafeMath for uint256;
address owner = 0x815dE3E00Be485DBCA2A2ADf40f945a8E0343b29;
address ipg_owner = 0xeF38E8c95C855d7f177684a0De07886135680D59;
bool private initDone = false;
IPGToken private ipgToken = IPGToken(0x5011157b062DC661D6D1e3460494d92c9B6544e2);
event CountryPurchased(uint256 id, address buyer, address seller, uint256 price);
event CountryAdded(uint256 id, uint256 category_id, uint256 price);
event BoughtIPG (address _buyer, uint256 _ipg_amount, uint256 _eth_paid);
event SoldIPG (address _seller, uint256 _ipg_amount, uint256 _revenue);

struct Country {
  address owner;
  uint256 price;
  uint256 category_id;
  bool locked;
}

mapping(uint256 => Country) private countryMap;
uint256 public countryCount;

bool isPaused = false;
bool public selling_stopped = false;
modifier onlyOwner() {
require (msg.sender == owner);
_;
}

modifier isUnlocked() {
  require(!isPaused);
  _;
}

modifier isRunning {
    assert (!selling_stopped);
    _;
}

constructor () public {
    isPaused = false;
    selling_stopped = false;
}
    
function setIPGInfo(address _contract, address _contract_owner) public onlyOwner{
  ipgToken = IPGToken(_contract);
  ipg_owner = _contract_owner;
}

function stopSelling(bool _isSelling) public onlyOwner {
  selling_stopped = _isSelling;
}

function pauseGame() public onlyOwner {
  isPaused = true;
}

function playGame() public onlyOwner {
  isPaused = false;
}

function GetIsPauded() public view returns(bool) {
  return(isPaused);
}


function withdrawAmount (uint256 _amount) onlyOwner() public {
  owner.transfer(_amount);
}

function _addrNotNull(address _to) internal pure returns (bool) {
  return(_to != address(0));
}

function init() public onlyOwner {
    require(!initDone);
    initDone = true;
    countryMap[0] = Country({locked: false, owner:owner, price: 25000000000, category_id: 3 });
    countryMap[1] = Country({locked: false, owner:owner, price: 25000000000, category_id: 3 });
    countryMap[2] = Country({locked: false, owner:owner, price: 25000000000, category_id: 3 });
    countryMap[3] = Country({locked: false, owner:owner, price: 25000000000, category_id: 4 });
    countryMap[4] = Country({locked: false, owner:owner, price: 25000000000, category_id: 1 });
    countryMap[5] = Country({locked: false, owner:owner, price: 25000000000, category_id: 1 });
    countryMap[6] = Country({locked: false, owner:owner, price: 25000000000, category_id: 1 });
    countryMap[7] = Country({locked: false, owner:owner, price: 25000000000, category_id: 1 });
    countryMap[8] = Country({locked: false, owner:owner, price: 25000000000, category_id: 1 });
    countryMap[9] = Country({locked: false, owner:owner, price: 25000000000, category_id: 1 });
    countryMap[10] = Country({locked: false, owner:owner, price: 25000000000, category_id: 6 });
    countryMap[11] = Country({locked: false, owner:owner, price: 25000000000, category_id: 6 });
    countryCount = 12;
}

function addCountry(uint256 _category_id, uint256 _price) public onlyOwner {
  countryMap[countryCount] = Country({price: _price, owner:owner, category_id: _category_id, locked : false});
  emit CountryAdded(countryCount++, _category_id, _price);
}

function purchaseCountry (uint256 _country_id) public isUnlocked {
    Country memory country = countryMap[_country_id];
    require(!country.locked);
    require(msg.sender != country.owner);

    uint256 token_balance = ipgToken.balanceOf(msg.sender);
    require(token_balance >= country.price);
    uint256 totalPerc = 160;

    uint256 parentFee = country.price.mul(150) / totalPerc;
    uint256 devFee = country.price.sub(parentFee);

    emit CountryPurchased(_country_id, msg.sender, country.owner, country.price);

    ipgToken.transferInGame(msg.sender, country.owner, parentFee);
    ipgToken.transferInGame(msg.sender, owner, devFee);

    countryMap[_country_id].owner = msg.sender;
    countryMap[_country_id].price = country.price.mul(totalPerc) / 100;
}

function BuyIPG () public payable isUnlocked returns (uint256 amount){
    uint256 buyPrice = ipgToken.GetBuyPrice();
    amount = msg.value / buyPrice * 100000000;
    
    ipgToken.transferInGame(ipg_owner, msg.sender, amount);
    emit BoughtIPG(msg.sender, amount, msg.value);
}

function SellIPG(uint256 amount) public isRunning returns (uint256 revenue){
    uint256 sellPrice = ipgToken.GetSellPrice();
    revenue = amount / sellPrice;
    msg.sender.transfer(revenue);
    ipgToken.transferInGame(ipg_owner, msg.sender, amount);
    emit SoldIPG(msg.sender, amount, revenue);
}


function getCountry(uint256 _country_id) public view returns (address _owner, uint256 price, uint256 category_id) {
  Country memory _country = countryMap[_country_id];
  _owner = _country.owner;
  price = _country.price;
  category_id = _country.category_id;
}

function getCountryCount() public view returns (uint256 country_count) {
  country_count = countryCount;
}

}