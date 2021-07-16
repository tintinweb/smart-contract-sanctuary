//SourceUnit: RichStock.sol

pragma solidity 0.5.10;

contract RichStock {

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

    uint8 public constant LAST_LEVEL = 13;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;

    uint public lastUserId = 2;
    address payable public owner;

    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(uint indexed sender, uint indexed userId, uint indexed currentReferrerId, uint callerId, uint8 matrix, uint8 level, uint reInvestCount);
    event Upgrade(uint indexed sender, uint indexed userId, uint indexed referrerId, uint8 matrix, uint8 level);
    event NewUserPlace(uint indexed sender, uint indexed userId, uint indexed referrerId, uint8 matrix, uint8 level, uint8 place, uint reInvestCount);
    event MissedEthReceive(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint8 level);
    event SentExtraEthDividends(uint indexed sender, uint indexed fromId, uint indexed receiverId, uint8 matrix, uint8 level);
    event Payout(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint8 level);
    event FundsPassedUp(uint indexed sender, uint indexed receiverWhoMissedId, uint indexed fromId, uint8 matrix, uint8 level);
 

    constructor(address payable ownerAddress) public {
        levelPrice[1] = 50 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }

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
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level, true);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(getIdByAddress(msg.sender), getIdByAddress(msg.sender), getIdByAddress(freeX3Referrer), 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated");

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level, true);

            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);

            emit Upgrade(getIdByAddress(msg.sender), getIdByAddress(msg.sender), getIdByAddress(freeX6Referrer), 2, level);
        }
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 100 trx, "registration cost 100 TRX");
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


        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;

        // Get Referral address of registering user
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1, false);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1, false), 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length), users[referrerAddress].x3Matrix[level].reinvestCount);
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 1, level, 3, users[referrerAddress].x3Matrix[level].reinvestCount);

        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level, false);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(referrerAddress), getIdByAddress(freeReferrerAddress), getIdByAddress(userAddress), 1, level, users[referrerAddress].x3Matrix[level].reinvestCount);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(owner), 0, getIdByAddress(userAddress), 1, level, users[referrerAddress].x3Matrix[level].reinvestCount);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length), users[referrerAddress].x6Matrix[level].reinvestCount);

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
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 5, users[ref].x6Matrix[level].reinvestCount);
                } else {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 6, users[ref].x6Matrix[level].reinvestCount);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 3, users[ref].x6Matrix[level].reinvestCount);
                } else {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 4, users[ref].x6Matrix[level].reinvestCount);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 5, users[ref].x6Matrix[level].reinvestCount);
                } else {
                    emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(ref), 2, level, 6, users[ref].x6Matrix[level].reinvestCount);
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
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]), 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].reinvestCount);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), users[referrerAddress].x6Matrix[level].reinvestCount);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]), 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].reinvestCount);
            emit NewUserPlace(getIdByAddress(msg.sender), getIdByAddress(userAddress), getIdByAddress(referrerAddress), 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), users[referrerAddress].x6Matrix[level].reinvestCount);
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
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level, false);

            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(referrerAddress), getIdByAddress(freeReferrerAddress), getIdByAddress(userAddress), 2, level, users[referrerAddress].x6Matrix[level].reinvestCount);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(getIdByAddress(msg.sender), getIdByAddress(owner), 0, getIdByAddress(userAddress), 2, level, users[referrerAddress].x6Matrix[level].reinvestCount);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level, bool emitEvent) internal returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }

            if (emitEvent == true) {
                emit FundsPassedUp(getIdByAddress(msg.sender), users[users[userAddress].referrer].id, users[userAddress].id, 1, level);
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeX6Referrer(address userAddress, uint8 level, bool emitEvent) internal returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }

            if (emitEvent == true) {
                emit FundsPassedUp(getIdByAddress(msg.sender), users[users[userAddress].referrer].id, users[userAddress].id, 2, level);
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

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x6Matrix[level].reinvestCount);
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
                    emit MissedEthReceive(getIdByAddress(msg.sender), getIdByAddress(receiver), getIdByAddress(_from), 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(getIdByAddress(msg.sender), getIdByAddress(receiver), getIdByAddress(_from), 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
    
        emit Payout(getIdByAddress(msg.sender), users[receiver].id, users[_from].id, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(getIdByAddress(msg.sender), users[_from].id, users[receiver].id, matrix, level);
        }
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
}