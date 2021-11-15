// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;

import {
    AccessControl as OZAccessControl
} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice Extends OpenZeppelin AccessControl contract with modifiers
 * @dev This contract and AccessControlUpgradeSafe are essentially duplicates.
 */
contract AccessControl is OZAccessControl {
    /** @notice access control roles **/
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    modifier onlyLpRole() {
        require(hasRole(LP_ROLE, _msgSender()), "NOT_LP_ROLE");
        _;
    }

    modifier onlyContractRole() {
        require(hasRole(CONTRACT_ROLE, _msgSender()), "NOT_CONTRACT_ROLE");
        _;
    }

    modifier onlyAdminRole() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyEmergencyRole() {
        require(hasRole(EMERGENCY_ROLE, _msgSender()), "NOT_EMERGENCY_ROLE");
        _;
    }

    modifier onlyLpOrContractRole() {
        require(
            hasRole(LP_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_LP_OR_CONTRACT_ROLE"
        );
        _;
    }

    modifier onlyAdminOrContractRole() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_ADMIN_OR_CONTRACT_ROLE"
        );
        _;
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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IDetailedERC20} from "./IDetailedERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {AccessControl} from "./AccessControl.sol";
import {INameIdentifier} from "./INameIdentifier.sol";
import {IAssetAllocation} from "./IAssetAllocation.sol";
import {IEmergencyExit} from "./IEmergencyExit.sol";

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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Used by the `NamedAddressSet` library to store sets of contracts
 */
