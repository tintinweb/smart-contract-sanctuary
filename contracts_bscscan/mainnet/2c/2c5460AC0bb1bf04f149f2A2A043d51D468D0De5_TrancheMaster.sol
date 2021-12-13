// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Permissions.sol";

contract Core is Permissions {

    constructor() public {
        _setupGovernor(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Permissions is AccessControl {
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant MULTISTRATEGY_ROLE = keccak256("MULTISTRATEGY_ROLE");

    constructor() public {
        _setupGovernor(address(this));
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, GOVERN_ROLE);
        _setRoleAdmin(MASTER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(TIMELOCK_ROLE, GOVERN_ROLE);
        _setRoleAdmin(MULTISTRATEGY_ROLE, GOVERN_ROLE);
    }

    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "Permissions::onlyGovernor: Caller is not a governor");
        _;
    }

    function createRole(bytes32 role, bytes32 adminRole) external onlyGovernor {
        _setRoleAdmin(role, adminRole);
    }

    function grantGovernor(address governor) external onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    function grantGuardian(address guardian) external onlyGovernor {
        grantRole(GUARDIAN_ROLE, guardian);
    }

    function grantMultistrategy(address multistrategy) external onlyGovernor {
        grantRole(MULTISTRATEGY_ROLE, multistrategy);
    }

    function revokeGovernor(address governor) external onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    function revokeGuardian(address guardian) external onlyGovernor {
        revokeRole(GUARDIAN_ROLE, guardian);
    }

    function revokeMultistrategy(address multistrategy) external onlyGovernor {
        revokeRole(MULTISTRATEGY_ROLE, multistrategy);
    }

    function isGovernor(address _address) public view virtual returns (bool) {
        return hasRole(GOVERN_ROLE, _address);
    }

    function isMultistrategy(address _address) public view virtual returns (bool) {
        return hasRole(MULTISTRATEGY_ROLE, _address);
    }

    function isGuardian(address _address) public view returns (bool) {
        return hasRole(GUARDIAN_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CreamFake is ERC20 {
    using SafeERC20 for IERC20;

    uint256 gains;
    address underlying;
    address rewardToken;
    bool loss;

    constructor(
        address _underlying,
        address _rewardToken,
        uint256 _gains,
        bool _loss
    ) public ERC20("", "") {
        underlying = _underlying;
        rewardToken = _rewardToken;
        gains = _gains;
        loss = _loss;
    }

    function mint(uint256 amount) public returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }

    function redeem(uint256 redeemTokens) public returns (uint256) {
        uint256 factor = loss ? (100 - gains) : (100 + gains);
        uint256 amount = (redeemTokens * factor) / 100;
        IERC20(underlying).safeTransfer(msg.sender, amount);
        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        _burn(msg.sender, redeemTokens);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVenus.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IOracle.sol";
import "../refs/CoreRef.sol";

contract StrategyVenus is IStrategyVenus, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override wantAddress;
    address public override vTokenAddress;
    address[] public override markets;
    address public override uniRouterAddress;

    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public override earnedAddress;
    address public override distributionAddress;

    address[] public override earnedToWantPath;

    uint256 public override borrowRate;

    bool public override isComp;

    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _wantAddress,
        address _vTokenAddress,
        address _uniRouterAddress,
        address _earnedAddress,
        address _distributionAddress,
        address[] memory _earnedToWantPath,
        bool _isComp,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        borrowRate = 585;
        wantAddress = _wantAddress;

        earnedToWantPath = _earnedToWantPath;

        earnedAddress = _earnedAddress;
        distributionAddress = _distributionAddress;
        vTokenAddress = _vTokenAddress;
        markets = [vTokenAddress];
        uniRouterAddress = _uniRouterAddress;

        isComp = _isComp;

        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));

        IVenusDistribution(distributionAddress).enterMarkets(markets);
    }

    function _supply(uint256 _amount) internal {
        require(IVToken(vTokenAddress).mint(_amount) == 0, "mint Err");
    }

    function _removeSupply(uint256 _amount) internal {
        require(IVToken(vTokenAddress).redeemUnderlying(_amount) == 0, "redeemUnderlying Err");
    }

    function _borrow(uint256 _amount) internal {
        require(IVToken(vTokenAddress).borrow(_amount) == 0, "borrow Err");
    }

    function _repayBorrow(uint256 _amount) internal {
        require(IVToken(vTokenAddress).repayBorrow(_amount) == 0, "repayBorrow Err");
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        (uint256 sup, uint256 brw, ) = updateBalance();

        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        _supply(wantLockedInHere());
    }

    function leverage(uint256 _amount) public override onlyTimelock {
        _leverage(_amount);
    }

    function _leverage(uint256 _amount) internal {
        updateStrategy();
        (uint256 sup, uint256 brw, ) = updateBalance();

        require(brw.add(_amount).mul(1000).div(borrowRate) <= sup, "ltv too high");
        _borrow(_amount);
        _supply(wantLockedInHere());
    }

    function deleverage(uint256 _amount) public override onlyTimelock {
        _deleverage(_amount);
    }

    function deleverageAll(uint256 redeemFeeAmt) public override onlyTimelock {
        updateStrategy();
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();
        require(brw.add(redeemFeeAmt) <= sup.sub(supMin), "amount too big");
        _removeSupply(brw.add(redeemFeeAmt));
        _repayBorrow(brw);
        _supply(wantLockedInHere());
    }

    function _deleverage(uint256 _amount) internal {
        updateStrategy();
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();

        require(_amount <= sup.sub(supMin), "amount too big");
        require(_amount <= brw, "amount too big");

        _removeSupply(_amount);
        _repayBorrow(wantLockedInHere());
    }

    function setBorrowRate(uint256 _borrowRate) public override onlyTimelock {
        updateStrategy();
        borrowRate = _borrowRate;
        (uint256 sup, , uint256 supMin) = updateBalance();
        require(sup >= supMin, "supply should be greater than supply min");
    }

    function earn() public override whenNotPaused onlyTimelock {
        if (isComp) {
            IVenusDistribution(distributionAddress).claimComp(address(this));
        } else {
            IVenusDistribution(distributionAddress).claimVenus(address(this));
        }
        uint256 minReturnWant;

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _supply(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        _withdraw();

        if (isComp) {
            IVenusDistribution(distributionAddress).claimComp(address(this));
        } else {
            IVenusDistribution(distributionAddress).claimVenus(address(this));
        }

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (earnedAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 wantBal = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, wantBal);
    }

    function _withdraw() internal {
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();
        uint256 _wantAmt = sup.sub(brw);
        uint256 delevAmtAvail = sup.sub(supMin);
        while (_wantAmt > delevAmtAvail) {
            if (delevAmtAvail > brw) {
                _deleverage(brw);
                (sup, brw, supMin) = updateBalance();
                delevAmtAvail = sup.sub(supMin);
                break;
            } else {
                _deleverage(delevAmtAvail);
            }
            (sup, brw, supMin) = updateBalance();
            delevAmtAvail = sup.sub(supMin);
        }

        if (_wantAmt > delevAmtAvail) {
            _wantAmt = delevAmtAvail;
        }

        _removeSupply(_wantAmt);
    }

    function _pause() internal override {
        super._pause();
        IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(vTokenAddress, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(earnedAddress);
        uint256 total = amount.mul(oraclePrice);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function updateBalance()
        public
        view
        override
        returns (
            uint256 sup,
            uint256 brw,
            uint256 supMin
        )
    {
        (uint256 errCode, uint256 _sup, uint256 _brw, uint256 exchangeRate) = IVToken(vTokenAddress).getAccountSnapshot(
            address(this)
        );
        require(errCode == 0, "Venus ErrCode");
        sup = _sup.mul(exchangeRate).div(1e18);
        brw = _brw;
        supMin = brw.mul(1000).div(borrowRate);
    }

    function wantLockedTotal() public view returns (uint256) {
        (uint256 sup, uint256 brw, ) = updateBalance();
        return wantLockedInHere().add(sup).sub(brw);
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != vTokenAddress, "!safe");

        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {
        require(IVToken(vTokenAddress).accrueInterest() == 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVenusDistribution {
    function claimVenus(address holder) external;

    function claimComp(address holder) external;

    function enterMarkets(address[] memory _vtokens) external;

    function exitMarket(address _vtoken) external;

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IVToken is IERC20 {

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint256);
    
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function accrueInterest() external returns (uint);
}

interface IVBNB is IVToken {
    function mint() external payable;

    function repayBorrow() external payable;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategy {
    function wantLockedInHere() external view returns (uint256);

    function lastEarnBlock() external view returns (uint256);

    function deposit(uint256 _wantAmt) external;

    function withdraw() external;

    function updateStrategy() external;

    function uniRouterAddress() external view returns (address);

    function wantAddress() external view returns (address);

    function earnedToWantPath(uint256 idx) external view returns (address);

    function earn() external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

interface ILeverageStrategy is IStrategy {
    function leverage(uint256 _amount) external;

    function deleverage(uint256 _amount) external;

    function deleverageAll(uint256 redeemFeeAmount) external;

    function updateBalance()
        external
        view
        returns (
            uint256 sup,
            uint256 brw,
            uint256 supMin
        );

    function borrowRate() external view returns (uint256);

    function setBorrowRate(uint256 _borrowRate) external;
}

interface IStrategyAlpaca is IStrategy {
    function vaultAddress() external view returns (address);

    function poolId() external view returns (uint256);
}

interface IStrategyVenus is ILeverageStrategy {
    function vTokenAddress() external view returns (address);

    function markets(uint256 idx) external view returns (address);

    function earnedAddress() external view returns (address);

    function distributionAddress() external view returns (address);

    function isComp() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IOracle {
    function oracle() external view returns (address);

    function getLatestPrice(address token) external view returns (uint256 price);

    function setFeeds(
        address[] memory _tokens,
        address[] memory _baseDecimals,
        address[] memory _aggregators
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/ICore.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract CoreRef is Pausable {
    event CoreUpdate(address indexed _core);

    ICore private _core;

    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    constructor(address core_) public {
        _core = ICore(core_);
    }

    modifier onlyGovernor() {
        require(_core.isGovernor(msg.sender), "CoreRef::onlyGovernor: Caller is not a governor");
        _;
    }

    modifier onlyGuardian() {
        require(_core.isGuardian(msg.sender), "CoreRef::onlyGuardian: Caller is not a guardian");
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef::onlyGuardianOrGovernor: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyMultistrategy() {
        require(_core.isMultistrategy(msg.sender), "CoreRef::onlyMultistrategy: Caller is not a multistrategy");
        _;
    }

    modifier onlyTimelock() {
        require(_core.hasRole(TIMELOCK_ROLE, msg.sender), "CoreRef::onlyTimelock: Caller is not a timelock");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "CoreRef::onlyRole: Not permit");
        _;
    }

    modifier onlyRoleOrOpenRole(bytes32 role) {
        require(
            _core.hasRole(role, address(0)) || _core.hasRole(role, msg.sender),
            "CoreRef::onlyRoleOrOpenRole: Not permit"
        );
        _;
    }

    function setCore(address core_) external onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function pause() public onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public onlyGuardianOrGovernor {
        _unpause();
    }

    function core() public view returns (ICore) {
        return _core;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICore {
    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isMultistrategy(address _address) external view returns (bool);

    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IOracle.sol";
import "../refs/CoreRef.sol";

contract StrategyAlpaca is IStrategyAlpaca, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override uniRouterAddress;

    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address public constant alpacaAddress = 0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F;

    address public constant fairLaunchAddress = 0xA625AB01B08ce023B2a342Dbb12a16f2C8489A8F;

    address public override vaultAddress;
    address public override wantAddress;
    uint256 public override poolId;

    address[] public override earnedToWantPath;
    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _vaultAddress,
        address _wantAddress,
        address _uniRouterAddress,
        uint256 _poolId,
        address[] memory _earnedToWantPath,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        vaultAddress = _vaultAddress;
        wantAddress = _wantAddress;
        poolId = _poolId;
        earnedToWantPath = _earnedToWantPath;
        uniRouterAddress = _uniRouterAddress;
        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(vaultAddress, uint256(-1));
        IERC20(vaultAddress).safeApprove(fairLaunchAddress, uint256(-1));
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        Vault(vaultAddress).deposit(_wantAmt);
        FairLaunch(fairLaunchAddress).deposit(address(this), poolId, Vault(vaultAddress).balanceOf(address(this)));
    }

    function earn() public override whenNotPaused onlyTimelock {
        FairLaunch(fairLaunchAddress).harvest(poolId);
        uint256 earnedAmt = IERC20(alpacaAddress).balanceOf(address(this));
        if (alpacaAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _deposit(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        (uint256 _amount, , , ) = FairLaunch(fairLaunchAddress).userInfo(poolId, address(this));
        FairLaunch(fairLaunchAddress).withdraw(address(this), poolId, _amount);
        Vault(vaultAddress).withdraw(Vault(vaultAddress).balanceOf(address(this)));

        uint256 earnedAmt = IERC20(alpacaAddress).balanceOf(address(this));
        if (alpacaAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 balance = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, balance);
    }

    function _pause() internal override {
        super._pause();
        IERC20(alpacaAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(vaultAddress, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vaultAddress, uint256(-1));
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(alpacaAddress);
        uint256 total = amount.mul(oraclePrice);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != alpacaAddress, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != vaultAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {}
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface Vault {
    function balanceOf(address account) external view returns (uint256);

    function totalToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function deposit(uint256 amountToken) external payable;

    function withdraw(uint256 share) external;

    function work(
        uint256 id,
        address worker,
        uint256 principalAmount,
        uint256 loan,
        uint256 maxReturn,
        bytes memory data
    ) external;
}

interface FairLaunch {
    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external; // staking

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external; // unstaking

    function harvest(uint256 _pid) external;

    function pendingAlpaca(uint256 _pid, address _user) external returns (uint256);

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 bonusDebt,
            uint256 fundedBy
        );
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyToken.sol";
import "../refs/CoreRef.sol";

contract MultiStrategyToken is IMultiStrategyToken, ReentrancyGuard, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");

    address public override token;

    address[] public override strategies;

    mapping(address => uint256) public override ratios;

    uint256 public override ratioTotal;

    event RatioChanged(address strategyAddress, uint256 ratioBefore, uint256 ratioAfter);

    constructor(
        address _core,
        address _token,
        address[] memory _strategies,
        uint256[] memory _ratios
    ) public CoreRef(_core) {
        require(_strategies.length == _ratios.length, "array not match");

        token = _token;
        strategies = _strategies;

        for (uint256 i = 0; i < strategies.length; i++) {
            ratios[strategies[i]] = _ratios[i];
            ratioTotal = ratioTotal.add(_ratios[i]);
        }

        approveToken();
    }

    function approveToken() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IERC20(token).safeApprove(strategies[i], uint256(-1));
        }
    }

    function deposit(uint256 _amount) public override {
        require(_amount != 0, "deposit must be greater than 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount);
    }

    function _deposit(uint256 _amount) internal nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 amt = _amount.mul(ratios[strategies[i]]).div(ratioTotal);
            IStrategy(strategies[i]).deposit(amt);
        }
    }

    function withdraw() public override onlyRole(MASTER_ROLE) nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).withdraw();
        }

        uint256 amt = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function changeRatio(uint256 index, uint256 value) public override onlyTimelock {
        require(strategies.length > index, "invalid index");
        uint256 valueBefore = ratios[strategies[index]];
        ratios[strategies[index]] = value;
        ratioTotal = ratioTotal.sub(valueBefore).add(value);

        emit RatioChanged(strategies[index], valueBefore, value);
    }

    function strategyCount() public view override returns (uint256) {
        return strategies.length;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != token, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateAllStrategies() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).updateStrategy();
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyToken {
    function token() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdraw() external;

    function approveToken() external;
}

interface IMultiStrategyToken is IStrategyToken {
    function strategies(uint256 idx) external view returns (address);

    function strategyCount() external view returns (uint256);

    function ratios(address _strategy) external view returns (uint256);

    function ratioTotal() external view returns (uint256);

    function changeRatio(uint256 _index, uint256 _value) external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function updateAllStrategies() external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMaster.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMaster is ITrancheMaster, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 apy;
        uint256 fee;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 capital;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
    }

    struct UserInfo {
        uint256 balance;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override currency;
    address public override staker;
    address public override strategy;

    address public override devAddress;

    mapping(address => UserInfo) public override userInfo;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _currency,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.cycle < cycle) {
                uint256 principal = inv.principal;
                if (principal > 0) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    uint256 capital = principal.mul(snapshot.rate).div(PercentageScale);
                    u.balance = u.balance.add(capital);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, principal, capital);
                }
                inv.cycle = cycle;
            }
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo storage u = userInfo[account];
        balance = u.balance;
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.principal > 0) {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    uint256 capital = inv.principal.mul(snapshot.rate).div(PercentageScale);
                    balance = balance.add(capital);
                } else {
                    invested = invested.add(inv.principal);
                }
            }
        }
    }

    function getInvest(uint256 tid) public view override checkTrancheID(tid) returns (uint256) {
        Investment storage inv = userInvest[msg.sender][tid];
        if (inv.cycle < cycle) {
            return 0;
        } else {
            return inv.principal;
        }
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal < t.target) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        IERC20(currency).safeTransferFrom(msg.sender, address(this), amountIn);
        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false);
    }

    function deposit(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) private {
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");

        Tranche storage t = tranches[tid];
        require(t.target >= t.principal.add(amount), "not enough quota");
        Investment storage inv = userInvest[msg.sender][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        t.principal = t.principal.add(amount);

        IMasterWTF(staker).updateStake(tid, msg.sender, inv.principal);

        emit Invest(msg.sender, tid, cycle, amount);

        if (returnLeft && u.balance > 0) {
            IERC20(currency).safeTransferFrom(address(this), msg.sender, u.balance);
            emit Withdraw(msg.sender, u.balance);
            u.balance = 0;
        }

        _tryStart();
    }

    function redeem(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);
        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function _startCycle() internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal);
        }

        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].principal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle() internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit();
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _processExit() internal {
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw();

        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            principal = senior.principal;
            capital = 0;
            interestShouldBe = senior.principal.mul(senior.apy).mul(_now - actualStartAt).div(365).div(86400).div(
                PercentageScale
            );

            uint256 all = principal.add(interestShouldBe);
            bool satisfied = restCapital >= all;
            if (!satisfied) {
                capital = restCapital;
                restCapital = 0;
            } else {
                capital = all;
                restCapital = restCapital.sub(all);
            }

            if (satisfied) {
                uint256 fee = capital.mul(senior.fee).div(PercentageParamScale);
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }

            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: principal,
                capital: capital,
                rate: cycleExchangeRate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: _now
            });

            senior.principal = 0;

            emit TrancheSettle(i, cycle, principal, capital, cycleExchangeRate);
        }

        uint256 juniorIndex = tranches.length - 1;
        Tranche storage junior = tranches[juniorIndex];
        principal = junior.principal;
        capital = restCapital;
        uint256 fee = capital.mul(junior.fee).div(PercentageParamScale);
        producedFee = producedFee.add(fee);
        capital = capital.sub(fee);
        cycleExchangeRate = _calculateExchangeRate(capital, principal);
        trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
            target: junior.target,
            principal: principal,
            capital: capital,
            rate: cycleExchangeRate,
            apy: junior.apy,
            fee: junior.fee,
            startAt: actualStartAt,
            stopAt: now
        });

        junior.principal = 0;

        emit TrancheSettle(juniorIndex, cycle, principal, capital, cycleExchangeRate);
    }

    function stop() public override checkActive nonReentrant {
        _stopCycle();
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            IERC20(currency).safeTransfer(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public override onlyGovernor {
        require(_amount > 0, "Zero amount");
        IERC20(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMaster {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function getInvest(uint256 tid) external view returns (uint256);

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external;

    function deposit(uint256 amount) external;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function stop() external;

    function withdrawFee(uint256 amount) external;

    function transferFeeToStaking(uint256 _amount, address _pool) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 apy,
            uint256 fee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function devAddress() external view returns (address);

    function userInfo(address account) external view returns (uint256);

    function userInvest(address account, uint256 tid) external view returns (uint256 cycle, uint256 principal);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 capital,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IMasterWTF {
    function rewardToken() external view returns (address);

    function rewardPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function cycleId() external view returns (uint256);

    function rewarding() external view returns (bool);

    function votingEscrow() external view returns (address);

    function poolInfo(uint256 pid) external view returns (uint256);

    function userInfo(uint256 pid, address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 cid,
            uint256 earned
        );

    function poolSnapshot(uint256 cid, uint256 pid)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare
        );

    function poolLength() external view returns (uint256);

    function add(uint256 _allocPoint) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setVotingEscrow(address _votingEscrow) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingReward(address _user, uint256 _pid) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) external;

    function start(uint256 _endBlock) external;

    function next(uint256 _cid) external;

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfNoLock,
        uint256 _newLockExpiryTsIfLockExists
    ) external;

    function claimAll(uint256 _lockDurationIfNoLock, uint256 _newLockExpiryTsIfLockExists) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IFeeRewards {
    function sendRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMaster.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyToken.sol";

contract TimelockController is CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant _DONE_TIMESTAMP = uint256(1);
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(bytes32 => uint256) private _timestamps;
    uint256 public minDelay;

    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    event Cancelled(bytes32 indexed id);

    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    modifier onlySelf() {
        require(msg.sender == address(this), "TimelockController::onlySelf: caller is not itself");
        _;
    }

    constructor(address _core, uint256 _minDelay) public CoreRef(_core) {
        minDelay = _minDelay;
        emit MinDelayChange(0, _minDelay);
    }

    receive() external payable {}

    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= minDelay, "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    function updateDelay(uint256 newDelay) public virtual onlySelf {
        emit MinDelayChange(minDelay, newDelay);
        minDelay = newDelay;
    }

    // IMasterWTF

    function setMasterWTF(
        address _master,
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlySelf {
        IMasterWTF(_master).set(_pid, _allocPoint, _withUpdate);
    }

    function updateRewardPerBlock(address _master, uint256 _rewardPerBlock) public onlySelf {
        IMasterWTF(_master).updateRewardPerBlock(_rewardPerBlock);
    }

    // ITrancheMaster

    function setTrancheMaster(
        address _trancheMaster,
        uint256 _tid,
        uint256 _target,
        uint256 _apy,
        uint256 _fee
    ) public onlySelf {
        ITrancheMaster(_trancheMaster).set(_tid, _target, _apy, _fee);
    }

    // IStrategyToken

    function changeRatio(
        address _token,
        uint256 _index,
        uint256 _value
    ) public onlySelf {
        IMultiStrategyToken(_token).changeRatio(_index, _value);
    }

    // IStrategy

    function earn(address _strategy) public onlyRole(EXECUTOR_ROLE) {
        IStrategy(_strategy).earn();
    }

    function inCaseTokensGetStuck(
        address _strategy,
        address _token,
        uint256 _amount,
        address _to
    ) public onlySelf {
        IStrategy(_strategy).inCaseTokensGetStuck(_token, _amount, _to);
    }

    function leverage(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).leverage(_amount);
    }

    function deleverage(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).deleverage(_amount);
    }

    function deleverageAll(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).deleverageAll(_amount);
    }

    function setBorrowRate(address _strategy, uint256 _borrowRate) public onlySelf {
        ILeverageStrategy(_strategy).setBorrowRate(_borrowRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IVotingEscrow.sol";

contract MasterWTF is IMasterWTF, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 cid;
        uint256 earned;
    }

    struct PoolInfo {
        uint256 allocPoint;
    }

    struct PoolStatus {
        uint256 totalSupply;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    address public override votingEscrow;
    address public override rewardToken;
    uint256 public override rewardPerBlock;
    uint256 public override totalAllocPoint = 0;
    uint256 public override startBlock;
    uint256 public override endBlock;
    uint256 public override cycleId = 0;
    bool public override rewarding = false;

    PoolInfo[] public override poolInfo;
    // pid => address => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;
    // cid => pid => PoolStatus
    mapping(uint256 => mapping(uint256 => PoolStatus)) public override poolSnapshot;

    modifier validatePid(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePid: Not exist");
        _;
    }

    event UpdateEmissionRate(uint256 rewardPerBlock);

    constructor(
        address _core,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] memory _pools,
        address _votingEscrow
    ) public CoreRef(_core) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        votingEscrow = _votingEscrow;
        IERC20(_rewardToken).safeApprove(votingEscrow, uint256(-1));
        uint256 total = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            total = total.add(_pools[i]);
            poolInfo.push(PoolInfo({allocPoint: _pools[i]}));
        }
        totalAllocPoint = total;
    }

    function poolLength() public view override returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint) public override onlyGovernor {
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({allocPoint: _allocPoint}));
    }

    function setVotingEscrow(address _votingEscrow) public override onlyTimelock {
        require(_votingEscrow != address(0), "Zero address");
        IERC20(rewardToken).safeApprove(votingEscrow, 0);
        votingEscrow = _votingEscrow;
        IERC20(rewardToken).safeApprove(votingEscrow, uint256(-1));
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public override onlyTimelock validatePid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    function getMultiplier(uint256 _from, uint256 _to) public view override returns (uint256) {
        return _to.sub(_from);
    }

    function pendingReward(address _user, uint256 _pid) public view override validatePid(_pid) returns (uint256) {
        PoolInfo storage info = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (cycleId == user.cid && rewarding && block.number > pool.lastRewardBlock && pool.totalSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number >= endBlock ? endBlock : block.number
            );
            uint256 reward = multiplier.mul(rewardPerBlock).mul(info.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(pool.totalSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt).add(user.earned);
    }

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override validatePid(_pid) {
        if (!rewarding) {
            return;
        }
        PoolInfo storage info = poolInfo[_pid];
        PoolStatus storage pool = poolSnapshot[cycleId][_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock ? endBlock : block.number;
        if (pool.totalSupply == 0 || info.allocPoint == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(info.allocPoint).div(totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(pool.totalSupply));
        pool.lastRewardBlock = lastRewardBlock;
    }

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) public override onlyRole(MASTER_ROLE) validatePid(_pid) nonReentrant {
        UserInfo storage user = userInfo[_pid][_account];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            user.earned = user.earned.add(pending);
        }

        if (cycleId == user.cid) {
            pool.totalSupply = pool.totalSupply.sub(user.amount).add(_amount);
            user.amount = _amount;
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        } else {
            pool = poolSnapshot[cycleId][_pid];
            pool.totalSupply = pool.totalSupply.add(_amount);
            user.amount = _amount;
            user.cid = cycleId;
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }
    }

    function start(uint256 _endBlock) public override onlyRole(MASTER_ROLE) nonReentrant {
        require(!rewarding, "cycle already active");
        require(_endBlock > block.number, "endBlock less");
        rewarding = true;
        endBlock = _endBlock;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolStatus storage pool = poolSnapshot[cycleId][i];
            pool.lastRewardBlock = block.number;
            pool.accRewardPerShare = 0;
        }
    }

    function next(uint256 _cid) public override onlyRole(MASTER_ROLE) nonReentrant {
        require(rewarding, "cycle not active");
        require(block.number >= endBlock, "cycle not expired");
        massUpdatePools();
        rewarding = false;
        cycleId = _cid;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            poolSnapshot[cycleId][i] = PoolStatus({totalSupply: 0, lastRewardBlock: 0, accRewardPerShare: 0});
        }
    }

    function _lockRewards(
        address _rewardBeneficiary,
        uint256 _rewardAmount,
        uint256 _lockDurationIfLockNotExists,
        uint256 _lockDurationIfLockExists
    ) internal {
        require(_rewardAmount > 0, "WTF Reward is zero");
        uint256 lockedAmountWTF = IVotingEscrow(votingEscrow).getLockedAmount(_rewardBeneficiary);

        // if no lock exists
        if (lockedAmountWTF == 0) {
            require(_lockDurationIfLockNotExists > 0, "Lock duration can't be zero");
            IVotingEscrow(votingEscrow).createLockFor(_rewardBeneficiary, _rewardAmount, _lockDurationIfLockNotExists);
        } else {
            // check if expired
            bool lockExpired = IVotingEscrow(votingEscrow).isLockExpired(_rewardBeneficiary);
            if (lockExpired) {
                require(_lockDurationIfLockExists > 0, "New lock expiry timestamp can't be zero");
            }
            IVotingEscrow(votingEscrow).increaseTimeAndAmountFor(
                _rewardBeneficiary,
                _rewardAmount,
                _lockDurationIfLockExists
            );
        }
    }

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfLockNotExists,
        uint256 _lockDurationIfLockExists
    ) public override nonReentrant {
        uint256 pending;
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];

        if (cycleId == user.cid) {
            updatePool(_pid);
        }

        pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (user.earned > 0) {
            pending = pending.add(user.earned);
            user.earned = 0;
        }
        if (pending > 0) {
            _lockRewards(msg.sender, pending, _lockDurationIfLockNotExists, _lockDurationIfLockExists);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
    }

    function claimAll(uint256 _lockDurationIfLockNotExists, uint256 _lockDurationIfLockExists)
        public
        override
        nonReentrant
    {
        uint256 pending = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PoolStatus storage pool = poolSnapshot[user.cid][i];
            if (cycleId == user.cid) {
                updatePool(i);
            }
            if (user.earned > 0) {
                pending = pending.add(user.earned);
                user.earned = 0;
            }
            pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt).add(pending);
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }

        if (pending > 0) {
            _lockRewards(msg.sender, pending, _lockDurationIfLockNotExists, _lockDurationIfLockExists);
        }
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 amount;
        if (_amount > balance) {
            amount = balance;
        } else {
            amount = _amount;
        }

        require(IERC20(rewardToken).transfer(_to, amount), "safeRewardTransfer: Transfer failed");
        return amount;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) public override onlyTimelock {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit UpdateEmissionRate(_rewardPerBlock);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IVotingEscrow {
    function createLock(uint256 _amount, uint256 duration) external;

    function createLockFor(
        address _account,
        uint256 _amount,
        uint256 _duration
    ) external;

    function getLockedAmount(address account) external view returns (uint256);

    function increaseLockDuration(uint256 _newExpiryTimestamp) external;

    function increaseLockDurationFor(address account, uint256 _newExpiryTimestamp) external;

    function increaseTimeAndAmount(uint256 _amount, uint256 _newExpiryTimestamp) external;

    function increaseTimeAndAmountFor(
        address _account,
        uint256 _amount,
        uint256 _newExpiryTimestamp
    ) external;

    function increaseAmount(uint256 _amount) external;

    function increaseAmountFor(address _account, uint256 _amount) external;

    function isLockExpired(address account) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract UniswapV2Router02 {
    using SafeERC20 for IERC20;
    address public currency;

    constructor(address _currency) public {
        currency = _currency;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        public
        returns (
            uint256[] memory amounts // uint256 deadline
        )
    {
        amounts = new uint256[](path.length);
        uint256 amountOut = amountIn;
        IERC20(currency).safeTransfer(to, amountOut);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        return amounts;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlpacaFake is ERC20 {
    using SafeERC20 for IERC20;

    uint256 gains;
    address underlying;
    address rewardToken;
    bool loss;

    constructor(
        address _underlying,
        address _rewardToken,
        uint256 _gains,
        bool _loss
    ) public ERC20("", "") {
        underlying = _underlying;
        rewardToken = _rewardToken;
        gains = _gains;
        loss = _loss;
    }

    function deposit(uint256 amount) public {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 redeemTokens) public {
        uint256 factor = loss ? (100 - gains) : (100 + gains);
        uint256 amount = (redeemTokens * factor) / 100;
        IERC20(underlying).safeTransfer(msg.sender, amount);
        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        _burn(msg.sender, redeemTokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Token is ERC20, Ownable {
    using SafeERC20 for ERC20;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(_amount > 0, "amount is 0");
        _mint(_to, _amount);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

contract Oracle is CoreRef {
    using SignedSafeMath for int256;

    struct Feed {
        address aggregator;
        uint8 baseDecimals;
    }
    // token address => Feed
    mapping(address => Feed) public feeds;

    constructor(
        address _core,
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) public CoreRef(_core) {
        _setFeeds(_tokens, _baseDecimals, _aggregators);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(address token) public view returns (int256 price) {
        Feed storage feed = feeds[token];
        require(feed.aggregator != address(0), "Oracle:: price feed does not exist");
        (, int256 price, , , ) = AggregatorV3Interface(feed.aggregator).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(feed.aggregator).decimals();
        uint8 baseDecimals = feed.baseDecimals;
        price = scalePrice(price, quoteDecimals, baseDecimals);
        return price;
    }

    function scalePrice(
        int256 _price,
        uint8 _quoteDecimals,
        uint8 _baseDecimals
    ) internal pure returns (int256) {
        if (_quoteDecimals < _baseDecimals) {
            return _price.mul(int256(10**uint256(_baseDecimals - _quoteDecimals)));
        } else if (_quoteDecimals > _baseDecimals) {
            return _price.div(int256(10**uint256(_quoteDecimals - _baseDecimals)));
        }
        return _price;
    }

    function setFeeds(
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) public onlyGovernor {
        _setFeeds(_tokens, _baseDecimals, _aggregators);
    }

    function _setFeeds(
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            feeds[_tokens[i]] = Feed(_aggregators[i], _baseDecimals[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}