/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// File: contracts/MoverValorYearnUSDCv2Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

///////////////////////////////////////////////////////////////////////////
//     __/|      
//  __////  /|   This smart contract is part of Mover infrastructure
// |// //_///    https://viamover.com
//    |_/ //     [email protected]
//       |/
///////////////////////////////////////////////////////////////////////////

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
library EnumerableSetUpgradeable {
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


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
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
    uint256[49] private __gap;
}


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


// Interface to represent asset pool interactions
interface IHolyValor {
    // safe amount of funds in base asset (USDC) that is possible to reclaim from this HolyValor without fee/penalty
    function safeReclaimAmount() external view returns(uint256);
    // total amount of funds in base asset (USDC) that is possible to reclaim from this HolyValor
    function totalReclaimAmount() external view returns(uint256);
    // callable only by a HolyPool, retrieve a portion of invested funds, return (just in case) amount transferred
    function reclaimFunds(uint256 amount, bool _safeExecution) external returns(uint256);
}


// Interface to represent asset pool interactions
interface IHolyPool {
    function getBaseAsset() external view returns(address);

    // functions callable by HolyHand transfer proxy
    function depositOnBehalf(address beneficiary, uint256 amount) external;
    function withdraw(address beneficiary, uint256 amount) external;

    // functions callable by HolyValor investment proxies
    // pool would transfer funds to HolyValor (returns actual amount, could be less than asked)
    function borrowToInvest(uint256 amount) external returns(uint256);
    // return invested body portion from HolyValor (pool will claim base assets from caller Valor)
    function returnInvested(uint256 amountCapitalBody) external;

    // functions callable by HolyRedeemer yield distributor
    function harvestYield(uint256 amount) external; // pool would transfer amount tokens from caller as it's profits
}


// Interface to yearn.finance USDC v2 vault
interface IYearnVaultUSDCv2 {
    // returns base asset address (USDC)
    function token() external view returns (address);

    // returns price of 1 lpToken (share) in amount of base asset (USDC)
    function pricePerShare() external view returns (uint);

    // available deposit limit for the vault
    function availableDepositLimit() external view returns (uint);

    // deposit USDC and receive lpTokens (shares)
    //    Measuring quantity of shares to issues is based on the total
    //    outstanding debt that this contract has ("expected value") instead
    //    of the total balance sheet it has ("estimated value") has important
    //    security considerations, and is done intentionally. If this value were
    //    measured against external systems, it could be purposely manipulated by
    //    an attacker to withdraw more assets than they otherwise should be able
    //    to claim by redeeming their shares.
    //
    //    On deposit, this means that shares are issued against the total amount
    //    that the deposited capital can be given in service of the debt that
    //    Strategies assume. If that number were to be lower than the "expected
    //    value" at some future point, depositing shares via this method could
    //    entitle the depositor to *less* than the deposited value once the
    //    "realized value" is updated from further reports by the Strategies
    //    to the Vaults.
    //
    //    Care should be taken by integrators to account for this discrepancy,
    //    by using the view-only methods of this contract (both off-chain and
    //    on-chain) to determine if depositing into the Vault is a "good idea".
    //  returns quantity of shares issued for _amount
    function deposit(uint _amount, address _recipient) external returns (uint);

    // withdraw amount of shares and return USDC
    //  maxloss is maximum loss in bps (1 = 0.01%)
    //  returns quantity of tokens redeemed for _shares.
    function withdraw(uint _shares, address _recipient, uint _maxloss) external returns (uint);

    // total base asset amount in the vault or under strategies
    function totalAssets() external view returns (uint);
}


