/**
 *Submitted for verification at FtmScan.com on 2021-11-28
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
* @dev
* Interface to access the Tier Configuration for Fantom Starter to see what Tier has
* what rights
**/
interface ITierConfigurationFantomStarter {

    /**
    * @dev
    * Get the pool weight multiplier
    **/
    function getPoolWeightMultiplier() external view returns (uint256);

    /**
    * @dev
    * Returns the length of all the TierConfigurationsIDsList
    **/
    function getTotalTierConfigurations() external view returns (uint256);

    /**
    * @dev
    * Get the Tier Allocation Rights By TierId
    **/
    function getTierAllocationRightsById(uint256 _tierId) external view returns (uint256);

    /**
    * @dev
    * Get the Tier Pool Weight By TierId
    **/
    function getTierPoolWeightByTierId(uint256 _tierId) external view returns (uint256);

    /**
    * @dev
    * Create a new Tier Configuration
    **/
    function createNewTierConfiguration(uint256 _tierId, bool _allocationRightsGuaranteed, uint256 _allocationRights, uint256 _poolWeight) external;

    /**
    * @dev
    * Check if allocation right for Tier by Id is guaranteed
    **/
    function checkIfTierAllocationRightsGuaranteedByTierId(uint256 _tierId) external view returns (bool);
}

