//SourceUnit: tronquinn_live.sol

pragma solidity 0.5.14;

interface TRC20 {
    function totalSupply() external view returns(uint256);
    function transfer(address _to, uint256 _value)external returns(bool);
    function approve(address _spender, uint _value)external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value)external returns(bool);
    function allowance(address _owner, address _spender)external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

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
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TronQuin {
    
    using SafeMath for uint256;
    // Investor details
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 directBonus;
        uint256 poolBonus;
        uint256 matchBonus;
        uint256 depositAmount;
        uint256 depositPayouts;
        uint40 depositTime;
        uint256 totalDeposits;
        uint256 totalPayouts;
        uint256 totalStructure;
    }
    
    // Levels minimum and maximum price
    struct level {
        uint min;
        uint max;
    }
    
    // Token instance
    TRC20 public _token;
    
    // Owmer address
    address payable public owner;
    // Platformfee address
    address payable public platformFee;
    // Eclipcityglobal address
    address payable public eclipcityGlobal;
    // Insurance address
    address payable public insurance;
    // Token added status
    bool public _tokenStatus;
    // Contract status
    bool public lockStatus;
     // Total withdraw amount
    uint256 public totalWithdraw;
    // Pool cycle counts
    uint256 public poolCycle;
    // Total deposit amount.
    uint public totalDeposited;
    // Matching bonus percentage
    uint8[] public matchBonuses;
    // Total users count
    uint256 public totalUsers = 1;
    // Pool amount
    uint public poolBalance;
    // Pool percentage
    uint[4] public poolBonuses;
    // matchinge6
    uint[]public matchLimit;
    // Withdraw time
    uint public poollastDraw = block.timestamp;
    // Token percentage
    uint public tokenPercentage = 5e6;
    // Token value
    uint public tokenValue = 200;
    
    // Mapping users details by address
    mapping(address => User) public users;
    // mapping levels by number
    mapping(uint => level)public Levels;
    // Mapping users referalls depsoit amount
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    // Mapping top 4 users
    mapping(uint8 => address) public poolTop;
    // mapping users teaminvest amount
    mapping(address => uint)public teamInvest;
    // Mapping users same level invest count
    mapping(address => mapping(uint => uint))public levelCount;
    
    // Upline commission event
    event Upline(address indexed user, address indexed upline);
    // Direct Commission event
    event DirectPayout(address indexed upline, address indexed user, uint256 value);
    // Matching Commission event
    event MatchPayout(address indexed upline, address indexed user, uint256 value);
    // Withdraw event
    event Withdraw(address indexed user, uint256 value);
    // Limit reach event
    event LimitReached(address indexed user, uint256 value);
    // Admin earnings event
    event AdminEarnings(address indexed user, uint value, uint time);
    // Platformfee event
    event PlatformFee(address indexed user, uint value, uint time);
    // Eclipcityglobal event
    event EclipcityGlobal(address indexed user, uint value, uint time);
    // Insurance event
    event Insurance(address indexed user, uint value, uint time);
    // Insurancecommission event
    event InsuranceCommission(address indexed user, uint value, uint time);
    // Poolpayout event
    event PoolPayout(address indexed user, uint value);
    // Token event
    event AddToken(address indexed owner, uint value, uint time);
    // Deposit event
    event Deposit(address indexed user, address indexed upline, uint value, uint time);
    // Failsafe event
    event FailSafe(address indexed user,uint value,uint time);
    
   

    /**
     * @dev Initializes the contract setting the _owner as the initial owner.
     */
    constructor(address payable _owner, address payable _platform, address payable _eclipcityglopal, address payable _insurance) public {
        owner = _owner;
        platformFee = _platform;
        eclipcityGlobal = _eclipcityglopal;
        insurance = _insurance;
        // Matching commission
        matchBonuses.push(30);
        matchBonuses.push(10);
        matchBonuses.push(10);
        matchBonuses.push(8);
        matchBonuses.push(8);
        matchBonuses.push(6);
        matchBonuses.push(6);
        matchBonuses.push(4);
        matchBonuses.push(4);
        matchBonuses.push(2);
        matchBonuses.push(2);
        matchBonuses.push(2);

        level memory Level;
        Level = level({ min: 500e6,  max: 100000e6 }); 
       
        Levels[1] = Level;

        Level = level({
            min: 100001e6,
            max: 300000e6
        });
        Levels[2] = Level;

        Level = level({
            min: 300001e6,
            max: 700000e6
        });
        Levels[3] = Level;

        Level = level({
            min: 700001e6,
            max: 1000000e6
        });
        Levels[4] = Level;
        
        // Matchinge6
        matchLimit.push(5000e6);
        matchLimit.push(20000e6);
        matchLimit.push(100000e6);
        matchLimit.push(250000e6);
        matchLimit.push(500000e6);
        matchLimit.push(1000000e6);
        matchLimit.push(2000000e6);
        matchLimit.push(4000000e6);
        matchLimit.push(10000000e6);
        matchLimit.push(25000000e6);
        matchLimit.push(25000000e6);
        matchLimit.push(25000000e6);
        
        // Pool bonus percentage
        poolBonuses[0] = 40e6;
        poolBonuses[1] = 30e6;
        poolBonuses[2] = 20e6;
        poolBonuses[3] = 10e6;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "TronQuin: Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "TronQuin: Contract Locked");
        _;
    }
    
    /**
     * @dev Throws if called by other contract
     */
    modifier isContractcheck(address _user) {
        require(!isContract(_user), "TronQuin: Invalid address");
        _;
    }

    /**
     * @dev deposit: User deposit with 500e6
     * Direct bonus 10% for upline
     * User can desposit again after 310% of previous deposit
     * Every deposit pooldeposit will update for top 4 user
     * Every 24hours drawpool function call and send bonus to top 4 users
     * Every deposit user can get free token if its enable
     * @param _upline: Referal address
     * @param _level: To choose a level
     */
    function deposit(address _upline,uint _level)external payable isLock isContractcheck(msg.sender) {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value,_level);
    }

    function _setUpline(address _addr, address _upline)internal{
        if (users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].depositTime > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            totalUsers++;

            for (uint8 i = 0; i < matchBonuses.length; i++) {
                if (_upline == address(0)) break;

                users[_upline].totalStructure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount,uint _level) internal {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if (users[_addr].depositTime > 0) {
            users[_addr].cycle++;
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].depositAmount), "TronQuin: Deposit already exists");
            require(_amount >= Levels[_level].min && _amount <= Levels[_level].max, "TronQuin: Bad amount");
        }
        else {
            require(_amount >= Levels[1].min && _amount <= Levels[1].max, "TronQuin: Bad amount");
        }
        users[_addr].payouts = 0;
        users[_addr].depositAmount = _amount;
        users[_addr].depositPayouts = 0;
        users[_addr].depositTime = uint40(block.timestamp);
        users[_addr].totalDeposits += _amount;
        teamInvest[users[_addr].upline] = teamInvest[users[_addr].upline].add(_amount);
        levelCount[_addr][_level] = levelCount[_addr][_level].add(1);
        totalDeposited = totalDeposited.add(_amount);
        if (users[_addr].upline != address(0)) {
            users[users[_addr].upline].directBonus = users[users[_addr].upline].directBonus.add(_amount.mul(10e6).div(100e6));
            emit DirectPayout(users[_addr].upline, _addr, _amount.mul(10e6).div(100e6));
        }
        _pollDeposits(_addr, _amount);

        if (poollastDraw.add(1 days) < block.timestamp) {
            _drawPool();
        }
        uint commission = _amount.mul(tokenPercentage).div(100e6);
        commission = commission.mul(tokenValue).div(1e6);
        if (_tokenStatus == true && _token.balanceOf(address(this)) >= commission) {
            _token.transfer(_addr, commission); // 10 tokens
        }
        require(address(uint160(platformFee)).send(_amount.mul(5e6).div(100e6)), "TronQuin: Platformfee failed"); // 5% for Platformfee
        emit PlatformFee(platformFee, _amount.mul(5e6).div(100e6), block.timestamp);
        require(address(uint160(eclipcityGlobal)).send(_amount.mul(1e6).div(100e6)), "TronQuin: Eclipcityglobal failed"); // 1% for eclipcityglopal
        emit EclipcityGlobal(eclipcityGlobal, _amount.mul(1e6).div(100e6), block.timestamp);
        require(address(uint160(insurance)).send(_amount.mul(1e6).div(100e6)), "TronQuin: Insurance failed"); // 1% for insurance
        emit Insurance(insurance, _amount.mul(1e6).div(100e6), block.timestamp);
        emit Deposit(_addr,users[_addr].upline,_amount,block.timestamp);
    }

    /**
     * @dev withdraw: User can get amount till maximum payout reach.
     * maximum payout based on(daily ROI, directBonus, poolbonus, matchbonus)
     * maximum payout limit 310 percentage
     */
    function withdraw() external isLock {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(msg.sender != owner, "TronQuin: only users");
        require(users[msg.sender].payouts < max_payout, "TronQuin: Full payouts");
        // Deposit payout
        if (to_payout > 0) {
            if (users[msg.sender].payouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts);
            }
            users[msg.sender].depositPayouts = users[msg.sender].depositPayouts.add(to_payout);
            users[msg.sender].payouts = users[msg.sender].payouts.add(to_payout);
            _matchPayout(msg.sender, to_payout);
        }
        // Direct payout
        if (users[msg.sender].payouts < max_payout && users[msg.sender].directBonus > 0) {
            uint256 direct_bonus = users[msg.sender].directBonus;
            if (users[msg.sender].payouts.add(direct_bonus) > max_payout) {
                direct_bonus = max_payout.sub(users[msg.sender].payouts);
            }
            users[msg.sender].directBonus = users[msg.sender].directBonus.sub(direct_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(direct_bonus);
            to_payout = to_payout.add(direct_bonus);
        }
        // Pool payout
        if (users[msg.sender].payouts < max_payout && users[msg.sender].poolBonus > 0) {
            uint256 pool_bonus = users[msg.sender].poolBonus;
            if (users[msg.sender].payouts.add(pool_bonus) > max_payout) {
                pool_bonus = max_payout.sub(users[msg.sender].payouts);
            }
            users[msg.sender].poolBonus = users[msg.sender].poolBonus.sub(pool_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(pool_bonus);
            to_payout = to_payout.add(pool_bonus);
        }
        // Match payout
        if (users[msg.sender].payouts < max_payout && users[msg.sender].matchBonus > 0) {
            uint256 match_bonus = users[msg.sender].matchBonus;
            uint256 insuranceCommission = match_bonus.mul(10e6).div(100e6);

            if (users[msg.sender].payouts.add(match_bonus) > max_payout) {
                match_bonus = max_payout.sub(users[msg.sender].payouts);
            }
            users[msg.sender].matchBonus = users[msg.sender].matchBonus.sub(match_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(match_bonus.sub(insuranceCommission));
            to_payout = to_payout.add(match_bonus.sub(insuranceCommission));
            require(insurance.send(insuranceCommission), "TronQuin: Insurance transaction failed"); // 10% from matching commission to insurance account
            emit InsuranceCommission(insurance, insuranceCommission, block.timestamp);
        }
        require(to_payout > 0, "TronQuin: Zero payout");
        users[msg.sender].totalPayouts = users[msg.sender].totalPayouts.add(to_payout);
        totalWithdraw = totalWithdraw.add(to_payout);
        require(msg.sender.send(to_payout), "TronQuin: Transfer failed"); // Daily roi, matching bonus, direct bonus, pool bonus
        emit Withdraw(msg.sender, to_payout);
        if (users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    /**
     * @dev adminWithdraw : Admin can withdraw their earnings.
     * 
     */
    function adminWithdraw()public onlyOwner{
        uint amount;
        if (users[owner].directBonus > 0) {
            amount = amount.add(users[owner].directBonus);
            users[owner].directBonus = 0;
        }
        if (users[owner].matchBonus > 0) {
            amount = amount.add(users[owner].matchBonus);
            users[owner].matchBonus = 0;
        }
        if (users[owner].poolBonus > 0) {
            amount = amount.add(users[owner].poolBonus);
            users[owner].poolBonus = 0;
        }
        require(address(uint160(owner)).send(amount), "TronQuin: Admin transaction failed");
        emit AdminEarnings(owner, amount, block.timestamp);
    }

    function _pollDeposits(address _addr, uint256 _amount)internal{
        poolBalance = poolBalance.add(_amount.mul(1e6).div(100e6)); // 1% for pool balance
        address upline = users[_addr].upline;
        if (upline == address(0)) return;
        pool_users_refs_deposits_sum[poolCycle][upline] += _amount;
        for (uint8 i = 0; i < poolBonuses.length; i++) {
            if (poolTop[i] == upline) break; // if top1 == upline
            if (poolTop[i] == address(0)) {
                poolTop[i] = upline;     // if empty push upline
                break;
            }
            if (pool_users_refs_deposits_sum[poolCycle][upline] > pool_users_refs_deposits_sum[poolCycle][poolTop[i]]) {
                for (uint8 j = i + 1; j < poolBonuses.length; j++) {
                    if (poolTop[j] == upline) {
                        for (uint8 k = j; k <= poolBonuses.length; k++) {
                            poolTop[k] = poolTop[k + 1];
                        }
                        break;
                    }
                }
                for (uint8 j = uint8(poolBonuses.length - 1); j > i; j--) {
                    poolTop[j] = poolTop[j - 1];
                }
                poolTop[i] = upline;
                break;
            }
        }
    }

    function _drawPool() private {
        poollastDraw = uint40(block.timestamp);
        poolCycle++;
        uint drawAmount = poolBalance;
        
        for (uint8 i = 0; i < poolBonuses.length; i++) { // Top 4 pool members
            if (poolTop[i] == address(0)) break;

            uint win = drawAmount.mul(poolBonuses[i]).div(100e6);

            users[poolTop[i]].poolBonus = users[poolTop[i]].poolBonus.add(win);
            poolBalance = poolBalance.sub(win);

            emit PoolPayout(poolTop[i], win);
        }

        for (uint8 i = 0; i < poolBonuses.length; i++) { // After pool bonus slots be empty
            poolTop[i] = address(0);
        }
    }


    function _matchPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        uint256 bonus;

        for (uint8 i = 0; i < 12; i++) {
            if (up == address(0)) break;

            if (i < 9) {
                if (users[up].referrals >= i + (3 + i) && teamInvest[up] >= matchLimit[i]) { // For matcing bonus
                    bonus = _amount.mul(matchBonuses[i]).div(100);
                    users[up].matchBonus = users[up].matchBonus.add(bonus);
                    emit MatchPayout(up, _addr, bonus);
                }
            }
            else if (i > 8) {
                if (users[up].referrals >= 25 && teamInvest[up] >= matchLimit[i]) {
                    bonus = _amount.mul(matchBonuses[i]).div(100);
                    users[up].matchBonus = users[up].matchBonus.add(bonus);
                    emit MatchPayout(up, _addr, bonus);
                }
            }
            up = users[up].upline;
        }

    }

   /**
     * @dev maxPayoutOf: Amount calculate by 310 percentage
     */
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount.mul(31).div(10); // 310% of deposit amount
    }
    
    /**
     * @dev payoutOf: Users daily ROI and maximum payout will be show
     */
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        uint amount = users[_addr].depositAmount;
        max_payout = this.maxPayoutOf(amount);
        if (users[_addr].depositPayouts < max_payout) {
            payout = ((amount.mul(1e6).div(100e6)).mul((block.timestamp.sub(users[_addr].depositTime)).div(1 days))).sub(users[_addr].depositPayouts); // Daily roi calculation

            if (users[_addr].depositPayouts.add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].depositPayouts);
            }
        }
    }
    
    /**
     * @dev addTokens : Adding token invokes by admin 
     */
    function addTokens(address token, uint _amount)public onlyOwner{
        
        _token = TRC20(token);
        _token.transferFrom(owner, address(this), _amount);
        _tokenStatus = true;
        emit AddToken(msg.sender,_amount,block.timestamp);
    }
    
    /**
     * @dev tokenStatus : For token status
     */
    function tokenStatus(bool _Status) public onlyOwner returns(bool) {
        _tokenStatus = _Status;
        return true;
    }
    
    /**
     * @dev updateToken : For token price updation
     */
    function updateToken(uint _tokenvalue)public onlyOwner{
        tokenValue = _tokenvalue;
    }
    
      /**
     * @dev updatePercentage : For token percentage updation
     */
    function updatePercentage(uint _tokenpercent)public onlyOwner{
        tokenPercentage = _tokenpercent;
    }
    
    /**
     * @dev userInfo : Returns users upline, depositTime, depositAmount, payouts, matchBonus
     */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].depositTime, users[_addr].depositAmount, users[_addr].payouts, users[_addr].matchBonus);
    }
    
    /**
     * @dev userInfoTotals : Returns users referrals, totalDeposits, totalStructure
     */
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].totalDeposits, users[_addr].totalStructure);
    }
    
    /**
     * @dev contractInfo : Returns totalUsers, totalDeposited, totalWithdraw
     */
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (totalUsers, totalDeposited, totalWithdraw);
    }
    
    /**
     * @dev failSafe: Returns transfere6
     */
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "TronQuin: Invalid Address");
        require(address(this).balance >= _amount, "TronQuin: Insufficient balance");
        (_toUser).transfer(_amount);
        emit FailSafe(_toUser,_amount,block.timestamp);
        return true;
    }
    
    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }

}