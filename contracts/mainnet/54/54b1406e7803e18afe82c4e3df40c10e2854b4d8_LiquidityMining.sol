// File: contracts/TokenInterface.sol


pragma solidity ^0.7.3;

interface TokenInterface{
    function burnFrom(address _from, uint _amount) external;
    function mintTo(address _to, uint _amount) external;
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.7.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.7.0;




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

// File: contracts/LiquidtyMining.sol

// SPDX-License-Identifier: GPL-3.0

// Author: Matt Hooft 
// https://github.com/Civitas-Fundamenta
// mhooft@fundamenta.network)

// This is a Liquidty Mining Contract that will allow users to deposit or "stake" Liquidty Pool Tokens to 
// earn rewards in the form of the FMTA Token. It is designed to be highly configurable so it can adapt to market
// and ecosystem conditions overtime. Liqudidty pools must be added by the conract owner and only added Tokens
// will be eleigible for rewards.  This also uses Role Based Access Control (RBAC) to allow other accounts and contracts
// (such as oracles) to function as `_ADMIN` allowing them to securly interact with the contract and providing possible 
// future extensibility.

// Liquidity Providers will earn rewards based on a Daily Percentage Yield (DPY) and will be able to compound thier positions
// to increase thier DPY based on a configurable factor (Compunding Daily Percentage Yield or CDPY). Liquidity Providers will 
// have a choice of three lock periods to choose from all with different CDPY factors.

// For example lets use 7, 14 and 21 as our choices for lock periods and have our user Stake 1000 LP Tokens: 

// LP Tokens Staked = 1000
// 7 days = DPY of 10% and CDPY of 0.5%, 
// 14 days  = DPY of 12% and CDPY of 0.75%
// 21 days = DPY of 15% and CDPY of 1.15%. 

// 7 Day Return = 700 FMTA
// 14 Day Return = 1680 FMTA
// 21 Day Return = 3150 FMTA

// DPY after CDPY is applied if users do not remove positions and just remove accrued DPY:

// 7 Day DPY = 10.5%
// 14 Day DPY = 12.75%
// 21 Day DPY = 16.15%

pragma solidity ^0.7.3;







contract LiquidityMining is Ownable, AccessControl {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    TokenInterface private fundamenta;
    
    //-------RBAC---------------------------

    bytes32 public constant _ADMIN = keccak256("_ADMIN");
    bytes32 public constant _REMOVAL = keccak256("_REMOVAL");
    bytes32 public constant _MOVE = keccak256("_MOVE");
    bytes32 public constant _RESCUE = keccak256("_RESCUE");
    
    //------------Token Vars-------------------
    
    bool public paused;
    bool public addDisabled;
    bool public removePositionOnly;
    
    /**
     * @dev variables to define three seperate lockPeriod's.
     * Each period uses different multipliers and basis points 
     * to calculate Liquidity Miners daily yield.
     */
    
    uint private lockPeriod0;
    uint private lockPeriod1;
    uint private lockPeriod2;
    
    uint private lockPeriod0BasisPoint;
    uint private lockPeriod1BasisPoint;
    uint private lockPeriod2BasisPoint;
    
    uint private compYield0;
    uint private compYield1;
    uint private compYield2;
    
    uint private lockPeriodBPScale;
    uint public maxUserBP;
    
    uint private preYieldDivisor;
    
    /**
     * @dev `periodCalc` uses blocks instead of timestamps
     * as a way to determine days. approx. 6500 blocks a day
     *  are mined on the ethereum network. 
     * `periodCalc` can also be configured if this were ever 
     * needed to be changed.  It also helps to lower it during 
     * testing if you are looking at using any of this code.
     */
     
    uint public periodCalc;
    
    //-------Structs/Mappings/Arrays-------------
    
    /**
     * @dev struct to keep track of Liquidity Providers who have 
     * chosen to stake UniswapV2 Liquidity Pool tokens towards 
     * earning FMTA. 
     */ 
    
    struct LiquidityProviders {
        address Provider;
        uint UnlockHeight;
        uint LockedAmount;
        uint Days;
        uint UserBP;
        uint TotalRewardsPaid;
    }
    
    /**
     * @dev struct to keep track of liquidty pools, total
     * rewards paid and total value locked in said pools.
     */
    
    struct PoolInfo {
        IERC20 ContractAddress;
        uint TotalRewardsPaidByPool;
        uint TotalLPTokensLocked;
        uint PoolBonus;
    }
    
    /**
     * @dev PoolInfo is tracked as an array. The length/index 
     * of the array will be used as the variable `_pid` (Pool ID) 
     * throughout the contract.
     */
    
    PoolInfo[] public poolInfo;
    
    /**
     * @dev mapping to keep track of the struct LiquidityProviders 
     * mapeed to user addresses but also maps it to `uint _pid`
     * this makes tracking the same address across multiple pools 
     * with different positions possible as _pid will also be the 
     * index of PoolInfo[]
     */
    
    mapping (uint => mapping (address => LiquidityProviders)) public provider;

    //-------Events--------------

    event PositionAdded (address _account, uint _amount, uint _blockHeight);
    event PositionRemoved (address _account, uint _amount, uint _blockHeight);
    event PositionForceRemoved (address _account, uint _amount, uint _blockHeight);
    event PositionCompounded (address _account, uint _amountAdded, uint _blockHeight);
    event ETHRescued (address _movedBy, address _movedTo, uint _amount, uint _blockHeight);
    event ERC20Movement (address _movedBy, address _movedTo, uint _amount, uint _blockHeight);
    
    
    /**
     * @dev constructor sets initial values for contract intiialization
     */ 
    
    constructor() {
        periodCalc = 6500;
        lockPeriodBPScale = 10000;
        lockPeriod0BasisPoint = 1000;
        lockPeriod1BasisPoint = 1500;
        lockPeriod2BasisPoint = 2000;
        preYieldDivisor = 2;
        maxUserBP = 3500;
        compYield0 = 50;
        compYield1 = 75;
        compYield2 = 125;
        lockPeriod0 = 3;
        lockPeriod1 = 7;
        lockPeriod2 = 14;
        removePositionOnly = false;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); //God Mode. DEFAULT_ADMIN_ROLE Must Require _ADMIN ROLE Sill to execute _ADMIN functions.
    }
     
