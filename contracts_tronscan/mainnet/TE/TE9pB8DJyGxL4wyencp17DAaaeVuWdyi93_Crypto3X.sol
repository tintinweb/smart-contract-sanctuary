//SourceUnit: Crypto3X_tron.sol

pragma solidity ^0.5.4;

contract Crypto3X {
    
    struct UserAccount {
        uint id;
        address referrer;
        uint partnersCount;
        uint X3Income;
        uint X4Income;
         
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint256 => uint256) X3LevelIncome;
        mapping(uint256 => uint256) X4LevelIncome;
        
        mapping(uint8 => XXX) x3Matrix;
        mapping(uint8 => XXXX) x6Matrix;
    }
    
    struct XXX {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct XXXX{
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => UserAccount) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    uint public totalIncome;
    uint public userPlaceCount;
    address public owner;
    address public partner;
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address currentReferrer, address caller, uint8 indexed matrix, uint8 indexed level, uint256 reinvestCount);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address user, address indexed referrer, uint8 indexed matrix, uint8 indexed level, uint8 place, uint256 reinvestCount, uint placeCount);
    event UserActiveLevels(address indexed user,uint8 indexed matrix, uint8 indexed level);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event UserIncome(address indexed user,address indexed from,uint256 value,uint8 matrix, uint8 level);
    
    constructor(address ownerAddress, address partnerAddress) public {
        levelPrice[1] = 250 * 1e6;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
           owner = ownerAddress;
           partner = partnerAddress;
      UserAccount memory user ;
          user= UserAccount({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            X3Income: uint(0),
            X4Income: uint(0)
        });   
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            emit UserActiveLevels(ownerAddress,1,i);
            users[ownerAddress].activeX6Levels[i] = true;
            emit UserActiveLevels(ownerAddress,2,i);
        }
        userIds[1] = ownerAddress;
        
        emit Registration(owner, address(0), 1, 0);
    }
  
    
    function regUser(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
            totalIncome += levelPrice[1] * 2;

    }
    
    function purchaseLevel(uint8 matrix, uint8 level) external payable {
        require(msg.value == levelPrice[level] ,"invalid price");
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
     
       
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
       
        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = getFreeXXXReferrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
             emit UserActiveLevels(msg.sender,1,level);
            updateXXXReferrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = getFreeXXXXReferrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
             emit UserActiveLevels(msg.sender,2,level);
            updateXXXXReferrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
        
        totalIncome += levelPrice[level];
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1]*2, "Invalid Cost");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
    
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cc");
        
        UserAccount memory user = UserAccount({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            X3Income: uint(0),
            X4Income: uint(0)
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
         emit UserActiveLevels(userAddress,1,1);
        users[userAddress].activeX6Levels[1] = true;
         emit UserActiveLevels(userAddress,2,1);
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = getFreeXXXReferrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateXXXReferrer(userAddress, freeX3Referrer, 1);

        updateXXXXReferrer(userAddress, getFreeXXXXReferrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateXXXReferrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length), users[referrerAddress].x3Matrix[level].reinvestCount, userPlaceCount++);
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3, (users[referrerAddress].x3Matrix[level].reinvestCount), userPlaceCount++);
       
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        if (referrerAddress != owner) {
            address freeReferrerAddress = getFreeXXXReferrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level, users[referrerAddress].x3Matrix[level].reinvestCount);
            updateXXXReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level, users[owner].x3Matrix[level].reinvestCount);
        }
    }

    function updateXXXXReferrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length), users[referrerAddress].x6Matrix[level].reinvestCount, userPlaceCount++);
            
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
                    emit NewUserPlace(userAddress, ref, 2, level, 5, users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3, users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4, users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
                }
            }

            return updateXXXXReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateXXXX(userAddress, referrerAddress, level, true);
                return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
            updateXXXX(userAddress, referrerAddress, level, true);
                return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateXXXX(userAddress, referrerAddress, level, false);
                return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateXXXX(userAddress, referrerAddress, level, false);
            return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateXXXX(userAddress, referrerAddress, level, true);
            return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateXXXX(userAddress, referrerAddress, level, false);
        } else {
            updateXXXX(userAddress, referrerAddress, level, true);
        }
        
        updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateXXXX(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            address ref = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), users[ref].x6Matrix[level].reinvestCount, userPlaceCount++);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), users[referrerAddress].x6Matrix[level].reinvestCount, userPlaceCount++);
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            address ref1 = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), users[ref1].x6Matrix[level].reinvestCount, userPlaceCount++);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), users[referrerAddress].x6Matrix[level].reinvestCount, userPlaceCount++);
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateXXXXReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
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
            address freeReferrerAddress = getFreeXXXXReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level, users[referrerAddress].x6Matrix[level].reinvestCount);
            updateXXXXReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level, users[referrerAddress].x6Matrix[level].reinvestCount);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function getFreeXXXReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    
    function getFreeXXXXReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveXXXLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveXXXXLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersXXXMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersXXXXMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function getEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
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
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = getEthReceiver(userAddress, _from, matrix, level);
        
        uint256 income = levelPrice[level];
        
        if (income > address(this).balance) {
            income = address(this).balance;
        }
        if (matrix == 1) {
            users[receiver].X3LevelIncome[level] += income;
            users[receiver].X3Income += income;
        } else {
            users[receiver].X4LevelIncome[level] += income;
            users[receiver].X4Income += income;
        }
        
        if (receiver == owner) {
            address(uint160(receiver)).transfer(income * 90/100);
            address(uint160(partner)).transfer(income * 10/100);
        } else {
            address(uint160(receiver)).transfer(income);
        }
        
    
         emit  UserIncome(receiver, _from, income, matrix, level);
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function getX3LevelIncome(address userAddress, uint8 level) public view returns (uint256) {
        return users[userAddress].X3LevelIncome[level];
    }
    
    function getX4LevelIncome(address userAddress, uint8 level) public view returns (uint256) {
        return users[userAddress].X4LevelIncome[level];
    }
    
    function getX3Income(address userAddress) public view returns (uint) {
        return users[userAddress].X3Income;
    }
    
    function getX4Income(address userAddress) public view returns (uint) {
        return users[userAddress].X4Income;
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}