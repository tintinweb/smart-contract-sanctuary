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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity =0.7.6;
pragma abicoder v2;


interface ICloseableRouter {
    event Deposit(uint256 amount, address token);
    event Withdraw(uint256 amount, address token);

    /**
     * @notice This function is mean to be the shutdown lever. It immediately destroy
     * the router and send all funds that could stuck here to the admin, so he could
     * return them to the investors.
     */
    function close() external;
}

pragma solidity =0.7.6;
pragma abicoder v2;


interface IOracle {
    function consult(address tokenIn, uint256 amountIn, address tokenOut) external view returns(uint256 amountOut);
}

pragma solidity =0.7.6;
pragma abicoder v2;

import "./ICloseableRouter.sol";


interface IRouterV2 is ICloseableRouter {

    struct DepositParams {
        address token; // token to deposit
        uint256 amountA; // in token to depost to stake in hive
        uint256 amountB; // in token to depost to autostake in XBE Staking Contract
        uint256 minAmountLP; // in curve eurt lp token that needs to be acquired
        uint256 minAmount; // minimum amount of token obtained from sushiswap swap from token to token that Curve accepts
        uint256 minAmountXBE; // minimum amount of XBE obtained from token/xbe swap
        uint256 deadline; // timestamp in future, so when the time passes this the swap txs will be reverted
        address recipient; // recipient of the LP of the Hive Vault
    }

    struct WithdrawParams {
        uint256 amount; // amount of LP of Hive Vault
        address token; // ETH or USDC
        uint256 amountOutMinForUniswap; // min amount that we will obtain when Curve tokens is withdrawn and swapped to desired token
        uint256 amountOutMinForCurve; // min amount that we wiil obtain from Curve protocol withdraw
        uint256 deadline; // timestamp in future, so when the time passes this the swaps txs will be reverted
        address recipient; // recipient of ETH or USDC
    }

    function deposit(DepositParams memory params) external payable returns(uint256);
    function withdraw(WithdrawParams memory params) external returns(uint256);

}

pragma solidity =0.7.6;
pragma abicoder v2;


interface IVaultTransfers {
    function deposit(uint256 _amount) external;

    function depositFor(uint256 _amount, address _for) external;

    function depositAll() external;

    function withdraw(uint256 _amount) external;

    function withdrawAll() external;
}

pragma solidity =0.7.6;
pragma abicoder v2;


interface IVotingStakingRewards {
    function stakeFor(address _for, uint256 _amount) external;
}

pragma solidity =0.7.6;
pragma abicoder v2;


interface ICurveStETHStableSwap {

    function lp_token() external view returns(address);

    function calc_token_amount(
        uint256[2] memory amounts,
        bool is_deposit
    ) external view returns(uint256);

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount
    ) external returns(uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_received
    ) external returns(uint256);

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns(uint256);

}

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "./utils/SushiswapSwaps.sol";
import "../interfaces/IRouterV2.sol";
import "../interfaces/IVaultTransfers.sol";
import "../interfaces/IVotingStakingRewards.sol";
import "../interfaces/curve/ICurveStETHStableSwap.sol";


/**
 * @title MIM Router for MIM Hive Vault
 * @notice This contract is created for Easy XBE project
 * @author Oleg Bedrin
 * @dev Created on: 21.10.2021
 */
