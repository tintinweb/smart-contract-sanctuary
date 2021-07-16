//SourceUnit: Protron.sol

pragma solidity 0.5.10;

contract ProTron {

    struct User {
        uint id;
        address referrer;

        uint8 T3LastLevel;
        uint8 T3XLastLevel;
        uint8 T4LastLevel;
        
        uint partnersCount;

        mapping(uint8 => bool) activeT3Levels;
        mapping(uint8 => bool) activeT4Levels;
        mapping(uint8 => bool) activeT3XLevels;

        mapping(uint8 => uint[]) queuePositions;

        mapping(uint8 => T3) t3Matrix;
        mapping(uint8 => T3X) t3XMatrix;
        mapping(uint8 => T4) t4Matrix;
    }

    struct T3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }

    struct T3X {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
    }

    struct T4 {
        address currentReferrer;

        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    struct T3XDynamicQueueData {
        uint queueNo;
        address userAddress;
    }

    uint8 public constant LAST_LEVEL = 15;

    mapping(address => User) public users;

    mapping(uint8 => uint) public currentPointingQueueNo;
    mapping(uint8 => uint) public lastAvailableQueueNo;

    // Level, LastqueueSlot
    mapping(uint8 => mapping(uint => T3XDynamicQueueData)) public T3XDynamicQueueOrder;

    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address payable public uplineUser;

    mapping(uint8 => uint) public price;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(uint indexed sender, uint indexed userId, uint indexed currentReferrerId, uint callerId, uint8 matrix, uint8 level, uint reInvestCount, bool isDynamicSpill);
    event Upgrade(uint indexed sender, uint indexed userId, uint indexed referrerId, uint8 matrix, uint8 level);
    event NewUserPlace(uint indexed sender, uint indexed userId, uint indexed referrerId, uint8 matrix, uint8 level, uint8 place, uint reInvestCount, uint userReInvestCount, bool isDynamicSpill);
    event MissedEthReceive(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint8 level, uint amount);
    event PayoutToUpline(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint8 level, uint amount, bool hasBlockedLevelMissings);

    event UplineBonus(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint8 level, uint amount);
    event SendToInviterT4(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint8 level, uint amount);
    
    event FundsPassedUp(uint indexed sender, uint indexed receiverWhoMissedId, uint indexed fromId, uint8 matrix, uint8 level);
 

    constructor(address payable uplineAddress) public {
        price[1] = 100 * 1e6;
        uint8 i;
        for (i = 2; i <= LAST_LEVEL - 2; i++) {
            price[i] = price[i-1] * 2;
        }
        price[14] = 609600 * 1e6;
        price[15] = 809600 * 1e6;

        uplineUser = uplineAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            T3LastLevel: 15,
            T3XLastLevel: 15,
            T4LastLevel: 15
        });

        users[uplineAddress] = user;
        idToAddress[1] = uplineAddress;

        for (uint8 j = 1; j <= LAST_LEVEL; j++) {
            users[uplineAddress].activeT3Levels[j] = true;
            users[uplineAddress].activeT4Levels[j] = true;
            users[uplineAddress].activeT3XLevels[j] = true;

            currentPointingQueueNo[j] = 1;
            lastAvailableQueueNo[j] = 2;

            T3XDynamicQueueData memory dynamicQueue = T3XDynamicQueueData({
                queueNo: 1,
                userAddress: uplineAddress
            });

            T3XDynamicQueueOrder[j][1] = dynamicQueue;

            users[uplineAddress].queuePositions[j].push(1);
        }

        userIds[1] = uplineAddress;
    }

    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, uplineUser);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function upgradeLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(msg.value == price[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeT3Levels[level], "level already activated");

            if (users[msg.sender].t3Matrix[level-1].blocked) {
                users[msg.sender].t3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeT3Referrer(msg.sender, level, true);
            users[msg.sender].t3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeT3Levels[level] = true;
            
            uint amount = price[level];
            uint uplineBonus = amount * 10 / 100;
            amount = price[level] - uplineBonus;
            sendExtras(msg.sender, 1, level, uplineBonus, 0);

            updateT3Referrer(msg.sender, freeX3Referrer, level, amount);
            
            emit Upgrade(getIdByAddress(msg.sender), getIdByAddress(msg.sender), getIdByAddress(freeX3Referrer), 1, level);

        } else if (matrix == 2) {
            require(!users[msg.sender].activeT4Levels[level], "level already activated");

            if (users[msg.sender].t4Matrix[level-1].blocked) {
                users[msg.sender].t4Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeT4Referrer(msg.sender, level, true);
            users[msg.sender].activeT4Levels[level] = true;
            
            uint amount = price[level];
            uint uplineBonus = price[level] * 10 / 100;
            uint inviterProfit = price[level] * 10 / 100;
            amount = price[level] - uplineBonus - inviterProfit;
            sendExtras(msg.sender, 2, level, uplineBonus, inviterProfit);

            updateT4Referrer(msg.sender, freeX6Referrer, level, amount);

            emit Upgrade(getIdByAddress(msg.sender), getIdByAddress(msg.sender), getIdByAddress(freeX6Referrer), 2, level);
        } else {
            require(!users[msg.sender].activeT3XLevels[level], "level already activated");
    
            address freeX3XReferrer = findFreeT3XReferrer(msg.sender, level, true);
            users[msg.sender].t3XMatrix[level].currentReferrer = freeX3XReferrer;
            users[msg.sender].activeT3XLevels[level] = true;
            
            uint amount = price[level];
            uint uplineBonus = price[level] * 10 / 100;
            amount = price[level] - uplineBonus;
            sendExtras(msg.sender, 3, level, uplineBonus, 0);

            updateT3XReferrer(msg.sender, freeX3XReferrer, level, false, amount);
            
            emit Upgrade(getIdByAddress(msg.sender), getIdByAddress(msg.sender), getIdByAddress(freeX3XReferrer), 3, level);
        }
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == (price[1]*3), "Invalid registration amount");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        User memory user = User({
            id: lastUserId,
            T3LastLevel: 1,
            T3XLastLevel: 1,
            T4LastLevel: 1,
            referrer: referrerAddress,
            partnersCount: 0
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeT3Levels[1] = true;
        users[userAddress].activeT4Levels[1] = true;
        users[userAddress].activeT3XLevels[1] = true;

        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;

        uint amount = price[1] * 3;
        uint uplineBonus = amount * 10 / 100;
        amount = price[1] - (uplineBonus / 3);
        sendExtras(msg.sender, 0, 1, uplineBonus, 0);

        // Get Referral address of registering user
        address freeX3Referrer = findFreeT3Referrer(userAddress, 1, false);
        users[userAddress].t3Matrix[1].currentReferrer = freeX3Referrer;
        updateT3Referrer(userAddress, freeX3Referrer, 1, amount);

        // T3 X Register
        address freeX3XReferrer = findFreeT3XReferrer(userAddress, 1, false);
        users[userAddress].t3XMatrix[1].currentReferrer = freeX3XReferrer;
        updateT3XReferrer(userAddress, freeX3XReferrer, 1, false, amount);
        
        updateT4Referrer(userAddress, findFreeT4Referrer(userAddress, 1, false), 1, amount);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateT3Referrer(address userAddress, address referrerAddress, uint8 level, uint amount) private {
        users[referrerAddress].t3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].t3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 1, level, uint8(users[referrerAddress].t3Matrix[level].referrals.length), users[referrerAddress].t3Matrix[level].reinvestCount, 0, false);
            return sendETHDividends(referrerAddress, userAddress, 1, level, amount);
        }
        
        emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 1, level, 3, users[referrerAddress].t3Matrix[level].reinvestCount, 0, false);

        //close matrix
        users[referrerAddress].t3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeT3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].t3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != uplineUser) {
            //check referrer active level
            address freeReferrerAddress = findFreeT3Referrer(referrerAddress, level, false);
            if (users[referrerAddress].t3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].t3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].t3Matrix[level].reinvestCount++;
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(referrerAddress), getIdByAddress(freeReferrerAddress), getIdByAddress(userAddress), 1, level, users[referrerAddress].t3Matrix[level].reinvestCount, false);
            updateT3Referrer(referrerAddress, freeReferrerAddress, level, amount);
        } else {
            sendETHDividends(uplineUser, userAddress, 1, level, amount);
            users[uplineUser].t3Matrix[level].reinvestCount++;
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(uplineUser), 0, getIdByAddress(userAddress), 1, level, users[uplineUser].t3Matrix[level].reinvestCount, false);
        }
    }

    function updateT3XReferrer(address userAddress, address referrerAddress, uint8 level, bool isDynamicSpill, uint amount) private {
        users[referrerAddress].t3XMatrix[level].referrals.push(userAddress);

        if(getIdByAddress(userAddress) < getIdByAddress(referrerAddress)) {
            T3XDynamicQueueData memory dynamicQueue = T3XDynamicQueueData({
                queueNo: lastAvailableQueueNo[level],
                userAddress: referrerAddress
            });
            users[referrerAddress].queuePositions[level].push(lastAvailableQueueNo[level]);
            T3XDynamicQueueOrder[level][lastAvailableQueueNo[level]] = dynamicQueue;
        } else {
            T3XDynamicQueueData memory dynamicQueue = T3XDynamicQueueData({
                queueNo: lastAvailableQueueNo[level],
                userAddress: userAddress
            });
            users[userAddress].queuePositions[level].push(lastAvailableQueueNo[level]);
            T3XDynamicQueueOrder[level][lastAvailableQueueNo[level]] = dynamicQueue;
        }
        
        lastAvailableQueueNo[level]++;

        if (users[referrerAddress].t3XMatrix[level].referrals.length < 3) {
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 3, level, uint8(users[referrerAddress].t3XMatrix[level].referrals.length), users[referrerAddress].t3XMatrix[level].reinvestCount, users[userAddress].t3Matrix[level].reinvestCount, isDynamicSpill);
            return sendETHDividends(referrerAddress, userAddress, 3, level, amount);
        }
        
        emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 3, level, 3, users[referrerAddress].t3XMatrix[level].reinvestCount, users[userAddress].t3Matrix[level].reinvestCount, false);

        //close matrix
        users[referrerAddress].t3XMatrix[level].referrals = new address[](0);

        address nextUserAddress = getNextT3XUser(level);

        if (users[referrerAddress].t3XMatrix[level].currentReferrer != nextUserAddress) {
            users[referrerAddress].t3XMatrix[level].currentReferrer = nextUserAddress;
        }
        currentPointingQueueNo[level]++;

        users[referrerAddress].t3XMatrix[level].reinvestCount++;
        emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(referrerAddress), getIdByAddress(nextUserAddress), getIdByAddress(userAddress), 3, level, users[referrerAddress].t3XMatrix[level].reinvestCount, isDynamicSpill);
        updateT3XReferrer(referrerAddress, nextUserAddress, level, true, amount);
    }

    function updateT4Referrer(address userAddress, address referrerAddress, uint8 level, uint amount) private {
        require(users[referrerAddress].activeT4Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].t4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].t4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 2, level, uint8(users[referrerAddress].t4Matrix[level].firstLevelReferrals.length), users[referrerAddress].t4Matrix[level].reinvestCount, 0, false);

            users[userAddress].t4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == uplineUser) {
                return sendETHDividends(referrerAddress, userAddress, 2, level, amount);
            }

            address ref = users[referrerAddress].t4Matrix[level].currentReferrer;
            users[ref].t4Matrix[level].secondLevelReferrals.push(userAddress);

            uint len = users[ref].t4Matrix[level].firstLevelReferrals.length;

            if ((len == 2) &&
                (users[ref].t4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].t4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].t4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 5, users[ref].t4Matrix[level].reinvestCount, 0, false);
                } else {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 6, users[ref].t4Matrix[level].reinvestCount, 0, false);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].t4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].t4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 3, users[ref].t4Matrix[level].reinvestCount, 0, false);
                } else {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 4, users[ref].t4Matrix[level].reinvestCount, 0, false);
                }
            } else if (len == 2 && users[ref].t4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].t4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 5, users[ref].t4Matrix[level].reinvestCount, 0, false);
                } else {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 6, users[ref].t4Matrix[level].reinvestCount, 0, false);
                }
            }

            return updateT4ReferrerOnSecondLevel(userAddress, ref, level, amount);
        }

        users[referrerAddress].t4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].t4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].t4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].t4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].t4Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateT4ReferrerOnSecondLevel(userAddress, referrerAddress, level, amount);
            } else if (users[referrerAddress].t4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].t4Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateT4ReferrerOnSecondLevel(userAddress, referrerAddress, level, amount);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateT4ReferrerOnSecondLevel(userAddress, referrerAddress, level, amount);
            }
        }

        if (users[referrerAddress].t4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateT4ReferrerOnSecondLevel(userAddress, referrerAddress, level, amount);
        } else if (users[referrerAddress].t4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateT4ReferrerOnSecondLevel(userAddress, referrerAddress, level, amount);
        }

        if (users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[0]].t4Matrix[level].firstLevelReferrals.length <=
            users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]].t4Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }

        updateT4ReferrerOnSecondLevel(userAddress, referrerAddress, level, amount);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[0]].t4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(users[referrerAddress].t4Matrix[level].firstLevelReferrals[0]), 2, level, uint8(users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[0]].t4Matrix[level].firstLevelReferrals.length), users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[0]].t4Matrix[level].reinvestCount, 0, false);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 2, level, 2 + uint8(users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[0]].t4Matrix[level].firstLevelReferrals.length), users[referrerAddress].t4Matrix[level].reinvestCount, 0, false);
            //set current level
            users[userAddress].t4Matrix[level].currentReferrer = users[referrerAddress].t4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]].t4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]), 2, level, uint8(users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]].t4Matrix[level].firstLevelReferrals.length), users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]].t4Matrix[level].reinvestCount, 0, false);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 2, level, 4 + uint8(users[users[referrerAddress].t4Matrix[level].firstLevelReferrals[1]].t4Matrix[level].firstLevelReferrals.length), users[referrerAddress].t4Matrix[level].reinvestCount, 0, false);
            //set current level
            users[userAddress].t4Matrix[level].currentReferrer = users[referrerAddress].t4Matrix[level].firstLevelReferrals[1];
        }
    }

    function updateT4ReferrerOnSecondLevel(address userAddress, address referrerAddress, uint8 level, uint amount) private {
        if (users[referrerAddress].t4Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level, amount);
        }
        
        address[] memory x6 = users[users[referrerAddress].t4Matrix[level].currentReferrer].t4Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].t4Matrix[level].currentReferrer].t4Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].t4Matrix[level].currentReferrer].t4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].t4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].t4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].t4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeT4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].t4Matrix[level].blocked = true;
        }

        users[referrerAddress].t4Matrix[level].reinvestCount++;
        
        if (referrerAddress != uplineUser) {
            address freeReferrerAddress = findFreeT4Referrer(referrerAddress, level, false);
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(referrerAddress), getIdByAddress(freeReferrerAddress), getIdByAddress(userAddress), 2, level, users[referrerAddress].t4Matrix[level].reinvestCount, false);
            updateT4Referrer(referrerAddress, freeReferrerAddress, level, amount);
        } else {
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(uplineUser), 0, getIdByAddress(userAddress), 2, level, users[referrerAddress].t4Matrix[level].reinvestCount, false);
            sendETHDividends(uplineUser, userAddress, 2, level, amount);
        }
    }
    
    function findFreeT3Referrer(address userAddress, uint8 level, bool emitEvent) internal returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeT3Levels[level]) {
                return users[userAddress].referrer;
            }

            if (emitEvent == true) {
                emit FundsPassedUp(getIdByAddress(msg.sender), users[users[userAddress].referrer].id, users[userAddress].id, 1, level);
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeT3XReferrer(address userAddress, uint8 level, bool emitEvent) internal returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeT3XLevels[level]) {
                return users[userAddress].referrer;
            }

            if (emitEvent == true) {
                emit FundsPassedUp(getIdByAddress(msg.sender), users[users[userAddress].referrer].id, users[userAddress].id, 3, level);
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeT4Referrer(address userAddress, uint8 level, bool emitEvent) internal returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeT4Levels[level]) {
                return users[userAddress].referrer;
            }

            if (emitEvent == true) {
                emit FundsPassedUp(getIdByAddress(msg.sender), users[users[userAddress].referrer].id, users[userAddress].id, 2, level);
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function getNextT3XUser(uint8 level) private view returns(address) {
        return T3XDynamicQueueOrder[level][currentPointingQueueNo[level]].userAddress;
    }

    function findUplineLeader(address userAddress) private view returns(address) {
        address uplineTop = address(uplineUser);
        while (true) {
            
            if (users[users[userAddress].referrer].partnersCount >= 25 || users[userAddress].referrer == uplineTop) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }

    function usersActiveT3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeT3Levels[level];
    }

    function usersActiveT4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeT4Levels[level];
    }

    function usersT3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].t3Matrix[level].currentReferrer,
                users[userAddress].t3Matrix[level].referrals,
                users[userAddress].t3Matrix[level].blocked,
                users[userAddress].t3Matrix[level].reinvestCount);
    }

    function usersT3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint) {
        return (users[userAddress].t3XMatrix[level].currentReferrer,
                users[userAddress].t3XMatrix[level].referrals,
                users[userAddress].t3XMatrix[level].reinvestCount);
    }

    function usersT4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint) {
        return (users[userAddress].t4Matrix[level].currentReferrer,
                users[userAddress].t4Matrix[level].firstLevelReferrals,
                users[userAddress].t4Matrix[level].secondLevelReferrals,
                users[userAddress].t4Matrix[level].blocked,
                users[userAddress].t4Matrix[level].closedPart,
                users[userAddress].t4Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level, uint amount) private returns(address, bool) {
        address receiver = userAddress;
        bool hasBlockedLevelMissings = false;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].t3Matrix[level].blocked) {
                    emit MissedEthReceive(getIdByAddress(msg.sender), getIdByAddress(receiver), getIdByAddress(_from), 1, level, amount);
                    hasBlockedLevelMissings = true;
                    receiver = users[receiver].t3Matrix[level].currentReferrer;
                } else {
                    return (receiver, hasBlockedLevelMissings);
                }
            }
        } else if (matrix == 2) {
            while (true) {
                if (users[receiver].t4Matrix[level].blocked) {
                    emit MissedEthReceive(getIdByAddress(msg.sender), getIdByAddress(receiver), getIdByAddress(_from), 2, level, amount);
                    hasBlockedLevelMissings = true;
                    receiver = users[receiver].t4Matrix[level].currentReferrer;
                } else {
                    return (receiver, hasBlockedLevelMissings);
                }
            }
        } else {
            return (receiver, hasBlockedLevelMissings);
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level, uint amount) private {
        (address receiver, bool hasBlockedLevelMissings) = findEthReceiver(userAddress, _from, matrix, level, amount);
        
        emit PayoutToUpline(users[msg.sender].id, users[receiver].id, users[_from].id, matrix, level, amount, hasBlockedLevelMissings);

        if (!address(uint160(receiver)).send(amount)) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
    }

    function sendExtras(address _from, uint8 matrix, uint8 level, uint uplineAmount, uint inviterProfit) private {
        sendUplineBonus(_from, matrix, level, uplineAmount);
    
        if(matrix == 2 && level > 1) {
            sendToInviter(users[_from].referrer, inviterProfit);
            emit SendToInviterT4(users[msg.sender].id, users[users[_from].referrer].id, users[_from].id, matrix, level, inviterProfit);
        }
    }

    function sendUplineBonus(address _from, uint8 matrix, uint8 level, uint amount) private {
        address uplineLeader = findUplineLeader(_from);
        address(uint160(uplineLeader)).transfer(amount);
        emit UplineBonus(users[msg.sender].id, users[uplineLeader].id, users[_from].id, matrix, level, amount);
    }

    function sendToInviter(address inviter, uint inviterAmount) private {
        address(uint160(inviter)).transfer(inviterAmount);
    }

    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function getAddressById(uint id) public view returns(address addr) {
        return userIds[id];
    }

    function getIdByAddress(address addr) public view returns(uint id) {
        return users[addr].id;
    }

    function getPositions(address userAddress, uint8 level) public view returns(uint[] memory) {
        return users[userAddress].queuePositions[level];
    }

    function getCurrentQueueUserId(uint8 level) public view returns(uint id) {
        address userAddress = T3XDynamicQueueOrder[level][currentPointingQueueNo[level]].userAddress;
        return users[userAddress].id;
    }
}