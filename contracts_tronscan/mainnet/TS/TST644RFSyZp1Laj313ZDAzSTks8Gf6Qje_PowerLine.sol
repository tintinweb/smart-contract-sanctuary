//SourceUnit: PowerLine.sol

pragma solidity >=0.5.8;

contract PowerLine {

    struct UsersPool {
        uint id;
        address sponsorAddress;
        uint reinvestCount;
    }
    
    struct PoolSlots {
        uint id;
        address userAddress;
        address sponsorAddress;
        uint8 eventsCount;
    }
    
    struct Powerbank {
        uint8 slot1;
        uint8 slot2;
        uint8 slot3;
        uint8 slot4;
        uint8 slot5;
        uint8 slot6;
        uint8 slot7;
        uint8 slot8;
        uint8 slot9;
        uint8 slot10;
        uint256 earnFromPowerline;
        uint256 earnFromPowerbank;
    }
        
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    event RegisterUserEvent(uint _userid, address indexed _user, address indexed _referrerAddress, uint8 indexed _autopool, uint _amount, uint _time);
    event ReinvestEvent(uint _userid, address indexed _user, address indexed _referrerAddress, uint8 indexed _autopool, uint _amount, uint _time);
    event DistributeUplineEvent(uint amount, address indexed _sponsorAddress, address indexed _fromAddress, uint _level, uint8 _fromPool, uint _time);
    event PowerlinePaymentEvent(uint amount, address indexed _from, address indexed _to, uint8 indexed _fromPool, uint _time);
    event PowerbankPaymentEvent(uint amount, address indexed _from, address indexed _to, uint8 indexed _fromPool, uint _time);

    mapping(uint8 => uint256) public slotPrice;

    mapping(address => UsersPool) public users_1;
    mapping(uint => PoolSlots) public pool_slots_1;
    mapping(address => UsersPool) public users_2;
    mapping(uint => PoolSlots) public pool_slots_2;
    mapping(address => UsersPool) public users_3;
    mapping(uint => PoolSlots) public pool_slots_3;
    mapping(address => UsersPool) public users_4;
    mapping(uint => PoolSlots) public pool_slots_4;
    mapping(address => UsersPool) public users_5;
    mapping(uint => PoolSlots) public pool_slots_5;
    mapping(address => UsersPool) public users_6;
    mapping(uint => PoolSlots) public pool_slots_6;
    mapping(address => UsersPool) public users_7;
    mapping(uint => PoolSlots) public pool_slots_7;
    mapping(address => UsersPool) public users_8;
    mapping(uint => PoolSlots) public pool_slots_8;
    mapping(address => UsersPool) public users_9;
    mapping(uint => PoolSlots) public pool_slots_9;
    mapping(address => UsersPool) public users_10;
    mapping(uint => PoolSlots) public pool_slots_10;

    mapping(address => Powerbank) public powerbank;
    
    uint public newUserId_ap1 = 1;
    uint public newUserId_ap2 = 1;
    uint public newUserId_ap3 = 1;
    uint public newUserId_ap4 = 1;
    uint public newUserId_ap5 = 1;
    uint public newUserId_ap6 = 1;
    uint public newUserId_ap7 = 1;
    uint public newUserId_ap8 = 1;
    uint public newUserId_ap9 = 1;
    uint public newUserId_ap10 = 1;

    uint public newSlotId_ap1 = 1;
    uint public activeSlot_ap1 = 1;
    uint public newSlotId_ap2 = 1;
    uint public activeSlot_ap2 = 1;
    uint public newSlotId_ap3 = 1;
    uint public activeSlot_ap3 = 1;
    uint public newSlotId_ap4 = 1;
    uint public activeSlot_ap4 = 1;
    uint public newSlotId_ap5 = 1;
    uint public activeSlot_ap5 = 1;
    uint public newSlotId_ap6 = 1;
    uint public activeSlot_ap6 = 1;
    uint public newSlotId_ap7 = 1;
    uint public activeSlot_ap7 = 1;
    uint public newSlotId_ap8 = 1;
    uint public activeSlot_ap8 = 1;
    uint public newSlotId_ap9 = 1;
    uint public activeSlot_ap9 = 1;
    uint public newSlotId_ap10 = 1;
    uint public activeSlot_ap10 = 1;
    
    address[] private whiteList;
    address public owner;
    address dc;
    
    uint256 public USDtoTRX = 3000000;
    
    constructor() public {
        
        owner = msg.sender;
        
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
        
        initiateSlots1(owner);
        initiateSlots2(owner);
        
    }
    
    function initiateSlots1(address _ownerAddress) private {       
        
        UsersPool memory user1 = UsersPool({
            id: newSlotId_ap1,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_1[_ownerAddress] = user1;
        
        PoolSlots memory _newSlot1 = PoolSlots({
            id: newSlotId_ap1,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_1[newSlotId_ap1] = _newSlot1;
        newUserId_ap1++;
        newSlotId_ap1++;
        
        UsersPool memory user2 = UsersPool({
            id: newSlotId_ap2,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_2[_ownerAddress] = user2;
        
        PoolSlots memory _newSlot2 = PoolSlots({
            id: newSlotId_ap2,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_2[newSlotId_ap2] = _newSlot2;
        newUserId_ap2++;
        newSlotId_ap2++;
        
        UsersPool memory user3 = UsersPool({
            id: newSlotId_ap3,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_3[_ownerAddress] = user3;
        
        PoolSlots memory _newSlot3 = PoolSlots({
            id: newSlotId_ap3,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_3[newSlotId_ap3] = _newSlot3;
        newUserId_ap3++;
        newSlotId_ap3++;
        
        UsersPool memory user4 = UsersPool({
            id: newSlotId_ap4,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_4[_ownerAddress] = user4;
        
        PoolSlots memory _newSlot4 = PoolSlots({
            id: newSlotId_ap4,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_4[newSlotId_ap4] = _newSlot4;
        newUserId_ap4++;
        newSlotId_ap4++;
        
       
        
        UsersPool memory user5 = UsersPool({
            id: newSlotId_ap5,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_5[_ownerAddress] = user5;
        
        PoolSlots memory _newSlot5 = PoolSlots({
            id: newSlotId_ap5,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_5[newSlotId_ap5] = _newSlot5;
        newUserId_ap5++;
        newSlotId_ap5++;
        
        
    }
    function initiateSlots2(address _ownerAddress) private {
       
        UsersPool memory user6 = UsersPool({
            id: newSlotId_ap6,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_6[_ownerAddress] = user6;
        
        PoolSlots memory _newSlot6 = PoolSlots({
            id: newSlotId_ap6,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_6[newSlotId_ap6] = _newSlot6;
        newUserId_ap6++;
        newSlotId_ap6++;
        
        UsersPool memory user7 = UsersPool({
            id: newSlotId_ap7,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_7[_ownerAddress] = user7;
        
        PoolSlots memory _newSlot7 = PoolSlots({
            id: newSlotId_ap7,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_7[newSlotId_ap7] = _newSlot7;
        newUserId_ap7++;
        newSlotId_ap7++;
        
        UsersPool memory user8 = UsersPool({
            id: newSlotId_ap8,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_8[_ownerAddress] = user8;
        
        PoolSlots memory _newSlot8 = PoolSlots({
            id: newSlotId_ap8,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_8[newSlotId_ap8] = _newSlot8;
        newUserId_ap8++;
        newSlotId_ap8++;

        UsersPool memory user9 = UsersPool({
            id: newSlotId_ap9,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_9[_ownerAddress] = user9;
        
        PoolSlots memory _newSlot9 = PoolSlots({
            id: newSlotId_ap9,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_9[newSlotId_ap9] = _newSlot9;
        newUserId_ap9++;
        newSlotId_ap9++;
        
        UsersPool memory user10 = UsersPool({
            id: newSlotId_ap10,
            sponsorAddress: _ownerAddress,
            reinvestCount: uint(0)
        });
        
        users_10[_ownerAddress] = user10;
        
        PoolSlots memory _newSlot10 = PoolSlots({
            id: newSlotId_ap10,
            userAddress: _ownerAddress,
            sponsorAddress: _ownerAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_10[newSlotId_ap10] = _newSlot10;
        newUserId_ap10++;
        newSlotId_ap10++;
    }
    
    function () external payable {

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

    function UpdateTRXPrice(uint256 _digits) public payable isOwner {
        USDtoTRX = _digits;
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
    
    function _setParentContract(address _t) isOwner public {
        dc = _t;
    }
    
    function isRegistered(address _val) private returns(uint256 answer){
        bytes4 sig = bytes4(keccak256("users(address)"));        
        assembly {
            let ptr := mload(0x40)           
            mstore(ptr,sig)           
            mstore(add(ptr,0x04), _val)
            let result := call(
              15000,
              sload(dc_slot), 
              0,
              ptr,
              0x24,
              ptr, 
              0x20)            
            if eq(result, 0) {
                revert(0, 0)
            }            
            answer := mload(ptr)
        }        
        return answer;
    }
    
    function getReferer(address _val) private returns(address answer){
        bytes4 sig = bytes4(keccak256("users(address)"));        
        assembly {
            let ptr := mload(0x40)           
            mstore(ptr,sig)           
            mstore(add(ptr,0x04), _val)
            let result := call(
              15000,
              sload(dc_slot), 
              0,
              ptr,
              0x24,
              ptr, 
              0xC0)            
            if eq(result, 0) {
                revert(0, 0)
            }
            returndatacopy(ptr, 0x60, 0x20)             
            answer := mload(ptr)
        }        
        return answer;        
    }
    
    function getPowerData(address _val) public returns (uint, address) {
        
        uint256 id = isRegistered(_val);
        if (id > 0) {
            return(id, getReferer(_val));
        }
        
    }
    
    function participatePool1() 
      public 
      payable 
    {
        
        require(msg.value == slotPrice[1]*2, "Wrong Value");
        require(isRegistered(msg.sender) > 0, "You are not present in Power Of Two. Register in P2 First!");
        require(!isUserExists(msg.sender, 1), "User already registered");

        bool _check = checkWhiteListed(msg.sender);
        require(_check == true, "You are not allowed to register");

        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
                
        powerbank[_sponsorAddress].slot1 = powerbank[_sponsorAddress].slot1 + 1;
        if (powerbank[_sponsorAddress].slot1 == 1) {
            payPowerbank(_sponsorAddress, 1);
        }
        if (powerbank[_sponsorAddress].slot1 == 2) {
            payPowerbank(_sponsorAddress, 1);
        }
        if (powerbank[_sponsorAddress].slot1 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 1);
            powerbank[_sponsorAddress].slot1 = 0;
        }

        uint eventCount = pool_slots_1[activeSlot_ap1].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_1[activeSlot_ap1].userAddress, 
                pool_slots_1[activeSlot_ap1].id, 
                pool_slots_1[activeSlot_ap1].sponsorAddress, 
                1
            ));
            pool_slots_1[activeSlot_ap1].eventsCount++;
        }
        
        UsersPool memory user1 = UsersPool({
            id: newSlotId_ap1,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_1[msg.sender] = user1;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap1,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_1[newSlotId_ap1] = _newSlot;
        newUserId_ap1++;
        emit RegisterUserEvent(newSlotId_ap1, msg.sender, _sponsorAddress, 1, msg.value, now);
        
        newSlotId_ap1++;
        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_1[activeSlot_ap1].userAddress, 1);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_1[activeSlot_ap1].sponsorAddress, 1);
            }
            pool_slots_1[activeSlot_ap1].eventsCount++;
        }
        
    }
    
    function participatePool2() 
      public 
      payable 
    {
        require(msg.value == slotPrice[2]*2, "Wrong Value");
        require(isUserExists(msg.sender, 1), "User not present in Slot 1");
        require(!isUserExists(msg.sender, 2), "User already registered in Slot 2");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
        
        powerbank[_sponsorAddress].slot2 = powerbank[_sponsorAddress].slot2 + 1;
        if (powerbank[_sponsorAddress].slot2 == 1) {
            payPowerbank(_sponsorAddress, 2);
        }
        if (powerbank[_sponsorAddress].slot2 == 2) {
            payPowerbank(_sponsorAddress, 2);
        }
        if (powerbank[_sponsorAddress].slot2 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 2);
            powerbank[_sponsorAddress].slot2 = 0;
        }

        uint eventCount = pool_slots_2[activeSlot_ap2].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_2[activeSlot_ap2].userAddress, 
                pool_slots_2[activeSlot_ap2].id, 
                pool_slots_2[activeSlot_ap2].sponsorAddress, 
                2
            ));
            pool_slots_2[activeSlot_ap2].eventsCount++;
        }
        
        UsersPool memory user2 = UsersPool({
            id: newSlotId_ap2,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_2[msg.sender] = user2;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap2,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_2[newSlotId_ap2] = _newSlot;
        newUserId_ap2++;
        emit RegisterUserEvent(newSlotId_ap2, msg.sender, _sponsorAddress, 2, msg.value, now);
        
        newSlotId_ap2++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_2[activeSlot_ap2].userAddress, 2);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_2[activeSlot_ap2].sponsorAddress, 2);
            }
            pool_slots_2[activeSlot_ap2].eventsCount++;
        }
    }

    function participatePool3() 
      public 
      payable 
    {
        require(msg.value == slotPrice[3]*2, "Wrong Value");
        require(isUserExists(msg.sender, 2), "User not present in Slot 2");
        require(!isUserExists(msg.sender, 3), "User already registered in Slot 3");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot3 = powerbank[_sponsorAddress].slot3 + 1;
        if (powerbank[_sponsorAddress].slot3 == 1) {
            payPowerbank(_sponsorAddress, 3);
        }
        if (powerbank[_sponsorAddress].slot3 == 2) {
            payPowerbank(_sponsorAddress, 3);
        }
        if (powerbank[_sponsorAddress].slot3 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 3);
            powerbank[_sponsorAddress].slot3 = 0;
        }

        uint eventCount = pool_slots_3[activeSlot_ap3].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_3[activeSlot_ap3].userAddress, 
                pool_slots_3[activeSlot_ap3].id, 
                pool_slots_3[activeSlot_ap3].sponsorAddress, 
                3
            ));
            pool_slots_3[activeSlot_ap3].eventsCount++;
        }
        
        UsersPool memory user3 = UsersPool({
            id: newSlotId_ap3,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_3[msg.sender] = user3;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap3,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_3[newSlotId_ap3] = _newSlot;
        newUserId_ap3++;
        emit RegisterUserEvent(newSlotId_ap3, msg.sender, _sponsorAddress, 3, msg.value, now);
        
        newSlotId_ap3++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_3[activeSlot_ap3].userAddress, 3);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_3[activeSlot_ap3].sponsorAddress, 3);
            }
            pool_slots_3[activeSlot_ap3].eventsCount++;
        }
    }

    function participatePool4() 
      public 
      payable 
    {
        require(msg.value == slotPrice[4]*2, "Wrong Value");
        require(isUserExists(msg.sender, 3), "User not present in Slot 3");
        require(!isUserExists(msg.sender, 4), "User already registered in Slot 4");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot4 = powerbank[_sponsorAddress].slot4 + 1;
        if (powerbank[_sponsorAddress].slot4 == 1) {
            payPowerbank(_sponsorAddress, 4);
        }
        if (powerbank[_sponsorAddress].slot4 == 2) {
            payPowerbank(_sponsorAddress, 4);
        }
        if (powerbank[_sponsorAddress].slot4 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 4);
            powerbank[_sponsorAddress].slot4 = 0;
        }

        uint eventCount = pool_slots_4[activeSlot_ap4].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_4[activeSlot_ap4].userAddress, 
                pool_slots_4[activeSlot_ap4].id, 
                pool_slots_4[activeSlot_ap4].sponsorAddress, 
                4
            ));
            pool_slots_4[activeSlot_ap4].eventsCount++;
        }
        
        UsersPool memory user4 = UsersPool({
            id: newSlotId_ap4,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_4[msg.sender] = user4;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap4,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_4[newSlotId_ap4] = _newSlot;
        newUserId_ap4++;
        emit RegisterUserEvent(newSlotId_ap4, msg.sender, _sponsorAddress, 4, msg.value, now);
        
        newSlotId_ap4++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_4[activeSlot_ap4].userAddress, 4);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_4[activeSlot_ap4].sponsorAddress, 4);
            }
            pool_slots_4[activeSlot_ap4].eventsCount++;
        }
    }

    function participatePool5() 
      public 
      payable 
    {
        require(msg.value == slotPrice[5]*2, "Wrong Value");
        require(isUserExists(msg.sender, 4), "User not present in Slot 4");
        require(!isUserExists(msg.sender, 5), "User already registered in Slot 5");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot5 = powerbank[_sponsorAddress].slot5 + 1;
        if (powerbank[_sponsorAddress].slot5 == 1) {
            payPowerbank(_sponsorAddress, 5);
        }
        if (powerbank[_sponsorAddress].slot5 == 2) {
            payPowerbank(_sponsorAddress, 5);
        }
        if (powerbank[_sponsorAddress].slot5 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 5);
            powerbank[_sponsorAddress].slot5 = 0;
        }

        uint eventCount = pool_slots_5[activeSlot_ap5].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_5[activeSlot_ap5].userAddress, 
                pool_slots_5[activeSlot_ap5].id, 
                pool_slots_5[activeSlot_ap5].sponsorAddress, 
                5
            ));
            pool_slots_5[activeSlot_ap5].eventsCount++;
        }
        
        UsersPool memory user5 = UsersPool({
            id: newSlotId_ap5,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_5[msg.sender] = user5;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap5,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_5[newSlotId_ap5] = _newSlot;
        newUserId_ap5++;
        emit RegisterUserEvent(newSlotId_ap5, msg.sender, _sponsorAddress, 5, msg.value, now);
        
        newSlotId_ap5++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_5[activeSlot_ap5].userAddress, 5);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_5[activeSlot_ap5].sponsorAddress, 5);
            }
            pool_slots_5[activeSlot_ap5].eventsCount++;
        }
    }

    function participatePool6() 
      public 
      payable 
    {
        require(msg.value == slotPrice[6]*2, "Wrong Value");
        require(isUserExists(msg.sender, 5), "User not present in Slot 5");
        require(!isUserExists(msg.sender, 6), "User already registered in Slot 6");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot6 = powerbank[_sponsorAddress].slot6 + 1;
        if (powerbank[_sponsorAddress].slot6 == 1) {
            payPowerbank(_sponsorAddress, 6);
        }
        if (powerbank[_sponsorAddress].slot6 == 2) {
            payPowerbank(_sponsorAddress, 6);
        }
        if (powerbank[_sponsorAddress].slot6 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 6);
            powerbank[_sponsorAddress].slot6 = 0;
        }

        uint eventCount = pool_slots_6[activeSlot_ap6].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_6[activeSlot_ap6].userAddress, 
                pool_slots_6[activeSlot_ap6].id, 
                pool_slots_6[activeSlot_ap6].sponsorAddress, 
                6
            ));
            pool_slots_6[activeSlot_ap6].eventsCount++;
        }
        
        UsersPool memory user6 = UsersPool({
            id: newSlotId_ap6,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_6[msg.sender] = user6;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap6,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_6[newSlotId_ap6] = _newSlot;
        newUserId_ap6++;
        emit RegisterUserEvent(newSlotId_ap6, msg.sender, _sponsorAddress, 6, msg.value, now);
        
        newSlotId_ap6++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_6[activeSlot_ap6].userAddress, 6);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_6[activeSlot_ap6].sponsorAddress, 6);
            }
            pool_slots_6[activeSlot_ap6].eventsCount++;
        }
    }

    function participatePool7() 
      public 
      payable 
    {
        require(msg.value == slotPrice[7]*2, "Wrong Value");
        require(isUserExists(msg.sender, 6), "User not present in Slot 6");
        require(!isUserExists(msg.sender, 7), "User already registered in Slot 7");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot7 = powerbank[_sponsorAddress].slot7 + 1;
        if (powerbank[_sponsorAddress].slot7 == 1) {
            payPowerbank(_sponsorAddress, 7);
        }
        if (powerbank[_sponsorAddress].slot7 == 2) {
            payPowerbank(_sponsorAddress, 7);
        }
        if (powerbank[_sponsorAddress].slot7 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 7);
            powerbank[_sponsorAddress].slot7 = 0;
        }

        uint eventCount = pool_slots_7[activeSlot_ap7].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_7[activeSlot_ap7].userAddress, 
                pool_slots_7[activeSlot_ap7].id, 
                pool_slots_7[activeSlot_ap7].sponsorAddress, 
                7
            ));
            pool_slots_7[activeSlot_ap7].eventsCount++;
        }
        
        UsersPool memory user7 = UsersPool({
            id: newSlotId_ap7,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_7[msg.sender] = user7;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap7,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_7[newSlotId_ap7] = _newSlot;
        newUserId_ap7++;
        emit RegisterUserEvent(newSlotId_ap7, msg.sender, _sponsorAddress, 7, msg.value, now);
        
        newSlotId_ap7++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_7[activeSlot_ap7].userAddress, 7);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_7[activeSlot_ap7].sponsorAddress, 7);
            }
            pool_slots_7[activeSlot_ap7].eventsCount++;
        }
    }

    function participatePool8() 
      public 
      payable 
    {
        require(msg.value == slotPrice[8]*2, "Wrong Value");
        require(isUserExists(msg.sender, 7), "User not present in Slot 7");
        require(!isUserExists(msg.sender, 8), "User already registered in Slot 8");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot8 = powerbank[_sponsorAddress].slot8 + 1;
        if (powerbank[_sponsorAddress].slot8 == 1) {
            payPowerbank(_sponsorAddress, 8);
        }
        if (powerbank[_sponsorAddress].slot8 == 2) {
            payPowerbank(_sponsorAddress, 8);
        }
        if (powerbank[_sponsorAddress].slot8 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 8);
            powerbank[_sponsorAddress].slot8 = 0;
        }

        uint eventCount = pool_slots_8[activeSlot_ap8].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_8[activeSlot_ap8].userAddress, 
                pool_slots_8[activeSlot_ap8].id, 
                pool_slots_8[activeSlot_ap8].sponsorAddress, 
                8
            ));
            pool_slots_8[activeSlot_ap8].eventsCount++;
        }
        
        UsersPool memory user8 = UsersPool({
            id: newSlotId_ap8,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_8[msg.sender] = user8;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap8,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_8[newSlotId_ap8] = _newSlot;
        newUserId_ap8++;
        emit RegisterUserEvent(newSlotId_ap8, msg.sender, _sponsorAddress, 8, msg.value, now);
        
        newSlotId_ap8++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_8[activeSlot_ap8].userAddress, 8);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_8[activeSlot_ap8].sponsorAddress, 8);
            }
            pool_slots_8[activeSlot_ap8].eventsCount++;
        }
    }

    function participatePool9() 
      public 
      payable 
    {
        require(msg.value == slotPrice[9]*2, "Wrong Value");
        require(isUserExists(msg.sender, 8), "User not present in Slot 8");
        require(!isUserExists(msg.sender, 9), "User already registered in Slot 9");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot9 = powerbank[_sponsorAddress].slot9 + 1;
        if (powerbank[_sponsorAddress].slot9 == 1) {
            payPowerbank(_sponsorAddress, 9);
        }
        if (powerbank[_sponsorAddress].slot9 == 2) {
            payPowerbank(_sponsorAddress, 9);
        }
        if (powerbank[_sponsorAddress].slot9 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 9);
            powerbank[_sponsorAddress].slot9 = 0;
        }

        uint eventCount = pool_slots_9[activeSlot_ap9].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_9[activeSlot_ap9].userAddress, 
                pool_slots_9[activeSlot_ap9].id, 
                pool_slots_9[activeSlot_ap9].sponsorAddress, 
                9
            ));
            pool_slots_9[activeSlot_ap9].eventsCount++;
        }
        
        UsersPool memory user9 = UsersPool({
            id: newSlotId_ap9,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_9[msg.sender] = user9;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap9,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_9[newSlotId_ap9] = _newSlot;
        newUserId_ap9++;
        emit RegisterUserEvent(newSlotId_ap9, msg.sender, _sponsorAddress, 9, msg.value, now);
        
        newSlotId_ap9++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_9[activeSlot_ap9].userAddress, 9);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_9[activeSlot_ap9].sponsorAddress, 9);
            }
            pool_slots_9[activeSlot_ap9].eventsCount++;
        }
    }

    function participatePool10() 
      public 
      payable 
    {
        require(msg.value == slotPrice[10]*2, "Wrong Value");
        require(isUserExists(msg.sender, 9), "User not present in Slot 9");
        require(!isUserExists(msg.sender, 10), "User already registered in Slot 10");
        
        address _userAddress = msg.sender;
        address _sponsorAddress = getReferer(_userAddress);
       
        powerbank[_sponsorAddress].slot10 = powerbank[_sponsorAddress].slot10 + 1;
        if (powerbank[_sponsorAddress].slot10 == 1) {
            payPowerbank(_sponsorAddress, 10);
        }
        if (powerbank[_sponsorAddress].slot10 == 2) {
            payPowerbank(_sponsorAddress, 10);
        }
        if (powerbank[_sponsorAddress].slot10 == 3) { 
            address _presponsorAddress = getReferer(_sponsorAddress);
            payPowerbank(_presponsorAddress, 10);
            powerbank[_sponsorAddress].slot10 = 0;
        }

        uint eventCount = pool_slots_10[activeSlot_ap10].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_10[activeSlot_ap10].userAddress, 
                pool_slots_10[activeSlot_ap10].id, 
                pool_slots_10[activeSlot_ap10].sponsorAddress, 
                10
            ));
            pool_slots_10[activeSlot_ap10].eventsCount++;
        }
        
        UsersPool memory user10 = UsersPool({
            id: newSlotId_ap10,
            sponsorAddress: _sponsorAddress,
            reinvestCount: uint(0)
        });
        users_10[msg.sender] = user10;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap10,
            userAddress: msg.sender,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        pool_slots_10[newSlotId_ap10] = _newSlot;
        newUserId_ap10++;
        emit RegisterUserEvent(newSlotId_ap10, msg.sender, _sponsorAddress, 10, msg.value, now);
        
        newSlotId_ap10++;

        if (eventCount < 2) {
            if(eventCount == 0) {
                payUpline(pool_slots_10[activeSlot_ap10].userAddress, 10);
            }
            if(eventCount == 1) {
                payUpline(pool_slots_10[activeSlot_ap10].sponsorAddress, 10);
            }
            pool_slots_10[activeSlot_ap10].eventsCount++;
        }
    }
    

    function reinvestSlot(address _userAddress, uint _userId, address _sponsorAddress, uint8 _fromPool) private returns (bool _isReinvested) {

        PoolSlots memory _reinvestslot = PoolSlots({
            id: _userId,
            userAddress: _userAddress,
            sponsorAddress: _sponsorAddress,
            eventsCount: uint8(0)
        });
        
        if (_fromPool == 1) {
            users_1[pool_slots_1[activeSlot_ap1].userAddress].reinvestCount++;        
            pool_slots_1[newSlotId_ap1] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap1, _userAddress, _sponsorAddress, 1, msg.value, now);
            newSlotId_ap1++;
        }
        if (_fromPool == 2) {
            users_2[pool_slots_2[activeSlot_ap2].userAddress].reinvestCount++;        
            pool_slots_2[newSlotId_ap2] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap2, _userAddress, _sponsorAddress, 2, msg.value, now);
            newSlotId_ap2++;
        }
        if (_fromPool == 3) {
            users_3[pool_slots_3[activeSlot_ap3].userAddress].reinvestCount++;        
            pool_slots_3[newSlotId_ap3] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap3, _userAddress, _sponsorAddress, 3, msg.value, now);
            newSlotId_ap3++;
        }
        if (_fromPool == 4) {
            users_4[pool_slots_4[activeSlot_ap4].userAddress].reinvestCount++;        
            pool_slots_4[newSlotId_ap4] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap4, _userAddress, _sponsorAddress, 4, msg.value, now);
            newSlotId_ap4++;
        }
        if (_fromPool == 5) {
            users_5[pool_slots_5[activeSlot_ap5].userAddress].reinvestCount++;        
            pool_slots_5[newSlotId_ap5] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap5, _userAddress, _sponsorAddress, 5, msg.value, now);
            newSlotId_ap5++;
        }
        if (_fromPool == 6) {
            users_6[pool_slots_6[activeSlot_ap6].userAddress].reinvestCount++;        
            pool_slots_6[newSlotId_ap6] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap6, _userAddress, _sponsorAddress, 6, msg.value, now);
            newSlotId_ap6++;
        }
        if (_fromPool == 7) {
            users_7[pool_slots_7[activeSlot_ap7].userAddress].reinvestCount++;        
            pool_slots_7[newSlotId_ap7] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap7, _userAddress, _sponsorAddress, 7, msg.value, now);
            newSlotId_ap7++;
        }
        if (_fromPool == 8) {
            users_8[pool_slots_8[activeSlot_ap8].userAddress].reinvestCount++;        
            pool_slots_8[newSlotId_ap8] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap8, _userAddress, _sponsorAddress, 8, msg.value, now);
            newSlotId_ap8++;
        }
        if (_fromPool == 9) {
            users_9[pool_slots_9[activeSlot_ap9].userAddress].reinvestCount++;        
            pool_slots_9[newSlotId_ap9] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap9, _userAddress, _sponsorAddress, 9, msg.value, now);
            newSlotId_ap9++;
        }
        if (_fromPool == 10) {
            users_10[pool_slots_10[activeSlot_ap10].userAddress].reinvestCount++;        
            pool_slots_10[newSlotId_ap10] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap10, _userAddress, _sponsorAddress, 10, msg.value, now);
            newSlotId_ap10++;
        }

        if (_fromPool == 1) {
            pool_slots_1[activeSlot_ap1].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap1+1;

            payUpline(pool_slots_1[_nextActiveSlot].userAddress, 1);
            activeSlot_ap1++;
        }
        if (_fromPool == 2) {
            pool_slots_2[activeSlot_ap2].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap2+1;

            payUpline(pool_slots_2[_nextActiveSlot].userAddress, 2);
            activeSlot_ap2++;
        }
        if (_fromPool == 3) {
            pool_slots_3[activeSlot_ap3].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap3+1;

            payUpline(pool_slots_3[_nextActiveSlot].userAddress, 3);
            activeSlot_ap3++;
        }
        if (_fromPool == 4) {
            pool_slots_4[activeSlot_ap4].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap4+1;

            payUpline(pool_slots_4[_nextActiveSlot].userAddress, 4);
            activeSlot_ap4++;
        }
        if (_fromPool == 5) {
            pool_slots_5[activeSlot_ap5].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap5+1;

            payUpline(pool_slots_5[_nextActiveSlot].userAddress, 5);
            activeSlot_ap5++;
        }
        if (_fromPool == 6) {
            pool_slots_6[activeSlot_ap6].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap6+1;

            payUpline(pool_slots_6[_nextActiveSlot].userAddress, 6);
            activeSlot_ap6++;
        }
        if (_fromPool == 7) {
            pool_slots_7[activeSlot_ap7].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap7+1;

            payUpline(pool_slots_7[_nextActiveSlot].userAddress, 7);
            activeSlot_ap7++;
        }
        if (_fromPool == 8) {
            pool_slots_8[activeSlot_ap8].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap8+1;

            payUpline(pool_slots_8[_nextActiveSlot].userAddress, 8);
            activeSlot_ap8++;
        }
        if (_fromPool == 9) {
            pool_slots_9[activeSlot_ap9].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap9+1;

            payUpline(pool_slots_9[_nextActiveSlot].userAddress, 9);
            activeSlot_ap9++;
        }
        if (_fromPool == 10) {
            pool_slots_10[activeSlot_ap10].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap10+1;

            payUpline(pool_slots_10[_nextActiveSlot].userAddress, 10);
            activeSlot_ap10++;
        }

        _isReinvested = true;

        return _isReinvested;
    }

    function payPowerbank(address _sponsorAddress, uint8 _fromPool) private returns (uint distributeAmount) {
        distributeAmount = msg.value / 2;
        uint256 id = isRegistered(_sponsorAddress);
        if (id > 0) {
            if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
                powerbank[_sponsorAddress].earnFromPowerbank += distributeAmount;
                emit PowerbankPaymentEvent(distributeAmount, msg.sender, _sponsorAddress, _fromPool, now);
            }
        } else {
            if (address(uint160(owner)).send(distributeAmount)) {
                powerbank[owner].earnFromPowerbank += distributeAmount;
                emit PowerbankPaymentEvent(distributeAmount, msg.sender, owner, _fromPool, now);
            }
        }
        return distributeAmount;
    }
    
    function payUpline(address _sponsorAddress, uint8 _fromPool) private returns (uint distributeAmount) {
        distributeAmount = msg.value / 2;
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            powerbank[_sponsorAddress].earnFromPowerline += distributeAmount;
            emit PowerlinePaymentEvent(distributeAmount, msg.sender, _sponsorAddress, _fromPool, now);
        }        
        return distributeAmount;
    }
    
    function isUserExists(address _userAddress, uint8 _autopool) public view returns (bool) {
        require((_autopool > 0) && (_autopool <= 10));
        if (_autopool == 1) return (users_1[_userAddress].id != 0);
        if (_autopool == 2) return (users_2[_userAddress].id != 0);
        if (_autopool == 3) return (users_3[_userAddress].id != 0);
        if (_autopool == 4) return (users_4[_userAddress].id != 0);
        if (_autopool == 5) return (users_5[_userAddress].id != 0);
        if (_autopool == 6) return (users_6[_userAddress].id != 0);
        if (_autopool == 7) return (users_7[_userAddress].id != 0);
        if (_autopool == 8) return (users_8[_userAddress].id != 0);
        if (_autopool == 9) return (users_9[_userAddress].id != 0);
        if (_autopool == 10) return (users_10[_userAddress].id != 0);
    }

    function withdraw() payable isOwner public {
         msg.sender.transfer(address(this).balance);
    }
    
}