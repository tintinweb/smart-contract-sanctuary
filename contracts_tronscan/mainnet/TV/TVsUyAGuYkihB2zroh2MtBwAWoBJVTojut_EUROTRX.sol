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
        mapping(uint256 => POOL) Pool;
        mapping(uint256 => bool) activeStaking;
    }

    struct MATRIX {
        address payable currentReferrer;
        uint downLineCount;
        address payable[] referrals;
    }
    struct POOL {
        uint shares;
        bool is_in_pool;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only Deployer");
        _;
    }
 
    uint maxDownLimit = 2;

    address public implementation;

    uint public lastIDCount = 0;
    uint public LAST_LEVEL = 9;
    
    uint public pool_count = 1;
    uint public poolTime = 24 hours;
    uint public nextClosingTime = now + poolTime;
    uint public deployerValidation = now + 48 hours;

    mapping(uint256 => address payable[] ) public pool_users;
    mapping(uint256 => uint256) public pool_amount;
    mapping(uint256 => uint256) public total_shares;

    address[] public trxPoolUsers;
    address[] public euroTrxPoolUsers;

    mapping(address => USER) public users;
    mapping(uint256 => uint256) public LevelPrice;
    mapping(uint256 => uint256) public stakingLevelPrice;
    
    uint256 public trxPoolAmount = 0;
    uint256 public euroTrxPoolAmount = 0;
    
    uint public marketingShare = 15;
    uint public incentivesShare = 75;
    uint public companyShare = 8;
    uint public stakingShare = 30;
    
    uint public marketingStakingShare = 5;
    uint public incentivesStakingShare = 5;
    uint public companyStakingShare = 8;
    uint public stakingStakingShare = 80;
    
    mapping(uint256 => uint256) public LevelIncome;

    event Registration(address userAddress, uint256 accountId, uint256 refId);
    event NewUserPlace(uint256 accountId, uint256 refId, uint place, uint level);
    
    event Direct(uint256 accountId, uint256 from_id, uint8 level, uint256 amount);
    event Level(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    event LevelStaking(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    event Matrix(uint256 accountId, uint256 from_id, uint8 level, uint networkLevel, uint256 amount);
    
    event PoolEnterTrx(uint256 accountId, uint256 time);
    event PoolEnterEuroTrx(uint256 accountId, uint256 time);
    
    event PoolTrxIncome(uint256 accountId, uint256 amount);
    event PoolEuroTrxIncome(uint256 accountId, uint256 amount);

    event PoolAmountTrx(uint256 amount);
    event PoolAmountEuroTrx(uint256 amount);
    
    event PoolEnter(uint256 accountId, uint now, uint pool_id);
    event ShareAdded(uint256 accountId,uint8 level, uint shares);
    event NewStakingPackageStandard(uint256 accountId, uint level, uint time);
    
    address public deployer;
    address payable public pool;
    address payable public owner;
    
    address payable company;
    address payable public marketing;
    address payable public incentives;
    address payable public staking;
    
    address payable public marketingStaking;
    address payable public incentivesStaking;
    address payable companyStaking;
    address payable public staking2;

    mapping(uint256 => address payable) public userAddressByID;

    constructor(address payable owneraddress,
    address payable _marketing, 
    address payable _company, 
    address payable _incentives, 
    address payable _pool, 
    address payable _staking,
    address payable _company2, 
    address payable _incentives2, 
    address payable _marketing2, 
    address payable _staking2)
        public
    {
        owner = owneraddress;
        pool = _pool;
        
        marketing = _marketing;
        company = _company;
        incentives = _incentives;
        staking = _staking;
        
        marketingStaking = _marketing2;
        companyStaking = _company2;
        incentivesStaking = _incentives2;
        staking2 = _staking2;

        deployer = msg.sender;

        LevelPrice[1] =  1250000000;
        stakingLevelPrice[1] = 12500000000;

        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            LevelPrice[i] = LevelPrice[i-1] * 2;
            stakingLevelPrice[i] = stakingLevelPrice[i - 1] * 2;
        }  

        LevelIncome[1] = 15;
        LevelIncome[2] = 5;
        LevelIncome[3] = 3;
        LevelIncome[4] = 2;
        LevelIncome[5] = 2;
        LevelIncome[6] = 1;
        LevelIncome[7] = 1;
        LevelIncome[8] = 1;
        LevelIncome[9] = 1;
        LevelIncome[10] = 1;
        LevelIncome[11] = 1;
        LevelIncome[12] = 1;
        LevelIncome[13] = 1;
        LevelIncome[14] = 2;
        LevelIncome[15] = 3;


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

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function upgradeTo(address _newImplementation) 
        external onlyDeployer 
    {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
    function getPendingTimeForNextClosing() public view returns(uint) {
        uint remainingTimeForPayout = 0;
        if(nextClosingTime >= now) {
            remainingTimeForPayout = nextClosingTime.sub(now);
        }
        return remainingTimeForPayout;
    }
    function getUserMatrix(address user, uint8 _level) public view returns (address payable referrer, address payable[] memory referrals, uint downLineCount) {
        return (users[user].Matrix[_level].currentReferrer, users[user].Matrix[_level].referrals, users[user].Matrix[_level].downLineCount);
    }
    function getUserPool(address user, uint8 _level) public view returns (uint shares, bool is_in_pool ) {
        return (users[user].Pool[_level].shares, users[user].Pool[_level].is_in_pool);
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

}