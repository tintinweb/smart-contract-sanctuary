/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity >=0.4.23 <0.6.0;

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SmartEdMatrix {

    struct User {
        uint id;
        address referrer;
        uint referralCount;
        uint256 lastpayout;
        uint256 dividends;
        uint256 totalwithdrawn;

        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint refreshingCount;
        uint256 time;
        uint256 leveldividends;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint refreshingCount;
        address closedPart;
        uint256 time;
        uint256 leveldividends;

    }

    uint8 public constant FINAL_LEVEL = 12;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    IBEP20 private _token;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event refresh(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedTokenReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event sendExtraTokens(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress, IBEP20 token) public {
        levelPrice[1] = 5 * 10 ** 18;
        for (uint8 i = 2; i <= FINAL_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        _token = token;
        User memory user = User({
            id: 1,
            referrer: address(0),
            referralCount: uint(0),
            lastpayout : 0,
            dividends : 0,
            totalwithdrawn:0

        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= FINAL_LEVEL; i++) {
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
        require(level > 1 && level <= FINAL_LEVEL, "invalid level");
        address giver = msg.sender; 
        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address userX3Referrer = findUserX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = userX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            users[msg.sender].x3Matrix[level].time = block.timestamp;
            upliftX3Referrer(msg.sender, userX3Referrer, giver, level);
            
            emit Upgrade(msg.sender, userX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address userX6Referrer = findUserX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            users[msg.sender].x6Matrix[level].time = block.timestamp;

            upliftX6Referrer(msg.sender, userX6Referrer,giver ,level);
            
            emit Upgrade(msg.sender, userX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        address giver = userAddress;
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            referralCount: 0,
            lastpayout : 0,
            dividends : 0,
            totalwithdrawn:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        users[userAddress].x3Matrix[1].time = block.timestamp;
        users[userAddress].x6Matrix[1].time = block.timestamp;

        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].referralCount++;

        address userX3Referrer = findUserX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = userX3Referrer;
        upliftX3Referrer(userAddress, userX3Referrer,giver, 1);

        upliftX6Referrer(userAddress, findUserX6Referrer(userAddress, 1),giver, 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function upliftX3Referrer(address userAddress, address referrerAddress,address giver, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendTokens(referrerAddress, giver, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != FINAL_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address userReferrerAddress = findUserX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != userReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = userReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].refreshingCount++;
            emit refresh(referrerAddress, userReferrerAddress, userAddress, 1, level);
            upliftX3Referrer(referrerAddress, userReferrerAddress, giver, level);
        } else {
            sendTokens(owner, giver, 1, level);
            users[owner].x3Matrix[level].refreshingCount++;
            emit refresh(owner, address(0), userAddress, 1, level);
        }
    }

    function upliftX6Referrer(address userAddress, address referrerAddress,address giver, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTokens(referrerAddress, giver, 2, level);
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

            return upliftX6ReferrerSecondLevel(userAddress, ref,giver, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                upliftX6(userAddress, referrerAddress, level, true);
                return upliftX6ReferrerSecondLevel(userAddress, referrerAddress,giver, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                upliftX6(userAddress, referrerAddress, level, true);
                return upliftX6ReferrerSecondLevel(userAddress, referrerAddress,giver, level);
            } else {
                upliftX6(userAddress, referrerAddress, level, false);
                return upliftX6ReferrerSecondLevel(userAddress, referrerAddress,giver, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            upliftX6(userAddress, referrerAddress, level, false);
            return upliftX6ReferrerSecondLevel(userAddress, referrerAddress,giver ,level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            upliftX6(userAddress, referrerAddress, level, true);
            return upliftX6ReferrerSecondLevel(userAddress, referrerAddress,giver ,level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            upliftX6(userAddress, referrerAddress, level, false);
        } else {
            upliftX6(userAddress, referrerAddress, level, true);
        }
        
        upliftX6ReferrerSecondLevel(userAddress, referrerAddress,giver, level);
    }

    function upliftX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
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
    
    function upliftX6ReferrerSecondLevel(address userAddress, address referrerAddress,address giver ,uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTokens(referrerAddress, giver, 2, level);
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

        if (!users[referrerAddress].activeX6Levels[level+1] && level != FINAL_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].refreshingCount++;
        
        if (referrerAddress != owner) {
            address userReferrerAddress = findUserX6Referrer(referrerAddress, level);

            emit refresh(referrerAddress, userReferrerAddress, userAddress, 2, level);
            upliftX6Referrer(referrerAddress, userReferrerAddress,giver, level);
        } else {
            emit refresh(owner, address(0), userAddress, 2, level);
            sendTokens(owner, giver, 2, level);
        }
    }
    
    function findUserX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findUserX6Referrer(address userAddress, uint8 level) public view returns(address) {
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
    function userDetails(address user) public view returns(uint256, uint256){
        return(users[user].dividends,users[user].totalwithdrawn);
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].leveldividends);

    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x6Matrix[level].leveldividends);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTokenReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedTokenReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedTokenReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendTokens(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTokenReceiver(userAddress, _from, matrix, level);

        _token.transferFrom(_from, address(uint160(receiver)), levelPrice[level]);
        
        if (isExtraDividends) {
            emit sendExtraTokens(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function getdividends(address user) public returns(bool){
        uint256 amount;
                for(uint8 i =1; i<=12; i++){
                amount = levelPrice[i];
                if(usersActiveX3Levels(user, i)){
                    uint256 deposittime = users[user].x3Matrix[i].time;
                    uint256 lastpayout = users[user].lastpayout;
                    uint256 dividends = calculateDividends(amount, deposittime, lastpayout);
                    users[user].x3Matrix[i].leveldividends = dividends;
                    users[user].dividends += dividends;
                }                 
                if(usersActiveX6Levels(user, i)) {
                    uint256 deposittime = users[user].x6Matrix[i].time;
                    uint256 lastpayout = users[user].lastpayout;
                    uint256 dividends = calculateDividends(amount, deposittime, lastpayout);
                    users[user].x6Matrix[i].leveldividends = dividends;
                    users[user].dividends += dividends;
                    }   
            } 
        return true;    
    }

    function calculateDividends(uint256 amount, uint256 depositTime, uint256 lastPayout) internal view returns (uint256) {
       uint256 dividends;
       uint256 end = depositTime + 8640000;
       uint256 from = lastPayout > depositTime ? lastPayout : depositTime;
       uint256 to = uint256(block.timestamp) > end ? end : uint256(block.timestamp);
       uint256 noOfSec = to - from;
       dividends = amount*noOfSec/1000;
       return dividends/86400;
   }

   function withdraw(address user) public payable returns(bool){
        
        address recepient = user;
        address _from = owner;
        uint256 amount = users[recepient].dividends;
        _token.transferFrom(_from, address(uint160(recepient)), amount);
        users[recepient].lastpayout = block.timestamp;
        users[recepient].totalwithdrawn += amount;
        users[recepient].dividends = 0;           
        return true;
    }           
}