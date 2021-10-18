/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity 0.5.16;

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
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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

  /**
   * @dev returns all information about the vesting schedule directly associated with the given
   * account.
   */
  function getIntrinsicVestingSchedule(address grantHolder)
  external
  view
  returns (
      uint32 cliffDuration,
      uint32 vestDuration,
      uint32 vestIntervalDays
  );

  /**
   * @dev Immediately grants tokens to an account, referencing a vesting schedule which may be
   * stored in the same account (individual/one-off) or in a different account (shared/uniform).
   */
  function grantVestingTokens(
      address beneficiary,
      uint256 totalAmount,
      uint256 vestingAmount,
      uint32 startDay,
      uint32 duration,
      uint32 cliffDuration,
      uint32 interval,
      bool isRevocable
  ) external returns (bool ok);

  /**
   * @dev returns the day number of the current day, in days since the UNIX epoch.
   */
  function today() external view returns (uint32 dayNumber);

  /**
   * @dev returns all information about the grant's vesting as of the given day
   * for the given account.
   */
  function vestingForAccountAsOf(
      address grantHolder,
      uint32 onDayOrToday
  )
  external
  view
  returns (
      uint256 amountVested,
      uint256 amountNotVested,
      uint256 amountOfGrant,
      uint32 vestStartDay,
      uint32 cliffDuration,
      uint32 vestDuration,
      uint32 vestIntervalDays,
      bool isActive,
      bool wasRevoked,
      uint32 revokedDay
  );

  /**
   * @dev If the account has a revocable grant, this forces the grant to end based on computing
   * the amount vested up to the given date. All tokens that would no longer vest are returned
   * to the account of the original grantor. 
   */
  function revokeGrant(address grantHolder) external returns (bool);
  
  /**
   * @dev Returns the available amount of a grantHolder.
   */
  function getAvailableAmount(address grantHolder, uint32 onDayOrToday) external view returns (uint256);

  event VestingScheduleCreated(
      address indexed vestingLocation,
      uint32 cliffDuration, uint32 indexed duration, uint32 interval,
      bool indexed isRevocable);

  event VestingTokensGranted(
      address indexed beneficiary,
      uint256 indexed vestingAmount,
      uint32 startDay,
      address vestingLocation,
      address indexed grantor);

  event GrantRevoked(address indexed grantHolder, uint32 indexed onDay);
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
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
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

