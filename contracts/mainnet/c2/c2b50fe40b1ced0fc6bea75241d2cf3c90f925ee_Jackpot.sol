/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Jackpot.sol

pragma solidity ^0.5.0;





/**
 * @dev Implementation of the {ERC20} interface.
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
 * allowances. See {ERC20-approve}.
 */
contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    // allocating 30 million tokens for promotion, airdrop, liquidity and dev share
    uint256 private _totalSupply = 99999900 * (10**8);

    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
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
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
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
     * @dev See {ERC20-transferFrom}.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    /* function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    } */
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    /* function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    } */
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
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
    /* function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    } */
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
    //uint256 internal constant ROUND_TIME = 1 days;
    //uint256 internal constant ROUND_TIME = 2 hours;
    uint256 public ROUND_TIME;
    //uint256 internal constant ROUND_TIME = 5 minutes;
    //uint256 internal constant LOTERY_ENTRY_TIME = 1 hours;
    //uint256 internal constant LOTERY_ENTRY_TIME = 20 minutes;
    uint256 public LOTERY_ENTRY_TIME;
    address public defaultReferrerAddr;
    /* Flush address */
    address payable public flushAddr;
    uint256 internal firstAuction = uint256(-1);
    uint256 internal LAST_FLUSHED_DAY = 0;
    /* ERC20 constants */
    string public constant name = "Jackpot Ethereum";
    string public constant symbol = "JETH";
    uint8 public constant decimals = 8;
    uint256 public LAUNCH_TIME; // = 1606046700;
    uint256 public dayNumberBegin; // = 2;
    /* Start of claim phase */
    uint256 internal constant CLAIM_STARTING_AMOUNT =
        2500000 * (10**uint256(decimals));
    uint256 internal constant CLAIM_LOWEST_AMOUNT =
        1000000 * (10**uint256(decimals));
    /* Number of words to hold 1 bit for each transform lobby day */
    uint256 internal constant XF_LOBBY_DAY_WORDS = ((1 + (50 * 7)) + 255) >> 8;
    /* Stake timing parameters */
    uint256 internal constant MIN_STAKE_DAYS = 1;
    uint256 internal constant MAX_STAKE_DAYS = 180; // Approx 0.5 years
    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;
    //uint256 private constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = 2 * 7;
    //uint256 private constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = 100 * 7;
    /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusSuns() */
    //uint256 private constant LPB_BONUS_PERCENT = 20;
    //uint256 private constant LPB_BONUS_MAX_PERCENT = 200;
    uint256 internal constant LPB = (18 * 100) / 20; /* LPB_BONUS_PERCENT */
    uint256 internal constant LPB_MAX_DAYS = (LPB * 200) / 100; /* LPB_BONUS_MAX_PERCENT */
    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusSuns() */
    //uint256 private constant BPB_BONUS_PERCENT = 10;
    //uint256 private constant BPB_MAX_JACKPOT = 7 * 1e6;
    uint256 internal constant BPB_MAX_SUNS =
        7 *
            1e6 * /* BPB_MAX_JACKPOT */
            (10**uint256(decimals));
    uint256 internal constant BPB = (BPB_MAX_SUNS * 100) / 10; /* BPB_BONUS_PERCENT */
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
        uint256 lockedSunsTotal;
        uint256 nextStakeSharesTotal;
        uint40 shareRate;
        uint256 stakePenaltyTotal;
        uint16 dailyDataCount;
        uint256 stakeSharesTotal;
        uint40 latestStakeId;
    }
    GlobalsStore public globals;
    /* Daily data */
    struct DailyDataStore {
        uint256 dayPayoutTotal;
        uint256 dayDividends;
        uint256 dayStakeSharesTotal;
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
        uint256 stakedSuns;
        uint256 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
    }
    struct UnstakeStore {
        uint40 stakeId;
        uint256 stakedSuns;
        uint256 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        uint256 unstakePayout;
        uint256 unstakeDividends;
    }
    mapping(address => StakeStore[]) public stakeLists;
    mapping(address => UnstakeStore[]) public endedStakeLists;
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
    mapping(uint256 => mapping(address => XfLobbyQueueStore))
        public xfLobbyMembers;
    mapping(address => uint256) public fromReferrs;
    mapping(uint256 => mapping(address => uint256))
        public jackpotReceivedAuction;

    /*  loteryLobbyEnter
     */
    event loteryLobbyEnter(
        uint256 timestamp,
        uint256 enterDay,
        uint256 indexed rawAmount
    );
    /*  loteryLobbyExit
     */
    event loteryLobbyExit(
        uint256 timestamp,
        uint256 enterDay,
        uint256 indexed rawAmount
    );
    event loteryWin(uint256 day, uint256 amount, address who);
    struct LoteryStore {
        uint256 change;
        uint256 chanceCount;
    }
    struct LoteryCount {
        address who;
        uint256 chanceCount;
    }
    struct winLoteryStat {
        address payable who;
        uint256 totalAmount;
        uint256 restAmount;
    }
    uint256 public lastEndedLoteryDay = 0;
    uint256 public lastEndedLoteryDayWithWinner = 0;
    uint256 public loteryDayWaitingForWinner = 0;
    uint256 public loteryDayWaitingForWinnerNew = 0;
    mapping(uint256 => winLoteryStat) public winners;
    mapping(uint256 => uint256) public dayChanceCount;
    // day => address => chance count
    mapping(uint256 => mapping(address => LoteryStore)) public loteryLobby;
    mapping(uint256 => LoteryCount[]) public loteryCount;

    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay) external {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        /* Skip pre-claim period */
        require(g._currentDay > 1, "JACKPOT: Too early"); /* CLAIM_PHASE_START_DAY */
        if (beforeDay != 0) {
            require(
                beforeDay <= g._currentDay,
                "JACKPOT: beforeDay cannot be in the future"
            );
            _dailyDataUpdate(g, beforeDay);
        } else {
            /* Default to updating before current day */
            _dailyDataUpdate(g, g._currentDay);
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
    /* function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory _dayStakeSharesTotal, uint256[] memory _dayPayoutTotal, uint256[] memory _dayDividends)
    {
        require(beginDay < endDay && endDay <= globals.dailyDataCount, "JACKPOT: range invalid");
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
    } */
    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * Ugly implementation due to limitations of the standard ABI encoder.
     * @return Fixed array of values
     */
    function globalInfo() external view returns (uint256[10] memory) {
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
    function allocatedSupply() external view returns (uint256) {
        return totalSupply().add(globals.lockedSunsTotal);
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay() external view returns (uint256) {
        return _currentDay();
    }

    function _currentDay() internal view returns (uint256) {
        return block.timestamp.sub(LAUNCH_TIME).div(ROUND_TIME);
    }

    function _dailyDataUpdateAuto(GlobalsCache memory g) internal {
        _dailyDataUpdate(g, g._currentDay);
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

    function _globalsCacheSnapshot(
        GlobalsCache memory g,
        GlobalsCache memory gSnapshot
    ) internal pure {
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
        if (
            g._lockedSunsTotal != gSnapshot._lockedSunsTotal ||
            g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal ||
            g._shareRate != gSnapshot._shareRate ||
            g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal
        ) {
            globals.lockedSunsTotal = g._lockedSunsTotal;
            globals.nextStakeSharesTotal = g._nextStakeSharesTotal;
            globals.shareRate = uint40(g._shareRate);
            globals.stakePenaltyTotal = g._stakePenaltyTotal;
        }
        if (
            g._dailyDataCount != gSnapshot._dailyDataCount ||
            g._stakeSharesTotal != gSnapshot._stakeSharesTotal ||
            g._latestStakeId != gSnapshot._latestStakeId
        ) {
            globals.dailyDataCount = uint16(g._dailyDataCount);
            globals.stakeSharesTotal = g._stakeSharesTotal;
            globals.latestStakeId = g._latestStakeId;
        }
    }

    function _stakeLoad(
        StakeStore storage stRef,
        uint40 stakeIdParam,
        StakeCache memory st
    ) internal view {
        /* Ensure caller's stakeIndex is still current */
        require(
            stakeIdParam == stRef.stakeId,
            "JACKPOT: stakeIdParam not in stake"
        );
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
        stRef.stakedSuns = st._stakedSuns;
        stRef.stakeShares = st._stakeShares;
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
    ) internal {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                newStakedSuns,
                newStakeShares,
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
        uint256 lastIndex = stakeListRef.length.sub(1);
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
     * @return Payout in Suns
     */
    function _estimatePayoutRewardsDay(
        GlobalsCache memory g,
        uint256 stakeSharesParam
    ) internal view returns (uint256 payout) {
        /* Prevent updating state for this estimation */
        GlobalsCache memory gJpt;
        _globalsCacheSnapshot(g, gJpt);
        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply().add(g._lockedSunsTotal);
        _dailyRoundCalc(gJpt, rs);
        /* Stake is no longer locked so it must be added to total as if it were */
        gJpt._stakeSharesTotal = gJpt._stakeSharesTotal.add(stakeSharesParam);
        payout = rs._payoutTotal.mul(stakeSharesParam).div(gJpt._stakeSharesTotal);
        return payout;
    }

    function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs)
        private
        pure
    {
        /*
            Calculate payout round
            Inflation of 20% inflation per 365 days             (approx 1 year)
            dailyInterestRate   = exp(log(1 + 20%)  / 365) - 1
                                = exp(log(1 + 0.2) / 365) - 1
                                = exp(log(1.2) / 365) - 1
                                = 0.00049963589095561        (approx)
            payout  = allocSupply * dailyInterestRate
                    = allocSupply / (1 / dailyInterestRate)
                    = allocSupply / (1 / 0.00049963589095561)
                    = allocSupply / 2001.45749755364         (approx)
                    = allocSupply * 342345 / 685188967
        */
        //rs._payoutTotal = (rs._allocSupplyCached * 342345 / 685188967);
        rs._payoutTotal = rs._allocSupplyCached.mul(342345).div(685188967);
        if (g._stakePenaltyTotal != 0) {
            rs._payoutTotal = rs._payoutTotal.add(g._stakePenaltyTotal);
            g._stakePenaltyTotal = 0;
        }
    }

    function _dailyRoundCalcAndStore(
        GlobalsCache memory g,
        DailyRoundState memory rs,
        uint256 day
    ) private {
        _dailyRoundCalc(g, rs);
        dailyData[day].dayPayoutTotal = rs._payoutTotal;
        /* if (day == firstAuction + 2)
            dailyData[day].dayDividends = xfLobby[day] + xfLobby[firstAuction];
        if (day == firstAuction + 3)
            dailyData[day].dayDividends = xfLobby[day] + xfLobby[firstAuction + 1]; */
        dailyData[day].dayDividends = xfLobby[day];
        dailyData[day].dayStakeSharesTotal = g._stakeSharesTotal;
    }

    function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay)
        private
    {
        if (g._dailyDataCount >= beforeDay) {
            /* Already up-to-date */
            return;
        }
        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply().add(g._lockedSunsTotal);
        uint256 day = g._dailyDataCount;
        _dailyRoundCalcAndStore(g, rs, day);
        /* Stakes started during this day are added to the total the next day */
        if (g._nextStakeSharesTotal != 0) {
            g._stakeSharesTotal = g._stakeSharesTotal.add(g._nextStakeSharesTotal);
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
    modifier onlyAfterNDays(uint256 daysShift) {
        require(now >= LAUNCH_TIME, "JACKPOT: Too early");
        require(
            firstAuction != uint256(-1),
            "JACKPOT: Must be at least one auction"
        );
        require(
            _currentDay() >= firstAuction.add(daysShift),
            "JACKPOT: Too early"
        );
        _;
    }

    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedSuns Number of Suns to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedSuns, uint256 newStakedDays)
        external
        onlyAfterNDays(1)
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        if (g._currentDay >= 1) endLoteryDay(g._currentDay.sub(1));
        /* Enforce the minimum stake time */
        require(
            newStakedDays >= MIN_STAKE_DAYS,
            "JACKPOT: newStakedDays lower than minimum"
        );
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
    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        if (g._currentDay >= 1) endLoteryDay(g._currentDay.sub(1));
        /* require() is more informative than the default assert() */
        require(
            stakeLists[stakerAddr].length != 0,
            "JACKPOT: Empty stake list"
        );
        require(
            stakeIndex < stakeLists[stakerAddr].length,
            "JACKPOT: stakeIndex invalid"
        );
        StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];
        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stRef, stakeIdParam, st);
        /* Stake must have served full term */
        require(
            g._currentDay >= st._lockedDay.add(st._stakedDays),
            "JACKPOT: Stake not fully served"
        );
        /* Stake must still be locked */
        require(st._unlockedDay == 0, "JACKPOT: Stake already unlocked");
        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);
        /* Unlock the completed stake */
        _stakeUnlock(g, st);
        /* stakeReturn & dividends values are unused here */
        (, uint256 payout, , uint256 penalty, uint256 cappedPenalty) =
            _stakePerformance(g, st, st._stakedDays);
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
            g._stakePenaltyTotal = g._stakePenaltyTotal.add(cappedPenalty);
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
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        StakeStore[] storage stakeListRef = stakeLists[msg.sender];
        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "JACKPOT: Empty stake list");
        require(
            stakeIndex < stakeListRef.length,
            "JACKPOT: stakeIndex invalid"
        );
        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);
        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);
        _globalsSync(g, gSnapshot);
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
                //require(g._currentDay >= st._lockedDay + 5, "JACKPOT: Stake must serve at least 5 days");
                _stakeUnlock(g, st);
                servedDays = g._currentDay.sub(st._lockedDay);
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays;
                }
            }
            (
                stakeReturn,
                payout,
                dividends,
                penalty,
                cappedPenalty
            ) = _stakePerformance(g, st, servedDays);
            msg.sender.transfer(dividends);
        } else {
            /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
            g._nextStakeSharesTotal = g._nextStakeSharesTotal.sub(st._stakeShares);
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
            payout,
            penalty,
            stakeReturn
        );
        if (cappedPenalty != 0 && !prevUnlocked) {
            /* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
            g._stakePenaltyTotal = g._stakePenaltyTotal.add(cappedPenalty);
        }
        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);
            /* Update the share rate if necessary */
            _shareRateUpdate(g, st, stakeReturn);
        }
        g._lockedSunsTotal = g._lockedSunsTotal.sub(st._stakedSuns);
        stakeListRef[stakeIndex].unlockedDay = uint16(
            g._currentDay.mod(uint256(uint16(-1)))
        );
        UnstakeStore memory endedInfo;
        endedInfo.stakeId = stakeListRef[stakeIndex].stakeId;
        endedInfo.stakedSuns = stakeListRef[stakeIndex].stakedSuns;
        endedInfo.stakeShares = stakeListRef[stakeIndex].stakeShares;
        endedInfo.lockedDay = stakeListRef[stakeIndex].lockedDay;
        endedInfo.stakedDays = stakeListRef[stakeIndex].stakedDays;
        endedInfo.unlockedDay = stakeListRef[stakeIndex].unlockedDay;
        endedInfo.unstakePayout = stakeReturn;
        endedInfo.unstakeDividends = dividends;
        //endedStakeLists[_msgSender()].push(stakeListRef[stakeIndex]);
        endedStakeLists[_msgSender()].push(endedInfo);
        _stakeRemove(stakeListRef, stakeIndex);
        _globalsSync(g, gSnapshot);
    }

    uint256 private undestributedLotery = 0;

    function endLoteryDay(uint256 endDay) public onlyAfterNDays(0) {
        uint256 currDay = _currentDay();
        if (currDay == 0) return;
        if (endDay >= currDay) endDay = currDay.sub(1);
        if (
            endDay == currDay.sub(1) &&
            now % ROUND_TIME <= LOTERY_ENTRY_TIME &&
            endDay > 0
        ) endDay = endDay.sub(1);
        else if (
            endDay == currDay.sub(1) &&
            now % ROUND_TIME <= LOTERY_ENTRY_TIME &&
            endDay == 0
        ) return;
        while (lastEndedLoteryDay <= endDay) {
            uint256 ChanceCount = dayChanceCount[lastEndedLoteryDay];
            if (ChanceCount == 0) {
                undestributedLotery = undestributedLotery.add(xfLobby[lastEndedLoteryDay].mul(25).div(1000));
                lastEndedLoteryDay = lastEndedLoteryDay.add(1);
                continue;
            }
            uint256 randomInt = _random(ChanceCount);
            //uint256 randomInt = _random(10000);
            uint256 count = 0;
            uint256 ind = 0;
            while (count < randomInt) {
                uint256 newChanceCount =
                    loteryCount[lastEndedLoteryDay][ind].chanceCount;
                if (count.add(newChanceCount) >= randomInt) break;
                count = count.add(newChanceCount);
                ind = ind.add(1);
            }
            uint256 amount = xfLobby[lastEndedLoteryDay].mul(25).div(1000);
            if (undestributedLotery > 0) {
                amount = amount.add(undestributedLotery);
                undestributedLotery = 0;
            }
            winners[lastEndedLoteryDay] = winLoteryStat(
                address(uint160(loteryCount[lastEndedLoteryDay][ind].who)),
                amount,
                amount
            );
            lastEndedLoteryDayWithWinner = lastEndedLoteryDay;
            emit loteryWin(
                lastEndedLoteryDay,
                amount,
                winners[lastEndedLoteryDay].who
            );
            //delete loteryCount[lastEndedLoteryDay];
            lastEndedLoteryDay = lastEndedLoteryDay.add(1);
        }
    }

    function loteryCountLen(uint256 day) external view returns (uint256) {
        return loteryCount[day].length;
    }

    function withdrawLotery(uint256 day) public {
        if (winners[day].restAmount != 0) {
            winners[day].who.transfer(winners[day].restAmount);
            winners[day].restAmount = 0;
        }
    }

    uint256 private nonce = 0;

    function _random(uint256 limit) private returns (uint256) {
        uint256 randomnumber =
            uint256(
                keccak256(
                    abi.encodePacked(
                        now,
                        msg.sender,
                        nonce,
                        blockhash(block.number),
                        block.number,
                        block.coinbase,
                        block.difficulty
                    )
                )
            ) % limit;
        nonce = nonce.add(1);
        return randomnumber;
    }

    function endedStakeCount(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return endedStakeLists[stakerAddr].length;
    }

    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr) external view returns (uint256) {
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
    ) internal {
        /* Enforce the maximum stake time */
        require(
            newStakedDays <= MAX_STAKE_DAYS,
            "JACKPOT: newStakedDays higher than maximum"
        );
        uint256 bonusSuns = _stakeStartBonusSuns(newStakedSuns, newStakedDays);
        uint256 newStakeShares = newStakedSuns.add(bonusSuns).mul(SHARE_RATE_SCALE).div(g._shareRate);
        /* Ensure newStakedSuns is enough for at least one stake share */
        require(
            newStakeShares != 0,
            "JACKPOT: newStakedSuns must be at least minimum shareRate"
        );
        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newLockedDay = g._currentDay.add(1);
        /* Create Stake */
        g._latestStakeId = uint40(uint256(g._latestStakeId).add(1));
        uint40 newStakeId = g._latestStakeId;
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
        g._nextStakeSharesTotal = g._nextStakeSharesTotal.add(newStakeShares);
        /* Track total staked Suns for inflation calculations */
        g._lockedSunsTotal = g._lockedSunsTotal.add(newStakedSuns);
    }

    /**
     * @dev Calculates total stake payout including rewards for a multi-day range
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return Payout in Suns
     */
    function calcPayoutRewards(
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    ) public view returns (uint256 payout) {
        uint256 currDay = _currentDay();
        require(beginDay <= currDay, "JACKPOT: Wrong argument for beginDay");
        require(
            endDay <= currDay && beginDay <= endDay,
            "JACKPOT: Wrong argument for endDay"
        );
        require(globals.latestStakeId != 0, "JACKPOT: latestStakeId error.");
        if (beginDay == endDay) return 0;
        uint256 counter;
        uint256 day = beginDay;
        while (day < endDay && day < globals.dailyDataCount) {
            uint256 dayPayout;
            dayPayout =
                dailyData[day].dayPayoutTotal.mul(stakeSharesParam).div(dailyData[day].dayStakeSharesTotal);
            if (counter < 4) {
                counter = counter.add(1);
            }
            /* Eligible to receive bonus */
            else {
                dayPayout =
                    dailyData[day].dayPayoutTotal.mul(stakeSharesParam).div(dailyData[day].dayStakeSharesTotal).mul(BONUS_DAY_SCALE);
                counter = 0;
            }
            payout = payout.add(dayPayout);
            day = day.add(1);
        }
        uint256 dayStakeSharesTotal =
            dailyData[uint256(globals.dailyDataCount).sub(1)].dayStakeSharesTotal;
        if (dayStakeSharesTotal == 0) dayStakeSharesTotal = stakeSharesParam;
        //require(dayStakeSharesTotal != 0, "JACKPOT: dayStakeSharesTotal == 0");
        uint256 dayPayoutTotal =
            dailyData[uint256(globals.dailyDataCount).sub(1)].dayPayoutTotal;
        while (day < endDay) {
            uint256 dayPayout;
            dayPayout =
                dayPayoutTotal.mul(stakeSharesParam).div(dayStakeSharesTotal);
            if (counter < 4) {
                counter = counter.add(1);
            }
            // Eligible to receive bonus
            else {
                dayPayout =
                    dayPayoutTotal.mul(stakeSharesParam).div(dayStakeSharesTotal).mul(BONUS_DAY_SCALE);
                counter = 0;
            }
            payout = payout.add(dayPayout);
            day = day.add(1);
        }
        return payout;
    }

    function calcPayoutRewardsBonusDays(
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    ) external view returns (uint256 payout) {
        uint256 currDay = _currentDay();
        require(beginDay <= currDay, "JACKPOT: Wrong argument for beginDay");
        require(
            endDay <= currDay && beginDay <= endDay,
            "JACKPOT: Wrong argument for endDay"
        );
        require(globals.latestStakeId != 0, "JACKPOT: latestStakeId error.");
        if (beginDay == endDay) return 0;
        uint256 day = beginDay.add(5);
        while (day < endDay && day < globals.dailyDataCount) {
            payout = payout.add(dailyData[day].dayPayoutTotal.mul(stakeSharesParam).div(dailyData[day].dayStakeSharesTotal));
            day = day.add(5);
        }
        uint256 dayStakeSharesTotal =
            dailyData[uint256(globals.dailyDataCount).sub(1)].dayStakeSharesTotal;
        if (dayStakeSharesTotal == 0) dayStakeSharesTotal = stakeSharesParam;
        //require(dayStakeSharesTotal != 0, "JACKPOT: dayStakeSharesTotal == 0");
        uint256 dayPayoutTotal =
            dailyData[uint256(globals.dailyDataCount).sub(1)].dayPayoutTotal;
        while (day < endDay) {
            payout = payout.add(dayPayoutTotal.mul(stakeSharesParam).div(dayStakeSharesTotal));
            day = day.add(5);
        }
        return payout;
    }

    /**
     * @dev Calculates user dividends
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return Payout in Suns
     */
    function calcPayoutDividendsReward(
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    ) public view returns (uint256 payout) {
        uint256 currDay = _currentDay();
        require(beginDay <= currDay, "JACKPOT: Wrong argument for beginDay");
        require(
            endDay <= currDay && beginDay <= endDay,
            "JACKPOT: Wrong argument for endDay"
        );
        require(globals.latestStakeId != 0, "JACKPOT: latestStakeId error.");
        if (beginDay == endDay) return 0;
        uint256 day = beginDay;
        while (day < endDay && day < globals.dailyDataCount) {
            uint256 dayPayout;
            /* user's share of 90% of the day's dividends */
            dayPayout = dayPayout.add(dailyData[day].dayDividends.mul(90).div(100).mul(stakeSharesParam).div(dailyData[day].dayStakeSharesTotal));
            payout = payout.add(dayPayout);
            day = day.add(1);
        }
        uint256 dayStakeSharesTotal =
            dailyData[uint256(globals.dailyDataCount).sub(1)].dayStakeSharesTotal;
        if (dayStakeSharesTotal == 0) dayStakeSharesTotal = stakeSharesParam;
        //require(dayStakeSharesTotal != 0, "JACKPOT: dayStakeSharesTotal == 0");
        while (day < endDay) {
            uint256 dayPayout;
            /* user's share of 90% of the day's dividends */
            dayPayout = dayPayout.add(xfLobby[day].mul(90).div(100).mul(stakeSharesParam).div(dayStakeSharesTotal));
            payout = payout.add(dayPayout);
            day = day.add(1);
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
            Bonus percentage scaled 0% to 10% for the first 7M JACKPOT of stake.
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
            cappedExtraDays = newStakedDays.sub(1) <= LPB_MAX_DAYS
                ? newStakedDays.sub(1)
                : LPB_MAX_DAYS;
        }
        uint256 cappedStakedSuns =
            newStakedSuns <= BPB_MAX_SUNS ? newStakedSuns : BPB_MAX_SUNS;
        bonusSuns = cappedExtraDays.mul(BPB).add(cappedStakedSuns.mul(LPB));
        bonusSuns = newStakedSuns.mul(bonusSuns).div(LPB.mul(BPB));
        return bonusSuns;
    }

    function _stakeUnlock(GlobalsCache memory g, StakeCache memory st)
        private
        pure
    {
        g._stakeSharesTotal = g._stakeSharesTotal.sub(st._stakeShares);
        st._unlockedDay = g._currentDay;
    }

    function _stakePerformance(
        GlobalsCache memory g,
        StakeCache memory st,
        uint256 servedDays
    )
        private
        view
        returns (
            uint256 stakeReturn,
            uint256 payout,
            uint256 dividends,
            uint256 penalty,
            uint256 cappedPenalty
        )
    {
        if (servedDays < st._stakedDays) {
            (payout, penalty) = _calcPayoutAndEarlyPenalty(
                g,
                st._lockedDay,
                st._stakedDays,
                servedDays,
                st._stakeShares
            );
            stakeReturn = st._stakedSuns.add(payout);
            dividends = calcPayoutDividendsReward(
                st._stakeShares,
                st._lockedDay,
                st._lockedDay.add(servedDays)
            );
        } else {
            // servedDays must == stakedDays here
            payout = calcPayoutRewards(
                st._stakeShares,
                st._lockedDay,
                st._lockedDay.add(servedDays)
            );
            dividends = calcPayoutDividendsReward(
                st._stakeShares,
                st._lockedDay,
                st._lockedDay.add(servedDays)
            );
            stakeReturn = st._stakedSuns.add(payout);
            penalty = _calcLatePenalty(
                st._lockedDay,
                st._stakedDays,
                st._unlockedDay,
                stakeReturn
            );
        }
        if (penalty != 0) {
            if (penalty > stakeReturn) {
                /* Cannot have a negative stake return */
                cappedPenalty = stakeReturn;
                stakeReturn = 0;
            } else {
                /* Remove penalty from the stake return */
                cappedPenalty = penalty;
                stakeReturn = stakeReturn.sub(cappedPenalty);
            }
        }
        return (stakeReturn, payout, dividends, penalty, cappedPenalty);
    }

    function getUnstakeParams(
        address user,
        uint256 stakeIndex,
        uint40 stakeIdParam
    )
        external
        view
        returns (
            uint256 stakeReturn,
            uint256 payout,
            uint256 dividends,
            uint256 penalty,
            uint256 cappedPenalty
        )
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        StakeStore[] storage stakeListRef = stakeLists[user];
        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "JACKPOT: Empty stake list");
        require(
            stakeIndex < stakeListRef.length,
            "JACKPOT: stakeIndex invalid"
        );
        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);
        uint256 servedDays = 0;
        bool prevUnlocked = (st._unlockedDay != 0);
        //return (stakeReturn, payout, dividends, penalty, cappedPenalty);
        if (g._currentDay >= st._lockedDay) {
            if (prevUnlocked) {
                /* Previously unlocked in stakeGoodAccounting(), so must have served full term */
                servedDays = st._stakedDays;
            } else {
                _stakeUnlock(g, st);
                servedDays = g._currentDay.sub(st._lockedDay);
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays;
                }
            }
            (
                stakeReturn,
                payout,
                dividends,
                penalty,
                cappedPenalty
            ) = _stakePerformance(g, st, servedDays);
        } else {
            /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
            stakeReturn = st._stakedSuns;
        }
        return (stakeReturn, payout, dividends, penalty, cappedPenalty);
    }

    function _calcPayoutAndEarlyPenalty(
        GlobalsCache memory g,
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 servedDays,
        uint256 stakeSharesParam
    ) private view returns (uint256 payout, uint256 penalty) {
        uint256 servedEndDay = lockedDayParam.add(servedDays);
        /* 50% of stakedDays (rounded up) with a minimum applied */
        uint256 penaltyDays = stakedDaysParam.add(1).div(2);
        if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
            penaltyDays = EARLY_PENALTY_MIN_DAYS;
        }
        if (servedDays == 0) {
            /* Fill penalty days with the estimated average payout */
            uint256 expected = _estimatePayoutRewardsDay(g, stakeSharesParam);
            penalty = expected.mul(penaltyDays);
            return (payout, penalty); // Actual payout was 0
        }
        if (penaltyDays < servedDays) {
            /*
                Simplified explanation of intervals where end-day is non-inclusive:
                penalty:    [lockedDay  ...  penaltyEndDay)
                delta:                      [penaltyEndDay  ...  servedEndDay)
                payout:     [lockedDay  .......................  servedEndDay)
            */
            uint256 penaltyEndDay = lockedDayParam.add(penaltyDays);
            penalty = calcPayoutRewards(
                stakeSharesParam,
                lockedDayParam,
                penaltyEndDay
            );
            uint256 delta =
                calcPayoutRewards(
                    stakeSharesParam,
                    penaltyEndDay,
                    servedEndDay
                );
            payout = penalty.add(delta);
            return (payout, penalty);
        }
        /* penaltyDays >= servedDays  */
        payout = calcPayoutRewards(
            stakeSharesParam,
            lockedDayParam,
            servedEndDay
        );
        if (penaltyDays == servedDays) {
            penalty = payout;
        } else {
            /*
                (penaltyDays > servedDays) means not enough days served, so fill the
                penalty days with the average payout from only the days that were served.
            */
            penalty = payout.mul(penaltyDays).div(servedDays);
        }
        return (payout, penalty);
    }

    function _calcLatePenalty(
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 unlockedDayParam,
        uint256 rawStakeReturn
    ) private pure returns (uint256) {
        /* Allow grace time before penalties accrue */
        uint256 maxUnlockedDay =
            lockedDayParam.add(stakedDaysParam).add(LATE_PENALTY_GRACE_DAYS);
        if (unlockedDayParam <= maxUnlockedDay) {
            return 0;
        }
        /* Calculate penalty as a percentage of stake return based on time */
        return rawStakeReturn.mul(unlockedDayParam.sub(maxUnlockedDay)).div(LATE_PENALTY_SCALE_DAYS);
    }

    function _shareRateUpdate(
        GlobalsCache memory g,
        StakeCache memory st,
        uint256 stakeReturn
    ) private {
        if (stakeReturn > st._stakedSuns) {
            /*
                Calculate the new shareRate that would yield the same number of shares if
                the user re-staked this stakeReturn, factoring in any bonuses they would
                receive in stakeStart().
            */
            uint256 bonusSuns =
                _stakeStartBonusSuns(stakeReturn, st._stakedDays);
            uint256 newShareRate =
                stakeReturn.add(bonusSuns).mul(SHARE_RATE_SCALE).div(st._stakeShares);
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
    function xfLobbyEnter(address referrerAddr) external payable {
        require(now >= LAUNCH_TIME, "JACKPOT: Too early");
        uint256 enterDay = _currentDay();
        require(enterDay < 365, "JACKPOT: Auction only first 365 days");
        if (firstAuction == uint256(-1)) firstAuction = enterDay;
        if (enterDay >= 1) endLoteryDay(enterDay.sub(1));
        uint256 rawAmount = msg.value;
        require(rawAmount != 0, "JACKPOT: Amount required");
        address sender = _msgSender();
        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][sender];
        uint256 entryIndex = qRef.tailIndex++;
        qRef.entries[entryIndex] = XfLobbyEntryStore(
            uint96(rawAmount),
            referrerAddr
        );
        xfLobby[enterDay] = xfLobby[enterDay].add(rawAmount);
        uint256 dayNumberNow = whatDayIsItToday(enterDay);
        //uint256 dayNumberNow = 1;
        bool is_good = block.timestamp.sub(LAUNCH_TIME) % ROUND_TIME <= LOTERY_ENTRY_TIME;
        /* if (is_good)
        {
            is_good = false;
            uint256 len = stakeLists[sender].length;
            for(uint256 i = 0; i < len && is_good == false; ++i)
            {
                uint256 _stakedDays = stakeLists[sender][i].stakedDays;
                uint256 _lockedDay = stakeLists[sender][i].lockedDay;
                if (_stakedDays >= 5 &&
                    _lockedDay + _stakedDays >= enterDay)
                    is_good = true;
            }
        } */
        if (
            is_good &&
            dayNumberNow % 2 == 1 &&
            loteryLobby[enterDay][sender].chanceCount == 0
        ) {
            loteryLobby[enterDay][sender].change = 0;
            loteryLobby[enterDay][sender].chanceCount = 1;
            dayChanceCount[enterDay] = dayChanceCount[enterDay].add(1);
            loteryCount[enterDay].push(LoteryCount(sender, 1));

            _updateLoteryDayWaitingForWinner(enterDay);

            //loteryDayWaitingForWinner = enterDay;
            emit loteryLobbyEnter(block.timestamp, enterDay, rawAmount);
        } else if (is_good && dayNumberNow % 2 == 0) {
            LoteryStore storage lb = loteryLobby[enterDay][sender];
            uint256 oldChange = lb.change;
            lb.change = oldChange.add(rawAmount) % 1 ether;
            uint256 newEth = oldChange.add(rawAmount).div(1 ether);
            if (newEth > 0) {
                lb.chanceCount = lb.chanceCount.add(newEth);
                dayChanceCount[enterDay] = dayChanceCount[enterDay].add(newEth);
                loteryCount[enterDay].push(LoteryCount(sender, newEth));

                _updateLoteryDayWaitingForWinner(enterDay);

                //loteryDayWaitingForWinner = enterDay;
                emit loteryLobbyEnter(block.timestamp, enterDay, rawAmount);
            }
        }
        emit XfLobbyEnter(block.timestamp, enterDay, entryIndex, rawAmount);
    }

    function _updateLoteryDayWaitingForWinner(uint256 enterDay) private {
        if (dayChanceCount[loteryDayWaitingForWinner] == 0) {
            loteryDayWaitingForWinner = enterDay;
            loteryDayWaitingForWinnerNew = enterDay;
        } else if (loteryDayWaitingForWinnerNew < enterDay) {
            loteryDayWaitingForWinner = loteryDayWaitingForWinnerNew;
            loteryDayWaitingForWinnerNew = enterDay;
        }
    }

    function whatDayIsItToday(uint256 day) public view returns (uint256) {
        return dayNumberBegin.add(day) % 7;
    }

    /**
     * @dev PUBLIC FACING: Leave the transform lobby after the round is complete
     * @param enterDay Day number when the member entered
     * @param count Number of queued-enters to exit (optional; 0 for all)
     */
    function xfLobbyExit(uint256 enterDay, uint256 count) external {
        uint256 currDay = _currentDay();
        require(enterDay < currDay, "JACKPOT: Round is not complete");
        if (currDay >= 1) endLoteryDay(currDay.sub(1));
        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];
        uint256 headIndex = qRef.headIndex;
        uint256 endIndex;
        if (count != 0) {
            require(
                count <= uint256(qRef.tailIndex).sub(headIndex),
                "JACKPOT: count invalid"
            );
            endIndex = headIndex.add(count);
        } else {
            endIndex = qRef.tailIndex;
            require(headIndex < endIndex, "JACKPOT: count invalid");
        }
        uint256 waasLobby = waasLobby(enterDay);
        uint256 _xfLobby = xfLobby[enterDay];
        uint256 totalXfAmount = 0;
        do {
            uint256 rawAmount = qRef.entries[headIndex].rawAmount;
            address referrerAddr = qRef.entries[headIndex].referrerAddr;
            //delete qRef.entries[headIndex];
            uint256 xfAmount = waasLobby.mul(rawAmount).div(_xfLobby);
            if (
                (referrerAddr == address(0) || referrerAddr == msg.sender) &&
                defaultReferrerAddr == address(0)
            ) {
                /* No referrer or Self-referred */
                _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
            } else {
                if (referrerAddr == address(0) || referrerAddr == msg.sender) {
                    uint256 referrerBonusSuns = xfAmount.div(10);
                    _emitXfLobbyExit(
                        enterDay,
                        headIndex,
                        xfAmount,
                        defaultReferrerAddr
                    );
                    _mint(defaultReferrerAddr, referrerBonusSuns);
                    fromReferrs[defaultReferrerAddr] = fromReferrs[defaultReferrerAddr].add(referrerBonusSuns);
                } else {
                    /* Referral bonus of 10% of xfAmount to member */
                    xfAmount = xfAmount.add(xfAmount.div(10));
                    /* Then a cumulative referrer bonus of 10% to referrer */
                    uint256 referrerBonusSuns = xfAmount.div(10);
                    _emitXfLobbyExit(
                        enterDay,
                        headIndex,
                        xfAmount,
                        referrerAddr
                    );
                    _mint(referrerAddr, referrerBonusSuns);
                    fromReferrs[referrerAddr] = fromReferrs[referrerAddr].add(referrerBonusSuns);
                }
            }
            totalXfAmount = totalXfAmount.add(xfAmount);
        } while (++headIndex < endIndex);
        qRef.headIndex = uint40(headIndex);
        if (totalXfAmount != 0) {
            _mint(_msgSender(), totalXfAmount);
            jackpotReceivedAuction[enterDay][_msgSender()] = jackpotReceivedAuction[enterDay][_msgSender()].add(totalXfAmount);
        }
    }

    /**
     * @dev PUBLIC FACING: External helper to return multiple values of xfLobby[] with
     * a single call
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return Fixed array of values
     */
    /* function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list)
    {
        require(
            beginDay < endDay && endDay <= _currentDay(),
            "JACKPOT: invalid range"
        );
        list = new uint256[](endDay - beginDay);
        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            list[dst++] = uint256(xfLobby[src++]);
        } while (src < endDay);
        return list;
    } */
    /**
     * @dev PUBLIC FACING: Release 7.5% dev share from daily dividends
     */
    function xfFlush() external onlyOwner {
        if (LAST_FLUSHED_DAY < firstAuction.add(2))
            LAST_FLUSHED_DAY = firstAuction.add(2);
        require(address(this).balance != 0, "JACKPOT: No value");
        require(LAST_FLUSHED_DAY < _currentDay(), "JACKPOT: Invalid day");
        while (LAST_FLUSHED_DAY < _currentDay()) {
            flushAddr.transfer(xfLobby[LAST_FLUSHED_DAY].mul(75).div(1000));
            LAST_FLUSHED_DAY = LAST_FLUSHED_DAY.add(1);
        }
    }

    /**
     * @dev PUBLIC FACING: Return a current lobby member queue entry.
     * Only needed due to limitations of the standard ABI encoder.
     * @param memberAddr TRX address of the lobby member
     * @param enterDay asdsadsa
     * @param entryIndex asdsadad
     * @return 1: Raw amount that was entered with; 2: Referring TRX addr (optional; 0x0 for no referrer)
     */
    function xfLobbyEntry(
        address memberAddr,
        uint256 enterDay,
        uint256 entryIndex
    ) external view returns (uint256 rawAmount, address referrerAddr) {
        XfLobbyEntryStore storage entry =
            xfLobbyMembers[enterDay][memberAddr].entries[entryIndex];
        require(entry.rawAmount != 0, "JACKPOT: Param invalid");
        return (entry.rawAmount, entry.referrerAddr);
    }

    function waasLobby(uint256 enterDay)
        public
        pure
        returns (uint256 _waasLobby)
    {
        /* 410958904109 = ~ 1500000 * SUNS_PER_JACKPOT / 365 */
        if (enterDay >= 0 && enterDay <= 365) {
            _waasLobby = CLAIM_STARTING_AMOUNT.sub(enterDay.mul(410958904109));
        } else {
            _waasLobby = CLAIM_LOWEST_AMOUNT;
        }
        return _waasLobby;
    }

    function _emitXfLobbyExit(
        uint256 enterDay,
        uint256 entryIndex,
        uint256 xfAmount,
        address referrerAddr
    ) private {
        emit XfLobbyExit(
            block.timestamp,
            enterDay,
            entryIndex,
            xfAmount,
            referrerAddr
        );
    }
}

