/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IMetisToken.sol



pragma solidity 0.6.12;

interface IMetisToken {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address target, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
// File: contracts/interfaces/IMining.sol



pragma solidity 0.6.12;

interface IMining {
    function deposit(
        address _creator,
        address _user, 
        uint256 _pid, 
        uint256 _amount,
        uint256 _dacId
    ) external returns (bool);

    function withdraw(address _creator, uint256 _pid, uint256 _amount) external returns (bool);

    function dismissDAC(uint256 _dacId, uint256 _pid, address _creator) external returns (bool);

    function tokenToPid(address _token) external view returns (uint256);
}
// File: contracts/interfaces/IDAC.sol



pragma solidity 0.6.12;


interface IDAC {

    event CreatedDAC(address indexed creator, uint256 indexed dacId, bytes32 indexed invitationCode);

    event JoinedDAC(uint256 indexed dacId, address indexed member, bytes32 indexed invitationCode);

    event MemberLeaveDAC(address indexed creator, uint256 dacId, address indexed member);

    event DismissedDAC(address indexed creator, uint256 dacId);

    event IncreasedDeposit(uint256 indexed dacId, address indexed creator, address indexed member, uint256 amount);

    event UpdatedWhitelist(address indexed user, uint256 indexed amount);

    function createDAC(string memory name, string memory introduction, string memory category, string memory photo, uint256 amount) external returns(bool);

    function joinDAC(uint256 dacId, uint256 amount, bytes32 invitationCode) external returns(bool);

    function memberLeaveDAC(uint256 dacId, address member) external returns(bool);

    function dismissDAC(uint256 dacId, address creator) external returns(bool);

    function increaseDeposit(uint256 dacId, address to, uint256 amount) external returns(bool);
}

// File: @openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;





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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;


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
    uint256[49] private __gap;
}

// File: contracts/DAC.sol



pragma solidity 0.6.12;









