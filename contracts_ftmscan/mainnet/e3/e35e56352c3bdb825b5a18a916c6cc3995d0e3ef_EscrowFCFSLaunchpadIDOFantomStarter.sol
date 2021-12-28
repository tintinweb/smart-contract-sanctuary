/**
 *Submitted for verification at FtmScan.com on 2021-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

/**
 * @dev String operations.
 * Enhanced Strings library by FantomStarter
 * Added concatenation
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
    * @dev
    * Added by FantomStarter
    * Concatenation for string types
    **/
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

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

    /**
    * @dev
    * Convert address to string
    **/
    function addressToAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Account is not in the admin list");
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

    function mintToken(address account, uint256 amount) external;

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

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

}

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
* @dev
* Interface to access the Whitelist
**/
interface IWhitelistWithFantomPass  {

    /**
    * @dev Returns the length of the whitelisted addresses
    **/
    function getWhitelistedAddressesCount() external view returns (uint count);

    /**
    * @dev Check if address is whitelisted
    **/
    function isWhitelisted(address _address) external view returns (bool);

    /**
    * @dev
    * Check if lottery has already been played
    **/
    function hasLotteryBeenPlayed() external view returns (bool hasBeenPlayed);

    /**
    * @dev
    * Check to see if the address already exists in the winners list
    **/
    function isAlreadyWinner(address _participant) external view returns (bool isParticipating);

    /**
    * @dev
    * Returns the maximum allowed participants in the lottery
    **/
    function getWinnerTokenAllocation(address _winner) external view returns (uint256 tokenAllocation);

    /**
    * @dev
    * Returns the lottery winners length of the array (if less people join in, the lottery winner pool is lower
    * than the expected maximum winners cap
    **/
    function getLotteryWinnersLength() external view returns (uint256 lotteryWinnersLength);
}



