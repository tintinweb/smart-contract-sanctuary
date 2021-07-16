//SourceUnit: NexZone _type.sol

pragma solidity >=0.4.23 <0.7.0;

contract NexZone {
    
    struct UserAccount {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        uint256 Z3Income;
        uint256 Z4Income;
        uint256 teamSize;
        bool primeZoneStatus; 
        mapping(uint8 => bool) activeZ3Levels;
        mapping(uint8 => bool) activeZ6Levels;
        
        mapping(uint256 => uint256) Z3LevelIncome;
        mapping(uint256 => uint256) Z4LevelIncome;
        
        mapping(uint8 => Z3) Z3Matrix;
        mapping(uint8 => Z4) Z6Matrix;
    }
    
    struct Z3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint256 reinvestCount;
    }
    
    struct Z4{
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        bool isInPool;
        bool isActive;
        uint256 reinvestCount;
    }
    
    struct GlobalMatrix {
        uint256 currentPosition;
        uint256 currentFreePosition;
        mapping(uint256 => address) globalFreeReferrer;
        mapping(uint256 => uint8) globalReferralCount;
    }

    uint8 public constant LAST_LEVEL = 12;
    uint256 public totalIncome;
    
    mapping(address => UserAccount) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;
    mapping(uint8 => GlobalMatrix) autoPools;
    
    uint16[] levelRate = [625, 250, 125];
    uint256 public lastUserId = 2;
    address payable public  owner;
    address partner;
    mapping(uint8 => uint256) public levelPrice;

    event UserRegistration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId);
    event Recycle(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level, uint256 reinvestCount);
    event UpgradeLevel(address indexed user, uint8 matrix, uint8 level);
    event NewZ3Referral(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint256 reinvestCount, uint8 index);
    event NewReferral(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint256 reinvestCount);
    event IncomeTransferred(address indexed user,address indexed from, uint256 value,uint8 matrix, uint8 level, uint8 logType);
    event MissedIncome(address _from, address missedBy, address receiver, uint8 matrix, uint8 level, uint256 incomeMissed);
    event PositionLog(uint256 currentPosition, uint256 currentFreePosition, address freeAddress, address currentAddress);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner has the access.");
        _;
    }
    
    constructor(address payable ownerAddress, address partnerAddress) public {
        levelPrice[1] = 600 * 1e6;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
           owner = ownerAddress;
           partner = partnerAddress;
      UserAccount memory user ;
          user= UserAccount({
            id: 1,
            referrer: address(0),
            partnersCount: uint256(0),
            Z3Income: uint256(0),
            Z4Income: uint256(0),
            teamSize: uint256(0),
            primeZoneStatus: true
        });   
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeZ3Levels[i] = true;
            emit UpgradeLevel(owner, 1, i);
            users[ownerAddress].activeZ6Levels[i] = true;
            emit UpgradeLevel(owner, 2, i);
            autoPools[i].currentPosition++;
            autoPools[i].currentFreePosition = 1;
            autoPools[i].globalFreeReferrer[1] = owner;
        }
        
        userIds[1] = ownerAddress;
        
        emit UserRegistration(owner, address(0), users[owner].id, 0);
        
    }
  
    function() external payable {
        
    }
    
    function regUser(address referrerAddress, uint8 _type) external payable {
        registration(msg.sender, referrerAddress, _type);
    }
    
    function buyLevel(uint8 level) external payable {
        if (lastUserId <= 7) {
            buyNewLevel(level, 0);
        } else {
            buyNewLevel(level, 1);
        }
    }
    
    function buyNewLevel(uint8 level, uint8 _type) private {
        if (_type == 0) {
            require(lastUserId <= 7, "500");
        } else {
            require(msg.value == (levelPrice[level]) ,"invalid price");
        }
        
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeZ3Levels[level], "level already activated");
        require(!users[msg.sender].activeZ6Levels[level], "level already activated");

            if (users[msg.sender].Z3Matrix[level-1].blocked) {
                users[msg.sender].Z3Matrix[level-1].blocked = false;
            }
    
            address freeZ3Referrer = nextZ3Referrer(msg.sender, level);
            users[msg.sender].Z3Matrix[level].currentReferrer = freeZ3Referrer;
            users[msg.sender].activeZ3Levels[level] = true;
            emit UpgradeLevel(msg.sender,1,level);
            newZ3Referrer(msg.sender, freeZ3Referrer, level, _type);

            if (users[msg.sender].Z6Matrix[level-1].blocked) {
                users[msg.sender].Z6Matrix[level-1].blocked = false;
            }
            
            users[msg.sender].activeZ6Levels[level] = true;
            emit UpgradeLevel(msg.sender,2,level);
            
            updateGlobalMatrix(msg.sender, level, _type);
        
        if (_type==1) {
            totalIncome += levelPrice[level];
        }
        
    }    
    
    function registration(address userAddress, address referrerAddress, uint8 _type) private {
        if (_type == 0) {
            require(lastUserId <= 7, "500");
        } else {
            require(msg.value == levelPrice[1], "Invalid Cost");
        }
        
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
            Z3Income: uint256(0),
            Z4Income: uint256(0),
            teamSize: uint256(0),
            primeZoneStatus: false
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeZ3Levels[1] = true; 
        users[userAddress].activeZ6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        
        users[referrerAddress].partnersCount++;
        
        if (users[referrerAddress].partnersCount == 2) {
            users[referrerAddress].primeZoneStatus = true;
        } 

        address freeZ3Referrer = nextZ3Referrer(userAddress, 1);
        users[userAddress].Z3Matrix[1].currentReferrer = freeZ3Referrer;
        newZ3Referrer(userAddress, freeZ3Referrer, 1, _type);
        
        updateGlobalMatrix(userAddress, 1, _type);
        
        if (_type == 0) {
            users[userAddress].primeZoneStatus = true;
            if (lastUserId <=4) {
                for (uint8 i=2; i<=LAST_LEVEL; i++) {
                    buyNewLevel(i, 0);
                }
            } else if (lastUserId <= 7) {
                for (uint8 i=2; i<=5; i++) {
                    buyNewLevel(i, 0);
                }
            }
        }
        
        emit UserRegistration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        emit UpgradeLevel(msg.sender, 1, 1);
        emit UpgradeLevel(msg.sender, 2, 1);
        lastUserId++;
        
        if (_type==1) {
            totalIncome += levelPrice[1];
        }
    }
    
    function updateZ3LevelOne(address userAddress, address referrerAddress, uint256 rewards, uint8 level, uint8 _type) private {
        users[referrerAddress].Z3Matrix[level].referrals.push(userAddress);
        uint8 size = uint8(users[referrerAddress].Z3Matrix[level].referrals.length);
        if (size != 2) {
            emit NewZ3Referral(userAddress, referrerAddress, 1, level, size, users[referrerAddress].Z3Matrix[level].reinvestCount, 1);
            
            return checkLevelThreshold(userAddress, referrerAddress, rewards, 1, level, _type);
        }
        
        emit NewZ3Referral(userAddress, referrerAddress, 1, level, size, (users[referrerAddress].Z3Matrix[level].reinvestCount), 1);
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = nextZ3Referrer(referrerAddress, level);
            if (users[referrerAddress].Z3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].Z3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            updateZ3LevelOne(referrerAddress, freeReferrerAddress, rewards, level, _type);
        } else {
            sendRewards(owner, userAddress, 1, level, rewards, _type);
            if (size == 3) {
                users[owner].Z3Matrix[level].reinvestCount++;
                emit Recycle(owner, address(0), userAddress, 1, level, users[owner].Z3Matrix[level].reinvestCount);
            }
        }
    }
    
    function newZ3Referrer(address userAddress, address referrerAddress, uint8 level, uint8 _type) private {
        address referrer = referrerAddress;

        for (uint8 i=0; i<3; i++) {
            uint256 rewards = ((levelPrice[level] * levelRate[i]) / 1500);
            if (i==0) {
                updateZ3LevelOne(userAddress, referrerAddress, rewards, level, _type);
            } else {
                uint8 size = uint8(users[referrerAddress].Z3Matrix[level].referrals.length);
                if (size == 2) {
                    sendRewards(userIds[2], userAddress, 1, level, rewards, _type);
                    if (referrer != owner) {
                        emit MissedIncome(address(0), address(0), userIds[2], 1, level, rewards);
                    }
                } else {
                    checkLevelThreshold(userAddress, referrer, rewards, 1, level, _type);
                }
                
                emit NewZ3Referral(userAddress, referrer, 1, level, uint8(size), users[referrer].Z3Matrix[level].reinvestCount, i+1);
            }
            
            referrer = nextZ3Referrer(referrer, level);
        }
        
        if (users[referrerAddress].Z3Matrix[level].referrals.length == 3) {
            users[referrerAddress].Z3Matrix[level].referrals = new address[](0);
            users[referrerAddress].Z3Matrix[level].reinvestCount++;
                  
            emit Recycle(referrerAddress, users[referrerAddress].Z3Matrix[level].currentReferrer, userAddress, 1, level, users[referrerAddress].Z3Matrix[level].reinvestCount);
        }
    }
    
    function checkLevelThreshold(address userAddress, address referrerAddress, uint256 rewards, uint8 matrix, uint8 level, uint8 _type) private {
        if (level != LAST_LEVEL) {
            if (((users[referrerAddress].Z3LevelIncome[level] + users[referrerAddress].Z4LevelIncome[level]) < ((2 ** uint256(level)) * (1000 * 1e6))) || users[referrerAddress].activeZ3Levels[level+1] || referrerAddress == owner) {
                sendRewards(referrerAddress, userAddress, matrix, level, rewards, _type);
            } else {
                sendRewards(userIds[2], userAddress, matrix, level, rewards, _type);
                emit MissedIncome(userAddress, referrerAddress, userIds[2], matrix, level, rewards);
            }
        } else if (level == LAST_LEVEL) {
            if ((users[referrerAddress].Z3LevelIncome[level] + users[referrerAddress].Z4LevelIncome[level]) < ((2 ** uint256(level)) * (1000 * 1e6)) || referrerAddress == owner) {
                sendRewards(referrerAddress, userAddress, matrix, level, rewards, _type);
            } else {
                sendRewards(userIds[2], userAddress, matrix, level, rewards, _type);
                emit MissedIncome(userAddress, referrerAddress, userIds[2], matrix, level, rewards);
            }
        }
    }
    
    function updateGlobalMatrix(address userAddress, uint8 level, uint8 _type) private {
        
        autoPools[level].currentPosition++;
        
        autoPools[level].globalFreeReferrer[autoPools[level].currentPosition] = userAddress;
        users[userAddress].Z6Matrix[level].currentReferrer = autoPools[level].globalFreeReferrer[autoPools[level].currentFreePosition];
        autoPools[level].globalReferralCount[autoPools[level].currentFreePosition]++;
        emit PositionLog(autoPools[level].currentPosition, autoPools[level].currentFreePosition, autoPools[level].globalFreeReferrer[autoPools[level].currentFreePosition], autoPools[level].globalFreeReferrer[autoPools[level].currentPosition]);
        if (autoPools[level].globalReferralCount[autoPools[level].currentFreePosition] == 2) {
            autoPools[level].currentFreePosition++;
        }
        newZ4Referrer(userAddress, users[userAddress].Z6Matrix[level].currentReferrer, level, _type);
        
    }

    function newZ4Referrer(address userAddress, address referrerAddress, uint8 level, uint8 _type) private {
        uint256 rewards = (levelPrice[level] / 3);
        
        users[referrerAddress].Z6Matrix[level].firstLevelReferrals.push(userAddress);
        emit NewReferral(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].Z6Matrix[level].firstLevelReferrals.length), users[referrerAddress].Z6Matrix[level].reinvestCount);
        address nextReferrer = users[referrerAddress].Z6Matrix[level].currentReferrer;
        if (nextReferrer != address(0)) {
            users[nextReferrer].Z6Matrix[level].secondLevelReferrals.push(nextReferrer);
            emit NewReferral(userAddress, nextReferrer, 2, level, (2 + uint8(users[nextReferrer].Z6Matrix[level].secondLevelReferrals.length)), users[nextReferrer].Z6Matrix[level].reinvestCount);
            if (users[nextReferrer].Z6Matrix[level].secondLevelReferrals.length < 4) {
                if(users[nextReferrer].primeZoneStatus) {
                    checkLevelThreshold(userAddress, nextReferrer, rewards, 2, level, _type);
                } else {
                    sendRewards(userIds[2], userAddress, 2, level, rewards, _type);
                    emit MissedIncome(userAddress, nextReferrer, userIds[2], 2, level, rewards);
                }
                
            } else {
                if (nextReferrer != owner) {
                    checkLevelThreshold(userAddress, users[nextReferrer].referrer, rewards, 2, level, _type);
                } else {
                    sendRewards(owner, userAddress, 2, level, rewards, _type);
                }
               
               users[nextReferrer].Z6Matrix[level].firstLevelReferrals = new address[](0);
               users[nextReferrer].Z6Matrix[level].secondLevelReferrals = new address[](0);
               users[nextReferrer].Z6Matrix[level].reinvestCount++;
               emit Recycle(nextReferrer, users[nextReferrer].Z6Matrix[level].currentReferrer, userAddress, 2, level, users[nextReferrer].Z6Matrix[level].reinvestCount);
               updateGlobalMatrix(nextReferrer, level, _type);
            }
        } else {
            sendRewards(owner, userAddress, 2, level, rewards, _type);
        }
        
    }
    
    function nextZ3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (userAddress != owner) {
            if (users[users[userAddress].referrer].activeZ3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
        
        return owner;
    }
    
    
    function nextZ4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (userAddress != owner) {
            if (users[users[userAddress].referrer].activeZ6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
        
        return owner;
    }

    function usersZ3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, bool) {
        return (users[userAddress].Z3Matrix[level].currentReferrer,
                users[userAddress].Z3Matrix[level].referrals,
                users[userAddress].Z3Matrix[level].blocked,
                users[userAddress].activeZ3Levels[level]);
    }

    function usersZ4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, bool) {
        return (users[userAddress].Z6Matrix[level].currentReferrer,
                users[userAddress].Z6Matrix[level].firstLevelReferrals,
                users[userAddress].Z6Matrix[level].secondLevelReferrals,
                users[userAddress].Z6Matrix[level].blocked,
                users[userAddress].activeZ6Levels[level]);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendRewards(address receiver, address _from, uint8 matrix, uint8 level, uint256 income, uint8 _type) private {
        if (_type == 1) {
            if (income > address(this).balance) {
                income = address(this).balance;
            }
                
            if (matrix == 1) {
                users[receiver].Z3LevelIncome[level] += income;
                users[receiver].Z3Income += income;
            } else {
                users[receiver].Z4LevelIncome[level] += income;
                users[receiver].Z4Income += income;
            }
            
            if (receiver == userIds[2] || receiver == owner) {
                address(uint160(receiver)).transfer(income * 9/10);
                address(uint160(partner)).transfer(income * 1/10);
            } else {
                address(uint160(receiver)).transfer(income);
            }
            
            emit  IncomeTransferred(receiver, _from, income, matrix, level, _type);
        }
    }
    
    function getZ3LevelIncome(address userAddress, uint8 level) public view returns (uint256) {
        return users[userAddress].Z3LevelIncome[level];
    }
    
    function getZ4LevelIncome(address userAddress, uint8 level) public view returns (uint256) {
        return users[userAddress].Z4LevelIncome[level];
    }
    
    function getFreePosition(uint8 level) public view returns (uint256) {
        return autoPools[level].currentFreePosition;
    }
    
    function getCurrentPosition(uint8 level) public view returns (uint256) {
        return autoPools[level].currentPosition;
    }
    
    function getCurrentReferrer(address userAddress, uint8 level) public view returns (address) {
        return users[userAddress].Z6Matrix[level].currentReferrer;
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}