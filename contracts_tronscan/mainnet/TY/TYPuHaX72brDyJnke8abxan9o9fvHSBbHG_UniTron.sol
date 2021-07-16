//SourceUnit: UniTron.sol

pragma solidity >=0.4.22 <0.7.0;

contract UniTron {
    
    address payable public owner;
    
    struct UserDetail {
        uint256 id;
        uint256 userIncome;
        uint256 poolIncome;
        address payable referrer;
        
        mapping (uint8 => bool) poolActiveStatus;
        mapping (uint8 => level) levelMatrix;
        mapping (uint8 => userGlobalPool) poolMatrix;
        
    }
    
    struct level {
        mapping (uint8 => uint256) levelReferrals;
    }
    
    struct SpillDetails {
        address _from;
        address referrer;
        address receiver;
        uint256 income;
        uint8 pool;
        uint8 level;
        uint256 levelReferrals;
        uint256 receiverLevelReferrals;
    }
    
     struct userGlobalPool {
        uint256 globalPoolPosition;
        address payable poolReferrer;
        uint256 reinvestCount;
        // uint256 lastLevelReferralCount;
        bool isBlocked;
        mapping (uint8 => uint256) levelReferralCount;
    }
    
    struct GlobalPool {
        uint256 currentPosition;
        uint256 currentFreePosition;
        mapping (uint256 => address payable) poolIds;
        // mapping (address => uint256) addressToPoolIds;
        mapping (uint256 => uint8) globalReferralCount;
    }
    
    uint256 public currentUserId = 1;
    uint8 public LAST_POOL = 15;
    uint256 public totalIncome;
    address payable referrerLevelOne;
    address payable referrerLevelTwo;
    address payable referrerLevelThree;
    address payable referrerLevelFour;
    address payable referrerLevelFive;
    address payable poolReferrerOne;
    address payable poolReferrerTwo;
    address payable poolReferrerThree;
    address payable poolReferrerFour;
    address payable poolReferrerFive;
    address payable freeReferrerOne;
    address payable freeReferrerTwo;
    address payable freeReferrerThree;
    address payable freeReferrerFour;
    address payable freeReferrerFive;
    mapping (address => UserDetail) users;
    mapping (uint256 => address) public userIds;
    mapping (uint8 => uint256) poolJoiningFees;
    mapping (uint8 => uint256) autoPoolIncome;
    mapping (uint8 => GlobalPool) globalPoolMatrix;
    
    event Registration(address user, address referrer, uint256 userId, uint256 referrerId);
    event PoolPurchased(address user, uint256 userId, uint8 pool);
    event LevelIncome(address _from, address receiver, uint256 income, uint8 pool, uint8 level, uint256 levelReferralCount);
    event PoolLevelUpdate(address _from, address receiver, uint8 pool, uint8 level, uint256 income, uint256 levelReferralCount);
    event GlobalPoolUpdated(address userAddress,uint8 pool, uint256 currentPosition, uint256 myPosition);
    event Reinvest(address userAddress, uint8 pool, uint256 reinvestCount, bool status);
    event NewUserPlaced(address userPlaced, address referrerAddress, uint256 userPlacedId, uint8 pool, uint256 referralCount);
    event SpilledLevelIncome(address _from, address referrer, address receiver, uint256 income, uint8 pool, uint8 level, uint256 levelReferralCount);
    
    constructor(address payable ownerAddress) public {
        owner = ownerAddress;
        poolJoiningFees[1] = 225 * 1e6;
        autoPoolIncome[1] = 25 * 1e6;
        
        
        for (uint8 i=2; i<=LAST_POOL; i++) {
            poolJoiningFees[i] = (poolJoiningFees[i-1] * 2);
            autoPoolIncome[i] = (autoPoolIncome[i-1] * 2);
        }
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            userIncome: uint256(0),
            poolIncome: uint256(0),
            referrer: address(0)
        });
        
        users[owner] = user;
        userIds[currentUserId] = owner;
        currentUserId++;
        
        UserDetail storage User = users[owner];
        
        emit Registration(owner, User.referrer, User.id, uint256(0));
        
        for (uint8 i=1; i<=LAST_POOL; i++) {
            GlobalPool storage globalPool = globalPoolMatrix[i];
        
            globalPool.currentPosition++;
            globalPool.poolIds[globalPool.currentPosition] = owner;
            User.poolMatrix[i].poolReferrer = address(0);
            User.poolMatrix[i].globalPoolPosition = globalPool.currentPosition;
            User.poolActiveStatus[i] = true;
            globalPool.currentFreePosition = globalPool.currentPosition;
            
            emit PoolPurchased(owner, User.id, i);
            emit GlobalPoolUpdated(owner, i, globalPool.currentFreePosition, globalPool.currentPosition);
        }
        
    }
    
    function registration(address payable referrerAddress) external payable {
        require(!isUserExists(msg.sender), "user already exists");
        require(isUserExists(referrerAddress), "user already exists");
        require(msg.value == (poolJoiningFees[1] + autoPoolIncome[1]), "Invalid registration amount");
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            userIncome: uint256(0),
            poolIncome: uint256(0),
            referrer: referrerAddress
        });
        
        users[msg.sender] = user;
        userIds[currentUserId] = msg.sender;
        currentUserId++;
        
        emit Registration(msg.sender, referrerAddress, users[msg.sender].id, users[referrerAddress].id);
        emit PoolPurchased(msg.sender, users[msg.sender].id, 1);
        
        levelIncome(msg.sender, referrerAddress, 1);
        emit NewUserPlaced(msg.sender, referrerAddress, users[msg.sender].id, 1, users[referrerAddress].levelMatrix[1].levelReferrals[1]);
        
        if (users[referrerAddress].levelMatrix[1].levelReferrals[1] == 2) {
            users[referrerAddress].poolActiveStatus[1] = true;
        }
        
        updateGlobalPool(msg.sender, 1);
        poolIncome(msg.sender, users[msg.sender].poolMatrix[1].poolReferrer, 1);
        owner.transfer(address(this).balance);
        
        totalIncome += msg.value;
    }
    
    function purchasePool(uint8 pool) external payable {
        UserDetail storage user = users[msg.sender];
        require(user.poolActiveStatus[1], "require atleast 2 directs to unlock all the slots");
        require(isUserExists(msg.sender), "User not registered yet");
        require(pool >= 1 && pool <= LAST_POOL, "Invalid pool number");
        require(msg.value == (poolJoiningFees[pool] + autoPoolIncome[pool]));
        
        if (user.poolMatrix[pool].reinvestCount > 0) {
            require(user.poolMatrix[pool].isBlocked, "Pool not filled yet");
            user.poolMatrix[pool].isBlocked = false;
            
            emit Reinvest(msg.sender, pool, user.poolMatrix[pool].reinvestCount, false);
        }
        
        emit PoolPurchased(msg.sender, user.id, pool);
        user.poolActiveStatus[pool] = true;
        levelIncome(msg.sender, user.referrer, pool);
        emit NewUserPlaced(msg.sender, user.referrer, user.id, pool, users[user.referrer].levelMatrix[pool].levelReferrals[1]);
        
        updateGlobalPool(msg.sender, pool);
        poolIncome(msg.sender, user.poolMatrix[pool].poolReferrer, pool);
        
        owner.transfer(address(this).balance);
        
        totalIncome += msg.value;
    }
    
    function levelIncome(address payable userAddress, address payable referrerAddress, uint8 pool) private {
        uint256 income = poolJoiningFees[pool];
        
        uint256 incomeLevelOne = income * 50/100;
        uint256 incomeLevelTwo = income * 20/100;
        uint256 incomeLevelThree = income * 5/100;
        uint256 incomeLevelFour = income * 10/100;
        uint256 incomeLevelFive = income * 15/100;
        
        referrerLevelOne = referrerAddress;
        referrerLevelTwo = users[referrerLevelOne].referrer;
        referrerLevelThree = users[referrerLevelTwo].referrer;
        referrerLevelFour = users[referrerLevelThree].referrer;
        referrerLevelFive = users[referrerLevelFour].referrer;
        
        freeReferrerOne = getFreeReferrer(userAddress, pool);
        freeReferrerTwo = getFreeReferrer(freeReferrerOne, pool);
        freeReferrerThree = getFreeReferrer(freeReferrerTwo, pool);
        freeReferrerFour = getFreeReferrer(freeReferrerThree, pool);
        freeReferrerFive = getFreeReferrer(freeReferrerFour, pool);
        
        
        if (referrerLevelOne != address(0)) {
            UserDetail storage user = users[referrerLevelOne];
            
            if (referrerLevelOne == owner) {
                user.userIncome += income;
                referrerLevelOne.transfer(income * 99/100);
                owner.transfer(income * 1/100);
                
                user.levelMatrix[pool].levelReferrals[1]++;
                
                emit LevelIncome(userAddress, referrerLevelOne, income, pool, 1, user.levelMatrix[pool].levelReferrals[1]);
            } else if (pool == 1 || freeReferrerOne == referrerLevelOne) {
                user.userIncome += incomeLevelOne * 99/100;
                referrerLevelOne.transfer(incomeLevelOne * 99/100);
                owner.transfer(incomeLevelOne * 1/100);
                users[owner].userIncome += incomeLevelOne * 1/100;
                
                user.levelMatrix[pool].levelReferrals[1]++;
                emit LevelIncome(userAddress, referrerLevelOne, incomeLevelOne * 99/100, pool, 1, user.levelMatrix[pool].levelReferrals[1]);
            } else {
                UserDetail storage User = users[freeReferrerOne];
                User.userIncome += incomeLevelOne * 99/100;
                freeReferrerOne.transfer(incomeLevelOne * 99/100);
                owner.transfer(incomeLevelOne * 1/100);
                users[owner].userIncome += incomeLevelOne * 1/100;
                user.levelMatrix[pool].levelReferrals[1]++;
                
                SpillDetails memory spill = SpillDetails({
                   _from: userAddress,
                   referrer: referrerLevelOne,
                   receiver: freeReferrerOne,
                   income: incomeLevelOne * 99/100,
                   pool: pool,
                   level: 1,
                   levelReferrals: user.levelMatrix[pool].levelReferrals[1],
                   receiverLevelReferrals: User.levelMatrix[pool].levelReferrals[1]
                });
                
                emit LevelIncome(spill._from, spill.receiver, spill.income, spill.pool, spill.level, spill.receiverLevelReferrals);
                emit SpilledLevelIncome(spill._from, spill.referrer, spill.receiver, spill.income, spill.pool, 1, spill.levelReferrals);
            }
        
        }
        
        if (referrerLevelTwo != address(0)) {
            UserDetail storage user = users[referrerLevelTwo];
            if (pool == 1 || freeReferrerTwo == referrerLevelTwo) {
                user.userIncome += incomeLevelTwo * 99/100;
                referrerLevelTwo.transfer(incomeLevelTwo * 99/100);
                users[owner].userIncome += incomeLevelTwo * 1/100;
                owner.transfer(incomeLevelTwo * 1/100);
                user.levelMatrix[pool].levelReferrals[2]++;
            
            emit LevelIncome(userAddress, referrerLevelTwo, incomeLevelTwo * 99/100, pool, 2, user.levelMatrix[pool].levelReferrals[2]);
            } else {
                UserDetail storage User = users[freeReferrerTwo];
                User.userIncome += incomeLevelTwo * 99/100;
                freeReferrerTwo.transfer(incomeLevelTwo * 99/100);
                owner.transfer(incomeLevelTwo * 1/100);
                users[owner].userIncome += incomeLevelTwo * 1/100;
                user.levelMatrix[pool].levelReferrals[2]++;
                
                SpillDetails memory spill = SpillDetails({
                   _from: userAddress,
                   referrer: referrerLevelTwo,
                   receiver: freeReferrerTwo,
                   income: incomeLevelTwo * 99/100,
                   pool: pool,
                   level: 2,
                   levelReferrals: user.levelMatrix[pool].levelReferrals[2],
                   receiverLevelReferrals: User.levelMatrix[pool].levelReferrals[2]
                });
                
                emit LevelIncome(spill._from, spill.receiver, spill.income, spill.pool, spill.level, spill.receiverLevelReferrals);
                emit SpilledLevelIncome(spill._from, spill.referrer, spill.receiver, spill.income, spill.pool, spill.level, spill.levelReferrals);
            }
        }
        
        if (referrerLevelThree != address(0)) {
            UserDetail storage user = users[referrerLevelThree];
            if (pool == 1 || freeReferrerThree == referrerLevelThree) {
                user.userIncome += incomeLevelThree * 99/100;
                referrerLevelThree.transfer(incomeLevelThree * 99/100);
                users[owner].userIncome += incomeLevelThree * 1/100;
                owner.transfer(incomeLevelThree * 1/100);
                user.levelMatrix[pool].levelReferrals[3]++;
                
                emit LevelIncome(userAddress, referrerLevelThree, incomeLevelThree * 99/100, pool, 3, user.levelMatrix[pool].levelReferrals[3]);
            } else {
                UserDetail storage User = users[freeReferrerThree];
                User.userIncome += incomeLevelThree * 99/100;
                freeReferrerThree.transfer(incomeLevelThree * 99/100);
                owner.transfer(incomeLevelThree * 1/100);
                users[owner].userIncome += incomeLevelThree * 1/100;
                user.levelMatrix[pool].levelReferrals[3]++;
                
                SpillDetails memory spill = SpillDetails({
                   _from: userAddress,
                   referrer: referrerLevelThree,
                   receiver: freeReferrerThree,
                   income: incomeLevelThree * 99/100,
                   pool: pool,
                   level: 3,
                   levelReferrals: user.levelMatrix[pool].levelReferrals[3],
                   receiverLevelReferrals: User.levelMatrix[pool].levelReferrals[3]
                });
                
                emit LevelIncome(spill._from, spill.receiver, spill.income, spill.pool, spill.level, spill.receiverLevelReferrals);
                emit SpilledLevelIncome(spill._from, spill.referrer, spill.receiver, spill.income, spill.pool, spill.level, spill.levelReferrals);
            }
            
        } 
        
        if (referrerLevelFour != address(0)) {
            UserDetail storage user = users[referrerLevelFour];
            
            if (pool == 1 || freeReferrerFour == referrerLevelFour) {
                user.userIncome += incomeLevelFour * 99/100;
                referrerLevelFour.transfer(incomeLevelFour * 99/100);
                users[owner].userIncome += incomeLevelFour * 1/100;
                owner.transfer(incomeLevelFour * 1/100);
                user.levelMatrix[pool].levelReferrals[4]++;
                
                emit LevelIncome(userAddress, referrerLevelFour, incomeLevelFour * 99/100, pool, 4, user.levelMatrix[pool].levelReferrals[4]);
            } else {
                UserDetail storage User = users[freeReferrerFour];
                User.userIncome += incomeLevelFour * 99/100;
                freeReferrerFour.transfer(incomeLevelFour * 99/100);
                owner.transfer(incomeLevelFour * 1/100);
                users[owner].userIncome += incomeLevelFour * 1/100;
                user.levelMatrix[pool].levelReferrals[4]++;
                
                SpillDetails memory spill = SpillDetails({
                   _from: userAddress,
                   referrer: referrerLevelFour,
                   receiver: freeReferrerFour,
                   income: incomeLevelFour * 99/100,
                   pool: pool,
                   level: 4,
                   levelReferrals: user.levelMatrix[pool].levelReferrals[4],
                   receiverLevelReferrals: User.levelMatrix[pool].levelReferrals[4]
                });
                
                emit LevelIncome(spill._from, spill.receiver, spill.income, spill.pool, spill.level, spill.receiverLevelReferrals);
                emit SpilledLevelIncome(spill._from, spill.referrer, spill.receiver, spill.income, spill.pool, spill.level, spill.levelReferrals);
            }
            
        } 
        
        if (referrerLevelFive != address(0)) {
            UserDetail storage user = users[referrerLevelFive];
            
            if (pool == 1 || freeReferrerFive == referrerLevelFive) {
                user.userIncome += incomeLevelFive * 99/100;
                referrerLevelFive.transfer(incomeLevelFive * 99/100);
                users[owner].userIncome += incomeLevelFive * 1/100;
                owner.transfer(incomeLevelFive * 1/100);
                user.levelMatrix[pool].levelReferrals[5]++;
                
                emit LevelIncome(userAddress, referrerLevelFive, incomeLevelFive * 99/100, pool, 5, user.levelMatrix[pool].levelReferrals[5]);
            } else {
                UserDetail storage User = users[freeReferrerFive];
                User.userIncome += incomeLevelFive * 99/100;
                freeReferrerFive.transfer(incomeLevelFive * 99/100);
                owner.transfer(incomeLevelFive * 1/100);
                users[owner].userIncome += incomeLevelFive * 1/100;
                user.levelMatrix[pool].levelReferrals[5]++;
                
                SpillDetails memory spill = SpillDetails({
                   _from: userAddress,
                   referrer: referrerLevelFive,
                   receiver: freeReferrerFive,
                   income: incomeLevelFive * 99/100,
                   pool: pool,
                   level: 5,
                   levelReferrals: user.levelMatrix[pool].levelReferrals[5],
                   receiverLevelReferrals: User.levelMatrix[pool].levelReferrals[5]
                });
                
                emit LevelIncome(spill._from, spill.receiver, spill.income, spill.pool, spill.level, spill.receiverLevelReferrals);
                emit SpilledLevelIncome(spill._from, spill.referrer, spill.receiver, spill.income, spill.pool, spill.level, spill.levelReferrals);
            }
            
        }    
    }
    
    function poolIncome(address userAddress, address payable referrerAddress, uint8 pool) private {
        // GlobalPool storage globalPool = globalPoolMatrix[pool];
        
        uint256 income = autoPoolIncome[pool];
        
        uint256 incomeLevelOne = income * 50/100;
        uint256 incomeLevelTwo = income * 20/100;
        uint256 incomeLevelThree = income * 5/100;
        uint256 incomeLevelFour = income * 10/100;
        uint256 incomeLevelFive = income * 15/100;
        
        poolReferrerOne = referrerAddress;
        poolReferrerTwo = users[poolReferrerOne].poolMatrix[pool].poolReferrer;
        poolReferrerThree = users[poolReferrerTwo].poolMatrix[pool].poolReferrer;
        poolReferrerFour = users[poolReferrerThree].poolMatrix[pool].poolReferrer;
        poolReferrerFive = users[poolReferrerFour].poolMatrix[pool].poolReferrer;
        
        if (poolReferrerOne != address(0)) {
            UserDetail storage user = users[poolReferrerOne];
            //check owner condtion, if referrer is owner transfer all the amount
            if (poolReferrerOne == owner) {
                user.poolIncome += income;
                poolReferrerOne.transfer(income * 99/100);
                owner.transfer(income * 1/100);
                user.poolMatrix[pool].levelReferralCount[1]++;
                emit PoolLevelUpdate(userAddress, poolReferrerOne, pool, 1, income, user.poolMatrix[pool].levelReferralCount[1]);
            } else if (user.poolMatrix[pool].levelReferralCount[1] < 2 && !users[poolReferrerOne].poolActiveStatus[pool]) {
                    user.poolIncome += incomeLevelOne * 99/100;
                    poolReferrerOne.transfer(incomeLevelOne * 99/100);
                    users[owner].poolIncome += incomeLevelOne * 1/100;
                    owner.transfer(incomeLevelOne * 1/100);
                    user.poolMatrix[pool].levelReferralCount[1]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerOne, pool, 1, incomeLevelOne * 99/100, user.poolMatrix[pool].levelReferralCount[1]);
            } else if (users[poolReferrerOne].poolActiveStatus[pool]) {
                    user.poolIncome += incomeLevelOne * 99/100;
                    poolReferrerOne.transfer(incomeLevelOne * 99/100);
                    users[owner].poolIncome += incomeLevelOne * 1/100;
                    owner.transfer(incomeLevelOne * 1/100);
                    user.poolMatrix[pool].levelReferralCount[1]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerOne, pool, 1, incomeLevelOne * 99/100, user.poolMatrix[pool].levelReferralCount[1]);
            } else {
                    owner.transfer(incomeLevelOne);
                    user.poolMatrix[pool].levelReferralCount[1]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerOne, pool, 1, 0, user.poolMatrix[pool].levelReferralCount[1]);
            }
            
        }
        
        if (poolReferrerTwo != address(0)) {
            UserDetail storage user = users[poolReferrerTwo];
            
            if (users[poolReferrerTwo].poolActiveStatus[pool]) {
                user.poolIncome += incomeLevelTwo * 99/100;
                poolReferrerTwo.transfer(incomeLevelTwo * 99/100);
                users[owner].poolIncome += incomeLevelTwo * 1/100;
                owner.transfer(incomeLevelTwo * 1/100);
                user.poolMatrix[pool].levelReferralCount[2]++;
                emit PoolLevelUpdate(userAddress, poolReferrerTwo, pool, 2, incomeLevelTwo, user.poolMatrix[pool].levelReferralCount[2]);
            } else {
                    owner.transfer(incomeLevelTwo);
                    user.poolMatrix[pool].levelReferralCount[2]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerTwo, pool, 2, 0, user.poolMatrix[pool].levelReferralCount[2]);
            }
        }
        
        if (poolReferrerThree != address(0)) {
            UserDetail storage user = users[poolReferrerThree];
            
            if (users[poolReferrerThree].poolActiveStatus[pool]) {
                user.poolIncome += incomeLevelThree * 99/100;
                poolReferrerThree.transfer(incomeLevelThree * 99/100);
                users[owner].poolIncome += incomeLevelThree * 1/100;
                owner.transfer(incomeLevelThree * 1/100);
                user.poolMatrix[pool].levelReferralCount[3]++;
                emit PoolLevelUpdate(userAddress, poolReferrerThree, pool, 3, incomeLevelThree, user.poolMatrix[pool].levelReferralCount[3]);
            } else {
                    owner.transfer(incomeLevelThree);
                    user.poolMatrix[pool].levelReferralCount[3]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerThree, pool, 3, 0, user.poolMatrix[pool].levelReferralCount[3]);
            }
        }
        
        if (poolReferrerFour != address(0)) {
            UserDetail storage user = users[poolReferrerFour];
            
            if (users[poolReferrerFour].poolActiveStatus[pool]) {
                user.poolIncome += incomeLevelFour * 99/100;
                poolReferrerFour.transfer(incomeLevelFour * 99/100);
                users[owner].poolIncome += incomeLevelFour * 1/100;
                owner.transfer(incomeLevelFour * 1/100);
                user.poolMatrix[pool].levelReferralCount[4]++;
                emit PoolLevelUpdate(userAddress, poolReferrerFour, pool, 4, incomeLevelFour, user.poolMatrix[pool].levelReferralCount[4]);
            } else {
                    owner.transfer(incomeLevelFour);
                    user.poolMatrix[pool].levelReferralCount[4]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerFour, pool, 4, 0, user.poolMatrix[pool].levelReferralCount[4]);
            }
            
        }
        
        if (poolReferrerFive != address(0)) {
            UserDetail storage user = users[poolReferrerFive];
            
            if (users[poolReferrerFive].poolActiveStatus[pool]) {
                user.poolIncome += incomeLevelFive * 99/100;
                poolReferrerFive.transfer(incomeLevelFive * 99/100);
                users[owner].poolIncome += incomeLevelFive * 1/100;
                owner.transfer(incomeLevelFive * 1/100);
                user.poolMatrix[pool].levelReferralCount[5]++;
                emit PoolLevelUpdate(userAddress, poolReferrerFive, pool, 5, incomeLevelFive * 99/100, user.poolMatrix[pool].levelReferralCount[5]);
            } else {
                    owner.transfer(incomeLevelFive);
                    user.poolMatrix[pool].levelReferralCount[5]++;
                    emit PoolLevelUpdate(userAddress, poolReferrerFive, pool, 5, 0, user.poolMatrix[pool].levelReferralCount[5]);
            }
            
            
            if (user.poolMatrix[pool].levelReferralCount[5] == 243 && poolReferrerFive != owner) {
                user.poolMatrix[pool].levelReferralCount[1] = 0;
                user.poolMatrix[pool].levelReferralCount[2] = 0;
                user.poolMatrix[pool].levelReferralCount[3] = 0;
                user.poolMatrix[pool].levelReferralCount[4] = 0;
                user.poolMatrix[pool].levelReferralCount[5] = 0;
                user.poolMatrix[pool].reinvestCount++;
                user.poolMatrix[pool].isBlocked = true;
                
                emit Reinvest(poolReferrerFive, pool, user.poolMatrix[pool].reinvestCount, true);
            } else if (user.poolMatrix[pool].levelReferralCount[5] == 243 && poolReferrerFive == owner) {
                user.poolMatrix[pool].levelReferralCount[1] = 0;
                user.poolMatrix[pool].levelReferralCount[2] = 0;
                user.poolMatrix[pool].levelReferralCount[3] = 0;
                user.poolMatrix[pool].levelReferralCount[4] = 0;
                user.poolMatrix[pool].levelReferralCount[5] = 0;
                user.poolMatrix[pool].reinvestCount++;
                user.poolMatrix[pool].isBlocked = true;
                
                emit Reinvest(owner, pool, user.poolMatrix[pool].reinvestCount, false);
                
                updateGlobalPool(owner, pool);
            }
        }
    }
    
    function updateGlobalPool(address payable userAddress, uint8 pool) private {
        UserDetail storage user = users[userAddress];
        GlobalPool storage globalPool = globalPoolMatrix[pool];
        
        globalPool.currentPosition++;
        globalPool.poolIds[globalPool.currentPosition] = userAddress;
        user.poolMatrix[pool].globalPoolPosition = globalPool.currentPosition;
                
        if (globalPool.globalReferralCount[globalPool.currentFreePosition] < 3) {
            
            user.poolMatrix[pool].poolReferrer = globalPool.poolIds[globalPool.currentFreePosition];
            globalPool.globalReferralCount[globalPool.currentFreePosition]++;
        } else {
            globalPool.currentFreePosition++;
            user.poolMatrix[pool].poolReferrer = globalPool.poolIds[globalPool.currentFreePosition];
            globalPool.globalReferralCount[globalPool.currentFreePosition]++;
        }
        
        emit GlobalPoolUpdated(userAddress, pool, globalPool.currentFreePosition, globalPool.currentPosition);
    }
    
    function getFreeReferrer(address payable userAddress, uint8 pool) private view returns(address payable) {
        while (userAddress != address(0)) {
            if (users[users[userAddress].referrer].poolActiveStatus[pool]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
        
        return owner;
    }
    
    function getUserDetails(address userAddress, uint8 pool) public view returns (uint256 userIncome, uint256 poolIncome, uint256 userId, bool poolActiveStatus, uint256 referrerId) {
        UserDetail storage user = users[userAddress];
        
        return (
            user.userIncome,
            user.poolIncome,
            user.id,
            user.poolActiveStatus[pool],
            users[user.referrer].id
            );
    }
    
    function getGlobalPool(uint8 pool) public view returns (uint256 currentPosition, uint256 currentFreePosition) {
        return (
                globalPoolMatrix[pool].currentPosition,
                globalPoolMatrix[pool].currentFreePosition
            );
    }
    
    function getUserGlobalPool(uint256 id, uint8 pool) public view returns (uint256 globalPosition, address poolReferrer) {
        UserDetail storage user = users[userIds[id]];
        return (
                user.poolMatrix[pool].globalPoolPosition,
                user.poolMatrix[pool].poolReferrer
            );
    }
    
    function getPoolPrice(uint8 pool) public view returns(uint256 price) {
        return (poolJoiningFees[pool] + autoPoolIncome[pool]);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
}