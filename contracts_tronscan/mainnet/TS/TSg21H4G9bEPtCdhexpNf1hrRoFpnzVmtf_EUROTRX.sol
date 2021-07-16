//SourceUnit: EuroTRX.sol

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

contract EUROTRX {
    using SafeMath for uint256;

    struct USER {
        bool joined;
        uint id;
        address payable upline;
        uint personalCount;
        uint poolAchiever;
        bool is_trx_pool;
        bool is_euro_trx_pool;
        uint256 originalReferrer;
        mapping(uint8 => MATRIX) Matrix;
        mapping(uint8 => bool) activeLevel;
    }

    struct MATRIX {
        address payable currentReferrer;
        address payable[] referrals;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only Deployer");
        _;
    }

    uint maxDownLimit = 2;

    uint public lastIDCount = 0;
    uint public LAST_LEVEL = 9;
    
    uint public poolTime = 24 hours;
    uint public nextClosingTime = now + poolTime;
    uint public deployerValidation = now + 24 hours;

    address[] public trxPoolUsers;
    address[] public euroTrxPoolUsers;

    mapping(address => USER) public users;
    mapping(uint256 => uint256) public LevelPrice;
    
    uint256 public trxPoolAmount = 0;
    uint256 public euroTrxPoolAmount = 0;
    
    uint public DirectIncomeShare = 34;
    uint public MatrixIncomeShare = 1;
    uint public OverRideShare = 3;
    uint public OtherOverRideShare = 3;
    uint public CompanyShare = 9;
    
    mapping(uint256 => uint256) public LevelIncome;

    event Registration(address userAddress, uint256 accountId, uint256 refId);
    event NewUserPlace(uint256 accountId, uint256 refId, uint place, uint level);
    
    event Direct(uint256 accountId, uint256 from_id, uint8 level, uint256 amount);
    event Level(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    event Matrix(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    
    event PoolEnterTrx(uint256 accountId, uint256 time);
    event PoolEnterEuroTrx(uint256 accountId, uint256 time);
    
    event PoolTrxIncome(uint256 accountId, uint256 amount);
    event PoolEuroTrxIncome(uint256 accountId, uint256 amount);

    event PoolAmountTrx(uint256 amount);
    event PoolAmountEuroTrx(uint256 amount);

    

    
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

        LevelIncome[1] = 10;
        LevelIncome[2] = 5;
        LevelIncome[3] = 4;
        LevelIncome[4] = 3;
        LevelIncome[5] = 2;
        LevelIncome[6] = 2;
        LevelIncome[7] = 2;
        LevelIncome[8] = 2;
        LevelIncome[9] = 2;

        USER memory user;
        lastIDCount++;

        user = USER({joined: true, id: lastIDCount, originalReferrer: 1, personalCount : 0, upline:address(0), poolAchiever : 0, is_trx_pool : false, is_euro_trx_pool :false});

        users[owneraddress] = user;
        userAddressByID[lastIDCount] = owneraddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[owneraddress].activeLevel[i] = true;
        }
        
        trxPoolUsers.push(owneraddress);
        users[owneraddress].is_trx_pool = true;
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
        require(_referrerID > 0 && _referrerID <= lastIDCount,"Incorrect referrer Id");
        

        if (users[userAddressByID[_referrerID]].Matrix[_level].referrals.length >=maxDownLimit) {
            _referrerID = users[findFreeReferrer(userAddressByID[_referrerID],_level)].id;
        }
        
        users[userAddressByID[originalReferrer]].personalCount++;
        
        USER memory UserInfo;

        lastIDCount++;

        UserInfo = USER({
            joined: true,
            id: lastIDCount,
            upline : userAddressByID[originalReferrer],
            originalReferrer: originalReferrer,
            personalCount:0,
            poolAchiever : 0,
            is_trx_pool : false, 
            is_euro_trx_pool :false
        });

        users[userAddress] = UserInfo;

        userAddressByID[lastIDCount] = userAddress;

         emit Registration(userAddress, lastIDCount, originalReferrer);

        users[userAddress].Matrix[_level].currentReferrer = userAddressByID[_referrerID];

        users[userAddressByID[_referrerID]].Matrix[_level].referrals.push(userAddress);
        
        emit NewUserPlace(lastIDCount, _referrerID, users[userAddressByID[_referrerID]].Matrix[1].referrals.length, _level);
        
        users[userAddress].activeLevel[_level] = true;
        
        if(msg.sender != deployer){
            trxPoolAmount += LevelPrice[_level] / 20;
            emit PoolAmountTrx(LevelPrice[_level] / 20);
            
            euroTrxPoolAmount += LevelPrice[_level] / 20;
            emit PoolAmountEuroTrx(LevelPrice[_level] / 20);
            
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
        
        uint256 _referrerID = findFreeActiveReferrer(userAddress, _level);
        
        if (users[userAddressByID[_referrerID]].Matrix[_level].referrals.length >=maxDownLimit) {
            _referrerID = users[findFreeReferrer(userAddressByID[_referrerID],_level)].id;
        }
        
        users[userAddress].Matrix[_level].currentReferrer = userAddressByID[_referrerID];

        users[userAddressByID[_referrerID]].Matrix[_level].referrals.push(userAddress);

        emit NewUserPlace(users[userAddress].id, _referrerID, users[userAddressByID[_referrerID]].Matrix[_level].referrals.length, _level);

        users[userAddress].activeLevel[_level] = true;
        
        if(msg.sender != deployer) {
            trxPoolAmount += LevelPrice[_level] / 20;
            emit PoolAmountTrx(LevelPrice[_level] / 20);
            
            euroTrxPoolAmount += LevelPrice[_level] / 20;
            emit PoolAmountEuroTrx(LevelPrice[_level] / 20);
            
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
             
            if(users[users[userAddress].upline].is_euro_trx_pool == false) {
                if(users[users[userAddress].upline].poolAchiever >= 2 && users[users[userAddress].upline].is_trx_pool == true){
                    emit PoolEnterEuroTrx(users[userAddress].originalReferrer, now);
                    users[users[userAddress].upline].is_euro_trx_pool = true;
                    euroTrxPoolUsers.push(users[userAddress].upline);
                }
            }
            
            if(users[userAddress].is_euro_trx_pool == false) {
                if(users[userAddress].poolAchiever >= 2) {
                    emit PoolEnterEuroTrx(users[userAddress].originalReferrer, now);
                    users[userAddress].is_euro_trx_pool = true;
                    euroTrxPoolUsers.push(userAddress);
                }
            }
        }
    }
    
    function distributeDirectIncome(address _user, uint8 _level) internal {
        
        uint256 income = LevelPrice[_level] * DirectIncomeShare / 100;
        
        if(users[_user].upline != address(0)) {

            if(users[users[_user].upline].activeLevel[_level] == true) {
                emit Direct(users[_user].originalReferrer,users[_user].id, _level, income);
                if(msg.sender != deployer){
                    (users[_user].upline).transfer(income);
                }
                
            }
            else {
                if(msg.sender != deployer){
                    trxPoolAmount += income / 2;
                    emit PoolAmountTrx(income / 2);
                    
                    euroTrxPoolAmount += income / 2;
                    emit PoolAmountEuroTrx(income / 2);
                }
            }
        }
    }
    function levelIncomeDistribution(address _user, uint8 _level) internal {
        address payable _upline = users[_user].upline;
        
        for(uint8 i = 1; i <= 9; i++) {
            
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
                    
                    euroTrxPoolAmount += income / 2;
                    emit PoolAmountEuroTrx(income / 2);
                }
            }
        }
    }
    function matrixIncomeDistribution(address _user, uint8 _level) internal {
        address payable _upline = users[_user].Matrix[_level].currentReferrer;
        
        for(uint8 i = 1; i <= 9; i++) {
            
            uint256 income = LevelPrice[_level] * MatrixIncomeShare / 100;
            
            if(_upline != address(0)) {
                
                if(users[_upline].activeLevel[i] == true) {
                    
                    emit Matrix(users[_upline].id, users[_user].id, _level, i, income);
                    if(msg.sender != deployer){
                        if(!address(uint160(_upline)).send(income)) {
                            address(uint160(_upline)).transfer(income);
                        }
                    }
                }
                else {
                    if(msg.sender != deployer){
                        trxPoolAmount += income / 2;
                        emit PoolAmountTrx(income / 2);
                        
                        euroTrxPoolAmount += income / 2;
                        emit PoolAmountEuroTrx(income / 2);
                    }
                }
                
                _upline = users[_upline].Matrix[_level].currentReferrer;
            }
            else {
                if(msg.sender != deployer){
                    trxPoolAmount += income / 2;
                    emit PoolAmountTrx(income / 2);
                    
                    euroTrxPoolAmount += income / 2;
                    emit PoolAmountEuroTrx(income / 2);
                }
            }
        }
    }
    
    function findFreeActiveReferrer(address userAddress, uint8 level) internal view returns(uint256) {
        while (true) {
            if (users[users[userAddress].upline].activeLevel[level] == true) {
                return users[users[userAddress].upline].id;
            }
            
            userAddress = users[userAddress].upline;
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
                if(euroTrxPoolAmount > 0) {

                    uint256 perUserAmount = euroTrxPoolAmount / euroTrxPoolUsers.length;
                    
                    for(uint i = 0; i < euroTrxPoolUsers.length; i++) {
                        
                        address userAddress = euroTrxPoolUsers[i];
                        
                        emit PoolEuroTrxIncome(users[userAddress].id, perUserAmount);
                        
                        if(!address(uint160(userAddress)).send(perUserAmount)){
                            return address(uint160(userAddress)).transfer(perUserAmount);
                        }
                    }

                    euroTrxPoolAmount = 0;
                }
                nextClosingTime = now.add(poolTime);
            }
        }
    }
    function findFreeReferrer(address _user, uint8 _level) internal view returns(address) {
        if(users[_user].Matrix[_level].referrals.length < maxDownLimit){
            return _user;
        }

        address[] memory referrals = new address[](2046);
        
        referrals[0] = users[_user].Matrix[_level].referrals[0]; 
        referrals[1] = users[_user].Matrix[_level].referrals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i =0; i<2046;i++){
            if(users[referrals[i]].Matrix[_level].referrals.length == maxDownLimit){
                if(i<1022){
                    referrals[(i+1)*2] = users[referrals[i]].Matrix[_level].referrals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].Matrix[_level].referrals[1];
                }
            }else{
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;
    }
    function getMatrix(address userAddress, uint8 level)
        public
        view
        returns (
            address payable,
            address payable[] memory
        )
    {
        return (
            users[userAddress].Matrix[level].currentReferrer,
            users[userAddress].Matrix[level].referrals
        );
    }
    function getPendingTimeForNextClosing() public view returns(uint) {
        uint remainingTimeForPayout = 0;
        if(nextClosingTime >= now) {
            remainingTimeForPayout = nextClosingTime.sub(now);
        }
        return remainingTimeForPayout;
    }

}