pragma solidity ^0.4.24;

//----------------------------------------------------------------------------
//Welcome to Dissidia of Contract PreSale
//欢迎来到契约纷争预售
//----------------------------------------------------------------------------

contract SafeMath{
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Administration is SafeMath{
    event Pause();
    event Unpause();
    event PriceRaise();
    event PriceStop();

    address public CEOAddress;
    address public CTOAddress;
    
    uint oneEth = 1 ether;
    uint public feeUnit = 1 finney;
    uint public preSaleDurance = 45 days;

    bool public paused = false;
    bool public pricePause = true;
    
    uint public startTime;
    uint public endTime;
    
    uint[3] raiseIndex = [
        3,
        7,
        5
    ];
    
    uint[3] rewardPercent = [
        15,
        25,
        30
    ];

    modifier onlyCEO() {
        require(msg.sender == CEOAddress);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == CEOAddress || msg.sender == CTOAddress);
        _;
    }

    function setCTO(address _newAdmin) public onlyCEO {
        require(_newAdmin != address(0));
        CTOAddress = _newAdmin;
    }

    function withdrawBalanceAll() external onlyAdmin {
        CEOAddress.transfer(address(this).balance);
    }
    
    function withdrawBalance(uint _amount) external onlyAdmin {
        CEOAddress.transfer(_amount);
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyCEO whenNotPaused returns(bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyCEO whenPaused returns(bool) {
        paused = false;
        emit Unpause();
        return true;
    }

    function _random(uint _lower, uint _range, uint _jump) internal view returns (uint) {
        uint number = uint(blockhash(block.number - _jump)) % _range;
        if (number < _lower) {
            number = _lower;
        }
        return number;
    }

    function setFeeUnit(uint _fee) public onlyCEO {
        feeUnit = _fee;
    }
    
    function setPreSaleDurance(uint _durance) public onlyCEO {
        preSaleDurance = _durance;
    }
    
    function unPausePriceRaise() public onlyCEO {
        require(pricePause == true);
        pricePause = false;
        startTime = uint(now);
        emit PriceRaise();
    }
    
    function pausePriceRaise() public onlyCEO {
        require(pricePause == false);
        pricePause = true;
        endTime = uint(now);
        emit PriceStop();
    }
    
    function _computePrice(uint _startPrice, uint _endPrice, uint _totalDurance, uint _timePass) internal pure returns (uint) {
        if (_timePass >= _totalDurance) {
            return _endPrice;
        } else {
            uint totalPriceChange = safeSub(_endPrice, _startPrice);
            uint currentPriceChange = totalPriceChange * uint(_timePass) / uint(_totalDurance);
            uint currentPrice = uint(_startPrice) + currentPriceChange;

            return uint(currentPrice);
        }
    }
    
    function computePrice(uint _startPrice, uint _raiseIndex) public view returns (uint) {
        if(pricePause == false) {
            uint timePass = safeSub(uint(now), startTime);
            return _computePrice(_startPrice, _startPrice*raiseIndex[_raiseIndex], preSaleDurance, timePass);
        } else {
            return _startPrice;
        }
    }
    
    function WhoIsTheContractMaster() public pure returns (string) {
        return "Alexander The Exlosion";
    }
}

contract Broker is Administration {
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event BrokerRegistered(uint indexed brokerId, address indexed broker);
    event AppendSubBroker(uint indexed brokerId, uint indexed subBrokerId, address indexed subBroker);
    event BrokerTransfer(address indexed newBroker, uint indexed brokerId, uint indexed subBrokerId);
    event BrokerFeeDistrubution(address indexed vipBroker, uint indexed vipShare, address indexed broker, uint share);
    event BrokerFeeClaim(address indexed broker, uint indexed fee);
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (uint => address[]) BrokerIdToBrokers;
    mapping (uint => uint) BrokerIdToSpots;
    mapping (address => uint) BrokerIncoming;
    
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    uint public vipBrokerFee = 5 ether;
    uint public brokerFee = 1.5 ether;
    uint public vipBrokerNum = 1000;
    uint public subBrokerNum = 5;
    
    // ----------------------------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Function
    // ----------------------------------------------------------------------------
    function _brokerFeeDistribute(uint _price, uint _type, uint _brokerId, uint _subBrokerId) internal {
        address vipBroker = getBrokerAddress(_brokerId, 0);
        address broker = getBrokerAddress(_brokerId, _subBrokerId);
        require(vipBroker != address(0) && broker != address(0));
        uint totalShare = _price*rewardPercent[_type]/100;
        BrokerIncoming[vipBroker] = BrokerIncoming[vipBroker] + totalShare*15/100;
        BrokerIncoming[broker] = BrokerIncoming[broker] + totalShare*85/100;
        
        emit BrokerFeeDistrubution(vipBroker, totalShare*15/100, broker, totalShare*85/100);
    }
    
    // ----------------------------------------------------------------------------
    // Public Function
    // ----------------------------------------------------------------------------
    function registerBroker() public payable returns (uint) {
        require(vipBrokerNum > 0);
        require(msg.value >= vipBrokerFee);
        vipBrokerNum--;
        uint brokerId = 1000 - vipBrokerNum;
        BrokerIdToBrokers[brokerId].push(msg.sender);
        BrokerIdToSpots[brokerId] = subBrokerNum;
        emit BrokerRegistered(brokerId, msg.sender);
        return brokerId;
    }
    
    function assignSubBroker(uint _brokerId, address _broker) public payable {
        require(msg.sender == BrokerIdToBrokers[_brokerId][0]);
        require(msg.value >= brokerFee);
        require(BrokerIdToSpots[_brokerId] > 0);
        uint newSubBrokerId = BrokerIdToBrokers[_brokerId].push(_broker) - 1;
        BrokerIdToSpots[_brokerId]--;
        
        emit AppendSubBroker(_brokerId, newSubBrokerId, _broker);
    }
    
    function transferBroker(address _newBroker, uint _brokerId, uint _subBrokerId) public whenNotPaused {
        require(_brokerId > 0 && _brokerId <= 1000);
        require(_subBrokerId >= 0 && _subBrokerId <= 5);
        require(BrokerIdToBrokers[_brokerId][_subBrokerId] == msg.sender);
        BrokerIdToBrokers[_brokerId][_subBrokerId] = _newBroker;
        
        emit BrokerTransfer(_newBroker, _brokerId, _subBrokerId);
    }

    function claimBrokerFee() public whenNotPaused {
        uint fee = BrokerIncoming[msg.sender];
        require(fee > 0);
        msg.sender.transfer(fee);
        BrokerIncoming[msg.sender] = 0;
        emit BrokerFeeClaim(msg.sender, fee);
    }
    
    function getBrokerIncoming(address _broker) public view returns (uint) {
        return BrokerIncoming[_broker];
    } 
    
    function getBrokerInfo(uint _brokerId) public view returns (
        address broker,
        uint subSpot
    ) { 
        broker = BrokerIdToBrokers[_brokerId][0];
        subSpot = BrokerIdToSpots[_brokerId];
    }
    
    function getBrokerAddress(uint _brokerId, uint _subBrokerId) public view returns (address) {
        return BrokerIdToBrokers[_brokerId][_subBrokerId];
    }
    
    function getVipBrokerNum() public view returns (uint) {
        return safeSub(1000, vipBrokerNum);
    }
}

contract PreSaleRealm is Broker {
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event RealmSaleCreate(uint indexed saleId, uint indexed realmId, uint indexed price);
    event BuyRealm(uint indexed saleId, uint realmId, address indexed buyer, uint indexed currentPrice);
    event RealmOfferSubmit(uint indexed saleId, uint realmId, address indexed bidder, uint indexed price);
    event RealmOfferAccept(uint indexed saleId, uint realmId, address indexed newOwner, uint indexed newPrice);
    event SetRealmSale(uint indexed saleId, uint indexed price);
    
    event RealmAuctionCreate(uint indexed auctionId, uint indexed realmId, uint indexed startPrice);
    event RealmAuctionBid(uint indexed auctionId, address indexed bidder, uint indexed offer);
    
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (uint => address) public RealmSaleToBuyer;
    
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    struct RealmSale {
        uint realmId;
        uint price;
        bool ifSold;
        address bidder;
        uint offerPrice;
        uint timestamp;
    }
    
    RealmSale[] realmSales;
    
    // ----------------------------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Function
    // ----------------------------------------------------------------------------
    function _generateRealmSale(uint _realmId, uint _price) internal returns (uint) {
        RealmSale memory _RealmSale = RealmSale({
            realmId: _realmId,
            price: _price,
            ifSold: false,
            bidder: address(0),
            offerPrice: 0,
            timestamp: 0
        });
        uint realmSaleId = realmSales.push(_RealmSale) - 1;
        emit RealmSaleCreate(realmSaleId, _realmId, _price);
        
        return realmSaleId;
    }
    // ----------------------------------------------------------------------------
    // Public Function
    // ----------------------------------------------------------------------------
    function createRealmSale(uint _num, uint _startId, uint _price) public onlyAdmin {
        for(uint i = 0; i<_num; i++) {
            _generateRealmSale(_startId + i, _price);
        }
    }
    
    function buyRealm(uint _realmSaleId, uint _brokerId, uint _subBrokerId) public payable whenNotPaused {
        RealmSale storage _realmSale = realmSales[_realmSaleId];
        require(RealmSaleToBuyer[_realmSale.realmId] == address(0));
        require(_realmSale.ifSold == false);
        uint currentPrice;
        if(pricePause == true) {
            if(_realmSale.timestamp != 0 && _realmSale.timestamp != endTime) {
                uint timePass = safeSub(endTime, startTime);
                _realmSale.price = _computePrice(_realmSale.price, _realmSale.price*raiseIndex[0], preSaleDurance, timePass);
                _realmSale.timestamp = endTime;
            }
            _brokerFeeDistribute(_realmSale.price, 0, _brokerId, _subBrokerId);
            require(msg.value >= _realmSale.price);
            currentPrice = _realmSale.price;
        } else {
            if(_realmSale.timestamp == 0) {
                _realmSale.timestamp = uint(now);
            }
            currentPrice = _computePrice(_realmSale.price, _realmSale.price*raiseIndex[0], preSaleDurance, safeSub(uint(now), startTime));
            _brokerFeeDistribute(currentPrice, 0, _brokerId, _subBrokerId);
            require(msg.value >= currentPrice);
            _realmSale.price = currentPrice;
        }
        RealmSaleToBuyer[_realmSale.realmId] = msg.sender;
        _realmSale.ifSold = true;
        emit BuyRealm(_realmSaleId, _realmSale.realmId, msg.sender, currentPrice);
    }
    
    function offlineRealmSold(uint _realmSaleId, address _buyer, uint _price) public onlyAdmin {
        RealmSale storage _realmSale = realmSales[_realmSaleId];
        require(_realmSale.ifSold == false);
        RealmSaleToBuyer[_realmSale.realmId] = _buyer;
        _realmSale.ifSold = true;
        emit BuyRealm(_realmSaleId, _realmSale.realmId, _buyer, _price);
    }
    
    function OfferToRealm(uint _realmSaleId, uint _price) public payable whenNotPaused {
        RealmSale storage _realmSale = realmSales[_realmSaleId];
        require(_realmSale.ifSold == true);
        require(_price >= _realmSale.offerPrice*11/10);
        require(msg.value >= _price);
        
        if(_realmSale.bidder == address(0)) {
            _realmSale.bidder = msg.sender;
            _realmSale.offerPrice = _price;
        } else {
            address lastBidder = _realmSale.bidder;
            uint lastOffer = _realmSale.price;
            lastBidder.transfer(lastOffer);
            
            _realmSale.bidder = msg.sender;
            _realmSale.offerPrice = _price;
        }
        
        emit RealmOfferSubmit(_realmSaleId, _realmSale.realmId, msg.sender, _price);
    }
    
    function AcceptRealmOffer(uint _realmSaleId) public whenNotPaused {
        RealmSale storage _realmSale = realmSales[_realmSaleId];
        require(RealmSaleToBuyer[_realmSale.realmId] == msg.sender);
        require(_realmSale.bidder != address(0) && _realmSale.offerPrice > 0);
        msg.sender.transfer(_realmSale.offerPrice);
        RealmSaleToBuyer[_realmSale.realmId] = _realmSale.bidder;
        _realmSale.price = _realmSale.offerPrice;
        
        emit RealmOfferAccept(_realmSaleId, _realmSale.realmId, _realmSale.bidder, _realmSale.offerPrice);
        
        _realmSale.bidder = address(0);
        _realmSale.offerPrice = 0;
    }
    
    function setRealmSale(uint _realmSaleId, uint _price) public onlyAdmin {
        RealmSale storage _realmSale = realmSales[_realmSaleId];
        require(_realmSale.ifSold == false);
        _realmSale.price = _price;
        emit SetRealmSale(_realmSaleId, _price);
    }
    
    function getRealmSale(uint _realmSaleId) public view returns (
        address owner,
        uint realmId,
        uint price,
        bool ifSold,
        address bidder,
        uint offerPrice,
        uint timestamp
    ) {
        RealmSale memory _RealmSale = realmSales[_realmSaleId];
        owner = RealmSaleToBuyer[_RealmSale.realmId];
        realmId = _RealmSale.realmId;
        price = _RealmSale.price;
        ifSold =_RealmSale.ifSold;
        bidder = _RealmSale.bidder;
        offerPrice = _RealmSale.offerPrice;
        timestamp = _RealmSale.timestamp;
    }
    
    function getRealmNum() public view returns (uint) {
        return realmSales.length;
    }
}

contract PreSaleCastle is PreSaleRealm {
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event CastleSaleCreate(uint indexed saleId, uint indexed castleId, uint indexed price, uint realmId, uint rarity);
    event BuyCastle(uint indexed saleId, uint castleId, address indexed buyer, uint indexed currentPrice);
    event CastleOfferSubmit(uint indexed saleId, uint castleId, address indexed bidder, uint indexed price);
    event CastleOfferAccept(uint indexed saleId, uint castleId, address indexed newOwner, uint indexed newPrice);
    event SetCastleSale(uint indexed saleId, uint indexed price);
    
    event CastleAuctionCreate(uint indexed auctionId, uint indexed castleId, uint indexed startPrice, uint realmId, uint rarity);
    event CastleAuctionBid(uint indexed auctionId, address indexed bidder, uint indexed offer);
    
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (uint => address) public CastleSaleToBuyer;
    
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    struct CastleSale {
        uint castleId;
        uint realmId;
        uint rarity;
        uint price;
        bool ifSold;
        address bidder;
        uint offerPrice;
        uint timestamp;
    }

    CastleSale[] castleSales;

    // ----------------------------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Function
    // ----------------------------------------------------------------------------
    function _generateCastleSale(uint _castleId, uint _realmId, uint _rarity, uint _price) internal returns (uint) {
        CastleSale memory _CastleSale = CastleSale({
            castleId: _castleId,
            realmId: _realmId,
            rarity: _rarity,
            price: _price,
            ifSold: false,
            bidder: address(0),
            offerPrice: 0,
            timestamp: 0
        });
        uint castleSaleId = castleSales.push(_CastleSale) - 1;
        emit CastleSaleCreate(castleSaleId, _castleId, _price, _realmId, _rarity);
        
        return castleSaleId;
    }

    // ----------------------------------------------------------------------------
    // Public Function
    // ----------------------------------------------------------------------------
    function createCastleSale(uint _num, uint _startId, uint _realmId, uint _rarity, uint _price) public onlyAdmin {
        for(uint i = 0; i<_num; i++) {
            _generateCastleSale(_startId + i, _realmId, _rarity, _price);
        }
    }
    
    function buyCastle(uint _castleSaleId, uint _brokerId, uint _subBrokerId) public payable whenNotPaused {
        CastleSale storage _castleSale = castleSales[_castleSaleId];
        require(CastleSaleToBuyer[_castleSale.castleId] == address(0));
        require(_castleSale.ifSold == false);
        uint currentPrice;
        if(pricePause == true) {
            if(_castleSale.timestamp != 0 && _castleSale.timestamp != endTime) {
                uint timePass = safeSub(endTime, startTime);
                _castleSale.price = _computePrice(_castleSale.price, _castleSale.price*raiseIndex[0], preSaleDurance, timePass);
                _castleSale.timestamp = endTime;
            }
            _brokerFeeDistribute(_castleSale.price, 0, _brokerId, _subBrokerId);
            require(msg.value >= _castleSale.price);
            currentPrice = _castleSale.price;
        } else {
            if(_castleSale.timestamp == 0) {
                _castleSale.timestamp = uint(now);
            }
            currentPrice = _computePrice(_castleSale.price, _castleSale.price*raiseIndex[0], preSaleDurance, safeSub(uint(now), startTime));
            _brokerFeeDistribute(currentPrice, 0, _brokerId, _subBrokerId);
            require(msg.value >= currentPrice);
            _castleSale.price = currentPrice;
        }
        CastleSaleToBuyer[_castleSale.castleId] = msg.sender;
        _castleSale.ifSold = true;
        emit BuyCastle(_castleSaleId, _castleSale.castleId, msg.sender, currentPrice);
    }
    
    function OfflineCastleSold(uint _castleSaleId, address _buyer, uint _price) public onlyAdmin {
        CastleSale storage _castleSale = castleSales[_castleSaleId];
        require(_castleSale.ifSold == false);
        CastleSaleToBuyer[_castleSale.castleId] = _buyer;
        _castleSale.ifSold = true;
        emit BuyCastle(_castleSaleId, _castleSale.castleId, _buyer, _price);
    }
    
    function OfferToCastle(uint _castleSaleId, uint _price) public payable whenNotPaused {
        CastleSale storage _castleSale = castleSales[_castleSaleId];
        require(_castleSale.ifSold == true);
        require(_price >= _castleSale.offerPrice*11/10);
        require(msg.value >= _price);
        
        if(_castleSale.bidder == address(0)) {
            _castleSale.bidder = msg.sender;
            _castleSale.offerPrice = _price;
        } else {
            address lastBidder = _castleSale.bidder;
            uint lastOffer = _castleSale.price;
            lastBidder.transfer(lastOffer);
            
            _castleSale.bidder = msg.sender;
            _castleSale.offerPrice = _price;
        }
        
        emit CastleOfferSubmit(_castleSaleId, _castleSale.castleId, msg.sender, _price);
    }
    
    function AcceptCastleOffer(uint _castleSaleId) public whenNotPaused {
        CastleSale storage _castleSale = castleSales[_castleSaleId];
        require(CastleSaleToBuyer[_castleSale.castleId] == msg.sender);
        require(_castleSale.bidder != address(0) && _castleSale.offerPrice > 0);
        msg.sender.transfer(_castleSale.offerPrice);
        CastleSaleToBuyer[_castleSale.castleId] = _castleSale.bidder;
        _castleSale.price = _castleSale.offerPrice;
        
        emit CastleOfferAccept(_castleSaleId, _castleSale.castleId, _castleSale.bidder, _castleSale.offerPrice);
        
        _castleSale.bidder = address(0);
        _castleSale.offerPrice = 0;
    }
    
    function setCastleSale(uint _castleSaleId, uint _price) public onlyAdmin {
        CastleSale storage _castleSale = castleSales[_castleSaleId];
        require(_castleSale.ifSold == false);
        _castleSale.price = _price;
        emit SetCastleSale(_castleSaleId, _price);
    }
    
    function getCastleSale(uint _castleSaleId) public view returns (
        address owner,
        uint castleId,
        uint realmId,
        uint rarity,
        uint price,
        bool ifSold,
        address bidder,
        uint offerPrice,
        uint timestamp
    ) {
        CastleSale memory _CastleSale = castleSales[_castleSaleId];
        owner = CastleSaleToBuyer[_CastleSale.castleId];
        castleId = _CastleSale.castleId;
        realmId = _CastleSale.realmId;
        rarity = _CastleSale.rarity;
        price = _CastleSale.price;
        ifSold =_CastleSale.ifSold;
        bidder = _CastleSale.bidder;
        offerPrice = _CastleSale.offerPrice;
        timestamp = _CastleSale.timestamp;
    }
    
    function getCastleNum() public view returns (uint) {
        return castleSales.length;
    }
}

contract PreSaleGuardian is PreSaleCastle {
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event GuardianSaleCreate(uint indexed saleId, uint indexed guardianId, uint indexed price, uint race, uint level, uint starRate);
    event BuyGuardian(uint indexed saleId, uint guardianId, address indexed buyer, uint indexed currentPrice);
    event GuardianOfferSubmit(uint indexed saleId, uint guardianId, address indexed bidder, uint indexed price);
    event GuardianOfferAccept(uint indexed saleId, uint guardianId, address indexed newOwner, uint indexed newPrice);
    event SetGuardianSale(uint indexed saleId, uint indexed price);
    
    event GuardianAuctionCreate(uint indexed auctionId, uint indexed guardianId, uint indexed startPrice, uint race, uint level, uint starRate);
    event GuardianAuctionBid(uint indexed auctionId, address indexed bidder, uint indexed offer);
    
    event VendingGuardian(uint indexed vendingId, address indexed buyer);
    event GuardianVendOffer(uint indexed vendingId, address indexed bidder, uint indexed offer);
    event GuardianVendAccept(uint indexed vendingId, address indexed newOwner, uint indexed newPrice);
    event SetGuardianVend(uint indexed priceId, uint indexed price);
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (uint => address) public GuardianSaleToBuyer;
    
    mapping (uint => uint) public GuardianVendToOffer;
    mapping (uint => address) public GuardianVendToBidder;
    mapping (uint => uint) public GuardianVendToTime;
    
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    struct GuardianSale {
        uint guardianId;
        uint race;
        uint starRate;
        uint level;
        uint price;
        bool ifSold;
        address bidder;
        uint offerPrice;
        uint timestamp;
    }
    
    GuardianSale[] guardianSales;

    uint[5] GuardianVending = [
        0.5 ether,
        0.35 ether,
        0.20 ether,
        0.15 ether,
        0.1 ether
    ];
    
    // ----------------------------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Function
    // ----------------------------------------------------------------------------
    function _generateGuardianSale(uint _guardianId, uint _race, uint _starRate, uint _level, uint _price) internal returns (uint) {
        GuardianSale memory _GuardianSale = GuardianSale({
            guardianId: _guardianId,
            race: _race,
            starRate: _starRate,
            level: _level,
            price: _price,
            ifSold: false,
            bidder: address(0),
            offerPrice: 0,
            timestamp: 0
        });
        uint guardianSaleId = guardianSales.push(_GuardianSale) - 1;
        emit GuardianSaleCreate(guardianSaleId, _guardianId, _price, _race, _level, _starRate);
        
        return guardianSaleId;
    }
    
    function _guardianVendPrice(uint _guardianId , uint _level) internal returns (uint) {
        if(pricePause == true) {
            if(GuardianVendToTime[_guardianId] != 0 && GuardianVendToTime[_guardianId] != endTime) {
                uint timePass = safeSub(endTime, startTime);
                GuardianVending[_level] = _computePrice(GuardianVending[_level], GuardianVending[_level]*raiseIndex[1], preSaleDurance, timePass);
                GuardianVendToTime[_guardianId] = endTime;
            }
            return GuardianVending[_level];
        } else {
            if(GuardianVendToTime[_guardianId] == 0) {
                GuardianVendToTime[_guardianId] = uint(now);
            }
            uint currentPrice = _computePrice(GuardianVending[_level], GuardianVending[_level]*raiseIndex[1], preSaleDurance, safeSub(uint(now), startTime));
            return currentPrice;
        }
    }
    
    // ----------------------------------------------------------------------------
    // Public Function
    // ----------------------------------------------------------------------------
    function createGuardianSale(uint _num, uint _startId, uint _race, uint _starRate, uint _level, uint _price) public onlyAdmin {
        for(uint i = 0; i<_num; i++) {
            _generateGuardianSale(_startId + i, _race, _starRate, _level, _price);
        }
    }
    
    function buyGuardian(uint _guardianSaleId, uint _brokerId, uint _subBrokerId) public payable whenNotPaused {
        GuardianSale storage _guardianSale = guardianSales[_guardianSaleId];
        require(GuardianSaleToBuyer[_guardianSale.guardianId] == address(0));
        require(_guardianSale.ifSold == false);
        uint currentPrice;
        if(pricePause == true) {
            if(_guardianSale.timestamp != 0 && _guardianSale.timestamp != endTime) {
                uint timePass = safeSub(endTime, startTime);
                _guardianSale.price = _computePrice(_guardianSale.price, _guardianSale.price*raiseIndex[1], preSaleDurance, timePass);
                _guardianSale.timestamp = endTime;
            }
            _brokerFeeDistribute(_guardianSale.price, 1, _brokerId, _subBrokerId);
            require(msg.value >= _guardianSale.price);
            currentPrice = _guardianSale.price;
        } else {
            if(_guardianSale.timestamp == 0) {
                _guardianSale.timestamp = uint(now);
            }
            currentPrice = _computePrice(_guardianSale.price, _guardianSale.price*raiseIndex[1], preSaleDurance, safeSub(uint(now), startTime));
            _brokerFeeDistribute(currentPrice, 1, _brokerId, _subBrokerId);
            require(msg.value >= currentPrice);
            _guardianSale.price = currentPrice;
        }
        GuardianSaleToBuyer[_guardianSale.guardianId] = msg.sender;
        _guardianSale.ifSold = true;
        emit BuyGuardian(_guardianSaleId, _guardianSale.guardianId, msg.sender, currentPrice);
    }
    
    function offlineGuardianSold(uint _guardianSaleId, address _buyer, uint _price) public onlyAdmin {
        GuardianSale storage _guardianSale = guardianSales[_guardianSaleId];
        require(_guardianSale.ifSold == false);
        GuardianSaleToBuyer[_guardianSale.guardianId] = _buyer;
        _guardianSale.ifSold = true;
        emit BuyGuardian(_guardianSaleId, _guardianSale.guardianId, _buyer, _price);
    }
    
    function OfferToGuardian(uint _guardianSaleId, uint _price) public payable whenNotPaused {
        GuardianSale storage _guardianSale = guardianSales[_guardianSaleId];
        require(_guardianSale.ifSold == true);
        require(_price > _guardianSale.offerPrice*11/10);
        require(msg.value >= _price);
        
        if(_guardianSale.bidder == address(0)) {
            _guardianSale.bidder = msg.sender;
            _guardianSale.offerPrice = _price;
        } else {
            address lastBidder = _guardianSale.bidder;
            uint lastOffer = _guardianSale.price;
            lastBidder.transfer(lastOffer);
            
            _guardianSale.bidder = msg.sender;
            _guardianSale.offerPrice = _price;
        }
        
        emit GuardianOfferSubmit(_guardianSaleId, _guardianSale.guardianId, msg.sender, _price);
    }
    
    function AcceptGuardianOffer(uint _guardianSaleId) public whenNotPaused {
        GuardianSale storage _guardianSale = guardianSales[_guardianSaleId];
        require(GuardianSaleToBuyer[_guardianSale.guardianId] == msg.sender);
        require(_guardianSale.bidder != address(0) && _guardianSale.offerPrice > 0);
        msg.sender.transfer(_guardianSale.offerPrice);
        GuardianSaleToBuyer[_guardianSale.guardianId] = _guardianSale.bidder;
        _guardianSale.price = _guardianSale.offerPrice;
        
        emit GuardianOfferAccept(_guardianSaleId, _guardianSale.guardianId, _guardianSale.bidder, _guardianSale.price);
        
        _guardianSale.bidder = address(0);
        _guardianSale.offerPrice = 0;
    }
    
    function setGuardianSale(uint _guardianSaleId, uint _price) public onlyAdmin {
        GuardianSale storage _guardianSale = guardianSales[_guardianSaleId];
        require(_guardianSale.ifSold == false);
        _guardianSale.price = _price;
        emit SetGuardianSale(_guardianSaleId, _price);
    }
    
    function getGuardianSale(uint _guardianSaleId) public view returns (
        address owner,
        uint guardianId,
        uint race,
        uint starRate,
        uint level,
        uint price,
        bool ifSold,
        address bidder,
        uint offerPrice,
        uint timestamp
    ) {
        GuardianSale memory _GuardianSale = guardianSales[_guardianSaleId];
        owner = GuardianSaleToBuyer[_GuardianSale.guardianId];
        guardianId = _GuardianSale.guardianId;
        race = _GuardianSale.race;
        starRate = _GuardianSale.starRate;
        level = _GuardianSale.level;
        price = _GuardianSale.price;
        ifSold =_GuardianSale.ifSold;
        bidder = _GuardianSale.bidder;
        offerPrice = _GuardianSale.offerPrice;
        timestamp = _GuardianSale.timestamp;
    }
    
    function getGuardianNum() public view returns (uint) {
        return guardianSales.length;
    }

    function vendGuardian(uint _guardianId) public payable whenNotPaused {
        require(_guardianId > 1000 && _guardianId <= 6000);
        if(_guardianId > 1000 && _guardianId <= 2000) {
            require(GuardianSaleToBuyer[_guardianId] == address(0));
            require(msg.value >= _guardianVendPrice(_guardianId, 0));
            GuardianSaleToBuyer[_guardianId] = msg.sender;
            GuardianVendToOffer[_guardianId] = GuardianVending[0];
        } else if (_guardianId > 2000 && _guardianId <= 3000) {
            require(GuardianSaleToBuyer[_guardianId] == address(0));
            require(msg.value >= _guardianVendPrice(_guardianId, 1));
            GuardianSaleToBuyer[_guardianId] = msg.sender;
            GuardianVendToOffer[_guardianId] = GuardianVending[1];
        } else if (_guardianId > 3000 && _guardianId <= 4000) {
            require(GuardianSaleToBuyer[_guardianId] == address(0));
            require(msg.value >= _guardianVendPrice(_guardianId, 2));
            GuardianSaleToBuyer[_guardianId] = msg.sender;
            GuardianVendToOffer[_guardianId] = GuardianVending[2];
        } else if (_guardianId > 4000 && _guardianId <= 5000) {
            require(GuardianSaleToBuyer[_guardianId] == address(0));
            require(msg.value >= _guardianVendPrice(_guardianId, 3));
            GuardianSaleToBuyer[_guardianId] = msg.sender;
            GuardianVendToOffer[_guardianId] = GuardianVending[3];
        } else if (_guardianId > 5000 && _guardianId <= 6000) {
            require(GuardianSaleToBuyer[_guardianId] == address(0));
            require(msg.value >= _guardianVendPrice(_guardianId, 4));
            GuardianSaleToBuyer[_guardianId] = msg.sender;
            GuardianVendToOffer[_guardianId] = GuardianVending[4];
        }
        emit VendingGuardian(_guardianId, msg.sender);
    }
    
    function offerGuardianVend(uint _guardianId, uint _offer) public payable whenNotPaused {
        require(GuardianSaleToBuyer[_guardianId] != address(0));
        require(_offer >= GuardianVendToOffer[_guardianId]*11/10);
        require(msg.value >= _offer);
        address lastBidder = GuardianVendToBidder[_guardianId];
        if(lastBidder != address(0)){
            lastBidder.transfer(GuardianVendToOffer[_guardianId]);
        }
        GuardianVendToBidder[_guardianId] = msg.sender;
        GuardianVendToOffer[_guardianId] = _offer;
        emit GuardianVendOffer(_guardianId, msg.sender, _offer);
    }
    
    function acceptGuardianVend(uint _guardianId) public whenNotPaused {
        require(GuardianSaleToBuyer[_guardianId] == msg.sender);
        address bidder = GuardianVendToBidder[_guardianId];
        uint offer = GuardianVendToOffer[_guardianId];
        require(bidder != address(0) && offer > 0);
        msg.sender.transfer(offer);
        GuardianSaleToBuyer[_guardianId] = bidder;
        GuardianVendToBidder[_guardianId] = address(0);
        GuardianVendToOffer[_guardianId] = 0;
        emit GuardianVendAccept(_guardianId, bidder, offer);
    }
    
    function setGuardianVend(uint _num, uint _price) public onlyAdmin {
        GuardianVending[_num] = _price;
        emit SetGuardianVend(_num, _price);
    }
    
    function getGuardianVend(uint _guardianId) public view returns (
        address owner,
        address bidder,
        uint offer
    ) {
        owner = GuardianSaleToBuyer[_guardianId];
        bidder = GuardianVendToBidder[_guardianId];
        offer = GuardianVendToOffer[_guardianId];
    }
}

contract PreSaleDisciple is PreSaleGuardian {
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event DiscipleSaleCreate(uint indexed saleId, uint indexed discipleId, uint indexed price, uint occupation, uint level);
    event BuyDisciple(uint indexed saleId, uint discipleId, address indexed buyer, uint indexed currentPrice);
    event DiscipleOfferSubmit(uint indexed saleId, uint discipleId, address indexed bidder, uint indexed price);
    event DiscipleOfferAccept(uint indexed saleId, uint discipleId, address indexed newOwner, uint indexed newPrice);
    event SetDiscipleSale(uint indexed saleId, uint indexed price);
    
    event DiscipleAuctionCreate(uint indexed auctionId, uint indexed discipleId, uint indexed startPrice, uint occupation, uint level);
    event DiscipleAuctionBid(uint indexed auctionId, address indexed bidder, uint indexed offer);
    
    event VendingDisciple(uint indexed vendingId, address indexed buyer);
    event DiscipleVendOffer(uint indexed vendingId, address indexed bidder, uint indexed offer);
    event DiscipleVendAccept(uint indexed vendingId, address indexed newOwner, uint indexed newPrice);
    event SetDiscipleVend(uint indexed priceId, uint indexed price);
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (uint => address) public DiscipleSaleToBuyer;
    
    mapping (uint => uint) public DiscipleVendToOffer;
    mapping (uint => address) public DiscipleVendToBidder;
    mapping (uint => uint) public DiscipleVendToTime;
    
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    struct DiscipleSale {
        uint discipleId;
        uint occupation;
        uint level;
        uint price;
        bool ifSold;
        address bidder;
        uint offerPrice;
        uint timestamp;
    }
    
    DiscipleSale[] discipleSales;

    uint[5] DiscipleVending = [
        0.8 ether,
        0.65 ether,
        0.45 ether,
        0.35 ether,
        0.2 ether
    ];
    
    // ----------------------------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Function
    // ----------------------------------------------------------------------------
    function _generateDiscipleSale(uint _discipleId, uint _occupation, uint _level, uint _price) internal returns (uint) {
        DiscipleSale memory _DiscipleSale = DiscipleSale({
            discipleId: _discipleId,
            occupation: _occupation,
            level: _level,
            price: _price,
            ifSold: false,
            bidder: address(0),
            offerPrice: 0,
            timestamp: 0
        });
        uint discipleSaleId = discipleSales.push(_DiscipleSale) - 1;
        emit DiscipleSaleCreate(discipleSaleId, _discipleId, _price, _occupation, _level);
        
        return discipleSaleId;
    }
    
    function _discipleVendPrice(uint _discipleId , uint _level) internal returns (uint) {
        if(pricePause == true) {
            if(DiscipleVendToTime[_discipleId] != 0 && DiscipleVendToTime[_discipleId] != endTime) {
                uint timePass = safeSub(endTime, startTime);
                DiscipleVending[_level] = _computePrice(DiscipleVending[_level], DiscipleVending[_level]*raiseIndex[1], preSaleDurance, timePass);
                DiscipleVendToTime[_discipleId] = endTime;
            }
            return DiscipleVending[_level];
        } else {
            if(DiscipleVendToTime[_discipleId] == 0) {
                DiscipleVendToTime[_discipleId] = uint(now);
            }
            uint currentPrice = _computePrice(DiscipleVending[_level], DiscipleVending[_level]*raiseIndex[1], preSaleDurance, safeSub(uint(now), startTime));
            return currentPrice;
        }
    }
    // ----------------------------------------------------------------------------
    // Public Function
    // ----------------------------------------------------------------------------
    function createDiscipleSale(uint _num, uint _startId, uint _occupation, uint _level, uint _price) public onlyAdmin {
        for(uint i = 0; i<_num; i++) {
            _generateDiscipleSale(_startId + i, _occupation, _level, _price);
        }
    }
    
    function buyDisciple(uint _discipleSaleId, uint _brokerId, uint _subBrokerId) public payable whenNotPaused {
        DiscipleSale storage _discipleSale = discipleSales[_discipleSaleId];
        require(DiscipleSaleToBuyer[_discipleSale.discipleId] == address(0));
        require(_discipleSale.ifSold == false);
        uint currentPrice;
        if(pricePause == true) {
            if(_discipleSale.timestamp != 0 && _discipleSale.timestamp != endTime) {
                uint timePass = safeSub(endTime, startTime);
                _discipleSale.price = _computePrice(_discipleSale.price, _discipleSale.price*raiseIndex[1], preSaleDurance, timePass);
                _discipleSale.timestamp = endTime;
            }
            _brokerFeeDistribute(_discipleSale.price, 1, _brokerId, _subBrokerId);
            require(msg.value >= _discipleSale.price);
            currentPrice = _discipleSale.price;
        } else {
            if(_discipleSale.timestamp == 0) {
                _discipleSale.timestamp = uint(now);
            }
            currentPrice = _computePrice(_discipleSale.price, _discipleSale.price*raiseIndex[1], preSaleDurance, safeSub(uint(now), startTime));
            _brokerFeeDistribute(currentPrice, 1, _brokerId, _subBrokerId);
            require(msg.value >= currentPrice);
            _discipleSale.price = currentPrice;
        }
        DiscipleSaleToBuyer[_discipleSale.discipleId] = msg.sender;
        _discipleSale.ifSold = true;
        emit BuyDisciple(_discipleSaleId, _discipleSale.discipleId, msg.sender, currentPrice);
    }
    
    function offlineDiscipleSold(uint _discipleSaleId, address _buyer, uint _price) public onlyAdmin {
        DiscipleSale storage _discipleSale = discipleSales[_discipleSaleId];
        require(_discipleSale.ifSold == false);
        DiscipleSaleToBuyer[_discipleSale.discipleId] = _buyer;
        _discipleSale.ifSold = true;
        emit BuyDisciple(_discipleSaleId, _discipleSale.discipleId, _buyer, _price);
    }
    
    function OfferToDisciple(uint _discipleSaleId, uint _price) public payable whenNotPaused {
        DiscipleSale storage _discipleSale = discipleSales[_discipleSaleId];
        require(_discipleSale.ifSold == true);
        require(_price > _discipleSale.offerPrice*11/10);
        require(msg.value >= _price);
        
        if(_discipleSale.bidder == address(0)) {
            _discipleSale.bidder = msg.sender;
            _discipleSale.offerPrice = _price;
        } else {
            address lastBidder = _discipleSale.bidder;
            uint lastOffer = _discipleSale.price;
            lastBidder.transfer(lastOffer);
            
            _discipleSale.bidder = msg.sender;
            _discipleSale.offerPrice = _price;
        }
        
        emit DiscipleOfferSubmit(_discipleSaleId, _discipleSale.discipleId, msg.sender, _price);
    }
    
    function AcceptDiscipleOffer(uint _discipleSaleId) public whenNotPaused {
        DiscipleSale storage _discipleSale = discipleSales[_discipleSaleId];
        require(DiscipleSaleToBuyer[_discipleSale.discipleId] == msg.sender);
        require(_discipleSale.bidder != address(0) && _discipleSale.offerPrice > 0);
        msg.sender.transfer(_discipleSale.offerPrice);
        DiscipleSaleToBuyer[_discipleSale.discipleId] = _discipleSale.bidder;
        _discipleSale.price = _discipleSale.offerPrice;
        
        emit DiscipleOfferAccept(_discipleSaleId, _discipleSale.discipleId, _discipleSale.bidder, _discipleSale.price);
        
        _discipleSale.bidder = address(0);
        _discipleSale.offerPrice = 0;
    }
    
    function setDiscipleSale(uint _discipleSaleId, uint _price) public onlyAdmin {
        DiscipleSale storage _discipleSale = discipleSales[_discipleSaleId];
        require(_discipleSale.ifSold == false);
        _discipleSale.price = _price;
        emit SetDiscipleSale(_discipleSaleId, _price);
    }
    
    function getDiscipleSale(uint _discipleSaleId) public view returns (
        address owner,
        uint discipleId,
        uint occupation,
        uint level,
        uint price,
        bool ifSold,
        address bidder,
        uint offerPrice,
        uint timestamp
    ) {
        DiscipleSale memory _DiscipleSale = discipleSales[_discipleSaleId];
        owner = DiscipleSaleToBuyer[_DiscipleSale.discipleId];
        discipleId = _DiscipleSale.discipleId;
        occupation = _DiscipleSale.occupation;
        level = _DiscipleSale.level;
        price = _DiscipleSale.price;
        ifSold =_DiscipleSale.ifSold;
        bidder = _DiscipleSale.bidder;
        offerPrice = _DiscipleSale.offerPrice;
        timestamp = _DiscipleSale.timestamp;
    }
    
    function getDiscipleNum() public view returns(uint) {
        return discipleSales.length;
    }
    
    function vendDisciple(uint _discipleId) public payable whenNotPaused {
        require(_discipleId > 1000 && _discipleId <= 10000);
        if(_discipleId > 1000 && _discipleId <= 2000) {
            require(DiscipleSaleToBuyer[_discipleId] == address(0));
            require(msg.value >= _discipleVendPrice(_discipleId, 0));
            DiscipleSaleToBuyer[_discipleId] = msg.sender;
            DiscipleVendToOffer[_discipleId] = DiscipleVending[0];
        } else if (_discipleId > 2000 && _discipleId <= 4000) {
            require(DiscipleSaleToBuyer[_discipleId] == address(0));
            require(msg.value >= _discipleVendPrice(_discipleId, 1));
            DiscipleSaleToBuyer[_discipleId] = msg.sender;
            DiscipleVendToOffer[_discipleId] = DiscipleVending[1];
        } else if (_discipleId > 4000 && _discipleId <= 6000) {
            require(DiscipleSaleToBuyer[_discipleId] == address(0));
            require(msg.value >= _discipleVendPrice(_discipleId, 2));
            DiscipleSaleToBuyer[_discipleId] = msg.sender;
            DiscipleVendToOffer[_discipleId] = DiscipleVending[2];
        } else if (_discipleId > 6000 && _discipleId <= 8000) {
            require(DiscipleSaleToBuyer[_discipleId] == address(0));
            require(msg.value >= _discipleVendPrice(_discipleId, 3));
            DiscipleSaleToBuyer[_discipleId] = msg.sender;
            DiscipleVendToOffer[_discipleId] = DiscipleVending[3];
        } else if (_discipleId > 8000 && _discipleId <= 10000) {
            require(DiscipleSaleToBuyer[_discipleId] == address(0));
            require(msg.value >= _discipleVendPrice(_discipleId, 4));
            DiscipleSaleToBuyer[_discipleId] = msg.sender;
            DiscipleVendToOffer[_discipleId] = DiscipleVending[4];
        }
        emit VendingDisciple(_discipleId, msg.sender);
    }
    
    function offerDiscipleVend(uint _discipleId, uint _offer) public payable whenNotPaused {
        require(DiscipleSaleToBuyer[_discipleId] != address(0));
        require(_offer >= DiscipleVendToOffer[_discipleId]*11/10);
        require(msg.value >= _offer);
        address lastBidder = DiscipleVendToBidder[_discipleId];
        if(lastBidder != address(0)){
            lastBidder.transfer(DiscipleVendToOffer[_discipleId]);
        }
        DiscipleVendToBidder[_discipleId] = msg.sender;
        DiscipleVendToOffer[_discipleId] = _offer;
        emit DiscipleVendOffer(_discipleId, msg.sender, _offer);
    }
    
    function acceptDiscipleVend(uint _discipleId) public whenNotPaused {
        require(DiscipleSaleToBuyer[_discipleId] == msg.sender);
        address bidder = DiscipleVendToBidder[_discipleId];
        uint offer = DiscipleVendToOffer[_discipleId];
        require(bidder != address(0) && offer > 0);
        msg.sender.transfer(offer);
        DiscipleSaleToBuyer[_discipleId] = bidder;
        DiscipleVendToBidder[_discipleId] = address(0);
        DiscipleVendToOffer[_discipleId] = 0;
        emit DiscipleVendAccept(_discipleId, bidder, offer);
    }
    
    function setDiscipleVend(uint _num, uint _price) public onlyAdmin {
        DiscipleVending[_num] = _price;
        emit SetDiscipleVend(_num, _price);
    }
    
    function getDiscipleVend(uint _discipleId) public view returns (
        address owner,
        address bidder,
        uint offer
    ) {
        owner = DiscipleSaleToBuyer[_discipleId];
        bidder = DiscipleVendToBidder[_discipleId];
        offer = DiscipleVendToOffer[_discipleId];
    }
}

contract PreSaleAssets is PreSaleDisciple {
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event BuyDiscipleItem(address indexed buyer, uint indexed rarity, uint indexed number, uint currentPrice);
    event BuyGuardianRune(address indexed buyer, uint indexed rarity, uint indexed number, uint currentPrice);
    
    event SetDiscipleItem(uint indexed rarity, uint indexed price);
    event SetGuardianRune(uint indexed rarity, uint indexed price);
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (address => uint) PlayerOwnRareItem;
    mapping (address => uint) PlayerOwnEpicItem;
    mapping (address => uint) PlayerOwnLegendaryItem;
    mapping (address => uint) PlayerOwnUniqueItem;
    
    mapping (address => uint) PlayerOwnRareRune;
    mapping (address => uint) PlayerOwnEpicRune;
    mapping (address => uint) PlayerOwnLegendaryRune;
    mapping (address => uint) PlayerOwnUniqueRune;
    
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    uint[4] public DiscipleItem = [
        0.68 ether,
        1.98 ether,
        4.88 ether,
        9.98 ether
    ];
    
    uint[4] public GuardianRune = [
        1.18 ether,
        4.88 ether,
        8.88 ether,
        13.88 ether
    ];
    
    uint itemTimeStamp;
    uint runeTimeStamp;
    // ----------------------------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Function
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Public Function
    // ----------------------------------------------------------------------------
    function buyDiscipleItem(uint _rarity, uint _num, uint _brokerId, uint _subBrokerId) public payable whenNotPaused {
        require(_rarity >= 0 && _rarity <= 4);
        uint currentPrice;
        if(pricePause == true) {
            if(itemTimeStamp != 0 && itemTimeStamp != endTime) {
                uint timePass = safeSub(endTime, startTime);
                DiscipleItem[0] = _computePrice(DiscipleItem[0], DiscipleItem[0]*raiseIndex[2], preSaleDurance, timePass);
                DiscipleItem[1] = _computePrice(DiscipleItem[1], DiscipleItem[1]*raiseIndex[2], preSaleDurance, timePass);
                DiscipleItem[2] = _computePrice(DiscipleItem[2], DiscipleItem[2]*raiseIndex[2], preSaleDurance, timePass);
                DiscipleItem[3] = _computePrice(DiscipleItem[3], DiscipleItem[3]*raiseIndex[2], preSaleDurance, timePass);
                itemTimeStamp = endTime;
            }
            require(msg.value >= DiscipleItem[_rarity]*_num);
            currentPrice = DiscipleItem[_rarity]*_num;
            _brokerFeeDistribute(currentPrice, 2, _brokerId, _subBrokerId);
        } else {
            if(itemTimeStamp == 0) {
                itemTimeStamp = uint(now);
            }
            currentPrice = _computePrice(DiscipleItem[_rarity], DiscipleItem[_rarity]*raiseIndex[2], preSaleDurance, safeSub(uint(now), startTime));
            require(msg.value >= currentPrice*_num);
            currentPrice = currentPrice*_num;
            _brokerFeeDistribute(currentPrice, 2, _brokerId, _subBrokerId);
        }
        if(_rarity == 0) {
            PlayerOwnRareItem[msg.sender] = safeAdd(PlayerOwnRareItem[msg.sender], _num);
        } else if (_rarity == 1) {
            PlayerOwnEpicItem[msg.sender] = safeAdd(PlayerOwnEpicItem[msg.sender], _num);
        } else if (_rarity == 2) {
            PlayerOwnLegendaryItem[msg.sender] = safeAdd(PlayerOwnLegendaryItem[msg.sender], _num);
        } else if (_rarity == 3) {
            PlayerOwnUniqueItem[msg.sender] = safeAdd(PlayerOwnUniqueItem[msg.sender], _num);
        }
        emit BuyDiscipleItem(msg.sender, _rarity, _num, currentPrice);
    }   
    
    function buyGuardianRune(uint _rarity, uint _num, uint _brokerId, uint _subBrokerId) public payable whenNotPaused {
        require(_rarity >= 0 && _rarity <= 4);
        uint currentPrice;
        if(pricePause == true) {
            if(runeTimeStamp != 0 && runeTimeStamp != endTime) {
                uint timePass = safeSub(endTime, startTime);
                GuardianRune[0] = _computePrice(GuardianRune[0], GuardianRune[0]*raiseIndex[2], preSaleDurance, timePass);
                GuardianRune[1] = _computePrice(GuardianRune[1], GuardianRune[1]*raiseIndex[2], preSaleDurance, timePass);
                GuardianRune[2] = _computePrice(GuardianRune[2], GuardianRune[2]*raiseIndex[2], preSaleDurance, timePass);
                GuardianRune[3] = _computePrice(GuardianRune[3], GuardianRune[3]*raiseIndex[2], preSaleDurance, timePass);
                runeTimeStamp = endTime;
            }
            require(msg.value >= GuardianRune[_rarity]*_num);
            currentPrice = GuardianRune[_rarity]*_num;
            _brokerFeeDistribute(currentPrice, 2, _brokerId, _subBrokerId);
        } else {
            if(runeTimeStamp == 0) {
                runeTimeStamp = uint(now);
            }
            currentPrice = _computePrice(GuardianRune[_rarity], GuardianRune[_rarity]*raiseIndex[2], preSaleDurance, safeSub(uint(now), startTime));
            require(msg.value >= currentPrice*_num);
            currentPrice = currentPrice*_num;
            _brokerFeeDistribute(currentPrice, 2, _brokerId, _subBrokerId);
        }
        if(_rarity == 0) {
            PlayerOwnRareRune[msg.sender] = safeAdd(PlayerOwnRareRune[msg.sender], _num);
        } else if (_rarity == 1) {
            PlayerOwnEpicRune[msg.sender] = safeAdd(PlayerOwnEpicRune[msg.sender], _num);
        } else if (_rarity == 2) {
            PlayerOwnLegendaryRune[msg.sender] = safeAdd(PlayerOwnLegendaryRune[msg.sender], _num);
        } else if (_rarity == 3) {
            PlayerOwnUniqueRune[msg.sender] = safeAdd(PlayerOwnUniqueRune[msg.sender], _num);
        }
        emit BuyGuardianRune(msg.sender, _rarity, _num, currentPrice);
    }
    
    function setDiscipleItem(uint _rarity, uint _price) public onlyAdmin {
        DiscipleItem[_rarity] = _price;
        emit SetDiscipleItem(_rarity, _price);
    }
    
    function setGuardianRune(uint _rarity, uint _price) public onlyAdmin {
        GuardianRune[_rarity] = _price;
        emit SetDiscipleItem(_rarity, _price);
    }
    
    function getPlayerInventory(address _player) public view returns (
        uint rareItem,
        uint epicItem,
        uint legendaryItem,
        uint uniqueItem,
        uint rareRune,
        uint epicRune,
        uint legendaryRune,
        uint uniqueRune
    ) {
        rareItem = PlayerOwnRareItem[_player];
        epicItem = PlayerOwnEpicItem[_player];
        legendaryItem = PlayerOwnLegendaryItem[_player];
        uniqueItem = PlayerOwnUniqueItem[_player];
        rareRune = PlayerOwnRareRune[_player];
        epicRune = PlayerOwnEpicRune[_player];
        legendaryRune = PlayerOwnLegendaryRune[_player];
        uniqueRune = PlayerOwnUniqueRune[_player];
    }
}

contract PreSale is PreSaleAssets {
    constructor() public {
        CEOAddress = msg.sender;
        BrokerIdToBrokers[0].push(msg.sender);
    }
}