/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Address.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol";
// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Address.sol";

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Context.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Strings.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\introspection\ERC165.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol";

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


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\access\AccessControl.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Context.sol";
// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Strings.sol";
// import "D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\introspection\ERC165.sol";

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


// Dependency file: contracts\interfaces\ILaunchPadFactory.sol

// pragma solidity ^0.8.4;

interface ILaunchPadFactory {
    /**
     * @dev Deploy laucnpad project contracts
     */
    function deployProject(
        address admin,
        address projectToken,
        address allocationToken,
        uint256 totalAllocationSize,
        address holderToken,
        uint256 price,
        uint256 start,
        uint256 end,
        uint256 minAmount
    ) external;

    /**
     * @dev set admin address for deployed project
     */
    function setProjectAdmin(address projectContract, address admin) external;

    /**
     * @dev revoke admin role from address for deployed project
     */
    function revokeProjectAdmin(address projectContract, address admin) external;
}


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\math\SafeMath.sol


// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Dependency file: D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\security\ReentrancyGuard.sol


// pragma solidity ^0.8.0;

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


// Dependency file: contracts\utils\FullMath.sol

// pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// Dependency file: contracts\VRMLaunchpadProject.sol

// pragma solidity ^0.8.4;
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\math\SafeMath.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\access\AccessControl.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Address.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\security\ReentrancyGuard.sol';
// import 'contracts\interfaces\ILaunchPadFactory.sol';
// import 'contracts\utils\FullMath.sol';

