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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IAccessControl.sol";

/// @title IFeeManagerFunctions
/// @author Angle Core Team
/// @dev Interface for the `FeeManager` contract
interface IFeeManagerFunctions is IAccessControl {
    // ================================= Keepers ===================================

    function updateUsersSLP() external;

    function updateHA() external;

    // ================================= Governance ================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        address _perpetualManager
    ) external;

    function setFees(
        uint256[] memory xArray,
        uint64[] memory yArray,
        uint8 typeChange
    ) external;

    function setHAFees(uint64 _haFeeDeposit, uint64 _haFeeWithdraw) external;
}

/// @title IFeeManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev We need these getters as they are used in other contracts of the protocol
interface IFeeManager is IFeeManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IOracle
/// @author Angle Core Team
/// @notice Interface for Angle's oracle contracts reading oracle rates from both UniswapV3 and Chainlink
/// from just UniswapV3 or from just Chainlink
interface IOracle {
    function read() external view returns (uint256);

    function readAll() external view returns (uint256 lowerRate, uint256 upperRate);

    function readLower() external view returns (uint256);

    function readUpper() external view returns (uint256);

    function readQuote(uint256 baseAmount) external view returns (uint256);

    function readQuoteLower(uint256 baseAmount) external view returns (uint256);

    function inBase() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IFeeManager.sol";
import "./IOracle.sol";
import "./IAccessControl.sol";

/// @title Interface of the contract managing perpetuals
/// @author Angle Core Team
/// @dev Front interface, meaning only user-facing functions
interface IPerpetualManagerFront is IERC721Metadata {
    function openPerpetual(
        address owner,
        uint256 amountBrought,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin
    ) external returns (uint256 perpetualID);

    function closePerpetual(
        uint256 perpetualID,
        address to,
        uint256 minCashOutAmount
    ) external;

    function addToPerpetual(uint256 perpetualID, uint256 amount) external;

    function removeFromPerpetual(
        uint256 perpetualID,
        uint256 amount,
        address to
    ) external;

    function liquidatePerpetuals(uint256[] memory perpetualIDs) external;

    function forceClosePerpetuals(uint256[] memory perpetualIDs) external;

    // ========================= External View Functions =============================

    function getCashOutAmount(uint256 perpetualID, uint256 rate) external view returns (uint256, uint256);

    function isApprovedOrOwner(address spender, uint256 perpetualID) external view returns (bool);
}

/// @title Interface of the contract managing perpetuals
/// @author Angle Core Team
/// @dev This interface does not contain user facing functions, it just has functions that are
/// interacted with in other parts of the protocol
interface IPerpetualManagerFunctions is IAccessControl {
    // ================================= Governance ================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IFeeManager feeManager,
        IOracle oracle_
    ) external;

    function setFeeManager(IFeeManager feeManager_) external;

    function setHAFees(
        uint64[] memory _xHAFees,
        uint64[] memory _yHAFees,
        uint8 deposit
    ) external;

    function setTargetAndLimitHAHedge(uint64 _targetHAHedge, uint64 _limitHAHedge) external;

    function setKeeperFeesLiquidationRatio(uint64 _keeperFeesLiquidationRatio) external;

    function setKeeperFeesCap(uint256 _keeperFeesLiquidationCap, uint256 _keeperFeesClosingCap) external;

    function setKeeperFeesClosing(uint64[] memory _xKeeperFeesClosing, uint64[] memory _yKeeperFeesClosing) external;

    function setLockTime(uint64 _lockTime) external;

    function setBoundsPerpetual(uint64 _maxLeverage, uint64 _maintenanceMargin) external;

    function pause() external;

    function unpause() external;

    // ==================================== Keepers ================================

    function setFeeKeeper(uint64 feeDeposit, uint64 feesWithdraw) external;

    // =============================== StableMaster ================================

    function setOracle(IOracle _oracle) external;
}

/// @title IPerpetualManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IPerpetualManager is IPerpetualManagerFunctions {
    function poolManager() external view returns (address);

    function oracle() external view returns (address);

    function targetHAHedge() external view returns (uint64);

    function totalHedgeAmount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IFeeManager.sol";
import "./IPerpetualManager.sol";
import "./IOracle.sol";

// Struct for the parameters associated to a strategy interacting with a collateral `PoolManager`
// contract
struct StrategyParams {
    // Timestamp of last report made by this strategy
    // It is also used to check if a strategy has been initialized
    uint256 lastReport;
    // Total amount the strategy is expected to have
    uint256 totalStrategyDebt;
    // The share of the total assets in the `PoolManager` contract that the `strategy` can access to.
    uint256 debtRatio;
}

/// @title IPoolManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the collateral poolManager contracts handling each one type of collateral for
/// a given stablecoin
/// @dev Only the functions used in other contracts of the protocol are left here
interface IPoolManagerFunctions {
    // ============================ Constructor ====================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IPerpetualManager _perpetualManager,
        IFeeManager feeManager,
        IOracle oracle
    ) external;

    // ============================ Yield Farming ==================================

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;

    // ============================ Governance =====================================

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address _guardian, address guardian) external;

    function revokeGuardian(address guardian) external;

    function setFeeManager(IFeeManager _feeManager) external;

    // ============================= Getters =======================================

    function getBalance() external view returns (uint256);

    function getTotalAsset() external view returns (uint256);
}

