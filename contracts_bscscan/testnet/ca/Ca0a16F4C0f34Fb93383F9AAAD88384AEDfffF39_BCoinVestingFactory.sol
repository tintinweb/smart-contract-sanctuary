// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BCoinVesting.sol";

/**
 * @dev PrivateSaleBCoinVesting will be blocked and release 10% each month.
 * Hence, the vestingDuration should be 10 months from the beginning.
 *
 */
contract PrivateSaleBCoinVesting is BCoinVesting {
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt
  ) BCoinVesting(_token, _owner, _vestingStartAt, 10) {}
}

/**
 * @dev TeamBCoinVesting will be blocked for 1 year,
 * then releaseed linearly each month during the next year.
 * Hence, the _vestingStartAt should delay 1 year
 * and the vestingDuration should be 12 months.
 *
 */
contract TeamBCoinVesting is BCoinVesting {
  //uint256 private SECONDS_PER_YEAR = 31536000;
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt
  ) BCoinVesting(_token, _owner, (_vestingStartAt + 3600), 12) {}
}

/**
 * @dev AdvisorBCoinVesting will be blocked for 1 year,
 * then releaseed linearly each month during the next year.
 * Hence, the _vestingStartAt should delay 1 year
 * and the vestingDuration should be 12 months.
 *
 */
contract AdvisorBCoinVesting is BCoinVesting {
  //uint256 private SECONDS_PER_YEAR = 31536000;
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt
  ) BCoinVesting(_token, _owner, (_vestingStartAt + 3600), 12) {}
}

/**
 * @dev DexLiquidityBCoinVesting will be blocked for 1 month,
 * then releaseed 5% each month during the next year.
 * Hence, the _vestingStartAt should delay 1 month
 * and the vestingDuration should be 20 months.
 *
 */
contract DexLiquidityBCoinVesting is BCoinVesting {
  //uint256 private SECONDS_PER_MONTH = 2628000;
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt
  ) BCoinVesting(_token, _owner, (_vestingStartAt + 300), 20) {}
}

/**
 * @dev ReserveBCoinVesting will be blocked for 1 year,
 * then releaseed linearly each month during the next 2 year.
 * Hence, the _vestingStartAt should delay 1 year
 * and the vestingDuration should be 24 months.
 *
 */
contract ReserveBCoinVesting is BCoinVesting {
  //uint256 private SECONDS_PER_YEAR = 31536000;
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt
  ) BCoinVesting(_token, _owner, (_vestingStartAt + 3600), 24) {}
}

/**
 * @dev BCoinVestingFactory is the main and is the only contract should be deployed.
 * Notice: remember to config the Token address and approriate startAtTimeStamp
 */
contract BCoinVestingFactory {
  // put the token address here
  // This should be included in the contract for transparency
  address public BCOIN_TOKEN_ADDRESS = 0x648a9CF8E95c73110D28E7e2329b2D0910Bd36B8;

  // put the startAtTimeStamp here
  // To test all contracts, change this timestamp to time in the past.
  uint256 public startAtTimeStamp = 1632380400;

  // address to track other information
  address public owner;
  address public privateSaleBCoinVesting;
  address public teamBCoinVesting;
  address public advisorBCoinVesting;
  address public dexLiquidityBCoinVesting;
  address public reserveBCoinVesting;

  constructor() {
    owner = msg.sender;

    PrivateSaleBCoinVesting _privateSaleBCoinVesting = new PrivateSaleBCoinVesting(
      BCOIN_TOKEN_ADDRESS,
      owner,
      startAtTimeStamp
    );
    privateSaleBCoinVesting = address(_privateSaleBCoinVesting);

    TeamBCoinVesting _teamBCoinVesting = new TeamBCoinVesting(BCOIN_TOKEN_ADDRESS, owner, startAtTimeStamp);
    teamBCoinVesting = address(_teamBCoinVesting);

    AdvisorBCoinVesting _advisorBCoinVesting = new AdvisorBCoinVesting(BCOIN_TOKEN_ADDRESS, owner, startAtTimeStamp);
    advisorBCoinVesting = address(_advisorBCoinVesting);

    DexLiquidityBCoinVesting _dexLiquidityBCoinVesting = new DexLiquidityBCoinVesting(
      BCOIN_TOKEN_ADDRESS,
      owner,
      startAtTimeStamp
    );
    dexLiquidityBCoinVesting = address(_dexLiquidityBCoinVesting);

    ReserveBCoinVesting _reserveBCoinVesting = new ReserveBCoinVesting(BCOIN_TOKEN_ADDRESS, owner, startAtTimeStamp);
    reserveBCoinVesting = address(_reserveBCoinVesting);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard. Does not include
 * the optional functions; to access them see {BEP20Detailed}.
 */
interface IBEP20 {
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
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
abstract contract BEPContext {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor() {}

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract BEPOwnable is BEPContext {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract BEPPausable is BEPOwnable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20Mintable}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is BEPContext, IBEP20, BEPPausable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  /**
   * @dev See {IBEP20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IBEP20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IBEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IBEP20-allowance}.
   */
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IBEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IBEP20-transferFrom}.
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override whenNotPaused returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IBEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IBEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
    );
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
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
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
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
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
    _approve(
      account,
      _msgSender(),
      _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
    );
  }
}

/**
 * @dev Optional functions from the BEP20 standard.
 */
