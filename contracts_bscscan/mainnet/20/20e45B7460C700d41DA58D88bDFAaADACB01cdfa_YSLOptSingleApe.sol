/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
    uint256[49] private __gap;
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IStrategy {
    function deposit(address from, uint256 amount) external;

    function withdraw(uint256 amount, address user) external;

    function getUserDepositedUSD(address user) external view returns (uint256);

    function transferOut(address _user, uint256 _amount) external returns (uint256);

    function transferIn(address _user, uint256 _amount) external returns (uint256);

    function earn(address user, bool isAmplified) external;

    function lpToken() external view returns (IERC20);

    function totalDeposited() external view returns (uint256);

    function currentReward(address _user) external view returns(uint256);
}

abstract contract YSLOpt is AccessControlUpgradeable, IStrategy {
    using SafeERC20 for IERC20;

    bytes32 public constant STRAT_ROLE = keccak256("STRAT_ROLE");
    uint256 public constant FEE_ACCURACY = 10000; // up to 2 decimals
    uint256 public constant DUST = 1e12;

    //BUSD token
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    //WBNB token
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /// @notice Underlying of the protocol
    IERC20 public override lpToken;

    address public feeAddress;
    address public referral;
    address public adapter;
    address public stratSwap;

    uint256 public coef_opt;
    uint256 public coef_opt_ref;
    uint256 public coef_ampl;
    uint256 public coef_ref;

    mapping(address => uint256) public userDeposited;
    uint256 public override totalDeposited;

    uint256 public optimizationTax;
    uint256 public controllerFee;

    /**********
     * MANAGEMENT INTERFACE
     **********/

    /// @notice Initializer
    /// @param _adapter ApeSwap adapter for locked liquidity
    /// @param _lpToken Underlying to be staked
    /// @param _feeAddress Treasury
    /// @param _referral Referral contract
    /// @param _stratSwap Swap contract for strategies
    function initialize(
        address _adapter,
        address _lpToken,
        address _feeAddress,
        address _referral,
        address _stratSwap
    ) internal virtual initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(STRAT_ROLE, address(this));

        optimizationTax = 1500; // 15%
        controllerFee = 30; // 0.3%

        coef_opt = 16500; // 165%
        coef_opt_ref = 17500; // 175% for the referrals
        coef_ampl = 22500; // 225% for amplification
        coef_ref = 1000; // 10% for referrees

        lpToken = IERC20(_lpToken);

        feeAddress = _feeAddress;

        adapter = _adapter;
        referral = _referral;
        stratSwap = _stratSwap;
    }

    function setCoefficients(
        uint256 _copt,
        uint256 _cs1,
        uint256 _cs2,
        uint256 _cref
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        coef_opt = _copt;
        coef_opt_ref = _cs1;
        coef_ampl = _cs2;
        coef_ref = _cref;
    }

    function setOptimizationTax(uint256 _tax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tax < FEE_ACCURACY, "Incorrect value");
        optimizationTax = _tax;
    }

    function setControllerFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_fee >= 30 && _fee <= 100, "Controller fee must lay within [0.3%; 1%]");
        controllerFee = _fee;
    }

    /**********
     * INPUT/OUTPUT INTERFACE
     **********/
    function deposit(address _from, uint256 _amount) public virtual override onlyRole(STRAT_ROLE) {
        userDeposited[_from] += _amount;
        totalDeposited += _amount;

        lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    function withdraw(uint256 _amount, address _user) external virtual override onlyRole(STRAT_ROLE) {
        withdrawAcc(_amount);

        userDeposited[_user] -= _amount;
        totalDeposited -= _amount;

        lpToken.approve(_msgSender(), _amount);
    }

    function swapBUSDForETH(uint256 amount, address _router) internal {
        address[] memory _path = new address[](2);
        _path[0] = BUSD;
        _path[1] = WBNB;
        IERC20(BUSD).approve(_router, amount);
        IPancakeRouter02(_router).swapExactTokensForETH(amount, 1, _path, feeAddress, block.timestamp + 10000);
    }

    function earn(address _user, bool _isAmplified) external virtual override;

    function compound() external virtual;

    /**********
     * INTERNAL HELPERS
     **********/

    function withdrawAcc(uint256 _amount) internal virtual;

    function collectControllerFee(uint256 _amount, address _router) internal {
        uint256 fee = (_amount * controllerFee) / FEE_ACCURACY;
        swapBUSDForETH(fee, _router);
    }

    function collectOptimisationTax(uint256 _amount) internal {
        uint256 tax = (_amount * optimizationTax) / FEE_ACCURACY;
        IERC20(BUSD).safeTransfer(feeAddress, tax);
    }

    function addLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address _router,
        address receiver
    ) internal returns (uint256 amount) {
        IERC20(token0).approve(_router, amount0);
        IERC20(token1).approve(_router, amount1);
        (, , amount) = (
            IPancakeRouter02(_router).addLiquidity(
                token0,
                token1,
                amount0,
                amount1,
                1,
                1,
                receiver,
                block.timestamp + 10000
            )
        );
        return amount;
    }

    function getPrice(
        address token0,
        address token1,
        uint256 amount,
        address _router
    ) internal view returns (uint256 out) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        out = IPancakeRouter02(_router).getAmountsOut(amount, path)[1];
    }
}
interface IStrategySwap {
    function sYSL() external view returns (address);

