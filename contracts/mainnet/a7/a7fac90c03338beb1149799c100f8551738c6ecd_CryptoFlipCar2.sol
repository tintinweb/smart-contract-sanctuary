pragma solidity ^0.4.24;


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


contract Manageable {

  address public owner;
  address public manager;
  bool public contractLock;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ManagerTransferred(address indexed previousManager, address indexed newManager);
  event ContractLockChanged(address admin, bool state);

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
    contractLock = false;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmin() {
    require((msg.sender == manager) || (msg.sender == owner));
    _;
  }

  modifier isUnlocked() {
    require(!contractLock);
    _;
  }

  function transferManager(address newManager) public onlyAdmin {
    require(_addrNotNull(newManager));
    emit ManagerTransferred(manager, newManager);
    manager = newManager;
  }

  function transferOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function setContractLock(bool setting) public onlyAdmin {
    contractLock = setting;
    emit ContractLockChanged(msg.sender, setting);
  }

  function _addrNotNull(address _to) internal pure returns (bool) {
    return(_to != address(0));
  }
}


contract CryptoFlipCar2 is Manageable {
  using SafeMath for uint256;

  uint256 private constant TYPE_CAR = 3;
  uint256 private constant TYPE_MAKE = 2;
  uint256 private constant TYPE_COMPANY = 1;
  uint256 private constant TYPE_WHALE = 0;

  uint256 private constant ADDR_M = (2**160)-1;
  uint256 private constant PRICE_M = (2**96)-1;
  uint256 private constant MAKE_PRICE_M = (2**91)-1;
  uint256 private constant COMPANY_ID_M = (2**5)-1;
  uint256 private constant RACE_ID_M = (2**96)-1;
  uint256 private constant RACE_BET_M = (2**128) - 1;
  uint256 private constant WINNER_M = (2**2)-1;
  uint256 private constant PINKSLIP_M = (2**1)-1;
  uint256 private constant STATE_M = (2**2)-1;

  uint256 private constant ADDR_S = 2**160;
  uint256 private constant MAKE_PRICE_S = 2**165;
  uint256 private constant RACE_ID_S = 2**162;
  uint256 private constant RACE_WINNER_S = 2**128;
  uint256 private constant PINKSLIP_S = 2**130;
  uint256 private constant STATE_S = 2**131;

  uint256 private constant RACE_READY = 0;
  uint256 private constant RACE_OPENED = 1;
  uint256 private constant RACE_FINISHED = 3;

  uint256 private constant AD_PRICE = 5000000000000000;
  uint256 private constant COMPANY_START_PRICE = 0.1 ether;
  uint256 private constant MAKE_START_PRICE = 0.01 ether;
  uint256 private constant CAR_START_PRICE = 0.005 ether;

/********************************************** EVENTS **********************************************/
  event RaceCreated(uint256 raceId, address player1, uint256 cardId, uint256 betAmount);
  event RaceFinished(uint256 raceId, address winner);

  event CardPurchased(uint256 cardType, uint256 cardId, address buyer, address seller, uint256 price);
  event CardTransferred(uint256 cardType, uint256 cardId, address buyer, address seller);
  event AdPurchased(uint256 cardType, uint256 cardId, address buyer, address seller, uint256 price);

  event CarAdded(uint256 id, uint256 makeId);
  event MakeAdded(uint256 id, uint256 companyId);
  event CompanyAdded(uint256 id);
/****************************************************************************************************/

/********************************************** STRUCTS *********************************************/
  struct Advert {
    uint256 data;
    string link;
    string text;
  }
  
  struct Car {
    address[4] owners;
    uint256 price;
    uint256 makeId;
    bool locked;
  }

  struct Race {
    uint256 player1Data;
    uint256 player2Data;
    uint256 metaData;
  }
/****************************************************************************************************/

/*********************************************** VARS ***********************************************/
  uint256 private whaleCard;

  mapping(uint256 => Race) private racesMap;
  mapping(uint256 => uint256) private companiesMap;
  mapping(uint256 => uint256) private makesMap;
  mapping(uint256 => Car) private carsMap;

  mapping(uint256 => mapping(uint256 => Advert)) private adsMap;

  uint256 public carCount;
  uint256 public makeCount;
  uint256 public companyCount;
  uint256 public openRaceCount;
  uint256 public finishedRaceCount;

  uint256 private adCardOwnerCut = 5;
  uint256 private ownerCut = 50;
  uint256 private whaleCut = 5;
  uint256 private devCut = 5;
  uint256 private parentCut = 10;
  uint256 private oldCarCut = 2;
  
  bool private initDone = false;
/****************************************************************************************************/

  function init() public onlyAdmin {
    require(!initDone);
    initDone = true;
    whaleCard = 544244940971561611450182022165966101192029151941515963475380724124;
    
    companiesMap[0] = 865561039198320994090019029559199471223345461753643689577969591538;
    companiesMap[1] = 865561039198320993054179444739682765137514550166591154999543755547;
    companiesMap[2] = 554846819998923714678602910082262521292860787724376787491777411291;
    companiesMap[3] = 355671038460848535541135615183955125321318851275538745891777411291;
    companiesMap[4] = 146150163733090292102777780770905740002982644405466239152731821942;
    companiesMap[5] = 355671038460848535508878910989526070534946658842850550567444902178;
    companiesMap[6] = 146150163733090292102777780770905740002982644405466239152731821942;
    companiesMap[7] = 146150163733090292102777780770905740002982644405466239152731821942;

    companyCount = 8;

    makesMap[0] = 4605053916465184876084057218227438981618782007393731932205532781978;
    makesMap[1] = 2914591086370370174599913075554161534533507828594490006968556374688;
    makesMap[2] = 1844677902766057073279966936236223278229324254247807717511561402428;
    makesMap[3] = 1844677902766057073279966936236223278229324254247807717511561402428;
    makesMap[4] = 4605053916465184876911990996766451400782681524689254663484418928006;
    makesMap[5] = 4605053916465184878081670562508085129910431352928816695390378405668;
    makesMap[6] = 1167517659978517137984061586248765661373868143008706876811221867930;
    makesMap[7] = 738935227834504519292893252751116942230691621264798552983426488380;
    makesMap[8] = 1167517659978517139445563223579668579577552975724989896467154410906;
    makesMap[9] = 738935227834504520754394890082019860434376453981081572639359031356;
    makesMap[10] = 738935227834504523289617387884832456129379376897516570443342499703;
    makesMap[11] = 1167517659978517142247011557709217019077442283260142618443342499703;
    makesMap[12] = 467680523945888942876598267953905513549396800157884357088327079798;

    makeCount = 13;

    carsMap[0] = Car({locked: false, owners:[0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x5C035Bb4Cb7dacbfeE076A5e61AA39a10da2E956, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 13122000000000000, makeId: 0 });  // solhint-disable-line max-line-length
    carsMap[1] = Car({locked: false, owners:[0x7396176Ac6C1ef05d57180e7733b9188B3571d9A, 0x71f35825a3B1528859dFa1A64b24242BC0d12990, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 13122000000000000, makeId: 0 });  // solhint-disable-line max-line-length
    carsMap[2] = Car({locked: false, owners:[0x71f35825a3B1528859dFa1A64b24242BC0d12990, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 0 });   // solhint-disable-line max-line-length
    carsMap[3] = Car({locked: false, owners:[0x65A05c896d9A6f428B3936ac5db8df28752Ccd44, 0x71f35825a3B1528859dFa1A64b24242BC0d12990, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 13122000000000000, makeId: 0 });  // solhint-disable-line max-line-length
    carsMap[4] = Car({locked: false, owners:[0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 10000000000000000, makeId: 5 });  // solhint-disable-line max-line-length
    carsMap[5] = Car({locked: false, owners:[0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 10000000000000000, makeId: 1 });  // solhint-disable-line max-line-length
    carsMap[6] = Car({locked: false, owners:[0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 10000000000000000, makeId: 4 });  // solhint-disable-line max-line-length
    carsMap[7] = Car({locked: false, owners:[0x62D5Be95C330b512b35922E347319afD708dA981, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 16200000000000000, makeId: 4 });  // solhint-disable-line max-line-length
    carsMap[8] = Car({locked: false, owners:[0x3130259deEdb3052E24FAD9d5E1f490CB8CCcaa0, 0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 16200000000000000, makeId: 6 });  // solhint-disable-line max-line-length
    carsMap[9] = Car({locked: false, owners:[0x19fC7935fd9D0BC335b4D0df3bE86eD51aD2E62A, 0x558F42Baf1A9352A955D301Fa644AD0F619B97d9, 0x5e4b61220039823aeF8a54EfBe47773194494f77, 0x7396176Ac6C1ef05d57180e7733b9188B3571d9A], price: 22051440000000000, makeId: 10});  // solhint-disable-line max-line-length
    carsMap[10] = Car({locked: false, owners:[0x504Af27f1Cef15772370b7C04b5D9d593Ee729f5, 0x19fC7935fd9D0BC335b4D0df3bE86eD51aD2E62A, 0x558F42Baf1A9352A955D301Fa644AD0F619B97d9, 0x5e4b61220039823aeF8a54EfBe47773194494f77], price: 37046419200000000, makeId: 11}); // solhint-disable-line max-line-length
    carsMap[11] = Car({locked: false, owners:[0x7396176Ac6C1ef05d57180e7733b9188B3571d9A, 0x5e4b61220039823aeF8a54EfBe47773194494f77, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 4 });  // solhint-disable-line max-line-length
    carsMap[12] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x7396176Ac6C1ef05d57180e7733b9188B3571d9A, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 7 });  // solhint-disable-line max-line-length
    carsMap[13] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x5e4b61220039823aeF8a54EfBe47773194494f77, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 10});  // solhint-disable-line max-line-length
    carsMap[14] = Car({locked: false, owners:[0x504Af27f1Cef15772370b7C04b5D9d593Ee729f5, 0x5e4b61220039823aeF8a54EfBe47773194494f77, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 11});  // solhint-disable-line max-line-length
    carsMap[15] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x5e4b61220039823aeF8a54EfBe47773194494f77, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 8 });  // solhint-disable-line max-line-length
    carsMap[16] = Car({locked: false, owners:[0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x558F42Baf1A9352A955D301Fa644AD0F619B97d9, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 9 });  // solhint-disable-line max-line-length
    carsMap[17] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x558F42Baf1A9352A955D301Fa644AD0F619B97d9, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 2 });  // solhint-disable-line max-line-length
    carsMap[18] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x19fC7935fd9D0BC335b4D0df3bE86eD51aD2E62A, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 3 });  // solhint-disable-line max-line-length
    carsMap[19] = Car({locked: false, owners:[0x308e9C99Ac194101C971FFcAca897AC943843dE8, 0x19fC7935fd9D0BC335b4D0df3bE86eD51aD2E62A, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 6 });  // solhint-disable-line max-line-length
    carsMap[20] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0xE9cfDadEa5FA5475861B62aA7d5dAA493C377122, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 10});  // solhint-disable-line max-line-length
    carsMap[21] = Car({locked: false, owners:[0x308e9C99Ac194101C971FFcAca897AC943843dE8, 0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 0 });  // solhint-disable-line max-line-length
    carsMap[22] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x308e9C99Ac194101C971FFcAca897AC943843dE8, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 12});  // solhint-disable-line max-line-length
    carsMap[23] = Car({locked: false, owners:[0xac2b4B94eCA37Cb7c9cF7062fEfB2792c5792731, 0x263b604509D6a825719859Ee458b2D91fb7d330D, 0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000], price: 13284000000000000, makeId: 12});  //solhint-disable-line max-line-length
    carsMap[24] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x308e9C99Ac194101C971FFcAca897AC943843dE8, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 2 });  // solhint-disable-line max-line-length
    carsMap[25] = Car({locked: false, owners:[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD, 0x504Af27f1Cef15772370b7C04b5D9d593Ee729f5, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 12});  // solhint-disable-line max-line-length
    carsMap[26] = Car({locked: false, owners:[0x9bD750685bF5bfCe24d1B8DE03a1ff3D2631ef5a, 0x3177Abbe93422c9525652b5d4e1101a248A99776, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000], price: 8100000000000000, makeId: 11});  // solhint-disable-line max-line-length
     
    carCount = 27;
  }

