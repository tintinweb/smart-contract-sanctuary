// SPDX-License-Identifier: MIT

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* NNNNNNNN        NNNNNNNN       OOOOOOOOO       XXXXXXX       XXXXXXX *
* N:::::::N       N::::::N     OO:::::::::OO     X:::::X       X:::::X *
* N::::::::N      N::::::N   OO:::::::::::::OO   X:::::X       X:::::X *
* N:::::::::N     N::::::N  O:::::::OOO:::::::O  X::::::X     X::::::X *
* N::::::::::N    N::::::N  O::::::O   O::::::O  XXX:::::X   X:::::XXX *
* N:::::::::::N   N::::::N  O:::::O     O:::::O     X:::::X X:::::X    *
* N:::::::N::::N  N::::::N  O:::::O     O:::::O      X:::::X:::::X     *
* N::::::N N::::N N::::::N  O:::::O     O:::::O       X:::::::::X      *
* N::::::N  N::::N:::::::N  O:::::O     O:::::O       X:::::::::X      *
* N::::::N   N:::::::::::N  O:::::O     O:::::O      X:::::X:::::X     *
* N::::::N    N::::::::::N  O:::::O     O:::::O     X:::::X X:::::X    *
* N::::::N     N:::::::::N  O::::::O   O::::::O  XXX:::::X   X:::::XXX *
* N::::::N      N::::::::N  O:::::::OOO:::::::O  X::::::X     X::::::X *
* N::::::N       N:::::::N   OO:::::::::::::OO   X:::::X       X:::::X *
* N::::::N        N::::::N     OO:::::::::OO     X:::::X       X:::::X *
* NNNNNNNN         NNNNNNN       OOOOOOOOO       XXXXXXX       XXXXXXX *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * /

/*
Project Name:   EquiNOX
Ticker:         Nox
Decimals:       18
Token type:     Certificate of deposit

Website: https://nox-token.com
Telegram: https://t.me/nox_token


NOX has everything a good staking token should have:
- NOX is immutable
- NOX has no owner
- NOX has daily auctions
- NOX has daily rewards for auction participants
- NOX has an Automated Market Maker built in
- NOX has a stable supply and liquidity growth
- NOX has a 1.8% daily inflation that slowly decays over time
- NOX has shares that go up when stakes are ended 
- NOX has penalties for ending stakes early
- NOX has 10% rewards for referrals 
- NOX has a sticky referral system
- NOX has flexible splitting and merging of stakes
- NOX allows transferring stakes to different accounts
- NOX has no end date for stakes

Also, NOX is the first certificate of deposit aligned with the seasons:
- Every season change has a predictable impact on how NOX behaves
- Harvest season is the most important season for NOX
- It's when old holders leave, new ones join, and diamond hands are rewarded
- Stakes can only be ended without penalty during harvest season
- Stakes that survive harvest get more valuable and earn more interest
*/

pragma solidity ^0.8.10;

interface IBEP20 {
  
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


/**
 * @dev Abstract contract that contains all NOX events
 */
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

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;

    function _now() internal view returns (uint timestamp) {
        timestamp = block.timestamp;
    }
    
    function isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = BokkyPooBahsDateTimeLibrary._isLeapYear(year);
    }

    function _getYear(uint timestamp) internal pure returns (uint year) {
        year = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
    }
    
    function _getDayOfYear(uint timestamp) internal pure returns(uint day) {
        day = BokkyPooBahsDateTimeLibrary.getDayOfYear(timestamp);
    }

    function _addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, _days);
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        _minutes = BokkyPooBahsDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }

    //taken from bokky lib but without the require
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint256) {
        // require(fromTimestamp <= toTimestamp);
        if(fromTimestamp > toTimestamp) return 0;
        return (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
}


/**
 * @dev Abstract contract that contains all data and functions related to checking current season and season rules.
 */
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

    uint256 public CurrentTokenDay;
    uint256 public CurrentTokenYear;

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
    
    //interest is generated all year except during harvest when it becomes lowest
    function canInterestBeGeneratedForDay(uint256 dayOfYear) public pure returns (bool) {
        Season currentSeason = _getSeasonForDay(dayOfYear);
        return currentSeason != Season.Autumn;
    }
    
    //ending stakes has penalties all year except during harvest
    function endingStakesHasPenaltiesForDay(uint256 dayOfYear) public pure returns (bool) {
        Season currentSeason = _getSeasonForDay(dayOfYear);
        return currentSeason != Season.Autumn;
    }
}

/**
 * @dev Abstract contract that contains all main constants, global variables, mappings, and data structures.
 */
abstract contract Data is Calendar {
    
    IBEP20 public BUSD_CONTRACT;
    address public AUCTION_CONTRACT;
    
    address internal M_ADDRESS1;
    address internal M_ADDRESS2;

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
    uint256 public ActiveStakesAccounting;
    
    
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
    
    
    uint8 public PoolRatioPos = 0;
    PoolRatio[] public LastSampledPoolRatios;

    /**
     * @dev Internal function to clone an origin stake into destination stake. It used on stake related operations: move, split and merge stake.
     */
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
    
    /**
     * @dev External function that returns the default token to busd ratio.
     * This function exists mainly to be used by the auctions contract.
     */
    function getDefaultTokenBusdRatio() external pure returns(uint256){
        return DEFAULT_TOKEN_BUSD_RATIO;
    }
}

