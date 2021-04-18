/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// Sources flattened with hardhat v2.2.0 https://hardhat.org

// File interfaces/IERC20.sol

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    // transfer and transferFrom intentionally missing, replaced with safeTransfers
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
// File interfaces/IMisoTokenFactory.sol

pragma solidity 0.6.12;

interface IMisoTokenFactory {
    function numberOfTokens() external view returns (uint256);
    function getTokens() external view returns (address[] memory);
}


// File contracts/OpenZeppelin/utils/EnumerableSet.sol

pragma solidity 0.6.12;

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


// File contracts/OpenZeppelin/utils/Address.sol

pragma solidity 0.6.12;

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


// File contracts/OpenZeppelin/utils/Context.sol

pragma solidity 0.6.12;

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


// File contracts/OpenZeppelin/access/AccessControl.sol

pragma solidity 0.6.12;



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


// File contracts/Access/MISOAdminAccess.sol

pragma solidity 0.6.12;

contract MISOAdminAccess is AccessControl {

    /// @dev Whether access is initialised.
    bool private initAccess;

    /// @notice Events for adding and removing various roles.
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );


    /// @notice The deployer is automatically given the admin role which will allow them to then grant roles to other addresses.
    constructor() public {
    }

    /**
     * @notice Initializes access controls.
     * @param _admin Admins address.
     */
    function initAccessControls(address _admin) public {
        require(!initAccess, "Already initialised");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        initAccess = true;
    }

    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the admin role.
     * @param _address EOA or contract being checked.
     * @return bool True if the account has the role or false if it does not.
     */
    function hasAdminRole(address _address) public  view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the admin role to an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract receiving the new role.
     */
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the admin role from an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract affected.
     */
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }
}


// File contracts/Access/MISOAccessControls.sol

pragma solidity 0.6.12;

/**
 * @notice Access Controls
 * @author Attr: BlockRocket.tech
 */