contract StETHRouter is IRouterV2, SushiswapSwaps {

    IVaultTransfers public stethHiveVault; // MIM Hive Router address
    IVotingStakingRewards public votingStakingRewards; // XBE Staking Contract
    ICurveStETHStableSwap public curveStETH; // Curve StETH StableSwap Pool - 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022
    IERC20 public curveStETHLpToken; // Curve Iron Bank StableSwap LP Token

    address public xbe; // XBE
    address public usdc; // USDC
    address public steth; // STETH - 0xae7ab96520de3a18e5e111b5eaab095312d7fe84

    uint256 public stETHIndexInStableSwapPool; // Index of STETH in Curve STETH StableSwap pool

    /**
     * @notice Constructor for StETHRouter
     * @param _easyXBESushiswapOracle SushiSwap oracle
     * @param _uniswapV2Router SushiSwap Router02
     * @param _steth STETH token
     * @param _usdc USDC token
     * @param _xbe XBE token
     * @param _stethHiveVault StETH Hive Vault
     * @param _votingStakingRewards Voting Staking Rewards (XBE Staking Contract)
     * @param _curveStETH Curve StETH StableSwap Pool
     */
    constructor(
        address _easyXBESushiswapOracle,
        address _uniswapV2Router,
        address _steth,
        address _usdc,
        address _xbe,
        address _stethHiveVault,
        address _votingStakingRewards,
        address _curveStETH
    )
        SushiswapSwaps(
          _easyXBESushiswapOracle,
          _uniswapV2Router,
          _msgSender()
        )
    {
        xbe = _xbe;
        steth = _steth;
        usdc = _usdc;
        curveStETH = ICurveStETHStableSwap(_curveStETH);
        curveStETHLpToken = IERC20(curveStETH.lp_token());
        stethHiveVault = IVaultTransfers(_stethHiveVault);
        votingStakingRewards = IVotingStakingRewards(_votingStakingRewards);
    }

    // only this tokens are allowed to be deposited or withdrawn
    modifier onlyValidToken(address token) {
        require(token == usdc || token == ETH, "invalidToken");
        _;
    }

    /**
     * @notice This setter is for index of StETH token in its curve stable swap pool
     * @param _idx index of StETH in the curve stableswap pool
     */
    function setStETHIndexInStableSwapPool(uint256 _idx) external onlyAdmin {
        stETHIndexInStableSwapPool = _idx;
    }

    function _performSwaps(DepositParams memory params)
        internal
        returns(uint256 tokensReceived, uint256 swappedAmountBToXBE)
    {
        if (params.token == ETH) {
            tokensReceived = _swapFromETH(
                steth,
                params.amountA,
                address(this),
                params.minAmount,
                params.deadline
            );
            swappedAmountBToXBE = _swapFromETH(
                xbe,
                params.amountB,
                address(this),
                params.minAmountXBE,
                params.deadline
            );
        } else {
            // params.token == usdc always
            TransferHelper.safeTransferFrom(
                params.token,
                params.recipient,
                address(this),
                params.amountA + params.amountB
            );
            tokensReceived = _swapTokens(
                params.token,
                steth,
                params.amountA,
                address(this),
                params.minAmount,
                params.deadline
            );
            swappedAmountBToXBE = _swapToTokenThroughEth(
                params.token,
                xbe,
                params.amountB,
                address(this),
                params.minAmountXBE,
                params.deadline
            );
        }
    }

    function _depositToCurve(uint256 _tokensReceived, uint256 _minAmountLP)
        internal
        returns(uint256 curveStETHtLpAmount)
    {
        TransferHelper.safeApprove(steth, address(curveStETH), _tokensReceived);
        uint256[2] memory amounts;
        amounts[stETHIndexInStableSwapPool] = _tokensReceived;
        curveStETHtLpAmount = curveStETH.add_liquidity(
            amounts,
            _minAmountLP
        );
    }

    function _depositToVotingStakingRewards(uint256 _swappedAmountBToXBE, address _recipient) internal {
        TransferHelper.safeApprove(xbe, address(votingStakingRewards), _swappedAmountBToXBE);
        votingStakingRewards.stakeFor(_recipient, _swappedAmountBToXBE);
    }

    function _depositToHive(address _recipient, uint256 _curveStETHtLpAmount) internal {
        TransferHelper.safeApprove(
            address(curveStETHLpToken),
            address(stethHiveVault),
            _curveStETHtLpAmount
        );
        stethHiveVault.depositFor(_curveStETHtLpAmount, _recipient);
    }

    /**
     * @notice This function is for deposit to StETH Hive Vault.
     * It should take your ETH or USDC, convert amount A to StETH, convert amount B to XBE and auto-stake it for you.
     * The A amount of StETH goes to Curve StETH StableSwap pool, and all acquired LP of the curve pool then staked in StETH Hive Vault
     * for you. You must approve amountA + amountB amount of tokens to this contract if they are not ETH.
     * @param params The params necessary to deposit, encoded as `DepositParams` struct in calldata.
     */
    function deposit(DepositParams calldata params)
        external
        payable
        override
        nonReentrant
        onlyValidAmounts(params.amountA, params.amountB)
        onlyValidToken(params.token)
        returns(uint256 curveStETHtLpAmount)
    {
        (uint256 tokensReceived, uint256 swappedAmountBToXBE) = _performSwaps(params);

        // equals to amount of LP Hive
        curveStETHtLpAmount = _depositToCurve(tokensReceived, params.minAmountLP);

        _depositToVotingStakingRewards(swappedAmountBToXBE, params.recipient);
        _depositToHive(params.recipient, curveStETHtLpAmount);
    }

    /**
     * @notice This function is for withdraw funds from StETH Hive Vault.
     * It should take your provided StETH Hive Vault LP tokens, withdraw your Curve StETH StableSwap
     * LP tokens, withdraw StETH from Curve and swap to either USDC or ETH, depending on your
     * desire. The result of the swap then transfers to you or provided address of a recipient.
     * @param params The params necessary to withdraw, encoded as `WithdrawParams` struct in calldata.
     */
    function withdraw(WithdrawParams calldata params)
        external
        override
        onlyValidToken(params.token)
        returns(uint256 amountReceived)
    {
        TransferHelper.safeTransferFrom(
            address(stethHiveVault),
            params.recipient,
            address(this),
            params.amount
        );

        uint256 balanceBefore = IERC20(address(curveStETHLpToken)).balanceOf(address(this));
        stethHiveVault.withdraw(params.amount);
        uint256 balanceAfter = IERC20(address(curveStETHLpToken)).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "nothingToWithdraw");
        uint256 curveStEthLpAmount = balanceAfter - balanceBefore;

        amountReceived = curveStETH.remove_liquidity_one_coin(
            curveStEthLpAmount,
            int128(uint128(stETHIndexInStableSwapPool)),
            params.amountOutMinForCurve
        );

        if (params.token == usdc) {
            amountReceived = _swapTokens(
                steth,
                usdc,
                amountReceived,
                params.recipient,
                params.amountOutMinForUniswap,
                params.deadline
            );
        } else {
            amountReceived = _swapToETH(
                steth,
                amountReceived,
                params.recipient,
                params.amountOutMinForUniswap,
                params.deadline
            );
        }
    }
}

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/ICloseableRouter.sol";

