/**
 *Submitted for verification at Etherscan.io on 2020-06-03
*/

/**
* ==========================================================
*
* SouSouETH
* ONE TEAM, ONE COMMUNITY, UNITED WE WILL PROSPER
*
* Website  : https://sousoueth.com
* Telegram : https://tel.sousoueth.com
*
* ==========================================================
**/

pragma solidity >=0.5.12 <0.7.0;

contract SouSouETH {

    struct User {
        uint id;
        uint referrerCount;
        uint referrerId;
        uint earnedFromPool;
        uint earnedFromRef;
        uint earnedFromGlobal;
        address[] referrals;
    }
    
    struct UsersPool {
        uint id;
        uint referrerId;
        uint reinvestCount;
    }
    
    struct PoolSlots {
        uint id;
        address userAddress;
        uint referrerId;
        uint8 eventsCount;
    }
        
    modifier validReferrerId(uint _referrerId) {
        require((_referrerId > 0) && (_referrerId < newUserId), "Invalid referrer ID");
        _;
    }
    
    event RegisterUserEvent(uint _userid, address indexed _user, address indexed _referrerAddress, uint8 indexed _autopool, uint _amount, uint _time);
    event ReinvestEvent(uint _userid, address indexed _user, address indexed _referrerAddress, uint8 indexed _autopool, uint _amount, uint _time);
    event DistributeUplineEvent(uint amount, address indexed _sponsorAddress, address indexed _fromAddress, uint _level, uint8 _fromPool, uint _time);
    event ReferralPaymentEvent(uint amount, address indexed _from, address indexed _to, uint8 indexed _fromPool, uint _time);

    mapping(address => User) public users;
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

    mapping(uint => address) public idToAddress;
    mapping (uint8 => uint8) public uplineAmount;
    
    uint public newUserId = 1;
    uint public newUserId_ap2 = 1;
    uint public newUserId_ap3 = 1;
    uint public newUserId_ap4 = 1;
    uint public newUserId_ap5 = 1;
    uint public newUserId_ap6 = 1;
    uint public newUserId_ap7 = 1;

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
    
    address public owner;
    
    constructor(address _ownerAddress) public {
        
        uplineAmount[1] = 50;
        uplineAmount[2] = 25;
        uplineAmount[3] = 15;
        uplineAmount[4] = 10;
        
        owner = _ownerAddress;
        
        User memory user = User({
            id: newUserId,
            referrerCount: uint(0),
            referrerId: uint(0),
            earnedFromPool: uint(0),
            earnedFromRef: uint(0),
            earnedFromGlobal: uint(0),
            referrals: new address[](0)
        });
        
        users[_ownerAddress] = user;
        idToAddress[newUserId] = _ownerAddress;
        newUserId++;
        
        //////
        
        UsersPool memory user2 = UsersPool({
            id: newSlotId_ap2,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_2[_ownerAddress] = user2;
        
        PoolSlots memory _newSlot2 = PoolSlots({
            id: newSlotId_ap2,
            userAddress: _ownerAddress,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        pool_slots_2[newSlotId_ap2] = _newSlot2;
        newUserId_ap2++;
        newSlotId_ap2++;
        
        ///////
        
        UsersPool memory user3 = UsersPool({
            id: newSlotId_ap3,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_3[_ownerAddress] = user3;
        
        PoolSlots memory _newSlot3 = PoolSlots({
            id: newSlotId_ap3,
            userAddress: _ownerAddress,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        pool_slots_3[newSlotId_ap3] = _newSlot3;
        newUserId_ap3++;
        newSlotId_ap3++;
        
        ///////
        
        UsersPool memory user4 = UsersPool({
            id: newSlotId_ap4,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_4[_ownerAddress] = user4;
        
        PoolSlots memory _newSlot4 = PoolSlots({
            id: newSlotId_ap4,
            userAddress: _ownerAddress,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        pool_slots_4[newSlotId_ap4] = _newSlot4;
        newUserId_ap4++;
        newSlotId_ap4++;
        
        ///////
        
        UsersPool memory user5 = UsersPool({
            id: newSlotId_ap5,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_5[_ownerAddress] = user5;
        
        PoolSlots memory _newSlot5 = PoolSlots({
            id: newSlotId_ap5,
            userAddress: _ownerAddress,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        pool_slots_5[newSlotId_ap5] = _newSlot5;
        newUserId_ap5++;
        newSlotId_ap5++;
        
        ///////
        
        UsersPool memory user6 = UsersPool({
            id: newSlotId_ap6,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_6[_ownerAddress] = user6;
        
        PoolSlots memory _newSlot6 = PoolSlots({
            id: newSlotId_ap6,
            userAddress: _ownerAddress,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        pool_slots_6[newSlotId_ap6] = _newSlot6;
        newUserId_ap6++;
        newSlotId_ap6++;
        
        ///////
        
        UsersPool memory user7 = UsersPool({
            id: newSlotId_ap7,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_7[_ownerAddress] = user7;
        
        PoolSlots memory _newSlot7 = PoolSlots({
            id: newSlotId_ap7,
            userAddress: _ownerAddress,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        pool_slots_7[newSlotId_ap7] = _newSlot7;
        newUserId_ap7++;
        newSlotId_ap7++;
    }
    
    function participatePool1(uint _referrerId) 
      public 
      payable 
      validReferrerId(_referrerId) 
    {
        
        require(msg.value == 0.1 ether, "Participation fee is 0.1 ETH");
        require(!isUserExists(msg.sender, 1), "User already registered");

        address _userAddress = msg.sender;
        address _referrerAddress = idToAddress[_referrerId];
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        users[_userAddress] = User({
            id: newUserId,
            referrerCount: uint(0),
            referrerId: _referrerId,
            earnedFromPool: uint(0),
            earnedFromRef: uint(0),
            earnedFromGlobal: uint(0),
            referrals: new address[](0)
        });
        idToAddress[newUserId] = _userAddress;

        emit RegisterUserEvent(newUserId, msg.sender, _referrerAddress, 1, msg.value, now);
        
        newUserId++;
        
        users[_referrerAddress].referrals.push(_userAddress);
        users[_referrerAddress].referrerCount++;
        
        uint amountToDistribute = msg.value;
        address sponsorAddress = idToAddress[_referrerId];        
        
        for (uint8 i = 1; i <= 4; i++) {
            
            if ( isUserExists(sponsorAddress, 1) ) {
                uint paid = payUpline(sponsorAddress, i, 1);
                amountToDistribute -= paid;
                users[sponsorAddress].earnedFromPool += paid;
                address _nextSponsorAddress = idToAddress[users[sponsorAddress].referrerId];
                sponsorAddress = _nextSponsorAddress;
            }
            
        }
        
        if (amountToDistribute > 0) {
            payFirstLine(idToAddress[1], amountToDistribute, 1);
            users[idToAddress[1]].earnedFromPool += amountToDistribute;
        }
        
    }
    
    function participatePool2() 
      public 
      payable 
    {
        require(msg.value == 0.2 ether, "Participation fee in Autopool is 0.2 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 2), "User already registered in AP2");

        uint eventCount = pool_slots_2[activeSlot_ap2].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_2[activeSlot_ap2].userAddress, 
                pool_slots_2[activeSlot_ap2].id, 
                idToAddress[users[pool_slots_2[activeSlot_ap2].userAddress].referrerId], 
                2
            ));
            pool_slots_2[activeSlot_ap2].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersPool memory user2 = UsersPool({
            id: newSlotId_ap2,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_2[msg.sender] = user2;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap2,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        pool_slots_2[newSlotId_ap2] = _newSlot;
        newUserId_ap2++;
        emit RegisterUserEvent(newSlotId_ap2, msg.sender, idToAddress[_referrerId], 2, msg.value, now);
        
        if (_referrerId > 0) {
            payUpline(idToAddress[_referrerId], 1, 2);
            users[idToAddress[_referrerId]].earnedFromRef += msg.value/2;
        }
        else{
            payUpline(idToAddress[1], 1, 2);
            users[idToAddress[1]].earnedFromRef += msg.value/2;
        }

        newSlotId_ap2++;

        if (eventCount < 2) {
            
            if(eventCount == 0) {
                payUpline(pool_slots_2[activeSlot_ap2].userAddress, 1, 2);
                users[pool_slots_2[activeSlot_ap2].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (pool_slots_2[activeSlot_ap2].referrerId > 0) {
                    payUpline(idToAddress[pool_slots_2[activeSlot_ap2].referrerId], 1, 2);
                    users[idToAddress[pool_slots_2[activeSlot_ap2].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 2);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            pool_slots_2[activeSlot_ap2].eventsCount++;
            
        }
        
    }

    function participatePool3() 
      public 
      payable 
    {
        require(msg.value == 0.3 ether, "Participation fee in Autopool is 0.3 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 3), "User already registered in AP3");

        uint eventCount = pool_slots_3[activeSlot_ap3].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_3[activeSlot_ap3].userAddress, 
                pool_slots_3[activeSlot_ap3].id, 
                idToAddress[users[pool_slots_3[activeSlot_ap3].userAddress].referrerId], 
                3
            ));
            pool_slots_3[activeSlot_ap3].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersPool memory user3 = UsersPool({
            id: newSlotId_ap3,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_3[msg.sender] = user3;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap3,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        pool_slots_3[newSlotId_ap3] = _newSlot;
        newUserId_ap3++;
        emit RegisterUserEvent(newSlotId_ap3, msg.sender, idToAddress[_referrerId], 3, msg.value, now);
        
        if (_referrerId > 0) {
            payUpline(idToAddress[_referrerId], 1, 3);
            users[idToAddress[_referrerId]].earnedFromRef += msg.value/2;
        }
        else{
            payUpline(idToAddress[1], 1, 3);
            users[idToAddress[1]].earnedFromRef += msg.value/2;
        }

        newSlotId_ap3++;

        if (eventCount < 2) {
            
            if(eventCount == 0) {
                payUpline(pool_slots_3[activeSlot_ap3].userAddress, 1, 3);
                users[pool_slots_3[activeSlot_ap3].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (pool_slots_3[activeSlot_ap3].referrerId > 0) {
                    payUpline(idToAddress[pool_slots_3[activeSlot_ap3].referrerId], 1, 3);
                    users[idToAddress[pool_slots_3[activeSlot_ap3].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 3);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            pool_slots_3[activeSlot_ap3].eventsCount++;
            
        }
        
    }

    function participatePool4() 
      public 
      payable 
    {
        require(msg.value == 0.4 ether, "Participation fee in Autopool is 0.4 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 4), "User already registered in AP4");

        uint eventCount = pool_slots_4[activeSlot_ap4].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_4[activeSlot_ap4].userAddress, 
                pool_slots_4[activeSlot_ap4].id, 
                idToAddress[users[pool_slots_4[activeSlot_ap4].userAddress].referrerId], 
                4
            ));
            pool_slots_4[activeSlot_ap4].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersPool memory user4 = UsersPool({
            id: newSlotId_ap4,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_4[msg.sender] = user4;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap4,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        pool_slots_4[newSlotId_ap4] = _newSlot;
        newUserId_ap4++;
        emit RegisterUserEvent(newSlotId_ap4, msg.sender, idToAddress[_referrerId], 4, msg.value, now);
        
        if (_referrerId > 0) {
            payUpline(idToAddress[_referrerId], 1, 4);
            users[idToAddress[_referrerId]].earnedFromRef += msg.value/2;
        }
        else{
            payUpline(idToAddress[1], 1, 4);
            users[idToAddress[1]].earnedFromRef += msg.value/2;
        }

        newSlotId_ap4++;

        if (eventCount < 2) {
            
            if(eventCount == 0) {
                payUpline(pool_slots_4[activeSlot_ap4].userAddress, 1, 4);
                users[pool_slots_4[activeSlot_ap4].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (pool_slots_4[activeSlot_ap4].referrerId > 0) {
                    payUpline(idToAddress[pool_slots_4[activeSlot_ap4].referrerId], 1, 4);
                    users[idToAddress[pool_slots_4[activeSlot_ap4].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 4);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            pool_slots_4[activeSlot_ap4].eventsCount++;
            
        }
        
    }

    function participatePool5() 
      public 
      payable 
    {
        require(msg.value == 0.5 ether, "Participation fee in Autopool is 0.5 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 5), "User already registered in AP5");

        uint eventCount = pool_slots_5[activeSlot_ap5].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_5[activeSlot_ap5].userAddress, 
                pool_slots_5[activeSlot_ap5].id, 
                idToAddress[users[pool_slots_5[activeSlot_ap5].userAddress].referrerId], 
                5
            ));
            pool_slots_5[activeSlot_ap5].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersPool memory user5 = UsersPool({
            id: newSlotId_ap5,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_5[msg.sender] = user5;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap5,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        pool_slots_5[newSlotId_ap5] = _newSlot;
        newUserId_ap5++;
        emit RegisterUserEvent(newSlotId_ap5, msg.sender, idToAddress[_referrerId], 5, msg.value, now);
        
        if (_referrerId > 0) {
            payUpline(idToAddress[_referrerId], 1, 5);
            users[idToAddress[_referrerId]].earnedFromRef += msg.value/2;
        }
        else{
            payUpline(idToAddress[1], 1, 5);
            users[idToAddress[1]].earnedFromRef += msg.value/2;
        }

        newSlotId_ap5++;

        if (eventCount < 2) {
            
            if(eventCount == 0) {
                payUpline(pool_slots_5[activeSlot_ap5].userAddress, 1, 5);
                users[pool_slots_5[activeSlot_ap5].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (pool_slots_5[activeSlot_ap5].referrerId > 0) {
                    payUpline(idToAddress[pool_slots_5[activeSlot_ap5].referrerId], 1, 5);
                    users[idToAddress[pool_slots_5[activeSlot_ap5].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 5);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            pool_slots_5[activeSlot_ap5].eventsCount++;
            
        }
        
    }

    function participatePool6() 
      public 
      payable 
    {
        require(msg.value == 0.7 ether, "Participation fee in Autopool is 0.7 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 6), "User already registered in AP6");

        uint eventCount = pool_slots_6[activeSlot_ap6].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_6[activeSlot_ap6].userAddress, 
                pool_slots_6[activeSlot_ap6].id, 
                idToAddress[users[pool_slots_6[activeSlot_ap6].userAddress].referrerId], 
                6
            ));
            pool_slots_6[activeSlot_ap6].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersPool memory user6 = UsersPool({
            id: newSlotId_ap6,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_6[msg.sender] = user6;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap6,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        pool_slots_6[newSlotId_ap6] = _newSlot;
        newUserId_ap6++;
        emit RegisterUserEvent(newSlotId_ap6, msg.sender, idToAddress[_referrerId], 6, msg.value, now);
        
        if (_referrerId > 0) {
            payUpline(idToAddress[_referrerId], 1, 6);
            users[idToAddress[_referrerId]].earnedFromRef += msg.value/2;
        }
        else{
            payUpline(idToAddress[1], 1, 6);
            users[idToAddress[1]].earnedFromRef += msg.value/2;
        }

        newSlotId_ap6++;

        if (eventCount < 2) {
            
            if(eventCount == 0) {
                payUpline(pool_slots_6[activeSlot_ap6].userAddress, 1, 6);
                users[pool_slots_6[activeSlot_ap6].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (pool_slots_6[activeSlot_ap6].referrerId > 0) {
                    payUpline(idToAddress[pool_slots_6[activeSlot_ap6].referrerId], 1, 6);
                    users[idToAddress[pool_slots_6[activeSlot_ap6].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 6);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            pool_slots_6[activeSlot_ap6].eventsCount++;
            
        }
        
    }

    function participatePool7() 
      public 
      payable 
    {
        require(msg.value == 1 ether, "Participation fee in Autopool is 1 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 7), "User already registered in AP7");

        uint eventCount = pool_slots_7[activeSlot_ap7].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                pool_slots_7[activeSlot_ap7].userAddress, 
                pool_slots_7[activeSlot_ap7].id, 
                idToAddress[users[pool_slots_7[activeSlot_ap7].userAddress].referrerId], 
                7
            ));
            pool_slots_7[activeSlot_ap7].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersPool memory user7 = UsersPool({
            id: newSlotId_ap7,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_7[msg.sender] = user7;
        
        PoolSlots memory _newSlot = PoolSlots({
            id: newSlotId_ap7,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        pool_slots_7[newSlotId_ap7] = _newSlot;
        newUserId_ap7++;
        emit RegisterUserEvent(newSlotId_ap7, msg.sender, idToAddress[_referrerId], 7, msg.value, now);

        if (_referrerId > 0) {
            payUpline(idToAddress[_referrerId], 1, 7);
            users[idToAddress[_referrerId]].earnedFromRef += msg.value/2;
        }
        else{
            payUpline(idToAddress[1], 1, 7);
            users[idToAddress[1]].earnedFromRef += msg.value/2;
        }
        
        newSlotId_ap7++;

        if (eventCount < 2) {
            
            if(eventCount == 0) {
                payUpline(pool_slots_7[activeSlot_ap7].userAddress, 1, 7);
                users[pool_slots_7[activeSlot_ap7].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (pool_slots_7[activeSlot_ap7].referrerId > 0) {
                    payUpline(idToAddress[pool_slots_7[activeSlot_ap7].referrerId], 1, 7);
                    users[idToAddress[pool_slots_7[activeSlot_ap7].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 7);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            pool_slots_7[activeSlot_ap7].eventsCount++;
            
        }
        
    }

    function reinvestSlot(address _userAddress, uint _userId, address _sponsorAddress, uint8 _fromPool) private returns (bool _isReinvested) {

        uint _referrerId = users[_userAddress].referrerId;

        PoolSlots memory _reinvestslot = PoolSlots({
            id: _userId,
            userAddress: _userAddress,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
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
        
        if (_fromPool == 2) {
            pool_slots_2[activeSlot_ap2].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap2+1;

            payUpline(pool_slots_2[_nextActiveSlot].userAddress, 1, 2);
            users[pool_slots_2[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap2++;
        }
        if (_fromPool == 3) {
            pool_slots_3[activeSlot_ap3].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap3+1;

            payUpline(pool_slots_3[_nextActiveSlot].userAddress, 1, 3);
            users[pool_slots_3[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap3++;
        }
        if (_fromPool == 4) {
            pool_slots_4[activeSlot_ap4].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap4+1;

            payUpline(pool_slots_4[_nextActiveSlot].userAddress, 1, 4);
            users[pool_slots_4[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap4++;
        }
        if (_fromPool == 5) {
            pool_slots_5[activeSlot_ap5].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap5+1;

            payUpline(pool_slots_5[_nextActiveSlot].userAddress, 1, 5);
            users[pool_slots_5[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap5++;
        }
        if (_fromPool == 6) {
            pool_slots_6[activeSlot_ap6].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap6+1;

            payUpline(pool_slots_6[_nextActiveSlot].userAddress, 1, 6);
            users[pool_slots_6[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap6++;
        }
        if (_fromPool == 7) {
            pool_slots_7[activeSlot_ap7].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap7+1;

            payUpline(pool_slots_7[_nextActiveSlot].userAddress, 1, 7);
            users[pool_slots_7[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap7++;
        }

        _isReinvested = true;

        return _isReinvested;

    }
    
    function payUpline(address _sponsorAddress, uint8 _refLevel, uint8 _fromPool) private returns (uint distributeAmount) {        
        require( _refLevel <= 4);
        distributeAmount = msg.value / 100 * uplineAmount[_refLevel];
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            if (_fromPool > 1) {
                emit ReferralPaymentEvent(distributeAmount, msg.sender, _sponsorAddress, _fromPool, now);
            } else
                emit DistributeUplineEvent(distributeAmount, _sponsorAddress, msg.sender, _refLevel, _fromPool, now);
        }        
        return distributeAmount;
    }
    
    function payFirstLine(address _sponsorAddress, uint payAmount, uint8 _fromPool) private returns (uint distributeAmount) {        
        distributeAmount = payAmount;
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            if (_fromPool > 1) {
                emit ReferralPaymentEvent(distributeAmount, msg.sender, _sponsorAddress, _fromPool, now);
            } else emit DistributeUplineEvent(distributeAmount, _sponsorAddress, msg.sender, 1, _fromPool, now);
        }        
        return distributeAmount;        
    }
    
    function isUserQualified(address _userAddress) public view returns (bool) {
        return (users[_userAddress].referrerCount > 0);
    }
    
    function isUserExists(address _userAddress, uint8 _autopool) public view returns (bool) {
        require((_autopool > 0) && (_autopool <= 7));
        if (_autopool == 1) return (users[_userAddress].id != 0);
        if (_autopool == 2) return (users_2[_userAddress].id != 0);
        if (_autopool == 3) return (users_3[_userAddress].id != 0);
        if (_autopool == 4) return (users_4[_userAddress].id != 0);
        if (_autopool == 5) return (users_5[_userAddress].id != 0);
        if (_autopool == 6) return (users_6[_userAddress].id != 0);
        if (_autopool == 7) return (users_7[_userAddress].id != 0);
    }
    
    function getUserReferrals(address _userAddress)
        public
        view
        returns (address[] memory)
      {
        return users[_userAddress].referrals;
      }
    
}