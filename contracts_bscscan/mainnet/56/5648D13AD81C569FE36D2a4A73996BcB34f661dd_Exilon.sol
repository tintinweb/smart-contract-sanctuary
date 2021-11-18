/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// File: @openzeppelin/contracts/access/IAccessControl.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/AccessControl.sol


pragma solidity ^0.8.0;





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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


pragma solidity ^0.8.0;


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

// File: contracts/pancake-swap/interfaces/IPancakeERC20.sol


pragma solidity ^0.8.0;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/pancake-swap/interfaces/IPancakePair.sol


pragma solidity ^0.8.0;


interface IPancakePair is IPancakeERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/pancake-swap/interfaces/IPancakeFactory.sol


pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts/pancake-swap/libraries/PancakeLibrary.sol


pragma solidity ^0.8.0;

//import '@uniswap/v2-core/contracts/interfaces/IPancakePair.sol';



library PancakeLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "PancakeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "PancakeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = IPancakeFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(pairFor(factory, tokenA, tokenB))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PancakeLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 9975;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 10000;
        uint256 denominator = (reserveOut - amountOut) * 9975;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "PancakeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "PancakeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/pancake-swap/interfaces/IPancakeRouter01.sol


pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/pancake-swap/interfaces/IPancakeRouter02.sol


pragma solidity ^0.8.0;


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/pancake-swap/interfaces/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/WethReceiver.sol


pragma solidity 0.8.10;


contract WethReceiver {
    address public immutable exilonToken;

    constructor(address _exilonToken) {
        exilonToken = _exilonToken;
    }

    function getWeth(address weth, uint256 amount) external {
        address _exilonToken = exilonToken;
        require(msg.sender == _exilonToken, "wethReceiver: Not allowed");
        IERC20(weth).transfer(_exilonToken, amount);
    }
}

// File: contracts/interfaces/IExilon.sol


pragma solidity ^0.8.0;

interface IExilon {
    function addLiquidity() external payable;

    function forceLpFeesDistribute() external;

    function excludeFromFeesDistribution(address user) external;

    function includeToFeesDistribution(address user) external;

    function excludeFromPayingFees(address user) external;

    function includeToPayingFees(address user) external;

    function enableLowerCommissions(address user) external;

    function disableLowerCommissions(address user) external;

    function setWethLimitForLpFee(uint256 newValue) external;

    function setDefaultLpMintAddress(address newValue) external;

    function setMarketingAddress(address newValue) external;
}

// File: contracts/Exilon.sol


pragma solidity 0.8.10;












