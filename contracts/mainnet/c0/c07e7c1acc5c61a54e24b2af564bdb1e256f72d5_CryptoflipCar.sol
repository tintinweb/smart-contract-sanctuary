pragma solidity ^0.4.18;

contract CryptoflipCar {
string version = &#39;1.1&#39;;
address ownerAddress = 0x3177Abbe93422c9525652b5d4e1101a248A99776;
address foundTeamAddress = 0x30A38029bEd78159B0342FF9722C3B56479328D8;

struct WhaleCard {
   address ownerAddress;
   uint256 curPrice;
}

struct Car {
    string name;
    address[4] ownerAddresses;
    uint256 curPrice;
    uint256 companyId;
    uint256 makeId;
    bool is_released;
    string adv_link;
    string adv_text;
    address adv_owner;
    uint256 adv_price;
}
    
struct Company {
    string name;
    address ownerAddress;
    uint256 curPrice;
    bool is_released;
    string adv_link;
    string adv_text;
    address adv_owner;
    uint256 adv_price;
}

struct Make {
    string name;
    address ownerAddress;
    uint256 curPrice;
    uint256 companyId;
    bool is_released;
    string adv_link;
    string adv_text;
    address adv_owner;
    uint256 adv_price;
}

Company[] companies;
Make[] makes;
Car[] cars;
WhaleCard whalecard;

modifier onlyOwner() {
require (msg.sender == ownerAddress);
_;
}

bool companiesAreInitiated = false;
bool makesAreInitiated = false;
bool carsAreInitiated = false;
bool whalecardAreInitiated = false;
bool isPaused = false;

/*
We use the following functions to pause and unpause the game.
*/
function pauseGame() public onlyOwner {
  isPaused = true;
}

function playGame() public onlyOwner {
  isPaused = false;
}

function GetIsPauded() public view returns(bool) {
  return(isPaused);
}

function purchaseCarAdv(uint256 _cardId, string _text, string _link) public payable {
  require(msg.value >= cars[_cardId].adv_price);
  require(isPaused == false);
  require(cars[_cardId].is_released == true);
  uint256 totalpercent = 160;
  uint256 commission5percent = div(mul(msg.value, 5), totalpercent);
  foundTeamAddress.transfer(commission5percent);
  uint256 commissionOwner = msg.value - commission5percent;
  cars[_cardId].ownerAddresses[0].transfer(commission5percent);
  commissionOwner = commissionOwner - commission5percent;
  cars[_cardId].adv_owner.transfer(commissionOwner);
  cars[_cardId].adv_owner = msg.sender;
  cars[_cardId].adv_price = div(mul(cars[_cardId].adv_price, totalpercent), 100);
  cars[_cardId].adv_text = _text;
  cars[_cardId].adv_link = _link;  
}

function purchaseCompanyAdv(uint256 _cardId, string _text, string _link) public payable {
  require(msg.value >= companies[_cardId].adv_price);
  require(isPaused == false);
  require(companies[_cardId].is_released == true);
  uint256 totalpercent = 160;
  uint256 commission5percent = div(mul(msg.value, 5), totalpercent);
  foundTeamAddress.transfer(commission5percent);
  uint256 commissionOwner = msg.value - commission5percent;
  companies[_cardId].ownerAddress.transfer(commission5percent);
  commissionOwner = commissionOwner - commission5percent;
  companies[_cardId].adv_owner.transfer(commissionOwner);
  companies[_cardId].adv_owner = msg.sender;
  companies[_cardId].adv_price = div(mul(companies[_cardId].adv_price, totalpercent), 100);
  companies[_cardId].adv_text = _text;
  companies[_cardId].adv_link = _link;  
}

function purchaseMakeAdv(uint256 _cardId, string _text, string _link) public payable {
  require(msg.value >= makes[_cardId].adv_price);
  require(isPaused == false);
  require(makes[_cardId].is_released == true);
  uint256 totalpercent = 160;
  uint256 commission5percent = div(mul(msg.value, 5), totalpercent);
  foundTeamAddress.transfer(commission5percent);
  uint256 commissionOwner = msg.value - commission5percent;
  makes[_cardId].ownerAddress.transfer(commission5percent);
  commissionOwner = commissionOwner - commission5percent;
  makes[_cardId].adv_owner.transfer(commissionOwner);
  makes[_cardId].adv_owner = msg.sender;
  makes[_cardId].adv_price = div(mul(makes[_cardId].adv_price, totalpercent), 100);
  makes[_cardId].adv_text = _text;
  makes[_cardId].adv_link = _link;  
}

function purchaseWhaleCard() public payable {
    require(msg.value >= whalecard.curPrice);
    require(isPaused == false);
    require(whalecardAreInitiated == true);
    uint256 totalpercent = 155;
    uint256 commission5percent = div(mul(msg.value, 5) , totalpercent);
    foundTeamAddress.transfer(commission5percent);    
    uint256 commissionOwner = msg.value - commission5percent;
    whalecard.ownerAddress.transfer(commissionOwner);    
    whalecard.ownerAddress = msg.sender;
    whalecard.curPrice = div(mul(whalecard.curPrice, totalpercent), 100);
}

function purchaseCarCard(uint256 _cardId) public payable {
  require(isPaused == false);   
  require(msg.value >= cars[_cardId].curPrice);
  require(cars[_cardId].is_released == true);
  require(carsAreInitiated == true);
  uint256 totalpercent = 150 + 5 + 2 + 2;
  uint256 commission1percent = div(mul(msg.value, 1) , totalpercent);  
  uint256 commissionOwner = msg.value;
  if (whalecardAreInitiated == true){
    totalpercent = totalpercent + 1;
    whalecard.ownerAddress.transfer(commission1percent);
    commissionOwner = commissionOwner - commission1percent;    
  }
  uint256 commission5percent = mul(commission1percent, 5);
  foundTeamAddress.transfer(commission5percent);
  commissionOwner = commissionOwner - commission5percent;
  uint256 commission2percent = mul(commission1percent, 2);
  uint256 companyId = cars[_cardId].companyId;
  companies[companyId].ownerAddress.transfer(commission2percent);
  commissionOwner = commissionOwner - commission2percent;
  uint256 makeId = cars[_cardId].makeId;
  makes[makeId].ownerAddress.transfer(commission2percent);
  commissionOwner = commissionOwner - commission2percent;
  if (cars[_cardId].ownerAddresses[3] != 0){
      cars[_cardId].ownerAddresses[3].transfer(commission2percent);
      commissionOwner = commissionOwner - commission2percent;
      totalpercent = totalpercent + 2;
  }
  cars[_cardId].ownerAddresses[3] = cars[_cardId].ownerAddresses[2];
  if (cars[_cardId].ownerAddresses[2] != 0){
      cars[_cardId].ownerAddresses[2].transfer(commission2percent);
      commissionOwner = commissionOwner - commission2percent;
      totalpercent = totalpercent + 2;
  }
  cars[_cardId].ownerAddresses[2] = cars[_cardId].ownerAddresses[1];
  if (cars[_cardId].ownerAddresses[1] != 0){
      cars[_cardId].ownerAddresses[1].transfer(commission2percent);
      commissionOwner = commissionOwner - commission2percent;
      totalpercent = totalpercent + 2;
  }
  cars[_cardId].ownerAddresses[1] = cars[_cardId].ownerAddresses[0];
  cars[_cardId].ownerAddresses[0].transfer(commissionOwner);
  cars[_cardId].ownerAddresses[0] = msg.sender;
  totalpercent = totalpercent + 2;
  cars[_cardId].curPrice = div(mul(cars[_cardId].curPrice, totalpercent), 100);
}

function purchaseMakeCard(uint256 _cardId) public payable {
  require(isPaused == false);   
  require(msg.value >= makes[_cardId].curPrice);
  require(makes[_cardId].is_released == true);
  require(makesAreInitiated == true);
  uint256 totalpercent = 150 + 5 + 2;
  uint256 commission1percent = div(mul(msg.value, 1) , totalpercent);  
  uint256 commissionOwner = msg.value;
  if (whalecardAreInitiated == true){
    totalpercent = totalpercent + 1;
    whalecard.ownerAddress.transfer(commission1percent);
    commissionOwner = commissionOwner - commission1percent;    
  }
  uint256 commission5percent = mul(commission1percent, 5);
  foundTeamAddress.transfer(commission5percent);
  commissionOwner = commissionOwner - commission5percent;
  uint256 commission2percent = mul(commission1percent, 2);
  uint256 companyId = makes[_cardId].companyId;
  companies[companyId].ownerAddress.transfer(commission2percent);
  commissionOwner = commissionOwner - commission2percent;
  makes[_cardId].ownerAddress.transfer(commissionOwner);
  makes[_cardId].ownerAddress = msg.sender;
  makes[_cardId].curPrice = div(mul(makes[_cardId].curPrice, totalpercent), 100);
}

function purchaseCompanyCard(uint256 _cardId) public payable {
  require(isPaused == false);   
  require(msg.value >= companies[_cardId].curPrice);
  require(companies[_cardId].is_released == true);
  require(companiesAreInitiated == true);
  uint256 totalpercent = 150 + 5;
  uint256 commission1percent = div(mul(msg.value, 1) , totalpercent);  
  uint256 commissionOwner = msg.value;
  if (whalecardAreInitiated == true){
    totalpercent = totalpercent + 1;
    whalecard.ownerAddress.transfer(commission1percent);
    commissionOwner = commissionOwner - commission1percent;    
  }
  uint256 commission5percent = mul(commission1percent, 5);
  foundTeamAddress.transfer(commission5percent);
  commissionOwner = commissionOwner - commission5percent;
  companies[_cardId].ownerAddress.transfer(commissionOwner);
  companies[_cardId].ownerAddress = msg.sender;
  companies[_cardId].curPrice = div(mul(companies[_cardId].curPrice, totalpercent), 100);
}
// This function will return all of the details of our company
function getCompanyCount() public view returns (uint) {
  return companies.length;
}

function getMakeCount() public view returns (uint) {
  return makes.length;
}

function getCarCount() public view returns (uint) {
  return cars.length;
}

function getWhaleCard() public view returns (
address ownerAddress1,
uint256 curPrice
){
    ownerAddress1 = whalecard.ownerAddress;
    curPrice = whalecard.curPrice;    
}

// This function will return all of the details of our company
function getCompany(uint256 _companyId) public view returns (
string name,
address ownerAddress1,
uint256 curPrice,
bool is_released,
string adv_text,
string adv_link,
uint256 adv_price,
address adv_owner,
uint id
) {
  Company storage _company = companies[_companyId];
  name = _company.name;
  ownerAddress1 = _company.ownerAddress;
  curPrice = _company.curPrice;
  is_released = _company.is_released;
  id = _companyId;
  adv_text = _company.adv_text;
  adv_link = _company.adv_link;
  adv_price = _company.adv_price;
  adv_owner = _company.adv_owner;
}

function getMake(uint _makeId) public view returns (
string name,
address ownerAddress1,
uint256 curPrice,
uint256 companyId,
bool is_released,
string adv_text,
string adv_link,
uint256 adv_price,
address adv_owner,
uint id
) {
  Make storage _make = makes[_makeId];
  name = _make.name;
  ownerAddress1 = _make.ownerAddress;
  curPrice = _make.curPrice;
  companyId = _make.companyId;
  is_released = _make.is_released;
  id = _makeId;
  adv_text = _make.adv_text;
  adv_link = _make.adv_link;
  adv_price = _make.adv_price;
  adv_owner = _make.adv_owner;
}

function getCar(uint _carId) public view returns (
string name,
address[4] ownerAddresses,
uint256 curPrice,
uint256 companyId,
uint256 makeId,
bool is_released,
string adv_text,
string adv_link,
uint256 adv_price,
address adv_owner,
uint id
) {
  Car storage _car = cars[_carId];
  name = _car.name;
  ownerAddresses = _car.ownerAddresses;
  curPrice = _car.curPrice;
  makeId = _car.makeId;
  companyId = _car.companyId;
  is_released = _car.is_released;
  id = _carId;
  adv_text = _car.adv_text;
  adv_link = _car.adv_link;
  adv_price = _car.adv_price;
  adv_owner = _car.adv_owner;
}


/**
@dev Multiplies two numbers, throws on overflow. => From the SafeMath library
*/
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
return c;
}

