/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/Address.sol

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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

// File: .deps/github/Loesil/VaultChef/contracts/DeFi Projects/ApeSwap/IApeMasterChef.sol

interface IApeMasterChef
{
    function poolLength() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (address token, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare);
    
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IToTheMoonRouter.sol

interface IToTheMoonRouter
{
    //-------------------------------------------------------------------------
    // ATTRIBUTES FUNCTIONS
    //-------------------------------------------------------------------------	
    
    function router() external view returns(address);
    
    //-------------------------------------------------------------------------
    // INFO FUNCTIONS
    //-------------------------------------------------------------------------	
    
    function getPair(address _token0, address _token1) external view returns(address);
    
	//-------------------------------------------------------------------------
    // PRICE FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function getPrice(address _tokenFrom, address _tokenTo) external view returns(uint256);
	
	function getPriceForAmount(address _tokenFrom, address _tokenTo, uint256 _amountFrom) external view returns(uint256);
	
	function getLPPrice(address _tokenFrom, address _tokenTo) external view returns(uint256);
	
	function getLPPriceForAmount(address _tokenFrom, address _tokenTo, uint256 _amountFrom) external view returns(uint256);

	//-------------------------------------------------------------------------
    // LIQUIDITY FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function addLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        address _spender
    ) external;
    
    function removeLiquidity(
        address _lpToken,
        uint256 _amount,
        address _spender
    ) external;

	//-------------------------------------------------------------------------
    // SWAP FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function swapExactTokensForTokensSupportingFee(
        uint256 _amount,
        address _tokenIn,
		address _tokenOut,
        address _spender
    ) external;
	
	function swapExactTokensForTokensSupportingFeeWithPath(
        uint256 _amount,
        address[] calldata _path,
        address _spender
    ) external;
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------	
    
    function makeSwapPath(address _tokenIn, address _tokenOut) external view returns(address[] memory);
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IRouter.sol

interface IRouter01
{
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

interface IRouter02 is IRouter01
{
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

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IBEP20.sol

interface IBEP20 is IERC20
{
	function decimals() external view returns (uint8);
	
	function symbol() external view returns (string memory);

	function name() external view returns (string memory);
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/ITokenPair.sol

interface ITokenPair is IBEP20
{
	//-------------------------------------------------------------------------
    // INFO FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function token0() external view returns (address);
	
	function token1() external view returns (address);
	
	function getReserves() external view returns (uint112, uint112, uint32);	
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IVault.sol

interface IVault
{
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
 
    function VERSION() external view returns(string memory);
    
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------
    
    function PERCENT_FACTOR() external view returns(uint256);
    
    function router() external view returns(address);
    
    function totalShares() external view returns(uint256);
    
    function lastCompoundTimestamp() external view returns(uint256);
    
    function depositToken() external view returns(address);
    
    function rewardToken() external view returns(address);
    
    function pauseCompound() external view returns(bool);
    
    function pauseDeposit() external view returns(bool);
    
    function pauseWithdraw() external view returns(bool);
    
    //-------------------------------------------------------------------------
    // VAULT INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalPending() external view returns(uint256);
    
    function getTotalDeposit() external view returns(uint256);
    
    function getMiningEndBlock() external view returns(uint256);
    
    function getMiningEndTime() external view returns(uint256);
    
    function isMinable() external view returns(bool);
    
    function canCompound() external view returns(bool);
    
    //-------------------------------------------------------------------------
    // USER INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function getUserShares(address _user) external view returns(uint256);
    
    function getUserPending(address _user) external view returns(uint256);
    
    function getUserDeposit(address _user) external view returns(uint256);
    
    //-------------------------------------------------------------------------
    // COMPOUND FUNCTIONS
    //-------------------------------------------------------------------------
    
    function tryCompound(address _claimAddress) external returns(bool);
    
    function compound(address _claimAddress) external;
    
    function getCompoundReward() external view returns(uint256);
    
    function getNextCompoundDelay() external view returns(uint256);

    //-------------------------------------------------------------------------
    // DEPOSIT / WITHDRAW FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getDepositFee() external view returns(uint256);
    
    function getWithdrawFee() external view returns(uint256);

    function deposit(address _user, uint256 _amount) external returns(uint256);

    function withdraw(address _user, uint256 _amount) external returns(uint256);
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IVaultChef.sol

interface IVaultChef
{
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
 
