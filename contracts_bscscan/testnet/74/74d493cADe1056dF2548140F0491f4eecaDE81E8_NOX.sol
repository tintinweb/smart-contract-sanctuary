pragma solidity ^0.8.10;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender); // added payable
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}



interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function addLiquidity(  
        address tokenA,  
        address tokenB,  
        uint amountADesired,  
        uint amountBDesired,  
        uint amountAMin,  
        uint amountBMin,  
        address to,  
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IAuctionContract {
    function checkDonatorBusdCredit(address addr) external view returns (uint256);
    function deductDonatorBusdCredit(address addr, uint256 amount) external;
}



contract BEP20Token is Context {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply = 0;
  uint8 private _decimals = 18;
  string private _symbol;
  string private _name;

  event Transfer(
      address indexed from,
      address indexed to,
      uint256 value
  );

  event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
  );

  constructor (string memory tokenName, string memory tokenSymbol) {
    _name = tokenName;
    _symbol = tokenSymbol;
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
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
   * problems described in {BEP20-approve}.
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
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
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
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
    require(account != address(0), "BEP20: mint to the zero address");

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
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

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
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}



abstract contract Events {


    event dayUpdated(
        uint256 year,
        uint256 dayOfYear,
        uint256 indexed tokenDay,
        uint256 tokenYear
    );
    
    event stakeCreated(
        bytes16 indexed stakeId,
        address indexed stakerAddress,
        uint256 stakeAmount,
        uint256 investedAmountInBusd,
        uint256 indexed stakeTokenDay
    );
    
    event stakeMoved(
        bytes16 indexed stakeId,
        address indexed sender,
        address indexed receiver,
        uint256 tokenDay
    );
    
    event stakeSplit(
        bytes16 indexed stakeId,
        bytes16 indexed newStakeId,
        uint256 splitDivisor,
        address indexed stakerAddress,
        uint256 tokenDay
    );
    
    event stakesMerged(
        bytes16 indexed stake1Id,
        bytes16 indexed stake2Id,
        address stakerAddress,
        uint256 tokenDay
    );
    
    event stakeEnded(
        bytes16 indexed stakeId,
        address indexed stackerAddress,
        uint256 mintedTokens,
        uint256 indexed tokenDay
    );
    
    event sharePriceUpdated(
        bytes16 indexed stakeId,
        uint256 indexed tokenDay,
        uint256 newSharePrice);
}


// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00 - Contract Instance
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @dev Abstract contract that contains all required BokkyPooBah's library functions
 */
abstract contract DateTime is BEP20Token{
    using SafeMath for uint256;

    
    uint256 INTERNAL_TESTING_NOW;
    function GET_INTERNAL_TESTING_NOW_TO_REMOVE() public view returns(uint timestamp) {
        return INTERNAL_TESTING_NOW;
    }
    function SET_INTERNAL_TESTING_NOW_TO_REMOVE(uint256 timestamp) public {
        INTERNAL_TESTING_NOW = timestamp;
    }
    function ADD_DAYS_TO_INTERNAL_TESTING_NOW_TO_REMOVE(uint256 numDays) public {
        INTERNAL_TESTING_NOW = addDays(INTERNAL_TESTING_NOW, numDays);
    }

    function _now() internal view returns (uint timestamp) {
        timestamp = block.timestamp;
    }
    
    function isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = BokkyPooBahsDateTimeLibrary._isLeapYear(year);
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        year = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
    }
    function getMonth(uint timestamp) public pure returns (uint month) {
        month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
    }
    function getDay(uint timestamp) public pure returns (uint day) {
        day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
    }
    
    function getDayOfYear(uint timestamp) public pure returns(uint day) {
        day = BokkyPooBahsDateTimeLibrary.getDayOfYear(timestamp);
    }

    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, _days);
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        _minutes = BokkyPooBahsDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }
}



abstract contract Calendar is DateTime, Events {
    
    enum Season {
        Winter,
        Spring,
        Summer,
        Autumn
    }


    uint256 constant SEASON_SIZE = 91;
    
    
    //01-01-2022 12:00PM EST
    uint256 public TokenStartTimestamp;

    uint256 public CurrentTokenDay = 1;

    uint256 public CurrentTokenYear = 1;

    uint256 public CurrentDayOfYear;

    uint256 public CurrentYear;
    
    function getCurrentTokenDay() public view returns(uint256) {
        return CurrentTokenDay;
    }

    function _getSeasonForDay(uint256 day) internal pure returns (Season) {
        if (day <= SEASON_SIZE) return Season.Winter;
        if (day <= SEASON_SIZE * 2) return Season.Spring;
        if (day <= SEASON_SIZE * 3) return Season.Summer;
        return Season.Autumn;
    }
    
    //interest is generated all year except during harvest
    function canInterestBeGeneratedForDay(uint256 dayOfYear) public pure returns (bool) {
        Season currentSeason = _getSeasonForDay(dayOfYear);
        return currentSeason != Season.Autumn;
    }
    
    //ending stakes has penalties all year except during harvest
    function endingStakesHasPenaltiesForDay(uint256 dayOfYear) public pure returns (bool) {
        Season currentSeason = _getSeasonForDay(dayOfYear);
        return currentSeason != Season.Autumn;
    }

    //stakes can be created all year except during harvest
    function canStakesBeCreatedForDay(uint256 dayOfYear) public pure returns (bool) {
        Season currentSeason = _getSeasonForDay(dayOfYear);
        return currentSeason != Season.Autumn;
    }
}


