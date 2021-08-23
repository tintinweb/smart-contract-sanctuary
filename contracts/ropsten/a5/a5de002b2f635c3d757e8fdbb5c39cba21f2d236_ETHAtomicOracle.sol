/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.7.0;

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
        assembly { codehash := extcodehash(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/access/AccessControl.sol

pragma solidity ^0.7.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/IStatusStorage.sol

pragma solidity ^0.7.4; // See "Solidity version" of README.md


/**
 * @title The Status Storage/Database contract.
 * @author Ville Sundell <[email protected]>
 * @dev The Status Storage Contract which is queried by the Oracles.
 *
 * This must be simple: just setting and getting database entries for any
 * address (`string calldata`).
 *
 * Access control is implemented by OpenZeppelin's {AccessControl} contract.
 * It allows us to specify different accounts for different administrative
 * actions (if desired). By default, `admin` is set for every role as a Role
 * Admin.
 *
 * There are two actions guarded by the Access Control logic:
 *  - Setting a Status (256 bits/flags) for any address (`string`), and
 *  - Getting a Status (256 bits/flags) for any address (`string`).
 *
 * The Roles are `SET_STATUS_ROLE` and `GET_STATUS_ROLE` respectively.
 *
 * Target address is intentionally implemented as `string calldata`:
 *  - `target` is not meant to be manipulated, only relayed from Oracle
 *    Contracts, and
 *  - `calldata` saves gas when handling arrays such as `string`.
 */
interface IStatusStorage {
    /**
     * @dev Setting Status (256 bits/flags) for an account.
     *
     * @param target Target account, any account on any network
     * @param status 256 bits (flags) status for an account
     */
    function setStatus(string calldata target, bytes32 status) external;

    /**
     * @dev Getting Status (256 bits/flags) for an account.
     *
     * @param target Target account, any account on any network
     * @return status 256 bits (flags) status for an account
     */
    function getStatus(string calldata target) external view returns (bytes32 status);

    /**
     * @dev Emitted when a status for an account is set
     *
     * @param status Set status, 256 bit flags
     */
    event StatusSet(string target, bytes32 status);
}

// File: contracts/IBaseAtomicOracle.sol

pragma solidity ^0.7.4; // See "Solidity version" of README.md



/**
 * @title Base contract for Atomic Oracles
 * @author Ville Sundell <[email protected]>
 * @dev This is a base contract for Atomic Oracles to inherit. This contract
 * handles communication to the {StatusStorage} contract.
 *
 * Access control is implemented by OpenZeppelin's {AccessControl} contract.
 * It allows us to specify different accounts for different administrative
 * actions (if desired). By default, `admin` is set for every role as a Role
 * Admin.
 *
 * For this particular contract, only one administrative action can be taken:
 *  - Replacing the current Status Storage Contract with another
 *    (`SET_STATUS_STORAGE_ROLE`).
 *
 * Status Storage can be replaced with another, because it's possible that in
 * the future there will be a highly optimized Status Storage. This way Client
 * Smart Contracts can use this same oracle in the future too.
 *
 * Target address is intentionally implemented as `string calldata`:
 *  - `target` is not meant to be manipulated, only relayed to the Storage
 *    Contract, and
 *  - `calldata` saves gas when handling arrays such as `string`.
 */
interface IBaseAtomicOracle {
    /**
     * @dev Replacing the existing Status Storage with a new one.
     *
     * @param statusStorage_ New Status Storage to replace the existing one
     */
    function setStatusStorage(IStatusStorage statusStorage_) external;

    /**
     * @dev Getter for `_statusStorage`.
     *
     * @return statusStorage The current `_statusStorage`
     */
    function getStatusStorage() external view returns (IStatusStorage statusStorage);

    /**
     * @dev Emitted when a new Status Storage contract is set for this oracle.
     *
     * @param statusStorage Address of the new Status Storage Contract
     */
    event StatusStorageSet(IStatusStorage statusStorage);
}

// File: contracts/BaseAtomicOracle.sol

pragma solidity 0.7.4; // See "Solidity version" of README.md





/**
 * @title Base contract for Atomic Oracles
 * @author Ville Sundell <[email protected]>
 * @dev This is a base contract for Atomic Oracles to inherit. This contract
 * handles communication to the {StatusStorage} contract.
 *
 * Access control is implemented by OpenZeppelin's {AccessControl} contract.
 * It allows us to specify different accounts for different administrative
 * actions (if desired). By default, `admin` is set for every role as a Role
 * Admin.
 *
 * For this particular contract, only one administrative action can be taken:
 *  - Replacing the current Status Storage Contract with another
 *    (`SET_STATUS_STORAGE_ROLE`).
 *
 * Status Storage can be replaced with another, because it's possible that in
 * the future there will be a highly optimized Status Storage. This way Client
 * Smart Contracts can use this same oracle in the future too.
 *
 * Target address is intentionally implemented as `string calldata`:
 *  - `target` is not meant to be manipulated, only relayed to the Storage
 *    Contract, and
 *  - `calldata` saves gas when handling arrays such as `string`.
 */
contract BaseAtomicOracle is AccessControl, IBaseAtomicOracle {
    bytes32 public constant SET_STATUS_STORAGE_ROLE = keccak256("SET_STATUS_STORAGE_ROLE");

    IStatusStorage private _statusStorage;

    /**
     * @dev This is the constructor, for better user experience, it checks
     * that `admin` nor `statusStorage_` is not 0x0.
     *
     * @param admin The address to be set as the Admin, and Role Admin for
     * `SET_STATUS_STORAGE_ROLE`.
     * @param statusStorage_ Initial Status Storage Contract. Can be changed
     * later.
     */
    constructor(address admin, IStatusStorage statusStorage_) {
        require(admin != address(0), "BaseAtomicOracle: admin can't be 0x0");

        _setStatusStorage(statusStorage_);

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SET_STATUS_STORAGE_ROLE, admin);
    }

    /**
     * @dev See {IBaseAtomicOracle-setStatusStorage}.
     */
    function setStatusStorage(IStatusStorage statusStorage_) external override {
        require(hasRole(SET_STATUS_STORAGE_ROLE, msg.sender), "BaseAtomicOracle: the caller is not allowed to the Status Storage");

        _setStatusStorage(statusStorage_);
    }

    /**
     * @dev See {IBaseAtomicOracle-getStatusStorage}.
     */
    function getStatusStorage() external view override returns (IStatusStorage statusStorage) {
        return _getStatusStorage();
    }

    /**
     * @dev Internal function for setting the current Status Storage.
     *
     * @param statusStorage_ The new Status Storage Contract
     */
    function _setStatusStorage(IStatusStorage statusStorage_) internal {
        require(address(statusStorage_) != address(0), "BaseAtomicOracle: Status Storage can't be 0x0");

        _statusStorage = statusStorage_;

        emit StatusStorageSet(statusStorage_);
    }

    /**
     * @dev Internal function for getting the current Status Storage.
     *
     * @return statusStorage Current Status Storage
     */
    function _getStatusStorage() internal view returns (IStatusStorage statusStorage) {
        return _statusStorage;
    }

    /**
     * @dev Internal function for getting Status (256 bits/flags) for an
     * account.
     *
     * @param target Target account, any account on any network
     * @return status 256 bits (flags) status for an account
     */
    function _getStatus(string calldata target) internal view returns (bytes32 status) {
        require(bytes(target).length > 0, "BaseAtomicOracle: address invalid");

        try _statusStorage.getStatus(target) returns (bytes32 targetStatus) {
            return targetStatus;
        } catch {
            revert("BaseAtomicOracle: call to Status Storage failed, are we allowed to call it?");
        }
    }
}

// File: contracts/IETHAtomicOracle.sol

pragma solidity ^0.7.4; // See "Solidity version" of README.md



/**
 * @title An Atomic Oracle accepting Ether for fees
 * @author Ville Sundell <[email protected]>
 * @dev A simple Atomic Oracle to serve statuses to Client Smart Contracts
 * for a fee in Ether.
 *
 * Client Smart Contract using this Oracle should always query the current
 * fee via {ETHAtomicOracle-getFee}, so the Client Smart Contract would be
 * ready for sudden price changes by the admin of this contract.
 *
 * Getting the default fee is not needed: {ETHAtomicOracle-getFee} should
 * be used instead.
 *
 * Access control is implemented by OpenZeppelin's {AccessControl} contract.
 * It allows us to specify different accounts for different administrative
 * actions (if desired). By default, `admin` is set for every role as a Role
 * Admin.
 *
 * There are three actions guarded by the Access Control logic:
 *  - setting a fee per Client Smart Contract (`SET_FEE_ROLE`),
 *  - withdrawing the fees from this contract (`WITHDRAW_ROLE`), and
 *  - setting the default fee (`SET_DEFAULT_FEE_ROLE`).
 *
 * Target address is intentionally implemented as `string calldata`:
 *  - `target` is not meant to be manipulated, only relayed from Oracle
 *    Contracts, and
 *  - `calldata` saves gas when handling arrays such as `string`.
 */
interface IETHAtomicOracle is IBaseAtomicOracle {
    /**
     * @dev Setting a fee for a specific Client Smart Contract.
     *
     * @param addr Address of the Client Smart Contract
     * @param fee Fee for this specific smart contract, use 0 to use the
     * default fee
     */
    function setFee(address addr, uint256 fee) external;

    /**
     * @dev Setting the default fee for queries.
     *
     * @param defaultFee_ New default fee for Client Smart Contracts without
     * their own personal fee in wei
     */
    function setDefaultFee(uint256 defaultFee_) external;

    /**
     * @dev Withdraw fees from this contract to the calling account
     *
     * Withdraw all the paid fees.
     */
    function withdrawFees() external;

    /**
     * @dev Status getter, see {BaseAtomicOracle-_getStatus}. Accepts ether.
     */
    function getStatusForETH(string calldata target) external payable returns (bytes32 status);

    /**
     * @dev Get the current fee for a specific Client Smart Contract.
     *
     * Use this to determine what your contract would pay.
     *
     * @param addr The Client Smart Contract whose fee would like to have
     * @return fee Current fee at the moment for `addr` in wei
     */
    function getFee(address addr) external view returns (uint256 fee);

    /**
     * @dev Emitted when a new fee for an address is set.
     *
     * @param addr Ethereum account address whose fee was set
     * @param fee The current fee in wei
     */
    event FeeSet(address addr, uint256 fee);

    /**
     * @dev Emitted when an authorized user withdraws paid fees from this
     * contract.
     *
     * @param destination Ethereum account address where the fees were
     * withdrawn to
     * @param amount Amount of fees withdrawn in wei
     */
    event FeesWithdrawn(address destination, uint256 amount);

    /**
     * @dev Emitted when default fee for account without a personal fee is set
     *
     * @param fee Current fee in wei for accounts without a personal fee
     */
    event DefaultFeeSet(uint256 fee);
}

// File: contracts/ETHAtomicOracle.sol

pragma solidity 0.7.4; // See "Solidity version" of README.md






/**
 * @title An Atomic Oracle accepting Ether for fees
 * @author Ville Sundell <[email protected]>
 * @dev A simple Atomic Oracle to serve statuses to Client Smart Contracts
 * for a fee in Ether.
 *
 * Client Smart Contract using this Oracle should always query the current
 * fee via {ETHAtomicOracle-getFee}, so the Client Smart Contract would be
 * ready for sudden price changes by the admin of this contract.
 *
 * Getting the default fee is not needed: {ETHAtomicOracle-getFee} should
 * be used instead.
 *
 * Access control is implemented by OpenZeppelin's {AccessControl} contract.
 * It allows us to specify different accounts for different administrative
 * actions (if desired). By default, `admin` is set for every role as a Role
 * Admin.
 *
 * There are three actions guarded by the Access Control logic:
 *  - setting a fee per Client Smart Contract (`SET_FEE_ROLE`),
 *  - withdrawing the fees from this contract (`WITHDRAW_ROLE`), and
 *  - setting the default fee (`SET_DEFAULT_FEE_ROLE`).
 *
 * Target address is intentionally implemented as `string calldata`:
 *  - `target` is not meant to be manipulated, only relayed from Oracle
 *    Contracts, and
 *  - `calldata` saves gas when handling arrays such as `string`.
 */
contract ETHAtomicOracle is AccessControl, BaseAtomicOracle, IETHAtomicOracle {
    using Address for address payable;

    bytes32 public constant SET_FEE_ROLE = keccak256("SET_FEE_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant SET_DEFAULT_FEE_ROLE = keccak256("SET_DEFAULT_FEE_ROLE");

    uint256 public _defaultFee;

    mapping (address => uint256) private _fees;


    /**
     * @dev This is the constructor, for better user experience, it checks
     * that `admin` nor `statusStorage_` is not 0x0. The check is done in
     * {BaseAtomicOracle}.
     *
     * Default fee can be set here, 0 is acceptable, though.
     *
     * @param admin The address to be set as the Admin, and Role Admin for
     * `WHITELIST_ROLE`.
     * @param defaultFee_ Initial default fee, can be 0
     * @param statusStorage Initial Status Storage Contract. Can be changed
     * later.
     */
    constructor(address admin, uint256 defaultFee_, IStatusStorage statusStorage) BaseAtomicOracle(admin, statusStorage) {
        _setDefaultFee(defaultFee_);

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SET_FEE_ROLE, admin);
        _setupRole(WITHDRAW_ROLE, admin);
        _setupRole(SET_DEFAULT_FEE_ROLE, admin);
    }

    /**
     * @dev See {IETHAtomicOracle-setFee}.
     */
    function setFee(address addr, uint256 fee) external override {
        require(hasRole(SET_FEE_ROLE, msg.sender), "ETHAtomicOracle: the caller is not allowed to set fees");

        _fees[addr] = fee;

        emit FeeSet(addr, fee);
    }

    /**
     * @dev See {IETHAtomicOracle-setDefaultFee}.
     */
    function setDefaultFee(uint256 defaultFee_) external override {
        require(hasRole(SET_DEFAULT_FEE_ROLE, msg.sender), "ETHAtomicOracle: the caller is not allowed to set the default fee");

        _setDefaultFee(defaultFee_);
    }

    /**
     * @dev See {IETHAtomicOracle-withdrawFees}.
     */
    function withdrawFees() external override {
        uint256 amount = address(this).balance;
        address payable caller = msg.sender;

        require(hasRole(WITHDRAW_ROLE, caller), "ETHAtomicOracle: the caller is not allowed to withdraw fees");
        caller.sendValue(amount);

        emit FeesWithdrawn(caller, amount);
    }

    /**
     * @dev See {IETHAtomicOracle-getStatusForETH}.
     */
    function getStatusForETH(string calldata target) external payable override returns (bytes32 status) {
        require(msg.value == _getFee(msg.sender), "ETHAtomicOracle: Supplied funds do not match the fee");

        return _getStatus(target);
    }

    /**
     * @dev See {IETHAtomicOracle-getFee}.
     */
    function getFee(address addr) external view override returns (uint256 fee) {
        return _getFee(addr);
    }

    /**
     * @dev Internal setter for the default fee.
     *
     * @param defaultFee_ New default fee for Client Smart Contracts without
     * their own personal fee
     */
    function _setDefaultFee(uint256 defaultFee_) internal {
        _defaultFee = defaultFee_;

        emit DefaultFeeSet(_defaultFee);
    }

    /**
     * @dev Internal getter for a fee for a specific Client Smart Contract.
     *
     * @param addr The Client Smart Contract whose fee would like to have
     * @return fee Current fee at the moment for `addr`
     */
    function _getFee(address addr) internal view returns (uint256 fee) {
        if (_fees[addr] > 0) {
            return _fees[addr];
        } else {
            return _defaultFee;
        }
    }
}