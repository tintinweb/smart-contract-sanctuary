// SPDX-License-Identifier: (Apache-2.0 AND MIT AND BSD-4-Clause)
//------------------------------------------------------------------------------
//
//   Copyright 2020 Fetch.AI Limited
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//------------------------------------------------------------------------------

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
//------------------------------------------------------------------------------
//
//   Copyright 2020 Fetch.AI Limited
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//------------------------------------------------------------------------------


/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
}
//------------------------------------------------------------------------------
//
//   Copyright 2020 Fetch.AI Limited
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//------------------------------------------------------------------------------




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


library AssetLib {
    using SafeMath for uint256;


    struct Asset {
        uint256 principal;
        uint256 compoundInterest;
    }


    function composite(Asset storage asset)
        internal view returns(uint256)
    {
        return asset.principal.add(asset.compoundInterest);
    }


    function compositeM(Asset memory asset)
        internal pure returns(uint256)
    {
        return asset.principal.add(asset.compoundInterest);
    }


    function imAddS(Asset memory to, Asset storage amount)
        internal view
    {
        to.principal = to.principal.add(amount.principal);
        to.compoundInterest = to.compoundInterest.add(amount.compoundInterest);
    }


    function iAdd(Asset storage to, Asset memory amount)
        internal
    {
        to.principal = to.principal.add(amount.principal);
        to.compoundInterest = to.compoundInterest.add(amount.compoundInterest);
    }


    function imSubM(Asset memory from, Asset storage amount)
        internal view
    {
        from.principal = from.principal.sub(amount.principal);
        from.compoundInterest = from.compoundInterest.sub(amount.compoundInterest);
    }


    function iSub(Asset storage from, Asset memory amount)
        internal
    {
        from.principal = from.principal.sub(amount.principal);
        from.compoundInterest = from.compoundInterest.sub(amount.compoundInterest);
    }


    function iSubPrincipalFirst(Asset storage from, uint256 amount)
        internal returns(Asset memory _amount)
    {
        if (from.principal >= amount) {
            from.principal = from.principal.sub(amount);
            _amount.principal = amount;
        } else {
           _amount.compoundInterest = amount.sub(from.principal);
            // NOTE(pb): Fail as soon as possible (even though this ordering of lines makes code less readable):
            from.compoundInterest = from.compoundInterest.sub(_amount.compoundInterest);

            _amount.principal = from.principal;
            from.principal = 0;
        }
    }


    function iSubCompoundInterestFirst(Asset storage from, uint256 amount)
        internal returns(Asset memory _amount)
    {
        if (from.compoundInterest >= amount) {
            from.compoundInterest = from.compoundInterest.sub(amount);
            _amount.compoundInterest = amount;
        } else {
            _amount.principal = amount.sub(from.compoundInterest);
            // NOTE(pb): Fail as soon as possible (even though this ordering of lines makes code less readable):
            from.principal = from.principal.sub(_amount.principal);

            _amount.compoundInterest = from.compoundInterest;
            from.compoundInterest = 0;
        }
    }

    // NOTE(pb): This is a little bit more expensive version of the commented-out function bellow,
    //           but it avoids copying the code by reusing (calling existing functions), and so
    //           making code more reliable and readable.
    function iRelocatePrincipalFirst(Asset storage from, Asset storage to, uint256 amount)
        internal returns(Asset memory _amount)
    {
        _amount = iSubPrincipalFirst(from, amount);
        iAdd(to, _amount);
    }

    // NOTE(pb): This is a little bit more expensive version of the commented-out function bellow,
    //           but it avoids copying the code by reusing (calling existing functions), and so
    //           making code more reliable and readable.
    function iRelocateCompoundInterestFirst(Asset storage from, Asset storage to, uint256 amount)
        internal returns(Asset memory _amount)
    {
        _amount = iSubCompoundInterestFirst(from, amount);
        iAdd(to, _amount);
    }

    ////NOTE(pb): Whole Commented out code block bellow consumes less gas then variant above, however for the price
    ////          of copy code which can be rather called (see notes in the commented out code):
    //function iRelocatePrincipalFirst(Asset storage from, Asset storage to, uint256 amount)
    //    internal pure returns(Asset memory _amount)
    //{
    //    if (from.principal >= amount) {
    //        from.principal = from.principal.sub(amount);
    //        to.principal = to.principal.add(amount);
    //        // NOTE(pb): Line bellow is enough - no necessity to call subtract for compound as it is called in
    //        //           uncommented variant of this function above.
    //        _amount.principal = amount;
    //    } else {
    //        _amount.compoundInterest = amount.sub(from.principal);
    //        // NOTE(pb): Fail as soon as possible (even though this ordering of lines makes code less readable):
    //        from.compoundInterest = from.compoundInterest.sub(_amount.compoundInterest);
    //        to.compoundInterest = to.compoundInterest.add(_amount.compoundInterest);
    //        to.principal = to.principal.add(from.principal);

    //        _amount.principal = from.principal;
    //        // NOTE(pb): Line bellow is enough - no necessity to call subtract for principal as it is called in
    //        //           uncommented variant of this function above.
    //         from.principal = 0;
    //     }
    //}


    //function iRelocateCompoundInterestFirst(Asset storage from, Asset storage to, uint256 amount)
    //    internal pure returns(Asset memory _amount)
    //{
    //    if (from.compoundInterest >= amount) {
    //        from.compoundInterest = from.compoundInterest.sub(amount);
    //        to.compoundInterest = to.compoundInterest.add(amount);
    //        // NOTE(pb): Line bellow is enough - no necessity to call subtract for principal as it is called in
    //        //           uncommented variant of this function above.
    //        _amount.compoundInterest = amount;
    //    } else {
    //        _amount.principal = amount.sub(from.compoundInterest);
    //        // NOTE(pb): Fail as soon as possible (even though this ordering of lines makes code less readable):
    //        from.principal = from.principal.sub(_amount.principal);
    //        to.principal = to.principal.add(_amount.principal);
    //        to.compoundInterest = to.compoundInterest.add(from.compoundInterest);

    //        _amount.compoundInterest = from.compoundInterest;
    //        // NOTE(pb): Line bellow is enough - no necessity to call subtract for compound as it is called in
    //        //           uncommented variant of this function above.
    //         from.compoundInterest = 0;
    //    }
    //}
}


