/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/
// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/upgrades-core/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IPowerPokeStaking.sol

pragma solidity ^0.6.12;

interface IPowerPokeStaking {
  enum UserStatus { UNAUTHORIZED, HDH, MEMBER }

  /*** User Interface ***/
  function createDeposit(uint256 userId_, uint256 amount_) external;

  function executeDeposit(uint256 userId_) external;

  function createWithdrawal(uint256 userId_, uint256 amount_) external;

  function executeWithdrawal(uint256 userId_, address to_) external;

  function createUser(
    address adminKey_,
    address reporterKey_,
    uint256 depositAmount
  ) external;

  function updateUser(
    uint256 userId,
    address adminKey_,
    address reporterKey_
  ) external;

  /*** Owner Interface ***/
  function setSlasher(address slasher) external;

  function setSlashingPct(uint256 slasherRewardPct, uint256 reservoirRewardPct) external;

  function setTimeouts(uint256 depositTimeout_, uint256 withdrawalTimeout_) external;

  function pause() external;

  function unpause() external;

  /*** PowerOracle Contract Interface ***/
  function slashHDH(uint256 slasherId_, uint256 times_) external;

  /*** Permissionless Interface ***/
  function setHDH(uint256 candidateId_) external;

  /*** Viewers ***/
  function getHDHID() external view returns (uint256);

  function getHighestDeposit() external view returns (uint256);

  function getDepositOf(uint256 userId) external view returns (uint256);

  function getPendingDepositOf(uint256 userId_) external view returns (uint256 balance, uint256 timeout);

  function getPendingWithdrawalOf(uint256 userId_) external view returns (uint256 balance, uint256 timeout);

  function getSlashAmount(uint256 slasheeId_, uint256 times_)
    external
    view
    returns (
      uint256 slasherReward,
      uint256 reservoirReward,
      uint256 totalSlash
    );

  function getUserStatus(
    uint256 userId_,
    address reporterKey_,
    uint256 minDeposit_
  ) external view returns (UserStatus);

  function authorizeHDH(uint256 userId_, address reporterKey_) external view;

  function authorizeNonHDH(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) external view;

  function authorizeMember(
    uint256 userId_,
    address reporterKey_,
    uint256 minDeposit_
  ) external view;

  function requireValidAdminKey(uint256 userId_, address adminKey_) external view;

  function requireValidAdminOrPokerKey(uint256 userId_, address adminOrPokerKey_) external view;

  function getLastDepositChange(uint256 userId_) external view returns (uint256);
}

// File: contracts/utils/PowerOwnable.sol

// A modified version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/access/Ownable.sol
// with no GSN Context support and _transferOwnership internal method

pragma solidity ^0.6.0;

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
contract PowerOwnable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
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
    require(_owner == msg.sender, "NOT_THE_OWNER");
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
    require(newOwner != address(0), "NEW_OWNER_IS_NULL");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "NEW_OWNER_IS_NULL");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/utils/PowerPausable.sol

// A modified version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/utils/Pausable.sol
// with no GSN Context support and no construct

pragma solidity ^0.6.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PowerPausable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "PAUSED");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(_paused, "NOT_PAUSED");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

// File: contracts/PowerPokeStakingStorageV1.sol

pragma solidity ^0.6.12;

contract PowerPokeStakingStorageV1 {
  struct User {
    address adminKey;
    address pokerKey;
    uint256 deposit;
    uint256 pendingDeposit;
    uint256 pendingDepositTimeout;
    uint256 pendingWithdrawal;
    uint256 pendingWithdrawalTimeout;
  }

  /// @notice The deposit timeout in seconds
  uint256 public depositTimeout;

  /// @notice The withdrawal timeout in seconds
  uint256 public withdrawalTimeout;

  /// @notice The reservoir which holds CVP tokens
  address public reservoir;

  /// @notice The slasher address (PowerPoke)
  address public slasher;

  /// @notice The total amount of all deposits
  uint256 public totalDeposit;

  /// @notice The share of a slasher in slashed deposit per one outdated asset (1 eth == 1%)
  uint256 public slasherSlashingRewardPct;

  /// @notice The share of the protocol(reservoir) in slashed deposit per one outdated asset (1 eth == 1%)
  uint256 public protocolSlashingRewardPct;

  /// @notice The incremented user ID counter. Is updated only within createUser function call
  uint256 public userIdCounter;

  /// @dev The highest deposit. Usually of the current reporterId. Is safe to be outdated.
  uint256 internal _highestDeposit;

  /// @dev The current highest deposit holder ID.
  uint256 internal _hdhId;

  /// @notice User details by it's ID
  mapping(uint256 => User) public users;

  /// @dev Last deposit change timestamp by user ID
  mapping(uint256 => uint256) internal _lastDepositChange;
}

