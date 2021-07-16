//SourceUnit: EverTron.sol

// SPDX-License-Identifier: MIT
/*
https://everin.one/
*/
pragma solidity >=0.5.8 <=0.5.14;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IEverStakePool{

    function stake(uint256 _amount) external;
    function isTokensFrozen(address userAddress) external view returns (bool);
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw()external;
    function unstake() external;
    function getDividends() external;
    function calculateDividends(address userAddress) external view returns (uint256);
    function createUser(address userAddress, uint32 userID) external;
    function isUserExists(address userAddress)external view returns (bool);
    function getPool(uint32 period) external view returns (string memory, string memory);
    function getUser(address userAddress) external view returns (string memory, string memory);
    function getCurrentPeriod() external view returns (uint32);
    function blockToPeriod(uint256 blockNumb) external view returns (uint32);
    function chargePool() external payable;

    event Stake(uint256 period, address indexed user, uint256 amount);
    event PoolCharged(uint256 period, uint256 amount);
    event UnStake(uint256 period, address indexed user, uint256 amount);
    event Dividends(uint256 period, address indexed user, uint256 amount);
}

interface IEverToken{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function initWhitelist(address[] calldata _addresses) external;
    function mintReward(uint256 _amount) external;
    function burn(uint256 _amount) external;
    function setJustswap(address payable _swapExchange) external;
    function getTokensCanBeBought(uint256 trx_sold) external view returns (uint256);
    function getTRXneededToBuy(uint256 tokens_bought) external view returns (uint256);
    function getTRXcanBeBought(uint256 tokens_sold) external view returns (uint256);
    function getTokensNeededToBuy(uint256 trx_bought) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Burned(address indexed burner, uint256 burnAmount);
    event MintedReward(address indexed minter, uint256 mintAmount);
}


