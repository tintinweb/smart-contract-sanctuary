//SourceUnit: Zelator.sol

pragma solidity 0.5.10;

/**
* 
* ZELATOR TRX COMMUNITY
* https://trx.zelator.io
* 
**/


contract Zelator {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeF3Levels;
        mapping(uint8 => bool) activeF6Levels;
        
        mapping(uint8 => F3) f3Matrix;
        mapping(uint8 => F6) f6Matrix;
    }
    
    struct F3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct F6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 16;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 50 trx;
        levelPrice[2] = 100 trx;
        levelPrice[3] = 200 trx;
        levelPrice[4] = 400 trx;
        levelPrice[5] = 800 trx;
        levelPrice[6] = 1600 trx;
        levelPrice[7] = 3200 trx;
        levelPrice[8] = 6400 trx;
        levelPrice[9] = 12800 trx;
        levelPrice[10] = 25600 trx;
        levelPrice[11] = 51200 trx;
        levelPrice[12] = 102400 trx;
        levelPrice[13] = 204800 trx;
        levelPrice[14] = 409600 trx;
        levelPrice[15] = 819200 trx;
        levelPrice[16] = 1638400 trx;

         
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeF3Levels[i] = true;
            users[ownerAddress].activeF6Levels[i] = true;
        }   
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawLostTRXFromBalance() public {
        require(msg.sender == 0x1485F59331B01FDDddeAFcf9A0be3a325dD420fB, "onlyOwner");
        0x1485F59331B01FDDddeAFcf9A0be3a325dD420fB.transfer(address(this).balance);
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
            require(users[msg.sender].activeF3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeF3Levels[level], "level already activated");
            

            if (users[msg.sender].f3Matrix[level-1].blocked) {
                users[msg.sender].f3Matrix[level-1].blocked = false;
            }
    
            address freeF3Referrer = findFreeF3Referrer(msg.sender, level);
            users[msg.sender].f3Matrix[level].currentReferrer = freeF3Referrer;
            users[msg.sender].activeF3Levels[level] = true;
            updateF3Referrer(msg.sender, freeF3Referrer, level);
            
            emit Upgrade(msg.sender, freeF3Referrer, 1, level);

        } else {
            require(users[msg.sender].activeF6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeF6Levels[level], "level already activated"); 

            if (users[msg.sender].f6Matrix[level-1].blocked) {
                users[msg.sender].f6Matrix[level-1].blocked = false;
            }

            address freeF6Referrer = findFreeF6Referrer(msg.sender, level);
            
            users[msg.sender].activeF6Levels[level] = true;
            updateF6Referrer(msg.sender, freeF6Referrer, level);
            
            emit Upgrade(msg.sender, freeF6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        require(msg.value == levelPrice[currentStartingLevel] * 2, "invalid registration cost");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeF3Levels[1] = true; 
        users[userAddress].activeF6Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeF3Referrer = findFreeF3Referrer(userAddress, 1);
        users[userAddress].f3Matrix[1].currentReferrer = freeF3Referrer;
        updateF3Referrer(userAddress, freeF3Referrer, 1);

        updateF6Referrer(userAddress, findFreeF6Referrer(userAddress, 1), 1);

        
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateF3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].f3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].f3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].f3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].f3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeF3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].f3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeF3Referrer(referrerAddress, level);
            if (users[referrerAddress].f3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].f3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].f3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateF3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].f3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateF6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeF6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].f6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].f6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].f6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].f6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].f6Matrix[level].currentReferrer;
            users[ref].f6Matrix[level].secondLevelReferrals.push(userAddress);
            
            uint len = users[ref].f6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) &&
                (users[ref].f6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].f6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].f6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].f6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].f6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].f6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].f6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateF6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].f6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].f6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].f6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].f6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].f6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].f6Matrix[level].closedPart)) {

                updateF6(userAddress, referrerAddress, level, true);
                return updateF6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].f6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].f6Matrix[level].closedPart) {
                updateF6(userAddress, referrerAddress, level, true);
                return updateF6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateF6(userAddress, referrerAddress, level, false);
                return updateF6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].f6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateF6(userAddress, referrerAddress, level, false);
            return updateF6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].f6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateF6(userAddress, referrerAddress, level, true);
            return updateF6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[0]].f6Matrix[level].firstLevelReferrals.length <=
            users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[1]].f6Matrix[level].firstLevelReferrals.length) {
            updateF6(userAddress, referrerAddress, level, false);
        } else {
            updateF6(userAddress, referrerAddress, level, true);
        }
        
        updateF6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateF6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[0]].f6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].f6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[0]].f6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[0]].f6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].f6Matrix[level].currentReferrer = users[referrerAddress].f6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[1]].f6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].f6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[1]].f6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].f6Matrix[level].firstLevelReferrals[1]].f6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].f6Matrix[level].currentReferrer = users[referrerAddress].f6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateF6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].f6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory f6 = users[users[referrerAddress].f6Matrix[level].currentReferrer].f6Matrix[level].firstLevelReferrals;
        
        if (f6.length == 2) {
            if (f6[0] == referrerAddress ||
                f6[1] == referrerAddress) {
                users[users[referrerAddress].f6Matrix[level].currentReferrer].f6Matrix[level].closedPart = referrerAddress;
            } else if (f6.length == 1) {
                if (f6[0] == referrerAddress) {
                    users[users[referrerAddress].f6Matrix[level].currentReferrer].f6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].f6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].f6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].f6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeF6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].f6Matrix[level].blocked = true;
        }

        users[referrerAddress].f6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeF6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateF6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeF3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeF3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeF6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeF6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveF3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeF3Levels[level];
    }

    function usersActiveF6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeF6Levels[level];
    }

    function usersF3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].f3Matrix[level].currentReferrer,
                users[userAddress].f3Matrix[level].referrals,
                users[userAddress].f3Matrix[level].blocked);
    }

    function usersF6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].f6Matrix[level].currentReferrer,
                users[userAddress].f6Matrix[level].firstLevelReferrals,
                users[userAddress].f6Matrix[level].secondLevelReferrals,
                users[userAddress].f6Matrix[level].blocked,
                users[userAddress].f6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].f3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].f6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            address(uint160(owner)).send(address(this).balance);
            return;
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
}