/**
* @dev
* With the current system for chance based on tier I would suggest the following:
* - Total winner spots is decided upfront. (For example 1000 for this ICO)
* - Every tier has a weight for getting share of the total allocation.
* - Everyone with a tier and valid KYC can join the Lottery.
*
* Then the system:
* - Tier 5, 6, 7 all get guaranteed allocation. So for lottery there is TotalSpots - Tier 5,6,7 addresses that joined the lottery. (Remaining Winner Spots)
* - Based on tier an address gets its address added x times (amount of tickets) in the lottery.
* - There is a draw to fill the 'Remaining Winner Spots'
*
* In the end we have 1000 winning addresses (Total winner spots).
* And we have a total winners weight. Address * tier weight.
*
* * Then the IDO contract needs to have a formula to determine Cap per tier based on total-weight.
* For example total-weight is 2000.
* A person with tier 1 joins who has 1x weight. He would get allocation of TotalCap / 2000 (total-weight) * 1.
* A person with tier 3 joins who has 4x weight. He would get allocation of TotalCap / 2000 (total-weight) * 4.
**/
contract WingswapPrivateLotteryFantomStarter is AccessControl {
    using SafeMath for uint256;
    using Strings for string;

    ITierConfigurationFantomStarter public tierConfigurationFantomStarter;

    struct LotteryParticipant {
        bool initialized;
        address participant;
        uint256 tierId;
        uint256 tokenAllocation;
    }

    // Set to True if the lottery has been initialized
    bool lotteryInitialized = false;

    // Set to True if the calculation has been initialized
    bool calculationInitialized = false;
    bool calculationPoolWeightInitialized = false;

    // Initial seed and block number used to do the random number calculation
    uint256 public initialBlockNumber;
    uint256 public  initialSeed;

    uint256 public poolWeight;

    // Tokens to be distributed to the players
    uint256 public idoTokensForDistribution;

    // Max lottery winners
    uint256 public maximumLotteryWinners;

    // Lottery Winners list
    address [] public lotteryWinners;

    // Based on the tier, this pool contains the participants X times
    address[] public lotteryPoolOfParticipants;

    // LotteryParticipants and their Tier
    mapping(address => LotteryParticipant) public lotteryPoolOfParticipantsAndTierMapping;

    // Lottery winners by address and their struct
    mapping(address => LotteryParticipant) public lotteryWinnersAndTierMapping;

    // Events
    event participantAdded(address participant, uint256 tier, uint256 allocationRights);
    event winnerAdded(uint256 seed, uint256 blockNumber, address winner, uint256 tier);
    event setManualBlockNumber(address admin);
    event lotteryRun(address admin, uint256 seed);
    event calculationRun(address admin);

    constructor(ITierConfigurationFantomStarter _tierConfigurationFantomStarter,
        uint256 _maximumLotteryWinners, uint256 _idoTokensForDistribution) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        tierConfigurationFantomStarter = _tierConfigurationFantomStarter;
        maximumLotteryWinners = _maximumLotteryWinners;
        idoTokensForDistribution = _idoTokensForDistribution;
    }

    // Getters and Setters
    /**
    * @dev
    * Fake play the lottery because, if there are already max winners because of the guaranteed Tier. we do not actually
    * Play the lottery. Set the block number to 1
    **/
    function setBlockNumberAndDoNotPlayLottery() public isAdmin {
        initialBlockNumber = 1;

        emit setManualBlockNumber(msg.sender);
    }

    /**
    * @dev
    * Returns the maximum allowed participants in the lottery
    **/
    function getWinnerTokenAllocation(address _winner) public view returns (uint256 tokenAllocation) {
        return lotteryWinnersAndTierMapping[_winner].tokenAllocation;
    }

    /**
    * @dev
    * Returns the maximum allowed participants in the lottery
    **/
    function getMaximumLotteryWinners() public view returns (uint256 maxLotteryWinners) {
        return maximumLotteryWinners;
    }

    /**
    * @dev
    * Returns the lottery winners length of the array (if less people join in, the lottery winner pool is lower
    * than the expected maximum winners cap
    **/
    function getLotteryWinnersLength() public view returns (uint256 lotteryWinnersLength) {
        return lotteryWinners.length;
    }

    /**
    * @dev
    * Get random number
    **/
    function getRandomNumberBasedOnSeedAndBlockNumber(uint256 _seed, uint256 _blockNumber) public view returns (uint256 randomNumber) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(_blockNumber), _seed)));
    }

    // Checks
    /**
    * @dev
    * Check to see if the address already exists in the participants list
    **/
    function isAlreadyParticipating(address _participant) public view returns (bool isParticipating) {
        bool result = false;

        // Check to see if the address already is in the participating lotteryPoolOfParticipantsAndTierMapping
        // Remember, mappings are created for participants when they are added to the pool
        result = lotteryPoolOfParticipantsAndTierMapping[_participant].initialized;

        return result;
    }

    /**
    * @dev
    * Check to see if the address already exists in the winners list
    **/
    function isAlreadyWinner(address _participant) public view returns (bool isParticipating) {
        bool result = false;

        // Check to see if the address already is in the winners lotteryWinnersAndTierMapping
        // Remember, mappings are created for participants when they are added to the pool
        result = lotteryWinnersAndTierMapping[_participant].initialized;

        return result;
    }

    /**
    * @dev
    * Check if lottery has already been played
    **/
    function hasLotteryBeenPlayed() public view returns (bool hasBeenPlayed) {
        return lotteryInitialized;
    }

    /**
    * @dev
    * Check if token allocation calculation has been run
    **/
    function hasTokenAllocationCalculationBeenRun() public view returns (bool hasCalculationBeenRun) {
        return calculationInitialized;
    }

    // BusinessLogic
    /**
    * @dev
    * Add participants and their tier to the lottery
    **/
    function addParticipants(address[] memory _participants, uint256[] memory _participantTiers) public isAdmin {
        require(_participants.length == _participantTiers.length, "Check that every participant has a Tier");
        require(lotteryWinners.length < maximumLotteryWinners, "Already a full list of winners, pointless to add more participants if they cannot win");

        for (uint256 i = 0; i < _participants.length; i++) {
            // The participant should not already be a winner or participant.
            require(isAlreadyParticipating(_participants[i]) == false, Strings.append("User ", Strings.addressToAsciiString(_participants[i]), " is already participating", "", ""));
            require(isAlreadyWinner(_participants[i]) == false, Strings.append("User ", Strings.addressToAsciiString(_participants[i]), " is already a winner", "", ""));

            address _participant = _participants[i];
            uint256 _tierId = _participantTiers[i];

            // If the participants Tier is a guaranteed allocation Tier, add the user to the winners lotteryWinners List and Mapping
            if (tierConfigurationFantomStarter.checkIfTierAllocationRightsGuaranteedByTierId(_participantTiers[i])) {
                // Add the participant address to the lottery winners list and mapping
                lotteryWinners.push(_participants[i]);

                lotteryWinnersAndTierMapping[_participants[i]] = LotteryParticipant(true, _participant, _tierId, 0);

                // Emit event
                emit winnerAdded(0, 0, _participants[i], _participantTiers[i]);
            } else {
                // Participant is not a winner by default, add the participant to the participant pool
                // Add the participant x times to the participant lottery pool based on their allocation rights
                uint256 _allocationRights = tierConfigurationFantomStarter.getTierAllocationRightsById(_participantTiers[i]);

                for (uint256 j = 0; j < _allocationRights; j++) {
                    if (j == 0) {
                        // First time running the allocation for the participant, create the mapping
                        lotteryPoolOfParticipantsAndTierMapping[_participants[i]] = LotteryParticipant(true, _participant, _tierId, 0);
                    }

                    lotteryPoolOfParticipants.push(_participants[i]);

                    emit participantAdded(_participants[i], _participantTiers[i], _allocationRights);
                }
            }
        }
    }

    /**
    * @dev
    * Play lottery
    * TODO: Refactor this so it fits here...
    **/
    function playLottery(uint256 _seed) public isAdmin {
        require(initialBlockNumber == 0, "The lottery has already been played, winners already calculated");
        require(lotteryInitialized == false, "The lottery has already been played, winners already calculated");
        require(_seed > 0, "The seed cannot be zero");
        require(lotteryWinners.length < maximumLotteryWinners, "Already a full list of winners, pointless to play if they cannot win");

        lotteryInitialized = true;
        initialBlockNumber = block.number;
        initialSeed = _seed;

        uint256 _tmpBlockNumber = initialBlockNumber;
        uint256 _tmpSeed = initialSeed;

        address[] memory _tmpParticipants = lotteryPoolOfParticipants;

        /**
        * For each lottery winner, loop and find the winner!
        * The winner is based on the calculation
        *
        * Get the seed and calculate a random number from the seed and blockNumber
        * use the random number and modulo from the maximumLotteryWinners to find the index of the winner
        * If the winnerIndex already is a winner, then go to the next user, but max winners will be -1
        **/
        while (lotteryWinners.length < maximumLotteryWinners) {
            uint256 _maximumLotteryWinners = _tmpParticipants.length;
            if (_tmpParticipants.length <= 0) {
                _maximumLotteryWinners = maximumLotteryWinners;
            }

            for (uint256 i = 0; i < maximumLotteryWinners; i++) {

                //  "Already a full list of winners, pointless to add more if they cannot win"
                if (lotteryWinners.length >= maximumLotteryWinners || _tmpParticipants.length == 0) {
                    break;
                }

                // Get random participantIndex to add as a winner
                uint256 _randomNumber = getRandomNumberBasedOnSeedAndBlockNumber(_tmpSeed, _tmpBlockNumber);
                uint256 _participantIndexWhoWon = _randomNumber % _maximumLotteryWinners;
                address _winner = _tmpParticipants[_participantIndexWhoWon];

                // Remove the participant from the participants array

                // This participant has already been added as a Winner
                if (isAlreadyWinner(_winner) == true) {
                    _tmpSeed = _tmpSeed.add(1);
                    _tmpBlockNumber = _tmpBlockNumber.sub(1);

                    // If we already have this winner, try again for another user
                    delete _tmpParticipants[_participantIndexWhoWon];

                    continue;
                }

                // The participant has won, so add him to the winners list
                lotteryWinners.push(_winner);

                lotteryWinnersAndTierMapping[_winner] = LotteryParticipant(
                    true, _winner, lotteryPoolOfParticipantsAndTierMapping[_winner].tierId, 0
                );

                emit winnerAdded(_tmpSeed, _tmpBlockNumber, _winner, lotteryPoolOfParticipantsAndTierMapping[_winner].tierId);

                // Update the block and seed number for the next calculation of random number
                _tmpSeed = _tmpSeed.add(1);
                _tmpBlockNumber = _tmpBlockNumber.sub(1);
            }
        }

        emit lotteryRun(msg.sender, _seed);
    }

    /**
    * @dev
    * Add winners coming from the backend lottery,
    * UPDATE THIS CONTRACT AND ADD THE WINNERS
    **/
    function addWinners(address[] memory _winners, uint256[] memory _winnersTiers, uint256[] memory _winnersAllocation) public isAdmin {
        require(_winners.length == _winnersTiers.length, Strings.append("Check that every winner has a Tier. Winners: ", Strings.toString(_winners.length), " -- ", "Tiers: ", Strings.toString(_winnersTiers.length)));
        require(_winners.length == _winnersAllocation.length, Strings.append("Check that every winner has an allocation. Winners: ", Strings.toString(_winners.length), " -- ", "Tiers: ", Strings.toString(_winnersAllocation.length)));
        require(_winners.length <= maximumLotteryWinners, Strings.append("You cannot add more winners than: ", Strings.toString(maximumLotteryWinners), " -- ", "Trying to add: ", Strings.toString(_winners.length)));
        require(lotteryWinners.length.add(_winners.length) <= maximumLotteryWinners, Strings.append("Winner overflow!!1. Existing winners: ", Strings.toString(maximumLotteryWinners), " -- ", "Trying to add extra winners: ", Strings.toString(_winners.length)));

        // Fake play the lottery
        if (lotteryInitialized == false) {
            lotteryInitialized = true;
            initialBlockNumber = block.number;
            calculationPoolWeightInitialized = true;
            calculationInitialized = true;
        }

        for (uint256 i = 0; i < _winners.length; i++) {
            lotteryWinners.push(_winners[i]);
            // TODO: Set token Tier Allocation per tier instead of per user
            lotteryWinnersAndTierMapping[_winners[i]] = LotteryParticipant(true, _winners[i], _winnersTiers[i], _winnersAllocation[i]);
        }
    }

    /**
    * @dev
    * Calculate the allocation amount for all winners only after the lottery
    * 200.000 tokens for allocation
    * p1: 1x
    * p2: 1.5x
    * p3: 3.25x
    * p4: 1.5x
    * p5 2.25x
    * ------------ +
    * 1000 + 1500 + 3250 + 1500 + 2250 = 9500  (multiply the pool weight by a factor of _poolWeightMultiplier
    *
    * 200.000 / 9500 = 21 tokens.
    * 21 * pool weight per participant
    * 21 * 1000 = 21000
    * 21 * 1500 = 31500
    * 21 * 3250 = 68250
    * 21 * 1500 = 31500
    * 21 * 2250 = 47250
    * ------------------- +
    * 199500 (500 tokens decimal loss) because of the 21
    **/
    function calculatePoolWeightForWinners() public isAdmin {
        require(initialBlockNumber > 0, "Need to play the lottery first before we can calculate the token allocation");
        require(calculationPoolWeightInitialized == false, "Calculation already has been run");

        calculationPoolWeightInitialized = true;

        // for each winner, calculate the tokens for Allocation
        for (uint8 i = 0; i < lotteryWinners.length; i++) {
            uint256 _tierId = lotteryWinnersAndTierMapping[lotteryWinners[i]].tierId;
            poolWeight = poolWeight.add(tierConfigurationFantomStarter.getTierPoolWeightByTierId(_tierId));
        }
    }

    // 9980000 max gas price
    function calculateTokenAllocationAmountForWinners() public isAdmin {
        require(initialBlockNumber > 0, "Need to play the lottery first before we can calculate the token allocation");
        require(calculationInitialized == false, "Calculation already has been run");
        require(calculationPoolWeightInitialized == true, "Calculate Pool Weight first");

        calculationInitialized = true;

        // for each winner, calculate the tokens for Allocation
        for (uint8 i = 0; i < lotteryWinners.length; i++) {

            uint256 _tierId = lotteryWinnersAndTierMapping[lotteryWinners[i]].tierId;
            uint256 _winnerPoolWeight = tierConfigurationFantomStarter.getTierPoolWeightByTierId(_tierId);
            uint256 _tokensForAllocation = idoTokensForDistribution.div(poolWeight).mul(_winnerPoolWeight);

            lotteryWinnersAndTierMapping[lotteryWinners[i]].tokenAllocation = _tokensForAllocation;
        }

        emit calculationRun(msg.sender);
    }
}