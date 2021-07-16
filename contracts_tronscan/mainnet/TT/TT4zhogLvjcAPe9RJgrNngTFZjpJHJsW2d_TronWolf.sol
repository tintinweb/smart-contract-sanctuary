//SourceUnit: TronWolf.sol

pragma solidity >=0.4.23 <0.6.0;

contract TronWolf {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_SLOT = 35;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    uint16 internal constant LEVEL_PER = 3000;
    uint16 internal constant LEVEL_DIVISOR = 10000;

    uint public lastUserId = 2;
    address public owner;
    address public deployer;
    
    mapping(uint => uint) public slotPrice;
    uint8 public constant levelIncome = 200;
        
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user,uint indexed userId, address indexed referrer,uint referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedTRONReceive(address indexed receiver,uint receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level);
    event MissedLevelIncome(address indexed receiver,uint  receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level, uint256 networklevel);
    event SentDividends(address indexed from,uint indexed fromId, address receiver,uint indexed receiverId, uint8 matrix, uint8 level, bool isExtra);
    event SentLevelincome(address indexed from,uint indexed fromId, address receiver,uint indexed receiverId, uint8 matrix, uint8 level,uint256 networklevel, bool isExtraLevel);
    
    modifier onlyDeployer() {
        require (msg.sender == deployer);
        _;
    }
    
    constructor(address ownerAddress) public {

        slotPrice[1] = 200 trx;
        slotPrice[2] = 260 trx;  
        slotPrice[3] = 335 trx;  
        slotPrice[4] = 440 trx;  
        slotPrice[5] = 575 trx;  
        slotPrice[6] = 750 trx;  
        slotPrice[7] = 965 trx;  
        slotPrice[8] = 1250 trx;  
        slotPrice[9] = 1625 trx;  
        slotPrice[10] = 2125 trx;  
        slotPrice[11] = 2750 trx; 
        slotPrice[12] = 3575 trx;  
        slotPrice[13] = 4650 trx;  
        slotPrice[14] = 6000 trx;  
        slotPrice[15] = 8000 trx;  
        slotPrice[16] = 10500 trx;  
        slotPrice[17] = 13500 trx;  
        slotPrice[18] = 17500 trx;  
        slotPrice[19] = 22500 trx;  
        slotPrice[20] = 30000 trx;  
        slotPrice[21] = 37500 trx;  
        slotPrice[22] = 50000 trx; 
        slotPrice[23] = 65000 trx; 
        slotPrice[24] = 84500 trx; 
        slotPrice[25] = 110000 trx; 
        slotPrice[26] = 142000 trx;  
        slotPrice[27] = 185000 trx; 
        slotPrice[28] = 240000 trx; 
        slotPrice[29] = 315000 trx; 
        slotPrice[30] = 400000 trx; 
        slotPrice[31] = 520000 trx; 
        slotPrice[32] = 675000 trx; 
        slotPrice[33] = 880000 trx; 
        slotPrice[34] = 1150000 trx; 
        slotPrice[35] = 1500000 trx; 

        owner = ownerAddress;
        deployer = msg.sender;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_SLOT; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "no user exist");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == slotPrice[level], "invalid price");
        require(level > 1 && level <= LAST_SLOT, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "slot activated");
            require(users[msg.sender].activeX3Levels[level - 1], "previous slot not activated");
            require(users[msg.sender].activeX6Levels[level - 1], "previous slot not activated"); 
            

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
          
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "slot activated"); 
            require(users[msg.sender].activeX6Levels[level - 1], "previous slot not activated"); 
            require(users[msg.sender].activeX3Levels[level - 1], "previous slot not activated");

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            distributeLevelIncome(msg.sender, matrix, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == (slotPrice[1] * 2), "Wrong Price");
        require(!isUserExists(userAddress), "User Exists");
        require(isUserExists(referrerAddress), "Wrong Referrer");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        distributeLevelIncome(userAddress, 2, 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendTRONDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress,users[userAddress].id,  referrerAddress,users[referrerAddress].id, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_SLOT) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRONDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id,  referrerAddress,users[referrerAddress].id, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTRONDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref, users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref, users[ref].id, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].id, 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].id, 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTRONDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_SLOT) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTRONDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function get3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].reinvestCount,
                users[userAddress].x3Matrix[level].blocked);
    }

    function getX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTRONReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedTRONReceive(receiver,users[receiver].id, _from,users[_from].id, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedTRONReceive(receiver,users[receiver].id, _from,users[_from].id, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
    function findLevelReceiver(address userAddress, address _from, uint8 matrix, uint8 level, uint256 networklevel) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].activeX3Levels[level] == false) {
                    emit MissedLevelIncome(receiver,users[receiver].id, _from,users[_from].id, matrix, level, networklevel);
                    isExtraDividends = true;
                    receiver = users[receiver].referrer;

                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].activeX6Levels[level] == false) {
                    emit MissedLevelIncome(receiver,users[receiver].id, _from,users[_from].id, matrix, level, networklevel);
                    receiver = users[receiver].referrer;
                    isExtraDividends = true;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
       
    function distributeLevelIncome(address userAddress, uint8 matrix, uint8 level) private {
        address from_address = userAddress;
        bool owner_flag = false;
        bool isExtraLevel;
        address receiver;
        uint i;
        for (i = 1; i <= 15 ; i++) {
            isExtraLevel = false;

            if(owner_flag == false)
            {
                userAddress = users[userAddress].referrer;

                if(userAddress == owner)
                {
                    owner_flag = true;
                }
            }
            else
            {
                userAddress = owner;
            }
            receiver = userAddress;
            if(userAddress != owner)
            {
                (receiver, isExtraLevel)  = findLevelReceiver(receiver, from_address, matrix, level, i);
                if(receiver == owner)
                {
                    owner_flag = true;
                }
                userAddress = receiver;
            }
            
            uint income = (slotPrice[level] * levelIncome / LEVEL_DIVISOR);
            emit SentLevelincome(from_address,users[from_address].id, receiver,users[receiver].id, matrix, level, i ,isExtraLevel);
            address(uint160(receiver)).transfer(income);
        }
    }
    function sendTRONDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTRONReceiver(userAddress, _from, matrix, level);

        emit SentDividends(_from,users[_from].id, receiver,users[receiver].id, matrix, level, isExtraDividends);

        if(matrix == 1)
        {
            if(!address(uint160(receiver)).send(slotPrice[level])){
                return address(uint160(receiver)).transfer(slotPrice[level]);
            }
        }
        else
        {
            if(!address(uint160(receiver)).send(slotPrice[level] - (slotPrice[level] * LEVEL_PER / LEVEL_DIVISOR)  )){
                return address(uint160(receiver)).transfer(slotPrice[level] - (slotPrice[level] * LEVEL_PER / LEVEL_DIVISOR));
            }
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function changeSlotPrice(uint _slot, uint _price) external onlyDeployer  {
        if(msg.sender == deployer)
        {
            require(_slot > 0, "Slot can not be 0");
            require(_price > 0, "Price can not be 0");
            require(slotPrice[_slot] != _price, "Already have this price");
            require(_slot <= LAST_SLOT, "Can not add more slots");
            
            slotPrice[_slot] = _price;
        }
    }
}