contract DAC is IDAC, AccessControlUpgradeable, OwnableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 private ADMIN_ROLE;
    bytes32 private MINING_ROLE;
    bytes32 private WHITELIST_ROLE;
    bool public DAOOpening;
    IMetisToken public Metis;
    IMining public MiningContract;

    enum DACState{Dismissed, Active}

    struct DACInfo{
        uint256 id;
        address creator;
        string name;
        string introduction;
        string category;
        string photo;
        uint256 amount;
        uint256 createTime;
        DACState state;
    }

    DACInfo[] public pool;
    mapping(address => uint256) public whitelist;
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) relations;
    mapping(address => uint256) public userToDAC;
    mapping(bytes32 => uint256) public invitationCodeToDAC;
    mapping(uint256 => bytes32) public DACToInvitationCode;
    mapping(address => bool) public isInvitedUser;
    uint256 public DISMISS_LIMIT;
    uint256 public MIN_DEPOSIT;
    uint256 public MAX_DEPOSIT;
    bool public onlyInvitedUser;

    constructor () public{}

    function initialize(IMetisToken metis, IMining miningContract) initializer external {
        __AccessControl_init();
        __Ownable_init();
        Metis = metis;
        MiningContract = miningContract;
        DISMISS_LIMIT = 10;
        MIN_DEPOSIT = 10 * 1e18;
        MAX_DEPOSIT = 2000 * 1e18;
        onlyInvitedUser = true;
        ADMIN_ROLE = "admin";
        MINING_ROLE = "mining";
        WHITELIST_ROLE = "whitelist";
        _setupRole(ADMIN_ROLE, _msgSender());    // grant `ADMIN_ROLE` to owner
        // generate sentinelDAC
        pool.push(DACInfo(0, address(0), "", "", "", "", 0, 0, DACState.Dismissed));
    }

    /**
    * @dev create new DAC
    */
    function createDAC(string memory name, string memory introduction, string memory category, string memory photo, uint256 amount) public override returns(bool){
        if (onlyInvitedUser) {
            require(isInvitedUser[_msgSender()], "not invited");
        }
        require(!_userExist(_msgSender()), "user exist");
        require(!(amount < MIN_DEPOSIT || amount > MAX_DEPOSIT), "amount not allowed");
        require(Metis.allowance(_msgSender(), address(MiningContract)) >= amount, "Not enough allowance for mining contract");   // check balance
        // create new DAC
        _createNewDAC(_msgSender(), name, introduction, category, photo, amount);
        _deposit(address(0), _msgSender(), amount, pool.length - 1);    // deposit
        return true;
    }

    /**
    * @dev member join exist DAC
    */
    function joinDAC(uint256 dacId, uint256 amount, bytes32 invitationCode) public override onlyEffectiveDAC(dacId) onlyInvited(invitationCode, dacId) returns(bool) {
        require(!_userExist(_msgSender()), "user exist");
        require(Metis.allowance(_msgSender(), address(MiningContract)) >= amount, "Not enough allowance for mining contract");
        DACInfo memory dac = pool[dacId];
        // persistence
        relations[dacId].add(_msgSender());
        userToDAC[_msgSender()] = dacId;
        _deposit(dac.creator, _msgSender(), amount, dacId);
        emit JoinedDAC(dacId, _msgSender(), invitationCode);
        return true;
    }

    /**
    * @dev member left the DAC
    */
    function memberLeaveDAC(uint256 dacId, address member) public override onlyRole(MINING_ROLE) onlyCorrectlyMember(dacId, member) returns(bool) {
        relations[dacId].remove(member);    // remove relation
        DACInfo memory dac = pool[dacId];
        userToDAC[member] = 0;
        emit MemberLeaveDAC(dac.creator, dacId, member);
        return true;
    }

    function DAODismissDAC(uint256 dacId) external onlyEffectiveDAC(dacId) onlyCorrectlyCreator(dacId, msg.sender) returns(bool) {
        require(DAOOpening, "not allowed now");
        DACInfo storage dac = pool[dacId];
        dac.state = DACState.Dismissed;
        userToDAC[msg.sender] = 0;
        relations[dacId].remove(msg.sender);
        MiningContract.dismissDAC(dacId, 0, msg.sender);
        emit DismissedDAC(msg.sender, dacId);
        return true;
    }

    /**
    * @dev dismissed DAC
    */
    function dismissDAC(uint256 dacId, address creator) public override onlyRole(MINING_ROLE) onlyEffectiveDAC(dacId) onlyCorrectlyCreator(dacId, creator) returns(bool) {
        require(relations[dacId].length() <= DISMISS_LIMIT, "not allowed dismissed");   // member count <= 10
        DACInfo storage dac = pool[dacId];
        dac.state = DACState.Dismissed;
        userToDAC[creator] = 0;
        relations[dacId].remove(creator);
        // dac.dismissedTime = block.timestamp;   // error stack too deep
        emit DismissedDAC(creator, dacId);
        return true;
    }

    /**
    * @dev creator/member increase deposit  max_deposit=2000
    * `from` the user eth address
    * `to`  when creator increase deposit this param must be address(0).
    */
    function increaseDeposit(uint256 dacId, address to, uint256 amount) public override onlyEffectiveDAC(dacId) returns(bool){
        require(Metis.allowance(_msgSender(), address(MiningContract)) >= amount, "Not enough allowance for mining contract");  // check allowance
        _deposit(to, _msgSender(), amount, dacId);     // deposit
        emit IncreasedDeposit(dacId, to, _msgSender(), amount);
        return true;
    }

    /**
    * @dev get the DAC members count
    */
    function getDACMemberCount(uint256 dacId) public view returns(uint256) {

        return relations[dacId].length();
    }

    /**
    * @dev get the provided DAC members addresses
    */
    function getDACMembers(uint256 dacId) public view returns(address[] memory){
        address[] memory members = new address[](relations[dacId].length());
        for (uint i=0; i<relations[dacId].length(); i++) {
            members[i] = relations[dacId].at(i);
        }
        return members;
    }

    /**
    * @dev get all dac id
    */
    function getPoolLength() public view returns(uint256) {
        return pool.length;
    }

    // /**
    // * @dev update new MetisToken Contract
    // */
    // function setMetisToken(IMetisToken _metis) external onlyOwner {
    //     Metis = _metis;
    // }

    // /**
    // * @dev update new Mining Contract
    // */
    // function setMining(IMining _mining) external onlyOwner {
    //     MiningContract = _mining;
    // }

    /**
    * @dev update min deposit value
    */
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        MIN_DEPOSIT = _minDeposit;
    }

    /**
    * @dev update max deposit value
    */
    function setMaxDeposit(uint256 _maxDeposit) external onlyOwner {
        MAX_DEPOSIT = _maxDeposit;
    }

    function setDismissLimit(uint256 _dismissLimit) external onlyOwner {
        DISMISS_LIMIT = _dismissLimit;
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyOwner {
        _setRoleAdmin(role, adminRole);
    }

    function setDAOOpening(bool _open) external onlyOwner {
        DAOOpening = _open;
    }

    function setOnlyInvitedUser(bool _onlyInvitedUser) external onlyOwner {
        onlyInvitedUser = _onlyInvitedUser;
    }

    function addInvitedUsers(address[] memory _users) external onlyOwner {
        require(_users.length > 0, "zero array");
        for (uint256 index = 0; index < _users.length; index++) {
            isInvitedUser[_users[index]] = true;
        }
    }

    /**
    * @dev update the whitelist only specified role
    */
    function updateWhitelist(address user, uint256 amount) public onlyRole(WHITELIST_ROLE){
        require(!_userExist(user), "user exist");
        whitelist[user] = amount;
        emit UpdatedWhitelist(user, amount);
    }

    /**
    * @dev query initialPower
    */
    function queryInitialPower(address user) public view returns(uint256 initialPower) {
        if (whitelist[user] != 0){
            initialPower = whitelist[user];
        }else{
            initialPower = 80;
        }
    }

    /**
    * @dev create new DAC
    */
    function _createNewDAC(address creator, string memory name, string memory introduction, string memory category, string memory photo, uint256 amount) internal {
        bytes32 invitationCode = _generateInvitationCode(creator, pool.length);     // generate invitationCode
        DACInfo memory newDac = DACInfo(pool.length, creator, name, introduction, category, photo, amount, block.timestamp, DACState.Active);  // dac info
        pool.push(newDac);
        relations[newDac.id].add(creator);
        userToDAC[creator] = newDac.id;
        invitationCodeToDAC[invitationCode] = newDac.id;
        DACToInvitationCode[newDac.id] = invitationCode;
        emit CreatedDAC(creator, newDac.id, invitationCode);
    }

    /**
    * @dev deposit
    */
    function _deposit(address to, address from, uint256 amount, uint256 dacId) internal {
        require(MiningContract.deposit(to, from, MiningContract.tokenToPid(address(Metis)), amount, dacId), "deposit failed");    // deposit
    }

    /**
    * @dev generate invitation code
    */
    function _generateInvitationCode(address user, uint256 dacId) internal pure returns(bytes32 invitationCode){
        invitationCode = keccak256(abi.encodePacked(user, dacId));
    }

    /**
    * @dev if user exist return `true` else `false`
    */
    function _userExist(address user) public view returns(bool){
        // user not in any DAC || user already left DAC
        if (userToDAC[user] == 0) {
            return false;
        }
        // user was forceleft the DAC
        if (pool[userToDAC[user]].state == DACState.Dismissed){
            return false;
        }
        return true;
    }

    /**
    * @dev if user is the DAC's creator return `true` else `false`
    */
    function _isCreator(uint256 dacId, address creator) private view returns(bool){
        require(dacId < pool.length, "out of range");
        DACInfo memory dac = pool[dacId];
        if (dac.creator == creator) {
            return true;
        }else{
            return false;
        }
    }

    /**
    * @dev if user is the DAC's member return `true` else `false`
    */
    function _isMember(uint256 dacId, address member) private view returns(bool) {
        return relations[dacId].contains(member);
    }

    /**
    * Modifiers
    */
    modifier onlyCorrectlyCreator(uint256 _dacId, address _creator){
        require(_isCreator(_dacId, _creator), "DAC not found");
        _;
    }

    modifier onlyCorrectlyMember(uint256 _dacId, address _member){
        require(!_isCreator(_dacId, _member), "creator only dismiss DAC");
        require(_isMember(_dacId, _member), "member not found");
        _;
    }

    modifier onlyEffectiveDAC(uint256 _dacId){
        require(pool[_dacId].state == DACState.Active, "DAC Dismissed");
        _;
    }

    modifier onlyRole(bytes32 _role) {
        require(hasRole(_role, _msgSender()), "only specified role can call this function");
        _;
    }

    modifier onlyInvited(bytes32 invitationCode, uint256 dacId) {
        require(invitationCodeToDAC[invitationCode] == dacId, "invitationCode error");
        _;
    }

}