    function PERCENT_FACTOR() external view returns (uint256);
    
    //-------------------------------------------------------------------------
    // ADMIN FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getVaultConfig() external view returns (address, address, uint256, uint256);
    
    //-------------------------------------------------------------------------
    // BANK FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getBankPoolPayoutRate() external view returns(uint256);
    
    function depositToBankVault(uint256 _amount) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/Vault.sol

abstract contract Vault is IVault, AccessControl, ReentrancyGuard
{
    using SafeERC20 for IERC20;
    
    //-------------------------------------------------------------------------
    // STRUCTS
    //-------------------------------------------------------------------------
    
    struct UserInfo
    {
		uint256 refundId; // ID in map, NEVER 0
        uint256 shares; // number of shares for a user
    }
	
	struct RefundInfo
	{
		address user; //address of user to refund
	}
    
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
    
    string public constant override VERSION = "1.6";
    
    //-------------------------------------------------------------------------
    // ROLES
    //-------------------------------------------------------------------------
    
    bytes32 public constant ROLE_VAULTCHEF = keccak256("ROLE_VAULTCHEF");
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_SECURITY_ADMIN = keccak256("ROLE_SECURITY_ADMIN");
    bytes32 public constant ROLE_SECURITY_MOD = keccak256("ROLE_SECURITY_MOD");
    
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------
    
    uint256 public immutable override PERCENT_FACTOR; //100%, got from vault chef
    
    mapping(address => UserInfo) public userMap;

	mapping(uint256 => RefundInfo) private refundMap; //will be indexed at 1
	uint256 private refundOffset = 1;
	uint256 private refundLength;
    
    address public immutable vaultChef;
    address public immutable chef;
    uint256 public immutable poolID;
    address public override router;
    
    uint256 public override totalShares;
    address public override depositToken;
    address public override rewardToken;
    address public token0;
    address public token1;
	address public stakingToken;
	address public additionalReward;
    
    address public governor;
    
    uint256 public compoundDelay;
    uint256 public override lastCompoundTimestamp;
    
    bool public override pauseCompound;
    bool public override pauseDeposit;
    bool public override pauseWithdraw;
    
    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event Panic(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event Unpanic(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event Deposit(address indexed _user, uint256 _amount, uint256 _depositedAmount, uint256 _userDepositBefore, uint256 _userDepositAfter);
    event Withdraw(address indexed _user, uint256 _amount, uint256 _withdrawnAmount, uint256 _userDepositBefore, uint256 _userDepositAfter);
    event Compound(uint256 indexed _timestamp, address indexed _claimAddress, uint256 _totalDepositBefore, uint256 _totalDepositAfter, uint256 _reward, uint256 _dust);
    
    //-------------------------------------------------------------------------
    // CREATE
    //-------------------------------------------------------------------------
    
    constructor(
        address _vaultChef,
        address _chef,
        uint256 _poolID,
        address _router
    )
    {
        //base
        vaultChef = _vaultChef;
        chef = _chef;
        poolID = _poolID;
        router = _router;
        PERCENT_FACTOR = IVaultChef(_vaultChef).PERCENT_FACTOR();
        
        //init access control
        _setupRole(ROLE_ADMIN, msg.sender);
        _setupRole(ROLE_VAULTCHEF, _vaultChef);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);
        _setRoleAdmin(ROLE_VAULTCHEF, ROLE_ADMIN);
        _setRoleAdmin(ROLE_MANAGER, ROLE_ADMIN);
        _setRoleAdmin(ROLE_SECURITY_ADMIN, ROLE_ADMIN);
        _setRoleAdmin(ROLE_SECURITY_MOD, ROLE_ADMIN);
    }
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function init(bool _isTokenPair) internal
	{
		if (_isTokenPair)
		{
			token0 = ITokenPair(depositToken).token0();
            token1 = ITokenPair(depositToken).token1();
		}
    }
    
    //-------------------------------------------------------------------------
    // VAULT INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function isStaking() internal view returns(bool)
    {
        return (token0 == address(0)
            || token1 == address(0));
    }
    
    function getTotalDeposit() public view override virtual returns(uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
     
    function getDepositFee() public view override virtual returns(uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
    
    function getWithdrawFee() public view override virtual returns(uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
     
    function getMiningEndBlock() public view override virtual returns(uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
    
    function getMiningEndTime() public view override virtual returns(uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
    
    function getAllocPoints() internal view virtual returns(uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 1;
    }
    
    function isMinable() public view override returns(bool)
    {
        uint256 endBlock = getMiningEndBlock();
        uint256 endTime = getMiningEndTime();
        if (getAllocPoints() == 0
            || (endBlock > 0
                && block.number >= endBlock)
            || (endTime > 0
                && endTime >= block.timestamp))
        {
            return false;
        }
        
        return true;
    }
    
    //-------------------------------------------------------------------------
    // USER INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function getUserShares(address _user) public override view returns(uint256)
    {
        return getShare(_user, totalShares);
    }
    
    function getUserPending(address _user) public override view returns(uint256)
    {
        return getShare(_user, this.getTotalPending());
    }
    
    function getUserDeposit(address _user) public override view returns(uint256)
    {
        return getShare(_user, getTotalDeposit());
    }
    
    function getShare(address _user, uint256 _total) internal view returns(uint256)
    {
        UserInfo storage user = userMap[_user];
        if (totalShares == 0)
        {
            return 0;
        }
        
        return (user.shares * _total) / totalShares;
    }
    
    //-------------------------------------------------------------------------
    // DEPOSIT / WITHDRAW FUNCTIONS
    //-------------------------------------------------------------------------
    
    function deposit(address _user, uint256 _amount) external override nonReentrant returns(uint256)
    {	
        requireRole_VaultChef();
        require(!pauseDeposit, "Vault deposit paused!");
		if (_amount > 0)
		{
			UserInfo storage user = userMap[_user];
			uint256 origAmount = _amount;
			uint256 userDepositBefore = getUserDeposit(_user);
			
			//ensure refund list
			checkRefundMap(_user);
			
			//deposit
			(_amount, ) = safeTransferFrom_withTax(_user, address(this), depositToken, _amount);
			
			//farm
			uint256 totalDepositBefore = getTotalDeposit();
            farm();
		
			//calculate shares
			uint256 sharesAdded = _amount;
			if (totalDepositBefore > 0)
			{
				sharesAdded = (_amount * totalShares) / totalDepositBefore;
			}
			totalShares += sharesAdded;
			user.shares += sharesAdded;

            //event
            emit Deposit(_user, origAmount, _amount, userDepositBefore, getUserDeposit(_user));
		}

        return _amount;
    }

    function withdraw(address _user, uint256 _amount) external override nonReentrant returns(uint256)
    {
        requireRole_VaultChef();
        require(!pauseWithdraw, "Vault withdraw paused!");
		if (_amount > 0)
		{
            //check share & total deposit
            UserInfo storage user = userMap[_user];
            uint256 totalDeposit = getTotalDeposit();
            if (_amount > totalDeposit)
            {
                _amount = totalDeposit;
            }
            uint256 amountShares = (_amount * totalShares) / totalDeposit;
    		if (amountShares > user.shares)
    		{
    		    amountShares = user.shares;
    		}
    		
    		//calculate amount
            uint256 userDeposit = getUserDeposit(_user);
    		uint256 withdrawAmount = (totalDeposit * amountShares) / totalShares;
    		if (withdrawAmount > totalDeposit)
    		{
    		    withdrawAmount = totalDeposit;
    		}
    		uint256 origAmount = withdrawAmount;
    		
    		//withdraw from vault & transfer
            (uint256 received,) = claim(withdrawAmount);
            IERC20(depositToken).safeTransfer(_user, received);		
    		
            //set shares/deposit
            user.shares -= amountShares;
            totalShares -= amountShares;
            
		    //event
            emit Withdraw(_user, origAmount, received, userDeposit, getUserDeposit(_user));
		}

        return _amount;
    }
    
    function poolDeposit(uint256 _amount) internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        _amount; // silence unused parameter warning without generating bytecode
        return (0, 0);
    }
    
    function poolWithdraw(uint256 _amount) internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        _amount; // silence unused parameter warning without generating bytecode
        return (0, 0);
    }
    
    //-------------------------------------------------------------------------
    // FARM / CLAIM FUNCTIONS
    //-------------------------------------------------------------------------
    
    function farm() internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        //try harvest before deposit (which also could harvest reward)
        if (getNextCompoundDelay() > 0
            && totalShares > 0)
        {
            poolWithdraw(0);
        }
        
        //get balance
        uint256 amount = IERC20(depositToken).balanceOf(address(this));
        
        //make deposit
        uint256 lostRate = 0;
        IERC20(depositToken).safeIncreaseAllowance(chef, amount);
        (amount, lostRate) = poolDeposit(amount);

        return (amount, lostRate);
    }
    
    function claim(uint256 _amount) internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        if (getTotalDeposit() == 0)
        {
            return (0, 0);
        }
        
        if (_amount != 0)
        {
            //try harvest before withdraw
            poolWithdraw(0);
        }
        return poolWithdraw(_amount);
    }    
    
    //-------------------------------------------------------------------------
    // COMPOUND FUNCTIONS
    //-------------------------------------------------------------------------
    
    function canCompound() public view override returns(bool)
    {
        return (!pauseCompound
            && getNextCompoundDelay() == 0);
    }
    
    function tryCompound(address _claimAddress) public override virtual returns(bool)
    {
        if (!canCompound())
        {
            return false;
        }
        
        compound(_claimAddress);
        return true;
    }
    
    function compound(address _claimAddress) public override virtual
    {
        requireRole_VaultChef();
        require(!pauseCompound, "Vault compound paused!");
		require(getNextCompoundDelay() == 0, "compoundLock");
		
		//get dust
		uint256 dustAmount = IERC20(rewardToken).balanceOf(address(this));
	
        //claim rewards
        claim(0);
        
        //convert additional reward to reward
        if (additionalReward != address(0))
        {
            uint256 additionalBalance = IERC20(additionalReward).balanceOf(address(this));
    		if (additionalBalance > 0)
    		{
    		    swapTokens(additionalBalance, additionalReward, true);   
    		}
        }

        //convert reward to deposit
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 rewardAmount = balance - dustAmount;
		if (balance > 0)
		{
			//distribute to treasury and compound reward
			balance = distributeFees(balance, _claimAddress);
			
			//send payout to bank
			balance = sendPayoutToBank(balance);

			//exchange reward to deposit
			if (!convertRewardToDeposit(balance))
			{
			    return;
			}
		}
        
        //reinvest		
		uint256 lastEarnDeposit = getTotalDeposit();
        farm();
        
        //set metadata
        lastCompoundTimestamp = block.timestamp;
        
        //event
        emit Compound(block.timestamp, _claimAddress, lastEarnDeposit, getTotalDeposit(), rewardAmount, dustAmount);
    }
    
    function calcCompoundReward(uint256 _earned) internal view returns(uint256)
    {
        (, , , uint reward) = IVaultChef(vaultChef).getVaultConfig();
        uint claimReward = (_earned * reward) / PERCENT_FACTOR;
        
        return claimReward;
    }

    function getCompoundReward() public override view returns(uint256)
    {
        return calcCompoundReward(this.getTotalPending());
    }
    
    function getNextCompound() public virtual view returns(uint256)
    {
        return lastCompoundTimestamp + compoundDelay;
    }
    
    function getNextCompoundDelay() public override view returns(uint256)
    {
        uint next = getNextCompound();
        if (next <= block.timestamp)
        {
            return 0;
        }
        
        return next - block.timestamp;
    }
    
    //-------------------------------------------------------------------------
    // SWAP FUNCTIONS
    //-------------------------------------------------------------------------
    
    function convertRewardToDeposit(uint256 _amount) internal virtual returns(bool)
    {
        bool success = true;
		if (isStaking())
		{
			if (rewardToken != depositToken
			    && !swapTokens(_amount, depositToken, false))
			{
			    return false;
			}
		}
		else
		{
			uint256 halfEarned = _amount / 2;

			//swap half earned to token0
			if (rewardToken != token0
			    && !swapTokens(halfEarned, token0, false))
    		{
    			success = false;
    		}

			//swap half earned to token1
			if (rewardToken != token1
			    && !swapTokens(halfEarned, token1, false))
    		{
    			success = false;
    		}

			//get deposit tokens
			uint256 token0Amount = IERC20(token0).balanceOf(address(this));
			uint256 token1Amount = IERC20(token1).balanceOf(address(this));
			if (token0Amount > 0
				&& token1Amount > 0)
			{
				addLiquidity(token0Amount, token1Amount);
			}
			
			//handle remaining dust
			convertDustToReward();
		}
		
		return success;
    }

    function convertDustToReward() public virtual
    {
        if (!isStaking())
        {
            return;
        }

        //converts token0 dust (if any) to reward token
        uint256 token0Amount = IERC20(token0).balanceOf(address(this));
        if (token0 != rewardToken
            && token0Amount > 0)
        {
            swapTokens(token0Amount, token0, true);
        }

        //converts token1 dust (if any) to reward token
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));
        if (token1 != rewardToken
            && token1Amount > 0)
        {
            swapTokens(token1Amount, token1, true);
        }
    }
    
    function addLiquidity(uint256 _amount0, uint256 _amount1) internal virtual
    {
        address projectRouter = IToTheMoonRouter(router).router();
        
		//increase allowance
		IERC20(token0).safeIncreaseAllowance(projectRouter, _amount0);
		IERC20(token1).safeIncreaseAllowance(projectRouter, _amount1);
		
		//add Liquidity
		IRouter02(projectRouter).addLiquidity(
            token0,
            token1,
            _amount0,
            _amount1,
            0,
            0,
           address(this),
           block.timestamp + 60
        );
    }
    
    function swapTokens(uint256 _amount, address _token, bool _toReward) internal virtual returns(bool)
    {
	    address projectRouter = IToTheMoonRouter(router).router();
	    
		//increase allowance
		IERC20((_toReward ? _token : rewardToken)).safeIncreaseAllowance(projectRouter, _amount);
	
		//swap
		try IRouter02(projectRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            IToTheMoonRouter(router).makeSwapPath(
                (_toReward ? _token : rewardToken),
                (_toReward ? rewardToken : _token)),
            address(this),
            block.timestamp + 60
        )
        {
            return true;
        }
        catch
        {
            return false;
        }
    }
    
    //-------------------------------------------------------------------------
    // BANK FUNCTIONS
    //-------------------------------------------------------------------------
    
    function sendPayoutToBank(uint256 _rewardBalance) internal returns(uint256)
    {
        //send payout to bank
		uint256 bankPayoutRate = IVaultChef(vaultChef).getBankPoolPayoutRate();
		uint256 reinvest = reduceByFee(_rewardBalance, bankPayoutRate);
		uint256 payout = _rewardBalance - reinvest;
		if (payout > 0)
		{
		    (, address bank, ,) = IVaultChef(vaultChef).getVaultConfig();
		    IERC20(rewardToken).safeIncreaseAllowance(bank, payout);
		    IVaultChef(vaultChef).depositToBankVault(payout);
		}
		return reinvest;
    }
	
    //-------------------------------------------------------------------------
    // TREASURY FUNCTIONS
    //-------------------------------------------------------------------------
	
	function withdrawToTreasury(address _token) external
	{
		//check if allowed (only unused tokens or when no deposit)
		bool locked = false;
		if (getTotalDeposit() != 0
			&& (_token == token0
				|| _token == token1
				|| _token == rewardToken
				|| _token == additionalReward
				|| _token == depositToken
				|| _token == stakingToken))
		{
			locked = true;
		}
		require(!locked, "locked");
		
		//transfer
		uint256 balance = IERC20(_token).balanceOf(address(this));
		if (balance > 0)
		{
			(address treasury, , ,) = IVaultChef(vaultChef).getVaultConfig();		
			IERC20(_token).safeTransfer(treasury, balance);
		}
	}
    
    function distributeFees(uint256 _earned, address _claimAddress) internal returns(uint256)
    {
        if (_earned > 0)
        {
            (address treasury, , uint256 fee,) = IVaultChef(vaultChef).getVaultConfig();
            
            //claim reward
            uint256 claimAmount = calcCompoundReward(_earned);
            if (claimAmount > 0)
            {
                IERC20(rewardToken).safeTransfer(_claimAddress, claimAmount);
            }

            //treasury fee
            uint256 treasuryAmount = 0;
            if (fee > 0)
            {
                treasuryAmount = (_earned * fee) / PERCENT_FACTOR;
                IERC20(rewardToken).safeTransfer(treasury, treasuryAmount);
                _earned -= treasuryAmount;
            }
            
            //reduce earned
            _earned -= claimAmount + treasuryAmount;
        }

        return _earned;
    }
	
	//-------------------------------------------------------------------------
    // REFUND FUNCTIONS
    //-------------------------------------------------------------------------

	function checkRefundMap(address _user) internal
	{
		UserInfo storage user = userMap[_user];
		if (user.refundId != 0)
		{
			//user is already in refund map
			return;
		}
		
		//set user data
		refundLength += 1;
		user.refundId = refundLength; //0 is never used
		
		//create refund data
		RefundInfo storage refund = refundMap[user.refundId];
		refund.user = _user;
	}
	
	function resetRefundOffset() external
	{
	    requireRole_Admin();
		refundOffset = 1;
	}
	
	function refundUsers(uint256 _count) external
	{
	    requireRole_Admin();
	    require(!pauseDeposit, "Vault deposit not paused!");
	    require(!pauseWithdraw, "Vault withdraw not paused!");

	    uint256 to = refundOffset + _count;
	    if (to > refundLength)
	    {
	        to = refundLength;
	    }
	    
		for (uint256 n = refundOffset; n <= to; n++)
		{
			RefundInfo storage refund = refundMap[n];
			UserInfo storage user = userMap[refund.user];
			
			//get user data
			uint256 userBalance = getUserDeposit(refund.user);
			if (userBalance > 0)
			{
				//claim			
				(uint256 received,) = claim(userBalance);
				
				//transfer
				IERC20(depositToken).safeTransfer(refund.user, received);		
				
				//set shares/deposit
				totalShares -= user.shares;
				user.shares = 0;
			}
			
			//next refund
			refundOffset += 1;			
		}	
	}
	
	//-------------------------------------------------------------------------
    // TRANSFER WITH TAX FUNCTIONS
    //-------------------------------------------------------------------------
    
    function safeTransferFrom_withTax(address _from, address _to, address _token, uint256 _amount) internal returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = IERC20(_token).balanceOf(_to);
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
        return calculateTransferLoss(_to, _token, _amount, balanceBefore);
    }
    