/**
 * @title Adminable - utility contract
 * @notice This contract holds all shared constants, roles and shared admin functions.
 * @author Oleg Bedrin
 * @dev Created on: 21.10.2021
 */
abstract contract Adminable is AccessControl, ReentrancyGuard, ICloseableRouter {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH address like in curve
    uint256 public constant MAX_BP = 10000; // Maximum amount of basis points

    uint256 public minBpsForXbeStake = 500; // Minimum amount of basis points to be swapped to XBE and auto-staked

    /**
     * @notice Constructor for Adminable instance, sets default admin role and save an admin address.
     */
    constructor() {
        address sender = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    /**
     * @notice This function is for evacuating stucked funds on the Adminable
     * instances. The routers contracts are not accumulating any funds, so
     * any funds that can be found between transactions are considered stucked.
     * This method only accessible to admin and all stucked funds are to be send
     * to the admin.
     * @param _token Address of the token that stucked
     * @param _amount Amount of the token that stucked
     */
    function evacuateTokens(address _token, uint256 _amount) external onlyAdmin {
        if (_token == ETH) {
            Address.sendValue(payable(_msgSender()), _amount);
        } else {
            IERC20(_token).safeTransfer(_msgSender(), _amount);
        }
    }

    /**
     * @notice This setter is for BPS number of amount that must be turned to XBE and auto-staked.
     * @param _minBpsForXbeStake amount of BPS
     */
    function setMinBpsForXbeSwap(uint256 _minBpsForXbeStake) external onlyAdmin {
        minBpsForXbeStake = _minBpsForXbeStake;
    }

    modifier onlyValidAmounts(uint256 _amountA, uint256 _amountB) {
        // Check (_amountB * MAX_BP) / (_amountA + _amountB) >= minBbsForXbeStake in a safe way
        (bool isNotMultiplicationOverflown, uint256 multiplication) = _amountB.tryMul(MAX_BP);
        (bool isNotAddingOverflown, uint256 adding) = _amountA.tryAdd(_amountB);
        require(isNotMultiplicationOverflown && isNotAddingOverflown, "addingOrMultiplicationOverflown");
        (bool isNotDivisionOnZero, uint256 division) = multiplication.tryDiv(adding);
        require(isNotDivisionOnZero, "divisionOnZero");
        require(division >= minBpsForXbeStake, "invalidAllocation");
        _;
    }

    /// @inheritdoc ICloseableRouter
    function close() external override onlyAdmin {
        selfdestruct(payable(_msgSender()));
    }
}

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "../../interfaces/IOracle.sol";
import "./Adminable.sol";


/**
 * @title SushiswapSwaps - is an utility contract providing swaps on SushiSwap for every it's child.
 * @notice This contract is created for Easy XBE project
 * @author Oleg Bedrin
 * @dev Created on: 21.10.2021
 */
abstract contract SushiswapSwaps is Adminable {

    IUniswapV2Router02 public router; // SushiSwap Router02

    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE"); // Oracle Manager Role

    address public oracleAddress; // Current Oracle contract address
    address public oracleManager; // Current Oracle manager address

    // token0 => token1 => amount of tolerance in wei of token1
    mapping(address => mapping(address => uint256)) public manipulationTolerances;

    modifier onlyOracleManager {
        require(hasRole(ORACLE_MANAGER_ROLE, _msgSender()), "!oracleManager");
        _;
    }

    /**
     * @notice Constructor for SushiswapSwaps
     * @param _oracleAddress An oracle address for SushiSwap, it can be address(0) - then it's just ignored.
     * @param _router SushiSwap Router02 instance address.
     * @param _oracleManager An address who can set new oracles for the children on SushiswapSwaps.
     */
    constructor(
        address _oracleAddress,
        address _router,
        address _oracleManager
    ) {
        oracleAddress = _oracleAddress;
        router = IUniswapV2Router02(_router);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ORACLE_MANAGER_ROLE, _oracleManager);
        oracleManager = _oracleManager;
    }

    /**
     * @notice This setter provides functionality to alter oracle address. It
     * can only be altered by the oracle manager address.
     * @param _newOracle Address of the new oracle contract
     */
    function setOracle(address _newOracle) external onlyOracleManager {
        oracleAddress = _newOracle;
    }

    /**
     * @notice Setter for admin to set new oracle manager address.
     * @param _oracleManager Address of the new oracle manager
     */
    function setOracleManagerRole(address _oracleManager) external onlyAdmin {
        revokeRole(ORACLE_MANAGER_ROLE, oracleManager);
        grantRole(ORACLE_MANAGER_ROLE, _oracleManager);
        oracleManager = _oracleManager;
    }

    /**
     * @notice This setter for price manipulation tolerances for different swaps
     * that could occur in the children of the contract.
     * @param _token0 Token for sale
     * @param _token1 Token to buy
     * @param _manipulationTolerance Amount in tokens (wei) of `_token1`
     */
    function setManipulationTolerance(
        address _token0,
        address _token1,
        uint256 _manipulationTolerance
    ) external onlyOracleManager {
        manipulationTolerances[_token0][_token1] = _manipulationTolerance;
    }

    /**
     * @notice Basic function that check if `deviation` in between [`a`, `b`] (inclusively).
     * @param a Start border of the interval
     * @param b End border of the interval
     * @param deviation Amount to check if it is in the interval or on the border of the interval
     * @return If `deviation` is in or out
     */
    function _deviationSmOrEqThan(uint256 a, uint256 b, uint256 deviation) internal returns(bool) {
        return a > b ? a - b <= deviation : b - a <= deviation;
    }

    /**
     * @notice Checks if sum that must be swapped won't be manipulated.
     * @param _amount Amount of the tokens at `path[0]`
     * @param path Vector of swaps
     */
    function _checkOnManipulation(uint256 _amount, address[] memory path) internal {
        if (oracleAddress != address(0)) {
            uint256 lastIdx = path.length - 1;
            require(
              _deviationSmOrEqThan(
                IOracle(oracleAddress).consult(path[0], _amount, path[lastIdx]),
                router.getAmountsOut(_amount, path)[lastIdx - 1],
                manipulationTolerances[path[0]][path[lastIdx]]
              ),
              "manipulationDetected"
            );
        }
    }

    /**
     * @notice Prepare path for dual swap and check it on manipulation.
     * @param _token0 Address of token to sell
     * @param _token1 Address of token to buy
     * @param _amount Amount of token to sell
     * @return path Vector of swap in array
     */
    function _prepareSwap(
        address _token0,
        address _token1,
        uint256 _amount
    ) internal returns(address[] memory path) {
        path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;
        _checkOnManipulation(_amount, path);
    }

    /**
     * @notice This internal function swaps from ETH to `_token1` and send the result of the swap to `recipient`.
     * @param _token1 Token to buy
     * @param _amount Amount ETH to sell
     * @param _recipient Recipient of the `_token1`
     * @param _amountOutMin Minimum amount of the `_token1` to acquire from the swap
     * @param _deadline Deadline in seconds, which when passed the swap reverts
     * @return amountOut Amount of `_token1` acquired after swap
     */
    function _swapFromETH(
        address _token1,
        uint256 _amount,
        address _recipient,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns(uint256 amountOut) {
        (address[] memory path) = _prepareSwap(
            router.WETH(),
            _token1,
            _amount
        );
        amountOut = router.swapExactETHForTokens{value: _amount}(
            _amountOutMin,
            path,
            _recipient,
            _deadline
        )[1];
    }

    /**
     * @notice This internal function swaps from `_token0` to `_token1` through ETH and send the result of the swap to `recipient`.
     * @param _token0 Token to sell
     * @param _token1 Token to buy
     * @param _amount Amount of `_token0` to sell
     * @param _recipient Recipient of the `_token1`
     * @param _amountOutMin Minimum amount of the `_token1` to acquire from the swap
     * @param _deadline Deadline in seconds, which when passed the swap reverts
     * @return amountOut Amount of `_token1` acquired after swap
     */
    function _swapToTokenThroughEth(
        address _token0,
        address _token1,
        uint256 _amount,
        address _recipient,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns(uint256 amountOut) {
        address[] memory path = new address[](3);
        path[0] = _token0;
        path[1] = router.WETH();
        path[2] = _token1;

        _checkOnManipulation(_amount, path);

        TransferHelper.safeApprove(_token0, address(router), _amount);

        amountOut = router.swapExactTokensForTokens(
            _amount,
            _amountOutMin,
            path,
            _recipient,
            _deadline
        )[2];
    }

    /**
     * @notice This internal function swaps from `_token0` to ETH and send the result of the swap to `recipient`.
     * @param _token0 Token to sell
     * @param _amount Amount of `_token0` to sell
     * @param _recipient Recipient of the `_token1`
     * @param _amountOutMin Minimum amount of the ETH to acquire from the swap
     * @param _deadline Deadline in seconds, which when passed the swap reverts
     * @return amountOut Amount of ETH acquired after swap
     */
    function _swapToETH(
        address _token0,
        uint256 _amount,
        address _recipient,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns(uint256 amountOut) {
        (address[] memory path) = _prepareSwap(
            _token0,
            router.WETH(),
            _amount
        );

        TransferHelper.safeApprove(_token0, address(router), _amount);

        amountOut = router.swapExactTokensForETH(
            _amount,
            _amountOutMin,
            path,
            _recipient,
            _deadline
        )[1];
    }

    /**
     * @notice This internal function swaps from `_token0` to `_token1` and send the result of the swap to `recipient`.
     * @param _token0 Token to sell
     * @param _token1 Token to buy
     * @param _amount Amount of `_token0` to sell
     * @param _recipient Recipient of the `_token1`
     * @param _amountOutMin Minimum amount of the `_token1` to acquire from the swap
     * @param _deadline Deadline in seconds, which when passed the swap reverts
     * @return amountOut Amount of `_token1` acquired after swap
     */
    function _swapTokens(
        address _token0,
        address _token1,
        uint256 _amount,
        address _recipient,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns(uint256 amountOut) {
        (address[] memory path) = _prepareSwap(
            _token0,
            _token1,
            _amount
        );

        TransferHelper.safeApprove(_token0, address(router), _amount);

        amountOut = router.swapExactTokensForTokens(
            _amount,
            _amountOutMin,
            path,
            _recipient,
            _deadline
        )[1];
    }
}