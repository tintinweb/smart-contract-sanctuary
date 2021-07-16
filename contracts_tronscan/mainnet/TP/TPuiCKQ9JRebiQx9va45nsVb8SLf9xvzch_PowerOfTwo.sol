//SourceUnit: PowerOfTwo.sol

/**
* ==========================================================
*
* Power of 2
* FIRST EVER FULLY DECENTRALIZED GLOBAL POWERLINE AUTOPOOL
*
* Website  : https://powerof2.run
*
* ==========================================================
**/

pragma solidity >=0.5.8;

contract PowerOfTwo {
    
    struct User {
        uint256 id;
        uint256 referrerCount;
        uint256 sponsorId;
        uint256 earnFromPrime;
        uint256 earnFromXFactor;
        uint256 _cntReinvestXFactor;
        uint256[] xFactorSlots1;
        uint256[] xFactorSlots2;
        uint256[] xFactorSlots3;
        uint256[] xFactorSlots4;
        uint256[] xFactorSlots5;
        uint256[] xFactorSlots6;
        uint256[] xFactorSlots7;
        uint256[] xFactorSlots8;
        uint256[] xFactorSlots9;
        uint256[] xFactorSlots10;
    }
    
    struct xFactorSlot {
        uint256 id;
        address _owner;
        uint256 _upperSlot;
        uint256[] _downlineSlots;
        uint8 _level;
        uint8 activeLeg;
        address[] referrals;
        bool closed;
    }
    
    struct Prime {
        uint256 id;
        uint256 partnersCnt;
        address sponsorAddress;
    }

    modifier validReferrerId(uint256 _referrerID) {
        require(_referrerID > 0 && _referrerID <= freeuserId, 'Invalid sponsor ID');
        _;
      }
   
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier checkRegistered() {
        require(freeUsers[msg.sender].id == 0, "Already Registered");
        _;
    }
    
    mapping(address => User) public freeUsers;
    uint256 public freeuserId = 1;

    address[] public whiteList;    
    
    mapping(uint256 => address) public idToAddress;
    mapping(uint8 => uint8) public uplineAmount;
    mapping(uint8 => uint256) public slotPrice;

    mapping(uint8 => uint256) public PrimeId;
    mapping(uint8 => uint256) public xFactorId;
    
    mapping(address => Prime) public PrimeLevel_1;
    mapping(address => Prime) public PrimeLevel_2;
    mapping(address => Prime) public PrimeLevel_3;
    mapping(address => Prime) public PrimeLevel_4;
    mapping(address => Prime) public PrimeLevel_5;
    mapping(address => Prime) public PrimeLevel_6;
    mapping(address => Prime) public PrimeLevel_7;
    mapping(address => Prime) public PrimeLevel_8;
    mapping(address => Prime) public PrimeLevel_9;
    mapping(address => Prime) public PrimeLevel_10;

    mapping(address => bool) public activeXFactor_1;
    mapping(address => bool) public activeXFactor_2;
    mapping(address => bool) public activeXFactor_3;
    mapping(address => bool) public activeXFactor_4;
    mapping(address => bool) public activeXFactor_5;
    mapping(address => bool) public activeXFactor_6;
    mapping(address => bool) public activeXFactor_7;
    mapping(address => bool) public activeXFactor_8;
    mapping(address => bool) public activeXFactor_9;
    mapping(address => bool) public activeXFactor_10;
       
    mapping(uint256 => xFactorSlot) public xFactorLevel1;
    mapping(uint256 => xFactorSlot) public xFactorLevel2;
    mapping(uint256 => xFactorSlot) public xFactorLevel3;
    mapping(uint256 => xFactorSlot) public xFactorLevel4;
    mapping(uint256 => xFactorSlot) public xFactorLevel5;
    mapping(uint256 => xFactorSlot) public xFactorLevel6;
    mapping(uint256 => xFactorSlot) public xFactorLevel7;
    mapping(uint256 => xFactorSlot) public xFactorLevel8;
    mapping(uint256 => xFactorSlot) public xFactorLevel9;
    mapping(uint256 => xFactorSlot) public xFactorLevel10;

    uint256 public USDtoTRX = 30000000; // 1 USD = TRX * 10^6
    address public owner;
    
    event payXFactor(uint256 amount, uint8 indexed _level, address indexed _userAddress, uint256 _time);
    event payPrime(uint256 amount, uint8 indexed _level, address indexed _userAddress, uint256 _time);
    event lostReferralPayment(address indexed _sponsorAddress, uint8 _level, uint256 amount);
    event RefPayment(uint256 amount, address indexed _sponsorAddress, address indexed _fromAddress, uint256 _level, uint256 _time);
    event DistributePayment(uint256 amount, address indexed _sponsorAddress, address indexed _fromAddress, uint256 _time);
    event FreeRegister(address indexed _userAddress, uint256 _time);
    event PaidRegister(address indexed _userAddress, uint256 _time);
    
    constructor() public {
        
        uplineAmount[1] = 10;
        uplineAmount[2] = 10;
        uplineAmount[3] = 10;
        uplineAmount[4] = 10;
        uplineAmount[5] = 10;
        uplineAmount[6] = 10;
        uplineAmount[7] = 10;
        uplineAmount[8] = 10;
        uplineAmount[9] = 10;
        uplineAmount[10] = 10;
        
        slotPrice[1] = 5 sun * USDtoTRX;
        slotPrice[2] = 10 sun * USDtoTRX;
        slotPrice[3] = 20 sun * USDtoTRX;
        slotPrice[4] = 40 sun * USDtoTRX;
        slotPrice[5] = 80 sun * USDtoTRX;
        slotPrice[6] = 160 sun * USDtoTRX;
        slotPrice[7] = 320 sun * USDtoTRX;
        slotPrice[8] = 640 sun * USDtoTRX;
        slotPrice[9] = 1280 sun * USDtoTRX;
        slotPrice[10] = 2560 sun * USDtoTRX;

        owner = msg.sender;
        initialSlots();

    }

    function addToWhiteList(address _addressToAdd) public payable isOwner returns (bool) {
        whiteList.push(_addressToAdd);
        return true;
    }

    function clearWhiteList() public payable isOwner returns (bool) {
        whiteList.length = 0;
        return true;
    }

    function checkWhiteListed(address _addressToCheck) private view returns (bool) {
        uint256 arrayLength = whiteList.length;
        if (whiteList.length == 0) return true;
        for (uint i=0; i<arrayLength; i++) {
          if (whiteList[i] == _addressToCheck) return true;
        }
        return false;
    } 
    
    function initialSlots() private {
               
        PrimeId[1] = 1;
        PrimeId[2] = 1;
        PrimeId[3] = 1;
        PrimeId[4] = 1;
        PrimeId[5] = 1;
        PrimeId[6] = 1;
        PrimeId[7] = 1;
        PrimeId[8] = 1;
        PrimeId[9] = 1;
        PrimeId[10] = 1;

        xFactorId[1] = 2;
        xFactorId[2] = 2;
        xFactorId[3] = 2;
        xFactorId[4] = 2;
        xFactorId[5] = 2;
        xFactorId[6] = 2;
        xFactorId[7] = 2;
        xFactorId[8] = 2;
        xFactorId[9] = 2;
        xFactorId[10] = 2;
               
        freeUsers[owner] = User({
            id: freeuserId,
            referrerCount: uint256(0),
            sponsorId: uint256(1),
            earnFromPrime: uint256(0),
            earnFromXFactor: uint256(0),
            _cntReinvestXFactor: uint256(0),
            xFactorSlots1: new uint256[](0),
            xFactorSlots2: new uint256[](0),
            xFactorSlots3: new uint256[](0),
            xFactorSlots4: new uint256[](0),
            xFactorSlots5: new uint256[](0),
            xFactorSlots6: new uint256[](0),
            xFactorSlots7: new uint256[](0),
            xFactorSlots8: new uint256[](0),
            xFactorSlots9: new uint256[](0),
            xFactorSlots10: new uint256[](0)
        });
        idToAddress[freeuserId] = owner;
        freeUsers[owner].xFactorSlots1.push(1);
        freeUsers[owner].xFactorSlots2.push(1);
        freeUsers[owner].xFactorSlots3.push(1);
        freeUsers[owner].xFactorSlots4.push(1);
        freeUsers[owner].xFactorSlots5.push(1);
        freeUsers[owner].xFactorSlots6.push(1);
        freeUsers[owner].xFactorSlots7.push(1);
        freeUsers[owner].xFactorSlots8.push(1);
        freeUsers[owner].xFactorSlots9.push(1);
        freeUsers[owner].xFactorSlots10.push(1);

        xFactorSlot memory slot1 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel1[1] = slot1;

        xFactorSlot memory slot2 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel2[1] = slot2;

        xFactorSlot memory slot3 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel3[1] = slot3;

        xFactorSlot memory slot4 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel4[1] = slot4;

        xFactorSlot memory slot5 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel5[1] = slot5;

        xFactorSlot memory slot6 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel6[1] = slot6;

        xFactorSlot memory slot7 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel7[1] = slot7;

        xFactorSlot memory slot8 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel8[1] = slot8;

        xFactorSlot memory slot9 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel9[1] = slot9;

        xFactorSlot memory slot10 = xFactorSlot({
            id: 1,
            _owner: owner,
            _upperSlot: 1,
            _downlineSlots: new uint256[](0),
            _level: 1,
            activeLeg: 0,
            referrals: new address[](0),
            closed: false
        });
        xFactorLevel10[1] = slot10;
        
        activeXFactor_1[msg.sender] = true;
        activeXFactor_2[msg.sender] = true;
        activeXFactor_3[msg.sender] = true;
        activeXFactor_4[msg.sender] = true;
        activeXFactor_5[msg.sender] = true;
        activeXFactor_6[msg.sender] = true;
        activeXFactor_7[msg.sender] = true;
        activeXFactor_8[msg.sender] = true;
        activeXFactor_9[msg.sender] = true;
        activeXFactor_10[msg.sender] = true;
        
        PrimeLevel_1[msg.sender] = Prime({
            id: PrimeId[1],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_2[msg.sender] = Prime({
            id: PrimeId[2],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_3[msg.sender] = Prime({
            id: PrimeId[3],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_4[msg.sender] = Prime({
            id: PrimeId[4],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_5[msg.sender] = Prime({
            id: PrimeId[5],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_6[msg.sender] = Prime({
            id: PrimeId[6],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_7[msg.sender] = Prime({
            id: PrimeId[7],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_8[msg.sender] = Prime({
            id: PrimeId[8],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_9[msg.sender] = Prime({
            id: PrimeId[9],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        PrimeLevel_10[msg.sender] = Prime({
            id: PrimeId[10],
            partnersCnt: 0,
            sponsorAddress: owner
        });
        
    }
    
    function () external payable {

    }
    
    function UpdateTRXPrice(uint256 _digits) public payable isOwner {
        USDtoTRX = _digits; // 1 TRX = USD * 10^6
        slotPrice[1] = 5 * USDtoTRX;
        slotPrice[2] = 10 * USDtoTRX;
        slotPrice[3] = 20 * USDtoTRX;
        slotPrice[4] = 40 * USDtoTRX;
        slotPrice[5] = 80 * USDtoTRX;
        slotPrice[6] = 160 * USDtoTRX;
        slotPrice[7] = 320 * USDtoTRX;
        slotPrice[8] = 640 * USDtoTRX;
        slotPrice[9] = 1280 * USDtoTRX;
        slotPrice[10] = 2560 * USDtoTRX;
    }
    
    function USDToTrx(uint256 _amount) public view returns (uint256 _usdInTrx) {
        _usdInTrx = (_amount * USDtoTRX);
        return _usdInTrx;
    }
    
    function register(uint256 _referrerID) 
        public 
        payable 
        checkRegistered
        validReferrerId(_referrerID) 
    {
        bool _check = checkWhiteListed(msg.sender);
        require(_check == true, "You are not allowed to register yet.");
        address _userAddress = msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        require(msg.value == 0, "Incorrect register data");
        
        freeuserId++;
        freeUsers[msg.sender] = User({
            id: freeuserId,
            referrerCount: 0,
            sponsorId: _referrerID,
            earnFromPrime: uint256(0),
            earnFromXFactor: uint256(0),
            _cntReinvestXFactor: uint256(0),
            xFactorSlots1: new uint256[](0),
            xFactorSlots2: new uint256[](0),
            xFactorSlots3: new uint256[](0),
            xFactorSlots4: new uint256[](0),
            xFactorSlots5: new uint256[](0),
            xFactorSlots6: new uint256[](0),
            xFactorSlots7: new uint256[](0),
            xFactorSlots8: new uint256[](0),
            xFactorSlots9: new uint256[](0),
            xFactorSlots10: new uint256[](0)
        });
        idToAddress[freeuserId] = msg.sender;
        address _sponsorAddress = idToAddress[_referrerID];
        freeUsers[_sponsorAddress].referrerCount++;
        emit FreeRegister(msg.sender, block.timestamp);
        
    }
    
    function registerWithUpgrade(uint256 _referrerID) 
        public 
        payable 
        checkRegistered
        validReferrerId(_referrerID) 
    {
     
        bool _check = checkWhiteListed(msg.sender);
        require(_check == true, "You are not allowed to register yet.");
        address _userAddress = msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        uint256 calculatedValue = slotPrice[1] * 2;
        require(msg.value == calculatedValue, "Incorrect purchase value");
        
        freeuserId++;
        freeUsers[msg.sender] = User({
            id: freeuserId,
            referrerCount: 0,
            sponsorId: _referrerID,
            earnFromPrime: uint256(0),
            earnFromXFactor: uint256(0),
            _cntReinvestXFactor: uint256(0),
            xFactorSlots1: new uint256[](0),
            xFactorSlots2: new uint256[](0),
            xFactorSlots3: new uint256[](0),
            xFactorSlots4: new uint256[](0),
            xFactorSlots5: new uint256[](0),
            xFactorSlots6: new uint256[](0),
            xFactorSlots7: new uint256[](0),
            xFactorSlots8: new uint256[](0),
            xFactorSlots9: new uint256[](0),
            xFactorSlots10: new uint256[](0)
        });
        idToAddress[freeuserId] = msg.sender;
        address _sponsorAddress = idToAddress[_referrerID];
        freeUsers[_sponsorAddress].referrerCount++;

        emit PaidRegister(msg.sender, block.timestamp);

        buyXFactorBatch(1, calculatedValue);
        buyPrimeBatch(1, _referrerID, calculatedValue);

    }
    
    function buyBatch(uint8 _level, uint256 _referrerID) public payable {
        require( _level > 0 && _level <= 10, "Incorrect level");
        uint256 calculatedValue = slotPrice[_level] * 2;
        require(msg.value == calculatedValue, "Incorrect purchase value");
        buyPrimeBatch(_level, _referrerID, calculatedValue);
        buyXFactorBatch(_level, calculatedValue);
    }
    
    function buyXFactor(uint8 _level) public payable {
        uint256 calculatedValue = slotPrice[_level];
        require(msg.value == slotPrice[_level], "Incorrect purchase value");
        buyXFactorBatch(_level, calculatedValue);
    }
    
    function buyXFactorBatch(uint8 _level, uint256 calculatedValue) private {
        
        require( _level > 0 && _level <= 10, "Incorrect level");
        require(msg.value == calculatedValue, "Incorrect purchase value");
        if (_level == 1) { require(activeXFactor_1[msg.sender] != true, "You already purchased this slot!");

         }
        if (_level == 2) { require(activeXFactor_2[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_1[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 3) { require(activeXFactor_3[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_2[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 4) { require(activeXFactor_4[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_3[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 5) { require(activeXFactor_5[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_4[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 6) { require(activeXFactor_6[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_5[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 7) { require(activeXFactor_7[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_6[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 8) { require(activeXFactor_8[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_7[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 9) { require(activeXFactor_9[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_8[msg.sender] == true, "You must buy Previous slot");
         }
        if (_level == 10) { require(activeXFactor_10[msg.sender] != true, "You already purchased this slot!");
                            require(activeXFactor_9[msg.sender] == true, "You must buy Previous slot");
         }
        address _userAddress = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        if (_level == 1) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_1[_userAddress] = true;
            xFactorLevel1[activeSlot].referrals.push(_userAddress);
            xFactorLevel1[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel1[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel1[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots1.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel1[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel1[xFactorLevel1[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel1[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel1[xFactorLevel1[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel1[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel1[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel1[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel1[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel1[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel1[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel1[_slotIdToReinvest]._owner].xFactorSlots1.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel1[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level] - 1;
            uint8 _upperSlotLeg = xFactorLevel1[xFactorLevel1[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel1[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 2) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_2[_userAddress] = true;
            xFactorLevel2[activeSlot].referrals.push(_userAddress);
            xFactorLevel2[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel2[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel2[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots2.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel2[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel2[xFactorLevel2[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel2[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel2[xFactorLevel2[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel2[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel2[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel2[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel2[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel2[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel2[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel2[_slotIdToReinvest]._owner].xFactorSlots2.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel2[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel2[xFactorLevel2[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel2[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 3) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_3[_userAddress] = true;
            xFactorLevel3[activeSlot].referrals.push(_userAddress);
            xFactorLevel3[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel3[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel3[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots3.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel3[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel3[xFactorLevel3[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel3[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel3[xFactorLevel3[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel3[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel3[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel3[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel3[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel3[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel3[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel3[_slotIdToReinvest]._owner].xFactorSlots3.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel3[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel3[xFactorLevel3[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel3[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }
        if (_level == 4) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_4[_userAddress] = true;
            xFactorLevel4[activeSlot].referrals.push(_userAddress);
            xFactorLevel4[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel4[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel4[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots4.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel4[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel4[xFactorLevel4[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel4[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel4[xFactorLevel4[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel4[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel4[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel4[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel4[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel4[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel4[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel4[_slotIdToReinvest]._owner].xFactorSlots4.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel4[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel4[xFactorLevel4[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel4[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 5) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_5[_userAddress] = true;
            xFactorLevel5[activeSlot].referrals.push(_userAddress);
            xFactorLevel5[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel5[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel5[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots5.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel5[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel5[xFactorLevel5[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel5[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel5[xFactorLevel5[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel5[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel5[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel5[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel5[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel5[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel5[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel5[_slotIdToReinvest]._owner].xFactorSlots5.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel5[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel5[xFactorLevel5[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel5[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 6) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_6[_userAddress] = true;
            xFactorLevel6[activeSlot].referrals.push(_userAddress);
            xFactorLevel6[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel6[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel6[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots6.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel6[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel6[xFactorLevel6[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel6[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel6[xFactorLevel6[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel6[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel6[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel6[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel6[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel6[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel6[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel6[_slotIdToReinvest]._owner].xFactorSlots6.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel6[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel6[xFactorLevel6[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel6[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 7) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_7[_userAddress] = true;
            xFactorLevel7[activeSlot].referrals.push(_userAddress);
            xFactorLevel7[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel7[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel7[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots7.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel7[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel7[xFactorLevel7[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel7[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel7[xFactorLevel7[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel7[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel7[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel7[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel7[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel7[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel7[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel7[_slotIdToReinvest]._owner].xFactorSlots7.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel7[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel7[xFactorLevel7[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel7[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 8) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_8[_userAddress] = true;
            xFactorLevel8[activeSlot].referrals.push(_userAddress);
            xFactorLevel8[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel8[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel8[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots8.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel8[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel8[xFactorLevel8[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel8[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel8[xFactorLevel8[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel8[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel8[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel8[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel8[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel8[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel8[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel8[_slotIdToReinvest]._owner].xFactorSlots8.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel8[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel8[xFactorLevel8[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel8[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 9) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_9[_userAddress] = true;
            xFactorLevel9[activeSlot].referrals.push(_userAddress);
            xFactorLevel9[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel9[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel9[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots9.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel9[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel9[xFactorLevel9[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel9[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel9[xFactorLevel9[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel9[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel9[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel9[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel9[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel9[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel9[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel9[_slotIdToReinvest]._owner].xFactorSlots9.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel9[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel9[xFactorLevel9[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel9[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }

        if (_level == 10) {            

            address sponsorAddress = findUpgradedSponsorX(idToAddress[freeUsers[_userAddress].sponsorId], _level);
            uint256 activeSlot = NewSlotParent(_level, sponsorAddress);
            activeXFactor_10[_userAddress] = true;
            xFactorLevel10[activeSlot].referrals.push(_userAddress);
            xFactorLevel10[activeSlot]._downlineSlots.push(xFactorId[_level]);
            xFactorLevel10[activeSlot].activeLeg++;

            xFactorSlot memory slot = xFactorSlot({
                id: xFactorId[_level],
                _owner: _userAddress,
                _upperSlot: activeSlot,
                _downlineSlots: new uint256[](0),
                _level: _level,
                activeLeg: 0,
                referrals: new address[](0),
                closed: false
            });
            xFactorLevel10[xFactorId[_level]] = slot;
            freeUsers[_userAddress].xFactorSlots10.push(xFactorId[_level]);

            xFactorId[_level]++;

            if (xFactorLevel10[activeSlot].activeLeg == 2) { 

                uint256 _slotID2 = xFactorLevel10[xFactorLevel10[activeSlot]._upperSlot]._downlineSlots[1]; 

                if (xFactorLevel10[_slotID2].activeLeg == 2) { 

                    uint256 _slotIdToReinvest = xFactorLevel10[xFactorLevel10[activeSlot]._upperSlot].id;

                    freeUsers[xFactorLevel10[_slotIdToReinvest]._owner]._cntReinvestXFactor++;

                    xFactorSlot memory reslot = xFactorLevel10[_slotIdToReinvest];
                    reslot.referrals = new address[](0);
                    reslot._downlineSlots = new uint256[](0);
                    reslot.activeLeg = 0;
                    uint256 findUpperSlot = NewSlotParent(_level, xFactorLevel10[_slotIdToReinvest]._owner);
                    reslot._upperSlot = findUpperSlot;
                    xFactorLevel10[findUpperSlot].activeLeg++;
                    reslot.id = xFactorId[_level];
                    xFactorLevel10[findUpperSlot]._downlineSlots.push(xFactorId[_level]);
                    xFactorLevel10[xFactorId[_level]] = reslot;
                    freeUsers[xFactorLevel10[_slotIdToReinvest]._owner].xFactorSlots10.push(xFactorId[_level]);
                    xFactorId[_level]++;

                    xFactorLevel10[_slotIdToReinvest].closed = true;

                }

            }

            uint256 _lastCreatedSlotId = xFactorId[_level]-1;
            uint8 _upperSlotLeg = xFactorLevel10[xFactorLevel10[_lastCreatedSlotId]._upperSlot].activeLeg;
            address _nextPaymentAddress = NextPaymentAddress(_level, _upperSlotLeg, xFactorLevel10[_lastCreatedSlotId]._upperSlot);
            payMagic(_nextPaymentAddress, _level);
        
        }
        
        emit payXFactor(slotPrice[_level], _level, msg.sender, block.timestamp);
    }
   
    function findUpgradedSponsor(address _sponsorAddress, uint8 _level) private view returns (address)  {
        require( _level > 0 && _level <= 10, "Incorrect level");
        if (_level == 1) {
            while (true) {
                if (PrimeLevel_1[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 2) {
            while (true) {
                if (PrimeLevel_2[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 3) {
            while (true) {
                if (PrimeLevel_3[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 4) {
            while (true) {
                if (PrimeLevel_4[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 5) {
            while (true) {
                if (PrimeLevel_5[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 6) {
            while (true) {
                if (PrimeLevel_6[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 7) {
            while (true) {
                if (PrimeLevel_7[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 8) {
            while (true) {
                if (PrimeLevel_8[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 9) {
            while (true) {
                if (PrimeLevel_9[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 10) {
            while (true) {
                if (PrimeLevel_10[_sponsorAddress].id == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
    }

    function findUpgradedSponsorX(address _sponsorAddress, uint8 _level) private view returns (address)  {
        require( _level > 0 && _level <= 10, "Incorrect level");
        if (_level == 1) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots1.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 2) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots2.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 3) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots3.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 4) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots4.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 5) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots5.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 6) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots6.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 7) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots7.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 8) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots8.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 9) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots9.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 10) {
            while (true) {
                if (freeUsers[_sponsorAddress].xFactorSlots10.length == 0) {
                    uint256 nextRefId = freeUsers[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
    }

    function NewSlotParent(uint8 _level, address sponsorAddress) private view returns (uint256 slotId) {
       
        uint8 activeSlotLeg = 0;
        uint256 activeSponsorSlotID = 0;

        if (_level == 1) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots1.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots1[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel1[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel1[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel1[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel1[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel1[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel1[downlineSlot1].activeLeg == 2) && (xFactorLevel1[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel1[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel1[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 2) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots2.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots2[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel2[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel2[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel2[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel2[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel2[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel2[downlineSlot1].activeLeg == 2) && (xFactorLevel2[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel2[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel2[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 3) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots3.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots3[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel3[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel3[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel3[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel3[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel3[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel3[downlineSlot1].activeLeg == 2) && (xFactorLevel3[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel3[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel3[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 4) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots4.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots4[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel4[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel4[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel4[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel4[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel4[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel4[downlineSlot1].activeLeg == 2) && (xFactorLevel4[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel4[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel4[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 5) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots5.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots5[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel5[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel5[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel5[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel5[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel5[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel5[downlineSlot1].activeLeg == 2) && (xFactorLevel5[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel5[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel5[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 6) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots6.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots6[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel6[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel6[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel6[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel6[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel6[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel6[downlineSlot1].activeLeg == 2) && (xFactorLevel6[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel6[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel6[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 7) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots7.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots7[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel7[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel7[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel7[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel7[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel7[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel7[downlineSlot1].activeLeg == 2) && (xFactorLevel7[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel7[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel7[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 8) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots8.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots8[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel8[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel8[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel8[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel8[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel8[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel8[downlineSlot1].activeLeg == 2) && (xFactorLevel8[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel8[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel8[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 9) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots9.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots9[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel9[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel9[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel9[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel9[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel9[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel9[downlineSlot1].activeLeg == 2) && (xFactorLevel9[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel9[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel9[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }
        if (_level == 10) {
            uint256 SlotIndex = freeUsers[sponsorAddress].xFactorSlots10.length - 1; 
            activeSponsorSlotID = freeUsers[sponsorAddress].xFactorSlots10[SlotIndex];  // 11
            while (true) {
                activeSlotLeg = xFactorLevel10[activeSponsorSlotID].activeLeg; 
                if (activeSlotLeg == 2) {
                    uint256 downlineSlot1 = xFactorLevel10[activeSponsorSlotID]._downlineSlots[0];
                    if (xFactorLevel10[downlineSlot1].activeLeg < 2) { 
                        return downlineSlot1;
                    } 
                    uint256 downlineSlot2 = xFactorLevel10[activeSponsorSlotID]._downlineSlots[1];
                    if (xFactorLevel10[downlineSlot2].activeLeg < 2) { 
                        return downlineSlot2;
                    }
                    if ((xFactorLevel10[downlineSlot1].activeLeg == 2) && (xFactorLevel10[downlineSlot2].activeLeg == 2)) {
                        activeSponsorSlotID = xFactorLevel10[downlineSlot1]._downlineSlots[0];
                    }
                } else {
                    if (SlotIndex > 0) {
                        activeSponsorSlotID = xFactorLevel10[activeSponsorSlotID]._upperSlot;
                    } else {
                        return activeSponsorSlotID;  
                    }
                    if (activeSponsorSlotID == 1) return activeSponsorSlotID;
                }
            }
        }

    }   
   
    function buyPrime(uint8 _level, uint256 _referrerID) public payable {
        uint256 calculatedValue = slotPrice[_level];
        require(msg.value == slotPrice[_level], "Incorrect purchase value");
        buyPrimeBatch(_level, _referrerID, calculatedValue);
    }
    
    function buyPrimeBatch(uint8 _level, uint256 _referrerID, uint256 calculatedValue) private validReferrerId(_referrerID) {
        
        require( _level > 0 && _level <= 10, "Incorrect level");
        require(msg.value == calculatedValue, "Incorrect purchase value");
        
        address _userAddress = msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        address _sponsorAddress = idToAddress[_referrerID];
        uint256 amountToDistribute = slotPrice[_level];
        
        if (_level == 1) {
            
            require(PrimeLevel_1[_userAddress].id == 0, "You already activated Prime Slot 1");
            PrimeId[1]++;
            PrimeLevel_1[_userAddress] = Prime({
                id: PrimeId[1],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_1[_sponsorAddress].partnersCnt++;

        }
        if (_level == 2) {
            
            require(PrimeLevel_2[_userAddress].id == 0, "You already activated Prime Slot 2");
            require(PrimeLevel_1[_userAddress].id != 0, "You have to upgrade in Prime Slot 1 before you can upgrade in Slot 2");
            PrimeId[2]++;
            PrimeLevel_2[_userAddress] = Prime({
                id: PrimeId[2],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_2[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 3) {
            
            require(PrimeLevel_3[_userAddress].id == 0, "You already activated Prime Slot 3");
            require(PrimeLevel_2[_userAddress].id != 0, "You have to upgrade in Prime Slot 2 before you can upgrade in Slot 3");
            PrimeId[3]++;
            PrimeLevel_3[_userAddress] = Prime({
                id: PrimeId[3],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_3[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 4) {
            
            require(PrimeLevel_4[_userAddress].id == 0, "You already activated Prime Slot 4");
            require(PrimeLevel_3[_userAddress].id != 0, "You have to upgrade in Prime Slot 3 before you can upgrade in Slot 4");
            PrimeId[4]++;
            PrimeLevel_4[_userAddress] = Prime({
                id: PrimeId[4],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_4[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 5) {
            
            require(PrimeLevel_5[_userAddress].id == 0, "You already activated Prime Slot 5");
            require(PrimeLevel_4[_userAddress].id != 0, "You have to upgrade in Prime Slot 4 before you can upgrade in Slot 5");
            PrimeId[5]++;
            PrimeLevel_5[_userAddress] = Prime({
                id: PrimeId[5],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_5[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 6) {
            
            require(PrimeLevel_6[_userAddress].id == 0, "You already activated Prime Slot 6");
            require(PrimeLevel_5[_userAddress].id != 0, "You have to upgrade in Prime Slot 5 before you can upgrade in Slot 6");
            PrimeId[6]++;
            PrimeLevel_6[_userAddress] = Prime({
                id: PrimeId[6],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_6[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 7) {
            
            require(PrimeLevel_7[_userAddress].id == 0, "You already activated Prime Slot 7");
            require(PrimeLevel_6[_userAddress].id != 0, "You have to upgrade in Prime Slot 6 before you can upgrade in Slot 7");
            PrimeId[7]++;
            PrimeLevel_7[_userAddress] = Prime({
                id: PrimeId[7],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_7[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 8) {
            
            require(PrimeLevel_8[_userAddress].id == 0, "You already activated Prime Slot 8");
            require(PrimeLevel_7[_userAddress].id != 0, "You have to upgrade in Prime Slot 7 before you can upgrade in Slot 8");
            PrimeId[8]++;
            PrimeLevel_8[_userAddress] = Prime({
                id: PrimeId[8],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_8[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 9) {
            
            require(PrimeLevel_9[_userAddress].id == 0, "You already activated Prime Slot 9");
            require(PrimeLevel_8[_userAddress].id != 0, "You have to upgrade in Prime Slot 8 before you can upgrade in Slot 9");
            PrimeId[9]++;
            PrimeLevel_9[_userAddress] = Prime({
                id: PrimeId[9],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_9[_sponsorAddress].partnersCnt++;
            
        }
        if (_level == 10) {
            
            require(PrimeLevel_10[_userAddress].id == 0, "You already activated Prime Slot 10");
            require(PrimeLevel_9[_userAddress].id != 0, "You have to upgrade in Prime Slot 9 before you can upgrade in Slot 10");
            PrimeId[10]++;
            PrimeLevel_10[_userAddress] = Prime({
                id: PrimeId[10],
                partnersCnt: 0,
                sponsorAddress: _sponsorAddress
            });
            PrimeLevel_10[_sponsorAddress].partnersCnt++;
            
        }
        
        address _findAddress = _sponsorAddress;

        for (uint8 i = 1; i <= 10; i++) {
            address _approvedSponsor = findUpgradedSponsor(_findAddress, _level);            
            uint256 paid = refPayment(slotPrice[_level], _approvedSponsor, i);
            freeUsers[_approvedSponsor].earnFromPrime += paid;
            amountToDistribute -= paid;
            _findAddress = idToAddress[freeUsers[_approvedSponsor].sponsorId];
        }
        
        if (amountToDistribute > 0) {
            freeUsers[idToAddress[1]].earnFromPrime += amountToDistribute;
            distributePayment(idToAddress[1], amountToDistribute);
        }
             
        emit payPrime(slotPrice[_level],_level, msg.sender, block.timestamp);   
    } 
    
    function refPayment(uint256 _payAmount, address _sponsorAddress, uint8 _refLevel) private returns (uint256 distributeAmount) {        
        require( _refLevel <= 10);
        distributeAmount = _payAmount / 100 * uplineAmount[_refLevel];
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            emit RefPayment(distributeAmount, _sponsorAddress, msg.sender, _refLevel, block.timestamp);
        }        
        return distributeAmount;
    }
    
    function distributePayment(address _sponsorAddress, uint256 _distributeAmount) private returns (uint256 distributeAmount) {
        uint256 payAmount = _distributeAmount;
        if (address(uint160(_sponsorAddress)).send(payAmount)) {
            emit DistributePayment(payAmount, _sponsorAddress, msg.sender, block.timestamp);
        }        
        return distributeAmount;
    }

    function isRegistered(address _userAddress) public view returns (bool) {
        return (freeUsers[_userAddress].id != 0);
    }
       
    function withdraw() payable isOwner public {
         msg.sender.transfer(address(this).balance);
    }

    function NextPaymentAddress(uint8 _level, uint8 _leg, uint256 _slot) private view returns (address _payTo) {
        if (_leg == 1) {
            if (_level == 1) _payTo = xFactorLevel1[_slot]._owner;
            if (_level == 2) _payTo = xFactorLevel2[_slot]._owner;
            if (_level == 3) _payTo = xFactorLevel3[_slot]._owner;
            if (_level == 4) _payTo = xFactorLevel4[_slot]._owner;
            if (_level == 5) _payTo = xFactorLevel5[_slot]._owner;
            if (_level == 6) _payTo = xFactorLevel6[_slot]._owner;
            if (_level == 7) _payTo = xFactorLevel7[_slot]._owner;
            if (_level == 8) _payTo = xFactorLevel8[_slot]._owner;
            if (_level == 9) _payTo = xFactorLevel9[_slot]._owner;
            if (_level == 10) _payTo = xFactorLevel10[_slot]._owner;
        }
        if (_leg == 2) {
            if (_level == 1) {
                uint256 prevSlot = xFactorLevel1[_slot]._upperSlot;
                _payTo = xFactorLevel1[prevSlot]._owner;
            }
            if (_level == 2) {
                uint256 prevSlot = xFactorLevel2[_slot]._upperSlot;
                _payTo = xFactorLevel2[prevSlot]._owner;
            }
            if (_level == 3) {
                uint256 prevSlot = xFactorLevel3[_slot]._upperSlot;
                _payTo = xFactorLevel3[prevSlot]._owner;
            }
            if (_level == 4) {
                uint256 prevSlot = xFactorLevel4[_slot]._upperSlot;
                _payTo = xFactorLevel4[prevSlot]._owner;
            }
            if (_level == 5) {
                uint256 prevSlot = xFactorLevel5[_slot]._upperSlot;
                _payTo = xFactorLevel5[prevSlot]._owner;
            }
            if (_level == 6) {
                uint256 prevSlot = xFactorLevel6[_slot]._upperSlot;
                _payTo = xFactorLevel6[prevSlot]._owner;
            }
            if (_level == 7) {
                uint256 prevSlot = xFactorLevel7[_slot]._upperSlot;
                _payTo = xFactorLevel7[prevSlot]._owner;
            }
            if (_level == 8) {
                uint256 prevSlot = xFactorLevel8[_slot]._upperSlot;
                _payTo = xFactorLevel8[prevSlot]._owner;
            }
            if (_level == 9) {
                uint256 prevSlot = xFactorLevel9[_slot]._upperSlot;
                _payTo = xFactorLevel9[prevSlot]._owner;
            }
            if (_level == 10) {
                uint256 prevSlot = xFactorLevel10[_slot]._upperSlot;
                _payTo = xFactorLevel10[prevSlot]._owner;
            }
        }
        return _payTo;
    }
    
    function payMagic(address _nextPaymentAddress, uint8 _lvl) private {
        freeUsers[_nextPaymentAddress].earnFromXFactor += slotPrice[_lvl];
        if (!address(uint160(_nextPaymentAddress)).send(slotPrice[_lvl])) {
            address(uint160(owner)).transfer(address(this).balance);
            return;
        }
    }
    
    function slotReferrals(uint256 _slotId, uint8 _level) public view returns (address[] memory) {
        if (_level == 1) return xFactorLevel1[_slotId].referrals;
        if (_level == 2) return xFactorLevel2[_slotId].referrals;
        if (_level == 3) return xFactorLevel3[_slotId].referrals;
        if (_level == 4) return xFactorLevel4[_slotId].referrals;
        if (_level == 5) return xFactorLevel5[_slotId].referrals;
        if (_level == 6) return xFactorLevel6[_slotId].referrals;
        if (_level == 7) return xFactorLevel7[_slotId].referrals;
        if (_level == 8) return xFactorLevel8[_slotId].referrals;
        if (_level == 9) return xFactorLevel9[_slotId].referrals;
        if (_level == 10) return xFactorLevel10[_slotId].referrals;
    }

    function xFactorSlotsCount(address _userAddress, uint8 _level) public view returns (uint256 _length) {
        if (_level == 1) return freeUsers[_userAddress].xFactorSlots1.length;
        if (_level == 2) return freeUsers[_userAddress].xFactorSlots2.length;
        if (_level == 3) return freeUsers[_userAddress].xFactorSlots3.length;
        if (_level == 4) return freeUsers[_userAddress].xFactorSlots4.length;
        if (_level == 5) return freeUsers[_userAddress].xFactorSlots5.length;
        if (_level == 6) return freeUsers[_userAddress].xFactorSlots6.length;
        if (_level == 7) return freeUsers[_userAddress].xFactorSlots7.length;
        if (_level == 8) return freeUsers[_userAddress].xFactorSlots8.length;
        if (_level == 9) return freeUsers[_userAddress].xFactorSlots9.length;
        if (_level == 10) return freeUsers[_userAddress].xFactorSlots10.length;
    }

    function primePartnersCount(address _userAddress, uint8 _level) public view returns (uint256 _length) {
        if (_level == 1) return PrimeLevel_1[_userAddress].partnersCnt;
        if (_level == 2) return PrimeLevel_2[_userAddress].partnersCnt;
        if (_level == 3) return PrimeLevel_3[_userAddress].partnersCnt;
        if (_level == 4) return PrimeLevel_4[_userAddress].partnersCnt;
        if (_level == 5) return PrimeLevel_5[_userAddress].partnersCnt;
        if (_level == 6) return PrimeLevel_6[_userAddress].partnersCnt;
        if (_level == 7) return PrimeLevel_7[_userAddress].partnersCnt;
        if (_level == 8) return PrimeLevel_8[_userAddress].partnersCnt;
        if (_level == 9) return PrimeLevel_9[_userAddress].partnersCnt;
        if (_level == 10) return PrimeLevel_10[_userAddress].partnersCnt;
    }

}