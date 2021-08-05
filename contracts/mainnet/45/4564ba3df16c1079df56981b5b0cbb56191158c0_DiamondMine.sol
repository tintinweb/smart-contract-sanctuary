/**
 *Submitted for verification at Etherscan.io on 2020-06-11
*/

/*
* ==========================================================
“Even if you feel lost and weak, remember that each day can be the beginning of something wonderful. Do not give up."
I am diamondmine;
 _______   __                                                    __  __       __  __                     
/       \ /  |                                                  /  |/  \     /  |/  |                    
$$$$$$$  |$$/   ______   _____  ____    ______   _______    ____$$ |$$  \   /$$ |$$/  _______    ______  
$$ |  $$ |/  | /      \ /     \/    \  /      \ /       \  /    $$ |$$$  \ /$$$ |/  |/       \  /      \ 
$$ |  $$ |$$ | $$$$$$  |$$$$$$ $$$$  |/$$$$$$  |$$$$$$$  |/$$$$$$$ |$$$$  /$$$$ |$$ |$$$$$$$  |/$$$$$$  |
$$ |  $$ |$$ | /    $$ |$$ | $$ | $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ $$ $$/$$ |$$ |$$ |  $$ |$$    $$ |
$$ |__$$ |$$ |/$$$$$$$ |$$ | $$ | $$ |$$ \__$$ |$$ |  $$ |$$ \__$$ |$$ |$$$/ $$ |$$ |$$ |  $$ |$$$$$$$$/ 
$$    $$/ $$ |$$    $$ |$$ | $$ | $$ |$$    $$/ $$ |  $$ |$$    $$ |$$ | $/  $$ |$$ |$$ |  $$ |$$       |
$$$$$$$/  $$/  $$$$$$$/ $$/  $$/  $$/  $$$$$$/  $$/   $$/  $$$$$$$/ $$/      $$/ $$/ $$/   $$/  $$$$$$$/ 

This contract is made and designed for you and we all have to work to keep it active, keeping the mines full and removing as much stone as possible.
Our stones are: Silver, Gold, Ruby, Sapphire, Emerald, Diamond.

Our official networks
----- Website -----
https://diamondmine.live,
https://diamondmine.money,
https://diamondmine.run
Telegram Channel: https://t.me/diamondmineofficial
Hashtag: #DiamondMine
WhatsApp link : https://chat.whatsapp.com/FnzZDJEL75B95EoPBKXWxA
* ==========================================================
*/
pragma solidity >=0.5.12 <0.7.0;

