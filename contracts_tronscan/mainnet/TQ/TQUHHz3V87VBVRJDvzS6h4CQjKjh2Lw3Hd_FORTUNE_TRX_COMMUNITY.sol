//SourceUnit: fortunetrontrxcommunity.sol

pragma solidity 0.5.10;

/**
*
* 
*Publish Date:24 Nov 2020
* 
*Coding Level:High
* 
*FORTUNE TRX COMMUNITY
*
* 
**/


contract FORTUNE_TRX_COMMUNITY {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeF1Levels;
        mapping(uint8 => bool) activeF2Levels;
        mapping(uint8 => bool) activeF3Levels;
        
        mapping(uint8 => F1) f1Matrix;
        mapping(uint8 => F2) f2Matrix;
        mapping(uint8 => F3) f3Matrix;
    }
    
    struct F1 {
        address currentReferrer;
        address[] f1referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct F2 {
        address currentReferrer;
        address[] f2referrals;
        bool blocked;
        uint reinvestCount;
    }
    
     struct F3 {
        address currentReferrer;
        address[] f3referrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 10;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedTrxReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraTrxDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        
        levelPrice[1] = 190;
        levelPrice[2] = 254;
        levelPrice[3] = 1017;
        levelPrice[4] = 4068;
        levelPrice[5] = 16273;
        levelPrice[6] = 51325;
        levelPrice[7] = 156588;
        levelPrice[8] = 480877;
        levelPrice[9] = 1001976;
        levelPrice[10] = 2008763;
         
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
            users[ownerAddress].activeF3Levels[i] = true;
        }   
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
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(users[msg.sender].activeF1Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeF1Levels[level], "level already activated");
            

            if (users[msg.sender].f1Matrix[level-1].blocked) {
                users[msg.sender].f1Matrix[level-1].blocked = false;
            }
    
            address freeF1Referrer = findFreeF1Referrer(msg.sender, level);
            users[msg.sender].f1Matrix[level].currentReferrer = freeF1Referrer;
            users[msg.sender].activeF1Levels[level] = true;
            updateF1Referrer(msg.sender, freeF1Referrer, level);
            
            emit Upgrade(msg.sender, freeF1Referrer, 1, level);

        }
        
        else if (matrix == 2) {
            require(users[msg.sender].activeF2Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeF2Levels[level], "level already activated");
            

            if (users[msg.sender].f2Matrix[level-1].blocked) {
                users[msg.sender].f2Matrix[level-1].blocked = false;
            }
    
            address freeF2Referrer = findFreeF2Referrer(msg.sender, level);
            users[msg.sender].f2Matrix[level].currentReferrer = freeF2Referrer;
            users[msg.sender].activeF2Levels[level] = true;
            updateF2Referrer(msg.sender, freeF2Referrer, level);
            
            emit Upgrade(msg.sender, freeF2Referrer, 2, level);

        }
        
        else {
            require(users[msg.sender].activeF3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeF3Levels[level], "level already activated"); 

            if (users[msg.sender].f3Matrix[level-1].blocked) {
                users[msg.sender].f3Matrix[level-1].blocked = false;
            }

            address freeF3Referrer = findFreeF3Referrer(msg.sender, level);
            
            users[msg.sender].activeF3Levels[level] = true;
            updateF3Referrer(msg.sender, freeF3Referrer, level);
            
            emit Upgrade(msg.sender, freeF3Referrer, 3, level);
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
        users[userAddress].activeF3Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeF1Referrer = findFreeF1Referrer(userAddress, 1);
        users[userAddress].f1Matrix[1].currentReferrer = freeF1Referrer;
		
        updateF1Referrer(userAddress, freeF1Referrer, 1);
        
        updateF2Referrer(userAddress, findFreeF2Referrer(userAddress, 1), 1);

        updateF3Referrer(userAddress, findFreeF3Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateF1Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].f1Matrix[level].f1referrals.push(userAddress);

        if (users[referrerAddress].f1Matrix[level].f1referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].f1Matrix[level].f1referrals.length));
            return sendTRXDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].f1Matrix[level].f1referrals = new address[](0);
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
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateF1Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRXDividends(owner, userAddress, 1, level);
            users[owner].f1Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }
    
    function updateF2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].f2Matrix[level].f2referrals.push(userAddress);

        if (users[referrerAddress].f2Matrix[level].f2referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].f2Matrix[level].f2referrals.length));
            return sendTRXDividends(referrerAddress, userAddress, 2, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 3);
        //close matrix
        users[referrerAddress].f2Matrix[level].f2referrals = new address[](0);
        if (!users[referrerAddress].activeF2Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].f2Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeF2Referrer(referrerAddress, level);
            if (users[referrerAddress].f2Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].f2Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].f2Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateF2Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRXDividends(owner, userAddress, 2, level);
            users[owner].f2Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateF3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeF3Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].f3Matrix[level].f3referrals.length < 2) {
            users[referrerAddress].f3Matrix[level].f3referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].f3Matrix[level].f3referrals.length));
            
            //set current level
            users[userAddress].f3Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTRXDividends(referrerAddress, userAddress, 3, level);
            }
            
            address ref = users[referrerAddress].f3Matrix[level].currentReferrer;            
  
            uint len = users[ref].f3Matrix[level].f3referrals.length;
            
            if ((len == 2) && 
                (users[ref].f3Matrix[level].f3referrals[0] == referrerAddress) &&
                (users[ref].f3Matrix[level].f3referrals[1] == referrerAddress)) {
                if (users[referrerAddress].f3Matrix[level].f3referrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].f3Matrix[level].f3referrals[0] == referrerAddress) {
                if (users[referrerAddress].f3Matrix[level].f3referrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 4);
                }
            } else if (len == 2 && users[ref].f3Matrix[level].f3referrals[1] == referrerAddress) {
                if (users[referrerAddress].f3Matrix[level].f3referrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                }
            }

            return;
        }
        
        if (users[referrerAddress].f3Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].f3Matrix[level].f3referrals[0] == 
                users[referrerAddress].f3Matrix[level].f3referrals[1]) &&
                (users[referrerAddress].f3Matrix[level].f3referrals[0] ==
                users[referrerAddress].f3Matrix[level].closedPart)) {
                return;
            } else if (users[referrerAddress].f3Matrix[level].f3referrals[0] == 
                users[referrerAddress].f3Matrix[level].closedPart) {
                return;
            }
        }
        
        if (users[users[referrerAddress].f3Matrix[level].f3referrals[0]].f3Matrix[level].f3referrals.length <= 
            users[users[referrerAddress].f3Matrix[level].f3referrals[1]].f3Matrix[level].f3referrals.length) {
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
    
    function findFreeF3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeF3Levels[level]) {
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

    function usersActiveF3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeF3Levels[level];
    }

    function usersf1Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].f1Matrix[level].currentReferrer,
                users[userAddress].f1Matrix[level].f1referrals,
                users[userAddress].f1Matrix[level].blocked);
    }
    
     function usersf2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].f2Matrix[level].currentReferrer,
                users[userAddress].f2Matrix[level].f2referrals,
                users[userAddress].f2Matrix[level].blocked);
    }

    function usersf3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, address) {
        return (users[userAddress].f3Matrix[level].currentReferrer,
                users[userAddress].f3Matrix[level].f3referrals,
                users[userAddress].f3Matrix[level].blocked,
                users[userAddress].f3Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTrxReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].f1Matrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f1Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
         if (matrix == 2) {
            while (true) {
                if (users[receiver].f2Matrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f2Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        else {
            while (true) {
                if (users[receiver].f3Matrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 3, level);
                    isExtraDividends = true;
                    receiver = users[receiver].f3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendTRXDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTrxReceiver(userAddress, _from, matrix, level);
        address(uint160(owner)).send(address(this).balance);        
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}