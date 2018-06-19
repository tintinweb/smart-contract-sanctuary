pragma solidity ^0.4.18;

contract CryptoflipCar {

address ownerAddress = 0x3177Abbe93422c9525652b5d4e1101a248A99776;
address foundTeamAddress = 0x30A38029bEd78159B0342FF9722C3B56479328D8;

struct WhaleCard {
   address ownerAddress;
   uint256 curPrice;
}

struct Company {
string name;
address ownerAddress;
uint256 curPrice;
bool is_released;
}

struct Make {
string name;
address ownerAddress;
uint256 curPrice;
uint256 companyId;
bool is_released;
}

struct Car {
string name;
address[] ownerAddresses;
uint256 curPrice;
uint256 companyId;
uint256 makeId;
bool is_released;
}

struct Adv {
string text;
string link;
uint256 card_type;  /* 0: company 1: makes 2: car*/
uint256 curPrice;
address ownerAddress;
uint256 cardId;
}

Company[] companies;
Make[] makes;
Car[] cars;
Adv[] advs;
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

function purchaseAdv(uint256 _cardType, uint256 _cardId, string _text, string _link) public payable {
  require(msg.value >= advs[_advId].curPrice);
  require(isPaused == false);
  uint256 _advId;
  bool is_adv = false;
  for (uint i=0; i < advs.length; i++) {
    if (advs[i].card_type == _cardType && advs[i].cardId == _cardId){
        _advId = i;
        is_adv = true;
    }
  }    
  require(is_adv == true);
  uint256 totalpercent = 160;

  uint256 commission5percent = (msg.value * 5 / totalpercent);
  foundTeamAddress.transfer(commission5percent);

  uint256 commissionOwner = msg.value - commission5percent;
    
  if (advs[_advId].card_type == 0){
    companies[advs[_advId].cardId].ownerAddress.transfer(commission5percent);
    commissionOwner = commissionOwner - commission5percent;
  } else if (advs[_advId].card_type == 1) {
    makes[advs[_advId].cardId].ownerAddress.transfer(commission5percent);
    commissionOwner = commissionOwner - commission5percent;
  } else if (advs[_advId].card_type == 2) {
    makes[advs[_advId].cardId].ownerAddress.transfer(commission5percent);
    commissionOwner = commissionOwner - commission5percent;
  }

  advs[_advId].ownerAddress.transfer(commissionOwner);
  advs[_advId].ownerAddress = msg.sender;
  advs[_advId].curPrice = div(mul(advs[_advId].curPrice, totalpercent), 100);
  advs[_advId].text = _text;
  advs[_advId].link = _link;  
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

function purchaseCard(uint256 _cardType, uint256 _cardId) public payable {
  require(isPaused == false);   
  uint256 totalpercent = 150;
  uint256 ownercount = 0;
  if (_cardType == 0){
      require(companies[_cardId].is_released == true);
      require(msg.value >= companies[_cardId].curPrice);
      totalpercent = totalpercent + 5;
  } else if (_cardType == 1) {
      require(makes[_cardId].is_released == true);
      require(msg.value >= makes[_cardId].curPrice);      
      totalpercent = totalpercent + 5 + 2;
  } else if (_cardType == 2) {
      require(cars[_cardId].is_released == true);
      require(msg.value >= cars[_cardId].curPrice);            
      uint256 len = cars[_cardId].ownerAddresses.length;
      ownercount = 1;
      if (cars[_cardId].ownerAddresses.length > 4){
        ownercount = 3;
      } else {
        ownercount = len-1;
      }
      totalpercent = 150 + 5 + 2 + 2 + mul(ownercount, 2);
  }

  uint256 commissionOwner = msg.value;
  uint256 commission1percent = div(mul(msg.value, 1) , totalpercent);  
  if (whalecardAreInitiated == true){
    totalpercent = totalpercent + 1;

    whalecard.ownerAddress.transfer(commission1percent);
    commissionOwner = commissionOwner - commission1percent;    
  }
  
  uint256 commission5percent = mul(commission1percent, 5);
  foundTeamAddress.transfer(commission5percent);

  commissionOwner = commissionOwner - commission5percent;
  uint256 commission2percent = mul(commission1percent, 2);

  if (_cardType == 0){
    companies[_cardId].ownerAddress.transfer(commissionOwner);
    companies[_cardId].ownerAddress = msg.sender;
    companies[_cardId].curPrice = div(mul(companies[_cardId].curPrice, totalpercent), 100);
  } else if (_cardType == 1) {
    uint256 companyId = makes[_cardId].companyId;
    companies[companyId].ownerAddress.transfer(commission2percent);
    commissionOwner = commissionOwner - commission5percent;
    makes[_cardId].ownerAddress.transfer(commissionOwner);
    makes[_cardId].ownerAddress = msg.sender;
    makes[_cardId].curPrice = div(mul(makes[_cardId].curPrice, totalpercent), 100);
  } else if (_cardType == 2){
    companyId = makes[_cardId].companyId;
    companies[companyId].ownerAddress.transfer(commission2percent);
    commissionOwner = commissionOwner - commission2percent;
    
    uint256 makeId = cars[_cardId].makeId;

    makes[makeId].ownerAddress.transfer(commission2percent);
    commissionOwner = commissionOwner - commission2percent;

    if (len > 1){
        for (uint i=len-2; i>=0; i--) {
            if (i > len-5){
                cars[_cardId].ownerAddresses[i].transfer(commission2percent);
                commissionOwner = commissionOwner - commission2percent;
            }
        }
    }

    cars[_cardId].ownerAddresses[len-1].transfer(commissionOwner);
    cars[_cardId].ownerAddresses.push(msg.sender);
    if (ownercount < 3) totalpercent = totalpercent + 2;
    cars[_cardId].curPrice = div(mul(cars[_cardId].curPrice, totalpercent), 100);
  }
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
uint id
) {
  Company storage _company = companies[_companyId];
  name = _company.name;
  ownerAddress1 = _company.ownerAddress;
  curPrice = _company.curPrice;
  is_released = _company.is_released;
  id = _companyId;
}

function getMake(uint _makeId) public view returns (
string name,
address ownerAddress1,
uint256 curPrice,
uint256 companyId,
bool is_released,
uint id
) {
  Make storage _make = makes[_makeId];
  name = _make.name;
  ownerAddress1 = _make.ownerAddress;
  curPrice = _make.curPrice;
  companyId = _make.companyId;
  is_released = _make.is_released;
  id = _makeId;
}

function getCar(uint _carId) public view returns (
string name,
address[] ownerAddresses,
uint256 curPrice,
uint256 companyId,
uint256 makeId,
bool is_released,
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
}


function getAdv(uint _cardType, uint _cardId) public view returns (
string text,
string link,
uint256 card_type,
address ownerAddress1,
uint256 curPrice,
uint256 cardId
) {
  Adv storage _adv = advs[0];
  for (uint i=0; i < advs.length; i++) {
    if (advs[i].card_type == _cardType && advs[i].cardId == _cardId){
        _adv = advs[i];
    }
  }
  text = _adv.text;
  link = _adv.link;
  ownerAddress1 = _adv.ownerAddress;
  curPrice = _adv.curPrice;
  cardId = _adv.cardId;
  card_type = _adv.card_type;
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
  addCompany(&#39;Aston Martin&#39;,ownerAddress, 100000000000000000);
  addCompany(&#39;BMW&#39;,ownerAddress, 100000000000000000);
  addCompany(&#39;Ferrari&#39;,ownerAddress, 100000000000000000);
  addCompany(&#39;Honda&#39;,ownerAddress, 100000000000000000);
  companiesAreInitiated = true;
}

function addCompany(string name, address address1, uint256 price) public onlyOwner {
  uint companyId = companies.length++;
  companies[companyId].name = name;
  companies[companyId].curPrice   = price;
  companies[companyId].ownerAddress = address1;
  companies[companyId].is_released   = true;

  uint advId = advs.length++;
  advs[advId].text = &#39;Your Ad here&#39;;
  advs[advId].link = &#39;http://cryptoflipcars.site/&#39;;
  advs[advId].curPrice   = 5000000000000000;
  advs[advId].card_type   = 0;
  advs[advId].ownerAddress = address1;
  advs[advId].cardId = companyId;
}

function setReleaseCompany(uint256 _companyId, bool is_released) public onlyOwner {
  companies[_companyId].is_released = is_released;
}

function InitiateMakes() public onlyOwner {
  require(makesAreInitiated == false);
  addMake(&#39;DB5&#39;,ownerAddress,0,10000000000000000);
  addMake(&#39;DB6&#39;,ownerAddress,0,10000000000000000);
  addMake(&#39;DB9&#39;,ownerAddress,0,10000000000000000);
  addMake(&#39;One-77&#39;,ownerAddress,0,10000000000000000);
  makesAreInitiated = true;
}

function addMake(string name, address address1, uint256 companyId, uint256 price) public onlyOwner {
  uint makeId = makes.length++;
  makes[makeId].name = name;
  makes[makeId].curPrice   = price;
  makes[makeId].ownerAddress = address1;
  makes[makeId].companyId   = companyId;
  makes[makeId].is_released   = true;

  uint advId = advs.length++;
  advs[advId].text = &#39;Your Ad here&#39;;
  advs[advId].link = &#39;http://cryptoflipcars.site/&#39;;
  advs[advId].curPrice   = 5000000000000000;
  advs[advId].card_type   = 1;
  advs[advId].ownerAddress = address1;
  advs[advId].cardId = makeId;
}



function InitiateCars() public onlyOwner {
  require(carsAreInitiated == false);
  addCar(&#39;1964 DB5 James Bond Edition&#39;,ownerAddress, 0, 0, 5000000000000000);
  addCar(&#39;Blue 1965 &#39;,ownerAddress, 0, 0, 5000000000000000);
  addCar(&#39;1964 DB5 James Bond Edition&#39;,ownerAddress,0,0,5000000000000000);
  addCar(&#39;Blue 1965 &#39;,ownerAddress,0,0,5000000000000000);
  carsAreInitiated = true;
}

function InitiateWhaleCard() public onlyOwner {
    require(whalecardAreInitiated == false);
    whalecard.ownerAddress = ownerAddress;
    whalecard.curPrice = 100000000000000000;
    whalecardAreInitiated = true;
}

function addCar(string name, address address1, uint256 companyId, uint256 makeId, uint256 price ) public onlyOwner {
  uint carId = cars.length++;
  cars[carId].name = name;
  cars[carId].curPrice   = price;
  cars[carId].ownerAddresses.push(address1);
  cars[carId].companyId   = companyId;
  cars[carId].makeId   = makeId;
  cars[carId].is_released   = true;

  uint advId = advs.length++;
  advs[advId].text = &#39;Your Ad here&#39;;
  advs[advId].link = &#39;http://cryptoflipcars.site/&#39;;
  advs[advId].curPrice   = 5000000000000000;
  advs[advId].card_type   = 2;
  advs[advId].ownerAddress = address1;
  advs[advId].cardId = carId;
}

function setReleaseCar(uint256 _carId, bool is_released) public onlyOwner {
  cars[_carId].is_released = is_released;
}

function setReleaseMake(uint256 _makeId, bool is_released) public onlyOwner {
  makes[_makeId].is_released = is_released;
}
}