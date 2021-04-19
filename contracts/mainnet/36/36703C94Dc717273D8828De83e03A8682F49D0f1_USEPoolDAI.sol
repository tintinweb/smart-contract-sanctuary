/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

//SPDX-License-Identifier: MIT 
pragma solidity 0.6.11; 
pragma experimental ABIEncoderV2;

// ====================================================================
//     ________                   _______                           
//    / ____/ /__  ____  ____ _  / ____(_)___  ____ _____  ________ 
//   / __/ / / _ \/ __ \/ __ `/ / /_  / / __ \/ __ `/ __ \/ ___/ _ \
//  / /___/ /  __/ / / / /_/ / / __/ / / / / / /_/ / / / / /__/  __/
// /_____/_/\___/_/ /_/\__,_(_)_/   /_/_/ /_/\__,_/_/ /_/\___/\___/                                                                                                                     
//                                                                        
// ====================================================================
// ====================== Elena Protocol (USE) ========================
// ====================================================================

// Dapp    :  https://elena.finance
// Twitter :  https://twitter.com/ElenaProtocol
// Telegram:  https://t.me/ElenaFinance
// ====================================================================

// File: contracts\@openzeppelin\contracts\math\SafeMath.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\utils\EnumerableSet.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\utils\Address.sol
// License: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// File: contracts\@openzeppelin\contracts\GSN\Context.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\access\AccessControl.sol
// License: MIT




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

// File: contracts\Common\ContractGuard.sol
// License: MIT

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;
    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }
    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }
    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            'ContractGuard: one block, one function'
        );
        require(
            !checkSameSenderReentranted(),
            'ContractGuard: one block, one function'
        );
        _;
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// File: contracts\Common\IERC20Detail.sol
// License: MIT


interface IERC20Detail is IERC20 {
    function decimals() external view returns (uint8);
}

// File: contracts\Share\IShareToken.sol
// License: MIT



interface IShareToken is IERC20 {  
    function pool_mint(address m_address, uint256 m_amount) external; 
    function pool_burn_from(address b_address, uint256 b_amount) external; 
    function burn(uint256 amount) external;
}

// File: contracts\Oracle\IUniswapPairOracle.sol
// License: MIT

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
interface IUniswapPairOracle { 
    function getPairToken(address token) external view returns(address);
    function containsToken(address token) external view returns(bool);
    function getSwapTokenReserve(address token) external view returns(uint256);
    function update() external returns(bool);
    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}

// File: contracts\USE\IUSEStablecoin.sol
// License: MIT


interface IUSEStablecoin {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function owner_address() external returns (address);
    function creator_address() external returns (address);
    function timelock_address() external returns (address); 
    function genesis_supply() external returns (uint256); 
    function refresh_cooldown() external returns (uint256);
    function price_target() external returns (uint256);
    function price_band() external returns (uint256);
    function DEFAULT_ADMIN_ADDRESS() external returns (address);
    function COLLATERAL_RATIO_PAUSER() external returns (bytes32);
    function collateral_ratio_paused() external returns (bool);
    function last_call_time() external returns (uint256);
    function USEDAIOracle() external returns (IUniswapPairOracle);
    function USESharesOracle() external returns (IUniswapPairOracle); 
    /* ========== VIEWS ========== */
    function use_pools(address a) external view returns (bool);
    function global_collateral_ratio() external view returns (uint256);
    function use_price() external view returns (uint256);
    function share_price()  external view returns (uint256);
    function share_price_in_use()  external view returns (uint256); 
    function globalCollateralValue() external view returns (uint256);
    /* ========== PUBLIC FUNCTIONS ========== */
    function refreshCollateralRatio() external;
    function swapCollateralAmount() external view returns(uint256);
    function pool_mint(address m_address, uint256 m_amount) external;
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function burn(uint256 amount) external;
}

// File: contracts\USE\Pools\USEPoolAlgo.sol
// License: MIT