contract MISOAccessControls is MISOAdminAccess {
    /// @notice Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Events for adding and removing various roles

    event MinterRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event MinterRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event OperatorRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event OperatorRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    /**
     * @notice The deployer is automatically given the admin role which will allow them to then grant roles to other addresses
     */
    constructor() public {
    }


    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasMinterRole(address _address) public view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the smart contract role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasSmartContractRole(address _address) public view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the operator role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasOperatorRole(address _address) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the minter role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addMinterRole(address _address) external {
        grantRole(MINTER_ROLE, _address);
        emit MinterRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the minter role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeMinterRole(address _address) external {
        revokeRole(MINTER_ROLE, _address);
        emit MinterRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the smart contract role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addSmartContractRole(address _address) external {
        grantRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the smart contract role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeSmartContractRole(address _address) external {
        revokeRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the operator role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addOperatorRole(address _address) external {
        grantRole(OPERATOR_ROLE, _address);
        emit OperatorRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the operator role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeOperatorRole(address _address) external {
        revokeRole(OPERATOR_ROLE, _address);
        emit OperatorRoleRemoved(_address, _msgSender());
    }

}


// File contracts/Helper/MISOHelper.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



//==================
//    Uniswap       
//==================

interface IUniswapFactory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapPair {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
}

//==================
//    Documents       
//==================

interface IDocument {
    function getDocument(string calldata _name) external view returns (string memory, uint256);
    function getDocumentCount() external view returns (uint256);
    function getDocumentName(uint256 index) external view returns (string memory);    
}

contract DocumentHepler {
    struct Document {
        string name;
        string data;
        uint256 lastModified;
    }

    function getDocuments(address _document) public view returns(Document[] memory) {
        IDocument document = IDocument(_document);
        uint256 documentCount = document.getDocumentCount();

        Document[] memory documents = new Document[](documentCount);

        for(uint256 i = 0; i < documentCount; i++) {
            string memory documentName = document.getDocumentName(i);
            (
                documents[i].data,
                documents[i].lastModified
            ) = document.getDocument(documentName);
            documents[i].name = documentName;
        }
        return documents;
    }
}


//==================
//     Tokens
//==================

contract TokenHelper {
    struct TokenInfo {
        address addr;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getTokensInfo(address[] memory addresses) public view returns (TokenInfo[] memory)
    {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            infos[i] = getTokenInfo(addresses[i]);
        }

        return infos;
    }

    function getTokenInfo(address _address) public view returns (TokenInfo memory) {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.addr = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        // info.decimals = token.decimals();

        return info;
    }

    function allowance(address _token, address _owner, address _spender) public view returns(uint256) {
        return IERC20(_token).allowance(_owner, _spender);
    }

}


//==================
//      Base
//==================

contract BaseHelper {
    IMisoMarketFactory public market;
    IMisoTokenFactory public tokenFactory;
    IMisoFarmFactory public farmFactory;
    address public launcher;

    /// @notice Responsible for access rights to the contract
    MISOAccessControls public accessControls;

    function setContracts(
        address _tokenFactory,
        address _market,
        address _launcher,
        address _farmFactory
    ) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "MISOHelper: Sender must be Admin"
        );
        if (_market != address(0)) {
            market = IMisoMarketFactory(_market);
        }
        if (_tokenFactory != address(0)) {
            tokenFactory = IMisoTokenFactory(_tokenFactory);
        }
        if (_launcher != address(0)) {
            launcher = _launcher;
        }
        if (_farmFactory != address(0)) {
            farmFactory = IMisoFarmFactory(_farmFactory);
        }
    }
}


//==================
//      Farms       
//==================

interface IMisoFarmFactory {
    function getTemplateId(address _farm) external view returns(uint256);
    function numberOfFarms() external view returns(uint256);
    function farms(uint256 _farmId) external view returns(address);
}

interface IFarm {
    function poolInfo(uint256 pid) external view returns(
        address lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accRewardsPerShare
    );
    function rewards() external view returns(address);
    function poolLength() external view returns (uint256);
    function rewardsPerBlock() external view returns (uint256);
    function bonusMultiplier() external view returns (uint256);
    function userInfo(uint256 pid, address _user) external view returns (uint256, uint256);
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256);
}

contract FarmHelper is BaseHelper, TokenHelper {
    struct FarmInfo {
        address addr;
        uint256 templateId;
        uint256 rewardsPerBlock;
        uint256 bonusMultiplier;
        TokenInfo rewardTokenInfo;
        PoolInfo[] pools;
    }

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardsPerShare;
        // uint112 reserve0;
        // uint112 reserve1;
        uint256 totalStaked;
        // TokenInfo token0;
        // TokenInfo token1;
        TokenInfo rewardTokenInfo;
        UserPoolInfo userInfo;
    }

    struct UserPoolInfo {
        uint256 totalStaked;
        uint256 lpBalance;
        uint256 lpAllowance;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    function getPools(address _farm, address _user) public view returns(PoolInfo[] memory) {
        IFarm farm = IFarm(_farm);
        uint256 poolLength = farm.poolLength();
        PoolInfo[] memory pools = new PoolInfo[](poolLength);
        
        for(uint256 i = 0; i < poolLength; i++) {
            address lpToken;
            (
                lpToken,
                pools[i].allocPoint,
                pools[i].lastRewardBlock,
                pools[i].accRewardsPerShare
            ) = farm.poolInfo(i);
            // IUniswapPair pair = IUniswapPair(lpToken);
            // address token0 = pair.token0();
            // address token1 = pair.token1();
            // (pools[i].reserve0, pools[i].reserve1,) = pair.getReserves();
            // pools[i].token0 = getTokenInfo(token0);
            // pools[i].token1 = getTokenInfo(token1);
            pools[i].lpToken = lpToken;

            if(_user != address(0)) {
                UserPoolInfo memory userInfo;
                (userInfo.totalStaked, userInfo.rewardDebt) = farm.userInfo(i, _user);
                userInfo.lpBalance = IERC20(lpToken).balanceOf(_user);
                userInfo.lpAllowance = IERC20(lpToken).allowance(_user, _farm);
                userInfo.pendingRewards = farm.pendingRewards(i, _user);

                pools[i].userInfo = userInfo;
            }
        }
        return pools;
    }    


    function getFarms(address _user) public view returns(FarmInfo[] memory) {
        uint256 numberOfFarms = farmFactory.numberOfFarms();

        FarmInfo[] memory infos = new FarmInfo[](numberOfFarms);

        for (uint256 i = 0; i < numberOfFarms; i++) {
            address farmAddr = farmFactory.farms(i);
            uint256 templateId = farmFactory.getTemplateId(farmAddr);
            IFarm farm = IFarm(farmAddr);

            infos[i].addr = address(farm);
            infos[i].templateId = templateId;
            infos[i].rewardsPerBlock = farm.rewardsPerBlock();
            infos[i].bonusMultiplier = farm.bonusMultiplier();
            infos[i].rewardTokenInfo = getTokenInfo(farm.rewards());
            infos[i].rewardTokenInfo = getTokenInfo(farm.rewards());
            infos[i].pools = getPools(farmAddr, _user);
        }

        return infos;
    }

    function getUserPoolInfo(address _user, address _farm, uint256 _pid) public view returns(UserPoolInfo memory) {
        IFarm farm = IFarm(_farm);

        (address lpToken,,,) = farm.poolInfo(_pid);
        UserPoolInfo memory userInfo;

        (userInfo.totalStaked, userInfo.rewardDebt) = farm.userInfo(_pid, _user);
        userInfo.lpBalance = IERC20(lpToken).balanceOf(_user);
        userInfo.lpAllowance = IERC20(lpToken).allowance(_user, _farm);
        userInfo.pendingRewards = farm.pendingRewards(_pid, _user);

        return userInfo;
    }
}

//==================
//     Markets       
//==================

interface IBaseAuction {
    function getBaseInformation() external view returns (
            address auctionToken,
            uint64 startTime,
            uint64 endTime,
            bool finalized
        );
}

interface IMisoMarketFactory {
    function getMarketTemplateId(address _auction) external view returns(uint64);
    function getMarkets() external view returns(address[] memory);
}

interface IMisoMarket {
    function paymentCurrency() external view returns (address) ;
    function auctionToken() external view returns (address) ;
    function marketPrice() external view returns (uint128, uint128);
    function marketInfo()
        external
        view
        returns (
        uint64 startTime,
        uint64 endTime,
        uint128 totalTokens
        );
    function auctionSuccessful() external view returns (bool);
    function commitments(address user) external view returns (uint256);
    function claimed(address user) external view returns (uint256);
    function tokensClaimable(address user) external view returns (uint256);
    function hasAdminRole(address user) external view returns (bool);
}

interface ICrowdsale is IMisoMarket {
    function marketStatus() external view returns(
        uint128 commitmentsTotal,
        bool finalized,
        bool usePointList
    );
}

interface IDutchAuction is IMisoMarket {
    function marketStatus() external view returns(
        uint128 commitmentsTotal,
        bool finalized,
        bool usePointList
    );
    // function totalTokensCommitted() external view returns (uint256);
    // function clearingPrice() external view returns (uint256);
}

interface IBatchAuction is IMisoMarket {
    function marketStatus() external view returns(
        uint256 commitmentsTotal,
        uint256 minimumCommitmentAmount,
        bool finalized,
        bool usePointList
    );
}

interface IHyperbolicAuction is IMisoMarket {
    function marketStatus() external view returns(
        uint128 commitmentsTotal,
        bool finalized,
        bool usePointList
    );
}

contract MarketHelper is BaseHelper, TokenHelper, DocumentHepler {

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct CrowdsaleInfo {
        address addr;
        address paymentCurrency;
        uint128 commitmentsTotal;
        uint128 totalTokens;
        uint128 rate;
        uint128 goal;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct DutchAuctionInfo {
        address addr;
        address paymentCurrency;
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
        uint128 startPrice;
        uint128 minimumPrice;
        uint128 commitmentsTotal;
        // uint256 totalTokensCommitted;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct BatchAuctionInfo {
        address addr;
        address paymentCurrency;
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
        uint256 commitmentsTotal;
        uint256 minimumCommitmentAmount;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct HyperbolicAuctionInfo {
        address addr;
        address paymentCurrency;
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
        uint128 minimumPrice;
        uint128 alpha;
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct MarketBaseInfo {
        address addr;
        uint64 templateId;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        TokenInfo tokenInfo;
    }

    struct PLInfo {
        TokenInfo token0;
        TokenInfo token1;
        address pairToken;
        address operator;
        uint256 locktime;
        uint256 unlock;
        uint256 deadline;
        uint256 launchwindow;
        uint256 expiry;
        uint256 liquidityAdded;
        uint256 launched;
    }

    struct UserMarketInfo {
        uint256 commitments;
        uint256 tokensClaimable;
        uint256 claimed;
        bool isAdmin;
    }

    function getMarkets() public view returns (MarketBaseInfo[] memory) {
        address[] memory markets = market.getMarkets();
        MarketBaseInfo[] memory infos = new MarketBaseInfo[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            
            uint64 templateId = market.getMarketTemplateId(markets[i]);
            address auctionToken;
            uint64 startTime;
            uint64 endTime;
            bool finalized;
            (auctionToken, startTime, endTime, finalized) = IBaseAuction(markets[i])
                .getBaseInformation();
            TokenInfo memory tokenInfo = getTokenInfo(auctionToken);

            infos[i].addr = markets[i];
            infos[i].templateId = templateId;
            infos[i].startTime = startTime;
            infos[i].endTime = endTime;
            infos[i].finalized = finalized;
            infos[i].tokenInfo = tokenInfo;
        }

        return infos;
    }

    function getCrowdsaleInfo(address _crowdsale) public view returns (CrowdsaleInfo memory) {
        ICrowdsale crowdsale = ICrowdsale(_crowdsale);
        CrowdsaleInfo memory info;

        info.addr = address(crowdsale);
        info.paymentCurrency = crowdsale.paymentCurrency();
        (info.commitmentsTotal, info.finalized, info.usePointList) = crowdsale.marketStatus();
        (info.startTime, info.endTime, info.totalTokens) = crowdsale.marketInfo();
        (info.rate, info.goal) = crowdsale.marketPrice();
        (info.auctionSuccessful) = crowdsale.auctionSuccessful();
        info.tokenInfo = getTokenInfo(crowdsale.auctionToken());

        address paymentCurrency = crowdsale.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if(paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;

        info.documents = getDocuments(_crowdsale);

        return info;
    }

    function getDutchAuctionInfo(address payable _dutchAuction) public view returns (DutchAuctionInfo memory)
    {
        IDutchAuction dutchAuction = IDutchAuction(_dutchAuction);
        DutchAuctionInfo memory info;

        info.addr = address(dutchAuction);
        // info.paymentCurrency = dutchAuction.paymentCurrency();
        (info.startTime, info.endTime, info.totalTokens) = dutchAuction.marketInfo();
        (info.startPrice, info.minimumPrice) = dutchAuction.marketPrice();
        (info.auctionSuccessful) = dutchAuction.auctionSuccessful();
        (
            info.commitmentsTotal,
            info.finalized,
            info.usePointList
        ) = dutchAuction.marketStatus();
        info.tokenInfo = getTokenInfo(dutchAuction.auctionToken());

        address paymentCurrency = dutchAuction.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if(paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;
        info.documents = getDocuments(_dutchAuction);

        return info;
    }

    function getBatchAuctionInfo(address payable _batchAuction) public view returns (BatchAuctionInfo memory) 
    {
        IBatchAuction batchAuction = IBatchAuction(_batchAuction);
        BatchAuctionInfo memory info;
        
        info.addr = address(batchAuction);
        info.paymentCurrency = batchAuction.paymentCurrency();
        (info.startTime, info.endTime, info.totalTokens) = batchAuction.marketInfo();
        (
            info.commitmentsTotal,
            info.minimumCommitmentAmount,
            info.finalized,
            info.usePointList
        ) = batchAuction.marketStatus();
        info.tokenInfo = getTokenInfo(batchAuction.auctionToken());
        address paymentCurrency = batchAuction.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if(paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;
        info.documents = getDocuments(_batchAuction);

        return info;
    }

    function getHyperbolicAuctionInfo(address payable _hyperbolicAuction) public view returns (HyperbolicAuctionInfo memory)
    {
        IHyperbolicAuction hyperbolicAuction = IHyperbolicAuction(_hyperbolicAuction);
        HyperbolicAuctionInfo memory info;

        info.addr = address(hyperbolicAuction);
        info.paymentCurrency = hyperbolicAuction.paymentCurrency();
        (info.startTime, info.endTime, info.totalTokens) = hyperbolicAuction.marketInfo();
        (info.minimumPrice, info.alpha) = hyperbolicAuction.marketPrice();
        (info.auctionSuccessful) = hyperbolicAuction.auctionSuccessful();
        (
            info.commitmentsTotal,
            info.finalized,
            info.usePointList
        ) = hyperbolicAuction.marketStatus();
        info.tokenInfo = getTokenInfo(hyperbolicAuction.auctionToken());
        
        address paymentCurrency = hyperbolicAuction.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if(paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;
        info.documents = getDocuments(_hyperbolicAuction);

        return info;
    }

    function getUserMarketInfo(address _action, address _user) public view returns(UserMarketInfo memory userInfo) {
        IMisoMarket market = IMisoMarket(_action);
        userInfo.commitments = market.commitments(_user);
        userInfo.tokensClaimable = market.tokensClaimable(_user);
        userInfo.claimed = market.claimed(_user);
        userInfo.isAdmin = market.hasAdminRole(_user);
    }

    function _getETHInfo() private pure returns(TokenInfo memory token) {
            token.addr = ETH_ADDRESS;
            token.name = "ETHEREUM";
            token.symbol = "ETH";
            token.decimals = 18;
    }

}

contract MISOHelper is MarketHelper, FarmHelper {

    constructor(
        address _accessControls,
        address _tokenFactory,
        address _market,
        address _launcher,
        address _farmFactory
    ) public { 
        require(_accessControls != address(0));
        accessControls = MISOAccessControls(_accessControls);
        tokenFactory = IMisoTokenFactory(_tokenFactory);
        market = IMisoMarketFactory(_market);
        launcher = _launcher;
        farmFactory = IMisoFarmFactory(_farmFactory);
    }

    function getTokens() public view returns(TokenInfo[] memory) {
        address[] memory tokens = tokenFactory.getTokens();
        TokenInfo[] memory infos = getTokensInfo(tokens);

        infos = getTokensInfo(tokens);

        return infos;
    }

}