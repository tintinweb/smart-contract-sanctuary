//SourceUnit: TrxWorld.sol

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
contract TrxWorld {
    using SafeMath for *;
    
    struct User {
        address upline;
        uint    referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint    deposit_time;
        uint    last_roi_withdraw;
        uint256 total_deposits;
        uint256 total_payouts;
        uint    total_structure;
        uint    minuteRate;
    }
    struct oldUser {
        bool    is_old;
        uint256 allowed_amount;
    }

    uint public part1_fee = 5;   
    uint public part2_fee = 5;   
    uint public part3_fee = 1;   

    address payable public part1;
    address payable public part2;
    address payable public part3;

    address public implementation;
    address payable public owner;
    address public deployer;

    uint payoutPeriod = 24 hours;
    uint poolPeriod = 24 hours;

    mapping(address => User) public users;
    mapping(address => oldUser) public old_user;

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    uint8[] public ref_bonuses;          
    uint8[] public pool_bonuses;      

    uint public pool_last_draw = now;
    uint256 public pool_cycle = 0;
    uint256 public pool_balance;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_self_sum;
    mapping(uint8 => address) public pool_top;
    mapping(uint8 => address) public pool_top_investor;

    uint256 public total_users = 0;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount, uint pool_flag);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner, address payable _part1, address payable _part2, address payable _part3) public {
        owner = _owner;

        part1 = _part1;
        part2 = _part2;
        part3 = _part3;

        deployer = msg.sender;
    
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
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

    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }

    function upgradeTo(address _newImplementation) 
        external onlyDeployer 
    {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    function maxPayoutOf(address userAddress, uint256 _amount) view external returns(uint256) {
        if(old_user[userAddress].is_old) {
            return _amount * 45 / 10;
        }
        else {
            return _amount * 325 / 100;
            
        }
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout, uint256 extraTime) {
        max_payout = this.maxPayoutOf(_addr, users[_addr].deposit_amount);
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;

        if(now > users[_addr].last_roi_withdraw + payoutPeriod && users[_addr].deposit_payouts < max_payout) {

            extraTime = now.sub(users[_addr].last_roi_withdraw);
            uint256 _dailyIncome;

            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);

            currInvestedAmount = users[_addr].deposit_amount;
            
            if(users[_addr].minuteRate == 1) {
                _dailyIncome = currInvestedAmount.div(100);
            }
            if(users[_addr].minuteRate == 2) {
                _dailyIncome = currInvestedAmount.div(8333.div(100));
            }
            if(users[_addr].minuteRate == 3) {
                _dailyIncome = currInvestedAmount.div(7142.div(100));
            }
            if(users[_addr].minuteRate == 4) {
                _dailyIncome = currInvestedAmount.div(625.div(10));
            }
            if(users[_addr].minuteRate == 5) {
                _dailyIncome = currInvestedAmount.div(5555.div(100));
            }
            if(users[_addr].minuteRate == 6) {
                _dailyIncome = currInvestedAmount.div(50);
            }

            payout = _dailyIncome.mul(remainingTimeForPayout);

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function poolTopInvestorInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top_investor[i];
            deps[i] = pool_users_refs_self_sum[pool_cycle][pool_top_investor[i]];
        }
    }

    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;

        if(pool_last_draw + poolPeriod >= now) {
            uint temp = pool_last_draw + poolPeriod;
            remainingTimeForPayout = temp.sub(now);
        }
        return remainingTimeForPayout;
    }
    
    function getNextPayoutCountdown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_roi_withdraw + payoutPeriod >= now) {
                remainingTimeForPayout = (users[_addr].last_roi_withdraw + payoutPeriod).sub(now);
            }
            else {
                uint256 temp = now.sub(users[_addr].last_roi_withdraw);
                remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
            }

            return remainingTimeForPayout;
        }
    }
}