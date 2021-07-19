//SourceUnit: FTRX.sol

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract FTRX {
    using SafeMath for uint256;

    struct USER {
        bool joined;
    
        uint id;
      
        address payable upline;
   
        address payable umbreline;
        uint personalCount;
        uint poolAchiever;
        bool is_trx_pool;
        bool is_ftrx_trx_pool;
        uint256 originalReferrer;
        mapping(uint8 => bool) activeLevel;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only Deployer");
        _;
    }

    uint maxDownLimit = 2;

    uint public lastIDCount = 9999;
    uint public LAST_LEVEL = 9;
    uint public DIAMOND_LEVEL = 6;
    
    uint public poolTime = 24 hours;
    uint public nextClosingTime = now + poolTime;
    uint public deployerValidation = now + 24 hours;

    address[] public trxPoolUsers;
    address[] public ftrxTrxPoolUsers;

    mapping(address => USER) public users;
    mapping(address => address payable[]) public downlines;
    mapping(uint256 => uint256) public LevelPrice;
    
    uint256 public trxPoolAmount = 0;
    uint256 public ftrxTrxPoolAmount = 0;
    
    uint public DirectIncomeShare = 34;
    uint public MatrixIncomeShare = 1;
    uint public OverRideShare = 3;
    uint public OtherOverRideShare = 3;
    uint public CompanyShare = 9;
    uint public DiamondShare = 1;

    uint lastDiamondTime = 0;
    uint public diamondReward = 0;

    uint public zs_offset;
    uint public zs_limit;

    address payable[] public diamondUsers;
    
    mapping(uint256 => uint256) public LevelIncome;

    event Registration(address userAddress, uint256 accountId, uint256 refId);
    event NewUserPlace(uint256 accountId, uint256 refId, uint place, uint level);
    
    event Direct(uint256 accountId, uint256 from_id, uint8 level, uint256 amount);
    event Level(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    event Matrix(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    
    event PoolEnterTrx(uint256 accountId, uint256 time);
    event PoolEnterftrxTrx(uint256 accountId, uint256 time);
    
    event PoolTrxIncome(uint256 accountId, uint256 amount);
    event PoolftrxTrxIncome(uint256 accountId, uint256 amount);

    event PoolAmountTrx(uint256 amount);
    event PoolAmountftrxTrx(uint256 amount);

    event diamondIncome(uint256 accountId, uint256 amount);

    address public deployer;

    address payable Company;
    address payable public owner;
    address payable public overRide;
    address payable public otherOverRide;

    mapping(uint256 => address payable) public userAddressByID;

    constructor(address payable owneraddress, address payable _overRide, address payable _company, address payable _otherOverRide)
        public
    {
        owner = owneraddress;
        overRide = _overRide;
        Company = _company;
        otherOverRide = _otherOverRide;

        deployer = msg.sender;

        LevelPrice[1] =  1250000000;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            LevelPrice[i] = LevelPrice[i-1] * 2;
        }  

        LevelIncome[1] = 16;
        LevelIncome[2] = 2;
        LevelIncome[3] = 1;
        LevelIncome[4] = 1;
        LevelIncome[5] = 1;
        LevelIncome[6] = 1;
        LevelIncome[7] = 1;
        LevelIncome[8] = 1;
        LevelIncome[9] = 1;
		LevelIncome[10] = 1;
		LevelIncome[11] = 1;
		LevelIncome[12] = 1;
		LevelIncome[13] = 1;
		LevelIncome[14] = 1;
		LevelIncome[15] = 2;
        USER memory user;
        lastIDCount++;

        user = USER({
            joined: true, 
            id: lastIDCount, 
            originalReferrer: 1, 
            personalCount : 0, 
            upline:address(0),
            umbreline: address(0),
            poolAchiever : 0, 
            is_trx_pool : false, 
            is_ftrx_trx_pool :false
        });

        users[owneraddress] = user;
        userAddressByID[lastIDCount] = owneraddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[owneraddress].activeLevel[i] = true;
        }

        trxPoolUsers.push(owneraddress);
		ftrxTrxPoolUsers.push(owneraddress);
        users[owneraddress].is_trx_pool = true;

        diamondUsers.push(owneraddress);
    }
    function regUserDeployer(address payable userAddress, uint256 _referrerID) external onlyDeployer {
        //this function is to rebind the users of old contract which is enabled only for first 24 hours only
        require(deployerValidation > now, "This function is disabled!!!");
        regUserInternal(userAddress, _referrerID);
    }
    function regUser(uint256 _referrerID) external payable {
        require(msg.value == LevelPrice[1], "Incorrect Value");
        regUserInternal(msg.sender, _referrerID);
    }

    function regUserInternal(address payable userAddress, uint256 _referrerID) internal {
        
        uint256 originalReferrer = _referrerID;
        uint8 _level = 1;

        require(!users[userAddress].joined, "User exist");
        require(_referrerID > 9999 && _referrerID <= lastIDCount,"Incorrect referrer Id");
        
        users[userAddressByID[originalReferrer]].personalCount++;
        
        USER memory UserInfo;

        lastIDCount++;

        UserInfo = USER({
            joined: true,
            id: lastIDCount,
            upline : userAddressByID[originalReferrer],
            umbreline: address(0),
            originalReferrer: originalReferrer,
            personalCount:0,
            poolAchiever : 0,
            is_trx_pool : false, 
            is_ftrx_trx_pool :false
            //maxMatrixLevel: 1
        });

        users[userAddress] = UserInfo;

        userAddressByID[lastIDCount] = userAddress;

        buildUmbre(userAddressByID[originalReferrer], userAddress);

        emit Registration(userAddress, lastIDCount, originalReferrer);
        
        users[userAddress].activeLevel[_level] = true;
        
        if(msg.sender != deployer){
            trxPoolAmount += LevelPrice[_level] / 100 * 4;
            emit PoolAmountTrx(LevelPrice[_level] / 100 * 4);
            
            ftrxTrxPoolAmount += LevelPrice[_level] / 100 * 5;
            emit PoolAmountftrxTrx(LevelPrice[_level] / 100 * 5);

            diamondReward += LevelPrice[_level] / 100 * DiamondShare;
            
            Company.transfer(LevelPrice[_level] * CompanyShare / 100);
            overRide.transfer(LevelPrice[_level] * OverRideShare / 100);
            otherOverRide.transfer(LevelPrice[_level] * OtherOverRideShare / 100);
        }
            
        distributeDirectIncome(userAddress, _level);
        levelIncomeDistribution(userAddress, _level);
        matrixIncomeDistribution(userAddress, _level);
    }

    function buyLevelDeployer(address payable userAddress, uint8 _level) external onlyDeployer {
        //this function is to rebind the users of old contract which is enabled only for first 24 hours only
        require(deployerValidation > now, "This function is disabled!!!");
        buyLevelInternal(userAddress, _level);
    }

    function buyLevel(uint8 _level) public payable {
        require(msg.value == LevelPrice[_level], "Incorrect Value");
        buyLevelInternal(msg.sender, _level);
    }

    function buyLevelInternal(address payable userAddress, uint8 _level) internal {
        
        require(users[userAddress].joined, "User Not");
        
        require(_level > 1 && _level <= LAST_LEVEL, "Incorrect Level");
        require(!users[userAddress].activeLevel[_level], "Already active");
        require(users[userAddress].activeLevel[_level - 1], "Previous Level");
        
        users[userAddress].activeLevel[_level] = true;

        if(_level == DIAMOND_LEVEL) {
            diamondUsers.push(userAddress);
        }
        
        if(msg.sender != deployer) {
            trxPoolAmount += LevelPrice[_level] / 100 * 4;
            emit PoolAmountTrx(LevelPrice[_level] / 100 * 4);
            
            ftrxTrxPoolAmount += LevelPrice[_level] / 100 * 5;
            emit PoolAmountftrxTrx(LevelPrice[_level] / 100 * 5);

            diamondReward += LevelPrice[_level] / 100 * DiamondShare;
            
            Company.transfer(LevelPrice[_level] * CompanyShare / 100);
            overRide.transfer(LevelPrice[_level] * OverRideShare / 100);
            otherOverRide.transfer(LevelPrice[_level] * OtherOverRideShare / 100);
        }
        
        distributeDirectIncome(userAddress, _level);
        levelIncomeDistribution(userAddress, _level);
        matrixIncomeDistribution(userAddress, _level);

        if(_level == LAST_LEVEL) {
            
            emit PoolEnterTrx(users[userAddress].id, now);
            users[userAddress].is_trx_pool = true;
            trxPoolUsers.push(userAddress);
            users[users[userAddress].upline].poolAchiever++;
             
            if(users[users[userAddress].upline].is_ftrx_trx_pool == false) {
                if(users[users[userAddress].upline].poolAchiever >= 2 && users[users[userAddress].upline].is_trx_pool == true){
                    emit PoolEnterftrxTrx(users[userAddress].originalReferrer, now);
                    users[users[userAddress].upline].is_ftrx_trx_pool = true;
                    ftrxTrxPoolUsers.push(users[userAddress].upline);
                }
            }
            
            if(users[userAddress].is_ftrx_trx_pool == false) {
                if(users[userAddress].poolAchiever >= 2) {
                    emit PoolEnterftrxTrx(users[userAddress].originalReferrer, now);
                    users[userAddress].is_ftrx_trx_pool = true;
                    ftrxTrxPoolUsers.push(userAddress);
                }
            }
        }
    }
    

    function distributeDirectIncome(address _user, uint8 _level) internal {
        
        uint256 income = LevelPrice[_level] * DirectIncomeShare / 100;
        
        if(users[_user].upline != address(0)) {
                emit Direct(users[_user].originalReferrer,users[_user].id, _level, income);
                if(msg.sender != deployer){
                    (users[_user].upline).transfer(income);
                }
        }
    }


    function levelIncomeDistribution(address _user, uint8 _level) internal {
        address payable _upline = users[_user].upline;
        
        for(uint8 i = 1; i <= 15; i++) {
            
            uint256 income = LevelPrice[_level] * LevelIncome[i] / 100;
            
            if(_upline != address(0)) {
                
                emit Level(users[_upline].id, users[_user].id, _level, i, income);
                if(msg.sender != deployer){
                    if(!address(uint160(_upline)).send(income)) {
                        address(uint160(_upline)).transfer(income);
                    }
                }
                
                _upline = users[_upline].upline;
            }
            else {
                if(msg.sender != deployer){
                    trxPoolAmount += income / 2;
                    emit PoolAmountTrx(income / 2);
                    
                    ftrxTrxPoolAmount += income / 2;
                    emit PoolAmountftrxTrx(income / 2);
                }
            }
        }
    }


    function matrixIncomeDistribution(address payable _user, uint8 _level) internal {
        address payable _umbreline = users[_user].umbreline;
        
        for(uint8 i = 1; i <= 9; i++) {
            
            uint256 income = LevelPrice[_level] * MatrixIncomeShare / 100;
            
            if(_umbreline != address(0)) {
                
                if(users[_umbreline].activeLevel[_level] == true) {
                    
                    emit Matrix(users[_umbreline].id, users[_user].id, _level, i, income);
                    if(msg.sender != deployer){
                        if(!address(uint160(_umbreline)).send(income)) {
                            address(uint160(_umbreline)).transfer(income);
                        }
                    }
                }
                else {
                    if(msg.sender != deployer){
                        trxPoolAmount += income / 2;
                        emit PoolAmountTrx(income / 2);
                        
                        ftrxTrxPoolAmount += income / 2;
                        emit PoolAmountftrxTrx(income / 2);
                    }
                }
                
                _umbreline = users[_umbreline].umbreline;
            }
            else {
                if(msg.sender != deployer){
                    trxPoolAmount += income / 2;
                    emit PoolAmountTrx(income / 2);
                    
                    ftrxTrxPoolAmount += income / 2;
                    emit PoolAmountftrxTrx(income / 2);
                }
            }
        }
    }
    

    function poolClosing(uint pool) public onlyDeployer {
        require(now > nextClosingTime, "Closing Time not came yet!!!");

        if(now > nextClosingTime){
            if(pool == 1) {
                if(trxPoolAmount > 0) {
                    
                    uint256 perUserAmount = trxPoolAmount / trxPoolUsers.length;
                    
                    for(uint i = 0; i < trxPoolUsers.length; i++) {
                        
                        address userAddress = trxPoolUsers[i];
                        
                        emit PoolTrxIncome(users[userAddress].id, perUserAmount);
                        
                        if(!address(uint160(userAddress)).send(perUserAmount)){
                            return address(uint160(userAddress)).transfer(perUserAmount);
                        }
                    }

                    trxPoolAmount = 0;
                }
            }
            if(pool == 2) {
                if(ftrxTrxPoolAmount > 0) {

                    uint256 perUserAmount = ftrxTrxPoolAmount / ftrxTrxPoolUsers.length;
                    
                    for(uint i = 0; i < ftrxTrxPoolUsers.length; i++) {
                        
                        address userAddress = ftrxTrxPoolUsers[i];
                        
                        emit PoolftrxTrxIncome(users[userAddress].id, perUserAmount);
                        
                        if(!address(uint160(userAddress)).send(perUserAmount)){
                            return address(uint160(userAddress)).transfer(perUserAmount);
                        }
                    }

                    ftrxTrxPoolAmount = 0;
                }
                nextClosingTime = now.add(poolTime);
            }
        }
    }


    function putDiamond(uint _offset, uint _limit, bool _clear) public onlyDeployer {
        zs_offset = _offset;
        zs_limit = _limit;
        uint256 perUserAmount = diamondReward / diamondUsers.length;
        for(uint i = zs_limit * zs_offset; i < diamondUsers.length && i < zs_offset * (zs_limit + 1); i++) {
                        
            address userAddress = diamondUsers[i];
            
            emit diamondIncome(users[userAddress].id, perUserAmount);
            
            if(!address(uint160(userAddress)).send(perUserAmount)){
                return address(uint160(userAddress)).transfer(perUserAmount);
            }
        }
        lastDiamondTime = now;
        if(_clear) {
            zs_offset = 0;
            zs_limit = 0;
            diamondReward = 0;
        }
    }

    function getPages() public view returns(uint, uint, uint) {
        return (zs_offset, zs_limit, diamondUsers.length);
    }



    function buildUmbre(address payable _up, address payable _down) internal {
        address payable target = findUmbrella(_up);

        users[_down].umbreline = target;
        if(target != address(0)) {
            downlines[target].push(_down);
        }
    }


    function findUmbrella(address payable _up) internal view returns(address payable) {
        address payable[] memory tmps = new address payable[](1024);
        uint a = 0;
        uint b = 1;
        tmps[0] = _up;
        while(true) {
            if (a == b) {
                return address(0);
            }
           
            if(downlines[tmps[a]].length < 2) {
                return tmps[a];
            } 

            if(downlines[tmps[a]].length > 0) {
                for(uint k = 0; k < downlines[tmps[a]].length; k++) {
                    if(b < 1024) {
                        tmps[b] = downlines[tmps[a]][k];
                        b++;
                    }
                }
            }
            
            a++;
             
        }
    }

    function getPendingTimeForNextClosing() public view returns(uint) {
        uint remainingTimeForPayout = 0;
        if(nextClosingTime >= now) {
            remainingTimeForPayout = nextClosingTime.sub(now);
        }
        return remainingTimeForPayout;
    }

    function importUser(address payable _user, uint _id, uint _referrerID, address payable _upline, uint _personalCount, uint _poolAchiever,
        bool _is_trx_pool, bool _is_ftrx_trx_pool, uint8 _maxLevel) public onlyDeployer {

        USER memory UserInfo;
        lastIDCount = _id;

        UserInfo = USER({
      
            joined: true,
            id: lastIDCount,
            upline : _upline,
            umbreline: address(0),
            originalReferrer: _referrerID,
            personalCount: _personalCount,
            poolAchiever : _poolAchiever,
            is_trx_pool : _is_trx_pool, 
            is_ftrx_trx_pool :_is_ftrx_trx_pool
        });

        users[_user] = UserInfo;

        userAddressByID[lastIDCount] = _user;

        if(_upline != address(0)) {
            buildUmbre(_upline, _user);
        }
        
        for(uint8 i = 1; i <= _maxLevel; i++) {
            users[_user].activeLevel[i] = true;
        }

        if(_maxLevel >= DIAMOND_LEVEL) {
            diamondUsers.push(_user);
        }
    }
}