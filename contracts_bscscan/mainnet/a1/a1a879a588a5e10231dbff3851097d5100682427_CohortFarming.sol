/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/interfaces/IERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


// File contracts/utils/Address.sol

pragma solidity >=0.5.0 <0.9.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

/**
    
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
    
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }
    
*/

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
     *
     * _Available since v2.4.0._

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
*/
}


// File contracts/utils/SafeMath.sol

pragma solidity >=0.5.0 <0.9.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/utils/SafeERC20.sol

pragma solidity >=0.5.0 <0.9.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


// File contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.5.0 <0.9.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor() public {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}


// File contracts/interfaces/IAccessControl.sol

// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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


// File contracts/utils/Context.sol

pragma solidity >=0.5.0 <0.9.0;

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
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        return msg.data;
    }
}


// File contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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


// File contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// File contracts/utils/ERC165.sol

// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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


// File contracts/utils/AccessControl.sol

// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/QUAICohortFarming.sol

pragma solidity =0.8.4;






    /*
     * rewardIndex keeps track of the total amount of rewards to be distributed for
     * each supplied unit of 'stakedToken' tokens. When used together with supplierIndex,
     * the total amount of rewards to be paid out to individual users can be calculated
     * when the user claims their rewards.
     *
     * Consider the following:
     *
     * At contract deployment, the contract has a zero 'stakedToken' balance. Immediately, a new
     * user, User A, deposits 1000 'stakedToken' tokens, thus increasing the total supply to
     * 1000 'stakedToken'. After 60 seconds, a second user, User B, deposits an additional 500 'stakedToken',
     * increasing the total supplied amount to 1500 'stakedToken'.
     *
     * Because all balance-changing contract calls, as well as those changing the reward
     * speeds, must invoke the accrueRewards function, these deposit calls trigger the
     * function too. The accrueRewards function considers the reward speed (denoted in
     * reward tokens per second), the reward and supplier reward indexes, and the supply
     * balance to calculate the accrued rewards.
     *
     * When User A deposits their tokens, rewards are yet to be accrued due to previous
     * inactivity; the elapsed time since the previous, non-existent, reward-accruing
     * contract call is zero, thus having a reward accrual period of zero. The block
     * time of the deposit transaction is saved in the contract to indicate last
     * activity time.
     *
     * When User B deposits their tokens, 60 seconds has elapsed since the previous
     * call to the accrueRewards function, indicated by the difference of the current
     * block time and the last activity time. In other words, up till the time of
     * User B's deposit, the contract has had a 60 second accrual period for the total
     * amount of 1000 'stakedToken' tokens at the set reward speed. Assuming a reward speed of
     * 5 tokens per second (denoted 5 T/s), the accrueRewards function calculates the
     * accrued reward per supplied unit of 'stakedToken' tokens for the elapsed time period.
     * This works out to ((5 T/s) / 1000 'stakedToken') * 60 s = 0.3 T/'stakedToken' during the 60 second
     * period. At this point, the global reward index variable is updated, increasing
     * its value by 0.3 T/'stakedToken', and the reward accrual block timestamp,
     * initialised in the previous step, is updated.
     *
     * After 90 seconds of the contract deployment, User A decides to claim their accrued
     * rewards. Claiming affects token balances, thus requiring an invocation of the
     * accrueRewards function. This time, the accrual period is 30 seconds (90 s - 60 s),
     * for which the reward accrued per unit of 'stakedToken' is ((5 T/s) / 1500 'stakedToken') * 30 s = 0.1 T/'stakedToken'.
     * The reward index is updated to 0.4 T/'stakedToken' (0.3 T/'stakedToken' + 0.1 T/'stakedToken') and the reward
     * accrual block timestamp is set to the current block time.
     *
     * After the reward accrual, User A's rewards are claimed by transferring the correct
     * amount of T tokens from the contract to User A. Because User A has not claimed any
     * rewards yet, their supplier index is zero, the initial value determined by the
     * global reward index at the time of the user's first deposit. The amount of accrued
     * rewards is determined by the difference between the global reward index and the
     * user's own supplier index; essentially, this value represents the amount of
     * T tokens that have been accrued per supplied 'stakedToken' during the time since the user's
     * last claim. User A has a supply balance of 1000 'stakedToken', thus having an unclaimed
     * token amount of (0.4 T/'stakedToken' - 0 T/'stakedToken') * 1000 'stakedToken' = 400 T. This amount is
     * transferred to User A, and their supplier index is set to the current global reward
     * index to indicate that all previous rewards have been accrued.
     *
     * If User B was to claim their rewards at the same time, the calculation would take
     * the form of (0.4 T/'stakedToken' - 0.3 T/'stakedToken') * 500 'stakedToken' = 50 T. As expected, the total amount
     * of accrued reward (5 T/s * 90 s = 450 T) equals to the sum of the rewards paid
     * out to both User A and User B (400 T + 50 T = 450 T).
     *
     * This method of reward accrual is used to minimise the contract call complexity.
     * If a global mapping of users to their accrued rewards was implemented instead of
     * the index calculations, each function call invoking the accrueRewards function
     * would become immensely more expensive due to having to update the rewards for each
     * user. In contrast, the index approach allows the update of only a single user
     * while still keeping track of the other's rewards.
     *
     * Because rewards can be paid in multiple assets, reward indexes, reward supplier
     * indexes, and reward speeds depend on the StakingReward token.
     */

