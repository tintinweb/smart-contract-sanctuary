/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-31
*/

pragma solidity 0.5.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface TRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

/**
 * @dev Implementation of the {TRC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {TRC20-approve}.
 */
contract ERC20 is Context, TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    // allocating 10 million tokens for xswap liquidity, promotions, airdrop and dev costs
    uint256 private _totalSupply = 10000000 * (10 ** 8);

    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * @dev See {TRC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {TRC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {TRC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {TRC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {TRC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {TRC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {TRC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {TRC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev External function to destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function burn(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "ERC20: not enough balance!");

        _burn(msg.sender, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract GlobalsAndUtility is ERC20 {
    /*  XfLobbyEnter
    */
    event XfLobbyEnter(
        uint256 timestamp,
        uint256 enterDay,
        uint256 indexed entryIndex,
        uint256 indexed rawAmount
    );

    /*  XfLobbyExit 
    */
    event XfLobbyExit(
        uint256 timestamp,
        uint256 enterDay,
        uint256 indexed entryIndex,
        uint256 indexed xfAmount,
        address indexed referrerAddr
    );

    /*  DailyDataUpdate
    */
    event DailyDataUpdate(
        address indexed updaterAddr,
        uint256 timestamp,
        uint256 beginDay,
        uint256 endDay
    );

    /*  StakeStart
    */
    event StakeStart(
        uint40 indexed stakeId,
        address indexed stakerAddr,
        uint256 stakedSuns,
        uint256 stakeShares,
        uint256 stakedDays
    );
    
    /*  StakeGoodAccounting
    */
    event StakeGoodAccounting(
        uint40 indexed stakeId,
        address indexed stakerAddr,
        address indexed senderAddr,
        uint256 stakedSuns,
        uint256 stakeShares,
        uint256 payout,
        uint256 penalty
    );

    /*  StakeEnd 
    */
    event StakeEnd(
        uint40 indexed stakeId,
        uint40 prevUnlocked,
        address indexed stakerAddr,
        uint256 lockedDay,
        uint256 servedDays,
        uint256 stakedSuns,
        uint256 stakeShares,
        uint256 dividends,
        uint256 payout,
        uint256 penalty,
        uint256 stakeReturn
    );

    /*  ShareRateChange 
    */
    event ShareRateChange(
        uint40 indexed stakeId,
        uint256 timestamp,
        uint256 newShareRate
    );

    /* T2X allocation share address */
    address payable internal constant T2X_SHARE_ADDR = 0x769902b4cB2dfD79F2370555AD255Bf599bF7155;

    uint8 internal LAST_FLUSHED_DAY = 1;

    /* ERC20 constants */
    string public constant name = "E2X";
    string public constant symbol = "E2X";
    uint8 public constant decimals = 8;

    /* Suns per Satoshi = 10,000 * 1e8 / 1e8 = 1e4 */
    uint256 private constant SUNS_PER_E2X = 10 ** uint256(decimals); // 1e8

    /* Time of contract launch (12-10-2020 T00:00:00Z) */
    uint256 internal constant LAUNCH_TIME = 1605139200;

    /* Start of claim phase */
    uint256 internal constant PRE_CLAIM_DAYS = 1;
    uint256 internal constant CLAIM_STARTING_AMOUNT = 5000000 * (10 ** 8);
    uint256 internal constant CLAIM_LOWEST_AMOUNT = 100000 * (10 ** 8);
    uint256 internal constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS;

    /* Number of words to hold 1 bit for each transform lobby day */
    uint256 internal constant XF_LOBBY_DAY_WORDS = ((1 + (50 * 7)) + 255) >> 8;

    /* Stake timing parameters */
    uint256 internal constant MIN_STAKE_DAYS = 1;

    uint256 internal constant MAX_STAKE_DAYS = 365;

    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;

    uint256 private constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = LATE_PENALTY_GRACE_WEEKS * 7;

    uint256 private constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = LATE_PENALTY_SCALE_WEEKS * 7;

    /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusSuns() */
    uint256 private constant LPB_BONUS_PERCENT = 20;
    uint256 private constant LPB_BONUS_MAX_PERCENT = 200;
    uint256 internal constant LPB = 364 * 100 / LPB_BONUS_PERCENT;
    uint256 internal constant LPB_MAX_DAYS = LPB * LPB_BONUS_MAX_PERCENT / 100;

    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusSuns() */
    uint256 private constant BPB_BONUS_PERCENT = 10;
    uint256 private constant BPB_MAX_E2X = 7 * 1e6;
    uint256 internal constant BPB_MAX_SUNS = BPB_MAX_E2X * SUNS_PER_E2X;
    uint256 internal constant BPB = BPB_MAX_SUNS * 100 / BPB_BONUS_PERCENT;

    /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_SCALE = 1e5;

    /* Share rate max (after scaling) */
    uint256 internal constant SHARE_RATE_UINT_SIZE = 40;
    uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;

    /* weekly staking bonus */
    uint8 internal constant BONUS_DAY_SCALE = 2;

    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        uint256 _lockedSunsTotal;
        uint256 _nextStakeSharesTotal;
        uint256 _shareRate;
        uint256 _stakePenaltyTotal;
        uint256 _dailyDataCount;
        uint256 _stakeSharesTotal;
        uint40 _latestStakeId;
        uint256 _currentDay;
    }

    struct GlobalsStore {
        uint72 lockedSunsTotal;
        uint72 nextStakeSharesTotal;
        uint40 shareRate;
        uint72 stakePenaltyTotal;
        uint16 dailyDataCount;
        uint72 stakeSharesTotal;
        uint40 latestStakeId;
    }

    GlobalsStore public globals;

    /* Daily data */
    struct DailyDataStore {
        uint72 dayPayoutTotal;
        uint256 dayDividends;
        uint72 dayStakeSharesTotal;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _stakedSuns;
        uint256 _stakeShares;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
    }

    struct StakeStore {
        uint40 stakeId;
        uint72 stakedSuns;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct DailyRoundState {
        uint256 _allocSupplyCached;
        uint256 _payoutTotal;
    }

    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }

    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }

    mapping(uint256 => uint256) public xfLobby;
    mapping(uint256 => mapping(address => XfLobbyQueueStore)) public xfLobbyMembers;

    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Skip pre-claim period */
        require(g._currentDay > CLAIM_PHASE_START_DAY, "E2X: Too early");

        if (beforeDay != 0) {
            require(beforeDay <= g._currentDay, "E2X: beforeDay cannot be in the future");

            _dailyDataUpdate(g, beforeDay, false);
        } else {
            /* Default to updating before current day */
            _dailyDataUpdate(g, g._currentDay, false);
        }

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: External helper to return multiple values of daily data with
     * a single call.
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return array of day stake shares total
     * @return array of day payout total
     */
    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory _dayStakeSharesTotal, uint256[] memory _dayPayoutTotal, uint256[] memory _dayDividends)
    {
        require(beginDay < endDay && endDay <= globals.dailyDataCount, "E2X: range invalid");

        _dayStakeSharesTotal = new uint256[](endDay - beginDay);
        _dayPayoutTotal = new uint256[](endDay - beginDay);
        _dayDividends = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            _dayStakeSharesTotal[dst] = uint256(dailyData[src].dayStakeSharesTotal);
            _dayPayoutTotal[dst++] = uint256(dailyData[src].dayPayoutTotal);
            _dayDividends[dst++] = dailyData[src].dayDividends;
        } while (++src < endDay);

        return (_dayStakeSharesTotal, _dayPayoutTotal, _dayDividends);
    }


    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * Ugly implementation due to limitations of the standard ABI encoder.
     * @return Fixed array of values
     */
    function globalInfo()
        external
        view
        returns (uint256[10] memory)
    {

        return [
            globals.lockedSunsTotal,
            globals.nextStakeSharesTotal,
            globals.shareRate,
            globals.stakePenaltyTotal,
            globals.dailyDataCount,
            globals.stakeSharesTotal,
            globals.latestStakeId,
            block.timestamp,
            totalSupply(),
            xfLobby[_currentDay()]
        ];
    }

    /**
     * @dev PUBLIC FACING: ERC20 totalSupply() is the circulating supply and does not include any
     * staked Suns. allocatedSupply() includes both.
     * @return Allocated Supply in Suns
     */
    function allocatedSupply()
        external
        view
        returns (uint256)
    {
        return totalSupply() + globals.lockedSunsTotal;
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }

    function _currentDay()
        internal
        view
        returns (uint256)
    {
        if (block.timestamp < LAUNCH_TIME){
             return 0;
        }else{
             return (block.timestamp - LAUNCH_TIME) / 1 days;
        }
    }

    function _dailyDataUpdateAuto(GlobalsCache memory g)
        internal
    {
        _dailyDataUpdate(g, g._currentDay, true);
    }

    function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        view
    {
        g._lockedSunsTotal = globals.lockedSunsTotal;
        g._nextStakeSharesTotal = globals.nextStakeSharesTotal;
        g._shareRate = globals.shareRate;
        g._stakePenaltyTotal = globals.stakePenaltyTotal;
        g._dailyDataCount = globals.dailyDataCount;
        g._stakeSharesTotal = globals.stakeSharesTotal;
        g._latestStakeId = globals.latestStakeId;
        g._currentDay = _currentDay();

        _globalsCacheSnapshot(g, gSnapshot);
    }

    function _globalsCacheSnapshot(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        pure
    {
        gSnapshot._lockedSunsTotal = g._lockedSunsTotal;
        gSnapshot._nextStakeSharesTotal = g._nextStakeSharesTotal;
        gSnapshot._shareRate = g._shareRate;
        gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
        gSnapshot._dailyDataCount = g._dailyDataCount;
        gSnapshot._stakeSharesTotal = g._stakeSharesTotal;
        gSnapshot._latestStakeId = g._latestStakeId;
    }

    function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
    {
        if (g._lockedSunsTotal != gSnapshot._lockedSunsTotal
            || g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal
            || g._shareRate != gSnapshot._shareRate
            || g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal) {
            globals.lockedSunsTotal = uint72(g._lockedSunsTotal);
            globals.nextStakeSharesTotal = uint72(g._nextStakeSharesTotal);
            globals.shareRate = uint40(g._shareRate);
            globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
        }
        if (g._dailyDataCount != gSnapshot._dailyDataCount
            || g._stakeSharesTotal != gSnapshot._stakeSharesTotal
            || g._latestStakeId != gSnapshot._latestStakeId) {
            globals.dailyDataCount = uint16(g._dailyDataCount);
            globals.stakeSharesTotal = uint72(g._stakeSharesTotal);
            globals.latestStakeId = g._latestStakeId;
        }
    }

    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st)
        internal
        view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "E2X: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._stakedSuns = stRef.stakedSuns;
        st._stakeShares = stRef.stakeShares;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
    }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
        internal
    {
        stRef.stakeId = st._stakeId;
        stRef.stakedSuns = uint72(st._stakedSuns);
        stRef.stakeShares = uint72(st._stakeShares);
        stRef.lockedDay = uint16(st._lockedDay);
        stRef.stakedDays = uint16(st._stakedDays);
        stRef.unlockedDay = uint16(st._unlockedDay);
    }

    function _stakeAdd(
        StakeStore[] storage stakeListRef,
        uint40 newStakeId,
        uint256 newStakedSuns,
        uint256 newStakeShares,
        uint256 newLockedDay,
        uint256 newStakedDays
    )
        internal
    {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                uint72(newStakedSuns),
                uint72(newStakeShares),
                uint16(newLockedDay),
                uint16(newStakedDays),
                uint16(0) // unlockedDay
            )
        );
    }

    /**
     * @dev Efficiently delete from an unordered array by moving the last element
     * to the "hole" and reducing the array length. Can change the order of the list
     * and invalidate previously held indexes.
     * @notice stakeListRef length and stakeIndex are already ensured valid in stakeEnd()
     * @param stakeListRef Reference to stakeLists[stakerAddr] array in storage
     * @param stakeIndex Index of the element to delete
     */
    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }

        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }

    /**
     * @dev Estimate the stake payout for an incomplete day
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param day Day to calculate bonuses for
     * @return Payout in Suns
     */
    function _estimatePayoutRewardsDay(GlobalsCache memory g, uint256 stakeSharesParam, uint256 day)
        internal
        view
        returns (uint256 payout)
    {
        /* Prevent updating state for this estimation */
        GlobalsCache memory gTmp;
        _globalsCacheSnapshot(g, gTmp);

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedSunsTotal;

        _dailyRoundCalc(gTmp, rs, day);

        /* Stake is no longer locked so it must be added to total as if it were */
        gTmp._stakeSharesTotal += stakeSharesParam;

        payout = rs._payoutTotal * stakeSharesParam / gTmp._stakeSharesTotal;

        return payout;
    }

    function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
        view
    {
        /*
            Calculate payout round

            Inflation of 5.42% inflation per 364 days             (approx 1 year)
            dailyInterestRate   = exp(log(1 + 5.42%)  / 364) - 1
                                = exp(log(1 + 0.0542) / 364) - 1
                                = exp(log(1.0542) / 364) - 1
                                = 0.0.00014523452066           (approx)

            payout  = allocSupply * dailyInterestRate
                    = allocSupply / (1 / dailyInterestRate)
                    = allocSupply / (1 / 0.00014523452066)
                    = allocSupply / 6885.4153644438375            (approx)
                    = allocSupply * 50000 / 68854153             (* 50000/50000 for int precision)
        */
        
        rs._payoutTotal = (rs._allocSupplyCached * 50000 / 68854153);

        if (g._stakePenaltyTotal != 0) {
            rs._payoutTotal += g._stakePenaltyTotal;
            g._stakePenaltyTotal = 0;
        }
    }

    function _dailyRoundCalcAndStore(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
    {
        _dailyRoundCalc(g, rs, day);

        dailyData[day].dayPayoutTotal = uint72(rs._payoutTotal);
        dailyData[day].dayDividends = xfLobby[day];
        dailyData[day].dayStakeSharesTotal = uint72(g._stakeSharesTotal);
    }

    function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay, bool isAutoUpdate)
        private
    {
        if (g._dailyDataCount >= beforeDay) {
            /* Already up-to-date */
            return;
        }

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedSunsTotal;

        uint256 day = g._dailyDataCount;

        _dailyRoundCalcAndStore(g, rs, day);

        /* Stakes started during this day are added to the total the next day */
        if (g._nextStakeSharesTotal != 0) {
            g._stakeSharesTotal += g._nextStakeSharesTotal;
            g._nextStakeSharesTotal = 0;
        }

        while (++day < beforeDay) {
            _dailyRoundCalcAndStore(g, rs, day);
        }

        emit DailyDataUpdate(
            msg.sender,
            block.timestamp,
            g._dailyDataCount, 
            day
        );
        
        g._dailyDataCount = day;
    }
}