interface INameIdentifier {
    /// @notice Should be implemented as a constant value
    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view returns (string memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {INameIdentifier} from "./INameIdentifier.sol";

/**
 * @notice For use with the `TvlManager` to track the value locked in a protocol
 */
interface IAssetAllocation is INameIdentifier {
    struct TokenData {
        address token;
        string symbol;
        uint8 decimals;
    }

    /**
     * @notice Get data for the underlying tokens stored in the protocol
     * @return The array of `TokenData`
     */
    function tokens() external view returns (TokenData[] memory);

    /**
     * @notice Get the number of different tokens stored in the protocol
     * @return The number of tokens
     */
    function numberOfTokens() external view returns (uint256);

    /**
     * @notice Get an account's balance for a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param account The account to get the balance for
     * @param tokenIndex The index of the token to get the balance for
     * @return The account's balance
     */
    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        returns (uint256);

    /**
     * @notice Get the symbol of a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param tokenIndex The index of the token
     * @return The symbol of the token
     */
    function symbolOf(uint8 tokenIndex) external view returns (string memory);

    /**
     * @notice Get the decimals of a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param tokenIndex The index of the token
     * @return The decimals of the token
     */
    function decimalsOf(uint8 tokenIndex) external view returns (uint8);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "./Imports.sol";

/**
 * @notice Used for contracts that need an emergency escape hatch
 * @notice Should only be used in an emergency to keep funds safu
 */
interface IEmergencyExit {
    /**
     * @param emergencySafe The address the tokens were escaped to
     * @param token The token escaped
     * @param balance The amount of tokens escaped
     */
    event EmergencyExit(address emergencySafe, IERC20 token, uint256 balance);

    /**
     * @notice Transfer all tokens to the emergency Safe
     * @dev Should only be callable by the emergency Safe
     * @dev Should only transfer tokens to the emergency Safe
     * @param token The token to transfer
     */
    function emergencyExit(address token) external;
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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";
import {TvlManager} from "./TvlManager.sol";

contract TestTvlManager is TvlManager {
    constructor(address addressRegistry_) public TvlManager(addressRegistry_) {} // solhint-disable-line no-empty-blocks

    function testEncodeAssetAllocationId(
        address assetAllocation,
        uint8 tokenIndex
    ) external pure returns (bytes32) {
        return _encodeAssetAllocationId(assetAllocation, tokenIndex);
    }

    function testDecodeAssetAllocationId(bytes32 id)
        external
        pure
        returns (address, uint8)
    {
        return _decodeAssetAllocationId(id);
    }

    function testGetAssetAllocationIdCount(
        IAssetAllocation[] memory allocations
    ) external view returns (uint256) {
        return _getAssetAllocationIdCount(allocations);
    }

    function testGetAssetAllocationIds(IAssetAllocation[] memory allocations)
        external
        view
        returns (bytes32[] memory)
    {
        return _getAssetAllocationsIds(allocations);
    }

    function testGetAssetAllocations()
        external
        view
        returns (IAssetAllocation[] memory)
    {
        return _getAssetAllocations();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    ReentrancyGuard,
    AccessControl
} from "contracts/common/Imports.sol";
import {NamedAddressSet} from "contracts/libraries/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {ILockingOracle} from "contracts/oracle/Imports.sol";

import {IChainlinkRegistry} from "./IChainlinkRegistry.sol";
import {IAssetAllocationRegistry} from "./IAssetAllocationRegistry.sol";
import {Erc20AllocationConstants} from "./Erc20Allocation.sol";

/**
 * @notice Assets can be deployed in a variety of ways within the DeFi
 * ecosystem: accounts, pools, vaults, gauges, etc. This contract tracks
 * deployed capital with asset allocations that allow position balances to
 * be priced and aggregated by Chainlink into the deployed TVL.
 * @notice When other contracts perform operations that can change how the TVL
 * must be calculated, such as swaping, staking, or claiming rewards, they
 * check the `TvlManager` to ensure the appropriate asset allocations are
 * registered.
 * @dev It is imperative that the registered asset allocations are up-to-date.
 * Any assets in the system that have been deployed but are not registered
 * could lead to significant misreporting of the TVL.
 */
contract TvlManager is
    AccessControl,
    ReentrancyGuard,
    IChainlinkRegistry,
    IAssetAllocationRegistry,
    Erc20AllocationConstants
{
    using NamedAddressSet for NamedAddressSet.AssetAllocationSet;

    IAddressRegistryV2 public addressRegistry;

    NamedAddressSet.AssetAllocationSet private _assetAllocations;

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /** @notice Log when the ERC20 asset allocation is changed */
    event Erc20AllocationChanged(address);

    constructor(address addressRegistry_) public {
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
    }

    /**
     * @notice Set the new address registry
     * @param addressRegistry_ The new address registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    function registerAssetAllocation(IAssetAllocation assetAllocation)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _assetAllocations.add(assetAllocation);

        _lockOracleAdapter();

        emit AssetAllocationRegistered(assetAllocation);
    }

    function removeAssetAllocation(string memory name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        require(
            keccak256(abi.encodePacked(name)) !=
                keccak256(abi.encodePacked(Erc20AllocationConstants.NAME)),
            "CANNOT_REMOVE_ALLOCATION"
        );

        _assetAllocations.remove(name);

        _lockOracleAdapter();

        emit AssetAllocationRemoved(name);
    }

    function getAssetAllocation(string calldata name)
        external
        view
        override
        returns (IAssetAllocation)
    {
        return _assetAllocations.get(name);
    }

    /**
     * @dev The list contains no duplicate identifiers
     * @dev IDs are not constant, updates to an asset allocation change the ID
     */
    function getAssetAllocationIds()
        external
        view
        override
        returns (bytes32[] memory)
    {
        IAssetAllocation[] memory allocations = _getAssetAllocations();
        return _getAssetAllocationsIds(allocations);
    }

    function isAssetAllocationRegistered(string[] calldata allocationNames)
        external
        view
        override
        returns (bool)
    {
        uint256 length = allocationNames.length;
        for (uint256 i = 0; i < length; i++) {
            IAssetAllocation allocation =
                _assetAllocations.get(allocationNames[i]);
            if (address(allocation) == address(0)) {
                return false;
            }
        }

        return true;
    }

    function balanceOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        (IAssetAllocation assetAllocation, uint8 tokenIndex) =
            _getAssetAllocation(allocationId);
        return
            assetAllocation.balanceOf(
                addressRegistry.lpAccountAddress(),
                tokenIndex
            );
    }

    function symbolOf(bytes32 allocationId)
        external
        view
        override
        returns (string memory)
    {
        (IAssetAllocation assetAllocation, uint8 tokenIndex) =
            _getAssetAllocation(allocationId);
        return assetAllocation.symbolOf(tokenIndex);
    }

    function decimalsOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        (IAssetAllocation assetAllocation, uint8 tokenIndex) =
            _getAssetAllocation(allocationId);
        return assetAllocation.decimalsOf(tokenIndex);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    /**
     * @notice Lock the `OracleAdapter` for the default period of time
     * @dev Locking protects against front-running while Chainlink updates
     */
    function _lockOracleAdapter() internal {
        ILockingOracle oracleAdapter =
            ILockingOracle(addressRegistry.oracleAdapterAddress());
        oracleAdapter.lock();
    }

    /**
     * @notice Get all IDs from an array of asset allocations
     * @notice Each ID is a unique asset allocation and token index pair
     * @dev Should contain no duplicate IDs
     * @return list of all IDs
     */
    function _getAssetAllocationsIds(IAssetAllocation[] memory allocations)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 idsLength = _getAssetAllocationIdCount(allocations);
        bytes32[] memory assetAllocationIds = new bytes32[](idsLength);

        uint256 k = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 tokensLength = allocations[i].numberOfTokens();

            require(tokensLength < type(uint8).max, "TOO_MANY_TOKENS");

            for (uint256 j = 0; j < tokensLength; j++) {
                assetAllocationIds[k] = _encodeAssetAllocationId(
                    address(allocations[i]),
                    uint8(j)
                );
                k++;
            }
        }

        return assetAllocationIds;
    }

    /**
     * @notice Get an asset allocation and token index pair from an ID
     * @notice The token index references a token in the asset allocation
     * @param id The ID
     * @return The asset allocation and token index pair
     */
    function _getAssetAllocation(bytes32 id)
        internal
        view
        returns (IAssetAllocation, uint8)
    {
        (address assetAllocationAddress, uint8 tokenIndex) =
            _decodeAssetAllocationId(id);

        IAssetAllocation assetAllocation =
            IAssetAllocation(assetAllocationAddress);

        require(
            _assetAllocations.contains(assetAllocation),
            "INVALID_ASSET_ALLOCATION"
        );
        require(
            assetAllocation.numberOfTokens() > tokenIndex,
            "INVALID_TOKEN_INDEX"
        );

        return (assetAllocation, tokenIndex);
    }

    /**
     * @notice Get the total number of IDs for an array of allocations
     * @notice Used by `_getAssetAllocationsIds`
     * @notice Needed to initialize an ID array with the correct length
     * @param allocations The array of asset allocations
     * @return The number of IDs
     */
    function _getAssetAllocationIdCount(IAssetAllocation[] memory allocations)
        internal
        view
        returns (uint256)
    {
        uint256 idsLength = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            idsLength += allocations[i].numberOfTokens();
        }

        return idsLength;
    }

    /**
     * @notice Get an array of registered asset allocations
     * @dev Needed to convert from the set data structure to an array
     * @return The array of asset allocations
     */
    function _getAssetAllocations()
        internal
        view
        returns (IAssetAllocation[] memory)
    {
        uint256 numAllocations = _assetAllocations.length();
        IAssetAllocation[] memory allocations =
            new IAssetAllocation[](numAllocations);

        for (uint256 i = 0; i < numAllocations; i++) {
            allocations[i] = _assetAllocations.at(i);
        }

        return allocations;
    }

    /**
     * @notice Create an ID from an asset allocation and token index pair
     * @param assetAllocation The asset allocation
     * @param tokenIndex The token index
     * @return The ID
     */
    function _encodeAssetAllocationId(address assetAllocation, uint8 tokenIndex)
        internal
        pure
        returns (bytes32)
    {
        bytes memory idPacked = abi.encodePacked(assetAllocation, tokenIndex);

        bytes32 id;

        assembly {
            id := mload(add(idPacked, 32))
        }

        return id;
    }

    /**
     * @notice Get the asset allocation and token index for a given ID
     * @param id The ID
     * @return The asset allocation address
     * @return The token index
     */
    function _decodeAssetAllocationId(bytes32 id)
        internal
        pure
        returns (address, uint8)
    {
        uint256 id_ = uint256(id);

        address assetAllocation = address(bytes20(uint160(id_ >> 96)));
        uint8 tokenIndex = uint8(id_ >> 88);

        return (assetAllocation, tokenIndex);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {NamedAddressSet} from "./NamedAddressSet.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IAddressRegistryV2} from "./IAddressRegistryV2.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {AggregatorV3Interface, FluxAggregator} from "./FluxAggregator.sol";
import {IOracleAdapter} from "./IOracleAdapter.sol";
import {IOverrideOracle} from "./IOverrideOracle.sol";
import {ILockingOracle} from "./ILockingOracle.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Interface used by Chainlink to aggregate allocations and compute TVL
 */
interface IChainlinkRegistry {
    /**
     * @notice Get all IDs from registered asset allocations
     * @notice Each ID is a unique asset allocation and token index pair
     * @dev Should contain no duplicate IDs
     * @return list of all IDs
     */
    function getAssetAllocationIds() external view returns (bytes32[] memory);

    /**
     * @notice Get the LP Account's balance for an asset allocation ID
     * @param allocationId The ID to fetch the balance for
     * @return The balance for the LP Account
     */
    function balanceOf(bytes32 allocationId) external view returns (uint256);

    /**
     * @notice Get the symbol for an allocation ID's underlying token
     * @param allocationId The ID to fetch the symbol for
     * @return The underlying token symbol
     */
    function symbolOf(bytes32 allocationId)
        external
        view
        returns (string memory);

    /**
     * @notice Get the decimals for an allocation ID's underlying token
     * @param allocationId The ID to fetch the decimals for
     * @return The underlying token decimals
     */
    function decimalsOf(bytes32 allocationId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";

/**
 * @notice For managing a collection of `IAssetAllocation` contracts
 */
interface IAssetAllocationRegistry {
    /** @notice Log when an asset allocation is registered */
    event AssetAllocationRegistered(IAssetAllocation assetAllocation);

    /** @notice Log when an asset allocation is removed */
    event AssetAllocationRemoved(string name);

    /**
     * @notice Add a new asset allocation to the registry
     * @dev Should not allow duplicate asset allocations
     * @param assetAllocation The new asset allocation
     */
    function registerAssetAllocation(IAssetAllocation assetAllocation) external;

    /**
     * @notice Remove an asset allocation from the registry
     * @param name The name of the asset allocation (see `INameIdentifier`)
     */
    function removeAssetAllocation(string memory name) external;

    /**
     * @notice Check if multiple asset allocations are ALL registered
     * @param allocationNames An array of asset allocation names
     * @return `true` if every allocation is registered, otherwise `false`
     */
    function isAssetAllocationRegistered(string[] calldata allocationNames)
        external
        view
        returns (bool);

    /**
     * @notice Get the registered asset allocation with a given name
     * @param name The asset allocation name
     * @return The asset allocation
     */
    function getAssetAllocation(string calldata name)
        external
        view
        returns (IAssetAllocation);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IERC20,
    IDetailedERC20,
    AccessControl,
    INameIdentifier,
    ReentrancyGuard
} from "contracts/common/Imports.sol";
import {Address, EnumerableSet} from "contracts/libraries/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";

import {IErc20Allocation} from "./IErc20Allocation.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";

abstract contract Erc20AllocationConstants is INameIdentifier {
    string public constant override NAME = "erc20Allocation";
}

contract Erc20Allocation is
    IErc20Allocation,
    AssetAllocationBase,
    Erc20AllocationConstants,
    AccessControl,
    ReentrancyGuard
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _tokenAddresses;
    mapping(address => TokenData) private _tokenToData;

    constructor(address addressRegistry_) public {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS_REGISTRY");
        IAddressRegistryV2 addressRegistry =
            IAddressRegistryV2(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
    }

    function registerErc20Token(IDetailedERC20 token)
        external
        override
        nonReentrant
        onlyAdminOrContractRole
    {
        string memory symbol = token.symbol();
        uint8 decimals = token.decimals();
        _registerErc20Token(token, symbol, decimals);
    }

    function registerErc20Token(IDetailedERC20 token, string calldata symbol)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        uint8 decimals = token.decimals();
        _registerErc20Token(token, symbol, decimals);
    }

    function registerErc20Token(
        IERC20 token,
        string calldata symbol,
        uint8 decimals
    ) external override nonReentrant onlyAdminRole {
        _registerErc20Token(token, symbol, decimals);
    }

    function removeErc20Token(IERC20 token)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _tokenAddresses.remove(address(token));
        delete _tokenToData[address(token)];

        emit Erc20TokenRemoved(token);
    }

    function isErc20TokenRegistered(IERC20 token)
        external
        view
        override
        returns (bool)
    {
        return _tokenAddresses.contains(address(token));
    }

    function isErc20TokenRegistered(IERC20[] calldata tokens)
        external
        view
        override
        returns (bool)
    {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (!_tokenAddresses.contains(address(tokens[i]))) {
                return false;
            }
        }

        return true;
    }

    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        override
        returns (uint256)
    {
        address token = addressOf(tokenIndex);
        return IERC20(token).balanceOf(account);
    }

    function tokens() public view override returns (TokenData[] memory) {
        TokenData[] memory _tokens = new TokenData[](_tokenAddresses.length());
        for (uint256 i = 0; i < _tokens.length; i++) {
            address tokenAddress = _tokenAddresses.at(i);
            _tokens[i] = _tokenToData[tokenAddress];
        }
        return _tokens;
    }

    function _registerErc20Token(
        IERC20 token,
        string memory symbol,
        uint8 decimals
    ) internal {
        require(address(token).isContract(), "INVALID_ADDRESS");
        require(bytes(symbol).length != 0, "INVALID_SYMBOL");
        _tokenAddresses.add(address(token));
        _tokenToData[address(token)] = TokenData(
            address(token),
            symbol,
            decimals
        );

        emit Erc20TokenRegistered(token, symbol, decimals);
    }
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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {IAssetAllocation, INameIdentifier} from "contracts/common/Imports.sol";
import {IZap, ISwap} from "contracts/lpaccount/Imports.sol";

/**
 * @notice Stores a set of addresses that can be looked up by name
 * @notice Addresses can be added or removed dynamically
 * @notice Useful for keeping track of unique deployed contracts
 * @dev Each address must be a contract with a `NAME` constant for lookup
 */
library NamedAddressSet {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Set {
        EnumerableSet.AddressSet _namedAddresses;
        mapping(string => INameIdentifier) _nameLookup;
    }

    struct AssetAllocationSet {
        Set _inner;
    }

    struct ZapSet {
        Set _inner;
    }

    struct SwapSet {
        Set _inner;
    }

    function _add(Set storage set, INameIdentifier namedAddress) private {
        require(Address.isContract(address(namedAddress)), "INVALID_ADDRESS");
        require(
            !set._namedAddresses.contains(address(namedAddress)),
            "DUPLICATE_ADDRESS"
        );

        string memory name = namedAddress.NAME();
        require(bytes(name).length != 0, "INVALID_NAME");
        require(address(set._nameLookup[name]) == address(0), "DUPLICATE_NAME");

        set._namedAddresses.add(address(namedAddress));
        set._nameLookup[name] = namedAddress;
    }

    function _remove(Set storage set, string memory name) private {
        address namedAddress = address(set._nameLookup[name]);
        require(namedAddress != address(0), "INVALID_NAME");

        set._namedAddresses.remove(namedAddress);
        delete set._nameLookup[name];
    }

    function _contains(Set storage set, INameIdentifier namedAddress)
        private
        view
        returns (bool)
    {
        return set._namedAddresses.contains(address(namedAddress));
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._namedAddresses.length();
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (INameIdentifier)
    {
        return INameIdentifier(set._namedAddresses.at(index));
    }

    function _get(Set storage set, string memory name)
        private
        view
        returns (INameIdentifier)
    {
        return set._nameLookup[name];
    }

    function _names(Set storage set) private view returns (string[] memory) {
        uint256 length_ = set._namedAddresses.length();
        string[] memory names_ = new string[](length_);

        for (uint256 i = 0; i < length_; i++) {
            INameIdentifier namedAddress =
                INameIdentifier(set._namedAddresses.at(i));
            names_[i] = namedAddress.NAME();
        }

        return names_;
    }

    function add(
        AssetAllocationSet storage set,
        IAssetAllocation assetAllocation
    ) internal {
        _add(set._inner, assetAllocation);
    }

    function remove(AssetAllocationSet storage set, string memory name)
        internal
    {
        _remove(set._inner, name);
    }

    function contains(
        AssetAllocationSet storage set,
        IAssetAllocation assetAllocation
    ) internal view returns (bool) {
        return _contains(set._inner, assetAllocation);
    }

    function length(AssetAllocationSet storage set)
        internal
        view
        returns (uint256)
    {
        return _length(set._inner);
    }

    function at(AssetAllocationSet storage set, uint256 index)
        internal
        view
        returns (IAssetAllocation)
    {
        return IAssetAllocation(address(_at(set._inner, index)));
    }

    function get(AssetAllocationSet storage set, string memory name)
        internal
        view
        returns (IAssetAllocation)
    {
        return IAssetAllocation(address(_get(set._inner, name)));
    }

    function names(AssetAllocationSet storage set)
        internal
        view
        returns (string[] memory)
    {
        return _names(set._inner);
    }

    function add(ZapSet storage set, IZap zap) internal {
        _add(set._inner, zap);
    }

    function remove(ZapSet storage set, string memory name) internal {
        _remove(set._inner, name);
    }

    function contains(ZapSet storage set, IZap zap)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, zap);
    }

    function length(ZapSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(ZapSet storage set, uint256 index)
        internal
        view
        returns (IZap)
    {
        return IZap(address(_at(set._inner, index)));
    }

    function get(ZapSet storage set, string memory name)
        internal
        view
        returns (IZap)
    {
        return IZap(address(_get(set._inner, name)));
    }

    function names(ZapSet storage set) internal view returns (string[] memory) {
        return _names(set._inner);
    }

    function add(SwapSet storage set, ISwap swap) internal {
        _add(set._inner, swap);
    }

    function remove(SwapSet storage set, string memory name) internal {
        _remove(set._inner, name);
    }

    function contains(SwapSet storage set, ISwap swap)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, swap);
    }

    function length(SwapSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(SwapSet storage set, uint256 index)
        internal
        view
        returns (ISwap)
    {
        return ISwap(address(_at(set._inner, index)));
    }

    function get(SwapSet storage set, string memory name)
        internal
        view
        returns (ISwap)
    {
        return ISwap(address(_get(set._inner, name)));
    }

    function names(SwapSet storage set)
        internal
        view
        returns (string[] memory)
    {
        return _names(set._inner);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IZap} from "./IZap.sol";
import {ISwap} from "./ISwap.sol";
import {ILpAccount} from "./ILpAccount.sol";
import {IZapRegistry} from "./IZapRegistry.sol";
import {ISwapRegistry} from "./ISwapRegistry.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    INameIdentifier,
    IERC20
} from "contracts/common/Imports.sol";

/**
 * @notice Used to define how an LP Account farms an external protocol
 */
interface IZap is INameIdentifier {
    /**
     * @notice Deploy liquidity to a protocol (i.e. enter a farm)
     * @dev Implementation should add liquidity and stake LP tokens
     * @param amounts Amount of each token to deploy
     */
    function deployLiquidity(uint256[] calldata amounts) external;

    /**
     * @notice Unwind liquidity from a protocol (i.e exit a farm)
     * @dev Implementation should unstake LP tokens and remove liquidity
     * @dev If there is only one token to unwind, `index` should be 0
     * @param amount Amount of liquidity to unwind
     * @param index Which token should be unwound
     */
    function unwindLiquidity(uint256 amount, uint8 index) external;

    /**
     * @notice Claim accrued rewards from the protocol (i.e. harvest yield)
     */
    function claim() external;

    /**
     * @notice Order of tokens for deploy `amounts` and unwind `index`
     * @dev Implementation should use human readable symbols
     * @dev Order should be the same for deploy and unwind
     * @return The array of symbols in order
     */
    function sortedSymbols() external view returns (string[] memory);

    /**
     * @notice Asset allocations to include in TVL
     * @dev Requires all allocations that track value deployed to the protocol
     * @return An array of the asset allocation names
     */
    function assetAllocations() external view returns (string[] memory);

    /**
     * @notice ERC20 asset allocations to include in TVL
     * @dev Should return addresses for all tokens that get deployed or unwound
     * @return The array of ERC20 token addresses
     */
    function erc20Allocations() external view returns (IERC20[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    INameIdentifier,
    IERC20
} from "contracts/common/Imports.sol";

/**
 * @notice Used to define a token swap that can be performed by an LP Account
 */
interface ISwap is INameIdentifier {
    /**
     * @dev Implementation should perform a token swap
     * @param amount The amount of the input token to swap
     * @param minAmount The minimum amount of the output token to accept
     */
    function swap(uint256 amount, uint256 minAmount) external;

    /**
     * @notice ERC20 asset allocations to include in TVL
     * @dev Should return addresses for all tokens going in and out of the swap
     * @return The array of ERC20 token addresses
     */
    function erc20Allocations() external view returns (IERC20[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For contracts that provide liquidity to external protocols
 */
interface ILpAccount {
    /**
     * @notice Deploy liquidity with a registered `IZap`
     * @dev The order of token amounts should match `IZap.sortedSymbols`
     * @param name The name of the `IZap`
     * @param amounts The token amounts to deploy
     */
    function deployStrategy(string calldata name, uint256[] calldata amounts)
        external;

    /**
     * @notice Unwind liquidity with a registered `IZap`
     * @dev The index should match the order of `IZap.sortedSymbols`
     * @param name The name of the `IZap`
     * @param amount The amount of the token to unwind
     * @param index The index of the token to unwind
     */
    function unwindStrategy(
        string calldata name,
        uint256 amount,
        uint8 index
    ) external;

    /**
     * @notice Return liquidity to a pool
     * @notice Typically used to refill a liquidity pool's reserve
     * @dev This should only be callable by the `MetaPoolToken`
     * @param pool The `IReservePool` to transfer to
     * @param amount The amount of the pool's underlyer token to transer
     */
    function transferToPool(address pool, uint256 amount) external;

    /**
     * @notice Swap tokens with a registered `ISwap`
     * @notice Used to compound reward tokens
     * @notice Used to rebalance underlyer tokens
     * @param name The name of the `IZap`
     * @param amount The amount of tokens to swap
     * @param minAmount The minimum amount of tokens to receive from the swap
     */
    function swap(
        string calldata name,
        uint256 amount,
        uint256 minAmount
    ) external;

    /**
     * @notice Claim reward tokens with a registered `IZap`
     * @param name The name of the `IZap`
     */
    function claim(string calldata name) external;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IZap} from "./IZap.sol";

/**
 * @notice For managing a collection of `IZap` contracts
 */
interface IZapRegistry {
    /** @notice Log when a new `IZap` is registered */
    event ZapRegistered(IZap zap);

    /** @notice Log when an `IZap` is removed */
    event ZapRemoved(string name);

    /**
     * @notice Add a new `IZap` to the registry
     * @dev Should not allow duplicate swaps
     * @param zap The new `IZap`
     */
    function registerZap(IZap zap) external;

    /**
     * @notice Remove an `IZap` from the registry
     * @param name The name of the `IZap` (see `INameIdentifier`)
     */
    function removeZap(string calldata name) external;

    /**
     * @notice Get the names of all registered `IZap`
     * @return An array of `IZap` names
     */
    function zapNames() external view returns (string[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ISwap} from "./ISwap.sol";

/**
 * @notice For managing a collection of `ISwap` contracts
 */
interface ISwapRegistry {
    /** @notice Log when a new `ISwap` is registered */
    event SwapRegistered(ISwap swap);

    /** @notice Log when an `ISwap` is removed */
    event SwapRemoved(string name);

    /**
     * @notice Add a new `ISwap` to the registry
     * @dev Should not allow duplicate swaps
     * @param swap The new `ISwap`
     */
    function registerSwap(ISwap swap) external;

    /**
     * @notice Remove an `ISwap` from the registry
     * @param name The name of the `ISwap` (see `INameIdentifier`)
     */
    function removeSwap(string calldata name) external;

    /**
     * @notice Get the names of all registered `ISwap`
     * @return An array of `ISwap` names
     */
    function swapNames() external view returns (string[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice The address registry has two important purposes, one which
 * is fairly concrete and another abstract.
 *
 * 1. The registry enables components of the APY.Finance system
 * and external systems to retrieve core addresses reliably
 * even when the functionality may move to a different
 * address.
 *
 * 2. The registry also makes explicit which contracts serve
 * as primary entrypoints for interacting with different
 * components.  Not every contract is registered here, only
 * the ones properly deserving of an identifier.  This helps
 * define explicit boundaries between groups of contracts,
 * each of which is logically cohesive.
 */
interface IAddressRegistryV2 {
    /**
     * @notice Log when a new address is registered
     * @param id The ID of the new address
     * @param _address The new address
     */
    event AddressRegistered(bytes32 id, address _address);

    /**
     * @notice Log when an address is removed from the registry
     * @param id The ID of the address
     * @param _address The address
     */
    event AddressDeleted(bytes32 id, address _address);

    /**
     * @notice Register address with identifier
     * @dev Using an existing ID will replace the old address with new
     * @dev Currently there is no way to remove an ID, as attempting to
     * register the zero address will revert.
     */
    function registerAddress(bytes32 id, address address_) external;

    /**
     * @notice Registers multiple address at once
     * @dev Convenient method to register multiple addresses at once.
     * @param ids Ids to register addresses under
     * @param addresses Addresses to register
     */
    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external;

    /**
     * @notice Removes a registered id and it's associated address
     * @dev Delete the address corresponding to the identifier Time-complexity is O(n) where n is the length of `_idList`.
     * @param id ID to remove along with it's associated address
     */
    function deleteAddress(bytes32 id) external;

    /**
     * @notice Returns the list of all registered identifiers.
     * @return List of identifiers
     */
    function getIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns the list of all registered identifiers
     * @param id Component identifier
     * @return The current address represented by an identifier
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice Returns the TVL Manager Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return TVL Manager Address
     */
    function tvlManagerAddress() external view returns (address);

    /**
     * @notice Returns the Chainlink Registry Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Chainlink Registry Address
     */
    function chainlinkRegistryAddress() external view returns (address);

    /**
     * @notice Returns the DAI Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return DAI Pool Address
     */
    function daiPoolAddress() external view returns (address);

    /**
     * @notice Returns the USDC Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return USDC Pool Address
     */
    function usdcPoolAddress() external view returns (address);

    /**
     * @notice Returns the USDT Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return USDT Pool Address
     */
    function usdtPoolAddress() external view returns (address);

    /**
     * @notice Returns the MAPT Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return MAPT Pool Address
     */
    function mAptAddress() external view returns (address);

    /**
     * @notice Returns the LP Account Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return LP Account Address
     */
    function lpAccountAddress() external view returns (address);

    /**
     * @notice Returns the LP Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return LP Safe Address
     */
    function lpSafeAddress() external view returns (address);

    /**
     * @notice Returns the Admin Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Admin Safe Address
     */
    function adminSafeAddress() external view returns (address);

    /**
     * @notice Returns the Emergency Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Emergency Safe Address
     */
    function emergencySafeAddress() external view returns (address);

    /**
     * @notice Returns the Oracle Adapter Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Oracle Adapter Address
     */
    function oracleAdapterAddress() external view returns (address);
}

/**
SPDX-License-Identifier: UNLICENSED
----------------------------------
---- APY.Finance comments --------
----------------------------------

Due to pragma being fixed at 0.6.6, we had to copy over this contract
and fix the imports.

original path: @chainlink/contracts/src/v0.6/FluxAggregator.sol
npm package version: 0.0.9
 */
pragma solidity 0.6.11;

import "@chainlink/contracts/src/v0.6/Median.sol";
import "@chainlink/contracts/src/v0.6/Owned.sol";
import "@chainlink/contracts/src/v0.6/SafeMath128.sol";
import "@chainlink/contracts/src/v0.6/SafeMath32.sol";
import "@chainlink/contracts/src/v0.6/SafeMath64.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV2V3Interface.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorValidatorInterface.sol";
import "@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMath.sol";

/* solhint-disable */
/**
 * @title The Prepaid Aggregator contract
 * @notice Handles aggregating data pushed in from off-chain, and unlocks
 * payment for oracles as they report. Oracles' submissions are gathered in
 * rounds, with each round aggregating the submissions for each oracle into a
 * single answer. The latest aggregated answer is exposed as well as historical
 * answers and their updated at timestamp.
 */
contract FluxAggregator is AggregatorV2V3Interface, Owned {
    using SafeMath for uint256;
    using SafeMath128 for uint128;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;

    struct Round {
        int256 answer;
        uint64 startedAt;
        uint64 updatedAt;
        uint32 answeredInRound;
    }

    struct RoundDetails {
        int256[] submissions;
        uint32 maxSubmissions;
        uint32 minSubmissions;
        uint32 timeout;
        uint128 paymentAmount;
    }

    struct OracleStatus {
        uint128 withdrawable;
        uint32 startingRound;
        uint32 endingRound;
        uint32 lastReportedRound;
        uint32 lastStartedRound;
        int256 latestSubmission;
        uint16 index;
        address admin;
        address pendingAdmin;
    }

    struct Requester {
        bool authorized;
        uint32 delay;
        uint32 lastStartedRound;
    }

    struct Funds {
        uint128 available;
        uint128 allocated;
    }

    LinkTokenInterface public linkToken;
    AggregatorValidatorInterface public validator;

    // Round related params
    uint128 public paymentAmount;
    uint32 public maxSubmissionCount;
    uint32 public minSubmissionCount;
    uint32 public restartDelay;
    uint32 public timeout;
    uint8 public override decimals;
    string public override description;

    int256 public immutable minSubmissionValue;
    int256 public immutable maxSubmissionValue;

    uint256 public constant override version = 3;

    /**
     * @notice To ensure owner isn't withdrawing required funds as oracles are
     * submitting updates, we enforce that the contract maintains a minimum
     * reserve of RESERVE_ROUNDS * oracleCount() LINK earmarked for payment to
     * oracles. (Of course, this doesn't prevent the contract from running out of
     * funds without the owner's intervention.)
     */
    uint256 private constant RESERVE_ROUNDS = 2;
    uint256 private constant MAX_ORACLE_COUNT = 77;
    uint32 private constant ROUND_MAX = 2**32 - 1;
    uint256 private constant VALIDATOR_GAS_LIMIT = 100000;
    // An error specific to the Aggregator V3 Interface, to prevent possible
    // confusion around accidentally reading unset values as reported values.
    string private constant V3_NO_DATA_ERROR = "No data present";

    uint32 private reportingRoundId;
    uint32 internal latestRoundId;
    mapping(address => OracleStatus) private oracles;
    mapping(uint32 => Round) internal rounds;
    mapping(uint32 => RoundDetails) internal details;
    mapping(address => Requester) internal requesters;
    address[] private oracleAddresses;
    Funds private recordedFunds;

    event AvailableFundsUpdated(uint256 indexed amount);
    event RoundDetailsUpdated(
        uint128 indexed paymentAmount,
        uint32 indexed minSubmissionCount,
        uint32 indexed maxSubmissionCount,
        uint32 restartDelay,
        uint32 timeout // measured in seconds
    );
    event OraclePermissionsUpdated(
        address indexed oracle,
        bool indexed whitelisted
    );
    event OracleAdminUpdated(address indexed oracle, address indexed newAdmin);
    event OracleAdminUpdateRequested(
        address indexed oracle,
        address admin,
        address newAdmin
    );
    event SubmissionReceived(
        int256 indexed submission,
        uint32 indexed round,
        address indexed oracle
    );
    event RequesterPermissionsSet(
        address indexed requester,
        bool authorized,
        uint32 delay
    );
    event ValidatorUpdated(address indexed previous, address indexed current);

    /**
     * @notice set up the aggregator with initial configuration
     * @param _link The address of the LINK token
     * @param _paymentAmount The amount paid of LINK paid to each oracle per submission, in wei (units of 10⁻¹⁸ LINK)
     * @param _timeout is the number of seconds after the previous round that are
     * allowed to lapse before allowing an oracle to skip an unfinished round
     * @param _validator is an optional contract address for validating
     * external validation of answers
     * @param _minSubmissionValue is an immutable check for a lower bound of what
     * submission values are accepted from an oracle
     * @param _maxSubmissionValue is an immutable check for an upper bound of what
     * submission values are accepted from an oracle
     * @param _decimals represents the number of decimals to offset the answer by
     * @param _description a short description of what is being reported
     */
    constructor(
        address _link,
        uint128 _paymentAmount,
        uint32 _timeout,
        address _validator,
        int256 _minSubmissionValue,
        int256 _maxSubmissionValue,
        uint8 _decimals,
        string memory _description
    ) public {
        linkToken = LinkTokenInterface(_link);
        updateFutureRounds(_paymentAmount, 0, 0, 0, _timeout);
        setValidator(_validator);
        minSubmissionValue = _minSubmissionValue;
        maxSubmissionValue = _maxSubmissionValue;
        decimals = _decimals;
        description = _description;
        rounds[0].updatedAt = uint64(block.timestamp.sub(uint256(_timeout)));
    }

    /**
     * @notice called by oracles when they have witnessed a need to update
     * @param _roundId is the ID of the round this submission pertains to
     * @param _submission is the updated data that the oracle is submitting
     */
    function submit(uint256 _roundId, int256 _submission) external {
        bytes memory error = validateOracleRound(msg.sender, uint32(_roundId));
        require(
            _submission >= minSubmissionValue,
            "value below minSubmissionValue"
        );
        require(
            _submission <= maxSubmissionValue,
            "value above maxSubmissionValue"
        );
        require(error.length == 0, string(error));

        oracleInitializeNewRound(uint32(_roundId));
        recordSubmission(_submission, uint32(_roundId));
        (bool updated, int256 newAnswer) = updateRoundAnswer(uint32(_roundId));
        payOracle(uint32(_roundId));
        deleteRoundDetails(uint32(_roundId));
        if (updated) {
            validateAnswer(uint32(_roundId), newAnswer);
        }
    }

    /**
     * @notice called by the owner to remove and add new oracles as well as
     * update the round related parameters that pertain to total oracle count
     * @param _removed is the list of addresses for the new Oracles being removed
     * @param _added is the list of addresses for the new Oracles being added
     * @param _addedAdmins is the admin addresses for the new respective _added
     * list. Only this address is allowed to access the respective oracle's funds
     * @param _minSubmissions is the new minimum submission count for each round
     * @param _maxSubmissions is the new maximum submission count for each round
     * @param _restartDelay is the number of rounds an Oracle has to wait before
     * they can initiate a round
     */
    function changeOracles(
        address[] calldata _removed,
        address[] calldata _added,
        address[] calldata _addedAdmins,
        uint32 _minSubmissions,
        uint32 _maxSubmissions,
        uint32 _restartDelay
    ) external onlyOwner() {
        for (uint256 i = 0; i < _removed.length; i++) {
            removeOracle(_removed[i]);
        }

        require(
            _added.length == _addedAdmins.length,
            "need same oracle and admin count"
        );
        require(
            uint256(oracleCount()).add(_added.length) <= MAX_ORACLE_COUNT,
            "max oracles allowed"
        );

        for (uint256 i = 0; i < _added.length; i++) {
            addOracle(_added[i], _addedAdmins[i]);
        }

        updateFutureRounds(
            paymentAmount,
            _minSubmissions,
            _maxSubmissions,
            _restartDelay,
            timeout
        );
    }

    /**
     * @notice update the round and payment related parameters for subsequent
     * rounds
     * @param _paymentAmount is the payment amount for subsequent rounds
     * @param _minSubmissions is the new minimum submission count for each round
     * @param _maxSubmissions is the new maximum submission count for each round
     * @param _restartDelay is the number of rounds an Oracle has to wait before
     * they can initiate a round
     */
    function updateFutureRounds(
        uint128 _paymentAmount,
        uint32 _minSubmissions,
        uint32 _maxSubmissions,
        uint32 _restartDelay,
        uint32 _timeout
    ) public onlyOwner() {
        uint32 oracleNum = oracleCount(); // Save on storage reads
        require(
            _maxSubmissions >= _minSubmissions,
            "max must equal/exceed min"
        );
        require(oracleNum >= _maxSubmissions, "max cannot exceed total");
        require(
            oracleNum == 0 || oracleNum > _restartDelay,
            "delay cannot exceed total"
        );
        require(
            recordedFunds.available >= requiredReserve(_paymentAmount),
            "insufficient funds for payment"
        );
        if (oracleCount() > 0) {
            require(_minSubmissions > 0, "min must be greater than 0");
        }

        paymentAmount = _paymentAmount;
        minSubmissionCount = _minSubmissions;
        maxSubmissionCount = _maxSubmissions;
        restartDelay = _restartDelay;
        timeout = _timeout;

        emit RoundDetailsUpdated(
            paymentAmount,
            _minSubmissions,
            _maxSubmissions,
            _restartDelay,
            _timeout
        );
    }

    /**
     * @notice the amount of payment yet to be withdrawn by oracles
     */
    function allocatedFunds() external view returns (uint128) {
        return recordedFunds.allocated;
    }

    /**
     * @notice the amount of future funding available to oracles
     */
    function availableFunds() external view returns (uint128) {
        return recordedFunds.available;
    }

    /**
     * @notice recalculate the amount of LINK available for payouts
     */
    function updateAvailableFunds() public {
        Funds memory funds = recordedFunds;

        uint256 nowAvailable =
            linkToken.balanceOf(address(this)).sub(funds.allocated);

        if (funds.available != nowAvailable) {
            recordedFunds.available = uint128(nowAvailable);
            emit AvailableFundsUpdated(nowAvailable);
        }
    }

    /**
     * @notice returns the number of oracles
     */
    function oracleCount() public view returns (uint8) {
        return uint8(oracleAddresses.length);
    }

    /**
     * @notice returns an array of addresses containing the oracles on contract
     */
    function getOracles() external view returns (address[] memory) {
        return oracleAddresses;
    }

    /**
     * @notice get the most recently reported answer
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestAnswer() public view virtual override returns (int256) {
        return rounds[latestRoundId].answer;
    }

    /**
     * @notice get the most recent updated at timestamp
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestTimestamp() public view virtual override returns (uint256) {
        return rounds[latestRoundId].updatedAt;
    }

    /**
     * @notice get the ID of the last updated round
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestRound() public view virtual override returns (uint256) {
        return latestRoundId;
    }

    /**
     * @notice get past rounds answers
     * @param _roundId the round number to retrieve the answer for
     *
     * @dev #[deprecated] Use getRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended getRoundData
     * instead which includes better verification information.
     */
    function getAnswer(uint256 _roundId)
        public
        view
        virtual
        override
        returns (int256)
    {
        if (validRoundId(_roundId)) {
            return rounds[uint32(_roundId)].answer;
        }
        return 0;
    }

    /**
     * @notice get timestamp when an answer was last updated
     * @param _roundId the round number to retrieve the updated timestamp for
     *
     * @dev #[deprecated] Use getRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended getRoundData
     * instead which includes better verification information.
     */
    function getTimestamp(uint256 _roundId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (validRoundId(_roundId)) {
            return rounds[uint32(_roundId)].updatedAt;
        }
        return 0;
    }

    /**
     * @notice get data about a round. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values.
     * @param _roundId the round ID to retrieve the round data for
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started. This is 0
     * if the round hasn't been started yet.
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed. answeredInRound may be smaller than roundId when the round
     * timed out. answeredInRound is equal to roundId when the round didn't time out
     * and was completed regularly.
     * @dev Note that for in-progress rounds (i.e. rounds that haven't yet received
     * maxSubmissions) answer and updatedAt may change between queries.
     */
    function getRoundData(uint80 _roundId)
        public
        view
        virtual
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        Round memory r = rounds[uint32(_roundId)];

        require(
            r.answeredInRound > 0 && validRoundId(_roundId),
            V3_NO_DATA_ERROR
        );

        return (
            _roundId,
            r.answer,
            r.startedAt,
            r.updatedAt,
            r.answeredInRound
        );
    }

    /**
     * @notice get data about the latest round. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values. Consumers are encouraged to
     * use this more fully featured method over the "legacy" latestRound/
     * latestAnswer/latestTimestamp functions. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values.
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started. This is 0
     * if the round hasn't been started yet.
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed. answeredInRound may be smaller than roundId when the round
     * timed out. answeredInRound is equal to roundId when the round didn't time
     * out and was completed regularly.
     * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
     * received maxSubmissions) answer and updatedAt may change between queries.
     */
    function latestRoundData()
        public
        view
        virtual
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return getRoundData(latestRoundId);
    }

    /**
     * @notice query the available amount of LINK for an oracle to withdraw
     */
    function withdrawablePayment(address _oracle)
        external
        view
        returns (uint256)
    {
        return oracles[_oracle].withdrawable;
    }

    /**
     * @notice transfers the oracle's LINK to another address. Can only be called
     * by the oracle's admin.
     * @param _oracle is the oracle whose LINK is transferred
     * @param _recipient is the address to send the LINK to
     * @param _amount is the amount of LINK to send
     */
    function withdrawPayment(
        address _oracle,
        address _recipient,
        uint256 _amount
    ) external {
        require(oracles[_oracle].admin == msg.sender, "only callable by admin");

        // Safe to downcast _amount because the total amount of LINK is less than 2^128.
        uint128 amount = uint128(_amount);
        uint128 available = oracles[_oracle].withdrawable;
        require(available >= amount, "insufficient withdrawable funds");

        oracles[_oracle].withdrawable = available.sub(amount);
        recordedFunds.allocated = recordedFunds.allocated.sub(amount);

        assert(linkToken.transfer(_recipient, uint256(amount)));
    }

    /**
     * @notice transfers the owner's LINK to another address
     * @param _recipient is the address to send the LINK to
     * @param _amount is the amount of LINK to send
     */
    function withdrawFunds(address _recipient, uint256 _amount)
        external
        onlyOwner()
    {
        uint256 available = uint256(recordedFunds.available);
        require(
            available.sub(requiredReserve(paymentAmount)) >= _amount,
            "insufficient reserve funds"
        );
        require(
            linkToken.transfer(_recipient, _amount),
            "token transfer failed"
        );
        updateAvailableFunds();
    }

    /**
     * @notice get the admin address of an oracle
     * @param _oracle is the address of the oracle whose admin is being queried
     */
    function getAdmin(address _oracle) external view returns (address) {
        return oracles[_oracle].admin;
    }

    /**
     * @notice transfer the admin address for an oracle
     * @param _oracle is the address of the oracle whose admin is being transferred
     * @param _newAdmin is the new admin address
     */
    function transferAdmin(address _oracle, address _newAdmin) external {
        require(oracles[_oracle].admin == msg.sender, "only callable by admin");
        oracles[_oracle].pendingAdmin = _newAdmin;

        emit OracleAdminUpdateRequested(_oracle, msg.sender, _newAdmin);
    }

    /**
     * @notice accept the admin address transfer for an oracle
     * @param _oracle is the address of the oracle whose admin is being transferred
     */
    function acceptAdmin(address _oracle) external {
        require(
            oracles[_oracle].pendingAdmin == msg.sender,
            "only callable by pending admin"
        );
        oracles[_oracle].pendingAdmin = address(0);
        oracles[_oracle].admin = msg.sender;

        emit OracleAdminUpdated(_oracle, msg.sender);
    }

    /**
     * @notice allows non-oracles to request a new round
     */
    function requestNewRound() external returns (uint80) {
        require(requesters[msg.sender].authorized, "not authorized requester");

        uint32 current = reportingRoundId;
        require(
            rounds[current].updatedAt > 0 || timedOut(current),
            "prev round must be supersedable"
        );

        uint32 newRoundId = current.add(1);
        requesterInitializeNewRound(newRoundId);
        return newRoundId;
    }

    /**
     * @notice allows the owner to specify new non-oracles to start new rounds
     * @param _requester is the address to set permissions for
     * @param _authorized is a boolean specifying whether they can start new rounds or not
     * @param _delay is the number of rounds the requester must wait before starting another round
     */
    function setRequesterPermissions(
        address _requester,
        bool _authorized,
        uint32 _delay
    ) external onlyOwner() {
        if (requesters[_requester].authorized == _authorized) return;

        if (_authorized) {
            requesters[_requester].authorized = _authorized;
            requesters[_requester].delay = _delay;
        } else {
            delete requesters[_requester];
        }

        emit RequesterPermissionsSet(_requester, _authorized, _delay);
    }

    /**
     * @notice called through LINK's transferAndCall to update available funds
     * in the same transaction as the funds were transferred to the aggregator
     * @param _data is mostly ignored. It is checked for length, to be sure
     * nothing strange is passed in.
     */
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata _data
    ) external {
        require(_data.length == 0, "transfer doesn't accept calldata");
        updateAvailableFunds();
    }

    /**
     * @notice a method to provide all current info oracles need. Intended only
     * only to be callable by oracles. Not for use by contracts to read state.
     * @param _oracle the address to look up information for.
     */
    function oracleRoundState(address _oracle, uint32 _queriedRoundId)
        external
        view
        returns (
            bool _eligibleToSubmit,
            uint32 _roundId,
            int256 _latestSubmission,
            uint64 _startedAt,
            uint64 _timeout,
            uint128 _availableFunds,
            uint8 _oracleCount,
            uint128 _paymentAmount
        )
    {
        require(msg.sender == tx.origin, "off-chain reading only");

        if (_queriedRoundId > 0) {
            Round storage round = rounds[_queriedRoundId];
            RoundDetails storage details = details[_queriedRoundId];
            return (
                eligibleForSpecificRound(_oracle, _queriedRoundId),
                _queriedRoundId,
                oracles[_oracle].latestSubmission,
                round.startedAt,
                details.timeout,
                recordedFunds.available,
                oracleCount(),
                (round.startedAt > 0 ? details.paymentAmount : paymentAmount)
            );
        } else {
            return oracleRoundStateSuggestRound(_oracle);
        }
    }

    /**
     * @notice method to update the address which does external data validation.
     * @param _newValidator designates the address of the new validation contract.
     */
    function setValidator(address _newValidator) public onlyOwner() {
        address previous = address(validator);

        if (previous != _newValidator) {
            validator = AggregatorValidatorInterface(_newValidator);

            emit ValidatorUpdated(previous, _newValidator);
        }
    }

    /**
     * Private
     */

    function initializeNewRound(uint32 _roundId) private {
        updateTimedOutRoundInfo(_roundId.sub(1));

        reportingRoundId = _roundId;
        RoundDetails memory nextDetails =
            RoundDetails(
                new int256[](0),
                maxSubmissionCount,
                minSubmissionCount,
                timeout,
                paymentAmount
            );
        details[_roundId] = nextDetails;
        rounds[_roundId].startedAt = uint64(block.timestamp);

        emit NewRound(_roundId, msg.sender, rounds[_roundId].startedAt);
    }

    function oracleInitializeNewRound(uint32 _roundId) private {
        if (!newRound(_roundId)) return;
        uint256 lastStarted = oracles[msg.sender].lastStartedRound; // cache storage reads
        if (_roundId <= lastStarted + restartDelay && lastStarted != 0) return;

        initializeNewRound(_roundId);

        oracles[msg.sender].lastStartedRound = _roundId;
    }

    function requesterInitializeNewRound(uint32 _roundId) private {
        if (!newRound(_roundId)) return;
        uint256 lastStarted = requesters[msg.sender].lastStartedRound; // cache storage reads
        require(
            _roundId > lastStarted + requesters[msg.sender].delay ||
                lastStarted == 0,
            "must delay requests"
        );

        initializeNewRound(_roundId);

        requesters[msg.sender].lastStartedRound = _roundId;
    }

    function updateTimedOutRoundInfo(uint32 _roundId) private {
        if (!timedOut(_roundId)) return;

        uint32 prevId = _roundId.sub(1);
        rounds[_roundId].answer = rounds[prevId].answer;
        rounds[_roundId].answeredInRound = rounds[prevId].answeredInRound;
        rounds[_roundId].updatedAt = uint64(block.timestamp);

        delete details[_roundId];
    }

    function eligibleForSpecificRound(address _oracle, uint32 _queriedRoundId)
        private
        view
        returns (bool _eligible)
    {
        if (rounds[_queriedRoundId].startedAt > 0) {
            return
                acceptingSubmissions(_queriedRoundId) &&
                validateOracleRound(_oracle, _queriedRoundId).length == 0;
        } else {
            return
                delayed(_oracle, _queriedRoundId) &&
                validateOracleRound(_oracle, _queriedRoundId).length == 0;
        }
    }

    function oracleRoundStateSuggestRound(address _oracle)
        private
        view
        returns (
            bool _eligibleToSubmit,
            uint32 _roundId,
            int256 _latestSubmission,
            uint64 _startedAt,
            uint64 _timeout,
            uint128 _availableFunds,
            uint8 _oracleCount,
            uint128 _paymentAmount
        )
    {
        Round storage round = rounds[0];
        OracleStatus storage oracle = oracles[_oracle];

        bool shouldSupersede =
            oracle.lastReportedRound == reportingRoundId ||
                !acceptingSubmissions(reportingRoundId);
        // Instead of nudging oracles to submit to the next round, the inclusion of
        // the shouldSupersede bool in the if condition pushes them towards
        // submitting in a currently open round.
        if (supersedable(reportingRoundId) && shouldSupersede) {
            _roundId = reportingRoundId.add(1);
            round = rounds[_roundId];

            _paymentAmount = paymentAmount;
            _eligibleToSubmit = delayed(_oracle, _roundId);
        } else {
            _roundId = reportingRoundId;
            round = rounds[_roundId];

            _paymentAmount = details[_roundId].paymentAmount;
            _eligibleToSubmit = acceptingSubmissions(_roundId);
        }

        if (validateOracleRound(_oracle, _roundId).length != 0) {
            _eligibleToSubmit = false;
        }

        return (
            _eligibleToSubmit,
            _roundId,
            oracle.latestSubmission,
            round.startedAt,
            details[_roundId].timeout,
            recordedFunds.available,
            oracleCount(),
            _paymentAmount
        );
    }

    function updateRoundAnswer(uint32 _roundId)
        internal
        returns (bool, int256)
    {
        if (
            details[_roundId].submissions.length <
            details[_roundId].minSubmissions
        ) {
            return (false, 0);
        }

        int256 newAnswer =
            Median.calculateInplace(details[_roundId].submissions);
        rounds[_roundId].answer = newAnswer;
        rounds[_roundId].updatedAt = uint64(block.timestamp);
        rounds[_roundId].answeredInRound = _roundId;
        latestRoundId = _roundId;

        emit AnswerUpdated(newAnswer, _roundId, now);

        return (true, newAnswer);
    }

    function validateAnswer(uint32 _roundId, int256 _newAnswer) private {
        AggregatorValidatorInterface av = validator; // cache storage reads
        if (address(av) == address(0)) return;

        uint32 prevRound = _roundId.sub(1);
        uint32 prevAnswerRoundId = rounds[prevRound].answeredInRound;
        int256 prevRoundAnswer = rounds[prevRound].answer;
        // We do not want the validator to ever prevent reporting, so we limit its
        // gas usage and catch any errors that may arise.
        try
            av.validate{gas: VALIDATOR_GAS_LIMIT}(
                prevAnswerRoundId,
                prevRoundAnswer,
                _roundId,
                _newAnswer
            )
        {} catch {}
    }

    function payOracle(uint32 _roundId) private {
        uint128 payment = details[_roundId].paymentAmount;
        Funds memory funds = recordedFunds;
        funds.available = funds.available.sub(payment);
        funds.allocated = funds.allocated.add(payment);
        recordedFunds = funds;
        oracles[msg.sender].withdrawable = oracles[msg.sender].withdrawable.add(
            payment
        );

        emit AvailableFundsUpdated(funds.available);
    }

    function recordSubmission(int256 _submission, uint32 _roundId) private {
        require(
            acceptingSubmissions(_roundId),
            "round not accepting submissions"
        );

        details[_roundId].submissions.push(_submission);
        oracles[msg.sender].lastReportedRound = _roundId;
        oracles[msg.sender].latestSubmission = _submission;

        emit SubmissionReceived(_submission, _roundId, msg.sender);
    }

    function deleteRoundDetails(uint32 _roundId) private {
        if (
            details[_roundId].submissions.length <
            details[_roundId].maxSubmissions
        ) return;

        delete details[_roundId];
    }

    function timedOut(uint32 _roundId) private view returns (bool) {
        uint64 startedAt = rounds[_roundId].startedAt;
        uint32 roundTimeout = details[_roundId].timeout;
        return
            startedAt > 0 &&
            roundTimeout > 0 &&
            startedAt.add(roundTimeout) < block.timestamp;
    }

    function getStartingRound(address _oracle) private view returns (uint32) {
        uint32 currentRound = reportingRoundId;
        if (currentRound != 0 && currentRound == oracles[_oracle].endingRound) {
            return currentRound;
        }
        return currentRound.add(1);
    }

    function previousAndCurrentUnanswered(uint32 _roundId, uint32 _rrId)
        private
        view
        returns (bool)
    {
        return _roundId.add(1) == _rrId && rounds[_rrId].updatedAt == 0;
    }

    function requiredReserve(uint256 payment) private view returns (uint256) {
        return payment.mul(oracleCount()).mul(RESERVE_ROUNDS);
    }

    function addOracle(address _oracle, address _admin) private {
        require(!oracleEnabled(_oracle), "oracle already enabled");

        require(_admin != address(0), "cannot set admin to 0");
        require(
            oracles[_oracle].admin == address(0) ||
                oracles[_oracle].admin == _admin,
            "owner cannot overwrite admin"
        );

        oracles[_oracle].startingRound = getStartingRound(_oracle);
        oracles[_oracle].endingRound = ROUND_MAX;
        oracles[_oracle].index = uint16(oracleAddresses.length);
        oracleAddresses.push(_oracle);
        oracles[_oracle].admin = _admin;

        emit OraclePermissionsUpdated(_oracle, true);
        emit OracleAdminUpdated(_oracle, _admin);
    }

    function removeOracle(address _oracle) private {
        require(oracleEnabled(_oracle), "oracle not enabled");

        oracles[_oracle].endingRound = reportingRoundId.add(1);
        address tail = oracleAddresses[uint256(oracleCount()).sub(1)];
        uint16 index = oracles[_oracle].index;
        oracles[tail].index = index;
        delete oracles[_oracle].index;
        oracleAddresses[index] = tail;
        oracleAddresses.pop();

        emit OraclePermissionsUpdated(_oracle, false);
    }

    function validateOracleRound(address _oracle, uint32 _roundId)
        private
        view
        returns (bytes memory)
    {
        // cache storage reads
        uint32 startingRound = oracles[_oracle].startingRound;
        uint32 rrId = reportingRoundId;

        if (startingRound == 0) return "not enabled oracle";
        if (startingRound > _roundId) return "not yet enabled oracle";
        if (oracles[_oracle].endingRound < _roundId)
            return "no longer allowed oracle";
        if (oracles[_oracle].lastReportedRound >= _roundId)
            return "cannot report on previous rounds";
        if (
            _roundId != rrId &&
            _roundId != rrId.add(1) &&
            !previousAndCurrentUnanswered(_roundId, rrId)
        ) return "invalid round to report";
        if (_roundId != 1 && !supersedable(_roundId.sub(1)))
            return "previous round not supersedable";
    }

    function supersedable(uint32 _roundId) private view returns (bool) {
        return rounds[_roundId].updatedAt > 0 || timedOut(_roundId);
    }

    function oracleEnabled(address _oracle) private view returns (bool) {
        return oracles[_oracle].endingRound == ROUND_MAX;
    }

    function acceptingSubmissions(uint32 _roundId) private view returns (bool) {
        return details[_roundId].maxSubmissions != 0;
    }

    function delayed(address _oracle, uint32 _roundId)
        private
        view
        returns (bool)
    {
        uint256 lastStarted = oracles[_oracle].lastStartedRound;
        return _roundId > lastStarted + restartDelay || lastStarted == 0;
    }

    function newRound(uint32 _roundId) private view returns (bool) {
        return _roundId == reportingRoundId.add(1);
    }

    function validRoundId(uint256 _roundId) private view returns (bool) {
        return _roundId <= ROUND_MAX;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Interface for securely interacting with Chainlink aggregators
 */
interface IOracleAdapter {
    struct Value {
        uint256 value;
        uint256 periodEnd;
    }

    /// @notice Event fired when asset's pricing source (aggregator) is updated
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /// @notice Event fired when the TVL aggregator address is updated
    event TvlSourceUpdated(address indexed source);

    /**
     * @notice Set the TVL source (aggregator)
     * @param source The new TVL source (aggregator)
     */
    function emergencySetTvlSource(address source) external;

    /**
     * @notice Set an asset's price source (aggregator)
     * @param asset The asset to change the source of
     * @param source The new source (aggregator)
     */
    function emergencySetAssetSource(address asset, address source) external;

    /**
     * @notice Set multiple assets' pricing sources
     * @param assets An array of assets (tokens)
     * @param sources An array of price sources (aggregators)
     */
    function emergencySetAssetSources(
        address[] memory assets,
        address[] memory sources
    ) external;

    /**
     * @notice Retrieve the asset's price from its pricing source
     * @param asset The asset address
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Retrieve the deployed TVL from the TVL aggregator
     * @return The TVL
     */
    function getTvl() external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IOracleAdapter} from "./IOracleAdapter.sol";

interface IOverrideOracle is IOracleAdapter {
    /**
     * @notice Event fired when asset value is set manually
     * @param asset The asset that is being overridden
     * @param value The new value used for the override
     * @param period The number of blocks the override will be active for
     * @param periodEnd The block on which the override ends
     */
    event AssetValueSet(
        address asset,
        uint256 value,
        uint256 period,
        uint256 periodEnd
    );

    /**
     * @notice Event fired when manually submitted asset value is
     * invalidated, allowing usual Chainlink pricing.
     */
    event AssetValueUnset(address asset);

    /**
     * @notice Event fired when deployed TVL is set manually
     * @param value The new value used for the override
     * @param period The number of blocks the override will be active for
     * @param periodEnd The block on which the override ends
     */
    event TvlSet(uint256 value, uint256 period, uint256 periodEnd);

    /**
     * @notice Event fired when manually submitted TVL is
     * invalidated, allowing usual Chainlink pricing.
     */
    event TvlUnset();

    /**
     * @notice Manually override the asset pricing source with a value
     * @param asset The asset that is being overriden
     * @param value asset value to return instead of from Chainlink
     * @param period length of time, in number of blocks, to use manual override
     */
    function emergencySetAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external;

    /**
     * @notice Revoke manually set value, allowing usual Chainlink pricing
     * @param asset address of asset to price
     */
    function emergencyUnsetAssetValue(address asset) external;

    /**
     * @notice Manually override the TVL source with a value
     * @param value TVL to return instead of from Chainlink
     * @param period length of time, in number of blocks, to use manual override
     */
    function emergencySetTvl(uint256 value, uint256 period) external;

    /// @notice Revoke manually set value, allowing usual Chainlink pricing
    function emergencyUnsetTvl() external;

    /// @notice Check if TVL has active manual override
    function hasTvlOverride() external view returns (bool);

    /**
     * @notice Check if asset has active manual override
     * @param asset address of the asset
     * @return `true` if manual override is active
     */
    function hasAssetOverride(address asset) external view returns (bool);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IOracleAdapter} from "./IOracleAdapter.sol";

/**
 * @notice For an `IOracleAdapter` that can be locked and unlocked
 */
interface ILockingOracle is IOracleAdapter {
    /// @notice Event fired when using the default lock
    event DefaultLocked(address locker, uint256 defaultPeriod, uint256 lockEnd);

    /// @notice Event fired when using a specified lock period
    event Locked(address locker, uint256 activePeriod, uint256 lockEnd);

    /// @notice Event fired when changing the default locking period
    event DefaultLockPeriodChanged(uint256 newPeriod);

    /// @notice Event fired when unlocking the adapter
    event Unlocked();

    /// @notice Event fired when updating the threshold for stale data
    event ChainlinkStalePeriodUpdated(uint256 period);

    /// @notice Block price/value retrieval for the default locking duration
    function lock() external;

    /**
     * @notice Block price/value retrieval for the specified duration.
     * @param period number of blocks to block retrieving values
     */
    function lockFor(uint256 period) external;

    /**
     * @notice Unblock price/value retrieval.  Should only be callable
     * by the Emergency Safe.
     */
    function emergencyUnlock() external;

    /**
     * @notice Set the length of time before values can be retrieved.
     * @param newPeriod number of blocks before values can be retrieved
     */
    function setDefaultLockPeriod(uint256 newPeriod) external;

    /**
     * @notice Set the length of time before an agg value is considered stale.
     * @param chainlinkStalePeriod_ the length of time in seconds
     */
    function setChainlinkStalePeriod(uint256 chainlinkStalePeriod_) external;

    /**
     * @notice Get the length of time, in number of blocks, before values
     * can be retrieved.
     */
    function defaultLockPeriod() external returns (uint256 period);

    /// @notice Check if the adapter is blocked from retrieving values.
    function isLocked() external view returns (bool);
}

pragma solidity ^0.6.0;

import "./vendor/SafeMath.sol";
import "./SignedSafeMath.sol";

library Median {
  using SignedSafeMath for int256;

  int256 constant INT_MAX = 2**255-1;

  /**
   * @notice Returns the sorted middle, or the average of the two middle indexed items if the
   * array has an even number of elements.
   * @dev The list passed as an argument isn't modified.
   * @dev This algorithm has expected runtime O(n), but for adversarially chosen inputs
   * the runtime is O(n^2).
   * @param list The list of elements to compare
   */
  function calculate(int256[] memory list)
    internal
    pure
    returns (int256)
  {
    return calculateInplace(copy(list));
  }

  /**
   * @notice See documentation for function calculate.
   * @dev The list passed as an argument may be permuted.
   */
  function calculateInplace(int256[] memory list)
    internal
    pure
    returns (int256)
  {
    require(0 < list.length, "list must not be empty");
    uint256 len = list.length;
    uint256 middleIndex = len / 2;
    if (len % 2 == 0) {
      int256 median1;
      int256 median2;
      (median1, median2) = quickselectTwo(list, 0, len - 1, middleIndex - 1, middleIndex);
      return SignedSafeMath.avg(median1, median2);
    } else {
      return quickselect(list, 0, len - 1, middleIndex);
    }
  }

  /**
   * @notice Maximum length of list that shortSelectTwo can handle
   */
  uint256 constant SHORTSELECTTWO_MAX_LENGTH = 7;

  /**
   * @notice Select the k1-th and k2-th element from list of length at most 7
   * @dev Uses an optimal sorting network
   */
  function shortSelectTwo(
    int256[] memory list,
    uint256 lo,
    uint256 hi,
    uint256 k1,
    uint256 k2
  )
    private
    pure
    returns (int256 k1th, int256 k2th)
  {
    // Uses an optimal sorting network (https://en.wikipedia.org/wiki/Sorting_network)
    // for lists of length 7. Network layout is taken from
    // http://jgamble.ripco.net/cgi-bin/nw.cgi?inputs=7&algorithm=hibbard&output=svg

    uint256 len = hi + 1 - lo;
    int256 x0 = list[lo + 0];
    int256 x1 = 1 < len ? list[lo + 1] : INT_MAX;
    int256 x2 = 2 < len ? list[lo + 2] : INT_MAX;
    int256 x3 = 3 < len ? list[lo + 3] : INT_MAX;
    int256 x4 = 4 < len ? list[lo + 4] : INT_MAX;
    int256 x5 = 5 < len ? list[lo + 5] : INT_MAX;
    int256 x6 = 6 < len ? list[lo + 6] : INT_MAX;

    if (x0 > x1) {(x0, x1) = (x1, x0);}
    if (x2 > x3) {(x2, x3) = (x3, x2);}
    if (x4 > x5) {(x4, x5) = (x5, x4);}
    if (x0 > x2) {(x0, x2) = (x2, x0);}
    if (x1 > x3) {(x1, x3) = (x3, x1);}
    if (x4 > x6) {(x4, x6) = (x6, x4);}
    if (x1 > x2) {(x1, x2) = (x2, x1);}
    if (x5 > x6) {(x5, x6) = (x6, x5);}
    if (x0 > x4) {(x0, x4) = (x4, x0);}
    if (x1 > x5) {(x1, x5) = (x5, x1);}
    if (x2 > x6) {(x2, x6) = (x6, x2);}
    if (x1 > x4) {(x1, x4) = (x4, x1);}
    if (x3 > x6) {(x3, x6) = (x6, x3);}
    if (x2 > x4) {(x2, x4) = (x4, x2);}
    if (x3 > x5) {(x3, x5) = (x5, x3);}
    if (x3 > x4) {(x3, x4) = (x4, x3);}

    uint256 index1 = k1 - lo;
    if (index1 == 0) {k1th = x0;}
    else if (index1 == 1) {k1th = x1;}
    else if (index1 == 2) {k1th = x2;}
    else if (index1 == 3) {k1th = x3;}
    else if (index1 == 4) {k1th = x4;}
    else if (index1 == 5) {k1th = x5;}
    else if (index1 == 6) {k1th = x6;}
    else {revert("k1 out of bounds");}

    uint256 index2 = k2 - lo;
    if (k1 == k2) {return (k1th, k1th);}
    else if (index2 == 0) {return (k1th, x0);}
    else if (index2 == 1) {return (k1th, x1);}
    else if (index2 == 2) {return (k1th, x2);}
    else if (index2 == 3) {return (k1th, x3);}
    else if (index2 == 4) {return (k1th, x4);}
    else if (index2 == 5) {return (k1th, x5);}
    else if (index2 == 6) {return (k1th, x6);}
    else {revert("k2 out of bounds");}
  }

  /**
   * @notice Selects the k-th ranked element from list, looking only at indices between lo and hi
   * (inclusive). Modifies list in-place.
   */
  function quickselect(int256[] memory list, uint256 lo, uint256 hi, uint256 k)
    private
    pure
    returns (int256 kth)
  {
    require(lo <= k);
    require(k <= hi);
    while (lo < hi) {
      if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
        int256 ignore;
        (kth, ignore) = shortSelectTwo(list, lo, hi, k, k);
        return kth;
      }
      uint256 pivotIndex = partition(list, lo, hi);
      if (k <= pivotIndex) {
        // since pivotIndex < (original hi passed to partition),
        // termination is guaranteed in this case
        hi = pivotIndex;
      } else {
        // since (original lo passed to partition) <= pivotIndex,
        // termination is guaranteed in this case
        lo = pivotIndex + 1;
      }
    }
    return list[lo];
  }

  /**
   * @notice Selects the k1-th and k2-th ranked elements from list, looking only at indices between
   * lo and hi (inclusive). Modifies list in-place.
   */
  function quickselectTwo(
    int256[] memory list,
    uint256 lo,
    uint256 hi,
    uint256 k1,
    uint256 k2
  )
    internal // for testing
    pure
    returns (int256 k1th, int256 k2th)
  {
    require(k1 < k2);
    require(lo <= k1 && k1 <= hi);
    require(lo <= k2 && k2 <= hi);

    while (true) {
      if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
        return shortSelectTwo(list, lo, hi, k1, k2);
      }
      uint256 pivotIdx = partition(list, lo, hi);
      if (k2 <= pivotIdx) {
        hi = pivotIdx;
      } else if (pivotIdx < k1) {
        lo = pivotIdx + 1;
      } else {
        assert(k1 <= pivotIdx && pivotIdx < k2);
        k1th = quickselect(list, lo, pivotIdx, k1);
        k2th = quickselect(list, pivotIdx + 1, hi, k2);
        return (k1th, k2th);
      }
    }
  }

  /**
   * @notice Partitions list in-place using Hoare's partitioning scheme.
   * Only elements of list between indices lo and hi (inclusive) will be modified.
   * Returns an index i, such that:
   * - lo <= i < hi
   * - forall j in [lo, i]. list[j] <= list[i]
   * - forall j in [i, hi]. list[i] <= list[j]
   */
  function partition(int256[] memory list, uint256 lo, uint256 hi)
    private
    pure
    returns (uint256)
  {
    // We don't care about overflow of the addition, because it would require a list
    // larger than any feasible computer's memory.
    int256 pivot = list[(lo + hi) / 2];
    lo -= 1; // this can underflow. that's intentional.
    hi += 1;
    while (true) {
      do {
        lo += 1;
      } while (list[lo] < pivot);
      do {
        hi -= 1;
      } while (list[hi] > pivot);
      if (lo < hi) {
        (list[lo], list[hi]) = (list[hi], list[lo]);
      } else {
        // Let orig_lo and orig_hi be the original values of lo and hi passed to partition.
        // Then, hi < orig_hi, because hi decreases *strictly* monotonically
        // in each loop iteration and
        // - either list[orig_hi] > pivot, in which case the first loop iteration
        //   will achieve hi < orig_hi;
        // - or list[orig_hi] <= pivot, in which case at least two loop iterations are
        //   needed:
        //   - lo will have to stop at least once in the interval
        //     [orig_lo, (orig_lo + orig_hi)/2]
        //   - (orig_lo + orig_hi)/2 < orig_hi
        return hi;
      }
    }
  }

  /**
   * @notice Makes an in-memory copy of the array passed in
   * @param list Reference to the array to be copied
   */
  function copy(int256[] memory list)
    private
    pure
    returns(int256[] memory)
  {
    int256[] memory list2 = new int256[](list.length);
    for (uint256 i = 0; i < list.length; i++) {
      list2[i] = list[i];
    }
    return list2;
  }
}

pragma solidity ^0.6.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address payable public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

pragma solidity ^0.6.0;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 128 bit integers.
 */
library SafeMath128 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint128 a, uint128 b) internal pure returns (uint128) {
    uint128 c = a + b;
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
    * - Subtraction cannot overflow.
    */
  function sub(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint128 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint128 a, uint128 b) internal pure returns (uint128) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint128 c = a * b;
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
    * - The divisor cannot be zero.
    */
  function div(uint128 a, uint128 b) internal pure returns (uint128) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint128 c = a / b;
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
    * - The divisor cannot be zero.
    */
  function mod(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 32 bit integers.
 */
library SafeMath32 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
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
    * - Subtraction cannot overflow.
    */
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint32 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint32 c = a * b;
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
    * - The divisor cannot be zero.
    */
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint32 c = a / b;
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
    * - The divisor cannot be zero.
    */
  function mod(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 64 bit integers.
 */
library SafeMath64 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
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
    * - Subtraction cannot overflow.
    */
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint64 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint64 a, uint64 b) internal pure returns (uint64) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint64 c = a * b;
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
    * - The divisor cannot be zero.
    */
  function div(uint64 a, uint64 b) internal pure returns (uint64) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint64 c = a / b;
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
    * - The divisor cannot be zero.
    */
  function mod(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

pragma solidity ^0.6.0;

interface AggregatorValidatorInterface {
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  ) external returns (bool);
}

pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

pragma solidity ^0.6.0;

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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

library SignedSafeMath {
  int256 constant private _INT256_MIN = -2**255;

  /**
   * @dev Multiplies two signed integers, reverts on overflow.
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
   * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

    int256 c = a / b;

    return c;
  }

  /**
   * @dev Subtracts two signed integers, reverts on overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  /**
   * @dev Adds two signed integers, reverts on overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  /**
   * @notice Computes average of two signed integers, ensuring that the computation
   * doesn't overflow.
   * @dev If the result is not an integer, it is rounded towards zero. For example,
   * avg(-3, -4) = -3
   */
  function avg(int256 _a, int256 _b)
    internal
    pure
    returns (int256)
  {
    if ((_a < 0 && _b > 0) || (_a > 0 && _b < 0)) {
      return add(_a, _b) / 2;
    }
    int256 remainder = (_a % 2 + _b % 2) / 2;
    return add(add(_a / 2, _b / 2), remainder);
  }
}

pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, IDetailedERC20} from "contracts/common/Imports.sol";

/**
 * @notice An asset allocation for tokens not stored in a protocol
 * @dev `IZap`s and `ISwap`s register these separate from other allocations
 * @dev Unlike other asset allocations, new tokens can be added or removed
 * @dev Registration can override `symbol` and `decimals` manually because
 * they are optional in the ERC20 standard.
 */
interface IErc20Allocation {
    /** @notice Log when an ERC20 allocation is registered */
    event Erc20TokenRegistered(IERC20 token, string symbol, uint8 decimals);

    /** @notice Log when an ERC20 allocation is removed */
    event Erc20TokenRemoved(IERC20 token);

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     */
    function registerErc20Token(IDetailedERC20 token) external;

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     * @param symbol Override the token symbol
     */
    function registerErc20Token(IDetailedERC20 token, string calldata symbol)
        external;

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     * @param symbol Override the token symbol
     * @param decimals Override the token decimals
     */
    function registerErc20Token(
        IERC20 token,
        string calldata symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Remove an ERC20 token from the asset allocation
     * @param token The token to remove
     */
    function removeErc20Token(IERC20 token) external;

    /**
     * @notice Check if an ERC20 token is registered
     * @param token The token to check
     * @return `true` if the token is registered, `false` otherwise
     */
    function isErc20TokenRegistered(IERC20 token) external view returns (bool);

    /**
     * @notice Check if multiple ERC20 tokens are ALL registered
     * @param tokens An array of tokens to check
     * @return `true` if every token is registered, `false` otherwise
     */
    function isErc20TokenRegistered(IERC20[] calldata tokens)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";

abstract contract AssetAllocationBase is IAssetAllocation {
    function numberOfTokens() external view override returns (uint256) {
        return tokens().length;
    }

    function symbolOf(uint8 tokenIndex)
        public
        view
        override
        returns (string memory)
    {
        return tokens()[tokenIndex].symbol;
    }

    function decimalsOf(uint8 tokenIndex) public view override returns (uint8) {
        return tokens()[tokenIndex].decimals;
    }

    function addressOf(uint8 tokenIndex) public view returns (address) {
        return tokens()[tokenIndex].token;
    }

    function tokens() public view virtual override returns (TokenData[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Ownable} from "contracts/common/Imports.sol";
import {Address} from "contracts/libraries/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {PoolToken} from "contracts/pool/PoolToken.sol";
import {PoolTokenProxy} from "contracts/pool/PoolTokenProxy.sol";
import {PoolTokenV2} from "contracts/pool/PoolTokenV2.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {AddressRegistryV2} from "contracts/registry/AddressRegistryV2.sol";
import {Erc20Allocation} from "contracts/tvl/Erc20Allocation.sol";
import {TvlManager} from "contracts/tvl/TvlManager.sol";
import {OracleAdapter} from "contracts/oracle/OracleAdapter.sol";
import {LpAccount} from "contracts/lpaccount/LpAccount.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy
} from "contracts/proxy/Imports.sol";

import {DeploymentConstants} from "./constants.sol";

abstract contract UpgradeableContractFactory {
    function create(
        address proxyFactory,
        address proxyAdmin,
        bytes memory initData
    ) public returns (address) {
        address logic = _deployLogic(initData);
        address proxy =
            ProxyFactory(proxyFactory).create(logic, proxyAdmin, initData);
        return address(proxy);
    }

    /**
     * `initData` is passed to allow initialization of the logic
     * contract's storage.  This is to block possible attack vectors.
     * Future added functionality may allow those controlling the
     * contract to selfdestruct it.
     */
    function _deployLogic(bytes memory initData)
        internal
        virtual
        returns (address);
}

contract MetaPoolTokenFactory is UpgradeableContractFactory {
    using Address for address;

    function _deployLogic(bytes memory initData)
        internal
        virtual
        override
        returns (address)
    {
        MetaPoolToken logic = new MetaPoolToken();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

contract LpAccountFactory is UpgradeableContractFactory {
    using Address for address;

    function _deployLogic(bytes memory initData)
        internal
        virtual
        override
        returns (address)
    {
        LpAccount logic = new LpAccount();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

contract ProxyFactory {
    function create(
        address logic,
        address proxyAdmin,
        bytes memory initData
    ) public returns (address) {
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(logic, proxyAdmin, initData);
        return address(proxy);
    }
}

contract PoolTokenV1Factory is UpgradeableContractFactory {
    using Address for address;

    address private _logic;

    function _deployLogic(bytes memory initData)
        internal
        virtual
        override
        returns (address)
    {
        if (_logic != address(0)) {
            return _logic;
        }
        PoolToken logic = new PoolToken();
        _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

contract PoolTokenV2Factory {
    function create() external returns (address) {
        PoolTokenV2 logicV2 = new PoolTokenV2();
        return address(logicV2);
    }
}

contract AddressRegistryV2Factory {
    function create() external returns (address) {
        AddressRegistryV2 logicV2 = new AddressRegistryV2();
        return address(logicV2);
    }
}

contract OracleAdapterFactory {
    function create(
        address addressRegistry,
        address tvlSource,
        address[] memory assets,
        address[] memory sources,
        uint256 aggStalePeriod,
        uint256 defaultLockPeriod
    ) public virtual returns (address) {
        OracleAdapter oracleAdapter =
            new OracleAdapter(
                addressRegistry,
                tvlSource,
                assets,
                sources,
                aggStalePeriod,
                defaultLockPeriod
            );
        return address(oracleAdapter);
    }
}

contract Erc20AllocationFactory {
    function create(address addressRegistry) external returns (address) {
        Erc20Allocation erc20Allocation = new Erc20Allocation(addressRegistry);
        return address(erc20Allocation);
    }
}

contract TvlManagerFactory {
    function create(address addressRegistry) external returns (address) {
        TvlManager tvlManager = new TvlManager(addressRegistry);
        return address(tvlManager);
    }
}

contract ProxyAdminFactory {
    function create() external returns (address) {
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        proxyAdmin.transferOwnership(msg.sender);
        return address(proxyAdmin);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IDetailedERC20} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {
    Initializable,
    ERC20UpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    AccessControlUpgradeSafe,
    Address as AddressUpgradeSafe,
    SafeMath as SafeMathUpgradeSafe,
    SignedSafeMath as SignedSafeMathUpgradeSafe
} from "contracts/proxy/Imports.sol";
import {ILpAccount} from "contracts/lpaccount/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {ILockingOracle} from "contracts/oracle/Imports.sol";
import {IReservePool} from "contracts/pool/Imports.sol";
import {
    IErc20Allocation,
    IAssetAllocationRegistry,
    Erc20AllocationConstants
} from "contracts/tvl/Imports.sol";

import {ILpAccountFunder} from "./ILpAccountFunder.sol";

/**
 * @notice This contract has hybrid functionality:
 *
 * - It acts as a token that tracks the capital that has been pulled
 * ("deployed") from APY Finance pools (PoolToken contracts)
 *
 * - It is permissioned to transfer funds between the pools and the
 * LP Account contract.
 *
 * @dev When MetaPoolToken pulls capital from the pools to the LP Account, it
 * will mint mAPT for each pool. Conversely, when MetaPoolToken withdraws funds
 * from the LP Account to the pools, it will burn mAPT for each pool.
 *
 * The ratio of each pool's mAPT balance to the total mAPT supply determines
 * the amount of the TVL dedicated to the pool.
 *
 *
 * DEPLOY CAPITAL TO YIELD FARMING STRATEGIES
 * Mints appropriate mAPT amount to track share of deployed TVL owned by a pool.
 *
 * +-------------+  MetaPoolToken.fundLpAccount  +-----------+
 * |             |------------------------------>|           |
 * | PoolTokenV2 |     MetaPoolToken.mint        | LpAccount |
 * |             |<------------------------------|           |
 * +-------------+                               +-----------+
 *
 *
 * WITHDRAW CAPITAL FROM YIELD FARMING STRATEGIES
 * Uses mAPT to calculate the amount of capital returned to the PoolToken.
 *
 * +-------------+  MetaPoolToken.withdrawFromLpAccount  +-----------+
 * |             |<--------------------------------------|           |
 * | PoolTokenV2 |          MetaPoolToken.burn           | LpAccount |
 * |             |-------------------------------------->|           |
 * +-------------+                                       +-----------+
 */
contract MetaPoolToken is
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe,
    ILpAccountFunder,
    Erc20AllocationConstants
{
    using AddressUpgradeSafe for address;
    using SafeMathUpgradeSafe for uint256;
    using SignedSafeMathUpgradeSafe for int256;
    using SafeERC20 for IDetailedERC20;

    uint256 public constant DEFAULT_MAPT_TO_UNDERLYER_FACTOR = 1000;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @notice used to protect mint and burn function */
    IAddressRegistryV2 public addressRegistry;

    /* ------------------------------- */

    event Mint(address acccount, uint256 amount);
    event Burn(address acccount, uint256 amount);
    event AddressRegistryChanged(address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address addressRegistry_) external initializer {
        // initialize ancestor storage
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY MetaPool Token", "mAPT");

        // initialize impl-specific storage
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(LP_ROLE, addressRegistry.lpSafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead, we
     * protect the upgrade init with the `onlyProxyAdmin` modifier, which
     * checks `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual nonReentrant onlyProxyAdmin {}

    /**
     * @notice Sets the address registry
     * @param addressRegistry_ the address of the registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    function fundLpAccount(bytes32[] calldata poolIds)
        external
        override
        nonReentrant
        onlyLpRole
    {
        (IReservePool[] memory pools, int256[] memory amounts) =
            getRebalanceAmounts(poolIds);

        uint256[] memory fundAmounts = _getFundAmounts(amounts);

        _fundLpAccount(pools, fundAmounts);

        emit FundLpAccount(poolIds, fundAmounts);
    }

    function withdrawFromLpAccount(bytes32[] calldata poolIds)
        external
        override
        nonReentrant
        onlyLpRole
    {
        (IReservePool[] memory pools, int256[] memory amounts) =
            getRebalanceAmounts(poolIds);

        uint256[] memory withdrawAmounts = _getWithdrawAmounts(amounts);

        _withdrawFromLpAccount(pools, withdrawAmounts);
        emit WithdrawFromLpAccount(poolIds, withdrawAmounts);
    }

    /**
     * @notice Get the USD-denominated value (in wei) of the pool's share
     * of the deployed capital, as tracked by the mAPT token.
     * @return The value deployed to the LP Account
     */
    function getDeployedValue(address pool) external view returns (uint256) {
        uint256 balance = balanceOf(pool);
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0 || balance == 0) return 0;

        return _getTvl().mul(balance).div(totalSupply);
    }

    /**
     * @notice Returns the (signed) top-up amount for each pool ID given.
     * A positive (negative) sign means the reserve level is in deficit
     * (excess) of required percentage.
     * @param poolIds array of pool identifiers
     * @return The array of pools
     * @return An array of rebalance amounts
     */
    function getRebalanceAmounts(bytes32[] memory poolIds)
        public
        view
        returns (IReservePool[] memory, int256[] memory)
    {
        IReservePool[] memory pools = new IReservePool[](poolIds.length);
        int256[] memory rebalanceAmounts = new int256[](poolIds.length);

        for (uint256 i = 0; i < poolIds.length; i++) {
            IReservePool pool =
                IReservePool(addressRegistry.getAddress(poolIds[i]));
            int256 rebalanceAmount = pool.getReserveTopUpValue();

            pools[i] = pool;
            rebalanceAmounts[i] = rebalanceAmount;
        }

        return (pools, rebalanceAmounts);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    function _fundLpAccount(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        address lpAccountAddress = addressRegistry.lpAccountAddress();
        require(lpAccountAddress != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        _multipleMintAndTransfer(pools, amounts);
        _registerPoolUnderlyers(pools);
    }

    function _multipleMintAndTransfer(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        uint256[] memory deltas = _calculateDeltas(pools, amounts);

        // MUST do the actual minting after calculating *all* mint amounts,
        // otherwise due to Chainlink not updating during a transaction,
        // the totalSupply will change while TVL doesn't.
        //
        // Using the pre-mint TVL and totalSupply gives the same answer
        // as using post-mint values.
        for (uint256 i = 0; i < pools.length; i++) {
            IReservePool pool = pools[i];
            uint256 mintAmount = deltas[i];
            uint256 transferAmount = amounts[i];
            _mintAndTransfer(pool, mintAmount, transferAmount);
        }

        ILockingOracle oracleAdapter = _getOracleAdapter();
        oracleAdapter.lock();
    }

    function _mintAndTransfer(
        IReservePool pool,
        uint256 mintAmount,
        uint256 transferAmount
    ) internal {
        if (mintAmount == 0) {
            return;
        }
        _mint(address(pool), mintAmount);
        pool.transferToLpAccount(transferAmount);
        emit Mint(address(pool), mintAmount);
    }

    function _withdrawFromLpAccount(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        address lpAccountAddress = addressRegistry.lpAccountAddress();
        require(lpAccountAddress != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        _multipleBurnAndTransfer(pools, amounts);
        _registerPoolUnderlyers(pools);
    }

    function _multipleBurnAndTransfer(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        address lpAccount = addressRegistry.lpAccountAddress();
        require(lpAccount != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        uint256[] memory deltas = _calculateDeltas(pools, amounts);

        // MUST do the actual burning after calculating *all* burn amounts,
        // otherwise due to Chainlink not updating during a transaction,
        // the totalSupply will change while TVL doesn't.
        //
        // Using the pre-burn TVL and totalSupply gives the same answer
        // as using post-burn values.
        for (uint256 i = 0; i < pools.length; i++) {
            IReservePool pool = pools[i];
            uint256 burnAmount = deltas[i];
            uint256 transferAmount = amounts[i];
            _burnAndTransfer(pool, lpAccount, burnAmount, transferAmount);
        }

        ILockingOracle oracleAdapter = _getOracleAdapter();
        oracleAdapter.lock();
    }

    function _burnAndTransfer(
        IReservePool pool,
        address lpAccount,
        uint256 burnAmount,
        uint256 transferAmount
    ) internal {
        if (burnAmount == 0) {
            return;
        }
        _burn(address(pool), burnAmount);
        ILpAccount(lpAccount).transferToPool(address(pool), transferAmount);
        emit Burn(address(pool), burnAmount);
    }

    /**
     * @notice Register an asset allocation for the account with each pool underlyer
     * @param pools list of pool amounts whose pool underlyers will be registered
     */
    function _registerPoolUnderlyers(IReservePool[] memory pools) internal {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));
        IErc20Allocation erc20Allocation =
            IErc20Allocation(
                address(
                    tvlManager.getAssetAllocation(Erc20AllocationConstants.NAME)
                )
            );

        for (uint256 i = 0; i < pools.length; i++) {
            IDetailedERC20 underlyer =
                IDetailedERC20(address(pools[i].underlyer()));

            if (!erc20Allocation.isErc20TokenRegistered(underlyer)) {
                erc20Allocation.registerErc20Token(underlyer);
            }
        }
    }

    /**
     * @notice Get the USD value of all assets in the system, not just those
     * being managed by the AccountManager but also the pool underlyers.
     *
     * Note this is NOT the same as the total value represented by the
     * total mAPT supply, i.e. the "deployed capital".
     *
     * @dev Chainlink nodes read from the TVLManager, pull the
     * prices from market feeds, and submits the calculated total value
     * to an aggregator contract.
     *
     * USD prices have 8 decimals.
     *
     * @return "Total Value Locked", the USD value of all APY Finance assets.
     */
    function _getTvl() internal view returns (uint256) {
        ILockingOracle oracleAdapter = _getOracleAdapter();
        return oracleAdapter.getTvl();
    }

    function _getOracleAdapter() internal view returns (ILockingOracle) {
        address oracleAdapterAddress = addressRegistry.oracleAdapterAddress();
        return ILockingOracle(oracleAdapterAddress);
    }

    function _calculateDeltas(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal view returns (uint256[] memory) {
        require(pools.length == amounts.length, "LENGTHS_MUST_MATCH");
        uint256[] memory deltas = new uint256[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            IReservePool pool = pools[i];
            uint256 amount = amounts[i];

            IDetailedERC20 underlyer = pool.underlyer();
            uint256 tokenPrice = pool.getUnderlyerPrice();
            uint8 decimals = underlyer.decimals();

            deltas[i] = _calculateDelta(amount, tokenPrice, decimals);
        }

        return deltas;
    }

    /**
     * @notice Calculate mAPT amount for given pool's underlyer amount.
     * @param amount Pool underlyer amount to be converted
     * @param tokenPrice Pool underlyer's USD price (in wei) per underlyer token
     * @param decimals Pool underlyer's number of decimals
     * @dev Price parameter is in units of wei per token ("big" unit), since
     * attempting to express wei per token bit ("small" unit) will be
     * fractional, requiring fixed-point representation.  This means we need
     * to also pass in the underlyer's number of decimals to do the appropriate
     * multiplication in the calculation.
     * @dev amount of APT minted should be in same ratio to APT supply
     * as deposit value is to pool's total value, i.e.:
     *
     * mint amount / total supply
     * = deposit value / pool total value
     *
     * For denominators, pre or post-deposit amounts can be used.
     * The important thing is they are consistent, i.e. both pre-deposit
     * or both post-deposit.
     */
    function _calculateDelta(
        uint256 amount,
        uint256 tokenPrice,
        uint8 decimals
    ) internal view returns (uint256) {
        uint256 value = amount.mul(tokenPrice).div(10**uint256(decimals));
        uint256 totalValue = _getTvl();
        uint256 totalSupply = totalSupply();

        if (totalValue == 0 || totalSupply == 0) {
            return value.mul(DEFAULT_MAPT_TO_UNDERLYER_FACTOR);
        }

        return value.mul(totalSupply).div(totalValue);
    }

    function _getFundAmounts(int256[] memory amounts)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory fundAmounts = new uint256[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            int256 amount = amounts[i];

            fundAmounts[i] = amount < 0 ? uint256(-amount) : 0;
        }

        return fundAmounts;
    }

    function _getWithdrawAmounts(int256[] memory amounts)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory withdrawAmounts = new uint256[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            int256 amount = amounts[i];

            withdrawAmounts[i] = amount > 0 ? uint256(amount) : 0;
        }

        return withdrawAmounts;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    OwnableUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import {
    ReentrancyGuardUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import {
    PausableUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    ERC20UpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import {
    SafeMath
} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {ILiquidityPool} from "./ILiquidityPool.sol";
import {IDetailedERC20} from "contracts/common/Imports.sol";

/**
 * @notice Old version of the `PoolToken`
 * @notice Should not be used in deployment
 */
contract PoolToken is
    ILiquidityPool,
    Initializable,
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe
{
    using SafeMath for uint256;
    using SafeERC20 for IDetailedERC20;

    uint256 public constant DEFAULT_APT_TO_UNDERLYER_FACTOR = 1000;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;
    bool public addLiquidityLock;
    bool public redeemLock;
    IDetailedERC20 public underlyer;
    AggregatorV3Interface public priceAgg;

    /* ------------------------------- */

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    function initialize(
        address adminAddress,
        IDetailedERC20 _underlyer,
        AggregatorV3Interface _priceAgg
    ) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");
        require(address(_underlyer) != address(0), "INVALID_TOKEN");
        require(address(_priceAgg) != address(0), "INVALID_AGG");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY Pool Token", "APT");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
        addLiquidityLock = false;
        redeemLock = false;
        underlyer = _underlyer;
        setPriceAggregator(_priceAgg);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function lock() external onlyOwner {
        _pause();
    }

    function unlock() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Mint corresponding amount of APT tokens for sent token amount.
     * @dev If no APT tokens have been minted yet, fallback to a fixed ratio.
     */
    function addLiquidity(uint256 tokenAmt)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!addLiquidityLock, "LOCKED");
        require(tokenAmt > 0, "AMOUNT_INSUFFICIENT");
        require(
            underlyer.allowance(msg.sender, address(this)) >= tokenAmt,
            "ALLOWANCE_INSUFFICIENT"
        );

        // calculateMintAmount() is not used because deposit value
        // is needed for the event
        uint256 depositEthValue = getEthValueFromTokenAmount(tokenAmt);
        uint256 poolTotalEthValue = getPoolTotalEthValue();
        uint256 mintAmount =
            _calculateMintAmount(depositEthValue, poolTotalEthValue);

        _mint(msg.sender, mintAmount);
        underlyer.safeTransferFrom(msg.sender, address(this), tokenAmt);

        emit DepositedAPT(
            msg.sender,
            underlyer,
            tokenAmt,
            mintAmount,
            depositEthValue,
            getPoolTotalEthValue()
        );
    }

    /** @notice Disable deposits. */
    function lockAddLiquidity() external onlyOwner {
        addLiquidityLock = true;
        emit AddLiquidityLocked();
    }

    /** @notice Enable deposits. */
    function unlockAddLiquidity() external onlyOwner {
        addLiquidityLock = false;
        emit AddLiquidityUnlocked();
    }

    /**
     * @notice Redeems APT amount for its underlying token amount.
     * @param aptAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 aptAmount)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!redeemLock, "LOCKED");
        require(aptAmount > 0, "AMOUNT_INSUFFICIENT");
        require(aptAmount <= balanceOf(msg.sender), "BALANCE_INSUFFICIENT");

        uint256 redeemTokenAmt = getUnderlyerAmount(aptAmount);

        _burn(msg.sender, aptAmount);
        underlyer.safeTransfer(msg.sender, redeemTokenAmt);

        emit RedeemedAPT(
            msg.sender,
            underlyer,
            redeemTokenAmt,
            aptAmount,
            getEthValueFromTokenAmount(redeemTokenAmt),
            getPoolTotalEthValue()
        );
    }

    /** @notice Disable APT redeeming. */
    function lockRedeem() external onlyOwner {
        redeemLock = true;
        emit RedeemLocked();
    }

    /** @notice Enable APT redeeming. */
    function unlockRedeem() external onlyOwner {
        redeemLock = false;
        emit RedeemUnlocked();
    }

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    function setPriceAggregator(AggregatorV3Interface _priceAgg)
        public
        onlyOwner
    {
        require(address(_priceAgg) != address(0), "INVALID_AGG");
        priceAgg = _priceAgg;
        emit PriceAggregatorChanged(address(_priceAgg));
    }

    /**
     * @notice Calculate APT amount to be minted from deposit amount.
     * @param tokenAmt The deposit amount of stablecoin
     * @return The mint amount
     */
    function calculateMintAmount(uint256 tokenAmt)
        public
        view
        returns (uint256)
    {
        uint256 depositEthValue = getEthValueFromTokenAmount(tokenAmt);
        uint256 poolTotalEthValue = getPoolTotalEthValue();
        return _calculateMintAmount(depositEthValue, poolTotalEthValue);
    }

    /**
     * @notice Get the underlying amount represented by APT amount.
     * @param aptAmount The amount of APT tokens
     * @return uint256 The underlying value of the APT tokens
     */
    function getUnderlyerAmount(uint256 aptAmount)
        public
        view
        returns (uint256)
    {
        return getTokenAmountFromEthValue(getAPTEthValue(aptAmount));
    }

    function getPoolTotalEthValue() public view virtual returns (uint256) {
        return getEthValueFromTokenAmount(underlyer.balanceOf(address(this)));
    }

    function getAPTEthValue(uint256 amount) public view returns (uint256) {
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        return (amount.mul(getPoolTotalEthValue())).div(totalSupply());
    }

    function getEthValueFromTokenAmount(uint256 amount)
        public
        view
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }
        uint256 decimals = underlyer.decimals();
        return ((getTokenEthPrice()).mul(amount)).div(10**decimals);
    }

    function getTokenAmountFromEthValue(uint256 ethValue)
        public
        view
        returns (uint256)
    {
        uint256 tokenEthPrice = getTokenEthPrice();
        uint256 decimals = underlyer.decimals();
        return ((10**decimals).mul(ethValue)).div(tokenEthPrice);
    }

    function getTokenEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceAgg.latestRoundData();
        require(price > 0, "UNABLE_TO_RETRIEVE_ETH_PRICE");
        return uint256(price);
    }

    /**
     * @dev amount of APT minted should be in same ratio to APT supply
     * as token amount sent is to contract's token balance, i.e.:
     *
     * mint amount / total supply (before deposit)
     * = token amount sent / contract token balance (before deposit)
     */
    function _calculateMintAmount(
        uint256 depositEthAmount,
        uint256 totalEthAmount
    ) internal view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (totalEthAmount == 0 || totalSupply == 0) {
            return depositEthAmount.mul(DEFAULT_APT_TO_UNDERLYER_FACTOR);
        }

        return (depositEthAmount.mul(totalSupply)).div(totalEthAmount);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {TransparentUpgradeableProxy} from "contracts/proxy/Imports.sol";

contract PoolTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        address _underlyer,
        address _priceAgg
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                _proxyAdmin,
                _underlyer,
                _priceAgg
            )
        )
    {} // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IDetailedERC20, IEmergencyExit} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {
    Initializable,
    ERC20UpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    AccessControlUpgradeSafe,
    Address as AddressUpgradeSafe,
    SafeMath as SafeMathUpgradeSafe,
    SignedSafeMath as SignedSafeMathUpgradeSafe
} from "contracts/proxy/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {
    AggregatorV3Interface,
    IOracleAdapter
} from "contracts/oracle/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";

import {
    IReservePool,
    IWithdrawFeePool,
    ILockingPool,
    IPoolToken,
    ILiquidityPoolV2
} from "./Imports.sol";

/**
 * @notice Collect user deposits so they can be lent to the LP Account
 * @notice Depositors share pool liquidity
 * @notice Reserves are maintained to process withdrawals
 * @notice Reserve tokens cannot be lent to the LP Account
 * @notice If a user withdraws too early after their deposit, there's a fee
 * @notice Tokens borrowed from the pool are tracked with the `MetaPoolToken`
 */
contract PoolTokenV2 is
    ILiquidityPoolV2,
    IPoolToken,
    IReservePool,
    IWithdrawFeePool,
    ILockingPool,
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe,
    IEmergencyExit
{
    using AddressUpgradeSafe for address;
    using SafeMathUpgradeSafe for uint256;
    using SignedSafeMathUpgradeSafe for int256;
    using SafeERC20 for IDetailedERC20;

    uint256 public constant DEFAULT_APT_TO_UNDERLYER_FACTOR = 1000;
    uint256 internal constant _MAX_INT256 = 2**255 - 1;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */

    // V1
    /** @dev used to protect init functions for upgrades */
    address private _proxyAdmin; // <-- deprecated in v2; visibility changed to avoid name clash
    /** @notice true if depositing is locked */
    bool public addLiquidityLock;
    /** @notice true if withdrawing is locked */
    bool public redeemLock;
    /** @notice underlying stablecoin */
    IDetailedERC20 public override underlyer;
    /** @notice USD price feed for the stablecoin */
    // AggregatorV3Interface public priceAgg; <-- removed in V2

    // V2
    /**
     * @notice registry to fetch core platform addresses from
     * @dev this slot replaces the last V1 slot for the price agg
     */
    IAddressRegistryV2 public addressRegistry;
    /** @notice seconds since last deposit during which withdrawal fee is charged */
    uint256 public override feePeriod;
    /** @notice percentage charged for withdrawal fee */
    uint256 public override feePercentage;
    /** @notice time of last deposit */
    mapping(address => uint256) public lastDepositTime;
    /** @notice percentage of pool total value available for immediate withdrawal */
    uint256 public override reservePercentage;

    /* ------------------------------- */

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     *
     * NOTE: this function is copied from the V1 contract and has already
     * been called during V1 deployment.  It is included here for clarity.
     */
    function initialize(
        address adminAddress,
        IDetailedERC20 underlyer_,
        AggregatorV3Interface priceAgg
    ) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");
        require(address(underlyer_) != address(0), "INVALID_TOKEN");
        require(address(priceAgg) != address(0), "INVALID_AGG");

        // initialize ancestor storage
        __Context_init_unchained();
        // __Ownable_init_unchained();  <-- Comment-out for compiler; replaced by AccessControl
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY Pool Token", "APT");

        // initialize impl-specific storage
        // _setAdminAddress(adminAddress);  <-- deprecated in V2.
        addLiquidityLock = false;
        redeemLock = false;
        underlyer = underlyer_;
        // setPriceAggregator(priceAgg);  <-- deprecated in V2.
    }

    /**
     * @dev Note the `initializer` modifier can only be used once in the
     * entire contract, so we can't use it here.  Instead, we protect
     * the upgrade init with the `onlyProxyAdmin` modifier, which checks
     * `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade(address addressRegistry_)
        external
        nonReentrant
        onlyProxyAdmin
    {
        _setAddressRegistry(addressRegistry_);

        // Sadly, the AccessControl init is protected by `initializer` so can't
        // be called ever again (see above natspec).  Fortunately, the init body
        // is empty, so we don't actually need to call it.
        // __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());

        feePeriod = 1 days;
        feePercentage = 5;
        reservePercentage = 5;
    }

    function emergencyLock() external override onlyEmergencyRole {
        _pause();
    }

    function emergencyUnlock() external override onlyEmergencyRole {
        _unpause();
    }

    /**
     * @dev If no APT tokens have been minted yet, fallback to a fixed ratio.
     */
    function addLiquidity(uint256 depositAmount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(!addLiquidityLock, "LOCKED");
        require(depositAmount > 0, "AMOUNT_INSUFFICIENT");
        require(
            underlyer.allowance(msg.sender, address(this)) >= depositAmount,
            "ALLOWANCE_INSUFFICIENT"
        );
        // solhint-disable-next-line not-rely-on-time
        lastDepositTime[msg.sender] = block.timestamp;

        // calculateMintAmount() is not used because deposit value
        // is needed for the event
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        uint256 mintAmount = _calculateMintAmount(depositValue, poolTotalValue);

        _mint(msg.sender, mintAmount);
        underlyer.safeTransferFrom(msg.sender, address(this), depositAmount);

        emit DepositedAPT(
            msg.sender,
            underlyer,
            depositAmount,
            mintAmount,
            depositValue,
            getPoolTotalValue()
        );
    }

    function emergencyLockAddLiquidity()
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        addLiquidityLock = true;
        emit AddLiquidityLocked();
    }

    function emergencyUnlockAddLiquidity()
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        addLiquidityLock = false;
        emit AddLiquidityUnlocked();
    }

    /**
     * @dev May revert if there is not enough in the pool.
     */
    function redeem(uint256 aptAmount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(!redeemLock, "LOCKED");
        require(aptAmount > 0, "AMOUNT_INSUFFICIENT");
        require(aptAmount <= balanceOf(msg.sender), "BALANCE_INSUFFICIENT");

        uint256 redeemUnderlyerAmt = getUnderlyerAmountWithFee(aptAmount);
        require(
            redeemUnderlyerAmt <= underlyer.balanceOf(address(this)),
            "RESERVE_INSUFFICIENT"
        );

        _burn(msg.sender, aptAmount);
        underlyer.safeTransfer(msg.sender, redeemUnderlyerAmt);

        emit RedeemedAPT(
            msg.sender,
            underlyer,
            redeemUnderlyerAmt,
            aptAmount,
            getValueFromUnderlyerAmount(redeemUnderlyerAmt),
            getPoolTotalValue()
        );
    }

    function emergencyLockRedeem()
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        redeemLock = true;
        emit RedeemLocked();
    }

    function emergencyUnlockRedeem()
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        redeemLock = false;
        emit RedeemUnlocked();
    }

    /**
     * @dev permissioned with CONTRACT_ROLE
     */
    function transferToLpAccount(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyContractRole
    {
        underlyer.safeTransfer(addressRegistry.lpAccountAddress(), amount);
    }

    /**
     * @notice Set the new address registry
     * @param addressRegistry_ The new address registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    function setFeePeriod(uint256 feePeriod_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        feePeriod = feePeriod_;
        emit FeePeriodChanged(feePeriod_);
    }

    function setFeePercentage(uint256 feePercentage_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        feePercentage = feePercentage_;
        emit FeePercentageChanged(feePercentage_);
    }

    function setReservePercentage(uint256 reservePercentage_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        reservePercentage = reservePercentage_;
        emit ReservePercentageChanged(reservePercentage_);
    }

    function emergencyExit(address token) external override onlyEmergencyRole {
        address emergencySafe = addressRegistry.emergencySafeAddress();
        IDetailedERC20 token_ = IDetailedERC20(token);
        uint256 balance = token_.balanceOf(address(this));
        token_.safeTransfer(emergencySafe, balance);

        emit EmergencyExit(emergencySafe, token_, balance);
    }

    function calculateMintAmount(uint256 depositAmount)
        external
        view
        override
        returns (uint256)
    {
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        return _calculateMintAmount(depositValue, poolTotalValue);
    }

    /**
     * @dev To check if fee will be applied, use `isEarlyRedeem`.
     */
    function getUnderlyerAmountWithFee(uint256 aptAmount)
        public
        view
        override
        returns (uint256)
    {
        uint256 redeemUnderlyerAmt = getUnderlyerAmount(aptAmount);
        if (isEarlyRedeem()) {
            uint256 fee = redeemUnderlyerAmt.mul(feePercentage).div(100);
            redeemUnderlyerAmt = redeemUnderlyerAmt.sub(fee);
        }
        return redeemUnderlyerAmt;
    }

    function getUnderlyerAmount(uint256 aptAmount)
        public
        view
        override
        returns (uint256)
    {
        if (aptAmount == 0) {
            return 0;
        }
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        // the below is mathematically equivalent to:
        //
        // getUnderlyerAmountFromValue(getAPTValue(aptAmount));
        //
        // but composing the two functions leads to early loss
        // of precision from division, so it's better to do it
        // this way:
        uint256 underlyerPrice = getUnderlyerPrice();
        uint256 decimals = underlyer.decimals();
        return
            aptAmount
                .mul(getPoolTotalValue())
                .mul(10**decimals)
                .div(totalSupply())
                .div(underlyerPrice);
    }

    /**
     * @dev `lastDepositTime` is stored each time user makes a deposit, so
     * the waiting period is restarted on each deposit.
     */
    function isEarlyRedeem() public view override returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp.sub(lastDepositTime[msg.sender]) < feePeriod;
    }

    /**
     * @dev Total value also includes that have been borrowed from the pool
     * @dev Typically it is the LP Account that borrows from the pool
     */
    function getPoolTotalValue() public view override returns (uint256) {
        uint256 underlyerValue = _getPoolUnderlyerValue();
        uint256 mAptValue = _getDeployedValue();
        return underlyerValue.add(mAptValue);
    }

    function getAPTValue(uint256 aptAmount)
        external
        view
        override
        returns (uint256)
    {
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        return aptAmount.mul(getPoolTotalValue()).div(totalSupply());
    }

    function getValueFromUnderlyerAmount(uint256 underlyerAmount)
        public
        view
        override
        returns (uint256)
    {
        if (underlyerAmount == 0) {
            return 0;
        }
        uint256 decimals = underlyer.decimals();
        return getUnderlyerPrice().mul(underlyerAmount).div(10**decimals);
    }

    function getUnderlyerPrice() public view override returns (uint256) {
        IOracleAdapter oracleAdapter =
            IOracleAdapter(addressRegistry.oracleAdapterAddress());
        return oracleAdapter.getAssetPrice(address(underlyer));
    }

    function getReserveTopUpValue() external view override returns (int256) {
        int256 topUpValue = _getReserveTopUpValue();
        if (topUpValue == 0) {
            return 0;
        }

        // Should never revert because the OracleAdapter converts from int256
        uint256 price = getUnderlyerPrice();
        require(price <= uint256(type(int256).max), "INVALID_PRICE");

        int256 topUpAmount =
            topUpValue.mul(int256(10**uint256(underlyer.decimals()))).div(
                int256(getUnderlyerPrice())
            );

        return topUpAmount;
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    /**
     * @dev This hook is in-place to block inter-user APT transfers, as it
     * is one avenue that can be used by arbitrageurs to drain the
     * reserves.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        // allow minting and burning
        if (from == address(0) || to == address(0)) return;
        // block transfer between users
        revert("INVALID_TRANSFER");
    }

    /**
     * @dev This "top-up" value should satisfy:
     *
     * top-up USD value + pool underlyer USD value
     * = (reserve %) * pool deployed value (after unwinding)
     *
     * @dev Taking the percentage of the pool's current deployed value
     * is not sufficient, because the requirement is to have the
     * resulting values after unwinding capital satisfy the
     * above equation.
     *
     * More precisely:
     *
     * R_pre = pool underlyer USD value before pushing unwound
     *         capital to the pool
     * R_post = pool underlyer USD value after pushing
     * DV_pre = pool's deployed USD value before unwinding
     * DV_post = pool's deployed USD value after unwinding
     * rPerc = the reserve percentage as a whole number
     *                     out of 100
     *
     * We want:
     *
     *     R_post = (rPerc / 100) * DV_post          (equation 1)
     *
     *     where R_post = R_pre + top-up value
     *           DV_post = DV_pre - top-up value
     *
     * Making the latter substitutions in equation 1, gives:
     *
     * top-up value = (rPerc * DV_pre - 100 * R_pre) / (100 + rPerc)
     */
    function _getReserveTopUpValue() internal view returns (int256) {
        uint256 unnormalizedTargetValue =
            _getDeployedValue().mul(reservePercentage);
        uint256 unnormalizedUnderlyerValue = _getPoolUnderlyerValue().mul(100);

        require(unnormalizedTargetValue <= _MAX_INT256, "SIGNED_INT_OVERFLOW");
        require(
            unnormalizedUnderlyerValue <= _MAX_INT256,
            "SIGNED_INT_OVERFLOW"
        );
        int256 topUpValue =
            int256(unnormalizedTargetValue)
                .sub(int256(unnormalizedUnderlyerValue))
                .div(int256(reservePercentage).add(100));
        return topUpValue;
    }

    /**
     * @dev amount of APT minted should be in same ratio to APT supply
     * as deposit value is to pool's total value, i.e.:
     *
     * mint amount / total supply
     * = deposit value / pool total value
     *
     * For denominators, pre or post-deposit amounts can be used.
     * The important thing is they are consistent, i.e. both pre-deposit
     * or both post-deposit.
     */
    function _calculateMintAmount(uint256 depositValue, uint256 poolTotalValue)
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = totalSupply();

        if (poolTotalValue == 0 || totalSupply == 0) {
            return depositValue.mul(DEFAULT_APT_TO_UNDERLYER_FACTOR);
        }

        return (depositValue.mul(totalSupply)).div(poolTotalValue);
    }

    /**
     * @notice Get the USD value of tokens in the pool
     * @return The USD value
     */
    function _getPoolUnderlyerValue() internal view returns (uint256) {
        return getValueFromUnderlyerAmount(underlyer.balanceOf(address(this)));
    }

    /**
     * @notice Get the USD value of tokens owed to the pool
     * @dev Tokens from the pool are typically borrowed by the LP Account
     * @dev Tokens borrowed from the pool are tracked with mAPT
     * @return The USD value
     */
    function _getDeployedValue() internal view returns (uint256) {
        MetaPoolToken mApt = MetaPoolToken(addressRegistry.mAptAddress());
        return mApt.getDeployedValue(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Initializable, OwnableUpgradeSafe} from "contracts/proxy/Imports.sol";
import {IAddressRegistryV2} from "./IAddressRegistryV2.sol";

contract AddressRegistryV2 is
    Initializable,
    OwnableUpgradeSafe,
    IAddressRegistryV2
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @dev the same address as the proxy admin; used
     *  to protect init functions for upgrades */
    address private _proxyAdmin; // <-- deprecated in V2.
    bytes32[] internal _idList;
    mapping(bytes32 => address) internal _idToAddress;

    /* ------------------------------- */

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     *
     * NOTE: this function is copied from the V1 contract and has already
     * been called during V1 deployment.  It is included here for clarity.
     */
    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        // _setAdminAddress(adminAddress);  <-- deprecated in V2.
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead, we
     * protect the upgrade init with the `onlyProxyAdmin` modifier, which
     * checks `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyProxyAdmin {}

    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external override onlyOwner {
        require(ids.length == addresses.length, "Inputs have differing length");
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];
            address address_ = addresses[i];
            registerAddress(id, address_);
        }
    }

    function deleteAddress(bytes32 id) external override onlyOwner {
        for (uint256 i = 0; i < _idList.length; i++) {
            if (_idList[i] == id) {
                // copy last element to slot i and shorten array
                _idList[i] = _idList[_idList.length - 1];
                _idList.pop();
                address address_ = _idToAddress[id];
                delete _idToAddress[id];
                emit AddressDeleted(id, address_);
                break;
            }
        }
    }

    function getIds() external view override returns (bytes32[] memory) {
        return _idList;
    }

    function chainlinkRegistryAddress()
        external
        view
        override
        returns (address)
    {
        return tvlManagerAddress();
    }

    function daiPoolAddress() external view override returns (address) {
        return getAddress("daiPool");
    }

    function usdcPoolAddress() external view override returns (address) {
        return getAddress("usdcPool");
    }

    function usdtPoolAddress() external view override returns (address) {
        return getAddress("usdtPool");
    }

    function mAptAddress() external view override returns (address) {
        return getAddress("mApt");
    }

    function lpAccountAddress() external view override returns (address) {
        return getAddress("lpAccount");
    }

    function lpSafeAddress() external view override returns (address) {
        return getAddress("lpSafe");
    }

    function adminSafeAddress() external view override returns (address) {
        return getAddress("adminSafe");
    }

    function emergencySafeAddress() external view override returns (address) {
        return getAddress("emergencySafe");
    }

    function oracleAdapterAddress() external view override returns (address) {
        return getAddress("oracleAdapter");
    }

    function registerAddress(bytes32 id, address address_)
        public
        override
        onlyOwner
    {
        require(address_ != address(0), "Invalid address");
        if (_idToAddress[id] == address(0)) {
            // id wasn't registered before, so add it to the list
            _idList.push(id);
        }
        _idToAddress[id] = address_;
        emit AddressRegistered(id, address_);
    }

    function tvlManagerAddress() public view override returns (address) {
        return getAddress("tvlManager");
    }

    function getAddress(bytes32 id) public view override returns (address) {
        address address_ = _idToAddress[id];
        require(address_ != address(0), "Missing address");
        return address_;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address, SafeMath} from "contracts/libraries/Imports.sol";

import {
    IERC20,
    AccessControl,
    ReentrancyGuard
} from "contracts/common/Imports.sol";

import {IAddressRegistryV2} from "contracts/registry/Imports.sol";

import {
    AggregatorV3Interface,
    IOracleAdapter,
    IOverrideOracle,
    ILockingOracle
} from "./Imports.sol";

/**
 * @title Oracle Adapter
 * @author APY.Finance
 * @notice Acts as a gateway to oracle values and implements oracle safeguards.
 *
 * Oracle Safeguard Flows:
 *
 *      - Unlocked → No Manual Submitted Value → Use Chainlink Value (default)
 *      - Unlocked → No Manual Submitted Value → Chainlink Value == 0 → mAPT totalSupply == 0 → Use 0
 *      - Unlocked → No Manual Submitted Value → Chainlink Value == 0 → mAPT totalSupply > 0 → Reverts
 *      - Unlocked → No Manual Submitted Value → No Chainlink Source → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value Call Reverts → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value > 24 hours → Reverts
 *      - Unlocked → Use Manual Submitted Value (emergency)
 *      - Locked → Reverts (nominal)
 *
 * @dev It is important to note that zero values are allowed for manual
 * submission but may result in a revert when pulling from Chainlink.
 *
 * This is because there are uncommon situations where the zero TVL is valid,
 * such as when all funds are unwound and moved back to the liquidity
 * pools, but total mAPT supply would be zero in those cases.  Outside those
 * situations, a zero TVL with nonzero supply likely indicates a Chainlink
 * failure, hence we revert out of an abundance of caution.
 *
 * In the rare situation where Chainlink *should* be returning zero TVL
 * with nonzero mAPT supply, we can set the zero TVL manually via the
 * Emergency Safe.  Such a situation is not expected to persist long.
 */
contract OracleAdapter is
    AccessControl,
    ReentrancyGuard,
    IOracleAdapter,
    IOverrideOracle,
    ILockingOracle
{
    using SafeMath for uint256;
    using Address for address;

    IAddressRegistryV2 public addressRegistry;

    uint256 public override defaultLockPeriod;

    /// @notice Contract is locked until this block number is passed.
    uint256 public lockEnd;

    /// @notice Chainlink heartbeat duration in seconds
    uint256 public chainlinkStalePeriod;

    AggregatorV3Interface public tvlSource;
    mapping(address => AggregatorV3Interface) public assetSources;

    /// @notice Submitted values that override Chainlink values until stale.
    mapping(address => Value) public submittedAssetValues;
    Value public submittedTvlValue;

    event AddressRegistryChanged(address);

    modifier unlocked() {
        require(!isLocked(), "ORACLE_LOCKED");
        _;
    }

    /**
     * @param addressRegistry_ The address registry
     * @param tvlSource_ The source for the TVL value
     * @param assets The assets priced by sources
     * @param sources The source for each asset
     * @param chainlinkStalePeriod_ The number of seconds until a source value is stale
     * @param defaultLockPeriod_ The default number of blocks a lock should last
     */
    constructor(
        address addressRegistry_,
        address tvlSource_,
        address[] memory assets,
        address[] memory sources,
        uint256 chainlinkStalePeriod_,
        uint256 defaultLockPeriod_
    ) public {
        _setAddressRegistry(addressRegistry_);
        _setTvlSource(tvlSource_);
        _setAssetSources(assets, sources);
        _setChainlinkStalePeriod(chainlinkStalePeriod_);
        _setDefaultLockPeriod(defaultLockPeriod_);

        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.tvlManagerAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.lpAccountAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
    }

    function setDefaultLockPeriod(uint256 newPeriod)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _setDefaultLockPeriod(newPeriod);
        emit DefaultLockPeriodChanged(newPeriod);
    }

    function lock() external override nonReentrant onlyContractRole {
        _lockFor(defaultLockPeriod);
        emit DefaultLocked(msg.sender, defaultLockPeriod, lockEnd);
    }

    function emergencyUnlock()
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        _lockFor(0);
        emit Unlocked();
    }

    /**
     * @dev Can only increase the remaining locking duration.
     * @dev If no lock exists, this allows setting of any defined locking period
     */
    function lockFor(uint256 activePeriod)
        external
        override
        nonReentrant
        onlyContractRole
    {
        uint256 oldLockEnd = lockEnd;
        _lockFor(activePeriod);
        require(lockEnd > oldLockEnd, "CANNOT_SHORTEN_LOCK");
        emit Locked(msg.sender, activePeriod, lockEnd);
    }

    /**
     * @notice Sets the address registry
     * @param addressRegistry_ the address of the registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    //------------------------------------------------------------
    // MANUAL SUBMISSION SETTERS
    //------------------------------------------------------------

    function emergencySetAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external override nonReentrant onlyEmergencyRole {
        // We do allow 0 values for submitted values
        uint256 periodEnd = block.number.add(period);
        submittedAssetValues[asset] = Value(value, periodEnd);
        emit AssetValueSet(asset, value, period, periodEnd);
    }

    function emergencyUnsetAssetValue(address asset)
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        require(
            submittedAssetValues[asset].periodEnd != 0,
            "NO_ASSET_VALUE_SET"
        );
        submittedAssetValues[asset].periodEnd = block.number;
        emit AssetValueUnset(asset);
    }

    function emergencySetTvl(uint256 value, uint256 period)
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        // We do allow 0 values for submitted values
        uint256 periodEnd = block.number.add(period);
        submittedTvlValue = Value(value, periodEnd);
        emit TvlSet(value, period, periodEnd);
    }

    function emergencyUnsetTvl()
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        require(submittedTvlValue.periodEnd != 0, "NO_TVL_SET");
        submittedTvlValue.periodEnd = block.number;
        emit TvlUnset();
    }

    //------------------------------------------------------------
    // CHAINLINK SETTERS
    //------------------------------------------------------------

    function emergencySetTvlSource(address source)
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        _setTvlSource(source);
    }

    function emergencySetAssetSources(
        address[] memory assets,
        address[] memory sources
    ) external override nonReentrant onlyEmergencyRole {
        _setAssetSources(assets, sources);
    }

    function emergencySetAssetSource(address asset, address source)
        external
        override
        nonReentrant
        onlyEmergencyRole
    {
        _setAssetSource(asset, source);
    }

    function setChainlinkStalePeriod(uint256 chainlinkStalePeriod_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _setChainlinkStalePeriod(chainlinkStalePeriod_);
    }

    //------------------------------------------------------------
    // ORACLE VALUE GETTERS
    //------------------------------------------------------------

    /**
     * @dev Zero values are considered valid if there is no mAPT minted,
     * and therefore no PoolTokenV2 liquidity in the LP Safe.
     */
    function getTvl() external view override unlocked returns (uint256) {
        if (hasTvlOverride()) {
            return submittedTvlValue.value;
        }

        uint256 price = _getPriceFromSource(tvlSource);

        require(
            price > 0 ||
                IERC20(addressRegistry.mAptAddress()).totalSupply() == 0,
            "INVALID_ZERO_TVL"
        );

        return price;
    }

    function hasTvlOverride() public view override returns (bool) {
        return block.number < submittedTvlValue.periodEnd;
    }

    function getAssetPrice(address asset)
        external
        view
        override
        unlocked
        returns (uint256)
    {
        if (hasAssetOverride(asset)) {
            return submittedAssetValues[asset].value;
        }

        AggregatorV3Interface source = assetSources[asset];
        uint256 price = _getPriceFromSource(source);

        //we do not allow 0 values for chainlink
        require(price > 0, "MISSING_ASSET_VALUE");

        return price;
    }

    function hasAssetOverride(address asset)
        public
        view
        override
        returns (bool)
    {
        return block.number < submittedAssetValues[asset].periodEnd;
    }

    function isLocked() public view override returns (bool) {
        return block.number < lockEnd;
    }

    function _setDefaultLockPeriod(uint256 newPeriod) internal {
        defaultLockPeriod = newPeriod;
    }

    function _lockFor(uint256 activePeriod) internal {
        lockEnd = block.number.add(activePeriod);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(Address.isContract(addressRegistry_), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    function _setChainlinkStalePeriod(uint256 chainlinkStalePeriod_) internal {
        require(chainlinkStalePeriod_ > 0, "INVALID_STALE_PERIOD");
        chainlinkStalePeriod = chainlinkStalePeriod_;
        emit ChainlinkStalePeriodUpdated(chainlinkStalePeriod_);
    }

    function _setTvlSource(address source) internal {
        require(source.isContract(), "INVALID_SOURCE");
        tvlSource = AggregatorV3Interface(source);
        emit TvlSourceUpdated(source);
    }

    function _setAssetSources(address[] memory assets, address[] memory sources)
        internal
    {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            _setAssetSource(assets[i], sources[i]);
        }
    }

    function _setAssetSource(address asset, address source) internal {
        require(source.isContract(), "INVALID_SOURCE");
        assetSources[asset] = AggregatorV3Interface(source);
        emit AssetSourceUpdated(asset, source);
    }

    /**
     * @notice Get the price from a source (aggregator)
     * @param source The Chainlink aggregator
     * @return the price from the source
     */
    function _getPriceFromSource(AggregatorV3Interface source)
        internal
        view
        returns (uint256)
    {
        require(address(source).isContract(), "INVALID_SOURCE");
        (, int256 price, , uint256 updatedAt, ) = source.latestRoundData();

        // must be negative for cast to uint
        require(price >= 0, "NEGATIVE_VALUE");

        // solhint-disable not-rely-on-time
        require(
            block.timestamp.sub(updatedAt) <= chainlinkStalePeriod,
            "CHAINLINK_STALE_DATA"
        );
        // solhint-enable not-rely-on-time

        return uint256(price);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    IERC20,
    IEmergencyExit
} from "contracts/common/Imports.sol";
import {
    Address,
    NamedAddressSet,
    SafeERC20
} from "contracts/libraries/Imports.sol";
import {
    Initializable,
    ReentrancyGuardUpgradeSafe,
    AccessControlUpgradeSafe
} from "contracts/proxy/Imports.sol";
import {ILiquidityPoolV2} from "contracts/pool/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {
    IAssetAllocationRegistry,
    IErc20Allocation,
    Erc20AllocationConstants
} from "contracts/tvl/Imports.sol";

import {
    IZap,
    ISwap,
    ILpAccount,
    IZapRegistry,
    ISwapRegistry
} from "./Imports.sol";

import {ILockingOracle} from "contracts/oracle/Imports.sol";

contract LpAccount is
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    ILpAccount,
    IZapRegistry,
    ISwapRegistry,
    Erc20AllocationConstants,
    IEmergencyExit
{
    using Address for address;
    using SafeERC20 for IERC20;
    using NamedAddressSet for NamedAddressSet.ZapSet;
    using NamedAddressSet for NamedAddressSet.SwapSet;

    uint256 private constant _DEFAULT_LOCK_PERIOD = 135;

    IAddressRegistryV2 public addressRegistry;
    uint256 public lockPeriod;

    NamedAddressSet.ZapSet private _zaps;
    NamedAddressSet.SwapSet private _swaps;

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /** @notice Log when the lock period is changed */
    event LockPeriodChanged(uint256);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address addressRegistry_) external initializer {
        // initialize ancestor storage
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();

        // initialize impl-specific storage
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(LP_ROLE, addressRegistry.lpSafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());

        lockPeriod = _DEFAULT_LOCK_PERIOD;
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead, we
     * protect the upgrade init with the `onlyProxyAdmin` modifier, which
     * checks `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual nonReentrant onlyProxyAdmin {}

    /**
     * @notice Sets the address registry
     * @param addressRegistry_ the address of the registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    /**
     * @notice Set the lock period
     * @param lockPeriod_ The new lock period
     */
    function setLockPeriod(uint256 lockPeriod_)
        external
        nonReentrant
        onlyAdminRole
    {
        lockPeriod = lockPeriod_;
        emit LockPeriodChanged(lockPeriod_);
    }

    function deployStrategy(string calldata name, uint256[] calldata amounts)
        external
        override
        nonReentrant
        onlyLpRole
    {
        IZap zap = _zaps.get(name);
        require(address(zap) != address(0), "INVALID_NAME");

        bool isAssetAllocationRegistered =
            _checkAllocationRegistrations(zap.assetAllocations());
        require(isAssetAllocationRegistered, "MISSING_ASSET_ALLOCATIONS");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(zap.erc20Allocations());
        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(zap).functionDelegateCall(
            abi.encodeWithSelector(IZap.deployLiquidity.selector, amounts)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function unwindStrategy(
        string calldata name,
        uint256 amount,
        uint8 index
    ) external override nonReentrant onlyLpRole {
        address zap = address(_zaps.get(name));
        require(zap != address(0), "INVALID_NAME");

        zap.functionDelegateCall(
            abi.encodeWithSelector(IZap.unwindLiquidity.selector, amount, index)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function registerZap(IZap zap)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _zaps.add(zap);

        emit ZapRegistered(zap);
    }

    function removeZap(string calldata name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _zaps.remove(name);

        emit ZapRemoved(name);
    }

    function transferToPool(address pool, uint256 amount)
        external
        override
        nonReentrant
        onlyContractRole
    {
        IERC20 underlyer = ILiquidityPoolV2(pool).underlyer();
        underlyer.safeTransfer(pool, amount);
    }

    function swap(
        string calldata name,
        uint256 amount,
        uint256 minAmount
    ) external override nonReentrant onlyLpRole {
        ISwap swap_ = _swaps.get(name);
        require(address(swap_) != address(0), "INVALID_NAME");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(swap_.erc20Allocations());

        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(swap_).functionDelegateCall(
            abi.encodeWithSelector(ISwap.swap.selector, amount, minAmount)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function registerSwap(ISwap swap_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _swaps.add(swap_);

        emit SwapRegistered(swap_);
    }

    function removeSwap(string calldata name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _swaps.remove(name);

        emit SwapRemoved(name);
    }

    function claim(string calldata name)
        external
        override
        nonReentrant
        onlyLpRole
    {
        IZap zap = _zaps.get(name);
        require(address(zap) != address(0), "INVALID_NAME");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(zap.erc20Allocations());
        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(zap).functionDelegateCall(
            abi.encodeWithSelector(IZap.claim.selector)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function emergencyExit(address token) external override onlyEmergencyRole {
        address emergencySafe = addressRegistry.emergencySafeAddress();
        IERC20 token_ = IERC20(token);
        uint256 balance = token_.balanceOf(address(this));
        token_.safeTransfer(emergencySafe, balance);

        emit EmergencyExit(emergencySafe, token_, balance);
    }

    function zapNames() external view override returns (string[] memory) {
        return _zaps.names();
    }

    function swapNames() external view override returns (string[] memory) {
        return _swaps.names();
    }

    /**
     * @notice Lock oracle adapter for the configured period
     * @param lockPeriod_ The number of blocks to lock for
     */
    function _lockOracleAdapter(uint256 lockPeriod_) internal {
        ILockingOracle oracleAdapter =
            ILockingOracle(addressRegistry.oracleAdapterAddress());
        oracleAdapter.lockFor(lockPeriod_);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(Address.isContract(addressRegistry_), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    /**
     * @notice Check if multiple asset allocations are ALL registered
     * @param allocationNames An array of asset allocation names to check
     * @return `true` if every asset allocation is registered, otherwise `false`
     */
    function _checkAllocationRegistrations(string[] memory allocationNames)
        internal
        view
        returns (bool)
    {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));

        return tvlManager.isAssetAllocationRegistered(allocationNames);
    }

    /**
     * @notice Check if multiple ERC20 asset allocations are ALL registered
     * @param tokens An array of ERC20 tokens to check
     * @return `true` if every ERC20 is registered, otherwise `false`
     */
    function _checkErc20Registrations(IERC20[] memory tokens)
        internal
        view
        returns (bool)
    {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));
        IErc20Allocation erc20Allocation =
            IErc20Allocation(
                address(
                    tvlManager.getAssetAllocation(Erc20AllocationConstants.NAME)
                )
            );

        return erc20Allocation.isErc20TokenRegistered(tokens);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Initializable} from "./Initializable.sol";
import {
    OwnableUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import {
    ERC20UpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import {
    ReentrancyGuardUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import {
    PausableUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import {AccessControlUpgradeSafe} from "./AccessControlUpgradeSafe.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

/* Aliases don't persist so we can't rename them here, but you should
 * rename them at point of import with the "UpgradeSafe" prefix, e.g.
 * import {Address as AddressUpgradeSafe} etc.
 */
import {
    Address
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import {
    SafeMath
} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import {
    SignedSafeMath
} from "@openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

abstract contract DeploymentConstants {
    address public constant ADDRESS_REGISTRY_PROXY_ADMIN = 
        0xFbF6c940c1811C3ebc135A9c4e39E042d02435d1;
    address public constant ADDRESS_REGISTRY_PROXY = 0x7EC81B7035e91f8435BdEb2787DCBd51116Ad303;

    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant POOL_PROXY_ADMIN =
        0x7965283631253DfCb71Db63a60C656DEDF76234f;
    address public constant DAI_POOL_PROXY =
        0x75CE0E501e2E6776FcAAa514f394a88a772A8970;
    address public constant USDC_POOL_PROXY =
        0xe18b0365D5D09F394f84eE56ed29DD2d8D6Fba5f;
    address public constant USDT_POOL_PROXY =
        0xeA9c5a2717D5Ab75afaAC340151e73a7e37d99A7;

    address public constant TVL_AGG_ADDRESS =
        0xDb299D394817D8e7bBe297E84AFfF7106CF92F5f;
    address public constant DAI_USD_AGG_ADDRESS =
        0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address public constant USDC_USD_AGG_ADDRESS =
        0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address public constant USDT_USD_AGG_ADDRESS =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IReservePool} from "./IReservePool.sol";
import {IWithdrawFeePool} from "./IWithdrawFeePool.sol";
import {ILockingPool} from "./ILockingPool.sol";
import {IPoolToken} from "./IPoolToken.sol";
import {ILiquidityPoolV2} from "./ILiquidityPoolV2.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IErc20Allocation} from "./IErc20Allocation.sol";
import {IChainlinkRegistry} from "./IChainlinkRegistry.sol";
import {IAssetAllocationRegistry} from "./IAssetAllocationRegistry.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";
import {ImmutableAssetAllocation} from "./ImmutableAssetAllocation.sol";
import {Erc20AllocationConstants} from "./Erc20Allocation.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IReservePool} from "contracts/pool/Imports.sol";

/**
 * @notice Facilitate lending liquidity to the LP Account from pools
 */
interface ILpAccountFunder {
    /**
     * @notice Log when liquidity is lent to the LP Account
     * @param poolIds An array of address registry IDs for pools that lent
     * @param amounts An array of the amount each pool lent
     */
    event FundLpAccount(bytes32[] poolIds, uint256[] amounts);

    /**
     * @notice Log when liquidity is repaid to the pools
     * @param poolIds An array of address registry IDs for pools were repaid
     * @param amounts An array of the amount each pool was repaid
     */
    event WithdrawFromLpAccount(bytes32[] poolIds, uint256[] amounts);

    /**
     * @notice Lend liquidity to the LP Account from pools
     * @dev Should calculate excess liquidity that can be lent
     * @param pools An array of address registry IDs for pools that lent
     */
    function fundLpAccount(bytes32[] calldata pools) external;

    /**
     * @notice Repay liquidity borrowed by the LP Account
     * @dev Should repay enough to fill up the pools' reserves
     * @param pools An array of address registry IDs for pools that were repaid
     */
    function withdrawFromLpAccount(bytes32[] calldata pools) external;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {
    Initializable as OZInitializable
} from "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

contract Initializable is OZInitializable {
    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyProxyAdmin() {
        require(msg.sender == proxyAdmin(), "PROXY_ADMIN_ONLY");
        _;
    }

    /**
     * @dev Returns the proxy admin address using the slot specified in EIP-1967:
     *
     * 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
     *  = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    function proxyAdmin() public view returns (address adm) {
        bytes32 slot =
            0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

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

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _setupDecimals(uint8 decimals_) internal {
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

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
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

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;

import {
    AccessControlUpgradeSafe as OZAccessControl
} from "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

/**
 * @notice Extends OpenZeppelin upgradeable AccessControl contract with modifiers
 * @dev This contract and AccessControl are essentially duplicates.
 */
contract AccessControlUpgradeSafe is OZAccessControl {
    /** @notice access control roles **/
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    modifier onlyLpRole() {
        require(hasRole(LP_ROLE, _msgSender()), "NOT_LP_ROLE");
        _;
    }

    modifier onlyContractRole() {
        require(hasRole(CONTRACT_ROLE, _msgSender()), "NOT_CONTRACT_ROLE");
        _;
    }

    modifier onlyAdminRole() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyEmergencyRole() {
        require(hasRole(EMERGENCY_ROLE, _msgSender()), "NOT_EMERGENCY_ROLE");
        _;
    }

    modifier onlyLpOrContractRole() {
        require(
            hasRole(LP_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_LP_OR_CONTRACT_ROLE"
        );
        _;
    }

    modifier onlyAdminOrContractRole() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_ADMIN_OR_CONTRACT_ROLE"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

pragma solidity ^0.6.2;

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
}

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
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
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

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

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";
import "../Initializable.sol";

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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {ILiquidityPoolV2} from "./ILiquidityPoolV2.sol";

/**
 * @notice For pools that keep a separate reserve of tokens
 */
interface IReservePool is ILiquidityPoolV2 {
    /**
     * @notice Log when the percent held in reserve is changed
     * @param reservePercentage The new percent held in reserve
     */
    event ReservePercentageChanged(uint256 reservePercentage);

    /**
     * @notice Set a new percent of tokens to hold in reserve
     * @param reservePercentage_ The new percent
     */
    function setReservePercentage(uint256 reservePercentage_) external;

    /**
     * @notice Transfer an amount of tokens to the LP Account
     * @dev This should only be callable by the `MetaPoolToken`
     * @param amount The amount of tokens
     */
    function transferToLpAccount(uint256 amount) external;

    /**
     * @notice Get the amount of tokens missing from the reserve
     * @dev A negative amount indicates extra tokens not needed for the reserve
     * @return The amount of missing tokens
     */
    function getReserveTopUpValue() external view returns (int256);

    /**
     * @notice Get the current percentage of tokens held in reserve
     * @return The percent
     */
    function reservePercentage() external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For pools that can charge an early withdrawal fee
 */
interface IWithdrawFeePool {
    /**
     * @notice Log when the fee period changes
     * @param feePeriod The new fee period
     */
    event FeePeriodChanged(uint256 feePeriod);

    /**
     * @notice Log when the fee percentage changes
     * @param feePercentage The new percentage
     */
    event FeePercentageChanged(uint256 feePercentage);

    /**
     * @notice Set the new fee period
     * @param feePeriod_ The new fee period
     */
    function setFeePeriod(uint256 feePeriod_) external;

    /**
     * @notice Set the new fee percentage
     * @param feePercentage_ The new percentage
     */
    function setFeePercentage(uint256 feePercentage_) external;

    /**
     * @notice Get the period of time that a withdrawal will be considered early
     * @notice An early withdrawal gets charged a fee
     * @notice The period starts from the time of the last deposit for an account
     * @return The time in seconds
     */
    function feePeriod() external view returns (uint256);

    /**
     * @notice Get the percentage of a withdrawal that is charged as a fee
     * @return The percentage
     */
    function feePercentage() external view returns (uint256);

    /**
     * @notice Check if caller will be charged early withdrawal fee
     * @return `true` when fee will apply, `false` when it won't
     */
    function isEarlyRedeem() external view returns (bool);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For pools that can be locked and unlocked in emergencies
 */
interface ILockingPool {
    /** @notice Log when deposits are locked */
    event AddLiquidityLocked();

    /** @notice Log when deposits are unlocked */
    event AddLiquidityUnlocked();

    /** @notice Log when withdrawals are locked */
    event RedeemLocked();

    /** @notice Log when withdrawals are unlocked */
    event RedeemUnlocked();

    /** @notice Lock deposits and withdrawals */
    function emergencyLock() external;

    /** @notice Unlock deposits and withdrawals */
    function emergencyUnlock() external;

    /** @notice Lock deposits */
    function emergencyLockAddLiquidity() external;

    /** @notice Unlock deposits */
    function emergencyUnlockAddLiquidity() external;

    /** @notice Lock withdrawals */
    function emergencyLockRedeem() external;

    /** @notice Unlock withdrawals */
    function emergencyUnlockRedeem() external;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IDetailedERC20} from "contracts/common/Imports.sol";

/**
 * @notice For pools that locked value between accounts
 * @dev Shares are accounted for using the `APT` token
 */
interface IPoolToken {
    /**
     * @notice Log a token deposit
     * @param sender Address of the depositor account
     * @param token Token deposited
     * @param tokenAmount The amount of tokens deposited
     * @param aptMintAmount Number of shares received
     * @param tokenEthValue Total value of the deposit
     * @param totalEthValueLocked Total value of the pool
     */
    event DepositedAPT(
        address indexed sender,
        IDetailedERC20 token,
        uint256 tokenAmount,
        uint256 aptMintAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );

    /**
     * @notice Log a token withdrawal
     * @param sender Address of the withdrawal account
     * @param token Token withdrawn
     * @param redeemedTokenAmount The amount of tokens withdrawn
     * @param aptRedeemAmount Number of shares redeemed
     * @param tokenEthValue Total value of the withdrawal
     * @param totalEthValueLocked Total value of the pool
     */
    event RedeemedAPT(
        address indexed sender,
        IDetailedERC20 token,
        uint256 redeemedTokenAmount,
        uint256 aptRedeemAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );

    /**
     * @notice Add liquidity for a share of the pool
     * @param amount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 amount) external;

    /**
     * @notice Redeem shares of the pool to withdraw liquidity
     * @param tokenAmount The amount of shares to redeem
     */
    function redeem(uint256 tokenAmount) external;

    /**
     * @notice Determine the share received for a deposit
     * @param depositAmount The size of the deposit
     * @return The number of shares
     */
    function calculateMintAmount(uint256 depositAmount)
        external
        view
        returns (uint256);

    /**
     * @notice How many tokens can be withdrawn with an amount of shares
     * @notice Accounts for early withdrawal fee
     * @param aptAmount The amount of shares
     * @return The amount of tokens
     */
    function getUnderlyerAmountWithFee(uint256 aptAmount)
        external
        view
        returns (uint256);

    /**
     * @notice How many tokens can be withdrawn with an amount of shares
     * @param aptAmount The amount of shares
     * @return The amount of tokens
     */
    function getUnderlyerAmount(uint256 aptAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Get the total USD value of an amount of shares
     * @param aptAmount The amount of shares
     * @return The total USD value of the shares
     */
    function getAPTValue(uint256 aptAmount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IDetailedERC20} from "contracts/common/Imports.sol";

/**
 * @notice For contracts that hold tokens and track the value locked
 */
interface ILiquidityPoolV2 {
    /**
     * @notice The token held by the pool
     * @return The token address
     */
    function underlyer() external view returns (IDetailedERC20);

    /**
     * @notice Get the total USD value locked in the pool
     * @return The total USD value
     */
    function getPoolTotalValue() external view returns (uint256);

    /**
     * @notice Get the total USD value of an amount of tokens
     * @param underlyerAmount The amount of tokens
     * @return The total USD value
     */
    function getValueFromUnderlyerAmount(uint256 underlyerAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Get the USD price of the token held by the pool
     * @return The price
     */
    function getUnderlyerPrice() external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Address} from "contracts/libraries/Imports.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";

/**
 * @notice Asset allocation with underlying tokens that cannot be added/removed
 */
abstract contract ImmutableAssetAllocation is AssetAllocationBase {
    using Address for address;

    constructor() public {
        _validateTokens(_getTokenData());
    }

    function tokens() public view override returns (TokenData[] memory) {
        TokenData[] memory tokens_ = _getTokenData();
        return tokens_;
    }

    /**
     * @notice Get the immutable array of underlying `TokenData`
     * @dev Should be implemented in child contracts with a hardcoded array
     * @return The array of `TokenData`
     */
    function _getTokenData() internal pure virtual returns (TokenData[] memory);

    /**
     * @notice Verifies that a `TokenData` array works with the `TvlManager`
     * @dev Reverts when there is invalid `TokenData`
     * @param tokens_ The array of `TokenData`
     */
    function _validateTokens(TokenData[] memory tokens_) internal view virtual {
        // length restriction due to encoding logic for allocation IDs
        require(tokens_.length < type(uint8).max, "TOO_MANY_TOKENS");
        for (uint256 i = 0; i < tokens_.length; i++) {
            address token = tokens_[i].token;
            _validateTokenAddress(token);
            string memory symbol = tokens_[i].symbol;
            require(bytes(symbol).length != 0, "INVALID_SYMBOL");
        }
        // TODO: check for duplicate tokens
    }

    /**
     * @notice Verify that a token is a contract
     * @param token The token to verify
     */
    function _validateTokenAddress(address token) internal view virtual {
        require(token.isContract(), "INVALID_ADDRESS");
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "contracts/common/Imports.sol";

interface ILiquidityPool {
    event DepositedAPT(
        address indexed sender,
        IERC20 token,
        uint256 tokenAmount,
        uint256 aptMintAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event RedeemedAPT(
        address indexed sender,
        IERC20 token,
        uint256 redeemedTokenAmount,
        uint256 aptRedeemAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event AddLiquidityLocked();
    event AddLiquidityUnlocked();
    event RedeemLocked();
    event RedeemUnlocked();
    event AdminChanged(address);
    event PriceAggregatorChanged(address agg);

    function addLiquidity(uint256 amount) external;

    function redeem(uint256 tokenAmount) external;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Address} from "contracts/libraries/Imports.sol";
import {TestMetaPoolToken} from "contracts/mapt/TestMetaPoolToken.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";

import {MetaPoolTokenFactory, OracleAdapterFactory} from "./factories.sol";

contract TestMetaPoolTokenFactory is MetaPoolTokenFactory {
    using Address for address;

    function _deployLogic(bytes memory initData)
        internal
        override
        returns (address)
    {
        TestMetaPoolToken logic = new TestMetaPoolToken();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

contract TestOracleAdapterFactory is OracleAdapterFactory {
    address public oracleAdapter;

    function preCreate(
        address addressRegistry,
        address tvlSource,
        address[] memory assets,
        address[] memory sources,
        uint256 aggStalePeriod,
        uint256 defaultLockPeriod
    ) external returns (address) {
        oracleAdapter = super.create(
            addressRegistry,
            tvlSource,
            assets,
            sources,
            aggStalePeriod,
            defaultLockPeriod
        );
    }

    function create(
        address,
        address,
        address[] memory,
        address[] memory,
        uint256,
        uint256
    ) public override returns (address) {
        require(oracleAdapter != address(0), "USE_PRECREATE_FIRST");
        return oracleAdapter;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IReservePool} from "contracts/pool/Imports.sol";

import {MetaPoolToken} from "./MetaPoolToken.sol";

/**
 * @dev Proxy contract to test internal variables and functions
 * Should not be used other than in test files!
 */
contract TestMetaPoolToken is MetaPoolToken {
    /// @dev useful for changing supply during calc tests
    function testMint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    /// @dev useful for changing supply during calc tests
    function testBurn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function testFundLpAccount(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) public {
        _fundLpAccount(pools, amounts);
    }

    function testWithdrawFromLpAccount(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) public {
        _withdrawFromLpAccount(pools, amounts);
    }

    function testMultipleMintAndTransfer(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) public {
        _multipleMintAndTransfer(pools, amounts);
    }

    function testMintAndTransfer(
        IReservePool pool,
        uint256 mintAmount,
        uint256 transferAmount
    ) public {
        _mintAndTransfer(pool, mintAmount, transferAmount);
    }

    function testMultipleBurnAndTransfer(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) public {
        _multipleBurnAndTransfer(pools, amounts);
    }

    function testBurnAndTransfer(
        IReservePool pool,
        address lpSafe,
        uint256 burnAmount,
        uint256 transferAmount
    ) public {
        _burnAndTransfer(pool, lpSafe, burnAmount, transferAmount);
    }

    function testRegisterPoolUnderlyers(IReservePool[] memory pools) public {
        _registerPoolUnderlyers(pools);
    }

    function testGetTvl() public view returns (uint256) {
        return _getTvl();
    }

    function testCalculateDeltas(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) public view returns (uint256[] memory) {
        return _calculateDeltas(pools, amounts);
    }

    function testCalculateDelta(
        uint256 amount,
        uint256 tokenPrice,
        uint8 decimals
    ) public view returns (uint256) {
        return _calculateDelta(amount, tokenPrice, decimals);
    }

    function testGetFundAmounts(int256[] memory amounts)
        public
        pure
        returns (uint256[] memory)
    {
        return _getFundAmounts(amounts);
    }

    function testGetWithdrawAmounts(int256[] memory amounts)
        public
        pure
        returns (uint256[] memory)
    {
        return _getWithdrawAmounts(amounts);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {LpAccount} from "./LpAccount.sol";
import {TestLpAccountStorage} from "./TestLpAccountStorage.sol";

contract TestLpAccount is TestLpAccountStorage, LpAccount {
    function _deployCalls() external view returns (uint256[][] memory) {
        return _deploysArray;
    }

    function _unwindCalls() external view returns (uint256[] memory) {
        return _unwindsArray;
    }

    function _swapCalls() external view returns (uint256[] memory) {
        return _swapsArray;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IAssetAllocation, IERC20} from "contracts/common/Imports.sol";

abstract contract TestLpAccountStorage {
    string internal _name;

    uint256[][] internal _deploysArray;
    uint256[] internal _unwindsArray;
    uint256[] internal _swapsArray;

    uint256 public _claimsCounter;

    string[] internal _assetAllocations;
    IERC20[] internal _tokens;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    IERC20,
    INameIdentifier
} from "contracts/common/Imports.sol";
import {IZap} from "./IZap.sol";
import {TestLpAccountStorage} from "./TestLpAccountStorage.sol";

contract TestZap is IZap, TestLpAccountStorage {
    string[] internal _sortedSymbols;

    constructor(string memory name) public {
        _name = name;
    }

    function deployLiquidity(uint256[] calldata amounts) external override {
        _deploysArray.push(amounts);
    }

    // TODO: push index in addition to amount
    function unwindLiquidity(uint256 amount, uint8) external override {
        _unwindsArray.push(amount);
    }

    function claim() external override {
        _claimsCounter += 1;
    }

    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view override returns (string memory) {
        return _name;
    }

    // Order of token amounts
    function sortedSymbols() external view override returns (string[] memory) {
        return _sortedSymbols;
    }

    function assetAllocations()
        external
        view
        override
        returns (string[] memory)
    {
        return _assetAllocations;
    }

    function erc20Allocations()
        external
        view
        override
        returns (IERC20[] memory)
    {
        return _tokens;
    }

    function _setAssetAllocations(string[] memory allocationNames) public {
        _assetAllocations = allocationNames;
    }

    function _setErc20Allocations(IERC20[] memory tokens) public {
        _tokens = tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "contracts/libraries/Imports.sol";
import {IERC20, IAssetAllocation} from "contracts/common/Imports.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {ISwap} from "contracts/lpaccount/Imports.sol";

abstract contract SwapBase is ISwap {
    using SafeERC20 for IERC20;

    ISwapRouter private constant _ROUTER =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IERC20 internal immutable _IN_TOKEN;
    IERC20 internal immutable _OUT_TOKEN;

    event Swap(ISwapRouter.ExactInputParams params, uint256 amountOut);

    constructor(IERC20 inToken, IERC20 outToken) public {
        _IN_TOKEN = inToken;
        _OUT_TOKEN = outToken;
    }

    // TODO: create function for calculating min amount
    function swap(uint256 amount, uint256 minAmount) external override {
        _IN_TOKEN.safeApprove(address(_ROUTER), 0);
        _IN_TOKEN.safeApprove(address(_ROUTER), amount);

        bytes memory path = _getPath();

        // solhint-disable not-rely-on-time
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: minAmount
            });
        // solhint-enable not-rely-on-time
        uint256 amountOut = _ROUTER.exactInput(params);

        emit Swap(params, amountOut);
    }

    function erc20Allocations()
        external
        view
        override
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](2);
        allocations[0] = _IN_TOKEN;
        allocations[1] = _OUT_TOKEN;
        return allocations;
    }

    function _getPath() internal view virtual returns (bytes memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {SwapBase} from "./SwapBase.sol";

abstract contract CrvToStablecoinSwapBase is SwapBase {
    IERC20 private constant _CRV =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 private constant _WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint24 private _CRV_WETH_FEE = 10000;
    uint24 private _WETH_STABLECOIN_FEE = 500;

    constructor(IERC20 stablecoin) public SwapBase(_CRV, stablecoin) {} // solhint-disable-line no-empty-blocks

    function _getPath() internal view virtual override returns (bytes memory) {
        bytes memory path =
            abi.encodePacked(
                address(_IN_TOKEN),
                _CRV_WETH_FEE,
                address(_WETH),
                _WETH_STABLECOIN_FEE,
                address(_OUT_TOKEN)
            );

        return path;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {CrvToStablecoinSwapBase} from "./CrvToStablecoinSwapBase.sol";

contract CrvToUsdtSwap is CrvToStablecoinSwapBase {
    string public constant override NAME = "crv-to-usdt";

    IERC20 private constant _USDT =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvToStablecoinSwapBase(_USDT) {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {CrvToStablecoinSwapBase} from "./CrvToStablecoinSwapBase.sol";

contract CrvToUsdcSwap is CrvToStablecoinSwapBase {
    string public constant override NAME = "crv-to-usdc";

    IERC20 private constant _USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvToStablecoinSwapBase(_USDC) {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {SwapBase} from "./SwapBase.sol";

abstract contract AaveToStablecoinSwapBase is SwapBase {
    IERC20 private constant _AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    IERC20 private constant _WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint24 private _AAVE_WETH_FEE = 3000;
    uint24 private _WETH_STABLECOIN_FEE = 500;

    constructor(IERC20 stablecoin) public SwapBase(_AAVE, stablecoin) {} // solhint-disable-line no-empty-blocks

    function _getPath() internal view virtual override returns (bytes memory) {
        bytes memory path =
            abi.encodePacked(
                address(_IN_TOKEN),
                _AAVE_WETH_FEE,
                address(_WETH),
                _WETH_STABLECOIN_FEE,
                address(_OUT_TOKEN)
            );

        return path;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {AaveToStablecoinSwapBase} from "./AaveToStablecoinSwapBase.sol";

contract AaveToUsdtSwap is AaveToStablecoinSwapBase {
    string public constant override NAME = "aave-to-usdt";

    IERC20 private constant _USDT =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // solhint-disable-next-line no-empty-blocks
    constructor() public AaveToStablecoinSwapBase(_USDT) {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {AaveToStablecoinSwapBase} from "./AaveToStablecoinSwapBase.sol";

contract AaveToUsdcSwap is AaveToStablecoinSwapBase {
    string public constant override NAME = "aave-to-usdc";

    IERC20 private constant _USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // solhint-disable-next-line no-empty-blocks
    constructor() public AaveToStablecoinSwapBase(_USDC) {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {AaveToStablecoinSwapBase} from "./AaveToStablecoinSwapBase.sol";

contract AaveToDaiSwap is AaveToStablecoinSwapBase {
    string public constant override NAME = "aave-to-dai";

    IERC20 private constant _DAI =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // solhint-disable-next-line no-empty-blocks
    constructor() public AaveToStablecoinSwapBase(_DAI) {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {CrvToStablecoinSwapBase} from "./CrvToStablecoinSwapBase.sol";

contract CrvToDaiSwap is CrvToStablecoinSwapBase {
    string public constant override NAME = "crv-to-dai";

    IERC20 private constant _DAI =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvToStablecoinSwapBase(_DAI) {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";

/**
 * @notice Uniswap contract for adding/removing liquidity from pools
 */
interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

/**
 * @title Periphery Contract for the Uniswap V2 Router
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Uniswap LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract UniswapPeriphery {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param lpToken the LP token representing the share of the pool
     * @param tokenIndex the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IUniswapV2Pair lpToken,
        uint256 tokenIndex
    ) external view returns (uint256 balance) {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(lpToken, tokenIndex);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IUniswapV2Pair lpToken, uint256 tokenIndex)
        public
        view
        returns (uint256 poolBalance)
    {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");
        IERC20 token;
        if (tokenIndex == 0) {
            token = IERC20(lpToken.token0());
        } else if (tokenIndex == 1) {
            token = IERC20(lpToken.token1());
        } else {
            revert("INVALID_TOKEN_INDEX");
        }
        poolBalance = token.balanceOf(address(lpToken));
    }

    function getLpTokenShare(address account, IERC20 lpToken)
        public
        view
        returns (uint256 balance, uint256 totalSupply)
    {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {SafeERC20, SafeMath} from "contracts/libraries/Imports.sol";
import {
    IOldStableSwap4 as IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveSusdV2Constants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract SusdV2Zap is CurveGaugeZapBase, CurveSusdV2Constants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            4
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(2);
        allocations[4] = IERC20(SNX_ADDRESS);
        allocations[5] = IERC20(SUSD_ADDRESS);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).coins(int128(i));
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2], amounts[3]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 4, "INVALID_INDEX");

        uint256[] memory balances = new uint256[](4);
        for (uint256 i = 0; i < balances.length; i++) {
            if (i == index) continue;
            IERC20 inToken = IERC20(_getCoinAtIndex(i));
            balances[i] = inToken.balanceOf(address(this));
        }

        IStableSwap swap = IStableSwap(SWAP_ADDRESS);
        swap.remove_liquidity(
            lpBalance,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );

        for (uint256 i = 0; i < balances.length; i++) {
            if (i == index) continue;
            IERC20 inToken = IERC20(_getCoinAtIndex(i));
            uint256 balanceDelta =
                inToken.balanceOf(address(this)).sub(balances[i]);
            inToken.safeApprove(address(swap), 0);
            inToken.safeApprove(address(swap), balanceDelta);
            swap.exchange(int128(i), index, balanceDelta, 0);
        }

        uint256 underlyerBalance =
            IERC20(_getCoinAtIndex(index)).balanceOf(address(this));
        require(underlyerBalance >= minAmount, "UNDER_MIN_AMOUNT");
    }

    /**
     * @dev claim protocol-specific rewards;
     *      CRV rewards are always claimed through the minter, in
     *      the `CurveGaugeZapBase` implementation.
     */
    function _claimRewards() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.claim_rewards();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {CTokenInterface} from "./CTokenInterface.sol";
import {ITokenMinter} from "./ITokenMinter.sol";
import {IStableSwap, IStableSwap3} from "./IStableSwap.sol";
import {IStableSwap2} from "./IStableSwap2.sol";
import {IStableSwap4} from "./IStableSwap4.sol";
import {IOldStableSwap2} from "./IOldStableSwap2.sol";
import {IOldStableSwap4} from "./IOldStableSwap4.sol";
import {ILiquidityGauge} from "./ILiquidityGauge.sol";
import {IStakingRewards} from "./IStakingRewards.sol";
import {IDepositZap} from "./IDepositZap.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveSusdV2Constants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-susdv2";

    address public constant STABLE_SWAP_ADDRESS =
        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public constant LP_TOKEN_ADDRESS =
        0xC25a3A3b969415c80451098fa907EC722572917F;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xA90996896660DEcC6E997655E065b23788857849;

    address public constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant SNX_ADDRESS =
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {
    CurveAllocationBase,
    CurveAllocationBase3
} from "./CurveAllocationBase.sol";
import {CurveAllocationBase2} from "./CurveAllocationBase2.sol";
import {CurveAllocationBase4} from "./CurveAllocationBase4.sol";
import {CurveGaugeZapBase} from "./CurveGaugeZapBase.sol";
import {CurveZapBase} from "./CurveZapBase.sol";
import {OldCurveAllocationBase2} from "./OldCurveAllocationBase2.sol";
import {OldCurveAllocationBase4} from "./OldCurveAllocationBase4.sol";
import {TestCurveZap} from "./TestCurveZap.sol";

// SPDX-License-Identifier: BSD 3-Clause
/*
 * https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
 */
pragma solidity 0.6.11;

interface CTokenInterface {
    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function totalSupply() external returns (uint256);

    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/**
 * @notice the Curve token minter
 * @author Curve Finance
 * @dev translated from vyper
 * license MIT
 * version 0.2.4
 */

// solhint-disable func-name-mixedcase, func-param-name-mixedcase
interface ITokenMinter {
    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge_addr `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge_addr) external;

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauge_addrs List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauge_addrs) external;

    /**
     * @notice Mint tokens for `_for`
     * @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
     * @param gauge_addr `LiquidityGauge` address to get mintable amount from
     * @param _for Address to mint to
     */
    function mint_for(address gauge_addr, address _for) external;

    /**
     * @notice allow `minting_user` to mint for `msg.sender`
     * @param minting_user Address to toggle permission for
     */
    function toggle_approve_mint(address minting_user) external;
}
// solhint-enable

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    // solhint-disable-next-line
    function underlying_coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    // solhint-disable-next-line
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 minMinAmount,
        bool useUnderlyer
    ) external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount,
        bool useUnderlyer
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// solhint-disable-next-line no-empty-blocks
interface IStableSwap3 is IStableSwap {

}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap2 {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap4 {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IOldStableSwap2 {
    function balances(int128 coin) external view returns (uint256);

    function coins(int128 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    /// @dev need this due to lack of `remove_liquidity_one_coin`
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy // solhint-disable-line func-param-name-mixedcase
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IOldStableSwap4 {
    function balances(int128 coin) external view returns (uint256);

    function coins(int128 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts)
        external;

    /// @dev need this due to lack of `remove_liquidity_one_coin`
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy // solhint-disable-line func-param-name-mixedcase
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the liquidity gauge, i.e. staking contract, for the stablecoin pool
 */
interface ILiquidityGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    /**
     * @notice Claim available reward tokens for msg.sender
     */
    // solhint-disable-next-line func-name-mixedcase
    function claim_rewards() external;

    /**
     * @notice Get the number of claimable reward tokens for a user
     * @dev This function should be manually changed to "view" in the ABI
     *      Calling it via a transaction will claim available reward tokens
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     * @return uint256 Claimable reward token amount
     */
    // solhint-disable-next-line func-name-mixedcase
    function claimable_reward(address _addr, address _token)
        external
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/*
 * Synthetix: StakingRewards.sol
 *
 * Docs: https://docs.synthetix.io/
 *
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2020 Synthetix
 *
 */

interface IStakingRewards {
    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-2.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IDepositZap {
    // this method only exists on the DepositCompound Contract
    // solhint-disable-next-line
    function underlying_coins(int128 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 _amount,
        int128 i,
        uint256 minAmount
    ) external;

    function curve() external view returns (address);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract Curve3PoolUnderlyerConstants {
    // underlyer addresses
    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
}

abstract contract Curve3PoolConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-3pool";

    address public constant STABLE_SWAP_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant LP_TOKEN_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// solhint-disable-next-line no-empty-blocks
contract CurveAllocationBase3 is CurveAllocationBase {

}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase2 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap2 stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap4,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase4 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap4 stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IERC20,
    IDetailedERC20
} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {
    ILiquidityGauge,
    ITokenMinter
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveZapBase} from "contracts/protocols/curve/common/CurveZapBase.sol";

abstract contract CurveGaugeZapBase is IZap, CurveZapBase {
    using SafeERC20 for IERC20;

    address internal constant MINTER_ADDRESS =
        0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    address internal immutable LP_ADDRESS;
    address internal immutable GAUGE_ADDRESS;

    constructor(
        address swapAddress,
        address lpAddress,
        address gaugeAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 nCoins
    )
        public
        CurveZapBase(swapAddress, denominator, slippage, nCoins)
    // solhint-disable-next-line no-empty-blocks
    {
        LP_ADDRESS = lpAddress;
        GAUGE_ADDRESS = gaugeAddress;
    }

    function _depositToGauge() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        uint256 lpBalance = IERC20(LP_ADDRESS).balanceOf(address(this));
        IERC20(LP_ADDRESS).safeApprove(GAUGE_ADDRESS, 0);
        IERC20(LP_ADDRESS).safeApprove(GAUGE_ADDRESS, lpBalance);
        liquidityGauge.deposit(lpBalance);
    }

    function _withdrawFromGauge(uint256 amount)
        internal
        override
        returns (uint256)
    {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.withdraw(amount);
        //lpBalance
        return IERC20(LP_ADDRESS).balanceOf(address(this));
    }

    function _claim() internal override {
        // claim CRV
        ITokenMinter(MINTER_ADDRESS).mint(GAUGE_ADDRESS);

        // claim protocol-specific rewards
        _claimRewards();
    }

    // solhint-disable-next-line no-empty-blocks
    function _claimRewards() internal virtual {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath, SafeERC20} from "contracts/libraries/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IDetailedERC20,
    IERC20
} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveZapBase is Curve3PoolUnderlyerConstants, IZap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal constant CRV_ADDRESS =
        0xD533a949740bb3306d119CC777fa900bA034cd52;

    address internal immutable SWAP_ADDRESS;
    uint256 internal immutable DENOMINATOR;
    uint256 internal immutable SLIPPAGE;
    uint256 internal immutable N_COINS;

    constructor(
        address swapAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 nCoins
    ) public {
        SWAP_ADDRESS = swapAddress;
        DENOMINATOR = denominator;
        SLIPPAGE = slippage;
        N_COINS = nCoins;
    }

    /// @param amounts array of underlyer amounts
    function deployLiquidity(uint256[] calldata amounts) external override {
        require(amounts.length == N_COINS, "INVALID_AMOUNTS");

        uint256 totalNormalizedDeposit = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;

            uint256 deposit = amounts[i];
            address underlyerAddress = _getCoinAtIndex(i);
            uint8 decimals = IDetailedERC20(underlyerAddress).decimals();

            uint256 normalizedDeposit =
                deposit.mul(10**uint256(18)).div(10**uint256(decimals));
            totalNormalizedDeposit = totalNormalizedDeposit.add(
                normalizedDeposit
            );

            IERC20(underlyerAddress).safeApprove(SWAP_ADDRESS, 0);
            IERC20(underlyerAddress).safeApprove(SWAP_ADDRESS, amounts[i]);
        }

        uint256 minAmount =
            _calcMinAmount(totalNormalizedDeposit, _getVirtualPrice());
        _addLiquidity(amounts, minAmount);
        _depositToGauge();
    }

    /**
     * @param amount LP token amount
     * @param index underlyer index
     */
    function unwindLiquidity(uint256 amount, uint8 index) external override {
        require(index < N_COINS, "INVALID_INDEX");
        uint256 lpBalance = _withdrawFromGauge(amount);
        address underlyerAddress = _getCoinAtIndex(index);
        uint8 decimals = IDetailedERC20(underlyerAddress).decimals();
        uint256 minAmount =
            _calcMinAmountUnderlyer(lpBalance, _getVirtualPrice(), decimals);
        _removeLiquidity(lpBalance, index, minAmount);
    }

    function claim() external override {
        _claim();
    }

    function sortedSymbols() public view override returns (string[] memory) {
        // N_COINS is not available as a public function
        // so we have to hardcode the number here
        string[] memory symbols = new string[](N_COINS);
        for (uint256 i = 0; i < symbols.length; i++) {
            address underlyerAddress = _getCoinAtIndex(i);
            symbols[i] = IDetailedERC20(underlyerAddress).symbol();
        }
        return symbols;
    }

    function _getVirtualPrice() internal view virtual returns (uint256);

    function _getCoinAtIndex(uint256 i) internal view virtual returns (address);

    function _addLiquidity(uint256[] calldata amounts_, uint256 minAmount)
        internal
        virtual;

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal virtual;

    function _depositToGauge() internal virtual;

    function _withdrawFromGauge(uint256 amount)
        internal
        virtual
        returns (uint256);

    function _claim() internal virtual;

    /**
     * @dev normalizedDepositAmount the amount in same units as virtual price (18 decimals)
     * @dev virtualPrice the "price", in 18 decimals, per big token unit of the LP token
     * @return required minimum amount of LP token (in token wei)
     */
    function _calcMinAmount(
        uint256 normalizedDepositAmount,
        uint256 virtualPrice
    ) internal view returns (uint256) {
        uint256 idealLpTokenAmount =
            normalizedDepositAmount.mul(1e18).div(virtualPrice);
        // allow some slippage/MEV
        return
            idealLpTokenAmount.mul(DENOMINATOR.sub(SLIPPAGE)).div(DENOMINATOR);
    }

    /**
     * @param lpTokenAmount the amount in the same units as Curve LP token (18 decimals)
     * @param virtualPrice the "price", in 18 decimals, per big token unit of the LP token
     * @param decimals the number of decimals for underlyer token
     * @return required minimum amount of underlyer (in token wei)
     */
    function _calcMinAmountUnderlyer(
        uint256 lpTokenAmount,
        uint256 virtualPrice,
        uint8 decimals
    ) internal view returns (uint256) {
        // TODO: grab LP Token decimals explicitly?
        uint256 normalizedUnderlyerAmount =
            lpTokenAmount.mul(virtualPrice).div(1e18);
        uint256 underlyerAmount =
            normalizedUnderlyerAmount.mul(10**uint256(decimals)).div(
                10**uint256(18)
            );

        // allow some slippage/MEV
        return underlyerAmount.mul(DENOMINATOR.sub(SLIPPAGE)).div(DENOMINATOR);
    }

    function _createErc20AllocationArray(uint256 extraAllocations)
        internal
        pure
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](extraAllocations.add(4));
        allocations[0] = IERC20(CRV_ADDRESS);
        allocations[1] = IERC20(DAI_ADDRESS);
        allocations[2] = IERC20(USDC_ADDRESS);
        allocations[3] = IERC20(USDT_ADDRESS);
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IOldStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract OldCurveAllocationBase2 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IOldStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        int128 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IOldStableSwap2 stableSwap, int128 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IOldStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IOldStableSwap4,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract OldCurveAllocationBase4 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IOldStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        int128 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IOldStableSwap4 stableSwap, int128 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IOldStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    CurveGaugeZapBase
} from "contracts/protocols/curve/common/CurveGaugeZapBase.sol";

contract TestCurveZap is CurveGaugeZapBase {
    string public constant override NAME = "TestCurveZap";

    address[] private _underlyers;

    constructor(
        address swapAddress,
        address lpTokenAddress,
        address liquidityGaugeAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 numOfCoins
    )
        public
        CurveGaugeZapBase(
            swapAddress,
            lpTokenAddress,
            liquidityGaugeAddress,
            denominator,
            slippage,
            numOfCoins
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function setUnderlyers(address[] calldata underlyers) external {
        _underlyers = underlyers;
    }

    function getSwapAddress() external view returns (address) {
        return SWAP_ADDRESS;
    }

    function getLpTokenAddress() external view returns (address) {
        return address(LP_ADDRESS);
    }

    function getGaugeAddress() external view returns (address) {
        return GAUGE_ADDRESS;
    }

    function getDenominator() external view returns (uint256) {
        return DENOMINATOR;
    }

    function getSlippage() external view returns (uint256) {
        return SLIPPAGE;
    }

    function getNumberOfCoins() external view returns (uint256) {
        return N_COINS;
    }

    function calcMinAmount(uint256 totalAmount, uint256 virtualPrice)
        external
        view
        returns (uint256)
    {
        return _calcMinAmount(totalAmount, virtualPrice);
    }

    function calcMinAmountUnderlyer(
        uint256 totalAmount,
        uint256 virtualPrice,
        uint8 decimals
    ) external view returns (uint256) {
        return _calcMinAmountUnderlyer(totalAmount, virtualPrice, decimals);
    }

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return 1;
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return _underlyers[i];
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount // solhint-disable-next-line no-empty-blocks
    ) internal override {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IOldStableSwap4,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    OldCurveAllocationBase4
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveSusdV2Constants} from "./Constants.sol";

contract CurveSusdV2Allocation is
    OldCurveAllocationBase4,
    ImmutableAssetAllocation,
    CurveSusdV2Constants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                IOldStableSwap4(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                tokenIndex
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](4);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[2] = TokenData(USDT_ADDRESS, "USDT", 6);
        tokens[3] = TokenData(SUSD_ADDRESS, "sUSD", 18);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveSaaveConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-saave";

    address public constant STABLE_SWAP_ADDRESS =
        0xEB16Ae0052ed37f479f7fe63849198Df1765a733;
    address public constant LP_TOKEN_ADDRESS =
        0x02d341CcB60fAaf662bC0554d13778015d1b285C;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0x462253b8F74B72304c145DB0e4Eebd326B22ca39;

    address public constant STKAAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant ADAI_ADDRESS =
        0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant ASUSD_ADDRESS =
        0x6C5024Cd4F8A59110119C56f8933403A539555EB;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    IStableSwap2 as IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveSaaveConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract SAavePoolZap is CurveGaugeZapBase, CurveSaaveConstants {
    string internal constant AAVE_ALLOCATION = "aave";

    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            2
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](2);
        allocationNames[0] = NAME;
        allocationNames[1] = AAVE_ALLOCATION;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).coins(i);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 2, "INVALID_INDEX");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount
        );
    }

    /**
     * @dev claim protocol-specific rewards; stkAAVE in this case.
     *      CRV rewards are always claimed through the minter, in
     *      the `CurveGaugeZapBase` implementation.
     */
    function _claimRewards() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.claim_rewards();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveUstConstants is INameIdentifier {
    string public constant override NAME = "curve-ust";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x94e131324b6054c0D789b190b2dAC504e4361b53);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x3B7020743Bc2A4ca9EaF9D0722d42E20d6935855);

    IMetaPool public constant META_POOL =
        IMetaPool(0x890f4e345B1dAED0367A877a1612f86A1f86985f);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IMetaPool} from "./IMetaPool.sol";
import {IOldDepositor} from "./IOldDepositor.sol";
import {IDepositor} from "./IDepositor.sol";
import {DepositorConstants} from "./Constants.sol";
import {MetaPoolAllocationBase} from "./MetaPoolAllocationBase.sol";
import {MetaPoolOldDepositorZap} from "./MetaPoolOldDepositorZap.sol";
import {MetaPoolDepositorZap} from "./MetaPoolDepositorZap.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the Curve metapool contract
 * @dev A metapool is sometimes its own LP token
 */
interface IMetaPool is IERC20 {
    /// @dev 1st coin is the protocol token, 2nd is the Curve base pool
    function balances(uint256 coin) external view returns (uint256);

    /// @dev 1st coin is the protocol token, 2nd is the Curve base pool
    function coins(uint256 coin) external view returns (address);

    /// @dev the number of coins is hard-coded in curve contracts
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /// @dev the number of coins is hard-coded in curve contracts
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IOldDepositor {
    // solhint-disable
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function coins(uint256 i) external view returns (address);

    function base_coins(uint256 i) external view returns (address);
    // solhint-enable
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IDepositor {
    // solhint-disable
    function add_liquidity(
        address _pool,
        uint256[4] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    // solhint-enable

    // solhint-disable
    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amounts
    ) external returns (uint256);
    // solhint-enable
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {
    IStableSwap
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IDepositor} from "./IDepositor.sol";

abstract contract DepositorConstants {
    IStableSwap public constant BASE_POOL =
        IStableSwap(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    // A depositor "zap" contract for metapools
    IDepositor public constant DEPOSITOR =
        IDepositor(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";

import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {IMetaPool} from "./IMetaPool.sol";

import {
    Curve3PoolAllocation
} from "contracts/protocols/curve/3pool/Allocation.sol";

import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

/**
 * @title Periphery Contract for a Curve metapool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of a Curve LP token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
abstract contract MetaPoolAllocationBase is
    ImmutableAssetAllocation,
    Curve3PoolUnderlyerConstants
{
    using SafeMath for uint256;

    /// @dev all existing Curve metapools are paired with 3Pool
    Curve3PoolAllocation public immutable curve3PoolAllocation;

    constructor(address curve3PoolAllocation_) public {
        curve3PoolAllocation = Curve3PoolAllocation(curve3PoolAllocation_);
    }

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's LP token balance.
     * @param metaPool the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IMetaPool metaPool,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(metaPool) != address(0), "INVALID_POOL");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(metaPool, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, metaPool, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IMetaPool metaPool, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(metaPool) != address(0), "INVALID_POOL");
        require(coin < 256, "INVALID_COIN");
        if (coin == 0) {
            return metaPool.balances(0);
        }
        coin -= 1;
        uint256 balance =
            curve3PoolAllocation.balanceOf(address(metaPool), uint8(coin));
        // renormalize using the pool's tracked 3Crv balance
        IERC20 baseLpToken = IERC20(metaPool.coins(1));
        uint256 adjustedBalance =
            balance.mul(metaPool.balances(1)).div(
                baseLpToken.balanceOf(address(metaPool))
            );
        return adjustedBalance;
    }

    function getLpTokenShare(
        address account,
        IMetaPool metaPool,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(metaPool) != address(0), "INVALID_POOL");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }

    function _getBasePoolTokenData(
        address primaryUnderlyer,
        string memory symbol,
        uint8 decimals
    ) internal pure returns (TokenData[] memory) {
        TokenData[] memory tokens = new TokenData[](4);
        tokens[0] = TokenData(primaryUnderlyer, symbol, decimals);
        tokens[1] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[2] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[3] = TokenData(USDT_ADDRESS, "USDT", 6);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {IMetaPool} from "./IMetaPool.sol";
import {IOldDepositor} from "./IOldDepositor.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

abstract contract MetaPoolOldDepositorZap is CurveGaugeZapBase {
    IOldDepositor internal immutable _DEPOSITOR;
    IMetaPool internal immutable _META_POOL;

    constructor(
        IOldDepositor depositor,
        IMetaPool metapool,
        address lpAddress,
        address gaugeAddress,
        uint256 denominator,
        uint256 slippage
    )
        public
        CurveGaugeZapBase(
            address(depositor),
            lpAddress,
            gaugeAddress,
            denominator,
            slippage,
            4
        )
    {
        _DEPOSITOR = depositor;
        _META_POOL = metapool;
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        _DEPOSITOR.add_liquidity(
            [amounts[0], amounts[1], amounts[2], amounts[3]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        IERC20(LP_ADDRESS).safeApprove(address(_DEPOSITOR), 0);
        IERC20(LP_ADDRESS).safeApprove(address(_DEPOSITOR), lpBalance);
        _DEPOSITOR.remove_liquidity_one_coin(lpBalance, index, minAmount);
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return _META_POOL.get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        if (i == 0) {
            return _DEPOSITOR.coins(0);
        } else {
            return _DEPOSITOR.base_coins(i.sub(1));
        }
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {IMetaPool} from "./IMetaPool.sol";
import {DepositorConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

abstract contract MetaPoolDepositorZap is
    CurveGaugeZapBase,
    DepositorConstants
{
    IMetaPool internal immutable _META_POOL;

    constructor(
        IMetaPool metapool,
        address lpAddress,
        address gaugeAddress,
        uint256 denominator,
        uint256 slippage
    )
        public
        CurveGaugeZapBase(
            address(DEPOSITOR),
            lpAddress,
            gaugeAddress,
            denominator,
            slippage,
            4
        )
    {
        _META_POOL = metapool;
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        DEPOSITOR.add_liquidity(
            address(_META_POOL),
            [amounts[0], amounts[1], amounts[2], amounts[3]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        IERC20(LP_ADDRESS).safeApprove(address(DEPOSITOR), 0);
        IERC20(LP_ADDRESS).safeApprove(address(DEPOSITOR), lpBalance);
        DEPOSITOR.remove_liquidity_one_coin(
            address(_META_POOL),
            lpBalance,
            index,
            minAmount
        );
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return _META_POOL.get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        if (i == 0) {
            return _META_POOL.coins(0);
        } else {
            return BASE_POOL.coins(i.sub(1));
        }
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    CurveAllocationBase
} from "contracts/protocols/curve/common/Imports.sol";

import {Curve3PoolConstants} from "./Constants.sol";

contract Curve3PoolAllocation is
    CurveAllocationBase,
    ImmutableAssetAllocation,
    Curve3PoolConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                IStableSwap(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](3);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[2] = TokenData(USDT_ADDRESS, "USDT", 6);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveUstConstants} from "./Constants.sol";
import {
    MetaPoolOldDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract UstPoolZap is MetaPoolOldDepositorZap, CurveUstConstants {
    constructor()
        public
        MetaPoolOldDepositorZap(
            DEPOSITOR,
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveUstConstants} from "./Constants.sol";

contract CurveUstAllocation is MetaPoolAllocationBase, CurveUstConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "UST", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveUsdpConstants} from "./Constants.sol";
import {
    MetaPoolOldDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract UsdpPoolZap is MetaPoolOldDepositorZap, CurveUsdpConstants {
    constructor()
        public
        MetaPoolOldDepositorZap(
            DEPOSITOR,
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveUsdpConstants is INameIdentifier {
    string public constant override NAME = "curve-usdp";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x055be5DDB7A925BfEF3417FC157f53CA77cA7222);

    IMetaPool public constant META_POOL =
        IMetaPool(0x42d7025938bEc20B69cBae5A77421082407f053A);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0x3c8cAee4E09296800f8D29A68Fa3837e2dae4940);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveUsdpConstants} from "./Constants.sol";

contract CurveUsdpAllocation is MetaPoolAllocationBase, CurveUsdpConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "USDP", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardDistributor is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Recipient {
        uint256 nonce;
        address wallet;
        uint256 amount;
    }

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant RECIPIENT_TYPEHASH =
        keccak256("Recipient(uint256 nonce,address wallet,uint256 amount)");

    bytes32 private immutable DOMAIN_SEPARATOR;

    IERC20 public immutable apyToken;
    mapping(address => uint256) public accountNonces;
    address public signer;

    event SignerSet(address newSigner);
    event Claimed(uint256 nonce, address recipient, uint256 amount);

    constructor(IERC20 token, address signerAddress) public {
        require(address(token) != address(0), "Invalid APY Address");
        require(signerAddress != address(0), "Invalid Signer Address");
        apyToken = token;
        signer = signerAddress;

        DOMAIN_SEPARATOR = _hashDomain(
            EIP712Domain({
                name: "APY Distribution",
                version: "1",
                chainId: _getChainID(),
                verifyingContract: address(this)
            })
        );
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s // bytes calldata signature
    ) external {
        address signatureSigner = ecrecover(_hash(recipient), v, r, s);
        require(signatureSigner == signer, "Invalid Signature");

        require(
            recipient.nonce == accountNonces[recipient.wallet],
            "Nonce Mismatch"
        );
        require(
            apyToken.balanceOf(address(this)) >= recipient.amount,
            "Insufficient Funds"
        );

        accountNonces[recipient.wallet] += 1;
        apyToken.safeTransfer(recipient.wallet, recipient.amount);

        emit Claimed(recipient.nonce, recipient.wallet, recipient.amount);
    }

    function _hash(Recipient memory recipient) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    _hashRecipient(recipient)
                )
            );
    }

    function _getChainID() private pure returns (uint256) {
        uint256 id;
        // no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function _hashDomain(EIP712Domain memory eip712Domain)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function _hashRecipient(Recipient memory recipient)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    RECIPIENT_TYPEHASH,
                    recipient.nonce,
                    recipient.wallet,
                    recipient.amount
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract GovernanceTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        uint256 _totalSupply
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,uint256)",
                _proxyAdmin,
                _totalSupply
            )
        )
    {} // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";

import {NamedAddressSet} from "./NamedAddressSet.sol";

contract TestNamedAssetAllocationSet {
    using NamedAddressSet for NamedAddressSet.AssetAllocationSet;

    NamedAddressSet.AssetAllocationSet private _set;

    function add(IAssetAllocation allocation) external {
        _set.add(allocation);
    }

    function remove(string memory name) external {
        _set.remove(name);
    }

    function contains(IAssetAllocation allocation)
        external
        view
        returns (bool)
    {
        return _set.contains(allocation);
    }

    function length() external view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) external view returns (IAssetAllocation) {
        return _set.at(index);
    }

    function get(string memory name) external view returns (IAssetAllocation) {
        return _set.get(name);
    }

    function names() external view returns (string[] memory) {
        return _set.names();
    }
}

contract TestNamedZapSet {
    using NamedAddressSet for NamedAddressSet.ZapSet;

    NamedAddressSet.ZapSet private _set;

    function add(IZap zap) external {
        _set.add(zap);
    }

    function remove(string memory name) external {
        _set.remove(name);
    }

    function contains(IZap zap) external view returns (bool) {
        return _set.contains(zap);
    }

    function length() external view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) external view returns (IZap) {
        return _set.at(index);
    }

    function get(string memory name) external view returns (IZap) {
        return _set.get(name);
    }

    function names() external view returns (string[] memory) {
        return _set.names();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {PoolTokenV2} from "./PoolTokenV2.sol";

/**
 * @dev Proxy contract to test internal variables and functions
 * Should not be used other than in test files!
 */
contract TestPoolTokenV2 is PoolTokenV2 {
    function testMint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function testBurn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function testTransfer(
        address from,
        address to,
        uint256 amount
    ) public {
        testBurn(from, amount);
        testMint(to, amount);
    }

    function testGetDeployedValue() public view returns (uint256) {
        return _getDeployedValue();
    }

    function testGetPoolUnderlyerValue() public view returns (uint256) {
        return _getPoolUnderlyerValue();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IDetailedERC20, Ownable} from "contracts/common/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {AggregatorV3Interface} from "contracts/oracle/Imports.sol";
import {PoolTokenV2} from "contracts/pool/PoolTokenV2.sol";
import {LpAccount} from "contracts/lpaccount/LpAccount.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {AddressRegistryV2} from "contracts/registry/AddressRegistryV2.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy
} from "contracts/proxy/Imports.sol";
import {IAssetAllocationRegistry} from "contracts/tvl/Imports.sol";

import {DeploymentConstants} from "./constants.sol";
import {
    AddressRegistryV2Factory,
    Erc20AllocationFactory,
    LpAccountFactory,
    MetaPoolTokenFactory,
    OracleAdapterFactory,
    ProxyAdminFactory,
    PoolTokenV1Factory,
    PoolTokenV2Factory,
    TvlManagerFactory
} from "./factories.sol";
import {IGnosisModuleManager, Enum} from "./IGnosisModuleManager.sol";

/** @dev
# Alpha Deployment

## Deployment order of contracts

The address registry needs multiple addresses registered
to setup the roles for access control in the contract
constructors:

MetaPoolToken

- emergencySafe (emergency role, default admin role)
- lpSafe (LP role)

PoolTokenV2

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- mApt (contract role)

TvlManager

- emergencySafe (emergency role, default admin role)
- lpSafe (LP role)

LpAccount

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- lpSafe (LP role)

OracleAdapter

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- tvlManager (contract role)
- mApt (contract role)
- lpAccount (contract role)

Note the order of dependencies: a contract requires contracts
above it in the list to be deployed first. Thus we need
to deploy in the order given, starting with the Safes.

*/

/* solhint-disable max-states-count, func-name-mixedcase */
contract AlphaDeployment is Ownable, DeploymentConstants {
    // TODO: figure out a versioning scheme
    string public constant VERSION = "1.0.0";

    address private constant FAKE_AGG_ADDRESS =
        0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;

    IAddressRegistryV2 public addressRegistry;

    address public immutable proxyAdminFactory;
    address public immutable proxyFactory;
    address public immutable addressRegistryV2Factory;
    address public immutable mAptFactory;
    address public immutable poolTokenV1Factory;
    address public immutable poolTokenV2Factory;
    address public immutable tvlManagerFactory;
    address public immutable erc20AllocationFactory;
    address public immutable oracleAdapterFactory;
    address public immutable lpAccountFactory;

    uint256 public step;

    address public immutable emergencySafe;
    address public immutable adminSafe;
    address public immutable lpSafe;

    // step 0
    address public addressRegistryV2;

    // step 1
    address public mApt;

    // step 2
    address public poolTokenV2;

    // step 3
    address public daiDemoPool;
    address public usdcDemoPool;
    address public usdtDemoPool;

    // step 4
    address public tvlManager;
    address public erc20Allocation;

    // step 5
    address public oracleAdapter;

    // step 6
    address public lpAccount;

    modifier updateStep(uint256 step_) {
        require(step == step_, "INVALID_STEP");
        _;
        step += 1;
    }

    /**
     * @dev Uses `getAddress` in case `AddressRegistry` has not been upgraded
     */
    modifier checkSafeRegistrations() {
        require(
            addressRegistry.getAddress("emergencySafe") == emergencySafe,
            "INVALID_EMERGENCY_SAFE"
        );

        require(
            addressRegistry.getAddress("adminSafe") == adminSafe,
            "INVALID_ADMIN_SAFE"
        );

        require(
            addressRegistry.getAddress("lpSafe") == lpSafe,
            "INVALID_LP_SAFE"
        );

        _;
    }

    constructor(
        address proxyAdminFactory_,
        address proxyFactory_,
        address addressRegistryV2Factory_,
        address mAptFactory_,
        address poolTokenV1Factory_,
        address poolTokenV2Factory_,
        address tvlManagerFactory_,
        address erc20AllocationFactory_,
        address oracleAdapterFactory_,
        address lpAccountFactory_
    ) public {
        addressRegistry = IAddressRegistryV2(ADDRESS_REGISTRY_PROXY);

        // Simplest to check now that Safes are deployed in order to
        // avoid repeated preconditions checks later.
        emergencySafe = addressRegistry.getAddress("emergencySafe");
        adminSafe = addressRegistry.getAddress("adminSafe");
        lpSafe = addressRegistry.getAddress("lpSafe");

        proxyAdminFactory = proxyAdminFactory_;
        proxyFactory = proxyFactory_;
        addressRegistryV2Factory = addressRegistryV2Factory_;
        mAptFactory = mAptFactory_;
        poolTokenV1Factory = poolTokenV1Factory_;
        poolTokenV2Factory = poolTokenV2Factory_;
        tvlManagerFactory = tvlManagerFactory_;
        erc20AllocationFactory = erc20AllocationFactory_;
        oracleAdapterFactory = oracleAdapterFactory_;
        lpAccountFactory = lpAccountFactory_;
    }

    /**
     * @dev
     *   Check a contract address from a previous step's deployment
     *   is registered with expected ID.
     *
     * @param registeredIds identifiers for the Address Registry
     * @param deployedAddresses addresses from previous steps' deploys
     */
    function checkRegisteredDependencies(
        bytes32[] memory registeredIds,
        address[] memory deployedAddresses
    ) public view virtual {
        require(
            registeredIds.length == deployedAddresses.length,
            "LENGTH_MISMATCH"
        );

        for (uint256 i = 0; i < registeredIds.length; i++) {
            require(
                addressRegistry.getAddress(registeredIds[i]) ==
                    deployedAddresses[i],
                "MISSING_DEPLOYED_ADDRESS"
            );
        }
    }

    /**
     * @dev
     *   Check the deployment contract has ownership of necessary
     *   contracts to perform actions, e.g. register an address or upgrade
     *   a proxy.
     *
     * @param ownedContracts addresses that should be owned by this contract
     */
    function checkOwnerships(address[] memory ownedContracts)
        public
        view
        virtual
    {
        for (uint256 i = 0; i < ownedContracts.length; i++) {
            require(
                Ownable(ownedContracts[i]).owner() == adminSafe,
                "MISSING_OWNERSHIP"
            );
        }
    }

    function deploy_0_AddressRegistryV2_upgrade()
        external
        onlyOwner
        updateStep(0)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](2);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        ownerships[1] = ADDRESS_REGISTRY_PROXY_ADMIN;
        checkOwnerships(ownerships);

        addressRegistryV2 = AddressRegistryV2Factory(addressRegistryV2Factory)
            .create();
        bytes memory data =
            abi.encodeWithSelector(
                ProxyAdmin.upgrade.selector,
                ADDRESS_REGISTRY_PROXY,
                addressRegistryV2
            );

        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                ADDRESS_REGISTRY_PROXY_ADMIN,
                0, // value
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );

        // TODO: delete "poolManager" ID

        // Initialize logic storage to block possible attack vector:
        // attacker may control and selfdestruct the logic contract
        // if more powerful functionality is added later
        AddressRegistryV2(addressRegistryV2).initialize(
            ADDRESS_REGISTRY_PROXY_ADMIN
        );
    }

    /// @dev Deploy the mAPT proxy and its proxy admin.
    ///      Does not register any roles for contracts.
    function deploy_1_MetaPoolToken()
        external
        onlyOwner
        updateStep(1)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address proxyAdmin = ProxyAdminFactory(proxyAdminFactory).create();

        bytes memory initData =
            abi.encodeWithSelector(
                MetaPoolToken.initialize.selector,
                addressRegistry
            );

        mApt = MetaPoolTokenFactory(mAptFactory).create(
            proxyFactory,
            proxyAdmin,
            initData
        );

        _registerAddress("mApt", mApt);

        ProxyAdmin(proxyAdmin).transferOwnership(adminSafe);
    }

    function deploy_2_PoolTokenV2_logic() external onlyOwner updateStep(2) {
        poolTokenV2 = PoolTokenV2Factory(poolTokenV2Factory).create();

        // Initialize logic storage to block possible attack vector:
        // attacker may control and selfdestruct the logic contract
        // if more powerful functionality is added later
        PoolTokenV2(poolTokenV2).initialize(
            POOL_PROXY_ADMIN,
            IDetailedERC20(DAI_ADDRESS),
            AggregatorV3Interface(0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe)
        );
    }

    /// @dev complete proxy deploy for the demo pools
    ///      Registers mAPT for a contract role.
    function deploy_3_DemoPools()
        external
        onlyOwner
        updateStep(3)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](1);
        address[] memory deployedAddresses = new address[](1);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address proxyAdmin = ProxyAdminFactory(proxyAdminFactory).create();

        bytes memory initDataV2 =
            abi.encodeWithSelector(
                PoolTokenV2.initializeUpgrade.selector,
                address(addressRegistry)
            );

        daiDemoPool = _deployDemoPool(
            DAI_ADDRESS,
            "daiDemoPool",
            proxyAdmin,
            initDataV2
        );

        usdcDemoPool = _deployDemoPool(
            USDC_ADDRESS,
            "usdcDemoPool",
            proxyAdmin,
            initDataV2
        );

        usdtDemoPool = _deployDemoPool(
            USDT_ADDRESS,
            "usdtDemoPool",
            proxyAdmin,
            initDataV2
        );

        ProxyAdmin(proxyAdmin).transferOwnership(adminSafe);
    }

    /// @dev Deploy ERC20 allocation and TVL Manager.
    ///      Does not register any roles for contracts.
    function deploy_4_TvlManager()
        external
        onlyOwner
        updateStep(4)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        tvlManager = TvlManagerFactory(tvlManagerFactory).create(
            address(addressRegistry)
        );
        _registerAddress("tvlManager", tvlManager);

        erc20Allocation = Erc20AllocationFactory(erc20AllocationFactory).create(
            address(addressRegistry)
        );

        bytes memory data =
            abi.encodeWithSelector(
                IAssetAllocationRegistry.registerAssetAllocation.selector,
                erc20Allocation
            );
        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                tvlManager,
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    /// @dev register mAPT for a contract role
    function deploy_5_LpAccount()
        external
        onlyOwner
        updateStep(5)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](1);
        address[] memory deployedAddresses = new address[](1);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address proxyAdmin = ProxyAdminFactory(proxyAdminFactory).create();

        bytes memory initData =
            abi.encodeWithSelector(
                LpAccount.initialize.selector,
                address(addressRegistry)
            );

        lpAccount = LpAccountFactory(lpAccountFactory).create(
            proxyFactory,
            proxyAdmin,
            initData
        );

        _registerAddress("lpAccount", lpAccount);

        ProxyAdmin(proxyAdmin).transferOwnership(adminSafe);
    }

    /// @dev registers mAPT, TvlManager, LpAccount for contract roles
    function deploy_6_OracleAdapter()
        external
        onlyOwner
        updateStep(6)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](3);
        address[] memory deployedAddresses = new address[](3);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        (registeredIds[1], deployedAddresses[1]) = ("tvlManager", tvlManager);
        (registeredIds[2], deployedAddresses[2]) = ("lpAccount", lpAccount);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address[] memory assets = new address[](3);
        assets[0] = DAI_ADDRESS;
        assets[1] = USDC_ADDRESS;
        assets[2] = USDT_ADDRESS;

        address[] memory sources = new address[](3);
        sources[0] = DAI_USD_AGG_ADDRESS;
        sources[1] = USDC_USD_AGG_ADDRESS;
        sources[2] = USDT_USD_AGG_ADDRESS;

        uint256 aggStalePeriod = 86400;
        uint256 defaultLockPeriod = 270;

        oracleAdapter = OracleAdapterFactory(oracleAdapterFactory).create(
            address(addressRegistry),
            TVL_AGG_ADDRESS,
            assets,
            sources,
            aggStalePeriod,
            defaultLockPeriod
        );

        _registerAddress("oracleAdapter", oracleAdapter);
    }

    /// @notice upgrade from v1 to v2
    /// @dev register mAPT for a contract role
    function deploy_7_PoolTokenV2_upgrade()
        external
        onlyOwner
        updateStep(7)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](1);
        address[] memory deployedAddresses = new address[](1);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = POOL_PROXY_ADMIN;
        checkOwnerships(ownerships);

        bytes memory initData =
            abi.encodeWithSelector(
                PoolTokenV2.initializeUpgrade.selector,
                addressRegistry
            );

        _upgradePool(DAI_POOL_PROXY, POOL_PROXY_ADMIN, initData);
        _upgradePool(USDC_POOL_PROXY, POOL_PROXY_ADMIN, initData);
        _upgradePool(USDT_POOL_PROXY, POOL_PROXY_ADMIN, initData);
    }

    function _registerAddress(bytes32 id, address address_) internal {
        bytes memory data =
            abi.encodeWithSelector(
                AddressRegistryV2.registerAddress.selector,
                id,
                address_
            );

        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                address(addressRegistry),
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    function _deployDemoPool(
        address token,
        bytes32 id,
        address proxyAdmin,
        bytes memory initData
    ) internal returns (address) {
        bytes memory data =
            abi.encodeWithSelector(
                PoolTokenV2.initialize.selector,
                proxyAdmin,
                token,
                FAKE_AGG_ADDRESS
            );

        address proxy =
            PoolTokenV1Factory(poolTokenV1Factory).create(
                proxyFactory,
                proxyAdmin,
                data
            );

        ProxyAdmin(proxyAdmin).upgradeAndCall(
            TransparentUpgradeableProxy(payable(proxy)),
            poolTokenV2,
            initData
        );

        _registerAddress(id, proxy);

        return proxy;
    }

    function _upgradePool(
        address proxy,
        address proxyAdmin,
        bytes memory initData
    ) internal {
        bytes memory data =
            abi.encodeWithSelector(
                ProxyAdmin.upgradeAndCall.selector,
                TransparentUpgradeableProxy(payable(proxy)),
                poolTokenV2,
                initData
            );

        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                proxyAdmin,
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }
}
/* solhint-enable func-name-mixedcase */

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.11;

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
interface IGnosisModuleManager {
    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) external;

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns array of first 10 modules.
    /// @return Array of modules.
    function getModules() external view returns (address[] memory);
}

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {AlphaDeployment} from "./AlphaDeployment.sol";

contract TestAlphaDeployment is AlphaDeployment {
    constructor(
        address proxyAdminFactory_,
        address proxyFactory_,
        address addressRegistryV2Factory,
        address mAptFactory_,
        address poolTokenV1Factory_,
        address poolTokenV2Factory_,
        address tvlManagerFactory_,
        address erc20AllocationFactory_,
        address oracleAdapterFactory_,
        address lpAccountFactory_
    )
        public
        AlphaDeployment(
            proxyAdminFactory_,
            proxyFactory_,
            addressRegistryV2Factory,
            mAptFactory_,
            poolTokenV1Factory_,
            poolTokenV2Factory_,
            tvlManagerFactory_,
            erc20AllocationFactory_,
            oracleAdapterFactory_,
            lpAccountFactory_
        )
    {} // solhint-disable no-empty-blocks

    function testSetStep(uint256 step_) public {
        step = step_;
    }

    function testSetMapt(address mApt_) public {
        mApt = mApt_;
    }

    function testSetPoolTokenV2(address poolTokenV2_) public {
        poolTokenV2 = poolTokenV2_;
    }

    function testSetTvlManager(address tvlManager_) public {
        tvlManager = tvlManager_;
    }

    function testSetLpAccount(address lpAccount_) public {
        lpAccount = lpAccount_;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    CurveAllocationBase2
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveSaaveConstants} from "./Constants.sol";

contract CurveSaaveAllocation is
    CurveAllocationBase2,
    ImmutableAssetAllocation,
    CurveSaaveConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        // No unwrapping of aTokens are needed, as `balanceOf`
        // automagically reflects the accrued interest and
        // aTokens convert 1:1 to the underlyer.
        return
            super.getUnderlyerBalance(
                account,
                IStableSwap2(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](2);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "sUSD", 18);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    CTokenInterface,
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    CurveAllocationBase
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveIronBankConstants} from "./Constants.sol";

contract CurveIronBankAllocation is
    CurveAllocationBase,
    ImmutableAssetAllocation,
    CurveIronBankConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        uint256 cyBalance =
            super.getUnderlyerBalance(
                account,
                IStableSwap(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                uint256(tokenIndex)
            );
        return unwrapBalance(cyBalance, tokenIndex);
    }

    function unwrapBalance(uint256 balance, uint8 tokenIndex)
        public
        view
        returns (uint256)
    {
        IStableSwap pool = IStableSwap(STABLE_SWAP_ADDRESS);
        CTokenInterface cyToken = CTokenInterface(pool.coins(tokenIndex));
        return balance.mul(cyToken.exchangeRateStored());
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](3);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[2] = TokenData(USDT_ADDRESS, "USDT", 6);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveIronBankConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-ironbank";

    address public constant STABLE_SWAP_ADDRESS =
        0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF;
    address public constant LP_TOKEN_ADDRESS =
        0x5282a4eF67D9C33135340fB3289cc1711c13638C;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xF5194c3325202F456c95c1Cf0cA36f8475C1949F;

    address public constant CYDAI_ADDRESS =
        0x8e595470Ed749b85C6F7669de83EAe304C2ec68F;
    address public constant CYUSDC_ADDRESS =
        0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c;
    address public constant CYUSDT_ADDRESS =
        0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveIronBankConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract IronBankPoolZap is CurveGaugeZapBase, CurveIronBankConstants {
    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            3
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).underlying_coins(i);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2]],
            minAmount,
            true
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < N_COINS, "INVALID_INDEX");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount,
            true
        );
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    CTokenInterface,
    IOldStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    OldCurveAllocationBase2
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveCompoundConstants} from "./Constants.sol";

contract CurveCompoundAllocation is
    OldCurveAllocationBase2,
    ImmutableAssetAllocation,
    CurveCompoundConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        uint256 cyBalance =
            super.getUnderlyerBalance(
                account,
                IOldStableSwap2(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                tokenIndex
            );
        return unwrapBalance(cyBalance, tokenIndex);
    }

    function unwrapBalance(uint256 balance, uint8 tokenIndex)
        public
        view
        returns (uint256)
    {
        IOldStableSwap2 pool = IOldStableSwap2(STABLE_SWAP_ADDRESS);
        CTokenInterface cyToken = CTokenInterface(pool.coins(tokenIndex));
        return balance.mul(cyToken.exchangeRateStored());
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](2);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveCompoundConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-compound";

    address public constant STABLE_SWAP_ADDRESS =
        0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address public constant DEPOSIT_ZAP_ADDRESS =
        0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
    address public constant LP_TOKEN_ADDRESS =
        0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0x7ca5b0a2910B33e9759DC7dDB0413949071D7575;

    address public constant CDAI_ADDRESS =
        0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant CUSDC_ADDRESS =
        0x39AA39c021dfbaE8faC545936693aC917d5E7563;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {SafeERC20, SafeMath} from "contracts/libraries/Imports.sol";
import {
    IOldStableSwap2 as IStableSwap,
    IDepositZap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveCompoundConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract CompoundPoolZap is CurveGaugeZapBase, CurveCompoundConstants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor()
        public
        CurveGaugeZapBase(
            DEPOSIT_ZAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            2
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        address stableSwap = IDepositZap(SWAP_ADDRESS).curve();
        return IStableSwap(stableSwap).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IDepositZap(SWAP_ADDRESS).underlying_coins(int128(i));
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IDepositZap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        IERC20(LP_TOKEN_ADDRESS).safeApprove(SWAP_ADDRESS, 0);
        IERC20(LP_TOKEN_ADDRESS).safeApprove(SWAP_ADDRESS, lpBalance);
        IDepositZap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount
        );
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap3,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    CurveAllocationBase3
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveAaveConstants} from "./Constants.sol";

contract CurveAaveAllocation is
    CurveAllocationBase3,
    ImmutableAssetAllocation,
    CurveAaveConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        // No unwrapping of aTokens are needed, as `balanceOf`
        // automagically reflects the accrued interest and
        // aTokens convert 1:1 to the underlyer.
        return
            super.getUnderlyerBalance(
                account,
                IStableSwap3(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](3);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[2] = TokenData(USDT_ADDRESS, "USDT", 6);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveAaveConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-aave";

    address public constant STABLE_SWAP_ADDRESS =
        0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;
    address public constant LP_TOKEN_ADDRESS =
        0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xd662908ADA2Ea1916B3318327A97eB18aD588b5d;

    address public constant STKAAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant ADAI_ADDRESS =
        0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant AUSDC_ADDRESS =
        0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant AUSDT_ADDRESS =
        0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveAaveConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract AavePoolZap is CurveGaugeZapBase, CurveAaveConstants {
    string internal constant AAVE_ALLOCATION = "aave";

    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            3
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](2);
        allocationNames[0] = NAME;
        allocationNames[1] = AAVE_ALLOCATION;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).underlying_coins(i);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2]],
            minAmount,
            true
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 3, "INVALID_INDEX");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount,
            true
        );
    }

    /**
     * @dev claim protocol-specific rewards; stkAAVE in this case.
     *      CRV rewards are always claimed through the minter, in
     *      the `CurveBasePoolGauge` implementation.
     */
    function _claimRewards() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.claim_rewards();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {INameIdentifier, IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {ILendingPool, DataTypes} from "./common/interfaces/ILendingPool.sol";
import {AaveConstants} from "./Constants.sol";
import {AaveAllocationBase} from "./common/AaveAllocationBase.sol";

contract AaveStableCoinAllocation is
    AaveAllocationBase,
    ImmutableAssetAllocation,
    AaveConstants,
    ApyUnderlyerConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        override
        returns (uint256)
    {
        address underlyer = addressOf(tokenIndex);
        return
            super.getUnderlyerBalance(
                account,
                ILendingPool(LENDING_POOL_ADDRESS),
                underlyer
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](4);
        tokens[0] = TokenData(DAI_ADDRESS, DAI_SYMBOL, DAI_DECIMALS);
        tokens[1] = TokenData(USDC_ADDRESS, USDC_SYMBOL, USDC_DECIMALS);
        tokens[2] = TokenData(USDT_ADDRESS, USDT_SYMBOL, USDT_DECIMALS);
        tokens[3] = TokenData(SUSD_ADDRESS, SUSD_SYMBOL, SUSD_DECIMALS);
        return tokens;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

abstract contract ApyUnderlyerConstants {
    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    string public constant DAI_SYMBOL = "DAI";
    uint8 public constant DAI_DECIMALS = 18;

    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string public constant USDC_SYMBOL = "USDC";
    uint8 public constant USDC_DECIMALS = 6;

    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    string public constant USDT_SYMBOL = "USDT";
    uint8 public constant USDT_DECIMALS = 6;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {DataTypes} from "../DataTypes.sol";

/**
 * @notice the lending pool contract
 */
interface ILendingPool {
    /**
     * @notice Deposits a certain amount of an asset into the protocol, minting
     * the same amount of corresponding aTokens, and transferring them
     * to the onBehalfOf address.
     * E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @dev When depositing, the LendingPool contract must have at least an
     * allowance() of amount for the asset being deposited.
     * During testing, you can use the referral code: 0.
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     * wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     * is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     * 0 if the action is executed directly by the user, without any middle-man
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning
     * the equivalent aTokens owned.
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC,
     * burning the 100 aUSDC
     * @dev Ensure you set the relevant ERC20 allowance of the aToken,
     * before calling this function, so the LendingPool
     * contract can burn the associated aTokens.
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     * - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     * wants to receive it on his own wallet, or a different address if the beneficiary is a
     * different wallet
     * @return The final amount withdrawn
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract AaveConstants is INameIdentifier {
    string public constant override NAME = "aave";

    address public constant LENDING_POOL_ADDRESS =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    address public constant AAVE_ADDRESS =
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant STAKED_AAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    address public constant STAKED_INCENTIVES_CONTROLLER_ADDRESS =
        0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    address public constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    string public constant SUSD_SYMBOL = "sUSD";
    uint8 public constant SUSD_DECIMALS = 18;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";

import {
    ILendingPool,
    DataTypes
} from "contracts/protocols/aave/common/interfaces/ILendingPool.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

/**
 * @title Periphery Contract for the Aave lending pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of an Aave lending token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract AaveAllocationBase {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's aToken balance
     * @dev aTokens represent the underlyer amount at par (1-1), growing with interest.
     * @param underlyer address of the underlying asset of the aToken
     * @param pool Aave lending pool
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        ILendingPool pool,
        address underlyer
    ) public view returns (uint256) {
        require(account != address(0), "INVALID_ACCOUNT");
        require(address(pool) != address(0), "INVALID_POOL");
        require(underlyer != address(0), "INVALID_UNDERLYER");

        DataTypes.ReserveData memory reserve = pool.getReserveData(underlyer);
        address aToken = reserve.aTokenAddress;
        // No unwrapping of aTokens are needed, as `balanceOf`
        // automagically reflects the accrued interest and
        // aTokens convert 1:1 to the underlyer.
        return IERC20(aToken).balanceOf(account);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.11;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {AaveBasePool} from "./common/AaveBasePool.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

contract AaveUsdtZap is AaveBasePool, ApyUnderlyerConstants {
    constructor() public AaveBasePool(USDT_ADDRESS, LENDING_POOL_ADDRESS) {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IDetailedERC20,
    IERC20
} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {ILendingPool, DataTypes} from "./interfaces/ILendingPool.sol";
import {
    IAaveIncentivesController
} from "./interfaces/IAaveIncentivesController.sol";
import {AaveConstants} from "contracts/protocols/aave/Constants.sol";

abstract contract AaveBasePool is IZap, AaveConstants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal immutable UNDERLYER_ADDRESS;
    address internal immutable POOL_ADDRESS;

    // TODO: think about including the AToken address to conserve gas
    // TODO: consider using IDetailedERC20 as the type instead of address for underlyer

    constructor(address underlyerAddress, address lendingAddress) public {
        UNDERLYER_ADDRESS = underlyerAddress;
        POOL_ADDRESS = lendingAddress;
    }

    /// @param amounts array of underlyer amounts
    function deployLiquidity(uint256[] calldata amounts) external override {
        require(amounts.length == 1, "INVALID_AMOUNTS");
        IERC20(UNDERLYER_ADDRESS).safeApprove(POOL_ADDRESS, 0);
        IERC20(UNDERLYER_ADDRESS).safeApprove(POOL_ADDRESS, amounts[0]);
        _deposit(amounts[0]);
    }

    /// @param amount LP token amount
    function unwindLiquidity(uint256 amount, uint8 index) external override {
        require(index == 0, "INVALID_INDEX");
        _withdraw(amount);
    }

    function claim() external virtual override {
        IAaveIncentivesController controller =
            IAaveIncentivesController(STAKED_INCENTIVES_CONTROLLER_ADDRESS);
        address[] memory assets = new address[](1);
        assets[0] = _getATokenAddress(UNDERLYER_ADDRESS);
        uint256 amount = controller.getRewardsBalance(assets, address(this));
        controller.claimRewards(assets, amount, address(this));
    }

    function sortedSymbols() public view override returns (string[] memory) {
        // so we have to hardcode the number here
        string[] memory symbols = new string[](1);
        symbols[0] = IDetailedERC20(UNDERLYER_ADDRESS).symbol();
        return symbols;
    }

    function assetAllocations()
        public
        view
        virtual
        override
        returns (string[] memory)
    {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations()
        public
        view
        virtual
        override
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](1);
        allocations[0] = IERC20(UNDERLYER_ADDRESS);
        return allocations;
    }

    function _deposit(uint256 amount) internal virtual {
        ILendingPool(POOL_ADDRESS).deposit(
            UNDERLYER_ADDRESS,
            amount,
            address(this),
            0
        );
    }

    function _withdraw(uint256 lpBalance) internal virtual {
        ILendingPool(POOL_ADDRESS).withdraw(
            UNDERLYER_ADDRESS,
            lpBalance,
            address(this)
        );
    }

    function _getATokenAddress(address underlyerAddress)
        internal
        view
        returns (address)
    {
        DataTypes.ReserveData memory reserveData =
            ILendingPool(POOL_ADDRESS).getReserveData(underlyerAddress);
        return reserveData.aTokenAddress;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.11;

pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param assets addresses of the asset that accrue rewards, i.e. aTokens or debtTokens.
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets addresses of the asset that accrue rewards, i.e. aTokens or debtTokens.
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param assets addresses of the asset that accrue rewards, i.e. aTokens or debtTokens.
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {AaveBasePool} from "./common/AaveBasePool.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

contract AaveUsdcZap is AaveBasePool, ApyUnderlyerConstants {
    constructor() public AaveBasePool(USDC_ADDRESS, LENDING_POOL_ADDRESS) {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation, IERC20} from "contracts/common/Imports.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {IStakedAave} from "./common/interfaces/IStakedAave.sol";
import {AaveBasePool} from "./common/AaveBasePool.sol";

contract StakedAaveZap is AaveBasePool {
    event WithdrawSucceeded(uint256 amount);
    event CooldownFromWithdrawFail(uint256 timestamp);

    constructor()
        public
        AaveBasePool(
            AAVE_ADDRESS, // underlyer
            STAKED_AAVE_ADDRESS // "pool"
        )
    {} // solhint-disable-line no-empty-blocks

    // solhint-disable-next-line no-empty-blocks
    function claim() external virtual override {
        IStakedAave stkAave = IStakedAave(POOL_ADDRESS);
        uint256 amount = stkAave.getTotalRewardsBalance(address(this));
        stkAave.claimRewards(address(this), amount);
    }

    function assetAllocations() public view override returns (string[] memory) {
        return new string[](0);
    }

    /// @dev track only unstaked AAVE
    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](1);
        allocations[0] = IERC20(UNDERLYER_ADDRESS);
        return allocations;
    }

    function _deposit(uint256 amount) internal override {
        IStakedAave(POOL_ADDRESS).stake(address(this), amount);
    }

    function _withdraw(uint256 amount) internal override {
        IStakedAave stkAave = IStakedAave(POOL_ADDRESS);
        try stkAave.redeem(address(this), amount) {
            emit WithdrawSucceeded(amount);
        } catch Error(string memory reason) {
            if (
                keccak256(bytes(reason)) ==
                keccak256(bytes("UNSTAKE_WINDOW_FINISHED"))
            ) {
                // Either there's never been a cooldown or it expired
                // and the unstake window also finished.
                stkAave.cooldown();
                emit CooldownFromWithdrawFail(block.timestamp); // solhint-disable-line not-rely-on-time
            } else if (
                keccak256(bytes(reason)) ==
                keccak256(bytes("INSUFFICIENT_COOLDOWN"))
            ) {
                // Still within the cooldown period; this is expected to
                // happen often, so we single this case out for better
                // understanding and possible future refactoring.
                revert(reason);
            } else {
                revert(reason);
            }
        } catch (bytes memory) {
            revert("STKAAVE_UNKNOWN_REASON");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.11;

import {IDetailedERC20} from "contracts/common/Imports.sol";

interface IStakedAave is IDetailedERC20 {
    /**
     * Stakes `amount` of AAVE tokens, sending the stkAAVE to `to`
     * Note: the msg.sender must already have a balance of AAVE token.
     */
    function stake(address to, uint256 amount) external;

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param to Address to redeem to
     * @param amount Amount to redeem
     */
    function redeem(address to, uint256 amount) external;

    /**
     * @dev Activates the cooldown period to unstake
     * - It can't be called if the user is not staking
     */
    function cooldown() external;

    /**
     * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
     * @param to Address to stake for
     * @param amount Amount to stake
     */
    function claimRewards(address to, uint256 amount) external;

    /**
     * Returns the current minimum cool down time needed to
     * elapse before a staker is able to unstake their tokens.
     * As of October 2020, the current COOLDOWN_SECONDS value is
     * 864000 seconds (i.e. 10 days). This value should always
     * be checked directly from the contracts.
     */
    //solhint-disable-next-line func-name-mixedcase
    function COOLDOWN_SECONDS() external view returns (uint256);

    /**
     * Returns the maximum window of time in seconds that a staker can
     * redeem() their stake once a cooldown() period has been completed.
     * As of October 2020, the current UNSTAKE_WINDOW value is
     * 172800 seconds (i.e. 2 days). This value should always be checked
     * directly from the contracts.
     */
    //solhint-disable-next-line func-name-mixedcase
    function UNSTAKE_WINDOW() external view returns (uint256);

    /**
     * @notice Returns the total rewards that are pending to be claimed by a staker.
     * @param staker the staker's address
     */
    function getTotalRewardsBalance(address staker)
        external
        view
        returns (uint256);

    function stakersCooldowns(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {AaveBasePool} from "./common/AaveBasePool.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

contract AaveDaiZap is AaveBasePool, ApyUnderlyerConstants {
    constructor() public AaveBasePool(DAI_ADDRESS, LENDING_POOL_ADDRESS) {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";

import {AaveBasePool} from "./AaveBasePool.sol";

contract TestAaveZap is AaveBasePool {
    constructor(address underlyerAddress, address lendingAddress)
        public
        AaveBasePool(underlyerAddress, lendingAddress)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function getUnderlyerAddress() external view returns (address) {
        return UNDERLYER_ADDRESS;
    }

    function getLendingAddress() external view returns (address) {
        return POOL_ADDRESS;
    }

    function assetAllocations() public view override returns (string[] memory) {
        return new string[](0);
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](0);
        return allocations;
    }

    // solhint-disable-next-line no-empty-blocks
    function _deposit(uint256 amount) internal virtual override {}

    // solhint-disable-next-line no-empty-blocks
    function _withdraw(uint256 lpBalance) internal virtual override {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ImmutableAssetAllocation} from "./ImmutableAssetAllocation.sol";

contract TestImmutableAssetAllocation is ImmutableAssetAllocation {
    string public constant override NAME = "testAllocation";

    function testGetTokenData() external pure returns (TokenData[] memory) {
        return _getTokenData();
    }

    function balanceOf(address, uint8)
        external
        view
        override
        returns (uint256)
    {
        return 42;
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens_ = new TokenData[](2);
        tokens_[0] = TokenData(
            0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe,
            "CAFE",
            6
        );
        tokens_[1] = TokenData(
            0xBEeFbeefbEefbeEFbeEfbEEfBEeFbeEfBeEfBeef,
            "BEEF",
            8
        );
        return tokens_;
    }

    function _validateTokenAddress(address) internal view override {
        return;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    OwnableUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import {
    ERC20UpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract GovernanceToken is
    Initializable,
    OwnableUpgradeSafe,
    ERC20UpgradeSafe
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;

    /* ------------------------------- */

    event AdminChanged(address);

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    function initialize(address adminAddress, uint256 totalSupply)
        external
        initializer
    {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained("APY Governance Token", "APY");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);

        _mint(msg.sender, totalSupply);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {GovernanceToken} from "./GovernanceToken.sol";

contract GovernanceTokenUpgraded is GovernanceToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IAddressRegistry {
    function getIds() external view returns (bytes32[] memory);

    function getAddress(bytes32 id) external view returns (address);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveUsdnConstants} from "./Constants.sol";
import {
    MetaPoolOldDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract UsdnPoolZap is MetaPoolOldDepositorZap, CurveUsdnConstants {
    constructor()
        public
        MetaPoolOldDepositorZap(
            DEPOSITOR,
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveUsdnConstants is INameIdentifier {
    string public constant override NAME = "curve-usdn";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x674C6Ad92Fd080e4004b2312b45f796a192D27a0);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);

    IMetaPool public constant META_POOL =
        IMetaPool(0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0x094d12e5b541784701FD8d65F11fc0598FBC6332);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveUsdnConstants} from "./Constants.sol";

contract CurveUsdnAllocation is MetaPoolAllocationBase, CurveUsdnConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "USDN", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveMusdConstants} from "./Constants.sol";
import {
    MetaPoolOldDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract MusdPoolZap is MetaPoolOldDepositorZap, CurveMusdConstants {
    constructor()
        public
        MetaPoolOldDepositorZap(
            DEPOSITOR,
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveMusdConstants is INameIdentifier {
    string public constant override NAME = "curve-musd";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x1AEf73d49Dedc4b1778d0706583995958Dc862e6);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x5f626c30EC1215f4EdCc9982265E8b1F411D1352);

    IMetaPool public constant META_POOL =
        IMetaPool(0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0x803A2B40c5a9BB2B86DD630B274Fa2A9202874C2);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveMusdConstants} from "./Constants.sol";

contract CurveMusdAllocation is MetaPoolAllocationBase, CurveMusdConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "mUSD", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveLusdConstants} from "./Constants.sol";
import {
    MetaPoolDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract LusdPoolZap is MetaPoolDepositorZap, CurveLusdConstants {
    constructor()
        public
        MetaPoolDepositorZap(
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveLusdConstants is INameIdentifier {
    string public constant override NAME = "curve-lusd";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x9B8519A9a00100720CCdC8a120fBeD319cA47a14);

    IMetaPool public constant META_POOL =
        IMetaPool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveLusdConstants} from "./Constants.sol";

contract CurveLusdAllocation is MetaPoolAllocationBase, CurveLusdConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "LUSD", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveFraxConstants} from "./Constants.sol";
import {
    MetaPoolDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract FraxPoolZap is MetaPoolDepositorZap, CurveFraxConstants {
    constructor()
        public
        MetaPoolDepositorZap(
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(2);
        allocations[4] = FXS;
        allocations[5] = PRIMARY_UNDERLYER;
        return allocations;
    }

    /**
     * @dev claim protocol-specific rewards;
     *      CRV rewards are always claimed through the minter, in
     *      the `CurveGaugeZapBase` implementation.
     */
    function _claimRewards() internal override {
        LIQUIDITY_GAUGE.claim_rewards();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveFraxConstants is INameIdentifier {
    string public constant override NAME = "curve-frax";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);

    IERC20 public constant FXS =
        IERC20(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x72E158d38dbd50A483501c24f792bDAAA3e7D55C);

    IMetaPool public constant META_POOL =
        IMetaPool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveFraxConstants} from "./Constants.sol";

contract CurveFraxAllocation is MetaPoolAllocationBase, CurveFraxConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "FRAX", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveBusdV2Constants} from "./Constants.sol";
import {
    MetaPoolDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract BusdV2PoolZap is MetaPoolDepositorZap, CurveBusdV2Constants {
    constructor()
        public
        MetaPoolDepositorZap(
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveBusdV2Constants is INameIdentifier {
    string public constant override NAME = "curve-busdv2";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0xd4B22fEdcA85E684919955061fDf353b9d38389b);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);

    IMetaPool public constant META_POOL =
        IMetaPool(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveBusdV2Constants} from "./Constants.sol";

contract CurveBusdV2Allocation is MetaPoolAllocationBase, CurveBusdV2Constants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "BUSD", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {CurveAlUsdConstants} from "./Constants.sol";
import {
    MetaPoolDepositorZap
} from "contracts/protocols/curve/metapool/Imports.sol";

contract AlUsdPoolZap is MetaPoolDepositorZap, CurveAlUsdConstants {
    constructor()
        public
        MetaPoolDepositorZap(
            META_POOL,
            address(LP_TOKEN),
            address(LIQUIDITY_GAUGE),
            10000,
            100
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(2);
        allocations[4] = ALCX;
        allocations[5] = PRIMARY_UNDERLYER; // alUSD
        return allocations;
    }

    /**
     * @dev claim protocol-specific rewards;
     *      CRV rewards are always claimed through the minter, in
     *      the `CurveGaugeZapBase` implementation.
     */
    function _claimRewards() internal override {
        LIQUIDITY_GAUGE.claim_rewards();
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveAlUsdConstants is INameIdentifier {
    string public constant override NAME = "curve-alusd";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9);

    IERC20 public constant ALCX =
        IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x9582C4ADACB3BCE56Fea3e590F05c3ca2fb9C477);

    // The metapool StableSwap contract
    IMetaPool public constant META_POOL =
        IMetaPool(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveAlUsdConstants} from "./Constants.sol";

contract CurveAlUsdAllocation is MetaPoolAllocationBase, CurveAlUsdConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "alUSD", 18);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {Curve3PoolConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract Curve3PoolZap is CurveGaugeZapBase, Curve3PoolConstants {
    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            3
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        return _createErc20AllocationArray(0);
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).coins(i);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 3, "INVALID_INDEX");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount
        );
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    IERC20,
    INameIdentifier
} from "contracts/common/Imports.sol";
import {ISwap} from "./ISwap.sol";
import {TestLpAccountStorage} from "./TestLpAccountStorage.sol";

contract TestSwap is ISwap, TestLpAccountStorage {
    constructor(string memory name) public {
        _name = name;
    }

    function swap(uint256 amount, uint256) external override {
        _swapsArray.push(amount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view override returns (string memory) {
        return _name;
    }

    function erc20Allocations()
        external
        view
        override
        returns (IERC20[] memory)
    {
        return _tokens;
    }

    function _setErc20Allocations(IERC20[] memory tokens) public {
        _tokens = tokens;
    }
}