/// @title IPoolManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev Used in other contracts of the protocol
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);

    function token() external view returns (address);

    function feeManager() external view returns (address);

    function totalDebt() external view returns (uint256);

    function strategies(address _strategy) external view returns (StrategyParams memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title ISanToken
/// @author Angle Core Team
/// @notice Interface for Angle's `SanToken` contract that handles sanTokens, tokens that are given to SLPs
/// contributing to a collateral for a given stablecoin
interface ISanToken is IERC20Upgradeable {
    // ================================== StableMaster =============================

    function mint(address account, uint256 amount) external;

    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    function burnSelf(uint256 amount, address burner) external;

    function stableMaster() external view returns (address);

    function poolManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Normally just importing `IPoolManager` should be sufficient, but for clarity here
// we prefer to import all concerned interfaces
import "./IPoolManager.sol";
import "./IOracle.sol";
import "./IPerpetualManager.sol";
import "./ISanToken.sol";

// Struct to handle all the parameters to manage the fees
// related to a given collateral pool (associated to the stablecoin)
struct MintBurnData {
    // Values of the thresholds to compute the minting fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeMint;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeMint;
    // Values of the thresholds to compute the burning fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeBurn;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeBurn;
    // Max proportion of collateral from users that can be covered by HAs
    // It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
    // the other changes accordingly
    uint64 targetHAHedge;
    // Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusMint;
    // Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusBurn;
    // Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
    uint256 capOnStableMinted;
}

// Struct to handle all the variables and parameters to handle SLPs in the protocol
// including the fraction of interests they receive or the fees to be distributed to
// them
struct SLPData {
    // Last timestamp at which the `sanRate` has been updated for SLPs
    uint256 lastBlockUpdated;
    // Fees accumulated from previous blocks and to be distributed to SLPs
    uint256 lockedInterests;
    // Max interests used to update the `sanRate` in a single block
    // Should be in collateral token base
    uint256 maxInterestsDistributed;
    // Amount of fees left aside for SLPs and that will be distributed
    // when the protocol is collateralized back again
    uint256 feesAside;
    // Part of the fees normally going to SLPs that is left aside
    // before the protocol is collateralized back again (depends on collateral ratio)
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippageFee;
    // Portion of the fees from users minting and burning
    // that goes to SLPs (the rest goes to surplus)
    uint64 feesForSLPs;
    // Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
    // If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippage;
    // Portion of the interests from lending
    // that goes to SLPs (the rest goes to surplus)
    uint64 interestsForSLPs;
}

/// @title IStableMasterFunctions
/// @author Angle Core Team
/// @notice Interface for the `StableMaster` contract
interface IStableMasterFunctions {
    function deploy(
        address[] memory _governorList,
        address _guardian,
        address _agToken
    ) external;

    // ============================== Lending ======================================

    function accumulateInterest(uint256 gain) external;

    function signalLoss(uint256 loss) external;

    // ============================== HAs ==========================================

    function getStocksUsers() external view returns (uint256 maxCAmountInStable);

    function convertToSLP(uint256 amount, address user) external;

    // ============================== Keepers ======================================

    function getCollateralRatio() external returns (uint256);

    function setFeeKeeper(
        uint64 feeMint,
        uint64 feeBurn,
        uint64 _slippage,
        uint64 _slippageFee
    ) external;

    // ============================== AgToken ======================================

    function updateStocksUsers(uint256 amount, address poolManager) external;

    // ============================= Governance ====================================

    function setCore(address newCore) external;

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address newGuardian, address oldGuardian) external;

    function revokeGuardian(address oldGuardian) external;

    function setCapOnStableAndMaxInterests(
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed,
        IPoolManager poolManager
    ) external;

    function setIncentivesForSLPs(
        uint64 _feesForSLPs,
        uint64 _interestsForSLPs,
        IPoolManager poolManager
    ) external;

    function setUserFees(
        IPoolManager poolManager,
        uint64[] memory _xFee,
        uint64[] memory _yFee,
        uint8 _mint
    ) external;

    function setTargetHAHedge(uint64 _targetHAHedge) external;

    function pause(bytes32 agent, IPoolManager poolManager) external;

    function unpause(bytes32 agent, IPoolManager poolManager) external;
}

/// @title IStableMaster
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
interface IStableMaster is IStableMasterFunctions {
    function agToken() external view returns (address);

    function collateralMap(IPoolManager poolManager)
        external
        view
        returns (
            IERC20 token,
            ISanToken sanToken,
            IPerpetualManager perpetualManager,
            IOracle oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IAccessControl.sol";

/// @title IStrategy
/// @author Inspired by Yearn with slight changes from Angle Core Team
/// @notice Interface for yield farming strategies
interface IStrategy is IAccessControl {
    function estimatedAPR() external view returns (uint256);

    function poolManager() external view returns (address);

    function want() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amountNeeded) external returns (uint256 amountFreed, uint256 _loss);

    function setEmergencyExit() external;

    function addGuardian(address _guardian) external;

    function revokeGuardian(address _guardian) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./PoolManagerInternal.sol";

/// @title PoolManager
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This file contains the functions that are callable by governance or by other contracts of the protocol
/// @dev References to this contract are called `PoolManager`
contract PoolManager is PoolManagerInternal, IPoolManagerFunctions {
    using SafeERC20 for IERC20;

    // ============================ Constructor ====================================

    /// @notice Constructor of the `PoolManager` contract
    /// @param _token Address of the collateral
    /// @param _stableMaster Reference to the master stablecoin (`StableMaster`) interface
    function initialize(address _token, IStableMaster _stableMaster)
        external
        initializer
        zeroCheck(_token)
        zeroCheck(address(_stableMaster))
    {
        __AccessControl_init();

        // Creating the correct references
        stableMaster = _stableMaster;
        token = IERC20(_token);

        // Access Control
        // The roles in this contract can only be modified from the `StableMaster`
        // For the moment `StableMaster` never uses the `GOVERNOR_ROLE`
        _setupRole(STABLEMASTER_ROLE, address(stableMaster));
        _setRoleAdmin(STABLEMASTER_ROLE, STABLEMASTER_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, STABLEMASTER_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, STABLEMASTER_ROLE);
        // No admin is set for `STRATEGY_ROLE`, checks are made in the appropriate functions
        // `addStrategy` and `revokeStrategy`
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ========================= `StableMaster` Functions ==========================

    /// @notice Changes the references to contracts from this protocol with which this collateral `PoolManager` interacts
    /// and propagates some references to the `perpetualManager` and `feeManager` contracts
    /// @param governorList List of the governor addresses of protocol
    /// @param guardian Address of the guardian of the protocol (it can be revoked)
    /// @param _perpetualManager New reference to the `PerpetualManager` contract containing all the logic for HAs
    /// @param _feeManager Reference to the `FeeManager` contract that will serve for the `PerpetualManager` contract
    /// @param _oracle Reference to the `Oracle` contract that will serve for the `PerpetualManager` contract
    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IPerpetualManager _perpetualManager,
        IFeeManager _feeManager,
        IOracle _oracle
    ) external override onlyRole(STABLEMASTER_ROLE) {
        // These references need to be stored to be able to propagate changes and maintain
        // the protocol's integrity when changes are posted from the `StableMaster`
        perpetualManager = _perpetualManager;
        feeManager = _feeManager;

        // Access control
        for (uint256 i = 0; i < governorList.length; i++) {
            _grantRole(GOVERNOR_ROLE, governorList[i]);
            _grantRole(GUARDIAN_ROLE, governorList[i]);
        }
        _grantRole(GUARDIAN_ROLE, guardian);

        // Propagates the changes to the other involved contracts
        perpetualManager.deployCollateral(governorList, guardian, _feeManager, _oracle);
        _feeManager.deployCollateral(governorList, guardian, address(_perpetualManager));

        // `StableMaster` and `PerpetualManager` need to have approval to directly transfer some of
        // this contract's tokens
        token.safeIncreaseAllowance(address(stableMaster), type(uint256).max);
        token.safeIncreaseAllowance(address(_perpetualManager), type(uint256).max);
    }

    /// @notice Adds a new governor address and echoes it to other contracts
    /// @param _governor New governor address
    function addGovernor(address _governor) external override onlyRole(STABLEMASTER_ROLE) {
        // Access control for this contract
        _grantRole(GOVERNOR_ROLE, _governor);
        // Echoes the change to other contracts interacting with this collateral `PoolManager`
        // Since the other contracts interacting with this `PoolManager` do not have governor roles,
        // we just need it to set the new governor as guardian in these contracts
        _addGuardian(_governor);
    }

    /// @notice Removes a governor address and echoes it to other contracts
    /// @param _governor Governor address to remove
    function removeGovernor(address _governor) external override onlyRole(STABLEMASTER_ROLE) {
        // Access control for this contract
        _revokeRole(GOVERNOR_ROLE, _governor);
        _revokeGuardian(_governor);
    }

    /// @notice Changes the guardian address and echoes it to other contracts that interact with this `PoolManager`
    /// @param _guardian New guardian address
    /// @param guardian Old guardian address to revoke
    function setGuardian(address _guardian, address guardian) external override onlyRole(STABLEMASTER_ROLE) {
        _revokeGuardian(guardian);
        _addGuardian(_guardian);
    }

    /// @notice Revokes the guardian address and echoes the change to other contracts that interact with this `PoolManager`
    /// @param guardian Address of the guardian to revoke
    function revokeGuardian(address guardian) external override onlyRole(STABLEMASTER_ROLE) {
        _revokeGuardian(guardian);
    }

    /// @notice Allows to propagate the change of keeper for the collateral/stablecoin pair
    /// @param _feeManager New `FeeManager` contract
    function setFeeManager(IFeeManager _feeManager) external override onlyRole(STABLEMASTER_ROLE) {
        // Changing the reference in the `PerpetualManager` contract where keepers are involved
        feeManager = _feeManager;
        perpetualManager.setFeeManager(_feeManager);
    }

    // ============================= Yield Farming =================================

    /// @notice Provides an estimated Annual Percentage Rate for SLPs based on lending to other protocols
    /// @dev This function is an estimation and is made for external use only
    /// @dev This does not take into account transaction fees which accrue to SLPs too
    /// @dev This can be manipulated by a flash loan attack (SLP deposit/ withdraw) via `_getTotalAsset`
    /// when entering you should make sure this hasn't be called by a flash loan and look
    /// at a mean of past APR.
    function estimatedAPR() external view returns (uint256 apr) {
        apr = 0;
        (, ISanToken sanTokenForAPR, , , , uint256 sanRate, , SLPData memory slpData, ) = stableMaster.collateralMap(
            IPoolManager(address(this))
        );
        uint256 supply = sanTokenForAPR.totalSupply();

        // `sanRate` should never be equal to 0
        if (supply == 0) return type(uint256).max;

        for (uint256 i = 0; i < strategyList.length; i++) {
            apr =
                apr +
                (strategies[strategyList[i]].debtRatio * IStrategy(strategyList[i]).estimatedAPR()) /
                BASE_PARAMS;
        }
        apr = (apr * slpData.interestsForSLPs * _getTotalAsset()) / sanRate / supply;
    }

    /// @notice Tells a strategy how much it can borrow from this `PoolManager`
    /// @return Amount of token a strategy has access to as a credit line
    /// @dev Since this function is a view function, there is no need to have an access control logic
    /// even though it will just be relevant for a strategy
    /// @dev Manipulating `_getTotalAsset` with a flashloan will only
    /// result in tokens being transferred at the cost of the caller
    function creditAvailable() external view override returns (uint256) {
        StrategyParams storage params = strategies[msg.sender];

        uint256 target = (_getTotalAsset() * params.debtRatio) / BASE_PARAMS;

        if (target < params.totalStrategyDebt) return 0;

        return Math.min(target - params.totalStrategyDebt, _getBalance());
    }

    /// @notice Tells a strategy how much it owes to this `PoolManager`
    /// @return Amount of token a strategy has to reimburse
    /// @dev Manipulating `_getTotalAsset` with a flashloan will only
    /// result in tokens being transferred at the cost of the caller
    function debtOutstanding() external view override returns (uint256) {
        StrategyParams storage params = strategies[msg.sender];

        uint256 target = (_getTotalAsset() * params.debtRatio) / BASE_PARAMS;

        if (target > params.totalStrategyDebt) return 0;

        return (params.totalStrategyDebt - target);
    }

    /// @notice Reports the gains or loss made by a strategy
    /// @param gain Amount strategy has realized as a gain on its investment since its
    /// last report, and is free to be given back to `PoolManager` as earnings
    /// @param loss Amount strategy has realized as a loss on its investment since its
    /// last report, and should be accounted for on the `PoolManager`'s balance sheet.
    /// The loss will reduce the `debtRatio`. The next time the strategy will harvest,
    /// it will pay back the debt in an attempt to adjust to the new debt limit.
    /// @param debtPayment Amount strategy has made available to cover outstanding debt
    /// @dev This is the main contact point where the strategy interacts with the `PoolManager`
    /// @dev The strategy reports back what it has free, then the `PoolManager` contract "decides"
    /// whether to take some back or give it more. Note that the most it can
    /// take is `gain + _debtPayment`, and the most it can give is all of the
    /// remaining reserves. Anything outside of those bounds is abnormal behavior.
    function report(
        uint256 gain,
        uint256 loss,
        uint256 debtPayment
    ) external override onlyRole(STRATEGY_ROLE) {
        require(token.balanceOf(msg.sender) >= gain + debtPayment, "72");

        StrategyParams storage params = strategies[msg.sender];
        // Updating parameters in the `perpetualManager`
        // This needs to be done now because it has implications in `_getTotalAsset()`
        params.totalStrategyDebt = params.totalStrategyDebt + gain - loss;
        totalDebt = totalDebt + gain - loss;
        params.lastReport = block.timestamp;

        // Warning: `_getTotalAsset` could be manipulated by flashloan attacks.
        // It may allow external users to transfer funds into strategy or remove funds
        // from the strategy. Yet, as it does not impact the profit or loss and as attackers
        // have no interest in making such txs to have a direct profit, we let it as is.
        // The only issue is if the strategy is compromised; in this case governance
        // should revoke the strategy
        uint256 target = ((_getTotalAsset()) * params.debtRatio) / BASE_PARAMS;
        if (target > params.totalStrategyDebt) {
            // If the strategy has some credit left, tokens can be transferred to this strategy
            uint256 available = Math.min(target - params.totalStrategyDebt, _getBalance());
            params.totalStrategyDebt = params.totalStrategyDebt + available;
            totalDebt = totalDebt + available;
            if (available > 0) {
                token.safeTransfer(msg.sender, available);
            }
        } else {
            uint256 available = Math.min(params.totalStrategyDebt - target, debtPayment + gain);
            params.totalStrategyDebt = params.totalStrategyDebt - available;
            totalDebt = totalDebt - available;
            if (available > 0) {
                token.safeTransferFrom(msg.sender, address(this), available);
            }
        }
        emit StrategyReported(msg.sender, gain, loss, debtPayment, params.totalStrategyDebt);

        // Handle gains before losses
        if (gain > 0) {
            uint256 gainForSurplus = (gain * interestsForSurplus) / BASE_PARAMS;
            uint256 adminDebtPre = adminDebt;
            // Depending on the current admin debt distribute the necessary gain from the strategies
            if (adminDebtPre == 0) interestsAccumulated += gainForSurplus;
            else if (adminDebtPre <= gainForSurplus) {
                interestsAccumulated += gainForSurplus - adminDebtPre;
                adminDebt = 0;
            } else adminDebt -= gainForSurplus;
            stableMaster.accumulateInterest(gain - gainForSurplus);
            emit FeesDistributed(gain);
        }

        // Handle eventual losses
        if (loss > 0) {
            uint256 lossForSurplus = (loss * interestsForSurplus) / BASE_PARAMS;
            uint256 interestsAccumulatedPreLoss = interestsAccumulated;
            // If the loss can not be entirely soaked by the interests to be distributed then
            // the protocol keeps track of the debt
            if (lossForSurplus > interestsAccumulatedPreLoss) {
                interestsAccumulated = 0;
                adminDebt += lossForSurplus - interestsAccumulatedPreLoss;
            } else interestsAccumulated -= lossForSurplus;
            // The rest is incurred to SLPs
            stableMaster.signalLoss(loss - lossForSurplus);
        }
    }

    // =========================== Governor Functions ==============================

    /// @notice Allows to recover any ERC20 token, including the token handled by this contract, and to send it
    /// to a contract
    /// @param tokenAddress Address of the token to recover
    /// @param to Address of the contract to send collateral to
    /// @param amountToRecover Amount of collateral to transfer
    /// @dev As this function can be used to transfer funds to another contract, it has to be a `GOVERNOR` function
    /// @dev In case the concerned token is the specific token handled by this contract, this function checks that the
    /// amount entered is not too big and approximates the surplus of the protocol
    /// @dev To esimate the amount of user claims on the concerned collateral, this function uses the `stocksUsers` for
    /// this collateral, but this is just an approximation as users can claim the collateral of their choice provided
    /// that they own a stablecoin
    /// @dev The sanity check excludes the HA claims: to get a sense of it, this function would need to compute the cash out
    /// amount of all the perpetuals, and this cannot be done on-chain in a cheap manner
    /// @dev Overall, even though there is a sanity check, this function relies on the fact that governance is not corrupted
    /// in this protocol and will not try to withdraw too much funds
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyRole(GOVERNOR_ROLE) {
        if (tokenAddress == address(token)) {
            // Fetching info from the `StableMaster`
            (
                ,
                ISanToken sanToken,
                ,
                IOracle oracle,
                uint256 stocksUsers,
                uint256 sanRate,
                uint256 collatBase,
                ,

            ) = IStableMaster(stableMaster).collateralMap(IPoolManager(address(this)));

            // Checking if there are enough reserves for the amount to withdraw
            require(
                _getTotalAsset() >=
                    amountToRecover +
                        (sanToken.totalSupply() * sanRate) /
                        BASE_TOKENS +
                        (stocksUsers * collatBase) /
                        oracle.readUpper() +
                        interestsAccumulated,
                "66"
            );

            token.safeTransfer(to, amountToRecover);
        } else {
            IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        }
        emit Recovered(tokenAddress, to, amountToRecover);
    }

    /// @notice Adds a strategy to the `PoolManager`
    /// @param strategy The address of the strategy to add
    /// @param _debtRatio The share of the total assets that the strategy has access to
    /// @dev Multiple checks are made. For instance, the contract must not already belong to the `PoolManager`
    /// and the underlying token of the strategy has to be consistent with the `PoolManager` contracts
    /// @dev This function is a `governor` function and not a `guardian` one because a `guardian` could add a strategy
    /// enabling the withdraw of the funds of the protocol
    /// @dev The `_debtRatio` should be expressed in `BASE_PARAMS`
    function addStrategy(address strategy, uint256 _debtRatio) external onlyRole(GOVERNOR_ROLE) zeroCheck(strategy) {
        StrategyParams storage params = strategies[strategy];

        require(params.lastReport == 0, "73");
        require(address(this) == IStrategy(strategy).poolManager(), "74");
        // Using current code, this condition should always be verified as in the constructor
        // of the strategy the `want()` is set to the token of this `PoolManager`
        require(address(token) == IStrategy(strategy).want(), "75");
        require(debtRatio + _debtRatio <= BASE_PARAMS, "76");

        // Add strategy to approved strategies
        params.lastReport = 1;
        params.totalStrategyDebt = 0;
        params.debtRatio = _debtRatio;

        _grantRole(STRATEGY_ROLE, strategy);

        // Update global parameters
        debtRatio += _debtRatio;
        emit StrategyAdded(strategy, debtRatio);

        strategyList.push(strategy);
    }

    // =========================== Guardian Functions ==============================

    /// @notice Sets a new surplus distributor to which surplus from the protocol will be pushed
    /// @param newSurplusConverter Address to which the role needs to be granted
    /// @dev It is as if the `GUARDIAN_ROLE` was admin of the `SURPLUS_DISTRIBUTOR_ROLE`
    /// @dev The address can be the zero address in case the protocol revokes the `surplusConverter`
    function setSurplusConverter(address newSurplusConverter) external onlyRole(GUARDIAN_ROLE) {
        address oldSurplusConverter = surplusConverter;
        surplusConverter = newSurplusConverter;
        emit SurplusConverterUpdated(newSurplusConverter, oldSurplusConverter);
    }

    /// @notice Sets the share of the interests going directly to the surplus
    /// @param _interestsForSurplus New value of the interests going directly to the surplus for buybacks
    /// @dev Guardian should make sure the incentives for SLPs are still high enough for them to enter the protocol
    function setInterestsForSurplus(uint64 _interestsForSurplus)
        external
        onlyRole(GUARDIAN_ROLE)
        onlyCompatibleFees(_interestsForSurplus)
    {
        interestsForSurplus = _interestsForSurplus;
        emit InterestsForSurplusUpdated(_interestsForSurplus);
    }

    /// @notice Modifies the funds a strategy has access to
    /// @param strategy The address of the Strategy
    /// @param _debtRatio The share of the total assets that the strategy has access to
    /// @dev The update has to be such that the `debtRatio` does not exceeds the 100% threshold
    /// as this `PoolManager` cannot lend collateral that it doesn't not own.
    /// @dev `_debtRatio` is stored as a uint256 but as any parameter of the protocol, it should be expressed
    /// in `BASE_PARAMS`
    function updateStrategyDebtRatio(address strategy, uint256 _debtRatio) external onlyRole(GUARDIAN_ROLE) {
        _updateStrategyDebtRatio(strategy, _debtRatio);
    }

    /// @notice Triggers an emergency exit for a strategy and then harvests it to fetch all the funds
    /// @param strategy The address of the `Strategy`
    function setStrategyEmergencyExit(address strategy) external onlyRole(GUARDIAN_ROLE) {
        _updateStrategyDebtRatio(strategy, 0);
        IStrategy(strategy).setEmergencyExit();
        IStrategy(strategy).harvest();
    }

    /// @notice Revokes a strategy
    /// @param strategy The address of the strategy to revoke
    /// @dev This should only be called after the following happened in order: the `strategy.debtRatio` has been set to 0,
    /// `harvest` has been called enough times to recover all capital gain/losses.
    function revokeStrategy(address strategy) external onlyRole(GUARDIAN_ROLE) {
        StrategyParams storage params = strategies[strategy];

        require(params.debtRatio == 0, "77");
        require(params.totalStrategyDebt == 0, "77");
        uint256 strategyListLength = strategyList.length;
        require(params.lastReport != 0 && strategyListLength >= 1, "78");
        // It has already been checked whether the strategy was a valid strategy
        for (uint256 i = 0; i < strategyListLength - 1; i++) {
            if (strategyList[i] == strategy) {
                strategyList[i] = strategyList[strategyListLength - 1];
                break;
            }
        }

        strategyList.pop();

        // Update global parameters
        debtRatio -= params.debtRatio;
        delete strategies[strategy];

        _revokeRole(STRATEGY_ROLE, strategy);

        emit StrategyRevoked(strategy);
    }

    /// @notice Withdraws a given amount from a strategy
    /// @param strategy The address of the strategy
    /// @param amount The amount to withdraw
    /// @dev This function tries to recover `amount` from the strategy, but it may not go through
    /// as we may not be able to withdraw from the lending protocol the full amount
    /// @dev In this last case we only update the parameters by setting the loss as the gap between
    /// what has been asked and what has been returned.
    function withdrawFromStrategy(IStrategy strategy, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        StrategyParams storage params = strategies[address(strategy)];
        require(params.lastReport != 0, "78");

        uint256 loss;
        (amount, loss) = strategy.withdraw(amount);

        // Handling eventual losses
        params.totalStrategyDebt = params.totalStrategyDebt - loss - amount;
        totalDebt = totalDebt - loss - amount;

        emit StrategyReported(address(strategy), 0, loss, amount - loss, params.totalStrategyDebt);

        // Handle eventual losses
        // With the strategy we are using in current tests, it is going to be impossible to have
        // a positive loss by calling strategy.withdraw, this function indeed calls _liquidatePosition
        // which output value is always zero
        if (loss > 0) stableMaster.signalLoss(loss);
    }

    // =================== Surplus Distributor Function ============================

    /// @notice Allows to push interests revenue accumulated by the protocol to the `surplusConverter` to do buybacks
    ///  or another form of redistribution to ANGLE or veANGLE token holders
    /// @dev This function is permissionless and anyone can transfer the `interestsAccumulated` by the protocol
    /// to the `surplusConverter`
    function pushSurplus() external {
        // If the `surplusConverter` has not been initialized, surplus should not be distributed
        // Storing the `surplusConverter` in an intermediate variable to avoid multiple reads in
        // storage
        address surplusConverterMem = surplusConverter;
        require(surplusConverterMem != address(0), "0");
        uint256 amount = interestsAccumulated;
        interestsAccumulated = 0;
        // Storing the `token` in memory to avoid duplicate reads in storage
        IERC20 tokenMem = token;
        tokenMem.safeTransfer(surplusConverterMem, amount);
        emit Recovered(address(tokenMem), surplusConverterMem, amount);
    }

    // ======================== Getters - View Functions ===========================

    /// @notice Gets the current balance of this `PoolManager` contract
    /// @return The amount of the underlying collateral that the contract currently owns
    /// @dev This balance does not take into account what has been lent to strategies
    function getBalance() external view override returns (uint256) {
        return _getBalance();
    }

    /// @notice Gets the total amount of collateral that is controlled by this `PoolManager` contract
    /// @return The amount of collateral owned by this contract plus the amount that has been lent to strategies
    /// @dev This is the value that is used to compute the debt ratio for a given strategy
    function getTotalAsset() external view override returns (uint256) {
        return _getTotalAsset();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import "../external/AccessControlUpgradeable.sol";

import "../interfaces/IFeeManager.sol";
import "../interfaces/IPoolManager.sol";
import "../interfaces/ISanToken.sol";
import "../interfaces/IPerpetualManager.sol";
import "../interfaces/IStableMaster.sol";
import "../interfaces/IStrategy.sol";

import "../utils/FunctionUtils.sol";

/// @title PoolManagerEvents
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This contract contains all the events of the `PoolManager` Contract
contract PoolManagerEvents {
    event FeesDistributed(uint256 amountDistributed);

    event Recovered(address indexed token, address indexed to, uint256 amount);

    event StrategyAdded(address indexed strategy, uint256 debtRatio);

    event InterestsForSurplusUpdated(uint64 _interestsForSurplus);

    event SurplusConverterUpdated(address indexed newSurplusConverter, address indexed oldSurplusConverter);

    event StrategyRevoked(address indexed strategy);

    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPayment,
        uint256 totalDebt
    );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./PoolManagerStorageV3.sol";

/// @title PoolManagerInternal
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This file contains all the internal functions of the `PoolManager` contract
contract PoolManagerInternal is PoolManagerStorageV3 {
    using SafeERC20 for IERC20;

    // Roles need to be defined here because there are some internal access control functions
    // in the `PoolManagerInternal` file

    /// @notice Role for `StableMaster` only
    bytes32 public constant STABLEMASTER_ROLE = keccak256("STABLEMASTER_ROLE");
    /// @notice Role for governors only
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    /// @notice Role for guardians and governors
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    /// @notice Role for `Strategy` only
    bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");

    // ======================= Access Control and Governance =======================

    /// @notice Adds a new guardian address and echoes the change to the contracts
    /// that interact with this collateral `PoolManager`
    /// @param _guardian New guardian address
    function _addGuardian(address _guardian) internal {
        // Granting the new role
        // Access control for this contract
        _grantRole(GUARDIAN_ROLE, _guardian);
        // Propagating the new role in other contract
        perpetualManager.grantRole(GUARDIAN_ROLE, _guardian);
        feeManager.grantRole(GUARDIAN_ROLE, _guardian);
        uint256 strategyListLength = strategyList.length;
        for (uint256 i = 0; i < strategyListLength; i++) {
            IStrategy(strategyList[i]).addGuardian(_guardian);
        }
    }

    /// @notice Revokes the guardian role and propagates the change to other contracts
    /// @param guardian Old guardian address to revoke
    function _revokeGuardian(address guardian) internal {
        _revokeRole(GUARDIAN_ROLE, guardian);
        perpetualManager.revokeRole(GUARDIAN_ROLE, guardian);
        feeManager.revokeRole(GUARDIAN_ROLE, guardian);
        uint256 strategyListLength = strategyList.length;
        for (uint256 i = 0; i < strategyListLength; i++) {
            IStrategy(strategyList[i]).revokeGuardian(guardian);
        }
    }

    // ============================= Yield Farming =================================

    /// @notice Internal version of `updateStrategyDebtRatio`
    /// @dev Updates the debt ratio for a strategy
    function _updateStrategyDebtRatio(address strategy, uint256 _debtRatio) internal {
        StrategyParams storage params = strategies[strategy];
        require(params.lastReport != 0, "78");
        debtRatio = debtRatio + _debtRatio - params.debtRatio;
        require(debtRatio <= BASE_PARAMS, "76");
        params.debtRatio = _debtRatio;
        emit StrategyAdded(strategy, debtRatio);
    }

    // ============================ Utils ==========================================

    /// @notice Returns this `PoolManager`'s reserve of collateral (not including what has been lent)
    function _getBalance() internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Returns the amount of assets owned by this `PoolManager`
    /// @dev This sums the current balance of the contract to what has been given to strategies
    /// @dev This amount can be manipulated by flash loans
    function _getTotalAsset() internal view returns (uint256) {
        return _getBalance() + totalDebt;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./PoolManagerEvents.sol";

/// @title PoolManagerStorageV1
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This file contains most of the variables and parameters stored for this contract. It does not contain all
/// as the storage file has been split into multiple files to avoid clashes when upgrading the smart contract
contract PoolManagerStorageV1 is PoolManagerEvents, FunctionUtils {
    // ================ References to contracts that cannot be modified ============

    /// @notice Interface for the underlying token accepted by this contract
    IERC20 public token;

    /// @notice Reference to the `PerpetualManager` for this collateral/stablecoin pair
    /// `PerpetualManager` is an upgradeable contract, there is therefore no need to be able to update this reference
    IPerpetualManager public perpetualManager;

    /// @notice Reference to the `StableMaster` contract corresponding to this `PoolManager`
    IStableMaster public stableMaster;

    // ============== References to contracts that can be modified =================

    /// @notice FeeManager contract for this collateral/stablecoin pair
    /// This reference can be updated by the `StableMaster` and change is going to be propagated
    /// to the `PerpetualManager` from this contract
    IFeeManager public feeManager;

    // ============================= Yield Farming =================================

    /// @notice Funds currently given to strategies
    uint256 public totalDebt;

    /// @notice Proportion of the funds managed dedicated to strategies
    /// Has to be between 0 and `BASE_PARAMS`
    uint256 public debtRatio;

    /// The struct `StrategyParams` is defined in the interface `IPoolManager`
    /// @notice Mapping between the address of a strategy contract and its corresponding details
    mapping(address => StrategyParams) public strategies;

    /// @notice List of the current strategies
    address[] public strategyList;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./PoolManagerStorageV1.sol";

/// @title PoolManagerStorageV2
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This file imports the `AccessControlUpgradeable`
contract PoolManagerStorageV2 is PoolManagerStorageV1, AccessControlUpgradeable {

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./PoolManagerStorageV2.sol";

/// @title PoolManagerStorageV3
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This file contains the last variables and parameters stored for this contract. The reason for not storing them
/// directly in `PoolManagerStorageV1` is that theywere introduced after a first deployment and may have introduced a
/// storage clash when upgrading
contract PoolManagerStorageV3 is PoolManagerStorageV2 {
    /// @notice Address of the surplus distributor allowed to distribute rewards
    address public surplusConverter;

    /// @notice Share of the interests going to surplus and share going to SLPs
    uint64 public interestsForSurplus;

    /// @notice Interests accumulated by the protocol and to be distributed through ANGLE or veANGLE
    /// token holders
    uint256 public interestsAccumulated;

    /// @notice Debt that must be paid by admins after a loss on a strategy
    uint256 public adminDebt;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title FunctionUtils
/// @author Angle Core Team
/// @notice Contains all the utility functions that are needed in different places of the protocol
/// @dev Functions in this contract should typically be pure functions
/// @dev This contract is voluntarily a contract and not a library to save some gas cost every time it is used
contract FunctionUtils {
    /// @notice Base that is used to compute ratios and floating numbers
    uint256 public constant BASE_TOKENS = 10**18;
    /// @notice Base that is used to define parameters that need to have a floating value (for instance parameters
    /// that are defined as ratios)
    uint256 public constant BASE_PARAMS = 10**9;

    /// @notice Computes the value of a linear by part function at a given point
    /// @param x Point of the function we want to compute
    /// @param xArray List of breaking points (in ascending order) that define the linear by part function
    /// @param yArray List of values at breaking points (not necessarily in ascending order)
    /// @dev The evolution of the linear by part function between two breaking points is linear
    /// @dev Before the first breaking point and after the last one, the function is constant with a value
    /// equal to the first or last value of the yArray
    /// @dev This function is relevant if `x` is between O and `BASE_PARAMS`. If `x` is greater than that, then
    /// everything will be as if `x` is equal to the greater element of the `xArray`
    function _piecewiseLinear(
        uint64 x,
        uint64[] memory xArray,
        uint64[] memory yArray
    ) internal pure returns (uint64) {
        if (x >= xArray[xArray.length - 1]) {
            return yArray[xArray.length - 1];
        } else if (x <= xArray[0]) {
            return yArray[0];
        } else {
            uint256 lower;
            uint256 upper = xArray.length - 1;
            uint256 mid;
            while (upper - lower > 1) {
                mid = lower + (upper - lower) / 2;
                if (xArray[mid] <= x) {
                    lower = mid;
                } else {
                    upper = mid;
                }
            }
            if (yArray[upper] > yArray[lower]) {
                // There is no risk of overflow here as in the product of the difference of `y`
                // with the difference of `x`, the product is inferior to `BASE_PARAMS**2` which does not
                // overflow for `uint64`
                return
                    yArray[lower] +
                    ((yArray[upper] - yArray[lower]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            } else {
                return
                    yArray[lower] -
                    ((yArray[lower] - yArray[upper]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            }
        }
    }

    /// @notice Checks if the input arrays given by governance to update the fee structure is valid
    /// @param xArray List of breaking points (in ascending order) that define the linear by part function
    /// @param yArray List of values at breaking points (not necessarily in ascending order)
    /// @dev This function is a way to avoid some governance attacks or errors
    /// @dev The modifier checks if the arrays have a non null length, if their length is the same, if the values
    /// in the `xArray` are in ascending order and if the values in the `xArray` and in the `yArray` are not superior
    /// to `BASE_PARAMS`
    modifier onlyCompatibleInputArrays(uint64[] memory xArray, uint64[] memory yArray) {
        require(xArray.length == yArray.length && xArray.length > 0, "5");
        for (uint256 i = 0; i <= yArray.length - 1; i++) {
            require(yArray[i] <= uint64(BASE_PARAMS) && xArray[i] <= uint64(BASE_PARAMS), "6");
            if (i > 0) {
                require(xArray[i] > xArray[i - 1], "7");
            }
        }
        _;
    }

    /// @notice Checks if the new value given for the parameter is consistent (it should be inferior to 1
    /// if it corresponds to a ratio)
    /// @param fees Value of the new parameter to check
    modifier onlyCompatibleFees(uint64 fees) {
        require(fees <= BASE_PARAMS, "4");
        _;
    }

    /// @notice Checks if the new address given is not null
    /// @param newAddress Address to check
    /// @dev Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
    modifier zeroCheck(address newAddress) {
        require(newAddress != address(0), "0");
        _;
    }
}