// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Adminable is Ownable, AccessControl {
    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Adminable: caller is not the owner or admin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILevelManager {
    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
        bool vip;
    }

    function isLocked(address account) external view returns (bool);

    function getTierById(string calldata id)
        external
        view
        returns (Tier memory);

    function getUserTier(address account) external view returns (Tier memory);

    function getUserUnlockTime(address account) external view returns (uint256);

    function getTierIds() external view returns (string[] memory);

    function lock(address account, uint256 idoStart) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingLockable {
    function isLocked(address account) external view returns (bool);

    function getLockedAmount(address account) external view returns (uint256);
}

interface IStakingLockableExternal {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    function userInfo(address account) external view returns (UserInfo memory);

    function isLocked(address account) external view returns (bool);

    function getLockedAmount(address account) external view returns (uint256);

    function lock(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingLockable.sol";
import "./ILevelManager.sol";
import "./WithLevels.sol";
import "./WithPools.sol";
import "../Adminable.sol";

contract LevelManager is Adminable, ILevelManager, WithLevels, WithPools {
    bool public lockEnabled = true;

    mapping(address => bool) isIDO;
    mapping(address => uint256) public userUnlocksAt;

    event Lock(address indexed account, uint256 unlockTime, address locker);
    event LockEnabled(bool status);

    modifier onlyIDO() {
        require(isIDO[_msgSender()], "Only IDOs can lock");
        _;
    }

    function isLocked(address account) external view override returns (bool) {
        return lockEnabled && userUnlocksAt[account] > block.timestamp;
    }

    function getUserTier(address account)
        public
        view
        override
        returns (Tier memory)
    {
        return getTierForAmount(getUserAmount(account));
    }

    function getUserUnlockTime(address account)
        external
        view
        override
        returns (uint256)
    {
        return userUnlocksAt[account];
    }

    function getUserAmount(address account) public view returns (uint256) {
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < pools.length; i++) {
            IStakingLockableExternal pool = pools[i];
            address poolAddr = address(pool);
            uint256 multiplier = poolMultiplier[poolAddr];
            if (poolEnabled[poolAddr]) {
                try pool.getLockedAmount(account) returns (uint256 amount) {
                    totalAmount += (amount * multiplier) / 1_000_000_000;
                    continue;
                } catch {}

                try pool.userInfo(account) returns (
                    IStakingLockableExternal.UserInfo memory userInfo
                ) {
                    totalAmount +=
                        (userInfo.amount * multiplier) /
                        1_000_000_000;
                    continue;
                } catch {}
            }
        }

        return totalAmount;
    }

    function toggleLocking(bool status) external onlyOwnerOrAdmin {
        lockEnabled = status;
        emit LockEnabled(status);
    }

    function addIDO(address account) external onlyOwnerOrAdmin {
        require(account != address(0), "IDO cannot be zero address");
        isIDO[account] = true;
    }

    function lock(address account, uint256 idoStart) external override onlyIDO {
        internalLock(account, idoStart);
    }

    function internalLock(address account, uint256 idoStart) internal {
        require(
            idoStart >= block.timestamp,
            "LevelManager: IDO start must be in future"
        );

        Tier memory tier = getUserTier(account);
        if (tier.lockingPeriod == 0) {
            return;
        }

        uint256 unlockTime = idoStart + tier.lockingPeriod;
        if (userUnlocksAt[account] < unlockTime) {
            userUnlocksAt[account] = unlockTime;
            emit Lock(account, unlockTime, _msgSender());

            // Support for old stakers
            for (uint256 i = 0; i < pools.length; i++) {
                IStakingLockableExternal pool = pools[i];
                address poolAddr = address(pool);
                if (poolEnabled[poolAddr]) {
                    try pool.lock(account) {} catch {}
                }
            }
        }
    }

    function unlock(address account) external onlyOwnerOrAdmin {
        userUnlocksAt[account] = block.timestamp;
    }

    function batchLock(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            internalLock(addresses[i], block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingLockable.sol";
import "./ILevelManager.sol";
import "../Adminable.sol";

abstract contract WithLevels is Adminable, ILevelManager {
    string constant noneTierId = "none";

    Tier[] public tiers;

    event TierCreate(
        string indexed id,
        uint8 multiplier,
        uint256 lockingPeriod,
        uint256 minAmount,
        bool random,
        uint8 odds,
        bool vip
    );
    event TierUpdate(
        string indexed id,
        uint8 multiplier,
        uint256 lockingPeriod,
        uint256 minAmount,
        bool random,
        uint8 odds,
        bool vip
    );
    event TierRemove(string indexed id, uint256 idx);

    constructor() {
        // Init with none level
        tiers.push(Tier(noneTierId, 0, 0, 0, false, 0, false));
    }

    function getTierIds() external view override returns (string[] memory) {
        string[] memory ids = new string[](tiers.length);
        for (uint256 i = 0; i < tiers.length; i++) {
            ids[i] = tiers[i].id;
        }

        return ids;
    }

    function getTierById(string calldata id)
        public
        view
        override
        returns (Tier memory)
    {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                return tiers[i];
            }
        }
        revert("No such tier");
    }

    function getTierForAmount(uint256 amount)
        internal
        view
        returns (Tier memory)
    {
        return tiers[getTierIdxForAmount(amount)];
    }

    function getTierIdxForAmount(uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }
        uint256 maxTierK = 0;
        uint256 maxTierV;
        for (uint256 i = 1; i < tiers.length; i++) {
            Tier storage tier = tiers[i];
            if (amount >= tier.minAmount && tier.minAmount > maxTierV) {
                maxTierK = i;
                maxTierV = tier.minAmount;
            }
        }

        return maxTierK;
    }

    function setTier(
        string calldata id,
        uint8 multiplier,
        uint256 lockingPeriod,
        uint256 minAmount,
        bool random,
        uint8 odds,
        bool vip
    ) external onlyOwnerOrAdmin returns (uint256) {
        require(!stringsEqual(id, noneTierId), "Can't change 'none' tier");

        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                tiers[i].multiplier = multiplier;
                tiers[i].lockingPeriod = lockingPeriod;
                tiers[i].minAmount = minAmount;
                tiers[i].random = random;
                tiers[i].odds = odds;
                tiers[i].vip = vip;

                emit TierUpdate(
                    id,
                    multiplier,
                    lockingPeriod,
                    minAmount,
                    random,
                    odds,
                    vip
                );

                return i;
            }
        }