/**
@dev Integer division of two numbers, truncating the quotient. => From the SafeMath library
*/
function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
uint c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
return c;
}



function InitiateCompanies() public onlyOwner {
  require(companiesAreInitiated == false);
  addCompany("Aston Martin", 0xe7eca2a94e9d59848f3c1e1ffaacd881d4c3a4f2, 592240896000000000 ,true);
  addCompany("BMW", 0x327bfb6286026bd1a017ba6693e0f47c8b98731b, 592240896000000000 ,true);
  addCompany("Ferrari", 0xef764bac8a438e7e498c2e5fccf0f174c3e3f8db, 379641600000000000 ,true);
  addCompany("Honda", 0xef764bac8a438e7e498c2e5fccf0f174c3e3f8db, 243360000000000000 ,true);
  companies[0].adv_text="BurnUP!!!";
  companies[0].adv_link="https://burnup.io/?r=0x049bEd1598655b64F09E4835084fBc502ab1aD86";
  companies[0].adv_owner=0x049bed1598655b64f09e4835084fbc502ab1ad86;
  companies[0].adv_price=8000000000000000;
  companiesAreInitiated = true;
}

function addCompany(string name, address address1, uint256 price, bool is_released) public onlyOwner {
  uint companyId = companies.length++;
  companies[companyId].name = name;
  companies[companyId].curPrice   = price;
  companies[companyId].ownerAddress = address1;
  companies[companyId].is_released   = is_released;
  companies[companyId].adv_text = &#39;Your Ad here&#39;;
  companies[companyId].adv_link = &#39;http://cryptoflipcars.site/&#39;;
  companies[companyId].adv_price   = 5000000000000000;
  companies[companyId].adv_owner = address1;
}