abstract contract Data is Calendar {
    
    IBEP20 public BUSD_CONTRACT;
    IBEP20 public AUCTION_CONTRACT;
    
    address internal M_ADDRESS1;
    address internal M_ADDRESS2;

    uint256 constant internal PRECISION_RATE = 1E18;
    uint256 constant internal REF_NUMERATOR = 1;
    uint256 constant internal REF_DENOMINATOR = 10;
    uint256 constant internal POOL_NUMERATOR = 8;
    uint256 constant internal POOL_DENOMINATOR = 10;
    uint256 constant internal M_NUMERATOR = 1;
    uint256 constant internal M_DENOMINATOR = 20;
    uint256 constant internal SHARE_PRICE_PRECISION = 1E5;
    uint256 constant internal INITIAL_SHARE_PRICE = SHARE_PRICE_PRECISION;
    uint256 constant internal SHARE_PRICE_MAX = 1E40;
    uint256 constant internal DEFAULT_TOKEN_BUSD_RATIO = 100000;
    
    uint256 public CurrentSharePrice;
    uint256 public SharesAccounting;
    uint256 public TokensStakedAccounting;
    uint256 public TotalTokensMintedToReferrals;
    
    
    enum StakeState {
        Active,
        InAccounting,
        Closed,
        Moved,
        Merged
    }
    
    struct Stake {
        bytes16 stakeId;
        uint256 stakeAmount;
        uint256 shares;
        uint256 investmentAmountInBusd;
        StakeState stakeState;
        uint256 interestAmount;
        uint256 stakeStartTokenDay;
        uint256 numDaysAccountedFor;
        uint256 accountingStartTokenDay;
        uint256 accountingStartDayOfYear;
        uint256 accountingStartTokenYear;
    }

    struct Inflation {
        uint256 numerator;
        uint256 denominator;
        uint256 totalShares;
        uint256 totalSupply;
        uint256 tokensStakedAccounting;
    }
    
    struct PoolRatio {
        uint256 amountToken;
        uint256 amountBusd;
        uint256 timestamp;
    }
    
    mapping(address => mapping(bytes16 => Stake)) public stakes;
    mapping(address => uint256) public stakeCount;
    mapping(address => address) public referrals;
    mapping(address => uint256) public tokensMintedToReferrals;
    mapping(uint256 => Inflation) public dailyInflations;
    mapping(address => uint256) public totalStakedByAccounts;
    
    uint256 public ActiveStakesAccounting;
    
    uint8 public PoolRatioPos = 0;
    PoolRatio[] public Last100SampledPoolRatios;


    function _cloneStake(Stake memory origin, Stake memory destination) internal pure {
        destination.stakeId = origin.stakeId;
        destination.stakeAmount = origin.stakeAmount;
        destination.shares = origin.shares;
        destination.investmentAmountInBusd = origin.investmentAmountInBusd;
        destination.stakeState = origin.stakeState;
        destination.interestAmount = origin.interestAmount;
        destination.stakeStartTokenDay = origin.stakeStartTokenDay;
        destination.numDaysAccountedFor = origin.numDaysAccountedFor;
        destination.accountingStartTokenDay = origin.accountingStartTokenDay;
        destination.accountingStartDayOfYear = origin.accountingStartDayOfYear;
        destination.accountingStartTokenYear = origin.accountingStartTokenYear;
    }
    

    function getDefaultTokenBusdRatio() external pure returns(uint256){
        return DEFAULT_TOKEN_BUSD_RATIO;
    }
}


