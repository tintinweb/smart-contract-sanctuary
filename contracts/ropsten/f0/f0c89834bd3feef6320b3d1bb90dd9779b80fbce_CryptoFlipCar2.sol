pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
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

    uint256 private TYPE_CAR = 3;
    uint256 private TYPE_MAKE = 2;
    uint256 private TYPE_COMPANY = 1;
    uint256 private TYPE_WHALE = 0;

    uint256 private ADDR_M = (2**160)-1;
    uint256 private PRICE_M = (2**96)-1;
    uint256 private MAKE_PRICE_M = (2**91)-1;
    uint256 private COMPANY_ID_M = (2**5)-1;
    uint256 private RACE_ID_M = (2**96)-1;
    
    uint256 private RACE_BET_M = (2**128) - 1;
    uint256 private WINNER_M = (2**2)-1;
    uint256 private PINKSLIP_M = (2**1)-1;
    uint256 private STATE_M = (2**2)-1;


    uint256 private ADDR_S = 2**160;
    uint256 private MAKE_PRICE_S = 2**165;
    uint256 private RACE_ID_S = 2**162;
    
    uint256 private RACE_WINNER_S = 2**128;
    uint256 private PINKSLIP_S = 2**130;
    uint256 private STATE_S = 2**131;

    uint256 private RACE_READY = 0;
    uint256 private RACE_OPENED = 1;
    uint256 private RACE_FINISHED = 3;

    uint256 private AD_PRICE = 5000000000000000;

    address private nullAddr = address(0);