/*
    MoverValor is an investment proxy, that is able to get a portion of funds from a Mover pool
    and allocate it in some yield-generating contract. Also acts as a trigger point for
    yield harvest, updating pool status and balancing pool allocation amount. 
    (the balancing and depositing could be made by the pool itself though)
    
    one important assumption for things to work properly: 
        LP tokens granted by pool DO NOT DECREASE IN UNDERLYING ASSET VALUE
        otherwise the handling of such scenarios must be done manually

    NOTE: MoverValorYearnUSDCv2Vault is not inherited from some kind of base Valor contract
          to keep all code in one page and have everything implemented explicitly.

    MoverValor has no allowance to get funds from MoverPool directly, only through investInVault method
*/
contract MoverValorYearnUSDCv2Vault is AccessControlUpgradeable, IHolyValor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant ALLOWANCE_SIZE = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant lpPrecision = 1e3;  // treshold to treat quantities (baseAsset, lpTokens) as equal (USDC has 6 decimals only)

    // role that grants most of financial operations for MoverValor
    bytes32 public constant FINMGMT_ROLE = keccak256("FINMGMT_ROLE");

    // emergency transfer (timelocked) variables and events
    address private emergencyTransferToken;
    address private emergencyTransferDestination;
    uint256 private emergencyTransferTimestamp;
    uint256 private emergencyTransferAmount;
    event EmergencyTransferSet(address indexed token, address indexed destination, uint256 amount);
    event EmergencyTransferExecute(address indexed token, address indexed destination, uint256 amount);

    // common MoverValor properties
    IERC20 public baseAsset;         // USDC
    IHolyPool public moverPool;      // Mover Pool address
    address public yieldDistributor; // MoverRedeemer address

    uint256 public amountInvested;   // baseAsset amount that is invested in vault
    uint256 public lpTokensBalance;  // must match lp tokens (vault ERC20) balance of this address

    event FundsInvested(uint256 amountRequested, uint256 amountActual, uint256 lpTokensReceived, uint256 lpTokensBalance);
    event FundsDivested(uint256 lpWithdrawn, uint256 baseAssetExpected, uint256 baseAssetReceived, uint256 lpTokensBalance);
    event HarvestYield(uint256 lpWithdrawn, uint256 baseAssetExpected, uint256 baseAssetReceived, uint256 lpTokensBalance);
    event WithdrawReclaim(uint256 lpWithdrawn, uint256 baseAssetExpected, uint256 baseAssetReceived, uint256 lpTokensBalance);

    // particular MoverValor-related variables
    IYearnVaultUSDCv2 public vaultContract; // yearn USDC vault
    uint256 public inceptionLPPriceUSDC;  // price of share (vault LP token) when Valor was constructed
    uint256 public inceptionTimestamp;    // inception timestamp

    function initialize(address _baseAsset, address _vaultAddress, address _poolAddress) public initializer {
	    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FINMGMT_ROLE, _msgSender());

        baseAsset = IERC20(_baseAsset); // USDC
        
        vaultContract = IYearnVaultUSDCv2(_vaultAddress); // yearn yUSDC vault
        inceptionLPPriceUSDC = vaultContract.pricePerShare();
        inceptionTimestamp = block.timestamp;

        connectPool(_poolAddress);

        amountInvested = 0;
        lpTokensBalance = 0;
    }

    // sets pool address and grants allowance to pool
    function connectPool(address _poolAddress) internal {
        moverPool = IHolyPool(_poolAddress);
        baseAsset.approve(_poolAddress, ALLOWANCE_SIZE);
    }

    // callable by admin to set pool for MoverValor
    // should not be called if this contract holds invested funds
    function setPool(address _poolAddress) public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin only");
        connectPool(_poolAddress);
    }

    // to save gas costs during withdrawals, etc, yield harvested (and it should be only yield)
    // is stored on this contract balance. Yield distributor contract should have permission
    // to get baseAsset tokens from this contract
    function setYieldDistributor(address _distributorAddress) public {
	    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin only");
        yieldDistributor = _distributorAddress;
        // only yield to be redistributed should be present on this contract in baseAsset
        // so no access to lp tokens for the funds invested
        baseAsset.approve(_distributorAddress, ALLOWANCE_SIZE);
    }

    // functions to get/put back funds to Mover Pool (and invest/divest to Yearn.Finance USDC v2 Vault)

    // callable only by Finmgmt and perform invest/divest of Mover Pool funds
    function investInVault(uint256 _amount, uint256 _minimumAmount) public {
        require(hasRole(FINMGMT_ROLE, msg.sender), "Finmgmt only");
        
        // get available funds from Mover Pool and allocate them in vault
        // pool can give less funds than asked to comply with its reserveTarget
        // (even may have not any free funds available)
        uint256 amountBefore = baseAsset.balanceOf(address(this));
        uint256 amountReceived = moverPool.borrowToInvest(_amount);
        uint256 amountAfter = baseAsset.balanceOf(address(this));
        require(amountReceived == amountAfter.sub(amountBefore), "reported/actual amount mismatch");
        require(amountReceived >= _minimumAmount, "minimum amount not available");

        // approve (if required) vault to perform deposit
        if(baseAsset.allowance(address(this), address(vaultContract)) < amountReceived) {
            baseAsset.approve(address(vaultContract), ALLOWANCE_SIZE);
        }

        // NOTE: the amount of lpTokens received for known amount could be used for on-chain APY calculation
        uint256 lpTokensBefore = IERC20(address(vaultContract)).balanceOf(address(this));
        vaultContract.deposit(amountReceived, address(this));
        uint256 lpTokensAfter = IERC20(address(vaultContract)).balanceOf(address(this));
        uint256 lpReceived = lpTokensAfter.sub(lpTokensBefore);
        require(lpReceived > 0, "lp tokens not received");

        // increase amounts of lp tokens and baseAsset deposited
        lpTokensBalance = lpTokensBalance.add(lpReceived);
        amountInvested = amountInvested.add(amountReceived);

        emit FundsInvested(_amount, amountReceived, lpReceived, lpTokensBalance);
    }

    // divest funds from vault
    // callable only by Finmgmt to return assets to Mover Pool
    // decreases the body of funds, and can realize yield when called
    // if amount is higher than safeDivestAmount, withdraw penalty would be applied to funds received back from Vault
    // amount is base asset quantity (USDC)
    // safeexecution if true, reverts when vault has insufficient base asset balance
    //               if false, vault would get funds from strategy, applying withdrawal fee
    // we don't fallback to available safe amount, because it can be low, this method should be called
    // by automated backend, and better to revert cheaply and reassess decision
    function divestFromVault(uint256 _amount, bool _safeExecution) public {
        require(hasRole(FINMGMT_ROLE, msg.sender), "Finmgmt only");

        uint256 safeWithdrawAmountUSDC = IERC20(vaultContract.token()).balanceOf(address(vaultContract));
        if (_safeExecution && _amount > safeWithdrawAmountUSDC) {
            revert("insufficient safe withdraw balance");
        }

        // this is 1e18 fixed-point number
        uint256 lpPriceUSDC = vaultContract.pricePerShare();

        // calculate amount of lpTokens to withdraw
        uint256 lpTokensToWithdraw = _amount.mul(1e18).div(lpPriceUSDC);
        
        if (lpTokensToWithdraw > IERC20(address(vaultContract)).balanceOf(address(this))) {
            revert("insufficient lp tokens");
        }

        // provide allowance for vault to burn lp tokens
        if (IERC20(address(vaultContract)).allowance(address(this), address(vaultContract)) < lpTokensToWithdraw) {
            IERC20(address(vaultContract)).approve(address(vaultContract), ALLOWANCE_SIZE);
        }

        uint256 baseAssetTokensBefore = baseAsset.balanceOf(address(this));
        vaultContract.withdraw(lpTokensToWithdraw, address(this), 50); // allow 50 bps (0.5%) of fees to occur
        uint256 baseAssetTokensAfter = baseAsset.balanceOf(address(this));
        uint256 USDCReceived = baseAssetTokensAfter.sub(baseAssetTokensBefore);
        // update number of lpTokens
        lpTokensBalance = lpTokensBalance.sub(lpTokensToWithdraw);

        // we are withdrawing the invested funds body portion (divesting)
        // so the calculated amount of lpTokens should match the target amount of USDC
        //   USDCReceived matches amount (could be tiny difference in least significant digits)
        //   negative outcome (unexpected) -- withdraw amount less than calculated
        //   (should occur only when safeExecution == false for emergency withdrawals)

        // transfer USDC received back to pool and decrease amountInvested
        moverPool.returnInvested(USDCReceived);

        // even if vault returnes less, decrease on the requested withdraw amount
        amountInvested = amountInvested.sub(_amount);

        emit FundsDivested(lpTokensToWithdraw, _amount, USDCReceived, lpTokensBalance);
    }

    // reclaimFunds method
    // callable only by Mover Pool (if additional funds needed during withdrawal request)
    // if amount retrieved is less than expected then withdraw penalty had occured.
    // there are 2 possible outcomes:
    // - amount of baseAsset received is exactly matching requested amount (excluding some lesser digits due to arithmetics);
    // - amount of baseAsset received is less than requested, withdraw penatly was applied by Vault;
    function reclaimFunds(uint256 _amount, bool _safeExecution) external override returns(uint256) {
        require(msg.sender == address(moverPool), "Pool only");

        uint256 safeWithdrawAmountUSDC = IERC20(vaultContract.token()).balanceOf(address(vaultContract));
        if (_safeExecution && _amount > safeWithdrawAmountUSDC) {
            revert("insufficient safe withdraw balance");
        }

        // this is 1e18 fixed-point number
        uint256 lpPriceUSDC = vaultContract.pricePerShare();

        // calculate amount of lpTokens to withdraw
        uint256 lpTokensToWithdraw = _amount.mul(1e18).div(lpPriceUSDC);
        
        // provide allowance for vault to burn lp tokens
        if (IERC20(address(vaultContract)).allowance(address(this), address(vaultContract)) < lpTokensToWithdraw) {
            IERC20(address(vaultContract)).approve(address(vaultContract), ALLOWANCE_SIZE);
        }

        uint256 baseAssetTokensBefore = baseAsset.balanceOf(address(this));
        vaultContract.withdraw(lpTokensToWithdraw, address(this), 50);
        uint256 baseAssetTokensAfter = baseAsset.balanceOf(address(this));
        uint256 USDCReceived = baseAssetTokensAfter.sub(baseAssetTokensBefore);
        // update number of lpTokens
        lpTokensBalance = lpTokensBalance.sub(lpTokensToWithdraw);

        // we are withdrawing the invested funds body portion for a withdrawal
        // so the calculated amount of lpTokens should match the target amount of USDC to receive
        // therefore, no yield is realized or other addresses balances affected in pool
        // two outcomes:
        //   USDCReceived matches amount (could be tiny difference in least significant digits)
        //   negative outcome (unexpected) -- withdraw amount less than calculated

        // transfer USDC received back to pool and decrease amountInvested
        baseAsset.transfer(address(moverPool), USDCReceived);

        // even if vault returnes less, decrease on the requested withdraw amount
        amountInvested = amountInvested.sub(_amount);

        emit WithdrawReclaim(lpTokensToWithdraw, _amount, USDCReceived, lpTokensBalance);

        return USDCReceived;
    }

    // harvest yield method
    // the goal of this method is to get baseAsset that:
    // - could be safely divested from Vault with zero loss;
    // - the resulting balance of current lpTokens price could not be below amountInvested;
    // - yield would reside on this Valor balance to be distributed byolyRedeemer
    //   to increase user balances on pool (and fulfill pool reserve), fulfill treasury and fund operations
    //   (yield asset claim strategy is not in the scope of this contract)
    // thus should not decreate invested funds body (amountInvested quantity of baseAsset)
    // for vaults v2 we can try to withdraw specifying 0 bps max loss
    function harvestYield(uint256 minExpectedAmount, uint256 maxAmount) public {
        require(hasRole(FINMGMT_ROLE, msg.sender), "Finmgmt only");

        // this is 1e18 fixed-point number
        uint256 lpPriceUSDC = vaultContract.pricePerShare();

        // calculate amount that won't decrease invested baseAsset amount
        // if calculation underflows, this is bad (vault shows negative return)
        uint256 accruedYieldUSDC = lpTokensBalance.mul(lpPriceUSDC).div(1e18).sub(amountInvested);
        require(accruedYieldUSDC >= minExpectedAmount, "yield to harvest less than min");
        
        // cap to maxAmount if applicable
        if (accruedYieldUSDC > maxAmount) {
            accruedYieldUSDC = maxAmount;
        }

        // calculate amount of lpTokens to withdraw
        uint256 lpTokensToWithdraw = accruedYieldUSDC.mul(1e18).div(lpPriceUSDC);

        // provide allowance for vault to burn lp tokens
        if (IERC20(address(vaultContract)).allowance(address(this), address(vaultContract)) < lpTokensToWithdraw) {
            IERC20(address(vaultContract)).approve(address(vaultContract), ALLOWANCE_SIZE);
        }

        uint256 baseAssetTokensBefore = baseAsset.balanceOf(address(this));
        vaultContract.withdraw(lpTokensToWithdraw, address(this), 0);
        uint256 baseAssetTokensAfter = baseAsset.balanceOf(address(this));
        uint256 USDCReceived = baseAssetTokensAfter.sub(baseAssetTokensBefore);
        // update number of lpTokens
        lpTokensBalance = lpTokensBalance.sub(lpTokensToWithdraw);

        // the received base asset USDC tokens reside on this contract until yield distributor picks them

        emit HarvestYield(lpTokensToWithdraw, accruedYieldUSDC, USDCReceived, lpTokensBalance);
        // good outcome -- accruedYieldUSDC matches USDCReceived (could be tiny difference in least significant digits)
        // negative outcome (unexpected) -- withdraw amount less than calculated
    }

    // get safe amount of funds in base asset (USDC) that is possible to reclaim from this MoverValor without fee/penalty
    function safeReclaimAmount() external override view returns(uint256) {
        // as we (and vault) recalculate shares/base asset amounts with high, but not unlimited precision, we
        // pessimize safe amount by a tiny margin (this does not affect accounts, it's to be sure
        // vault would be able to provide base asset to lp shares quantity without external fee)
        uint256 safeAmount = IERC20(vaultContract.token()).balanceOf(address(vaultContract));
        if (safeAmount >= lpPrecision) {
            return safeAmount.sub(lpPrecision);
        }
        return 0; // safe amount is so tiny, we assume 0
    }

    function totalReclaimAmount() external override view returns(uint256) {
        return amountInvested;
    }

    // get current net asset value measured in baseAsset of Mover Valor (USDC)
    // NOTE: this includes unharvested yield and should not be used for reclaim calculations
    function getAssetsUnderManagement() public view returns(uint256) {
        // this is 1e18 fixed-point number
        uint256 lpPriceUSDC = vaultContract.pricePerShare();

        return lpTokensBalance.mul(lpPriceUSDC).div(1e18);
    }

    // simple APY getter (share price increase since inception of this contract)
    function getAPYInception() public view returns(uint256) {
        // this is 1e18 fixed-point number
        uint256 lpPriceUSDC = vaultContract.pricePerShare();

        return lpPriceUSDC.mul(1e18).div(inceptionLPPriceUSDC);
    }

    // emergencyTransferTimelockSet is for safety (if some tokens got stuck)
    // timelock applied because this contract holds lp tokens for invested funds
    // in the future it could be removed, to restrict access to user funds
    // this is timelocked as contract can have user funds
	function emergencyTransferTimelockSet(address _token, address _destination, uint256 _amount) public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin only");
        emergencyTransferTimestamp = block.timestamp;
        emergencyTransferToken = _token;
        emergencyTransferDestination = _destination;
        emergencyTransferAmount = _amount;

        emit EmergencyTransferSet(_token, _destination, _amount);
	}

	function emergencyTransferExecute() public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin only");
        require(block.timestamp > emergencyTransferTimestamp + 24 * 3600, "timelock too early");
        require(block.timestamp < emergencyTransferTimestamp + 72 * 3600, "timelock too late");

        IERC20(emergencyTransferToken).safeTransfer(emergencyTransferDestination, emergencyTransferAmount);

        emit EmergencyTransferExecute(emergencyTransferToken, emergencyTransferDestination, emergencyTransferAmount);
        // clear emergency transfer timelock data
        emergencyTransferTimestamp = 0;
        emergencyTransferToken = address(0);
        emergencyTransferDestination = address(0);
        emergencyTransferAmount = 0;
    }
}