    function safeTransfer_withTax(address _to, address _token, uint256 _amount) internal returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = IERC20(_token).balanceOf(_to);
        IERC20(_token).safeTransfer(_to, _amount);
        return calculateTransferLoss(_to, _token, _amount, balanceBefore);
    }
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function calculateTransferLoss(address _target, address _token, uint256 _amount, uint256 _balanceBefore) internal view returns(uint256 _received, uint256 _lostRate)
    {
        if (_amount == 0)
        {
            return (0, 0);
        }
        uint256 balanceAfter = IERC20(_token).balanceOf(_target);
        return calculateTransferLossValue(_amount, _balanceBefore, balanceAfter);
    }
    
    function calculateTransferLossValue(uint256 _amount, uint256 _balanceBefore, uint256 _balanceAfter) internal view returns(uint256 _received, uint256 _lostRate)
    {
        if (_amount == 0)
        {
            return (0, 0);
        }
        uint256 received = _balanceAfter - _balanceBefore;
        uint256 lost = _amount - received;
        uint256 lostRate = (lost * PERCENT_FACTOR) / _amount;
        return (received, lostRate);
    }
    
    function reduceByFee(uint256 _value, uint256 _feeRate) internal view returns(uint256)
    {
        if (_feeRate == 0)
        {
            return _value;
        }
        return (_value * (PERCENT_FACTOR - _feeRate)) / PERCENT_FACTOR;
    }
    