/********************************************** EVENTS **********************************************/

    event RaceCreated(uint256 raceId, address player1, uint256 cardId, uint256 betAmount);
    event RaceFinished(uint256 raceId, address winner);

    event CardPurchased(uint256 cardType, uint256 cardId, address buyer, address seller, uint256 price);
    event CardTransferred(uint256 cardType, uint256 cardId, address buyer, address seller);
    event AdPurchased(uint256 cardType, uint256 cardId, address buyer, address seller, uint256 price);

    event CarAdded(uint256 id, address owner, uint256 price, uint256 makeId);
    event MakeAdded(uint256 id, address owner, uint256 price, uint256 companyId);
    event CompanyAdded(uint256 id, address owner, uint256 price);

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

    struct Race{
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

/****************************************************************************************************/

    constructor() public {
        whaleCard = 544244940971561611450182022165966101192029151941515963475380724124;
    }

/********************************************** RACES ***********************************************/

    function createRace(uint256 _cardId, uint256 _betAmount, uint256 pinkSlip) public payable isUnlocked {
        uint256 excess = msg.value.sub(_betAmount);
        require(_owns(msg.sender, TYPE_CAR, _cardId));
        require(!carsMap[_cardId].locked);
        carsMap[_cardId].locked = true;
        
        racesMap[openRaceCount+finishedRaceCount].player1Data = _packPlayerData(msg.sender, _cardId);
        racesMap[openRaceCount+finishedRaceCount].metaData = _packRaceData(_betAmount, 0, pinkSlip, RACE_OPENED);

        emit RaceCreated(openRaceCount++, msg.sender, _cardId, _betAmount);
        _pay(msg.sender, excess);
    }

    function joinRaceAndFinish (uint256 _raceId, uint256 _cardId) public payable isUnlocked {
        require(msg.sender == tx.origin);  //solium-disable-line

        require(_owns(msg.sender, TYPE_CAR, _cardId));
        
        require(!carsMap[_cardId].locked);
        
        Race memory _race = racesMap[_raceId];
        (uint256 bet, bool pinkslip) = _unpackRaceFinishData(_race.metaData);
        
        require(_raceOpened(_race.metaData));
        
        openRaceCount--;
        finishedRaceCount++; 
        
        racesMap[_raceId].player2Data = _packPlayerData(msg.sender, _cardId);
        address player1 = address(_race.player1Data & ADDR_M);

        uint256 winner = _getRNGValue(_raceId);
        address winnerAddr = (winner == 1) ? player1 : msg.sender;

        if (pinkslip) {
            _transferCar(winnerAddr, _race.player1Data);
            _transferCar(winnerAddr, _race.player2Data);
        }

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
        seller = (seller == nullAddr) ? owner : seller;
        
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
        if(_cardType == TYPE_WHALE) {
            _purchaseWhaleCard();
        } else if(_cardType == TYPE_COMPANY) {
            _purchaseCompany(_cardId);
        } else if(_cardType == TYPE_MAKE) {
            _purchaseMake(_cardId);
        } else if(_cardType == TYPE_CAR) {
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
        seller = (seller == nullAddr) ? owner : seller;
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
    
    function addCompany(address _ownerAddr, uint256 _price) public onlyAdmin {
        require(_addrNotNull(_ownerAddr) && (_price != 0));
        companiesMap[companyCount] = _packItemData(_ownerAddr, _price);
        emit CompanyAdded(companyCount++, _ownerAddr, _price);
    }

    function bulkAddCompany(address[] _ownerAddrs, uint256[] _prices) public onlyAdmin {
        uint256 ownerCount = _ownerAddrs.length;
        require(ownerCount == _prices.length);
        for(uint256 i = 0; i < ownerCount; i++) {
            if(_addrNotNull(_ownerAddrs[i])) {
                addCompany(_ownerAddrs[i], _prices[i]);
            }
        }
    }
    
    function bulkAddMake(address[] _ownerAddrs, uint256[] _prices, uint256[] _companyIds) public onlyAdmin {
        uint256 ownerCount = _ownerAddrs.length;
        require(ownerCount == _prices.length);
        require(ownerCount == _companyIds.length);
        for(uint256 i = 0; i < ownerCount; i++) {
            addMake(_ownerAddrs[i], _prices[i], _companyIds[i]);
        }
    }

    function addMake(address _ownerAddr, uint256 _price, uint256 _companyId) public onlyAdmin {
        require(_addrNotNull(_ownerAddr) && (_price != 0));
        makesMap[makeCount] = _packMakeData(_ownerAddr, _price, _companyId);
        emit MakeAdded(makeCount++, _ownerAddr, _price, _companyId);
    }
    
    function addCar(address[4] _ownerAddrs, uint256 _price, uint256 _makeId) public onlyAdmin {
        require(_addrNotNull(_ownerAddrs[0]) && (_price != 0));
        carsMap[carCount] = Car({price: _price, owners: _ownerAddrs, makeId: _makeId, locked : false});
        emit CarAdded(carCount++, _ownerAddrs[0], _price, _makeId);
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
        if(newOwner == seller) {
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
        if(_addrNotNull(_to) && _value != 0) {
            _to.transfer(_value);
        }
    }

    function _transferCar(address newOwner, uint256 _data) private returns (bool) {
        uint256 id = _getRacerCar(_data);
        carsMap[id].locked = false;
        _transferCard(newOwner, TYPE_CAR, id);
    }        

    function _oldOwnersOf(uint256 _carId) private view returns(uint256) {
        Car memory _car = carsMap[_carId];
        uint256 count = _addrNotNull(_car.owners[1]) ? 1: 0;
        count += (_addrNotNull(_car.owners[2]) ? 1: 0);
        count += (_addrNotNull(_car.owners[3]) ? 1: 0);
        return(count);
    }

    function _packItemData(address itemOwner, uint256 price) public view returns(uint256) {
        uint256 _data = (~(ADDR_M) & _data) | (uint256(itemOwner) & ADDR_M);
        _data = (~(PRICE_M*ADDR_S) & _data) | ((price & PRICE_M) * ADDR_S);
        return(_data);
    }
    
    function _unpackItemData(uint256 _data) private view returns(address itemOwner, uint256 price) {
        itemOwner = address(_data & ADDR_M);
        price = PRICE_M & (_data / ADDR_S);
    }

    function _packMakeData(address makeOwner, uint256 price, uint256 companyId) private view returns(uint256 _data) {
        _data = (~(ADDR_M) & _data) | (uint256(makeOwner) & ADDR_M);
        _data = (~(COMPANY_ID_M*ADDR_S) & _data) | ((companyId & COMPANY_ID_M) * ADDR_S);
        _data = (~(MAKE_PRICE_M*MAKE_PRICE_S) & _data) | ((price & MAKE_PRICE_M) * MAKE_PRICE_S);
    }

    function _unpackMakeData(uint256 _data) private view returns(address makeOwner, uint256 companyId, uint256 price) {
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
        
        _pay(ownerOf(0,0), whaleFee);
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

        _pay(ownerOf(TYPE_WHALE,0), whaleFee);
        _pay(ownerOf(TYPE_COMPANY, companyId),parentFee);         
        _pay(owner, devFee);
        _pay(seller,sellerCommission);
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

    function _packPlayerData(address player, uint256 id) private view returns(uint256 playerData) {
        playerData = (~(ADDR_M) & playerData) | (uint256(player) & ADDR_M);
        playerData = (~(RACE_ID_M*ADDR_S) & playerData) | ((id & RACE_ID_M) * ADDR_S);
    }

    function _unpackPlayerData(uint256 playerData) private view returns(address player, uint256 id) {
        player = address(playerData & ADDR_M);
        id = (RACE_ID_M & (playerData / ADDR_S));
    }

    function _packRaceData(uint256 _bet, uint256 _winner, uint256 _pinkslip, uint256 _state) private view returns(uint256 _raceData) {
        _raceData = (~(RACE_BET_M) & _raceData) | (_bet & RACE_BET_M);
        _raceData = (~(WINNER_M*RACE_WINNER_S) & _raceData) | ((_winner & WINNER_M) * RACE_WINNER_S);
        _raceData = (~(PINKSLIP_M*PINKSLIP_S) & _raceData) | ((_pinkslip & PINKSLIP_M) * PINKSLIP_S);
        _raceData = (~(STATE_M*STATE_S) & _raceData) | ((_state & STATE_M) * STATE_S);
    }

    function _unpackRaceData(uint256 _raceData) private view returns(uint256 bet, uint256 winner, bool pinkslip, uint256 state) {
        bet = _raceData & RACE_BET_M;
        winner = (WINNER_M & (_raceData / RACE_WINNER_S));
        pinkslip = (PINKSLIP_M & (_raceData / PINKSLIP_S)) != 0;
        state = (STATE_M & (_raceData / STATE_S));
    }
    
    function _unpackRaceFinishData(uint256 _raceData) private view returns(uint256 bet, bool pinkslip) {
        bet = _raceData & RACE_BET_M;
        pinkslip = (PINKSLIP_M & (_raceData / PINKSLIP_S)) != 0;
    }
    
    function _updateRaceWinner(uint256 raceId, uint256 winner) private {
        racesMap[raceId].metaData = (~(STATE_M*STATE_S) & racesMap[raceId].metaData) | ((RACE_FINISHED & STATE_M) * STATE_S);
        racesMap[raceId].metaData = (~(WINNER_M*RACE_WINNER_S) & racesMap[raceId].metaData) | ((winner & WINNER_M) * RACE_WINNER_S);
    }

    function _raceOpened(uint256 raceData) private view returns (bool opened) {
        uint256 state = (STATE_M & (raceData / STATE_S));
        opened = ((state == RACE_OPENED));
    }

    function _getRacerCar(uint256 playerData) private view returns (uint256 id) {
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