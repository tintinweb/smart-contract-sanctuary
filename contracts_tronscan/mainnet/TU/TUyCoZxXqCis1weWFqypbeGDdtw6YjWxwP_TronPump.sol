//SourceUnit: TronPump.sol

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
contract TronPump {
    using SafeMath for *;

    struct User {
        address payable upline;
        uint256 referrals;
        uint    sameAmountReferrals;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 inv_pool_bonus;
        uint256 match_bonus;
        uint256 payouts;
        uint256 total_deposits;
        uint    last_roi_withdraw;
        mapping(address => ReferralIncome) referralincome;
        Investment[] investments;
    }
    struct Investment {
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint    deposit_time;
        uint    daily_return;
    }

    struct ReferralIncome {
        uint256 firstLevel;
        uint256 secondLevel;
        uint256 thirdLevel;
        uint256 fourthLevel;
        uint256 fifthLevel;
    }

    address public implementation;
    address payable public owner;
    address public deployer;
    address payable public admin_fee;
    address payable public admin_fee2;
    address payable public insurance_pool_user;

    uint payoutPeriod = 24 hours;
    uint poolPeriod = 24 hours;
    uint insurance_pool_per = 1;
    uint base_daily_return = 10;
    uint max_income = 2;

    uint admin_fee1_share = 3;
    uint admin_fee2_share = 3;

    mapping(address => User) public users;

    uint8[] public ref_bonuses;
    uint8[] public pool_bonuses;   

    uint[] public LevelIncome;
    uint   public pool_last_draw = now;
    uint256 public pool_cycle;
    uint256 public pool_balance;

    uint256 public insurance_pool;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_self_sum;
    mapping(uint8 => address) public pool_top;
    mapping(uint8 => address) public pool_top_investor;

    modifier onlyDeployer() {
        require (msg.sender == deployer);
        _;
    }

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount, uint which);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner, address payable _admin_fee, address payable _insurance_pool_user, address payable _admin_fee2) public {
        owner = _owner;
        deployer = msg.sender;

        admin_fee = _admin_fee;
        admin_fee2 = _admin_fee2;
        insurance_pool_user = _insurance_pool_user;
        
        ref_bonuses.push(10);
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

        LevelIncome.push(100);
        LevelIncome.push(20);
        LevelIncome.push(15);
        LevelIncome.push(15);
        LevelIncome.push(10);

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

    /*
        Only external call
    */
    function getDailyReturn(address _addr) view external returns(uint256 payout) {
        
        uint256 dividends;

        for (uint256 i = 0; i < users[msg.sender].investments.length; i++) {
            
            if (users[msg.sender].investments[i].deposit_payouts < users[msg.sender].investments[i].deposit_amount.mul(max_income)) {
                if (users[msg.sender].investments[i].deposit_time > users[msg.sender].last_roi_withdraw) {

					dividends = (users[msg.sender].investments[i].deposit_amount.mul(users[msg.sender].investments[i].daily_return).div(1000))
						.mul(now.sub(users[msg.sender].investments[i].deposit_time))
						.div(payoutPeriod);
				} else {
					dividends = (users[msg.sender].investments[i].deposit_amount.mul(users[msg.sender].investments[i].daily_return).div(1000))
						.mul(now.sub(users[msg.sender].last_roi_withdraw))
						.div(payoutPeriod);
				}
				
				if (users[msg.sender].investments[i].deposit_payouts.add(dividends) > users[msg.sender].investments[i].deposit_amount.mul(2)) {
					dividends = (users[msg.sender].investments[i].deposit_amount.mul(2)).sub(users[msg.sender].investments[i].deposit_payouts);
				}
				
				payout = payout.add(dividends);
				
            }
        }
    }
    function userInfo(address _addr) view external returns(address upline, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 inv_pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus,users[_addr].inv_pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_balance, uint256 _pool_lider, uint256 _pool_investor) {
        return (total_users, total_deposited, total_withdraw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], pool_users_refs_self_sum[pool_cycle][pool_top_investor[0]]);
    }
    function getRefferalIncome(address _addr) view external returns(uint256[5] memory income) {
          income[0] = users[_addr].referralincome[_addr].firstLevel;
          income[1] = users[_addr].referralincome[_addr].secondLevel;
          income[2] = users[_addr].referralincome[_addr].thirdLevel;
          income[3] = users[_addr].referralincome[_addr].fourthLevel;
          income[4] = users[_addr].referralincome[_addr].fifthLevel;
    }
    function getInvesments(address _addr) view external returns(uint256[] memory, uint256[] memory, uint[] memory, uint[] memory) {
        uint256[] memory deposit_amount_i = new uint256[] (users[_addr].investments.length);
        uint256[] memory deposit_payouts_i = new uint256[] (users[_addr].investments.length);
        uint[] memory deposit_time_i = new uint256[] (users[_addr].investments.length);
        uint[] memory daily_return_i = new uint256[] (users[_addr].investments.length);

        for(uint8 i = 0; i < users[_addr].investments.length; i++) {
            deposit_amount_i[i] = users[_addr].investments[i].deposit_amount;
            deposit_payouts_i[i] = users[_addr].investments[i].deposit_payouts;
            deposit_time_i[i] = users[_addr].investments[i].deposit_time;
            daily_return_i[i] = users[_addr].investments[i].daily_return;
        }

        return(deposit_amount_i, deposit_payouts_i, deposit_time_i, daily_return_i);
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
            if(pool_top_investor[i] == address(0)) break;

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
}