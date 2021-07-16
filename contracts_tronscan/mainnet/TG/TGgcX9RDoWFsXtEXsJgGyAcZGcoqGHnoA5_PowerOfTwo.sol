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
        address referrer;
        uint256 earnFromPrime;
        uint256 earnFromXFactor;
        mapping(uint8 => bool) activeXFLevels;
        mapping(uint8 => XF) xFMatrix;
    }
    
    struct XF {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint256 reinvestCount;
        address closedPart;
        uint256 partnersOnSlot;
    }
    
    struct Prime {
        uint256 id;
        uint256 partnersCnt;
        address sponsorAddress;
    }

    modifier validReferrerId(uint256 _referrerID) {
        require(_referrerID > 0 && _referrerID <= userId, 'Invalid sponsor ID');
        _;
      }
   
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier checkRegistered() {
        require(users[msg.sender].id == 0, "Already Registered");
        _;
    }
    
    mapping(address => User) public users;
    uint256 public userId = 1;

    address[] public whiteList;    
    
    mapping(uint256 => address) public idToAddress;
    mapping(uint8 => uint8) public uplineAmount;
    mapping(uint8 => uint256) public slotPrice;

    mapping(uint8 => uint256) public PrimeId;   
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

    uint256 public USDtoTRX = 30000000; // 1 USD = TRX * 10^6
    address public owner;
    
    event payPrime(uint256 amount, uint8 indexed _level, address indexed _userAddress, uint256 _time);
    event RefPayment(uint256 amount, address indexed _sponsorAddress, address indexed _fromAddress, uint256 _level, uint256 _time);
    event DistributePayment(uint256 amount, address indexed _sponsorAddress, address indexed _fromAddress, uint256 _time);
    event PaidRegister(address indexed _userAddress, uint256 _time);

    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 level);
    
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
               
        users[owner] = User({
            id: userId,
            referrerCount: uint256(0),
            sponsorId: uint256(1),
            referrer: address(0),
            earnFromPrime: uint256(0),
            earnFromXFactor: uint256(0)
        });
        idToAddress[userId] = owner;

        for (uint8 i = 1; i <= 10; i++) {
            users[owner].activeXFLevels[i] = true;
        } 
        
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
        require(_check == true, "You are not allowed to register");

        address _userAddress = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        uint256 calculatedValue = slotPrice[1] * 2;
        require(msg.value == calculatedValue, "Incorrect purchase value");
        
        address _sponsorAddress = idToAddress[_referrerID];
        users[_sponsorAddress].referrerCount++;
        
        userId++;
        users[_userAddress] = User({
            id: userId,
            referrerCount: 0,
            sponsorId: _referrerID,
            referrer: _sponsorAddress,
            earnFromPrime: uint256(0),
            earnFromXFactor: uint256(0)
        });
        idToAddress[userId] = _userAddress;
        users[_userAddress].activeXFLevels[1] = true;

        users[_sponsorAddress].xFMatrix[1].partnersOnSlot++;

        buyPrimeBatch(1, calculatedValue);
        updateXFReferrer(_userAddress, findFreeXFReferrer(_userAddress, 1), 1);

        emit PaidRegister(msg.sender, block.timestamp);

    }
    
    function buyBatch(uint8 _level) public payable {
        require( _level > 0 && _level <= 10, "Incorrect level");
        uint256 calculatedValue = slotPrice[_level] * 2;
        require(msg.value == calculatedValue, "Incorrect purchase value");
        buyPrimeBatch(_level, calculatedValue);
        buyXFactorBatch(_level, calculatedValue);
    }
    
    function buyXFactor(uint8 _level) public payable {
        uint256 calculatedValue = slotPrice[_level];
        require(msg.value == slotPrice[_level], "Incorrect purchase value");
        buyXFactorBatch(_level, calculatedValue);
    }
    
    function buyXFactorBatch(uint8 level, uint256 calculatedValue) private {
        
        require(level > 0 && level <= 10, "Incorrect level");
        require(msg.value == calculatedValue, "Incorrect purchase value");
        require(users[msg.sender].activeXFLevels[level-1], "You must buy Previous slot");
        require(!users[msg.sender].activeXFLevels[level], "You already purchased this slot!"); 
        if (level == 3) require(PrimeLevel_2[msg.sender].id != 0, "You have to upgrade in Prime Slot 2 before you can upgrade in XF Slot 3");
        if (level == 4) require(PrimeLevel_3[msg.sender].id != 0, "You have to upgrade in Prime Slot 3 before you can upgrade in XF Slot 4");
        if (level == 5) require(PrimeLevel_4[msg.sender].id != 0, "You have to upgrade in Prime Slot 4 before you can upgrade in XF Slot 5");
        if (level == 6) require(PrimeLevel_5[msg.sender].id != 0, "You have to upgrade in Prime Slot 5 before you can upgrade in XF Slot 6");
        if (level == 7) require(PrimeLevel_6[msg.sender].id != 0, "You have to upgrade in Prime Slot 6 before you can upgrade in XF Slot 7");
        if (level == 8) require(PrimeLevel_7[msg.sender].id != 0, "You have to upgrade in Prime Slot 7 before you can upgrade in XF Slot 8");
        if (level == 9) require(PrimeLevel_8[msg.sender].id != 0, "You have to upgrade in Prime Slot 8 before you can upgrade in XF Slot 9");
        if (level == 10) require(PrimeLevel_9[msg.sender].id != 0, "You have to upgrade in Prime Slot 9 before you can upgrade in XF Slot 10");

        if (users[msg.sender].xFMatrix[level-1].blocked) {
            users[msg.sender].xFMatrix[level-1].blocked = false;
        }
        address freeXFReferrer = findFreeXFReferrer(msg.sender, level);        
        users[msg.sender].activeXFLevels[level] = true;
        updateXFReferrer(msg.sender, freeXFReferrer, level);

        address _sponsorAddress = users[msg.sender].referrer;
        users[_sponsorAddress].xFMatrix[level].partnersOnSlot++;

        emit Upgrade(msg.sender, freeXFReferrer, level);

    }
   
    function findUpgradedSponsor(address _sponsorAddress, uint8 _level) private view returns (address)  {
        require( _level > 0 && _level <= 10, "Incorrect level");
        if (_level == 1) {
            while (true) {
                if (PrimeLevel_1[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 2) {
            while (true) {
                if (PrimeLevel_2[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 3) {
            while (true) {
                if (PrimeLevel_3[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 4) {
            while (true) {
                if (PrimeLevel_4[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 5) {
            while (true) {
                if (PrimeLevel_5[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 6) {
            while (true) {
                if (PrimeLevel_6[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 7) {
            while (true) {
                if (PrimeLevel_7[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 8) {
            while (true) {
                if (PrimeLevel_8[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 9) {
            while (true) {
                if (PrimeLevel_9[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
        if (_level == 10) {
            while (true) {
                if (PrimeLevel_10[_sponsorAddress].id == 0) {
                    uint256 nextRefId = users[_sponsorAddress].sponsorId;
                    _sponsorAddress = idToAddress[nextRefId];
                    if (nextRefId == 1) return _sponsorAddress;
                }                
                return _sponsorAddress;
            }
        }
    }

   
    function buyPrime(uint8 _level) public payable {
        uint256 calculatedValue = slotPrice[_level];
        require(msg.value == slotPrice[_level], "Incorrect purchase value");
        buyPrimeBatch(_level, calculatedValue);
    }
    
    function buyPrimeBatch(uint8 _level, uint256 calculatedValue) private {
        
        require( _level > 0 && _level <= 10, "Incorrect level");
        require(msg.value == calculatedValue, "Incorrect purchase value");
        
        address _userAddress = msg.sender;
        uint256 _referrerID = users[_userAddress].sponsorId;

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
            users[_approvedSponsor].earnFromPrime += paid;
            amountToDistribute -= paid;
            _findAddress = idToAddress[users[_approvedSponsor].sponsorId];
        }
        
        if (amountToDistribute > 0) {
            users[idToAddress[1]].earnFromPrime += amountToDistribute;
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
        return (users[_userAddress].id != 0);
    }
       
    function withdraw() payable isOwner public {
         msg.sender.transfer(address(this).balance);
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

    function updateXFReferrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeXFLevels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].xFMatrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].xFMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(users[referrerAddress].xFMatrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].xFMatrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, level);
            }
            
            address ref = users[referrerAddress].xFMatrix[level].currentReferrer;            
            users[ref].xFMatrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].xFMatrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].xFMatrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].xFMatrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].xFMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].xFMatrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].xFMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, level, 4);
                }
            } else if (len == 2 && users[ref].xFMatrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].xFMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, level, 6);
                }
            }

            return updateXFReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].xFMatrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].xFMatrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].xFMatrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].xFMatrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].xFMatrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].xFMatrix[level].closedPart)) {

                updateXF(userAddress, referrerAddress, level, true);
                return updateXFReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].xFMatrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].xFMatrix[level].closedPart) {
                updateXF(userAddress, referrerAddress, level, true);
                return updateXFReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateXF(userAddress, referrerAddress, level, false);
                return updateXFReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].xFMatrix[level].firstLevelReferrals[1] == userAddress) {
            updateXF(userAddress, referrerAddress, level, false);
            return updateXFReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].xFMatrix[level].firstLevelReferrals[0] == userAddress) {
            updateXF(userAddress, referrerAddress, level, true);
            return updateXFReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[0]].xFMatrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[1]].xFMatrix[level].firstLevelReferrals.length) {
            updateXF(userAddress, referrerAddress, level, false);
        } else {
            updateXF(userAddress, referrerAddress, level, true);
        }
        
        updateXFReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateXF(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[0]].xFMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].xFMatrix[level].firstLevelReferrals[0], level, uint8(users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[0]].xFMatrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, level, 2 + uint8(users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[0]].xFMatrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].xFMatrix[level].currentReferrer = users[referrerAddress].xFMatrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[1]].xFMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].xFMatrix[level].firstLevelReferrals[1], level, uint8(users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[1]].xFMatrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, level, 4 + uint8(users[users[referrerAddress].xFMatrix[level].firstLevelReferrals[1]].xFMatrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].xFMatrix[level].currentReferrer = users[referrerAddress].xFMatrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateXFReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].xFMatrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, level);
        }
        
        address[] memory xF = users[users[referrerAddress].xFMatrix[level].currentReferrer].xFMatrix[level].firstLevelReferrals;
        
        if (xF.length == 2) {
            if (xF[0] == referrerAddress ||
                xF[1] == referrerAddress) {
                users[users[referrerAddress].xFMatrix[level].currentReferrer].xFMatrix[level].closedPart = referrerAddress;
            } else if (xF.length == 1) {
                if (xF[0] == referrerAddress) {
                    users[users[referrerAddress].xFMatrix[level].currentReferrer].xFMatrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].xFMatrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].xFMatrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].xFMatrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeXFLevels[level+1] && level != 10) {
            users[referrerAddress].xFMatrix[level].blocked = true;
        }

        users[referrerAddress].xFMatrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeXFReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
            updateXFReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, level);
            sendETHDividends(owner, userAddress, level);
        }
    }
    
    
    function findFreeXFReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeXFLevels[level]) {
                return users[userAddress].referrer;
            }            
            userAddress = users[userAddress].referrer;
        }
    }

    function usersActiveXFLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeXFLevels[level];
    }

    function usersXFMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint256) {
        return (users[userAddress].xFMatrix[level].currentReferrer,
                users[userAddress].xFMatrix[level].firstLevelReferrals,
                users[userAddress].xFMatrix[level].secondLevelReferrals,
                users[userAddress].xFMatrix[level].blocked,
                users[userAddress].xFMatrix[level].closedPart,
                users[userAddress].xFMatrix[level].reinvestCount
                );
    }

    function usersXFMatrixPartners(address userAddress, uint8 level) public view returns(uint256) {
        return users[userAddress].xFMatrix[level].partnersOnSlot;
    }
    
    function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;        
        while (true) {
            if (users[receiver].xFMatrix[level].blocked) {
                emit MissedEthReceive(receiver, _from, level);
                isExtraDividends = true;
                receiver = users[receiver].xFMatrix[level].currentReferrer;
            } else {
                return (receiver, isExtraDividends);
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, level);

        if (!address(uint160(receiver)).send(slotPrice[level])) {
            address(uint160(owner)).transfer(address(this).balance);
            users[owner].earnFromXFactor += slotPrice[level];
            return;
        }

        users[receiver].earnFromXFactor += slotPrice[level];
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, level);
        }
    }

}