abstract contract Interest is Data {

    using SafeMath for uint256;


     function calculatePenaltyForEndingStakesAtDayOfYear(uint256 tokenYear, uint256 dayOfYear) public pure returns (uint256 numerator, uint256 denominator) {
        //if we are in harvest there are no penalties thus return 0/1
        if(!endingStakesHasPenaltiesForDay(dayOfYear)) return (0,1);
        
        
        uint256 totalPeriodSize = SEASON_SIZE * 3;
        
        uint256 firstDayOfYear = 1;
        uint256 numDaysElapsedFromYearStart = dayOfYear - firstDayOfYear; //lowest value will be 0
        uint256 numDaysRemainingForHarvest = totalPeriodSize - numDaysElapsedFromYearStart;
        
        //year 1 = 1/4 (75% reduction); year two = 3/4 (25% reduction); onwards = 1/1 (no reduction)
        uint256 penaltyReductorNumerator = tokenYear == 2 ? 3 : 1;
        uint256 penaltyReductorDenominator = tokenYear < 3 ? 4 : 1;
        
        //ajusts the number of days hence decreasing the penalty if it's the case
        //this division never results in a division by zero
        uint256 numDaysAdjusted = numDaysRemainingForHarvest.mul(penaltyReductorNumerator).div(penaltyReductorDenominator);
        
        return (numDaysAdjusted, totalPeriodSize);
    }
     

    function calculatePrincipalAndInterestIfClosingStakeToday(address addr, bytes16 stakeId, uint256 numDaysToAccountFor) public view returns(uint256 principal, uint256 interest) {
        Stake storage stake = stakes[addr][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Address does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active || stake.stakeState == StakeState.InAccounting, "Stake is not active nor in accounting");
        
        uint256 accountStakeUntilDayOfYear = stake.stakeState == StakeState.InAccounting ? stake.accountingStartDayOfYear : CurrentDayOfYear;
        uint256 accountStakeUntilTokenYear = stake.stakeState == StakeState.InAccounting ? stake.accountingStartTokenYear : CurrentTokenYear;
        
        (principal, interest) = getPrincipalAndInterestForStake(addr, stakeId, numDaysToAccountFor);

        //if the stake is being ended on the same token day it was created, there are no penalties
        if(stake.stakeStartTokenDay == CurrentTokenDay) {
            return (stake.stakeAmount, stake.interestAmount);
        }

        //outside harvest there are penalties for ending stakes. 
        if(endingStakesHasPenaltiesForDay(accountStakeUntilDayOfYear)) {
            //penalize principal corresponding to how many days are left until last day before harvest
            
            (uint256 numerator, uint256 denominator) = calculatePenaltyForEndingStakesAtDayOfYear(accountStakeUntilTokenYear, accountStakeUntilDayOfYear);
            
            //remove from the principal the quantity represented by the fraction of penalty to apply
            //the denominator applied as a divisor is a constant in the function that returned it, therefore this divisision never results in a division by zero
            principal = principal.sub(principal.mul(numerator).div(denominator));
        }
        
        return (principal, interest);
    }

    
    function getPrincipalAndInterestForStake(address addr, bytes16 stakeId, uint256 numDaysToAccountFor) public view returns (uint256 principal, uint256 interest) {
        Stake storage stake = stakes[addr][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Address does not contain stake with provided id");

        interest = stake.interestAmount;
        principal = stake.stakeAmount;
        
        if(stake.stakeState == StakeState.Closed || stake.stakeState == StakeState.Moved || stake.stakeState == StakeState.Merged) return (principal, interest);
        
        
        uint256 accountStakeUntilTokenDay = stake.stakeState == StakeState.InAccounting ? stake.accountingStartTokenDay : CurrentTokenDay;

        
        for(uint256 i = stake.stakeStartTokenDay + stake.numDaysAccountedFor; i < accountStakeUntilTokenDay; i++) {
        
            if(numDaysToAccountFor == 0) break;
            
            interest = interest.add(
                
                    dailyInflations[i].totalSupply.add(dailyInflations[i].tokensStakedAccounting)
                    .mul(dailyInflations[i].numerator)
                
                    .mul(stake.shares)
                    .div(dailyInflations[i].denominator)
                
                    .div(dailyInflations[i].totalShares));
            
            
            numDaysToAccountFor--;
        }

        return (principal, interest);
    }
    
    
    function getTodaysGlobalInflationRate() public view returns (uint256 numerator, uint256 denominator) {
        return _calculateGlobalInflationRateForTokenYearAndDayOfYear(CurrentTokenYear, CurrentDayOfYear);
    }

    
    function _calculateGlobalInflationRateForTokenYearAndDayOfYear(uint256 tokenYear, uint256 dayOfYear) internal pure returns (uint256 numerator, uint256 denominator) {
        
        //During harvest season no interest is generated
        if (!canInterestBeGeneratedForDay(dayOfYear)) {
            return (0,1);
        }
        
        //Since inflation changes every season for the first 6 years, this implementation was used to avoid a long if/else chain
        uint32[19] memory numerators = [uint32(18315018), 14652015,10989011,7326007,3663004,3296703,2930403,2564103,2197802,1831502,1465201,1098901,732601,366300,329670,293040,256410,219780,146520];
        uint8 index = _getSeasonForDay(dayOfYear) == Season.Winter ? 1 : _getSeasonForDay(dayOfYear) == Season.Spring ? 2 : 3;
        uint8 posCalc = uint8((tokenYear-1)*3 + index);
        uint8 pos = posCalc < 19 ? posCalc : 19;
        return (numerators[pos-1], 1000000000);
        
        
    
    }
    
    
    function getInvestmentRateForTokenPerYear(uint256 tokenYear) public pure returns(uint256 numerator, uint256 denominator) {
        
        uint32[6] memory numerators = [uint32(2500000), 1250000, 625000, 312500, 156250, 78125];
        uint8 pos = uint8(tokenYear < 6 ? tokenYear : 6);
        return (numerators[pos-1], 10000000);
        
    
    }
}



abstract contract Helper is Interest {
    
    function _toBytes16(uint256 x) internal pure returns (bytes16 b) {
       return bytes16(bytes32(x));
    }
    
    function generateID(address x, uint256 y, bytes1 z) internal pure returns (bytes16 b) {
        b = _toBytes16(
            uint256(
                keccak256(
                    abi.encodePacked(x, y, z)
                )
            )
        );
    }
    
    function _notContract(address _addr) internal view returns (bool) {
        uint32 size; assembly { size := extcodesize(_addr) } return (size == 0); }
}



abstract contract PoolMgmt is Helper
{
    using SafeMath for uint256;
    
    IUniswapV2Pair public UNISWAP_PAIR;
    IUniswapV2Router02 public UNISWAP_ROUTER;
    address public FACTORY;


    function hasPoolBeenCreated() public view returns (bool) {
        return IUniswapV2Factory(UNISWAP_ROUTER.factory()).getPair(address(this), address(BUSD_CONTRACT)) != address(0x0);
    }
    

    function createPool() external {
        require(msg.sender == address(AUCTION_CONTRACT), "Not authorized");
        if(!hasPoolBeenCreated()) {
            _createPool();
        }
    }
    

    function _createPool() private {
        UNISWAP_PAIR = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(address(this), address(BUSD_CONTRACT)));
    }
    


    function registerPoolRatio() public returns (uint256 tokenAmount, uint256 busdAmount, uint256 timestamp) {
        
        tokenAmount = 0;
        busdAmount = 0;
        timestamp = 0;

        
        if(!hasPoolBeenCreated()) {
            return (tokenAmount, busdAmount, timestamp);
        }

        timestamp = _now();

        if (Last100SampledPoolRatios.length > 0) 
        {
            PoolRatio storage lastSample = Last100SampledPoolRatios[Last100SampledPoolRatios.length - 1];

            
            if (lastSample.timestamp > timestamp) return (tokenAmount, busdAmount, timestamp);

            
            if(diffMinutes(lastSample.timestamp, timestamp) < 1) return (tokenAmount, busdAmount, timestamp);
        }
        
        (uint256 reserveIn, uint256 reserveOut, ) = UNISWAP_PAIR.getReserves(); // reserveIn SHOULD be TOKEN, may be BUSD
        
        if(UNISWAP_PAIR.token0() == address(this)) {
            tokenAmount = reserveIn;
            busdAmount = reserveOut;
        }
        else {
            tokenAmount = reserveOut;
            busdAmount = reserveIn;
        }
        
        PoolRatio memory newPoolRatio = PoolRatio(tokenAmount, busdAmount, timestamp);
        
        
        uint256 maxSize = 3;
        
        
        if(Last100SampledPoolRatios.length < maxSize) {
            Last100SampledPoolRatios.push(newPoolRatio);
        }
        
        else {
            Last100SampledPoolRatios[PoolRatioPos] = newPoolRatio;
            PoolRatioPos++;
            if(PoolRatioPos == maxSize) PoolRatioPos = 0;
        }

        return (tokenAmount, busdAmount, timestamp);
    }


    function getPoolAvg() public view returns (uint256, uint256) {
        
        
        if (Last100SampledPoolRatios.length == 0) return (DEFAULT_TOKEN_BUSD_RATIO, 1);
        uint256 poolTokenAvg = 0;
        uint256 poolBusdAvg = 0;

        for(uint256 i = 0; i < Last100SampledPoolRatios.length; i++) {
            poolTokenAvg = poolTokenAvg.add(Last100SampledPoolRatios[i].amountToken);
            poolBusdAvg = poolBusdAvg.add(Last100SampledPoolRatios[i].amountBusd);
        }

        
        poolTokenAvg = poolTokenAvg.div(Last100SampledPoolRatios.length);
        poolBusdAvg = poolBusdAvg.div(Last100SampledPoolRatios.length);
        
        
        if(poolBusdAvg == 0) return (DEFAULT_TOKEN_BUSD_RATIO, 1);


        
        if(poolTokenAvg == 0) return (1, DEFAULT_TOKEN_BUSD_RATIO);

        return (poolTokenAvg, poolBusdAvg);
    }
    
    
    function fillLiquidityPool() public {
        (uint256 poolTokenAvg, uint256 poolBusdAvg) = getPoolAvg();
        _fillLiquidityPool(poolTokenAvg, poolBusdAvg);
    }
    

    function _fillLiquidityPool(uint256 poolTokenAvg, uint256 poolBusdAvg) internal {
        
        uint256 tokenAmount = 0;
        uint256 busdAmount = BUSD_CONTRACT.balanceOf(address(this));
        
    
        if(busdAmount < 1E18) return;
        
        if(!hasPoolBeenCreated()) {
            _createPool();
            
            
            tokenAmount = busdAmount.mul(DEFAULT_TOKEN_BUSD_RATIO);
        }
        else {
    
            tokenAmount = busdAmount.mul(poolTokenAvg).div(poolBusdAvg);
        }
        
    
        _mint(address(this), tokenAmount);
        _approve(address(this), address(UNISWAP_ROUTER), tokenAmount);
        BUSD_CONTRACT.approve(address(UNISWAP_ROUTER), busdAmount);
        
        UNISWAP_ROUTER.addLiquidity(
            address(this),
            address(BUSD_CONTRACT),
            tokenAmount,
            busdAmount,
            0,
            0,
            address(0x0),
            _now().add(2 hours)
        );

    }
}