/**
* The LaunchpadFantomStarter for the IDO FantomStarter
**/
contract EscrowFCFSLaunchpadIDOFantomStarter is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // Token to be sold
    IERC20Metadata public idoToken;
    // Token in which payments can be done
    IERC20Metadata public payToken;
    // Whitelisted users
    IWhitelistWithFantomPass public whitelistedAddress;

    // The Initial sale token price
    // Price of idoToken in payToken value based on ratio
    uint256 public idoTokenPriceRatio;  // If the ido is 0.5 paytoken worth, then this would be 0,5 * 10_000 = 5_000
    // The ratio for the token
    uint256 public idoTokenPriceMultiplier = 10_000;
    // Max IDO token allocation
    uint256 public maxIdoTokenAllocation;

    // Initial Allocation on Ido Tokens, if 0, then there is no initial allocation
    uint256 public initialPercentageAllocationIdoTokens;

    // Spend Pay Count
    uint256 public totalSpendPayTokens = 0;
    // Sold tokens count
    uint256 public totalAllocatedIdoTokens = 0;
    // Total amount of tokens to be sold, is Set at the funding
    uint256 public tokensForSale = 0;

    // Investors count
    uint256 public investorCount = 0;

    // Start and End date for the eligible addresses to buy their tokens/funds
    uint256 public startDateFunding;
    uint256 public endDateFunding;

    // End date until when token can be claimed, calculation will be done based on how long until end date
    uint256 public startDateOfClaimingTokens;
    uint256 public endDateOfClaimingTokens;

    // If the IDO token has been funded to the contract
    bool public isIdoTokenFundedToContract = false;
    // To keep track of the ido Cancellation
    bool public isFundingCanceled = false;
    // Enables the payment only to be in one transaction
    bool public inOneTransaction = false;
    // Enable claiming
    bool public isClaimingOpen = false;

    // Array to keep track of all the buyers
    address[] public buyersList;
    // Mapping to keep track of how many pay tokens have been spend by the byer
    mapping(address => uint256) public spendPayTokensMapping;
    // Mapping to keep tack of how many IDO tokens the buyer should get
    mapping(address => uint256) public idoTokensToGetMapping;
    // Mapping to keep tack of how many IDO tokens the buyer has claimed
    mapping(address => uint256) public idoTokensClaimedMapping;
    // Mapping to keep track if the buyer has claimed the pay tokens spend on IDO cancel
    mapping(address => bool) public hasClaimedPayTokensMapping;

    // Events
    event BoughtIDOTokens(address buyer, uint256 spendPayTokens, uint256 idoTokensToGet, uint256 timestamp);
    event ClaimedIDOTokens(address buyer, uint256 idoTokensToGet);

    // Logging
    event ChangedEndDateOfClaimingTokens(address admin, uint256 oldEndDateOfClaimingTokens, uint256 endDateOfClaimingTokens);
    event ChangedIsClaimingOpen(address admin, bool oldIsClaimingOpen, bool isClaimingOpen);
    event ChangedInitialPercentageAllocationIdoTokens(address admin, uint256 oldInitialPercentageAllocationIdoTokens, uint256 initialPercentageAllocationIdoTokens);
    event ChangedMaxIdoTokenAllocation(address admin, uint256 oldMaxIdoTokenAllocation, uint256 maxIdoTokenAllocation);

    constructor(
        IERC20Metadata _idoToken,
        IERC20Metadata _payToken,
        IWhitelistWithFantomPass _whitelistedAddress,
        uint256 _idoTokenPriceRatio,
        uint256 _startDateFunding,
        uint256 _endDateFunding,
        uint256 _endDateOfClaimingTokens,
        uint256 _claimingInitialPercentage,
        uint256 _maxIdoTokenAllocation,
        bool _inOneTransaction
    ) {
        /* Confirmations */
        require(_startDateFunding < _endDateFunding, "The starting date of the funding should be before the end date of the funding");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        idoToken = _idoToken;
        payToken = _payToken;
        whitelistedAddress = _whitelistedAddress;

        // Set initial sale token price
        idoTokenPriceRatio = _idoTokenPriceRatio;
        idoTokenPriceMultiplier = 10_000;

        // Set starting and ending dates of funding
        startDateFunding = _startDateFunding;
        endDateFunding = _endDateFunding;

        // Tokens to be claimed until, calculation based on this end date
        endDateOfClaimingTokens = _endDateOfClaimingTokens;

        // Set total IDO tokens for allocation
        maxIdoTokenAllocation = _maxIdoTokenAllocation;

        // If set to true, the IDO tokens need to be payed in one transaction
        inOneTransaction = _inOneTransaction;

        // Set initial Claiming Percentage
        setInitialPercentageAllocationIdoTokens(_claimingInitialPercentage);

        // Default value, until funds have been made
        isIdoTokenFundedToContract = false;
    }

    // MODIFIERS
    /**
    * @dev
    * Modifier used to check if the msg.sender is whitelisted
    **/
    modifier onlyWhitelisted() {
        require(whitelistedAddress.isWhitelisted(msg.sender), "The buyer is not whitelisted");
        _;
    }

    /**
    * @dev Modifier used to check if the contract has been funded enough sale tokens
    **/
    modifier isIdoTokenFunded() {
        require(isIdoTokenFundedToContract, "The contract did not receive the IDO tokens");
        _;
    }

    /**
    * @dev Modifier used to check if the Funding period is open
    **/
    modifier isFundingOpenAndRunning() {
        require(isFundingOpen(), "The Funding Period is not Open");
        _;
    }

    /**
    * @dev Modifier used to check if the Funding has ended
    **/
    modifier isFundingClosed() {
        require(isFundingEnded(), "The Funding Period has not ended");
        _;
    }

    /**
    * @dev Modifier to keep track if the Funding has been canceled
    **/
    modifier isFundingCanceledByAdmin() {
        require(isFundingCanceled == true, "Funding has not been canceled");
        _;
    }

    /**
    * @dev Modifier to keep track if the Funding has been canceled
    **/
    modifier isFundingNotCanceledByAdmin() {
        require(isFundingCanceled == false, "Funding has been canceled");
        _;
    }

    // Getters and Setters
    /**
    * @dev
    * Change the amount in pay tokens per wallet
    **/
    function setMaxIdoTokenAllocation(uint256 _maxIdoTokenAllocation) external isAdmin {
        require(isClaimingOpen == false, "Claiming is already enabled");
        require(_maxIdoTokenAllocation > 0, "The IDO token allocation should be greater than zero");

        uint256 _oldMaxIdoTokenAllocation = maxIdoTokenAllocation;

        maxIdoTokenAllocation = _maxIdoTokenAllocation;

        emit ChangedMaxIdoTokenAllocation(msg.sender, _oldMaxIdoTokenAllocation, _maxIdoTokenAllocation);
    }

    /**
    * @dev
    * Change the initial percentage of token allocation to be claimed
    **/
    function setInitialPercentageAllocationIdoTokens(uint256 _percentage) public isAdmin {
        require(isClaimingOpen == false, "Claiming is already enabled");
        require(_percentage <= 100, "You cannot give more than 100 percent of the token allocation");

        uint256 _oldInitialPercentageAllocationIdoTokens = initialPercentageAllocationIdoTokens;

        initialPercentageAllocationIdoTokens = _percentage;

        emit ChangedInitialPercentageAllocationIdoTokens(msg.sender, _oldInitialPercentageAllocationIdoTokens, _percentage);
    }

    /**
    * @dev
    * Set if the claiming is enabled or not
    **/
    function enableClaiming(bool _isClaimingOpen, uint256 _startDateOfClaimingTokens) external isAdmin {
        bool _oldIsClaimingOpen = isClaimingOpen;

        isClaimingOpen = _isClaimingOpen;
        startDateOfClaimingTokens = _startDateOfClaimingTokens;

        emit ChangedIsClaimingOpen(msg.sender, _oldIsClaimingOpen, isClaimingOpen);
    }

    /**
    * @dev
    * Set the end date for tokens to be claimed by all buyers
    **/
    function setEndDateOfClaimingTokens(uint256 _endDateOfClaimingTokens) external isAdmin {
        require(isClaimingOpen == false, "Claiming is already enabled");

        uint256 _oldEndDateOfClaimingTokens = endDateOfClaimingTokens;

        endDateOfClaimingTokens = _endDateOfClaimingTokens;

        emit ChangedEndDateOfClaimingTokens(msg.sender, _oldEndDateOfClaimingTokens, endDateOfClaimingTokens);
    }

    /**
    * @dev Returns a list of all buyers (wallet addresses)
    **/
    function getBuyers() external view returns (address[] memory) {
        return buyersList;
    }

    /**
    * @dev
    * Returns boolean of the wallet address when he is a buyer or not
    **/
    function isBuyer(address _buyer) public view returns (bool buyer) {
        for (uint256 i = 0; i < buyersList.length; i++) {
            if (buyersList[i] == _buyer) {
                return true;
            }
        }

        return false;
    }

    /**
    * @dev Get the available IDO Tokens
    **/
    function availableIdoTokens() public view returns (uint256) {
        return idoToken.balanceOf(address(this));
    }

    /**
    * @dev Get the balance of Payed Pay Tokens
    **/
    function payTokensSpend() external view returns (uint256) {
        return payToken.balanceOf(address(this));
    }

    /**
    * @dev Get total tokens bought by msg.sender, and total tokens spent
    **/
    function getTotalIdoTokensBoughtAndPayTokensSpend(address _buyer) external view returns (uint256 idoTokens, uint256 payTokens) {
        require(whitelistedAddress.isWhitelisted(_buyer), "Wallet is not whitelisted");

        uint256 _totalBoughtIdoTokens = idoTokensToGetMapping[_buyer];
        uint256 _totalSpendPayTokens = spendPayTokensMapping[_buyer];

        return (_totalBoughtIdoTokens, _totalSpendPayTokens);
    }

    /**
    * @dev Get total tokens bought, and total tokens spent
    **/
    function getTotalIdoTokensBoughtAndPayTokensSpend() external view returns (uint256 idoTokens, uint256 payTokens) {
        uint256 _receiptTotalAmountBoughtIdoTokens = 0;
        uint256 _receiptTotalAmountSpendPayTokens = 0;

        for (uint i = 0; i < buyersList.length; i++) {
            address _buyer = buyersList[i];
            _receiptTotalAmountBoughtIdoTokens = _receiptTotalAmountBoughtIdoTokens.add(idoTokensToGetMapping[_buyer]);
            _receiptTotalAmountSpendPayTokens = _receiptTotalAmountSpendPayTokens.add(spendPayTokensMapping[_buyer]);
        }

        return (_receiptTotalAmountBoughtIdoTokens, _receiptTotalAmountSpendPayTokens);
    }

    /**
    * @dev
    * Returns back the pay token amount to buy the entire allocation in one Transaction
    **/
    function getPaymentForEntireAllocation(address _buyer) external view returns (uint256 payTokensAmount) {
        require(whitelistedAddress.isWhitelisted(_buyer), "Wallet is not whitelisted");

        return calculateMaxPaymentToken(whitelistedAddress.getWinnerTokenAllocation(_buyer));
    }

    /**
    * @dev
    * Returns the claimable tokens at this point in time
    **/
    function getClaimableTokens(address _buyer) external view returns (uint256 claimableTokens) {
        require(whitelistedAddress.isWhitelisted(_buyer), "Wallet is not whitelisted");

        uint256 result = 0;

        uint256 _secondsInTotalBetweenStartAndEndDateClaimingTokens = endDateOfClaimingTokens.sub(startDateOfClaimingTokens);
        uint256 _idoTokensPerSecond = idoTokensToGetMapping[msg.sender].div(_secondsInTotalBetweenStartAndEndDateClaimingTokens);

        uint256 _totalTokensToGet = 0;

        // If the current time already surpassed the endDateOfClaimingTokens, allocation all tokens and subtract how much
        // already have been claimed
        if (block.timestamp >= endDateOfClaimingTokens) {
            _totalTokensToGet = idoTokensToGetMapping[_buyer];
        } else if (initialPercentageAllocationIdoTokens > 0) {
            // It looks like there is an Initial Ido allocation percentage.
            // Calculate the _totalTokensToGet with this percentage
            uint256 _initialTokensToGet = calculateIdoTokensBought(spendPayTokensMapping[_buyer]).div(100).mul(initialPercentageAllocationIdoTokens);

            if (block.timestamp >= startDateOfClaimingTokens) {
                // Remove the initial tokes to get from the total supply tokens to get percentage
                _idoTokensPerSecond = idoTokensToGetMapping[_buyer].sub(_initialTokensToGet).div(_secondsInTotalBetweenStartAndEndDateClaimingTokens);

                // Calculate how many tokens to get since startDateOfClaimingTokens
                uint256 _secondsPassedSinceStart = block.timestamp.sub(startDateOfClaimingTokens);
                _totalTokensToGet = _idoTokensPerSecond.mul(_secondsPassedSinceStart);
            }

            // Add the initial tokens to get to the tokens that can be claimed
            _totalTokensToGet = _totalTokensToGet.add(_initialTokensToGet);
        } else {
            // End date has not yet been reached
            uint256 _secondsPassedSinceStart = block.timestamp.sub(startDateOfClaimingTokens);
            _totalTokensToGet = _idoTokensPerSecond.mul(_secondsPassedSinceStart);
        }

        // Subtract previous already claimed tokens
        result = _totalTokensToGet.sub(idoTokensClaimedMapping[_buyer]);

        return result;
    }

    // Checks
    /**
    * @dev Check if the Funding has started ans has not ended
    **/
    function isFundingOpen() public view returns (bool isOpen) {
        return block.timestamp >= startDateFunding && block.timestamp <= endDateFunding;
    }

    /**
    * @dev Check if the current date is pre-funding
    **/
    function isPreStartFunding() external view returns (bool isPreStart){
        return block.timestamp < startDateFunding;
    }

    /**
    * @dev Check if the Funding period has ended
    **/
    function isFundingEnded() public view returns (bool isClosed){
        return block.timestamp > endDateFunding;
    }

    /**
    * @dev Check to see if the wallet has enough Pay Tokens to spend
    **/
    function hasWalletEnoughPayTokens(address _wallet, uint256 _requiredTokens) public view returns (bool hasEnoughPayTokens) {
        bool result = false;

        // Check if the balance of the _wallet has at least the required tokens.
        if (payToken.balanceOf(_wallet) >= _requiredTokens) {
            result = true;
        }

        return result;
    }

    /**
    * @dev
    * Check if the contract has sold out all IDO tokens
    **/
    function isSoldOut() external view returns (bool soldOut) {
        bool result = false;

        if (totalAllocatedIdoTokens >= maxIdoTokenAllocation) {
            result = true;
        }

        return result;
    }

    // BusinessLogic
    /**
    * @dev
    * Calculates how much Payment tokens you need to spend to acquire the exact IDO token allocation
    **/
    function calculateMaxPaymentToken(uint256 _idoTokensToGet) public view returns (uint256 maxPaymentTokens) {
        /**
         _amountInPayToken = _amountInPayToken.mul(idoTokenPriceMultiplier); // 250_000_000 * 10_000 = 2.500.000.000.000

        uint256 _divideByRatio = idoTokenPriceRatio.mul(10 ** uint256(payToken_decimals()).sub(2)); 38 * 100_000 = 3.800.000

        uint256 _idoTokensToGet = _amountInPayToken.div(_divideByRatio); 2.500.000.000.000 /  3.800.000 = 657.894,7368421053

        _idoTokensToGet = _idoTokensToGet.mul(10 ** uint256(idoToken_decimals()).sub(2)); 657.894,7368421053 * 100_000_000_000_000_000 = 65789_470_000_000_000_000_000

        **/

        _idoTokensToGet = _idoTokensToGet.div(10 ** uint256(idoToken.decimals()).sub(2)); // 65789_470_000_000_000_000_000 / 100_000_000_000_000_000 = 657.894,7368421053

        uint256 _divideByRatio = idoTokenPriceRatio.mul(10 ** uint256(payToken.decimals()).sub(2)); // 38 * 100_000 = 3.800.000

        uint256 _amountInPayToken = _idoTokensToGet.mul(_divideByRatio);  // 657.894,7368421053 *  3.800.000 = 2.500.000.000.000

        _amountInPayToken = _amountInPayToken.div(idoTokenPriceMultiplier); // 2.500.000.000.000 / 10_000 = 250_000_000 USDC tokens

        return _amountInPayToken;
    }

    /**
    * @dev Logic to calculate the amount of Ido Tokens bought
    **/
    function calculateIdoTokensBought(uint256 _amountInPayToken) public view returns (uint256 idoTokensBought) {
        /**
         _amountInPayToken = _amountInPayToken.mul(idoTokenPriceMultiplier); // 250_000_000 * 10_000 = 2.500.000.000.000

        uint256 _divideByRatio = idoTokenPriceRatio.mul(10 ** uint256(payToken_decimals()).sub(2)); 38 * 100_000 = 3.800.000

        uint256 _idoTokensToGet = _amountInPayToken.div(_divideByRatio); 2.500.000.000.000 /  3.800.000 = 657.894,7368421053

        _idoTokensToGet = _idoTokensToGet.mul(10 ** uint256(idoToken_decimals()).sub(2)); 657.894,7368421053 * 100_000_000_000_000_000 = 65789_470_000_000_000_000_000

        **/

        _amountInPayToken = _amountInPayToken.mul(idoTokenPriceMultiplier);

        uint256 _divideByRatio = idoTokenPriceRatio.mul(10 ** uint256(payToken.decimals()).sub(2));

        uint256 _idoTokensToGet = _amountInPayToken.div(_divideByRatio);

        _idoTokensToGet = _idoTokensToGet.mul(10 ** uint256(idoToken.decimals()).sub(2));

        return _idoTokensToGet;
    }

    /**
    * @dev Give the contractAddress the ido tokens to be sold
    **/
    function fundToContract(uint256 _amountInIdoTokens) external isAdmin isFundingClosed isFundingNotCanceledByAdmin {
        require(isIdoTokenFundedToContract == false, "Already funded tokens");
        require(totalAllocatedIdoTokens <= _amountInIdoTokens, "You should at least match the totalAllocatedIdoTokens");
        require(idoToken.balanceOf(msg.sender) >= _amountInIdoTokens, "The msg.sender does not have enough tokens to fund to the contract");

        // Transfer Funds
        require(idoToken.transferFrom(msg.sender, address(this), _amountInIdoTokens), "Failed sale token to be transferred to the contract");

        /* If Amount is equal to needed - sale is ready */
        tokensForSale = _amountInIdoTokens;
        isIdoTokenFundedToContract = true;
    }

    /**
    * @dev Buy Tokens, but not really, just transfer the payment tokens to the Contract and create a receipt that
    * can later be claimed by the buyer
    **/
    function buy(uint256 _amountInPayToken) external isFundingOpenAndRunning isFundingNotCanceledByAdmin onlyWhitelisted {
        require(_amountInPayToken > 0, "Amount has to be positive");
        require(hasWalletEnoughPayTokens(msg.sender, _amountInPayToken) == true, "msg.sender has not enough payment tokens");
        require(calculateIdoTokensBought(_amountInPayToken) <= whitelistedAddress.getWinnerTokenAllocation(msg.sender), "You cannot spend more tokens than is allowed");
        require(spendPayTokensMapping[msg.sender].add(_amountInPayToken) <= calculateMaxPaymentToken(whitelistedAddress.getWinnerTokenAllocation(msg.sender)), "You cannot buy more tokens than is allowed according to your allocation");
        require(totalAllocatedIdoTokens.add(calculateIdoTokensBought(_amountInPayToken)) <= maxIdoTokenAllocation, "No more IDO tokens left");

        if (inOneTransaction) {
            require(_amountInPayToken >= calculateMaxPaymentToken(whitelistedAddress.getWinnerTokenAllocation(msg.sender)), "You need to buy your entire allocation in one transaction");
        }

        uint256 _idoTokensToBuy = calculateIdoTokensBought(_amountInPayToken);

        // Since this is the first purchase and there are no receipts, add the address to the investor counter
        if (spendPayTokensMapping[msg.sender] == 0) {
            investorCount = investorCount.add(1);
        }

        // First Get paid in pay tokens
        require(payToken.transferFrom(msg.sender, address(this), _amountInPayToken), "Payment not completed in PayTokens");
        totalSpendPayTokens = totalSpendPayTokens.add(_amountInPayToken);
        totalAllocatedIdoTokens = totalAllocatedIdoTokens.add(_idoTokensToBuy);

        spendPayTokensMapping[msg.sender] = spendPayTokensMapping[msg.sender].add(_amountInPayToken);
        idoTokensToGetMapping[msg.sender] = idoTokensToGetMapping[msg.sender].add(_idoTokensToBuy);

        if (!isBuyer(msg.sender)) {
            buyersList.push(msg.sender);
        }

        emit BoughtIDOTokens(msg.sender, _amountInPayToken, _idoTokensToBuy, block.timestamp);
    }

    /**
    * @dev After the Funding period, users are allowed to claim their IDO Tokens
    **/
    function claimTokens() external isFundingClosed isFundingNotCanceledByAdmin {
        require(isIdoTokenFundedToContract == true, "Tokens have not been added to the contract YET");
        require(idoTokensClaimedMapping[msg.sender] < idoTokensToGetMapping[msg.sender], "You have already claimed the tokens");
        require(isClaimingOpen == true, "Cannot claim, you need to wait until claiming is enabled");
        require(isBuyer(msg.sender) == true, "You are not a buyer");

        uint256 _secondsInTotalBetweenStartAndEndDateClaimingTokens = endDateOfClaimingTokens.sub(startDateOfClaimingTokens);
        uint256 _idoTokensPerSecond = idoTokensToGetMapping[msg.sender].div(_secondsInTotalBetweenStartAndEndDateClaimingTokens);

        uint256 _totalTokensToGet = 0;

        // If the current time already surpassed the endDateOfClaimingTokens, allocation all tokens and subtract how much
        // already have been claimed
        if (block.timestamp >= endDateOfClaimingTokens) {
            _totalTokensToGet = idoTokensToGetMapping[msg.sender];
        } else if (initialPercentageAllocationIdoTokens > 0) {
            // It looks like there is an Initial Ido allocation percentage.
            // Calculate the _totalTokensToGet with this percentage
            uint256 _initialTokensToGet = calculateIdoTokensBought(spendPayTokensMapping[msg.sender]).div(100).mul(initialPercentageAllocationIdoTokens);

            if (block.timestamp >= startDateOfClaimingTokens) {
                // Remove the initial tokes to get from the total supply tokens to get percentage
                _idoTokensPerSecond = idoTokensToGetMapping[msg.sender].sub(_initialTokensToGet).div(_secondsInTotalBetweenStartAndEndDateClaimingTokens);

                // Calculate how many tokens to get since startDateOfClaimingTokens
                uint256 _secondsPassedSinceStart = block.timestamp.sub(startDateOfClaimingTokens);
                _totalTokensToGet = _idoTokensPerSecond.mul(_secondsPassedSinceStart);
            }

            // Add the initial tokens to get to the tokens that can be claimed
            _totalTokensToGet = _totalTokensToGet.add(_initialTokensToGet);
        } else {
            // End date has not yet been reached
            uint256 _secondsPassedSinceStart = block.timestamp.sub(startDateOfClaimingTokens);
            _totalTokensToGet = _idoTokensPerSecond.mul(_secondsPassedSinceStart);
        }

        // Subtract previous already claimed tokens
        _totalTokensToGet = _totalTokensToGet.sub(idoTokensClaimedMapping[msg.sender]);

        // Transfer the idoTokens to the msg.sender from the contract
        require(idoToken.transfer(msg.sender, _totalTokensToGet), "Transfer the idoToken to the msg.sender");

        // Update mapping
        idoTokensClaimedMapping[msg.sender] = idoTokensClaimedMapping[msg.sender].add(_totalTokensToGet);

        emit ClaimedIDOTokens(msg.sender, _totalTokensToGet);
    }

    /**
    * @dev Withdraw Pay Tokens from contract
    * Only withdraw Pay tokens after the funding has ended
    **/
    function withdrawPayTokens(address _owner, uint256 _payTokensToWithdraw) external isAdmin isFundingClosed {
        require(payToken.transfer(_owner, _payTokensToWithdraw), "Transferred Pay Tokens not completed");
    }

    /**
    * @dev Withdraw the unsold idoTokens
    **/
    function withdrawUnsoldIdoTokens(address _owner, uint256 _idoTokensToWithdraw) external isAdmin isFundingClosed {
        require(availableIdoTokens() > 0, "The contract has no IDO tokens left");
        require(idoToken.transfer(_owner, _idoTokensToWithdraw), "Transferred Sale Tokens not completed");
    }

    /**
    * @dev Cancels the entire sale and returns all the tokens payed back to the owner
    * Can be canceled at any time
    **/
    function cancelIdoSale() external isAdmin {
        isFundingCanceled = true;
    }

    /**
    * @dev Let user claim his payed tokens
    **/
    function claimPayedTokensOnIdoCancel() external isFundingCanceledByAdmin {
        require(hasClaimedPayTokensMapping[msg.sender] == false, "You have been refunded already");

        uint256 _payTokensToReturn = spendPayTokensMapping[msg.sender];

        require(payToken.transfer(msg.sender, _payTokensToReturn), "Transfer the payToken to the buyer has failed");

        // Set mapping to claimed tokens to True
        hasClaimedPayTokensMapping[msg.sender] = true;
    }
}