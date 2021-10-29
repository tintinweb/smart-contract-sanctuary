/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.9;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

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

struct RoleAccess {
    bytes32 role;
    address addr;
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
 * By default, the admin role for all roles is `ROLE_ADMIN`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `ROLE_ADMIN` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant ROLE_ADMIN = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(ROLE_ADMIN) {
        _grantRole(role, account);
    }
    
    function grantRolesBulk(RoleAccess[] calldata roles)
        external
        onlyRole(ROLE_ADMIN)
    {
        for(uint i = 0; i<roles.length; i++)
        {
            _setupRole(roles[i].role, roles[i].addr);
        }
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

interface IDefiFactoryToken {
    
    function balanceOf(
        address account
    )
        external
        view
        returns (uint);
    
    function totalSupply()
        external
        view
        returns (uint);
        
    function mintHumanAddress(address to, uint desiredAmountToMint) external;

    function burnHumanAddress(address from, uint desiredAmountToBurn) external;
    
    function transferCustom(address sender, address recipient, uint256 amount) external;
    
    function getUtilsContractAtPos(uint pos)
        external
        view
        returns (address);
}

struct IsHumanInfo {
    bool isHumanTransaction;
    bool isBuy;
    bool isSell;
}

interface IDeftStorageContract {
    
    function getBuyTimestamp(address tokenAddr, address addr)
        external
        view
        returns (uint);
    
    function updateBuyTimestamp(address tokenAddr, address addr, uint newBuyTimestamp)
        external;
        
    function isHumanTransaction(address tokenAddr, address sender, address recipient)
        external
        returns (IsHumanInfo memory);
    
    function isBotAddress(address addr)
        external
        view
        returns (bool);
    
    function isExcludedFromBalance(address addr)
        external
        view
        returns (bool);
    
    function bulkMarkAddressAsBot(address[] calldata addrs)
        external;
    
    function markAddressAsBot(address addr)
        external;
    
    function markAddressAsNotBot(address addr)
        external;
        
        
    function markPairAsDeftEthPair(address addr, bool value)
        external;
    
    function markPairAsDeftOtherPair(address addr, bool value)
        external;
}

struct DailySnapshot {
    uint inflationAmount;
    uint totalShares;
    uint sharePrice;
}

struct Stake {
    address owner;
    uint stakedAmount;
    uint startDay;
    uint lockedForXDays;
    uint endDay;
    uint maxSharesCountOnStartStake;
}

struct StartStake {
    uint stakedAmount;
    uint lockedForXDays;
}

struct Settings {
    uint MINIMUM_DAYS_FOR_HIGH_PENALTY;
    uint CONTROLLED_APY;
    uint SMALLER_PAYS_BETTER_BONUS;
    uint LONGER_PAYS_BETTER_BONUS;
    uint END_STAKE_FROM;
    uint END_STAKE_TO;
    uint MINIMUM_STAKE_DAYS;
    uint MAXIMUM_STAKE_DAYS;
}

contract StakingSystem is AccessControlEnumerable {
    DailySnapshot[] public dailySnapshots;
    uint[] public cachedInterestPerShare;
    
    Stake[] public stakes;
    Settings public settings;
    
    uint constant DEFT_STORAGE_CONTRACT_ID = 3;
    uint constant MINIMUM_SMALLER_PAYS_BETTER = 1000 * 1e18; // 1k DEFT
    uint constant MAXIMUM_SMALLER_PAYS_BETTER = 1000000 * 1e18; // 1M DEFT
    uint constant CACHED_DAYS_INTEREST = 100;
    uint constant DAYS_IN_ONE_YEAR = 365;
    uint constant SHARE_PRICE_DENORM = 1e18;
    uint constant INTEREST_PER_SHARE_DENORM = 1e18;
    uint constant APY_DENORM = 1e6;
    uint constant SECONDS_IN_ONE_DAY = 86400;
    
    IDefiFactoryToken deftToken = IDefiFactoryToken(
        0xdef1fac7Bf08f173D286BbBDcBeeADe695129840
    );
    
    uint public launchTimestamp;
    
    event StakeStarted(
        uint stakeId, 
        address owner, 
        uint stakedAmount, 
        uint startDay, 
        uint lockedForXDays, 
        uint sharesCount
    );
    event StakeEnded(
        uint stakeId, 
        uint endDay, 
        uint interest, 
        uint penalty
    );
    event StakeOwnerChanged(
        uint stakeId, 
        address newOwner
    );
    event StakeUpdated(
        uint stakeId, 
        uint lockedForXDays,
        uint sharesCount
    );
    
    event DailySnapshotSealed(
        uint sealedDay, 
        uint inflationAmount,
        uint totalShares,
        uint sharePrice,
        uint totalStaked,
        uint totalSupply
    );
    event CachedInterestPerShareSealed(
        uint sealedDay,
        uint sealedCachedDay, 
        uint cachedInterestPerShare
    );
    
    event SettingsUpdated(
        Settings Settings
    );
    
    event NewMaxSharePriceReached(
        uint newSharePrice
    );
   
    event BurnedAndAddedToStakersInflation(
        address fromAddr, 
        uint amountToBurn, 
        uint currentDay
    );
    
    constructor() 
    {
        settings.MINIMUM_DAYS_FOR_HIGH_PENALTY = 0;
        settings.CONTROLLED_APY = 4e5; // 40%
        settings.END_STAKE_FROM = 30;
        settings.END_STAKE_TO = 2*DAYS_IN_ONE_YEAR; // TODO: 5% per month penalty
        settings.MINIMUM_STAKE_DAYS = 1;
        settings.MAXIMUM_STAKE_DAYS = 100*DAYS_IN_ONE_YEAR;
        settings.LONGER_PAYS_BETTER_BONUS = 3e6; // 3e6/1e6 = 300% shares bonus max
        settings.SMALLER_PAYS_BETTER_BONUS = 25e4; // 25e4/1e6 = 25% shares bonus max
        
        launchTimestamp = 1635604537; // 30 October 2021
        
        dailySnapshots.push(DailySnapshot(
            0,
            0,
            SHARE_PRICE_DENORM
        ));
        emit DailySnapshotSealed(
            0,
            0,
            0,
            SHARE_PRICE_DENORM,
            0,
            0
        );
        dailySnapshots.push(DailySnapshot(
            0,
            0,
            SHARE_PRICE_DENORM
        ));
        cachedInterestPerShare.push(0);
        emit NewMaxSharePriceReached(SHARE_PRICE_DENORM);
        
        updateAllSnapshots();
        
        _setupRole(ROLE_ADMIN, msg.sender);
    }
    
    modifier onlyRealUsers()
    {
        IDeftStorageContract iDeftStorageContract = IDeftStorageContract(
            IDefiFactoryToken(deftToken).getUtilsContractAtPos(DEFT_STORAGE_CONTRACT_ID)
        );
        require(
            !iDeftStorageContract.isBotAddress(msg.sender),
            "SS: Only real users allowed!"
        );
        _;
    }
    
    modifier onlyStakeOwners(uint stakeId)
    {
        require(
            msg.sender == stakes[stakeId].owner,
            "SS: Stake owner does not match"
        );
        _;
    }
    
    modifier onlyExistingStake(uint stakeId)
    {
        require(
            stakeId < stakes.length,
            "SS: Stake does not exist"
        );
        _;
    }
    
    modifier onlyActiveStake(uint stakeId)
    {
        require(
            stakes[stakeId].endDay == 0,
            "SS: Stake was already ended"
        );
        _;
    }
    
    function adminUpdateSettings(Settings calldata _settings)
        public
        onlyRole(ROLE_ADMIN)
    {
        settings = _settings;
        
        emit SettingsUpdated(_settings);
    }
    
    function adminBurnAndAddToStakersInflation(address fromAddr, uint amountToBurn)
        public
        onlyRole(ROLE_ADMIN)
    {
        updateAllSnapshots();
        
        deftToken.burnHumanAddress(fromAddr, amountToBurn);
        
        uint today = getCurrentDaySinceLaunch();
        dailySnapshots[today].inflationAmount += amountToBurn;
        
        emit BurnedAndAddedToStakersInflation(fromAddr, amountToBurn, today);
    }
    
    function bulkTransferOwnership(uint[] calldata stakeIds, address newOwner)
        public
    {
        for(uint i = 0; i<stakeIds.length; i++)
        {
            transferOwnership(stakeIds[i], newOwner);
        }
    }
    
    function transferOwnership(uint stakeId, address newOwner)
        public
        onlyRealUsers()
        onlyStakeOwners(stakeId)
        onlyExistingStake(stakeId)
        onlyActiveStake(stakeId)
    {
        require(
            stakes[stakeId].owner != newOwner,
            "SS: New owner must be different from old owner"
        );
        
        updateAllSnapshots();
        
        stakes[stakeId].owner = newOwner;
        emit StakeOwnerChanged(stakeId, newOwner);
    }
    
    function updateAllSnapshots()
        public
    {
        updateSnapshots(getCurrentDaySinceLaunch());
    }
    
    function updateSnapshots(uint givenDay)
        public
    {
        require(
            givenDay <= getCurrentDaySinceLaunch(),
            "SS: Exceeded current day"
        );
        
        uint startDay = dailySnapshots.length-1; // last sealed day
        if (startDay == givenDay) return;
        
        for (uint i = startDay; i<givenDay; i++)
        {
            uint currentSnapshotIndex = dailySnapshots.length > i? i: dailySnapshots.length-1;
            uint sharesCount =
                ((settings.LONGER_PAYS_BETTER_BONUS + APY_DENORM) * SHARE_PRICE_DENORM) / 
                    (APY_DENORM * dailySnapshots[currentSnapshotIndex].sharePrice);
            uint inflationAmount = 
                (settings.CONTROLLED_APY * (dailySnapshots[currentSnapshotIndex].totalShares + sharesCount)) / 
                    (sharesCount * DAYS_IN_ONE_YEAR * APY_DENORM);
            
            if (dailySnapshots.length > i)
            {
                dailySnapshots[currentSnapshotIndex].inflationAmount += inflationAmount;
            } else
            {
                dailySnapshots.push(DailySnapshot(
                    inflationAmount,
                    dailySnapshots[currentSnapshotIndex].totalShares,
                    dailySnapshots[currentSnapshotIndex].sharePrice
                ));
            }
            emit DailySnapshotSealed(
                i,
                dailySnapshots[currentSnapshotIndex].inflationAmount,
                dailySnapshots[currentSnapshotIndex].totalShares,
                dailySnapshots[currentSnapshotIndex].sharePrice,
                getTotalTokensStaked(),
                deftToken.totalSupply()
            );
        }
        
        if (dailySnapshots.length == givenDay)
        {
            dailySnapshots.push(DailySnapshot(
                0,
                dailySnapshots[givenDay-1].totalShares,
                dailySnapshots[givenDay-1].sharePrice
            ));
        }
        
        uint startCachedDay = cachedInterestPerShare.length-1;
        uint endCachedDay = givenDay / CACHED_DAYS_INTEREST;
        for(uint i = startCachedDay; i<endCachedDay; i++)
        {
            uint interestPerShare;
            for(uint j = i*CACHED_DAYS_INTEREST; j<(i+1)*CACHED_DAYS_INTEREST; j++)
            {
                if (dailySnapshots[j].totalShares == 0) continue;
                
                interestPerShare += 
                    (dailySnapshots[j].inflationAmount * INTEREST_PER_SHARE_DENORM) / dailySnapshots[j].totalShares;
            }
            
            if (cachedInterestPerShare.length > i)
            {
                cachedInterestPerShare[i] = interestPerShare;
            } else {
                cachedInterestPerShare.push(interestPerShare);
            }
            emit CachedInterestPerShareSealed(
                i, // sealedDay
                cachedInterestPerShare.length - 1, // sealedCachedDay
                interestPerShare
            );
        }
        if (cachedInterestPerShare.length == endCachedDay)
        {
            cachedInterestPerShare.push(0);
        }
    }
    
    function bulkStartStake(StartStake[] calldata startStakes)
        public
    {
        for(uint i; i<startStakes.length; i++)
        {
            startStake(startStakes[i]);
        }
    }
    
    function startStake(StartStake memory _startStake)
        public
        onlyRealUsers()
        returns(uint stakeId)
    {
        require(
            _startStake.stakedAmount > 0,
            "SS: StakedAmount has to be larger than zero"
        );
        require(
            _startStake.stakedAmount <= deftToken.balanceOf(msg.sender),
            "SS: StakedAmount exceeds balance"
        );
        require(
            _startStake.lockedForXDays >= settings.MINIMUM_STAKE_DAYS,
            "SS: Stake must be locked for more than min days"
        );
        require(
            _startStake.lockedForXDays <= settings.MAXIMUM_STAKE_DAYS,
            "SS: Stake must be locked for less than max years"
        );
        
        updateAllSnapshots();
        
        deftToken.transferCustom(msg.sender, address(this), _startStake.stakedAmount);
        
        uint today = getCurrentDaySinceLaunch();
        Stake memory stake = Stake(
            msg.sender,
            _startStake.stakedAmount,
            today,
            _startStake.lockedForXDays,
            0,
            0
        );
        stake.maxSharesCountOnStartStake = getSharesCountByStake(stake, 0);
        
        stakes.push(
            stake
        );
        stakeId = stakes.length - 1;
        
        dailySnapshots[today].totalShares += stake.maxSharesCountOnStartStake;
        
        emit StakeStarted(
            stakeId,
            stake.owner,
            stake.stakedAmount, 
            stake.startDay,
            stake.lockedForXDays,
            stake.maxSharesCountOnStartStake
        );
        
        return stakeId;
    }
    
    function bulkEndStake(uint[] calldata stakeIds)
        public
    {
        for(uint i; i<stakeIds.length; i++)
        {
            endStake(stakeIds[i]);
        }
    }
    
    function endStake(
        uint stakeId
    )
        public
        onlyRealUsers()
        onlyStakeOwners(stakeId)
        onlyExistingStake(stakeId)
        onlyActiveStake(stakeId)
    {
        updateAllSnapshots();
        
        uint today = getCurrentDaySinceLaunch();
        stakes[stakeId].endDay = today;
        
        deftToken.transferCustom(address(this), msg.sender, stakes[stakeId].stakedAmount);
        
        uint interest;
        if (
                today < stakes[stakeId].startDay + stakes[stakeId].lockedForXDays
        ) { // Early end stake: Calculating interest similar to scrapeStake one
            Stake memory modifiedStakeToGetInterest = stakes[stakeId];
            modifiedStakeToGetInterest.lockedForXDays = today - stakes[stakeId].startDay;
            
            interest = getInterestByStake(modifiedStakeToGetInterest, today);
        } else { // Late or correct end stake
            interest = getInterestByStake(stakes[stakeId], today);
        }
        
        if (interest > 0)
        {
            deftToken.mintHumanAddress(msg.sender, interest);
        }
        
        uint penalty = getPenaltyByStake(stakes[stakeId], today, interest);
        if (penalty > 0) 
        {
            deftToken.burnHumanAddress(msg.sender, penalty);
            dailySnapshots[today].inflationAmount += penalty;
        }
        
        uint payout = stakes[stakeId].stakedAmount + interest - penalty;
        uint ROI = (payout * SHARE_PRICE_DENORM) / stakes[stakeId].stakedAmount;
        if (ROI > dailySnapshots[today].sharePrice) 
        {
           dailySnapshots[today].sharePrice = ROI;
           emit NewMaxSharePriceReached(ROI);
        }
        
        dailySnapshots[today].totalShares -= stakes[stakeId].maxSharesCountOnStartStake;
        
        emit StakeEnded(stakeId, today, interest, penalty);
    }
    
    function bulkScrapeStake(uint[] calldata stakeIds)
        public
    {
        for(uint i; i<stakeIds.length; i++)
        {
            scrapeStake(stakeIds[i]);
        }
    }
    
    function scrapeStake(
        uint stakeId
    )
        public
        onlyRealUsers()
        onlyStakeOwners(stakeId)
        onlyExistingStake(stakeId)
        onlyActiveStake(stakeId)
    {
        updateAllSnapshots();
        
        uint today = getCurrentDaySinceLaunch();
        require(
            today > stakes[stakeId].startDay,
            "SS: Scraping is available once in 1 day"
        );
        require(
            today < stakes[stakeId].startDay + stakes[stakeId].lockedForXDays,
            "SS: Scraping is available once while stake is In Progress status"
        );
        
        uint oldLockedForXDays = stakes[stakeId].lockedForXDays;
        uint oldSharesCount = stakes[stakeId].maxSharesCountOnStartStake;
        
        stakes[stakeId].lockedForXDays = today - stakes[stakeId].startDay;
        uint newSharesCount = getSharesCountByStake(stakes[stakeId], 0);
        
        dailySnapshots[today].totalShares = dailySnapshots[today].totalShares - oldSharesCount + newSharesCount;
        stakes[stakeId].maxSharesCountOnStartStake = newSharesCount;
        
        emit StakeUpdated(
            stakeId, 
            stakes[stakeId].lockedForXDays,
            newSharesCount
        );
        
        endStake(stakeId);
        
        uint newLockedForXDays = oldLockedForXDays - stakes[stakeId].lockedForXDays;
        startStake(StartStake(stakes[stakeId].stakedAmount, newLockedForXDays));
    }
    
    function getTotalTokensStaked()
        public
        view
        returns(uint)
    {
        return IDefiFactoryToken(deftToken).balanceOf(address(this));
    }
    
    function getDailySnapshotsLength()
        public
        view
        returns(uint)
    {
        return dailySnapshots.length;
    }
    
    function getCachedInterestPerShareLength()
        public
        view
        returns(uint)
    {
        return cachedInterestPerShare.length;
    }
    
    function getStakesLength()
        public
        view
        returns(uint)
    {
        return stakes.length;
    }
    
    function getInterestById(uint stakeId, uint givenDay)
        public
        view
        returns (uint)
    {
        return getInterestByStake(stakes[stakeId], givenDay);
    }
    
    function getInterestByStake(Stake memory stake, uint givenDay)
        public
        view
        returns (uint)
    {
        if (givenDay <= stake.startDay) return 0;
        
        uint interest;
        
        uint endDay = minOfTwoUints(givenDay, stake.startDay + stake.lockedForXDays);
        endDay = minOfTwoUints(endDay, dailySnapshots.length);
        
        uint sharesCount = getSharesCountByStake(stake, givenDay);
        uint startCachedDay = stake.startDay/CACHED_DAYS_INTEREST + 1;
        uint endBeforeFirstCachedDay = minOfTwoUints(endDay, startCachedDay*CACHED_DAYS_INTEREST); 
        for(uint i = stake.startDay; i<endBeforeFirstCachedDay; i++)
        {
            if (dailySnapshots[i].totalShares == 0) continue;
            
            interest += (dailySnapshots[i].inflationAmount * sharesCount) / dailySnapshots[i].totalShares;
        }
        
        uint endCachedDay = endDay/CACHED_DAYS_INTEREST; 
        for(uint i = startCachedDay; i<endCachedDay; i++)
        {
            interest += (cachedInterestPerShare[i] * sharesCount) / INTEREST_PER_SHARE_DENORM;
        }
        
        uint startAfterLastCachedDay = endDay - endDay % CACHED_DAYS_INTEREST;
        if (startAfterLastCachedDay > stake.startDay) // do not double iterate if numberOfDaysServed < CACHED_DAYS_INTEREST 
        {
            for(uint i = startAfterLastCachedDay; i<endDay; i++)
            {
                if (dailySnapshots[i].totalShares == 0) continue;
                
                interest += (dailySnapshots[i].inflationAmount * sharesCount) / dailySnapshots[i].totalShares;
            }
        }
        
        return interest;
    }
    
    function getPenaltyById(uint stakeId, uint givenDay, uint interest)
        public
        view
        returns (uint)
    {
        return getPenaltyByStake(stakes[stakeId], givenDay, interest);
    }
    
    function getPenaltyByStake(Stake memory stake, uint givenDay, uint interest)
        public
        view
        returns (uint)
    {
        /*
        0 -- 0 days served => 0% principal back
        0 days -- 100% served --> 0-100% (principal+interest) back
        100% + 30 days --> 100% (principal+interest) back
        100% + 30 days -- 100% + 30 days + 2*365 days --> 100-10% (principal+interest) back
        > 100% + 30 days + 30*20 days --> 10% (principal+interest) back
        */
        uint penalty;
        uint howManyDaysServed = givenDay > stake.startDay? givenDay - stake.startDay: 0;
        uint riskAmount = stake.stakedAmount + interest;
        
        if (howManyDaysServed <= settings.MINIMUM_DAYS_FOR_HIGH_PENALTY) // Stake just started or less than 7 days passed)
        {
            penalty = riskAmount; // 100%
        } else if (howManyDaysServed <= stake.lockedForXDays) 
        {
            // 100-0%
            penalty = 
                (riskAmount * (stake.lockedForXDays - howManyDaysServed)) / (stake.lockedForXDays - settings.MINIMUM_DAYS_FOR_HIGH_PENALTY);
        } else if (howManyDaysServed <= stake.lockedForXDays + settings.END_STAKE_FROM)
        {
            penalty = 0;
        } else if (howManyDaysServed <= stake.lockedForXDays + settings.END_STAKE_FROM + settings.END_STAKE_TO) {
            // 0-90%
            penalty = 
                (riskAmount * 9 * (howManyDaysServed - stake.lockedForXDays - settings.END_STAKE_FROM)) / (10 * settings.END_STAKE_TO);
        } else // if (howManyDaysServed > stake.lockedForXDays + settings.END_STAKE_FROM + settings.END_STAKE_TO)
        {
            // 90%
            penalty = (riskAmount * 9) / 10;
        } 
        
        return penalty;
    }
    
    function getSharesCountById(uint stakeId, uint givenDay)
        public
        view
        returns(uint)
    {
        return getSharesCountByStake(stakes[stakeId], givenDay);
    }
    
    function getSharesCountByStake(Stake memory stake, uint givenDay)
        public
        view
        returns (uint)
    {
        uint numberOfDaysServed;
        if (givenDay == 0)
        {
            numberOfDaysServed = stake.lockedForXDays;
        } else if (givenDay > stake.startDay)
        {
            numberOfDaysServed = givenDay - stake.startDay;
        } else // givenDay > 0 && givenDay < stake.startDay
        {
            return 0;
        }
        numberOfDaysServed = minOfTwoUints(numberOfDaysServed, 10*DAYS_IN_ONE_YEAR);
        
        uint initialSharesCount = 
            (stake.stakedAmount * SHARE_PRICE_DENORM) / dailySnapshots[stake.startDay].sharePrice;
        uint longerPaysBetterSharesCount =
            (settings.LONGER_PAYS_BETTER_BONUS * numberOfDaysServed * stake.stakedAmount * SHARE_PRICE_DENORM) / 
                (APY_DENORM * 10 * DAYS_IN_ONE_YEAR * dailySnapshots[stake.startDay].sharePrice);
        uint smallerPaysBetterSharesCountMultiplier;
        if (stake.stakedAmount <= MINIMUM_SMALLER_PAYS_BETTER)
        {
            smallerPaysBetterSharesCountMultiplier = APY_DENORM + settings.SMALLER_PAYS_BETTER_BONUS;
        } else if (
            MINIMUM_SMALLER_PAYS_BETTER < stake.stakedAmount &&
            stake.stakedAmount < MAXIMUM_SMALLER_PAYS_BETTER
        ) {
            smallerPaysBetterSharesCountMultiplier = 
                APY_DENORM + 
                    (settings.SMALLER_PAYS_BETTER_BONUS * (MAXIMUM_SMALLER_PAYS_BETTER - stake.stakedAmount)) /
                        (MAXIMUM_SMALLER_PAYS_BETTER - MINIMUM_SMALLER_PAYS_BETTER);
        } else // MAXIMUM_SMALLER_PAYS_BETTER >= stake.stakedAmount
        {
            smallerPaysBetterSharesCountMultiplier = APY_DENORM;
        }
        uint sharesCount = 
            ((initialSharesCount + longerPaysBetterSharesCount) * smallerPaysBetterSharesCountMultiplier) / 
                APY_DENORM;
                
        return sharesCount;
    }
    
    function getCurrentDaySinceLaunch()
        public
        view
        returns (uint)
    {
        return 1 + block.timestamp / SECONDS_IN_ONE_DAY - launchTimestamp / SECONDS_IN_ONE_DAY;
    }
    
    function getCurrentCachedPerShareDay()
        public
        view
        returns (uint)
    {
        return getCurrentDaySinceLaunch() / CACHED_DAYS_INTEREST;
    }
    
    function minOfTwoUints(uint uint1, uint uint2)
        private
        pure
        returns(uint)
    {
        if (uint1 < uint2) return uint1;
        return uint2;
    }
}