     //------------State modifiers---------------------
     
      modifier unpaused() {
        require(!paused, "LiquidityMining: Contract is Paused");
        _;
    }
    
     modifier addPositionNotDisabled() {
        require(!addDisabled, "LiquidityMining: Adding a Position is currently disabled");
        _;
    }
    
    modifier remPosOnly() {
        require(!removePositionOnly, "LiquidityMining: Only Removing a position is allowed at the moment");
        _;
    }
    
    //----------Modifier Functions----------------------

    function setPaused(bool _paused) external {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        paused = _paused;
    }
    
    function setRemovePosOnly(bool _removeOnly) external {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        removePositionOnly = _removeOnly;
    }
    
      function disableAdd(bool _addDisabled) external {
          require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        addDisabled = _addDisabled;
    }
    
    //------------Token Functions----------------------
    
    /**
     * @dev functions to add and remove Liquidty Pool pairs to allow users to
     * stake the pools LP Tokens towards earnign rewards. Can only
     * be called by accounts with the `_ADMIN` role and should only 
     * be added once. The index at which the pool pair is stored 
     * will determine the pools `_pid`. Note if you remove a pool the 
     * index remians but is just left empty making the _pid return
     * zero value if called.
     */
    
    function addLiquidtyPoolToken(IERC20 _lpTokenAddress, uint _bonus) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        poolInfo.push(PoolInfo({
            ContractAddress: _lpTokenAddress,
            TotalRewardsPaidByPool: 0,
            TotalLPTokensLocked: 0,
            PoolBonus: _bonus
        }));
  
    }

    
    function removeLiquidtyPoolToken(uint _pid) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        delete poolInfo[_pid];
        
    }
    
    //------------Information Functions------------------
    
    /**
     * @dev return the length of the pool array
     */
    
     function poolLength() external view returns (uint) {
        return poolInfo.length;
    }
    
    /**
     * @dev function to return the contracts balances of LP Tokens
     * staked from different Uniswap pools.
     */

    function contractBalanceByPoolID(uint _pid) public view returns (uint _balance) {
        PoolInfo memory pool = poolInfo[_pid];
        address ca = address(this);
        return pool.ContractAddress.balanceOf(ca);
    }
    
    /**
     * @dev funtion that returns a callers staked position in a pool 
     * using `_pid` as an argument.
     */
    
    function accountPosition(address _account, uint _pid) public view returns (
        address _accountAddress, 
        uint _unlockHeight, 
        uint _lockedAmount, 
        uint _lockPeriodInDays, 
        uint _userDPY, 
        IERC20 _lpTokenAddress,
        uint _totalRewardsPaidFromPool
    ) {
        LiquidityProviders memory p = provider[_pid][_account];
        PoolInfo memory pool = poolInfo[_pid];
        return (
            p.Provider, 
            p.UnlockHeight, 
            p.LockedAmount, 
            p.Days, 
            p.UserBP, 
            pool.ContractAddress,
            pool.TotalRewardsPaidByPool
        );
    }
    
    /**
     * @dev funtion that returns a true or false regarding whether
     * an account as a position in a pool.  Takes the account address
     * and `_pid` as arguments
     */
    
    function hasPosition(address _userAddress, uint _pid) public view returns (bool _hasPosition) {
        LiquidityProviders memory p = provider[_pid][_userAddress];
        if(p.LockedAmount == 0)
        return false;
        else 
        return true;
    }
    
    /**
     * @dev function to show current lock periods.
     */
    
    function showCurrentLockPeriods() external view returns (
        uint _lockPeriod0, 
        uint _lockPeriod1, 
        uint _lockPeriod2
    ) {
        return (
            lockPeriod0, 
            lockPeriod1, 
            lockPeriod2
        );
    }
    
    //-----------Set Functions----------------------
    
    /**
     * @dev function to set the token that will be minting rewards 
     * for Liquidity Providers.
     */
    
    function setTokenContract(TokenInterface _fmta) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        fundamenta = _fmta;
    }
    
    /**
     * @dev allows accounts with the _ADMIN role to set new lock periods.
     */
    
    function setLockPeriods(uint _newPeriod0, uint _newPeriod1, uint _newPeriod2) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        require(_newPeriod2 > _newPeriod1 && _newPeriod1 > _newPeriod0);
        lockPeriod0 = _newPeriod0;
        lockPeriod1 = _newPeriod1;
        lockPeriod2 = _newPeriod2;
    }
    
    /**
     * @dev allows contract owner to set a new `periodCalc`
     */
    
    function setPeriodCalc(uint _newPeriodCalc) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        periodCalc = _newPeriodCalc;
    }

    /**
     * @dev set of functions to set parameters regarding 
     * lock periods and basis points which are used to  
     * calculate a users daily yield. Can only be called 
     * by contract _ADMIN.
     */
    
    function setLockPeriodBasisPoints (
        uint _newLockPeriod0BasisPoint, 
        uint _newLockPeriod1BasisPoint, 
        uint _newLockPeriod2BasisPoint) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        lockPeriod0BasisPoint = _newLockPeriod0BasisPoint;
        lockPeriod1BasisPoint = _newLockPeriod1BasisPoint;
        lockPeriod2BasisPoint = _newLockPeriod2BasisPoint;
    }
    
    function setLockPeriodBPScale(uint _newLockPeriodScale) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        lockPeriodBPScale = _newLockPeriodScale;
    
    }

    function setMaxUserBP(uint _newMaxUserBP) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        maxUserBP = _newMaxUserBP;
 
    }
    
    function setCompoundYield (
        uint _newCompoundYield0, 
        uint _newCompoundYield1, 
        uint _newCompoundYield2) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        compYield0 = _newCompoundYield0;
        compYield1 = _newCompoundYield1;
        compYield2 = _newCompoundYield2;
        
    }
    
    function setPoolBonus(uint _pid, uint _bonus) public {
        require(hasRole(_ADMIN, msg.sender));
        PoolInfo storage pool = poolInfo[_pid];
        pool.PoolBonus = _bonus;
    }

    function setPreYieldDivisor(uint _newDivisor) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        preYieldDivisor = _newDivisor;
    }
    
    //-----------Position/Rewards Functions------------------
    
    /**
     * @dev this function allows a user to add a liquidity Staking
     * position.  The user will need to choose one of the three
     * configured lock Periods. Users may add to the position 
     * only once per lock period.
     */
    
    function addPosition(uint _lpTokenAmount, uint _lockPeriod, uint _pid) public addPositionNotDisabled unpaused{
        LiquidityProviders storage p = provider[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        address ca = address(this);
        require(p.LockedAmount == 0, "LiquidityMining: This account already has a position");
        if(_lockPeriod == lockPeriod0) {
            pool.ContractAddress.safeTransferFrom(msg.sender, ca, _lpTokenAmount);
            uint _preYield = _lpTokenAmount.mul(lockPeriod0BasisPoint.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(_lockPeriod);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                block.number.add(periodCalc.mul(lockPeriod0)), 
                _lpTokenAmount, 
                lockPeriod0, 
                lockPeriod0BasisPoint,
                p.TotalRewardsPaid.add(_preYield.div(preYieldDivisor))
            );
            fundamenta.mintTo(msg.sender, _preYield.div(preYieldDivisor));
            pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(_preYield.div(preYieldDivisor));
        } else if (_lockPeriod == lockPeriod1) {
            pool.ContractAddress.safeTransferFrom(msg.sender, ca, _lpTokenAmount);
            uint _preYield = _lpTokenAmount.mul(lockPeriod1BasisPoint.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(_lockPeriod);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                block.number.add(periodCalc.mul(lockPeriod1)), 
                _lpTokenAmount, 
                lockPeriod1, 
                lockPeriod1BasisPoint,
                p.TotalRewardsPaid.add(_preYield.div(preYieldDivisor))
            );
            fundamenta.mintTo(msg.sender, _preYield.div(preYieldDivisor));
            pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(_preYield.div(preYieldDivisor));
        } else if (_lockPeriod == lockPeriod2) {
            pool.ContractAddress.safeTransferFrom(msg.sender, ca, _lpTokenAmount);
            uint _preYield = _lpTokenAmount.mul(lockPeriod2BasisPoint.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(_lockPeriod);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                block.number.add(periodCalc.mul(lockPeriod2)), 
                _lpTokenAmount, 
                lockPeriod2, 
                lockPeriod2BasisPoint,
                p.TotalRewardsPaid.add(_preYield.div(preYieldDivisor))
            );
            fundamenta.mintTo(msg.sender, _preYield.div(preYieldDivisor));
            pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(_preYield.div(preYieldDivisor));
        }else revert("LiquidityMining: Incompatible Lock Period");
      emit PositionAdded (
          msg.sender,
          _lpTokenAmount,
          block.number
      );
    }
    
    /**
     * @dev allows a user to remove a liquidity staking position
     * and will withdraw any pending rewards. User must withdraw 
     * the entire position.
     */
    
    function removePosition(uint _lpTokenAmount, uint _pid) external unpaused {
        LiquidityProviders storage p = provider[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        require(_lpTokenAmount == p.LockedAmount, "LiquidyMining: Either you do not have a position or you must remove the entire amount.");
        require(p.UnlockHeight < block.number, "LiquidityMining: Not Long Enough");
            pool.ContractAddress.safeTransfer(msg.sender, _lpTokenAmount);
            uint yield = calculateUserDailyYield(_pid);
            fundamenta.mintTo(msg.sender, yield);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                0, 
                p.LockedAmount.sub(_lpTokenAmount),
                0, 
                0,
                p.TotalRewardsPaid.add(yield)
            );
        pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
        pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.sub(_lpTokenAmount);
        emit PositionRemoved(
        msg.sender,
        _lpTokenAmount,
        block.number
      );
    }

    /**
     * @dev function to forcibly remove a users position.  This 
     * is required due to the fact that the basis points used to 
     * calculate user DPY will be constantly changing.
     * We will need to forceibly remove positions of lazy (or malicious)
     * users who will try to take advantage of DPY being lowered instead 
     * of raised and maintining thier current return levels.
     */
    
    function forcePositionRemoval(uint _pid, address _account) public {
        require(hasRole(_REMOVAL, msg.sender));
        LiquidityProviders storage p = provider[_pid][_account];
        PoolInfo storage pool = poolInfo[_pid];
        uint _lpTokenAmount = p.LockedAmount;
        pool.ContractAddress.safeTransfer(_account, _lpTokenAmount);
        uint _newLpTokenAmount = p.LockedAmount.sub(_lpTokenAmount);
        uint yield = calculateUserDailyYield(_pid);
        fundamenta.mintTo(msg.sender, yield);
        provider[_pid][_account] = LiquidityProviders (
            _account, 
            0, 
            _newLpTokenAmount, 
            0, 
            0,
            p.TotalRewardsPaid.add(yield)
        );
        pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
        pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.sub(_lpTokenAmount);
        emit PositionForceRemoved(
        msg.sender,
        _lpTokenAmount,
        block.number
      );
    
    }

    /**
     * @dev calculates a users daily yield. DY is calculated
     * using basis points and the lock period as a multiplier.
     * Basis Points and the scale used are configurble by accounts
     * or contracts that have the _ADMIN Role
     */
    
    function calculateUserDailyYield(uint _pid) public view returns (uint _dailyYield) {
        LiquidityProviders memory p = provider[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        uint dailyYield = p.LockedAmount.mul(p.UserBP.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(p.Days);
        return dailyYield;
    }
    
    /**
     * @dev allow user to withdraw thier accrued yield. Reset 
     * the lock period to continue liquidity mining and apply
     * CDPY to DPY. Allow user to add more stake if desired
     * in the process. Once a user has reached the `maxUserBP`
     * DPY will no longer increase.
     */
    
    function withdrawAccruedYieldAndAdd(uint _pid, uint _lpTokenAmount) public remPosOnly unpaused{
        LiquidityProviders storage p = provider[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        uint yield = calculateUserDailyYield(_pid);
        require(removePositionOnly == false);
        require(p.UnlockHeight < block.number);
        if (_lpTokenAmount != 0) {
            if(p.Days == lockPeriod0) {
                fundamenta.mintTo(msg.sender, yield);
                pool.ContractAddress.safeTransferFrom(msg.sender, address(this), _lpTokenAmount);
                provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod0)), 
                    _lpTokenAmount.add(p.LockedAmount), 
                    lockPeriod0, 
                    p.UserBP.add(p.UserBP >= maxUserBP ? 0 : compYield0),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
                pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            } else if (p.Days == lockPeriod1) {
                fundamenta.mintTo(msg.sender, yield);
                pool.ContractAddress.safeTransferFrom(msg.sender, address(this), _lpTokenAmount);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod1)),
                    _lpTokenAmount.add(p.LockedAmount), 
                    lockPeriod1, 
                    p.UserBP.add(p.UserBP >= maxUserBP ? 0 : compYield1),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
                pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            } else if (p.Days == lockPeriod2) {
                fundamenta.mintTo(msg.sender, yield);
                pool.ContractAddress.safeTransferFrom(msg.sender, address(this), _lpTokenAmount);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod2)), 
                    _lpTokenAmount.add(p.LockedAmount), 
                    lockPeriod2, 
                    p.UserBP.add(p.UserBP >= maxUserBP ? 0 : compYield2),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
                pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            } else revert("LiquidityMining: Incompatible Lock Period");
        } else if (_lpTokenAmount == 0) {
            if(p.Days == lockPeriod0) {
                fundamenta.mintTo(msg.sender, yield);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod0)), 
                    p.LockedAmount, 
                    lockPeriod0, 
                    p.UserBP.add(p.UserBP >= maxUserBP ? 0 : compYield0),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
            } else if (p.Days == lockPeriod1) {
                fundamenta.mintTo(msg.sender, yield);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod1)), 
                    p.LockedAmount, 
                    lockPeriod1, 
                    p.UserBP.add(p.UserBP >= maxUserBP ? 0 : compYield1),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
            } else if (p.Days == lockPeriod2) {
                fundamenta.mintTo(msg.sender, yield);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod2)), 
                    p.LockedAmount, 
                    lockPeriod2, 
                    p.UserBP.add(p.UserBP >= maxUserBP ? 0 : compYield2),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
            }else revert("LiquidityMining: Incompatible Lock Period");
        }else revert("LiquidityMining: ?" );
         emit PositionRemoved (
             msg.sender,
             _lpTokenAmount,
             block.number
         );
    }
    
    //-------Movement Functions---------------------

    /**
     * @dev The below function will allow contracts or accounts
     * with the _MOVE role to move tokens that are staked with
     * the contract.  Currently this will not be used nor will
     * any accounts/contracts be granted the _MOVE role.  The 
     * Reason for including this capability is two fold. One, 
     * it allows us to recover tokens if they are sent to the 
     * contract by mistake. Two, it will allow us to further
     * extend the use of this contract and the tokens staked
     * within it to allow for use of farming other opprotiunites
     * giving users even further rewards.  If and when this is 
     * activated/used will be a community decision.  
     */
    
    function moveERC20(address _ERC20, address _dest, uint _ERC20Amount) public {
        require(hasRole(_MOVE, msg.sender));
        IERC20(_ERC20).safeTransfer(_dest, _ERC20Amount);
        emit ERC20Movement (
            msg.sender,
            _dest,
            _ERC20Amount,
            block.number
        );

    }

    function ethRescue(address payable _dest, uint _etherAmount) public {
        require(hasRole(_RESCUE, msg.sender));
        _dest.transfer(_etherAmount);
        emit ETHRescued (
            msg.sender,
            _dest,
            _etherAmount,
            block.number
        );
    }
    
}