library Finance {
    using SafeMath for uint256;
    using AssetLib for AssetLib.Asset;


    function pow (int128 x, uint256 n)
        internal pure returns (int128 r)
    {
        r = ABDKMath64x64.fromUInt (1);

        while (n != 0) {
            if ((n & 1) != 0) {
                r = ABDKMath64x64.mul (r, x);
                n -= 1;
            } else {
                x = ABDKMath64x64.mul (x, x);
                n >>= 1;
            }
        }
    }


    function compoundInterest (uint256 principal, uint256 ratio, uint256 n)
        internal pure returns (uint256)
    {
        return ABDKMath64x64.mulu (
            pow (
                ABDKMath64x64.add (
                    ABDKMath64x64.fromUInt (1),
                    ABDKMath64x64.divu (
                          ratio,
                          10**18)
                    ),
                    n
                ),
            principal);
    }


    function compoundInterest (uint256 principal, int256 ratio, uint256 n)
        internal pure returns (uint256)
    {
        return ABDKMath64x64.mulu (
            pow (
                ABDKMath64x64.add (
                    ABDKMath64x64.fromUInt (1),
                    ABDKMath64x64.divi (
                          ratio,
                          10**18)
                    ),
                    n
                ),
            principal);
    }


    function compoundInterest (AssetLib.Asset storage asset, uint256 interest, uint256 n)
        internal
    {
        uint256 composite = asset.composite();
        composite = compoundInterest(composite, interest, n);

        asset.compoundInterest = composite.sub(asset.principal);
    }
}