contract Jackpot is TransformableToken {
    constructor(
        uint256 _LAUNCH_TIME,
        uint256 _dayNumberBegin,
        uint256 _ROUND_TIME,
        uint256 _LOTERY_ENTRY_TIME
    ) public {
        require(_dayNumberBegin > 0 && _dayNumberBegin < 7);
        LAUNCH_TIME = _LAUNCH_TIME;
        dayNumberBegin = _dayNumberBegin;
        ROUND_TIME = _ROUND_TIME;
        LOTERY_ENTRY_TIME = _LOTERY_ENTRY_TIME;
        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(SHARE_RATE_SCALE);
        uint256 currDay;
        if (block.timestamp < _LAUNCH_TIME)
            currDay = 0;
        else
            currDay = _currentDay();
        lastEndedLoteryDay = currDay;
        globals.dailyDataCount = uint16(currDay);
        lastEndedLoteryDayWithWinner = currDay;
        loteryDayWaitingForWinner = currDay;
        loteryDayWaitingForWinnerNew = currDay;
    }

    function() external payable {}

    function setDefaultReferrerAddr(address _defaultReferrerAddr)
        external
        onlyOwner
    {
        defaultReferrerAddr = _defaultReferrerAddr;
    }

    function setFlushAddr(address payable _flushAddr) external onlyOwner {
        flushAddr = _flushAddr;
    }

    function getDayUnixTime(uint256 day) external view returns (uint256) {
        return LAUNCH_TIME.add(day.mul(ROUND_TIME));
    }

    function getFirstAuction() external view returns (bool, uint256) {
        if (firstAuction == uint256(-1)) return (false, 0);
        else return (true, firstAuction);
    }

    bool private isFirstTwoDaysWithdrawed = false;

    function ownerClaimFirstTwoDays() external onlyOwner onlyAfterNDays(2) {
        require(
            isFirstTwoDaysWithdrawed == false,
            "JACKPOT: Already withdrawed"
        );

        flushAddr.transfer(xfLobby[firstAuction].add(xfLobby[firstAuction.add(1)]));

        isFirstTwoDaysWithdrawed = true;
    }
}