contract USEPoolAlgo {
    using SafeMath for uint256;
    // Constants for various precisions
    uint256 public constant PRICE_PRECISION = 1e6;
    uint256 public constant COLLATERAL_RATIO_PRECISION = 1e6;
    // ================ Structs ================
    // Needed to lower stack size
    struct MintFU_Params {
        uint256 shares_price_usd; 
        uint256 col_price_usd;
        uint256 shares_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }
    struct BuybackShares_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 shares_price_usd;
        uint256 col_price_usd;
        uint256 shares_amount;
    }
    // ================ Functions ================
    function calcMint1t1USE(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18.mul(col_price)).div(1e6);
    } 
    // Must be internal because of the struct
    function calcMintFractionalUSE(MintFU_Params memory params) public pure returns (uint256,uint256, uint256) {
          (uint256 mint_amount1, uint256 collateral_need_d18_1, uint256 shares_needed1) = calcMintFractionalWithCollateral(params);
          (uint256 mint_amount2, uint256 collateral_need_d18_2, uint256 shares_needed2) = calcMintFractionalWithShare(params);
          if(mint_amount1 > mint_amount2){
              return (mint_amount2,collateral_need_d18_2,shares_needed2);
          }else{
              return (mint_amount1,collateral_need_d18_1,shares_needed1);
          }
    }
    // Must be internal because of the struct
    function calcMintFractionalWithCollateral(MintFU_Params memory params) public pure returns (uint256,uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint USE. We do this by seeing the minimum mintable USE based on each amount 
        uint256 c_dollar_value_d18_with_precision = params.collateral_amount.mul(params.col_price_usd);
        uint256 c_dollar_value_d18 = c_dollar_value_d18_with_precision.div(1e6); 
        uint calculated_shares_dollar_value_d18 = 
                    (c_dollar_value_d18_with_precision.div(params.col_ratio))
                    .sub(c_dollar_value_d18);
        uint calculated_shares_needed = calculated_shares_dollar_value_d18.mul(1e6).div(params.shares_price_usd);
        return (
            c_dollar_value_d18.add(calculated_shares_dollar_value_d18),
            params.collateral_amount,
            calculated_shares_needed
        );
    }
     // Must be internal because of the struct
    function calcMintFractionalWithShare(MintFU_Params memory params) public pure returns (uint256,uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint USE. We do this by seeing the minimum mintable USE based on each amount 
        uint256 shares_dollar_value_d18_with_precision = params.shares_amount.mul(params.shares_price_usd);
        uint256 shares_dollar_value_d18 = shares_dollar_value_d18_with_precision.div(1e6); 
        uint calculated_collateral_dollar_value_d18 = 
                    shares_dollar_value_d18_with_precision.mul(params.col_ratio)
                    .div(COLLATERAL_RATIO_PRECISION.sub(params.col_ratio)).div(1e6); 
        uint calculated_collateral_needed = calculated_collateral_dollar_value_d18.mul(1e6).div(params.col_price_usd);
        return (
            shares_dollar_value_d18.add(calculated_collateral_dollar_value_d18),
            calculated_collateral_needed,
            params.shares_amount
        );
    }
    function calcRedeem1t1USE(uint256 col_price_usd, uint256 use_amount) public pure returns (uint256) {
        return use_amount.mul(1e6).div(col_price_usd);
    }
    // Must be internal because of the struct
    function calcBuyBackShares(BuybackShares_Params memory params) public pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible Shares with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");
        // Make sure not to take more than is available
        uint256 shares_dollar_value_d18 = params.shares_amount.mul(params.shares_price_usd).div(1e6);
        require(shares_dollar_value_d18 <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");
        // Get the equivalent amount of collateral based on the market value of Shares provided 
        uint256 collateral_equivalent_d18 = shares_dollar_value_d18.mul(1e6).div(params.col_price_usd);
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));
        return (
            collateral_equivalent_d18
        );
    }
    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = total_supply.mul(global_collateral_ratio).div(1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value.sub(global_collat_value); // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }
    function calcRecollateralizeUSEInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 frax_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = collateral_amount.mul(col_price).div(1e6);
        uint256 effective_collateral_ratio = global_collat_value.mul(1e6).div(frax_total_supply); //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio.mul(frax_total_supply).sub(frax_total_supply.mul(effective_collateral_ratio))).div(1e6);
        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }
        return (amount_to_recollat.mul(1e6).div(col_price), amount_to_recollat);
    }
}

// File: contracts\USE\Pools\USEPool.sol
// License: MIT