// [Canonical ERC20-FET] = 10**(-18)x[ECR20-FET]
contract Staking is AccessControl {
    using SafeMath for uint256;
    using AssetLib for AssetLib.Asset;

    struct InterestRatePerBlock {
        uint256 sinceBlock;
        // NOTE(pb): To simplify, interest rate value can *not* be negative
        uint256 rate; // Signed interest rate in [10**18] units => real_rate = rate / 10**18.
        //// Number of users who bound stake while this particular interest rate was still in effect.
        //// This enables to identify when we can delete interest rates which are no more used by anyone
        //// (continuously from the beginning).
        //uint256 numberOfRegisteredUsers;
    }

    struct Stake {
        uint256 sinceBlock;
        uint256 sinceInterestRateIndex;
        AssetLib.Asset asset;
    }

    struct LockedAsset {
        uint256 liquidSinceBlock;
        AssetLib.Asset asset;
    }

    struct Locked {
        AssetLib.Asset aggregate;
        LockedAsset[] assets;
    }

    // *******    EVENTS    ********
    event BindStake(
          address indexed stakerAddress
        , uint256 indexed sinceInterestRateIndex
        , uint256 principal
        , uint256 compoundInterest
    );

    /**
     * @dev This event is triggered exclusivelly to recalculate the compount interest of ALREADY staked asset
     *      for the poriod since it was calculated the last time. This means this event does *NOT* include *YET*
     *      any added (resp. removed) asset user is currently binding (resp. unbinding).
     *      The main motivation for this event is to give listener opportunity to get feedback what is the 
     *      user's staked asset value with compound interrest recalculated to *CURRENT* block *BEFORE* user's
     *      action (binding resp. unbinding) affects user's staked asset value.
     */
    event StakeCompoundInterest(
          address indexed stakerAddress
        , uint256 indexed sinceInterestRateIndex
        , uint256 principal // = previous_principal
        , uint256 compoundInterest // = previous_principal * (pow(1+interest, _getBlockNumber()-since_block) - 1)
    );

    event LiquidityDeposited(
          address indexed stakerAddress
        , uint256 amount
    );

    event LiquidityUnlocked(
          address indexed stakerAddress
        , uint256 principal
        , uint256 compoundInterest
    );

    event UnbindStake(
          address indexed stakerAddress
        , uint256 indexed liquidSinceBlock
        , uint256 principal
        , uint256 compoundInterest
    );

    event NewInterestRate(
          uint256 indexed index
        , uint256 rate // Signed interest rate in [10**18] units => real_rate = rate / 10**18
    );

    event Withdraw(
          address indexed stakerAddress
        , uint256 principal
        , uint256 compoundInterest
    );

    event LockPeriod(uint64 numOfBlocks);
    event Pause(uint256 sinceBlock);
    event TokenWithdrawal(address targetAddress, uint256 amount);
    event ExcessTokenWithdrawal(address targetAddress, uint256 amount);
    event RewardsPoolTokenTopUp(address sender, uint256 amount);
    event RewardsPoolTokenWithdrawal(address targetAddress, uint256 amount);
    event DeleteContract();


    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");
    uint256 public constant DELETE_PROTECTION_PERIOD = 370285;// 60*24*60*60[s] / (14[s/block]) = 370285[block];

    IERC20 public _token;

    // NOTE(pb): This needs to be either completely replaced by multisig concept,
    //           or at least joined with multisig.
    //           This contract does not have, by-design on conceptual level, any clearly defined repeating
    //           life-cycle behaviour (for instance: `initialise -> staking-period -> locked-period` cycle
    //           with clear start & end of each life-cycle. Life-cycle of this contract is single monolithic
    //           period `creation -> delete-contract`, where there is no clear place where to `update` the
    //           earliest deletion block value, thus it would need to be set once at the contract creation
    //           point what completely defeats the protection by time delay.
    uint256 public _earliestDelete;
    
    uint256 public _pausedSinceBlock;
    uint64 public _lockPeriodInBlocks;

    // Represents amount of reward funds which are dedicated to cover accrued compound interest during user withdrawals.
    uint256 public _rewardsPoolBalance;
    // Accumulated global value of all principals (from all users) currently held in this contract (liquid, bound and locked).
    uint256 public _accruedGlobalPrincipal;
    AssetLib.Asset public _accruedGlobalLiquidity; // Exact
    AssetLib.Asset public _accruedGlobalLocked; // Exact

    uint256 public _interestRatesStartIdx;
    uint256 public _interestRatesNextIdx;
    mapping(uint256 => InterestRatePerBlock) public _interestRates;

    mapping(address => Stake) _stakes;
    mapping(address => Locked) _locked;
    mapping(address => AssetLib.Asset) public _liquidity;


    /* Only callable by owner */
    modifier onlyOwner() {
        require(_isOwner(), "Caller is not an owner");
        _;
    }

    /* Only callable by owner or delegate */
    modifier onlyDelegate() {
        require(_isOwner() || hasRole(DELEGATE_ROLE, msg.sender), "Caller is neither owner nor delegate");
        _;
    }

    modifier verifyTxExpiration(uint256 expirationBlock) {
        require(_getBlockNumber() <= expirationBlock, "Transaction expired");
        _;
    }

    modifier verifyNotPaused() {
        require(_pausedSinceBlock > _getBlockNumber(), "Contract has been paused");
        _;
    }


    /*******************
    Contract start
    *******************/
    /**
     * @param ERC20Address address of the ERC20 contract
     */
    constructor(
          address ERC20Address
        , uint256 interestRatePerBlock
        , uint256 pausedSinceBlock
        , uint64  lockPeriodInBlocks) 
    public 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _token = IERC20(ERC20Address);
        _earliestDelete = _getBlockNumber().add(DELETE_PROTECTION_PERIOD);
        
        // NOTE(pb): Unnecessary initialisations, shall be done implicitly by VM
        //_interestRatesStartIdx = 0;
        //_interestRatesNextIdx = 0;
        //_rewardsPoolBalance = 0;
        //_accruedGlobalPrincipal = 0;
        //_accruedGlobalLiquidity = 0;
        //_accruedGlobalLocked = 0;

        _updateLockPeriod(lockPeriodInBlocks);
        _addInterestRate(interestRatePerBlock);
        _pauseSince(pausedSinceBlock /* uint256(0) */);
    }


    /**
     * @notice Add new interest rate in to the ordered container of previously added interest rates
     * @param rate - signed interest rate value in [10**18] units => real_rate [1] = rate [10**18] / 10**18
     * @param expirationBlock - block number beyond which is the carrier Tx considered expired, and so rejected.
     *                     This is for protection of Tx sender to exactly define lifecycle length of the Tx,
     *                     and so avoiding uncertainty of how long Tx sender needs to wait for Tx processing.
     *                     Tx can be withheld
     * @dev expiration period
     */
    function addInterestRate(
        uint256 rate,
        uint256 expirationBlock
        )
        external
        onlyDelegate()
        verifyTxExpiration(expirationBlock)
    {
        _addInterestRate(rate);
    }


    function deposit(
        uint256 amount,
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        bool makeTransfer = amount != 0;
        if (makeTransfer) {
            require(_token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
            _accruedGlobalPrincipal = _accruedGlobalPrincipal.add(amount);
            _accruedGlobalLiquidity.principal = _accruedGlobalLiquidity.principal.add(amount);
            emit LiquidityDeposited(msg.sender, amount);
        }

        uint256 curr_block = _getBlockNumber();
        (, AssetLib.Asset storage liquidity,) = _collectLiquidity(msg.sender, curr_block);

        if (makeTransfer) {
            liquidity.principal = liquidity.principal.add(amount);
       }
    }


    /**
     * @notice Withdraws amount from sender' available liquidity pool back to sender address,
     *         preferring withdrawal from compound interest dimension of liquidity.
     *
     * @param amount - value to withdraw
     *
     * @dev public access
     */
    function withdraw(
        uint256 amount,
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        address sender = msg.sender;
        uint256 curr_block = _getBlockNumber();
        (, AssetLib.Asset storage liquidity,) = _collectLiquidity(sender, curr_block);

        AssetLib.Asset memory _amount = liquidity.iSubCompoundInterestFirst(amount);
        _finaliseWithdraw(sender, _amount, amount);
    }


    /**
     * @notice Withdraws *WHOLE* compound interest amount available to sender.
     *
     * @dev public access
     */
    function withdrawPrincipal(
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        address sender = msg.sender;
        uint256 curr_block = _getBlockNumber();
        (, AssetLib.Asset storage liquidity, ) = _collectLiquidity(sender, curr_block);

        AssetLib.Asset memory _amount;
        _amount.principal = liquidity.principal;
        liquidity.principal = 0;

        _finaliseWithdraw(sender, _amount, _amount.principal);
    }


    /**
     * @notice Withdraws *WHOLE* compound interest amount available to sender.
     *
     * @dev public access
     */
    function withdrawCompoundInterest(
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        address sender = msg.sender;
        uint256 curr_block = _getBlockNumber();
        (, AssetLib.Asset storage liquidity, ) = _collectLiquidity(sender, curr_block);

        AssetLib.Asset memory _amount;
        _amount.compoundInterest = liquidity.compoundInterest;
        liquidity.compoundInterest = 0;

        _finaliseWithdraw(sender, _amount, _amount.compoundInterest);
    }


    /**
     * @notice Withdraws whole liquidity available to sender back to sender' address,
     *
     * @dev public access
     */
    function withdrawWholeLiquidity(
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        address sender = msg.sender;
        uint256 curr_block = _getBlockNumber();
        (, AssetLib.Asset storage liquidity, ) = _collectLiquidity(sender, curr_block);

        _finaliseWithdraw(sender, liquidity, liquidity.composite());
        liquidity.compoundInterest = 0;
        liquidity.principal = 0;
    }


    function bindStake(
        uint256 amount,
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        require(amount != 0, "Amount must be higher than zero");

        uint256 curr_block = _getBlockNumber();

        (, AssetLib.Asset storage liquidity, ) = _collectLiquidity(msg.sender, curr_block);

        //// NOTE(pb): Strictly speaking, the following check is not necessary, since the requirement will be checked
        ////           during the `iRelocatePrincipalFirst(...)` method code flow (see bellow).
        //uint256 composite = liquidity.composite();
        //require(amount <= composite, "Insufficient liquidity.");

        Stake storage stake = _updateStakeCompoundInterest(msg.sender, curr_block);
        AssetLib.Asset memory _amount = liquidity.iRelocatePrincipalFirst(stake.asset, amount);
        _accruedGlobalLiquidity.iSub(_amount);

       //// NOTE(pb): Emitting only info about Tx input `amount` value, decomposed to principal & compound interest
       ////           coordinates based on liquidity available.
       //if (amount > 0) {
            emit BindStake(msg.sender, stake.sinceInterestRateIndex, _amount.principal, _amount.compoundInterest);
        //}
    }


    /**
     * @notice Unbinds amount from the stake of sender of the transaction,
     *         and *LOCKS* it for number of blocks defined by value of the
     *         `_lockPeriodInBlocks` state of this contract at the point
     *         of this call.
     *         The locked amount can *NOT* be withdrawn from the contract
     *         *BEFORE* the lock period ends.
     *
     *         Unbinding (=calling this method) also means, that compound
     *         interest will be calculated for period since la.
     *
     * @param amount - value to un-bind from the stake
     *                 If `amount=0` then the **WHOLE** stake (including
     *                 compound interest) will be unbound.
     *
     * @dev public access
     */
    function unbindStake(
        uint256 amount, //NOTE: If zero, then all stake is withdrawn
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        verifyNotPaused
    {
        uint256 curr_block = _getBlockNumber();
        address sender = msg.sender;
        Stake storage stake = _updateStakeCompoundInterest(sender, curr_block);

        uint256 stake_composite = stake.asset.composite();
        AssetLib.Asset memory _amount;

        if (amount > 0) {
            // TODO(pb): Failing this way is expensive (causing rollback of state change).
            //           It would be beneficial to retain newly calculated liquidity value
            //           in to the state, thus the invested calculation would not come to wain.
            //           However that comes with another implication - this would need
            //           to return status/error code instead of reverting = caller MUST actually
            //           check the return value, what might be trap for callers who do not expect
            //           this behaviour (Tx execution passed , but in fact the essential feature
            //           has not been fully executed).
            require(amount <= stake_composite, "Amount is higher than stake");

            if (_lockPeriodInBlocks == 0) {
                _amount = stake.asset.iRelocateCompoundInterestFirst(_liquidity[sender], amount);
                _accruedGlobalLiquidity.iAdd(_amount);
                emit UnbindStake(sender, curr_block, _amount.principal, _amount.compoundInterest);
                emit LiquidityUnlocked(sender, _amount.principal, _amount.compoundInterest);
            } else {
                Locked storage locked = _locked[sender];
                LockedAsset storage newLockedAsset = locked.assets.push();
                newLockedAsset.liquidSinceBlock = curr_block.add(_lockPeriodInBlocks);
                _amount = stake.asset.iRelocateCompoundInterestFirst(newLockedAsset.asset, amount);

                _accruedGlobalLocked.iAdd(_amount);
                locked.aggregate.iAdd(_amount);

                // NOTE: Emitting only info about Tx input values, not resulting compound values
                emit UnbindStake(sender, newLockedAsset.liquidSinceBlock, _amount.principal, _amount.compoundInterest);
            }
        } else {
            if (stake_composite == 0) {
                // NOTE(pb): Nothing to do
                return;
            }

            _amount = stake.asset;
            stake.asset.principal = 0;
            stake.asset.compoundInterest = 0;

            if (_lockPeriodInBlocks == 0) {
                _liquidity[sender].iAdd(_amount);
                _accruedGlobalLiquidity.iAdd(_amount);
                emit UnbindStake(sender, curr_block, _amount.principal, _amount.compoundInterest);
                emit LiquidityUnlocked(sender, _amount.principal, _amount.compoundInterest);
            } else {
                Locked storage locked = _locked[sender];
                LockedAsset storage newLockedAsset = locked.assets.push();
                newLockedAsset.liquidSinceBlock = curr_block.add(_lockPeriodInBlocks);
                newLockedAsset.asset = _amount;

                _accruedGlobalLocked.iAdd(_amount);
                locked.aggregate.iAdd(_amount);

                // NOTE: Emitting only info about Tx input values, not resulting compound values
                emit UnbindStake(msg.sender, newLockedAsset.liquidSinceBlock, newLockedAsset.asset.principal, newLockedAsset.asset.compoundInterest);
            }
        }
    }


    function getRewardsPoolBalance() external view returns(uint256) {
        return _rewardsPoolBalance;
    }


    function getEarliestDeleteBlock() external view returns(uint256) {
        return _earliestDelete;
    }


    function getNumberOfLockedAssetsForUser(address forAddress) external view returns(uint256 length) {
        length = _locked[forAddress].assets.length;
    }


    function getLockedAssetsAggregateForUser(address forAddress) external view returns(uint256 principal, uint256 compoundInterest) {
        AssetLib.Asset storage aggregate = _locked[forAddress].aggregate;
        return (aggregate.principal, aggregate.compoundInterest);
    }


    /**
     * @dev Returns locked assets decomposed in to 3 separate arrays (principal, compound interest, liquid since block)
     *      NOTE(pb): This method might be quite expensive, depending on size of locked assets
     */
    function getLockedAssetsForUser(address forAddress)
        external view
        returns(uint256[] memory principal, uint256[] memory compoundInterest, uint256[] memory liquidSinceBlock)
    {
        LockedAsset[] storage lockedAssets = _locked[forAddress].assets;
        uint256 length = lockedAssets.length;
        if (length != 0) {
            principal = new uint256[](length);
            compoundInterest = new uint256[](length);
            liquidSinceBlock = new uint256[](length);

            for (uint256 i=0; i < length; ++i) {
                LockedAsset storage la = lockedAssets[i];
                AssetLib.Asset storage a = la.asset;
                principal[i] = a.principal;
                compoundInterest[i] = a.compoundInterest;
                liquidSinceBlock[i] = la.liquidSinceBlock;
            }
        }
    }


    function getStakeForUser(address forAddress) external view returns(uint256 principal, uint256 compoundInterest, uint256 sinceBlock, uint256 sinceInterestRateIndex) {
        Stake storage stake = _stakes[forAddress];
        principal = stake.asset.principal;
        compoundInterest = stake.asset.compoundInterest;
        sinceBlock = stake.sinceBlock;
        sinceInterestRateIndex = stake.sinceInterestRateIndex;
    }


    /**
       @dev Even though this is considered as administrative action (is not affected by
            by contract paused state, it can be executed by anyone who wishes to
            top-up the rewards pool (funds are sent in to contract, *not* the other way around).
            The Rewards Pool is exclusively dedicated to cover withdrawals of user' compound interest,
            which is effectively the reward.
     */
    function topUpRewardsPool(
        uint256 amount,
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
    {
        if (amount == 0) {
            return;
        }

        require(_token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        _rewardsPoolBalance = _rewardsPoolBalance.add(amount);
        emit RewardsPoolTokenTopUp(msg.sender, amount);
    }


    /**
     * @notice Updates Lock Period value
     * @param numOfBlocks  length of the lock period
     * @dev Delegate only
     */
    function updateLockPeriod(uint64 numOfBlocks, uint256 txExpirationBlock)
        external
        verifyTxExpiration(txExpirationBlock)
        onlyDelegate
    {
        _updateLockPeriod(numOfBlocks);
    }


    /**
     * @notice Pauses all NON-administrative interaction with the contract since the specidfed block number 
     * @param blockNumber block number since which non-admin interaction will be paused (for all _getBlockNumber() >= blockNumber)
     * @dev Delegate only
     */
    function pauseSince(uint256 blockNumber, uint256 txExpirationBlock)
        external
        verifyTxExpiration(txExpirationBlock)
        onlyDelegate
    {
        _pauseSince(blockNumber);
    }


    /**
     * @dev Withdraw tokens from rewards pool.
     *
     * @param amount : amount to withdraw.
     *                 If `amount == 0` then whole amount in rewards pool will be withdrawn.
     * @param targetAddress : address to send tokens to
     */
    function withdrawFromRewardsPool(uint256 amount, address payable targetAddress,
        uint256 txExpirationBlock
        )
        external
        verifyTxExpiration(txExpirationBlock)
        onlyOwner
    {
        if (amount == 0) {
            amount = _rewardsPoolBalance;
        } else {
            require(amount <= _rewardsPoolBalance, "Amount higher than rewards pool");
        }

        // NOTE(pb): Strictly speaking, consistency check in following lines is not necessary,
        //           the if-else code above guarantees that everything is alright:
        uint256 contractBalance = _token.balanceOf(address(this));
        uint256 expectedMinContractBalance = _accruedGlobalPrincipal.add(amount);
        require(expectedMinContractBalance <= contractBalance, "Contract inconsistency.");

        require(_token.transfer(targetAddress, amount), "Not enough funds on contr. addr.");

        // NOTE(pb): No need for SafeMath.sub since the overflow is checked in the if-else code above.
        _rewardsPoolBalance -= amount;

        emit RewardsPoolTokenWithdrawal(targetAddress, amount);
    }


    /**
     * @dev Withdraw "excess" tokens, which were sent to contract directly via direct ERC20.transfer(...),
     *      without interacting with API of this (Staking) contract, what could be done only by mistake.
     *      Thus this method is meant to be used primarily for rescue purposes, enabling withdrawal of such
     *      "excess" tokens out of contract.
     * @param targetAddress : address to send tokens to
     * @param txExpirationBlock : block number until which is the transaction valid (inclusive).
     *                            When transaction is processed after this block, it fails.
     */
    function withdrawExcessTokens(address payable targetAddress, uint256 txExpirationBlock)
        external
        verifyTxExpiration(txExpirationBlock)
        onlyOwner
    {
        uint256 contractBalance = _token.balanceOf(address(this));
        uint256 expectedMinContractBalance = _accruedGlobalPrincipal.add(_rewardsPoolBalance);
        // NOTE(pb): The following subtraction shall *fail* (revert) IF the contract is in *INCONSISTENT* state,
        //           = when contract balance is less than minial expected balance:
        uint256 excessAmount = contractBalance.sub(expectedMinContractBalance);
        require(_token.transfer(targetAddress, excessAmount), "Not enough funds on contr. addr.");
        emit ExcessTokenWithdrawal(targetAddress, excessAmount);
    }


    /**
     * @notice Delete the contract, transfers the remaining token and ether balance to the specified
       payoutAddress
     * @param payoutAddress address to transfer the balances to. Ensure that this is able to handle ERC20 tokens
     * @dev owner only + only on or after `_earliestDelete` block
     */
    function deleteContract(address payable payoutAddress, uint256 txExpirationBlock)
    external
    verifyTxExpiration(txExpirationBlock)
    onlyOwner
    {
        require(_earliestDelete >= _getBlockNumber(), "Earliest delete not reached");
        uint256 contractBalance = _token.balanceOf(address(this));
        require(_token.transfer(payoutAddress, contractBalance));
        emit DeleteContract();
        selfdestruct(payoutAddress);
    }
 

    // **********************************************************
    // ******************    INTERNAL METHODS   *****************


    /**
     * @dev VIRTUAL Method returning bock number. Introduced for 
     *      testing purposes (allows mocking).
     */
    function _getBlockNumber() internal view virtual returns(uint256)
    {
        return block.number;
    }


    function _isOwner() internal view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * @notice Add new interest rate in to the ordered container of previously added interest rates
     * @param rate - signed interest rate value in [10**18] units => real_rate [1] = rate [10**18] / 10**18
     */
    function _addInterestRate(uint256 rate) internal 
    {
        uint256 idx = _interestRatesNextIdx;
        _interestRates[idx] = InterestRatePerBlock({
              sinceBlock: _getBlockNumber()
            , rate: rate
            //,numberOfRegisteredUsers: 0
            });
        _interestRatesNextIdx = _interestRatesNextIdx.add(1);

        emit NewInterestRate(idx, rate);
    }


    /**
     * @notice Updates Lock Period value
     * @param numOfBlocks  length of the lock period
     */
    function _updateLockPeriod(uint64 numOfBlocks) internal
    {
        _lockPeriodInBlocks = numOfBlocks;
        emit LockPeriod(numOfBlocks);
    }


    /**
     * @notice Pauses all NON-administrative interaction with the contract since the specidfed block number 
     * @param blockNumber block number since which non-admin interaction will be paused (for all _getBlockNumber() >= blockNumber)
     */
    function _pauseSince(uint256 blockNumber) internal 
    {
        uint256 currentBlockNumber = _getBlockNumber();
        _pausedSinceBlock = blockNumber < currentBlockNumber ? currentBlockNumber : blockNumber;
        emit Pause(_pausedSinceBlock);
    }


    /**
     * @notice Withdraws amount from sender' available liquidity pool back to sender address,
     *         preferring withdrawal from compound interest dimension of liquidity.
     *
     * @param amount - value to withdraw
     *
     * @dev NOTE(pb): Passing redundant `uint256 amount` (on top of the `Asset _amount`) in the name
     *                of performance to avoid calculating it again from `_amount` (or the other way around).
     *                IMPLICATION: Caller **MUST** pass correct values, ensuring that `amount == _amount.composite()`,
     *                since this private method is **NOT** verifying this condition due to performance reasons.
     */
    function _finaliseWithdraw(address sender, AssetLib.Asset memory _amount, uint256 amount) internal {
         if (amount != 0) {
            require(_rewardsPoolBalance >= _amount.compoundInterest, "Not enough funds in rewards pool");
            require(_token.transfer(sender, amount), "Transfer failed");

            _rewardsPoolBalance = _rewardsPoolBalance.sub(_amount.compoundInterest);
            _accruedGlobalPrincipal = _accruedGlobalPrincipal.sub(_amount.principal);
            _accruedGlobalLiquidity.iSub(_amount);

            // NOTE(pb): Emitting only info about Tx input `amount` value, decomposed to principal & compound interest
            //           coordinates based on liquidity available.
            emit Withdraw(msg.sender, _amount.principal, _amount.compoundInterest);
         }
    }


    function _updateStakeCompoundInterest(address sender, uint256 at_block)
        internal
        returns(Stake storage stake)
    {
        stake = _stakes[sender];
        uint256 composite = stake.asset.composite();
        if (composite != 0)
        {
            // TODO(pb): There is more effective algorithm than this.
            uint256 start_block = stake.sinceBlock;
            // NOTE(pb): Probability of `++i`  or `j=i+1` overflowing is limitly approaching zero,
            // since we would need to create `(1<<256)-1`, resp `1<<256)-2`,  number of interrest rates in order to reach the overflow
            for (uint256 i=stake.sinceInterestRateIndex; i < _interestRatesNextIdx; ++i) {
                InterestRatePerBlock storage interest = _interestRates[i];
                // TODO(pb): It is not strictly necessary to do this assert, and rather fully rely
                //           on correctness of `addInterestRate(...)` implementation.
                require(interest.sinceBlock <= start_block, "sinceBlock inconsistency");
                uint256 end_block = at_block;

                uint256 j = i + 1;
                if (j < _interestRatesNextIdx) {
                    InterestRatePerBlock storage next_interest = _interestRates[j];
                    end_block = next_interest.sinceBlock;
                }

                composite = Finance.compoundInterest(composite, interest.rate, end_block - start_block);
                start_block = end_block;
            }

            stake.asset.compoundInterest = composite.sub(stake.asset.principal);
        }

        stake.sinceBlock = at_block;
        stake.sinceInterestRateIndex = (_interestRatesNextIdx != 0 ? _interestRatesNextIdx - 1 : 0);
        // TODO(pb): Careful: The `StakeCompoundInterest` event doers not carry explicit block number value - it relies
        //           on the fact that Event implicitly carries value block.number where the event has been triggered,
        //           what however can be different than value of the `at_block` input parameter passed in.
        //           Thus this method needs to be EITHER refactored to drop the `at_block` parameter (and so get the
        //           value internally by calling the `_getBlockNumber()` method), OR the `StakeCompoundInterest` event
        //           needs to be extended to include the `uint256 sinceBlock` attribute.
        //           The original reason for passing the `at_block` parameter was to spare gas for calling the
        //           `_getBlockNumber()` method twice (by the caller of this method + by this method), what might NOT be
        //           relevant anymore (after refactoring), since caller might not need to use the block number value anymore.
        emit StakeCompoundInterest(sender, stake.sinceInterestRateIndex, stake.asset.principal, stake.asset.compoundInterest);
    }


    function _collectLiquidity(address sender, uint256 at_block)
        internal
        returns(AssetLib.Asset memory unlockedLiquidity, AssetLib.Asset storage liquidity, bool collected)
    {
        Locked storage locked = _locked[sender];
        LockedAsset[] storage lockedAssets = locked.assets;
        liquidity = _liquidity[sender];

        for (uint256 i=0; i < lockedAssets.length; ) {
            LockedAsset memory l = lockedAssets[i];

            if (l.liquidSinceBlock > at_block) {
                ++i; // NOTE(pb): Probability of overflow is zero, what is ensured by condition in this for cycle.
                continue;
            }

            unlockedLiquidity.principal = unlockedLiquidity.principal.add(l.asset.principal);
            // NOTE(pb): The following can potentially overflow, since accrued compound interest can be high, depending on values on sequence of interest rates & length of compounding intervals involved.
            unlockedLiquidity.compoundInterest = unlockedLiquidity.compoundInterest.add(l.asset.compoundInterest);

            // Copying last element of the array in to the current one,
            // so that the last one can be popped out of the array.
            // NOTE(pb): Probability of overflow during `-` operation is zero, what is ensured by condition in this for cycle.
            uint256 last_idx = lockedAssets.length - 1;
            if (i != last_idx) {
                lockedAssets[i] = lockedAssets[last_idx];
            }
            // TODO(pb): It will be cheaper (GAS consumption-wise) to simply leave
            // elements in array (do NOT delete them) and rather store "amortised"
            // size of the array in secondary separate store variable (= do NOT
            // use `array.length` as primary indication of array length).
            // Destruction of the array items is expensive. Excess of "allocated"
            // array storage can be left temporarily (or even permanently) unused.
            lockedAssets.pop();
        }

        // TODO(pb): This should not be necessary.
        if (lockedAssets.length == 0) {
            delete _locked[sender];
        }

        collected = unlockedLiquidity.principal != 0 || unlockedLiquidity.compoundInterest != 0;
        if (collected) {
             emit LiquidityUnlocked(sender, unlockedLiquidity.principal, unlockedLiquidity.compoundInterest);

            _accruedGlobalLocked.iSub(unlockedLiquidity);
            if (lockedAssets.length != 0) {
                locked.aggregate.iSub(unlockedLiquidity);
            }

            _accruedGlobalLiquidity.iAdd(unlockedLiquidity);

            liquidity.iAdd(unlockedLiquidity);
        }
    }

}