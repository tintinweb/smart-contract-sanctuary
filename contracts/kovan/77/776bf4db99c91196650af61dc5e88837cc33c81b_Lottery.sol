/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}


// File @chainlink/contracts/src/v0.8/[email protected]

pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


// File @chainlink/contracts/src/v0.8/[email protected]

pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File contracts/Lottery.sol

pragma solidity 0.8.7;




// chainlink goodies


/*
 * @interface IUniswapV2Factory
 *
 *
 *
 */
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

/*
 * @interface IUniswapV2Pair
 *
 *
 *
 */
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

/*
 * @interface IUniswapV2Router01
 *
 *
 *
 */
interface IUniswapV2Router01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/*
 * @interface IUniswapV2Router02
 *
 *
 *
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract Lottery is AccessControl, VRFConsumerBase {

    event Winner(address indexed winner, string winType);
    event Payout(address winner, uint amount);
    event winnerDrawn (uint[6] ticket, uint epoch);
    event TicketBought(address indexed user, uint[6] ticket, uint amount);
    event LotteryStarted(uint openTime);
    event SwapETHForTokens(uint256 amountIn, address[] path);

    using SafeMath for uint;
    using SafeMath for int256;

    using Counters for Counters.Counter;
    /**
        @dev powerball split percentages
     */
    Counters.Counter public ticketCount;
    Counters.Counter public winnerCount;
    Counters.Counter public userCount;

    address vicexToken;
    IERC20 vicex;
    IERC20 link;

    address public immutable deadAddress =
        0x000000000000000000000000000000000000dEaD;
    address public dexAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2FACTORY;
    address public uniswapV2Pair;

    address public dev; // dev wallet
    address public viceRwards;

    // lotto start end and delta time
    uint public startTime;
    uint public epoch;
    uint public startOffset;
    uint public lotteryLength = 3600;
    // lotto state
    bool public open;
    bool processing;

    uint public ticketPrice = 3; // ether

    uint public pb = 110;
    uint public pbOne = 55;
    uint public pbTwo = 12;
    uint public noPbThree = 13;
    uint public pbThree = 11;
    uint public noPbFour = 11;
    uint public pbFour = 22;
    uint public noPbFive = 86;
    uint public jackpot = 600;

    address[] winnersPb;
    address[] winnersPbOne;
    address[] winnersPbTwo;
    address[] winnersNoPbThree;
    address[] winnersPbThree;
    address[] winnersNoPbFour;
    address[] winnersPbFour;
    address[] winnersnoPbFive;
    address[] winnersJackpot;

    uint public reserve = 80;   // reserve to fund next prize pool

    uint public opsFee = 50;   // marketing wallet
    uint public lFee = 100; // liquidity fee
    uint public affiliateFee = 250;

    uint public n = 1000;   // normalizer

    mapping (address => uint[6][]) tickets;

    address[] users;
    mapping (address => uint) balances;
    /**
        @dev Create the admin role, with `root` as a member.
        @dev link, coordinator, price feed, vicex address all needed for chainlink in production
    */

    // min amount of vicex in contract before an LP swap
    uint256 public swapThreshold = 250000000000 * (10**9);

    bool public swapEnabled = true;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint[] public winningTicket;

    AggregatorV3Interface internal priceFeed;

    // VRFConsumerBase(VRFCoordinator, LINK token address)
    constructor (address _dev) VRFConsumerBase(0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, 0xa36085F69e2889c224210F603D836748e7dC0088) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        link = IERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);        // chainlink LINK  Setup

        vicexToken = 0xEB4383b41040e1cF62A49b79E7c00A9bC74FC773;    // kovan
        // LP setup
        vicex = IERC20(vicexToken);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(dexAddress);   // uniswap router (Mainnet & Kovan)
        uniswapV2FACTORY = IUniswapV2Factory(_uniswapV2Router.factory());

        // set Router for use by utility functions
        uniswapV2Router = _uniswapV2Router;
        
        /*  ETH/USD Pricefeed Setup
         *
         *  Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         *  Rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
         *  Kovan: 0x9326BFA02ADD2366b30bacB125260Af641031331
         *
         *  Select appropriate address for pricefeedAggregator
         */
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        /*
         *
         *
         *  MAINNET
         *  LINK Token Address:  0x514910771AF9Ca656af840dff83E8264EcF986CA
         *  VRF Coordinator: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
         *  Key Hash:    0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
         *  Fee: 2 LINK
         *
         *  KOVAN
         *  LINK Token Address:  0xa36085F69e2889c224210F603D836748e7dC0088
         *  VRF Coordinator: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
         *  Key Hash:    0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
         *  Fee: 0.1 LINK
         *
         *  RINKEBY
         *  LINK Token Address:  0x01BE23585060835E02B77ef475b0Cc51aA1e0709
         *  VRF Coordinator: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
         *  Key Hash:    0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
         *  Fee: 0.1 LINK
         *
         *
         *
         *
         */
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4; // rinkeby specific
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        
        // dev wallet
        dev = _dev;
        // initial conditions
        open = false;
        epoch = 0;

    }
    /**
     * Returns the latest price
     */
    function getLatestPrice() internal view returns (int) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getTicketPrice() public view returns (uint) {
        // pricefeeds are 10^8 based
        uint price = uint(getLatestPrice()); 
        price = price / 10 ** 8;
        return ticketPrice * (10 ** 18) / price;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(link.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    
    function getWinningTicketLength() public view returns (uint) {
        return winningTicket.length;
    }

    // draw
    function draw() public {
        require(open, "lottery is closed");
        require(startTime + lotteryLength <= block.timestamp, 'sale is ongoing');
        // set open to false while winners are found
        open = false;
        
        for (uint i = 0; i < 7; i++) {
            getRandomNumber();
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // time require
        // check if powerball
        uint randomNumber;
        if (winningTicket.length < 5 ) {
            randomNumber = randomness.mod(69).add(1);
            winningTicket.push(randomNumber);
        } 
        else if (winningTicket.length == 5 ) {
            randomNumber = randomness.mod(26).add(1);
            winningTicket.push(randomNumber);
        }
    }

    function getTicketCount () view external returns (uint) {
        return ticketCount.current();
    }

    function getWinnerCount () view external returns (uint) {
        require(!processing, "Calculating winners, try again later");
        return winnerCount.current();
    }

    function getUserTicketCount () view external returns (uint) {
        return tickets[msg.sender].length;
    }

    function getUserTickets () view external returns (uint[6][] memory) {
        require(open, 'lotto is closed, no tickets available');
        return tickets[msg.sender];
    }
    /*
     *  @function setLotteryLength
     *
     *  Set the length of time the lottery will
     *  take place in second to draw the RNG.
     *
     *    Human Readable Time  Seconds
     *    1 Hour   3600 Seconds
     *    1 Day    86400 Seconds
     *    1 Week   604800 Seconds
     *    1 Month (30.44 days) 2629743 Seconds
     */
    function setLotteryLength (uint length) external onlyAdmin {
        require(!open, 'lotto is open, cannot set length');
        lotteryLength = length;
    }
    
    function setLotteryState(bool state) external onlyAdmin {
        open = state;
    }
    // start lotto 
    function start() external onlyAdmin {
        require(!open, 'lotto is open, cannot start again');
        startTime = block.timestamp;
        open = true;
        emit LotteryStarted(startTime);
    }
    // generate randomness
    // @dev - static for now
    /*
    function draw() external {
        require(startTime + lotteryLength <= block.timestamp, 'lottery is ongoing, cannot draw winning ticket.');
        open = false;
        uint[6] memory winner;
        for (uint i = 1; i < 7; i++) {
            winner[i-1] = i; // [1,2,3,4,5,6]
        }
        findWinners(winner);
        emit winnerDrawn(winner, epoch);
    }
    */

    function setTicketPrice(uint price) external onlyAdmin {
        ticketPrice = price;
    }
    // LP swap hook
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    /// @dev Restricted to members of the community.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to members.");
        _;
    }  
    /// @dev Return `true` if the `account` belongs to the community.
    function isAdmin(address account)
        public virtual view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
    }
    // powerball percentage settings
    function setPb(uint percentage) public onlyAdmin {
        pb = percentage;
    }

    function setPbOne(uint percentage) public onlyAdmin {
        pbOne = percentage;
    }

    function setPbTwo(uint percentage) public onlyAdmin {
        pbTwo = percentage;
    }

    function setPbThree(uint percentage) public onlyAdmin {
        pbThree = percentage;
    }

    function setPbFour(uint percentage) public onlyAdmin {
        pbFour = percentage;
    }

    function setJackpot(uint percentage) public onlyAdmin {
        jackpot = percentage;
    }
    // no powerball percentage settings
    function setNoPbThree(uint percentage) public onlyAdmin {
        noPbThree = percentage;
    }

    function setNoPbFour(uint percentage) public onlyAdmin {
        noPbFour = percentage;
    }

    function setNoPbFive(uint percentage) public onlyAdmin {
        noPbFive = percentage;
    }

    function claim() external {
        require(!processing, 'Paying winners...please try again later');
        require(balances[msg.sender] > 0, 'No balance for caller');
        if (balances[msg.sender] > 0) { // withdrawThreshold
            uint balance = balances[msg.sender];
            payable(msg.sender).transfer(balance);
            balances[msg.sender] = 0;
            emit Payout(msg.sender, balance);
        }
    }

    receive() external payable {}

    function takeFeesBasic(uint amount) internal swapping returns (uint) {
        uint opsAmount = amount.mul(opsFee).div(n);
        uint liquidityFee = amount.mul(lFee).div(n);
        // uint divAmount = amount.mul(divFee).div(n);
        // swap rewards amount and send to the staking contract
        // pay dev
        if (balances[dev] == 0) {
            balances[dev] = opsAmount;
        } else {
            balances[dev] = balances[dev].add(opsAmount);
        }
        // LP
        if(shouldSwapBack()){ 
            swapETHForTokens(liquidityFee); 
        }
        return amount.sub(opsAmount).sub(liquidityFee);
    }

    function takeFeesAffiliate(uint amount, address affiliate) internal swapping returns (uint) {
        uint opsAmount = amount.mul(opsFee).div(n);
        uint aFee = amount.mul(affiliateFee).div(n);
        uint liquidityFee = amount.mul(lFee).div(n);
        // uint divAmount = amount.mul(divFee).div(n);
        // swap rewards amount and send to the staking contract
        // pay dev
        if (balances[dev] == 0) {
            balances[dev] = opsAmount;
        } else {
            balances[dev] = balances[dev].add(opsAmount);
        }
        // pay affiliate
        if (balances[affiliate] == 0) {
            balances[affiliate] = aFee;
        } else {
            balances[affiliate] = balances[affiliate].add(aFee);
        }
        // LP 
        if(shouldSwapBack()){ 
            swapETHForTokens(liquidityFee); 
        }
        return amount.sub(opsAmount).sub(aFee).sub(liquidityFee);
    }
    
    // * @dev by convention the powerball will be the last number
    function shouldSwapBack() internal view returns (bool) {
        return !inSwap
        && swapEnabled;
    }

    function swapETHForTokens(uint256 amount) private swapping {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = vicexToken;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyAdmin {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
    function buyTicket(uint[6] memory ticket) public payable {
        require(msg.value >= getTicketPrice(), 'Not enough ether sent to buy a ticket');
        require(startTime + lotteryLength >= block.timestamp, 'sale is over');
        require(open, 'lottory has not started yet');
        require(ticket.length == 6, 'Incorrect ticket format');   
        // add to users
        users.push(msg.sender);
        userCount.increment();
        // @dev - add fee check conditions
        uint jackpotAmount = takeFeesBasic(msg.value);

        tickets[msg.sender].push(ticket);

        ticketCount.increment();

        balances[address(this)] = balances[address(this)].add(jackpotAmount);
        emit TicketBought(msg.sender, ticket, msg.value);
    }
    
    function buyTicketWithAffiliate(uint[6] memory ticket, address affiliate) public payable {
        require(msg.value >= getTicketPrice(), 'Not enough ether sent to buy a ticket');
        require(startTime + lotteryLength >= block.timestamp, 'sale is over');
        require(open, 'lottery has not started yet');
        require(ticket.length == 6, 'Incorrect ticket format');

        users.push(msg.sender);
        userCount.increment();
        // @dev - add fee check conditions
        uint jackpotAmount = takeFeesAffiliate(msg.value, affiliate);

        tickets[msg.sender].push(ticket);

        ticketCount.increment();

        balances[address(this)] = balances[address(this)].add(jackpotAmount);
        emit TicketBought(msg.sender, ticket, msg.value);
    }

    function getUserCount() view external returns (uint) {
        return userCount.current();
    }

    function findWinner(address ticketOwner, uint[] memory wTicket, uint[6] memory uTicket) internal  {
        require(wTicket.length == uTicket.length, 'Incorrect Ticket Format');
        bool powerball;
        // last entry is powerball
        if (wTicket[5] == uTicket[5]) powerball = true;
        // for the first 5 number entries, any match constitutes a win
        uint matches = 0;
        for (uint i = 0; i < 5; i++) {
            uint uNumber = uTicket[i];
            // check if the number is a match
            for (uint j = 0; j < 5; j++) {
                if (uNumber == wTicket[j]) matches = matches.add(1);
            }
        }
        // condition - no matches, no powerball
        if (!powerball && matches == 0) {
            emit Winner(ticketOwner, 'none');
            return;
        }

        // condition - jackpot
        if (powerball && matches == 5) {
            winnersJackpot.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, 'jackpot');
            return;
        }
        // condition - if five match
        else if (!powerball && matches == 5) {
            winnersnoPbFive.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, '5');
            return;
        }
        // condition - if four match + powerball
        else if (powerball && matches == 4) {
            winnersPbFour.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, 'p4');
            return;
        }
        // condition - if four match
        else if (!powerball && matches == 4) {
            winnersNoPbFour.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, '4');
            return;
        }
        // condition - if three match + powerball
        else if (powerball && matches == 3) {
            winnersPbThree.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, 'p3');
            return;
        }
        // condition - if three match
        else if (!powerball && matches == 3) {
            winnersNoPbThree.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, '3');
            return;
        }
        // condition - if two match + powerball
        else if (powerball && matches == 2) {
            winnersPbTwo.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, 'p2');
            return;
        }
        // condition - if one match + powerball
        else if (powerball && matches == 1) {
            winnersPbOne.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, 'p1');
            return;
        }
        else if (powerball && matches == 0) {
            winnersPb.push(ticketOwner);
            winnerCount.increment();
            emit Winner(ticketOwner, 'p');
            return;
        }
    }

    function setShares(address[] memory winners, uint percentage) internal {
        if (winners.length == 0) return;
        uint allWinners = winners.length;
        // payout is 50% of contract balance
        uint payoutPerWinner = balances[address(this)].mul(percentage).div(n).div(allWinners);
        for (uint i = 0; i < allWinners; i++) {
            if (balances[winners[i]] == 0) balances[winners[i]] = payoutPerWinner;
            else {balances[winners[i]].add(payoutPerWinner);}
        }
    }
    
    function removeTicket(address ticketHolder) internal {
        delete tickets[ticketHolder];
    }

    function findWinners() external onlyAdmin {   // need better role system
        require(startTime + lotteryLength <= block.timestamp, 'lottery is ongoing, cannot draw winning ticket.');
        require(!open, 'lottery has not ended');
        require(winningTicket.length == 6, 'Winning Ticket is being drawn or has not been called.');
        require(!processing, 'Paying winners...please try again later');
        // set processsing to true so no claims can be made until the balances are actualized
        processing = true;

        // loop over all known tickets
        for (uint i = 0; i < users.length; i++) {
            uint[6][] memory userTickets = tickets[users[i]];
            // iterate through user tickets and find the highest win for a user
            for (uint j = 0; j < userTickets.length; j++) {
                findWinner(users[i], winningTicket, userTickets[j]);
            }
            removeTicket(users[i]);
        }
        setShares(winnersPb, pb);
        setShares(winnersPbOne, pbOne);
        setShares(winnersPbTwo, pbTwo);
        setShares(winnersNoPbThree, noPbThree);
        setShares(winnersPbThree, pbThree);
        setShares(winnersNoPbFour, noPbFour);
        setShares(winnersPbFour, pbFour);
        setShares(winnersnoPbFive, noPbFive);
        setShares(winnersJackpot, jackpot);

        // reset lottery state so the lottery can be started again
        rollOver();
        // claims actualized
        processing = false;
    }
    
    function reset() internal {
        // reset winner arrays
        delete winnersPb;
        delete winnersPbOne;
        delete winnersPbTwo;
        delete winnersPbThree;
        delete winnersNoPbThree;
        delete winnersPbFour;
        delete winnersnoPbFive;
        delete winnersJackpot;
        // reset participants array
        delete users;
        // reset winningTicket
        delete winningTicket;
    }

    function getUserBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function rollOver() internal {
        require(startTime + lotteryLength <= block.timestamp, 'sale has not ended');
        require(!open, 'sale is still active');
        require(startTime < block.timestamp, 'sale has not started');
        reset();
        epoch = epoch.add(1);
    }

    function withdrawLink(address recipient, uint256 amount) public onlyAdmin{
        link.transfer(recipient, amount);
    }

    /*
     *  @function getETHBalance
     *  
     *  Check the balance of ETH in the contract.
     *
     *  @returns address(this).balance <uint>
     *
     */
    function getETHBalance() public view returns(uint) {
        return address(this).balance;
    }

    /*
     *  @function withdrawOverFlowETH
     *  
     *  Withdraw the balance of ETH in the contract
     *  and send to the contract owner's wallet.
     *
     */
    function withdrawOverFlowETH() public onlyAdmin {
        address payable to = payable(msg.sender);
        to.transfer(getETHBalance());
    }
}