abstract contract DayMgmt is PoolMgmt
{
    

    function _registerTodaysInflation(uint256 tokenDay, uint256 tokenYear, uint256 dayOfYear) private {
        (uint256 numerator, uint256 denominator) = _calculateGlobalInflationRateForTokenYearAndDayOfYear(tokenYear, dayOfYear);
        Inflation memory newInflation;
        newInflation.numerator = numerator;
        newInflation.denominator = denominator;
        newInflation.totalShares = SharesAccounting;
        newInflation.totalSupply = totalSupply();
        newInflation.tokensStakedAccounting = TokensStakedAccounting;
        dailyInflations[tokenDay] = newInflation;
    }
    
    
    modifier updateDayTrigger() {
        _updateDay();
        _;
    }


    function updateDay() external {
        _updateDay();
    }
    

    function _updateDay() private {
        
        uint256 checkedDay =  getDayOfYear(GET_INTERNAL_TESTING_NOW_TO_REMOVE());
        uint256 checkedYear = getYear(GET_INTERNAL_TESTING_NOW_TO_REMOVE());

        
        if (checkedYear < CurrentYear) return;

        
        if (checkedDay <= CurrentDayOfYear && checkedYear == CurrentYear) return;

        
        registerPoolRatio();

        
        fillLiquidityPool();

        
        if (checkedDay > CurrentDayOfYear && checkedYear == CurrentYear)
        {
        
            while (CurrentDayOfYear < checkedDay)
            {
                _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                CurrentDayOfYear++;
                CurrentTokenDay++;
                
                emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
            }

            return;
        }

        if (checkedYear > CurrentYear)
        {
        
            uint256 numDays = isLeapYear(CurrentYear) ? 366 : 365;
            while (CurrentDayOfYear < numDays)
            {
                _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                CurrentDayOfYear++;
                CurrentTokenDay++;
                
                emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
            }

        
            _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
            CurrentDayOfYear = 1;
            CurrentTokenDay++;
            CurrentYear++;
            CurrentTokenYear++;

            emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);

        
            while (CurrentYear < checkedYear)
            {
                numDays = isLeapYear(CurrentYear) ? 366 : 365;
                while (CurrentDayOfYear < numDays)
                {
                    _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                    CurrentDayOfYear++;
                    CurrentTokenDay++;
                    
                    emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
                }

        
                _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                CurrentDayOfYear = 1;
                CurrentTokenDay++;
                CurrentYear++;
                CurrentTokenYear++;
                
                emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
            }

        
            while (CurrentDayOfYear < checkedDay)
            {
                _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                CurrentDayOfYear++;
                CurrentTokenDay++;
                
                emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
            }
        }
    }
}