contract VRMLaunchpadProject is AccessControl, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum ProjectState {
        FundRaising,
        Allocation,
        Closed
    }
    // info about allocation request
    struct RequestInfo {
        address allocationToken;
        uint256 date;
        uint256 amount;
    }
    struct UserInfo {
        address user;
        uint256 total;
        address allocationToken;
        address holderToken;
        uint256 holderTokenBalance;
    }

    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
    }
    /* ========== STATE VARIABLES ========== */

    ILaunchPadFactory public factory;
    IERC20 public projectToken;
    IERC20 public allocationToken;
    IERC20 public holderToken;
    uint256 public totalAllocationSize;
    uint256 public price;
    uint256 public start;
    uint256 public end;
    uint256 public minAmount;
    ProjectState public state = ProjectState.FundRaising;

    uint256 public arrayLimit;

    uint256 public lastUpdateTime;

    uint256 private _totalSupply;
    uint256 private _totalUsers;
    uint256 private _totalProcessed;
    uint256 private _totalTransferred;

    mapping(address => uint256) private _totals;
    mapping(address => RequestInfo[]) private _requests;
    mapping(address => bool) private _processed;
    mapping(uint256 => address) private _holders;

    address[] public admins;
    uint256 public totalAdmins;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /* ========== EVENTS ========== */
    event NewAllocationRequest(
        address indexed user,
        address indexed allocationToken,
        uint256 amount,
        uint256 totalSupply,
        address holderToken,
        uint256 holderTokenBalance
    );
    event AddAllocationRequest(
        address indexed user,
        address indexed allocationToken,
        uint256 amount,
        uint256 totalRequestsSupply,
        uint256 totalSupply,
        address holderToken,
        uint256 holderTokenBalance
    );

    event AllocationTransferred(address indexed token, uint256 amount);
    event ProjectClosed(address indexed token, uint256 totalTransferred);

    constructor(
        address _admin,
        address _projectToken,
        address _allocationToken,
        uint256 _totalAllocationSize,
        address _holderToken,
        uint256 _price,
        uint256 _start,
        uint256 _end,
        uint256 _minAmount
    ) {
        require(_projectToken != _allocationToken, 'project token and allocation token must be not the same!');
        require(IERC20Metadata(_projectToken).decimals() > 0, '_projectToken is not Token contract');
        require(IERC20Metadata(_allocationToken).decimals() > 0, '_allocationToken is not Token contract');
        require(_totalAllocationSize > 0, '_totalAllocationSize=0');
        require(_holderToken != address(0), 'Empty holder token address');
        require(IERC20Metadata(_holderToken).decimals() > 0, '_holderToken is not Token contract');
        require(_price > 0, '_price=0');
        require(_start > 0, '_start=0');
        require(_end > 0, '_end=0');
        require(_end > _start, 'end date must after start date');
        require(_minAmount > 0, '_minAmount=0');

        require(isContract(_msgSender()), 'not a factory contract');
        require(!isContract(_admin), 'admin address must be not contract address');

        factory = ILaunchPadFactory(_msgSender());
        projectToken = IERC20(_projectToken);
        allocationToken = IERC20(_allocationToken);
        holderToken = IERC20(_holderToken);
        price = _price;
        start = _start;
        end = _end;
        minAmount = _minAmount;
        lastUpdateTime = block.timestamp;
        arrayLimit = 200;
        totalAllocationSize = _totalAllocationSize;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _admin);
        admins.push(_msgSender());
        admins.push(_admin);
        totalAdmins = admins.length;
    }

    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        admins.push(account);
        totalAdmins = admins.length;
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        bool found = false;
        uint256 index = 0;
        for (; index < admins.length; index++) {
            if (admins[index] == account) {
                found = true;
                break;
            }
        }
        if (!found) return;

        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        admins.pop();
        totalAdmins = admins.length;
    }

    function setArrayLimit(uint256 _newLimit) public onlyRole(ADMIN_ROLE) {
        require(_newLimit != 0);
        arrayLimit = _newLimit;
    }

    // TODO: remove
    function updateParams(
        uint256 _start,
        uint256 _end,
        ProjectState _state,
        uint256 _minAmount,
        uint256 _totalAllocationSize
    ) public onlyRole(ADMIN_ROLE) {
        require(_start > 0, '_start=0');
        require(_end > 0, '_end=0');
        require(_end > _start, 'end date must after start date');
        require(_minAmount > 0, '_minAmount=0');
        start = _start;
        end = _end;
        state = _state;
        minAmount = _minAmount;
        totalAllocationSize = _totalAllocationSize;
        lastUpdateTime = block.timestamp;
    }

    function canAllocateRequest(uint256 amount) public view returns (bool) {
        return
            state == ProjectState.FundRaising &&
            block.timestamp >= start &&
            block.timestamp < end &&
            amount >= minAmount;
    }

    function allocateRequest(uint256 amount) public nonReentrant {
        require(state == ProjectState.FundRaising, 'fund-raising done');
        require(block.timestamp >= start, 'not started');
        require(block.timestamp < end, 'has finished');
        require(amount >= minAmount, 'amount must be greater than minAmount');
        uint256 allowance = allocationToken.allowance(_msgSender(), address(this));
        require(allowance >= amount, 'amount not aproved for this contract');

        allocationToken.safeTransferFrom(_msgSender(), address(this), amount);

        RequestInfo[] storage userRequests = _requests[_msgSender()];
        bool newRequest = userRequests.length == 0;
        uint256 holderTokenBalance = holderToken.balanceOf(_msgSender());
        userRequests.push(RequestInfo(address(allocationToken), block.timestamp, amount));

        _totals[_msgSender()] = _totals[_msgSender()].add(amount);
        _totalSupply = _totalSupply.add(amount);
        if (newRequest) {
            _holders[_totalUsers] = _msgSender();
            _totalUsers = _totalUsers.add(1);
            emit NewAllocationRequest(
                _msgSender(),
                address(allocationToken),
                amount,
                _totalSupply,
                address(holderToken),
                holderTokenBalance
            );
        } else {
            emit AddAllocationRequest(
                _msgSender(),
                address(allocationToken),
                amount,
                _totals[_msgSender()],
                _totalSupply,
                address(holderToken),
                holderTokenBalance
            );
        }
    }

    function getTotals(address user) public view returns (uint256) {
        return _totals[user];
    }

    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getTotalUsers() public view returns (uint256) {
        return _totalUsers;
    }

    function getUsers() public view returns (UserInfo[] memory) {
        UserInfo[] memory users = new UserInfo[](_totalUsers);
        for (uint256 index = 0; index < _totalUsers; index++) {
            uint256 holderTokenBalance = holderToken.balanceOf(_holders[index]);
            users[index] = UserInfo(
                _holders[index],
                _totals[_holders[index]],
                address(allocationToken),
                address(holderToken),
                holderTokenBalance
            );
        }
        return users;
    }

    function _getTokenInfo(address token) internal view returns (TokenInfo memory info) {
        IERC20Metadata meta = IERC20Metadata(token);
        info.tokenAddress = token;
        info.symbol = meta.symbol();
        info.decimals = meta.decimals();
        info.name = meta.name();
    }

    function getProjectTokenInfo() public view returns (TokenInfo memory) {
        return _getTokenInfo(address(projectToken));
    }

    function getAllocationTokenInfo() public view returns (TokenInfo memory) {
        return _getTokenInfo(address(allocationToken));
    }

    function getHolderTokenInfo() public view returns (TokenInfo memory) {
        return _getTokenInfo(address(holderToken));
    }

    function startAllocation() external nonReentrant onlyRole(ADMIN_ROLE) {
        require(state == ProjectState.FundRaising, 'project not in fund-raising state');
        require(block.timestamp > end, 'fund-raising must be finished');
        state = ProjectState.Allocation;
        lastUpdateTime = block.timestamp;
    }

    function closeProject() external nonReentrant onlyRole(ADMIN_ROLE) {
        require(state == ProjectState.Allocation, 'project not in Allocation state');
        state = ProjectState.Closed;
        lastUpdateTime = block.timestamp;
        state = ProjectState.Closed;
        allocationToken.safeTransfer(_msgSender(), allocationToken.balanceOf(address(this)));
        emit ProjectClosed(address(projectToken), _totalTransferred);
    }

    function transferAllocations(address[] memory _contributors, uint256[] memory _projectTokenBalances)
        external
        nonReentrant
        onlyRole(ADMIN_ROLE)
    {
        require(block.timestamp > end, 'fund-raising must be finished');
        require(_contributors.length <= arrayLimit);
        require(state == ProjectState.Allocation, 'project not in Allocation state');
        uint256 total = 0;
        uint8 i = 0;
        uint8 projectTokenDecimals = IERC20Metadata(address(projectToken)).decimals();
        for (i; i < _contributors.length; i++) {
            if (!_processed[_contributors[i]]) {
                uint256 totalInAllocationToken = _totals[_contributors[i]];
                uint256 balanceInAllocationToken = FullMath.mulDiv(
                    _projectTokenBalances[i],
                    price,
                    10**projectTokenDecimals
                );
                projectToken.safeTransferFrom(_msgSender(), _contributors[i], _projectTokenBalances[i]);
                if (totalInAllocationToken > balanceInAllocationToken && balanceInAllocationToken > 0) {
                    allocationToken.safeTransfer(
                        _contributors[i],
                        totalInAllocationToken.sub(balanceInAllocationToken)
                    );
                }
                _processed[_contributors[i]] = true;
                total = total.add(_projectTokenBalances[i]);
                _totalProcessed = _totalProcessed.add(1);
                _totalTransferred = _totalTransferred.add(total);
            }
        }
        lastUpdateTime = block.timestamp;
        emit AllocationTransferred(address(projectToken), total);
    }
}