    //-------------------------------------------------------------------------
    // GOVERNANCE FUNCTIONS
    //-------------------------------------------------------------------------
    
    function pause(bool _disableDeposit, bool _disableWithdraw, bool _disableCompound) external
    {
        requireRole_SecurityMod();
        
        if (_disableDeposit)
        {    
            pauseDeposit = true;
        }
        if (_disableWithdraw)
        {    
            pauseWithdraw = true;
        }
        if (_disableCompound)
        {    
            pauseCompound = true;
        }
        emit Panic(msg.sender, _disableDeposit, _disableWithdraw, _disableCompound);
    }
    
    function unpause(bool _enableDeposit, bool _enableWithdraw, bool _enableCompound) external
    {
        requireRole_SecurityAdmin();
        
        if (_enableDeposit)
        {    
            pauseDeposit = false;
        }
        if (_enableWithdraw)
        {    
            pauseWithdraw = false;
        }
        if (_enableCompound)
        {    
            pauseCompound = false;
        }
        emit Unpanic(msg.sender, _enableDeposit, _enableWithdraw, _enableCompound);
    }
    
    function setCompoundDelay(uint256 _delay) external
    {
        requireRole_Manager();
        compoundDelay = _delay;
    }
    
    function setRouter(address _router) external
    {
        requireRole_Manager();
        router = _router;
    }
    
