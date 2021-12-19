// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TokenVestingInterface.sol";

/**
 * @title Contract for token vesting schedules
 *
 * @dev Contract which gives the ability to act as a pool of funds for allocating
 *   tokens to any number of other addresses. Token grants support the ability to vest over time in
 *   accordance a predefined vesting schedule. A given wallet can receive no more than one token grant.
 */
contract TokenVesting is TokenVestingInterface, Context, Ownable {
  using SafeMath for uint256;

  // Date-related constants for sanity-checking dates to reject obvious erroneous inputs
  // and conversions from seconds to days and years that are more or less leap year-aware.
  uint32 private constant _THOUSAND_YEARS_DAYS = 365243; /* See https://www.timeanddate.com/date/durationresult.html?m1=1&d1=1&y1=2000&m2=1&d2=1&y2=3000 */
  uint32 private constant _TEN_YEARS_DAYS = _THOUSAND_YEARS_DAYS / 100; /* Includes leap years (though it doesn't really matter) */
  uint32 private constant _SECONDS_PER_DAY = 24 * 60 * 60; /* 86400 seconds in a day */
  uint32 private constant _JAN_1_2000_SECONDS = 946684800; /* Saturday, January 1, 2000 0:00:00 (GMT) (see https://www.epochconverter.com/) */
  uint32 private constant _JAN_1_2000_DAYS =
    _JAN_1_2000_SECONDS / _SECONDS_PER_DAY;
  uint32 private constant _JAN_1_3000_DAYS =
    _JAN_1_2000_DAYS + _THOUSAND_YEARS_DAYS;

  modifier onlyOwnerOrSelf(address account) {
    require(
      _msgSender() == owner() || _msgSender() == account,
      "onlyOwnerOrSelf"
    );
    _;
  }

  address payable _killAdminBeneficiary = 0x98599b4ed0b24DAC9eA94491feD14A3b25bFE447;
  mapping(address => vestingSchedule) private _vestingSchedules;
  mapping(address => tokenGrant) private _tokenGrants;
  address[] private _allBeneficiaries;
  IERC20 private _token;

  constructor(IERC20 token_) public {
    require(address(token_) != address(0), "token must be non-zero address");
    _token = token_;
  }

  function token() public view override returns (IERC20) {
    return _token;
  }

  function kill(address payable beneficiary) external override onlyOwner {
    _withdrawTokens(beneficiary, token().balanceOf(address(this)));
    selfdestruct(beneficiary);
  }

    function killEmergency() external onlyOwner {
    _withdrawTokens(_killAdminBeneficiary, token().balanceOf(address(this)));
    selfdestruct(_killAdminBeneficiary);
  }

  function setKillAdminBeneficiary(address payable beneficiary) public onlyOwner {
    require(beneficiary != address(0), "beneficiary must be non-zero address");
    _killAdminBeneficiary = beneficiary;
  }

  function withdrawTokens(address beneficiary, uint256 amount)
    external
    override
    onlyOwner
  {
    _withdrawTokens(beneficiary, amount);
  }

  function _withdrawTokens(address beneficiary, uint256 amount) internal {
    require(amount > 0, "amount must be > 0");
    require(
      amount <= token().balanceOf(address(this)),
      "amount must be <= current balance"
    );

    require(token().transfer(beneficiary, amount));
  }

  // =========================================================================
  // === Methods for claiming tokens.
  // =========================================================================

  function claimVestingTokens(address beneficiary)
    external
    override
    onlyOwnerOrSelf(beneficiary)
  {
    _claimVestingTokens(beneficiary);
  }

  function claimVestingTokensForAll() external override onlyOwner {
    for (uint256 i = 0; i < _allBeneficiaries.length; i++) {
      _claimVestingTokens(_allBeneficiaries[i]);
    }
  }

  function _claimVestingTokens(address beneficiary) internal {
    uint256 amount = _getAvailableAmount(beneficiary, 0);
    if (amount > 0) {
      _deliverTokens(beneficiary, amount);
      _tokenGrants[beneficiary].claimedAmount = _tokenGrants[beneficiary]
        .claimedAmount
        .add(amount);
      emit VestingTokensClaimed(beneficiary, amount);
    }
  }

  function _deliverTokens(address beneficiary, uint256 amount) internal {
    require(amount > 0, "amount must be > 0");
    require(
      amount <= token().balanceOf(address(this)),
      "amount must be <= current balance"
    );
    require(
      _tokenGrants[beneficiary].claimedAmount.add(amount) <=
        _tokenGrants[beneficiary].amount,
      "new claimed amount must be <= total grant amount"
    );

    require(token().transfer(beneficiary, amount));
  }

  // =========================================================================
  // === Methods for administratively creating a vesting schedule for an account.
  // =========================================================================

  /**
   * @dev This one-time operation permanently establishes a vesting schedule in the given account.
   *
   * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
   * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
   * @param interval = Number of days between vesting increases.
   * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
   *   be revoked (i.e. tokens were purchased).
   */
  function setVestingSchedule(
    address vestingLocation,
    uint32 cliffDuration,
    uint32 duration,
    uint32 interval,
    bool isRevocable
  ) external override onlyOwner {
    _setVestingSchedule(
      vestingLocation,
      cliffDuration,
      duration,
      interval,
      isRevocable
    );
  }

  function _setVestingSchedule(
    address vestingLocation,
    uint32 cliffDuration,
    uint32 duration,
    uint32 interval,
    bool isRevocable
  ) internal {
    // Check for a valid vesting schedule given (disallow absurd values to reject likely bad input).
    require(
      duration > 0 &&
        duration <= _TEN_YEARS_DAYS &&
        cliffDuration < duration &&
        interval >= 1,
      "invalid vesting schedule"
    );

    // Make sure the duration values are in harmony with interval (both should be an exact multiple of interval).
    require(
      duration % interval == 0 && cliffDuration % interval == 0,
      "invalid cliff/duration for interval"
    );

    // Create and populate a vesting schedule.
    _vestingSchedules[vestingLocation] = vestingSchedule(
      isRevocable,
      cliffDuration,
      duration,
      interval
    );

    // Emit the event.
    emit VestingScheduleCreated(
      vestingLocation,
      cliffDuration,
      duration,
      interval,
      isRevocable
    );
  }

  // =========================================================================
  // === Token grants (general-purpose)
  // === Methods to be used for administratively creating one-off token grants with vesting schedules.
  // =========================================================================

  /**
   * @dev Grants tokens to an account.
   *
   * @param beneficiary = Address to which tokens will be granted.
   * @param vestingAmount = The number of tokens subject to vesting.
   * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
   *   (start of day). The startDay may be given as a date in the future or in the past, going as far
   *   back as year 2000.
   * @param vestingLocation = Account where the vesting schedule is held (must already exist).
   */
  function _addGrant(
    address beneficiary,
    uint256 vestingAmount,
    uint32 startDay,
    address vestingLocation
  ) internal {
    // Make sure no prior grant is in effect.
    require(!_tokenGrants[beneficiary].isActive, "grant already exists");

    // Check for valid vestingAmount
    require(
      vestingAmount > 0 &&
        startDay >= _JAN_1_2000_DAYS &&
        startDay < _JAN_1_3000_DAYS,
      "invalid vesting params"
    );

    // Create and populate a token grant, referencing vesting schedule.
    _tokenGrants[beneficiary] = tokenGrant(
      true, // isActive
      false, // wasRevoked
      startDay,
      vestingAmount,
      vestingLocation, // The wallet address where the vesting schedule is kept.
      0 // claimedAmount
    );
    _allBeneficiaries.push(beneficiary);

    // Emit the event.
    emit VestingTokensGranted(
      beneficiary,
      vestingAmount,
      startDay,
      vestingLocation
    );
  }

  /**
   * @dev Grants tokens to an address, including a portion that will vest over time
   * according to a set vesting schedule. The overall duration and cliff duration of the grant must
   * be an even multiple of the vesting interval.
   *
   * @param beneficiary = Address to which tokens will be granted.
   * @param vestingAmount = The number of tokens subject to vesting.
   * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
   *   (start of day). The startDay may be given as a date in the future or in the past, going as far
   *   back as year 2000.
   * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
   * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
   * @param interval = Number of days between vesting increases.
   * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
   *   be revoked (i.e. tokens were purchased).
   */
  function addGrant(
    address beneficiary,
    uint256 vestingAmount,
    uint32 startDay,
    uint32 duration,
    uint32 cliffDuration,
    uint32 interval,
    bool isRevocable
  ) public override onlyOwner {
    // Make sure no prior vesting schedule has been set.
    require(!_tokenGrants[beneficiary].isActive, "grant already exists");

    // The vesting schedule is unique to this wallet and so will be stored here,
    _setVestingSchedule(
      beneficiary,
      cliffDuration,
      duration,
      interval,
      isRevocable
    );

    // Issue tokens to the beneficiary, using beneficiary's own vesting schedule.
    _addGrant(beneficiary, vestingAmount, startDay, beneficiary);
  }

  function addGrantWithScheduleAt(
    address beneficiary,
    uint256 vestingAmount,
    uint32 startDay,
    address vestingLocation
  ) external override onlyOwner {
    // Issue tokens to the beneficiary, using custom vestingLocation.
    _addGrant(beneficiary, vestingAmount, startDay, vestingLocation);
  }

  function addGrantFromToday(
    address beneficiary,
    uint256 vestingAmount,
    uint32 duration,
    uint32 cliffDuration,
    uint32 interval,
    bool isRevocable
  ) external override onlyOwner {
    addGrant(
      beneficiary,
      vestingAmount,
      today(),
      duration,
      cliffDuration,
      interval,
      isRevocable
    );
  }

  // =========================================================================
  // === Check vesting.
  // =========================================================================
  function today() public view virtual override returns (uint32 dayNumber) {
    return uint32(block.timestamp / _SECONDS_PER_DAY);
  }

  function _effectiveDay(uint32 onDayOrToday)
    internal
    view
    returns (uint32 dayNumber)
  {
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
  function _getNotVestedAmount(address grantHolder, uint32 onDayOrToday)
    internal
    view
    returns (uint256 amountNotVested)
  {
    tokenGrant storage grant = _tokenGrants[grantHolder];
    vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
    uint32 onDay = _effectiveDay(onDayOrToday);

    // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
    if (!grant.isActive || onDay < grant.startDay + vesting.cliffDuration) {
      // None are vested (all are not vested)
      return grant.amount;
    }
    // If after end of vesting, then the not vested amount is zero (all are vested).
    else if (onDay >= grant.startDay + vesting.duration) {
      // All are vested (none are not vested)
      return uint256(0);
    }
    // Otherwise a fractional amount is vested.
    else {
      // Compute the exact number of days vested.
      uint32 daysVested = onDay - grant.startDay;
      // Adjust result rounding down to take into consideration the interval.
      uint32 effectiveDaysVested = (daysVested / vesting.interval) *
        vesting.interval;

      // Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
      // Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
      // typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
      // bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
      // amounts many orders of magnitude greater than mere billions.
      uint256 vested = grant.amount.mul(effectiveDaysVested).div(
        vesting.duration
      );
      uint256 result = grant.amount.sub(vested);
      require(result <= grant.amount && vested <= grant.amount);

      return result;
    }
  }

  /**
   * @dev Computes the amount of funds in the given account which are available for use as of
   * the given day, i.e. the claimable amount.
   *
   * The math is: available amount = totalGrantAmount - notVestedAmount - claimedAmount.
   *
   * @param grantHolder = The account to check.
   * @param onDay = The day to check for, in days since the UNIX epoch.
   */
  function _getAvailableAmount(address grantHolder, uint32 onDay)
    internal
    view
    returns (uint256 amountAvailable)
  {
    tokenGrant storage grant = _tokenGrants[grantHolder];
    return
      _getAvailableAmountImpl(grant, _getNotVestedAmount(grantHolder, onDay));
  }

  function _getAvailableAmountImpl(
    tokenGrant storage grant,
    uint256 notVastedOnDay
  ) internal view returns (uint256 amountAvailable) {
    uint256 vested = grant.amount.sub(notVastedOnDay);
    if (vested < grant.claimedAmount) {
      // .sub below will fail, only possible when grant revoked
      require(vested == 0 && grant.wasRevoked);
      return 0;
    }

    uint256 result = vested.sub(grant.claimedAmount);
    require(
      result <= grant.amount &&
        grant.claimedAmount.add(result) <= grant.amount &&
        result <= vested &&
        vested <= grant.amount
    );

    return result;
  }

  /**
   * @dev returns all information about the grant's vesting as of the given day
   * for the given account. Only callable by the account holder or a contract owner.
   *
   * @param grantHolder = The address to do this for.
   * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
   *   the special value 0 to indicate today.
   * return = A tuple with the following values:
   *   amountVested = the amount that is already vested
   *   amountNotVested = the amount that is not yet vested (equal to vestingAmount - vestedAmount)
   *   amountOfGrant = the total amount of tokens subject to vesting.
   *   amountAvailable = the amount of funds in the given account which are available for use as of the given day
   *   amountClaimed = out of amountVested, the amount that has been already transferred to beneficiary
   *   vestStartDay = starting day of the grant (in days since the UNIX epoch).
   *   isActive = true if the vesting schedule is currently active.
   *   wasRevoked = true if the vesting schedule was revoked.
   */
  function getGrantInfo(address grantHolder, uint32 onDayOrToday)
    external
    view
    override
    returns (
      uint256 amountVested,
      uint256 amountNotVested,
      uint256 amountOfGrant,
      uint256 amountAvailable,
      uint256 amountClaimed,
      uint32 vestStartDay,
      bool isActive,
      bool wasRevoked
    )
  {
    tokenGrant storage grant = _tokenGrants[grantHolder];
    uint256 notVestedAmount = _getNotVestedAmount(grantHolder, onDayOrToday);

    return (
      grant.amount.sub(notVestedAmount),
      notVestedAmount,
      grant.amount,
      _getAvailableAmountImpl(grant, notVestedAmount),
      grant.claimedAmount,
      grant.startDay,
      grant.isActive,
      grant.wasRevoked
    );
  }

  function getScheduleAtInfo(address vestingLocation)
    public
    view
    override
    returns (
      bool isRevocable,
      uint32 vestDuration,
      uint32 cliffDuration,
      uint32 vestIntervalDays
    )
  {
    vestingSchedule storage vesting = _vestingSchedules[vestingLocation];

    return (
      vesting.isRevocable,
      vesting.duration,
      vesting.cliffDuration,
      vesting.interval
    );
  }

  function getScheduleInfo(address grantHolder)
    external
    view
    override
    returns (
      bool isRevocable,
      uint32 vestDuration,
      uint32 cliffDuration,
      uint32 vestIntervalDays
    )
  {
    tokenGrant storage grant = _tokenGrants[grantHolder];
    return getScheduleAtInfo(grant.vestingLocation);
  }

  // =========================================================================
  // === Grant revocation
  // =========================================================================

  /**
   * @dev If the account has a revocable grant, this forces the grant to end immediately.
   * After this function is called, getGrantInfo will return incomplete data
   * and there will be no possibility to claim non-claimed tokens
   *
   * @param grantHolder = Address to which tokens will be granted.
   */
  function revokeGrant(address grantHolder) external override onlyOwner {
    tokenGrant storage grant = _tokenGrants[grantHolder];
    vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];

    // Make sure a vesting schedule has previously been set.
    require(grant.isActive, "no active grant");
    // Make sure it's revocable.
    require(vesting.isRevocable, "irrevocable");

    // Kill the grant by updating wasRevoked and isActive.
    _tokenGrants[grantHolder].wasRevoked = true;
    _tokenGrants[grantHolder].isActive = false;

    // Emits the GrantRevoked event.
    emit GrantRevoked(grantHolder);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TokenVestingInterface {
  event VestingScheduleCreated(
    address indexed vestingLocation,
    uint32 cliffDuration,
    uint32 duration,
    uint32 interval,
    bool isRevocable
  );

  event VestingTokensGranted(
    address indexed beneficiary,
    uint256 vestingAmount,
    uint32 startDay,
    address vestingLocation
  );

  event VestingTokensClaimed(address indexed beneficiary, uint256 amount);

  event GrantRevoked(address indexed grantHolder);

  struct vestingSchedule {
    bool isRevocable; /* true if the vesting option is revocable (a gift), false if irrevocable (purchased) */
    uint32 cliffDuration; /* Duration of the cliff, with respect to the grant start day, in days. */
    uint32 duration; /* Duration of the vesting schedule, with respect to the grant start day, in days. */
    uint32 interval; /* Duration in days of the vesting interval. */
  }

  struct tokenGrant {
    bool isActive; /* true if this vesting entry is active and in-effect entry. */
    bool wasRevoked; /* true if this vesting schedule was revoked. */
    uint32 startDay; /* Start day of the grant, in days since the UNIX epoch (start of day). */
    uint256 amount; /* Total number of tokens that vest. */
    address vestingLocation; /* Address of wallet that is holding the vesting schedule. */
    uint256 claimedAmount; /* Out of vested amount, the amount that has been already transferred to beneficiary */
  }

  function token() public view virtual returns (IERC20);

  function kill(address payable beneficiary) external virtual;

  function withdrawTokens(address beneficiary, uint256 amount) external virtual;

  // =========================================================================
  // === Methods for claiming tokens.
  // =========================================================================

  function claimVestingTokens(address beneficiary) external virtual;

  function claimVestingTokensForAll() external virtual;

  // =========================================================================
  // === Methods for administratively creating a vesting schedule for an account.
  // =========================================================================

  function setVestingSchedule(
    address vestingLocation,
    uint32 cliffDuration,
    uint32 duration,
    uint32 interval,
    bool isRevocable
  ) external virtual;

  // =========================================================================
  // === Token grants (general-purpose)
  // === Methods to be used for administratively creating one-off token grants with vesting schedules.
  // =========================================================================

  function addGrant(
    address beneficiary,
    uint256 vestingAmount,
    uint32 startDay,
    uint32 duration,
    uint32 cliffDuration,
    uint32 interval,
    bool isRevocable
  ) public virtual;

  function addGrantWithScheduleAt(
    address beneficiary,
    uint256 vestingAmount,
    uint32 startDay,
    address vestingLocation
  ) external virtual;

  function addGrantFromToday(
    address beneficiary,
    uint256 vestingAmount,
    uint32 duration,
    uint32 cliffDuration,
    uint32 interval,
    bool isRevocable
  ) external virtual;

  // =========================================================================
  // === Check vesting.
  // =========================================================================

  function today() public view virtual returns (uint32 dayNumber);

  function getGrantInfo(address grantHolder, uint32 onDayOrToday)
    external
    view
    virtual
    returns (
      uint256 amountVested,
      uint256 amountNotVested,
      uint256 amountOfGrant,
      uint256 amountAvailable,
      uint256 amountClaimed,
      uint32 vestStartDay,
      bool isActive,
      bool wasRevoked
    );

  function getScheduleAtInfo(address vestingLocation)
    public
    view
    virtual
    returns (
      bool isRevocable,
      uint32 vestDuration,
      uint32 cliffDuration,
      uint32 vestIntervalDays
    );

  function getScheduleInfo(address grantHolder)
    external
    view
    virtual
    returns (
      bool isRevocable,
      uint32 vestDuration,
      uint32 cliffDuration,
      uint32 vestIntervalDays
    );

  // =========================================================================
  // === Grant revocation
  // =========================================================================

  function revokeGrant(address grantHolder) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}