// Root file: contracts\VRMLaunchpadFactory.sol

pragma solidity ^0.8.4;
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\access\AccessControl.sol';
// import 'D:\repos\VRM\VRM-Launchpad\VRM.Launchpad.Contracts\node_modules\@openzeppelin\contracts\utils\Address.sol';
// import 'contracts\interfaces\ILaunchPadFactory.sol';
// import 'contracts\VRMLaunchpadProject.sol';

contract VRMLaunchpadFactory is AccessControl, ILaunchPadFactory {
    using Address for address payable;
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    // info about project
    struct ProjectInfo {
        address projectContract;
        address projectToken;
        address allocationToken;
        address holderToken;
        uint256 totalAllocationSize;
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 minAmount;
    }

    ProjectInfo[] public projects;
    uint256 public totalProjects;
    mapping(address => uint256) public projectToIndex;

    /* ========== EVENTS ========== */

    event ProjectDeployed(address indexed projectContract);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function deployProject(
        address admin,
        address projectToken,
        address allocationToken,
        uint256 totalAllocationSize,
        address holderToken,
        uint256 price,
        uint256 start,
        uint256 end,
        uint256 minAmount
    ) external override {
        require(hasRole(ADMIN_ROLE, _msgSender()), 'Caller is not an admin');
        address deployedContract = address(
            new VRMLaunchpadProject(
                admin,
                projectToken,
                allocationToken,
                totalAllocationSize,
                holderToken,
                price,
                start,
                end,
                minAmount
            )
        );
        projects.push(
            ProjectInfo(
                deployedContract,
                projectToken,
                allocationToken,
                holderToken,
                totalAllocationSize,
                price,
                start,
                end,
                minAmount
            )
        );
        totalProjects = projects.length;
        projectToIndex[deployedContract] = totalProjects - 1;
        emit ProjectDeployed(deployedContract);
    }

    function setProjectAdmin(address projectContract, address admin) external override onlyRole(ADMIN_ROLE) {
        ProjectInfo storage info = projects[projectToIndex[projectContract]];
        require(
            info.projectContract != address(0),
            'VRMLaunchpadFactory::setProjectAdmin: project contract is not deployed'
        );
        VRMLaunchpadProject project = VRMLaunchpadProject(info.projectContract);
        project.grantRole(project.ADMIN_ROLE(), admin);
    }

    function revokeProjectAdmin(address projectContract, address admin) external override onlyRole(ADMIN_ROLE) {
        ProjectInfo storage info = projects[projectToIndex[projectContract]];
        require(
            info.projectContract != address(0),
            'VRMLaunchpadFactory::revokeProjectAdmin: project contract is not deployed'
        );
        VRMLaunchpadProject project = VRMLaunchpadProject(info.projectContract);
        project.revokeRole(project.ADMIN_ROLE(), admin);
    }

    function getProjectInfo(address projectContract) public view returns (ProjectInfo memory) {
        ProjectInfo storage info = projects[projectToIndex[projectContract]];
        require(
            info.projectContract != address(0),
            'VRMLaunchpadFactory::getProjectInfo: project contract is not deployed'
        );
        return info;
    }
}