/********************************************** RACES ***********************************************/
  function createRace(uint256 _cardId, uint256 _betAmount, uint256 pinkSlip) public payable isUnlocked {
    uint256 excess = msg.value.sub(_betAmount);
    require(_owns(msg.sender, TYPE_CAR, _cardId));
    require(!carsMap[_cardId].locked);
    carsMap[_cardId].locked = true;
    
    racesMap[openRaceCount+finishedRaceCount].player1Data = _packPlayerData(msg.sender, _cardId);
    racesMap[openRaceCount+finishedRaceCount].metaData = _packRaceData(_betAmount, 0, pinkSlip, RACE_OPENED);
    openRaceCount++;

    emit RaceCreated(openRaceCount+finishedRaceCount, msg.sender, _cardId, _betAmount);
    _pay(msg.sender, excess);
  }
  
  function joinRaceAndFinish (uint256 _raceId, uint256 _cardId) public payable isUnlocked {
    require(msg.sender == tx.origin);

    require(_owns(msg.sender, TYPE_CAR, _cardId));
    
    require(!carsMap[_cardId].locked);
    (uint256 bet, bool pinkslip) = _unpackRaceFinishData(racesMap[_raceId].metaData);
    
    require(_raceOpened(racesMap[_raceId].metaData));
    
    openRaceCount--;
    finishedRaceCount++; 
    
    racesMap[_raceId].player2Data = _packPlayerData(msg.sender, _cardId);
    address player1 = address(racesMap[_raceId].player1Data & ADDR_M);

    uint256 winner = _getRNGValue(_raceId);
    address winnerAddr = (winner == 1) ? player1 : msg.sender;

    _transferCar(winnerAddr, racesMap[_raceId].player1Data, pinkslip);
    _transferCar(winnerAddr, racesMap[_raceId].player2Data, pinkslip);

    uint256 devFee = bet.mul(2).mul(devCut) / 100;
    uint256 winnings = bet.mul(2).sub(devFee);
    
    _updateRaceWinner(_raceId, winner);
    emit RaceFinished(_raceId, winnerAddr);
    
    _pay(msg.sender, msg.value.sub(bet));
    _pay(owner, devFee);
    _pay(winnerAddr, winnings);
  }
