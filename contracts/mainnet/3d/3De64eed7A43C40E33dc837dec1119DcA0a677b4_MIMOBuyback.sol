// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessController is AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
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

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
  address public immutable override token;
  bytes32 public immutable override merkleRoot;
  uint256 public immutable override endTime;

  // This is a packed array of booleans.
  mapping(uint256 => uint256) private _claimedBitMap;

  constructor(
    address _token,
    bytes32 _merkleRoot,
    uint256 _endTime
  ) public {
    token = _token;
    merkleRoot = _merkleRoot;
    require(block.timestamp < _endTime, "Invalid endTime");
    endTime = _endTime;
  }

  /** @dev Modifier to check that claim period is active.*/
  modifier whenActive() {
    require(isActive(), "Claim period has ended");
    _;
  }

  function claim(
    uint256 _index,
    address _account,
    uint256 _amount,
    bytes32[] calldata merkleProof
  ) external override whenActive {
    require(!isClaimed(_index), "Drop already claimed");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it claimed and send the token.
    _setClaimed(_index);
    require(IERC20(token).transfer(_account, _amount), "Transfer failed");

    emit Claimed(_index, _account, _amount);
  }

  function isClaimed(uint256 _index) public view override returns (bool) {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    uint256 claimedWord = _claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function isActive() public view override returns (bool) {
    return block.timestamp < endTime;
  }

  function recoverERC20(address _tokenAddress, uint256 _tokenAmount) public onlyOwner {
    IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
  }

  function _setClaimed(uint256 _index) private {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    _claimedBitMap[claimedWordIndex] = _claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }
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
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
  // This event is triggered whenever a call to #claim succeeds.
  event Claimed(uint256 index, address account, uint256 amount);

  // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  // Returns the address of the token distributed by this contract.
  function token() external view returns (address);

  // Returns the merkle root of the merkle tree containing account balances available to claim.
  function merkleRoot() external view returns (bytes32);

  // Returns true if the index has been marked claimed.
  function isClaimed(uint256 index) external view returns (bool);

  // Returns the block timestamp when claims will end
  function endTime() external view returns (uint256);

  // Returns true if the claim period has not ended.
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libraries/WadRayMath.sol";
import "./interfaces/IVaultsCoreV1.sol";
import "./interfaces/ILiquidationManagerV1.sol";
import "./interfaces/IAddressProviderV1.sol";

contract VaultsCoreV1 is IVaultsCoreV1, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 public constant MAX_INT = 2**256 - 1;

  mapping(address => uint256) public override cumulativeRates;
  mapping(address => uint256) public override lastRefresh;

  IAddressProviderV1 public override a;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender));
    _;
  }

  modifier onlyVaultOwner(uint256 _vaultId) {
    require(a.vaultsData().vaultOwner(_vaultId) == msg.sender);
    _;
  }

  modifier onlyConfig() {
    require(msg.sender == address(a.config()));
    _;
  }

  constructor(IAddressProviderV1 _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /*
    Allow smooth upgrading of the vaultscore.
    @dev this function approves token transfers to the new vaultscore of
    both stablex and all configured collateral types
    @param _newVaultsCore address of the new vaultscore
  */
  function upgrade(address _newVaultsCore) public override onlyManager {
    require(address(_newVaultsCore) != address(0));
    require(a.stablex().approve(_newVaultsCore, MAX_INT));

    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      IERC20 asset = IERC20(collateralType);
      asset.safeApprove(_newVaultsCore, MAX_INT);
    }
  }

  /**
    Calculate the available income
    @return available income that has not been minted yet.
  **/
  function availableIncome() public view override returns (uint256) {
    return a.vaultsData().debt().sub(a.stablex().totalSupply());
  }

  /**
    Refresh the cumulative rates and debts of all vaults and all collateral types.
  **/
  function refresh() public override {
    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      refreshCollateral(collateralType);
    }
  }

  /**
    Initialize the cumulative rates to 1 for a new collateral type.
    @param _collateralType the address of the new collateral type to be initialized
  **/
  function initializeRates(address _collateralType) public override onlyConfig {
    require(_collateralType != address(0));
    lastRefresh[_collateralType] = now;
    cumulativeRates[_collateralType] = WadRayMath.ray();
  }

  /**
    Refresh the cumulative rate of a collateraltype.
    @dev this updates the debt for all vaults with the specified collateral type.
    @param _collateralType the address of the collateral type to be refreshed.
  **/
  function refreshCollateral(address _collateralType) public override {
    require(_collateralType != address(0));
    require(a.config().collateralIds(_collateralType) != 0);
    uint256 timestamp = now;
    uint256 timeElapsed = timestamp.sub(lastRefresh[_collateralType]);
    _refreshCumulativeRate(_collateralType, timeElapsed);
    lastRefresh[_collateralType] = timestamp;
  }

  /**
    Internal function to increase the cumulative rate over a specified time period
    @dev this updates the debt for all vaults with the specified collateral type.
    @param _collateralType the address of the collateral type to be updated
    @param _timeElapsed the amount of time in seconds to add to the cumulative rate
  **/
  function _refreshCumulativeRate(address _collateralType, uint256 _timeElapsed) internal {
    uint256 borrowRate = a.config().collateralBorrowRate(_collateralType);
    uint256 oldCumulativeRate = cumulativeRates[_collateralType];
    cumulativeRates[_collateralType] = a.ratesManager().calculateCumulativeRate(
      borrowRate,
      oldCumulativeRate,
      _timeElapsed
    );
    emit CumulativeRateUpdated(_collateralType, _timeElapsed, cumulativeRates[_collateralType]);
  }

  /**
    Deposit an ERC20 token into the vault of the msg.sender as collateral
    @dev A new vault is created if no vault exists for the `msg.sender` with the specified collateral type.
    this function used `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _collateralType the address of the collateral type to be deposited
    @param _amount the amount of tokens to be deposited in WEI.
  **/
  function deposit(address _collateralType, uint256 _amount) public override {
    require(a.config().collateralIds(_collateralType) != 0);
    uint256 vaultId = a.vaultsData().vaultId(_collateralType, msg.sender);
    if (vaultId == 0) {
      vaultId = a.vaultsData().createVault(_collateralType, msg.sender);
    }
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(vaultId);
    a.vaultsData().setCollateralBalance(vaultId, v.collateralBalance.add(_amount));

    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposited(vaultId, _amount, msg.sender);
  }

  /**
    Withdraws ERC20 tokens from a vault.
    @dev Only te owner of a vault can withdraw collateral from it.
    `withdraw()` will fail if it would bring the vault below the liquidation treshold.
    @param _vaultId the ID of the vault from which to withdraw the collateral.
    @param _amount the amount of ERC20 tokens to be withdrawn in WEI.
  **/
  function withdraw(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(_amount <= v.collateralBalance);
    uint256 newCollateralBalance = v.collateralBalance.sub(_amount);
    a.vaultsData().setCollateralBalance(_vaultId, newCollateralBalance);
    if (v.baseDebt > 0) {
      //save gas cost when withdrawing from 0 debt vault
      refreshCollateral(v.collateralType);
      uint256 newCollateralValue = a.priceFeed().convertFrom(v.collateralType, newCollateralBalance);
      bool _isHealthy = ILiquidationManagerV1(address(a.liquidationManager())).isHealthy(
        v.collateralType,
        newCollateralValue,
        a.vaultsData().vaultDebt(_vaultId)
      );
      require(_isHealthy);
    }

    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransfer(msg.sender, _amount);
    emit Withdrawn(_vaultId, _amount, msg.sender);
  }

  /**
    Convenience function to withdraw all collateral of a vault
    @dev Only te owner of a vault can withdraw collateral from it.
    `withdrawAll()` will fail if the vault has any outstanding debt attached to it.
    @param _vaultId the ID of the vault from which to withdraw the collateral.
  **/
  function withdrawAll(uint256 _vaultId) public override onlyVaultOwner(_vaultId) {
    uint256 collateralBalance = a.vaultsData().vaultCollateralBalance(_vaultId);
    withdraw(_vaultId, collateralBalance);
  }

  /**
    Borrow new StableX (Eg: PAR) tokens from a vault.
    @dev Only te owner of a vault can borrow from it.
    `borrow()` will update the outstanding vault debt to the current time before attempting the withdrawal.
     and will fail if it would bring the vault below the liquidation treshold.
    @param _vaultId the ID of the vault from which to borrow.
    @param _amount the amount of borrowed StableX tokens in WEI.
  **/
  function borrow(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    //make sure current rate is up to date
    refreshCollateral(v.collateralType);

    uint256 originationFeePercentage = a.config().collateralOriginationFee(v.collateralType);
    uint256 newDebt = _amount;
    if (originationFeePercentage > 0) {
      newDebt = newDebt.add(_amount.wadMul(originationFeePercentage));
    }

    // Increment vault borrow balance
    uint256 newBaseDebt = a.ratesManager().calculateBaseDebt(newDebt, cumulativeRates[v.collateralType]);

    a.vaultsData().setBaseDebt(_vaultId, v.baseDebt.add(newBaseDebt));

    uint256 collateralValue = a.priceFeed().convertFrom(v.collateralType, v.collateralBalance);
    uint256 newVaultDebt = a.vaultsData().vaultDebt(_vaultId);

    require(a.vaultsData().collateralDebt(v.collateralType) <= a.config().collateralDebtLimit(v.collateralType));

    bool isHealthy = ILiquidationManagerV1(address(a.liquidationManager())).isHealthy(
      v.collateralType,
      collateralValue,
      newVaultDebt
    );
    require(isHealthy);

    a.stablex().mint(msg.sender, _amount);
    emit Borrowed(_vaultId, _amount, msg.sender);
  }

  /**
    Convenience function to repay all debt of a vault
    @dev `repayAll()` will update the outstanding vault debt to the current time.
    @param _vaultId the ID of the vault for which to repay the debt.
  **/
  function repayAll(uint256 _vaultId) public override {
    repay(_vaultId, 2**256 - 1);
  }

  /**
    Repay an outstanding StableX balance to a vault.
    @dev `repay()` will update the outstanding vault debt to the current time.
    @param _vaultId the ID of the vault for which to repay the outstanding debt balance.
    @param _amount the amount of StableX tokens in WEI to be repaid.
  **/
  function repay(uint256 _vaultId, uint256 _amount) public override nonReentrant {
    address collateralType = a.vaultsData().vaultCollateralType(_vaultId);

    // Make sure current rate is up to date
    refreshCollateral(collateralType);

    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);
    // Decrement vault borrow balance
    if (_amount >= currentVaultDebt) {
      //full repayment
      _amount = currentVaultDebt; //only pay back what's outstanding
    }
    _reduceVaultDebt(_vaultId, _amount);
    a.stablex().burn(msg.sender, _amount);

    emit Repaid(_vaultId, _amount, msg.sender);
  }

  /**
    Internal helper function to reduce the debt of a vault.
    @dev assumes cumulative rates for the vault's collateral type are up to date.
    please call `refreshCollateral()` before calling this function.
    @param _vaultId the ID of the vault for which to reduce the debt.
    @param _amount the amount of debt to be reduced.
  **/
  function _reduceVaultDebt(uint256 _vaultId, uint256 _amount) internal {
    address collateralType = a.vaultsData().vaultCollateralType(_vaultId);

    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);
    uint256 remainder = currentVaultDebt.sub(_amount);
    uint256 cumulativeRate = cumulativeRates[collateralType];

    if (remainder == 0) {
      a.vaultsData().setBaseDebt(_vaultId, 0);
    } else {
      uint256 newBaseDebt = a.ratesManager().calculateBaseDebt(remainder, cumulativeRate);
      a.vaultsData().setBaseDebt(_vaultId, newBaseDebt);
    }
  }

  /**
    Liquidate a vault that is below the liquidation treshold by repaying it's outstanding debt.
    @dev `liquidate()` will update the outstanding vault debt to the current time and pay a `liquidationBonus`
    to the liquidator. `liquidate()` can be called by anyone.
    @param _vaultId the ID of the vault to be liquidated.
  **/
  function liquidate(uint256 _vaultId) public override nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    refreshCollateral(v.collateralType);

    uint256 collateralValue = a.priceFeed().convertFrom(v.collateralType, v.collateralBalance);
    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);

    require(
      !ILiquidationManagerV1(address(a.liquidationManager())).isHealthy(
        v.collateralType,
        collateralValue,
        currentVaultDebt
      )
    );

    uint256 discountedValue = ILiquidationManagerV1(address(a.liquidationManager())).applyLiquidationDiscount(
      collateralValue
    );
    uint256 collateralToReceive;
    uint256 stableXToPay = currentVaultDebt;

    if (discountedValue < currentVaultDebt) {
      //Insurance Case
      uint256 insuranceAmount = currentVaultDebt.sub(discountedValue);
      require(a.stablex().balanceOf(address(this)) >= insuranceAmount);
      a.stablex().burn(address(this), insuranceAmount);
      emit InsurancePaid(_vaultId, insuranceAmount, msg.sender);
      collateralToReceive = v.collateralBalance;
      stableXToPay = currentVaultDebt.sub(insuranceAmount);
    } else {
      collateralToReceive = a.priceFeed().convertTo(v.collateralType, currentVaultDebt);
      collateralToReceive = collateralToReceive.add(
        ILiquidationManagerV1(address(a.liquidationManager())).liquidationBonus(collateralToReceive)
      );
    }
    // reduce the vault debt to 0
    _reduceVaultDebt(_vaultId, currentVaultDebt);
    a.stablex().burn(msg.sender, stableXToPay);

    // send the collateral to the liquidator
    a.vaultsData().setCollateralBalance(_vaultId, v.collateralBalance.sub(collateralToReceive));
    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransfer(msg.sender, collateralToReceive);

    emit Liquidated(_vaultId, stableXToPay, collateralToReceive, v.owner, msg.sender);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
  using SafeMath for uint256;

  uint256 internal constant _WAD = 1e18;
  uint256 internal constant _HALF_WAD = _WAD / 2;

  uint256 internal constant _RAY = 1e27;
  uint256 internal constant _HALF_RAY = _RAY / 2;

  uint256 internal constant _WAD_RAY_RATIO = 1e9;

  function ray() internal pure returns (uint256) {
    return _RAY;
  }

  function wad() internal pure returns (uint256) {
    return _WAD;
  }

  function halfRay() internal pure returns (uint256) {
    return _HALF_RAY;
  }

  function halfWad() internal pure returns (uint256) {
    return _HALF_WAD;
  }

  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_WAD.add(a.mul(b)).div(_WAD);
  }

  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_WAD)).div(b);
  }

  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_RAY.add(a.mul(b)).div(_RAY);
  }

  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_RAY)).div(b);
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = _WAD_RAY_RATIO / 2;

    return halfRatio.add(a).div(_WAD_RAY_RATIO);
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a.mul(_WAD_RAY_RATIO);
  }

  /**
   * @dev calculates x^n, in ray. The code uses the ModExp precompile
   * @param x base
   * @param n exponent
   * @return z = x^n, in ray
   */
  function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : _RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rayMul(x, x);

      if (n % 2 != 0) {
        z = rayMul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import './IAddressProviderV1.sol';

interface IVaultsCoreV1 {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawAll(uint256 _vaultId) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  //Refresh
  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  //upgrade
  function upgrade(address _newVaultsCore) external;

  //Read only

  function a() external view returns (IAddressProviderV1);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IAddressProviderV1.sol';

interface ILiquidationManagerV1 {
  function a() external view returns (IAddressProviderV1);

  function calculateHealthFactor(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(uint256 _amount) external view returns (uint256 discountedAmount);

  function isHealthy(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IConfigProviderV1.sol';
import './ILiquidationManagerV1.sol';
import './IVaultsCoreV1.sol';
import '../../interfaces/IVaultsCore.sol';
import '../../interfaces/IAccessController.sol';
import '../../interfaces/ISTABLEX.sol';
import '../../interfaces/IPriceFeed.sol';
import '../../interfaces/IRatesManager.sol';
import '../../interfaces/IVaultsDataProvider.sol';
import '../../interfaces/IFeeDistributor.sol';

interface IAddressProviderV1 {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProviderV1 _config) external;

  function setVaultsCore(IVaultsCoreV1 _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManagerV1 _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProviderV1);

  function core() external view returns (IVaultsCoreV1);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManagerV1);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IAddressProviderV1.sol';

interface IConfigProviderV1 {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setLiquidationBonus(uint256 _bonus) external;

  function a() external view returns (IAddressProviderV1);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function liquidationBonus() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../interfaces/IWETH.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

interface IVaultsCore {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function depositETH() external payable;

  function depositByVaultId(uint256 _vaultId, uint256 _amount) external;

  function depositETHByVaultId(uint256 _vaultId) external payable;

  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) external;

  function depositETHAndBorrow(uint256 _borrowAmount) external payable;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawETH(uint256 _vaultId, uint256 _amount) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  function liquidatePartial(uint256 _vaultId, uint256 _amount) external;

  function upgrade(address payable _newVaultsCore) external;

  function acceptUpgrade(address payable _oldVaultsCore) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function WETH() external view returns (IWETH);

  function debtNotifier() external view returns (IDebtNotifier);

  function state() external view returns (IVaultsCoreState);

  function cumulativeRates(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAccessController {
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;

  function MANAGER_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAddressProvider.sol";

interface ISTABLEX is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function a() external view returns (IAddressProvider);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../chainlink/AggregatorV3Interface.sol";
import "../interfaces/IAddressProvider.sol";

interface IPriceFeed {
  event OracleUpdated(address indexed asset, address oracle, address sender);
  event EurOracleUpdated(address oracle, address sender);

  function setAssetOracle(address _asset, address _oracle) external;

  function setEurOracle(address _oracle) external;

  function a() external view returns (IAddressProvider);

  function assetOracles(address _asset) external view returns (AggregatorV3Interface);

  function eurOracle() external view returns (AggregatorV3Interface);

  function getAssetPrice(address _asset) external view returns (uint256);

  function convertFrom(address _asset, uint256 _amount) external view returns (uint256);

  function convertTo(address _asset, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IRatesManager {
  function a() external view returns (IAddressProvider);

  //current annualized borrow rate
  function annualizedBorrowRate(uint256 _currentBorrowRate) external pure returns (uint256);

  //uses current cumulative rate to calculate totalDebt based on baseDebt at time T0
  function calculateDebt(uint256 _baseDebt, uint256 _cumulativeRate) external pure returns (uint256);

  //uses current cumulative rate to calculate baseDebt at time T0
  function calculateBaseDebt(uint256 _debt, uint256 _cumulativeRate) external pure returns (uint256);

  //calculate a new cumulative rate
  function calculateCumulativeRate(
    uint256 _borrowRate,
    uint256 _cumulativeRate,
    uint256 _timeElapsed
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "../interfaces/IAddressProvider.sol";

interface IVaultsDataProvider {
  struct Vault {
    // borrowedType support USDX / PAR
    address collateralType;
    address owner;
    uint256 collateralBalance;
    uint256 baseDebt;
    uint256 createdAt;
  }

  //Write
  function createVault(address _collateralType, address _owner) external returns (uint256);

  function setCollateralBalance(uint256 _id, uint256 _balance) external;

  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) external;

  // Read
  function a() external view returns (IAddressProvider);

  function baseDebt(address _collateralType) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaults(uint256 _id) external view returns (Vault memory);

  function vaultOwner(uint256 _id) external view returns (address);

  function vaultCollateralType(uint256 _id) external view returns (address);

  function vaultCollateralBalance(uint256 _id) external view returns (uint256);

  function vaultBaseDebt(uint256 _id) external view returns (uint256);

  function vaultId(address _collateralType, address _owner) external view returns (uint256);

  function vaultExists(uint256 _id) external view returns (bool);

  function vaultDebt(uint256 _vaultId) external view returns (uint256);

  function debt() external view returns (uint256);

  function collateralDebt(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IFeeDistributor {
  event PayeeAdded(address indexed account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  function release() external;

  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function a() external view returns (IAddressProvider);

  function lastReleasedAt() external view returns (uint256);

  function getPayees() external view returns (address[] memory);

  function totalShares() external view returns (uint256);

  function shares(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAccessController.sol";
import "./IConfigProvider.sol";
import "./ISTABLEX.sol";
import "./IPriceFeed.sol";
import "./IRatesManager.sol";
import "./ILiquidationManager.sol";
import "./IVaultsCore.sol";
import "./IVaultsDataProvider.sol";
import "./IFeeDistributor.sol";

interface IAddressProvider {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProvider _config) external;

  function setVaultsCore(IVaultsCore _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManager _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProvider);

  function core() external view returns (IVaultsCore);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManager);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "./IAddressProvider.sol";
import "../v1/interfaces/IVaultsCoreV1.sol";

interface IVaultsCoreState {
  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  function syncState(IVaultsCoreState _stateAddress) external;

  function syncStateFromV1(IVaultsCoreV1 _core) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);

  function synced() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import '../../governance/interfaces/IGovernanceAddressProvider.sol';
import './ISupplyMiner.sol';

interface IDebtNotifier {
  function debtChanged(uint256 _vaultId) external;

  function setCollateralSupplyMiner(address collateral, ISupplyMiner supplyMiner) external;

  function a() external view returns (IGovernanceAddressProvider);

  function collateralSupplyMinerMapping(address collateral) external view returns (ISupplyMiner);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IConfigProvider {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 liquidationRatio;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
    uint256 liquidationBonus;
    uint256 liquidationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 liquidationRatio,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee,
    uint256 liquidationBonus,
    uint256 liquidationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus) external;

  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) external;

  function setMinVotingPeriod(uint256 _minVotingPeriod) external;

  function setMaxVotingPeriod(uint256 _maxVotingPeriod) external;

  function setVotingQuorum(uint256 _votingQuorum) external;

  function setProposalThreshold(uint256 _proposalThreshold) external;

  function a() external view returns (IAddressProvider);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function minVotingPeriod() external view returns (uint256);

  function maxVotingPeriod() external view returns (uint256);

  function votingQuorum() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralLiquidationRatio(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);

  function collateralLiquidationBonus(address _collateralType) external view returns (uint256);

  function collateralLiquidationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface ILiquidationManager {
  function a() external view returns (IAddressProvider);

  function calculateHealthFactor(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(address _collateralType, uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(address _collateralType, uint256 _amount)
    external
    view
    returns (uint256 discountedAmount);

  function isHealthy(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IGovernorAlpha.sol';
import './ITimelock.sol';
import './IVotingEscrow.sol';
import '../../interfaces/IAccessController.sol';
import '../../interfaces/IAddressProvider.sol';
import '../../liquidityMining/interfaces/IMIMO.sol';
import '../../liquidityMining/interfaces/IDebtNotifier.sol';

interface IGovernanceAddressProvider {
  function setParallelAddressProvider(IAddressProvider _parallel) external;

  function setMIMO(IMIMO _mimo) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  function setGovernorAlpha(IGovernorAlpha _governorAlpha) external;

  function setTimelock(ITimelock _timelock) external;

  function setVotingEscrow(IVotingEscrow _votingEscrow) external;

  function controller() external view returns (IAccessController);

  function parallel() external view returns (IAddressProvider);

  function mimo() external view returns (IMIMO);

  function debtNotifier() external view returns (IDebtNotifier);

  function governorAlpha() external view returns (IGovernorAlpha);

  function timelock() external view returns (ITimelock);

  function votingEscrow() external view returns (IVotingEscrow);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface ISupplyMiner {
  function baseDebtChanged(address user, uint256 newBaseDebt) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IGovernorAlpha {
  /// @notice Possible states that a proposal may be in
  enum ProposalState { Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;
    // Creator of the proposal
    address proposer;
    // The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    // the ordered list of target addresses for calls to be made
    address[] targets;
    // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    // The ordered list of function signatures to be called
    string[] signatures;
    // The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    // The timestamp at which voting begins: holders must delegate their votes prior to this timestamp
    uint256 startTime;
    // The timestamp at which voting ends: votes must be cast prior to this timestamp
    uint256 endTime;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been canceled
    bool canceled;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal
    bool support;
    // The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startTime,
    uint256 endTime,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description,
    uint256 endTime
  ) external returns (uint256);

  function queue(uint256 proposalId) external;

  function execute(uint256 proposalId) external payable;

  function cancel(uint256 proposalId) external;

  function castVote(uint256 proposalId, bool support) external;

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

  function state(uint256 proposalId) external view returns (ProposalState);

  function quorumVotes() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

interface ITimelock {
  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  function acceptAdmin() external;

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);

  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function queuedTransactions(bytes32 hash) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../liquidityMining/interfaces/IGenericMiner.sol';

interface IVotingEscrow {
  enum LockAction { CREATE_LOCK, INCREASE_LOCK_AMOUNT, INCREASE_LOCK_TIME }

  struct LockedBalance {
    uint256 amount;
    uint256 end;
  }

  /** Shared Events */
  event Deposit(address indexed provider, uint256 value, uint256 locktime, LockAction indexed action, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event Expired();

  function createLock(uint256 _value, uint256 _unlockTime) external;

  function increaseLockAmount(uint256 _value) external;

  function increaseLockLength(uint256 _unlockTime) external;

  function withdraw() external;

  function expireContract() external;

  function setMiner(IGenericMiner _miner) external;

  function setMinimumLockTime(uint256 _minimumLockTime) external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256);

  function balanceOfAt(address _owner, uint256 _blockTime) external view returns (uint256);

  function stakingToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMIMO is IERC20 {
  function burn(address account, uint256 amount) external;

  function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '../../interfaces/IAddressProvider.sol';
import '../../governance/interfaces/IGovernanceAddressProvider.sol';

interface IGenericMiner {
  struct UserInfo {
    uint256 stake;
    uint256 accAmountPerShare; // User's accAmountPerShare
  }

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeIncreased(address indexed user, uint256 stake);

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeDecreased(address indexed user, uint256 stake);

  function releaseMIMO(address _user) external;

  function a() external view returns (IGovernanceAddressProvider);

  function stake(address _user) external view returns (uint256);

  function pendingMIMO(address _user) external view returns (uint256);

  function totalStake() external view returns (uint256);

  function userInfo(address _user) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IVaultsDataProviderV1.sol";
import "./interfaces/IAddressProviderV1.sol";

contract VaultsDataProviderV1 is IVaultsDataProviderV1 {
  using SafeMath for uint256;

  IAddressProviderV1 public override a;

  uint256 public override vaultCount = 0;

  mapping(address => uint256) public override baseDebt;

  mapping(uint256 => Vault) private _vaults;
  mapping(address => mapping(address => uint256)) private _vaultOwners;

  modifier onlyVaultsCore() {
    require(msg.sender == address(a.core()), "Caller is not VaultsCore");
    _;
  }

  constructor(IAddressProviderV1 _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Opens a new vault.
    @dev only the vaultsCore module can call this function
    @param _collateralType address to the collateral asset e.g. WETH
    @param _owner the owner of the new vault.
  */
  function createVault(address _collateralType, address _owner) public override onlyVaultsCore returns (uint256) {
    require(_collateralType != address(0));
    require(_owner != address(0));
    uint256 newId = ++vaultCount;
    require(_collateralType != address(0), "collateralType unknown");
    Vault memory v = Vault({
      collateralType: _collateralType,
      owner: _owner,
      collateralBalance: 0,
      baseDebt: 0,
      createdAt: block.timestamp
    });
    _vaults[newId] = v;
    _vaultOwners[_owner][_collateralType] = newId;
    return newId;
  }

  /**
    Set the collateral balance of a vault.
    @dev only the vaultsCore module can call this function
    @param _id Vault ID of which the collateral balance will be updated
    @param _balance the new balance of the vault.
  */
  function setCollateralBalance(uint256 _id, uint256 _balance) public override onlyVaultsCore {
    require(vaultExists(_id), "Vault not found.");
    Vault storage v = _vaults[_id];
    v.collateralBalance = _balance;
  }

  /**
    Set the base debt of a vault.
    @dev only the vaultsCore module can call this function
    @param _id Vault ID of which the base debt will be updated
    @param _newBaseDebt the new base debt of the vault.
  */
  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) public override onlyVaultsCore {
    Vault storage _vault = _vaults[_id];
    if (_newBaseDebt > _vault.baseDebt) {
      uint256 increase = _newBaseDebt.sub(_vault.baseDebt);
      baseDebt[_vault.collateralType] = baseDebt[_vault.collateralType].add(increase);
    } else {
      uint256 decrease = _vault.baseDebt.sub(_newBaseDebt);
      baseDebt[_vault.collateralType] = baseDebt[_vault.collateralType].sub(decrease);
    }
    _vault.baseDebt = _newBaseDebt;
  }

  /**
    Get a vault by vault ID.
    @param _id The vault's ID to be retrieved
  */
  function vaults(uint256 _id) public view override returns (Vault memory) {
    Vault memory v = _vaults[_id];
    return v;
  }

  /**
    Get the owner of a vault.
    @param _id the ID of the vault
    @return owner of the vault
  */
  function vaultOwner(uint256 _id) public view override returns (address) {
    return _vaults[_id].owner;
  }

  /**
    Get the collateral type of a vault.
    @param _id the ID of the vault
    @return address for the collateral type of the vault
  */
  function vaultCollateralType(uint256 _id) public view override returns (address) {
    return _vaults[_id].collateralType;
  }

  /**
    Get the collateral balance of a vault.
    @param _id the ID of the vault
    @return collateral balance of the vault
  */
  function vaultCollateralBalance(uint256 _id) public view override returns (uint256) {
    return _vaults[_id].collateralBalance;
  }

  /**
    Get the base debt of a vault.
    @param _id the ID of the vault
    @return base debt of the vault
  */
  function vaultBaseDebt(uint256 _id) public view override returns (uint256) {
    return _vaults[_id].baseDebt;
  }

  /**
    Retrieve the vault id for a specified owner and collateral type.
    @dev returns 0 for non-existing vaults
    @param _collateralType address of the collateral type (Eg: WETH)
    @param _owner address of the owner of the vault
    @return vault id of the vault or 0
  */
  function vaultId(address _collateralType, address _owner) public view override returns (uint256) {
    return _vaultOwners[_owner][_collateralType];
  }

  /**
    Checks if a specified vault exists.
    @param _id the ID of the vault
    @return boolean if the vault exists
  */
  function vaultExists(uint256 _id) public view override returns (bool) {
    Vault memory v = _vaults[_id];
    return v.collateralType != address(0);
  }

  /**
    Calculated the total outstanding debt for all vaults and all collateral types.
    @dev uses the existing cumulative rate. Call `refresh()` on `VaultsCore`
    to make sure it's up to date.
    @return total debt of the platform
  */
  function debt() public view override returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      total = total.add(collateralDebt(collateralType));
    }
    return total;
  }

  /**
    Calculated the total outstanding debt for all vaults of a specific collateral type.
    @dev uses the existing cumulative rate. Call `refreshCollateral()` on `VaultsCore`
    to make sure it's up to date.
    @param _collateralType address of the collateral type (Eg: WETH)
    @return total debt of the platform of one collateral type
  */
  function collateralDebt(address _collateralType) public view override returns (uint256) {
    return a.ratesManager().calculateDebt(baseDebt[_collateralType], a.core().cumulativeRates(_collateralType));
  }

  /**
    Calculated the total outstanding debt for a specific vault.
    @dev uses the existing cumulative rate. Call `refreshCollateral()` on `VaultsCore`
    to make sure it's up to date.
    @param _vaultId the ID of the vault
    @return total debt of one vault
  */
  function vaultDebt(uint256 _vaultId) public view override returns (uint256) {
    IVaultsDataProviderV1.Vault memory v = vaults(_vaultId);
    return a.ratesManager().calculateDebt(v.baseDebt, a.core().cumulativeRates(v.collateralType));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import './IAddressProviderV1.sol';

interface IVaultsDataProviderV1 {
  struct Vault {
    // borrowedType support USDX / PAR
    address collateralType;
    address owner;
    uint256 collateralBalance;
    uint256 baseDebt;
    uint256 createdAt;
  }

  //Write
  function createVault(address _collateralType, address _owner) external returns (uint256);

  function setCollateralBalance(uint256 _id, uint256 _balance) external;

  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) external;

  function a() external view returns (IAddressProviderV1);

  // Read
  function baseDebt(address _collateralType) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaults(uint256 _id) external view returns (Vault memory);

  function vaultOwner(uint256 _id) external view returns (address);

  function vaultCollateralType(uint256 _id) external view returns (address);

  function vaultCollateralBalance(uint256 _id) external view returns (uint256);

  function vaultBaseDebt(uint256 _id) external view returns (uint256);

  function vaultId(address _collateralType, address _owner) external view returns (uint256);

  function vaultExists(uint256 _id) external view returns (bool);

  function vaultDebt(uint256 _vaultId) external view returns (uint256);

  function debt() external view returns (uint256);

  function collateralDebt(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "./interfaces/IAddressProviderV1.sol";
import "./interfaces/IConfigProviderV1.sol";
import "./interfaces/ILiquidationManagerV1.sol";

contract LiquidationManagerV1 is ILiquidationManagerV1, ReentrancyGuard {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  IAddressProviderV1 public override a;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18; // 1
  uint256 public constant FULL_LIQUIDIATION_TRESHOLD = 100e18; // 100 USDX, vaults below 100 USDX can be liquidated in full

  constructor(IAddressProviderV1 _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Check if the health factor is above or equal to 1.
    @param _collateralType address of the collateral type
    @param _collateralValue value of the collateral in stableX currency
    @param _vaultDebt outstanding debt to which the collateral balance shall be compared
    @return boolean if the health factor is >= 1.
  */
  function isHealthy(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) public view override returns (bool) {
    uint256 healthFactor = calculateHealthFactor(_collateralType, _collateralValue, _vaultDebt);
    return healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
  }

  /**
    Calculate the healthfactor of a debt balance
    @param _collateralType address of the collateral type
    @param _collateralValue value of the collateral in stableX currency
    @param _vaultDebt outstanding debt to which the collateral balance shall be compared
    @return healthFactor
  */
  function calculateHealthFactor(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) public view override returns (uint256 healthFactor) {
    if (_vaultDebt == 0) return WadRayMath.wad();

    // CurrentCollateralizationRatio = deposited ETH in USD / debt in USD
    uint256 collateralizationRatio = _collateralValue.wadDiv(_vaultDebt);

    // Healthfactor = CurrentCollateralizationRatio / MinimumCollateralizationRatio

    uint256 collateralId = a.config().collateralIds(_collateralType);
    require(collateralId > 0, "collateral not supported");

    uint256 minRatio = a.config().collateralConfigs(collateralId).minCollateralRatio;
    if (minRatio > 0) {
      return collateralizationRatio.wadDiv(minRatio);
    }

    return 1e18; // 1
  }

  /**
    Calculate the liquidation bonus for a specified amount
    @param _amount amount for which the liquidation bonus shall be calculated
    @return bonus the liquidation bonus to pay out
  */
  function liquidationBonus(uint256 _amount) public view override returns (uint256 bonus) {
    return _amount.wadMul(IConfigProviderV1(address(a.config())).liquidationBonus());
  }

  /**
    Apply the liquidation bonus to a balance as a discount.
    @param _amount the balance on which to apply to liquidation bonus as a discount.
    @return discountedAmount
  */
  function applyLiquidationDiscount(uint256 _amount) public view override returns (uint256 discountedAmount) {
    return _amount.wadDiv(IConfigProviderV1(address(a.config())).liquidationBonus().add(WadRayMath.wad()));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCore.sol";
import "../interfaces/IAccessController.sol";
import "../interfaces/IConfigProvider.sol";
import "../interfaces/ISTABLEX.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IRatesManager.sol";
import "../interfaces/IVaultsDataProvider.sol";
import "./interfaces/IConfigProviderV1.sol";
import "./interfaces/ILiquidationManagerV1.sol";
import "./interfaces/IVaultsCoreV1.sol";

contract AddressProviderV1 is IAddressProvider {
  IAccessController public override controller;
  IConfigProvider public override config;
  IVaultsCore public override core;

  ISTABLEX public override stablex;
  IRatesManager public override ratesManager;
  IPriceFeed public override priceFeed;
  ILiquidationManager public override liquidationManager;
  IVaultsDataProvider public override vaultsData;
  IFeeDistributor public override feeDistributor;

  constructor(IAccessController _controller) public {
    controller = _controller;
  }

  modifier onlyManager() {
    require(controller.hasRole(controller.MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  function setAccessController(IAccessController _controller) public override onlyManager {
    require(address(_controller) != address(0));
    controller = _controller;
  }

  function setConfigProvider(IConfigProvider _config) public override onlyManager {
    require(address(_config) != address(0));
    config = _config;
  }

  function setVaultsCore(IVaultsCore _core) public override onlyManager {
    require(address(_core) != address(0));
    core = _core;
  }

  function setStableX(ISTABLEX _stablex) public override onlyManager {
    require(address(_stablex) != address(0));
    stablex = _stablex;
  }

  function setRatesManager(IRatesManager _ratesManager) public override onlyManager {
    require(address(_ratesManager) != address(0));
    ratesManager = _ratesManager;
  }

  function setLiquidationManager(ILiquidationManager _liquidationManager) public override onlyManager {
    require(address(_liquidationManager) != address(0));
    liquidationManager = _liquidationManager;
  }

  function setPriceFeed(IPriceFeed _priceFeed) public override onlyManager {
    require(address(_priceFeed) != address(0));
    priceFeed = _priceFeed;
  }

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) public override onlyManager {
    require(address(_vaultsData) != address(0));
    vaultsData = _vaultsData;
  }

  function setFeeDistributor(IFeeDistributor _feeDistributor) public override onlyManager {
    require(address(_feeDistributor) != address(0));
    feeDistributor = _feeDistributor;
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../libraries/WadRayMath.sol";
import "./interfaces/IConfigProviderV1.sol";
import "./interfaces/IAddressProviderV1.sol";
import "./interfaces/IVaultsCoreV1.sol";

contract ConfigProviderV1 is IConfigProviderV1 {
  IAddressProviderV1 public override a;

  mapping(uint256 => CollateralConfig) private _collateralConfigs; //indexing starts at 1
  mapping(address => uint256) public override collateralIds;

  uint256 public override numCollateralConfigs;
  uint256 public override liquidationBonus = 5e16; // 5%

  constructor(IAddressProviderV1 _addresses) public {
    a = _addresses;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /**
    Creates or overwrites an existing config for a collateral type
    @param _collateralType address of the collateral type
    @param _debtLimit the debt ceiling for the collateral type
    @param _minCollateralRatio the minimum ratio to maintain to avoid liquidation
    @param _borrowRate the borrowing rate specified in 1 second interval in RAY accuracy.
    @param _originationFee an optional origination fee for newly created debt. Can be 0.
  */
  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee
  ) public override onlyManager {
    require(address(_collateralType) != address(0));
    if (collateralIds[_collateralType] == 0) {
      //new collateral
      IVaultsCoreV1(address(a.core())).initializeRates(_collateralType);
      CollateralConfig memory config = CollateralConfig({
        collateralType: _collateralType,
        debtLimit: _debtLimit,
        minCollateralRatio: _minCollateralRatio,
        borrowRate: _borrowRate,
        originationFee: _originationFee
      });

      numCollateralConfigs++;
      _collateralConfigs[numCollateralConfigs] = config;
      collateralIds[_collateralType] = numCollateralConfigs;
    } else {
      // Update collateral config
      IVaultsCoreV1(address(a.core())).refreshCollateral(_collateralType);
      uint256 id = collateralIds[_collateralType];

      _collateralConfigs[id].collateralType = _collateralType;
      _collateralConfigs[id].debtLimit = _debtLimit;
      _collateralConfigs[id].minCollateralRatio = _minCollateralRatio;
      _collateralConfigs[id].borrowRate = _borrowRate;
      _collateralConfigs[id].originationFee = _originationFee;
    }
    emit CollateralUpdated(_collateralType, _debtLimit, _minCollateralRatio, _borrowRate, _originationFee);
  }

  function _emitUpdateEvent(address _collateralType) internal {
    emit CollateralUpdated(
      _collateralType,
      _collateralConfigs[collateralIds[_collateralType]].debtLimit,
      _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio,
      _collateralConfigs[collateralIds[_collateralType]].borrowRate,
      _collateralConfigs[collateralIds[_collateralType]].originationFee
    );
  }

  /**
    Remove the config for a collateral type
    @param _collateralType address of the collateral type
  */
  function removeCollateral(address _collateralType) public override onlyManager {
    uint256 id = collateralIds[_collateralType];
    require(id != 0, "collateral does not exist");

    collateralIds[_collateralType] = 0;

    _collateralConfigs[id] = _collateralConfigs[numCollateralConfigs]; //move last entry forward
    collateralIds[_collateralConfigs[id].collateralType] = id; //update id for last entry
    delete _collateralConfigs[numCollateralConfigs];
    numCollateralConfigs--;

    emit CollateralRemoved(_collateralType);
  }

  /**
    Sets the debt limit for a collateral type
    @param _collateralType address of the collateral type
    @param _debtLimit the new debt limit
  */
  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) public override onlyManager {
    _collateralConfigs[collateralIds[_collateralType]].debtLimit = _debtLimit;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the minimum collateralization ratio for a collateral type
    @dev this is the liquidation treshold under which a vault is considered open for liquidation.
    @param _collateralType address of the collateral type
    @param _minCollateralRatio the new minimum collateralization ratio
  */
  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio)
    public
    override
    onlyManager
  {
    _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio = _minCollateralRatio;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the borrowing rate for a collateral type
    @dev borrowing rate is specified for a 1 sec interval and accurancy is in RAY.
    @param _collateralType address of the collateral type
    @param _borrowRate the new borrowing rate for a 1 sec interval
  */
  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) public override onlyManager {
    IVaultsCoreV1(address(a.core())).refreshCollateral(_collateralType);
    _collateralConfigs[collateralIds[_collateralType]].borrowRate = _borrowRate;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the origiation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
    @param _originationFee new origination fee in WAD
  */
  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) public override onlyManager {
    _collateralConfigs[collateralIds[_collateralType]].originationFee = _originationFee;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Get the debt limit for a collateral type
    @dev this is a platform wide limit for new debt issuance against a specific collateral type
    @param _collateralType address of the collateral type
  */
  function collateralDebtLimit(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].debtLimit;
  }

  /**
    Get the minimum collateralization ratio for a collateral type
    @dev this is the liquidation treshold under which a vault is considered open for liquidation.
    @param _collateralType address of the collateral type
  */
  function collateralMinCollateralRatio(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio;
  }

  /**
    Get the borrowing rate for a collateral type
    @dev borrowing rate is specified for a 1 sec interval and accurancy is in RAY.
    @param _collateralType address of the collateral type
  */
  function collateralBorrowRate(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].borrowRate;
  }

  /**
    Get the origiation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralOriginationFee(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].originationFee;
  }

  /**
    Set the platform wide incentive for liquidations.
    @dev the liquidation bonus is specified in WAD
    @param _bonus the liquidation bonus to be paid to liquidators
  */
  function setLiquidationBonus(uint256 _bonus) public override onlyManager {
    liquidationBonus = _bonus;
  }

  /**
    Retreives the entire config for a specific config id.
    @param _id the ID of the conifg to be returned
  */
  function collateralConfigs(uint256 _id) public view override returns (CollateralConfig memory) {
    require(_id <= numCollateralConfigs, "Invalid config id");
    return _collateralConfigs[_id];
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../v1/interfaces/IConfigProviderV1.sol";
import "../v1/interfaces/IVaultsCoreV1.sol";
import "../v1/interfaces/IFeeDistributorV1.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCore.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../interfaces/ILiquidationManager.sol";
import "../interfaces/IConfigProvider.sol";
import "../interfaces/IFeeDistributor.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

contract Upgrade {
  using SafeMath for uint256;

  uint256 public constant LIQUIDATION_BONUS = 5e16; // 5%

  IAddressProvider public a;
  IVaultsCore public core;
  IVaultsCoreState public coreState;
  ILiquidationManager public liquidationManager;
  IConfigProvider public config;
  IFeeDistributor public feeDistributor;
  IDebtNotifier public debtNotifier;
  IPriceFeed public priceFeed;
  address public bpool;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender));
    _;
  }

  constructor(
    IAddressProvider _addresses,
    IVaultsCore _core,
    IVaultsCoreState _coreState,
    ILiquidationManager _liquidationManager,
    IConfigProvider _config,
    IFeeDistributor _feeDistributor,
    IDebtNotifier _debtNotifier,
    IPriceFeed _priceFeed,
    address _bpool
  ) public {
    require(address(_addresses) != address(0));
    require(address(_core) != address(0));
    require(address(_coreState) != address(0));
    require(address(_liquidationManager) != address(0));
    require(address(_config) != address(0));
    require(address(_feeDistributor) != address(0));
    require(address(_debtNotifier) != address(0));
    require(address(_priceFeed) != address(0));
    require(_bpool != address(0));

    a = _addresses;
    core = _core;
    coreState = _coreState;
    liquidationManager = _liquidationManager;
    config = _config;
    feeDistributor = _feeDistributor;
    debtNotifier = _debtNotifier;
    priceFeed = _priceFeed;
    bpool = _bpool;
  }

  function upgrade() public onlyManager {
    IConfigProviderV1 oldConfig = IConfigProviderV1(address(a.config()));
    IPriceFeed oldPriceFeed = IPriceFeed(address(a.priceFeed()));
    IVaultsCoreV1 oldCore = IVaultsCoreV1(address(a.core()));
    IFeeDistributorV1 oldFeeDistributor = IFeeDistributorV1(address(a.feeDistributor()));

    bytes32 MINTER_ROLE = a.controller().MINTER_ROLE();
    bytes32 MANAGER_ROLE = a.controller().MANAGER_ROLE();
    bytes32 DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    a.controller().grantRole(MANAGER_ROLE, address(this));
    a.controller().grantRole(MINTER_ROLE, address(core));
    a.controller().grantRole(MINTER_ROLE, address(feeDistributor));

    oldCore.refresh();
    if (oldCore.availableIncome() > 0) {
      oldFeeDistributor.release();
    }

    a.controller().revokeRole(MINTER_ROLE, address(a.core()));
    a.controller().revokeRole(MINTER_ROLE, address(a.feeDistributor()));

    oldCore.upgrade(payable(address(core)));

    a.setVaultsCore(core);
    a.setConfigProvider(config);
    a.setLiquidationManager(liquidationManager);
    a.setFeeDistributor(feeDistributor);
    a.setPriceFeed(priceFeed);

    priceFeed.setEurOracle(address(oldPriceFeed.eurOracle()));

    uint256 numCollateralConfigs = oldConfig.numCollateralConfigs();
    for (uint256 i = 1; i <= numCollateralConfigs; i++) {
      IConfigProviderV1.CollateralConfig memory collateralConfig = oldConfig.collateralConfigs(i);

      config.setCollateralConfig(
        collateralConfig.collateralType,
        collateralConfig.debtLimit,
        collateralConfig.minCollateralRatio,
        collateralConfig.minCollateralRatio,
        collateralConfig.borrowRate,
        collateralConfig.originationFee,
        LIQUIDATION_BONUS,
        0
      );

      priceFeed.setAssetOracle(
        collateralConfig.collateralType,
        address(oldPriceFeed.assetOracles(collateralConfig.collateralType))
      );
    }

    coreState.syncStateFromV1(oldCore);
    core.acceptUpgrade(payable(address(oldCore)));
    core.setDebtNotifier(debtNotifier);
    debtNotifier.a().setDebtNotifier(debtNotifier);

    address[] memory payees = new address[](2);
    payees[0] = bpool;
    payees[1] = address(core);
    uint256[] memory shares = new uint256[](2);
    shares[0] = uint256(90);
    shares[1] = uint256(10);
    feeDistributor.changePayees(payees, shares);

    a.controller().revokeRole(MANAGER_ROLE, address(this));
    a.controller().revokeRole(DEFAULT_ADMIN_ROLE, address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './IAddressProviderV1.sol';

interface IFeeDistributorV1 {
  event PayeeAdded(address indexed account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  function release() external;

  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function a() external view returns (IAddressProviderV1);

  function lastReleasedAt() external view returns (uint256);

  function getPayees() external view returns (address[] memory);

  function totalShares() external view returns (uint256);

  function shares(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../liquidityMining/interfaces/IMIMO.sol";
import "../liquidityMining/interfaces/IMIMODistributor.sol";
import "../liquidityMining/interfaces/ISupplyMiner.sol";
import "../liquidityMining/interfaces/IDemandMiner.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";
import "../libraries/WadRayMath.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "../governance/interfaces/IVotingEscrow.sol";
import "../interfaces/IAddressProvider.sol";

contract MIMODeployment {
  IGovernanceAddressProvider public ga;
  IMIMO public mimo;
  IMIMODistributor public mimoDistributor;
  ISupplyMiner public wethSupplyMiner;
  ISupplyMiner public wbtcSupplyMiner;
  ISupplyMiner public usdcSupplyMiner;
  IDemandMiner public demandMiner;
  IDebtNotifier public debtNotifier;
  IVotingEscrow public votingEscrow;

  address public weth;
  address public wbtc;
  address public usdc;

  modifier onlyManager() {
    require(ga.controller().hasRole(ga.controller().MANAGER_ROLE(), msg.sender), "Caller is not Manager");
    _;
  }

  constructor(
    IGovernanceAddressProvider _ga,
    IMIMO _mimo,
    IMIMODistributor _mimoDistributor,
    ISupplyMiner _wethSupplyMiner,
    ISupplyMiner _wbtcSupplyMiner,
    ISupplyMiner _usdcSupplyMiner,
    IDemandMiner _demandMiner,
    IDebtNotifier _debtNotifier,
    IVotingEscrow _votingEscrow,
    address _weth,
    address _wbtc,
    address _usdc
  ) public {
    require(address(_ga) != address(0));
    require(address(_mimo) != address(0));
    require(address(_mimoDistributor) != address(0));
    require(address(_wethSupplyMiner) != address(0));
    require(address(_wbtcSupplyMiner) != address(0));
    require(address(_usdcSupplyMiner) != address(0));
    require(address(_demandMiner) != address(0));
    require(address(_debtNotifier) != address(0));
    require(address(_votingEscrow) != address(0));
    require(_weth != address(0));
    require(_wbtc != address(0));
    require(_usdc != address(0));

    ga = _ga;
    mimo = _mimo;
    mimoDistributor = _mimoDistributor;
    wethSupplyMiner = _wethSupplyMiner;
    wbtcSupplyMiner = _wbtcSupplyMiner;
    usdcSupplyMiner = _usdcSupplyMiner;
    demandMiner = _demandMiner;
    debtNotifier = _debtNotifier;
    votingEscrow = _votingEscrow;

    weth = _weth;
    wbtc = _wbtc;
    usdc = _usdc;
  }

  function setup() public onlyManager {
    //IAddressProvider parallel = a.parallel();

    //bytes32 MIMO_MINTER_ROLE = keccak256("MIMO_MINTER_ROLE");
    //bytes32 DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;

    ga.setMIMO(mimo);
    ga.setVotingEscrow(votingEscrow);

    debtNotifier.setCollateralSupplyMiner(weth, wethSupplyMiner);
    debtNotifier.setCollateralSupplyMiner(wbtc, wbtcSupplyMiner);
    debtNotifier.setCollateralSupplyMiner(usdc, usdcSupplyMiner);

    address[] memory payees = new address[](4);
    payees[0] = address(wethSupplyMiner);
    payees[1] = address(wbtcSupplyMiner);
    payees[2] = address(usdcSupplyMiner);
    payees[3] = address(demandMiner);
    uint256[] memory shares = new uint256[](4);
    shares[0] = uint256(20);
    shares[1] = uint256(25);
    shares[2] = uint256(5);
    shares[3] = uint256(50);
    mimoDistributor.changePayees(payees, shares);

    bytes32 MANAGER_ROLE = ga.controller().MANAGER_ROLE();
    ga.controller().renounceRole(MANAGER_ROLE, address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import '../../governance/interfaces/IGovernanceAddressProvider.sol';
import './IBaseDistributor.sol';

interface IMIMODistributorExtension {
  function startTime() external view returns (uint256);

  function currentIssuance() external view returns (uint256);

  function weeklyIssuanceAt(uint256 timestamp) external view returns (uint256);

  function totalSupplyAt(uint256 timestamp) external view returns (uint256);
}

interface IMIMODistributor is IBaseDistributor, IMIMODistributorExtension {}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDemandMiner {
  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function token() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import '../../governance/interfaces/IGovernanceAddressProvider.sol';

interface IBaseDistributor {
  event PayeeAdded(address account, uint256 shares);
  event TokensReleased(uint256 newTokens, uint256 releasedAt);

  /**
    Public function to release the accumulated new MIMO tokens to the payees.
    @dev anyone can call this.
  */
  function release() external;

  /**
    Updates the payee configuration to a new one.
    @dev will release existing fees before the update.
    @param _payees Array of payees
    @param _shares Array of shares for each payee
  */
  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function totalShares() external view returns (uint256);

  function shares(address) external view returns (uint256);

  function a() external view returns (IGovernanceAddressProvider);

  function mintableTokens() external view returns (uint256);

  /**
    Get current configured payees.
    @return array of current payees.
  */
  function getPayees() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsDataProvider.sol";
import "../interfaces/IVaultsCore.sol";

contract RepayVault {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint256 public constant REPAY_PER_VAULT = 10 ether;

  IAddressProvider public a;

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));

    a = _addresses;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not Manager");
    _;
  }

  function repay() public onlyManager {
    IVaultsCore core = a.core();
    IVaultsDataProvider vaultsData = a.vaultsData();
    uint256 vaultCount = a.vaultsData().vaultCount();

    for (uint256 vaultId = 1; vaultId <= vaultCount; vaultId++) {
      uint256 baseDebt = vaultsData.vaultBaseDebt(vaultId);

      //if (vaultId==28 || vaultId==29 || vaultId==30 || vaultId==31 || vaultId==32 || vaultId==33 || vaultId==35){
      //  continue;
      //}

      if (baseDebt == 0) {
        continue;
      }

      core.repay(vaultId, REPAY_PER_VAULT);
    }

    IERC20 par = IERC20(a.stablex());
    par.safeTransfer(msg.sender, par.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libraries/WadRayMath.sol";
import "../interfaces/IVaultsCore.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

contract VaultsCore is IVaultsCore, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 internal constant _MAX_INT = 2**256 - 1;

  IAddressProvider public override a;
  IWETH public override WETH;
  IVaultsCoreState public override state;
  IDebtNotifier public override debtNotifier;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender));
    _;
  }

  modifier onlyVaultOwner(uint256 _vaultId) {
    require(a.vaultsData().vaultOwner(_vaultId) == msg.sender);
    _;
  }

  constructor(
    IAddressProvider _addresses,
    IWETH _IWETH,
    IVaultsCoreState _vaultsCoreState
  ) public {
    require(address(_addresses) != address(0));
    require(address(_IWETH) != address(0));
    require(address(_vaultsCoreState) != address(0));
    a = _addresses;
    WETH = _IWETH;
    state = _vaultsCoreState;
  }

  // For a contract to receive ETH, it needs to have a payable fallback function
  // https://ethereum.stackexchange.com/a/47415
  receive() external payable {
    require(msg.sender == address(WETH));
  }

  /*
    Allow smooth upgrading of the vaultscore.
    @dev this function approves token transfers to the new vaultscore of
    both stablex and all configured collateral types
    @param _newVaultsCore address of the new vaultscore
  */
  function upgrade(address payable _newVaultsCore) public override onlyManager {
    require(address(_newVaultsCore) != address(0));
    require(a.stablex().approve(_newVaultsCore, _MAX_INT));

    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      IERC20 asset = IERC20(collateralType);
      asset.safeApprove(_newVaultsCore, _MAX_INT);
    }
  }

  /*
    Allow smooth upgrading of the VaultsCore.
    @dev this function transfers both PAR and all configured collateral
    types to the new vaultscore.
  */
  function acceptUpgrade(address payable _oldVaultsCore) public override onlyManager {
    IERC20 stableX = IERC20(a.stablex());
    stableX.safeTransferFrom(_oldVaultsCore, address(this), stableX.balanceOf(_oldVaultsCore));

    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      IERC20 asset = IERC20(collateralType);
      asset.safeTransferFrom(_oldVaultsCore, address(this), asset.balanceOf(_oldVaultsCore));
    }
  }

  /**
    Configure the debt notifier.
    @param _debtNotifier the new DebtNotifier module address.
  **/
  function setDebtNotifier(IDebtNotifier _debtNotifier) public override onlyManager {
    require(address(_debtNotifier) != address(0));
    debtNotifier = _debtNotifier;
  }

  /**
    Deposit an ERC20 token into the vault of the msg.sender as collateral
    @dev A new vault is created if no vault exists for the `msg.sender` with the specified collateral type.
    this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _collateralType the address of the collateral type to be deposited
    @param _amount the amount of tokens to be deposited in WEI.
  **/
  function deposit(address _collateralType, uint256 _amount) public override {
    require(a.config().collateralIds(_collateralType) != 0);

    IERC20 asset = IERC20(_collateralType);
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    _addCollateralToVault(_collateralType, _amount);
  }

  /**
    Wraps ETH and deposits WETH into the vault of the msg.sender as collateral
    @dev A new vault is created if no WETH vault exists
  **/
  function depositETH() public payable override {
    WETH.deposit{ value: msg.value }();
    _addCollateralToVault(address(WETH), msg.value);
  }

  /**
    Deposit an ERC20 token into the specified vault as collateral
    @dev this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _vaultId the address of the collateral type to be deposited
    @param _amount the amount of tokens to be deposited in WEI.
  **/
  function depositByVaultId(uint256 _vaultId, uint256 _amount) public override {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(v.collateralType != address(0));

    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    _addCollateralToVaultById(_vaultId, _amount);
  }

  /**
    Wraps ETH and deposits WETH into the specified vault as collateral
    @dev this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _vaultId the address of the collateral type to be deposited
  **/
  function depositETHByVaultId(uint256 _vaultId) public payable override {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(v.collateralType == address(WETH));

    WETH.deposit{ value: msg.value }();

    _addCollateralToVaultById(_vaultId, msg.value);
  }

  /**
    Deposit an ERC20 token into the vault of the msg.sender as collateral and borrows the specified amount of tokens in WEI
    @dev see deposit() and borrow()
    @param _collateralType the address of the collateral type to be deposited
    @param _depositAmount the amount of tokens to be deposited in WEI.
    @param _borrowAmount the amount of borrowed StableX tokens in WEI.
  **/
  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) public override {
    deposit(_collateralType, _depositAmount);
    uint256 vaultId = a.vaultsData().vaultId(_collateralType, msg.sender);
    borrow(vaultId, _borrowAmount);
  }

  /**
    Wraps ETH and deposits WETH into the vault of the msg.sender as collateral and borrows the specified amount of tokens in WEI
    @dev see depositETH() and borrow()
    @param _borrowAmount the amount of borrowed StableX tokens in WEI.
  **/
  function depositETHAndBorrow(uint256 _borrowAmount) public payable override {
    depositETH();
    uint256 vaultId = a.vaultsData().vaultId(address(WETH), msg.sender);
    borrow(vaultId, _borrowAmount);
  }

  function _addCollateralToVault(address _collateralType, uint256 _amount) internal {
    uint256 vaultId = a.vaultsData().vaultId(_collateralType, msg.sender);
    if (vaultId == 0) {
      vaultId = a.vaultsData().createVault(_collateralType, msg.sender);
    }

    _addCollateralToVaultById(vaultId, _amount);
  }

  function _addCollateralToVaultById(uint256 _vaultId, uint256 _amount) internal {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    a.vaultsData().setCollateralBalance(_vaultId, v.collateralBalance.add(_amount));

    emit Deposited(_vaultId, _amount, msg.sender);
  }

  /**
    Withdraws ERC20 tokens from a vault.
    @dev Only the owner of a vault can withdraw collateral from it.
    `withdraw()` will fail if it would bring the vault below the minimum collateralization treshold.
    @param _vaultId the ID of the vault from which to withdraw the collateral.
    @param _amount the amount of ERC20 tokens to be withdrawn in WEI.
  **/
  function withdraw(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    _removeCollateralFromVault(_vaultId, _amount);
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransfer(msg.sender, _amount);
  }

  /**
    Withdraws ETH from a WETH vault.
    @dev Only the owner of a vault can withdraw collateral from it.
    `withdraw()` will fail if it would bring the vault below the minimum collateralization treshold.
    @param _vaultId the ID of the vault from which to withdraw the collateral.
    @param _amount the amount of ETH to be withdrawn in WEI.
  **/
  function withdrawETH(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    _removeCollateralFromVault(_vaultId, _amount);
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    require(v.collateralType == address(WETH));

    WETH.withdraw(_amount);
    msg.sender.transfer(_amount);
  }

  function _removeCollateralFromVault(uint256 _vaultId, uint256 _amount) internal {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(_amount <= v.collateralBalance);
    uint256 newCollateralBalance = v.collateralBalance.sub(_amount);
    a.vaultsData().setCollateralBalance(_vaultId, newCollateralBalance);
    if (v.baseDebt > 0) {
      // Save gas cost when withdrawing from 0 debt vault
      state.refreshCollateral(v.collateralType);
      uint256 newCollateralValue = a.priceFeed().convertFrom(v.collateralType, newCollateralBalance);
      require(
        a.liquidationManager().isHealthy(
          newCollateralValue,
          a.vaultsData().vaultDebt(_vaultId),
          a.config().collateralConfigs(a.config().collateralIds(v.collateralType)).minCollateralRatio
        )
      );
    }

    emit Withdrawn(_vaultId, _amount, msg.sender);
  }

  /**
    Borrow new PAR tokens from a vault.
    @dev Only the owner of a vault can borrow from it.
    `borrow()` will update the outstanding vault debt to the current time before attempting the withdrawal.
     `borrow()` will fail if it would bring the vault below the minimum collateralization treshold.
    @param _vaultId the ID of the vault from which to borrow.
    @param _amount the amount of borrowed PAR tokens in WEI.
  **/
  function borrow(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    // Make sure current rate is up to date
    state.refreshCollateral(v.collateralType);

    uint256 originationFeePercentage = a.config().collateralOriginationFee(v.collateralType);
    uint256 newDebt = _amount;
    if (originationFeePercentage > 0) {
      newDebt = newDebt.add(_amount.wadMul(originationFeePercentage));
    }

    // Increment vault borrow balance
    uint256 newBaseDebt = a.ratesManager().calculateBaseDebt(newDebt, cumulativeRates(v.collateralType));

    a.vaultsData().setBaseDebt(_vaultId, v.baseDebt.add(newBaseDebt));

    uint256 collateralValue = a.priceFeed().convertFrom(v.collateralType, v.collateralBalance);
    uint256 newVaultDebt = a.vaultsData().vaultDebt(_vaultId);

    require(a.vaultsData().collateralDebt(v.collateralType) <= a.config().collateralDebtLimit(v.collateralType));

    bool isHealthy = a.liquidationManager().isHealthy(
      collateralValue,
      newVaultDebt,
      a.config().collateralConfigs(a.config().collateralIds(v.collateralType)).minCollateralRatio
    );
    require(isHealthy);

    a.stablex().mint(msg.sender, _amount);
    debtNotifier.debtChanged(_vaultId);
    emit Borrowed(_vaultId, _amount, msg.sender);
  }

  /**
    Convenience function to repay all debt of a vault
    @dev `repayAll()` will update the outstanding vault debt to the current time.
    @param _vaultId the ID of the vault for which to repay the debt.
  **/
  function repayAll(uint256 _vaultId) public override {
    repay(_vaultId, _MAX_INT);
  }

  /**
    Repay an outstanding PAR balance to a vault.
    @dev `repay()` will update the outstanding vault debt to the current time.
    @param _vaultId the ID of the vault for which to repay the outstanding debt balance.
    @param _amount the amount of PAR tokens in WEI to be repaid.
  **/
  function repay(uint256 _vaultId, uint256 _amount) public override nonReentrant {
    address collateralType = a.vaultsData().vaultCollateralType(_vaultId);

    // Make sure current rate is up to date
    state.refreshCollateral(collateralType);

    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);
    // Decrement vault borrow balance
    if (_amount >= currentVaultDebt) {
      //full repayment
      _amount = currentVaultDebt; //only pay back what's outstanding
    }
    _reduceVaultDebt(_vaultId, _amount);
    a.stablex().burn(msg.sender, _amount);
    debtNotifier.debtChanged(_vaultId);
    emit Repaid(_vaultId, _amount, msg.sender);
  }

  /**
    Internal helper function to reduce the debt of a vault.
    @dev assumes cumulative rates for the vault's collateral type are up to date.
    please call `refreshCollateral()` before calling this function.
    @param _vaultId the ID of the vault for which to reduce the debt.
    @param _amount the amount of debt to be reduced.
  **/
  function _reduceVaultDebt(uint256 _vaultId, uint256 _amount) internal {
    address collateralType = a.vaultsData().vaultCollateralType(_vaultId);

    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);
    uint256 remainder = currentVaultDebt.sub(_amount);
    uint256 cumulativeRate = cumulativeRates(collateralType);

    if (remainder == 0) {
      a.vaultsData().setBaseDebt(_vaultId, 0);
    } else {
      uint256 newBaseDebt = a.ratesManager().calculateBaseDebt(remainder, cumulativeRate);
      a.vaultsData().setBaseDebt(_vaultId, newBaseDebt);
    }
  }

  /**
    Liquidate a vault that is below the liquidation treshold by repaying its outstanding debt.
    @dev `liquidate()` will update the outstanding vault debt to the current time and pay a `liquidationBonus`
    to the liquidator. `liquidate()` can be called by anyone.
    @param _vaultId the ID of the vault to be liquidated.
  **/
  function liquidate(uint256 _vaultId) public override {
    liquidatePartial(_vaultId, _MAX_INT);
  }

  /**
    Liquidate a vault partially that is below the liquidation treshold by repaying part of its outstanding debt.
    @dev `liquidatePartial()` will update the outstanding vault debt to the current time and pay a `liquidationBonus`
    to the liquidator. A LiquidationFee will be applied to the borrower during the liquidation.
    This means that the change in outstanding debt can be smaller than the repaid amount.
    `liquidatePartial()` can be called by anyone.
    @param _vaultId the ID of the vault to be liquidated.
    @param _amount the amount of debt+liquidationFee to repay.
  **/
  function liquidatePartial(uint256 _vaultId, uint256 _amount) public override nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    state.refreshCollateral(v.collateralType);

    uint256 collateralValue = a.priceFeed().convertFrom(v.collateralType, v.collateralBalance);
    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);

    require(
      !a.liquidationManager().isHealthy(
        collateralValue,
        currentVaultDebt,
        a.config().collateralConfigs(a.config().collateralIds(v.collateralType)).liquidationRatio
      )
    );

    uint256 repaymentAfterLiquidationFeeRatio = WadRayMath.wad().sub(
      a.config().collateralLiquidationFee(v.collateralType)
    );
    uint256 maxLiquiditionCost = currentVaultDebt.wadDiv(repaymentAfterLiquidationFeeRatio);

    uint256 repayAmount;

    if (_amount > maxLiquiditionCost) {
      _amount = maxLiquiditionCost;
      repayAmount = currentVaultDebt;
    } else {
      repayAmount = _amount.wadMul(repaymentAfterLiquidationFeeRatio);
    }

    // collateral value to be received by the liquidator is based on the total amount repaid (including the liquidationFee).
    uint256 collateralValueToReceive = _amount.add(a.liquidationManager().liquidationBonus(v.collateralType, _amount));
    uint256 insuranceAmount = 0;
    if (collateralValueToReceive >= collateralValue) {
      // Not enough collateral for debt & liquidation fee
      collateralValueToReceive = collateralValue;
      uint256 discountedCollateralValue = a.liquidationManager().applyLiquidationDiscount(
        v.collateralType,
        collateralValue
      );

      if (currentVaultDebt > discountedCollateralValue) {
        // Not enough collateral for debt alone
        insuranceAmount = currentVaultDebt.sub(discountedCollateralValue);
        require(a.stablex().balanceOf(address(this)) >= insuranceAmount);
        a.stablex().burn(address(this), insuranceAmount); // Insurance uses local reserves to pay down debt
        emit InsurancePaid(_vaultId, insuranceAmount, msg.sender);
      }

      repayAmount = currentVaultDebt.sub(insuranceAmount);
      _amount = discountedCollateralValue;
    }

    // reduce the vault debt by repayAmount
    _reduceVaultDebt(_vaultId, repayAmount.add(insuranceAmount));
    a.stablex().burn(msg.sender, _amount);

    // send the claimed collateral to the liquidator
    uint256 collateralToReceive = a.priceFeed().convertTo(v.collateralType, collateralValueToReceive);
    a.vaultsData().setCollateralBalance(_vaultId, v.collateralBalance.sub(collateralToReceive));
    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransfer(msg.sender, collateralToReceive);

    debtNotifier.debtChanged(_vaultId);

    emit Liquidated(_vaultId, repayAmount, collateralToReceive, v.owner, msg.sender);
  }

  /**
    Returns the cumulativeRate of a collateral type. This function exists for
    backwards compatibility with the VaultsDataProvider.
    @param _collateralType the address of the collateral type.
  **/
  function cumulativeRates(address _collateralType) public view override returns (uint256) {
    return state.cumulativeRates(_collateralType);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libraries/WadRayMath.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../v1/interfaces/IVaultsCoreV1.sol";

contract VaultsCoreState is IVaultsCoreState {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 internal constant _MAX_INT = 2**256 - 1;

  bool public override synced = false;
  IAddressProvider public override a;

  mapping(address => uint256) public override cumulativeRates;
  mapping(address => uint256) public override lastRefresh;

  modifier onlyConfig() {
    require(msg.sender == address(a.config()));
    _;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender));
    _;
  }

  modifier notSynced() {
    require(!synced);
    _;
  }

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Calculate the available income
    @return available income that has not been minted yet.
  **/
  function availableIncome() public view override returns (uint256) {
    return a.vaultsData().debt().sub(a.stablex().totalSupply());
  }

  /**
    Refresh the cumulative rates and debts of all vaults and all collateral types.
    @dev anyone can call this.
  **/
  function refresh() public override {
    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      refreshCollateral(collateralType);
    }
  }

  /**
    Sync state with another instance. This is used during version upgrade to keep V2 in sync with V2.
    @dev This call will read the state via
      `cumulativeRates(address collateralType)` and `lastRefresh(address collateralType)`.
    @param _stateAddress address from which the state is to be copied.
  **/
  function syncState(IVaultsCoreState _stateAddress) public override onlyManager notSynced {
    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      cumulativeRates[collateralType] = _stateAddress.cumulativeRates(collateralType);
      lastRefresh[collateralType] = _stateAddress.lastRefresh(collateralType);
    }
    synced = true;
  }

  /**
    Sync state with v1 core. This is used during version upgrade to keep V2 in sync with V1.
    @dev This call will read the state via
      `cumulativeRates(address collateralType)` and `lastRefresh(address collateralType)`.
    @param _core address of core v1 from which the state is to be copied.
  **/
  function syncStateFromV1(IVaultsCoreV1 _core) public override onlyManager notSynced {
    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      cumulativeRates[collateralType] = _core.cumulativeRates(collateralType);
      lastRefresh[collateralType] = _core.lastRefresh(collateralType);
    }
    synced = true;
  }

  /**
    Initialize the cumulative rates to 1 for a new collateral type.
    @param _collateralType the address of the new collateral type to be initialized
  **/
  function initializeRates(address _collateralType) public override onlyConfig {
    require(_collateralType != address(0));
    lastRefresh[_collateralType] = block.timestamp;
    cumulativeRates[_collateralType] = WadRayMath.ray();
  }

  /**
    Refresh the cumulative rate of a collateraltype.
    @dev this updates the debt for all vaults with the specified collateral type.
    @param _collateralType the address of the collateral type to be refreshed.
  **/
  function refreshCollateral(address _collateralType) public override {
    require(_collateralType != address(0));
    require(a.config().collateralIds(_collateralType) != 0);
    uint256 timestamp = block.timestamp;
    uint256 timeElapsed = timestamp.sub(lastRefresh[_collateralType]);
    _refreshCumulativeRate(_collateralType, timeElapsed);
    lastRefresh[_collateralType] = timestamp;
  }

  /**
    Internal function to increase the cumulative rate over a specified time period
    @dev this updates the debt for all vaults with the specified collateral type.
    @param _collateralType the address of the collateral type to be updated
    @param _timeElapsed the amount of time in seconds to add to the cumulative rate
  **/
  function _refreshCumulativeRate(address _collateralType, uint256 _timeElapsed) internal {
    uint256 borrowRate = a.config().collateralBorrowRate(_collateralType);
    uint256 oldCumulativeRate = cumulativeRates[_collateralType];
    cumulativeRates[_collateralType] = a.ratesManager().calculateCumulativeRate(
      borrowRate,
      oldCumulativeRate,
      _timeElapsed
    );
    emit CumulativeRateUpdated(_collateralType, _timeElapsed, cumulativeRates[_collateralType]);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../libraries/WadRayMath.sol";
import "../interfaces/ISTABLEX.sol";
import "./interfaces/IFeeDistributorV1.sol";
import "./interfaces/IAddressProviderV1.sol";

contract FeeDistributorV1 is IFeeDistributorV1, ReentrancyGuard {
  using SafeMath for uint256;

  event PayeeAdded(address account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  uint256 public override lastReleasedAt;
  IAddressProviderV1 public override a;

  uint256 public override totalShares;
  mapping(address => uint256) public override shares;
  address[] public payees;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not Manager");
    _;
  }

  constructor(IAddressProviderV1 _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Public function to release the accumulated fee income to the payees.
    @dev anyone can call this.
  */
  function release() public override nonReentrant {
    uint256 income = a.core().availableIncome();
    require(income > 0, "income is 0");
    require(payees.length > 0, "Payees not configured yet");
    lastReleasedAt = now;

    // Mint USDX to all receivers
    for (uint256 i = 0; i < payees.length; i++) {
      address payee = payees[i];
      _release(income, payee);
    }
    emit FeeReleased(income, lastReleasedAt);
  }

  /**
    Get current configured payees.
    @return array of current payees.
  */
  function getPayees() public view override returns (address[] memory) {
    return payees;
  }

  /**
    Internal function to release a percentage of income to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalIncomeReceived Total income for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalIncomeReceived, address _payee) internal {
    uint256 payment = _totalIncomeReceived.mul(shares[_payee]).div(totalShares);
    a.stablex().mint(_payee, payment);
  }

  /**
    Internal function to add a new payee.
    @dev will update totalShares and therefore reduce the relative share of all other payees.
    @param _payee The address of the payee to add.
    @param _shares The number of shares owned by the payee.
  */
  function _addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0), "payee is the zero address");
    require(_shares > 0, "shares are 0");
    require(shares[_payee] == 0, "payee already has shares");

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
    emit PayeeAdded(_payee, _shares);
  }

  /**
    Updates the payee configuration to a new one.
    @dev will release existing fees before the update.
    @param _payees Array of payees
    @param _shares Array of shares for each payee
  */
  function changePayees(address[] memory _payees, uint256[] memory _shares) public override onlyManager {
    require(_payees.length == _shares.length, "Payees and shares mismatched");
    require(_payees.length > 0, "No payees");

    uint256 income = a.core().availableIncome();
    if (income > 0 && payees.length > 0) {
      release();
    }

    for (uint256 i = 0; i < payees.length; i++) {
      delete shares[payees[i]];
    }
    delete payees;
    totalShares = 0;

    for (uint256 i = 0; i < _payees.length; i++) {
      _addPayee(_payees[i], _shares[i]);
    }
  }
}

// solium-disable security/no-block-members
// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/ISTABLEX.sol";

/**
 * @title   USDX
 * @notice  Stablecoin which can be minted against collateral in a vault
 */
contract USDX is ISTABLEX, ERC20("USD Stablecoin", "USDX") {
  IAddressProvider public override a;

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  function mint(address account, uint256 amount) public override onlyMinter {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public override onlyMinter {
    _burn(account, amount);
  }

  modifier onlyMinter() {
    require(a.controller().hasRole(a.controller().MINTER_ROLE(), msg.sender), "Caller is not a minter");
    _;
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

// solium-disable security/no-block-members
// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/ISTABLEX.sol";

/**
 * @title  PAR
 * @notice  Stablecoin which can be minted against collateral in a vault
 */
contract PAR is ISTABLEX, ERC20("PAR Stablecoin", "PAR") {
  IAddressProvider public override a;

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  function mint(address account, uint256 amount) public override onlyMinter {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public override onlyMinter {
    _burn(account, amount);
  }

  modifier onlyMinter() {
    require(a.controller().hasRole(a.controller().MINTER_ROLE(), msg.sender), "Caller is not a minter");
    _;
  }
}

// solium-disable security/no-block-members
// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";

/**
 * @title  MIMO
 * @notice  MIMO Governance token
 */
contract MIMO is ERC20("MIMO Parallel Governance Token", "MIMO") {
  IGovernanceAddressProvider public a;

  bytes32 public constant MIMO_MINTER_ROLE = keccak256("MIMO_MINTER_ROLE");

  constructor(IGovernanceAddressProvider _a) public {
    require(address(_a) != address(0));

    a = _a;
  }

  modifier onlyMIMOMinter() {
    require(a.controller().hasRole(MIMO_MINTER_ROLE, msg.sender), "Caller is not MIMO Minter");
    _;
  }

  function mint(address account, uint256 amount) public onlyMIMOMinter {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public onlyMIMOMinter {
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../token/MIMO.sol";

import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "../liquidityMining/interfaces/IMIMODistributor.sol";

contract PreUseAirdrop {
  using SafeERC20 for IERC20;

  struct Payout {
    address recipient;
    uint256 amount;
  }

  Payout[] public payouts;

  IGovernanceAddressProvider public ga;
  IMIMODistributor public mimoDistributor;

  modifier onlyManager() {
    require(ga.controller().hasRole(ga.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  constructor(IGovernanceAddressProvider _ga, IMIMODistributor _mimoDistributor) public {
    require(address(_ga) != address(0));
    require(address(_mimoDistributor) != address(0));

    ga = _ga;
    mimoDistributor = _mimoDistributor;

    payouts.push(Payout(0xBBd92c75C6f8B0FFe9e5BCb2e56a5e2600871a10, 271147720731494841509243076));
    payouts.push(Payout(0xcc8793d5eB95fAa707ea4155e09b2D3F44F33D1E, 210989402066696530434956148));
    payouts.push(Payout(0x185f19B43d818E10a31BE68f445ef8EDCB8AFB83, 22182938994846641176273320));
    payouts.push(Payout(0xDeD9F901D40A96C3Ee558E6885bcc7eFC51ad078, 13678603288816593264718593));
    payouts.push(Payout(0x0B3890bbF2553Bd098B45006aDD734d6Fbd6089E, 8416873402881706143143730));
    payouts.push(Payout(0x3F41a1CFd3C8B8d9c162dE0f42307a0095A6e5DF, 7159719590701445955473554));
    payouts.push(Payout(0x9115BaDce4873d58fa73b08279529A796550999a, 5632453715407980754075398));
    payouts.push(Payout(0x7BC8C0B66d7f0E2193ED11eeCAAfE7c1837b926f, 5414893264683531027764823));
    payouts.push(Payout(0xE7809aaaaa78E5a24E059889E561f598F3a4664c, 4712320945661497844704387));
    payouts.push(Payout(0xf4D3566729f257edD0D4bF365d8f0Db7bF56e1C6, 2997276841876706895655431));
    payouts.push(Payout(0x6Cf9AA65EBaD7028536E353393630e2340ca6049, 2734992792750385321760387));
    payouts.push(Payout(0x74386381Cb384CC0FBa0Ac669d22f515FfC147D2, 1366427847282177615773594));
    payouts.push(Payout(0x9144b150f28437E06Ab5FF5190365294eb1E87ec, 1363226310703652991601514));
    payouts.push(Payout(0x5691d53685e8e219329bD8ADf62b1A0A17df9D11, 702790464733701088417744));
    payouts.push(Payout(0x2B91B4f5223a0a1f5c7e1D139dDdD6B5B57C7A51, 678663683269882192090830));
    payouts.push(Payout(0x8ddBad507F3b20239516810C308Ba4f3BaeAf3a1, 635520835923336863138335));
    payouts.push(Payout(0xc3874A2C59b9779A75874Be6B5f0b578120A8701, 488385391000796390198744));
    payouts.push(Payout(0x0A22C160f7E57F2e7d88b2fa1B1B03571bdE6128, 297735186117080365383063));
    payouts.push(Payout(0x0a1aa2b65832fC0c71f2Ba488c84BeE0b9DB9692, 132688033756581498940995));
    payouts.push(Payout(0xAf7b7AbC272a3aE6dD6dA41b9832C758477a85f2, 130254714680714068405131));
    payouts.push(Payout(0xCDb17d9bCbA8E3bab6F68D59065efe784700Bee1, 71018627162763037055295));
    payouts.push(Payout(0x4Dec19003F9Bb01A4c0D089605618b2d76deE30d, 69655357581389001902516));
    payouts.push(Payout(0x31AacA1940C82130c2D4407E609e626E87A7BC18, 21678478730854029506989));
    payouts.push(Payout(0xBc77AB8dd8BAa6ddf0D0c241d31b2e30bcEC127d, 21573657481017931484432));
    payouts.push(Payout(0x1c25cDD83Cd7106C3dcB361230eC9E6930Aadd30, 14188368728356337446426));
    payouts.push(Payout(0xf1B78ed53fa2f9B8cFfa677Ad8023aCa92109d08, 13831474058511281838532));
    payouts.push(Payout(0xd27962455de27561e62345a516931F2392997263, 6968208393315527988941));
    payouts.push(Payout(0xD8A4411C623aD361E98bC9D98cA33eE1cF308Bca, 4476771187861728227997));
    payouts.push(Payout(0x1f06fA59809ee23Ee06e533D67D29C6564fC1964, 3358338614042115121460));
    payouts.push(Payout(0xeDccc1501e3BCC8b3973B9BE33f6Bd7072d28388, 2328788070517256560738));
    payouts.push(Payout(0xD738A884B2aFE625d372260E57e86E3eB4d5e1D7, 466769668474372743140));
    payouts.push(Payout(0x6942b1b6526Fa05035d47c09B419039c00Ef7545, 442736084997163005698));
  }

  function airdrop() public onlyManager {
    MIMO mimo = MIMO(address(ga.mimo()));
    for (uint256 i = 0; i < payouts.length; i++) {
      Payout memory payout = payouts[i];
      mimo.mint(payout.recipient, payout.amount);
    }
    require(mimoDistributor.mintableTokens() > 0);

    bytes32 MIMO_MINTER_ROLE = mimo.MIMO_MINTER_ROLE();
    ga.controller().renounceRole(MIMO_MINTER_ROLE, address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./interfaces/IMIMODistributor.sol";
import "./BaseDistributor.sol";

contract MIMODistributorV2 is BaseDistributor, IMIMODistributorExtension {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 private constant _SECONDS_PER_YEAR = 365 days;
  uint256 private constant _SECONDS_PER_WEEK = 7 days;
  uint256 private constant _WEEKLY_R = 986125e21; // -1.3875% per week (-5.55% / 4)
  uint256 private _FIRST_WEEK_TOKENS;

  uint256 public override startTime;
  uint256 public alreadyMinted;

  constructor(
    IGovernanceAddressProvider _a,
    uint256 _startTime,
    IMIMODistributor _mimoDistributor
  ) public {
    require(address(_a) != address(0));
    require(address(_mimoDistributor) != address(0));

    a = _a;
    startTime = _startTime;
    alreadyMinted = _mimoDistributor.totalSupplyAt(startTime);

    uint256 weeklyIssuanceV1 = _mimoDistributor.weeklyIssuanceAt(startTime);
    _FIRST_WEEK_TOKENS = weeklyIssuanceV1 / 4; // reduce weeky issuance by 4
  }

  /**
    Get current monthly issuance of new MIMO tokens.
    @return number of monthly issued tokens currently`.
  */
  function currentIssuance() public view override returns (uint256) {
    return weeklyIssuanceAt(now);
  }

  /**
    Get monthly issuance of new MIMO tokens at `timestamp`.
    @dev invalid for timestamps before deployment
    @param timestamp for which to calculate the monthly issuance
    @return number of monthly issued tokens at `timestamp`.
  */
  function weeklyIssuanceAt(uint256 timestamp) public view override returns (uint256) {
    uint256 elapsedSeconds = timestamp.sub(startTime);
    uint256 elapsedWeeks = elapsedSeconds.div(_SECONDS_PER_WEEK);
    return _WEEKLY_R.rayPow(elapsedWeeks).rayMul(_FIRST_WEEK_TOKENS);
  }

  /**
    Calculates how many MIMO tokens can be minted since the last time tokens were minted
    @return number of mintable tokens available right now.
  */
  function mintableTokens() public view override returns (uint256) {
    return totalSupplyAt(now).sub(a.mimo().totalSupply());
  }

  /**
    Calculates the totalSupply for any point after `startTime`
    @param timestamp for which to calculate the totalSupply
    @return totalSupply at timestamp.
  */
  function totalSupplyAt(uint256 timestamp) public view override returns (uint256) {
    uint256 elapsedSeconds = timestamp.sub(startTime);
    uint256 elapsedWeeks = elapsedSeconds.div(_SECONDS_PER_WEEK);
    uint256 lastWeekSeconds = elapsedSeconds % _SECONDS_PER_WEEK;
    uint256 one = WadRayMath.ray();
    uint256 fullWeeks = one.sub(_WEEKLY_R.rayPow(elapsedWeeks)).rayMul(_FIRST_WEEK_TOKENS).rayDiv(one.sub(_WEEKLY_R));
    uint256 currentWeekIssuance = weeklyIssuanceAt(timestamp);
    uint256 partialWeek = currentWeekIssuance.mul(lastWeekSeconds).div(_SECONDS_PER_WEEK);
    return alreadyMinted.add(fullWeeks.add(partialWeek));
  }

  /**
    Internal function to release a percentage of newTokens to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalnewTokensReceived Total newTokens for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalnewTokensReceived, address _payee) internal override {
    uint256 payment = _totalnewTokensReceived.mul(shares[_payee]).div(totalShares);
    a.mimo().mint(_payee, payment);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./interfaces/IBaseDistributor.sol";

/*
  	Distribution Formula:
  	55.5m MIMO in first week
  	-5.55% redution per week

  	total(timestamp) = _SECONDS_PER_WEEK * ( (1-weeklyR^(timestamp/_SECONDS_PER_WEEK)) / (1-weeklyR) )
  		+ timestamp % _SECONDS_PER_WEEK * (1-weeklyR^(timestamp/_SECONDS_PER_WEEK)
  */

abstract contract BaseDistributor is IBaseDistributor {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 public override totalShares;
  mapping(address => uint256) public override shares;
  address[] public payees;

  IGovernanceAddressProvider public override a;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not Manager");
    _;
  }

  /**
    Public function to release the accumulated new MIMO tokens to the payees.
    @dev anyone can call this.
  */
  function release() public override {
    uint256 newTokens = mintableTokens();
    require(newTokens > 0, "newTokens is 0");
    require(payees.length > 0, "Payees not configured yet");
    // Mint MIMO to all receivers
    for (uint256 i = 0; i < payees.length; i++) {
      address payee = payees[i];
      _release(newTokens, payee);
    }
    emit TokensReleased(newTokens, now);
  }

  /**
    Updates the payee configuration to a new one.
    @dev will release existing fees before the update.
    @param _payees Array of payees
    @param _shares Array of shares for each payee
  */
  function changePayees(address[] memory _payees, uint256[] memory _shares) public override onlyManager {
    require(_payees.length == _shares.length, "Payees and shares mismatched");
    require(_payees.length > 0, "No payees");

    if (payees.length > 0 && mintableTokens() > 0) {
      release();
    }

    for (uint256 i = 0; i < payees.length; i++) {
      delete shares[payees[i]];
    }
    delete payees;
    totalShares = 0;

    for (uint256 i = 0; i < _payees.length; i++) {
      _addPayee(_payees[i], _shares[i]);
    }
  }

  /**
    Get current configured payees.
    @return array of current payees.
  */
  function getPayees() public view override returns (address[] memory) {
    return payees;
  }

  /**
    Calculates how many MIMO tokens can be minted since the last time tokens were minted
    @return number of mintable tokens available right now.
  */
  function mintableTokens() public view virtual override returns (uint256);

  /**
    Internal function to release a percentage of newTokens to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalnewTokensReceived Total newTokens for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalnewTokensReceived, address _payee) internal virtual;

  /**
    Internal function to add a new payee.
    @dev will update totalShares and therefore reduce the relative share of all other payees.
    @param _payee The address of the payee to add.
    @param _shares The number of shares owned by the payee.
  */
  function _addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0), "payee is the zero address");
    require(_shares > 0, "shares are 0");
    require(shares[_payee] == 0, "payee already has shares");

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
    emit PayeeAdded(_payee, _shares);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/interfaces/IRootChainManager.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./BaseDistributor.sol";

contract PolygonDistributor is BaseDistributor {
  using SafeMath for uint256;

  IRootChainManager public rootChainManager;
  address public erc20Predicate;

  constructor(
    IGovernanceAddressProvider _a,
    IRootChainManager _rootChainManager,
    address _erc20Predicate
  ) public {
    require(address(_a) != address(0));
    require(address(_rootChainManager) != address(0));
    require(_erc20Predicate != address(0));

    a = _a;
    rootChainManager = _rootChainManager;
    erc20Predicate = _erc20Predicate;
  }

  /**
    Calculates how many MIMO tokens can be minted since the last time tokens were minted
    @return number of mintable tokens available right now.
  */
  function mintableTokens() public view override returns (uint256) {
    return a.mimo().balanceOf(address(this));
  }

  /**
    Internal function to release a percentage of newTokens to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalnewTokensReceived Total newTokens for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalnewTokensReceived, address _payee) internal override {
    uint256 payment = _totalnewTokensReceived.mul(shares[_payee]).div(totalShares);
    a.mimo().approve(erc20Predicate, payment);
    rootChainManager.depositFor(_payee, address(a.mimo()), abi.encode(payment));
  }
}

pragma solidity 0.6.12;

interface IRootChainManager {
  event TokenMapped(address indexed rootToken, address indexed childToken, bytes32 indexed tokenType);

  event PredicateRegistered(bytes32 indexed tokenType, address indexed predicateAddress);

  function registerPredicate(bytes32 tokenType, address predicateAddress) external;

  function mapToken(
    address rootToken,
    address childToken,
    bytes32 tokenType
  ) external;

  function depositEtherFor(address user) external payable;

  function depositFor(
    address user,
    address rootToken,
    bytes calldata depositData
  ) external;

  function exit(bytes calldata inputData) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../liquidityMining/GenericMiner.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";

contract MockGenericMiner is GenericMiner {
  constructor(IGovernanceAddressProvider _addresses) public GenericMiner(_addresses) {}

  function increaseStake(address user, uint256 value) public {
    _increaseStake(user, value);
  }

  function decreaseStake(address user, uint256 value) public {
    _decreaseStake(user, value);
  }
}

//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "./interfaces/IGenericMiner.sol";

/*
    GenericMiner is based on ERC2917. https://github.com/gnufoo/ERC2917-Proposal

    The Objective of GenericMiner is to implement a decentralized staking mechanism, which calculates _users' share
    by accumulating stake * time. And calculates _users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_stake(time1) - user_accumulated_stake(time0)
       _____________________________________________________________________________  * (gross_stake(t1) - gross_stake(t0))
       total_accumulated_stake(time1) - total_accumulated_stake(time0)

*/
contract GenericMiner is IGenericMiner {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  mapping(address => UserInfo) internal _users;

  uint256 public override totalStake;
  IGovernanceAddressProvider public override a;

  uint256 internal _balanceTracker;
  uint256 internal _accAmountPerShare;

  constructor(IGovernanceAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Releases the outstanding MIMO balance to the user.
    @param _user the address of the user for which the MIMO tokens will be released.
  */
  function releaseMIMO(address _user) public virtual override {
    UserInfo storage userInfo = _users[_user];
    _refresh();
    uint256 pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
    _balanceTracker = _balanceTracker.sub(pending);
    userInfo.accAmountPerShare = _accAmountPerShare;
    require(a.mimo().transfer(_user, pending));
  }

  /**
    Returns the number of tokens a user has staked.
    @param _user the address of the user.
    @return number of staked tokens
  */
  function stake(address _user) public view override returns (uint256) {
    return _users[_user].stake;
  }

  /**
    Returns the number of tokens a user can claim via `releaseMIMO`.
    @param _user the address of the user.
    @return number of MIMO tokens that the user can claim
  */
  function pendingMIMO(address _user) public view override returns (uint256) {
    uint256 currentBalance = a.mimo().balanceOf(address(this));
    uint256 reward = currentBalance.sub(_balanceTracker);
    uint256 accAmountPerShare = _accAmountPerShare.add(reward.rayDiv(totalStake));

    return _users[_user].stake.rayMul(accAmountPerShare.sub(_users[_user].accAmountPerShare));
  }

  /**
    Returns the userInfo stored of a user.
    @param _user the address of the user.
    @return `struct UserInfo {
      uint256 stake;
      uint256 rewardDebt;
    }`
  **/
  function userInfo(address _user) public view override returns (UserInfo memory) {
    return _users[_user];
  }

  /**
    Refreshes the global state and subsequently decreases the stake a user has.
    This is an internal call and meant to be called within derivative contracts.
    @param user the address of the user
    @param value the amount by which the stake will be reduced
  */
  function _decreaseStake(address user, uint256 value) internal {
    require(value > 0, "STAKE_MUST_BE_GREATER_THAN_ZERO"); //TODO cleanup error message

    UserInfo storage userInfo = _users[user];
    require(userInfo.stake >= value, "INSUFFICIENT_STAKE_FOR_USER"); //TODO cleanup error message
    _refresh();
    uint256 pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
    _balanceTracker = _balanceTracker.sub(pending);
    userInfo.stake = userInfo.stake.sub(value);
    userInfo.accAmountPerShare = _accAmountPerShare;
    totalStake = totalStake.sub(value);

    require(a.mimo().transfer(user, pending));
    emit StakeDecreased(user, value);
  }

  /**
    Refreshes the global state and subsequently increases a user's stake.
    This is an internal call and meant to be called within derivative contracts.
    @param user the address of the user
    @param value the amount by which the stake will be increased
  */
  function _increaseStake(address user, uint256 value) internal {
    require(value > 0, "STAKE_MUST_BE_GREATER_THAN_ZERO"); //TODO cleanup error message

    UserInfo storage userInfo = _users[user];
    _refresh();

    uint256 pending;
    if (userInfo.stake > 0) {
      pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
      _balanceTracker = _balanceTracker.sub(pending);
    }

    totalStake = totalStake.add(value);
    userInfo.stake = userInfo.stake.add(value);
    userInfo.accAmountPerShare = _accAmountPerShare;

    if (pending > 0) {
      require(a.mimo().transfer(user, pending));
    }

    emit StakeIncreased(user, value);
  }

  /**
    Refreshes the global state and subsequently updates a user's stake.
    This is an internal call and meant to be called within derivative contracts.
    @param user the address of the user
    @param stake the new amount of stake for the user
  */
  function _updateStake(address user, uint256 stake) internal returns (bool) {
    uint256 oldStake = _users[user].stake;
    if (stake > oldStake) {
      _increaseStake(user, stake.sub(oldStake));
    }
    if (stake < oldStake) {
      _decreaseStake(user, oldStake.sub(stake));
    }
  }

  /**
    Internal read function to calculate the number of MIMO tokens that
    have accumulated since the last token release.
    @dev This is an internal call and meant to be called within derivative contracts.
    @return newly accumulated token balance
  */
  function _newTokensReceived() internal view returns (uint256) {
    return a.mimo().balanceOf(address(this)).sub(_balanceTracker);
  }

  /**
    Updates the internal state variables after accounting for newly received MIMO tokens.
  */
  function _refresh() internal {
    if (totalStake == 0) {
      return;
    }
    uint256 currentBalance = a.mimo().balanceOf(address(this));
    uint256 reward = currentBalance.sub(_balanceTracker);
    _balanceTracker = currentBalance;

    _accAmountPerShare = _accAmountPerShare.add(reward.rayDiv(totalStake));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./GenericMiner.sol";
import "./interfaces/IVotingMiner.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "../governance/interfaces/IVotingEscrow.sol";

contract VotingMiner is IVotingMiner, GenericMiner {
  constructor(IGovernanceAddressProvider _addresses) public GenericMiner(_addresses) {}

  /**
    Releases the outstanding MIMO balance to the user.
    @param _user the address of the user for which the MIMO tokens will be released.
  */
  function releaseMIMO(address _user) public override {
    IVotingEscrow votingEscrow = a.votingEscrow();
    require((msg.sender == _user) || (msg.sender == address(votingEscrow)));

    UserInfo storage userInfo = _users[_user];
    _refresh();
    uint256 pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
    _balanceTracker = _balanceTracker.sub(pending);
    userInfo.accAmountPerShare = _accAmountPerShare;

    uint256 votingPower = votingEscrow.balanceOf(_user);
    totalStake = totalStake.add(votingPower).sub(userInfo.stake);
    userInfo.stake = votingPower;

    if (pending > 0) {
      require(a.mimo().transfer(_user, pending));
    }
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IVotingMiner {}

// SPDX-License-Identifier: AGPL-3.0
/* solium-disable security/no-block-members */
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IGovernanceAddressProvider.sol";
import "../liquidityMining/interfaces/IGenericMiner.sol";

/**
 * @title  VotingEscrow
 * @notice Lockup GOV, receive vGOV (voting weight that decays over time)
 * @dev    Supports:
 *            1) Tracking MIMO Locked up
 *            2) Decaying voting weight lookup
 *            3) Closure of contract
 */
contract VotingEscrow is IVotingEscrow, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant MAXTIME = 1460 days; // 365 * 4 years
  uint256 public minimumLockTime = 1 days;
  bool public expired = false;
  IERC20 public override stakingToken;

  mapping(address => LockedBalance) public locked;

  string public override name;
  string public override symbol;
  // solhint-disable-next-line
  uint256 public constant override decimals = 18;

  // AddressProvider
  IGovernanceAddressProvider public a;
  IGenericMiner public miner;

  constructor(
    IERC20 _stakingToken,
    IGovernanceAddressProvider _a,
    IGenericMiner _miner,
    string memory _name,
    string memory _symbol
  ) public {
    require(address(_stakingToken) != address(0));
    require(address(_a) != address(0));
    require(address(_miner) != address(0));

    stakingToken = _stakingToken;
    a = _a;
    miner = _miner;

    name = _name;
    symbol = _symbol;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /** @dev Modifier to ensure contract has not yet expired */
  modifier contractNotExpired() {
    require(!expired, "Contract is expired");
    _;
  }

  /**
   * @dev Creates a new lock
   * @param _value Total units of StakingToken to lockup
   * @param _unlockTime Time at which the stake should unlock
   */
  function createLock(uint256 _value, uint256 _unlockTime) external override nonReentrant contractNotExpired {
    LockedBalance memory locked_ = LockedBalance({ amount: locked[msg.sender].amount, end: locked[msg.sender].end });

    require(_value > 0, "Must stake non zero amount");
    require(locked_.amount == 0, "Withdraw old tokens first");
    require(_unlockTime > block.timestamp, "Can only lock until time in the future");
    require(_unlockTime.sub(block.timestamp) > minimumLockTime, "Lock duration should be larger than minimum locktime");

    _depositFor(msg.sender, _value, _unlockTime, locked_, LockAction.CREATE_LOCK);
  }

  /**
   * @dev Increases amount of stake thats locked up & resets decay
   * @param _value Additional units of StakingToken to add to exiting stake
   */
  function increaseLockAmount(uint256 _value) external override nonReentrant contractNotExpired {
    LockedBalance memory locked_ = LockedBalance({ amount: locked[msg.sender].amount, end: locked[msg.sender].end });

    require(_value > 0, "Must stake non zero amount");
    require(locked_.amount > 0, "No existing lock found");
    require(locked_.end > block.timestamp, "Cannot add to expired lock. Withdraw");

    _depositFor(msg.sender, _value, 0, locked_, LockAction.INCREASE_LOCK_AMOUNT);
  }

  /**
   * @dev Increases length of lockup & resets decay
   * @param _unlockTime New unlocktime for lockup
   */
  function increaseLockLength(uint256 _unlockTime) external override nonReentrant contractNotExpired {
    LockedBalance memory locked_ = LockedBalance({ amount: locked[msg.sender].amount, end: locked[msg.sender].end });

    require(locked_.amount > 0, "Nothing is locked");
    require(locked_.end > block.timestamp, "Lock expired");
    require(_unlockTime > locked_.end, "Can only increase lock time");
    require(_unlockTime.sub(locked_.end) > minimumLockTime, "Lock duration should be larger than minimum locktime");

    _depositFor(msg.sender, 0, _unlockTime, locked_, LockAction.INCREASE_LOCK_TIME);
  }

  /**
   * @dev Withdraws all the senders stake, providing lockup is over
   */
  function withdraw() external override {
    _withdraw(msg.sender);
  }

  /**
   * @dev Ends the contract, unlocking all stakes.
   * No more staking can happen. Only withdraw.
   */
  function expireContract() external override onlyManager contractNotExpired {
    expired = true;
    emit Expired();
  }

  /**
   * @dev Set miner address.
   * @param _miner new miner contract address
   */
  function setMiner(IGenericMiner _miner) external override onlyManager contractNotExpired {
    miner = _miner;
  }

  /**
   * @dev Set minimumLockTime.
   * @param _minimumLockTime minimum lockTime
   */
  function setMinimumLockTime(uint256 _minimumLockTime) external override onlyManager contractNotExpired {
    minimumLockTime = _minimumLockTime;
  }

  /***************************************
                    GETTERS
    ****************************************/

  /**
   * @dev Gets the user's votingWeight at the current time.
   * @param _owner User for which to return the votingWeight
   * @return uint256 Balance of user
   */
  function balanceOf(address _owner) public view override returns (uint256) {
    return balanceOfAt(_owner, block.timestamp);
  }

  /**
   * @dev Gets a users votingWeight at a given block timestamp
   * @param _owner User for which to return the balance
   * @param _blockTime Timestamp for which to calculate balance. Can not be in the past
   * @return uint256 Balance of user
   */
  function balanceOfAt(address _owner, uint256 _blockTime) public view override returns (uint256) {
    require(_blockTime >= block.timestamp, "Must pass block timestamp in the future");

    LockedBalance memory currentLock = locked[_owner];

    if (currentLock.end <= _blockTime) return 0;
    uint256 remainingLocktime = currentLock.end.sub(_blockTime);
    if (remainingLocktime > MAXTIME) {
      remainingLocktime = MAXTIME;
    }

    return currentLock.amount.mul(remainingLocktime).div(MAXTIME);
  }

  /**
   * @dev Deposits or creates a stake for a given address
   * @param _addr User address to assign the stake
   * @param _value Total units of StakingToken to lockup
   * @param _unlockTime Time at which the stake should unlock
   * @param _oldLocked Previous amount staked by this user
   * @param _action See LockAction enum
   */
  function _depositFor(
    address _addr,
    uint256 _value,
    uint256 _unlockTime,
    LockedBalance memory _oldLocked,
    LockAction _action
  ) internal {
    LockedBalance memory newLocked = LockedBalance({ amount: _oldLocked.amount, end: _oldLocked.end });

    // Adding to existing lock, or if a lock is expired - creating a new one
    newLocked.amount = newLocked.amount.add(_value);
    if (_unlockTime != 0) {
      newLocked.end = _unlockTime;
    }
    locked[_addr] = newLocked;

    if (_value != 0) {
      stakingToken.safeTransferFrom(_addr, address(this), _value);
    }

    miner.releaseMIMO(_addr);

    emit Deposit(_addr, _value, newLocked.end, _action, block.timestamp);
  }

  /**
   * @dev Withdraws a given users stake, providing the lockup has finished
   * @param _addr User for which to withdraw
   */
  function _withdraw(address _addr) internal nonReentrant {
    LockedBalance memory oldLock = LockedBalance({ end: locked[_addr].end, amount: locked[_addr].amount });
    require(block.timestamp >= oldLock.end || expired, "The lock didn't expire");
    require(oldLock.amount > 0, "Must have something to withdraw");

    uint256 value = uint256(oldLock.amount);

    LockedBalance memory currentLock = LockedBalance({ end: 0, amount: 0 });
    locked[_addr] = currentLock;

    stakingToken.safeTransfer(_addr, value);
    miner.releaseMIMO(_addr);

    emit Withdraw(_addr, value, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IMIMO.sol";
import "./interfaces/IGenericMiner.sol";

import "hardhat/console.sol";

contract PARMiner {
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 stake;
    uint256 accAmountPerShare;
    uint256 accParAmountPerShare;
  }

  event StakeIncreased(address indexed user, uint256 stake);
  event StakeDecreased(address indexed user, uint256 stake);

  IERC20 public par;

  mapping(address => UserInfo) internal _users;

  uint256 public totalStake;
  IGovernanceAddressProvider public a;

  uint256 internal _balanceTracker;
  uint256 internal _accAmountPerShare;

  uint256 internal _parBalanceTracker;
  uint256 internal _accParAmountPerShare;

  constructor(IGovernanceAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;

    par = IERC20(_addresses.parallel().stablex());
  }

  /**
    Deposit an ERC20 pool token for staking
    @dev this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param amount the amount of tokens to be deposited. Unit is in WEI.
  **/
  function deposit(uint256 amount) public {
    par.safeTransferFrom(msg.sender, address(this), amount);
    _increaseStake(msg.sender, amount);
  }

  /**
    Withdraw staked ERC20 pool tokens. Will fail if user does not have enough tokens staked.
    @param amount the amount of tokens to be withdrawn. Unit is in WEI.
  **/
  function withdraw(uint256 amount) public {
    par.safeTransfer(msg.sender, amount);
    _decreaseStake(msg.sender, amount);
  }

  /**
    Releases the outstanding MIMO balance to the user.
    @param _user the address of the user for which the MIMO tokens will be released.
  */
  function releaseMIMO(address _user) public virtual {
    UserInfo storage userInfo = _users[_user];
    _refresh();
    _refreshPAR(totalStake);
    uint256 pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
    _balanceTracker = _balanceTracker.sub(pending);
    userInfo.accAmountPerShare = _accAmountPerShare;
    require(a.mimo().transfer(_user, pending));
  }

  /**
    Releases the outstanding PAR reward balance to the user.
    @param _user the address of the user for which the PAR tokens will be released.
  */
  function releasePAR(address _user) public virtual {
    UserInfo storage userInfo = _users[_user];
    _refresh();
    _refreshPAR(totalStake);
    uint256 pending = userInfo.stake.rayMul(_accParAmountPerShare.sub(userInfo.accParAmountPerShare));
    _parBalanceTracker = _parBalanceTracker.sub(pending);
    userInfo.accParAmountPerShare = _accParAmountPerShare;
    require(par.transfer(_user, pending));
  }

  /**
    Restakes the outstanding PAR reward balance to the user. Instead of sending the PAR to the user, it will be added to their stake
    @param _user the address of the user for which the PAR tokens will be restaked.
  */
  function restakePAR(address _user) public virtual {
    UserInfo storage userInfo = _users[_user];
    _refresh();
    _refreshPAR(totalStake);
    uint256 pending = userInfo.stake.rayMul(_accParAmountPerShare.sub(userInfo.accParAmountPerShare));
    _parBalanceTracker = _parBalanceTracker.sub(pending);
    userInfo.accParAmountPerShare = _accParAmountPerShare;

    _increaseStake(_user, pending);
  }

  /**
    Returns the number of tokens a user has staked.
    @param _user the address of the user.
    @return number of staked tokens
  */
  function stake(address _user) public view returns (uint256) {
    return _users[_user].stake;
  }

  /**
    Returns the number of tokens a user can claim via `releaseMIMO`.
    @param _user the address of the user.
    @return number of MIMO tokens that the user can claim
  */
  function pendingMIMO(address _user) public view returns (uint256) {
    uint256 currentBalance = a.mimo().balanceOf(address(this));
    uint256 reward = currentBalance.sub(_balanceTracker);
    uint256 accAmountPerShare = _accAmountPerShare.add(reward.rayDiv(totalStake));

    return _users[_user].stake.rayMul(accAmountPerShare.sub(_users[_user].accAmountPerShare));
  }

  /**
    Returns the number of PAR tokens the user has earned as a reward
    @param _user the address of the user.
    @return nnumber of PAR tokens that will be sent automatically when staking/unstaking
  */
  function pendingPAR(address _user) public view returns (uint256) {
    uint256 currentBalance = par.balanceOf(address(this)).sub(totalStake);
    uint256 reward = currentBalance.sub(_parBalanceTracker);
    uint256 accParAmountPerShare = _accParAmountPerShare.add(reward.rayDiv(totalStake));

    return _users[_user].stake.rayMul(accParAmountPerShare.sub(_users[_user].accParAmountPerShare));
  }

  /**
    Returns the userInfo stored of a user.
    @param _user the address of the user.
    @return `struct UserInfo {
      uint256 stake;
      uint256 rewardDebt;
    }`
  **/
  function userInfo(address _user) public view returns (UserInfo memory) {
    return _users[_user];
  }

  /**
    Refreshes the global state and subsequently decreases the stake a user has.
    This is an internal call and meant to be called within derivative contracts.
    @param user the address of the user
    @param value the amount by which the stake will be reduced
  */
  function _decreaseStake(address user, uint256 value) internal {
    require(value > 0, "STAKE_MUST_BE_GREATER_THAN_ZERO"); //TODO cleanup error message

    UserInfo storage userInfo = _users[user];
    require(userInfo.stake >= value, "INSUFFICIENT_STAKE_FOR_USER"); //TODO cleanup error message
    _refresh();
    uint256 newTotalStake = totalStake.sub(value);
    _refreshPAR(newTotalStake);

    uint256 pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
    _balanceTracker = _balanceTracker.sub(pending);
    userInfo.accAmountPerShare = _accAmountPerShare;

    uint256 pendingPAR = userInfo.stake.rayMul(_accParAmountPerShare.sub(userInfo.accParAmountPerShare));

    _parBalanceTracker = _parBalanceTracker.sub(pendingPAR);
    userInfo.accParAmountPerShare = _accParAmountPerShare;

    userInfo.stake = userInfo.stake.sub(value);
    totalStake = newTotalStake;

    if (pending > 0) {
      require(a.mimo().transfer(user, pending));
    }
    if (pendingPAR > 0) {
      require(par.transfer(user, pendingPAR));
    }

    emit StakeDecreased(user, value);
  }

  /**
    Refreshes the global state and subsequently increases a user's stake.
    This is an internal call and meant to be called within derivative contracts.
    @param user the address of the user
    @param value the amount by which the stake will be increased
  */
  function _increaseStake(address user, uint256 value) internal {
    require(value > 0, "STAKE_MUST_BE_GREATER_THAN_ZERO"); //TODO cleanup error message

    UserInfo storage userInfo = _users[user];

    _refresh();

    uint256 newTotalStake = totalStake.add(value);
    _refreshPAR(newTotalStake);

    uint256 pending;
    uint256 pendingPAR;
    if (userInfo.stake > 0) {
      pending = userInfo.stake.rayMul(_accAmountPerShare.sub(userInfo.accAmountPerShare));
      _balanceTracker = _balanceTracker.sub(pending);

      // maybe we should add the accumulated PAR to the stake of the user instead?
      pendingPAR = userInfo.stake.rayMul(_accParAmountPerShare.sub(userInfo.accParAmountPerShare));
      _parBalanceTracker = _parBalanceTracker.sub(pendingPAR);
    }

    totalStake = newTotalStake;
    userInfo.stake = userInfo.stake.add(value);

    userInfo.accAmountPerShare = _accAmountPerShare;
    userInfo.accParAmountPerShare = _accParAmountPerShare;

    if (pendingPAR > 0) {
      // add pendingPAR balance to stake and totalStake instead of sending it back
      userInfo.stake = userInfo.stake.add(pendingPAR);
      totalStake = totalStake.add(pendingPAR);
    }
    if (pending > 0) {
      require(a.mimo().transfer(user, pending));
    }

    emit StakeIncreased(user, value.add(pendingPAR));
  }

  /**
    Refreshes the global state and subsequently updates a user's stake.
    This is an internal call and meant to be called within derivative contracts.
    @param user the address of the user
    @param stake the new amount of stake for the user
  */
  function _updateStake(address user, uint256 stake) internal returns (bool) {
    uint256 oldStake = _users[user].stake;
    if (stake > oldStake) {
      _increaseStake(user, stake.sub(oldStake));
    }
    if (stake < oldStake) {
      _decreaseStake(user, oldStake.sub(stake));
    }
  }

  /**
    Updates the internal state variables after accounting for newly received MIMO tokens.
  */
  function _refresh() internal {
    if (totalStake == 0) {
      return;
    }
    uint256 currentBalance = a.mimo().balanceOf(address(this));
    uint256 reward = currentBalance.sub(_balanceTracker);
    _balanceTracker = currentBalance;
    _accAmountPerShare = _accAmountPerShare.add(reward.rayDiv(totalStake));
  }

  /**
    Updates the internal state variables after accounting for newly received PAR tokens.
  */
  function _refreshPAR(uint256 newTotalStake) internal {
    if (totalStake == 0) {
      return;
    }
    uint256 currentParBalance = par.balanceOf(address(this)).sub(newTotalStake);
    uint256 parReward = currentParBalance.sub(_parBalanceTracker);

    _parBalanceTracker = currentParBalance;
    _accParAmountPerShare = _accParAmountPerShare.add(parReward.rayDiv(totalStake));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./GenericMiner.sol";
import "./interfaces/IMIMO.sol";
import "./interfaces/IDemandMiner.sol";

contract DemandMiner is IDemandMiner, GenericMiner {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public override token;

  constructor(IGovernanceAddressProvider _addresses, IERC20 _token) public GenericMiner(_addresses) {
    require(address(_token) != address(0));
    require(address(_token) != address(_addresses.mimo()));
    token = _token;
  }

  /**
    Deposit an ERC20 pool token for staking
    @dev this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param amount the amount of tokens to be deposited. Unit is in WEI.
  **/
  function deposit(uint256 amount) public override {
    token.safeTransferFrom(msg.sender, address(this), amount);
    _increaseStake(msg.sender, amount);
  }

  /**
    Withdraw staked ERC20 pool tokens. Will fail if user does not have enough tokens staked.
    @param amount the amount of tokens to be withdrawn. Unit is in WEI.
  **/
  function withdraw(uint256 amount) public override {
    token.safeTransfer(msg.sender, amount);
    _decreaseStake(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./BaseDistributor.sol";

contract EthereumDistributor is BaseDistributor {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  constructor(IGovernanceAddressProvider _a) public {
    require(address(_a) != address(0));

    a = _a;
  }

  /**
    Calculates how many MIMO tokens can be minted since the last time tokens were minted
    @return number of mintable tokens available right now.
  */
  function mintableTokens() public view override returns (uint256) {
    return a.mimo().balanceOf(address(this));
  }

  /**
    Internal function to release a percentage of newTokens to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalnewTokensReceived Total newTokens for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalnewTokensReceived, address _payee) internal override {
    uint256 payment = _totalnewTokensReceived.mul(shares[_payee]).div(totalShares);
    IERC20(a.mimo()).safeTransfer(_payee, payment);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./interfaces/IGovernanceAddressProvider.sol";
import "./interfaces/IGovernorAlpha.sol";
import "./interfaces/ITimelock.sol";
import "./interfaces/IVotingEscrow.sol";
import "../interfaces/IAccessController.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";
import "../liquidityMining/interfaces/IMIMO.sol";

contract GovernanceAddressProvider is IGovernanceAddressProvider {
  IAddressProvider public override parallel;
  IMIMO public override mimo;
  IDebtNotifier public override debtNotifier;
  IGovernorAlpha public override governorAlpha;
  ITimelock public override timelock;
  IVotingEscrow public override votingEscrow;

  constructor(IAddressProvider _parallel) public {
    require(address(_parallel) != address(0));
    parallel = _parallel;
  }

  modifier onlyManager() {
    require(controller().hasRole(controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /**
    Update the `AddressProvider` address that points to main AddressProvider
    used in the Parallel Protocol
    @dev only manager can call this.
    @param _parallel the address of the new `AddressProvider` address.
  */
  function setParallelAddressProvider(IAddressProvider _parallel) public override onlyManager {
    require(address(_parallel) != address(0));
    parallel = _parallel;
  }

  /**
    Update the `MIMO` ERC20 token address
    @dev only manager can call this.
    @param _mimo the address of the new `MIMO` token address.
  */
  function setMIMO(IMIMO _mimo) public override onlyManager {
    require(address(_mimo) != address(0));
    mimo = _mimo;
  }

  /**
    Update the `DebtNotifier` address
    @dev only manager can call this.
    @param _debtNotifier the address of the new `DebtNotifier`.
  */
  function setDebtNotifier(IDebtNotifier _debtNotifier) public override onlyManager {
    require(address(_debtNotifier) != address(0));
    debtNotifier = _debtNotifier;
  }

  /**
    Update the `GovernorAlpha` address
    @dev only manager can call this.
    @param _governorAlpha the address of the new `GovernorAlpha`.
  */
  function setGovernorAlpha(IGovernorAlpha _governorAlpha) public override onlyManager {
    require(address(_governorAlpha) != address(0));
    governorAlpha = _governorAlpha;
  }

  /**
    Update the `Timelock` address
    @dev only manager can call this.
    @param _timelock the address of the new `Timelock`.
  */
  function setTimelock(ITimelock _timelock) public override onlyManager {
    require(address(_timelock) != address(0));
    timelock = _timelock;
  }

  /**
    Update the `VotingEscrow` address
    @dev only manager can call this.
    @param _votingEscrow the address of the new `VotingEscrow`.
  */
  function setVotingEscrow(IVotingEscrow _votingEscrow) public override onlyManager {
    require(address(_votingEscrow) != address(0));
    votingEscrow = _votingEscrow;
  }

  function controller() public view override returns (IAccessController) {
    return parallel.controller();
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCore.sol";
import "../interfaces/IAccessController.sol";
import "../interfaces/IConfigProvider.sol";
import "../interfaces/ISTABLEX.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IRatesManager.sol";
import "../interfaces/ILiquidationManager.sol";
import "../interfaces/IVaultsCore.sol";
import "../interfaces/IVaultsDataProvider.sol";

contract AddressProvider is IAddressProvider {
  IAccessController public override controller;
  IConfigProvider public override config;
  IVaultsCore public override core;

  ISTABLEX public override stablex;
  IRatesManager public override ratesManager;
  IPriceFeed public override priceFeed;
  ILiquidationManager public override liquidationManager;
  IVaultsDataProvider public override vaultsData;
  IFeeDistributor public override feeDistributor;

  constructor(IAccessController _controller) public {
    controller = _controller;
  }

  modifier onlyManager() {
    require(controller.hasRole(controller.MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  function setAccessController(IAccessController _controller) public override onlyManager {
    require(address(_controller) != address(0));
    controller = _controller;
  }

  function setConfigProvider(IConfigProvider _config) public override onlyManager {
    require(address(_config) != address(0));
    config = _config;
  }

  function setVaultsCore(IVaultsCore _core) public override onlyManager {
    require(address(_core) != address(0));
    core = _core;
  }

  function setStableX(ISTABLEX _stablex) public override onlyManager {
    require(address(_stablex) != address(0));
    stablex = _stablex;
  }

  function setRatesManager(IRatesManager _ratesManager) public override onlyManager {
    require(address(_ratesManager) != address(0));
    ratesManager = _ratesManager;
  }

  function setLiquidationManager(ILiquidationManager _liquidationManager) public override onlyManager {
    require(address(_liquidationManager) != address(0));
    liquidationManager = _liquidationManager;
  }

  function setPriceFeed(IPriceFeed _priceFeed) public override onlyManager {
    require(address(_priceFeed) != address(0));
    priceFeed = _priceFeed;
  }

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) public override onlyManager {
    require(address(_vaultsData) != address(0));
    vaultsData = _vaultsData;
  }

  function setFeeDistributor(IFeeDistributor _feeDistributor) public override onlyManager {
    require(address(_feeDistributor) != address(0));
    feeDistributor = _feeDistributor;
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./interfaces/ISupplyMiner.sol";
import "../interfaces/IVaultsDataProvider.sol";

contract DebtNotifier is IDebtNotifier {
  IGovernanceAddressProvider public override a;
  mapping(address => ISupplyMiner) public override collateralSupplyMinerMapping;

  constructor(IGovernanceAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  modifier onlyVaultsCore() {
    require(msg.sender == address(a.parallel().core()), "Caller is not VaultsCore");
    _;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender));
    _;
  }

  /**
    Notifies the correct supplyMiner of a change in debt.
    @dev Only the vaultsCore can call this.
    `debtChanged` will silently return if collateralType is not known to prevent any problems in vaultscore.
    @param _vaultId the ID of the vault of which the debt has changed.
  **/
  function debtChanged(uint256 _vaultId) public override onlyVaultsCore {
    IVaultsDataProvider.Vault memory v = a.parallel().vaultsData().vaults(_vaultId);

    ISupplyMiner supplyMiner = collateralSupplyMinerMapping[v.collateralType];
    if (address(supplyMiner) == address(0)) {
      // not throwing error so VaultsCore keeps working
      return;
    }
    supplyMiner.baseDebtChanged(v.owner, v.baseDebt);
  }

  /**
    Updates the collateral to supplyMiner mapping.
    @dev Manager role in the AccessController is required to call this.
    @param collateral the address of the collateralType.
    @param supplyMiner the address of the supplyMiner which will be notified on debt changes for this collateralType.
  **/
  function setCollateralSupplyMiner(address collateral, ISupplyMiner supplyMiner) public override onlyManager {
    collateralSupplyMinerMapping[collateral] = supplyMiner;
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GenericMiner.sol";
import "./interfaces/ISupplyMiner.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";

contract SupplyMiner is ISupplyMiner, GenericMiner {
  using SafeMath for uint256;

  constructor(IGovernanceAddressProvider _addresses) public GenericMiner(_addresses) {}

  modifier onlyNotifier() {
    require(msg.sender == address(a.debtNotifier()), "Caller is not DebtNotifier");
    _;
  }

  /**
    Gets called by the `DebtNotifier` and will update the stake of the user
    to match his current outstanding debt by using his baseDebt.
    @param user address of the user.
    @param newBaseDebt the new baseDebt and therefore stake for the user.
  */
  function baseDebtChanged(address user, uint256 newBaseDebt) public override onlyNotifier {
    _updateStake(user, newBaseDebt);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVaultsDataProvider.sol";
import "../interfaces/IAddressProvider.sol";

contract VaultsDataProvider is IVaultsDataProvider {
  using SafeMath for uint256;

  IAddressProvider public override a;

  uint256 public override vaultCount = 0;

  mapping(address => uint256) public override baseDebt;

  mapping(uint256 => Vault) private _vaults;
  mapping(address => mapping(address => uint256)) private _vaultOwners;

  modifier onlyVaultsCore() {
    require(msg.sender == address(a.core()), "Caller is not VaultsCore");
    _;
  }

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Opens a new vault.
    @dev only the vaultsCore module can call this function
    @param _collateralType address to the collateral asset e.g. WETH
    @param _owner the owner of the new vault.
  */
  function createVault(address _collateralType, address _owner) public override onlyVaultsCore returns (uint256) {
    require(_collateralType != address(0));
    require(_owner != address(0));
    uint256 newId = ++vaultCount;
    require(_collateralType != address(0), "collateralType unknown");
    Vault memory v = Vault({
      collateralType: _collateralType,
      owner: _owner,
      collateralBalance: 0,
      baseDebt: 0,
      createdAt: block.timestamp
    });
    _vaults[newId] = v;
    _vaultOwners[_owner][_collateralType] = newId;
    return newId;
  }

  /**
    Set the collateral balance of a vault.
    @dev only the vaultsCore module can call this function
    @param _id Vault ID of which the collateral balance will be updated
    @param _balance the new balance of the vault.
  */
  function setCollateralBalance(uint256 _id, uint256 _balance) public override onlyVaultsCore {
    require(vaultExists(_id), "Vault not found.");
    Vault storage v = _vaults[_id];
    v.collateralBalance = _balance;
  }

  /**
    Set the base debt of a vault.
    @dev only the vaultsCore module can call this function
    @param _id Vault ID of which the base debt will be updated
    @param _newBaseDebt the new base debt of the vault.
  */
  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) public override onlyVaultsCore {
    Vault storage _vault = _vaults[_id];
    if (_newBaseDebt > _vault.baseDebt) {
      uint256 increase = _newBaseDebt.sub(_vault.baseDebt);
      baseDebt[_vault.collateralType] = baseDebt[_vault.collateralType].add(increase);
    } else {
      uint256 decrease = _vault.baseDebt.sub(_newBaseDebt);
      baseDebt[_vault.collateralType] = baseDebt[_vault.collateralType].sub(decrease);
    }
    _vault.baseDebt = _newBaseDebt;
  }

  /**
    Get a vault by vault ID.
    @param _id The vault's ID to be retrieved
    @return struct Vault {
      address collateralType;
      address owner;
      uint256 collateralBalance;
      uint256 baseDebt;
      uint256 createdAt;
    }
  */
  function vaults(uint256 _id) public view override returns (Vault memory) {
    Vault memory v = _vaults[_id];
    return v;
  }

  /**
    Get the owner of a vault.
    @param _id the ID of the vault
    @return owner of the vault
  */
  function vaultOwner(uint256 _id) public view override returns (address) {
    return _vaults[_id].owner;
  }

  /**
    Get the collateral type of a vault.
    @param _id the ID of the vault
    @return address for the collateral type of the vault
  */
  function vaultCollateralType(uint256 _id) public view override returns (address) {
    return _vaults[_id].collateralType;
  }

  /**
    Get the collateral balance of a vault.
    @param _id the ID of the vault
    @return collateral balance of the vault
  */
  function vaultCollateralBalance(uint256 _id) public view override returns (uint256) {
    return _vaults[_id].collateralBalance;
  }

  /**
    Get the base debt of a vault.
    @param _id the ID of the vault
    @return base debt of the vault
  */
  function vaultBaseDebt(uint256 _id) public view override returns (uint256) {
    return _vaults[_id].baseDebt;
  }

  /**
    Retrieve the vault id for a specified owner and collateral type.
    @dev returns 0 for non-existing vaults
    @param _collateralType address of the collateral type (Eg: WETH)
    @param _owner address of the owner of the vault
    @return vault id of the vault or 0
  */
  function vaultId(address _collateralType, address _owner) public view override returns (uint256) {
    return _vaultOwners[_owner][_collateralType];
  }

  /**
    Checks if a specified vault exists.
    @param _id the ID of the vault
    @return boolean if the vault exists
  */
  function vaultExists(uint256 _id) public view override returns (bool) {
    Vault memory v = _vaults[_id];
    return v.collateralType != address(0);
  }

  /**
    Calculated the total outstanding debt for all vaults and all collateral types.
    @dev uses the existing cumulative rate. Call `refresh()` on `VaultsCore`
    to make sure it's up to date.
    @return total debt of the platform
  */
  function debt() public view override returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      total = total.add(collateralDebt(collateralType));
    }
    return total;
  }

  /**
    Calculated the total outstanding debt for all vaults of a specific collateral type.
    @dev uses the existing cumulative rate. Call `refreshCollateral()` on `VaultsCore`
    to make sure it's up to date.
    @param _collateralType address of the collateral type (Eg: WETH)
    @return total debt of the platform of one collateral type
  */
  function collateralDebt(address _collateralType) public view override returns (uint256) {
    return a.ratesManager().calculateDebt(baseDebt[_collateralType], a.core().cumulativeRates(_collateralType));
  }

  /**
    Calculated the total outstanding debt for a specific vault.
    @dev uses the existing cumulative rate. Call `refreshCollateral()` on `VaultsCore`
    to make sure it's up to date.
    @param _vaultId the ID of the vault
    @return total debt of one vault
  */
  function vaultDebt(uint256 _vaultId) public view override returns (uint256) {
    IVaultsDataProvider.Vault memory v = _vaults[_vaultId];
    return a.ratesManager().calculateDebt(v.baseDebt, a.core().cumulativeRates(v.collateralType));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "../interfaces/ILiquidationManager.sol";
import "../interfaces/IAddressProvider.sol";

contract LiquidationManager is ILiquidationManager, ReentrancyGuard {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  IAddressProvider public override a;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18; // 1

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Check if the health factor is above or equal to 1.
    @param _collateralValue value of the collateral in PAR
    @param _vaultDebt outstanding debt to which the collateral balance shall be compared
    @param _minRatio min ratio to calculate health factor
    @return boolean if the health factor is >= 1.
  */
  function isHealthy(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) public view override returns (bool) {
    uint256 healthFactor = calculateHealthFactor(_collateralValue, _vaultDebt, _minRatio);
    return healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
  }

  /**
    Calculate the healthfactor of a debt balance
    @param _collateralValue value of the collateral in PAR currency
    @param _vaultDebt outstanding debt to which the collateral balance shall be compared
    @param _minRatio min ratio to calculate health factor
    @return healthFactor
  */
  function calculateHealthFactor(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) public view override returns (uint256 healthFactor) {
    if (_vaultDebt == 0) return WadRayMath.wad();

    // CurrentCollateralizationRatio = value(deposited ETH) / debt
    uint256 collateralizationRatio = _collateralValue.wadDiv(_vaultDebt);

    // Healthfactor = CurrentCollateralizationRatio / MinimumCollateralizationRatio
    if (_minRatio > 0) {
      return collateralizationRatio.wadDiv(_minRatio);
    }

    return 1e18; // 1
  }

  /**
    Calculate the liquidation bonus for a specified amount
    @param _collateralType address of the collateral type
    @param _amount amount for which the liquidation bonus shall be calculated
    @return bonus the liquidation bonus to pay out
  */
  function liquidationBonus(address _collateralType, uint256 _amount) public view override returns (uint256 bonus) {
    return _amount.wadMul(a.config().collateralLiquidationBonus(_collateralType));
  }

  /**
    Apply the liquidation bonus to a balance as a discount.
    @param _collateralType address of the collateral type
    @param _amount the balance on which to apply to liquidation bonus as a discount.
    @return discountedAmount
  */
  function applyLiquidationDiscount(address _collateralType, uint256 _amount)
    public
    view
    override
    returns (uint256 discountedAmount)
  {
    return _amount.wadDiv(a.config().collateralLiquidationBonus(_collateralType).add(WadRayMath.wad()));
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../libraries/WadRayMath.sol";
import "../interfaces/ISTABLEX.sol";
import "../interfaces/IFeeDistributor.sol";
import "../interfaces/IAddressProvider.sol";

contract FeeDistributor is IFeeDistributor, ReentrancyGuard {
  using SafeMath for uint256;

  event PayeeAdded(address account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  uint256 public override lastReleasedAt;
  IAddressProvider public override a;

  uint256 public override totalShares;
  mapping(address => uint256) public override shares;
  address[] public payees;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not Manager");
    _;
  }

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Public function to release the accumulated fee income to the payees.
    @dev anyone can call this.
  */
  function release() public override nonReentrant {
    uint256 income = a.core().state().availableIncome();
    require(income > 0, "income is 0");
    require(payees.length > 0, "Payees not configured yet");
    lastReleasedAt = now;

    // Mint USDX to all receivers
    for (uint256 i = 0; i < payees.length; i++) {
      address payee = payees[i];
      _release(income, payee);
    }
    emit FeeReleased(income, lastReleasedAt);
  }

  /**
    Updates the payee configuration to a new one.
    @dev will release existing fees before the update.
    @param _payees Array of payees
    @param _shares Array of shares for each payee
  */
  function changePayees(address[] memory _payees, uint256[] memory _shares) public override onlyManager {
    require(_payees.length == _shares.length, "Payees and shares mismatched");
    require(_payees.length > 0, "No payees");

    uint256 income = a.core().state().availableIncome();
    if (income > 0 && payees.length > 0) {
      release();
    }

    for (uint256 i = 0; i < payees.length; i++) {
      delete shares[payees[i]];
    }
    delete payees;
    totalShares = 0;

    for (uint256 i = 0; i < _payees.length; i++) {
      _addPayee(_payees[i], _shares[i]);
    }
  }

  /**
    Get current configured payees.
    @return array of current payees.
  */
  function getPayees() public view override returns (address[] memory) {
    return payees;
  }

  /**
    Internal function to release a percentage of income to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalIncomeReceived Total income for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalIncomeReceived, address _payee) internal {
    uint256 payment = _totalIncomeReceived.mul(shares[_payee]).div(totalShares);
    a.stablex().mint(_payee, payment);
  }

  /**
    Internal function to add a new payee.
    @dev will update totalShares and therefore reduce the relative share of all other payees.
    @param _payee The address of the payee to add.
    @param _shares The number of shares owned by the payee.
  */
  function _addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0), "payee is the zero address");
    require(_shares > 0, "shares are 0");
    require(shares[_payee] == 0, "payee already has shares");

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
    emit PayeeAdded(_payee, _shares);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "../interfaces/IRatesManager.sol";
import "../interfaces/IAddressProvider.sol";

contract RatesManager is IRatesManager {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 private constant _SECONDS_PER_YEAR = 365 days;

  IAddressProvider public override a;

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  /**
    Calculate the annualized borrow rate from the specified borrowing rate.
    @param _borrowRate rate for a 1 second interval specified in RAY accuracy.
    @return annualized rate
  */
  function annualizedBorrowRate(uint256 _borrowRate) public pure override returns (uint256) {
    return _borrowRate.rayPow(_SECONDS_PER_YEAR);
  }

  /**
    Calculate the total debt from a specified base debt and cumulative rate.
    @param _baseDebt the base debt to be used. Can be a vault base debt or an aggregate base debt
    @param _cumulativeRate the cumulative rate in RAY accuracy.
    @return debt after applying the cumulative rate
  */
  function calculateDebt(uint256 _baseDebt, uint256 _cumulativeRate) public pure override returns (uint256 debt) {
    return _baseDebt.rayMul(_cumulativeRate);
  }

  /**
    Calculate the base debt from a specified total debt and cumulative rate.
    @param _debt the total debt to be used.
    @param _cumulativeRate the cumulative rate in RAY accuracy.
    @return baseDebt the new base debt
  */
  function calculateBaseDebt(uint256 _debt, uint256 _cumulativeRate) public pure override returns (uint256 baseDebt) {
    return _debt.rayDiv(_cumulativeRate);
  }

  /**
    Bring an existing cumulative rate forward in time
    @param _borrowRate rate for a 1 second interval specified in RAY accuracy to be applied
    @param _timeElapsed the time over whicht the borrow rate shall be applied
    @param _cumulativeRate the initial cumulative rate from which to apply the borrow rate
    @return new cumulative rate
  */
  function calculateCumulativeRate(
    uint256 _borrowRate,
    uint256 _cumulativeRate,
    uint256 _timeElapsed
  ) public view override returns (uint256) {
    if (_timeElapsed == 0) return _cumulativeRate;
    uint256 cumulativeElapsed = _borrowRate.rayPow(_timeElapsed);
    return _cumulativeRate.rayMul(cumulativeElapsed);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IPriceFeed.sol";
import "../interfaces/IAddressProvider.sol";
import "../chainlink/AggregatorV3Interface.sol";
import "../libraries/MathPow.sol";
import "../libraries/WadRayMath.sol";

contract PriceFeed is IPriceFeed {
  using SafeMath for uint256;
  using SafeMath for uint8;
  using WadRayMath for uint256;

  uint256 public constant PRICE_ORACLE_STALE_THRESHOLD = 1 days;

  IAddressProvider public override a;

  mapping(address => AggregatorV3Interface) public override assetOracles;

  AggregatorV3Interface public override eurOracle;

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));
    a = _addresses;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /**
   * @notice Sets the oracle for the given asset,
   * @param _asset address to the collateral asset e.g. WETH
   * @param _oracle address to the oracel, this oracle should implement the AggregatorV3Interface
   */
  function setAssetOracle(address _asset, address _oracle) public override onlyManager {
    require(_asset != address(0));
    require(_oracle != address(0));
    assetOracles[_asset] = AggregatorV3Interface(_oracle);
    emit OracleUpdated(_asset, _oracle, msg.sender);
  }

  /**
   * @notice Sets the oracle for EUR, this oracle should provide EUR-USD prices
   * @param _oracle address to the oracle, this oracle should implement the AggregatorV3Interface
   */
  function setEurOracle(address _oracle) public override onlyManager {
    require(_oracle != address(0));
    eurOracle = AggregatorV3Interface(_oracle);
    emit EurOracleUpdated(_oracle, msg.sender);
  }

  /**
   * Gets the asset price in EUR (PAR)
   * @dev returned value has matching decimals to the asset oracle (not the EUR oracle)
   * @param _asset address to the collateral asset e.g. WETH
   */
  function getAssetPrice(address _asset) public view override returns (uint256 price) {
    (, int256 eurAnswer, , uint256 eurUpdatedAt, ) = eurOracle.latestRoundData();
    require(eurAnswer > 0, "EUR price data not valid");
    require(block.timestamp - eurUpdatedAt < PRICE_ORACLE_STALE_THRESHOLD, "EUR price data is stale");

    (, int256 answer, , uint256 assetUpdatedAt, ) = assetOracles[_asset].latestRoundData();
    require(answer > 0, "Price data not valid");
    require(block.timestamp - assetUpdatedAt < PRICE_ORACLE_STALE_THRESHOLD, "Price data is stale");

    uint8 eurDecimals = eurOracle.decimals();
    uint256 eurAccuracy = MathPow.pow(10, eurDecimals);
    return uint256(answer).mul(eurAccuracy).div(uint256(eurAnswer));
  }

  /**
   * @notice Converts asset balance into stablecoin balance at current price
   * @param _asset address to the collateral asset e.g. WETH
   * @param _amount amount of collateral
   */
  function convertFrom(address _asset, uint256 _amount) public view override returns (uint256) {
    uint256 price = getAssetPrice(_asset);
    uint8 collateralDecimals = ERC20(_asset).decimals();
    uint8 parDecimals = ERC20(address(a.stablex())).decimals(); // Needs re-casting because ISTABLEX does not expose decimals()
    uint8 oracleDecimals = assetOracles[_asset].decimals();
    uint256 parAccuracy = MathPow.pow(10, parDecimals);
    uint256 collateralAccuracy = MathPow.pow(10, oracleDecimals.add(collateralDecimals));
    return _amount.mul(price).mul(parAccuracy).div(collateralAccuracy);
  }

  /**
   * @notice Converts stablecoin balance into collateral balance at current price
   * @param _asset address to the collateral asset e.g. WETH
   * @param _amount amount of stablecoin
   */
  function convertTo(address _asset, uint256 _amount) public view override returns (uint256) {
    uint256 price = getAssetPrice(_asset);
    uint8 collateralDecimals = ERC20(_asset).decimals();
    uint8 parDecimals = ERC20(address(a.stablex())).decimals(); // Needs re-casting because ISTABLEX does not expose decimals()
    uint8 oracleDecimals = assetOracles[_asset].decimals();
    uint256 parAccuracy = MathPow.pow(10, parDecimals);
    uint256 collateralAccuracy = MathPow.pow(10, oracleDecimals.add(collateralDecimals));
    return _amount.mul(collateralAccuracy).div(price).div(parAccuracy);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MathPow {
  function pow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : 1;

    for (n /= 2; n != 0; n /= 2) {
      x = SafeMath.mul(x, x);

      if (n % 2 != 0) {
        z = SafeMath.mul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../chainlink/AggregatorV3Interface.sol";

contract MockChainlinkFeed is AggregatorV3Interface, Ownable {
  uint256 private _latestPrice;
  string public override description;
  uint256 public override version = 3;

  uint8 public override decimals;

  constructor(
    uint8 _decimals,
    uint256 _price,
    string memory _description
  ) public {
    decimals = _decimals;
    _latestPrice = _price;
    description = _description;
  }

  function setLatestPrice(uint256 price) public onlyOwner {
    require(price > 110033500); // > 1.1 USD
    require(price < 130033500); // > 1.3 USD
    _latestPrice = price;
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param _roundId the requested round ID as presented through the proxy, this
   * is made up of the aggregator's round ID with the phase ID encoded in the
   * two highest order bytes
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(uint80 _roundId)
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = uint80(_roundId);
    answer = int256(_latestPrice);
    startedAt = uint256(1597422127);
    updatedAt = uint256(1597695228);
    answeredInRound = uint80(_roundId);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData()
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint256 latestRound = 101;
    roundId = uint80(latestRound);
    answer = int256(_latestPrice);
    startedAt = uint256(1597422127);
    updatedAt = now;
    answeredInRound = uint80(latestRound);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../chainlink/AggregatorV3Interface.sol";

contract MockChainlinkAggregator is AggregatorV3Interface {
  uint256 private _latestPrice;
  uint256 private _updatedAt;
  string public override description;
  uint256 public override version = 3;

  uint8 public override decimals;

  constructor(
    uint8 _decimals,
    uint256 _price,
    string memory _description
  ) public {
    decimals = _decimals;
    _latestPrice = _price;
    description = _description;
  }

  function setLatestPrice(uint256 price) public {
    _latestPrice = price;
  }

  function setUpdatedAt(uint256 updatedAt) public {
    _updatedAt = updatedAt;
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param _roundId the requested round ID as presented through the proxy, this
   * is made up of the aggregator's round ID with the phase ID encoded in the
   * two highest order bytes
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(uint80 _roundId)
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = uint80(_roundId);
    answer = int256(_latestPrice);
    startedAt = uint256(1597422127);
    updatedAt = uint256(1597695228);
    answeredInRound = uint80(_roundId);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData()
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint256 latestRound = 101;
    roundId = uint80(latestRound);
    answer = int256(_latestPrice);
    startedAt = uint256(1597422127);
    updatedAt = _updatedAt;
    answeredInRound = uint80(latestRound);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../libraries/WadRayMath.sol";
import "../interfaces/IConfigProvider.sol";
import "../interfaces/IAddressProvider.sol";

contract ConfigProvider is IConfigProvider {
  IAddressProvider public override a;

  mapping(uint256 => CollateralConfig) private _collateralConfigs; //indexing starts at 1
  mapping(address => uint256) public override collateralIds;

  uint256 public override numCollateralConfigs;
  /// @notice The minimum duration of voting on a proposal, in seconds
  uint256 public override minVotingPeriod = 3 days;
  /// @notice The max duration of voting on a proposal, in seconds
  uint256 public override maxVotingPeriod = 2 weeks;
  /// @notice The percentage of votes in support of a proposal required in order for a quorum to be reached and for a proposal to succeed
  uint256 public override votingQuorum = 1e16; // 1%
  /// @notice The percentage of votes required in order for a voter to become a proposer
  uint256 public override proposalThreshold = 2e14; // 0.02%

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));

    a = _addresses;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /**
    Creates or overwrites an existing config for a collateral type
    @param _collateralType address of the collateral type
    @param _debtLimit the debt ceiling for the collateral type
    @param _liquidationRatio the minimum ratio to maintain to avoid liquidation
    @param _minCollateralRatio the minimum ratio to maintain to borrow new money or withdraw collateral
    @param _borrowRate the borrowing rate specified in 1 second interval in RAY accuracy.
    @param _originationFee an optional origination fee for newly created debt. Can be 0.
    @param _liquidationBonus the liquidation bonus to be paid to liquidators.
    @param _liquidationFee an optional fee for liquidation debt. Can be 0.
  */
  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) public override onlyManager {
    require(address(_collateralType) != address(0));
    require(_minCollateralRatio >= _liquidationRatio);
    if (collateralIds[_collateralType] == 0) {
      // Initialize new collateral
      a.core().state().initializeRates(_collateralType);
      CollateralConfig memory config = CollateralConfig({
        collateralType: _collateralType,
        debtLimit: _debtLimit,
        liquidationRatio: _liquidationRatio,
        minCollateralRatio: _minCollateralRatio,
        borrowRate: _borrowRate,
        originationFee: _originationFee,
        liquidationBonus: _liquidationBonus,
        liquidationFee: _liquidationFee
      });

      numCollateralConfigs++;
      _collateralConfigs[numCollateralConfigs] = config;
      collateralIds[_collateralType] = numCollateralConfigs;
    } else {
      // Update collateral config
      a.core().state().refreshCollateral(_collateralType);
      uint256 id = collateralIds[_collateralType];

      _collateralConfigs[id].collateralType = _collateralType;
      _collateralConfigs[id].debtLimit = _debtLimit;
      _collateralConfigs[id].liquidationRatio = _liquidationRatio;
      _collateralConfigs[id].minCollateralRatio = _minCollateralRatio;
      _collateralConfigs[id].borrowRate = _borrowRate;
      _collateralConfigs[id].originationFee = _originationFee;
      _collateralConfigs[id].liquidationBonus = _liquidationBonus;
      _collateralConfigs[id].liquidationFee = _liquidationFee;
    }
    emit CollateralUpdated(
      _collateralType,
      _debtLimit,
      _liquidationRatio,
      _minCollateralRatio,
      _borrowRate,
      _originationFee,
      _liquidationBonus,
      _liquidationFee
    );
  }

  function _emitUpdateEvent(address _collateralType) internal {
    emit CollateralUpdated(
      _collateralType,
      _collateralConfigs[collateralIds[_collateralType]].debtLimit,
      _collateralConfigs[collateralIds[_collateralType]].liquidationRatio,
      _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio,
      _collateralConfigs[collateralIds[_collateralType]].borrowRate,
      _collateralConfigs[collateralIds[_collateralType]].originationFee,
      _collateralConfigs[collateralIds[_collateralType]].liquidationBonus,
      _collateralConfigs[collateralIds[_collateralType]].liquidationFee
    );
  }

  /**
    Remove the config for a collateral type
    @param _collateralType address of the collateral type
  */
  function removeCollateral(address _collateralType) public override onlyManager {
    uint256 id = collateralIds[_collateralType];
    require(id != 0, "collateral does not exist");

    _collateralConfigs[id] = _collateralConfigs[numCollateralConfigs]; //move last entry forward
    collateralIds[_collateralConfigs[id].collateralType] = id; //update id for last entry
    delete _collateralConfigs[numCollateralConfigs]; // delete last entry
    delete collateralIds[_collateralType];

    numCollateralConfigs--;

    emit CollateralRemoved(_collateralType);
  }

  /**
    Sets the debt limit for a collateral type
    @param _collateralType address of the collateral type
    @param _debtLimit the new debt limit
  */
  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) public override onlyManager {
    _collateralConfigs[collateralIds[_collateralType]].debtLimit = _debtLimit;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the minimum liquidation ratio for a collateral type
    @dev this is the liquidation treshold under which a vault is considered open for liquidation.
    @param _collateralType address of the collateral type
    @param _liquidationRatio the new minimum collateralization ratio
  */
  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio)
    public
    override
    onlyManager
  {
    require(_liquidationRatio <= _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio);
    _collateralConfigs[collateralIds[_collateralType]].liquidationRatio = _liquidationRatio;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the minimum ratio for a collateral type for new borrowing or collateral withdrawal
    @param _collateralType address of the collateral type
    @param _minCollateralRatio the new minimum open ratio
  */
  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio)
    public
    override
    onlyManager
  {
    require(_minCollateralRatio >= _collateralConfigs[collateralIds[_collateralType]].liquidationRatio);
    _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio = _minCollateralRatio;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the borrowing rate for a collateral type
    @dev borrowing rate is specified for a 1 sec interval and accurancy is in RAY.
    @param _collateralType address of the collateral type
    @param _borrowRate the new borrowing rate for a 1 sec interval
  */
  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) public override onlyManager {
    a.core().state().refreshCollateral(_collateralType);
    _collateralConfigs[collateralIds[_collateralType]].borrowRate = _borrowRate;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the origiation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
    @param _originationFee new origination fee in WAD
  */
  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) public override onlyManager {
    _collateralConfigs[collateralIds[_collateralType]].originationFee = _originationFee;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the liquidation bonus for a collateral type
    @dev the liquidation bonus is specified in WAD
    @param _collateralType address of the collateral type
    @param _liquidationBonus the liquidation bonus to be paid to liquidators.
  */
  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus)
    public
    override
    onlyManager
  {
    _collateralConfigs[collateralIds[_collateralType]].liquidationBonus = _liquidationBonus;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the liquidation fee for a collateral type
    @dev this rate is applied as a fee for liquidation and is specified in WAD
    @param _collateralType address of the collateral type
    @param _liquidationFee new liquidation fee in WAD
  */
  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) public override onlyManager {
    require(_liquidationFee < 1e18); // fee < 100%
    _collateralConfigs[collateralIds[_collateralType]].liquidationFee = _liquidationFee;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Set the min voting period for a gov proposal.
    @param _minVotingPeriod the min voting period for a gov proposal
  */
  function setMinVotingPeriod(uint256 _minVotingPeriod) public override onlyManager {
    minVotingPeriod = _minVotingPeriod;
  }

  /**
    Set the max voting period for a gov proposal.
    @param _maxVotingPeriod the max voting period for a gov proposal
  */
  function setMaxVotingPeriod(uint256 _maxVotingPeriod) public override onlyManager {
    maxVotingPeriod = _maxVotingPeriod;
  }

  /**
    Set the voting quora for a gov proposal.
    @param _votingQuorum the voting quora for a gov proposal
  */
  function setVotingQuorum(uint256 _votingQuorum) public override onlyManager {
    require(_votingQuorum < 1e18);
    votingQuorum = _votingQuorum;
  }

  /**
    Set the proposal threshold for a gov proposal.
    @param _proposalThreshold the proposal threshold for a gov proposal
  */
  function setProposalThreshold(uint256 _proposalThreshold) public override onlyManager {
    require(_proposalThreshold < 1e18);
    proposalThreshold = _proposalThreshold;
  }

  /**
    Get the debt limit for a collateral type
    @dev this is a platform wide limit for new debt issuance against a specific collateral type
    @param _collateralType address of the collateral type
  */
  function collateralDebtLimit(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].debtLimit;
  }

  /**
    Get the liquidation ratio that needs to be maintained for a collateral type to avoid liquidation.
    @param _collateralType address of the collateral type
  */
  function collateralLiquidationRatio(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].liquidationRatio;
  }

  /**
    Get the minimum collateralization ratio for a collateral type for new borrowing or collateral withdrawal.
    @param _collateralType address of the collateral type
  */
  function collateralMinCollateralRatio(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio;
  }

  /**
    Get the borrowing rate for a collateral type
    @dev borrowing rate is specified for a 1 sec interval and accurancy is in RAY.
    @param _collateralType address of the collateral type
  */
  function collateralBorrowRate(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].borrowRate;
  }

  /**
    Get the origiation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralOriginationFee(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].originationFee;
  }

  /**
    Get the liquidation bonus for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralLiquidationBonus(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].liquidationBonus;
  }

  /**
    Get the liquidation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralLiquidationFee(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].liquidationFee;
  }

  /**
    Retreives the entire config for a specific config id.
    @param _id the ID of the conifg to be returned
  */
  function collateralConfigs(uint256 _id) public view override returns (CollateralConfig memory) {
    require(_id <= numCollateralConfigs, "Invalid config id");
    return _collateralConfigs[_id];
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ITimelock.sol";

contract Timelock is ITimelock {
  using SafeMath for uint256;

  uint256 public constant MINIMUM_DELAY = 2 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;
  uint256 public constant override GRACE_PERIOD = 14 days;

  address public admin;
  address public pendingAdmin;
  uint256 public override delay;

  mapping(bytes32 => bool) public override queuedTransactions;

  constructor(address _admin, uint256 _delay) public {
    require(address(_admin) != address(0));
    require(_delay >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
    require(_delay <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

    admin = _admin;
    delay = _delay;
  }

  receive() external payable {}

  fallback() external payable {}

  function setDelay(uint256 _delay) public {
    require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
    require(_delay >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
    require(_delay <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
    delay = _delay;

    emit NewDelay(delay);
  }

  function acceptAdmin() public override {
    require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address _pendingAdmin) public {
    require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
    pendingAdmin = _pendingAdmin;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public override returns (bytes32) {
    require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
    require(
      eta >= block.timestamp.add(delay),
      "Timelock::queueTransaction: Estimated execution block must satisfy delay."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public override {
    require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable override returns (bytes memory) {
    require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
    require(block.timestamp >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    require(block.timestamp <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(callData);
    require(success, "Timelock::executeTransaction: Transaction execution reverted.");

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import '../Timelock.sol';

// Test timelock contract with admin helpers
contract TestTimelock is Timelock {
  constructor(address admin_, uint256 delay_) public Timelock(admin_, 2 days) {
    delay = delay_;
  }

  function harnessSetPendingAdmin(address pendingAdmin_) public {
    pendingAdmin = pendingAdmin_;
  }

  function harnessSetAdmin(address admin_) public {
    admin = admin_;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IGovernorAlpha.sol";
import "./interfaces/IGovernanceAddressProvider.sol";
import "../libraries/WadRayMath.sol";

contract GovernorAlpha is IGovernorAlpha {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint256) {
    return 10;
  } // 10 actions

  IGovernanceAddressProvider public a;

  /// @notice The address of the Governor Guardian
  address public guardian;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  constructor(IGovernanceAddressProvider _addresses, address _guardian) public {
    require(address(_addresses) != address(0));
    require(address(_guardian) != address(0));

    a = _addresses;
    guardian = _guardian;
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description,
    uint256 endTime
  ) public override returns (uint256) {
    uint256 votingDuration = endTime.sub(block.timestamp);
    require(votingDuration >= a.parallel().config().minVotingPeriod(), "Proposal end-time too early");
    require(votingDuration <= a.parallel().config().maxVotingPeriod(), "Proposal end-time too late");

    require(
      a.votingEscrow().balanceOfAt(msg.sender, endTime) > proposalThreshold(),
      "GovernorAlpha::propose: proposer votes below proposal threshold"
    );
    require(
      targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
      "GovernorAlpha::propose: proposal function information arity mismatch"
    );
    require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
    require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

    uint256 latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active,
        "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal"
      );
    }

    proposalCount++;
    Proposal memory newProposal = Proposal({
      id: proposalCount,
      proposer: msg.sender,
      eta: 0,
      targets: targets,
      values: values,
      signatures: signatures,
      calldatas: calldatas,
      startTime: block.timestamp,
      endTime: endTime,
      forVotes: 0,
      againstVotes: 0,
      canceled: false,
      executed: false
    });

    proposals[newProposal.id] = newProposal;
    latestProposalIds[newProposal.proposer] = newProposal.id;

    emit ProposalCreated(
      newProposal.id,
      msg.sender,
      targets,
      values,
      signatures,
      calldatas,
      block.timestamp,
      endTime,
      description
    );
    return newProposal.id;
  }

  function queue(uint256 proposalId) public override {
    require(
      state(proposalId) == ProposalState.Succeeded,
      "GovernorAlpha::queue: proposal can only be queued if it is succeeded"
    );
    Proposal storage proposal = proposals[proposalId];
    uint256 eta = block.timestamp.add(a.timelock().delay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
    }
    proposal.eta = eta;
    emit ProposalQueued(proposalId, eta);
  }

  function execute(uint256 proposalId) public payable override {
    require(
      state(proposalId) == ProposalState.Queued,
      "GovernorAlpha::execute: proposal can only be executed if it is queued"
    );
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      a.timelock().executeTransaction{ value: proposal.values[i] }(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }
    emit ProposalExecuted(proposalId);
  }

  function cancel(uint256 proposalId) public override {
    ProposalState state = state(proposalId);
    require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

    Proposal storage proposal = proposals[proposalId];
    require(msg.sender == guardian, "Only Guardian can cancel");

    proposal.canceled = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      a.timelock().cancelTransaction(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }

    emit ProposalCanceled(proposalId);
  }

  function castVote(uint256 proposalId, bool support) public override {
    require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[msg.sender];
    require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
    uint256 votes = a.votingEscrow().balanceOfAt(msg.sender, proposal.endTime);

    if (support) {
      proposal.forVotes = proposal.forVotes.add(votes);
    } else {
      proposal.againstVotes = proposal.againstVotes.add(votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    emit VoteCast(msg.sender, proposalId, support, votes);
  }

  // solhint-disable-next-line private-vars-leading-underscore
  function __acceptAdmin() public {
    require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
    a.timelock().acceptAdmin();
  }

  // solhint-disable-next-line private-vars-leading-underscore
  function __abdicate() public {
    require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
    guardian = address(0);
  }

  // solhint-disable-next-line private-vars-leading-underscore
  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
    a.timelock().queueTransaction(
      address(a.timelock()),
      0,
      "setPendingAdmin(address)",
      abi.encode(newPendingAdmin),
      eta
    );
  }

  // solhint-disable-next-line private-vars-leading-underscore
  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
    a.timelock().executeTransaction(
      address(a.timelock()),
      0,
      "setPendingAdmin(address)",
      abi.encode(newPendingAdmin),
      eta
    );
  }

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public view override returns (uint256) {
    return a.votingEscrow().stakingToken().totalSupply().wadMul(a.parallel().config().votingQuorum());
  }

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public view override returns (uint256) {
    return a.votingEscrow().stakingToken().totalSupply().wadMul(a.parallel().config().proposalThreshold());
  }

  function getActions(uint256 proposalId)
    public
    view
    override
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    )
  {
    Proposal storage p = proposals[proposalId];
    return (p.targets, p.values, p.signatures, p.calldatas);
  }

  function getReceipt(uint256 proposalId, address voter) public view override returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view override returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.timestamp <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
      return ProposalState.Defeated;
    } else if (proposal.eta == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (block.timestamp >= a.timelock().GRACE_PERIOD().add(proposal.endTime)) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function _queueOrRevert(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) internal {
    require(
      !a.timelock().queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
      "GovernorAlpha::_queueOrRevert: proposal action already queued at eta"
    );
    a.timelock().queueTransaction(target, value, signature, data, eta);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadRayMath.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./interfaces/IMIMODistributor.sol";
import "./BaseDistributor.sol";

/*
  	Distribution Formula:
  	55.5m MIMO in first week
  	-5.55% redution per week

  	total(timestamp) = _SECONDS_PER_WEEK * ( (1-_WEEKLY_R^(timestamp/_SECONDS_PER_WEEK)) / (1-_WEEKLY_R) )
  		+ timestamp % _SECONDS_PER_WEEK * (1-_WEEKLY_R^(timestamp/_SECONDS_PER_WEEK)
  */

contract MIMODistributor is BaseDistributor, IMIMODistributorExtension {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 private constant _SECONDS_PER_YEAR = 365 days;
  uint256 private constant _SECONDS_PER_WEEK = 7 days;
  uint256 private constant _WEEKLY_R = 9445e23; //-5.55%
  uint256 private constant _FIRST_WEEK_TOKENS = 55500000 ether; //55.5m

  uint256 public override startTime;

  constructor(IGovernanceAddressProvider _a, uint256 _startTime) public {
    require(address(_a) != address(0));

    a = _a;
    startTime = _startTime;
  }

  /**
    Get current monthly issuance of new MIMO tokens.
    @return number of monthly issued tokens currently`.
  */
  function currentIssuance() public view override returns (uint256) {
    return weeklyIssuanceAt(now);
  }

  /**
    Get monthly issuance of new MIMO tokens at `timestamp`.
    @dev invalid for timestamps before deployment
    @param timestamp for which to calculate the monthly issuance
    @return number of monthly issued tokens at `timestamp`.
  */
  function weeklyIssuanceAt(uint256 timestamp) public view override returns (uint256) {
    uint256 elapsedSeconds = timestamp.sub(startTime);
    uint256 elapsedWeeks = elapsedSeconds.div(_SECONDS_PER_WEEK);
    return _WEEKLY_R.rayPow(elapsedWeeks).rayMul(_FIRST_WEEK_TOKENS);
  }

  /**
    Calculates how many MIMO tokens can be minted since the last time tokens were minted
    @return number of mintable tokens available right now.
  */
  function mintableTokens() public view override returns (uint256) {
    return totalSupplyAt(now).sub(a.mimo().totalSupply());
  }

  /**
    Calculates the totalSupply for any point after `startTime`
    @param timestamp for which to calculate the totalSupply
    @return totalSupply at timestamp.
  */
  function totalSupplyAt(uint256 timestamp) public view override returns (uint256) {
    uint256 elapsedSeconds = timestamp.sub(startTime);
    uint256 elapsedWeeks = elapsedSeconds.div(_SECONDS_PER_WEEK);
    uint256 lastWeekSeconds = elapsedSeconds % _SECONDS_PER_WEEK;
    uint256 one = WadRayMath.ray();
    uint256 fullWeeks = one.sub(_WEEKLY_R.rayPow(elapsedWeeks)).rayMul(_FIRST_WEEK_TOKENS).rayDiv(one.sub(_WEEKLY_R));
    uint256 currentWeekIssuance = weeklyIssuanceAt(timestamp);
    uint256 partialWeek = currentWeekIssuance.mul(lastWeekSeconds).div(_SECONDS_PER_WEEK);
    return fullWeeks.add(partialWeek);
  }

  /**
    Internal function to release a percentage of newTokens to a specific payee
    @dev uses totalShares to calculate correct share
    @param _totalnewTokensReceived Total newTokens for all payees, will be split according to shares
    @param _payee The address of the payee to whom to distribute the fees.
  */
  function _release(uint256 _totalnewTokensReceived, address _payee) internal override {
    uint256 payment = _totalnewTokensReceived.mul(shares[_payee]).div(totalShares);
    a.mimo().mint(_payee, payment);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../governance/interfaces/IGovernanceAddressProvider.sol";
import "./interfaces/IBaseDistributor.sol";

contract DistributorManager {
  using SafeMath for uint256;

  IGovernanceAddressProvider public a;
  IBaseDistributor public mimmoDistributor;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not Manager");
    _;
  }

  constructor(IGovernanceAddressProvider _a, IBaseDistributor _mimmoDistributor) public {
    require(address(_a) != address(0));
    require(address(_mimmoDistributor) != address(0));

    a = _a;
    mimmoDistributor = _mimmoDistributor;
  }

  /**
    Public function to release the accumulated new MIMO tokens to the payees.
    @dev anyone can call this.
  */
  function releaseAll() public {
    mimmoDistributor.release();
    address[] memory distributors = mimmoDistributor.getPayees();
    for (uint256 i = 0; i < distributors.length; i++) {
      IBaseDistributor(distributors[i]).release();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWETH is ERC20("Wrapped Ether", "WETH") {
  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function deposit() public payable {
    _mint(msg.sender, msg.value);
  }

  function withdraw(uint256 wad) public {
    _burn(msg.sender, wad);
    msg.sender.transfer(wad);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWBTC is ERC20("Wrapped Bitcoin", "WBTC") {
  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockMIMO is ERC20("MIMO Token", "MIMO") {
  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public ERC20(_name, _symbol) {
    super._setupDecimals(_decimals);
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public {
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockBPT is ERC20("Balancer Pool Token", "BPT") {
  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAddressProvider.sol";
import "../libraries/interfaces/IVault.sol";

contract MIMOBuyback {
  bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

  IAddressProvider public a;
  IERC20 public PAR;
  IERC20 public MIMO;
  uint256 public lockExpiry;
  bytes32 public poolID;
  IVault public balancer = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  bool public whitelistEnabled = false;

  constructor(
    uint256 _lockExpiry,
    bytes32 _poolID,
    address _a,
    address _mimo
  ) public {
    lockExpiry = _lockExpiry;
    poolID = _poolID;
    a = IAddressProvider(_a);
    MIMO = IERC20(_mimo);
    PAR = a.stablex();

    PAR.approve(address(balancer), 2**256 - 1);
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  modifier onlyKeeper() {
    require(
      !whitelistEnabled || (whitelistEnabled && a.controller().hasRole(KEEPER_ROLE, msg.sender)),
      "Caller is not a Keeper"
    );
    _;
  }

  function withdrawMIMO(address destination) public onlyManager {
    require(block.timestamp > lockExpiry, "lock not expired yet");
    require(MIMO.transfer(destination, MIMO.balanceOf(address(this))));
  }

  function buyMIMO() public onlyKeeper {
    a.core().state().refresh();
    a.feeDistributor().release();

    bytes memory userData = abi.encode();
    IVault.SingleSwap memory singleSwap = IVault.SingleSwap(
      poolID,
      IVault.SwapKind.GIVEN_IN,
      IAsset(address(PAR)), // swap in
      IAsset(address(MIMO)), // swap out
      PAR.balanceOf(address(this)), // all PAR of this contract
      userData
    );

    IVault.FundManagement memory fundManagement = IVault.FundManagement(
      address(this), // sender
      false, // useInternalBalance
      payable(address(this)), // recipient
      false // // useInternalBalance
    );

    balancer.swap(
      singleSwap,
      fundManagement,
      0, // limit, could be frontrun?
      2**256 - 1 // deadline
    );
  }

  function setWhitelistEnabled(bool _status) public onlyManager {
    whitelistEnabled = _status;
  }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

interface IVault {
  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  /**
   * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
   * the `kind` value.
   *
   * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
   * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
   *
   * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
   * used to extend swap behavior.
   */
  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
   * `recipient` account.
   *
   * If the caller is not `sender`, it must be an authorized relayer for them.
   *
   * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
   * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
   * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
   * `joinPool`.
   *
   * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
   * transferred. This matches the behavior of `exitPool`.
   *
   * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
   * revert.
   */
  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  /**
   * @dev Performs a swap with a single Pool.
   *
   * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
   * taken from the Pool, which must be greater than or equal to `limit`.
   *
   * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
   * sent to the Pool, which must be less than or equal to `limit`.
   *
   * Internal Balance usage and the recipient are determined by the `funds` struct.
   *
   * Emits a `Swap` event.
   */
  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

/**
    Buggy ERC20 implementation without the return bool on `transfer`, `transferFrom` and `approve` for testing purposes
*/

contract MockBuggyERC20 is Context {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name_, string memory symbol_) public {
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual {
    _transfer(_msgSender(), recipient, amount);
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual {
    _approve(_msgSender(), spender, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface BPool is IERC20 {
  function gulp(address token) external;

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external returns (uint256 poolAmountOut);

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external returns (uint256 tokenAmountIn);

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint256 tokenAmountOut);

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external returns (uint256 poolAmountIn);

  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) external pure returns (uint256 poolAmountOut);

  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

  function getSwapFee() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getNormalizedWeight(address token) external view returns (uint256);

  function isPublicSwap() external view returns (bool);

  function isFinalized() external view returns (bool);
}