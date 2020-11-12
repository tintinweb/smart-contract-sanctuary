/** 
*SPDX-License-Identifier: BSD-3-Clause
**/

/**
*
* 
*  $$$$$$\                                      $$\                    $$\   $$\
* $$  __$$\                                     $$ |                   $$ |  $$ |
* $$ /  \__| $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$ | $$$$$$\   $$$$$$\ \$$\ $$  |
* \$$$$$$\  $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$ |$$  __$$\ $$  __$$\ \$$$$  /
*  \____$$\ $$ /  $$ |$$$$$$$$ |$$$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|$$  $$<
* $$\   $$ |$$ |  $$ |$$   ____|$$   ____|$$ |  $$ |$$   ____|$$ |     $$  /\$$\
* \$$$$$$  |$$$$$$$  |\$$$$$$$\ \$$$$$$$\ \$$$$$$$ |\$$$$$$$\ $$ |     $$ /  $$ |
*  \______/ $$  ____/  \_______| \_______| \_______| \_______|\__|     \__|  \__|
*           $$ |
*           $$ |
*           \__|
*
**/

pragma solidity >=0.5.0 <0.6.10;

contract SpeederXContract {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeF1Levels;
        mapping(uint8 => bool) activeF2Levels;
        
        mapping(uint8 => F1) f1Matrix;
        mapping(uint8 => F2) f2Matrix;
    }
    
    struct F1 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct F2 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 13;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public reinvestGlobalCount;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    uint internal reentryStatus;
    uint internal constant entryEnabled = 1;
    uint internal constant entryDisabled = 2;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event SentETH(address indexed receiver, uint8 matrix, uint8 level);
    
    modifier blockReEntry() {
        require(reentryStatus != entryDisabled, "Security Block");
        reentryStatus = entryDisabled;
    
        _;
    
        reentryStatus = entryEnabled;
    }
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 0.02 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        reentryStatus = entryEnabled;
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeF1Levels[i] = true;
            users[ownerAddress].activeF2Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    fallback() external payable blockReEntry(){
        return registration(msg.sender, bytesToAddress(msg.data));
    }
    receive() external payable blockReEntry() {
        return registration(msg.sender, owner);
    }

    function registrationExt(address referrerAddress) external payable blockReEntry() {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 startLevel, uint8 endLevel) external payable blockReEntry() {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(startLevel >= 0 && startLevel < LAST_LEVEL, "invalid startLevel");
        require(endLevel > 1 && endLevel <= LAST_LEVEL, "invalid endLevel");

        if(startLevel == 0){
            require(msg.value == levelPrice[endLevel], "invalid price");
            buyNewEachLevel(matrix, endLevel);
        } else {
            uint amount;
            for (uint8 i = startLevel; i <= endLevel; i++) {
                amount += levelPrice[i] ;
            }
            require(msg.value == amount, "invalid many level price");

            for (uint8 i = startLevel; i <= endLevel; i++) {
                buyNewEachLevel(matrix, i);
            }
        }
    } 

    function buyNewEachLevel(uint8 matrix, uint8 level) private {
        if (matrix == 1) {
            require(!users[msg.sender].activeF1Levels[level], "level already activated");

            if (users[msg.sender].f1Matrix[level-1].blocked) {
                users[msg.sender].f1Matrix[level-1].blocked = false;
            }
    
            address freeF1Referrer = findFreeF1Referrer(msg.sender, level);
            users[msg.sender].f1Matrix[level].currentReferrer = freeF1Referrer;
            users[msg.sender].activeF1Levels[level] = true;
            updateF1Referrer(msg.sender, freeF1Referrer, level);
            
            emit Upgrade(msg.sender, freeF1Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeF2Levels[level], "level already activated"); 

            if (users[msg.sender].f2Matrix[level-1].blocked) {
                users[msg.sender].f2Matrix[level-1].blocked = false;
            }

            address freeF2Referrer = findFreeF2Referrer(msg.sender, level);
            
            users[msg.sender].activeF2Levels[level] = true;
            updateF2Referrer(msg.sender, freeF2Referrer, level);
            
            emit Upgrade(msg.sender, freeF2Referrer, 2, level);
        }
    }  
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.04 ether, "registration cost 0.04");
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
        
        users[userAddress].activeF1Levels[1] = true; 
        users[userAddress].activeF2Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeF1Referrer = findFreeF1Referrer(userAddress, 1);
        users[userAddress].f1Matrix[1].currentReferrer = freeF1Referrer;
        updateF1Referrer(userAddress, freeF1Referrer, 1);

        updateF2Referrer(userAddress, findFreeF2Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateF1Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].f1Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].f1Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].f1Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].f1Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeF1Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].f1Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeF1Referrer(referrerAddress, level);
            if (users[referrerAddress].f1Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].f1Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].f1Matrix[level].reinvestCount++;
            reinvestGlobalCount[referrerAddress] = users[referrerAddress].f1Matrix[level].reinvestCount;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateF1Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].f1Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateF2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeF2Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].f2Matrix[level].firstLevelReferrals.length < 2) {
            
            users[referrerAddress].f2Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].f2Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].f2Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].f2Matrix[level].currentReferrer;            
            users[ref].f2Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].f2Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].f2Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].f2Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].f2Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].f2Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].f2Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].f2Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].f2Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateF2ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].f2Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].f2Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].f2Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].f2Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].f2Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].f2Matrix[level].closedPart)) {

                updateF2(userAddress, referrerAddress, level, true);
                return updateF2ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].f2Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].f2Matrix[level].closedPart) {
                updateF2(userAddress, referrerAddress, level, true);
                return updateF2ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateF2(userAddress, referrerAddress, level, false);
                return updateF2ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].f2Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateF2(userAddress, referrerAddress, level, false);
            return updateF2ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].f2Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateF2(userAddress, referrerAddress, level, true);
            return updateF2ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[0]].f2Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[1]].f2Matrix[level].firstLevelReferrals.length) {
            updateF2(userAddress, referrerAddress, level, false);
        } else {
            updateF2(userAddress, referrerAddress, level, true);
        }
        
        updateF2ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateF2(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[0]].f2Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].f2Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[0]].f2Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[0]].f2Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].f2Matrix[level].currentReferrer = users[referrerAddress].f2Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[1]].f2Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].f2Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[1]].f2Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].f2Matrix[level].firstLevelReferrals[1]].f2Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].f2Matrix[level].currentReferrer = users[referrerAddress].f2Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateF2ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].f2Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory f2 = users[users[referrerAddress].f2Matrix[level].currentReferrer].f2Matrix[level].firstLevelReferrals;
        
        if (f2.length == 2) {
            if (f2[0] == referrerAddress ||
                f2[1] == referrerAddress) {
                users[users[referrerAddress].f2Matrix[level].currentReferrer].f2Matrix[level].closedPart = referrerAddress;
            } else if (f2.length == 1) {
                if (f2[0] == referrerAddress) {
                    users[users[referrerAddress].f2Matrix[level].currentReferrer].f2Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].f2Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].f2Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].f2Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeF2Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].f2Matrix[level].blocked = true;
        }

        users[referrerAddress].f2Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeF2Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateF2Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeF1Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeF1Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeF2Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeF2Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveF1Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeF1Levels[level];
    }

    function usersActiveF2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeF2Levels[level];
    }

    function usersF1Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].f1Matrix[level].currentReferrer,
                users[userAddress].f1Matrix[level].referrals,
                users[userAddress].f1Matrix[level].blocked);
    }

    function usersF2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].f2Matrix[level].currentReferrer,
                users[userAddress].f2Matrix[level].firstLevelReferrals,
                users[userAddress].f2Matrix[level].secondLevelReferrals,
                users[userAddress].f2Matrix[level].blocked,
                users[userAddress].f2Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].f1Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f1Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].f2Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f2Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        
        (bool success, ) = address(uint160(receiver)).call{ value: levelPrice[level], gas: 40000 }("");

        if (success == false) { 
          (success, ) = address(uint160(receiver)).call{ value: levelPrice[level], gas: 40000 }("");
          require(success, 'Transfer Failed');
        }
        
        emit SentETH(receiver, matrix, level);
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}