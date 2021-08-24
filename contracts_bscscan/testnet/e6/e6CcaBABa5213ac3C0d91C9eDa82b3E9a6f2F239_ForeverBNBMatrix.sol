/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// testing - 3


// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract ForeverBNBMatrix {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 14;
    uint public currentUserId = 2;
    address public ownerAddress;
    bool public lockStatus;
    
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    mapping(uint8 => uint) public levelPrice;
    mapping(address => uint) public availMatriBal;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event MissedMatrixEarnings(address indexed receiver, address indexed from, uint8 level, uint amount);
    event ReceivedMatrixEarnings(address indexed receiver, address indexed from, uint8 level, uint amount);
    
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
      
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    constructor()  {
        levelPrice[0] = 0.0125e18; 
        ownerAddress = msg.sender;
        
        users[ownerAddress].id = 1;
        userIds[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
            users[ownerAddress].activeX6Levels[i] = true;
        }
    }
    
    receive() external isLock onlyOwner payable {
       
    }
    
    function updateMatrixPrice(uint8 _level, uint _price)  external onlyOwner returns(bool) {
          levelPrice[_level] = _price;
          return true;
    } 
    
    function guard(address payable _toUser, uint _amount) external onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    } 
    
    function contractLock(bool _lockStatus) external onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    } 

    function registration(address referrerAddress) external isLock payable {
        register(msg.sender, referrerAddress);
    }
    
    function manualBuyLevel(uint8 level) external isLock payable {
        availMatriBal[msg.sender] += msg.value;
        
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(availMatriBal[msg.sender] == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeX6Levels[level], "level already activated"); 
        require(users[msg.sender].activeX6Levels[level-1], "buy previous levels first."); 


        address freeX6Referrer = findFreeX6Referrer(msg.sender, msg.sender, level);
        
        buyLevel(msg.sender, freeX6Referrer, level);
       
    } 
    
    function buyLevel(address userAddress, address referrerAddress, uint8 level) private {
        
        users[userAddress].activeX6Levels[level] = true;
        
        availMatriBal[userAddress] -= levelPrice[level];
        
        updateX6Referrer(userAddress, referrerAddress, level);
        
        emit Upgrade(userAddress, referrerAddress, level);
        
    }
    
    function register(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1], "invalid registration cost");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        users[userAddress].id = currentUserId;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeX6Levels[1] = true;
        
        userIds[currentUserId] = userAddress;
        currentUserId++;
        users[referrerAddress].partnersCount++;
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, userAddress, 1), 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress,  level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == ownerAddress) {
                return sendMatrixEarnings(referrerAddress, userAddress, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, level, 6);
                }
            }
            
            else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                        
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, level, 4);
                }
            } 
            
            else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, level, 6);
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
            } 
            
            else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } 
            
            else {
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } 
        
        else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            
            if(referrerAddress != ownerAddress &&
            (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 2 ||
            users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 3) && 
            users[referrerAddress].activeX6Levels[level+1] == false) {
                
                return updateMatrixBal(referrerAddress, level, levelPrice[level]);
                
            }
            
            else
                return sendMatrixEarnings(referrerAddress, userAddress, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } 
            
            else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != ownerAddress) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, userAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(ownerAddress, address(0), userAddress, level);
            sendMatrixEarnings(ownerAddress, userAddress, level);
        }
    }
    
    function findFreeX6Referrer(address userAddress, address caller, uint8 level) private returns(address k) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            emit MissedMatrixEarnings(users[userAddress].referrer, caller, level, levelPrice[level]);
            userAddress = users[userAddress].referrer;
        }
    }
    
    function updateMatrixBal(address userAddress, uint8 level, uint amount) private {
         availMatriBal[userAddress] += amount; 
         
         if(availMatriBal[userAddress] == levelPrice[level+1]) {
             
            address freeX6Referrer = findFreeX6Referrer(userAddress, msg.sender, level+1);
        
            buyLevel(userAddress, freeX6Referrer, level+1);
             
         }
         
    }
    
    function sendMatrixEarnings(address recieverAddress, address _from, uint8 level) private {
        
        require((payable(recieverAddress)).send(levelPrice[level]), "Transaction Failed");
        
        emit ReceivedMatrixEarnings(recieverAddress, _from,  level, levelPrice[level]);
    }
    
    function findFreeReferrer(address userAddress, uint8 level) public view  returns(address ref) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, uint,address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].reinvestCount,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
}