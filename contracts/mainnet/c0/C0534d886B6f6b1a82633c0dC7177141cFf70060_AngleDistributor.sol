// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAccessControl.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
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
abstract contract AccessControlUpgradeable is Initializable, IAccessControl {
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

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
        _checkRole(role, msg.sender);
        _;
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
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) external override {
        require(account == msg.sender, "71");

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
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IAngleMiddlemanGauge {
    function notifyReward(address gauge, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IGaugeController {
    //solhint-disable-next-line
    function gauge_types(address addr) external view returns (int128);

    //solhint-disable-next-line
    function gauge_relative_weight_write(address addr, uint256 timestamp) external returns (uint256);

    //solhint-disable-next-line
    function gauge_relative_weight(address addr, uint256 timestamp) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface ILiquidityGauge {
    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IStakingRewardsFunctions
/// @author Angle Core Team
/// @notice Interface for the staking rewards contract that interact with the `RewardsDistributor` contract
interface IStakingRewardsFunctions {
    function notifyRewardAmount(uint256 reward) external;

    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external;

    function setNewRewardsDistribution(address newRewardsDistribution) external;
}

/// @title IStakingRewards
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IStakingRewards is IStakingRewardsFunctions {
    function rewardToken() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./AngleDistributorEvents.sol";

/// @title AngleDistributor
/// @author Forked from contracts developed by Curve and Frax and adapted by Angle Core Team
/// - ERC20CRV.vy (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/ERC20CRV.vy)
/// - FraxGaugeFXSRewardsDistributor.sol (https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Curve/FraxGaugeFXSRewardsDistributor.sol)
/// @notice All the events used in `AngleDistributor` contract
contract AngleDistributor is AngleDistributorEvents, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Role for governors only
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    /// @notice Role for the guardian
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Length of a week in seconds
    uint256 public constant WEEK = 3600 * 24 * 7;

    /// @notice Time at which the emission rate is updated
    uint256 public constant RATE_REDUCTION_TIME = WEEK;

    /// @notice Reduction of the emission rate
    uint256 public constant RATE_REDUCTION_COEFFICIENT = 1007827884862117171; // 1.5 ^ (1/52) * 10**18

    /// @notice Base used for computation
    uint256 public constant BASE = 10**18;

    /// @notice Maps the address of a gauge to the last time this gauge received rewards
    mapping(address => uint256) public lastTimeGaugePaid;

    /// @notice Maps the address of a gauge to whether it was killed or not
    /// A gauge killed in this contract cannot receive any rewards
    mapping(address => bool) public killedGauges;

    /// @notice Maps the address of a type >= 2 gauge to a delegate address responsible
    /// for giving rewards to the actual gauge
    mapping(address => address) public delegateGauges;

    /// @notice Maps the address of a gauge delegate to whether this delegate supports the `notifyReward` interface
    /// and is therefore built for automation
    mapping(address => bool) public isInterfaceKnown;

    /// @notice Address of the ANGLE token given as a reward
    IERC20 public rewardToken;

    /// @notice Address of the `GaugeController` contract
    IGaugeController public controller;

    /// @notice Address responsible for pulling rewards of type >= 2 gauges and distributing it to the
    /// associated contracts if there is not already an address delegated for this specific contract
    address public delegateGauge;

    /// @notice ANGLE current emission rate, it is first defined in the initializer and then updated every week
    uint256 public rate;

    /// @notice Timestamp at which the current emission epoch started
    uint256 public startEpochTime;

    /// @notice Amount of ANGLE tokens distributed through staking at the start of the epoch
    /// This is an informational variable used to track how much has been distributed through liquidity mining
    uint256 public startEpochSupply;

    /// @notice Index of the current emission epoch
    /// Here also, this variable is not useful per se inside the smart contracts of the protocol, it is
    /// just an informational variable
    uint256 public miningEpoch;

    /// @notice Whether ANGLE distribution through this contract is on or no
    bool public distributionsOn;

    /// @notice Constructor of the contract
    /// @param _rewardToken Address of the ANGLE token
    /// @param _controller Address of the GaugeController
    /// @param _initialRate Initial ANGLE emission rate
    /// @param _startEpochSupply Amount of ANGLE tokens already distributed via liquidity mining
    /// @param governor Governor address of the contract
    /// @param guardian Address of the guardian of this contract
    /// @param _delegateGauge Address that will be used to pull rewards for type 2 gauges
    /// @dev After this contract is created, the correct amount of ANGLE tokens should be transferred to the contract
    /// @dev The `_delegateGauge` can be the zero address
    function initialize(
        address _rewardToken,
        address _controller,
        uint256 _initialRate,
        uint256 _startEpochSupply,
        address governor,
        address guardian,
        address _delegateGauge
    ) external initializer {
        require(
            _controller != address(0) && _rewardToken != address(0) && guardian != address(0) && governor != address(0),
            "0"
        );
        rewardToken = IERC20(_rewardToken);
        controller = IGaugeController(_controller);
        startEpochSupply = _startEpochSupply;
        miningEpoch = 0;
        // Some ANGLE tokens should be sent to the contract directly after initialization
        rate = _initialRate;
        delegateGauge = _delegateGauge;
        distributionsOn = false;
        startEpochTime = block.timestamp;
        _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERNOR_ROLE);
        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(GOVERNOR_ROLE, governor);
        _setupRole(GUARDIAN_ROLE, governor);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ======================== Internal Functions =================================

    /// @notice Internal function to distribute rewards to a gauge
    /// @param gaugeAddr Address of the gauge to distribute rewards to
    /// @return weeksElapsed Weeks elapsed since the last call
    /// @return rewardTally Amount of rewards distributed to the gauge
    /// @dev The reason for having an internal function is that it's called by the `distributeReward` and the
    /// `distributeRewardToMultipleGauges`
    /// @dev Although they would need to be performed all the time this function is called, this function does not
    /// contain checks on whether distribution is on, and on whether rate should be reduced. These are done in each external
    /// function calling this function for gas efficiency
    function _distributeReward(address gaugeAddr) internal returns (uint256 weeksElapsed, uint256 rewardTally) {
        // Checking if the gauge has been added or if it still possible to distribute rewards to this gauge
        int128 gaugeType = IGaugeController(controller).gauge_types(gaugeAddr);
        require(gaugeType >= 0 && !killedGauges[gaugeAddr], "110");

        // Calculate the elapsed time in weeks.
        uint256 lastTimePaid = lastTimeGaugePaid[gaugeAddr];

        // Edge case for first reward for this gauge
        if (lastTimePaid == 0) {
            weeksElapsed = 1;
            if (gaugeType == 0) {
                // We give a full approval for the gauges with type zero which correspond to the staking
                // contracts of the protocol
                rewardToken.safeApprove(gaugeAddr, type(uint256).max);
            }
        } else {
            // Truncation desired
            weeksElapsed = (block.timestamp - lastTimePaid) / WEEK;
            // Return early here for 0 weeks instead of throwing, as it could have bad effects in other contracts
            if (weeksElapsed == 0) {
                return (0, 0);
            }
        }
        rewardTally = 0;
        // We use this variable to keep track of the emission rate across different weeks
        uint256 weeklyRate = rate;
        for (uint256 i = 0; i < weeksElapsed; i++) {
            uint256 relWeightAtWeek;
            if (i == 0) {
                // Mutative, for the current week: makes sure the weight is checkpointed. Also returns the weight.
                relWeightAtWeek = controller.gauge_relative_weight_write(gaugeAddr, block.timestamp);
            } else {
                // View
                relWeightAtWeek = controller.gauge_relative_weight(gaugeAddr, (block.timestamp - WEEK * i));
            }
            rewardTally += (weeklyRate * relWeightAtWeek * WEEK) / BASE;

            // To get the rate of the week prior from the current rate we just have to multiply by the weekly division
            // factor
            // There may be some precisions error: inferred previous values of the rate may be different to what we would
            // have had if the rate had been computed correctly in these weeks: we expect from empirical observations
            // this `weeklyRate` to be inferior to what the `rate` would have been
            weeklyRate = (weeklyRate * RATE_REDUCTION_COEFFICIENT) / BASE;
        }

        // Update the last time paid, rounded to the closest week
        // in order not to have an ever moving time on when to call this function
        lastTimeGaugePaid[gaugeAddr] = (block.timestamp / WEEK) * WEEK;

        // If the `gaugeType >= 2`, this means that the gauge is a gauge on another chain (and corresponds to tokens
        // that need to be bridged) or is associated to an external contract of the Angle Protocol
        if (gaugeType >= 2) {
            // If it is defined, we use the specific delegate attached to the gauge
            address delegate = delegateGauges[gaugeAddr];
            if (delegate == address(0)) {
                // If not, we check if a delegate common to all gauges with type >= 2 can be used
                delegate = delegateGauge;
            }
            if (delegate != address(0)) {
                // In the case where the gauge has a delegate (specific or not), then rewards are transferred to this gauge
                rewardToken.safeTransfer(delegate, rewardTally);
                // If this delegate supports a specific interface, then rewards sent are notified through this
                // interface
                if (isInterfaceKnown[delegate]) {
                    IAngleMiddlemanGauge(delegate).notifyReward(gaugeAddr, rewardTally);
                }
            } else {
                rewardToken.safeTransfer(gaugeAddr, rewardTally);
            }
        } else if (gaugeType == 1) {
            // This is for the case of Perpetual contracts which need to be able to receive their reward tokens
            rewardToken.safeTransfer(gaugeAddr, rewardTally);
            IStakingRewards(gaugeAddr).notifyRewardAmount(rewardTally);
        } else {
            // Mainnet: Pay out the rewards directly to the gauge
            ILiquidityGauge(gaugeAddr).deposit_reward_token(address(rewardToken), rewardTally);
        }
        emit RewardDistributed(gaugeAddr, rewardTally);
    }

    /// @notice Updates mining rate and supply at the start of the epoch
    /// @dev Any modifying mining call must also call this
    /// @dev It is possible that more than one week past between two calls of this function, and for this reason
    /// this function has been slightly modified from Curve implementation by Angle Team
    function _updateMiningParameters() internal {
        // When entering this function, we always have: `(block.timestamp - startEpochTime) / RATE_REDUCTION_TIME >= 1`
        uint256 epochDelta = (block.timestamp - startEpochTime) / RATE_REDUCTION_TIME;

        // Storing intermediate values for the rate and for the `startEpochSupply`
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += RATE_REDUCTION_TIME * epochDelta;
        miningEpoch += epochDelta;

        for (uint256 i = 0; i < epochDelta; i++) {
            // Updating the intermediate values of the `startEpochSupply`
            _startEpochSupply += _rate * RATE_REDUCTION_TIME;
            _rate = (_rate * BASE) / RATE_REDUCTION_COEFFICIENT;
        }
        rate = _rate;
        startEpochSupply = _startEpochSupply;
        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }

    /// @notice Toggles the fact that a gauge delegate can be used for automation or not and therefore supports
    /// the `notifyReward` interface
    /// @param _delegateGauge Address of the gauge to change
    function _toggleInterfaceKnown(address _delegateGauge) internal {
        bool isInterfaceKnownMem = isInterfaceKnown[_delegateGauge];
        isInterfaceKnown[_delegateGauge] = !isInterfaceKnownMem;
        emit InterfaceKnownToggled(_delegateGauge, !isInterfaceKnownMem);
    }

    // ================= Permissionless External Functions =========================

    /// @notice Distributes rewards to a staking contract (also called gauge)
    /// @param gaugeAddr Address of the gauge to send tokens too
    /// @return weeksElapsed Number of weeks elapsed since the last time rewards were distributed
    /// @return rewardTally Amount of tokens sent to the gauge
    /// @dev Anyone can call this function to distribute rewards to the different staking contracts
    function distributeReward(address gaugeAddr) external nonReentrant returns (uint256, uint256) {
        // Checking if distribution is on
        require(distributionsOn == true, "109");
        // Updating rate distribution parameters if need be
        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();
        }
        return _distributeReward(gaugeAddr);
    }

    /// @notice Distributes rewards to multiple staking contracts
    /// @param gauges Addresses of the gauge to send tokens too
    /// @dev Anyone can call this function to distribute rewards to the different staking contracts
    /// @dev Compared with the `distributeReward` function, this function sends rewards to multiple
    /// contracts at the same time
    function distributeRewardToMultipleGauges(address[] memory gauges) external nonReentrant {
        // Checking if distribution is on
        require(distributionsOn == true, "109");
        // Updating rate distribution parameters if need be
        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();
        }
        for (uint256 i = 0; i < gauges.length; i++) {
            _distributeReward(gauges[i]);
        }
    }

    /// @notice Updates mining rate and supply at the start of the epoch
    /// @dev Callable by any address, but only once per epoch
    function updateMiningParameters() external {
        require(block.timestamp >= startEpochTime + RATE_REDUCTION_TIME, "108");
        _updateMiningParameters();
    }

    // ========================= Governor Functions ================================

    /// @notice Withdraws ERC20 tokens that could accrue on this contract
    /// @param tokenAddress Address of the ERC20 token to withdraw
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @dev Added to support recovering LP Rewards and other mistaken tokens
    /// from other systems to be distributed to holders
    /// @dev This function could also be used to recover ANGLE tokens in case the rate got smaller
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) {
        // If the token is the ANGLE token, we need to make sure that governance is not going to withdraw
        // too many tokens and that it'll be able to sustain the weekly distribution forever
        // This check assumes that `distributeReward` has been called for gauges and that there are no gauges
        // which have not received their past week's rewards
        if (tokenAddress == address(rewardToken)) {
            uint256 currentBalance = rewardToken.balanceOf(address(this));
            // The amount distributed till the end is `rate * WEEK / (1 - RATE_REDUCTION_FACTOR)` where
            // `RATE_REDUCTION_FACTOR = BASE / RATE_REDUCTION_COEFFICIENT` which translates to:
            require(
                currentBalance >=
                    ((rate * RATE_REDUCTION_COEFFICIENT) * WEEK) / (RATE_REDUCTION_COEFFICIENT - BASE) + amount,
                "4"
            );
        }
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit Recovered(tokenAddress, to, amount);
    }

    /// @notice Sets a new gauge controller
    /// @param _controller Address of the new gauge controller
    function setGaugeController(address _controller) external onlyRole(GOVERNOR_ROLE) {
        require(_controller != address(0), "0");
        controller = IGaugeController(_controller);
        emit GaugeControllerUpdated(_controller);
    }

    /// @notice Sets a new delegate gauge for pulling rewards of a type >= 2 gauges or of all type >= 2 gauges
    /// @param gaugeAddr Gauge to change the delegate of
    /// @param _delegateGauge Address of the new gauge delegate related to `gaugeAddr`
    /// @param toggleInterface Whether we should toggle the fact that the `_delegateGauge` is built for automation or not
    /// @dev This function can be used to remove delegating or introduce the pulling of rewards to a given address
    /// @dev If `gaugeAddr` is the zero address, this function updates the delegate gauge common to all gauges with type >= 2
    /// @dev The `toggleInterface` parameter has been added for convenience to save one transaction when adding a gauge delegate
    /// which supports the `notifyReward` interface
    function setDelegateGauge(
        address gaugeAddr,
        address _delegateGauge,
        bool toggleInterface
    ) external onlyRole(GOVERNOR_ROLE) {
        if (gaugeAddr != address(0)) {
            delegateGauges[gaugeAddr] = _delegateGauge;
        } else {
            delegateGauge = _delegateGauge;
        }
        emit DelegateGaugeUpdated(gaugeAddr, _delegateGauge);

        if (toggleInterface) {
            _toggleInterfaceKnown(_delegateGauge);
        }
    }

    /// @notice Changes the ANGLE emission rate
    /// @param _newRate New ANGLE emission rate
    /// @dev It is important to be super wary when calling this function and to make sure that `distributeReward`
    /// has been called for all gauges in the past weeks. If not, gauges may get an incorrect distribution of ANGLE rewards
    /// for these past weeks based on the new rate and not on the old rate
    /// @dev Governance should thus make sure to call this function rarely and when it does to do it after the weekly `distributeReward`
    /// calls for all existing gauges
    /// @dev As this function assumes that `distributeReward` has been called during the week, it also assumes that the `startEpochSupply`
    /// parameter has been put up to date
    function setRate(uint256 _newRate) external onlyRole(GOVERNOR_ROLE) {
        // Checking if the new rate is compatible with the amount of ANGLE tokens this contract has in balance
        // This check assumes, like this function, that `distributeReward` has correctly been called before
        require(
            rewardToken.balanceOf(address(this)) >=
                ((_newRate * RATE_REDUCTION_COEFFICIENT) * WEEK) / (RATE_REDUCTION_COEFFICIENT - BASE),
            "4"
        );
        rate = _newRate;
        emit RateUpdated(_newRate);
    }

    /// @notice Toggles the status of a gauge to either killed or unkilled
    /// @param gaugeAddr Gauge to toggle the status of
    /// @dev It is impossible to kill a gauge in the `GaugeController` contract, for this reason killing of gauges
    /// takes place in the `AngleDistributor` contract
    /// @dev This means that people could vote for a gauge in the gauge controller contract but that rewards are not going
    /// to be distributed to it in the end: people would need to remove their weights on the gauge killed to end the diminution
    /// in rewards
    /// @dev In the case of a gauge being killed, this function resets the timestamps at which this gauge has been approved and
    /// disapproves the gauge to spend the token
    /// @dev It should be cautiously called by governance as it could result in less ANGLE overall rewards than initially planned
    /// if people do not remove their voting weights to the killed gauge
    function toggleGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
        bool gaugeKilledMem = killedGauges[gaugeAddr];
        if (!gaugeKilledMem) {
            delete lastTimeGaugePaid[gaugeAddr];
            rewardToken.safeApprove(gaugeAddr, 0);
        }
        killedGauges[gaugeAddr] = !gaugeKilledMem;
        emit GaugeToggled(gaugeAddr, !gaugeKilledMem);
    }

    // ========================= Guardian Function =================================

    /// @notice Halts or activates distribution of rewards
    function toggleDistributions() external onlyRole(GUARDIAN_ROLE) {
        bool distributionsOnMem = distributionsOn;
        distributionsOn = !distributionsOnMem;
        emit DistributionsToggled(!distributionsOnMem);
    }

    /// @notice Notifies that the interface of a gauge delegate is known or has changed
    /// @param _delegateGauge Address of the gauge to change
    /// @dev Gauge delegates that are built for automation should be toggled
    function toggleInterfaceKnown(address _delegateGauge) external onlyRole(GUARDIAN_ROLE) {
        _toggleInterfaceKnown(_delegateGauge);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IGaugeController.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IAngleMiddlemanGauge.sol";
import "../interfaces/IStakingRewards.sol";

import "../external/AccessControlUpgradeable.sol";

/// @title AngleDistributorEvents
/// @author Angle Core Team
/// @notice All the events used in `AngleDistributor` contract
contract AngleDistributorEvents {
    event DelegateGaugeUpdated(address indexed _gaugeAddr, address indexed _delegateGauge);
    event DistributionsToggled(bool _distributionsOn);
    event GaugeControllerUpdated(address indexed _controller);
    event GaugeToggled(address indexed gaugeAddr, bool newStatus);
    event InterfaceKnownToggled(address indexed _delegateGauge, bool _isInterfaceKnown);
    event RateUpdated(uint256 _newRate);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);
    event RewardDistributed(address indexed gaugeAddr, uint256 rewardTally);
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
}