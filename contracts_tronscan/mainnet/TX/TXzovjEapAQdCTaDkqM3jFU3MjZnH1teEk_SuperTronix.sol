//SourceUnit: SuperTronix.sol

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

contract SuperTronix {
    using SafeMath for *;
    address public implementation;
    struct USER {
        uint256 id;
        uint partnersCount;
        uint256 referrer;
        mapping(uint256 => MATRIX) Matrix;
        mapping(uint256 => POOL) Pool;
        mapping(uint256 => bool) activeLevel;
    }
    struct MATRIX {
        address payable currentReferrer;
        address [] referrals;
        uint downLineCount;
        uint reinvestCount;
    }
    struct POOL {
        uint shares;
        bool is_in_pool;
    }

    uint    public pool_count = 1;
    uint    public pool_closing = 1 days;
    uint    public pool_last_closing = now;
    uint256 public maxDownLimit = 5;
    uint256 public lastIDCount = 0;
    uint256 public tronxPoolShare = 10;
    
    
    uint256 public mdPoolShare = 10;
    uint256 public companyPoolShare = 10;
    uint256 public leaderPoolShare = 5;

    uint256 public incomeDivider = 100;
    
    uint    public LAST_LEVEL = 9;
    
    mapping(uint256 => address payable[] ) public pool_users;
    mapping(uint256 => uint256) public pool_amount;
    mapping(uint256 => uint256) public total_shares;
    mapping(address => USER)    public users;
    mapping(uint256 => uint256) public LevelPrice;
    mapping(uint256 => address payable) public FreeIncome;
    mapping(uint256 => uint256) public LevelIncome;

    event Registration(address userAddress, uint256 accountId, uint256 refId);
    event NewUserPlace(uint256 accountId, uint256 refId, uint place, uint level);
    event UnilevelIncome(uint256 accountId, uint256 from, uint level, uint256 amount, uint networkLevel);
    event PoolIncome(uint256 accountId, uint level, uint256 amount, uint time);
    event Reinvest(address userAddress, address indexed caller, uint8 level);
    event PoolEnter(uint256 accountId, uint now, uint pool_id);

    address payable public owner;
    address payable public mdPool;
    address payable public companyPool;
    address payable public leaderPool;
    address payable public freePool;

    address public deployer;

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    mapping(uint256 => address payable) public userAddressByID;

    constructor(
        address payable _mdPool, 
        address payable _companyPool, 
        address payable _leaderPool,
        address payable _free1,
        address payable _free2,
        address payable _free3,
        address payable _free4,
        address payable _freePool
        ) public {

        owner = _companyPool;
        deployer = msg.sender;
        
        mdPool = _mdPool;
        companyPool = _companyPool;
        leaderPool = _leaderPool;
        freePool = _freePool;

        LevelPrice[1] =  1000000000;

        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            LevelPrice[i] = LevelPrice[i-1] * 2;
        }   
        
        FreeIncome[1] = _free1;
        FreeIncome[2] = _free2;
        FreeIncome[3] = _free3;
        FreeIncome[4] = _free4;

        LevelIncome[1] = 50;
        LevelIncome[2] = 7;
        LevelIncome[3] = 4;
        LevelIncome[4] = 2;
        LevelIncome[5] = 2;

        lastIDCount++;

        USER memory user = USER({
            id: lastIDCount,
            referrer: 0,
            partnersCount: uint(0)
        });
        
        users[_companyPool] = user;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_companyPool].activeLevel[i] = true;
        }

        userAddressByID[lastIDCount] = _companyPool;
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
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function getUserMatrix(address user, uint8 _level) public view returns (address payable referrer, address[] memory referrals, uint downLineCount, uint reinvestCount ) {
        return (users[user].Matrix[_level].currentReferrer, users[user].Matrix[_level].referrals, users[user].Matrix[_level].downLineCount, users[user].Matrix[_level].reinvestCount);
    }
    
    function getUserPool(address user, uint8 _level) public view returns (uint shares, bool is_in_pool ) {
        return (users[user].Pool[_level].shares, users[user].Pool[_level].is_in_pool);
    }
    
    function getAllPoolUsers(uint8 _level) public view returns(address payable[] memory all_users) {
        return pool_users[_level];
    }
    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;

        if(pool_last_closing + pool_closing >= now) {
            uint temp = pool_last_closing + pool_closing;
            remainingTimeForPayout = temp.sub(now);
        }
        return remainingTimeForPayout;
    }
}