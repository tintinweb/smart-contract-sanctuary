//SourceUnit: Asortss.sol

 pragma solidity >=0.4.23 <0.6.0;

contract Assorts {

 struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX9Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X9) x9Matrix;
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
    
    struct X9 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint[] place;
        address[] thirdlevelreferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 16;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8  matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 20 trx;
        levelPrice[2] = 40 trx;
        levelPrice[3] = 80 trx;
        levelPrice[4] = 160 trx;
        levelPrice[5] = 320 trx;
        levelPrice[6] = 640 trx;
        levelPrice[7] = 1280 trx;
        levelPrice[8] = 2560 trx;
        levelPrice[9] = 5120 trx;
        levelPrice[10] = 10240 trx;
        levelPrice[11] = 20480 trx;
        levelPrice[12] = 40960 trx;
        levelPrice[13] = 81920 trx;
        levelPrice[14] = 163840 trx;
        levelPrice[15] = 36780 trx;
        levelPrice[16] = 655360 trx;
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeX9Levels[i] = true;
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
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix==3, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else if (matrix == 2){
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
        else{
             require(!users[msg.sender].activeX9Levels[level], "level already activated"); 

            if (users[msg.sender].x9Matrix[level-1].blocked) {
                users[msg.sender].x9Matrix[level-1].blocked = false;
            }

            address freeX9Referrer = findFreeX9Referrer(msg.sender, level);
            
            users[msg.sender].activeX9Levels[level] = true;
            updateX9Referrer(msg.sender, freeX9Referrer, level);
            
            emit Upgrade(msg.sender, freeX9Referrer, 3, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 50 trx, "registration cost 50");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
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
        users[userAddress].activeX9Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
        updateX9Referrer(userAddress, findFreeX9Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
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
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
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

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
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
    
    function usersActiveX9Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX9Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function usersX9Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,address[] memory, bool, address) {
        return (users[userAddress].x9Matrix[level].currentReferrer,
                users[userAddress].x9Matrix[level].firstLevelReferrals,
                users[userAddress].x9Matrix[level].secondLevelReferrals,
                users[userAddress].x9Matrix[level].thirdlevelreferrals,
                users[userAddress].x9Matrix[level].blocked,
                users[userAddress].x9Matrix[level].closedPart);
    }
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else if (matrix == 2){
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else{
            while (true) {
                if (users[receiver].x9Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 3, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x9Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    /*  12X */
    function updateX9Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX9Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x9Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].x9Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x9Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 3, level);
            }
            
            address ref = users[referrerAddress].x9Matrix[level].currentReferrer;            
            users[ref].x9Matrix[level].secondLevelReferrals.push(userAddress); 
            
            address ref1 = users[ref].x9Matrix[level].currentReferrer;            
            users[ref1].x9Matrix[level].thirdlevelreferrals.push(userAddress);
            
            uint len = users[ref].x9Matrix[level].firstLevelReferrals.length;
            uint8 toppos=2;
            if(ref1!=address(0x0)){
            if(ref==users[ref1].x9Matrix[level].firstLevelReferrals[0]){
                toppos=1;
            }else
            {
                toppos=2;
            }
            }
            if ((len == 2) && 
                (users[ref].x9Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x9Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x9Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x9Matrix[level].place.push(5);
                    emit NewUserPlace(userAddress, ref, 3, level, 5); 
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                } else {
                    users[ref].x9Matrix[level].place.push(6);
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                }
            }  else
            if ((len == 1 || len == 2) &&
                    users[ref].x9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x9Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x9Matrix[level].place.push(3);
                    emit NewUserPlace(userAddress, ref, 3, level, 3);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+3);
                } else {
                    users[ref].x9Matrix[level].place.push(4);
                    emit NewUserPlace(userAddress, ref, 3, level, 4);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+4);
                }
            } else if (len == 2 && users[ref].x9Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x9Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x9Matrix[level].place.push(5);
                     emit NewUserPlace(userAddress, ref, 3, level, 5);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                } else {
                    users[ref].x9Matrix[level].place.push(6);
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+6);
                }
            }
            
            return updateX9ReferrerSecondLevel(userAddress, ref1, level);
        }
         if (users[referrerAddress].x9Matrix[level].secondLevelReferrals.length < 4) {
        users[referrerAddress].x9Matrix[level].secondLevelReferrals.push(userAddress);
        address secondref = users[referrerAddress].x9Matrix[level].currentReferrer; 
        if(secondref==address(0x0))
        secondref=owner;
        if (users[referrerAddress].x9Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX9(userAddress, referrerAddress, level, false);
            return updateX9ReferrerSecondLevel(userAddress, secondref, level);
        } else if (users[referrerAddress].x9Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX9(userAddress, referrerAddress, level, true);
            return updateX9ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        if (users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length < 
            2) {
            updateX9(userAddress, referrerAddress, level, false);
        } else {
            updateX9(userAddress, referrerAddress, level, true);
        }
        
        updateX9ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        
        else  if (users[referrerAddress].x9Matrix[level].thirdlevelreferrals.length < 8) {
        users[referrerAddress].x9Matrix[level].thirdlevelreferrals.push(userAddress);

      if (users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length<2) {
            updateX9Fromsecond(userAddress, referrerAddress, level, 0);
            return updateX9ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.length<2) {
            updateX9Fromsecond(userAddress, referrerAddress, level, 1);
            return updateX9ReferrerSecondLevel(userAddress, referrerAddress, level);
        }else if (users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[2]].x9Matrix[level].firstLevelReferrals.length<2) {
            updateX9Fromsecond(userAddress, referrerAddress, level, 2);
            return updateX9ReferrerSecondLevel(userAddress, referrerAddress, level);
        }else if (users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[3]].x9Matrix[level].firstLevelReferrals.length<2) {
            updateX9Fromsecond(userAddress, referrerAddress, level, 3);
            return updateX9ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        //updateX9Fromsecond(userAddress, referrerAddress, level, users[referrerAddress].x9Matrix[level].secondLevelReferrals.length);
          
        
        updateX9ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    function updateX9(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].thirdlevelreferrals.push(userAddress);
            
            emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].firstLevelReferrals[0], 3, level, uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 2 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length));
           
            users[referrerAddress].x9Matrix[level].place.push(2 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length));
           
           if(referrerAddress!=address(0x0) && referrerAddress!=owner){
            if(users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].firstLevelReferrals[0]==referrerAddress)
            emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].currentReferrer, 3, level,6 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length));
            else
            emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].currentReferrer, 3, level, (10 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[0]].x9Matrix[level].firstLevelReferrals.length)));
            //set current level
           }
            users[userAddress].x9Matrix[level].currentReferrer = users[referrerAddress].x9Matrix[level].firstLevelReferrals[0];
           
        } else {
            users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].thirdlevelreferrals.push(userAddress);
            
            emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].firstLevelReferrals[1], 3, level, uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 4 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.length));
            
            users[referrerAddress].x9Matrix[level].place.push(4 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.length));
            
            if(referrerAddress!=address(0x0) && referrerAddress!=owner){
            if(users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].firstLevelReferrals[0]==referrerAddress)
            emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].currentReferrer, 3, level, 8 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.length));
            else
            emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].currentReferrer, 3, level, 12 + uint8(users[users[referrerAddress].x9Matrix[level].firstLevelReferrals[1]].x9Matrix[level].firstLevelReferrals.length));
            }
            //set current level
            users[userAddress].x9Matrix[level].currentReferrer = users[referrerAddress].x9Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX9Fromsecond(address userAddress, address referrerAddress, uint8 level,uint pos) private {
            users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].firstLevelReferrals.push(userAddress);
             users[users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].currentReferrer].x9Matrix[level].secondLevelReferrals.push(userAddress);
            
            
            uint8 len=uint8(users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].firstLevelReferrals.length);
            
            uint temppos=users[referrerAddress].x9Matrix[level].place[pos];
            emit NewUserPlace(userAddress, referrerAddress, 3, level,uint8(((temppos)*2)+len)); //third position
            if(temppos<5){
            emit NewUserPlace(userAddress, users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].currentReferrer, 3, level,uint8((((temppos-3)+1)*2)+len));
                       users[users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].currentReferrer].x9Matrix[level].place.push((((temppos-3)+1)*2)+len);
            }else{
            emit NewUserPlace(userAddress, users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].currentReferrer, 3, level,uint8((((temppos-3)-1)*2)+len));
                       users[users[users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos]].x9Matrix[level].currentReferrer].x9Matrix[level].place.push((((temppos-3)-1)*2)+len);
            }
             emit NewUserPlace(userAddress, users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos], 3, level, len); //first position
           //set current level
            
            users[userAddress].x9Matrix[level].currentReferrer = users[referrerAddress].x9Matrix[level].secondLevelReferrals[pos];
           
       
    }
    
    function updateX9ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==address(0x0)){
            return sendETHDividends(owner, userAddress, 3, level);
        }
        if (users[referrerAddress].x9Matrix[level].thirdlevelreferrals.length < 8) {
            return sendETHDividends(referrerAddress, userAddress, 3, level);
        }
        
        address[] memory x9 = users[users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].currentReferrer].x9Matrix[level].firstLevelReferrals;
        
        if (x9.length == 2) {
            if (x9[0] == referrerAddress ||
                x9[1] == referrerAddress) {
                users[users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].currentReferrer].x9Matrix[level].closedPart = referrerAddress;
            } else if (x9.length == 1) {
                if (x9[0] == referrerAddress) {
                    users[users[users[referrerAddress].x9Matrix[level].currentReferrer].x9Matrix[level].currentReferrer].x9Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x9Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x9Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x9Matrix[level].thirdlevelreferrals = new address[](0);
        users[referrerAddress].x9Matrix[level].closedPart = address(0);
        users[referrerAddress].x9Matrix[level].place=new uint[](0);

        if (!users[referrerAddress].activeX9Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x9Matrix[level].blocked = true;
        }

        users[referrerAddress].x9Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX9Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateX9Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 3, level);
            sendETHDividends(owner, userAddress, 3, level);
        }
    }
    
     function findFreeX9Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX9Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
}