contract Exilon is IERC20, IERC20Metadata, AccessControl, IExilon {
    /* STATE VARIABLES */

    // public data

    IPancakeRouter02 public immutable dexRouter;
    address public immutable dexPairExilonWeth;
    address public immutable dexPairUsdWeth;
    address public immutable usdAddress;
    address public wethReceiver;

    address public defaultLpMintAddress;
    address public marketingAddress;

    uint256 public feeAmountInTokens;
    uint256 public wethLimitForLpFee = 1 ether;
    uint256 public immutable feeAmountInUsd;

    address public reserveFeeAddress;
    uint256 public reserveFee;

    // private data

    uint8 private constant _DECIMALS = 6;

    string private constant _NAME = "Exilon";
    string private constant _SYMBOL = "EXL";

    mapping(address => mapping(address => uint256)) private _allowances;

    // "internal" balances for not fixed addresses
    mapping(address => uint256) private _notFixedBalances;
    // "external" balances for fixed addresses
    mapping(address => uint256) private _fixedBalances;

    uint256 private constant _TOTAL_EXTERNAL_SUPPLY = 5 * 10**12 * 10**_DECIMALS;
    // div by _TOTAL_EXTERNAL_SUPPLY is needed because
    // notFixedExternalTotalSupply * notFixedInternalTotalSupply
    // must fit into uint256
    uint256 private constant _MAX_INTERNAL_SUPPLY = type(uint256).max / _TOTAL_EXTERNAL_SUPPLY;
    uint256 private constant _INITIAL_AMOUNT_TO_LIQUIDITY = (_TOTAL_EXTERNAL_SUPPLY * 40) / 100;

    // _notFixedInternalTotalSupply * _notFixedExternalTotalSupply <= type(uint256).max
    uint256 private _notFixedExternalTotalSupply;
    uint256 private _notFixedInternalTotalSupply;

    // 0 - not added; 1 - added
    uint256 private _isLpAdded;
    address private immutable _weth;

    uint256 private _startBlock;
    uint256 private _startTimestamp;

    // addresses that exluded from distribution of fees from transfers (have fixed balances)
    mapping(address => bool) public isExcludedFromDistribution;
    mapping(address => bool) public isExcludedFromPayingFees;
    mapping(address => bool) public isHavingLowerCommissions;

    /* MODIFIERS */

    modifier onlyWhenLiquidityAdded() {
        require(_isLpAdded == 1, "Exilon: Liquidity not added");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Exilon: Sender is not admin");
        _;
    }

    /* EVENTS */

    event ExcludedFromFeesDistribution(address indexed user);
    event IncludedToFeesDistribution(address indexed user);

    event ExcludedFromPayingFees(address indexed user);
    event IncludedToPayingFees(address indexed user);

    event EnabledLowerCommissions(address indexed user);
    event DisabledLowerCommissions(address indexed user);

    event ChangeWethLimitForLpFee(uint256 oldValue, uint256 newValue);
    event ChangeDefaultLpMintAddress(address indexed oldValue, address indexed newValue);
    event ChangeMarketingAddress(address oldValue, address newValue);

    event ForceLpFeesDistribution();

    event LiquidityAdded(uint256 amount);

    event TokenDistribution(uint256 amount);

    /* STRUCTS */

    struct FeesInfo {
        uint256 lpFee;
        uint256 distributeFee;
        uint256 burnFee;
        uint256 marketingFee;
        uint256 reserveFee;
    }

    struct PoolInfo {
        uint256 tokenReserves;
        uint256 wethReserves;
        uint256 wethBalance;
        address dexPair;
        address weth;
        bool isToken0;
    }

    /* FUNCTIONS */

    constructor(
        IPancakeRouter02 _dexRouter,
        address _usdAddress,
        address[] memory toDistribute,
        address _defaultLpMintAddress,
        address _marketingAddress
    ) {
        dexRouter = _dexRouter;
        IPancakeFactory dexFactory = IPancakeFactory(_dexRouter.factory());

        address weth = _dexRouter.WETH();
        _weth = weth;

        address _dexPairExilonWeth = dexFactory.createPair(address(this), weth);
        dexPairExilonWeth = _dexPairExilonWeth;

        {
            usdAddress = _usdAddress;
            feeAmountInUsd = 10**IERC20Metadata(_usdAddress).decimals();

            address _dexPairUsdWeth = dexFactory.getPair(weth, _usdAddress);
            require(_dexPairUsdWeth != address(0), "Exilon: Wrong usd token");
            dexPairUsdWeth = _dexPairUsdWeth;
        }

        defaultLpMintAddress = _defaultLpMintAddress;
        marketingAddress = _marketingAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // add LP pair and burn address to excludedFromDistribution
        isExcludedFromDistribution[_dexPairExilonWeth] = true;
        isExcludedFromDistribution[address(0xdead)] = true;
        isExcludedFromDistribution[_marketingAddress] = true;

        // _fixedBalances[address(this)] only used for adding liquidity
        isExcludedFromDistribution[address(this)] = true;
        _fixedBalances[address(this)] = _INITIAL_AMOUNT_TO_LIQUIDITY;
        // add changes to transfer _INITIAL_AMOUNT_TO_LIQUIDITY amount from NotFixed to Fixed account
        // because LP pair is exluded from distribution
        uint256 notFixedExternalTotalSupply = _TOTAL_EXTERNAL_SUPPLY;

        uint256 notFixedInternalTotalSupply = _MAX_INTERNAL_SUPPLY;

        uint256 notFixedAmount = (_INITIAL_AMOUNT_TO_LIQUIDITY * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;

        notFixedExternalTotalSupply -= _INITIAL_AMOUNT_TO_LIQUIDITY;
        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

        notFixedInternalTotalSupply -= notFixedAmount;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        // notFixedInternalTotalSupply amount will be distributed between toDistribute addresses
        // it is addresses for team
        require(toDistribute.length > 0, "Exilon: Length error");
        uint256 restAmount = notFixedInternalTotalSupply;
        for (uint256 i = 0; i < toDistribute.length; ++i) {
            uint256 amountToDistribute;
            if (i < toDistribute.length - 1) {
                amountToDistribute = notFixedInternalTotalSupply / toDistribute.length;
                restAmount -= amountToDistribute;
            } else {
                amountToDistribute = restAmount;
            }

            _notFixedBalances[toDistribute[i]] = amountToDistribute;

            uint256 fixedAmountDistributed = (amountToDistribute * notFixedExternalTotalSupply) /
                notFixedInternalTotalSupply;
            emit Transfer(address(0), toDistribute[i], fixedAmountDistributed);
        }
        emit Transfer(address(0), address(this), _INITIAL_AMOUNT_TO_LIQUIDITY);
    }

    /* EXTERNAL FUNCTIONS */

    function addLiquidity() external payable override onlyAdmin {
        require(_isLpAdded == 0, "Exilon: Only once");
        _isLpAdded = 1;

        _startBlock = block.number;
        _startTimestamp = block.timestamp;

        uint256 amountToLiquidity = _fixedBalances[address(this)];
        delete _fixedBalances[address(this)];
        isExcludedFromDistribution[address(this)] = false;

        address _dexPairExilonWeth = dexPairExilonWeth;
        _fixedBalances[_dexPairExilonWeth] = amountToLiquidity;

        address weth = _weth;
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).transfer(_dexPairExilonWeth, msg.value);

        IPancakePair(_dexPairExilonWeth).mint(defaultLpMintAddress);

        emit Transfer(address(this), _dexPairExilonWeth, amountToLiquidity);
        emit LiquidityAdded(msg.value);
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        onlyWhenLiquidityAdded
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override onlyWhenLiquidityAdded returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Exilon: Amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        _transfer(sender, recipient, amount);

        return true;
    }

    function forceLpFeesDistribute() external override onlyWhenLiquidityAdded onlyAdmin {
        PoolInfo memory poolInfo;
        poolInfo.dexPair = dexPairExilonWeth;
        poolInfo.weth = _weth;
        _distributeLpFee(address(0), 0, true, poolInfo);

        emit ForceLpFeesDistribution();
    }

    function distributeTokens(uint256 amount) external {
        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        require(notFixedExternalTotalSupply != 0, "Exilon: Distribution to nobody");

        if (isExcludedFromDistribution[msg.sender]) {
            uint256 fixedUserBalance = _fixedBalances[msg.sender];
            require(fixedUserBalance >= amount, "Exilon: Not enough balance");

            _notFixedBalances[msg.sender] = fixedUserBalance - amount;
            _notFixedExternalTotalSupply = notFixedExternalTotalSupply + amount;
        } else {
            uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

            uint256 notFixedUserBalance = _notFixedBalances[msg.sender];
            uint256 fixedUserBalance = (notFixedExternalTotalSupply * notFixedUserBalance) /
                notFixedInternalTotalSupply;
            require(fixedUserBalance >= amount, "Exilon: Not enough balance");

            uint256 notFixedDistributeAmount = (amount * notFixedInternalTotalSupply) /
                notFixedExternalTotalSupply;

            _notFixedBalances[msg.sender] = notFixedUserBalance - notFixedDistributeAmount;
            _notFixedInternalTotalSupply = notFixedInternalTotalSupply - notFixedDistributeAmount;
        }

        emit TokenDistribution(amount);
    }

    function excludeFromFeesDistribution(address user)
        external
        override
        onlyWhenLiquidityAdded
        onlyAdmin
    {
        require(!isExcludedFromDistribution[user], "Exilon: Already excluded");
        isExcludedFromDistribution[user] = true;

        uint256 notFixedUserBalance = _notFixedBalances[user];
        if (notFixedUserBalance > 0) {
            uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
            uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

            uint256 fixedUserBalance = (notFixedExternalTotalSupply * notFixedUserBalance) /
                notFixedInternalTotalSupply;

            _fixedBalances[user] = fixedUserBalance;
            delete _notFixedBalances[user];

            notFixedExternalTotalSupply -= fixedUserBalance;
            _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

            notFixedInternalTotalSupply -= notFixedUserBalance;
            _notFixedInternalTotalSupply = notFixedInternalTotalSupply;
        }

        emit ExcludedFromFeesDistribution(user);
    }

    function includeToFeesDistribution(address user)
        external
        override
        onlyWhenLiquidityAdded
        onlyAdmin
    {
        require(
            user != address(0xdead) &&
                user != dexPairExilonWeth &&
                user != marketingAddress &&
                user != reserveFeeAddress,
            "Exilon: Wrong address"
        );
        require(isExcludedFromDistribution[user], "Exilon: Already included");
        isExcludedFromDistribution[user] = false;

        uint256 fixedUserBalance = _fixedBalances[user];
        if (fixedUserBalance > 0) {
            uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
            uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

            uint256 notFixedUserBalance;
            if (notFixedInternalTotalSupply == 0) {
                // if there was no notFixed accounts

                // notice that
                // notFixedInternalTotalSupply != 0  <=>  notFixedExternalTotalSupply != 0
                // and
                // notFixedInternalTotalSupply == 0  <=>  notFixedExternalTotalSupply == 0

                notFixedUserBalance =
                    (fixedUserBalance * _MAX_INTERNAL_SUPPLY) /
                    _TOTAL_EXTERNAL_SUPPLY;
            } else {
                notFixedUserBalance =
                    (fixedUserBalance * notFixedInternalTotalSupply) /
                    notFixedExternalTotalSupply;
            }

            _notFixedBalances[user] = notFixedUserBalance;
            delete _fixedBalances[user];

            notFixedExternalTotalSupply += fixedUserBalance;
            _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

            notFixedInternalTotalSupply += notFixedUserBalance;
            _notFixedInternalTotalSupply = notFixedInternalTotalSupply;
        }

        emit IncludedToFeesDistribution(user);
    }

    function excludeFromPayingFees(address user) external override onlyAdmin {
        require(user != address(0xdead) && user != dexPairExilonWeth, "Exilon: Wrong address");
        require(!isExcludedFromPayingFees[user], "Exilon: Already excluded");
        isExcludedFromPayingFees[user] = true;

        emit ExcludedFromPayingFees(user);
    }

    function includeToPayingFees(address user) external override onlyAdmin {
        require(user != address(0xdead) && user != dexPairExilonWeth, "Exilon: Wrong address");
        require(isExcludedFromPayingFees[user], "Exilon: Already included");
        isExcludedFromPayingFees[user] = false;

        emit IncludedToPayingFees(user);
    }

    function enableLowerCommissions(address user) external override onlyAdmin {
        require(user != address(0xdead) && user != dexPairExilonWeth, "Exilon: Wrong address");
        require(!isHavingLowerCommissions[user], "Exilon: Already included");
        isHavingLowerCommissions[user] = true;

        emit EnabledLowerCommissions(user);
    }

    function disableLowerCommissions(address user) external override onlyAdmin {
        require(user != address(0xdead) && user != dexPairExilonWeth, "Exilon: Wrong address");
        require(isHavingLowerCommissions[user], "Exilon: Already included");
        isHavingLowerCommissions[user] = false;

        emit DisabledLowerCommissions(user);
    }

    function setWethLimitForLpFee(uint256 newValue) external override onlyAdmin {
        require(newValue <= 10 ether, "Exilon: Too big value");
        uint256 oldValue = wethLimitForLpFee;
        wethLimitForLpFee = newValue;

        emit ChangeWethLimitForLpFee(oldValue, newValue);
    }

    function setDefaultLpMintAddress(address newValue) external override onlyAdmin {
        address oldValue = defaultLpMintAddress;
        defaultLpMintAddress = newValue;

        emit ChangeDefaultLpMintAddress(oldValue, newValue);
    }

    function setWethReceiver(address value) external onlyAdmin {
        require(wethReceiver == address(0) && value != address(0), "Exilon: Only once");
        wethReceiver = value;
    }

    function setMarketingAddress(address newValue) external override onlyAdmin {
        require(isExcludedFromDistribution[newValue], "Exilon: Marketing address must be fixed");
        address oldValue = marketingAddress;
        marketingAddress = newValue;

        emit ChangeMarketingAddress(oldValue, newValue);
    }

    function setReserveFeeParameters(address _reserveFeeAddress, uint256 _reserveFee) external {
        if (_reserveFee > 0) {
            require(
                isExcludedFromDistribution[_reserveFeeAddress],
                "Exilon: Reserve fee address must be fixed"
            );
            require(
                _reserveFee <= 100, // 1%
                "Exilon: Fee too big"
            );
        }

        reserveFeeAddress = _reserveFeeAddress;
        reserveFee = _reserveFee;
    }

    function name() external view virtual override returns (string memory) {
        return _NAME;
    }

    function symbol() external view virtual override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external view virtual override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _TOTAL_EXTERNAL_SUPPLY;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        if (isExcludedFromDistribution[account]) {
            return _fixedBalances[account];
        } else {
            return
                (_notFixedBalances[account] * _notFixedExternalTotalSupply) /
                _notFixedInternalTotalSupply;
        }
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /* PUBLIC FUNCTIONS */

    /* INTERNAL FUNCTIONS */

    /* PRIVATE FUNCTIONS */

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Exilon: From zero address");
        require(spender != address(0), "Exilon: To zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        bool isFromFixed = isExcludedFromDistribution[from];
        bool isToFixed = isExcludedFromDistribution[to];

        if (isFromFixed == true && isToFixed == true) {
            _transferFromFixedToFixed(from, to, amount);
        } else if (isFromFixed == true && isToFixed == false) {
            _transferFromFixedToNotFixed(from, to, amount);
        } else if (isFromFixed == false && isToFixed == true) {
            _trasnferFromNotFixedToFixed(from, to, amount);
        } else {
            _transferFromNotFixedToNotFixed(from, to, amount);
        }
    }

    function _transferFromFixedToFixed(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 fixedBalanceFrom = _fixedBalances[from];
        require(fixedBalanceFrom >= amount, "Exilon: Amount exceeds balance");
        _fixedBalances[from] = (fixedBalanceFrom - amount);

        address _dexPairExilonWeth = dexPairExilonWeth;
        uint256 transferAmount;
        if (from == _dexPairExilonWeth) {
            // buy tokens
            FeesInfo memory fees;
            (transferAmount, fees) = _makeBuyAction(
                _dexPairExilonWeth,
                from,
                to,
                amount,
                _notFixedInternalTotalSupply
            );

            if (fees.distributeFee > 0) {
                // Fee to distribute between users
                _notFixedExternalTotalSupply += fees.distributeFee;
            }
        } else if (to == _dexPairExilonWeth) {
            // sell tokens
            FeesInfo memory fees;
            (transferAmount, fees) = _makeSellAction(
                _dexPairExilonWeth,
                from,
                amount,
                amount >= (fixedBalanceFrom * 9) / 10,
                _notFixedInternalTotalSupply
            );

            if (fees.distributeFee > 0) {
                // Fee to distribute between users
                _notFixedExternalTotalSupply += fees.distributeFee;
            }
        } else {
            (transferAmount, ) = _makeTransferAction(_dexPairExilonWeth, from, to, amount);
        }

        _fixedBalances[to] += transferAmount;

        emit Transfer(from, to, transferAmount);
    }

    function _transferFromFixedToNotFixed(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 fixedBalanceFrom = _fixedBalances[from];
        require(fixedBalanceFrom >= amount, "Exilon: Amount exceeds balance");
        _fixedBalances[from] = (fixedBalanceFrom - amount);

        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

        address _dexPairExilonWeth = dexPairExilonWeth;
        uint256 transferAmount;
        uint256 distributionAmount;
        // sell tokens cannot be because
        // dexPairExilonWeth is fixed
        if (from == _dexPairExilonWeth) {
            // buy tokens
            FeesInfo memory fees;
            (transferAmount, fees) = _makeBuyAction(
                _dexPairExilonWeth,
                from,
                to,
                amount,
                notFixedInternalTotalSupply
            );
            distributionAmount = fees.distributeFee;
        } else {
            (transferAmount, ) = _makeTransferAction(_dexPairExilonWeth, from, to, amount);
        }

        uint256 notFixedAmount;
        if (notFixedInternalTotalSupply == 0) {
            notFixedAmount = (transferAmount * _MAX_INTERNAL_SUPPLY) / _TOTAL_EXTERNAL_SUPPLY;
        } else {
            notFixedAmount =
                (transferAmount * notFixedInternalTotalSupply) /
                notFixedExternalTotalSupply;
        }
        _notFixedBalances[to] += notFixedAmount;

        notFixedExternalTotalSupply += transferAmount + distributionAmount;
        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

        notFixedInternalTotalSupply += notFixedAmount;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        emit Transfer(from, to, transferAmount);
    }

    function _trasnferFromNotFixedToFixed(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

        uint256 notFixedAmount = (amount * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;

        uint256 notFixedBalanceFrom = _notFixedBalances[from];
        require(notFixedBalanceFrom >= notFixedAmount, "Exilon: Amount exceeds balance");
        _notFixedBalances[from] = (notFixedBalanceFrom - notFixedAmount);

        address _dexPairExilonWeth = dexPairExilonWeth;
        uint256 transferAmount;
        uint256 distributionAmount;
        // buy tokens cannot be because
        // dexPairExilonWeth is fixed
        if (to == _dexPairExilonWeth) {
            // sell tokens
            FeesInfo memory fees;
            (transferAmount, fees) = _makeSellAction(
                _dexPairExilonWeth,
                from,
                amount,
                amount >=
                    (((notFixedBalanceFrom * notFixedExternalTotalSupply) /
                        notFixedInternalTotalSupply) * 9) /
                        10,
                notFixedInternalTotalSupply
            );
            distributionAmount = fees.distributeFee;
        } else {
            (transferAmount, ) = _makeTransferAction(_dexPairExilonWeth, from, to, amount);
        }

        _fixedBalances[to] += transferAmount;

        notFixedExternalTotalSupply -= amount;
        notFixedExternalTotalSupply += distributionAmount;
        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

        notFixedInternalTotalSupply -= notFixedAmount;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        emit Transfer(from, to, transferAmount);
    }

    function _transferFromNotFixedToNotFixed(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

        uint256 notFixedAmount = (amount * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;

        uint256 notFixedBalanceFrom = _notFixedBalances[from];
        require(notFixedBalanceFrom >= notFixedAmount, "Exilon: Amount exceeds balance");
        _notFixedBalances[from] = (notFixedBalanceFrom - notFixedAmount);

        (uint256 fixedTrasnferAmount, uint256 feeAmount) = _makeTransferAction(
            dexPairExilonWeth,
            from,
            to,
            amount
        );

        uint256 notFixedFeeAmount = (feeAmount * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;
        _notFixedBalances[to] += notFixedAmount - notFixedFeeAmount;

        notFixedExternalTotalSupply -= feeAmount;
        notFixedInternalTotalSupply -= notFixedFeeAmount;

        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        emit Transfer(from, to, fixedTrasnferAmount);
    }

    function _makeBurnAction(address from, uint256 burnFee)
        private
        returns (uint256 remainingAmount)
    {
        uint256 burnAddressBalance = _fixedBalances[address(0xdead)];
        uint256 maxBalanceInBurnAddress = (_TOTAL_EXTERNAL_SUPPLY * 6) / 10;
        if (burnAddressBalance < maxBalanceInBurnAddress) {
            uint256 burnAddressBalanceBefore = burnAddressBalance;
            burnAddressBalance += burnFee;
            if (burnAddressBalance > maxBalanceInBurnAddress) {
                remainingAmount = burnAddressBalance - maxBalanceInBurnAddress;
                burnAddressBalance = maxBalanceInBurnAddress;
            }
            _fixedBalances[address(0xdead)] = burnAddressBalance;
            emit Transfer(from, address(0xdead), burnAddressBalance - burnAddressBalanceBefore);
        } else {
            remainingAmount = burnFee;
        }
    }

    function _distributeLpFee(
        address from,
        uint256 lpFee,
        bool isForce,
        PoolInfo memory poolInfo
    ) private {
        // Fee to lp pair
        uint256 _feeAmountInTokens = feeAmountInTokens;
        if (from != address(0) && lpFee > 0) {
            emit Transfer(from, address(0), lpFee);
        }
        _feeAmountInTokens += lpFee;

        if (_feeAmountInTokens == 0) {
            return;
        }

        if (from == poolInfo.dexPair) {
            // if removing lp or buy tokens then exit
            // because dex pair is locked
            if (lpFee > 0) {
                feeAmountInTokens = _feeAmountInTokens;
            }
            return;
        }

        if (poolInfo.tokenReserves == 0) {
            poolInfo = _getDexPairInfo(poolInfo, address(this), true);
        }

        uint256 contractBalance = IERC20(poolInfo.weth).balanceOf(address(this));
        uint256 wethFeesPrice = PancakeLibrary.getAmountOut(
            _feeAmountInTokens,
            poolInfo.tokenReserves,
            poolInfo.wethReserves
        );

        if (
            wethFeesPrice == 0 ||
            (isForce == false && wethFeesPrice + contractBalance < wethLimitForLpFee)
        ) {
            if (lpFee > 0) {
                feeAmountInTokens = _feeAmountInTokens;
            }
            return;
        }

        uint256 wethAmountReturn;
        if (poolInfo.wethReserves < poolInfo.wethBalance) {
            // if in pool already weth of user
            // it can happen if user is adding lp
            wethAmountReturn = poolInfo.wethBalance - poolInfo.wethReserves;
            IPancakePair(poolInfo.dexPair).skim(address(this));
        }

        uint256 amountOfWethToBuy = (wethFeesPrice + contractBalance) / 2;
        if (amountOfWethToBuy > contractBalance) {
            amountOfWethToBuy -= contractBalance;

            uint256 amountTokenToSell = PancakeLibrary.getAmountIn(
                amountOfWethToBuy,
                poolInfo.tokenReserves,
                poolInfo.wethReserves
            );

            if (amountTokenToSell == 0) {
                if (lpFee > 0) {
                    feeAmountInTokens = _feeAmountInTokens;
                }
                return;
            }

            _fixedBalances[poolInfo.dexPair] += amountTokenToSell;
            emit Transfer(address(0), poolInfo.dexPair, amountTokenToSell);
            {
                uint256 amount0Out;
                uint256 amount1Out;
                if (poolInfo.isToken0) {
                    amount1Out = amountOfWethToBuy;
                } else {
                    amount0Out = amountOfWethToBuy;
                }
                address _wethReceiver = wethReceiver;
                IPancakePair(poolInfo.dexPair).swap(amount0Out, amount1Out, _wethReceiver, "");
                WethReceiver(_wethReceiver).getWeth(poolInfo.weth, amountOfWethToBuy);
            }
            _feeAmountInTokens -= amountTokenToSell;
            contractBalance += amountOfWethToBuy;

            poolInfo.tokenReserves += amountTokenToSell;
            poolInfo.wethReserves -= amountOfWethToBuy;
        }

        uint256 amountOfTokens = PancakeLibrary.quote(
            contractBalance,
            poolInfo.wethReserves,
            poolInfo.tokenReserves
        );
        uint256 amountOfWeth = contractBalance;
        if (amountOfTokens > _feeAmountInTokens) {
            amountOfWeth = PancakeLibrary.quote(
                _feeAmountInTokens,
                poolInfo.tokenReserves,
                poolInfo.wethReserves
            );
            amountOfTokens = _feeAmountInTokens;
        }

        _fixedBalances[poolInfo.dexPair] += amountOfTokens;
        feeAmountInTokens = _feeAmountInTokens - amountOfTokens;

        emit Transfer(address(0), poolInfo.dexPair, amountOfTokens);

        IERC20(poolInfo.weth).transfer(poolInfo.dexPair, amountOfWeth);
        IPancakePair(poolInfo.dexPair).mint(defaultLpMintAddress);

        if (wethAmountReturn > 0) {
            IERC20(poolInfo.weth).transfer(poolInfo.dexPair, wethAmountReturn);
        }
    }

    function _checkBuyRestrictionsOnStart(PoolInfo memory poolInfo)
        private
        view
        returns (PoolInfo memory)
    {
        uint256 blocknumber = block.number - _startBlock;

        // [0; 60) - 0.1 BNB
        // [60; 120) - 0.3 BNB
        // [120; 180) - 0.5 BNB
        // [180; 240) - 0.7 BNB
        // [240; +inf) - unlimited

        if (blocknumber < 240) {
            if (blocknumber < 60) {
                return _checkBuyAmountCeil(poolInfo, 1 ether / 10);
            } else if (blocknumber < 120) {
                return _checkBuyAmountCeil(poolInfo, 3 ether / 10);
            } else if (blocknumber < 180) {
                return _checkBuyAmountCeil(poolInfo, 5 ether / 10);
            } else {
                return _checkBuyAmountCeil(poolInfo, 7 ether / 10);
            }
        }

        return poolInfo;
    }

    function _checkBuyAmountCeil(PoolInfo memory poolInfo, uint256 amount)
        private
        view
        returns (PoolInfo memory)
    {
        poolInfo = _getDexPairInfo(poolInfo, address(this), true);

        if (poolInfo.wethBalance >= poolInfo.wethReserves) {
            // if not removing lp
            require(
                poolInfo.wethBalance - poolInfo.wethReserves <= amount,
                "Exilon: To big buy amount"
            );
        }

        return poolInfo;
    }

    function _getDexPairInfo(
        PoolInfo memory poolInfo,
        address tokenAddress,
        bool withTrueBalance
    ) private view returns (PoolInfo memory) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(poolInfo.dexPair).getReserves();
        (address token0, ) = PancakeLibrary.sortTokens(tokenAddress, poolInfo.weth);
        if (token0 == tokenAddress) {
            poolInfo.tokenReserves = reserve0;
            poolInfo.wethReserves = reserve1;
            poolInfo.isToken0 = true;
        } else {
            poolInfo.wethReserves = reserve0;
            poolInfo.tokenReserves = reserve1;
            poolInfo.isToken0 = false;
        }
        if (withTrueBalance) {
            poolInfo.wethBalance = IERC20(poolInfo.weth).balanceOf(poolInfo.dexPair);
        }

        return poolInfo;
    }

    function _makeBuyAction(
        address _dexPairExilonWeth,
        address from,
        address to,
        uint256 amount,
        uint256 notFixedInternalTotalSupply
    ) private returns (uint256 transferAmount, FeesInfo memory fees) {
        PoolInfo memory poolInfo;
        poolInfo.dexPair = _dexPairExilonWeth;
        poolInfo.weth = _weth;
        poolInfo = _checkBuyRestrictionsOnStart(poolInfo);

        if (!isExcludedFromPayingFees[to]) {
            uint256 multiplier;
            if (isHavingLowerCommissions[from]) {
                multiplier = 10;
            } else {
                multiplier = 100;
            }

            fees.burnFee = (amount * multiplier) / 10000;
            fees.marketingFee = (amount * 2 * multiplier) / 10000;

            fees.reserveFee = (amount * reserveFee * multiplier) / (10000 * 100);

            if (notFixedInternalTotalSupply == 0) {
                fees.lpFee = (amount * 9 * multiplier) / 10000;
            } else {
                fees.distributeFee = (amount * multiplier) / 10000;
                fees.lpFee = (amount * 8 * multiplier) / 10000;
            }
        }

        uint256 additionalToLp;
        if (fees.burnFee > 0) {
            additionalToLp = _makeBurnAction(from, fees.burnFee);
        }

        if (fees.marketingFee > 0) {
            address _marketingAddress = marketingAddress;
            _fixedBalances[_marketingAddress] += fees.marketingFee;

            emit Transfer(from, _marketingAddress, fees.marketingFee);
        }

        if (fees.lpFee > 0) {
            _distributeLpFee(from, fees.lpFee + additionalToLp, false, poolInfo);
        }

        if (fees.reserveFee > 0) {
            _fixedBalances[reserveFeeAddress] += fees.reserveFee;
        }

        transferAmount =
            amount -
            fees.burnFee -
            fees.lpFee -
            fees.distributeFee -
            fees.marketingFee -
            fees.reserveFee;
    }

    function _makeSellAction(
        address _dexPairExilonWeth,
        address from,
        uint256 amount,
        bool isSellingBig,
        uint256 notFixedInternalTotalSupply
    ) private returns (uint256 transferAmount, FeesInfo memory fees) {
        if (!isExcludedFromPayingFees[from]) {
            uint256 multiplier;
            if (isHavingLowerCommissions[from]) {
                multiplier = 10;
            } else {
                multiplier = 100;
            }

            fees.burnFee = (amount * multiplier) / 10000;
            fees.marketingFee = (amount * 2 * multiplier) / 10000;

            fees.reserveFee = (amount * reserveFee * multiplier) / (10000 * 100);

            uint256 timeFromStart = block.timestamp - _startTimestamp;
            if (timeFromStart < 30 minutes) {
                if (isSellingBig) {
                    fees.lpFee = 16;
                } else {
                    fees.lpFee = 14;
                }
            } else if (timeFromStart < 60 minutes) {
                if (isSellingBig) {
                    fees.lpFee = 13;
                } else {
                    fees.lpFee = 11;
                }
            } else {
                if (isSellingBig) {
                    fees.lpFee = 10;
                } else {
                    fees.lpFee = 8;
                }
            }

            if (notFixedInternalTotalSupply == 0) {
                fees.lpFee = ((fees.lpFee + 1) * amount * multiplier) / 10000;
            } else {
                fees.lpFee = (fees.lpFee * amount * multiplier) / 10000;
                fees.distributeFee = (amount * multiplier) / 10000;
            }
        }

        uint256 additionalToLp;
        if (fees.burnFee > 0) {
            additionalToLp = _makeBurnAction(from, fees.burnFee);
        }

        if (fees.marketingFee > 0) {
            address _marketingAddress = marketingAddress;
            _fixedBalances[_marketingAddress] += fees.marketingFee;

            emit Transfer(from, _marketingAddress, fees.marketingFee);
        }

        if (fees.lpFee > 0) {
            PoolInfo memory poolInfo;
            poolInfo.dexPair = _dexPairExilonWeth;
            poolInfo.weth = _weth;
            _distributeLpFee(from, fees.lpFee + additionalToLp, false, poolInfo);
        }

        if (fees.reserveFee > 0) {
            _fixedBalances[reserveFeeAddress] += fees.reserveFee;
        }

        transferAmount =
            amount -
            fees.burnFee -
            fees.lpFee -
            fees.distributeFee -
            fees.marketingFee -
            fees.reserveFee;
    }

    function _makeTransferAction(
        address _dexPairExilonWeth,
        address from,
        address to,
        uint256 amount
    ) private returns (uint256 transferAmount, uint256 feeAmount) {
        if (isExcludedFromPayingFees[from] || isExcludedFromPayingFees[to]) {
            return (amount, 0);
        }

        if (Address.isContract(to)) {
            try IPancakePair(to).factory() returns (address) {
                // make sure
                try IPancakePair(to).token0() returns (address) {
                    revert("Not allowed creating new LP pairs of this token");
                } catch (bytes memory) {}
            } catch (bytes memory) {}
        }

        PoolInfo memory poolInfoExilon;
        poolInfoExilon.dexPair = _dexPairExilonWeth;
        poolInfoExilon.weth = _weth;
        poolInfoExilon = _getDexPairInfo(poolInfoExilon, address(this), false);

        PoolInfo memory poolInfoUsd;
        poolInfoUsd.dexPair = dexPairUsdWeth;
        poolInfoUsd.weth = poolInfoExilon.weth;
        poolInfoUsd = _getDexPairInfo(poolInfoUsd, usdAddress, false);

        uint256 amountWethNeeded = PancakeLibrary.getAmountIn(
            feeAmountInUsd,
            poolInfoUsd.wethReserves,
            poolInfoUsd.tokenReserves
        );
        feeAmount = PancakeLibrary.getAmountIn(
            amountWethNeeded,
            poolInfoExilon.tokenReserves,
            poolInfoExilon.wethReserves
        );

        require(amount > feeAmount, "Exilon: Small transfer amount (not more than fee)");
        transferAmount = amount - feeAmount;

        address _marketingAddress = marketingAddress;
        _fixedBalances[_marketingAddress] += feeAmount;

        emit Transfer(from, _marketingAddress, feeAmount);
    }
}