contract StakeableToken is GlobalsAndUtility {
    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedSuns Number of Suns to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedSuns, uint256 newStakedDays)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Enforce the minimum stake time */
        require(newStakedDays >= MIN_STAKE_DAYS, "E2X: newStakedDays lower than minimum");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        _stakeStart(g, newStakedSuns, newStakedDays);

        /* Remove staked Suns from balance of staker */
        _burn(msg.sender, newStakedSuns);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* require() is more informative than the default assert() */
        require(stakeLists[stakerAddr].length != 0, "E2X: Empty stake list");
        require(stakeIndex < stakeLists[stakerAddr].length, "E2X: stakeIndex invalid");

        StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stRef, stakeIdParam, st);

        /* Stake must have served full term */
        require(g._currentDay >= st._lockedDay + st._stakedDays, "E2X: Stake not fully served");

        /* Stake must still be locked */
        require(st._unlockedDay == 0, "E2X: Stake already unlocked");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        /* Unlock the completed stake */
        _stakeUnlock(g, st);

        /* stakeReturn & dividends values are unused here */
        (, uint256 payout, uint256 dividends, uint256 penalty, uint256 cappedPenalty) = _stakePerformance(
            g,
            st,
            st._stakedDays
        );

        emit StakeGoodAccounting(
            stakeIdParam,
            stakerAddr,
            msg.sender,
            st._stakedSuns,
            st._stakeShares,
            payout,
            penalty
        );

        if (cappedPenalty != 0) {
            g._stakePenaltyTotal += cappedPenalty;
        }

        /* st._unlockedDay has changed */
        _stakeUpdate(stRef, st);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        StakeStore[] storage stakeListRef = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "E2X: Empty stake list");
        require(stakeIndex < stakeListRef.length, "E2X: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        uint256 servedDays = 0;

        bool prevUnlocked = (st._unlockedDay != 0);
        uint256 stakeReturn;
        uint256 payout = 0;
        uint256 dividends = 0;
        uint256 penalty = 0;
        uint256 cappedPenalty = 0;

        if (g._currentDay >= st._lockedDay) {
            if (prevUnlocked) {
                /* Previously unlocked in stakeGoodAccounting(), so must have served full term */
                servedDays = st._stakedDays;
            } else {
                _stakeUnlock(g, st);

                servedDays = g._currentDay - st._lockedDay;
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays;
                }
            }

            (stakeReturn, payout, dividends, penalty, cappedPenalty) = _stakePerformance(g, st, servedDays);

            msg.sender.transfer(dividends);
        } else {
            /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
            g._nextStakeSharesTotal -= st._stakeShares;

            stakeReturn = st._stakedSuns;
        }

        emit StakeEnd(
            stakeIdParam, 
            prevUnlocked ? 1 : 0,
            msg.sender,
            st._lockedDay,
            servedDays, 
            st._stakedSuns, 
            st._stakeShares, 
            dividends,
            payout, 
            penalty,
            stakeReturn
        );

        if (cappedPenalty != 0 && !prevUnlocked) {
            /* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
            g._stakePenaltyTotal += cappedPenalty;
        }

        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);
            
            /* Update the share rate if necessary */
            _shareRateUpdate(g, st, stakeReturn);
        }
        g._lockedSunsTotal -= st._stakedSuns;

        _stakeRemove(stakeListRef, stakeIndex);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return stakeLists[stakerAddr].length;
    }

    /**
     * @dev Open a stake.
     * @param g Cache of stored globals
     * @param newStakedSuns Number of Suns to stake
     * @param newStakedDays Number of days to stake
     */
    function _stakeStart(
        GlobalsCache memory g,
        uint256 newStakedSuns,
        uint256 newStakedDays
    )
        internal
    {
        /* Enforce the maximum stake time */
        require(newStakedDays <= MAX_STAKE_DAYS, "E2X: newStakedDays higher than maximum");

        uint256 bonusSuns = _stakeStartBonusSuns(newStakedSuns, newStakedDays);
        uint256 newStakeShares = (newStakedSuns + bonusSuns) * SHARE_RATE_SCALE / g._shareRate;

        /* Ensure newStakedSuns is enough for at least one stake share */
        require(newStakeShares != 0, "E2X: newStakedSuns must be at least minimum shareRate");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newLockedDay = g._currentDay + 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId;
        _stakeAdd(
            stakeLists[msg.sender],
            newStakeId,
            newStakedSuns,
            newStakeShares,
            newLockedDay,
            newStakedDays
        );

        emit StakeStart(
            newStakeId, 
            msg.sender,
            newStakedSuns, 
            newStakeShares, 
            newStakedDays
        );

        /* Stake is added to total in the next round, not the current round */
        g._nextStakeSharesTotal += newStakeShares;

        /* Track total staked Suns for inflation calculations */
        g._lockedSunsTotal += newStakedSuns;
    }

    /**
     * @dev Calculates total stake payout including rewards for a multi-day range
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return Payout in Suns
     */
    function _calcPayoutRewards(
        GlobalsCache memory g,
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    )
        private
        view
        returns (uint256 payout)
    {
        uint256 counter;

        for (uint256 day = beginDay; day < endDay; day++) {
            uint256 dayPayout;

            dayPayout = dailyData[day].dayPayoutTotal * stakeSharesParam
                / dailyData[day].dayStakeSharesTotal;

            if (counter < 4) {
                counter++;
            } 
            /* Eligible to receive bonus */
            else {
                dayPayout = (dailyData[day].dayPayoutTotal * stakeSharesParam
                / dailyData[day].dayStakeSharesTotal) * BONUS_DAY_SCALE;
                counter = 0;
            }

            payout += dayPayout;
        }

        return payout;
    }

    /**
     * @dev Calculates user dividends
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return Payout in Suns
     */
    function _calcPayoutDividendsReward(
        GlobalsCache memory g,
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    )
        private
        view
        returns (uint256 payout)
    {

        for (uint256 day = beginDay; day < endDay; day++) {
            uint256 dayPayout;

            /* user's share of 95% of the day's dividends */
            dayPayout += ((dailyData[day].dayDividends * 90) / 100) * stakeSharesParam
            / dailyData[day].dayStakeSharesTotal;

            payout += dayPayout;
        }

        return payout;
    }

    /**
     * @dev Calculate bonus Suns for a new stake, if any
     * @param newStakedSuns Number of Suns to stake
     * @param newStakedDays Number of days to stake
     */
    function _stakeStartBonusSuns(uint256 newStakedSuns, uint256 newStakedDays)
        private
        pure
        returns (uint256 bonusSuns)
    {
        /*
            LONGER PAYS BETTER:

            If longer than 1 day stake is committed to, each extra day
            gives bonus shares of approximately 0.0548%, which is approximately 20%
            extra per year of increased stake length committed to, but capped to a
            maximum of 200% extra.

            extraDays       =  stakedDays - 1

            longerBonus%    = (extraDays / 364) * 20%
                            = (extraDays / 364) / 5
                            =  extraDays / 1820
                            =  extraDays / LPB

            extraDays       =  longerBonus% * 1820
            extraDaysMax    =  longerBonusMax% * 1820
                            =  200% * 1820
                            =  3640
                            =  LPB_MAX_DAYS

            BIGGER PAYS BETTER:

            Bonus percentage scaled 0% to 10% for the first 7M E2X of stake.

            biggerBonus%    = (cappedSuns /  BPB_MAX_SUNS) * 10%
                            = (cappedSuns /  BPB_MAX_SUNS) / 10
                            =  cappedSuns / (BPB_MAX_SUNS * 10)
                            =  cappedSuns /  BPB

            COMBINED:

            combinedBonus%  =            longerBonus%  +  biggerBonus%

                                      cappedExtraDays     cappedSuns
                            =         ---------------  +  ------------
                                            LPB               BPB

                                cappedExtraDays * BPB     cappedSuns * LPB
                            =   ---------------------  +  ------------------
                                      LPB * BPB               LPB * BPB

                                cappedExtraDays * BPB  +  cappedSuns * LPB
                            =   --------------------------------------------
                                                  LPB  *  BPB

            bonusSuns     = suns * combinedBonus%
                            = suns * (cappedExtraDays * BPB  +  cappedSuns * LPB) / (LPB * BPB)
        */
        uint256 cappedExtraDays = 0;

        /* Must be more than 1 day for Longer-Pays-Better */
        if (newStakedDays > 1) {
            cappedExtraDays = newStakedDays <= LPB_MAX_DAYS ? newStakedDays - 1 : LPB_MAX_DAYS;
        }

        uint256 cappedStakedSuns = newStakedSuns <= BPB_MAX_SUNS
            ? newStakedSuns
            : BPB_MAX_SUNS;

        bonusSuns = cappedExtraDays * BPB + cappedStakedSuns * LPB;
        bonusSuns = newStakedSuns * bonusSuns / (LPB * BPB);

        return bonusSuns;
    }

    function _stakeUnlock(GlobalsCache memory g, StakeCache memory st)
        private
        pure
    {
        g._stakeSharesTotal -= st._stakeShares;
        st._unlockedDay = g._currentDay;
    }

    function _stakePerformance(GlobalsCache memory g, StakeCache memory st, uint256 servedDays)
        private
        view
        returns (uint256 stakeReturn, uint256 payout, uint256 dividends, uint256 penalty, uint256 cappedPenalty)
    {
        if (servedDays < st._stakedDays) {
            (payout, penalty) = _calcPayoutAndEarlyPenalty(
                g,
                st._lockedDay,
                st._stakedDays,
                servedDays,
                st._stakeShares
            );
            stakeReturn = st._stakedSuns + payout;

            dividends = _calcPayoutDividendsReward(
                g,
                st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );
        } else {
            // servedDays must == stakedDays here
            payout = _calcPayoutRewards(
                g,
                st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );

            dividends = _calcPayoutDividendsReward(
                g,
                st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );

            stakeReturn = st._stakedSuns + payout;

            penalty = _calcLatePenalty(st._lockedDay, st._stakedDays, st._unlockedDay, stakeReturn);
        }
        if (penalty != 0) {
            if (penalty > stakeReturn) {
                /* Cannot have a negative stake return */
                cappedPenalty = stakeReturn;
                stakeReturn = 0;
            } else {
                /* Remove penalty from the stake return */
                cappedPenalty = penalty;
                stakeReturn -= cappedPenalty;
            }
        }
        return (stakeReturn, payout, dividends, penalty, cappedPenalty);
    }

    function _calcPayoutAndEarlyPenalty(
        GlobalsCache memory g,
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 servedDays,
        uint256 stakeSharesParam
    )
        private
        view
        returns (uint256 payout, uint256 penalty)
    {
        uint256 servedEndDay = lockedDayParam + servedDays;

        /* 50% of stakedDays (rounded up) with a minimum applied */
        uint256 penaltyDays = (stakedDaysParam + 1) / 2;
        if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
            penaltyDays = EARLY_PENALTY_MIN_DAYS;
        }

        if (servedDays == 0) {
            /* Fill penalty days with the estimated average payout */
            uint256 expected = _estimatePayoutRewardsDay(g, stakeSharesParam, lockedDayParam);
            penalty = expected * penaltyDays;
            return (payout, penalty); // Actual payout was 0
        }

        if (penaltyDays < servedDays) {
            /*
                Simplified explanation of intervals where end-day is non-inclusive:

                penalty:    [lockedDay  ...  penaltyEndDay)
                delta:                      [penaltyEndDay  ...  servedEndDay)
                payout:     [lockedDay  .......................  servedEndDay)
            */
            uint256 penaltyEndDay = lockedDayParam + penaltyDays;
            penalty = _calcPayoutRewards(g, stakeSharesParam, lockedDayParam, penaltyEndDay);

            uint256 delta = _calcPayoutRewards(g, stakeSharesParam, penaltyEndDay, servedEndDay);
            payout = penalty + delta;
            return (payout, penalty);
        }

        /* penaltyDays >= servedDays  */
        payout = _calcPayoutRewards(g, stakeSharesParam, lockedDayParam, servedEndDay);

        if (penaltyDays == servedDays) {
            penalty = payout;
        } else {
            /*
                (penaltyDays > servedDays) means not enough days served, so fill the
                penalty days with the average payout from only the days that were served.
            */
            penalty = payout * penaltyDays / servedDays;
        }
        return (payout, penalty);
    }

    function _calcLatePenalty(
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 unlockedDayParam,
        uint256 rawStakeReturn
    )
        private
        pure
        returns (uint256)
    {
        /* Allow grace time before penalties accrue */
        uint256 maxUnlockedDay = lockedDayParam + stakedDaysParam + LATE_PENALTY_GRACE_DAYS;
        if (unlockedDayParam <= maxUnlockedDay) {
            return 0;
        }

        /* Calculate penalty as a percentage of stake return based on time */
        return rawStakeReturn * (unlockedDayParam - maxUnlockedDay) / LATE_PENALTY_SCALE_DAYS;
    }

    function _shareRateUpdate(GlobalsCache memory g, StakeCache memory st, uint256 stakeReturn)
        private
    {
        if (stakeReturn > st._stakedSuns) {
            /*
                Calculate the new shareRate that would yield the same number of shares if
                the user re-staked this stakeReturn, factoring in any bonuses they would
                receive in stakeStart().
            */
            uint256 bonusSuns = _stakeStartBonusSuns(stakeReturn, st._stakedDays);
            uint256 newShareRate = (stakeReturn + bonusSuns) * SHARE_RATE_SCALE / st._stakeShares;

            if (newShareRate > SHARE_RATE_MAX) {
                /*
                    Realistically this can't happen, but there are contrived theoretical
                    scenarios that can lead to extreme values of newShareRate, so it is
                    capped to prevent them anyway.
                */
                newShareRate = SHARE_RATE_MAX;
            }

            if (newShareRate > g._shareRate) {
                g._shareRate = newShareRate;

                emit ShareRateChange(
                    st._stakeId,
                    block.timestamp,
                    newShareRate
                );
            }
        }
    }

}

