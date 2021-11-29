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

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

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
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

interface IController {
  function addDomani(address _domani) external;

  function feeRecipient() external view returns (address);

  function getModuleFee(address _module, uint256 _feeType) external view returns (uint256);

  function isModule(address _module) external view returns (bool);

  function isDomani(address _domani) external view returns (bool);

  function isSystemContract(address _contractAddress) external view returns (bool);

  function resourceId(uint256 _id) external view returns (address);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IDomani
 * @author Domani Protocol
 *
 * Interface for operating with Domani tokens.
 */
interface IDomani is IERC20 {
  /* ============ Enums ============ */

  enum ModuleState {
    NONE,
    PENDING,
    INITIALIZED
  }

  /* ============ Structs ============ */
  /**
   * The base definition of a Domani Position
   *
   * @param component           Address of token in the Position
   * @param module              If not in default state, the address of associated module
   * @param unit                Each unit is the # of components per 10^18 of a Domani token
   * @param positionState       Position ENUM. Default is 0; External is 1
   * @param data                Arbitrary data
   */
  struct Position {
    address component;
    address module;
    int256 unit;
    uint8 positionState;
    bytes data;
  }

  /**
   * A struct that stores a component's cash position details and external positions
   * This data structure allows O(1) access to a component's cash position units and
   * virtual units.
   *
   * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
   *                                  updating all units at once via the position multiplier. Virtual units are achieved
   *                                  by dividing a "real" value by the "positionMultiplier"
   * @param componentIndex
   * @param externalPositionModules   List of external modules attached to each external position. Each module
   *                                  maps to an external position
   * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
   */
  struct ComponentPosition {
    int256 virtualUnit;
    address[] externalPositionModules;
    mapping(address => ExternalPosition) externalPositions;
  }

  /**
   * A struct that stores a component's external position details including virtual unit and any
   * auxiliary data.
   *
   * @param virtualUnit       Virtual value of a component's EXTERNAL position.
   * @param data              Arbitrary data
   */
  struct ExternalPosition {
    int256 virtualUnit;
    bytes data;
  }

  /* ============ Functions ============ */

  function addComponent(address _component) external;

  function removeComponent(address _component) external;

  function editDefaultPositionUnit(address _component, int256 _realUnit) external;

  function addExternalPositionModule(address _component, address _positionModule) external;

  function removeExternalPositionModule(address _component, address _positionModule) external;

  function editExternalPositionUnit(
    address _component,
    address _positionModule,
    int256 _realUnit
  ) external;

  function editExternalPositionData(
    address _component,
    address _positionModule,
    bytes calldata _data
  ) external;

  function invoke(
    address _target,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes memory);

  function editPositionMultiplier(int256 _newMultiplier) external;

  function mint(address _account, uint256 _quantity) external;

  function burn(address _account, uint256 _quantity) external;

  function lock() external;

  function unlock() external;

  function addModule(address _module) external;

  function removeModule(address _module) external;

  function initializeModule() external;

  function setManager(address _manager) external;

  function manager() external view returns (address);

  function moduleStates(address _module) external view returns (ModuleState);

  function getModules() external view returns (address[] memory);

  function getDefaultPositionRealUnit(address _component) external view returns (int256);

  function getExternalPositionRealUnit(address _component, address _positionModule)
    external
    view
    returns (int256);

  function getComponents() external view returns (address[] memory);

  function getExternalPositionModules(address _component) external view returns (address[] memory);

  function getExternalPositionData(address _component, address _positionModule)
    external
    view
    returns (bytes memory);

  function isExternalPositionModule(address _component, address _module)
    external
    view
    returns (bool);

  function isComponent(address _component) external view returns (bool);

  function positionMultiplier() external view returns (int256);

  function getPositions() external view returns (Position[] memory);

  function getTotalComponentRealUnits(address _component) external view returns (int256);

  function isInitializedModule(address _module) external view returns (bool);

  function isPendingModule(address _module) external view returns (bool);

  function isLocked() external view returns (bool);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

import {IDomani} from "../interfaces/IDomani.sol";

interface IDomaniValuer {
  function calculateDomaniValuation(IDomani _domani, address _quoteAsset)
    external
    view
    returns (uint256);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

interface IIntegrationRegistry {
  function addIntegration(
    address _module,
    string memory _id,
    address _wrapper
  ) external;

  function getIntegrationAdapter(address _module, string memory _id)
    external
    view
    returns (address);

  function getIntegrationAdapterWithHash(address _module, bytes32 _id)
    external
    view
    returns (address);

  function isValidIntegration(address _module, string memory _id) external view returns (bool);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

/**
 * @title IModule
 * @author Domani Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
  /**
   * Called by a Domani to notify that this module was removed from the Domani token. Any logic can be included
   * in case checks need to be made or state needs to be cleared.
   */
  function removeModule() external;
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

/**
 * @title IPriceOracle
 * @author Domani Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
  /* ============ Functions ============ */

  function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

  function masterQuoteAsset() external view returns (address);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

/**
 * @title AddressArrayUtils
 * @author Domani Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {
  /**
   * Finds the index of the first occurrence of the given element.
   * @param A The input array to search
   * @param a The value to find
   * @return Returns (index and isIn) for the first occurrence starting from index 0
   */
  function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
    uint256 length = A.length;
    for (uint256 i = 0; i < length; i++) {
      if (A[i] == a) {
        return (i, true);
      }
    }
    return (uint256(-1), false);
  }

  /**
   * Returns true if the value is present in the list. Uses indexOf internally.
   * @param A The input array to search
   * @param a The value to find
   * @return Returns isIn for the first occurrence starting from index 0
   */
  function contains(address[] memory A, address a) internal pure returns (bool) {
    (, bool isIn) = indexOf(A, a);
    return isIn;
  }