        Tier memory newTier = Tier(
            id,
            multiplier,
            lockingPeriod,
            minAmount,
            random,
            odds,
            vip
        );
        tiers.push(newTier);

        emit TierCreate(
            id,
            multiplier,
            lockingPeriod,
            minAmount,
            random,
            odds,
            vip
        );

        return tiers.length - 1;
    }

    function deleteTier(string calldata id) external onlyOwnerOrAdmin {
        require(!stringsEqual(id, noneTierId), "Can't delete 'none' tier");

        for (uint256 tierIdx = 0; tierIdx < tiers.length; tierIdx++) {
            if (stringsEqual(tiers[tierIdx].id, id)) {
                for (uint256 i = tierIdx; i < tiers.length - 1; i++) {
                    tiers[i] = tiers[i + 1];
                }
                tiers.pop();

                emit TierRemove(id, tierIdx);
                break;
            }
        }
    }

    function stringsEqual(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingLockable.sol";
import "./ILevelManager.sol";
import "../Adminable.sol";

abstract contract WithPools is Adminable, ILevelManager {
    IStakingLockableExternal[] public pools;
    mapping(address => bool) public poolEnabled;
    // 1x = 100, 0.5x = 50
    mapping(address => uint256) public poolMultiplier;

    event PoolEnabled(address indexed pool, bool status);
    event PoolMultiplierSet(address indexed pool, uint256 multiplier);

    function addPool(address pool, uint256 multiplier)
        external
        onlyOwnerOrAdmin
    {
        pools.push(IStakingLockableExternal(pool));
        togglePool(pool, true);

        if (multiplier == 0) {
            multiplier = 100;
        }
        setPoolMultiplier(pool, multiplier);
    }

    function togglePool(address pool, bool status) public onlyOwnerOrAdmin {
        poolEnabled[pool] = status;
        emit PoolEnabled(pool, status);
    }

    function setPoolMultiplier(address pool, uint256 multiplier)
        public
        onlyOwnerOrAdmin
    {
        require(multiplier > 0, "LevelManager: Multiplier must be > 0");
        poolMultiplier[pool] = multiplier;
        emit PoolMultiplierSet(pool, multiplier);
    }
}

