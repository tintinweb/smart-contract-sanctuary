/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: @openzeppelin/contracts/access/IAccessControl.sol



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

// File: NewYearToken.sol


pragma solidity ^0.8.2;








contract NewYearToken is Context, IERC20, IERC20Metadata, AccessControl {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public busd;
    IUniswapV2Router02 public router;
    address public pair;

    mapping(address => bool) public isLpToken;
    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) public excludedFromAntiWhale;

    uint256 public antiWhaleTxAmountRate = 20; // 0.2%
    bool public antiWhaleEnabled;
    bool public antiWhaleSellEnabled;
    bool public antiWhaleBuyEnabled;
    bool public antiWhaleTransferEnabled;

    address public rewardSwapAddress;
    address[] public rewardSwapReceivers;
    uint256[] public rewardSwapReceiversRate;

    uint256 public rewardSellCounter;
    uint256 public rewardSellAmount;
    uint256 public rewardSellRate;
    uint256 public rewardSellLimit;

    uint256 public rewardBuyCounter;
    uint256 public rewardBuyAmount;
    uint256 public rewardBuyRate;
    uint256 public rewardBuyLimit;


    uint256 public marketingFeeRate;

    bool public marketingSwapEnabled = true;

    address[] public marketingReceivers;
    uint256[] public marketingReceiversRate;
    
    uint256 public marketingCounter;
    uint256 public marketingAmount;
    uint256 public marketingLimit;

    bool private inSwap;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _name = "New Year Token";
        _symbol = "NYT";

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _mint(msg.sender, 1000000 * 10 ** 18);

        rewardSwapAddress = 0xB12ea6bad27632d0Ebaee2FFB7afe7C71087b086;
        // rewardSwapAddress = address(0);
        busd = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; // busd token
        // busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // busd token
        router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // router
        // router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // router
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), busd);
        isLpToken[pair] = true;

        setExcludedFromFee(msg.sender, true);
        setExcludedFromAntiWhale(msg.sender, true);

        setExcludedFromFee(address(this), true);
        setExcludedFromAntiWhale(address(this), true);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function maxAntiWhaleTxAmount() public view returns (uint256) {
        return _calcFee(totalSupply(), antiWhaleTxAmountRate);
    }

    function setLpToken(address lpToken, bool lp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(lpToken != address(0), "BEP20: invalid LP address");
        require(lpToken != pair, "ERC20: exclude busd pair");

        isLpToken[lpToken] = lp;
    }

    function setExcludedFromFee(address _address, bool _isExcludedFromFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        excludedFromFee[_address] = _isExcludedFromFee;
    }

    function setExcludedFromAntiWhale(address _address, bool _isExcludedFromAntiWhale) public onlyRole(DEFAULT_ADMIN_ROLE) {
        excludedFromAntiWhale[_address] = _isExcludedFromAntiWhale;
    }

    function setAntiWhaleTxAmountRate(uint256 _antiWhaleTxAmountRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_antiWhaleTxAmountRate <= 500 && _antiWhaleTxAmountRate >= 20, "ERC20: invalid _antiWhaleTxAmountRate");
        antiWhaleTxAmountRate = _antiWhaleTxAmountRate;
    }

    function setAntiWhaleEnabled(bool _antiWhaleEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        antiWhaleEnabled = _antiWhaleEnabled;
    }

    function setAntiWhaleSellEnabled(bool _antiWhaleSellEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        antiWhaleSellEnabled = _antiWhaleSellEnabled;
    }

    function setAntiWhaleBuyEnabled(bool _antiWhaleBuyEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        antiWhaleBuyEnabled = _antiWhaleBuyEnabled;
    }
    
    function setAntiWhaleTransferEnabled(bool _antiWhaleTransferEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        antiWhaleTransferEnabled = _antiWhaleTransferEnabled;
    }

    function setRewardSwapAddress(address _rewardSwapAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardSwapAddress = _rewardSwapAddress;
    }

    function setRewardSwapReceivers(address[] calldata _rewardSwapReceivers, uint256[] calldata _rewardSwapReceiversRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewardSwapReceivers.length == _rewardSwapReceiversRate.length);

        uint256 totalRate = 0;
        for (uint256 i = 0; i < _rewardSwapReceiversRate.length; i++) {
            totalRate = totalRate.add(_rewardSwapReceiversRate[i]);
        }
        require(totalRate <= 10000); // 100%


        uint256 rewardSwapReceiversLength = rewardSwapReceivers.length;
        for (uint i = 0; i < _rewardSwapReceivers.length; i++) {
            if (rewardSwapReceiversLength > 0 && rewardSwapReceiversLength - 1 >= i) {
                rewardSwapReceivers[i] = _rewardSwapReceivers[i];
            } else {
                rewardSwapReceivers.push(_rewardSwapReceivers[i]);
            }
        }

        if (rewardSwapReceiversLength > _rewardSwapReceivers.length) {
            uint256 diff = rewardSwapReceiversLength.sub(_rewardSwapReceivers.length);
            for (uint i = 0; i < diff; i++) {
                rewardSwapReceivers.pop();
            }
        }


        uint256 itemLength = rewardSwapReceiversRate.length;
        for (uint i = 0; i < _rewardSwapReceiversRate.length; i++) {
            if (itemLength > 0 && itemLength - 1 >= i) {
                rewardSwapReceiversRate[i] = _rewardSwapReceiversRate[i];
            } else {
                rewardSwapReceiversRate.push(_rewardSwapReceiversRate[i]);
            }
        }

        if (itemLength > _rewardSwapReceiversRate.length) {
            uint256 diff = itemLength.sub(_rewardSwapReceiversRate.length);
            for (uint i = 0; i < diff; i++) {
                rewardSwapReceiversRate.pop();
            }
        }
    }

    function setMarketingFeeRate(uint256 _marketingFeeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_marketingFeeRate >= 0 && _marketingFeeRate <= 1000); // min 0%; max 10%
        marketingFeeRate = _marketingFeeRate;
    }

    function setMarketingSwapEnabled(bool _marketingSwapEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketingSwapEnabled = _marketingSwapEnabled;
    }

    function setMarketingReceivers(address[] calldata _marketingReceivers, uint256[] calldata _marketingReceiversRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_marketingReceivers.length == _marketingReceiversRate.length);

        uint256 totalRate = 0;
        for (uint256 i = 0; i < _marketingReceiversRate.length; i++) {
            totalRate = totalRate.add(_marketingReceiversRate[i]);
        }
        require(totalRate <= 10000);

        uint256 marketingReceiversLength = marketingReceivers.length;
        for (uint i = 0; i < _marketingReceivers.length; i++) {
            if (marketingReceiversLength > 0 && marketingReceiversLength - 1 >= i) {
                marketingReceivers[i] = _marketingReceivers[i];
            } else {
                marketingReceivers.push(_marketingReceivers[i]);
            }
        }

        if (marketingReceiversLength > _marketingReceivers.length) {
            uint256 diff = marketingReceiversLength.sub(_marketingReceivers.length);
            for (uint i = 0; i < diff; i++) {
                marketingReceivers.pop();
            }
        }


        uint256 itemLength = marketingReceiversRate.length;
        for (uint i = 0; i < _marketingReceiversRate.length; i++) {
            if (itemLength > 0 && itemLength - 1 >= i) {
                marketingReceiversRate[i] = _marketingReceiversRate[i];
            } else {
                marketingReceiversRate.push(_marketingReceiversRate[i]);
            }
        }

        if (itemLength > _marketingReceiversRate.length) {
            uint256 diff = itemLength.sub(_marketingReceiversRate.length);
            for (uint i = 0; i < diff; i++) {
                marketingReceiversRate.pop();
            }
        }
    }

    function setMarketingLimit(uint256 _marketingLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketingLimit = _marketingLimit;
    }

    function marketingReset() external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketingCounter = 0;
        marketingAmount = 0;
    }

    function rewardSellReset() external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardSellCounter = 0;
        rewardSellAmount = 0;
    }

    function setRewardSellRate(uint256 _rewardSellRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(0 <= _rewardSellRate && _rewardSellRate <= 1500);
        rewardSellRate = _rewardSellRate;
    }

    function setRewardSellLimit(uint256 _rewardSellLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardSellLimit = _rewardSellLimit;
    }

    function rewardBuyReset() external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardBuyCounter = 0;
        rewardBuyAmount = 0;
    }

    function setRewardBuyRate(uint256 _rewardBuyRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(0 <= _rewardBuyRate && _rewardBuyRate <= 1500);
        rewardBuyRate = _rewardBuyRate;
    }

    function setRewardBuyLimit(uint256 _rewardBuyLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardBuyLimit = _rewardBuyLimit;
    }

    function swapRewards(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) lockTheSwap {
        if (balanceOf(address(this)) >= amount) {
            IERC20 _busd = IERC20(busd);

            if (rewardSwapReceivers.length > 0) {
                uint256 oldBusdBalance = _busd.balanceOf(address(this));
                _swapTokensForBusd(amount, address(this));
                uint256 newBusdBalance = _busd.balanceOf(address(this));
                uint256 busdBalanceDiff = newBusdBalance.sub(oldBusdBalance);

                for (uint256 i = 0; i < rewardSwapReceivers.length; i++) {
                    uint256 _calcAmount = _calcFee(busdBalanceDiff, rewardSwapReceiversRate[i]);
                    if (_busd.balanceOf(address(this)) >= _calcAmount) {
                        _busd.transfer(rewardSwapReceivers[i], _calcAmount);
                    }
                }
            } else {
                _swapTokensForBusd(amount, rewardSwapAddress);
            }
        }
    }

    function swapMarketingFees(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (balanceOf(address(this)) >= amount) {
            IERC20 _busd = IERC20(busd);

            uint256 oldBusdBalance = _busd.balanceOf(address(this));
            _swapTokensForBusd(amount, address(this));
            uint256 newBusdBalance = _busd.balanceOf(address(this));
            uint256 busdBalanceDiff = newBusdBalance.sub(oldBusdBalance);
    
            if (marketingReceivers.length > 0) {
                for (uint256 i = 0; i < marketingReceivers.length; i++) {
                    uint256 _calcAmount = _calcFee(busdBalanceDiff, marketingReceiversRate[i]);
                    if (_busd.balanceOf(address(this)) >= _calcAmount) {
                        _busd.transfer(marketingReceivers[i], _calcAmount);
                    }
                }
            }
        }
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        if (
            antiWhaleEnabled && 
            !excludedFromAntiWhale[sender] && 
            !excludedFromAntiWhale[recipient] && 
            (
                antiWhaleSellEnabled && _isSell(sender, recipient) ||
                antiWhaleBuyEnabled && _isBuy(sender, recipient) ||
                antiWhaleTransferEnabled && _isTransfer(sender, recipient)
            )
        ) {
            require(amount <= maxAntiWhaleTxAmount(), "ERC20: transfer amount exceeds the maxAntiWhaleTxAmount");
        }

        uint256 calculatedAmount = amount;

        if (!inSwap && !(excludedFromFee[sender] || excludedFromFee[recipient])) {
            if (marketingFeeRate > 0) {
                uint256 _calcAmount = _calcFee(calculatedAmount, marketingFeeRate);
                _transferAmount(sender, address(this), _calcAmount, false);

                marketingAmount = marketingAmount.add(_calcAmount);
                marketingCounter = marketingCounter.add(1);

                if (marketingSwapEnabled && marketingCounter >= marketingLimit && balanceOf(address(this)) >= marketingAmount) {
                    swapMarketingFees(marketingAmount);

                    marketingAmount = 0;
                    marketingCounter = 0;
                }

                calculatedAmount = calculatedAmount.sub(_calcAmount);
            }
        }
 
        _transferAmount(sender, recipient, calculatedAmount, true);

        if (!inSwap) {
            _afterTokenTransfer(sender, recipient, amount);
        }
    }

    function _transferAmount(address from, address to, uint256 amount, bool isPublic) internal {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        if (isPublic) {
            emit Transfer(from, to, amount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account != deadAddress, "ERC20: burn from the dead address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");

        _transferAmount(account, deadAddress, amount, true);

        _afterTokenTransfer(account, deadAddress, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal {
        if (_isSell(from, to)) {

            if (rewardSellRate > 0) {
                rewardSellCounter = rewardSellCounter.add(1);
                rewardSellAmount = rewardSellAmount.add(amount);

                if (rewardSellCounter >= rewardSellLimit) {
                    uint256 rewardAmount = _calcFee(rewardSellAmount, rewardSellRate);

                    if (balanceOf(rewardSwapAddress) >= rewardAmount) {
                        _transferAmount(rewardSwapAddress, address(this), rewardAmount, false);

                        swapRewards(rewardAmount);

                        rewardSellCounter = 0;
                        rewardSellAmount = 0;
                    }
                }
            }

        } else if (_isBuy(from, to)) {

            if (rewardBuyRate > 0) {
                rewardBuyCounter = rewardBuyCounter.add(1);
                rewardBuyAmount = rewardBuyAmount.add(amount);

                if (rewardBuyCounter >= rewardBuyLimit) {
                    uint256 rewardAmount = _calcFee(rewardBuyAmount, rewardBuyRate);

                    if (balanceOf(rewardSwapAddress) >= rewardAmount) {
                        _transferAmount(rewardSwapAddress, address(this), rewardAmount, false);

                        swapRewards(rewardAmount);

                        rewardBuyCounter = 0;
                        rewardBuyAmount = 0;
                    }
                }
            }

        }
    }

    function _calcFee(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return amount.mul(rate).div(100000);
    }

    function _isSell(address from, address to) internal view returns (bool) {
        return !isLpToken[from] && isLpToken[to];
    }

    function _isBuy(address from, address to) internal view returns (bool) {
        return isLpToken[from] && !isLpToken[to];
    }

    function _isTransfer(address from, address to) internal view returns (bool) {
        return !isLpToken[from] && !isLpToken[to];
    }

    function _swapTokensForBusd(uint256 _tokenAmount, address _recipient) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = busd;

        _approve(address(this), address(router), _tokenAmount);
        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            _recipient,
            block.timestamp
        );
    }

}