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

contract EurTrx {
    using SafeMath for *;
    address public implementation;
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
    uint    public LAST_LEVEL = 9;
    
    uint public poolTime = 24 hours;
    uint public nextClosingTime = now + poolTime;

    address[] public trxPoolUsers;
    address[] public euroTrxPoolUsers;

    mapping(address => USER) public users;
    mapping(uint256 => uint256) public LevelPrice;
    
    uint256 public trxPoolAmount = 0;
    uint256 public euroTrxPoolAmount = 0;
    
    uint public DirectIncomeShare = 40;
    uint public MatrixIncomeShare = 1;
    uint public OverRideShare = 3;
    uint public CompanyShare = 10;
    
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

    
    address public deployer;

    address payable Company;
    address payable public owner;
    address payable public overRide;
    address payable public missingLevel;
    address payable public missingPackage;

    mapping(uint256 => address payable) public userAddressByID;

    constructor(address payable owneraddress, address payable _overRide, address payable _company, address payable _missingLevel, address payable _missingPackage)
        public
    {
        owner = owneraddress;
        overRide = _overRide;
        Company = _company;
        missingPackage = _missingPackage;
        missingLevel = _missingLevel;

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
        LevelIncome[6] = 1;
        LevelIncome[7] = 1;
        LevelIncome[8] = 1;
        LevelIncome[9] = 1;

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