contract BEP20A53 is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _maxTotalSupply;
  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;
  
  // Date-related constants for sanity-checking dates to reject obvious erroneous inputs
  // and conversions from seconds to days and years that are more or less leap year-aware.
  uint32 private constant THOUSAND_YEARS_DAYS = 365243;                   /* See https://www.timeanddate.com/date/durationresult.html?m1=1&d1=1&y1=2000&m2=1&d2=1&y2=3000 */
  uint32 private constant TEN_YEARS_DAYS = THOUSAND_YEARS_DAYS / 100;     /* Includes leap years (though it doesn't really matter) */
  uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;                 /* 86400 seconds in a day */
  uint32 private constant JAN_1_2000_SECONDS = 946684800;                 /* Saturday, January 1, 2000 0:00:00 (GMT) (see https://www.epochconverter.com/) */
  uint32 private constant JAN_1_2000_DAYS = JAN_1_2000_SECONDS / SECONDS_PER_DAY;
  uint32 private constant JAN_1_3000_DAYS = JAN_1_2000_DAYS + THOUSAND_YEARS_DAYS;

  struct vestingSchedule {
      bool isValid;               /* true if an entry exists and is valid */
      bool isRevocable;           /* true if the vesting option is revocable (a gift), false if irrevocable (purchased) */
      uint32 cliffDuration;       /* Duration of the cliff, with respect to the grant start day, in days. */
      uint32 duration;            /* Duration of the vesting schedule, with respect to the grant start day, in days. */
      uint32 interval;            /* Duration in days of the vesting interval. */
  }

  struct tokenGrant {
      bool isActive;              /* true if this vesting entry is active and in-effect entry. */
      bool wasRevoked;            /* true if this vesting schedule was revoked. */
      uint32 startDay;            /* Start day of the grant, in days since the UNIX epoch (start of day). */
      uint256 amount;             /* Total number of tokens that vest. */
      address vestingLocation;    /* Address of wallet that is holding the vesting schedule. */
      address grantor;            /* Grantor that made the grant */
      uint32 revokedDay;          /* the day this vesting schedule was revoked */
  }
  
  mapping(address => vestingSchedule) private _vestingSchedules;
  mapping(address => tokenGrant) private _tokenGrants;

  constructor() public {
    _name = "A53 Token";
    _symbol = "A53";
    _decimals = 18;
    _maxTotalSupply = 150000000 * 10**18;
    _totalSupply = 1350000 * 10**18;
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);


  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
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
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }
  

  // =========================================================================
  // === Methods for administratively creating a vesting schedule for an account.
  // =========================================================================

  /**
   * @dev This one-time operation permanently establishes a vesting schedule in the given account.
   *
   * @param vestingLocation = Account into which to store the vesting schedule.
   * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
   * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
   * @param interval = Number of days between vesting increases.
   * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
   *   be revoked (i.e. tokens were purchased).
   */
  function _setVestingSchedule(
      address vestingLocation,
      uint32 cliffDuration, uint32 duration, uint32 interval,
      bool isRevocable) internal returns (bool ok) {

      // Check for a valid vesting schedule given (disallow absurd values to reject likely bad input).
      require(
          duration > 0 && duration <= TEN_YEARS_DAYS
          && cliffDuration < duration
          && interval >= 1,
          "invalid vesting schedule"
      );

      // Make sure the duration values are in harmony with interval (both should be an exact multiple of interval).
      require(
          duration % interval == 0 && cliffDuration % interval == 0,
          "invalid cliff/duration for interval"
      );

      // Create and populate a vesting schedule.
      _vestingSchedules[vestingLocation] = vestingSchedule(
          true/*isValid*/,
          isRevocable,
          cliffDuration, duration, interval
      );

      // Emit the event and return success.
      emit VestingScheduleCreated(
          vestingLocation,
          cliffDuration, duration, interval,
          isRevocable);
      return true;
  }

  function _hasVestingSchedule(address account) internal view returns (bool ok) {
      return _vestingSchedules[account].isValid;
  }

  /**
   * @dev returns all information about the vesting schedule directly associated with the given
   * account.
   *
   * @param grantHolder = The address to do this for.
   *   the special value 0 to indicate today.
   * @return = A tuple with the following values:
   *   vestDuration = grant duration in days.
   *   cliffDuration = duration of the cliff.
   *   vestIntervalDays = number of days between vesting periods.
   */
  function getIntrinsicVestingSchedule(address grantHolder)
  public
  view
  returns (
      uint32 vestDuration,
      uint32 cliffDuration,
      uint32 vestIntervalDays
  )
  {
      return (
      _vestingSchedules[grantHolder].duration,
      _vestingSchedules[grantHolder].cliffDuration,
      _vestingSchedules[grantHolder].interval
      );
  }

  // =========================================================================
  // === Token grants (general-purpose)
  // === Methods to be used for administratively creating one-off token grants with vesting schedules.
  // =========================================================================

  /**
   * @dev Immediately grants tokens to an account, referencing a vesting schedule which may be
   * stored in the same account (individual/one-off) or in a different account (shared/uniform).
   *
   * @param beneficiary = Address to which tokens will be granted.
   * @param totalAmount = Total number of tokens to deposit into the account.
   * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
   * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
   *   (start of day). The startDay may be given as a date in the future or in the past, going as far
   *   back as year 2000.
   * @param vestingLocation = Account where the vesting schedule is held (must already exist).
   * @param grantor = Account which performed the grant. Also the account from where the granted
   *   funds will be withdrawn.
   */
  function _grantVestingTokens(
      address beneficiary,
      uint256 totalAmount,
      uint256 vestingAmount,
      uint32 startDay,
      address vestingLocation,
      address grantor
  )
  internal returns (bool ok)
  {
    // Make sure no prior grant is in effect.
    require(!_tokenGrants[beneficiary].isActive, "grant already exists");

      // Check for valid vestingAmount
      require(
          vestingAmount <= totalAmount && vestingAmount > 0
          && startDay >= JAN_1_2000_DAYS && startDay < JAN_1_3000_DAYS,
          "invalid vesting params");

      // Make sure the vesting schedule we are about to use is valid.
      require(_hasVestingSchedule(vestingLocation), "no such vesting schedule");

      // Transfer the total number of tokens from grantor into the account's holdings.
      _transfer(grantor, beneficiary, totalAmount);

      // Create and populate a token grant, referencing vesting schedule.
      _tokenGrants[beneficiary] = tokenGrant(
          true/*isActive*/,
          false/*wasRevoked*/,
          startDay,
          vestingAmount,
          vestingLocation, /* The wallet address where the vesting schedule is kept. */
          grantor,             /* The account that performed the grant (where revoked funds would be sent) */
          0 /* RevokedDay = 0 */
      );

      // Emit the event and return success.
      emit VestingTokensGranted(beneficiary, vestingAmount, startDay, vestingLocation, grantor);
      return true;
  }

  /**
   * @dev Immediately grants tokens to an address, including a portion that will vest over time
   * according to a set vesting schedule. The overall duration and cliff duration of the grant must
   * be an even multiple of the vesting interval.
   *
   * @param beneficiary = Address to which tokens will be granted.
   * @param totalAmount = Total number of tokens to deposit into the account.
   * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
   * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
   *   (start of day). The startDay may be given as a date in the future or in the past, going as far
   *   back as year 2000.
   * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
   * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
   * @param interval = Number of days between vesting increases.
   * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
   *   be revoked (i.e. tokens were purchased).
   */
  function grantVestingTokens(
      address beneficiary,
      uint256 totalAmount,
      uint256 vestingAmount,
      uint32 startDay,
      uint32 duration,
      uint32 cliffDuration,
      uint32 interval,
      bool isRevocable
  ) public onlyOwner returns (bool ok) {
      // Make sure no prior vesting schedule has been set.
      require(!_tokenGrants[beneficiary].isActive, "grant already exists");

      // The vesting schedule is unique to this wallet and so will be stored here,
      _setVestingSchedule(beneficiary, cliffDuration, duration, interval, isRevocable);

      // Issue grantor tokens to the beneficiary, using beneficiary's own vesting schedule.
      _grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, beneficiary, msg.sender);

      return true;
  }

  /**
   * @dev returns the day number of the current day, in days since the UNIX epoch.
   * From 0:0:0 GMT of the day
   */
  function today() public view returns (uint32 dayNumber) {
      return uint32(block.timestamp / SECONDS_PER_DAY);
  }

  function _effectiveDay(uint32 onDayOrToday) internal view returns (uint32 dayNumber) {
      return onDayOrToday == 0 ? today() : onDayOrToday;
  }

  /**
   * @dev Determines the amount of tokens that have not vested in the given account.
   *
   * The math is: not vested amount = vesting amount * (end date - on date)/(end date - start date)
   *
   * @param grantHolder = The account to check.
   * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
   *   the special value 0 to indicate today.
   */
  function _getNotVestedAmount(address grantHolder, uint32 onDayOrToday) internal view returns (uint256 amountNotVested) {
      tokenGrant storage grant = _tokenGrants[grantHolder];
      vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
      uint32 onDay = _effectiveDay(onDayOrToday);
      uint32 daysVested;

      // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
      if ((!grant.isActive || onDay < grant.startDay + vesting.cliffDuration) && !grant.wasRevoked)
      {
          // None are vested (all are not vested)
          return grant.amount;
      }
      // If after end of vesting, then the not vested amount is zero (all are vested).
      else if (onDay >= grant.startDay + vesting.duration)
      {
          // All are vested (none are not vested)
          return uint256(0);
      }
      // If there's schedule, but was revoked
      else if (grant.wasRevoked){
          // Compute the exact number of days vested.
          daysVested = grant.revokedDay - grant.startDay;
      }
      // Otherwise a fractional amount is vested.
      else
      {
          // Compute the exact number of days vested.
          daysVested = onDay - grant.startDay;
      }
          
     // Adjust result rounding down to take into consideration the interval.
     uint32 effectiveDaysVested = (daysVested / vesting.interval) * vesting.interval;

     // Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
     // Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
     // typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
     // bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
     // amounts many orders of magnitude greater than mere billions.
     uint256 vested = grant.amount.mul(effectiveDaysVested).div(vesting.duration);
     return grant.amount.sub(vested);
  }

  /**
   * @dev Computes the amount of funds in the given account which are available for use as of
   * the given day. If there's no vesting schedule then 0 tokens are considered to be vested and
   * this just returns the full account balance.
   *
   * The math is: available amount = total funds - notVestedAmount.
   *
   * @param grantHolder = The account to check.
   * @param onDay = The day to check for, in days since the UNIX epoch.
   */
  function _getAvailableAmount(address grantHolder, uint32 onDay) internal view returns (uint256 amountAvailable) {
      tokenGrant storage grant = _tokenGrants[grantHolder];
      uint256 totalTokens = _balances[grantHolder];
      if(grant.isActive){
          return totalTokens.sub(_getNotVestedAmount(grantHolder, onDay));
      }
      else{
          return totalTokens;
      }
  }

  /**
   * @dev returns all information about the grant's vesting as of the given day
   * for the given account.
   *
   * @param grantHolder = The address to do this for.
   * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
   *   the special value 0 to indicate today.
   * @return = A tuple with the following values:
   *   amountVested = the amount out of vestingAmount that is vested
   *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
   *   amountOfGrant = the amount of tokens subject to vesting.
   *   vestStartDay = starting day of the grant (in days since the UNIX epoch).
   *   vestDuration = grant duration in days.
   *   cliffDuration = duration of the cliff.
   *   vestIntervalDays = number of days between vesting periods.
   *   isActive = true if the vesting schedule is currently active.
   *   wasRevoked = true if the vesting schedule was revoked.
   */
  function vestingForAccountAsOf(
      address grantHolder,
      uint32 onDayOrToday
  )
  public
  view
  returns (
      uint256 amountVested,
      uint256 amountNotVested,
      uint256 amountOfGrant,
      uint32 vestStartDay,
      uint32 vestDuration,
      uint32 cliffDuration,
      uint32 vestIntervalDays,
      bool isActive,
      bool wasRevoked,
      uint32 revokedDay
  )
  {
      tokenGrant storage grant = _tokenGrants[grantHolder];
      vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
      uint256 notVestedAmount = _getNotVestedAmount(grantHolder, onDayOrToday);
      uint256 grantAmount = grant.amount;

      return (
      grantAmount.sub(notVestedAmount),
      notVestedAmount,
      grantAmount,
      grant.startDay,
      vesting.duration,
      vesting.cliffDuration,
      vesting.interval,
      grant.isActive,
      grant.wasRevoked,
      grant.revokedDay
      );
  }

  /**
   * @dev returns true if the account has sufficient funds available to cover the given amount,
   *   including consideration for vesting tokens.
   *
   * @param account = The account to check.
   * @param amount = The required amount of vested funds.
   * @param onDay = The day to check for, in days since the UNIX epoch.
   */
  function _fundsAreAvailableOn(address account, uint256 amount, uint32 onDay) internal view returns (bool ok) {
      return (amount <= _getAvailableAmount(account, onDay));
  }


  // =========================================================================
  // === Grant revocation
  // =========================================================================

  /**
   * @dev If the account has a revocable grant, this forces the grant to end based on computing
   * the amount vested up to the given date. All tokens that would no longer vest are returned
   * to the account of the original grantor.
   *
   * @param grantHolder = Address to which tokens will be granted.
   */
  function revokeGrant(address grantHolder) public onlyOwner returns (bool ok) {
      tokenGrant storage grant = _tokenGrants[grantHolder];
      vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
      uint256 notVestedAmount;

      // Make sure grantor can only revoke from own pool.
      require(msg.sender == owner() || msg.sender == grant.grantor, "not allowed");
      // Make sure a vesting schedule has previously been set.
      require(grant.isActive, "no active vesting schedule");
      // Make sure it's revocable.
      require(vesting.isRevocable, "irrevocable");
        
      uint32 onDay = _effectiveDay(0);
      // Fail on likely erroneous input.
      require(onDay <= grant.startDay + vesting.duration, "no effect");
        
      notVestedAmount = _getNotVestedAmount(grantHolder, onDay);

      // take back not-vested tokens from grantHolder.
      _transfer(grantHolder, grant.grantor, notVestedAmount);

      // Kill the grant by updating wasRevoked and isActive.
      _tokenGrants[grantHolder].wasRevoked = true;
      _tokenGrants[grantHolder].isActive = false;
      _tokenGrants[grantHolder].revokedDay = onDay;

      emit GrantRevoked(grantHolder, onDay);
      /* Emits the GrantRevoked event. */
      return true;
  }
  
  /**
   * @dev Returns the available amount of a grantHolder.
   */
  function getAvailableAmount(address grantHolder, uint32 onDayOrToday) external view returns (uint256){
      uint32 onDay = _effectiveDay(onDayOrToday);
      return _getAvailableAmount(grantHolder, onDay);
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
    require(_fundsAreAvailableOn(msg.sender, amount, today()), "fund are unavailable");
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
    require(_fundsAreAvailableOn(msg.sender, amount, today()), "fund are unavailable");
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
    require(_fundsAreAvailableOn(sender, amount, today()), "fund are unavailable");
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
    require(_fundsAreAvailableOn(msg.sender, _allowances[msg.sender][spender] + addedValue, today()), "fund are unavailable");
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
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
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
    require((_totalSupply + amount) <= _maxTotalSupply, "exceed the allowable total supply limit");

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