contract EverTron {


    using SafeMath for uint256;
    
    struct Reward{
        uint32 lastWithdraw;
        uint256 totalAmount;
        mapping(uint32 => uint256) dayReward;
    }
    
    struct User {
        uint32 referrerID;
        uint32 partnersCount;
        
        uint8 activeX3Levels;
        uint8 activeX6Levels;
        address userAddress;
       
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X3 {
        uint32 currentReferrerID;
        uint32[] referralsID;
        bool blocked;
        uint32 reinvestCount;
    }
    
    struct X6 {
        uint32 currentReferrerID;
        uint32[] firstLevelReferralsID;
        uint32[] secondLevelReferralsID;
        bool blocked;
        uint32 reinvestCount;

        uint32 closedPart;
    }

    uint8 public constant LAST_LEVEL = 20;
    uint32 public constant TOTAL_FREEZING_DAYS=90;
    
    
    uint256 public startBlock;
    
    mapping(uint32 => User) public users;
    mapping(uint32 => Reward) public pendingReward;
    mapping(address => uint32) public AddressToId;

    uint32 public lastUserId = 2;
    address public matrixesRoot;
    
    uint256 public blocksInFreezingDay; //28800;//1200 * 24 h
    uint8 public giftActivationLevelsIds;
    
    mapping(uint8 => uint256) public levelPrice;

    IEverStakePool public stakePool;
    IEverToken public everToken;
    
    event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId);
    event Reinvest(uint32 indexed userID, uint32 indexed currentReferrerID, uint32 indexed callerID, uint8 matrix, uint8 level);
    event Upgrade(uint32 indexed userId, uint32 indexed referrerId, uint8 matrix, uint8 level);
    event NewUserPlace(uint32 indexed userId, uint32 indexed referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(uint32 indexed receiverID, uint32 indexed fromID, uint8 matrix, uint8 level);
    event SentExtraEthDividends(uint32 indexed fromID, uint32 indexed receiverID, uint256 amount, uint8 matrix, uint8 level);
    event SentEthDividends(uint32 indexed fromID, uint32 indexed receiverID, uint256 amount, uint8 matrix, uint8 level);
    event SentEver(uint32 indexed receiverID, uint256 amount, uint8 matrix, uint8 level);
    event SentEverReward(uint32 upToDay, uint32 indexed userId, uint256 amount);
    
    constructor(address payable _stakePool, address _everToken, address _matrixesRoot, uint256 _blocksInFreezingDay, uint8 _giftActivationLevelsIds) public {
        
        levelPrice[1] = 150 trx;
        levelPrice[2] = 250 trx;
        levelPrice[3] = 450 trx;
        levelPrice[4] = 750 trx;
        levelPrice[5] = 1250 trx;
        levelPrice[6] = 2000 trx;
        levelPrice[7] = 3500 trx;
        levelPrice[8] = 6000 trx;
        levelPrice[9] = 10000 trx;
        levelPrice[10] = 17000 trx;
        levelPrice[11] = 29000 trx;
        levelPrice[12] = 50000 trx;
        levelPrice[13] = 85000 trx;
        levelPrice[14] = 144000 trx;
        levelPrice[15] = 222000 trx;
        levelPrice[16] = 333000 trx;
        levelPrice[17] = 499000 trx;
        levelPrice[18] = 749000 trx;
        levelPrice[19] = 1125000 trx;
        levelPrice[20] = 1650000 trx;
        
        matrixesRoot = _matrixesRoot;
        
        stakePool = IEverStakePool(_stakePool);
        everToken = IEverToken(_everToken);
        startBlock = block.number;
        blocksInFreezingDay =_blocksInFreezingDay;
        giftActivationLevelsIds = _giftActivationLevelsIds;
        
        User memory user = User({
            referrerID: 0,
            partnersCount: 0,
            activeX3Levels: LAST_LEVEL,
            activeX6Levels: LAST_LEVEL,
            userAddress:matrixesRoot
        });
        
        users[1] = user;
        AddressToId[matrixesRoot]=1;
        //idToAddress[1] = matrixesRoot;

    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        uint32 userID=AddressToId[msg.sender];
        require(userID>0, "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(users[userID].activeX3Levels == (level-uint8(1)), "wrong next X3 level,check current");
            

            if (users[userID].x3Matrix[level-1].blocked) {
                users[userID].x3Matrix[level-1].blocked = false;
            }
    
            uint32 freeX3ReferrerID = findFreeX3Referrer(userID, level);
            users[userID].x3Matrix[level].currentReferrerID = freeX3ReferrerID;
            users[userID].activeX3Levels = level;
            updateX3Referrer(userID, freeX3ReferrerID, level);
            
            emit Upgrade(userID, freeX3ReferrerID, 1, level);

        } else {
            require(users[userID].activeX6Levels == (level-uint8(1)), "wrong next X6 level,check current"); 

            if (users[userID].x6Matrix[level-1].blocked) {
                users[userID].x6Matrix[level-1].blocked = false;
            }

            uint32 freeX6ReferrerID = findFreeX6Referrer(userID, level);
            
            users[userID].activeX6Levels = level;
            updateX6Referrer(userID, freeX6ReferrerID, level);
            
            emit Upgrade(userID, freeX6ReferrerID, 2, level);
        }
    }    
    
    function registrationExt(uint32 referrerID) external payable{

        address userAddress=msg.sender;
        require(!isUserExists(userAddress), "user exists");

        require(referrerID>0 && isUserExists(users[referrerID].userAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0 && msg.sender == tx.origin, "cannot be a contract");
        require(msg.value == levelPrice[1] * 2, "invalid registration cost");

        uint32 userID=lastUserId;
        lastUserId++;       
        users[referrerID].partnersCount++;
        
        User memory user = User({
            referrerID: referrerID,
            partnersCount: 0,
            activeX3Levels: (userID > giftActivationLevelsIds ? 1:LAST_LEVEL),
            activeX6Levels: (userID > giftActivationLevelsIds ? 1:LAST_LEVEL),
            userAddress:userAddress
        });
        
        users[userID] = user;
        AddressToId[userAddress]=userID;
        users[userID].x3Matrix[1].currentReferrerID = referrerID;
        //idToAddress[userID] = userAddress;
        updateX3Referrer(userID, referrerID, 1);

        updateX6Referrer(userID, referrerID, 1);

        stakePool.createUser(userAddress, userID);
       
        emit Registration(userAddress, users[referrerID].userAddress, userID, referrerID);
    }
    
    function updateX3Referrer(uint32 userID, uint32 referrerID, uint8 level) private {
        users[referrerID].x3Matrix[level].referralsID.push(userID);

        if (users[referrerID].x3Matrix[level].referralsID.length < 3) {
            emit NewUserPlace(userID, referrerID, 1, level, uint8(users[referrerID].x3Matrix[level].referralsID.length));
            return sendETHDividends(referrerID, userID, 1, level);
        }
        
        emit NewUserPlace(userID, referrerID, 1, level, 3);
        //close matrix
        users[referrerID].x3Matrix[level].referralsID = new uint32[](0);
        if (users[referrerID].activeX3Levels < (level+uint8(1)) && level != LAST_LEVEL) {
            users[referrerID].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerID > 1) {
            //check referrer active level
            uint32 freeReferrerID = findFreeX3Referrer(referrerID, level);
            if (users[referrerID].x3Matrix[level].currentReferrerID != freeReferrerID) {
                users[referrerID].x3Matrix[level].currentReferrerID = freeReferrerID;
            }
            
            users[referrerID].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerID, freeReferrerID, userID, 1, level);
            updateX3Referrer(referrerID, freeReferrerID, level);
        } else {
            sendETHDividends(1, userID, 1, level);
            users[1].x3Matrix[level].reinvestCount++;
            emit Reinvest(1, 0, userID, 1, level);
        }
    }

    function updateX6Referrer(uint32 userID, uint32 referrerID, uint8 level) private {
        require(users[referrerID].activeX6Levels>=level, "500. Referrer level is inactive");
        
        if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length < 2) {
            users[referrerID].x6Matrix[level].firstLevelReferralsID.push(userID);
            emit NewUserPlace(userID, referrerID, 2, level, uint8(users[referrerID].x6Matrix[level].firstLevelReferralsID.length));
            
            //set current level
            users[userID].x6Matrix[level].currentReferrerID = referrerID;

            if (referrerID > 1) {            
            
                uint32 ref = users[referrerID].x6Matrix[level].currentReferrerID;            
                users[ref].x6Matrix[level].secondLevelReferralsID.push(userID); 
            
                uint256 len = users[ref].x6Matrix[level].firstLevelReferralsID.length;
            
                if ((len == 2) && 
                    (users[ref].x6Matrix[level].firstLevelReferralsID[0] == referrerID) &&
                    (users[ref].x6Matrix[level].firstLevelReferralsID[1] == referrerID)) {
                    if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length == 1) {
                        emit NewUserPlace(userID, ref, 2, level, 5);
                    } else {
                        emit NewUserPlace(userID, ref, 2, level, 6);
                    }
                }  else if ((len == 1 || len == 2) &&
                        users[ref].x6Matrix[level].firstLevelReferralsID[0] == referrerID) {
                    if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length == 1) {
                        emit NewUserPlace(userID, ref, 2, level, 3);
                    } else {
                        emit NewUserPlace(userID, ref, 2, level, 4);
                    }
                } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferralsID[1] == referrerID) {
                    if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length == 1) {
                        emit NewUserPlace(userID, ref, 2, level, 5);
                    } else {
                        emit NewUserPlace(userID, ref, 2, level, 6);
                    }
                }

                return updateX6ReferrerSecondLevel(userID, ref, level);
            }else{
                return sendETHDividends(referrerID, userID, 2, level);
            }
        }
        
        users[referrerID].x6Matrix[level].secondLevelReferralsID.push(userID);

        if (users[referrerID].x6Matrix[level].closedPart != 0) {
            if (users[referrerID].x6Matrix[level].firstLevelReferralsID[0] == users[referrerID].x6Matrix[level].closedPart) {

                updateX6(userID, referrerID, level, true);
                return updateX6ReferrerSecondLevel(userID, referrerID, level);

            } else {
                updateX6(userID, referrerID, level, false);
                return updateX6ReferrerSecondLevel(userID, referrerID, level);
            }
        }

        if (users[referrerID].x6Matrix[level].firstLevelReferralsID[1] == userID) {
            updateX6(userID, referrerID, level, false);
            return updateX6ReferrerSecondLevel(userID, referrerID, level);
        } else if (users[referrerID].x6Matrix[level].firstLevelReferralsID[0] == userID) {
            updateX6(userID, referrerID, level, true);
            return updateX6ReferrerSecondLevel(userID, referrerID, level);
        }
        
        if (users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.length <= 
            users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.length) {
            updateX6(userID, referrerID, level, false);
        } else {
            updateX6(userID, referrerID, level, true);
        }
        
        updateX6ReferrerSecondLevel(userID, referrerID, level);
    }

    function updateX6(uint32 userID, uint32 referrerID, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.push(userID);
            emit NewUserPlace(userID, users[referrerID].x6Matrix[level].firstLevelReferralsID[0], 2, level, uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.length));
            emit NewUserPlace(userID, referrerID, 2, level, 2 + uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.length));
            //set current level
            users[userID].x6Matrix[level].currentReferrerID = users[referrerID].x6Matrix[level].firstLevelReferralsID[0];
        } else {
            users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.push(userID);
            emit NewUserPlace(userID, users[referrerID].x6Matrix[level].firstLevelReferralsID[1], 2, level, uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.length));
            emit NewUserPlace(userID, referrerID, 2, level, 4 + uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.length));
            //set current level
            users[userID].x6Matrix[level].currentReferrerID = users[referrerID].x6Matrix[level].firstLevelReferralsID[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(uint32 userID, uint32 referrerID, uint8 level) private {
        if (users[referrerID].x6Matrix[level].secondLevelReferralsID.length < 4) {
            return sendETHDividends(referrerID, userID, 2, level);
        }
        
        uint32[] memory x6 = users[users[referrerID].x6Matrix[level].currentReferrerID].x6Matrix[level].firstLevelReferralsID;
        
        if (x6.length == 2) {
            if (x6[0] == referrerID ||
                x6[1] == referrerID) {
                users[users[referrerID].x6Matrix[level].currentReferrerID].x6Matrix[level].closedPart = referrerID;
            } else if (x6.length == 1) {
                if (x6[0] == referrerID) {
                    users[users[referrerID].x6Matrix[level].currentReferrerID].x6Matrix[level].closedPart = referrerID;
                }
            }
        }
        
        users[referrerID].x6Matrix[level].firstLevelReferralsID = new uint32[](0);
        users[referrerID].x6Matrix[level].secondLevelReferralsID = new uint32[](0);
        users[referrerID].x6Matrix[level].closedPart = 0;

        if (users[referrerID].activeX6Levels < (level+uint8(1)) && level != LAST_LEVEL) {
            users[referrerID].x6Matrix[level].blocked = true;
        }

        users[referrerID].x6Matrix[level].reinvestCount++;
        
        if (referrerID >1) {
            uint32 freeReferrerID = findFreeX6Referrer(referrerID, level);

            emit Reinvest(referrerID, freeReferrerID, userID, 2, level);
            updateX6Referrer(referrerID, freeReferrerID, level);
        } else {
            emit Reinvest(1, 0, userID, 2, level);
            sendETHDividends(1, userID, 2, level);
        }
    }
    
    function findFreeX3Referrer(uint32 userID, uint8 level) public view returns(uint32) {
        while (true) {
            if (users[users[userID].referrerID].activeX3Levels>=level) {
                return users[userID].referrerID;
            }
            
            userID = users[userID].referrerID;
        }
    }
    
    function findFreeX6Referrer(uint32 userID, uint8 level) public view returns(uint32) {
        while (true) {
            if (users[users[userID].referrerID].activeX6Levels>=level) {
                return users[userID].referrerID;
            }
            
            userID = users[userID].referrerID;
        }
    }
        
    function usersActiveX3Levels(uint32 userID, uint8 level) external view returns(bool) {
        return users[userID].activeX3Levels>=level;
    }

    function usersActiveX6Levels(uint32 userID, uint8 level) external view returns(bool) {
        return users[userID].activeX6Levels>=level;
    }

    function usersX3Matrix(uint32 userID, uint8 level) external view returns(uint32, uint32[] memory, bool, uint32) {
        return (users[userID].x3Matrix[level].currentReferrerID,
                users[userID].x3Matrix[level].referralsID,
                users[userID].x3Matrix[level].blocked,users[userID].x3Matrix[level].reinvestCount);
    }

    function usersX6Matrix(uint32 userID, uint8 level) external view returns(uint32, uint32[] memory, uint32[] memory, bool, uint32, uint32) {
        return (users[userID].x6Matrix[level].currentReferrerID,
                users[userID].x6Matrix[level].firstLevelReferralsID,
                users[userID].x6Matrix[level].secondLevelReferralsID,
                users[userID].x6Matrix[level].blocked,
                users[userID].x6Matrix[level].closedPart,
                users[userID].x6Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (AddressToId[user] != 0);
    }

    function findEthReceiver(uint32 userID, uint32 _fromID, uint8 matrix, uint8 level) private returns(uint32, bool) {
        uint32 receiver = userID;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _fromID, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrerID;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _fromID, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrerID;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function getCurrentDay() public view returns (uint32) {
        return uint32(block.number.sub(startBlock).div(blocksInFreezingDay));
    }

    function getReward() external {
        require(
            isUserExists(msg.sender),
            "user is not exists. Register first."
        );
        uint32 userID=AddressToId[msg.sender];
        (uint256 reward_amount,uint32 day) = calculateReward(userID);
        require(
            reward_amount>0,
            "The current available reward is zero."
        );

        if (reward_amount > everToken.balanceOf(address(this))) {
            reward_amount = everToken.balanceOf(address(this));
        }
        if (reward_amount > pendingReward[userID].totalAmount) {
            reward_amount = pendingReward[userID].totalAmount;
        }
        if (reward_amount > 0) {
            pendingReward[userID].lastWithdraw=day;          
            pendingReward[userID].totalAmount=pendingReward[userID].totalAmount.sub(reward_amount);
            everToken.transfer(address(msg.sender), reward_amount);
            emit SentEverReward(day,userID,reward_amount);           
        }      
    }

    function calculateReward(uint32 userID)
        public
        view
        returns (uint256,uint32)
    {
        uint256 reward = 0;
        uint32 currentDay=getCurrentDay();
        uint32 upToDay=(currentDay > TOTAL_FREEZING_DAYS ? (currentDay-TOTAL_FREEZING_DAYS):0);

        if(userID<lastUserId){//user exist       
            uint32 i = pendingReward[userID].lastWithdraw;
        
            if (pendingReward[userID].totalAmount > 0 && upToDay > i) {                    
                for (i; i < upToDay; i++) {
                    reward = reward.add(pendingReward[userID].dayReward[i]);
                }
            }
        }
        return (reward,upToDay);
    }

    function sendETHDividends(uint32 userID, uint32 _fromID, uint8 matrix, uint8 level) private {
        //uint32 memory referrerID=AddressToId[referrerAddress];
        (uint32 receiverID, bool isExtraDividends) = findEthReceiver(userID, _fromID, matrix, level);
        uint32 day=getCurrentDay();

        uint256 amountTRX=levelPrice[level].div(10);
        uint256 amountTRXforUser=levelPrice[level].sub(amountTRX);        
        stakePool.chargePool.value(amountTRX)();     
        //(bool success, ) = address(stakePool).call.value(amountTRX)("");
        //require(success, "Address: unable to send value, recipient may have reverted");
        uint256 amountEver = everToken.getTokensNeededToBuy(amountTRX);
        uint256 multiplier=1;
        if(day<14){
            multiplier=4;
        }else if(day<28){
            multiplier=3;
        }else if(day<42){
            multiplier=2;
        }
        if(amountEver>0){
            uint256 amountForUser=amountEver.div(2).mul(multiplier).add(amountEver.mul(level).div(40));
            everToken.mintReward(amountForUser);
            pendingReward[receiverID].dayReward[day]=pendingReward[receiverID].dayReward[day].add(amountForUser);
            pendingReward[receiverID].totalAmount=pendingReward[receiverID].totalAmount.add(amountForUser);
            emit SentEver(receiverID,amountForUser, matrix, level);
        }

        if (!address(uint160(users[receiverID].userAddress)).send(amountTRXforUser)) {
            address(uint160(matrixesRoot)).transfer(address(this).balance);
            return;
        }
        
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_fromID, receiverID, amountTRXforUser, matrix, level);
        }else{
            emit SentEthDividends(_fromID, receiverID, amountTRXforUser, matrix, level);
        }
    }
    
}