    function YSL() external view returns (address);

    function reversedPath(address[] memory path) external pure returns (address[] memory);

    function lock(
        uint256 amount,
        uint256 lockTime,
        address user
    ) external;

    function unlock(address user) external;

    function migrate(uint256 amount, address pool) external;

    function swapLPToBusd(
        uint256 _amount,
        address _router,
        address[] memory _path,
        IERC20 lpToken
    ) external returns (uint256);

    function swapBusdToLP(
        uint256 _amount,
        address _router,
        address[] memory _path
    ) external returns (uint256);

    function swapLPToBusd(
        uint256 _amount,
        address _router,
        address[] memory path0,
        address[] memory path1,
        IERC20 lpToken
    ) external returns (uint256);

    function swapBusdToLP(
        uint256 _amount,
        address _router,
        address[] memory path0,
        address[] memory path1,
        IERC20 lpToken
    ) external;

    function getBusdAmount(
        uint256 _amount,
        IERC20 lpToken,
        address _router,
        address[] memory path0,
        address[] memory path1
    ) external view returns (uint256);

    function getBusdAmount(
        uint256 _amount,
        address[] memory path,
        address _router
    ) external view returns (uint256);
}

interface IsYSL is IERC20 {
    function YSLSupply() external returns (uint256);

    function isMinted() external returns (bool);

    function mintPurchased(
        address account,
        uint256 amount,
        uint256 lockTime
    ) external;

    function mintAirdropped(
        address account,
        uint256 amount,
        uint256 locktime
    ) external;

    function mintFor(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(uint256 amount) external;
}

interface IReferral {
    function hasReferral(address _account) external view returns (bool);

    function referrals(address _account) external view returns (address);

    function proccessReferral(
        address _sender,
        address _segCreator,
        bytes memory _sig
    ) external;

    function proccessReferral(address _sender, address _segCreator) external;
}

interface IPancakeMaster {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function deposit(uint256 id, uint256 amount) external;

    function withdraw(uint256 poolId, uint256 amount) external;

    function userInfo(uint256 id, address _user) external view returns (UserInfo memory);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
}
interface ILock {
    function setLock(
        uint256 _time,
        address _beneficiary,
        uint256 _amount
    ) external;

    function releaseClient(address _beneficiary, uint256 _amount) external;