/****************************************************************************************************/

/******************************************** PURCHASE **********************************************/
  function purchaseAd(uint256 _cardType, uint256 _cardId, string adText, string adLink) public payable isUnlocked {
    
    (address seller, uint256 price) = _unpackItemData(adsMap[_cardType][_cardId].data);
    price = (price == 0) ? AD_PRICE : price;
    seller = (seller == address(0)) ? owner : seller;
    
    uint256 excess = msg.value.sub(price);
    require(_released(_cardType, _cardId));
    require(_cardType != 0);
  
    uint256 totalPerc = 100 + adCardOwnerCut + ownerCut + devCut;
    uint256 newPrice = price.mul(totalPerc) / 100;

    uint256 cardsellerCommission = price.mul(adCardOwnerCut) / totalPerc;
    uint256 devFee = price.mul(devCut) / totalPerc;
    uint256 sellerCommission = price - (cardsellerCommission + devFee);
    uint256 adData = _packItemData(msg.sender, newPrice);

    adsMap[_cardType][_cardId] = Advert({text: adText, link: adLink, data: adData});
    
    emit AdPurchased(_cardType, _cardId, msg.sender, seller, price);

    _pay(ownerOf(_cardType, _cardId), cardsellerCommission);
    _pay(owner, devFee);
    _pay(seller, sellerCommission);
    _pay(msg.sender, excess);
  }

  function purchaseCard(uint256 _cardType, uint256 _cardId) public payable isUnlocked {
    if ( _cardType == TYPE_WHALE) {
      _purchaseWhaleCard();
    } else if (_cardType == TYPE_COMPANY) {
      _purchaseCompany(_cardId);
    } else if (_cardType == TYPE_MAKE) {
      _purchaseMake(_cardId);
    } else if (_cardType == TYPE_CAR) {
      _purchaseCar(_cardId);
    }
  }
