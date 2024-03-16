/**
 *Submitted for verification at moonriver.moonscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File contracts/interfaces/ICollateralSystem.sol

pragma solidity >=0.6.12 <0.9.0;

interface ICollateralSystem {
    function getUserLinaCollateralBreakdown(address _user) external view returns (uint256 staked, uint256 locked);

    function IsSatisfyTargetRatio(address _user) external view returns (bool);

    function GetUserTotalCollateralInUsd(address _user) external view returns (uint256 rTotal);

    function MaxRedeemableInUsd(address _user) external view returns (uint256);

    function getFreeCollateralInUsd(address user) external view returns (uint256);

    function moveCollateral(
        address fromUser,
        address toUser,
        bytes32 currency,
        uint256 amount
    ) external;

    function collateralFromUnlockReward(
        address user,
        address rewarder,
        bytes32 currency,
        uint256 amount
    ) external;
}

// File contracts/interfaces/IRewardLocker.sol

pragma solidity >=0.6.12 <0.9.0;

interface IRewardLocker {
    function balanceOf(address user) external view returns (uint256);

    function totalLockedAmount() external view returns (uint256);

    function addReward(
        address user,
        uint256 amount,
        uint256 unlockTime
    ) external;

    function moveReward(
        address from,
        address recipient,
        uint256 amount,
        uint256[] calldata rewardEntryIds
    ) external;

    function moveRewardProRata(
        address from,
        address recipient1,
        uint256 amount1,
        address recipient2,
        uint256 amount2,
        uint256[] calldata rewardEntryIds
    ) external;
}

// File contracts/RewardLocker.sol

pragma solidity =0.8.9;

contract RewardLocker is IRewardLocker, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event RewardEntryAdded(uint256 entryId, address user, uint256 amount, uint256 unlockTime);
    event RewardEntryRemoved(uint256 entryId);
    event RewardAmountChanged(uint256 entryId, uint256 oldAmount, uint256 newAmount);
    event RewardEntryUnlocked(uint256 entryId, address user, uint256 amount);

    /**
     * @dev The struct used to store reward data. Address is deliberately left out and put in the
     * mapping key of `rewardEntries` to minimize struct size. Struct fields are padded to 256 bits
     * to save storage space, and thus gas fees.
     */
    struct RewardEntry {
        uint216 amount;
        uint40 unlockTime;
    }
    struct MoveEntryParams {
        address from;
        address recipient1;
        uint256 amount1;
        address recipient2;
        uint256 amount2;
        uint256 rewardEntryId;
        uint256 amount1Left;
        uint256 amount2Left;
    }

    uint256 public lastRewardEntryId;
    mapping(uint256 => mapping(address => RewardEntry)) public rewardEntries;
    mapping(address => uint256) public lockedAmountByAddresses;
    uint256 public override totalLockedAmount;

    address public linaTokenAddr;
    IAccessControlUpgradeable public accessCtrl;
    address public collateralSystemAddr;
    address public rewarderAddress;

    bytes32 private constant ROLE_LOCK_REWARD = "LOCK_REWARD";
    bytes32 private constant ROLE_MOVE_REWARD = "MOVE_REWARD";

    modifier onlyLockRewardRole() {
        require(accessCtrl.hasRole(ROLE_LOCK_REWARD, msg.sender), "RewardLocker: not LOCK_REWARD role");
        _;
    }

    modifier onlyMoveRewardRole() {
        require(accessCtrl.hasRole(ROLE_MOVE_REWARD, msg.sender), "RewardLocker: not MOVE_REWARD role");
        _;
    }

    function balanceOf(address user) external view override returns (uint256) {
        return lockedAmountByAddresses[user];
    }

    function __RewardLocker_init(address _linaTokenAddr, IAccessControlUpgradeable _accessCtrl) public initializer {
        __Ownable_init();

        require(_linaTokenAddr != address(0), "RewardLocker: zero address");
        require(address(_accessCtrl) != address(0), "RewardLocker: zero address");

        linaTokenAddr = _linaTokenAddr;
        accessCtrl = _accessCtrl;
    }

    function addReward(
        address user,
        uint256 amount,
        uint256 unlockTime
    ) external override onlyLockRewardRole {
        _addReward(user, amount, unlockTime);
    }

    /**
     * @dev A temporary function for migrating reward entries in bulk from the old contract.
     * To be removed via a contract upgrade after migration.
     */
    function migrateRewards(
        address[] calldata users,
        uint256[] calldata amounts,
        uint256[] calldata unlockTimes
    ) external onlyOwner {
        require(users.length > 0, "RewardLocker: empty array");
        require(users.length == amounts.length && amounts.length == unlockTimes.length, "RewardLocker: length mismatch");

        for (uint256 ind = 0; ind < users.length; ind++) {
            _addReward(users[ind], amounts[ind], unlockTimes[ind]);
        }
    }

    function moveReward(
        address from,
        address recipient,
        uint256 amount,
        uint256[] calldata rewardEntryIds
    ) external override onlyMoveRewardRole {
        _moveRewardProRata(from, recipient, amount, address(0), 0, rewardEntryIds);
    }

    function moveRewardProRata(
        address from,
        address recipient1,
        uint256 amount1,
        address recipient2,
        uint256 amount2,
        uint256[] calldata rewardEntryIds
    ) external override onlyMoveRewardRole {
        _moveRewardProRata(from, recipient1, amount1, recipient2, amount2, rewardEntryIds);
    }

    function updateCollateralSystemAddress(address _collateralSystemAddr) external onlyOwner {
        require(_collateralSystemAddr != address(0), "RewardLocker: Collateral system address must not be 0");
        collateralSystemAddr = _collateralSystemAddr;
    }

    function updateRewarderAddress(address _rewarderAddress) external onlyOwner {
        require(_rewarderAddress != address(0), "RewardLocker: Rewarder address must not be 0");
        rewarderAddress = _rewarderAddress;
    }

    function unlockReward(address user, uint256 rewardEntryId) external {
        _unlockReward(user, rewardEntryId);
    }

    function unlockRewards(address[] calldata users, uint256[] calldata rewardEntryIds) external {
        require(users.length == rewardEntryIds.length, "RewardLocker: array length mismatch");

        for (uint256 ind = 0; ind < users.length; ind++) {
            _unlockReward(users[ind], rewardEntryIds[ind]);
        }
    }

    function _addReward(
        address user,
        uint256 amount,
        uint256 unlockTime
    ) private {
        require(amount > 0, "RewardLocker: zero amount");

        uint216 trimmedAmount = uint216(amount);
        uint40 trimmedUnlockTime = uint40(unlockTime);
        require(uint256(trimmedAmount) == amount, "RewardLocker: reward amount overflow");
        require(uint256(trimmedUnlockTime) == unlockTime, "RewardLocker: unlock time overflow");

        lastRewardEntryId++;

        rewardEntries[lastRewardEntryId][user] = RewardEntry({amount: trimmedAmount, unlockTime: trimmedUnlockTime});
        lockedAmountByAddresses[user] = lockedAmountByAddresses[user].add(amount);
        totalLockedAmount = totalLockedAmount.add(amount);

        emit RewardEntryAdded(lastRewardEntryId, user, amount, unlockTime);
    }

    function _unlockReward(address user, uint256 rewardEntryId) private {
        require(rewarderAddress != address(0), "RewardLocker: Rewarder address not set");
        require(collateralSystemAddr != address(0), "RewardLocker: Collateral system address not set");

        RewardEntry memory rewardEntry = rewardEntries[rewardEntryId][user];
        require(rewardEntry.amount > 0, "RewardLocker: Reward entry amount is 0, no reward to unlock");
        require(block.timestamp >= rewardEntry.unlockTime, "RewardLocker: Unlock time not reached");

        if (rewarderAddress == address(this)) {
            IERC20Upgradeable(linaTokenAddr).approve(collateralSystemAddr, rewardEntry.amount);
        }

        ICollateralSystem(collateralSystemAddr).collateralFromUnlockReward(
            user,
            rewarderAddress,
            "CHAOS",
            rewardEntry.amount
        );

        lockedAmountByAddresses[user] = lockedAmountByAddresses[user].sub(rewardEntry.amount);
        totalLockedAmount = totalLockedAmount.sub(rewardEntry.amount);
        emit RewardEntryUnlocked(rewardEntryId, user, rewardEntry.amount);

        delete rewardEntries[rewardEntryId][user];
        emit RewardEntryRemoved(rewardEntryId);
    }

    function _moveRewardProRata(
        address from,
        address recipient1,
        uint256 amount1,
        address recipient2,
        uint256 amount2,
        uint256[] calldata rewardEntryIds
    ) private {
        // Check amount and adjust from balance directly
        uint256 totalAmount = amount1.add(amount2);
        require(totalAmount > 0 && totalAmount <= lockedAmountByAddresses[from], "RewardLocker: amount out of range");
        lockedAmountByAddresses[from] = lockedAmountByAddresses[from].sub(totalAmount);

        uint256 amount1Left = amount1;
        uint256 amount2Left = amount2;

        for (uint256 ind = 0; ind < rewardEntryIds.length; ind++) {
            uint256 currentRewardEntryId = rewardEntryIds[ind];

            (amount1Left, amount2Left) = moveRewardEntry(
                MoveEntryParams({
                    from: from,
                    recipient1: recipient1,
                    amount1: amount1,
                    recipient2: recipient2,
                    amount2: amount2,
                    rewardEntryId: currentRewardEntryId,
                    amount1Left: amount1Left,
                    amount2Left: amount2Left
                })
            );

            if (amount1Left == 0 && amount2Left == 0) break;
        }

        // Ensure all amounts are distributed
        require(amount1Left == 0 && amount2Left == 0, "RewardLocker: amount not filled with all entries");
    }

    function moveRewardEntry(MoveEntryParams memory params)
        private
        returns (uint256 amount1LeftAfter, uint256 amount2LeftAfter)
    {
        RewardEntry memory currentRewardEntry = rewardEntries[params.rewardEntryId][params.from];
        if (currentRewardEntry.amount == 0) {
            /**
             * This reward entry is gone. We're not reverting the tx here because it's possible for
             * moveReward() or moveRewardProRata() to be called multiple times in a single transaction.
             * Instead of asking the caller to precisely track used entries, we just ignore them here.
             */
            return (params.amount1Left, params.amount2Left);
        }

        uint256 totalAmountLeft = params.amount1Left.add(params.amount2Left);

        uint256 currentAmount = MathUpgradeable.min(totalAmountLeft, currentRewardEntry.amount);
        if (currentAmount == currentRewardEntry.amount) {
            // Entry should be removed
            delete rewardEntries[params.rewardEntryId][params.from];

            emit RewardEntryRemoved(params.rewardEntryId);
        } else {
            // Entry should be amended
            uint256 newAmount = uint256(currentRewardEntry.amount).sub(currentAmount);

            rewardEntries[params.rewardEntryId][params.from].amount = uint216(newAmount);

            emit RewardAmountChanged(params.rewardEntryId, currentRewardEntry.amount, newAmount);
        }

        uint256 currentAmountTo1;
        uint256 currentAmountTo2;

        if (totalAmountLeft == currentAmount) {
            // Amount from the current entry is enough for both recipients
            currentAmountTo1 = params.amount1Left;
            currentAmountTo2 = params.amount2Left;
        } else {
            // Pro-rata allocation
            currentAmountTo1 = MathUpgradeable.min(
                params.amount1Left,
                currentAmount.mul(params.amount1).div(params.amount1.add(params.amount2))
            );
            currentAmountTo2 = currentAmount.sub(currentAmountTo1);
        }

        if (currentAmountTo1 > 0) {
            _addReward(params.recipient1, currentAmountTo1, currentRewardEntry.unlockTime);
        }

        if (currentAmountTo2 > 0) {
            _addReward(params.recipient2, currentAmountTo2, currentRewardEntry.unlockTime);
        }

        return (params.amount1Left.sub(currentAmountTo1), params.amount2Left.sub(currentAmountTo2));
    }
}