    function lock(
        uint256 _amount,
        uint256 _time,
        address _user
    ) external;
}


contract YSLOptSingleApe is YSLOpt {
    using SafeERC20 for IERC20;

    ///@notice ApeSwap router
    address public constant apeSwap = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address public constant apeMaster = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;

    address[] public path0;

    address public lockContract;
    IERC20 public want;
    uint256 public id;

    uint256 public maturityEarn;
    mapping(address=>uint256) public lastEarn;

    function initialize(
        uint256 _id,
        address _adapter,
        address _lpToken,
        address _feeAddress,
        address _referral,
        address _stratSwap,
        address _lockContract,
        address _want,
        address[] memory _path
    ) public initializer {
        super.initialize(_adapter, _lpToken, _feeAddress, _referral, _stratSwap);
        path0 = _path;

        lockContract = _lockContract;
        id = _id;
        want = IERC20(_want);
    }

    function setLockContract(address _lockContract) external onlyRole(STRAT_ROLE) {
        lockContract = _lockContract;
    }

    function setMaturityEarn(uint256 _maturityEarn) external onlyRole(STRAT_ROLE) {
        maturityEarn = _maturityEarn;
    }

    /**********
     * MANAGEMENT INTERFACE
     **********/

    /// @notice Function to be called every hour in order to provide compounds
    function compound() external override {
        address[] memory path = new address[](2);
        path[0] = address(want);
        path[1] = BUSD;

        uint256 wantBalanceBefore = want.balanceOf(address(this));
        // Get current APR from the protocol
        withdrawAcc(0);

        uint256 wantBalanceAfter = want.balanceOf(address(this));

        // Convert to BUSD
        uint256 wantBalance = wantBalanceAfter - wantBalanceBefore;
        if (wantBalance > DUST) {
            want.approve(apeSwap, wantBalance);
            IPancakeRouter02(apeSwap).swapExactTokensForTokens(
                wantBalance,
                1,
                path,
                address(this),
                block.timestamp + 10000
            );

            // Deduct Controller fee
            uint256 usdBefore = IERC20(BUSD).balanceOf(address(this));
            collectControllerFee(usdBefore, apeSwap);

            // Deduct Optimisation Tax
            usdBefore = IERC20(BUSD).balanceOf(address(this));
            collectOptimisationTax(usdBefore);

            // Get underlying from the harvested BUSD
            IERC20(BUSD).approve(stratSwap, IERC20(BUSD).balanceOf(address(this)));
            IStrategySwap(stratSwap).swapBusdToLP(IERC20(BUSD).balanceOf(address(this)), apeSwap, path0);
        }
        // Deposit (compound) underlyings
        uint256 lpBalance = lpToken.balanceOf(address(this));
        if (lpBalance > DUST) {
            lpToken.approve(apeMaster, lpToken.balanceOf(address(this)));
            IPancakeMaster(apeMaster).enterStaking(lpToken.balanceOf(address(this)));
        }
    }

    /// @notice Function to harvest earnings by the user
    function earn(address _user, bool _isAmplified) external override onlyRole(STRAT_ROLE) {
        if (totalDeposited == 0 || userDeposited[_user] == 0) return;

        // Get total compounds
        uint256 totalCompounds = IPancakeMaster(apeMaster).userInfo(id, address(this)).amount;
        totalCompounds += lpToken.balanceOf(address(this));
        require(totalCompounds >= totalDeposited, "Cannot earn because of incorrect compounds");

        // Get users share of compounds: rewards * user's share
        uint256 userCompounds = ((totalCompounds - totalDeposited) * userDeposited[_user]) / totalDeposited;

        if (maturityEarn > 0) {
            uint256 period = block.timestamp - lastEarn[_user];
            if (period < maturityEarn) {
                userCompounds = userCompounds * period / maturityEarn;
            }
            lastEarn[_user] = block.timestamp;
        }

        if (userCompounds <= DUST) return;

        // Withdraw users share of compounds. Take from current amount if need
        uint256 curBalance = lpToken.balanceOf(address(this));
        if (curBalance < userCompounds) {
            IPancakeMaster(apeMaster).leaveStaking(userCompounds - curBalance);
        }

        // Sell user's compounded amount into BUSD
        lpToken.approve(stratSwap, userCompounds);
        uint256 usersCompUSD = IStrategySwap(stratSwap).swapLPToBusd(userCompounds, apeSwap, path0, lpToken);

        // Mint YSL equivalent to the collected BUSD
        address[] memory path = new address[](2);
        address _ysl = IStrategySwap(stratSwap).YSL();
        path[0] = BUSD;
        path[1] = _ysl;

        uint256 emission = getPrice(path[0], path[1], usersCompUSD, apeSwap);
        IsYSL(_ysl).mintFor(address(this), emission);

        // Add YSL-BUSD liquidity and send LP to the Adapter
        addLiquidity(path[0], path[1], usersCompUSD, emission, apeSwap, adapter);

        // Mint sYSL equivalent of the collected BUSD with optimisation (or amplification)
        mintBonus(usersCompUSD, _user, _isAmplified);
    }

    /**********
     * MIGRATION INTERFACE
     **********/

    function transferOut(address _user, uint256 _amount) public override onlyRole(STRAT_ROLE) returns (uint256) {
        revert("Transfer is disabled");

        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = IStrategySwap(stratSwap).YSL();
        userDeposited[_user] -= _amount;
        totalDeposited -= _amount;
        uint256 fee = _amount / 1000;
        _amount -= fee;
        uint256 amountUSDBefore = IERC20(BUSD).balanceOf(address(this));
        lpToken.approve(stratSwap, fee);
        IStrategySwap(stratSwap).swapLPToBusd(fee, apeSwap, path0, lpToken);
        uint256 amountUSDAfter = IERC20(BUSD).balanceOf(address(this));
        uint256 emission = getPrice(path[0], path[1], amountUSDAfter - amountUSDAfter, apeSwap);
        addLiquidity(path[0], path[1], amountUSDAfter - amountUSDBefore, emission, apeSwap, adapter);
        amountUSDBefore = IERC20(BUSD).balanceOf(address(this));
        lpToken.approve(stratSwap, _amount);
        IStrategySwap(stratSwap).swapLPToBusd(_amount, apeSwap, path0, lpToken);
        amountUSDAfter = IERC20(BUSD).balanceOf(address(this));
        IERC20(BUSD).safeTransfer(stratSwap, amountUSDAfter - amountUSDBefore);


        lastEarn[_user] = block.timestamp;

        return amountUSDAfter - amountUSDBefore;
    }

    function transferIn(address _user, uint256 _amount) public override onlyRole(STRAT_ROLE) returns (uint256) {
        revert("Transfer is disabled");
        IStrategySwap(stratSwap).migrate(_amount, address(this));
        IERC20(BUSD).safeTransferFrom(stratSwap, address(this), _amount);
        uint256 amountLPBefore = lpToken.balanceOf(address(this));
        IERC20(BUSD).approve(stratSwap, _amount);
        IStrategySwap(stratSwap).swapBusdToLP(_amount, apeSwap, path0);
        uint256 amountLPAfter = lpToken.balanceOf(address(this));
        userDeposited[_user] += amountLPAfter - amountLPBefore;
        totalDeposited += amountLPAfter - amountLPBefore;

        lastEarn[_user] = block.timestamp;

        return amountLPAfter - amountLPBefore;
    }

    /**********
     * INPUT/OUTPUT INTERFACE
     **********/
    function deposit(address _from, uint256 _amount) public virtual override onlyRole(STRAT_ROLE) {
        lastEarn[_from] = block.timestamp;

        userDeposited[_from] += _amount;
        totalDeposited += _amount;

        lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    function withdraw(uint256 _amount, address _user) external virtual override onlyRole(STRAT_ROLE) {
        lastEarn[_user] = block.timestamp;

        withdrawAcc(_amount);

        userDeposited[_user] -= _amount;
        totalDeposited -= _amount;

        lpToken.approve(_msgSender(), _amount);
    }

    function getUserDepositedUSD(address _user) public view override returns (uint256 amount) {
        if (userDeposited[_user] == 0) {
            return 0;
        }
        return IStrategySwap(stratSwap).getBusdAmount(userDeposited[_user], path0, apeSwap);
    }

    function getTotalDepositedUSD() public view returns (uint256 amount) {
        if (totalDeposited == 0) {
            return 0;
        }
        return IStrategySwap(stratSwap).getBusdAmount(totalDeposited, path0, apeSwap);
    }

    function mintBonus(
        uint256 usersCompUSD,
        address _user,
        bool _isAmplified
    ) internal {
        address _sysl = IStrategySwap(stratSwap).sYSL();
        uint256 syslemission = getPrice(BUSD, _sysl, usersCompUSD, apeSwap);

        bool hasRef = IReferral(referral).hasReferral(_user);
        uint256 koef = hasRef ? coef_opt_ref : coef_opt;
        koef = _isAmplified ? coef_ampl : koef;

        if (hasRef) {
            sendReferralBonus(syslemission, _user);
        }

        uint256 usersIncome = (syslemission * koef) / FEE_ACCURACY;
        IsYSL(_sysl).mint(usersIncome);

        // Send minted sYSL to the vesting contract
        IsYSL(_sysl).approve(lockContract, usersIncome);
        ILock(lockContract).lock(usersIncome, 90 days, _user);
    }

    function sendReferralBonus(uint256 syslemission, address _user) internal {
        address _sysl = IStrategySwap(stratSwap).sYSL();

        uint256 bonus = (syslemission * coef_ref) / FEE_ACCURACY;
        IsYSL(_sysl).mint(bonus);
        IsYSL(_sysl).approve(lockContract, bonus);
        // Send minted sYSL to the vesting contract
        address creator = IReferral(referral).referrals(_user);
        ILock(lockContract).lock(bonus, 90 days, creator);
    }

    function withdrawAcc(uint256 _amount) internal override {
        uint256 totalCompounds = IPancakeMaster(apeMaster).userInfo(id, address(this)).amount;
        if (totalCompounds > 0) {
            IPancakeMaster(apeMaster).leaveStaking(_amount);
        }
    }

    function restorePool() public onlyRole(STRAT_ROLE) {
        uint256 totalCompounds = IPancakeMaster(apeMaster).userInfo(id, address(this)).amount;
        IPancakeMaster(apeMaster).leaveStaking(totalCompounds);
    }

    function currentRewardUSD(address _user) public view returns (uint256) {
        if (totalDeposited == 0 || userDeposited[_user] == 0) return 0;

        // Get total compounds
        uint256 totalCompounds = IPancakeMaster(apeMaster).userInfo(id, address(this)).amount;
        totalCompounds += lpToken.balanceOf(address(this));

        // Get users share of compounds: rewards * user's share
        uint256 userCompounds = ((totalCompounds - totalDeposited) * userDeposited[_user]) / totalDeposited;

        if (maturityEarn > 0) {
            uint256 period = block.timestamp - lastEarn[_user];
            if (period < maturityEarn) {
                userCompounds = userCompounds * period / maturityEarn;
            }
        }
        if (userCompounds <= DUST) {
            return 0;
        }

        uint256 usersUSD = getPrice(address(want), BUSD, userCompounds, apeSwap);
        // Optimisation
        uint256 usersIncome = (usersUSD * coef_opt) / FEE_ACCURACY;

        return usersIncome;
    }

    function currentReward(address _user) public view override returns (uint256) {
        address _sysl = IStrategySwap(stratSwap).sYSL();
        uint256 rewardUSD = currentRewardUSD(_user);
        if (rewardUSD == 0) {
            return 0;
        }
        return getPrice(BUSD, _sysl, rewardUSD, apeSwap);
    }
}