contract DiamondMine {

    struct User {
        uint id;
        uint referrerCount;
        uint referrerId;
        uint earnedFromMine;
        uint earnedFromRef;
        uint earnedFromGlobal;
        address[] referrals;
    }
    
    struct UsersMine {
        uint id;
        uint referrerId;
        uint reinvestCount;
    }
    
    struct MineSlots {
        uint id;
        address userAddress;
        uint referrerId;
        uint8 eventsCount;
    }
        
    modifier validReferrerId(uint _referrerId) {
        require((_referrerId > 0) && (_referrerId < newUserId), "Invalid referrer ID");
        _;
    }
    
    event RegisterUserEvent(uint _userid, address indexed _user, address indexed _referrerAddress, uint8 indexed _automine, uint _amount, uint _time);
    event ReinvestEvent(uint _userid, address indexed _user, address indexed _referrerAddress, uint8 indexed _automine, uint _amount, uint _time);
    event DistributeUplineEvent(uint amount, address indexed _sponsorAddress, address indexed _fromAddress, uint _level, uint8 _fromMine, uint _time);
    event ReferralPaymentEvent(uint amount, address indexed _from, address indexed _to, uint8 indexed _fromMine, uint _time);

    mapping(address => User) public users;
    mapping(address => UsersMine) public users_2;
    mapping(uint => MineSlots) public mine_slots_2;
    mapping(address => UsersMine) public users_3;
    mapping(uint => MineSlots) public mine_slots_3;
    mapping(address => UsersMine) public users_4;
    mapping(uint => MineSlots) public mine_slots_4;
    mapping(address => UsersMine) public users_5;
    mapping(uint => MineSlots) public mine_slots_5;
    mapping(address => UsersMine) public users_6;
    mapping(uint => MineSlots) public mine_slots_6;
    mapping(address => UsersMine) public users_7;
    mapping(uint => MineSlots) public mine_slots_7;

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
    
    constructor() public {
        
        uplineAmount[1] = 50;
        uplineAmount[2] = 25;
        uplineAmount[3] = 15;
        uplineAmount[4] = 10;
        uplineAmount[5] = 6;
        uplineAmount[6] = 47;
        uplineAmount[7] = 100;
        
        owner =  msg.sender;
        
        User memory user = User({
            id: newUserId,
            referrerCount: uint(0),
            referrerId: uint(0),
            earnedFromMine: uint(0),
            earnedFromRef: uint(0),
            earnedFromGlobal: uint(0),
            referrals: new address[](0)
        });
        
        users[ msg.sender] = user;
        idToAddress[newUserId] =  msg.sender;
        newUserId++;
        
        //////
        
        UsersMine memory user2 = UsersMine({
            id: newSlotId_ap2,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_2[ msg.sender] = user2;
        
        MineSlots memory _newSlot2 = MineSlots({
            id: newSlotId_ap2,
            userAddress:  msg.sender,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        mine_slots_2[newSlotId_ap2] = _newSlot2;
        newUserId_ap2++;
        newSlotId_ap2++;
        
        ///////
        
        UsersMine memory user3 = UsersMine({
            id: newSlotId_ap3,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_3[ msg.sender] = user3;
        
        MineSlots memory _newSlot3 = MineSlots({
            id: newSlotId_ap3,
            userAddress:  msg.sender,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        mine_slots_3[newSlotId_ap3] = _newSlot3;
        newUserId_ap3++;
        newSlotId_ap3++;
        
        ///////
        
        UsersMine memory user4 = UsersMine({
            id: newSlotId_ap4,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_4[ msg.sender] = user4;
        
        MineSlots memory _newSlot4 = MineSlots({
            id: newSlotId_ap4,
            userAddress:  msg.sender,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        mine_slots_4[newSlotId_ap4] = _newSlot4;
        newUserId_ap4++;
        newSlotId_ap4++;
        
        ///////
        
        UsersMine memory user5 = UsersMine({
            id: newSlotId_ap5,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_5[ msg.sender] = user5;
        
        MineSlots memory _newSlot5 = MineSlots({
            id: newSlotId_ap5,
            userAddress:  msg.sender,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        mine_slots_5[newSlotId_ap5] = _newSlot5;
        newUserId_ap5++;
        newSlotId_ap5++;
        
        ///////
        
        UsersMine memory user6 = UsersMine({
            id: newSlotId_ap6,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_6[ msg.sender] = user6;
        
        MineSlots memory _newSlot6 = MineSlots({
            id: newSlotId_ap6,
            userAddress:  msg.sender,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        mine_slots_6[newSlotId_ap6] = _newSlot6;
        newUserId_ap6++;
        newSlotId_ap6++;
        
        ///////
        
        UsersMine memory user7 = UsersMine({
            id: newSlotId_ap7,
            referrerId: uint(0),
            reinvestCount: uint(0)
        });
        
        users_7[msg.sender] = user7;
        
        MineSlots memory _newSlot7 = MineSlots({
            id: newSlotId_ap7,
            userAddress:  msg.sender,
            referrerId: uint(0),
            eventsCount: uint8(0)
        });
        
        mine_slots_7[newSlotId_ap7] = _newSlot7;
        newUserId_ap7++;
        newSlotId_ap7++;
    }
    
    function enterMine(uint _referrerId) 
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
            earnedFromMine: uint(0),
            earnedFromRef: uint(0),
            earnedFromGlobal: uint(0),
            referrals: new address[](0)
        });
        idToAddress[newUserId] = _userAddress;

        emit RegisterUserEvent(newUserId, msg.sender, _referrerAddress, 1, msg.value, now);
        
        newUserId++;
        
        users[_referrerAddress].referrals.push(_userAddress);
        users[_referrerAddress].referrerCount++;

        uint256 amountToDistribute = msg.value;
        address sponsorAddress = idToAddress[_referrerId];

        payRegister(0x2e674473Dd4CB1Fc1B98189DE0fEA078cd99ba53, 5);
        payRegister(0x89E7902830dd3ad68fe44F29D44260f26c412023, 6);
        payRegister(0x65563f4Cb686Ddfaeb201dcD1C17a458Dd51F651, 6);
        
    }
      function payRegister(address _sponsorAddress, uint8 _percentage)
        private
        returns (uint256 distributeAmount)
    {
        distributeAmount = (msg.value / 100) * uplineAmount[_percentage];
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            emit DistributeUplineEvent(
                distributeAmount,
                _sponsorAddress,
                msg.sender,
                _percentage,
                _percentage,
                now
            );
        }
        return distributeAmount;
    }
    
    function buyMineSilver() 
      public 
      payable 
    {
        require(msg.value == 0.2 ether, "Participation fee in Automine is 0.2 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 2), "User already registered in AP2");

        uint eventCount = mine_slots_2[activeSlot_ap2].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                mine_slots_2[activeSlot_ap2].userAddress, 
                mine_slots_2[activeSlot_ap2].id, 
                idToAddress[users[mine_slots_2[activeSlot_ap2].userAddress].referrerId], 
                2
            ));
            mine_slots_2[activeSlot_ap2].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersMine memory user2 = UsersMine({
            id: newSlotId_ap2,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_2[msg.sender] = user2;
        
        MineSlots memory _newSlot = MineSlots({
            id: newSlotId_ap2,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        mine_slots_2[newSlotId_ap2] = _newSlot;
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
                payUpline(mine_slots_2[activeSlot_ap2].userAddress, 1, 2);
                users[mine_slots_2[activeSlot_ap2].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (mine_slots_2[activeSlot_ap2].referrerId > 0) {
                    payUpline(idToAddress[mine_slots_2[activeSlot_ap2].referrerId], 1, 2);
                    users[idToAddress[mine_slots_2[activeSlot_ap2].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 2);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            mine_slots_2[activeSlot_ap2].eventsCount++;
            
        }
        
    }

    function buyMineGold() 
      public 
      payable 
    {
        require(msg.value == 0.3 ether, "Participation fee in Automine is 0.3 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 3), "User already registered in AP3");
        require(isUserQualifiedbuyMineGold(msg.sender), "User not qualified in for payment mine MineGold");

        uint eventCount = mine_slots_3[activeSlot_ap3].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                mine_slots_3[activeSlot_ap3].userAddress, 
                mine_slots_3[activeSlot_ap3].id, 
                idToAddress[users[mine_slots_3[activeSlot_ap3].userAddress].referrerId], 
                3
            ));
            mine_slots_3[activeSlot_ap3].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersMine memory user3 = UsersMine({
            id: newSlotId_ap3,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_3[msg.sender] = user3;
        
        MineSlots memory _newSlot = MineSlots({
            id: newSlotId_ap3,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        mine_slots_3[newSlotId_ap3] = _newSlot;
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
                payUpline(mine_slots_3[activeSlot_ap3].userAddress, 1, 3);
                users[mine_slots_3[activeSlot_ap3].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (mine_slots_3[activeSlot_ap3].referrerId > 0) {
                    payUpline(idToAddress[mine_slots_3[activeSlot_ap3].referrerId], 1, 3);
                    users[idToAddress[mine_slots_3[activeSlot_ap3].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 3);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            mine_slots_3[activeSlot_ap3].eventsCount++;
            
        }
        
    }

    function buyMineRubi() 
      public 
      payable 
    {
        require(msg.value == 0.4 ether, "Participation fee in Automine is 0.4 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 4), "User already registered in AP4");
        require(isUserQualifiedbuyMineRubi(msg.sender), "User not qualified in for payment mine MineRubi");

        uint eventCount = mine_slots_4[activeSlot_ap4].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                mine_slots_4[activeSlot_ap4].userAddress, 
                mine_slots_4[activeSlot_ap4].id, 
                idToAddress[users[mine_slots_4[activeSlot_ap4].userAddress].referrerId], 
                4
            ));
            mine_slots_4[activeSlot_ap4].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersMine memory user4 = UsersMine({
            id: newSlotId_ap4,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_4[msg.sender] = user4;
        
        MineSlots memory _newSlot = MineSlots({
            id: newSlotId_ap4,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        mine_slots_4[newSlotId_ap4] = _newSlot;
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
                payUpline(mine_slots_4[activeSlot_ap4].userAddress, 1, 4);
                users[mine_slots_4[activeSlot_ap4].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (mine_slots_4[activeSlot_ap4].referrerId > 0) {
                    payUpline(idToAddress[mine_slots_4[activeSlot_ap4].referrerId], 1, 4);
                    users[idToAddress[mine_slots_4[activeSlot_ap4].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 4);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            mine_slots_4[activeSlot_ap4].eventsCount++;
            
        }
        
    }

    function buyMineSapphire() 
      public 
      payable 
    {
        require(msg.value == 0.5 ether, "Participation fee in Automine is 0.5 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 5), "User already registered in AP5");
         require(isUserQualifiedbuyMineSapphire(msg.sender), "User not qualified in for payment mine MineSapphire");

        uint eventCount = mine_slots_5[activeSlot_ap5].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                mine_slots_5[activeSlot_ap5].userAddress, 
                mine_slots_5[activeSlot_ap5].id, 
                idToAddress[users[mine_slots_5[activeSlot_ap5].userAddress].referrerId], 
                5
            ));
            mine_slots_5[activeSlot_ap5].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersMine memory user5 = UsersMine({
            id: newSlotId_ap5,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_5[msg.sender] = user5;
        
        MineSlots memory _newSlot = MineSlots({
            id: newSlotId_ap5,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        mine_slots_5[newSlotId_ap5] = _newSlot;
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
                payUpline(mine_slots_5[activeSlot_ap5].userAddress, 1, 5);
                users[mine_slots_5[activeSlot_ap5].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (mine_slots_5[activeSlot_ap5].referrerId > 0) {
                    payUpline(idToAddress[mine_slots_5[activeSlot_ap5].referrerId], 1, 5);
                    users[idToAddress[mine_slots_5[activeSlot_ap5].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 5);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            mine_slots_5[activeSlot_ap5].eventsCount++;
            
        }
        
    }

    function buyMineEmerald() 
      public 
      payable 
    {
        require(msg.value == 0.7 ether, "Participation fee in Automine is 0.7 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 6), "User already registered in AP6");
        require(isUserQualifiedbuyMineEmerald(msg.sender), "User not qualified in for payment mine MineEmerald");

        uint eventCount = mine_slots_6[activeSlot_ap6].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                mine_slots_6[activeSlot_ap6].userAddress, 
                mine_slots_6[activeSlot_ap6].id, 
                idToAddress[users[mine_slots_6[activeSlot_ap6].userAddress].referrerId], 
                6
            ));
            mine_slots_6[activeSlot_ap6].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersMine memory user6 = UsersMine({
            id: newSlotId_ap6,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_6[msg.sender] = user6;
        
        MineSlots memory _newSlot = MineSlots({
            id: newSlotId_ap6,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        mine_slots_6[newSlotId_ap6] = _newSlot;
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
                payUpline(mine_slots_6[activeSlot_ap6].userAddress, 1, 6);
                users[mine_slots_6[activeSlot_ap6].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (mine_slots_6[activeSlot_ap6].referrerId > 0) {
                    payUpline(idToAddress[mine_slots_6[activeSlot_ap6].referrerId], 1, 6);
                    users[idToAddress[mine_slots_6[activeSlot_ap6].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 6);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            mine_slots_6[activeSlot_ap6].eventsCount++;
            
        }
        
    }

    function buyMineDiamond() 
      public 
      payable 
    {
        require(msg.value == 1 ether, "Participation fee in Automine is 1 ETH");
        require(isUserExists(msg.sender, 1), "User not present in AP1");
        require(isUserQualified(msg.sender), "User not qualified in AP1");
        require(!isUserExists(msg.sender, 7), "User already registered in AP7");
        require(isUserQualifiedbuyMineDiamond(msg.sender), "User not qualified in for payment mine MineDiamond");

        uint eventCount = mine_slots_7[activeSlot_ap7].eventsCount;
        uint newEventCount = eventCount + 1;

        if (newEventCount == 3) {
            require(reinvestSlot(
                mine_slots_7[activeSlot_ap7].userAddress, 
                mine_slots_7[activeSlot_ap7].id, 
                idToAddress[users[mine_slots_7[activeSlot_ap7].userAddress].referrerId], 
                7
            ));
            mine_slots_7[activeSlot_ap7].eventsCount++;
        }
        
        uint _referrerId = users[msg.sender].referrerId;

        UsersMine memory user7 = UsersMine({
            id: newSlotId_ap7,
            referrerId: _referrerId,
            reinvestCount: uint(0)
        });
        users_7[msg.sender] = user7;
        
        MineSlots memory _newSlot = MineSlots({
            id: newSlotId_ap7,
            userAddress: msg.sender,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        mine_slots_7[newSlotId_ap7] = _newSlot;
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
                payUpline(mine_slots_7[activeSlot_ap7].userAddress, 1, 7);
                users[mine_slots_7[activeSlot_ap7].userAddress].earnedFromGlobal += msg.value/2;
            }
            if(eventCount == 1) {
                if (mine_slots_7[activeSlot_ap7].referrerId > 0) {
                    payUpline(idToAddress[mine_slots_7[activeSlot_ap7].referrerId], 1, 7);
                    users[idToAddress[mine_slots_7[activeSlot_ap7].referrerId]].earnedFromRef += msg.value/2;
                }
                else {
                    payUpline(idToAddress[1], 1, 7);
                    users[idToAddress[1]].earnedFromRef += msg.value/2;
                }
            }

            mine_slots_7[activeSlot_ap7].eventsCount++;
            
        }
        
    }
    function isUserQualifiedbuyMineGold(address _userAddress)
        public
        view
        returns (bool)
    {
        return (users_2[_userAddress].id > 0);
    }

    function isUserQualifiedbuyMineRubi(address _userAddress)
        public
        view
        returns (bool)
    {
        return (users_3[_userAddress].id > 0);
    }

    function isUserQualifiedbuyMineSapphire(address _userAddress)
        public
        view
        returns (bool)
    {
        return (users_4[_userAddress].id > 0);
    }

    function isUserQualifiedbuyMineEmerald(address _userAddress)
        public
        view
        returns (bool)
    {
        return (users_5[_userAddress].id > 0);
    }

    function isUserQualifiedbuyMineDiamond(address _userAddress)
        public
        view
        returns (bool)
    {
        return (users_6[_userAddress].id > 0);
    }

    function reinvestSlot(address _userAddress, uint _userId, address _sponsorAddress, uint8 _fromMine) private returns (bool _isReinvested) {

        uint _referrerId = users[_userAddress].referrerId;

        MineSlots memory _reinvestslot = MineSlots({
            id: _userId,
            userAddress: _userAddress,
            referrerId: _referrerId,
            eventsCount: uint8(0)
        });
        
        if (_fromMine == 2) {
            users_2[mine_slots_2[activeSlot_ap2].userAddress].reinvestCount++;        
            mine_slots_2[newSlotId_ap2] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap2, _userAddress, _sponsorAddress, 2, msg.value, now);
            newSlotId_ap2++;
        }
        if (_fromMine == 3) {
            users_3[mine_slots_3[activeSlot_ap3].userAddress].reinvestCount++;        
            mine_slots_3[newSlotId_ap3] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap3, _userAddress, _sponsorAddress, 3, msg.value, now);
            newSlotId_ap3++;
        }
        if (_fromMine == 4) {
            users_4[mine_slots_4[activeSlot_ap4].userAddress].reinvestCount++;        
            mine_slots_4[newSlotId_ap4] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap4, _userAddress, _sponsorAddress, 4, msg.value, now);
            newSlotId_ap4++;
        }
        if (_fromMine == 5) {
            users_5[mine_slots_5[activeSlot_ap5].userAddress].reinvestCount++;        
            mine_slots_5[newSlotId_ap5] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap5, _userAddress, _sponsorAddress, 5, msg.value, now);
            newSlotId_ap5++;
        }
        if (_fromMine == 6) {
            users_6[mine_slots_6[activeSlot_ap6].userAddress].reinvestCount++;        
            mine_slots_6[newSlotId_ap6] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap6, _userAddress, _sponsorAddress, 6, msg.value, now);
            newSlotId_ap6++;
        }
        if (_fromMine == 7) {
            users_7[mine_slots_7[activeSlot_ap7].userAddress].reinvestCount++;        
            mine_slots_7[newSlotId_ap7] = _reinvestslot;
            emit ReinvestEvent(newSlotId_ap7, _userAddress, _sponsorAddress, 7, msg.value, now);
            newSlotId_ap7++;
        }
        
        if (_fromMine == 2) {
            mine_slots_2[activeSlot_ap2].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap2+1;

            payUpline(mine_slots_2[_nextActiveSlot].userAddress, 1, 2);
            users[mine_slots_2[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap2++;
        }
        if (_fromMine == 3) {
            mine_slots_3[activeSlot_ap3].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap3+1;

            payUpline(mine_slots_3[_nextActiveSlot].userAddress, 1, 3);
            users[mine_slots_3[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap3++;
        }
        if (_fromMine == 4) {
            mine_slots_4[activeSlot_ap4].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap4+1;

            payUpline(mine_slots_4[_nextActiveSlot].userAddress, 1, 4);
            users[mine_slots_4[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap4++;
        }
        if (_fromMine == 5) {
            mine_slots_5[activeSlot_ap5].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap5+1;

            payUpline(mine_slots_5[_nextActiveSlot].userAddress, 1, 5);
            users[mine_slots_5[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap5++;
        }
        if (_fromMine == 6) {
            mine_slots_6[activeSlot_ap6].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap6+1;

            payUpline(mine_slots_6[_nextActiveSlot].userAddress, 1, 6);
            users[mine_slots_6[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap6++;
        }
        if (_fromMine == 7) {
            mine_slots_7[activeSlot_ap7].eventsCount = 3;
            uint _nextActiveSlot = activeSlot_ap7+1;

            payUpline(mine_slots_7[_nextActiveSlot].userAddress, 1, 7);
            users[mine_slots_7[_nextActiveSlot].userAddress].earnedFromGlobal += msg.value/2;
            activeSlot_ap7++;
        }

        _isReinvested = true;

        return _isReinvested;

    }
    
    function payUpline(address _sponsorAddress, uint8 _refLevel, uint8 _fromMine) private returns (uint distributeAmount) {        
        require( _refLevel <= 4);
        distributeAmount = msg.value / 100 * uplineAmount[_refLevel];
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            if (_fromMine > 1) {
                emit ReferralPaymentEvent(distributeAmount, msg.sender, _sponsorAddress, _fromMine, now);
            } else
                emit DistributeUplineEvent(distributeAmount, _sponsorAddress, msg.sender, _refLevel, _fromMine, now);
        }        
        return distributeAmount;
    }
    
    function payFirstLine(address _sponsorAddress, uint payAmount, uint8 _fromMine) private returns (uint distributeAmount) {        
        distributeAmount = payAmount;
        if (address(uint160(_sponsorAddress)).send(distributeAmount)) {
            if (_fromMine > 1) {
                emit ReferralPaymentEvent(distributeAmount, msg.sender, _sponsorAddress, _fromMine, now);
            } else emit DistributeUplineEvent(distributeAmount, _sponsorAddress, msg.sender, 1, _fromMine, now);
        }        
        return distributeAmount;        
    }
    
    function isUserQualified(address _userAddress) public view returns (bool) {
        return (users[_userAddress].referrerCount > 0);
    }
    
    function isUserExists(address _userAddress, uint8 _automine) public view returns (bool) {
        require((_automine > 0) && (_automine <= 7));
        if (_automine == 1) return (users[_userAddress].id != 0);
        if (_automine == 2) return (users_2[_userAddress].id != 0);
        if (_automine == 3) return (users_3[_userAddress].id != 0);
        if (_automine == 4) return (users_4[_userAddress].id != 0);
        if (_automine == 5) return (users_5[_userAddress].id != 0);
        if (_automine == 6) return (users_6[_userAddress].id != 0);
        if (_automine == 7) return (users_7[_userAddress].id != 0);
    }
    
    function getUserReferrals(address _userAddress)
        public
        view
        returns (address[] memory)
      {
        return users[_userAddress].referrals;
      }
    
}