/**
 * @dev Abstract contract that contains all functions related to interest and inflation calculation.
 */
abstract contract Interest is Data {

    using SafeMath for uint256;

    /**
     * @dev Public function that calculates the penalties for ending a stake at a given year of the token existance, and at the specific day of the year.
     * First day of the year has highest penalty. Last day before harvest season has lowest penalty. Harvest season has no penalty.
     * First two years have the penalty reduced in 75% and 25%, respectively.
     * Returns the fraction that can be multiplied with the principal, to obtain the penalty amount that should be subtracted from the principal.
     */
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
     
    /**
     * @dev Public function that calculates the principal and interest for a stake that is going to be closed, or is being closed (stakes that are in accounting state)
     * The numDaysToAccountFor allows for the calculation of the principal and interest up to a given number of days.
     * This is useful for when "ending a stake slowly" to make sure very old stakes can also be ended, by accounting their principal and interest
     * in multiple subsequent transactions until all days have been accounted for.
     */
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

    /**
     * @dev Public function that calculates the principal and accrued interest for a stake for a given number of elapsed days, without considering any penalties for ending the stake early.
     */
    function getPrincipalAndInterestForStake(address addr, bytes16 stakeId, uint256 numDaysToAccountFor) public view returns (uint256 principal, uint256 interest) {
        Stake storage stake = stakes[addr][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Address does not contain stake with provided id");

        interest = stake.interestAmount;
        principal = stake.stakeAmount;
        
        if(stake.stakeState == StakeState.Closed || stake.stakeState == StakeState.Moved || stake.stakeState == StakeState.Merged) return (principal, interest);
        
        //if the stake is in accounting use the start accounting date otherwise the stake is still active
        uint256 accountStakeUntilTokenDay = stake.stakeState == StakeState.InAccounting ? stake.accountingStartTokenDay : CurrentTokenDay;

        //go through all days up to the day before the accountStakeUntilTokenDay
        for(uint256 i = stake.stakeStartTokenDay + stake.numDaysAccountedFor; i < accountStakeUntilTokenDay; i++) {
            //solidity doesn't support multivariable fors
            if(numDaysToAccountFor == 0) break;
            
            interest = interest.add(
                //each stakes earns as interest a fraction of the global token inflation according to its share ratio
                    dailyInflations[i].totalSupply.add(dailyInflations[i].tokensStakedAccounting)
                    .mul(dailyInflations[i].numerator)
                    //multiply by fraction of stake shares to total shares
                    .mul(stake.shares)
                    .div(dailyInflations[i].denominator)
                    //since a stake to exist needs to have shares (this is a require on create stake) and that is accounted for in SharesAccounting
                    //and since the totalShares of a dailyInflation has the day value of SharesAccounting
                    //therefore this division will never result in a division by zero
                    .div(dailyInflations[i].totalShares));
            
            //solidity doesn't support multivariable fors
            numDaysToAccountFor--;
        }

        return (principal, interest);
    }
    
    /**
     * @dev Public function that obtains the current global inflation rate.
     */
    function getTodaysGlobalInflationRate() public view returns (uint256 numerator, uint256 denominator) {
        return calculateGlobalInflationRateForTokenYearAndDayOfYear(CurrentTokenYear, CurrentDayOfYear);
    }

    /**
     * @dev Internal function that calculates the global inflation rate for a given day. Inflation is expressed as interest for all active stakes according to their individual share size.
     * Returns a fraction that expresses the percentage of inflation for the given day.
     */
    function calculateGlobalInflationRateForTokenYearAndDayOfYear(uint256 tokenYear, uint256 dayOfYear) public pure returns (uint256 numerator, uint256 denominator) {
        
        //During harvest season minimum interest is generated
        if (!canInterestBeGeneratedForDay(dayOfYear)) {
            return (146520, 1000000000);
        }
        
        //Since inflation changes every season for the first 6 years, this implementation was used to avoid a long if/else chain
        uint32[19] memory numerators = [uint32(18315018), 14652015,10989011,7326007,3663004,3296703,2930403,2564103,2197802,1831502,1465201,1098901,732601,366300,329670,293040,256410,219780,146520];
        uint8 index = _getSeasonForDay(dayOfYear) == Season.Winter ? 1 : _getSeasonForDay(dayOfYear) == Season.Spring ? 2 : 3;
        uint8 posCalc = uint8((tokenYear-1)*3 + index);
        uint8 pos = posCalc < 19 ? posCalc : 19;
        return (numerators[pos-1], 1000000000);
        
        
        /*Here is listed all planned daily percentual inflations for the first six years
        
        year one    - winter --- 500% interest  - 5/273     = 0.018315018 = (18315018, 1000000000)
        year one    - spring --- 400% interest  - 4/273     = 0.014652015 = (14652015, 1000000000)
        year one    - summer --- 300% interest  - 3/273     = 0.010989011 = (10989011, 1000000000)
        
        year two    - winter --- 200% interest  - 2/273     = 0.007326007 = (7326007, 1000000000)
        year two    - spring --- 100% interest  - 1/273     = 0.003663004 = (3663004, 1000000000)
        year two    - summer --- 90% interest   - 0.9/273   = 0.003296703 = (3296703, 1000000000)
        
        year three  - winter --- 80% interest   - 0.8/273   = 0.002930403 = (2930403, 1000000000)
        year three  - spring --- 70% interest   - 0.7/273   = 0.002564103 = (2564103, 1000000000)
        year three  - summer --- 60% interest   - 0.6/273   = 0.002197802 = (2197802, 1000000000)
        
        year four   - winter --- 50% interest   - 0.5/273   = 0.001831502 = (1831502, 1000000000)
        year four   - spring --- 40% interest   - 0.4/273   = 0.001465201 = (1465201, 1000000000)
        year four   - summer --- 30% interest   - 0.3/273   = 0.001098901 = (1098901, 1000000000)
        
        year five   - winter --- 20% interest   - 0.2/273   = 0.000732601 = (732601, 1000000000)
        year five   - spring --- 10% interest   - 0.1/273   = 0.000366300 = (366300, 1000000000)
        year five   - summer --- 9% interest    - 0.09/273  = 0.000329670 = (329670, 1000000000)
        
        year six    - winter --- 8% interest    - 0.08/273  = 0.000293040 = (293040, 1000000000)
        year six    - spring --- 7% interest    - 0.07/273  = 0.000256410 = (256410, 1000000000)
        year six    - summer --- 6% interest    - 0.06/273  = 0.000219780 = (219780, 1000000000)
        
        further years and seasons have 4% interest. 0.04/273 = 0.000146520 = (146520, 1000000000)
        
        */
    }
    
    /**
     * @dev Public function that calculates the percentage in value of BUSD to NOX tokens that should be invested when a stake with that given amount of NOX is created.
     */
    function getInvestmentRateForTokenPerYear(uint256 tokenYear) public pure returns(uint256 numerator, uint256 denominator) {
        
        uint32[6] memory numerators = [uint32(2500000), 1250000, 625000, 312500, 156250, 78125];
        uint8 pos = uint8(tokenYear < 6 ? tokenYear : 6);
        return (numerators[pos-1], 10000000);
        
        /* when a stake is created in needs busd investment for liquidity pool unless user has busd credit

        year one    - 25%       busd
        year two    - 12.5%     busd
        year three  - 6.25%     busd
        year four   - 3.125%    busd
        year five   - 1.5625%   busd
        
        further years - 0.78125%  busd

        */
    }
}


/**
 * @dev Abstract contract that contains helper functions
 */
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


/**
 * @dev Abstract contract that contains all functions related to interacting with the NOX-BUSD pool
 */
abstract contract PoolMgmt is Helper
{
    using SafeMath for uint256;
    
    IUniswapV2Pair public UNISWAP_PAIR;
    IUniswapV2Router02 public UNISWAP_ROUTER;
    address public FACTORY;

    /**
     * @dev Public function to check if the NOX-BUSD pool has been created
     */
    function hasPoolBeenCreated() public view returns (bool) {
        return IUniswapV2Factory(UNISWAP_ROUTER.factory()).getPair(address(this), address(BUSD_CONTRACT)) != address(0x0);
    }
    
    /**
     * @dev External function, accessible only by the auctions contract to create the NOX-BUSD pool
     */
    function createPool() external {
        require(msg.sender == AUCTION_CONTRACT, "Not authorized");
        if(!hasPoolBeenCreated()) {
            _createPool();
        }
    }
    
    /**
     * @dev Private function to create the NOX-BUSD pool
     */
    function _createPool() private {
        UNISWAP_PAIR = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(address(this), address(BUSD_CONTRACT)));
    }
    

    /**
     * @dev Public function for registering the current NOX-BUSD pool ratio.
     * Can be called by an external benefactor
     * Contains an array with samples of the pool ratio that can only be updated every X mins.
     * It's main purpose is to prevent manipulation of the pool ratio right before creating a stake.
     */
    function registerPoolRatio() public {
        

        //only register after the pool has been created, this happens when there are enough reserves to fill the pool
        if(!hasPoolBeenCreated()) return;

        uint256 tokenAmount;
        uint256 busdAmount;
        uint256 timestamp = _now();

        if (LastSampledPoolRatios.length > 0) 
        {
            PoolRatio storage lastSample = PoolRatioPos == 0 ? LastSampledPoolRatios[LastSampledPoolRatios.length - 1] : LastSampledPoolRatios[PoolRatioPos - 1];

            //if the time of the timestamp is higher than the current time, do nothing
            if (lastSample.timestamp > timestamp) return;

            //don't allow samples that are less than 3 minutes apart
            if(diffMinutes(lastSample.timestamp, timestamp) < 3) return;
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
        
        //has at best an average of the last 15 minutes
        uint256 maxSize = 5;
        
        //while the array isn't filled, fill it
        if(LastSampledPoolRatios.length < maxSize) {
            LastSampledPoolRatios.push(newPoolRatio);
        }
        //after the array has been filled, use the PoolRatioPos to write on top of it and a round-robin approach
        else {
            LastSampledPoolRatios[PoolRatioPos] = newPoolRatio;
            PoolRatioPos++;
            if(PoolRatioPos >= maxSize) PoolRatioPos = 0;
        }
    }

    /**
     * @dev Public function that calculates the current average of sampled pool ratios
     */
    function getPoolAvg() public view returns (uint256, uint256) {
        
        //if pool is empty return the default ratio
        if (LastSampledPoolRatios.length == 0) return (DEFAULT_TOKEN_BUSD_RATIO, 1);
        uint256 poolTokenAvg;
        uint256 poolBusdAvg;

        for(uint256 i = 0; i < LastSampledPoolRatios.length; i++) {
            poolTokenAvg = poolTokenAvg.add(LastSampledPoolRatios[i].amountToken);
            poolBusdAvg = poolBusdAvg.add(LastSampledPoolRatios[i].amountBusd);
        }

        //since the length of the array is checked above for zero, these divisions will never result in a division by zero
        poolTokenAvg = poolTokenAvg.div(LastSampledPoolRatios.length);
        poolBusdAvg = poolBusdAvg.div(LastSampledPoolRatios.length);
        
        //if for some reason the poolBusdAvg is 0 
        //meaning much more NOX than BUSD, so NOX is cheap
        //return the default ratio
        if(poolBusdAvg == 0) return (DEFAULT_TOKEN_BUSD_RATIO, 1);


        //if for some reason the poolTokenAvg is 0
        //meaning much more BUSD than NOX, so NOX is expensive
        //return the default ratio inverted
        if(poolTokenAvg == 0) return (1, DEFAULT_TOKEN_BUSD_RATIO);

        return (poolTokenAvg, poolBusdAvg);
    }
    
    /** 
    * @dev Public function to fill the liquidity pool of NOX-BUSD if possible
    */
    function fillLiquidityPool() public {
        (uint256 poolTokenAvg, uint256 poolBusdAvg) = getPoolAvg();
        _fillLiquidityPool(poolTokenAvg, poolBusdAvg);
    }
    
    /**
     * @dev Internal function to fill the liquidity NOX-BUSD pool when enough busd has been gathered.
     */
    function _fillLiquidityPool(uint256 poolTokenAvg, uint256 poolBusdAvg) internal {
        
        uint256 tokenAmount;
        uint256 busdAmount = BUSD_CONTRACT.balanceOf(address(this));
        
        if(busdAmount < 1E18) return;
        
        if(!hasPoolBeenCreated()) {
            _createPool();
            
            //Set initial ratio for nox to busd
            tokenAmount = busdAmount.mul(DEFAULT_TOKEN_BUSD_RATIO);
        }
        else {
            //since this function is only called by fillLiquidityPool, and since the poolBusdAvg parameter is retrieved from getPoolAvg
            //and since that function makes sure that poolBusdAvg is never zero, this division never results in a division by zero
            tokenAmount = busdAmount.mul(poolTokenAvg).div(poolBusdAvg);
        }
        
        //the contract may have some remaining NOX tokens that it wasn't able to transfer to the pool
        uint256 heldTokens = BEP20Token(address(this)).balanceOf(address(this));
        
        //if the quantity of held tokens is inferior to what needs to be minted, mint the difference
        if(heldTokens < tokenAmount) {
            //mint the tokens for the pool
            _mint(address(this), tokenAmount.sub(heldTokens));    
        }
        //otherwise, the contract holds enough NOX to fill the pool at the current rate

        _approve(address(this), address(UNISWAP_ROUTER), tokenAmount);
        BUSD_CONTRACT.approve(address(UNISWAP_ROUTER), busdAmount);
        
        UNISWAP_ROUTER.addLiquidity(
            address(this),
            address(BUSD_CONTRACT),
            tokenAmount,
            busdAmount,
            0,
            0,
            address(0x0), //burn liquidity tokens
            _now().add(2 hours)
        );

    }
}

/**
 * @dev Abstract contract that contains all functions related to updating the current NOX day.
 */
abstract contract DayMgmt is PoolMgmt
{
    
    /**
     * @dev Private function to register the daily inflation and existing shares right before updating the day to the next day.
     */
    function _registerTodaysInflation(uint256 tokenDay, uint256 tokenYear, uint256 dayOfYear) private {
        (uint256 numerator, uint256 denominator) = calculateGlobalInflationRateForTokenYearAndDayOfYear(tokenYear, dayOfYear);
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

    /**
     * External function that allows anyone to trigger the update day (and as such paying the transaction fees)
     */
    function updateDay() external {
        _updateDay();
    }

    
    
    /**
     * @dev Private function to update the current NOX day. Is mainly responsible for registering the daily inflation and current existing shares,
     * and also to update four global variables: 
     * CurrentDayOfYear (the current calendar day of the year).
     * CurrentYear (the current calendar year)
     * CurrentTokenDay (the current number of elapsed days since the start of NOX)
     * CurrentTokenYear (the current number of elapsed years since the start of NOX)
     */
    function _updateDay() private {

        uint256 _NOW = _now();
        uint256 checkedDay =  _getDayOfYear(_NOW);
        uint256 checkedYear = _getYear(_NOW);

        //year is before current year, nothing to do
        if (checkedYear < CurrentYear) return;

        //day is before or equal to current day, nothing to do
        if (checkedDay <= CurrentDayOfYear && checkedYear == CurrentYear) return;
        //if we reached here means that either the checked day is bigger than the current day or the checked year is bigger than the current year

        //checks if at least one full day has ellapsed since the last update
        if(diffDays(
            _addDays(TokenStartTimestamp, CurrentTokenDay-1),
            _NOW
            ) == 0) return;

        //if the update day isn't called every day, the day will ajust according to midnight UTC instead of the token hour
        //this will make the next token day last longer

        //try to register the pool ratio
        registerPoolRatio();

        //try to fill the liquidity pool
        fillLiquidityPool();

        //if one or more days have passed but still same year
        if (checkedDay > CurrentDayOfYear && checkedYear == CurrentYear)
        {
            //for each day update current days
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
            //first, update current days until the end of the year
            uint256 numDays = isLeapYear(CurrentYear) ? 366 : 365;
            while (CurrentDayOfYear < numDays)
            {
                _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                CurrentDayOfYear++;
                CurrentTokenDay++;
                
                emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
            }

            //update to day 1 of next year
            _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
            CurrentDayOfYear = 1;
            CurrentTokenDay++;
            CurrentYear++;
            CurrentTokenYear++;

            emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);

            //while you are not on the same year
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

                //update to day 1 of next year
                _registerTodaysInflation(CurrentTokenDay, CurrentTokenYear, CurrentDayOfYear);
                CurrentDayOfYear = 1;
                CurrentTokenDay++;
                CurrentYear++;
                CurrentTokenYear++;
                
                emit dayUpdated(CurrentYear, CurrentDayOfYear, CurrentTokenDay, CurrentTokenYear);
            }

            //here we've reached the current year
            //therefore update the current days until checked day
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



/**
 * @dev Abstract contract that contains all functions related to the management of stakes
 */
abstract contract StakeMgmt is DayMgmt
{
    using SafeMath for uint256;

    /**
     * @dev Private function to calculate the net difference between two values.
     */
    function _diffValues(uint256 value1, uint256 value2) private pure returns (uint256) {
        return value1 >= value2 ? value1.sub(value2) : value2.sub(value1);
    }
    
    /**
     * @dev Private function to determine if a net difference from a reference value is below a provided percentual maxium.
     */
    function _isDiffBelowPercentDifference(uint256 diff, uint256 referenceValue, uint256 percent) private pure returns (bool) {
        require(percent > 0 && percent < 100, "Function not used correctly - percent needs to be higher than 0 and lower than 100");
        require(referenceValue > diff, "Function not used correctly - referenceValue needs to be higher than diff");
        
        if(diff == 0) return true;
        
        uint256 oneHundred = 100;

        //calculates the ratio of 100 to the provided percentage
        //since the function requires that percent is higher than 0, this division never results in a division by zero
        uint256 referenceRatio = oneHundred.div(percent);
        
        //calculates the ratio of the reference value to the difference
        //since the function returns if diff equals 0, this division never results in a division by zero
        uint256 providedRatio = referenceValue.div(diff);
        
        //the provided ratio should be higher or equal to the reference value for the difference to be below the percent given
        return providedRatio >= referenceRatio;
    }
    
    /**
    * @dev Private function to determine if the amount of NOX to stake, and the corresponding amount of BUSD already converted into NOX (at the current sampled pool rate) is proportional.
    */
    function _checkIfAmountToStakeAndInvestAreProportional(uint256 amountToStake, uint256 correspondingAmountToInvestInToken, uint256 tokenYear) private pure returns (bool withinBounds) {
        
        (uint256 numerator, uint256 denominator) = getInvestmentRateForTokenPerYear(tokenYear);

        //calculate the corresponding quantity in tokens a user should invest in busd
        uint256 targetQuantityInTokensToInvest = amountToStake.mul(numerator).div(denominator);
        
        //check the difference between the calculated invested busd in tokens and the provided amount
        uint256 diff = _diffValues(targetQuantityInTokensToInvest, correspondingAmountToInvestInToken);
        
         //the % error should be less than 10%
        return (_isDiffBelowPercentDifference(diff, correspondingAmountToInvestInToken, 10));
    }
    
    /**
     * @dev Private function to process the transferred BUSD upon stake creation.
     */
    function _processInvestedBusdForStake(uint256 amountToInvestBusd, address referral, uint256 poolTokenAvg, uint256 poolBusdAvg) private {
        //check if user has enough busd to invest    
        require(BUSD_CONTRACT.balanceOf(msg.sender) >= amountToInvestBusd, "Account does not have enough BUSD");
        require(BUSD_CONTRACT.allowance(msg.sender, address(this)) >= amountToInvestBusd, "Not enough BUSD allowed");
        require(BUSD_CONTRACT.transferFrom(msg.sender, address(this), amountToInvestBusd), "Unable to transfer required BUSD");
        
        
        //check if referral was provided and if so update it
        if(referral != address(0x0) && referral != msg.sender) {
            referrals[msg.sender] = referral;
        }
        
        //if there is an address to work with, otherwise do nothing
        if(referrals[msg.sender] != address(0x0)) {
            //calculate the corresponding amount again since it might have been ajusted
            uint256 tokensToMintForReferral = amountToInvestBusd
                .mul(poolTokenAvg)
                .mul(REF_NUMERATOR)
                //since the poolBusdAvg passed to this function is retrieved from the getPoolAvg which ensures the poolBusdAvg is never 0
                //this division never results in a division by zero
                .div(poolBusdAvg)
                //this REF_DENOMINATOR is a constant and is never zero
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

        //all busd that remains will be added to the liquidity pool
    }

    /**
     * @dev External function to create a stake.
     * The user has to provide the amount of NOX he wants to stake, the correct proportion of busd to invest, and the referral address (0x0 address is the accepted default value if no referral address is provided)
     * If user has enough busd as credit from participating in auctions, no busd will be debited.
     * All debited busd will be minted back to the user. This means free NOX for the user if the user has credit from auctions.
     */
    function createStake(uint256 amountToStake, uint256 amountToInvestBusd, address referral) updateDayTrigger external {
        require(amountToStake > 100000, "Cannot stake less than 100000 millis");
        require(amountToInvestBusd > 0, "Cannot invest less than 0");
        
        require(BEP20Token(address(this)).balanceOf(msg.sender) >= amountToStake, "Account does not have enough tokens");
        require(_notContract(referral), "Referral address cannot be a contract");
        
        //the CurrentSharePrice only increases therefore it will never be 0
        uint256 newStakeShares = amountToStake.mul(SHARE_PRICE_PRECISION).div(CurrentSharePrice);
        require(newStakeShares > 0, "Staked amount is not enough to buy shares");
        
        uint256 originalAmountToInvestBusd = amountToInvestBusd;
        //get the current pool ratio
        (uint256 poolTokenAvg, uint256 poolBusdAvg) = getPoolAvg();
        
        //calculate the amount in tokens being invested, according to the ratio retrieved by the pool
        //since the poolBusdAvg is retrieved from getPoolAvg and getPoolAvg ensures poolBusdAvg is never 0, this division never results in a division by zero
        uint256 correspondingAmountToInvestInToken = amountToInvestBusd.mul(poolTokenAvg).div(poolBusdAvg);
        
        bool isRatioWithinBounds = _checkIfAmountToStakeAndInvestAreProportional(amountToStake, correspondingAmountToInvestInToken, CurrentTokenYear);
        require(isRatioWithinBounds, "The ratio of tokens to invest to busd is not correct");
        //otherwise, the user isn't exceeding the maximum investment amount
        
        
        //burn stake amount
        _burn(msg.sender, amountToStake);
        //increase the number of tokens staked
        TokensStakedAccounting = TokensStakedAccounting.add(amountToStake);
        totalStakedByAccounts[msg.sender] = totalStakedByAccounts[msg.sender].add(amountToStake);
        
        
        //check if the user has bought tokens through auction
        uint256 busdAmountInvestedToAuction = IAuctionContract(AUCTION_CONTRACT).checkDonatorBusdCredit(msg.sender);
        
        //if the user has bought through auction deduct from investment and deduct from auction
        if(busdAmountInvestedToAuction > 0) {
            
            uint256 quantityToDeduct = busdAmountInvestedToAuction > amountToInvestBusd ? amountToInvestBusd : busdAmountInvestedToAuction;

            //adjust amount to invest
            amountToInvestBusd = amountToInvestBusd.sub(quantityToDeduct);

            //update user credit on auction
            IAuctionContract(AUCTION_CONTRACT).deductDonatorBusdCredit(msg.sender, quantityToDeduct);

            uint256 correspondingQuantityInTokensToDeduct = quantityToDeduct.mul(poolTokenAvg).div(poolBusdAvg);
            //mint back to the user, in tokens, the amount of busd that was deducted from his credit
            _mint(msg.sender, correspondingQuantityInTokensToDeduct);

        } //otherwise, user hasn't bought through auction
            

        //amount invested might be 0 if enough was donated to auction
        if(amountToInvestBusd > 0) {
        
            _processInvestedBusdForStake(amountToInvestBusd, referral, poolTokenAvg, poolBusdAvg);
        }
        
        //try to register the pool ratio
        registerPoolRatio();
        
        //create the stake
        Stake memory newStake;
        
        newStake.stakeId = generateID(msg.sender, stakeCount[msg.sender], 0x01);
        newStake.stakeAmount = amountToStake;
        newStake.shares = newStakeShares;
        newStake.investmentAmountInBusd = originalAmountToInvestBusd;
        newStake.stakeState = StakeState.Active;
        
        newStake.stakeStartTokenDay = CurrentTokenDay;
        
        stakes[msg.sender][newStake.stakeId] = newStake;
        stakeCount[msg.sender] = stakeCount[msg.sender] + 1;
        ActiveStakesAccounting = ActiveStakesAccounting + 1;
        
        
        //increase total shares
        SharesAccounting = SharesAccounting.add(newStakeShares);
        emit stakeCreated(newStake.stakeId, msg.sender, newStake.stakeAmount, newStake.investmentAmountInBusd, newStake.stakeStartTokenDay);
        
    }
    
    /**
     * @dev External function to end a stake. Applies the penalties (if any) on the principal, calculates the accrued interest, and mints back to the user both principal and interest.
     */
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
       
        //decrease the number of tokens staked
        TokensStakedAccounting = TokensStakedAccounting.sub(stake.stakeAmount);
        totalStakedByAccounts[msg.sender] = totalStakedByAccounts[msg.sender].sub(stake.stakeAmount);

        //decrease total shares
        SharesAccounting = SharesAccounting.sub(stake.shares);
        
        //decrease total active stakes
        ActiveStakesAccounting = ActiveStakesAccounting - 1;
        
         //mint back principal (with possible penalties) plus accrued interest
        _mint(msg.sender, tokensToMint);
        
        _updateSharePrice(stakeId, stake.numDaysAccountedFor, stake.stakeAmount, stake.shares, tokensToMint);
        
        emit stakeEnded(stakeId, msg.sender, tokensToMint, CurrentTokenDay);
        
        //try to register the pool ratio
        registerPoolRatio();
    }
    
    /**
     * @dev External function to move a stake.
     * Marks the provided stake as moved, and creates a new stake equal to the moved one for the receiver address.
     * No new shares are generated from this operations.
     * The stake marked as moved has all it's accounting closed.
     */
    function moveStake(bytes16 stakeId, address toAddress) updateDayTrigger external {
        require(toAddress != msg.sender, 'Sender and receiver cannot be the same');

        Stake storage stake = stakes[msg.sender][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Sender does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active, "Stake can only be moved if it is active");
        
        Stake memory newStake;

        _cloneStake(stake, newStake);
        
        //mark the old stake as moved
        stake.stakeState = StakeState.Moved;
        stake.numDaysAccountedFor = CurrentTokenDay.sub(stake.stakeStartTokenDay);
        stake.accountingStartTokenDay = CurrentTokenDay;
        stake.accountingStartDayOfYear = CurrentDayOfYear;
        stake.accountingStartTokenYear = CurrentTokenYear;
        
        //save the new stake for the new staker (toAddress)
        bytes16 newReceiverStakeID = generateID(toAddress, stakeCount[toAddress], 0x01);
        newStake.stakeId = newReceiverStakeID;
        stakes[toAddress][newReceiverStakeID] = newStake;
        stakeCount[toAddress] = stakeCount[toAddress] + 1;

        //update accounting of total staked
        totalStakedByAccounts[msg.sender] = totalStakedByAccounts[msg.sender].sub(stake.stakeAmount);
        totalStakedByAccounts[toAddress] = totalStakedByAccounts[toAddress].add(stake.stakeAmount);
 
        emit stakeMoved(stakeId, msg.sender, toAddress, CurrentTokenDay);
        
        //try to register the pool ratio
        registerPoolRatio();
    }
    
    /**
     * @dev External function to split a stake.
     * Creates a new stake and has the principal, interest, and shares, of the current stake and new stake split according to the split divisor.
     * A split divisor of 2 is a split in 50% of the current stake, and a split divisor of 10000 is a split of 0.01% of the current stake.
     * The new stake has all the remaining data equal to the current stake.
     */
    function splitStake(bytes16 stakeId, uint256 splitDivisor) updateDayTrigger external {
        
        require(splitDivisor >= 2 && splitDivisor <= 10000, "Divisor must be between 2 and 10000");
        
        Stake storage stake = stakes[msg.sender][stakeId];
        bool stakeFound = stake.stakeId == stakeId;
        require(stakeFound, "Sender does not contain stake with provided id");
        require(stake.stakeState == StakeState.Active, "Stake can only be split if it is active");
     
        Stake memory newStake;
        _cloneStake(stake, newStake);
        
        newStake.stakeId = generateID(msg.sender, stakeCount[msg.sender], 0x01);
        
        //update the new stake principal applying the divisor
        //the splitDivisor can never be 0 as required by the function
        newStake.stakeAmount = newStake.stakeAmount.div(splitDivisor);
        require(newStake.stakeAmount > 0, "Split cancelled, the new stake would have 0 principal");
        //update the current stake principal by subtracting the one applied to the new stake
        stake.stakeAmount = stake.stakeAmount >= newStake.stakeAmount ? stake.stakeAmount.sub(newStake.stakeAmount) : 0;
        require(stake.stakeAmount > 0, "Split cancelled, the current stake would have 0 principal");
        
        //do the same for shares
        newStake.shares = newStake.shares.div(splitDivisor);
        require(newStake.shares > 0, "Split cancelled, the new stake would have 0 shares");
        stake.shares = stake.shares >= newStake.shares ? stake.shares.sub(newStake.shares) : 0;
        require(stake.shares > 0, "Split cancelled, the current stake would have 0 shares");
        
        //do the same for interest
        //since the interest is zero in storage until the stake is accounted for, the bigger than 0 requirements do not apply here
        newStake.interestAmount = newStake.interestAmount.div(splitDivisor);
        stake.interestAmount = stake.interestAmount >= newStake.interestAmount ? stake.interestAmount.sub(newStake.interestAmount) : 0;
        
        //save new stake
        stakes[msg.sender][newStake.stakeId] = newStake;

        //increment stake count
        stakeCount[msg.sender] = stakeCount[msg.sender] + 1;
        
        //increase total active stakes
        ActiveStakesAccounting = ActiveStakesAccounting + 1;

        emit stakeSplit(stake.stakeId, newStake.stakeId, splitDivisor, msg.sender, CurrentTokenDay);
        
        //try to register the pool ratio
        registerPoolRatio();
    }
    
    /**
     * @dev External function to merge two stakes.
     * Both stakes are marked as closed, and a new stake is created with the sum of the principal, accrued interest, and shares of both stakes.
     */
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
    
    /**
     * @dev Private helper function to merge two stakes.
     * Needs to receive the older and newer stakes, accordingly, to ajust the accrued interest from the older stake until the creation date from the newer stake.
     */
    function _mergeStakes(address owner, Stake storage olderStake, Stake storage newerStake) private {
        //determine the difference of days - has to be >= 0
        uint256 diff = newerStake.stakeStartTokenDay - olderStake.stakeStartTokenDay;
        
        //get all days of interest from older stake until the start of the newer stake
        (uint256 principal, uint256 interest) = getPrincipalAndInterestForStake(owner, olderStake.stakeId, diff);
        
        //add principal, interest and shares from older stake to newer stake
        newerStake.stakeAmount = newerStake.stakeAmount.add(principal);
        newerStake.interestAmount = newerStake.interestAmount.add(interest);
        newerStake.shares = newerStake.shares.add(olderStake.shares);
        
        //end old stake
        olderStake.stakeState = StakeState.Merged;
        //store the interest calculated up until the start of the newer stake
        olderStake.interestAmount = interest;
        //store the number of days accounted for until the start of the newer stake
        olderStake.numDaysAccountedFor = diff;
        olderStake.accountingStartTokenDay = CurrentTokenDay;
        olderStake.accountingStartDayOfYear = CurrentDayOfYear;
        olderStake.accountingStartTokenYear = CurrentTokenYear;

        //decrease total active stakes
        ActiveStakesAccounting = ActiveStakesAccounting - 1;
        
        emit stakesMerged(olderStake.stakeId, newerStake.stakeId, owner, CurrentTokenDay);
        
        //try to register the pool ratio
        registerPoolRatio();
        
    }

    /**
     * @dev External function to start or continue the accounting of a stake.
     * This function is used to end very long stakes. It ensures stakes can always be ended because this way it is not required to fit all accounting into one block only.
     * Accounting can be done slowly, through multiple transactions.
     */
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
        
        //update the stake interest
        //this is an attribution and not an addition because the addition of the current stake interest plus the accrued interest for numDaysToAccountFor
        //has been calculated inside the getPrincipalAndInterestForStake function
        stake.interestAmount = interest;
        
        stake.numDaysAccountedFor = stake.numDaysAccountedFor.add(numDaysToAccountFor);
        
        //try to register the pool ratio
        registerPoolRatio();
        
    }

    /**
     * @dev Private function to update the share price. Calculations are similar to the HEX model.
     */
    function _updateSharePrice(bytes16 stakeId, uint256 stakeDays, uint256 stakedAmount, uint256 stakeShares, uint256 stakeReturn) private {
        if (stakeReturn > stakedAmount) {
            

            //we want to avoid very sharp share price increases
            //this should happen only when there is much more unstaked tokens than staked tokens
            //as such we should assume a maximum share price increase that is aligned with the average stake interest growth in normal situations
            //let us therefore assume an average daily interest of 1% (this is a good aproximate for the first two years)
            //as such, the average return a stake should have is stakedAmount + (0.01 x stakedAmount x stakeDays)
            //let us then cap the max stake return to that
            uint256 stakeReturnCap = stakedAmount + stakedAmount.mul(stakeDays).div(100);

            if(stakeReturn > stakeReturnCap) {
                stakeReturn = stakeReturnCap;
            }


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
    
    /**
     * @dev External function to provide pagination of stakes.
     */
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
    
    /**
     * @dev External function to provide pagination of daily registered inflations.
     */
    function inflationPagination(uint256 offset, uint256 length) external view returns (Inflation[] memory inflations) {
        //if offset has exceeded the available elements return an empty array
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


/**
 * @dev NOX contract that inherits from all abstract contracts
 */
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
    
    /**
     * @dev External function accessible only by the token definer to set external addresses and contracts.
     */
    function setContracts(address auctionContract, address mAddress1, address mAddress2) external onlyTokenDefiner {
        AUCTION_CONTRACT = auctionContract;
        M_ADDRESS1 = mAddress1;
        M_ADDRESS2 = mAddress2;
    }

    /**
     * @dev External function accessible only by the token definer to set the timestamp for the start of the NOX contract.
     */
    function startContract(uint256 timestamp) external onlyTokenDefiner {
        
        TokenStartTimestamp = timestamp; //value should be 1641056400
        CurrentYear = _getYear(TokenStartTimestamp);
        CurrentDayOfYear = _getDayOfYear(TokenStartTimestamp);
        CurrentTokenDay = 1;
        CurrentTokenYear = 1;
    }
    
    /**
     * @dev External function accessible only by the token definer to forever deny special access for the token definer. This operation is irreversible.
     */
    function revokeAccess() external onlyTokenDefiner {
        TOKEN_DEFINER = address(0x0);
    }
    
    /**
     * @dev NOX token contract constructor.
     */
    constructor() BEP20Token("NOX", "NOX") {
        
        CurrentSharePrice = INITIAL_SHARE_PRICE;
        
        TOKEN_DEFINER = msg.sender;
        
        BUSD_CONTRACT = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        UNISWAP_ROUTER = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
    }
    
    /**
     * @dev External function to mint supply for the auction contract only.
     */
    function mintSupply(address addr, uint256 amount) external {
        require(msg.sender == AUCTION_CONTRACT, "Not authorized");
        _mint(addr, amount);
    }
}