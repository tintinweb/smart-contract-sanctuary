//SourceUnit: tron_buddy.sol

pragma solidity 0.5.10;

contract XGOLD {
    function deposit(address sender, address referrer) public payable;
}

contract TRONBUDDY {
    
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
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }

    mapping(uint8 => uint256) public running_vid;

    
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 14;
    
    mapping(address => User) public users;

    mapping(uint => address) public idToAddress;

    mapping(uint => address) public vidToAddress;

    uint public lastUserId = 2;
    uint public lastvId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;

    XGOLD public xGOLD;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public 
    {
        levelPrice[1] = 18 trx;
        levelPrice[2] = 30 trx;
        levelPrice[3] = 40 trx;
        levelPrice[4] = 50 trx;
        levelPrice[5] = 60 trx;
        levelPrice[6] = 70 trx;
        levelPrice[7] = 80 trx;
        levelPrice[8] = 90 trx;
        levelPrice[9] = 100 trx;
        levelPrice[10] = 51200 trx;
        levelPrice[11] = 102400 trx;
        levelPrice[12] = 204800 trx;
        levelPrice[13] = 409600 trx;
        levelPrice[14] = 819200 trx;


        blevelPrice[1] = 12 trx;
        blevelPrice[2] = 30 trx;
        blevelPrice[3] = 40 trx;
        blevelPrice[4] = 50 trx;
        blevelPrice[5] = 60 trx;
        blevelPrice[6] = 70 trx;
        blevelPrice[7] = 80 trx;
        blevelPrice[8] = 90 trx;
        blevelPrice[9] = 100 trx;
        blevelPrice[10] = 51200 trx;
        blevelPrice[11] = 102400 trx;
        blevelPrice[12] = 204800 trx;
        blevelPrice[13] = 409600 trx;
        blevelPrice[14] = 819200 trx;
         
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        vidToAddress[1] = ownerAddress;        

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
        running_vid[i]=1;
        } 
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }   
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function setXGold(address xGoldAddress) public 
    {
        require(msg.sender == owner, "onlyOwner");
        require(address(xGOLD) == address(0));
        xGOLD = XGOLD(xGoldAddress);
    }

    function withdrawLostTRXFromBalance() public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
    
    //===================   Start Buy New Level ===============

    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");        
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) 
        {
            require(msg.value == levelPrice[level], "invalid price");
            require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX3Levels[level], "level already activated");            

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } 
        else {
            require(msg.value == blevelPrice[level], "invalid price");
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated");            

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }
    
            address freeX6Referrer = findFreeX6Referrer(level);
            users[msg.sender].x6Matrix[level].currentReferrer = freeX6Referrer;
            users[msg.sender].activeX6Levels[level] = true;
            updateX3Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    

    //===================   End Buy New Level ===============
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        if (address(xGOLD) != address(0)) {
            xGOLD.deposit(userAddress, referrerAddress);
            require(msg.value == levelPrice[currentStartingLevel] * 3, "invalid registration cost");
        } else {
            require(msg.value == levelPrice[currentStartingLevel]+blevelPrice[currentStartingLevel] , "invalid registration cost");
        }
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        vidToAddress[lastvId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        lastUserId++;
        lastvId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);

        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(1), 1);        
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 2) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) 
            {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }


      function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private 
      {
        users[referrerAddress].x6Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].referrals.length < 1) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2);
        //close matrix
        users[referrerAddress].x6Matrix[level].referrals = new address[](0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL && users[referrerAddress].x6Matrix[level].reinvestCount==2) 
        {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        //create new one by recursion
       
            //check referrer active level

        running_vid[level]=running_vid[level]+1;

            address freeReferrerAddress = findFreeX6Referrer(level);
            if (users[referrerAddress].x6Matrix[level].currentReferrer != freeReferrerAddress) 
            {
                users[referrerAddress].x6Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x6Matrix[level].reinvestCount++;

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
       
    }

 
    

    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) 
    {
        while (true) 
        {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(uint8 level) public view returns(address) 
    {
        uint256 id=running_vid[level];
        return vidToAddress[id];   
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) 
    {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) 
    {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint256) 
    {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint256) 
    {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
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
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
    if(matrix==1)
    {
        if (!address(uint160(receiver)).send(levelPrice[level])) {
            address(uint160(owner)).send(address(this).balance);
            return;
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    else
    {
        if (!address(uint160(receiver)).send(blevelPrice[level])) {
            address(uint160(owner)).send(address(this).balance);
            return;
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}
//41a4e7176790732f8a2a7593902d63748386923531