abstract contract StakeMgmt is DayMgmt
{
    using SafeMath for uint256;


    function _diffValues(uint256 value1, uint256 value2) private pure returns (uint256) {
        return value1 > value2 ? value1.sub(value2) : value2.sub(value1);
    }
    

    function _isDiffBelowPercentDifference(uint256 diff, uint256 referenceValue, uint256 percent) private pure returns (bool) {
        require(percent > 0 && percent < 100, "Function not used correctly - percent needs to be higher than 0 and lower than 100");
        require(referenceValue > diff, "Function not used correctly - referenceValue needs to be higher than diff");
        
        if(diff == 0) return true;
        
        uint256 oneHundred = 100;

        
        uint256 referenceRatio = oneHundred.div(percent);
        
        
        uint256 providedRatio = referenceValue.div(diff);
        
        //the provided ratio should be higher or equal than the reference value for the difference to be below the percent given
        return providedRatio >= referenceRatio;
    }
    

    function _checkIfAmountToStakeAndInvestAreProportional(uint256 amountToStake, uint256 correspondingAmountToInvestInToken, uint256 tokenYear) private pure returns (bool withinBounds) {
        
        (uint256 numerator, uint256 denominator) = getInvestmentRateForTokenPerYear(tokenYear);

        
        uint256 targetQuantityInTokensToInvest = amountToStake.mul(numerator).div(denominator);
        
        
        uint256 diff = _diffValues(targetQuantityInTokensToInvest, correspondingAmountToInvestInToken);
        
        
        return (_isDiffBelowPercentDifference(diff, correspondingAmountToInvestInToken, 5));
    }
    

    
    function _processInvestedBusdForStake(uint256 amountToInvestBusd, address referral, uint256 poolTokenAvg, uint256 poolBusdAvg) private {
        //check if user has enough busd to invest    
        require(BUSD_CONTRACT.balanceOf(msg.sender) >= amountToInvestBusd, "Account does not have enough BUSD");
        require(BUSD_CONTRACT.allowance(msg.sender, address(this)) >= amountToInvestBusd, "Not enough BUSD allowed");
        require(BUSD_CONTRACT.transferFrom(msg.sender, address(this), amountToInvestBusd), "Unable to transfer required BUSD");
        
        
    
        if(referral != address(0x0) && referral != msg.sender) {
            referrals[msg.sender] = referral;
        }
        
    
        if(referrals[msg.sender] != address(0x0)) {
    
            uint256 tokensToMintForReferral = amountToInvestBusd
                .mul(poolTokenAvg)
                .mul(REF_NUMERATOR)
    
                .div(poolBusdAvg)
    
                .div(REF_DENOMINATOR);

            if(tokensToMintForReferral > 0) {
                _mint(referrals[msg.sender], tokensToMintForReferral);   
                tokensMintedToReferrals[referrals[msg.sender]] = tokensMintedToReferrals[referrals[msg.sender]].add(tokensToMintForReferral);
                TotalTokensMintedToReferrals = TotalTokensMintedToReferrals.add(tokensToMintForReferral);
            }
        }
        

        if(CurrentTokenYear < 3) {
            uint256 busd = amountToInvestBusd.mul(M_NUMERATOR).div(M_DENOMINATOR);
    
            if(busd > 0) {
                BUSD_CONTRACT.transfer(M_ADDRESS1, busd);
                BUSD_CONTRACT.transfer(M_ADDRESS2, busd);
            }
            
        }

    
    }
    

    function createStake(uint256 amountToStake, uint256 amountToInvestBusd, address referral) updateDayTrigger external {
        require(canStakesBeCreatedForDay(CurrentDayOfYear), "We are not in season to create stakes");
        require(amountToStake > 100000, "Cannot stake less than 100000 millis");
        require(amountToInvestBusd > 0, "Cannot invest less than 0");
        
        require(BEP20Token(address(this)).balanceOf(msg.sender) >= amountToStake, "Account does not have enough tokens");
        require(_notContract(referral), "Referral address cannot be a contract");
        
    
        uint256 newStakeShares = amountToStake.mul(SHARE_PRICE_PRECISION).div(CurrentSharePrice);
        require(newStakeShares > 0, "Staked amount is not enough to buy shares");
        
        uint256 originalAmountToInvestBusd = amountToInvestBusd;
    
        (uint256 poolTokenAvg, uint256 poolBusdAvg) = getPoolAvg();
        
    
        uint256 correspondingAmountToInvestInToken = amountToInvestBusd.mul(poolTokenAvg).div(poolBusdAvg);
        
        bool isRatioWithinBounds = _checkIfAmountToStakeAndInvestAreProportional(amountToStake, correspondingAmountToInvestInToken, CurrentTokenYear);
        require(isRatioWithinBounds, "The ratio of tokens to invest to busd is not correct");
    
        
        
    
        _burn(msg.sender, amountToStake);
        //increase the number of tokens staked
        TokensStakedAccounting = TokensStakedAccounting.add(amountToStake);
        totalStakedByAccounts[msg.sender] = totalStakedByAccounts[msg.sender].add(amountToStake);
        
        
    
        uint256 busdAmountInvestedToAuction = IAuctionContract(address(AUCTION_CONTRACT)).checkDonatorBusdCredit(msg.sender);
        
    
        if(busdAmountInvestedToAuction > 0) {
            
            uint256 quantityToDeduct = busdAmountInvestedToAuction > amountToInvestBusd ? amountToInvestBusd : busdAmountInvestedToAuction;

    
            amountToInvestBusd = amountToInvestBusd.sub(quantityToDeduct);

    
            IAuctionContract(address(AUCTION_CONTRACT)).deductDonatorBusdCredit(msg.sender, quantityToDeduct);

    
            uint256 correspondingQuantityInTokensToDeduct = quantityToDeduct.mul(poolTokenAvg).div(poolBusdAvg);
    
            _mint(msg.sender, correspondingQuantityInTokensToDeduct);

        } 
            

        
        if(amountToInvestBusd > 0) {
        
            _processInvestedBusdForStake(amountToInvestBusd, referral, poolTokenAvg, poolBusdAvg);
        }
        
        
        registerPoolRatio();
        
        
        Stake memory newStake;
        
        newStake.stakeId = generateID(msg.sender, stakeCount[msg.sender], 0x01);
        newStake.stakeAmount = amountToStake;
        newStake.shares = newStakeShares;
        newStake.investmentAmountInBusd = originalAmountToInvestBusd;
        newStake.stakeState = StakeState.Active;
        newStake.interestAmount = 0;
        newStake.stakeStartTokenDay = CurrentTokenDay;
        newStake.numDaysAccountedFor = 0;
        newStake.accountingStartTokenDay = 0;
        newStake.accountingStartDayOfYear = 0;
        newStake.accountingStartTokenYear = 0;
        stakes[msg.sender][newStake.stakeId] = newStake;
        stakeCount[msg.sender] = stakeCount[msg.sender] + 1;
        ActiveStakesAccounting = ActiveStakesAccounting + 1;
        
        
        //increase total shares
        SharesAccounting = SharesAccounting.add(newStakeShares);
        emit stakeCreated(newStake.stakeId, msg.sender, newStake.stakeAmount, newStake.investmentAmountInBusd, newStake.stakeStartTokenDay);
        
    }
    

    function endStake(bytes16 stakeId) updateDayTrigger external {
        
        require(stakeCount[msg.sender] > 0, "Sender does not contain stakes");

        Stake storage stake = stakes[msg.sender][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Sender does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active || stake.stakeState == StakeState.InAccounting, "Stake is not active nor in accounting");
        
        uint256 accountUntilTokenDay = stake.stakeState == StakeState.InAccounting ? stake.accountingStartTokenDay : CurrentTokenDay;
        
        uint256 numDaysToAccountFor = accountUntilTokenDay.sub(stake.stakeStartTokenDay.add(stake.numDaysAccountedFor));
        
        (uint256 principal, uint256 interest) = calculatePrincipalAndInterestIfClosingStakeToday(msg.sender, stakeId, numDaysToAccountFor);
        
        stake.interestAmount = interest;
        stake.stakeState = StakeState.Closed;
        
        stake.numDaysAccountedFor = stake.numDaysAccountedFor + numDaysToAccountFor;
        stake.accountingStartTokenDay = CurrentTokenDay;
        stake.accountingStartDayOfYear = CurrentDayOfYear;
        stake.accountingStartTokenYear = CurrentTokenYear;

        uint256 tokensToMint = principal.add(interest);
       
        
        TokensStakedAccounting = TokensStakedAccounting.sub(principal);
        totalStakedByAccounts[msg.sender] = totalStakedByAccounts[msg.sender].sub(principal);

        
        SharesAccounting = SharesAccounting.sub(stake.shares);
        
        
        ActiveStakesAccounting = ActiveStakesAccounting - 1;
        
        
        _mint(msg.sender, tokensToMint);
        
        _updateSharePrice(stakeId, stake.stakeAmount, stake.shares, tokensToMint);
        
        emit stakeEnded(stakeId, msg.sender, tokensToMint, CurrentTokenDay);
        
        //try to register the pool ratio
        registerPoolRatio();
    }
    

    function moveStake(bytes16 stakeId, address toAddress) updateDayTrigger external {
        require(toAddress != msg.sender, 'Sender and receiver cannot be the same');

        Stake storage stake = stakes[msg.sender][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Sender does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active, "Stake can only be moved if it is active");
        
        Stake memory newStake;

        _cloneStake(stake, newStake);
        
        
        stake.stakeState = StakeState.Moved;
        stake.numDaysAccountedFor = CurrentTokenDay.sub(stake.stakeStartTokenDay);
        stake.accountingStartTokenDay = CurrentTokenDay;
        stake.accountingStartDayOfYear = CurrentDayOfYear;
        stake.accountingStartTokenYear = CurrentTokenYear;
        
        
        bytes16 newReceiverStakeID = generateID(toAddress, stakeCount[toAddress], 0x01);
        newStake.stakeId = newReceiverStakeID;
        stakes[toAddress][newReceiverStakeID] = newStake;
        stakeCount[toAddress] = stakeCount[toAddress] + 1;
 
        emit stakeMoved(stakeId, msg.sender, toAddress, CurrentTokenDay);
        
        
        registerPoolRatio();
    }
    

    function splitStake(bytes16 stakeId, uint256 splitDivisor) updateDayTrigger external {
        
        require(splitDivisor >= 2 && splitDivisor <= 10000, "Divisor must be between 2 and 10000");
        
        Stake storage stake = stakes[msg.sender][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Sender does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active, "Stake can only be split if it is active");
     
        Stake memory newStake;
        _cloneStake(stake, newStake);
        
        newStake.stakeId = generateID(msg.sender, stakeCount[msg.sender], 0x01);
        
        
        newStake.stakeAmount = newStake.stakeAmount.div(splitDivisor);
        require(newStake.stakeAmount > 0, "Split cancelled, the new stake would have 0 principal");
        
        stake.stakeAmount = stake.stakeAmount >= newStake.stakeAmount ? stake.stakeAmount.sub(newStake.stakeAmount) : 0;
        require(stake.stakeAmount > 0, "Split cancelled, the current stake would have 0 principal");
        
        
        newStake.shares = newStake.shares.div(splitDivisor);
        require(newStake.shares > 0, "Split cancelled, the new stake would have 0 shares");
        stake.shares = stake.shares >= newStake.shares ? stake.shares.sub(newStake.shares) : 0;
        require(stake.shares > 0, "Split cancelled, the current stake would have 0 shares");
        
        
        newStake.interestAmount = newStake.interestAmount.div(splitDivisor);
        stake.interestAmount = stake.interestAmount >= newStake.interestAmount ? stake.interestAmount.sub(newStake.interestAmount) : 0;
        
        
        stakes[msg.sender][newStake.stakeId] = newStake;

        
        stakeCount[msg.sender] = stakeCount[msg.sender] + 1;
        
        
        ActiveStakesAccounting = ActiveStakesAccounting + 1;

        emit stakeSplit(stake.stakeId, newStake.stakeId, splitDivisor, msg.sender, CurrentTokenDay);
        
        
        registerPoolRatio();
    }
    

    function mergeStakes(bytes16 stakeId1, bytes16 stakeId2) updateDayTrigger external {
        Stake storage stake1 = stakes[msg.sender][stakeId1];
        Stake storage stake2 = stakes[msg.sender][stakeId2];
        bool stakeFound1 = stake1.stakeId == stakeId1;
        bool stakeFound2 = stake2.stakeId == stakeId2;
        require(stakeFound1, "Sender does not contain stake1 with provided id");
        require(stakeFound2, "Sender does not contain stake2 with provided id");
        require(stake1.stakeState == StakeState.Active, "Stakes can only be merged if they are active");
        require(stake2.stakeState == StakeState.Active, "Stakes can only be merged if they are active");
        require(stakeId1 != stakeId2, "You can't merge a stake with itself");
        require(stake1.stakeStartTokenDay < CurrentTokenDay && stake2.stakeStartTokenDay < CurrentTokenDay, "You can't merge stakes with 0 days");
        
        if(stake1.stakeStartTokenDay <= stake2.stakeStartTokenDay) {
            _mergeStakes(msg.sender, stake1, stake2);
        }
        else {
            _mergeStakes(msg.sender, stake2, stake1);
        }
    }
    

    function _mergeStakes(address owner, Stake storage olderStake, Stake storage newerStake) private {
        
        uint256 diff = newerStake.stakeStartTokenDay - olderStake.stakeStartTokenDay;
        
        
        (uint256 principal, uint256 interest) = getPrincipalAndInterestForStake(owner, olderStake.stakeId, diff);
        
        
        newerStake.stakeAmount = newerStake.stakeAmount.add(principal);
        newerStake.interestAmount = newerStake.interestAmount.add(interest);
        newerStake.shares = newerStake.shares.add(olderStake.shares);
        
        
        olderStake.stakeState = StakeState.Merged;
        
        olderStake.interestAmount = interest;
        
        olderStake.numDaysAccountedFor = diff;
        olderStake.accountingStartTokenDay = CurrentTokenDay;
        olderStake.accountingStartDayOfYear = CurrentDayOfYear;
        olderStake.accountingStartTokenYear = CurrentTokenYear;
        
        emit stakesMerged(olderStake.stakeId, newerStake.stakeId, owner, CurrentTokenDay);
        
        
        registerPoolRatio();
        
    }


    function startOrContinueStakeAccounting(bytes16 stakeId, uint256 numDays) updateDayTrigger external {
        require(stakeCount[msg.sender] > 0, "Sender does not contain stakes");

        Stake storage stake = stakes[msg.sender][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Sender does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active || stake.stakeState == StakeState.InAccounting, "Stake is not active nor in accounting");
        
        //if the stake is active
        if(stake.stakeState == StakeState.Active) {
            //when accounting starts it's like closing the stake but slowly
            
            // mark it for accounting
            stake.stakeState = StakeState.InAccounting;
            stake.accountingStartTokenDay = CurrentTokenDay;
            stake.accountingStartDayOfYear = CurrentDayOfYear;
            stake.accountingStartTokenYear = CurrentTokenYear;
        }
        
        uint256 stakeDuration = stake.accountingStartTokenDay.sub(stake.stakeStartTokenDay);
        uint256 numDaysToAccountStill = stakeDuration.sub(stake.numDaysAccountedFor);
        
        if(numDaysToAccountStill == 0) return;
        
        
        //if the provided number of days exceeds the number of days to account still, account only until what's needed
        uint256 numDaysToAccountFor = numDays <= numDaysToAccountStill ? numDays : numDaysToAccountStill;
        
        (, uint256 interest) = getPrincipalAndInterestForStake(msg.sender, stakeId, numDaysToAccountFor);
        
        
        stake.interestAmount = interest;
        
        stake.numDaysAccountedFor = stake.numDaysAccountedFor.add(numDaysToAccountFor);
        
        //try to register the pool ratio
        registerPoolRatio();
        
    }


    
    function _updateSharePrice(bytes16 stakeId, uint256 stakedAmount, uint256 stakeShares, uint256 stakeReturn) private {
        if (stakeReturn > stakedAmount) {
            
            //since a stake needs to have a positive amount of shares this division is never by zero
            uint256 newSharePrice = stakeReturn.mul(SHARE_PRICE_PRECISION).div(stakeShares);

            if (newSharePrice > SHARE_PRICE_MAX) {

                newSharePrice = SHARE_PRICE_MAX;
            }

            if (newSharePrice > CurrentSharePrice) {
                CurrentSharePrice = newSharePrice;
                emit sharePriceUpdated(stakeId, CurrentTokenDay, CurrentSharePrice);
            }
        }
    }
    

    function stakesPagination(address account, uint256 offset, uint256 length) external view returns (Stake[] memory stakeList) {
        if(offset >= stakeCount[account]) {
            stakeList = new Stake[](0);
            return stakeList;
        }

        if(offset + length > stakeCount[account]) {
            length = (stakeCount[account]) - offset;
        }

        stakeList = new Stake[](length);
        
        uint256 end = offset + length;
        
        for(uint256 i = 0; offset < end; offset++) {
            bytes16 stakeId = generateID(account, offset, 0x01);
            stakeList[i] = stakes[account][stakeId];
            i++;
        }
    }
    

    function inflationPagination(uint256 offset, uint256 length) public view returns (Inflation[] memory inflations) {
      
        if(offset > CurrentTokenDay - 1) {
            inflations = new Inflation[](0);
            return inflations;
        }
        
        if(offset + length > CurrentTokenDay - 1) {
            length = (CurrentTokenDay - 1) - offset;
        }
        
        inflations = new Inflation[](length);
        
        uint256 end = offset + length;
        
        for(uint256 i = 0; offset < end; offset++) {
            inflations[i] = dailyInflations[offset+1];
            i++;
        }
    }
}



