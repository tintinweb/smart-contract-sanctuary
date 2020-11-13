// File: @openzeppelin/contracts/utils/EnumerableSet.sol

// SPDX-License-Identifier: MIT AND GPL-3.0-or-later

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

// File: @openzeppelin/contracts/utils/Address.sol


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


pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/IMintableERC20.sol


pragma solidity ^0.6.0;


/**
 * @dev Interface of an ERC20 which implements the mint() function.
 */
interface IMintableERC20
   is IERC20
{
   /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
    */
   function mint(address to, uint256 amount) external;
}

// File: contracts/KnsTokenWork.sol

/**************************************************************************************
 *                                                                                    *
 *                             GENERATED FILE DO NOT EDIT                             *
 *   ___  ____  _  _  ____  ____    __   ____  ____  ____     ____  ____  __    ____  *
 *  / __)( ___)( \( )( ___)(  _ \  /__\ (_  _)( ___)(  _ \   ( ___)(_  _)(  )  ( ___) *
 * ( (_-. )__)  )  (  )__)  )   / /(__)\  )(   )__)  )(_) )   )__)  _)(_  )(__  )__)  *
 *  \___/(____)(_)\_)(____)(_)\_)(__)(__)(__) (____)(____/   (__)  (____)(____)(____) *
 *                                                                                    *
 *                             GENERATED FILE DO NOT EDIT                             *
 *                                                                                    *
 **************************************************************************************/
pragma solidity ^0.6.0;

contract KnsTokenWork
{
   /**
    * Compute the work function for a seed, secured_struct_hash, and nonce.
    *
    * work_result[10] is the actual work function value, this is what is compared against the target.
    * work_result[0] through work_result[9] (inclusive) are the values of w[y_i].
    */
   function work(
      uint256 seed,
      uint256 secured_struct_hash,
      uint256 nonce
      ) public pure returns (uint256[11] memory work_result)
   {
      uint256 w;
      uint256 x;
      uint256 y;
      uint256 result = secured_struct_hash;
      uint256 coeff_0 = (nonce % 0x0000fffd)+1;
      uint256 coeff_1 = (nonce % 0x0000fffb)+1;
      uint256 coeff_2 = (nonce % 0x0000fff7)+1;
      uint256 coeff_3 = (nonce % 0x0000fff1)+1;
      uint256 coeff_4 = (nonce % 0x0000ffef)+1;




      x = secured_struct_hash % 0x0000fffd;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[0] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000fffb;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[1] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000fff7;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[2] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000fff1;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[3] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffef;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[4] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffe5;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[5] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffdf;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[6] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffd9;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[7] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffd3;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[8] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffd1;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[9] = w;
      result ^= w;


      work_result[10] = result;
      return work_result;
   }
}

// File: contracts/KnsTokenMining.sol


pragma solidity ^0.6.0;