contract TransformableToken is StakeableToken {
    /**
     * @dev PUBLIC FACING: Enter the auction lobby for the current round
     * @param referrerAddr TRX address of referring user (optional; 0x0 for no referrer)
     */
    function xfLobbyEnter(address referrerAddr)
        external
        payable
    {
        uint256 enterDay = _currentDay();

        uint256 rawAmount = msg.value;
        require(rawAmount != 0, "E2X: Amount required");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

        uint256 entryIndex = qRef.tailIndex++;

        qRef.entries[entryIndex] = XfLobbyEntryStore(uint96(rawAmount), referrerAddr);

        xfLobby[enterDay] += rawAmount;

        emit XfLobbyEnter(
            block.timestamp, 
            enterDay, 
            entryIndex, 
            rawAmount
        );
    }

    /**
     * @dev PUBLIC FACING: Leave the transform lobby after the round is complete
     * @param enterDay Day number when the member entered
     * @param count Number of queued-enters to exit (optional; 0 for all)
     */
    function xfLobbyExit(uint256 enterDay, uint256 count)
        external
    {
        require(enterDay < _currentDay(), "E2X: Round is not complete");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

        uint256 headIndex = qRef.headIndex;
        uint256 endIndex;

        if (count != 0) {
            require(count <= qRef.tailIndex - headIndex, "E2X: count invalid");
            endIndex = headIndex + count;
        } else {
            endIndex = qRef.tailIndex;
            require(headIndex < endIndex, "E2X: count invalid");
        }

        uint256 waasLobby = _waasLobby(enterDay);
        uint256 _xfLobby = xfLobby[enterDay];
        uint256 totalXfAmount = 0;

        do {
            uint256 rawAmount = qRef.entries[headIndex].rawAmount;
            address referrerAddr = qRef.entries[headIndex].referrerAddr;

            delete qRef.entries[headIndex];

            uint256 xfAmount = waasLobby * rawAmount / _xfLobby;

            if (referrerAddr == address(0) || referrerAddr == msg.sender) {
                /* No referrer or Self-referred */
                _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
            } else {
                /* Referral bonus of 5% of xfAmount to member */
                uint256 referralBonusSuns = xfAmount / 20;

                xfAmount += referralBonusSuns;

                /* Then a cumulative referrer bonus of 10% to referrer */
                uint256 referrerBonusSuns = xfAmount / 10;

                _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
                _mint(referrerAddr, referrerBonusSuns);
            }

            totalXfAmount += xfAmount;
        } while (++headIndex < endIndex);

        qRef.headIndex = uint40(headIndex);

        if (totalXfAmount != 0) {
            _mint(msg.sender, totalXfAmount);
        }
    }

    /**
     * @dev PUBLIC FACING: External helper to return multiple values of xfLobby[] with
     * a single call
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return Fixed array of values
     */
    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list)
    {
        require(
            beginDay < endDay && endDay <= _currentDay(),
            "E2X: invalid range"
        );

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            list[dst++] = uint256(xfLobby[src++]);
        } while (src < endDay);

        return list;
    }

    /**
     * @dev PUBLIC FACING: Release 5% dev share from daily dividends
     */
    function xfFlush()
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        
        require(address(this).balance != 0, "E2X: No value");

        require(LAST_FLUSHED_DAY < _currentDay(), "E2X: Invalid day");

        _dailyDataUpdateAuto(g);

        T2X_SHARE_ADDR.transfer((dailyData[LAST_FLUSHED_DAY].dayDividends * 10) / 100);

        LAST_FLUSHED_DAY++;

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Return a current lobby member queue entry.
     * Only needed due to limitations of the standard ABI encoder.
     * @param memberAddr TRX address of the lobby member
     * @param enterDay 
     * @param entryIndex 
     * @return 1: Raw amount that was entered with; 2: Referring TRX addr (optional; 0x0 for no referrer)
     */
    function xfLobbyEntry(address memberAddr, uint256 enterDay, uint256 entryIndex)
        external
        view
        returns (uint256 rawAmount, address referrerAddr)
    {
        XfLobbyEntryStore storage entry = xfLobbyMembers[enterDay][memberAddr].entries[entryIndex];

        require(entry.rawAmount != 0, "E2X: Param invalid");

        return (entry.rawAmount, entry.referrerAddr);
    }

    /**
     * @dev PUBLIC FACING: Return the lobby days that a user is in with a single call
     * @param memberAddr TRX address of the user
     * @return Bit vector of lobby day numbers
     */
    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[XF_LOBBY_DAY_WORDS] memory words)
    {
        uint256 day = _currentDay() + 1;

        while (day-- != 0) {
            if (xfLobbyMembers[day][memberAddr].tailIndex > xfLobbyMembers[day][memberAddr].headIndex) {
                words[day >> 8] |= 1 << (day & 255);
            }
        }

        return words;
    }
    
    function _waasLobby(uint256 enterDay)
        private
        returns (uint256 waasLobby)
    {
        /* 1342465753424 = ~ 4900000 * SUNS_PER_E2X / 365 */
        if (enterDay > 0 && enterDay <= 365) {                                     
            waasLobby = CLAIM_STARTING_AMOUNT - ((enterDay - 1) * 1342465753424);
        } else {
            waasLobby = CLAIM_LOWEST_AMOUNT;
        }

        return waasLobby;
    }

    function _emitXfLobbyExit(
        uint256 enterDay,
        uint256 entryIndex,
        uint256 xfAmount,
        address referrerAddr
    )
        private
    {
        emit XfLobbyExit(
            block.timestamp, 
            enterDay,
            entryIndex,
            xfAmount,
            referrerAddr
        );
    }
}

contract E2X is TransformableToken {
    constructor()
        public
    {
        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(1 * SHARE_RATE_SCALE);
    }

    function() external payable {}
}