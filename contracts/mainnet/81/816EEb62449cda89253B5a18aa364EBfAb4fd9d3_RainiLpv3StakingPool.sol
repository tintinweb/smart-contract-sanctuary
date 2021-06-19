/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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

    constructor () {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface INonfungiblePositionManager is IERC721 {
  function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface RainiLpv2StakingPool {
  function burn(address _owner, uint256 _amount) external;
  function balanceOf(address _owner) external view returns(uint256);
}

contract RainiLpv3StakingPool is AccessControl, ReentrancyGuard, ERC721Holder {
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  using SafeERC20 for IERC20;
 
  // Fixed / admin assigned values:

  uint256 public rewardRate;
  uint256 public minRewardStake;
  uint256 constant public REWARD_DECIMALS = 1000000;

  uint256 public maxBonus;
  uint256 public bonusDuration;
  uint256 public bonusRate;
  uint256 constant public BONUS_DECIMALS = 1000000000;

  uint256 constant public RAINI_REWARD_DECIMALS = 1000000000000;

  int24 public minTickUpper;
  int24 public maxTickLower;
  uint24 public feeRequired;


  INonfungiblePositionManager public rainiLpNFT;
  RainiLpv2StakingPool public rainiLpv2StakingPool;
  IERC20 public rainiToken;

  address public exchangeTokenAddress;

  uint256 public unicornToEth;


  // Universal variables
  uint256 public totalSupply;
  
  struct GeneralRewardVars {
    uint32 lastUpdateTime;
    uint64 rainiRewardPerTokenStored;
    uint32 periodFinish;
    uint128 rainiRewardRate;
  }

  GeneralRewardVars public generalRewardVars;

  // account specific variables

  struct AccountRewardVars {
    uint40 lastBonus;
    uint32 lastUpdated;
    uint104 rainiRewards;
    uint64 rainiRewardPerTokenPaid;
  }

  struct AccountVars {
    uint128 staked;
    uint128 unicornBalance;
  }


  mapping(address => AccountRewardVars) internal accountRewardVars;
  mapping(address => AccountVars) internal accountVars;
  mapping(address => uint32[]) internal stakedNFTs;


  // Events
  event EthWithdrawn(uint256 amount);

  event RewardSet(uint256 rewardRate, uint256 minRewardStake);
  event BonusesSet(uint256 maxBonus, uint256 bonusDuration);
  event RainiLpTokenSet(address token);
  event UnicornToEthSet(uint256 unicornToEth);
  event TickRangeSet(int24 minTickUpper, int24 maxTickLower);
  event FeeRequiredSet(uint24 feeRequired);
  

  event TokensStaked(address payer, uint256 amount, uint256 timestamp);
  event TokensWithdrawn(address owner, uint256 amount, uint256 timestamp);

  event UnicornPointsBurned(address owner, uint256 amount);
  event UnicornPointsMinted(address owner, uint256 amount);
  event UnicornPointsBought(address owner, uint256 amount);

  event RewardWithdrawn(address owner, uint256 amount, uint256 timestamp);
  event RewardPoolAdded(uint256 _amount, uint256 _duration, uint256 timestamp);

  constructor(address _rainiLpNFT, address _rainiToken, address _exchangeToken, address _v2Pool) {
    require(_rainiLpNFT != address(0), "RainiLpv3StakingPool: _rainiLpToken is zero address");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    rainiLpNFT = INonfungiblePositionManager(_rainiLpNFT);
    exchangeTokenAddress = _exchangeToken;
    rainiToken = IERC20(_rainiToken);
    rainiLpv2StakingPool = RainiLpv2StakingPool(_v2Pool);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RainiLpv3StakingPool: caller is not an owner");
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, _msgSender()), "RainiLpv3StakingPool: caller is not a burner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "RainiLpv3StakingPool: caller is not a minter");
    _;
  }
  
  modifier balanceUpdate(address _owner) {

    AccountRewardVars memory _accountRewardVars = accountRewardVars[_owner];
    AccountVars memory _accountVars = accountVars[_owner];
    GeneralRewardVars memory _generalRewardVars = generalRewardVars;

    // Raini rewards
    _generalRewardVars.rainiRewardPerTokenStored = uint64(rainiRewardPerToken());
    _generalRewardVars.lastUpdateTime = uint32(lastTimeRewardApplicable());

    if (_owner != address(0)) {
      uint32 duration = uint32(block.timestamp) - _accountRewardVars.lastUpdated;
      uint128 reward = calculateReward(_owner, _accountVars.staked, duration);
  
      _accountVars.unicornBalance = _accountVars.unicornBalance + reward;
      _accountRewardVars.lastUpdated = uint32(block.timestamp);
      _accountRewardVars.lastBonus = uint40(Math.min(maxBonus, _accountRewardVars.lastBonus + bonusRate * duration));
      
      _accountRewardVars.rainiRewards = uint104(rainiEarned(_owner));
      _accountRewardVars.rainiRewardPerTokenPaid = _generalRewardVars.rainiRewardPerTokenStored;
    }

    accountRewardVars[_owner] = _accountRewardVars;
    accountVars[_owner] = _accountVars;
    generalRewardVars = _generalRewardVars;

    _;
  }

  function getRewardByDuration(address _owner, uint256 _amount, uint256 _duration) 
    public view returns(uint256) {
      return calculateReward(_owner, _amount, _duration);
  }

  function getStaked(address _owner) 
    public view returns(uint256) {
      return accountVars[_owner].staked;
  }

  function getStakedPositions(address _owner) 
    public view returns(uint32[] memory) {
      return stakedNFTs[_owner];
  }
  
  function balanceOf(address _owner)
    public view returns(uint256) {
      uint256 reward = calculateReward(_owner, accountVars[_owner].staked, block.timestamp - accountRewardVars[_owner].lastUpdated);
      return accountVars[_owner].unicornBalance + reward;
  }

  function getCurrentBonus(address _owner) 
    public view returns(uint256) {
      AccountRewardVars memory _accountRewardVars = accountRewardVars[_owner];

      if(accountVars[_owner].staked == 0) {
        return 0;
      } 
      uint256 duration = block.timestamp - _accountRewardVars.lastUpdated;
      return Math.min(maxBonus, _accountRewardVars.lastBonus + bonusRate * duration);
  }

  function getCurrentAvgBonus(address _owner, uint256 _duration)
    public view returns(uint256) {
      AccountRewardVars memory _accountRewardVars = accountRewardVars[_owner];

      if(accountVars[_owner].staked == 0) {
        return 0;
      } 
      uint256 avgBonus;
      if(_accountRewardVars.lastBonus < maxBonus) {
        uint256 durationTillMax = (maxBonus - _accountRewardVars.lastBonus) / bonusRate;
        if(_duration > durationTillMax) {
          uint256 avgWeightedBonusTillMax = (_accountRewardVars.lastBonus + maxBonus) * durationTillMax / 2;
          uint256 weightedMaxBonus = maxBonus * (_duration - durationTillMax);

          avgBonus = (avgWeightedBonusTillMax + weightedMaxBonus) / _duration;
        } else {
          avgBonus = (_accountRewardVars.lastBonus + bonusRate * _duration + _accountRewardVars.lastBonus) / 2;
        }
      } else {
        avgBonus = maxBonus;
      }
      return avgBonus;
  }

  function setReward(uint256 _rewardRate, uint256 _minRewardStake)
    external onlyOwner {
      rewardRate = _rewardRate;
      minRewardStake = _minRewardStake;

      emit RewardSet(rewardRate, minRewardStake);
  }

  function setUnicornToEth(uint256 _unicornToEth)
    external onlyOwner {
      unicornToEth = _unicornToEth;
      
      emit UnicornToEthSet(_unicornToEth);
  }

  function setBonus(uint256 _maxBonus, uint256 _bonusDuration)
    external onlyOwner {
      maxBonus = _maxBonus * BONUS_DECIMALS;
      bonusDuration = _bonusDuration;
      bonusRate = maxBonus / _bonusDuration;

      emit BonusesSet(_maxBonus, _bonusDuration);
  }
  function setTickRange(int24 _maxTickLower, int24 _minTickUpper)
    external onlyOwner {
      minTickUpper = _minTickUpper;
      maxTickLower = _maxTickLower;
      emit TickRangeSet(_minTickUpper, _maxTickLower);
  }

  function setFeeRequired(uint24 _feeRequired)
    external onlyOwner {
      feeRequired = _feeRequired;  
      emit FeeRequiredSet(_feeRequired);
  }

  function stake(uint32 _tokenId)
    external nonReentrant balanceUpdate(_msgSender()) {
      (
        ,//uint96 nonce,
        ,//address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        ,//uint256 feeGrowthInside0LastX128,
        ,//uint256 feeGrowthInside1LastX128,
        ,//uint128 tokensOwed0,
        //uint128 tokensOwed1
      ) = rainiLpNFT.positions(_tokenId);

      require(tickUpper > minTickUpper, "RainiLpv3StakingPool: tickUpper too low");
      require(tickLower < maxTickLower, "RainiLpv3StakingPool: tickLower too high");
      require((token0 ==  exchangeTokenAddress && token1 == address(rainiToken)) ||
              (token1 ==  exchangeTokenAddress && token0 == address(rainiToken)), "RainiLpv3StakingPool: NFT tokens not correct");
      require(fee == feeRequired, "RainiLpv3StakingPool: fee != feeRequired");

      rainiLpNFT.safeTransferFrom(_msgSender(), address(this), _tokenId);

      uint32[] memory nfts = stakedNFTs[_msgSender()];
      bool wasAdded = false;
      for (uint i = 0; i < nfts.length; i++) {
         if (nfts[i] == 0) {
           stakedNFTs[_msgSender()][i] = _tokenId;
           wasAdded = true;
           break;
         }
      }
      if (!wasAdded) {
        stakedNFTs[_msgSender()].push(_tokenId);
      }      

      totalSupply = totalSupply + liquidity;
      uint128 currentStake = accountVars[_msgSender()].staked;
      accountVars[_msgSender()].staked = currentStake + liquidity;
      accountRewardVars[_msgSender()].lastBonus = uint40(accountRewardVars[_msgSender()].lastBonus * currentStake / (currentStake + liquidity));

      emit TokensStaked(_msgSender(), liquidity, block.timestamp);
  }
  
  function withdraw(uint256 _tokenId)
    external nonReentrant balanceUpdate(_msgSender()) {

      bool ownsNFT = false;
      uint32[] memory nfts = stakedNFTs[_msgSender()];
      for (uint i = 0; i < nfts.length; i++) {
        if (nfts[i] == _tokenId) {
          ownsNFT = true;
          delete stakedNFTs[_msgSender()][i];
          break;
        }
      }
      require(ownsNFT == true, "RainiLpv3StakingPool: Not the owner");

      rainiLpNFT.safeTransferFrom(address(this), _msgSender(), _tokenId);

      (
        ,//uint96 nonce,
        ,//address operator,
        ,//address token0,
        ,//address token1,
        ,//uint24 fee,
        ,//int24 tickLower,
        ,//int24 tickUpper,
        uint128 liquidity,
        ,//uint256 feeGrowthInside0LastX128,
        ,//uint256 feeGrowthInside1LastX128,
        ,//uint128 tokensOwed0,
        //uint128 tokensOwed1
      ) = rainiLpNFT.positions(_tokenId);

      accountVars[_msgSender()].staked = accountVars[_msgSender()].staked - liquidity;
      totalSupply = totalSupply - liquidity;

      emit TokensWithdrawn(_msgSender(), liquidity, block.timestamp);
  }

  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "RainiLpv3StakingPool: not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "RainiLpv3StakingPool: transfer failed");
      emit EthWithdrawn(_amount);
  }
  
  function mint(address[] calldata _addresses, uint256[] calldata _points) 
    external onlyMinter {
      require(_addresses.length == _points.length, "RainiLpv3StakingPool: Arrays not equal");
      
      for (uint256 i = 0; i < _addresses.length; i++) {
        accountVars[_addresses[i]].unicornBalance = uint128(accountVars[_addresses[i]].unicornBalance + _points[i]);
        
        emit UnicornPointsMinted(_addresses[i], _points[i]);
      }
  }
  
  function buyUnicorn(uint256 _amount) 
    external payable {
      require(_amount > 0, "RainiLpv3StakingPool: _amount is zero");
      require(msg.value * unicornToEth >= _amount, "RainiLpv3StakingPool: not enougth eth");

      accountVars[_msgSender()].unicornBalance = uint128(accountVars[_msgSender()].unicornBalance + _amount);

      uint256 refund = msg.value - (_amount / unicornToEth);
      if(refund > 0) {
        (bool success, ) = _msgSender().call{ value: refund }("");
        require(success, "RainiLpv3StakingPool: transfer failed");
      }
      
      emit UnicornPointsBought(_msgSender(), _amount);
  }  
  
  function burn(address _owner, uint256 _amount) 
    external nonReentrant onlyBurner balanceUpdate(_owner) {
      accountVars[_owner].unicornBalance = uint128(accountVars[_owner].unicornBalance - _amount);
      
      emit UnicornPointsBurned(_owner, _amount);
  }
    
  function calculateReward(address _owner, uint256 _amount, uint256 _duration) 
    private view returns(uint128) {
      uint256 reward = _duration * rewardRate * _amount / (REWARD_DECIMALS * minRewardStake);

      return calculateBonus(_owner, reward, _duration);
  }

  function calculateBonus(address _owner, uint256 _amount, uint256 _duration)
    private view returns(uint128) {
      uint256 avgBonus = getCurrentAvgBonus(_owner, _duration);
      return uint128(_amount + _amount * avgBonus  / BONUS_DECIMALS / 100);
  }



  // RAINI rewards

  function lastTimeRewardApplicable() public view returns (uint256) {
      return Math.min(block.timestamp, generalRewardVars.periodFinish);
  }

  function rainiRewardPerToken() public view returns (uint256) {
    GeneralRewardVars memory _generalRewardVars = generalRewardVars;

    if (totalSupply == 0) {
      return _generalRewardVars.rainiRewardPerTokenStored;
    }
    
    return _generalRewardVars.rainiRewardPerTokenStored + (uint256(lastTimeRewardApplicable() - _generalRewardVars.lastUpdateTime) * _generalRewardVars.rainiRewardRate * RAINI_REWARD_DECIMALS) / totalSupply;
  }

  function rainiEarned(address account) public view returns (uint256) {
    AccountRewardVars memory _accountRewardVars = accountRewardVars[account];
    AccountVars memory _accountVars = accountVars[account];
    
    uint256 calculatedEarned = (uint256(_accountVars.staked) * (rainiRewardPerToken() - _accountRewardVars.rainiRewardPerTokenPaid)) / RAINI_REWARD_DECIMALS + _accountRewardVars.rainiRewards;
    uint256 poolBalance = rainiToken.balanceOf(address(this));
    // some rare case the reward can be slightly bigger than real number, we need to check against how much we have left in pool
    if (calculatedEarned > poolBalance) return poolBalance;
    return calculatedEarned;
  }

  function addRainiRewardPool(uint256 _amount, uint256 _duration)
    external onlyOwner nonReentrant balanceUpdate(address(0)) {

      GeneralRewardVars memory _generalRewardVars = generalRewardVars;

      if (_generalRewardVars.periodFinish > block.timestamp) {
        uint256 timeRemaining = _generalRewardVars.periodFinish - block.timestamp;
        _amount += timeRemaining * _generalRewardVars.rainiRewardRate;
      }

      rainiToken.safeTransferFrom(_msgSender(), address(this), _amount);
      _generalRewardVars.rainiRewardRate = uint128(_amount / _duration);
      _generalRewardVars.periodFinish = uint32(block.timestamp + _duration);
      _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
      generalRewardVars = _generalRewardVars;
      emit RewardPoolAdded(_amount, _duration, block.timestamp);
  }

  function abortRainiRewardPool() external onlyOwner nonReentrant balanceUpdate(address(0)) {

      GeneralRewardVars memory _generalRewardVars = generalRewardVars;

      require (_generalRewardVars.periodFinish > block.timestamp, "Reward pool is not active");
      
      uint256 timeRemaining = _generalRewardVars.periodFinish - block.timestamp;
      uint256 remainingAmount = timeRemaining * _generalRewardVars.rainiRewardRate;
      rainiToken.transfer(_msgSender(), remainingAmount);

      _generalRewardVars.rainiRewardRate = 0;
      _generalRewardVars.periodFinish = uint32(block.timestamp);
      _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
      generalRewardVars = _generalRewardVars;
  }

  function recoverRaini(uint256 _amount) external onlyOwner nonReentrant {
    require(generalRewardVars.periodFinish < block.timestamp, "Raini cannot be recovered while reward pool active.");
    rainiToken.transfer(_msgSender(), _amount);
  }

  function withdrawReward() external nonReentrant balanceUpdate(_msgSender()) {
    uint256 reward = rainiEarned(_msgSender());
    require(reward > 1, "no reward to withdraw");
    if (reward > 1) {
      accountRewardVars[_msgSender()].rainiRewards = 0;
      rainiToken.safeTransfer(_msgSender(), reward);
    }

    emit RewardWithdrawn(_msgSender(), reward, block.timestamp);
  }



  // LP v2 migration
  function migrateV2Unicorns() external {
    uint256 balance = rainiLpv2StakingPool.balanceOf(_msgSender());
    rainiLpv2StakingPool.burn(_msgSender(), balance);
    accountVars[_msgSender()].unicornBalance = uint128(accountVars[_msgSender()].unicornBalance + balance);
    emit UnicornPointsMinted(_msgSender(), balance);
  }
}