contract KnsTokenMining
   is AccessControl,
      KnsTokenWork
{
   IMintableERC20 public token;
   mapping (uint256 => uint256) private user_pow_height;

   uint256 public constant ONE_KNS = 100000000;
   uint256 public constant MINEABLE_TOKENS = 100 * 1000000 * ONE_KNS;

   uint256 public constant FINAL_PRINT_RATE = 1500;  // basis points
   uint256 public constant TOTAL_EMISSION_TIME = 180 days;
   uint256 public constant EMISSION_COEFF_1 = (MINEABLE_TOKENS * (20000 - FINAL_PRINT_RATE) * TOTAL_EMISSION_TIME);
   uint256 public constant EMISSION_COEFF_2 = (MINEABLE_TOKENS * (10000 - FINAL_PRINT_RATE));
   uint256 public constant HC_RESERVE_DECAY_TIME = 5 days;
   uint256 public constant RECENT_BLOCK_LIMIT = 96;

   uint256 public start_time;
   uint256 public token_reserve;
   uint256 public hc_reserve;
   uint256 public last_mint_time;

   bool public is_testing;

   event Mine( address[] recipients, uint256[] split_percents, uint256 hc_submit, uint256 hc_decay, uint256 token_virtual_mint, uint256[] tokens_mined );

   constructor( address tok, uint256 start_t, uint256 start_hc_reserve, bool testing )
      public
   {
      token = IMintableERC20(tok);
      _setupRole( DEFAULT_ADMIN_ROLE, _msgSender() );

      start_time = start_t;
      last_mint_time = start_t;
      hc_reserve = start_hc_reserve;
      token_reserve = 0;

      is_testing = testing;

      _initial_mining_event( start_hc_reserve );
   }

   function _initial_mining_event( uint256 start_hc_reserve ) internal
   {
      address[] memory recipients = new address[](1);
      uint256[] memory split_percents = new uint256[](1);
      uint256[] memory tokens_mined = new uint256[](1);

      recipients[0] = address(0);
      split_percents[0] = 10000;
      tokens_mined[0] = 0;

      emit Mine( recipients, split_percents, start_hc_reserve, 0, 0, tokens_mined );
   }

   /**
    * Get the hash of the secured struct.
    *
    * Basically calls keccak256() on parameters.  Mainly exists for readability purposes.
    */
   function get_secured_struct_hash(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height
      ) public pure returns (uint256)
   {
      return uint256( keccak256( abi.encode( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height ) ) );
   }

   /**
    * Require w[0]..w[9] are all distinct values.
    *
    * w[10] is untouched.
    */
   function check_uniqueness(
      uint256[11] memory w
      ) public pure
   {
      // Implement a simple direct comparison algorithm, unroll to optimize gas usage.
      require( (w[0] != w[1]) && (w[0] != w[2]) && (w[0] != w[3]) && (w[0] != w[4]) && (w[0] != w[5]) && (w[0] != w[6]) && (w[0] != w[7]) && (w[0] != w[8]) && (w[0] != w[9])
                              && (w[1] != w[2]) && (w[1] != w[3]) && (w[1] != w[4]) && (w[1] != w[5]) && (w[1] != w[6]) && (w[1] != w[7]) && (w[1] != w[8]) && (w[1] != w[9])
                                                && (w[2] != w[3]) && (w[2] != w[4]) && (w[2] != w[5]) && (w[2] != w[6]) && (w[2] != w[7]) && (w[2] != w[8]) && (w[2] != w[9])
                                                                  && (w[3] != w[4]) && (w[3] != w[5]) && (w[3] != w[6]) && (w[3] != w[7]) && (w[3] != w[8]) && (w[3] != w[9])
                                                                                    && (w[4] != w[5]) && (w[4] != w[6]) && (w[4] != w[7]) && (w[4] != w[8]) && (w[4] != w[9])
                                                                                                      && (w[5] != w[6]) && (w[5] != w[7]) && (w[5] != w[8]) && (w[5] != w[9])
                                                                                                                        && (w[6] != w[7]) && (w[6] != w[8]) && (w[6] != w[9])
                                                                                                                                          && (w[7] != w[8]) && (w[7] != w[9])
                                                                                                                                                            && (w[8] != w[9]),
               "Non-unique work components" );
   }

   /**
    * Check proof of work for validity.
    *
    * Throws if the provided fields have any problems.
    */
   function check_pow(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce
      ) public view
   {
      require( recent_eth_block_hash != 0, "Zero block hash not allowed" );
      require( recent_eth_block_number <= block.number, "Recent block in future" );
      require( recent_eth_block_number + RECENT_BLOCK_LIMIT > block.number, "Recent block too old" );
      require( nonce >= recent_eth_block_hash, "Nonce too small" );
      require( (recent_eth_block_hash + (1 << 128)) > nonce, "Nonce too large" );
      require( uint256( blockhash( recent_eth_block_number ) ) == recent_eth_block_hash, "Block hash mismatch" );

      require( recipients.length <= 5, "Number of recipients cannot exceed 5" );
      require( recipients.length == split_percents.length, "Recipient and split percent array size mismatch" );
      array_check( split_percents );

      require( get_pow_height( _msgSender(), recipients, split_percents ) + 1 == pow_height, "pow_height mismatch" );
      uint256 h = get_secured_struct_hash( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height );
      uint256[11] memory w = work( recent_eth_block_hash, h, nonce );
      check_uniqueness( w );
      require( w[10] < target, "Work missed target" );     // always fails if target == 0
   }

   function array_check( uint256[] memory arr )
   internal pure
   {
      uint256 sum = 0;
      for (uint i = 0; i < arr.length; i++)
      {
         require( arr[i] <= 10000, "Percent array element cannot exceed 10000" );
         sum += arr[i];
      }
      require( sum == 10000, "Split percentages do not add up to 10000" );
   }

   function get_emission_curve( uint256 t )
      public view returns (uint256)
   {
      if( t < start_time )
         t = start_time;
      if( t > start_time + TOTAL_EMISSION_TIME )
         t = start_time + TOTAL_EMISSION_TIME;
      t -= start_time;
      return ((EMISSION_COEFF_1 - (EMISSION_COEFF_2*t))*t) / (10000 * TOTAL_EMISSION_TIME * TOTAL_EMISSION_TIME);
   }

   function get_hc_reserve_multiplier( uint256 dt )
      public pure returns (uint256)
   {
      if( dt >= HC_RESERVE_DECAY_TIME )
         return 0x80000000;
      int256 idt = (int256( dt ) << 32) / int32(HC_RESERVE_DECAY_TIME);
      int256 y = -0xa2b23f3;
      y *= idt;
      y >>= 32;
      y += 0x3b9d3bec;
      y *= idt;
      y >>= 32;
      y -= 0xb17217f7;
      y *= idt;
      y >>= 32;
      y += 0x100000000;
      if( y < 0 )
         y = 0;
      return uint256( y );
   }

   function get_background_activity( uint256 current_time ) public view
      returns (uint256 hc_decay, uint256 token_virtual_mint)
   {
      hc_decay = 0;
      token_virtual_mint = 0;

      if( current_time <= last_mint_time )
         return (hc_decay, token_virtual_mint);
      uint256 dt = current_time - last_mint_time;

      uint256 f_prev = get_emission_curve( last_mint_time );
      uint256 f_now = get_emission_curve( current_time );
      if( f_now <= f_prev )
         return (hc_decay, token_virtual_mint);

      uint256 mul = get_hc_reserve_multiplier( dt );
      uint256 new_hc_reserve = (hc_reserve * mul) >> 32;
      hc_decay = hc_reserve - new_hc_reserve;

      token_virtual_mint = f_now - f_prev;

      return (hc_decay, token_virtual_mint);
   }

   function process_background_activity( uint256 current_time ) internal
      returns (uint256 hc_decay, uint256 token_virtual_mint)
   {
      (hc_decay, token_virtual_mint) = get_background_activity( current_time );
      hc_reserve -= hc_decay;
      token_reserve += token_virtual_mint;
      last_mint_time = current_time;
      return (hc_decay, token_virtual_mint);
   }

   /**
    * Calculate value in tokens the given hash credits are worth
    **/
   function get_hash_credits_conversion( uint256 hc )
      public view
      returns (uint256)
   {
      require( hc > 1, "HC underflow" );
      require( hc < (1 << 128), "HC overflow" );

      // xyk algorithm
      uint256 x0 = token_reserve;
      uint256 y0 = hc_reserve;

      require( x0 < (1 << 128), "Token balance overflow" );
      require( y0 < (1 << 128), "HC balance overflow" );

      uint256 y1 = y0 + hc;
      require( y1 < (1 << 128), "HC balance overflow" );

      // x0*y0 = x1*y1 -> x1 = (x0*y0)/y1
      // NB above require() ensures overflow safety
      uint256 x1 = ((x0*y0)/y1)+1;
      require( x1 < x0, "No tokens available" );

      return x0-x1;
   }

   /**
    * Executes the trade of hash credits to tokens
    * Returns number of minted tokens
    **/
   function convert_hash_credits(
      uint256 hc ) internal
      returns (uint256)
   {
      uint256 tokens_minted = get_hash_credits_conversion( hc );
      hc_reserve += hc;
      token_reserve -= tokens_minted;

      return tokens_minted;
   }

   function increment_pow_height(
      address[] memory recipients,
      uint256[] memory split_percents ) internal
   {
      user_pow_height[uint256( keccak256( abi.encode( _msgSender(), recipients, split_percents ) ) )] += 1;
   }

   function mine_impl(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce,
      uint256 current_time ) internal
   {
      check_pow(
         recipients,
         split_percents,
         recent_eth_block_number,
         recent_eth_block_hash,
         target,
         pow_height,
         nonce
         );
      uint256 hc_submit = uint256(-1)/target;

      uint256 hc_decay;
      uint256 token_virtual_mint;
      (hc_decay, token_virtual_mint) = process_background_activity( current_time );
      uint256 token_mined;
      token_mined = convert_hash_credits( hc_submit );

      uint256[] memory distribution = distribute( recipients, split_percents, token_mined );
      increment_pow_height( recipients, split_percents );

      emit Mine( recipients, split_percents, hc_submit, hc_decay, token_virtual_mint, distribution );
   }

   /**
    * Get the total number of proof-of-work submitted by a user.
    */
   function get_pow_height(
      address from,
      address[] memory recipients,
      uint256[] memory split_percents
    )
      public view
      returns (uint256)
   {
      return user_pow_height[uint256( keccak256( abi.encode( from, recipients, split_percents ) ) )];
   }

   /**
    * Executes the distribution, minting the tokens to the recipient addresses
    **/
   function distribute(address[] memory recipients, uint256[] memory split_percents, uint256 token_mined)
   internal returns ( uint256[] memory )
   {
      uint256 remaining = token_mined;
      uint256[] memory distribution = new uint256[]( recipients.length );
      for (uint i = distribution.length-1; i > 0; i--)
      {
         distribution[i] = (token_mined * split_percents[i]) / 10000;
	 token.mint( recipients[i], distribution[i] );
	 remaining -= distribution[i];
      }
      distribution[0] = remaining;
      token.mint( recipients[0], remaining );

      return distribution;
   }

   function mine(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce ) public
   {
      require( now >= start_time, "Mining has not started" );
      mine_impl( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height, nonce, now );
   }

   function test_process_background_activity( uint256 current_time )
      public
   {
      require( is_testing, "Cannot call test method" );
      process_background_activity( current_time );
   }

   function test_mine(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce,
      uint256 current_time ) public
   {
      require( is_testing, "Cannot call test method" );
      mine_impl( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height, nonce, current_time );
   }
}