abstract contract BEP20Detailed {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
   * these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IBEP20-balanceOf} and {IBEP20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

abstract contract BCoinVesting is BEPOwnable {
  using SafeMath for uint256;

  // Address of BCOIN Token.
  IBEP20 public bcoinToken;

  // Starting timestamp of vesting
  // Will be used as a starting point for all dates calculations.
  // The first vesting will happen one month after this timestamp
  uint256 public vestingStartAt;

  // Vesting duration in seconds
  uint256 public vestingDuration;

  // Vesting cliff is one month
  // 365*(60*60*24) / 12
  uint256 internal constant SECONDS_PER_MONTH = 300;

  // Percent of vested token which can be withraw per month;
  uint256 internal percent_unlease_per_month;

  // Beneficiary contains details of each beneficiary/investor
  struct Beneficiary {
    uint256 initialBalance;
    uint256 monthsClaimed;
    uint256 totalClaimed;
  }

  // beneficiaries tracks all beneficiary and store data in storage
  mapping(address => Beneficiary) public beneficiaries;

  // Event raised on each successful withdraw.
  event Claim(address beneficiary, uint256 amount, uint256 timestamp);

  // Event raised on each desposit
  event Deposit(address beneficiary, uint256 initialBalance, uint256 timestamp);

  // @dev constructor creates the vesting contract
  // @param _token Address of BCOIN token
  // @param _owner Address of owner of this contract, a.k.a the CEO
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _vestingDuration the duration since _vestingStartAt until the vesting ends, in months.
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt,
    uint256 _vestingDuration
  ) {
    require(_token != address(0), "zero-address");
    require(_owner != address(0), "zero-address");
    bcoinToken = IBEP20(_token);
    _transferOwnership(_owner);
    vestingStartAt = _vestingStartAt;
    vestingDuration = _vestingDuration;
  }

  // @dev addBeneficiary registers a beneficiary and deposit a
  // corresponded amount of token for this beneficiary
  //
  // The owner can call this function many times to update
  // (additionally desposit) the amount of token for this beneficiary
  // @param _beneficiary Address of the beneficiary
  // @param _amount Amount of token belongs to this beneficiary
  function addBeneficiary(address _beneficiary, uint256 _amount) public onlyOwner {
    //require(block.timestamp < vestingStartAt, "not-update-after-vesting-started");
    require(_beneficiary != address(0), "zero-address");
    // Based on ERC20 standard, to transfer funds to this contract,
    // the owner must first call approve() to allow to transfer token to this contract.
    require(bcoinToken.transferFrom(_msgSender(), address(this), _amount), "cannot-transfer-token-to-this-contract");

    // update storage data
    Beneficiary storage bf = beneficiaries[_beneficiary];
    bf.initialBalance = bf.initialBalance.add(_amount);

    emit Deposit(_beneficiary, bf.initialBalance, block.timestamp);
  }

  // @dev Claim withraws the vested token and sends beneficiary
  // Only the owner or the beneficiary can call this function
  // @param _beneficiary Address of the beneficiary
  function claimVestedToken(address _beneficiary) public {
    require(isOwner() || (_msgSender() == _beneficiary), "must-be-onwer-or-beneficiary");
    uint256 monthsVestable;
    uint256 tokenVestable;
    (monthsVestable, tokenVestable) = calculateClaimable(_beneficiary);
    require(tokenVestable > 0, "nothing-to-be-vested");

    require(bcoinToken.transfer(_beneficiary, tokenVestable), "fail-to-transfer-token");

    // update data in blockchain storage
    Beneficiary storage bf = beneficiaries[_beneficiary];
    bf.monthsClaimed = bf.monthsClaimed.add(monthsVestable);
    bf.totalClaimed = bf.totalClaimed.add(tokenVestable);

    emit Claim(_beneficiary, tokenVestable, block.timestamp);
  }

  // calculateWithrawable calculates the claimable token of the beneficiary
  // claimable token each month is rounded if it is a decimal number
  // So the rest of the token will be claimed on the last month (the duration is over)
  // @param _beneficiary Address of the beneficiary
  function calculateClaimable(address _beneficiary) private view returns (uint256, uint256) {
    uint256 _now = block.timestamp;
    if (_now < vestingStartAt) {
      return (0, 0);
    }

    uint256 elapsedTime = _now.sub(vestingStartAt);
    uint256 elapsedMonths = elapsedTime.div(SECONDS_PER_MONTH);

    if (elapsedMonths < 1) {
      return (0, 0);
    }

    Beneficiary storage bf = beneficiaries[_beneficiary];
    require(bf.initialBalance > 0, "beneficiary-not-found");

    // If over vesting duration, all tokens vested
    if (elapsedMonths >= vestingDuration) {
      uint256 remaining = bf.initialBalance.sub(bf.totalClaimed);
      return (vestingDuration, remaining);
    } else {
      uint256 monthsVestable = elapsedMonths.sub(bf.monthsClaimed);
      uint256 tokenVestedPerMonth = bf.initialBalance.div(vestingDuration);
      uint256 tokenVestable = monthsVestable.mul(tokenVestedPerMonth);
      return (monthsVestable, tokenVestable);
    }
  }

  // view function to check status of a beneficiary
  function getBeneficiary(address _beneficiary)
    public
    view
    returns (
      uint256 initialBalance,
      uint256 monthsClaimed,
      uint256 totalClaimed
    )
  {
    Beneficiary storage bf = beneficiaries[_beneficiary];
    require(bf.initialBalance > 0, "beneficiary-not-found");

    return (bf.initialBalance, bf.monthsClaimed, bf.totalClaimed);
  }
}