function setReleaseCompany(uint256 _companyId, bool is_released) public onlyOwner {
  companies[_companyId].is_released = is_released;
}

function InitiateMakes() public onlyOwner {
  require(makesAreInitiated == false);
  addMake("DB5", 0x7396176ac6c1ef05d57180e7733b9188b3571d9a, 98465804768000000 ,0, true);
  addMake("DB6", 0x3130259deedb3052e24fad9d5e1f490cb8cccaa0, 62320129600000000 ,0, true);
  addMake("DB9", 0xa2381223639181689cd6c46d38a1a4884bb6d83c, 39443120000000000 ,0, true);
  addMake("One-77", 0xa2381223639181689cd6c46d38a1a4884bb6d83c, 39443120000000000 ,0, true);
  addMake("BMW 507", 0x049bed1598655b64f09e4835084fbc502ab1ad86, 98465804768000000 ,1, false);
  addMake("BMW Z8", 0xd17e2bfe196470a9fefb567e8f5992214eb42f24, 98465804768000000 ,1, false);
  addMake("Fererrari LaFerrari", 0x7396176ac6c1ef05d57180e7733b9188b3571d9a, 24964000000000000 ,2, true);
  addMake("Ferrari California", 0xa2381223639181689cd6c46d38a1a4884bb6d83c, 15800000000000000 ,2, true);
  addMake("Honda Accord", 0x7396176ac6c1ef05d57180e7733b9188b3571d9a, 24964000000000000 ,3, true);
  addMake("Honda Civic", 0xa2381223639181689cd6c46d38a1a4884bb6d83c, 15800000000000000 ,3, false);
  makesAreInitiated = true;
}