/****************************************************************************************************/

/********************************************* GETTERS **********************************************/
  function getWhaleCard() public view returns (address _owner, uint256 _price) {
    (_owner, _price) = _unpackItemData(whaleCard);
  }

  function getCompany(uint256 _companyId) public view returns(address _owner, uint256 _price) {
    (_owner, _price) = _unpackItemData(companiesMap[_companyId]);
  }

  function getMake(uint256 _makeId) public view returns(address _owner, uint256 _price, uint256 _companyId) {
    (_owner, _companyId, _price) = _unpackMakeData(makesMap[_makeId]);
  }
  
  function getCar(uint256 _carId) public view returns (address[4] owners, uint256 price, uint256 makeId) {
    Car memory _car = carsMap[_carId];
    owners = _car.owners;
    price = _car.price;
    makeId = _car.makeId;
  }
  
  function getRace(uint256 _raceId) public view returns(uint256 _p1Data, uint256 _p2Data, uint256 _raceMetaData) {
    Race memory _race = racesMap[_raceId];
    _p1Data = _race.player1Data;
    _p2Data = _race.player2Data;
    _raceMetaData = _race.metaData;
  }
  
  function getFullRace(uint256 _raceId) public view returns(
    address p1, uint256 p1Id,
    address p2, uint256 p2Id,
    uint256 bet, uint256 winner, bool pinkslip, uint256 state) {
    Race memory _race = racesMap[_raceId];
    (p1, p1Id) = _unpackPlayerData(_race.player1Data);
    (p2, p2Id) = _unpackPlayerData(_race.player2Data);
    (bet, winner, pinkslip, state) = _unpackRaceData(_race.metaData);
  }

  function getAd(uint256 _cardType, uint256 _cardId) public view returns(string text, string link, address seller, uint256 price) {
    Advert memory ad = adsMap[_cardType][_cardId];
    (seller, price) = _unpackItemData(ad.data);
    price = (price == 0) ? AD_PRICE : price;
    seller = (seller == address(0)) ? owner : seller;
    text = ad.text;
    link = ad.link;
  }
  
  function getCuts() public view returns(uint256[6] cuts) {
    cuts = [adCardOwnerCut, ownerCut, whaleCut, devCut, parentCut, oldCarCut];
  }

  function ownerOf(uint256 cardType, uint256 cardId) public view returns(address cardOwner) {
    if (cardType == TYPE_WHALE) {
      cardOwner = address(whaleCard & ADDR_M);
    } else if (cardType == TYPE_COMPANY) {
      cardOwner = address(companiesMap[cardId] & ADDR_M);
    } else if (cardType == TYPE_MAKE) {
      cardOwner = address(makesMap[cardId] & ADDR_M);
    } else if (cardType == TYPE_CAR) {
      cardOwner = carsMap[cardId].owners[0];
    }
  }
