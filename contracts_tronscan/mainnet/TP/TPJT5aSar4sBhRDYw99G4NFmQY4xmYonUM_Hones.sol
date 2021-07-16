//SourceUnit: hones.sol

pragma solidity >=0.4.23 <0.6.0;

contract Hones {
    
    struct User {
        uint id;
        address referrer;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address closedPart;
    }
    
    struct defishare{
      address currentAddress;
      uint8 level;
   }
   
   struct wildcard{
       address currentAddress;
       uint8 remainingWildcard;
   }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    uint16 internal constant LEVEL_PER = 2000;
    uint16 internal constant LEVEL_DIVISOR = 10000; 
    
    defishare[] defishares; 
    wildcard[] wildcards;
    
    uint256 public totalDefishare;
    uint256 public totalWildcard;
    
    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    uint8 public constant levelIncome = 10;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event BuyDefishare(address indexed userAddress, uint8 level);
    event WildCard(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event SentDividends(address _from, address user, uint8 matrix, uint256 amount);
    event SentLevelincome(address indexed from,uint indexed fromId, address receiver,uint indexed receiverId, uint8 matrix, uint8 level,uint8 networklevel);
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 100 * 1e6;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
        
        totalDefishare = 0;
        totalWildcard = 0;
        
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
    
    
    function registrationWildcard(address userAddress, address referrerAddress) external payable {
        registration(userAddress, referrerAddress);
    }
    
    function insertDefishare( address currentAddress, uint8 level) private{
        defishare memory newDefishare = defishare(currentAddress , level);
        defishares.push(newDefishare);
        totalDefishare++;
   }
   
   function insertWildcard( address currentAddress, uint8 remainingWildcard) private{
        wildcard memory newWildcard = wildcard(currentAddress , remainingWildcard);
        wildcards.push(newWildcard);
   }
   
   function buyDefishare(uint8 level) external payable{
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 0 && level <= LAST_LEVEL, "invalid level");
        sendDefishareTRON(msg.sender, level);
        insertDefishare(msg.sender, level);
   }
   
   
   function updateWildcard(address currentAddress, uint8 NewremainingWildcard) private returns (bool success){
       for(uint256 i =0; i< totalWildcard; i++){
           if(wildcards[i].currentAddress == currentAddress){
              wildcards[i].remainingWildcard = NewremainingWildcard;
              return true;
           }
       }
       return false;
   }
   
   
   function getWildcard(address currentAddress) public view returns(uint8 remainingWildcard){
        for(uint256 i =0; i< totalWildcard; i++){
           if(wildcards[i].currentAddress == currentAddress){
              return (wildcards[i].remainingWildcard);
           }
       }
       return 4;
   }     
   
   
    function getTotalDefishare() public view returns (uint256 length){
      return defishares.length;
   }
   
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level, true);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }
    
    
    function doWildcard(address userAddress, address referrerAddress, uint8 matrix, uint8 level) external payable{
        uint8 remaingwc = getWildcard(msg.sender);
        uint8 newwildcard = 0;
        uint8 checkLevel = level-1;
        require(remaingwc>0, "All Wildcards used");
        
        require(isUserExists(userAddress), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
        //if remainingWildcard is 4
        if(remaingwc == 4){
            require(usersActiveX3Levels(msg.sender, 3), "Atleast 3 level should be activated to use Wildcards");
            newwildcard = 3;
        }else if(remaingwc == 3){
            require(usersActiveX3Levels(msg.sender, 3), "Atleast 6 level should be activated to use Wildcards");
            newwildcard = 2;
        }else if(remaingwc == 2){
            require(usersActiveX3Levels(msg.sender, 3), "Atleast 9 level should be activated to use Wildcards");
            newwildcard = 1;
        }else if(remaingwc == 1){
            require(usersActiveX3Levels(msg.sender, 3), "Atleast 12 level should be activated to use Wildcards");
            newwildcard = 0;
        }else{
            require(usersActiveX3Levels(msg.sender, 3), "All Wildcards Used");
        }
        
        if(matrix == 1){
            require(users[userAddress].activeX3Levels[checkLevel], "invalid user. please upgrade user.");
            if(!users[userAddress].activeX3Levels[level]){
                users[userAddress].activeX3Levels[level] = true;
                emit Upgrade(userAddress, referrerAddress, 1, level);
            }
            updateX3Referrer(userAddress, referrerAddress, level);
        }else{
            require(users[userAddress].activeX6Levels[checkLevel], "invalid user. please upgrade user.");
            if(!users[userAddress].activeX6Levels[level]){
                users[userAddress].activeX6Levels[level] = true;
                emit Upgrade(userAddress, referrerAddress, 2, level);
            }
            updateX6Referrer(userAddress, referrerAddress, level, true);
        }
        
        updateWildcard(msg.sender, newwildcard);
        
        totalWildcard++;
        
         emit WildCard(userAddress, referrerAddress, msg.sender, matrix, level);
    }
    
    
    
    function registration(address userAddress, address referrerAddress) private{
        require(msg.value == 300 * 1e6, "registration cost 300 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1, true);
        
        insertDefishare(userAddress, 1);
        insertWildcard(userAddress, 4);
        
        address(uint160(owner)).transfer(levelPrice[1]);
        emit BuyDefishare(msg.sender, 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendTRONDividends(userAddress, referrerAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRONDividends(userAddress, owner, 1, level);
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level, bool sendtron) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                if(sendtron){
                    return sendTRONDividends(userAddress, referrerAddress, 2, level);
                }
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

            return updateX6ReferrerSecondLevel(userAddress, ref, level, true);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, sendtron);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, sendtron);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, sendtron);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, sendtron);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, sendtron);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, sendtron);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
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
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level, bool sendtron) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            if(sendtron){
            return sendTRONDividends(userAddress, referrerAddress, 2, level);
            }
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
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level, sendtron);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            if(sendtron){
            sendTRONDividends(userAddress, owner, 2, level);
            }
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
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

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals);
    }
    

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].closedPart);
    }

    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }


     function distributeLevelIncome(address userAddress, uint8 matrix, uint8 level) private {
        
        uint principal =  (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR) * 100;
        address from_address = userAddress;
        bool owner_flag = false;
        address receiver;

         if(userAddress == owner){
            owner_flag = true;
        }

        for (uint8 i = 1; i <= 10 ; i++) {

            if(owner_flag == false)
            {
                userAddress = users[userAddress].referrer;

                if(userAddress == owner)
                {
                    owner_flag = true;
                }
            }
            else
            {
                userAddress = owner;
            }
            receiver = userAddress;
            if(userAddress != owner)
            {
                if(receiver == owner)
                {
                    owner_flag = true;
                }
                userAddress = receiver;
            }
            
            if(!address(uint160(receiver)).send(((principal * levelIncome / LEVEL_DIVISOR))))
            {
                uint income = (principal * levelIncome / LEVEL_DIVISOR) * 100;
                return address(uint160(receiver)).transfer(income);
            }
            if(owner_flag == false){
            emit SentLevelincome(from_address,users[from_address].id, receiver,users[receiver].id, matrix, level, i);
            }
        }
    }

    function sendTRONDividends(address _from, address userAddress, uint8 matrix, uint8 level) private {

        if(!address(uint160(userAddress)).send(levelPrice[level] - (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR)  )){
            return address(uint160(userAddress)).transfer(levelPrice[level] - (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR));
        }
        emit SentDividends(_from, userAddress, matrix, levelPrice[level] - (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR));
         return distributeLevelIncome(userAddress, matrix, level);
    }
    
    
    function sendDefishareTRON(address _from, uint8 level) private {
        address(uint160(owner)).transfer(levelPrice[level]);
        emit BuyDefishare(_from, level);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}