contract CohortFarming is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //contract address for token that users stake for rewards
    address public immutable stakedToken;
    //number of rewards tokens distributed to users
    uint256 public numberStakingRewards;
    // Sum of all supplied 'stakedToken' tokens
    uint256 public totalSupplies;
    //see explanation of accrualBlockTimestamp, rewardIndex, and supplierRewardIndex above
    uint256 public accrualBlockTimestamp;
    mapping(uint256 => uint256) public rewardIndex;
    mapping(address => mapping(uint256 => uint256)) public supplierRewardIndex; 
    // Supplied 'stakedToken' for each user
    mapping(address => uint256) public supplyAmount;
    // Addresses of the ERC20 reward tokens
    mapping(uint256 => address) public rewardTokenAddresses;
    // Reward accrual speeds per reward token as tokens per second
    mapping(uint256 => uint256) public rewardSpeeds;
    // Reward rewardPeriodFinishes per reward token as UTC timestamps
    mapping(uint256 => uint256) public rewardPeriodFinishes;
    // Total unclaimed amount of each reward token promised/accrued to users
    mapping(uint256 => uint256) public unwithdrawnAccruedRewards;    
    // Unclaimed staking rewards per user and token
    mapping(address => mapping(uint256 => uint256)) public accruedReward;

    //special mechanism for stakedToken to offer specific yearly multiplier. non-compounded value, where 1e18 is a multiplier of 1 (i.e. 100% APR)
    uint256 public stakedTokenRewardIndex = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 public stakedTokenYearlyReturn;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    constructor(address _stakedToken, uint256 _numberStakingRewards, address[] memory _rewardTokens, uint256[] memory _rewardPeriodFinishes) {
        require(_stakedToken != address(0));
        require(_rewardTokens.length == _numberStakingRewards, "bad _rewardTokens input");
        require(_rewardPeriodFinishes.length == _numberStakingRewards, "bad _rewardPeriodFinishes input");
        stakedToken = _stakedToken;
        numberStakingRewards = _numberStakingRewards;
        for (uint256 i = 0; i < _numberStakingRewards; i++) {
            require(_rewardTokens[i] != address(0));
            require(_rewardPeriodFinishes[i] > block.timestamp, "cannot set rewards to finish in past");
            rewardTokenAddresses[i] = _rewardTokens[i];
            rewardPeriodFinishes[i] = _rewardPeriodFinishes[i];
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

     /*
     * Get the current amount of available rewards for claiming.
     *
     * @param rewardToken Reward token whose claimable balance to query
     * @return Balance of claimable reward tokens
     */
    function getClaimableRewards(uint256 rewardTokenIndex) external view returns(uint256) {
        return getUserClaimableRewards(msg.sender, rewardTokenIndex);
    }

     /*
     * Get the current amount of available rewards for claiming.
     *
     * @param user Address of user
     * @param rewardToken Reward token whose claimable balance to query
     * @return Balance of claimable reward tokens
     */
    function getUserClaimableRewards(address user, uint256 rewardTokenIndex) public view returns(uint256) {
        require(rewardTokenIndex <= numberStakingRewards, "Invalid reward token");
        uint256 rewardIndexToUse = rewardIndex[rewardTokenIndex];
        //imitate accrual logic without state update
        if (block.timestamp > accrualBlockTimestamp && totalSupplies != 0) {
            uint256 rewardSpeed = rewardSpeeds[rewardTokenIndex];
            if (rewardSpeed != 0 && accrualBlockTimestamp < rewardPeriodFinishes[rewardTokenIndex]) {
                uint256 blockTimestampDelta = (min(block.timestamp, rewardPeriodFinishes[rewardTokenIndex]) - accrualBlockTimestamp);
                uint256 accrued = (rewardSpeeds[rewardTokenIndex] * blockTimestampDelta);
                uint256 accruedPerStakedToken = (accrued * 1e36) / totalSupplies;
                rewardIndexToUse += accruedPerStakedToken;
            }
        }
        uint256 rewardIndexDelta = rewardIndexToUse - (supplierRewardIndex[user][rewardTokenIndex]);
        uint256 claimableReward = ((rewardIndexDelta * supplyAmount[user]) / 1e36) + accruedReward[user][rewardTokenIndex];
        return claimableReward;
    }

    //returns fraction of total deposits that user controls, *multiplied by 1e18*
    function getUserDepositedFraction(address user) external view returns(uint256) {
        if (totalSupplies == 0) {
            return 0;
        } else {
            return (supplyAmount[user] * 1e18) / totalSupplies; 
        }
    }

    //returns amount of token left to distribute
    function getRemainingTokens(uint256 rewardTokenIndex) external view returns(uint256) {
        if (rewardPeriodFinishes[rewardTokenIndex] <= block.timestamp) {
            return 0;
        } else {
            uint256 amount = (rewardPeriodFinishes[rewardTokenIndex] - block.timestamp) * rewardSpeeds[rewardTokenIndex];
            uint256 bal = IERC20(rewardTokenAddresses[rewardTokenIndex]).balanceOf(address(this));
            if (rewardTokenIndex == stakedTokenYearlyReturn) {
                if (bal > totalSupplies) {
                    bal -= totalSupplies;
                } else {
                    bal = 0;
                }
            }
            return min(amount, bal);
        }
    }

    function lastTimeRewardApplicable(uint256 rewardTokenIndex) public view returns (uint256) {
        return min(block.timestamp, rewardPeriodFinishes[rewardTokenIndex]);
    }

    function deposit(uint256 amount) external nonReentrant {
        IERC20 token = IERC20(stakedToken);
        uint256 contractBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 depositedAmount = token.balanceOf(address(this)) - contractBalance;
        distributeReward(msg.sender);
        totalSupplies += depositedAmount;
        supplyAmount[msg.sender] += depositedAmount;
        autoUpdateStakedTokenRewardSpeed();

    }

    function withdraw(uint amount) public nonReentrant {
        require(amount <= supplyAmount[msg.sender], "Too large withdrawal");
        distributeReward(msg.sender);
        supplyAmount[msg.sender] -= amount;
        totalSupplies -= amount;
        IERC20 token = IERC20(stakedToken);
        autoUpdateStakedTokenRewardSpeed();
        token.safeTransfer(msg.sender, amount);
    }

    function exit() external {
        withdraw(supplyAmount[msg.sender]);
    }

    function claimRewards() external nonReentrant {
        distributeReward(msg.sender);
        for (uint256 i = 0; i < numberStakingRewards; i++) {
            uint256 amount = accruedReward[msg.sender][i];
            claimErc20(i, msg.sender, amount);
        }
    }

    function setRewardSpeed(uint256 rewardTokenIndex, uint256 speed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (accrualBlockTimestamp != 0) {
            accrueReward();
        }
        rewardSpeeds[rewardTokenIndex] = speed;
    }

    function setRewardPeriodFinish(uint256 rewardTokenIndex, uint256 rewardPeriodFinish) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rewardPeriodFinish > block.timestamp, "cannot set rewards to finish in past");
        rewardPeriodFinishes[rewardTokenIndex] = rewardPeriodFinish;
    }

    function setStakedTokenYearlyReturn(uint256 _stakedTokenYearlyReturn) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedTokenYearlyReturn = _stakedTokenYearlyReturn;
        autoUpdateStakedTokenRewardSpeed();
    }

    function setStakedTokenRewardIndex(uint256 _stakedTokenRewardIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedTokenRewardIndex = _stakedTokenRewardIndex;
        autoUpdateStakedTokenRewardSpeed();
    }

    function addNewRewardToken(address rewardTokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rewardTokenAddress != address(0), "Cannot set zero address");
        numberStakingRewards += 1;
        rewardTokenAddresses[numberStakingRewards - 1] = rewardTokenAddress;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(tokenAddress != address(stakedToken), "Cannot withdraw the staked token");
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * Update reward accrual state.
     *
     * @dev accrueReward() must be called every time the token balances
     *      or reward speeds change
     */
    function accrueReward() internal {
        if (block.timestamp == accrualBlockTimestamp) {
            return;
        } else if (totalSupplies == 0) {
            accrualBlockTimestamp = block.timestamp;
            return;
        }
        for (uint256 i = 0; i < numberStakingRewards; i += 1) {
            uint256 rewardSpeed = rewardSpeeds[i];
            if (rewardSpeed == 0 || accrualBlockTimestamp >= rewardPeriodFinishes[i]) {
                continue;
            }
            uint256 blockTimestampDelta = (min(block.timestamp, rewardPeriodFinishes[i]) - accrualBlockTimestamp);
            uint256 accrued = (rewardSpeeds[i] * blockTimestampDelta);

            IERC20 token = IERC20(rewardTokenAddresses[i]);
            uint256 contractTokenBalance = token.balanceOf(address(this));
            uint256 remainingToDistribute = (contractTokenBalance > unwithdrawnAccruedRewards[i]) ? (contractTokenBalance - unwithdrawnAccruedRewards[i]) : 0;
            if (accrued > remainingToDistribute) {
                accrued = remainingToDistribute;
                rewardSpeeds[i] = 0;
            }
            unwithdrawnAccruedRewards[i] += accrued;

            uint256 accruedPerStakedToken = (accrued * 1e36) / totalSupplies;
            rewardIndex[i] += accruedPerStakedToken;
        }
        accrualBlockTimestamp = block.timestamp;
    }

    /**
     * Calculate accrued rewards for a single account based on the reward indexes.
     *
     * @param recipient Account for which to calculate accrued rewards
     */
    function distributeReward(address recipient) internal {
        accrueReward();
        for (uint256 i = 0; i < numberStakingRewards; i += 1) {
            uint256 rewardIndexDelta = (rewardIndex[i] - supplierRewardIndex[recipient][i]);
            uint256 accruedAmount = (rewardIndexDelta * supplyAmount[recipient]) / 1e36;
            accruedReward[recipient][i] += accruedAmount;
            supplierRewardIndex[recipient][i] = rewardIndex[i];
        }
    }

    /**
     * Transfer ERC20 rewards from the contract to the reward recipient.
     *
     * @param rewardTokenIndex ERC20 reward token which is claimed
     * @param recipient Address, whose rewards are claimed
     * @param amount The amount of claimed reward
     */
    function claimErc20(uint256 rewardTokenIndex, address recipient, uint256 amount) internal {
        require(accruedReward[recipient][rewardTokenIndex] <= amount, "Not enough accrued rewards");
        IERC20 token = IERC20(rewardTokenAddresses[rewardTokenIndex]);
        accruedReward[recipient][rewardTokenIndex] -= amount;
        unwithdrawnAccruedRewards[rewardTokenIndex] -= min(unwithdrawnAccruedRewards[rewardTokenIndex], amount);
        token.safeTransfer(recipient, amount);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //special mechanism for stakedToken to offer specific yearly multiplier. called within deposits and withdrawals to auto-update its reward speed
    function autoUpdateStakedTokenRewardSpeed() internal {
        if (rewardPeriodFinishes[stakedTokenRewardIndex] <= block.timestamp) {
            rewardSpeeds[stakedTokenRewardIndex] = 0;
        } else {
            //31536000 is the number of seconds in a year
            uint256 newRewardSpeed = totalSupplies * stakedTokenYearlyReturn / (31536000 * 1e18);
            uint256 bal = IERC20(rewardTokenAddresses[stakedTokenRewardIndex]).balanceOf(address(this));
            if (bal > totalSupplies) {
                bal -= totalSupplies;
            } else {
                bal = 0;
            }
            uint256 rewardSpeedFromRemaining = bal / (rewardPeriodFinishes[stakedTokenRewardIndex] - block.timestamp);
            rewardSpeeds[stakedTokenRewardIndex] = min(newRewardSpeed, rewardSpeedFromRemaining);
        }
    }
}