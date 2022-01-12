/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity >=0.4.23 <0.6.0;


contract BNBEE {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeA3Levels;
        mapping(uint8 => bool) activeA6Levels;
        
        mapping(uint8 => A3) A3Matrix;
        mapping(uint8 => A6) A6Matrix;
    }
    
    struct A3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct A6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    struct userDetails {
        address user;
        address reffer;
        address[] referals;
    }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => userDetails) private userdetails;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    bool public registerStatus;
  
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedBNBReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraBNBDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 0.05e18;
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
            users[ownerAddress].activeA3Levels[i] = true;
            users[ownerAddress].activeA6Levels[i] = true;
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
            require(!users[msg.sender].activeA3Levels[level], "level already activated");

            if (users[msg.sender].A3Matrix[level-1].blocked) {
                users[msg.sender].A3Matrix[level-1].blocked = false;
            }
    
            address freeA3Referrer = findFreeA3Referrer(msg.sender, level);
            users[msg.sender].A3Matrix[level].currentReferrer = freeA3Referrer;
            users[msg.sender].activeA3Levels[level] = true;
            updateA3Referrer(msg.sender, freeA3Referrer, level);
            
            emit Upgrade(msg.sender, freeA3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeA6Levels[level], "level already activated"); 

            if (users[msg.sender].A6Matrix[level-1].blocked) {
                users[msg.sender].A6Matrix[level-1].blocked = false;
            }

            address freeA6Referrer = findFreeA6Referrer(msg.sender, level);
            
            users[msg.sender].activeA6Levels[level] = true;
            updateA6Referrer(msg.sender, freeA6Referrer, level);
            
            emit Upgrade(msg.sender, freeA6Referrer, 2, level);
        }
    }   

    function registerAccount(address[12] memory _users) public {
        require(owner == msg.sender,"Only Owner Accessible");
        address  reffer;
        reffer = owner;
        for(uint8 i = 0;i < _users.length; i++){
          User memory user = User({
            id: lastUserId,
            referrer: reffer,
            partnersCount: 0
        });
        
        users[_users[i]] = user;
        idToAddress[lastUserId] = _users[i];
        
        users[_users[i]].referrer = reffer;
        
        userIds[lastUserId] = _users[i];
        lastUserId++;
        users[reffer].partnersCount++; 
        levelUpdate(_users[i]);
        emit Registration(_users[i], reffer, users[_users[i]].id, users[reffer].id);
        reffer = idToAddress[users[_users[i]].id];
    }
 }

    function levelUpdate(address _user) private {
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_user].activeA3Levels[i] = true;
            users[_user].activeA6Levels[i] = true;
        }
    }

    function A3Register(address[12] memory _users)public {
      require(owner == msg.sender,"Only Owner Accessible");
      address a3reffer;
          for(uint8 i = 0;i < _users.length; i++){
             require(isUserExists(_users[i]), "user is not exists. Register first.");
              a3reffer = users[_users[i]].referrer;
              A3Referrer(_users[i],a3reffer);
          }
    }    

    function A3Referrer(address _user,address _reffer)private{
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
         users[_user].A3Matrix[i].currentReferrer = _reffer;
          updateA3Referrer(_user,_reffer,i);
        }
    }

    function A6Register(address[12] memory _users)public {
      require(owner == msg.sender,"Only Owner Accessible");
          for(uint8 i = 0;i < _users.length; i++){
             require(isUserExists(_users[i]), "user is not exists. Register first.");
              A6Referrer(_users[i]);
          }
    }    

    function A6Referrer(address _user)private{
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
        updateA6Referrer(_user, findFreeA6Referrer(_user, i), i);
        }
    }

    function updateRegisterStatus(bool _status)public{
        require(owner == msg.sender,"Only Owner Accessible");
        registerStatus = _status;
    }

    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(msg.value == 0.1e18, "registration cost 0.1");
        
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
        
        users[userAddress].activeA3Levels[1] = true; 
        users[userAddress].activeA6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeA3Referrer = findFreeA3Referrer(userAddress, 1);
        users[userAddress].A3Matrix[1].currentReferrer = freeA3Referrer;
        updateA3Referrer(userAddress, freeA3Referrer, 1);

        updateA6Referrer(userAddress, findFreeA6Referrer(userAddress, 1), 1);
      
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateA3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].A3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].A3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].A3Matrix[level].referrals.length));
            return sendBNBDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].A3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeA3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].A3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeA3Referrer(referrerAddress, level);
            if (users[referrerAddress].A3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].A3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].A3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateA3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendBNBDividends(owner, userAddress, 1, level);
            users[owner].A3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateA6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeA6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].A6Matrix[level].firstLevelReferrals.length < 2) {
         
            users[referrerAddress].A6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].A6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].A6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendBNBDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].A6Matrix[level].currentReferrer;            
            users[ref].A6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].A6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].A6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].A6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].A6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].A6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].A6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].A6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].A6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateA6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].A6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].A6Matrix[level].closedPart != address(0)) {
          
            if ((users[referrerAddress].A6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].A6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].A6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].A6Matrix[level].closedPart)) {

                updateA6(userAddress, referrerAddress, level, true);
                return updateA6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].A6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].A6Matrix[level].closedPart) {
                  
                updateA6(userAddress, referrerAddress, level, true);
                return updateA6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
              
                updateA6(userAddress, referrerAddress, level, false);
                return updateA6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].A6Matrix[level].firstLevelReferrals[1] == userAddress) {
          
            updateA6(userAddress, referrerAddress, level, false);
            return updateA6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].A6Matrix[level].firstLevelReferrals[0] == userAddress) {
            
            updateA6(userAddress, referrerAddress, level, true);
            return updateA6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[0]].A6Matrix[level].firstLevelReferrals.length <= 
           
            users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[1]].A6Matrix[level].firstLevelReferrals.length) {
                
            updateA6(userAddress, referrerAddress, level, false);
        } else {
          
            if( users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[0]].A6Matrix[level].firstLevelReferrals.length < 2){
                  updateA6(userAddress, referrerAddress, level, false);
            }
            else{
                 updateA6(userAddress, referrerAddress, level, true);
            }
          
        }
        
        updateA6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

   
    function updateA6(address userAddress, address referrerAddress, uint8 level, bool a2) private {
        if (!a2) {
            users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[0]].A6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].A6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[0]].A6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[0]].A6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].A6Matrix[level].currentReferrer = users[referrerAddress].A6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[1]].A6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].A6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[1]].A6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].A6Matrix[level].firstLevelReferrals[1]].A6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].A6Matrix[level].currentReferrer = users[referrerAddress].A6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateA6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].A6Matrix[level].secondLevelReferrals.length < 4) {
            return sendBNBDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory a6 = users[users[referrerAddress].A6Matrix[level].currentReferrer].A6Matrix[level].firstLevelReferrals;
        
        if (a6.length == 2) {
            if (a6[0] == referrerAddress ||
                a6[1] == referrerAddress) {
                users[users[referrerAddress].A6Matrix[level].currentReferrer].A6Matrix[level].closedPart = referrerAddress;
            } else if (a6.length == 1) {
                if (a6[0] == referrerAddress) {
                    users[users[referrerAddress].A6Matrix[level].currentReferrer].A6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].A6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].A6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].A6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeA6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].A6Matrix[level].blocked = true;
        }

        users[referrerAddress].A6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeA6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateA6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendBNBDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeA3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeA3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeA6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeA6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveA3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeA3Levels[level];
    }

    function usersActiveA6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeA6Levels[level];
    }

    function usersA3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].A3Matrix[level].currentReferrer,
                users[userAddress].A3Matrix[level].referrals,
                users[userAddress].A3Matrix[level].blocked);
    }

    function usersA6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].A6Matrix[level].currentReferrer,
                users[userAddress].A6Matrix[level].firstLevelReferrals,
                users[userAddress].A6Matrix[level].secondLevelReferrals,
                users[userAddress].A6Matrix[level].blocked,
                users[userAddress].A6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findBNBReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].A3Matrix[level].blocked) {
                    emit MissedBNBReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].A3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].A6Matrix[level].blocked) {
                    emit MissedBNBReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].A6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendBNBDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
    
    if(registerStatus){
            (address receiver, bool isExtraDividends) = findBNBReceiver(userAddress, _from, matrix, level);

         if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
    
       
        
        if (isExtraDividends) {
            emit SentExtraBNBDividends(_from, receiver, matrix, level);
        }
    }
    }
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}