/****************************************************************************************************/

/********************************************* RELEASE **********************************************/   
  function transferCard(address _newOwner, uint256 _cardType, uint256 _cardId) public onlyAdmin {
    _transferCard(_newOwner, _cardType, _cardId);
  }
/****************************************************************************************************/

/******************************************** ADD CARDS *********************************************/
  function addCompany() public onlyAdmin {
    companiesMap[companyCount] = _packItemData(owner, COMPANY_START_PRICE);
    emit CompanyAdded(companyCount++);
  }

  function addMake(uint256 _companyId) public onlyAdmin {
    makesMap[makeCount] = _packMakeData(owner, MAKE_START_PRICE, _companyId);
    emit MakeAdded(makeCount++, _companyId);
  }
  
  function addCar(uint256 _makeId) public onlyAdmin {
    carsMap[carCount] = Car({price: CAR_START_PRICE, owners: [owner, address(0), address(0), address(0)], makeId: _makeId, locked : false});
    emit CarAdded(carCount++, _makeId);
  }
  
  function addAd(address _ownerAddr, uint256 _price, uint256 _cardType, uint256 _cardId, string _text, string _link) public onlyAdmin {
    require(_addrNotNull(_ownerAddr) && (_price != 0));
    uint256 _data = _packItemData(_ownerAddr, _price);
    adsMap[_cardType][_cardId] = Advert({text: _text, link: _link, data: _data});
  }
  
  function editCuts(uint256[6] cuts) public onlyAdmin {
    adCardOwnerCut = (cuts[0] == 0) ? adCardOwnerCut : cuts[0];
    ownerCut = (cuts[1] == 0) ? ownerCut : cuts[1];
    whaleCut = (cuts[2] == 0) ? whaleCut : cuts[2];
    devCut = (cuts[3] == 0) ? devCut : cuts[3];
    parentCut = (cuts[4] == 0) ? parentCut : cuts[4];
    oldCarCut = (cuts[5] == 0) ? oldCarCut : cuts[5];
  }
/****************************************************************************************************/