// File: contracts/PowerPokeStaking.sol

pragma solidity ^0.6.12;








contract PowerPokeStaking is IPowerPokeStaking, PowerOwnable, Initializable, PowerPausable, PowerPokeStakingStorageV1 {
  using SafeMath for uint256;

  uint256 public constant HUNDRED_PCT = 100 ether;

  /// @notice The event emitted when a new user is created
  event CreateUser(uint256 indexed userId, address indexed adminKey, address indexed pokerKey, uint256 initialDeposit);

  /// @notice The event emitted when an existing user is updated
  event UpdateUser(uint256 indexed userId, address indexed adminKey, address indexed pokerKey);

  /// @notice The event emitted when the user creates pending deposit
  event CreateDeposit(
    uint256 indexed userId,
    address indexed depositor,
    uint256 pendingTimeout,
    uint256 amount,
    uint256 pendingDepositAfter
  );

  /// @notice The event emitted when the user transfers his deposit from pending to the active
  event ExecuteDeposit(uint256 indexed userId, uint256 pendingTimeout, uint256 amount, uint256 depositAfter);

  /// @notice The event emitted when the user creates pending deposit
  event CreateWithdrawal(
    uint256 indexed userId,
    uint256 pendingTimeout,
    uint256 amount,
    uint256 pendingWithdrawalAfter,
    uint256 depositAfter
  );

  /// @notice The event emitted when a valid admin key withdraws funds from
  event ExecuteWithdrawal(uint256 indexed userId, address indexed to, uint256 pendingTimeout, uint256 amount);

  /// @notice The event emitted when the owner sets new slashing percent values, where 1ether == 1%
  event SetSlashingPct(uint256 slasherSlashingRewardPct, uint256 protocolSlashingRewardPct);

  /// @notice The event emitted when the owner sets new deposit and withdrawal timeouts
  event SetTimeouts(uint256 depositTimeout, uint256 withdrawalTimeout);

  /// @notice The event emitted when the owner sets a new PowerOracle linked contract
  event SetSlasher(address powerOracle);

  /// @notice The event emitted when an arbitrary user fixes an outdated reporter userId record
  event SetReporter(uint256 indexed reporterId, address indexed msgSender);

  /// @notice The event emitted when the PowerOracle contract requests to slash a user with the given ID
  event Slash(uint256 indexed slasherId, uint256 indexed reporterId, uint256 slasherReward, uint256 reservoirReward);

  /// @notice The event emitted when the existing reporter is replaced with a new one due some reason
  event ReporterChange(
    uint256 indexed prevId,
    uint256 indexed nextId,
    uint256 highestDepositPrev,
    uint256 actualDepositPrev,
    uint256 actualDepositNext
  );

  /// @notice CVP token address
  IERC20 public immutable CVP_TOKEN;

  constructor(address cvpToken_) public {
    require(cvpToken_ != address(0), "CVP_ADDR_IS_0");

    CVP_TOKEN = IERC20(cvpToken_);
  }

  function initialize(
    address owner_,
    address reservoir_,
    address slasher_,
    uint256 slasherSlashingRewardPct_,
    uint256 reservoirSlashingRewardPct_,
    uint256 depositTimeout_,
    uint256 withdrawTimeout_
  ) external initializer {
    require(depositTimeout_ > 0, "DEPOSIT_TIMEOUT_IS_0");
    require(withdrawTimeout_ > 0, "WITHDRAW_TIMEOUT_IS_0");

    _transferOwnership(owner_);
    reservoir = reservoir_;
    slasher = slasher_;
    slasherSlashingRewardPct = slasherSlashingRewardPct_;
    protocolSlashingRewardPct = reservoirSlashingRewardPct_;
    depositTimeout = depositTimeout_;
    withdrawalTimeout = withdrawTimeout_;
  }

  /*** User Interface ***/

  /**
   * @notice An arbitrary user deposits CVP stake to the contract for the given user ID
   * @param userId_ The user ID to make deposit for
   * @param amount_ The amount in CVP tokens to deposit
   */
  function createDeposit(uint256 userId_, uint256 amount_) external override whenNotPaused {
    require(amount_ > 0, "MISSING_AMOUNT");

    User storage user = users[userId_];

    require(user.adminKey != address(0), "INVALID_USER");

    _createDeposit(userId_, amount_);
  }

  function _createDeposit(uint256 userId_, uint256 amount_) internal {
    User storage user = users[userId_];

    uint256 pendingDepositAfter = user.pendingDeposit.add(amount_);
    uint256 timeout = block.timestamp.add(depositTimeout);

    user.pendingDeposit = pendingDepositAfter;
    user.pendingDepositTimeout = timeout;

    emit CreateDeposit(userId_, msg.sender, timeout, amount_, pendingDepositAfter);
    CVP_TOKEN.transferFrom(msg.sender, address(this), amount_);
  }

  function executeDeposit(uint256 userId_) external override {
    User storage user = users[userId_];
    uint256 amount = user.pendingDeposit;
    uint256 pendingDepositTimeout = user.pendingDepositTimeout;

    // check
    require(user.adminKey == msg.sender, "ONLY_ADMIN_ALLOWED");
    require(amount > 0, "NO_PENDING_DEPOSIT");
    require(block.timestamp >= pendingDepositTimeout, "TIMEOUT_NOT_PASSED");

    // increment deposit
    uint256 depositAfter = user.deposit.add(amount);
    user.deposit = depositAfter;
    totalDeposit = totalDeposit.add(amount);

    // reset pending deposit
    user.pendingDeposit = 0;
    user.pendingDepositTimeout = 0;

    _lastDepositChange[userId_] = block.timestamp;

    _trySetHighestDepositHolder(userId_, depositAfter);

    emit ExecuteDeposit(userId_, pendingDepositTimeout, amount, depositAfter);
  }

  function _trySetHighestDepositHolder(uint256 candidateId_, uint256 candidateDepositAfter_) internal {
    uint256 prevHdhID = _hdhId;
    uint256 prevDeposit = users[prevHdhID].deposit;

    if (candidateDepositAfter_ > prevDeposit && prevHdhID != candidateId_) {
      emit ReporterChange(prevHdhID, candidateId_, _highestDeposit, users[prevHdhID].deposit, candidateDepositAfter_);

      _highestDeposit = candidateDepositAfter_;
      _hdhId = candidateId_;
    }
  }

  /**
   * @notice A valid users admin key withdraws the deposited stake form the contract
   * @param userId_ The user ID to withdraw deposit from
   * @param amount_ The amount in CVP tokens to withdraw
   */
  function createWithdrawal(uint256 userId_, uint256 amount_) external override {
    require(amount_ > 0, "MISSING_AMOUNT");

    User storage user = users[userId_];
    require(msg.sender == user.adminKey, "ONLY_ADMIN_ALLOWED");

    // decrement deposit
    uint256 depositBefore = user.deposit;
    require(amount_ <= depositBefore, "AMOUNT_EXCEEDS_DEPOSIT");

    uint256 depositAfter = depositBefore - amount_;
    user.deposit = depositAfter;
    totalDeposit = totalDeposit.sub(amount_);

    // increment pending withdrawal
    uint256 pendingWithdrawalAfter = user.pendingWithdrawal.add(amount_);
    uint256 timeout = block.timestamp.add(withdrawalTimeout);
    user.pendingWithdrawal = pendingWithdrawalAfter;
    user.pendingWithdrawalTimeout = timeout;

    _lastDepositChange[userId_] = block.timestamp;

    emit CreateWithdrawal(userId_, timeout, amount_, pendingWithdrawalAfter, depositAfter);
  }

  function executeWithdrawal(uint256 userId_, address to_) external override {
    require(to_ != address(0), "CANT_WITHDRAW_TO_0");

    User storage user = users[userId_];

    uint256 pendingWithdrawalTimeout = user.pendingWithdrawalTimeout;
    uint256 amount = user.pendingWithdrawal;

    require(msg.sender == user.adminKey, "ONLY_ADMIN_ALLOWED");
    require(amount > 0, "NO_PENDING_WITHDRAWAL");
    require(block.timestamp >= pendingWithdrawalTimeout, "TIMEOUT_NOT_PASSED");

    user.pendingWithdrawal = 0;
    user.pendingWithdrawalTimeout = 0;

    emit ExecuteWithdrawal(userId_, to_, pendingWithdrawalTimeout, amount);
    CVP_TOKEN.transfer(to_, amount);
  }

  /**
   * @notice Creates a new user ID and stores the given keys
   * @param adminKey_ The admin key for the new user
   * @param pokerKey_ The poker key for the new user
   * @param initialDeposit_ The initial deposit to be transferred to this contract
   */
  function createUser(
    address adminKey_,
    address pokerKey_,
    uint256 initialDeposit_
  ) external override whenNotPaused {
    uint256 userId = ++userIdCounter;

    users[userId] = User(adminKey_, pokerKey_, 0, 0, 0, 0, 0);

    emit CreateUser(userId, adminKey_, pokerKey_, initialDeposit_);

    if (initialDeposit_ > 0) {
      _createDeposit(userId, initialDeposit_);
    }
  }

  /**
   * @notice Updates an existing user, only the current adminKey is eligible calling this method.
   * @param adminKey_ The new admin key for the user
   * @param pokerKey_ The new poker key for the user
   */
  function updateUser(
    uint256 userId_,
    address adminKey_,
    address pokerKey_
  ) external override {
    User storage user = users[userId_];
    require(msg.sender == user.adminKey, "ONLY_ADMIN_ALLOWED");

    if (adminKey_ != user.adminKey) {
      user.adminKey = adminKey_;
    }
    if (pokerKey_ != user.pokerKey) {
      user.pokerKey = pokerKey_;
    }

    emit UpdateUser(userId_, adminKey_, pokerKey_);
  }

  /*** SLASHER INTERFACE ***/

  /**
   * @notice Slashes the current reporter if it did not make poke() call during the given report interval
   * @param slasherId_ The slasher ID
   * @param times_ The multiplier for a single slashing percent
   */
  function slashHDH(uint256 slasherId_, uint256 times_) external virtual override {
    require(msg.sender == slasher, "ONLY_SLASHER_ALLOWED");

    uint256 hdhId = _hdhId;
    uint256 hdhDeposit = users[hdhId].deposit;

    (uint256 slasherReward, uint256 reservoirReward, ) = getSlashAmount(hdhId, times_);

    uint256 amount = slasherReward.add(reservoirReward);
    require(hdhDeposit >= amount, "INSUFFICIENT_HDH_DEPOSIT");

    // users[reporterId].deposit = reporterDeposit - slasherReward - reservoirReward;
    users[hdhId].deposit = hdhDeposit.sub(amount);

    // totalDeposit = totalDeposit - reservoirReward; (slasherReward is kept on the contract)
    totalDeposit = totalDeposit.sub(reservoirReward);

    if (slasherReward > 0) {
      // uint256 slasherDepositAfter = users[slasherId_].deposit + slasherReward
      uint256 slasherDepositAfter = users[slasherId_].deposit.add(slasherReward);
      users[slasherId_].deposit = slasherDepositAfter;
      _trySetHighestDepositHolder(slasherId_, slasherDepositAfter);
    }

    if (reservoirReward > 0) {
      CVP_TOKEN.transfer(reservoir, reservoirReward);
    }

    emit Slash(slasherId_, hdhId, slasherReward, reservoirReward);
  }

  /*** OWNER INTERFACE ***/

  /**
   * @notice The owner sets a new slasher address
   * @param slasher_ The slasher address to set
   */
  function setSlasher(address slasher_) external override onlyOwner {
    slasher = slasher_;
    emit SetSlasher(slasher_);
  }

  /**
   * @notice The owner sets the new slashing percent values
   * @param slasherSlashingRewardPct_ The slasher share will be accrued on the slasher's deposit
   * @param protocolSlashingRewardPct_ The protocol share will immediately be transferred to reservoir
   */
  function setSlashingPct(uint256 slasherSlashingRewardPct_, uint256 protocolSlashingRewardPct_)
    external
    override
    onlyOwner
  {
    require(slasherSlashingRewardPct_.add(protocolSlashingRewardPct_) <= HUNDRED_PCT, "INVALID_SUM");

    slasherSlashingRewardPct = slasherSlashingRewardPct_;
    protocolSlashingRewardPct = protocolSlashingRewardPct_;
    emit SetSlashingPct(slasherSlashingRewardPct_, protocolSlashingRewardPct_);
  }

  function setTimeouts(uint256 depositTimeout_, uint256 withdrawalTimeout_) external override onlyOwner {
    depositTimeout = depositTimeout_;
    withdrawalTimeout = withdrawalTimeout_;
    emit SetTimeouts(depositTimeout_, withdrawalTimeout_);
  }

  /**
   * @notice The owner pauses poke*-operations
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice The owner unpauses poke*-operations
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /*** PERMISSIONLESS INTERFACE ***/

  /**
   * @notice Set a given address as a reporter if his deposit is higher than the current highestDeposit
   * @param candidateId_ Te candidate address to try
   */
  function setHDH(uint256 candidateId_) external override {
    uint256 candidateDeposit = users[candidateId_].deposit;
    uint256 prevHdhId = _hdhId;
    uint256 currentReporterDeposit = users[prevHdhId].deposit;

    require(candidateDeposit > currentReporterDeposit, "INSUFFICIENT_CANDIDATE_DEPOSIT");

    emit ReporterChange(prevHdhId, candidateId_, _highestDeposit, currentReporterDeposit, candidateDeposit);
    emit SetReporter(candidateId_, msg.sender);

    _highestDeposit = candidateDeposit;
    _hdhId = candidateId_;
  }

  /*** VIEWERS ***/

  function getHDHID() external view override returns (uint256) {
    return _hdhId;
  }

  function getHighestDeposit() external view override returns (uint256) {
    return _highestDeposit;
  }

  function getDepositOf(uint256 userId_) external view override returns (uint256) {
    return users[userId_].deposit;
  }

  function getPendingDepositOf(uint256 userId_) external view override returns (uint256 balance, uint256 timeout) {
    return (users[userId_].pendingDeposit, users[userId_].pendingDepositTimeout);
  }

  function getPendingWithdrawalOf(uint256 userId_) external view override returns (uint256 balance, uint256 timeout) {
    return (users[userId_].pendingWithdrawal, users[userId_].pendingWithdrawalTimeout);
  }

  function getSlashAmount(uint256 slasheeId_, uint256 times_)
    public
    view
    override
    returns (
      uint256 slasherReward,
      uint256 reservoirReward,
      uint256 totalSlash
    )
  {
    uint256 product = times_.mul(users[slasheeId_].deposit);
    // slasherReward = times_ * reporterDeposit * slasherRewardPct / HUNDRED_PCT;
    slasherReward = product.mul(slasherSlashingRewardPct) / HUNDRED_PCT;
    // reservoirReward = times_ * reporterDeposit * reservoirSlashingRewardPct / HUNDRED_PCT;
    reservoirReward = product.mul(protocolSlashingRewardPct) / HUNDRED_PCT;
    // totalSlash = slasherReward + reservoirReward
    totalSlash = slasherReward.add(reservoirReward);
  }

  function getUserStatus(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) external view override returns (UserStatus) {
    if (userId_ == _hdhId && users[userId_].pokerKey == pokerKey_) {
      return UserStatus.HDH;
    }
    if (users[userId_].deposit >= minDeposit_ && users[userId_].pokerKey == pokerKey_) {
      return UserStatus.MEMBER;
    }
    return UserStatus.UNAUTHORIZED;
  }

  function authorizeHDH(uint256 userId_, address pokerKey_) external view override {
    require(userId_ == _hdhId, "NOT_HDH");
    require(users[userId_].pokerKey == pokerKey_, "INVALID_POKER_KEY");
  }

  function authorizeNonHDH(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) external view override {
    require(userId_ != _hdhId, "IS_HDH");
    authorizeMember(userId_, pokerKey_, minDeposit_);
  }

  function authorizeMember(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) public view override {
    require(users[userId_].deposit >= minDeposit_, "INSUFFICIENT_DEPOSIT");
    require(users[userId_].pokerKey == pokerKey_, "INVALID_POKER_KEY");
  }

  function requireValidAdminKey(uint256 userId_, address adminKey_) external view override {
    require(users[userId_].adminKey == adminKey_, "INVALID_AMIN_KEY");
  }

  function requireValidAdminOrPokerKey(uint256 userId_, address adminOrPokerKey_) external view override {
    require(
      users[userId_].adminKey == adminOrPokerKey_ || users[userId_].pokerKey == adminOrPokerKey_,
      "INVALID_AMIN_OR_POKER_KEY"
    );
  }

  function getLastDepositChange(uint256 userId_) external view override returns (uint256) {
    return _lastDepositChange[userId_];
  }
}