  /**
   * Returns true if there are 2 elements that are the same in an array
   * @param A The input array to search
   * @return Returns boolean for the first occurrence of a duplicate
   */
  function hasDuplicate(address[] memory A) internal pure returns (bool) {
    require(A.length > 0, "A is empty");

    for (uint256 i = 0; i < A.length - 1; i++) {
      address current = A[i];
      for (uint256 j = i + 1; j < A.length; j++) {
        if (current == A[j]) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * @param A The input array to search
   * @param a The address to remove
   * @return Returns the array with the object removed.
   */
  function remove(address[] memory A, address a) internal pure returns (address[] memory) {
    (uint256 index, bool isIn) = indexOf(A, a);
    if (!isIn) {
      revert("Address not in array.");
    } else {
      (address[] memory _A, ) = pop(A, index);
      return _A;
    }
  }

  /**
   * @param A The input array to search
   * @param a The address to remove
   */
  function removeStorage(address[] storage A, address a) internal {
    (uint256 index, bool isIn) = indexOf(A, a);
    if (!isIn) {
      revert("Address not in array.");
    } else {
      uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
      if (index != lastIndex) {
        A[index] = A[lastIndex];
      }
      A.pop();
    }
  }

  /**
   * Removes specified index from array
   * @param A The input array to search
   * @param index The index to remove
   * @return Returns the new array and the removed entry
   */
  function pop(address[] memory A, uint256 index)
    internal
    pure
    returns (address[] memory, address)
  {
    uint256 length = A.length;
    require(index < A.length, "Index must be < A length");
    address[] memory newAddresses = new address[](length - 1);
    for (uint256 i = 0; i < index; i++) {
      newAddresses[i] = A[i];
    }
    for (uint256 j = index + 1; j < length; j++) {
      newAddresses[j - 1] = A[j];
    }
    return (newAddresses, A[index]);
  }

  /**
   * Returns the combination of the two arrays
   * @param A The first array
   * @param B The second array
   * @return Returns A extended by B
   */
  function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
    uint256 aLength = A.length;
    uint256 bLength = B.length;
    address[] memory newAddresses = new address[](aLength + bLength);
    for (uint256 i = 0; i < aLength; i++) {
      newAddresses[i] = A[i];
    }
    for (uint256 j = 0; j < bLength; j++) {
      newAddresses[aLength + j] = B[j];
    }
    return newAddresses;
  }

  /**
   * Validate that address and uint array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of uint
   */
  function validatePairsWithArray(address[] memory A, uint256[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and bool array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of bool
   */
  function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and string array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of strings
   */
  function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address array lengths match, and calling address array are not empty
   * and contain no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of addresses
   */
  function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and bytes array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of bytes
   */
  function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate address array is not empty and contains no duplicate elements.
   *
   * @param A          Array of addresses
   */
  function _validateLengthAndUniqueness(address[] memory A) internal pure {
    require(A.length > 0, "Array length must be > 0");
    require(!hasDuplicate(A), "Cannot duplicate addresses");
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Domani Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
  using SafeMath for uint256;

  /**
   * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
   * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
   *
   * @param _token           ERC20 token to approve
   * @param _from            The account to transfer tokens from
   * @param _to              The account to transfer tokens to
   * @param _quantity        The quantity to transfer
   */
  function transferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal {
    // Call specified ERC20 contract to transfer tokens (via proxy).
    if (_quantity > 0) {
      uint256 existingBalance = _token.balanceOf(_to);

      SafeERC20.safeTransferFrom(_token, _from, _to, _quantity);

      uint256 newBalance = _token.balanceOf(_to);

      // Verify transfer quantity is reflected in balance
      require(newBalance == existingBalance.add(_quantity), "Invalid post transfer balance");
    }
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title PreciseUnitMath
 * @author Domani Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 */
library PreciseUnitMath {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;
  int256 internal constant PRECISE_UNIT_INT = 10**18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;
  // Max and min signed integer value
  int256 internal constant MAX_INT_256 = type(int256).max;
  int256 internal constant MIN_INT_256 = type(int256).min;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnitInt() internal pure returns (int256) {
    return PRECISE_UNIT_INT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxInt256() internal pure returns (int256) {
    return MAX_INT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function minInt256() internal pure returns (int256) {
    return MIN_INT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(PRECISE_UNIT);
  }

  /**
   * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
   * significand of a number with 18 decimals precision.
   */
  function preciseMul(int256 a, int256 b) internal pure returns (int256) {
    return a.mul(b).div(PRECISE_UNIT_INT);
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(PRECISE_UNIT).div(b);
  }

  /**
   * @dev Divides value a by value b (result is rounded towards 0).
   */
  function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
    return a.mul(PRECISE_UNIT_INT).div(b);
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Cant divide by 0");

    return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
  }

  /**
   * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
   */
  function divDown(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "Cant divide by 0");
    require(a != MIN_INT_256 || b != -1, "Invalid input");

    int256 result = a.div(b);
    if (a ^ b < 0 && a % b != 0) {
      result -= 1;
    }

    return result;
  }

  /**
   * @dev Multiplies value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a.mul(b), PRECISE_UNIT_INT);
  }

  /**
   * @dev Divides value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a.mul(PRECISE_UNIT_INT), b);
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, "Value must be positive");

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      // Using safemath multiplication prevents overflows
      result = previousResult.mul(a);
    }

    return result;
  }

  /**
   * @dev Returns true if a =~ b within range, false otherwise.
   */
  function approximatelyEquals(
    uint256 a,
    uint256 b,
    uint256 range
  ) internal pure returns (bool) {
    return a <= b.add(range) && a >= b.sub(range);
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IDomani} from "../../interfaces/IDomani.sol";

/**
 * @title Invoke
 * @author Domani Protocol
 *
 * A collection of common utility functions for interacting with the Domani's invoke function
 */
library Invoke {
  using SafeMath for uint256;

  /* ============ Internal ============ */

  /**
   * Instructs the Domani to domani approvals of the ERC20 token to a spender.
   *
   * @param _domani        Domani instance to invoke
   * @param _token           ERC20 token to approve
   * @param _spender         The account allowed to spend the Domani's balance
   * @param _quantity        The quantity of allowance to allow
   */
  function invokeApprove(
    IDomani _domani,
    address _token,
    address _spender,
    uint256 _quantity
  ) internal {
    bytes memory callData = abi.encodeWithSignature(
      "approve(address,uint256)",
      _spender,
      _quantity
    );
    _domani.invoke(_token, 0, callData);
  }

  /**
   * Instructs the Domani to transfer the ERC20 token to a recipient.
   *
   * @param _domani        Domani instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function invokeTransfer(
    IDomani _domani,
    address _token,
    address _to,
    uint256 _quantity
  ) internal {
    if (_quantity > 0) {
      bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
      _domani.invoke(_token, 0, callData);
    }
  }

  /**
   * Instructs the Domani to transfer the ERC20 token to a recipient.
   * The new Domani balance must equal the existing balance less the quantity transferred
   *
   * @param _domani        Domani instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function strictInvokeTransfer(
    IDomani _domani,
    address _token,
    address _to,
    uint256 _quantity
  ) internal {
    if (_quantity > 0) {
      // Retrieve current balance of token for the Domani
      uint256 existingBalance = IERC20(_token).balanceOf(address(_domani));

      Invoke.invokeTransfer(_domani, _token, _to, _quantity);

      // Get new balance of transferred token for Domani
      uint256 newBalance = IERC20(_token).balanceOf(address(_domani));

      // Verify only the transfer quantity is subtracted
      require(newBalance == existingBalance.sub(_quantity), "Invalid post transfer balance");
    }
  }

  /**
   * Instructs the Domani to unwrap the passed quantity of WETH
   *
   * @param _domani        Domani instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeUnwrapWETH(
    IDomani _domani,
    address _weth,
    uint256 _quantity
  ) internal {
    bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
    _domani.invoke(_weth, 0, callData);
  }

  /**
   * Instructs the Domani to wrap the passed quantity of ETH
   *
   * @param _domani        Domani instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeWrapWETH(
    IDomani _domani,
    address _weth,
    uint256 _quantity
  ) internal {
    bytes memory callData = abi.encodeWithSignature("deposit()");
    _domani.invoke(_weth, _quantity, callData);
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AddressArrayUtils} from "../../lib/AddressArrayUtils.sol";
import {ExplicitERC20} from "../../lib/ExplicitERC20.sol";
import {IController} from "../../interfaces/IController.sol";
import {IModule} from "../../interfaces/IModule.sol";
import {IDomani} from "../../interfaces/IDomani.sol";
import {Invoke} from "./Invoke.sol";
import {Position} from "./Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";
import {ResourceIdentifier} from "./ResourceIdentifier.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Domani Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
  using AddressArrayUtils for address[];
  using Invoke for IDomani;
  using Position for IDomani;
  using PreciseUnitMath for uint256;
  using ResourceIdentifier for IController;
  using SafeCast for int256;
  using SafeCast for uint256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  /* ============ State Variables ============ */

  // Address of the controller
  IController public controller;

  /* ============ Modifiers ============ */

  modifier onlyManagerAndValidDomani(IDomani _domani) {
    _validateOnlyManagerAndValidDomani(_domani);
    _;
  }

  modifier onlyDomaniManager(IDomani _domani, address _caller) {
    _validateOnlyDomaniManager(_domani, _caller);
    _;
  }

  modifier onlyValidAndInitializedDomani(IDomani _domani) {
    _validateOnlyValidAndInitializedDomani(_domani);
    _;
  }

  /**
   * Throws if the sender is not a Domani's module or module not enabled
   */
  modifier onlyModule(IDomani _domani) {
    _validateOnlyModule(_domani);
    _;
  }

  /**
   * Utilized during module initializations to check that the module is in pending state
   * and that the Domani is valid
   */
  modifier onlyValidAndPendingDomani(IDomani _domani) {
    _validateOnlyValidAndPendingDomani(_domani);
    _;
  }

  /* ============ Constructor ============ */

  /**
   * Domani state variables and map asset pairs to their oracles
   *
   * @param _controller             Address of controller contract
   */
  constructor(IController _controller) {
    controller = _controller;
  }

  /* ============ Internal Functions ============ */

  /**
   * Transfers tokens from an address (that has domani allowance on the module).
   *
   * @param  _token          The address of the ERC20 token
   * @param  _from           The address to transfer from
   * @param  _to             The address to transfer to
   * @param  _quantity       The number of tokens to transfer
   */
  function transferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal {
    ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
  }

  /**
   * Gets the integration for the module with the passed in name. Validates that the address is not empty
   */
  function getAndValidateAdapter(string memory _integrationName) internal view returns (address) {
    bytes32 integrationHash = getNameHash(_integrationName);
    return getAndValidateAdapterWithHash(integrationHash);
  }

  /**
   * Gets the integration for the module with the passed in hash. Validates that the address is not empty
   */
  function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns (address) {
    address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
      address(this),
      _integrationHash
    );

    require(adapter != address(0), "Must be valid adapter");
    return adapter;
  }

  /**
   * Gets the total fee for this module of the passed in index (fee % * quantity)
   */
  function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns (uint256) {
    uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
    return _quantity.preciseMul(feePercentage);
  }

  /**
   * Pays the _feeQuantity from the _domani denominated in _token to the protocol fee recipient
   */
  function payProtocolFeeFromDomani(
    IDomani _domani,
    address _token,
    uint256 _feeQuantity
  ) internal {
    if (_feeQuantity > 0) {
      _domani.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity);
    }
  }

  /**
   * Returns true if the module is in process of initialization on the Domani
   */
  function isDomaniPendingInitialization(IDomani _domani) internal view returns (bool) {
    return _domani.isPendingModule(address(this));
  }

  /**
   * Returns true if the address is the Domani's manager
   */
  function isDomaniManager(IDomani _domani, address _toCheck) internal view returns (bool) {
    return _domani.manager() == _toCheck;
  }

  /**
   * Returns true if Domani must be enabled on the controller
   * and module is registered on the Domani
   */
  function isDomaniValidAndInitialized(IDomani _domani) internal view returns (bool) {
    return controller.isDomani(address(_domani)) && _domani.isInitializedModule(address(this));
  }

  /**
   * Hashes the string and returns a bytes32 value
   */
  function getNameHash(string memory _name) internal pure returns (bytes32) {
    return keccak256(bytes(_name));
  }

  /* ============== Modifier Helpers ===============
   * Internal functions used to reduce bytecode size
   */

  /**
   * Caller must Domani manager and Domani must be valid and initialized
   */
  function _validateOnlyManagerAndValidDomani(IDomani _domani) internal view {
    require(isDomaniManager(_domani, msg.sender), "Must be the Domani manager");
    require(isDomaniValidAndInitialized(_domani), "Must be a valid and initialized Domani");
  }

  /**
   * Caller must Domani manager
   */
  function _validateOnlyDomaniManager(IDomani _domani, address _caller) internal view {
    require(isDomaniManager(_domani, _caller), "Must be the Domani manager");
  }

  /**
   * Domani must be valid and initialized
   */
  function _validateOnlyValidAndInitializedDomani(IDomani _domani) internal view {
    require(isDomaniValidAndInitialized(_domani), "Must be a valid and initialized Domani");
  }

  /**
   * Caller must be initialized module and module must be enabled on the controller
   */
  function _validateOnlyModule(IDomani _domani) internal view {
    require(
      _domani.moduleStates(msg.sender) == IDomani.ModuleState.INITIALIZED,
      "Only the module can call"
    );

    require(controller.isModule(msg.sender), "Module must be enabled on controller");
  }

  /**
   * Domani must be in a pending state and module must be in pending state
   */
  function _validateOnlyValidAndPendingDomani(IDomani _domani) internal view {
    require(controller.isDomani(address(_domani)), "Must be controller-enabled Domani");
    require(isDomaniPendingInitialization(_domani), "Must be pending initialization");
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {IDomani} from "../../interfaces/IDomani.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title Position
 * @author Domani Protocol
 *
 * Collection of helper functions for handling and updating Domani Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
  using SafeCast for uint256;
  using SafeMath for uint256;
  using SafeCast for int256;
  using SignedSafeMath for int256;
  using PreciseUnitMath for uint256;

  /* ============ Helper ============ */

  /**
   * Returns whether the Domani has a default position for a given component (if the real unit is > 0)
   */
  function hasDefaultPosition(IDomani _domani, address _component) internal view returns (bool) {
    return _domani.getDefaultPositionRealUnit(_component) > 0;
  }

  /**
   * Returns whether the Domani has an external position for a given component (if # of position modules is > 0)
   */
  function hasExternalPosition(IDomani _domani, address _component) internal view returns (bool) {
    return _domani.getExternalPositionModules(_component).length > 0;
  }

  /**
   * Returns whether the Domani component default position real unit is greater than or equal to units passed in.
   */
  function hasSufficientDefaultUnits(
    IDomani _domani,
    address _component,
    uint256 _unit
  ) internal view returns (bool) {
    return _domani.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
  }

  /**
   * Returns whether the Domani component external position is greater than or equal to the real units passed in.
   */
  function hasSufficientExternalUnits(
    IDomani _domani,
    address _component,
    address _positionModule,
    uint256 _unit
  ) internal view returns (bool) {
    return _domani.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();
  }

  /**
   * If the position does not exist, create a new Position and add to the Domani. If it already exists,
   * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
   * components where needed (in light of potential external positions).
   *
   * @param _domani           Address of Domani being modified
   * @param _component          Address of the component
   * @param _newUnit            Quantity of Position units - must be >= 0
   */
  function editDefaultPosition(
    IDomani _domani,
    address _component,
    uint256 _newUnit
  ) internal {
    bool isPositionFound = hasDefaultPosition(_domani, _component);
    if (!isPositionFound && _newUnit > 0) {
      // If there is no Default Position and no External Modules, then component does not exist
      if (!hasExternalPosition(_domani, _component)) {
        _domani.addComponent(_component);
      }
    } else if (isPositionFound && _newUnit == 0) {
      // If there is a Default Position and no external positions, remove the component
      if (!hasExternalPosition(_domani, _component)) {
        _domani.removeComponent(_component);
      }
    }

    _domani.editDefaultPositionUnit(_component, _newUnit.toInt256());
  }

  /**
   * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
   * 1) If component is not already added then add component and external position.
   * 2) If component is added but no existing external position using the passed module exists then add the external position.
   * 3) If the existing position is being added to then just update the unit and data
   * 4) If the position is being closed and no other external positions or default positions are associated with the component
   *    then untrack the component and remove external position.
   * 5) If the position is being closed and other existing positions still exist for the component then just remove the
   *    external position.
   *
   * @param _domani         Domani being updated
   * @param _component        Component position being updated
   * @param _module           Module external position is associated with
   * @param _newUnit          Position units of new external position
   * @param _data             Arbitrary data associated with the position
   */
  function editExternalPosition(
    IDomani _domani,
    address _component,
    address _module,
    int256 _newUnit,
    bytes memory _data
  ) internal {
    if (_newUnit != 0) {
      if (!_domani.isComponent(_component)) {
        _domani.addComponent(_component);
        _domani.addExternalPositionModule(_component, _module);
      } else if (!_domani.isExternalPositionModule(_component, _module)) {
        _domani.addExternalPositionModule(_component, _module);
      }
      _domani.editExternalPositionUnit(_component, _module, _newUnit);
      _domani.editExternalPositionData(_component, _module, _data);
    } else {
      require(_data.length == 0, "Passed data must be null");
      // If no default or external position remaining then remove component from components array
      if (_domani.getExternalPositionRealUnit(_component, _module) != 0) {
        address[] memory positionModules = _domani.getExternalPositionModules(_component);
        if (_domani.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
          require(
            positionModules[0] == _module,
            "External positions must be 0 to remove component"
          );
          _domani.removeComponent(_component);
        }
        _domani.removeExternalPositionModule(_component, _module);
      }
    }
  }

  /**
   * Get total notional amount of Default position
   *
   * @param _domaniSupply     Supply of Domani in precise units (10^18)
   * @param _positionUnit       Quantity of Position units
   *
   * @return                    Total notional amount of units
   */
  function getDefaultTotalNotional(uint256 _domaniSupply, uint256 _positionUnit)
    internal
    pure
    returns (uint256)
  {
    return _domaniSupply.preciseMul(_positionUnit);
  }

  /**
   * Get position unit from total notional amount
   *
   * @param _domaniSupply     Supply of Domani in precise units (10^18)
   * @param _totalNotional      Total notional amount of component prior to
   * @return                    Default position unit
   */
  function getDefaultPositionUnit(uint256 _domaniSupply, uint256 _totalNotional)
    internal
    pure
    returns (uint256)
  {
    return _totalNotional.preciseDiv(_domaniSupply);
  }

  /**
   * Get the total tracked balance - total supply * position unit
   *
   * @param _domani           Address of the Domani
   * @param _component          Address of the component
   * @return                    Notional tracked balance
   */
  function getDefaultTrackedBalance(IDomani _domani, address _component)
    internal
    view
    returns (uint256)
  {
    int256 positionUnit = _domani.getDefaultPositionRealUnit(_component);
    return _domani.totalSupply().preciseMul(positionUnit.toUint256());
  }

  /**
   * Calculates the new default position unit and performs the edit with the new unit
   *
   * @param _domani                 Address of the Domani
   * @param _component                Address of the component
   * @param _setTotalSupply           Current Domani supply
   * @param _componentPreviousBalance Pre-action component balance
   * @return                          Current component balance
   * @return                          Previous position unit
   * @return                          New position unit
   */
  function calculateAndEditDefaultPosition(
    IDomani _domani,
    address _component,
    uint256 _setTotalSupply,
    uint256 _componentPreviousBalance
  )
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 currentBalance = IERC20(_component).balanceOf(address(_domani));
    uint256 positionUnit = _domani.getDefaultPositionRealUnit(_component).toUint256();

    uint256 newTokenUnit;
    if (currentBalance > 0) {
      newTokenUnit = calculateDefaultEditPositionUnit(
        _setTotalSupply,
        _componentPreviousBalance,
        currentBalance,
        positionUnit
      );
    } else {
      newTokenUnit = 0;
    }

    editDefaultPosition(_domani, _component, newTokenUnit);

    return (currentBalance, positionUnit, newTokenUnit);
  }

  /**
   * Calculate the new position unit given total notional values pre and post executing an action that changes Domani state
   * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
   *
   * @param _domaniSupply     Supply of Domani in precise units (10^18)
   * @param _preTotalNotional   Total notional amount of component prior to executing action
   * @param _postTotalNotional  Total notional amount of component after the executing action
   * @param _prePositionUnit    Position unit of Domani prior to executing action
   * @return                    New position unit
   */
  function calculateDefaultEditPositionUnit(
    uint256 _domaniSupply,
    uint256 _preTotalNotional,
    uint256 _postTotalNotional,
    uint256 _prePositionUnit
  ) internal pure returns (uint256) {
    // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
    uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_domaniSupply));
    return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_domaniSupply);
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IController} from "../../interfaces/IController.sol";
import {IIntegrationRegistry} from "../../interfaces/IIntegrationRegistry.sol";
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {IDomaniValuer} from "../../interfaces/IDomaniValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Domani Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {
  // IntegrationRegistry will always be resource ID 0 in the system
  uint256 internal constant INTEGRATION_REGISTRY_RESOURCE_ID = 0;
  // PriceOracle will always be resource ID 1 in the system
  uint256 internal constant PRICE_ORACLE_RESOURCE_ID = 1;
  // DomaniValuer resource will always be resource ID 2 in the system
  uint256 internal constant SET_VALUER_RESOURCE_ID = 2;

  /* ============ Internal ============ */

  /**
   * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
   * the Controller
   */
  function getIntegrationRegistry(IController _controller)
    internal
    view
    returns (IIntegrationRegistry)
  {
    return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
  }

  /**
   * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
   */
  function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
    return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
  }

  /**
   * Gets the instance of Domani valuer on Controller. Note: DomaniValuer is stored as index 2 on the Controller
   */
  function getDomaniValuer(IController _controller) internal view returns (IDomaniValuer) {
    return IDomaniValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
  }
}

/*
    Copyright 2021 Memento Blockchain Pte. Ltd. 

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {AddressArrayUtils} from "../../lib/AddressArrayUtils.sol";
import {IController} from "../../interfaces/IController.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IIntegrationRegistry} from "../../interfaces/IIntegrationRegistry.sol";
import {Invoke} from "../lib/Invoke.sol";
import {IDomani} from "../../interfaces/IDomani.sol";
import {ModuleBase} from "../lib/ModuleBase.sol";
import {Position} from "../lib/Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title DextfTradeModule
 * @author DEXTF Protocol
 *
 * Module that enables DEXTF fund managers to propose a new trade. If this trade is approved and
 * not blocked, after the proposal period, the fund manager can transition to the fund to the trading
 * state, where market makers can rebalance the fund by sending inbound components and recieving the
 * outbound ones as specified by the proposed trade.
 */

contract DextfTradeModule is ModuleBase, ReentrancyGuard, AccessControl {
  using AddressArrayUtils for address[];
  using Invoke for IDomani;
  using Position for IDomani;
  using PreciseUnitMath for uint256;
  using SafeCast for int256;
  using SafeMath for uint256;

  // **** Enumerations
  enum FundState {
    REGULAR,
    PROPOSAL,
    TRADING
  }

  // **** Data structures
  struct ProposalConstraints {
    // The minimum time delay between the proposal state and the trading state
    uint256 minimumDelay;
    // The minimum number of approver votes to transition to the trading state
    uint256 minimumApproverVotes;
    // The minimum number of blocker votes needed to stop a trade proposal
    uint256 minimumBlockerVotes;
  }

  struct TradeComponent {
    // The address of the component to be traded
    address componentAddress;
    // The traded quantity, in real units
    uint256 tradeRealUnits;
  }

  struct ProposedTrade {
    // The Specific contraints for this proposal
    ProposalConstraints proposalConstraints;
    // The list of trade components that will be sent to the fund when trading
    TradeComponent[] inboundTradeComponents;
    // The list of trade components that will be sent to the trader when trading
    TradeComponent[] outboundTradeComponents;
    // The maximum number of fund tokens that can be traded
    uint256 maxTradedFundTokens;
    // The number of fund tokens that have been traded so far
    uint256 tradedFundTokens;
    // The timestamp of the most-recent trade proposal
    uint256 proposalTimestamp;
    // The list of approvers that voted for the proposal, empty at the beginning of the proposal
    address[] approverVotes;
    // The list of blockers that voted against the proposal, empty at the beginning of the proposal
    address[] blockerVotes;
  }

  // **** Events
  event ProposalConstraintsUpdated(
    uint256 minimumDelay,
    uint256 minimumApproverVotes,
    uint256 minimumBlockerVotes
  );

  event TradeProposed(
    IDomani indexed fund,
    uint256 indexed proposalTimestamp,
    uint256 maxTradedFundTokens,
    uint256 minimumDelay,
    uint256 minimumApproverVotes,
    uint256 minimumBlockerVotes,
    uint256 inboundComponentsCount,
    uint256 outboundComponentsCount
  );

  event ApprovalVoteCast(
    IDomani indexed fund,
    uint256 indexed proposalTimestamp,
    address indexed voter
  );

  event BlockerVoteCast(
    IDomani indexed fund,
    uint256 indexed proposalTimestamp,
    address indexed voter
  );

  event TradingStarted(IDomani indexed fund, uint256 indexed proposalTimestamp);

  event InboundComponentReceived(
    IDomani indexed domani,
    uint256 indexed proposalTimestamp,
    address indexed marketMaker,
    address inToken,
    uint256 inboundAmount
  );

  event OutboundComponentSent(
    IDomani indexed domani,
    uint256 indexed proposalTimestamp,
    address indexed marketMaker,
    address outToken,
    uint256 outboundAmount
  );

  // **** Constants
  bytes32 public constant TRADE_ADMIN_ROLE = keccak256("TRADE_ADMIN_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
  bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");
  bytes32 public constant MARKET_MAKER_ROLE = keccak256("MARKET_MAKER_ROLE");

  // **** State variables

  // These are the minimum values to be enforced for all trade proposal for all funds
  ProposalConstraints public moduleConstraints;

  // For each fund the relevant data for the current propsed trade
  mapping(IDomani => ProposedTrade) public proposalDetails;

  // The state of each fund
  mapping(IDomani => FundState) public fundState;

  // **** Constructor
  constructor(
    IController _controller,
    uint256 _minimumDelay,
    uint256 _minimumApproverVotes,
    uint256 _minimumBlockerVotes,
    address[] memory _administrators,
    address[] memory _approvers,
    address[] memory _blockers,
    address[] memory _marketMakers
  ) ModuleBase(_controller) {
    _setRoleAdmin(TRADE_ADMIN_ROLE, TRADE_ADMIN_ROLE);
    _setRoleAdmin(APPROVER_ROLE, TRADE_ADMIN_ROLE);
    _setRoleAdmin(BLOCKER_ROLE, TRADE_ADMIN_ROLE);
    _setRoleAdmin(MARKET_MAKER_ROLE, TRADE_ADMIN_ROLE);

    require(_administrators.length > 0, "At least one administrator is required");

    // Register administrators
    for (uint256 i = 0; i < _administrators.length; ++i) {
      _setupRole(TRADE_ADMIN_ROLE, _administrators[i]);
    }

    // Register approvers
    for (uint256 i = 0; i < _approvers.length; ++i) {
      _setupRole(APPROVER_ROLE, _approvers[i]);
    }

    // Register blockers
    for (uint256 i = 0; i < _blockers.length; ++i) {
      _setupRole(BLOCKER_ROLE, _blockers[i]);
    }

    // Register market makers
    for (uint256 i = 0; i < _marketMakers.length; ++i) {
      _setupRole(MARKET_MAKER_ROLE, _marketMakers[i]);
    }

    _updateProposalConstraints(_minimumDelay, _minimumApproverVotes, _minimumBlockerVotes);
  }

  // **** Modifiers
  /**
   * @dev Modifier to make a function callable only by a certain role.
   */
  modifier onlyRole(bytes32 role) {
    require(hasRole(role, _msgSender()), "Sender requires permission");
    _;
  }

  /**
   * @dev Modifier to make a function callable only by a certain role. In
   * addition to checking the sender's role, `address(0)` 's role is also
   * considered. Granting a role to `address(0)` is equivalent to enabling
   * this role for everyone.
   */
  modifier onlyRoleOrOpenRole(bytes32 role) {
    require(
      hasRole(role, _msgSender()) || hasRole(role, address(0)),
      "Sender requires permission, or open role"
    );
    _;
  }

  // **** External functions called by the Domani smart contract

  /**
   * Initializes this module to the Domani. Only callable by the Domani's manager.
   *
   * @param _fund         Address of the Domani
   */
  function initialize(IDomani _fund)
    external
    onlyDomaniManager(_fund, msg.sender)
    onlyValidAndPendingDomani(_fund)
  {
    fundState[_fund] = FundState.REGULAR;
    _fund.initializeModule();
  }

  /**
   * Called by a Domani to notify that this module was removed.
   * Clears the proposalDetails and the fundState.
   */
  function removeModule() external override {
    delete proposalDetails[IDomani(msg.sender)];
    delete fundState[IDomani(msg.sender)];
  }

  // **** External functions called only by the trade administrator
  /**
   * ONLY BY ADMINISTRATOR: updates the module-wide proposal constraints.
   *
   * @param _minimumDelay          The minimum time delay between the proposal state and the trading state
   * @param _minimumApproverVotes  The minimum number of approver votes to transition to the trading state
   * @param _minimumBlockerVotes   The minimum number of blocker votes needed to stop a trade proposal
   */

  function updateProposalConstraints(
    uint256 _minimumDelay,
    uint256 _minimumApproverVotes,
    uint256 _minimumBlockerVotes
  ) external nonReentrant onlyRole(TRADE_ADMIN_ROLE) {
    _updateProposalConstraints(_minimumDelay, _minimumApproverVotes, _minimumBlockerVotes);
  }

  // **** External functions called by the fund manager
  /**
   * ONLY FUND MANAGER: regardless of the current fund state, transition the fund to the regular state.
   * It can be use both to cancel a prposal or to cancel trading.
   *
   * @param _fund   Address of the fund to be transitioned to the regular state
   */
  function revertToRegularState(IDomani _fund) external onlyManagerAndValidDomani(_fund) {
    require(fundState[_fund] != FundState.REGULAR, "Already in regular state");
    fundState[_fund] = FundState.REGULAR;
  }

  /**
   * ONLY FUND MANAGER: propose a new trade together with new constraint and transition a fund
   * from the regular state to the proposal state. There are no checks on the proposed trade as
   * these checks are left to the approvers and blockers.
   *
   * @param _fund                    Address of the fund subject of the trade
   * @param _maxTradedFundTokens     The maximum number of fund tokens that can be traded
   * @param _proposalConstraints     The constraints for this proposal
   * @param _inboundAddresses        The component addresses entering the fund
   * @param _outboundAddresses       The component addresses exiting the fund
   * @param _inboundRealUnitsArray   The value of the incoming tokens per fund token, in real units
   * @param _outboundRealUnitsArray  The value of the outgoing tokens per fund token, in real units
   */

  function proposeTrade(
    IDomani _fund,
    uint256 _maxTradedFundTokens,
    ProposalConstraints calldata _proposalConstraints,
    address[] calldata _inboundAddresses,
    uint256[] calldata _inboundRealUnitsArray,
    address[] calldata _outboundAddresses,
    uint256[] calldata _outboundRealUnitsArray
  ) external onlyManagerAndValidDomani(_fund) {
    // Check that the fund was in the regular state
    require(fundState[_fund] == FundState.REGULAR, "Fund must be in the regular state");

    // Check that the proposal constraints are compatible with the module-wise constraints
    require(
      _proposalConstraints.minimumDelay >= moduleConstraints.minimumDelay,
      "minimum delay too short"
    );
    require(
      _proposalConstraints.minimumApproverVotes >= moduleConstraints.minimumApproverVotes,
      "minimum approvers too small"
    );
    require(
      _proposalConstraints.minimumBlockerVotes >= moduleConstraints.minimumBlockerVotes,
      "minimum blockers too small"
    );

    // Check that the proposed trade is not empty
    require(_inboundAddresses.length > 0, "Inbound addresses cannot be empty");
    require(_outboundAddresses.length > 0, "Outbound addresses cannot be empty");
    // Check for vector consistency
    require(_inboundRealUnitsArray.length == _inboundAddresses.length, "Mismatch inbound lenghts");
    require(
      _outboundAddresses.length == _outboundRealUnitsArray.length,
      "Mismatch outbound lenghts"
    );

    // Make sure there is no null address in either inbound or outbound components
    require(!_inboundAddresses.contains(address(0)), "Null address in inbound componets");
    require(!_outboundAddresses.contains(address(0)), "Null address in outbound componets");

    // Check that there are non duplicate in the component addresses
    require(
      !_inboundAddresses.extend(_outboundAddresses).hasDuplicate(),
      "Duplicate components are not allowed"
    );

    // Check that max number of fund tokens traded is bigger than 0
    require(_maxTradedFundTokens > 0, "Max number of traded tokens must be bigger than 0");

    // Keep track of the maxium tokens to be traded
    proposalDetails[_fund].maxTradedFundTokens = _maxTradedFundTokens;

    // Reset the number of fund tokens that have been traded so far
    proposalDetails[_fund].tradedFundTokens = 0;

    // Save the current block timestamp as the proposal timestamp
    // solhint-disable-next-line not-rely-on-time
    proposalDetails[_fund].proposalTimestamp = block.timestamp;

    // Update the proposal constraints and the new allocation components
    proposalDetails[_fund].proposalConstraints.minimumDelay = _proposalConstraints.minimumDelay;

    proposalDetails[_fund].proposalConstraints.minimumApproverVotes = _proposalConstraints
    .minimumApproverVotes;

    proposalDetails[_fund].proposalConstraints.minimumBlockerVotes = _proposalConstraints
    .minimumBlockerVotes;

    // Reset the previous proposal votes
    delete proposalDetails[_fund].approverVotes;
    delete proposalDetails[_fund].blockerVotes;

    // Destroy the previous and create the new inboundTradeComponents vector
    delete proposalDetails[_fund].inboundTradeComponents;

    // Loop and push the inbound components
    for (uint256 i = 0; i < _inboundAddresses.length; i++) {
      proposalDetails[_fund].inboundTradeComponents.push(
        TradeComponent({
          componentAddress: _inboundAddresses[i],
          tradeRealUnits: _inboundRealUnitsArray[i]
        })
      );
    }

    // Destroy the previous and create the new outboundTradeComponents vector
    delete proposalDetails[_fund].outboundTradeComponents;

    // Loop and push the outbound components
    for (uint256 i = 0; i < _outboundAddresses.length; i++) {
      proposalDetails[_fund].outboundTradeComponents.push(
        TradeComponent({
          componentAddress: _outboundAddresses[i],
          tradeRealUnits: _outboundRealUnitsArray[i]
        })
      );
    }

    // Check that outboud components are compatible with the current fund holdings
    _checkOutboundComponents(_fund);

    fundState[_fund] = FundState.PROPOSAL;

    emit TradeProposed(
      _fund,
      block.timestamp,
      _maxTradedFundTokens,
      _proposalConstraints.minimumDelay,
      _proposalConstraints.minimumApproverVotes,
      _proposalConstraints.minimumBlockerVotes,
      _inboundAddresses.length,
      _outboundAddresses.length
    );
  }

  /**
   * ONLY FUND MANAGER: Transition the fund from the proposal state to the trading state if all
   * constranits are satifid: the minimum proposal time has elapsed, there are enough approval votes
   * and there are not too many blocker votes.
   *
   * @param _fund             Address of the fund for which trading can start
   */
  function startTrading(IDomani _fund) external onlyManagerAndValidDomani(_fund) {
    // Check that the fund was in the proposal state
    require(fundState[_fund] == FundState.PROPOSAL, "Fund must be in the proposal state");

    // Check that we are after the proposed period
    require(
      block.timestamp >=
        proposalDetails[_fund].proposalTimestamp.add(
          proposalDetails[_fund].proposalConstraints.minimumDelay
        ),
      "Proposal period not over yet"
    );

    // Check that there are not enough blocker votes
    if (proposalDetails[_fund].proposalConstraints.minimumBlockerVotes > 0) {
      require(
        proposalDetails[_fund].blockerVotes.length <
          proposalDetails[_fund].proposalConstraints.minimumBlockerVotes,
        "Too many blocker votes"
      );
    }

    // Check that there are enough approval votes
    require(
      proposalDetails[_fund].approverVotes.length >=
        proposalDetails[_fund].proposalConstraints.minimumApproverVotes,
      "Not enough approval votes"
    );

    // Transition the fund to the trading state
    fundState[_fund] = FundState.TRADING;

    emit TradingStarted(_fund, proposalDetails[_fund].proposalTimestamp);
  }

  // **** External functions called by approvers
  /**
   * ONLY APPROVERS: called by an approver to cast an approval vote to the latest proposal on a certain fund.
   * Once the vote is cast it cannot be retracted.
   *
   * @param _fund      Address of the fund for which the approval vote is cast
   */
  function castApprovalVote(IDomani _fund) external onlyRole(APPROVER_ROLE) {
    // Check that the fund is in the proposal state
    require(fundState[_fund] == FundState.PROPOSAL, "Fund must be in proposal state");

    // Check that this approver hasn't voted yet
    require(
      !proposalDetails[_fund].approverVotes.contains(msg.sender),
      "Approver has already voted"
    );

    // Add the approval vote to the tally
    proposalDetails[_fund].approverVotes.push(msg.sender);

    emit ApprovalVoteCast(_fund, proposalDetails[_fund].proposalTimestamp, msg.sender);
  }

  // **** External functions called by blockers
  /**
   * ONLY BLOCKERS: called by a blocker to cast a blocking vote to the latest proposal on a certain fund.
   * Once the vote is cast it cannot be retracted.
   *
   * @param _fund      Address of the fund for which the blocker vote is cast
   */
  function castBlockerVote(IDomani _fund) external onlyRole(BLOCKER_ROLE) {
    // Check that the fund is in the proposal state
    require(fundState[_fund] == FundState.PROPOSAL, "Fund must be in proposal state");

    // Check that this blocker hasn't voted yet
    require(!proposalDetails[_fund].blockerVotes.contains(msg.sender), "Blocker has already voted");

    // Add the approval vote to the tally
    proposalDetails[_fund].blockerVotes.push(msg.sender);

    emit BlockerVoteCast(_fund, proposalDetails[_fund].proposalTimestamp, msg.sender);
  }

  // **** External functions called by market makers
  /**
   * ONLY MARKET MAKERS: called by market makers to perform the actual trade by sending inboud components
   * and receiveing outbound ones.
   *
   * @param _fund      Address of the fund for which want to perform the trade
   * @param _quantity  The equivalent number of fund tokens to be traded
   *
   */
  function performTrade(IDomani _fund, uint256 _quantity)
    external
    nonReentrant
    onlyRoleOrOpenRole(MARKET_MAKER_ROLE)
  {
    // Check that the fund is in the trading state
    require(fundState[_fund] == FundState.TRADING, "Fund must be in trading state");

    // Check that the quantity is positive
    require(_quantity > 0, "Quantity must be positive");

    // Compute total fund supply
    uint256 fundTotalSupply = _fund.totalSupply();

    // Check that the quantity is not larger than the total supply
    require(_quantity <= fundTotalSupply, "Quantity exceeds total supply");

    // Check that we do traded more fund tokens than originally intended
    uint256 newTotalQuantity = proposalDetails[_fund].tradedFundTokens.add(_quantity);
    require(
      newTotalQuantity <= proposalDetails[_fund].maxTradedFundTokens,
      "Maximum quantity of traded fund tokens exceeded"
    );

    // We need to perform this check again because the positions might have changed since proposal
    _checkOutboundComponents(_fund);

    // We store the component current balances before trading, to keep track of airdrops
    uint256[] memory preTradeInboundBalances = _computePreTradeBalances(
      _fund,
      proposalDetails[_fund].inboundTradeComponents
    );

    uint256[] memory preTradeOutboundBalances = _computePreTradeBalances(
      _fund,
      proposalDetails[_fund].outboundTradeComponents
    );

    // Compute quantity-scaled inbound/outbound components
    (
      TradeComponent[] memory scaledInboundComponents,
      TradeComponent[] memory scaledOutboundComponents
    ) = _scaleComponents(_fund, _quantity);

    // Trade the outbound components for the inbound ones
    _tradeInboundComponents(_fund, scaledInboundComponents);
    _tradeOutboundComponents(_fund, scaledOutboundComponents);

    // Update the fund positions after the trade
    _updateFundPositions(
      _fund,
      proposalDetails[_fund].inboundTradeComponents,
      fundTotalSupply,
      preTradeInboundBalances
    );
    _updateFundPositions(
      _fund,
      proposalDetails[_fund].outboundTradeComponents,
      fundTotalSupply,
      preTradeOutboundBalances
    );

    // Update the quanity if tokens traded so far
    proposalDetails[_fund].tradedFundTokens = newTotalQuantity;
  }

  // **** External views

  /**
   * Returns the latest proposal details for a given fund.
   *
   * @param _fund Address of the fund for which the proposal details are needed
   *
   * @return proposalDetails The latest trade proposal details for the given fund
   */
  function getProposalDetails(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (ProposedTrade memory)
  {
    return proposalDetails[_fund];
  }

  /**
   * Retrieves the timestamp of the current fund proposal.
   *
   * @param _fund  Fund for which we want to query the proposal timestamp
   *
   * @return proposalTimestamp    The latest proposal timestamp for the given fund
   */
  function getProposalTimestamp(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (uint256)
  {
    return proposalDetails[_fund].proposalTimestamp;
  }

  /**
   * Retrieves the constraints of the current fund proposal.
   *
   * @param _fund                  Fund for which we want to query the proposal constraints
   *
   * @return minimumDelay          The minimum time delay between the proposal state and the trading state
   * @return minimumApproverVotes  The minimum number of approver votes to transition to the trading state
   * @return minimumBlockerVotes   he minimum number of blocker votes needed to stop a proposal
   */
  function getProposalConstraints(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      proposalDetails[_fund].proposalConstraints.minimumDelay,
      proposalDetails[_fund].proposalConstraints.minimumApproverVotes,
      proposalDetails[_fund].proposalConstraints.minimumBlockerVotes
    );
  }

  /**
   * Retrieves the proposed inbound allocation components, in real units.
   *
   * @param _fund                 Fund for which we want to query the inbound components
   *
   * @return _componentAddresses      The addresses of the proposed inbound components
   * @return _positionRealUnitsArray  The value of the inbound component flow
   */
  function getProposedInboundComponents(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (address[] memory, uint256[] memory)
  {
    // Allocate the memory for the arrays
    address[] memory componentAddresses = new address[](
      proposalDetails[_fund].inboundTradeComponents.length
    );
    uint256[] memory tradeRealUnitsArray = new uint256[](
      proposalDetails[_fund].inboundTradeComponents.length
    );

    // Transpose the inboundTradeComponents array
    for (uint256 i = 0; i < proposalDetails[_fund].inboundTradeComponents.length; i++) {
      componentAddresses[i] = proposalDetails[_fund].inboundTradeComponents[i].componentAddress;
      tradeRealUnitsArray[i] = proposalDetails[_fund].inboundTradeComponents[i].tradeRealUnits;
    }

    return (componentAddresses, tradeRealUnitsArray);
  }

  /**
   * Retrieves the proposed outbound allocation components, in real units.
   *
   * @param _fund                 Fund for which we want to query the outbound components
   *
   * @return _componentAddresses      The addresses of the proposed outbound components
   * @return _positionRealUnitsArray  The value of the outbound component flow
   */
  function getProposedOutboundComponents(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (address[] memory, uint256[] memory)
  {
    // Allocate the memory for the arrays
    address[] memory componentAddresses = new address[](
      proposalDetails[_fund].outboundTradeComponents.length
    );
    uint256[] memory tradeRealUnitsArray = new uint256[](
      proposalDetails[_fund].outboundTradeComponents.length
    );

    // Transpose the outboundTradeComponents array
    for (uint256 i = 0; i < proposalDetails[_fund].outboundTradeComponents.length; i++) {
      componentAddresses[i] = proposalDetails[_fund].outboundTradeComponents[i].componentAddress;
      tradeRealUnitsArray[i] = proposalDetails[_fund].outboundTradeComponents[i].tradeRealUnits;
    }

    return (componentAddresses, tradeRealUnitsArray);
  }

  /**
   * Retrieves the latest tally of the approver votes cast on the most recent proposal.
   *
   * @param _fund                 Fund for which we want to query the approver votes
   *
   * @return approverVotes        The array of approvers that cast a vote on the latest proposal
   */
  function getApprovalVotes(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (address[] memory)
  {
    return proposalDetails[_fund].approverVotes;
  }

  /**
   * Retrieves the latest tally of the blocker votes cast on the most recent proposal.
   *
   * @param _fund                 Fund for which we want to query the blocker votes
   *
   * @return blockerVotes        The array of blockers that cast a vote on the latest proposal
   */
  function getBlockerVotes(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (address[] memory)
  {
    return proposalDetails[_fund].blockerVotes;
  }

  /**
   * Retrieves the currently and maximum equivalent traded fund tokens
   *
   * @param _fund                 Fund for which we want to query the equivalent traded fund tokens
   *
   * @return tradedFundTokens     The equivalent number of fund tokens that have been traded so far
   * @return maxTradedFundTokens  The maximum number of equivalent fund tokens that can be traded
   */
  function getTradedFundTokens(IDomani _fund)
    external
    view
    onlyValidAndInitializedDomani(_fund)
    returns (uint256, uint256)
  {
    return (proposalDetails[_fund].tradedFundTokens, proposalDetails[_fund].maxTradedFundTokens);
  }

  /**
   * Compute the proposed/actual trade components according to the given quantity
   *
   * @param _fund         Address of the fund subject of the trade
   * @param _quantity     The number of fund base units to be traded
   *
   * @return address[]           The array of inbound addresses
   * @return uint256[]           The array of inbound quantities in real units
   * @return address[]           The array of outbound addresses
   * @return uint256[]           The array of outbound quantities in real units
   */
  function computeInboundOutboundComponents(IDomani _fund, uint256 _quantity)
    public
    view
    onlyValidAndInitializedDomani(_fund)
    returns (
      address[] memory,
      uint256[] memory,
      address[] memory,
      uint256[] memory
    )
  {
    // Compute quantity-scaled inbound/outbound components
    (
      TradeComponent[] memory scaledInboundComponents,
      TradeComponent[] memory scaledOutboundComponents
    ) = _scaleComponents(_fund, _quantity);

    // Reserve the correct memory space for all arrays
    address[] memory inboundAddresses = new address[](scaledInboundComponents.length);
    uint256[] memory inboundRealUnitsArray = new uint256[](scaledInboundComponents.length);
    address[] memory outboundAddresses = new address[](scaledOutboundComponents.length);
    uint256[] memory outboundRealUnitsArray = new uint256[](scaledOutboundComponents.length);

    // Traspose the inbound vectors
    for (uint256 i = 0; i < inboundAddresses.length; i++) {
      inboundAddresses[i] = scaledInboundComponents[i].componentAddress;
      inboundRealUnitsArray[i] = scaledInboundComponents[i].tradeRealUnits;
    }

    // Traspose the outbound vectors
    for (uint256 i = 0; i < outboundAddresses.length; i++) {
      outboundAddresses[i] = scaledOutboundComponents[i].componentAddress;
      outboundRealUnitsArray[i] = scaledOutboundComponents[i].tradeRealUnits;
    }

    return (inboundAddresses, inboundRealUnitsArray, outboundAddresses, outboundRealUnitsArray);
  }

  // **** Internal functions

  /**
   * Private function to update the module-wide minimum proposal constraints.
   *
   * @param _minimumDelay          The minimum time delay between the proposal state and the trading state
   * @param _minimumApproverVotes  The minimum number of approver votes to transition to the trading state
   * @param _minimumBlockerVotes   The minimum number of blocker votes needed to stop a proposal
   */
  function _updateProposalConstraints(
    uint256 _minimumDelay,
    uint256 _minimumApproverVotes,
    uint256 _minimumBlockerVotes
  ) internal {
    moduleConstraints.minimumDelay = _minimumDelay;
    moduleConstraints.minimumApproverVotes = _minimumApproverVotes;
    moduleConstraints.minimumBlockerVotes = _minimumBlockerVotes;

    emit ProposalConstraintsUpdated(_minimumDelay, _minimumApproverVotes, _minimumBlockerVotes);
  }

  /**
   * Trades the inbound components from the transaction sender to the fund contract.
   * Note that the tokens need to be approved before they can be transferred.
   *
   * @param _fund                     Address of the fund subject of the trade
   * @param _scaledInboundComponents  The inbound components to be received
   */
  function _tradeInboundComponents(IDomani _fund, TradeComponent[] memory _scaledInboundComponents)
    internal
  {
    // Transfer the inbound components
    for (uint256 i = 0; i < _scaledInboundComponents.length; i++) {
      transferFrom(
        IERC20(_scaledInboundComponents[i].componentAddress),
        msg.sender,
        address(_fund),
        _scaledInboundComponents[i].tradeRealUnits
      );

      emit InboundComponentReceived(
        _fund,
        proposalDetails[_fund].proposalTimestamp,
        msg.sender,
        _scaledInboundComponents[i].componentAddress,
        _scaledInboundComponents[i].tradeRealUnits
      );
    }
  }

  /**
   * Trades the outbound components from the fund contract to the transaction sender
   *
   * @param _fund                Address of the fund subject of the trade
   * @param _scaledOutboundComponents  The outbound components to be sent out
   */
  function _tradeOutboundComponents(
    IDomani _fund,
    TradeComponent[] memory _scaledOutboundComponents
  ) internal {
    // Transfer the outbound components
    for (uint256 i = 0; i < _scaledOutboundComponents.length; i++) {
      _fund.strictInvokeTransfer(
        _scaledOutboundComponents[i].componentAddress,
        msg.sender,
        _scaledOutboundComponents[i].tradeRealUnits
      );
      emit OutboundComponentSent(
        _fund,
        proposalDetails[_fund].proposalTimestamp,
        msg.sender,
        _scaledOutboundComponents[i].componentAddress,
        _scaledOutboundComponents[i].tradeRealUnits
      );
    }
  }

  /**
   * Update the fund positions according to the trades just executed
   *
   * @param _fund                Address of the fund subject of the position update
   * @param _tradeComponents     The components to be updated
   * @param _fundTotalSupply          The observed fund total supply
   * @param _preTradePositionBalances The fund balance for each given component, observed before the trade
   */
  function _updateFundPositions(
    IDomani _fund,
    TradeComponent[] memory _tradeComponents,
    uint256 _fundTotalSupply,
    uint256[] memory _preTradePositionBalances
  ) internal {
    // Edit the inbound-component positions
    for (uint256 i = 0; i < _tradeComponents.length; i++) {
      _fund.calculateAndEditDefaultPosition(
        _tradeComponents[i].componentAddress,
        _fundTotalSupply,
        _preTradePositionBalances[i]
      );
    }
  }

  /**
   * Makes sure that the requested outbound components do not exceed the current positions
   *
   * @param _fund    Address of the fund subject of the trade
   */
  function _checkOutboundComponents(IDomani _fund) internal view {
    for (uint256 i = 0; i < proposalDetails[_fund].outboundTradeComponents.length; i++) {
      address tradeComponentAddress = proposalDetails[_fund]
      .outboundTradeComponents[i]
      .componentAddress;
      if (_fund.isComponent(tradeComponentAddress)) {
        uint256 outboundComponentRealUnits = proposalDetails[_fund]
        .outboundTradeComponents[i]
        .tradeRealUnits;
        uint256 currentRealUnits = _fund
        .getDefaultPositionRealUnit(tradeComponentAddress)
        .toUint256();

        require(
          outboundComponentRealUnits <= currentRealUnits,
          "Insufficient balance for outbound component"
        );
      } else {
        revert("Outbound component not in the fund");
      }
    }
  }

  // **** Internal views

  /**
   * Computes the component balance before the trades.
   *
   * @param _fund                Address of the fund subject of the trade
   * @param _tradeComponents     The components to be traded and their quantities
   *
   * @return uint256[]           The array if pre-trade balances
   */
  function _computePreTradeBalances(IDomani _fund, TradeComponent[] memory _tradeComponents)
    internal
    view
    returns (uint256[] memory)
  {
    // Allocate the memory array first
    uint256[] memory preTradeBalances = new uint256[](_tradeComponents.length);

    // Fetch the position balance and store it in the array
    for (uint256 i = 0; i < _tradeComponents.length; i++) {
      preTradeBalances[i] = IERC20(_tradeComponents[i].componentAddress).balanceOf(address(_fund));
    }

    return preTradeBalances;
  }

  /**
   * Rescale the fund proposed/actual trade components according to the given quantity
   *
   * @param _fund         Address of the fund subject of the trade
   * @param _quantity     The number of fund base units to be traded
   *
   * @return TradeComponent[]    The scaled inbound trade components
   * @return TradeComponent[]    The scaled outbound trade components
   */
  function _scaleComponents(IDomani _fund, uint256 _quantity)
    internal
    view
    returns (TradeComponent[] memory, TradeComponent[] memory)
  {
    // Reserve the correct memory space for both inbound and outbound vectors
    TradeComponent[] memory _scaledInboundComponents = new TradeComponent[](
      proposalDetails[_fund].inboundTradeComponents.length
    );

    TradeComponent[] memory _scaledOutboundComponents = new TradeComponent[](
      proposalDetails[_fund].outboundTradeComponents.length
    );

    // Compute the scaled inbound components
    for (uint256 i = 0; i < _scaledInboundComponents.length; i++) {
      uint256 realUnit = proposalDetails[_fund].inboundTradeComponents[i].tradeRealUnits;

      // Use preciseMulCeil to be consistent with the BasicIssuance module issuance
      _scaledInboundComponents[i].tradeRealUnits = realUnit.preciseMulCeil(_quantity);

      _scaledInboundComponents[i].componentAddress = proposalDetails[_fund]
      .inboundTradeComponents[i]
      .componentAddress;
    }

    // Compute the scaled outbound components
    for (uint256 i = 0; i < _scaledOutboundComponents.length; i++) {
      uint256 realUnit = proposalDetails[_fund].outboundTradeComponents[i].tradeRealUnits;

      // Use preciseMul to be consistent with the BasicIssuance module redemption
      _scaledOutboundComponents[i].tradeRealUnits = _quantity.preciseMul(realUnit);
      _scaledOutboundComponents[i].componentAddress = proposalDetails[_fund]
      .outboundTradeComponents[i]
      .componentAddress;
    }
    return (_scaledInboundComponents, _scaledOutboundComponents);
  }
}