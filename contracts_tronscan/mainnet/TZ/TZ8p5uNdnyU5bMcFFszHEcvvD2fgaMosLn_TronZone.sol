//SourceUnit: TronZone.sol

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
contract TronZone {
    using SafeMath for *;
    
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint    deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint checkpoint;
        uint256 return_package;
    }
    
    address public implementation;
    address payable public owner;
    address public deployer;
    address payable public admin_fee1;
    address payable public admin_fee2;

    mapping(address => User) public users;

    uint8[] public ref_bonuses;  
    uint8[] public levelIncome;

    uint8[] public pool_bonuses;
    uint    public pool_last_draw = now;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_self_sum;
    mapping(uint8 => address) public pool_top_investor;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public contract_return_step = 100000000000;
    uint256 public PERCENTS_DIVIDER = 10000;
    uint256 public TIME_STEP = 1 days;
    uint256 public base_return = 100;
    uint256 public max_return = 1500;
    uint256 public max_income = 3;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    
    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    constructor(address payable _owner, address payable _admin_fee1, address payable _admin_fee2) public {
        owner = _owner;
        deployer = msg.sender;
        
        admin_fee1 = _admin_fee1;
        admin_fee2 = _admin_fee2;
        
        levelIncome.push(8);
        levelIncome.push(4);
        levelIncome.push(3);
        levelIncome.push(2);
        levelIncome.push(1);
        levelIncome.push(1);
        levelIncome.push(1);
        levelIncome.push(1);
        levelIncome.push(1);
        levelIncome.push(1);

        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(1);

        pool_bonuses.push(100);
    }
    

    function() payable external {
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

    function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        return _amount * max_income;
    }
    function getUserDailyContractIncomePercentage(address _addr) view external returns(uint256) {
        
        uint256 contractReturn = this.getDailyContractIncomePercentage(address(this).balance);
        
        if(contractReturn == max_return) {
            return max_return;
        }
        else {
            if(contractReturn.add(users[_addr].return_package) > max_return) {
                return max_return;
            }
            else {
                return contractReturn.add(users[_addr].return_package);
            }
            
        }
    }
    function getDailyContractIncomePercentage(uint256 contractBalance) view external returns(uint256) {
        
        uint256 contractReturn = 0;
        
        if(contractBalance >= contract_return_step) {
            contractReturn = (contractBalance.div(contract_return_step)).mul(5);
        }
        
        if(base_return.add(contractReturn) > max_return) {
            return max_return;
        }
        else {
            return base_return.add(contractReturn);
        }
        
    }
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            uint256 userReturnRate = this.getUserDailyContractIncomePercentage(_addr);
            
            payout = (users[_addr].deposit_amount.mul(userReturnRate).div(PERCENTS_DIVIDER))
						.mul(now.sub(users[_addr].checkpoint))
						.div(TIME_STEP);
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;

        if(pool_last_draw + 1 days >= now) {
            uint temp = pool_last_draw + 1 days;
            remainingTimeForPayout = temp.sub(now);
        }
        return remainingTimeForPayout;
    }
    
    function userInfo(address _addr) view external returns(address upline, uint deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_self_sum[pool_cycle][pool_top_investor[0]]);
    }

    function poolTopInvestorInfo() view external returns(address[1] memory addrs, uint256[1] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top_investor[i] == address(0)) break;

            addrs[i] = pool_top_investor[i];
            deps[i] = pool_users_refs_self_sum[pool_cycle][pool_top_investor[i]];
        }
    }
}