/********************************************* PRIVATE **********************************************/

  function _editPriceOf(uint256 cardType, uint256 cardId, uint256 _newPrice) private {
    if (cardType == TYPE_WHALE) {
      whaleCard = (~(PRICE_M*ADDR_S) & whaleCard) | ((_newPrice & PRICE_M) * ADDR_S);
    } else if (cardType == TYPE_COMPANY) {
      companiesMap[cardId] = (~(PRICE_M*ADDR_S) & companiesMap[cardId]) | ((_newPrice & PRICE_M) * ADDR_S);
    } else if (cardType == TYPE_MAKE) {
      makesMap[cardId] = (~(MAKE_PRICE_M*MAKE_PRICE_S) & makesMap[cardId]) | ((_newPrice & MAKE_PRICE_M) * MAKE_PRICE_S);
    } else if (cardType == TYPE_CAR) {
      carsMap[cardId].price = _newPrice;
    }
  }

  function _priceOf(uint256 cardType, uint256 cardId) private view returns(uint256 _price) {
    if (cardType == TYPE_WHALE) {
      _price = (PRICE_M & (whaleCard / ADDR_S));
    } else if (cardType == TYPE_COMPANY) {
      _price = (PRICE_M & (companiesMap[cardId] / ADDR_S));
    } else if (cardType == TYPE_MAKE) {
      _price = (MAKE_PRICE_M & (makesMap[cardId] / MAKE_PRICE_S));
    } else if (cardType == TYPE_CAR) {
      _price = carsMap[cardId].price;
    }
  }

  function _owns(address _owner, uint256 cardType, uint256 cardId) private view returns(bool) {
    address _toCheck = ownerOf(cardType, cardId);
    return(_owner == _toCheck);
  }

  function _released(uint256 cardType, uint256 cardId) private view returns(bool) {
    return(_addrNotNull(ownerOf(cardType, cardId)));
  }
  
  function _transferCard(address newOwner, uint256 cardType, uint256 cardId) private returns (bool) {   
    require(_released(cardType, cardId));
    address seller = ownerOf(cardType, cardId);
    if ( newOwner == seller) {
    } else if (cardType == TYPE_WHALE) {
      whaleCard = (~(ADDR_M) & whaleCard) | (uint256(newOwner) & ADDR_M);
    } else if (cardType == TYPE_COMPANY) {
      companiesMap[cardId] = (~(ADDR_M) & companiesMap[cardId]) | (uint256(newOwner) & ADDR_M);
    } else if (cardType == TYPE_MAKE) {
      makesMap[cardId] = (~(ADDR_M) & makesMap[cardId]) | (uint256(newOwner) & ADDR_M);
    } else if (cardType == TYPE_CAR) {
      carsMap[cardId].owners[3] = carsMap[cardId].owners[2];
      carsMap[cardId].owners[2] = carsMap[cardId].owners[1];    
      carsMap[cardId].owners[1] = carsMap[cardId].owners[0];
      carsMap[cardId].owners[0] = newOwner;
    }
    emit CardTransferred(cardType, cardId, newOwner, seller);
  }

  function _pay(address _to, uint256 _value) private {
    if ( _addrNotNull(_to) && _value != 0) {
      _to.transfer(_value);
    }
  }

  function _transferCar(address newOwner, uint256 _data, bool pinkslip) private returns (bool) {
    uint256 id = _getRacerCar(_data);
    carsMap[id].locked = false;
    if ( pinkslip) {
      _transferCard(newOwner, TYPE_CAR, id);
    }
  }    

  function _oldOwnersOf(uint256 _carId) private view returns(uint256) {
    Car memory _car = carsMap[_carId];
    uint256 count = _addrNotNull(_car.owners[1]) ? 1 : 0;
    count += (_addrNotNull(_car.owners[2]) ? 1 : 0);
    count += (_addrNotNull(_car.owners[3]) ? 1 : 0);
    return(count);
  }

  function _packItemData(address itemOwner, uint256 price) public pure returns(uint256) {
    uint256 _data = (~(ADDR_M) & _data) | (uint256(itemOwner) & ADDR_M);
    _data = (~(PRICE_M*ADDR_S) & _data) | ((price & PRICE_M) * ADDR_S);
    return(_data);
  }
  
  function _unpackItemData(uint256 _data) private pure returns(address itemOwner, uint256 price) {
    itemOwner = address(_data & ADDR_M);
    price = PRICE_M & (_data / ADDR_S);
  }

  function _packMakeData(address makeOwner, uint256 price, uint256 companyId) private pure returns(uint256 _data) {
    _data = (~(ADDR_M) & _data) | (uint256(makeOwner) & ADDR_M);
    _data = (~(COMPANY_ID_M*ADDR_S) & _data) | ((companyId & COMPANY_ID_M) * ADDR_S);
    _data = (~(MAKE_PRICE_M*MAKE_PRICE_S) & _data) | ((price & MAKE_PRICE_M) * MAKE_PRICE_S);
  }

  function _unpackMakeData(uint256 _data) private pure returns(address makeOwner, uint256 companyId, uint256 price) {
    makeOwner = address(_data & ADDR_M);
    companyId = COMPANY_ID_M & (_data / ADDR_S);
    price = (MAKE_PRICE_M & (_data / MAKE_PRICE_S));
  }

  function _purchaseCar(uint256 _cardId) private {
    Car memory car = carsMap[_cardId];
    require(!car.locked);

    uint256 excess = msg.value.sub(car.price);

    require(msg.sender != car.owners[0]);

    uint256 totalPerc = 100 + ownerCut + devCut + whaleCut + (2 * parentCut) + (oldCarCut * _oldOwnersOf(_cardId));
    
    uint256 parentFee = car.price.mul(parentCut) / totalPerc;    
    uint256 oldCarFee = car.price.mul(oldCarCut) / totalPerc;  
    uint256 whaleFee = car.price.mul(whaleCut) / totalPerc;  
    uint256 devFee = car.price.mul(devCut) / totalPerc;
    
    uint256 sellerCommission = car.price - ((oldCarFee * _oldOwnersOf(_cardId)) + (2 * parentFee) + devFee + whaleFee);

    uint256 companyId = COMPANY_ID_M & (makesMap[car.makeId] / ADDR_S);

    emit CardPurchased(TYPE_CAR, _cardId, msg.sender, car.owners[0], car.price);

    _transferCard(msg.sender, TYPE_CAR, _cardId);
    _editPriceOf(TYPE_CAR, _cardId, car.price.mul(totalPerc) / 100);
     
    _pay(ownerOf(TYPE_COMPANY, companyId), parentFee);
    _pay(ownerOf(TYPE_MAKE, car.makeId), parentFee);

    _pay(car.owners[0], sellerCommission);
    _pay(car.owners[1], oldCarFee);
    _pay(car.owners[2], oldCarFee);
    _pay(car.owners[3], oldCarFee);
    
    _pay(ownerOf(0, 0), whaleFee);
    _pay(owner, devFee);
    _pay(msg.sender, excess);
  }

  function _purchaseMake(uint256 _cardId) private isUnlocked {
    (address seller, uint256 price, uint256 companyId) = getMake(_cardId);
    uint256 excess = msg.value.sub(price);

    require(msg.sender != seller);
    
    uint256 totalPerc = 100 + ownerCut + devCut + parentCut + whaleCut;
    
    uint256 parentFee = price.mul(parentCut) / totalPerc;
    uint256 whaleFee = price.mul(whaleCut) / totalPerc;
    uint256 devFee = price.mul(devCut) / totalPerc;

    uint256 newPrice = price.mul(totalPerc) / 100;
  
    uint256 sellerCommission = price - (parentFee+whaleFee+devFee);
    
    _transferCard(msg.sender, 2, _cardId);
    _editPriceOf(2, _cardId, newPrice);
    
    emit CardPurchased(2, _cardId, msg.sender, seller, price);

    _pay(ownerOf(TYPE_WHALE, 0), whaleFee);
    _pay(ownerOf(TYPE_COMPANY, companyId), parentFee);     
    _pay(owner, devFee);
    _pay(seller, sellerCommission);
    _pay(msg.sender, excess);
  }

  function _purchaseCompany(uint256 _cardId) private isUnlocked {
    (address seller, uint256 price) = getCompany(_cardId);
    uint256 excess = msg.value.sub(price);

    require(msg.sender != seller);

    uint256 totalPerc = 100+ownerCut+devCut+whaleCut;
    uint256 newPrice = price.mul(totalPerc) / 100;
    
    _transferCard(msg.sender, 1, _cardId);
    _editPriceOf(1, _cardId, newPrice);
    
    uint256 whaleFee = price.mul(whaleCut) / totalPerc;
    uint256 devFee = price.mul(devCut) / totalPerc;
    uint256 sellerCommission = price - (whaleFee + devFee);
    
    emit CardPurchased(1, _cardId, msg.sender, seller, price);
    
    _pay(ownerOf(0,0), whaleFee);
    _pay(owner, devFee);
    _pay(seller,sellerCommission);
    _pay(msg.sender, excess);
  }

  function _purchaseWhaleCard() private isUnlocked {
    (address seller, uint256 price) = getWhaleCard();
    uint256 excess = msg.value.sub(price);
    
    require(msg.sender != seller);

    uint256 totalPerc = 100 + ownerCut + devCut;
    uint256 devFee = price.mul(devCut) / totalPerc;

    uint256 sellerCommission = price - devFee;
    uint256 newPrice = price.mul(totalPerc) / 100;

    _transferCard(msg.sender, TYPE_WHALE, TYPE_WHALE);
    _editPriceOf(TYPE_WHALE, TYPE_WHALE, newPrice);
    
    emit CardPurchased(TYPE_WHALE, TYPE_WHALE, msg.sender, seller, price);
      
    _pay(owner, devFee);
    _pay(seller, sellerCommission);
    _pay(msg.sender, excess);
  }