    //-------------------------------------------------------------------------
    // ACCESS CONTROL FUNCTIONS
    //-------------------------------------------------------------------------

    function requireRole_VaultChef() internal view
    {
        require(hasRole(ROLE_VAULTCHEF, msg.sender), "Caller is not VaultChef");
    }
    
    function requireRole_Admin() internal view
    {
        require(hasRole(ROLE_ADMIN, msg.sender), "Caller is not Admin");
    }

    function requireRole_Manager() internal view
    {
        require(hasRole(ROLE_ADMIN, msg.sender) || hasRole(ROLE_MANAGER, msg.sender), "Caller is not Admin/Manager");
    }
    
    function requireRole_SecurityAdmin() internal view
    {
        require(hasRole(ROLE_ADMIN, msg.sender) || hasRole(ROLE_SECURITY_ADMIN, msg.sender), "Caller is not Admin/SecurityAdmin");
    }
    
    function requireRole_SecurityMod() internal view
    {
        require(hasRole(ROLE_ADMIN, msg.sender) || hasRole(ROLE_SECURITY_ADMIN, msg.sender) || hasRole(ROLE_SECURITY_MOD, msg.sender), "Caller is not Admin/SecurityAdmin/SecurityMod");
    }
}

// File: .deps/github/Loesil/VaultChef/contracts/DeFi Projects/ApeSwap/VaultApeSwapMaster.sol

contract VaultApeSwapMaster is Vault
{
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------

    address public constant REWARD_TOKEN = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    
    address public constant CHEF = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;
    
    address public constant ROUTER = 0x5F4B9F765194af6aB76741958c3121B2970f1879;
	
	address public constant STAKING_TOKEN = 0x86Ef5e73EDB2Fea111909Fe35aFcC564572AcC06;
    
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------

    bool public immutable isCAKEStaking;
    
    //-------------------------------------------------------------------------
    // CREATE
    //-------------------------------------------------------------------------
    
    constructor(
        address _vaultChef,
        uint256 _poolID,
        bool _isTokenPair
    ) Vault(
        _vaultChef,
        CHEF,
        _poolID,
		ROUTER
    )
    {
        //tokens
        (depositToken, , ,) = IApeMasterChef(CHEF).poolInfo(_poolID);
        rewardToken = REWARD_TOKEN;		
        isCAKEStaking = (_poolID == 0);
		stakingToken = STAKING_TOKEN;
        
        //init
        init(_isTokenPair);
    }
    
    //-------------------------------------------------------------------------
    // VAULT INFO FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getTotalPending() public override view returns (uint256)
    {
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 pending = IApeMasterChef(chef).pendingCake(poolID, address(this));
        
        return balance + pending;
    }
    
    function getTotalDeposit() public view override returns (uint256)
    {
        (uint256 deposit, ) = IApeMasterChef(chef).userInfo(poolID, address(this));
        return deposit;
    }
	
	function getAllocPoints() internal view override returns (uint256)
    {
        (, uint256 alloc, , ) = IApeMasterChef(chef).poolInfo(poolID);
        return alloc;
    }
    
    //-------------------------------------------------------------------------
    // DEPOSIT / WITHDRAW FUNCTIONS
    //-------------------------------------------------------------------------
    
    function poolDeposit(uint256 _amount) internal override returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = getTotalDeposit();
        if (isCAKEStaking)
        {
            IApeMasterChef(chef).enterStaking(_amount);
        }
        else
        {
            IApeMasterChef(chef).deposit(poolID, _amount);
        }
        return calculateTransferLossValue(_amount, balanceBefore, getTotalDeposit());
    }
    
    function poolWithdraw(uint256 _amount) internal override returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = IERC20(depositToken).balanceOf(address(this));
         if (isCAKEStaking)
        {
            IApeMasterChef(chef).leaveStaking(_amount);
        }
        else
        {
            IApeMasterChef(chef).withdraw(poolID, _amount);
        }
        return calculateTransferLoss(address(this), depositToken, _amount, balanceBefore);
    }
}