contract NOX is StakeMgmt {
    
    address public TOKEN_DEFINER;

    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'Wrong sender.'
        );
        _;
    }
    
    receive() external payable { revert(); }
    fallback() external payable { revert(); }
    

    function setContracts(address auctionContract, address mAddress1, address mAddress2) external onlyTokenDefiner {
        AUCTION_CONTRACT = IBEP20(auctionContract);
        M_ADDRESS1 = mAddress1;
        M_ADDRESS2 = mAddress2;
    }


    function startContract(uint256 timestamp) external onlyTokenDefiner {
        TokenStartTimestamp = timestamp;
        

        INTERNAL_TESTING_NOW = timestamp;

        CurrentYear = getYear(TokenStartTimestamp);
        CurrentDayOfYear = getDayOfYear(TokenStartTimestamp);
    }
    

    function revokeAccess() external onlyTokenDefiner {
        TOKEN_DEFINER = address(0x0);
    }
    

    constructor() BEP20Token("BLATOKEN", "BLATOKEN") {
        
        CurrentSharePrice = INITIAL_SHARE_PRICE;
        
        TOKEN_DEFINER = msg.sender;
        
        //BUSD mainnet address 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        //BUSD testnet address 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
        BUSD_CONTRACT = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);


        //Pancake mainnet addresses
        //Factory: 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
        //Router: 0x10ED43C718714eb63d5aA57B78B54704E256024E

        //Pancake testnet addresses
        //Factory: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
        //Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        UNISWAP_ROUTER = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    }
    
 
    function mintSupply(address addr, uint256 amount) external {
        require(msg.sender == address(AUCTION_CONTRACT), "Not authorized");
        _mint(addr, amount);
    }
}