/****************************************************************************************************/

/****************************************** PRIVATE RACE ********************************************/
  function _packPlayerData(address player, uint256 id) private pure returns(uint256 playerData) {
    playerData = (~(ADDR_M) & playerData) | (uint256(player) & ADDR_M);
    playerData = (~(RACE_ID_M*ADDR_S) & playerData) | ((id & RACE_ID_M) * ADDR_S);
  }

  function _unpackPlayerData(uint256 playerData) private pure returns(address player, uint256 id) {
    player = address(playerData & ADDR_M);
    id = (RACE_ID_M & (playerData / ADDR_S));
  }

  function _packRaceData(uint256 _bet, uint256 _winner, uint256 _pinkslip, uint256 _state) private pure returns(uint256 _raceData) {
    _raceData = (~(RACE_BET_M) & _raceData) | (_bet & RACE_BET_M);
    _raceData = (~(WINNER_M*RACE_WINNER_S) & _raceData) | ((_winner & WINNER_M) * RACE_WINNER_S);
    _raceData = (~(PINKSLIP_M*PINKSLIP_S) & _raceData) | ((_pinkslip & PINKSLIP_M) * PINKSLIP_S);
    _raceData = (~(STATE_M*STATE_S) & _raceData) | ((_state & STATE_M) * STATE_S);
  }

  function _unpackRaceData(uint256 _raceData) private pure returns(uint256 bet, uint256 winner, bool pinkslip, uint256 state) {
    bet = _raceData & RACE_BET_M;
    winner = (WINNER_M & (_raceData / RACE_WINNER_S));
    pinkslip = (PINKSLIP_M & (_raceData / PINKSLIP_S)) != 0;
    state = (STATE_M & (_raceData / STATE_S));
  }
  
  function _unpackRaceFinishData(uint256 _raceData) private pure returns(uint256 bet, bool pinkslip) {
    bet = _raceData & RACE_BET_M;
    pinkslip = (PINKSLIP_M & (_raceData / PINKSLIP_S)) != 0;
  }
  
  function _updateRaceWinner(uint256 raceId, uint256 winner) private {
    racesMap[raceId].metaData = (~(STATE_M*STATE_S) & racesMap[raceId].metaData) | ((RACE_FINISHED & STATE_M) * STATE_S);
    racesMap[raceId].metaData = (~(WINNER_M*RACE_WINNER_S) & racesMap[raceId].metaData) | ((winner & WINNER_M) * RACE_WINNER_S);
  }

  function _raceOpened(uint256 raceData) private pure returns (bool opened) {
    uint256 state = (STATE_M & (raceData / STATE_S));
    opened = ((state == RACE_OPENED));
  }

  function _getRacerCar(uint256 playerData) private pure returns (uint256 id) {
    id = (RACE_ID_M & (playerData / ADDR_S));
  }

  function _getRNGValue(uint256 id) private view returns(uint256 winner) {
    Race memory race = racesMap[id];
    uint256 p1Price = _priceOf(TYPE_CAR, _getRacerCar(race.player1Data));
    uint256 p2Price = _priceOf(TYPE_CAR, _getRacerCar(race.player2Data));
    uint256 _totalValue = p1Price.add(p2Price); 
    
    uint256 blockToCheck = block.number - 1;
    uint256 weight = (p1Price.mul(2) < _totalValue) ? _totalValue/2 : p1Price;
    //uint256 ratio = ((2**256)-1)/_totalValue;
    uint256 ratio = 115792089237316195423570985008687907853269984665640564039457584007913129639935/_totalValue;
    bytes32 blockHash = blockhash(blockToCheck);
    winner = (uint256(keccak256(abi.encodePacked(blockHash))) > weight*ratio) ? 2 : 1;
  }
/****************************************************************************************************/
}