function addMake(string name, address address1, uint256 price, uint256 companyId,  bool is_released) public onlyOwner {
  uint makeId = makes.length++;
  makes[makeId].name = name;
  makes[makeId].curPrice   = price;
  makes[makeId].ownerAddress = address1;
  makes[makeId].companyId   = companyId;
  makes[makeId].is_released   = is_released;
  makes[makeId].adv_text = &#39;Your Ad here&#39;;
  makes[makeId].adv_link = &#39;http://cryptoflipcars.site/&#39;;
  makes[makeId].adv_price   = 5000000000000000;
  makes[makeId].adv_owner = address1;
}



function InitiateCars() public onlyOwner {
  require(carsAreInitiated == false);
  addCar("1964 DB5 James Bond Edition", 0x5c035bb4cb7dacbfee076a5e61aa39a10da2e956, 8100000000000000 ,0, 0, true);
  addCar("Blue 1965" , 0x71f35825a3b1528859dfa1a64b24242bc0d12990, 8100000000000000 ,0, 0, true);
  addCar("1964 DB5 James Bond Edition", 0x71f35825a3b1528859dfa1a64b24242bc0d12990, 8100000000000000 ,0, 0, true);
  addCar("Blue 1965" , 0x71f35825a3b1528859dfa1a64b24242bc0d12990, 8100000000000000 ,0, 0, true);
  addCar("Z8 2003", 0x3177abbe93422c9525652b5d4e1101a248a99776, 10000000000000000 ,1, 5, true);
  addCar("DB6 Chocolate", 0x3177abbe93422c9525652b5d4e1101a248a99776, 10000000000000000 ,0, 1, true);
  addCar("507 Black", 0x3177abbe93422c9525652b5d4e1101a248a99776, 10000000000000000 ,1, 4, true);
  addCar("507 Silver", 0x62d5be95c330b512b35922e347319afd708da981, 16200000000000000 ,1, 4, true);
  addCar("Z8 Black with Red Interior", 0x3177abbe93422c9525652b5d4e1101a248a99776, 10000000000000000 ,1, 5, true);
  addCar("Gordon Ramsey&#39;s Grey LaFerrari", 0x3177abbe93422c9525652b5d4e1101a248a99776, 10000000000000000 ,2, 6, true);
  carsAreInitiated = true;
}

function InitiateWhaleCard() public onlyOwner {
    require(whalecardAreInitiated == false);
    whalecard.ownerAddress = ownerAddress;
    whalecard.curPrice = 100000000000000000;
    whalecardAreInitiated = true;
}

function addCar(string name, address address1, uint256 price, uint256 companyId, uint256 makeId,  bool is_released) public onlyOwner {
  uint carId = cars.length++;
  cars[carId].name = name;
  cars[carId].curPrice   = price;
  cars[carId].ownerAddresses[0] = address1;
  cars[carId].companyId   = companyId;
  cars[carId].makeId   = makeId;
  cars[carId].is_released   = is_released;
  cars[carId].adv_text = &#39;Your Ad here&#39;;
  cars[carId].adv_link = &#39;http://cryptoflipcars.site/&#39;;
  cars[carId].adv_price   = 5000000000000000;
  cars[carId].adv_owner = address1;
}

function setReleaseCar(uint256 _carId, bool is_released) public onlyOwner {
  cars[_carId].is_released = is_released;
}

function setReleaseMake(uint256 _makeId, bool is_released) public onlyOwner {
  makes[_makeId].is_released = is_released;
}
}