abstract contract USEPool is USEPoolAlgo,ContractGuard,AccessControl {
    using SafeMath for uint256;
    /* ========== STATE VARIABLES ========== */
    IERC20Detail public collateral_token;
    address public collateral_address;
    address public owner_address;
    address public community_address;
    address public use_contract_address;
    address public shares_contract_address;
    address public timelock_address;
    IShareToken private SHARE;
    IUSEStablecoin private USE; 
    uint256 public minting_tax_base;
    uint256 public minting_tax_multiplier; 
    uint256 public minting_required_reserve_ratio;
    uint256 public redemption_gcr_adj = PRECISION;   // PRECISION/PRECISION = 1
    uint256 public redemption_tax_base;
    uint256 public redemption_tax_multiplier;
    uint256 public redemption_tax_exponent;
    uint256 public redemption_required_reserve_ratio = 800000;
    uint256 public buyback_tax;
    uint256 public recollat_tax;
    uint256 public community_rate_ratio = 15000;
    uint256 public community_rate_in_use;
    uint256 public community_rate_in_share;
    mapping (address => uint256) public redeemSharesBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolShares;
    mapping (address => uint256) public lastRedeemed;
    // Constants for various precisions
    uint256 public constant PRECISION = 1e6;  
    uint256 public constant RESERVE_RATIO_PRECISION = 1e6;    
    uint256 public constant COLLATERAL_RATIO_MAX = 1e6;
    // Number of decimals needed to get to 18
    uint256 public immutable missing_decimals;
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pool_ceiling = 10000000000e18;
    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;
    // Bonus rate on Shares minted during recollateralizeUSE(); 6 decimals of precision, set to 0.5% on genesis
    uint256 public bonus_rate = 5000;
    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 2;
    uint256 public global_use_supply_adj = 1000e18;  //genesis_supply
    // AccessControl Roles
    bytes32 public constant MINT_PAUSER = keccak256("MINT_PAUSER");
    bytes32 public constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    bytes32 public constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    bytes32 public constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 public constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    bytes32 public constant COMMUNITY_RATER = keccak256("COMMUNITY_RATER");
    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;
    event UpdateOracleBonus(address indexed user,bool bonus1, bool bonus2);
    /* ========== MODIFIERS ========== */
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
        _;
    }
    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        require(redemptionOpened() == true,"Redeeming is closed");
        _;
    }
    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        require(mintingOpened() == true,"Minting is closed");
        _;
    }
    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _use_contract_address,
        address _shares_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        address _community_address
    ) public {
        USE = IUSEStablecoin(_use_contract_address);
        SHARE = IShareToken(_shares_contract_address);
        use_contract_address = _use_contract_address;
        shares_contract_address = _shares_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        community_address = _community_address;
        collateral_token = IERC20Detail(_collateral_address); 
        missing_decimals = uint(18).sub(collateral_token.decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MINT_PAUSER, timelock_address);
        grantRole(REDEEM_PAUSER, timelock_address);
        grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
        grantRole(BUYBACK_PAUSER, timelock_address);
        grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
        grantRole(COMMUNITY_RATER, _community_address);
    }
    /* ========== VIEWS ========== */
    // Returns dollar value of collateral held in this USE pool
    function collatDollarBalance() public view returns (uint256) {
        uint256 collateral_amount = collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral);
        uint256 collat_usd_price = collateralPricePaused == true ? pausedPrice : getCollateralPrice();
        return collateral_amount.mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); 
    }
    // Returns the value of excess collateral held in this USE pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {      
        uint256 total_supply = USE.totalSupply().sub(global_use_supply_adj);       
        uint256 global_collat_value = USE.globalCollateralValue();
        uint256 global_collateral_ratio = USE.global_collateral_ratio();
        // Handles an overcollateralized contract with CR > 1
        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) {
            global_collateral_ratio = COLLATERAL_RATIO_PRECISION; 
        }
        // Calculates collateral needed to back each 1 USE with $1 of collateral at current collat ratio
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION);
        if (global_collat_value > required_collat_dollar_value_d18) {
           return global_collat_value.sub(required_collat_dollar_value_d18);
        }
        return 0;
    }
    /* ========== PUBLIC FUNCTIONS ========== */ 
    function getCollateralPrice() public view virtual returns (uint256);
    function getCollateralAmount()   public view  returns (uint256){
        return collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral);
    }
    function requiredReserveRatio() public view returns(uint256){
        uint256 pool_collateral_amount = getCollateralAmount();
        uint256 swap_collateral_amount = USE.swapCollateralAmount();
        require(swap_collateral_amount>0,"swap collateral is empty?");
        return pool_collateral_amount.mul(RESERVE_RATIO_PRECISION).div(swap_collateral_amount);
    }
    function mintingOpened() public view returns(bool){ 
        return  (requiredReserveRatio() >= minting_required_reserve_ratio);
    }
    function redemptionOpened() public view returns(bool){
        return  (requiredReserveRatio() >= redemption_required_reserve_ratio);
    }
    //
    function mintingTax() public view returns(uint256){
        uint256 _dynamicTax =  minting_tax_multiplier.mul(requiredReserveRatio()).div(RESERVE_RATIO_PRECISION); 
        return  minting_tax_base + _dynamicTax;       
    }
    function dynamicRedemptionTax(uint256 ratio,uint256 multiplier,uint256 exponent) public pure returns(uint256){        
        return multiplier.mul(RESERVE_RATIO_PRECISION**exponent).div(ratio**exponent);
    }
    //
    function redemptionTax() public view returns(uint256){
        uint256 _dynamicTax =dynamicRedemptionTax(requiredReserveRatio(),redemption_tax_multiplier,redemption_tax_exponent);
        return  redemption_tax_base + _dynamicTax;       
    } 
    function updateOraclePrice() public { 
        IUniswapPairOracle _useDaiOracle = USE.USEDAIOracle();
        IUniswapPairOracle _useSharesOracle = USE.USESharesOracle();
        bool _bonus1 = _useDaiOracle.update();
        bool _bonus2 = _useSharesOracle.update(); 
        if(_bonus1 || _bonus2){
            emit UpdateOracleBonus(msg.sender,_bonus1,_bonus2);
        }
    }
    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1USE(uint256 collateral_amount, uint256 use_out_min) external onlyOneBlock notMintPaused { 
        updateOraclePrice();       
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        require(USE.global_collateral_ratio() >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require(getCollateralAmount().add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        (uint256 use_amount_d18) = calcMint1t1USE(
            getCollateralPrice(),
            collateral_amount_d18
        ); //1 USE for each $1 worth of collateral
        community_rate_in_use  =  community_rate_in_use.add(use_amount_d18.mul(community_rate_ratio).div(PRECISION));
        use_amount_d18 = (use_amount_d18.mul(uint(1e6).sub(mintingTax()))).div(1e6); //remove precision at the end
        require(use_out_min <= use_amount_d18, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        USE.pool_mint(msg.sender, use_amount_d18);  
    }
    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalUSE(uint256 collateral_amount, uint256 shares_amount, uint256 use_out_min) external onlyOneBlock notMintPaused {
        updateOraclePrice();
        uint256 share_price = USE.share_price();
        uint256 global_collateral_ratio = USE.global_collateral_ratio();
        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(getCollateralAmount().add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more USE can be minted with this collateral");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        MintFU_Params memory input_params = MintFU_Params(
            share_price,
            getCollateralPrice(),
            shares_amount,
            collateral_amount_d18,
            global_collateral_ratio
        );
        (uint256 mint_amount,uint256 collateral_need_d18, uint256 shares_needed) = calcMintFractionalUSE(input_params);
        community_rate_in_use  =  community_rate_in_use.add(mint_amount.mul(community_rate_ratio).div(PRECISION));
        mint_amount = (mint_amount.mul(uint(1e6).sub(mintingTax()))).div(1e6);
        require(use_out_min <= mint_amount, "Slippage limit reached");
        require(shares_needed <= shares_amount, "Not enough Shares inputted");
        uint256 collateral_need = collateral_need_d18.div(10 ** missing_decimals);
        SHARE.pool_burn_from(msg.sender, shares_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_need);
        USE.pool_mint(msg.sender, mint_amount);      
    }
    // Redeem collateral. 100% collateral-backed
    function redeem1t1USE(uint256 use_amount, uint256 COLLATERAL_out_min) external onlyOneBlock notRedeemPaused {
        updateOraclePrice();
        require(USE.global_collateral_ratio() == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");
        // Need to adjust for decimals of collateral
        uint256 use_amount_precision = use_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = calcRedeem1t1USE(
            getCollateralPrice(),
            use_amount_precision
        );
        community_rate_in_use  =  community_rate_in_use.add(use_amount.mul(community_rate_ratio).div(PRECISION));
        collateral_needed = (collateral_needed.mul(uint(1e6).sub(redemptionTax()))).div(1e6);
        require(collateral_needed <= getCollateralAmount(), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
        lastRedeemed[msg.sender] = block.number;
        // Move all external functions to the end
        USE.pool_burn_from(msg.sender, use_amount); 
        require(redemptionOpened() == true,"Redeem amount too large !");
    }
    // Will fail if fully collateralized or algorithmic
    // Redeem USE for collateral and SHARE. > 0% and < 100% collateral-backed
    function redeemFractionalUSE(uint256 use_amount, uint256 shares_out_min, uint256 COLLATERAL_out_min) external onlyOneBlock notRedeemPaused {
        updateOraclePrice();
        uint256 global_collateral_ratio = USE.global_collateral_ratio();
        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        global_collateral_ratio = global_collateral_ratio.mul(redemption_gcr_adj).div(PRECISION);
        uint256 use_amount_post_tax = (use_amount.mul(uint(1e6).sub(redemptionTax()))).div(PRICE_PRECISION);
        uint256 shares_dollar_value_d18 = use_amount_post_tax.sub(use_amount_post_tax.mul(global_collateral_ratio).div(PRICE_PRECISION));
        uint256 shares_amount = shares_dollar_value_d18.mul(PRICE_PRECISION).div(USE.share_price());
        // Need to adjust for decimals of collateral
        uint256 use_amount_precision = use_amount_post_tax.div(10 ** missing_decimals);
        uint256 collateral_dollar_value = use_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
        uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(getCollateralPrice());
        require(collateral_amount <= getCollateralAmount(), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(shares_out_min <= shares_amount, "Slippage limit reached [Shares]");
        community_rate_in_use  =  community_rate_in_use.add(use_amount.mul(community_rate_ratio).div(PRECISION));
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);
        redeemSharesBalances[msg.sender] = redeemSharesBalances[msg.sender].add(shares_amount);
        unclaimedPoolShares = unclaimedPoolShares.add(shares_amount);
        lastRedeemed[msg.sender] = block.number;
        // Move all external functions to the end
        USE.pool_burn_from(msg.sender, use_amount);
        SHARE.pool_mint(address(this), shares_amount);
        require(redemptionOpened() == true,"Redeem amount too large !");
    }
    // After a redemption happens, transfer the newly minted Shares and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out USE/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external onlyOneBlock{        
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendShares = false;
        bool sendCollateral = false;
        uint sharesAmount;
        uint CollateralAmount;
        // Use Checks-Effects-Interactions pattern
        if(redeemSharesBalances[msg.sender] > 0){
            sharesAmount = redeemSharesBalances[msg.sender];
            redeemSharesBalances[msg.sender] = 0;
            unclaimedPoolShares = unclaimedPoolShares.sub(sharesAmount);
            sendShares = true;
        }
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);
            sendCollateral = true;
        }
        if(sendShares == true){
            SHARE.transfer(msg.sender, sharesAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
    }
    // When the protocol is recollateralizing, we need to give a discount of Shares to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get Shares for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of Shares + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra Shares value from the bonus rate as an arb opportunity
    function recollateralizeUSE(uint256 collateral_amount, uint256 shares_out_min) external onlyOneBlock {
        require(recollateralizePaused == false, "Recollateralize is paused");
        updateOraclePrice();
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 share_price = USE.share_price();
        uint256 use_total_supply = USE.totalSupply().sub(global_use_supply_adj);
        uint256 global_collateral_ratio = USE.global_collateral_ratio();
        uint256 global_collat_value = USE.globalCollateralValue();
        (uint256 collateral_units, uint256 amount_to_recollat) = calcRecollateralizeUSEInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            use_total_supply,
            global_collateral_ratio
        ); 
        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);
        uint256 shares_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate).sub(recollat_tax)).div(share_price);
        require(shares_out_min <= shares_paid_back, "Slippage limit reached");
        community_rate_in_share =  community_rate_in_share.add(shares_paid_back.mul(community_rate_ratio).div(PRECISION));
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        SHARE.pool_mint(msg.sender, shares_paid_back);
    }
    // Function can be called by an Shares holder to have the protocol buy back Shares with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackShares(uint256 shares_amount, uint256 COLLATERAL_out_min) external onlyOneBlock {
        require(buyBackPaused == false, "Buyback is paused");
        updateOraclePrice();
        uint256 share_price = USE.share_price();
        BuybackShares_Params memory input_params = BuybackShares_Params(
            availableExcessCollatDV(),
            share_price,
            getCollateralPrice(),
            shares_amount
        );
        (uint256 collateral_equivalent_d18) = (calcBuyBackShares(input_params)).mul(uint(1e6).sub(buyback_tax)).div(1e6);
        uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);
        require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
        community_rate_in_share  =  community_rate_in_share.add(shares_amount.mul(community_rate_ratio).div(PRECISION));
        // Give the sender their desired collateral and burn the Shares
        SHARE.pool_burn_from(msg.sender, shares_amount);
        collateral_token.transfer(msg.sender, collateral_precision);
    }
    /* ========== RESTRICTED FUNCTIONS ========== */
    function toggleMinting() external {
        require(hasRole(MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }
    function toggleRedeeming() external {
        require(hasRole(REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }
    function toggleRecollateralize() external {
        require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }
    function toggleBuyBack() external {
        require(hasRole(BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
    }
    function toggleCollateralPrice(uint256 _new_price) external {
        require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = _new_price;
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;
    }
    function toggleCommunityInSharesRate(uint256 _rate) external{
        require(community_rate_in_share>0,"No SHARE rate");
        require(hasRole(COMMUNITY_RATER, msg.sender));
        uint256 _amount_rate = community_rate_in_share.mul(_rate).div(PRECISION);
        community_rate_in_share = community_rate_in_share.sub(_amount_rate);
        SHARE.pool_mint(msg.sender,_amount_rate);  
    }
    function toggleCommunityInUSERate(uint256 _rate) external{
        require(community_rate_in_use>0,"No USE rate");
        require(hasRole(COMMUNITY_RATER, msg.sender));
        uint256 _amount_rate_use = community_rate_in_use.mul(_rate).div(PRECISION);        
        community_rate_in_use = community_rate_in_use.sub(_amount_rate_use);
        uint256 _share_price_use = USE.share_price_in_use();
        uint256 _amount_rate = _amount_rate_use.mul(PRICE_PRECISION).div(_share_price_use);
        SHARE.pool_mint(msg.sender,_amount_rate);  
    }
    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_ceiling, 
                               uint256 new_bonus_rate, 
                               uint256 new_redemption_delay, 
                               uint256 new_buyback_tax, 
                               uint256 new_recollat_tax,
                               uint256 use_supply_adj) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay; 
        buyback_tax = new_buyback_tax;
        recollat_tax = new_recollat_tax;
        global_use_supply_adj = use_supply_adj;
    }
    function setMintingParameters(uint256 _ratioLevel,
                                  uint256 _tax_base,
                                  uint256 _tax_multiplier) external onlyByOwnerOrGovernance{
        minting_required_reserve_ratio = _ratioLevel;
        minting_tax_base = _tax_base;
        minting_tax_multiplier = _tax_multiplier;
    }
    function setRedemptionParameters(uint256 _ratioLevel,
                                     uint256 _tax_base,
                                     uint256 _tax_multiplier,
                                     uint256 _tax_exponent,
                                     uint256 _redeem_gcr_adj) external onlyByOwnerOrGovernance{
        redemption_required_reserve_ratio = _ratioLevel;
        redemption_tax_base = _tax_base;
        redemption_tax_multiplier = _tax_multiplier;
        redemption_tax_exponent = _tax_exponent;
        redemption_gcr_adj = _redeem_gcr_adj;
    }
    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }
    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }
    function setCommunityParameters(address _community_address,uint256 _ratio) external onlyByOwnerOrGovernance {
        community_address = _community_address;
        community_rate_ratio = _ratio;
    } 
    /* ========== EVENTS ========== */
}

// File: contracts\USE\Pools\USEPoolDAI.sol
// License: MIT

contract USEPoolDAI is USEPool {
    address public DAI_address;
    constructor(
        address _use_contract_address,
        address _shares_contract_address,
        address _collateral_address,
        address _creator_address, 
        address _timelock_address,
        address _community_address
    ) 
    USEPool(_use_contract_address, _shares_contract_address, _collateral_address, _creator_address, _timelock_address,_community_address)
    public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DAI_address = _collateral_address;
    }
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view override returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else { 
            //Only For Dai
            return 1 * PRICE_PRECISION; 
        }
    } 
}