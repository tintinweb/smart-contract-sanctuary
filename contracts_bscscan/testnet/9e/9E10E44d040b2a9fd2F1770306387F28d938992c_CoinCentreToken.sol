/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: MIT

// --------------------------------------------
// ----------- COIN CENTRE TOKEN --------------
// --------------------------------------------
// 0xB37C2F0649f23e95161C6B2C3baA9B57C4c1B1De
// 0x1Fa2883Fc9804154154Ca429Ec585a9A8211306B

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
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances; 

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        } 
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual { 
        require(account != address(0), "Access Denied - _mint Zero Address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
 * By default, the admin role for all roles is `ROLEADMIN`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `ROLEADMIN` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant ROLEADMIN = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `ROLEADMIN` is the starting admin for all roles, despite
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


/**
 * @title CoinCentreToken ERC20 token
 * @dev This is the base token to allow for staking and trading
 */
contract CoinCentreToken is ERC20, AccessControl {
    using SafeMath for uint256; 

    //*
    bytes32 public constant ROLEMINTER = keccak256("ROLEMINTER");  
    // bytes32 public constant ZBOUNTY1 = keccak256("MyBOUNTY1"); 
    // bytes32 public constant ZBOUNTY2 = keccak256("MyBOUNTY2"); 
    // bytes32 public constant ZSEEDROUND = keccak256("MySEEDROUND"); 
    // bytes32 public constant ZPRIVATESALE = keccak256("MyPRIVATESALE"); 
    // bytes32 public constant ZMATRIX = keccak256("MyMATRIX"); 
    // bytes32 public constant ZGAME = keccak256("MyGAME");  
      
    //*  
    bytes20 private dDefSpo;
    bytes20 private dDefTop;
    uint16 private dMmbrLis;
    uint16 private dRdrpLis;
    uint16 private dSdrnLis;
    uint16 private dPrslLis;
    uint16 private dMttnLis;
    uint16 private dMtthLis;
    uint16 private dGmLis; 
    struct Mmbr {
        bytes4 ztyp;
        bytes20 zmem;
        bytes20 zspo;
        bytes20 zspo2; 
        bytes20 zspo3; 
        bytes20 zspo4; 
        bytes20 zspo5;  
        bytes32 zdat;
        uint16 zdatid;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Mmbr[]) mmbrs;
    mapping(uint16 => bytes20) public mymmbrs;
    struct Rdrp {
        uint zairsta;
        bytes20 zmem;
        uint256 zairtok;
        uint256 zairtokref; 
        uint16 zdatid;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Rdrp[]) rdrps;
    struct Sdrn {
        uint zseerousta;
        bytes20 zmem;
        uint256 zseeroutok;
        uint256 zseeroutokref;
        uint256 zseeroucoi;
        uint256 zseeroucoiref;
        uint16 zdatid;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Sdrn[]) sdrns;
    struct Prsl {
        uint zprisalsta;
        bytes20 zmem;
        uint16 zdatid;
        uint256 zprisaltok;
        uint256 zprisaltokref;
        uint256 zprisalcoi;
        uint256 zprisalcoiref; 
        uint256 zdatreg;
    }   
    mapping(bytes20 => Prsl[]) prsls;
    struct Mttn {
        uint zmat10sta;
        bytes20 zmem;
        uint16 zdatid;
        uint256 zmat10tok;
        uint256 zmat10tokref;
        uint256 zmat10coi;
        uint256 zmat10coiref;
        uint256 zmat10poinew;
        uint256 zmat10poiold;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Mttn[]) mttns;
    struct Mtth {
        uint zmat30sta;
        bytes20 zmem;
        uint256 zmat30tok;
        uint256 zmat30tokref;
        uint256 zmat30coi;
        uint256 zmat30coiref;
        uint256 zmat30poinew;
        uint256 zmat30poiold;
        uint16 zdatid;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Mtth[]) mtths;
    struct Gm {
        uint zgamsta;
        bytes20 zmem;
        uint256 zgamtok;
        uint256 zgamtokref;
        uint256 zgamcoi;
        uint256 zgamcoiref;
        uint256 zgampoinew;
        uint256 zgampoiold;
        uint16 zdatid;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Gm[]) gms;
    
    //* 
    // bytes20[] private dRdrpLis; 
    uint private dRdrpSta;
        uint256 private dRdrpTokHarCap;
        uint256 private dRdrpCoiPri; 
        uint256 private dRdrpTok;
        uint256 private dRdrpTokRef;
    uint256 private dRdrpTotTok; 
    
     
    constructor() ERC20("CoinCentreToken", "CCTOKEN") {
        _setupRole(ROLEADMIN, _msgSender());
        _setupRole(ROLEMINTER, _msgSender());  
 
        //Init totalSupply
        _mint(_msgSender(), uint256(5000000).mul(uint256(10)**18));


        //*
        dDefTop = bytes20(_msgSender()); 
        dDefSpo = dDefTop; 
 
        dMmbrLis ++;
        Mmbr memory vmmbr = Mmbr({ 
            ztyp: '1',
            zmem: dDefTop,
            zspo: dDefSpo,
            zspo2: dDefSpo,
            zspo3: dDefSpo,
            zspo4: dDefSpo,
            zspo5: dDefSpo, 
            zdat: 'constructor', 
            zdatid: dMmbrLis,
            zdatreg: block.timestamp
        }); 
        mmbrs[dDefTop].push(vmmbr); 
        mymmbrs[dMmbrLis] = dDefTop; 

        dRdrpLis ++;
        Rdrp memory vrdrp = Rdrp({  
            zairsta: 0, 
            zmem: dDefTop,
            zdatid: dRdrpLis,
            zairtok: 0,
            zairtokref: 0,
            zdatreg: block.timestamp
        }); 
        rdrps[dDefTop].push(vrdrp); 
        
        dSdrnLis ++; 
        Sdrn memory vsdrn = Sdrn({  
            zseerousta: 0,
            zmem: dDefTop,
            zdatid: dSdrnLis,
            zseeroutok: 0,
            zseeroutokref: 0,
            zseeroucoi: 0,
            zseeroucoiref: 0, 
            zdatreg: block.timestamp
        }); 
        sdrns[dDefTop].push(vsdrn); 

        dPrslLis ++;
        Prsl memory vprsl = Prsl({  
            zprisalsta: 0,  
            zmem: dDefTop,
            zdatid: dPrslLis,
            zprisaltok: 0,
            zprisaltokref: 0,
            zprisalcoi: 0,
            zprisalcoiref: 0,  
            zdatreg: block.timestamp
        }); 
        prsls[dDefTop].push(vprsl); 
        
        dMttnLis ++;
        Mttn memory vmttn = Mttn({  
            zmat10sta: 0, 
            zmem: dDefTop,
            zdatid: dMttnLis,
            zmat10tok: 0,
            zmat10tokref: 0,
            zmat10coi: 0,
            zmat10coiref: 0,
            zmat10poinew: 0,
            zmat10poiold: 0, 
            zdatreg: block.timestamp
        }); 
        mttns[dDefTop].push(vmttn); 

        dMtthLis ++;
        Mtth memory vmtth = Mtth({  
            zmat30sta: 0, 
            zmem: dDefTop,
            zmat30tok: 0,
            zmat30tokref: 0,
            zmat30coi: 0,
            zmat30coiref: 0,
            zmat30poinew: 0,  
            zmat30poiold: 0, 
            zdatid: dMtthLis,
            zdatreg: block.timestamp 
        }); 
        mtths[dDefTop].push(vmtth); 
        
        dGmLis ++;
        Gm memory vgm = Gm({  
            zgamsta: 0,
            zmem: dDefTop,
            zgamtok: 0,
            zgamtokref: 0,
            zgamcoi: 0,
            zgamcoiref: 0,
            zgampoinew: 0,
            zgampoiold: 0,
            zdatid: dGmLis,
            zdatreg: block.timestamp 
        }); 
        gms[dDefTop].push(vgm); 
        
        //*
        dRdrpSta = 1; 
        dRdrpTokHarCap = 800000; 
        // dRdrpCoiPri = 0;
        dRdrpTok = 400;
        dRdrpTokRef = 100;
        // dRdrpTotTok = 0; 

    }


     
    /**
     * @dev Returns Rdrp 
     */
    function airdropIsReg(address ykey) public view virtual returns (uint) { 
        bytes20 xkey = bytes20(ykey);
        return rdrps[xkey].length;
    }
    function airdropIsTaken(address ykey) public view virtual returns (uint) { 
        bytes20 xkey = bytes20(ykey);
        return rdrps[xkey][0].zairsta;
    }
    function airdropLen() public view returns(uint256) {
        return dRdrpLis;
    }
    function airdropTotTok() public view virtual returns (uint256) {
        return dRdrpTotTok;
    } 
    function airdropSta() public view virtual returns (uint) {
        return dRdrpSta;
    }
    function airdropStaSet(uint ystatus) public {
        require( hasRole(0x00, _msgSender()), "Access Denied" );
        dRdrpSta = ystatus;
    } 
    
    function airdropClaim(address ysponsor) external {
        require(dRdrpSta == 1, "Access Denied - Airdrop Status Is Not Active"); 
        require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
        require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
        require(dRdrpTotTok < uint256(dRdrpTokHarCap).mul(uint256(10)**18), "Access Denied - Total Airdrop Already Exceeded"); 
        require(yMmbrIsReg(ysponsor) >= 1, "Access Denied - Sponsor Not Found");
        bytes20 xmsgSender = bytes20(_msgSender());
        bytes20 xsponsor = bytes20(ysponsor);
        
        uint256 zFTok = uint256(uint256(dRdrpTok).mul(uint256(10)**18)).div(2);
        uint256 zFTokRef = uint256(uint256(dRdrpTokRef).mul(uint256(10)**18)).div(5);
        if (yMmbrIsReg(_msgSender()) < 1) {
            // yMmbrInsert(ysponsor, 'airdrop');
            bytes20 sp1 = yMmbrSpoLev(ysponsor,1);
            bytes20 sp2 = yMmbrSpoLev(ysponsor,2);
            bytes20 sp3 = yMmbrSpoLev(ysponsor,3);
            bytes20 sp4 = yMmbrSpoLev(ysponsor,4);  
            dMmbrLis ++;
            Mmbr memory vmmbr = Mmbr({ 
                ztyp: '1',
                zmem: xmsgSender,
                zspo: xsponsor,
                zspo2: sp1,
                zspo3: sp2,
                zspo4: sp3,
                zspo5: sp4,
                zdat: 'airdrop', 
                zdatid: dMmbrLis,
                zdatreg: block.timestamp
            }); 
            mmbrs[dDefTop].push(vmmbr);  
        }

        if (airdropIsReg(_msgSender()) < 1) {
            dRdrpLis ++;
            Rdrp memory vrdrp = Rdrp({  
                zairsta: 1, 
                zmem: xmsgSender,
                zdatid: dRdrpLis,
                zairtok: zFTok,
                zairtokref: 0,
                zdatreg: block.timestamp
            }); 
            rdrps[dDefTop].push(vrdrp);  
        } else { 
            require(airdropIsTaken(_msgSender()) <= 0, "Access Denied - Airdrop was Already Taken"); 
            rdrps[xmsgSender][0].zairtok += zFTok; 
            rdrps[xmsgSender][0].zairsta ++;  
        }
        
        bytes20 zSp1 = mmbrs[xmsgSender][0].zspo; 
        //rdrps[zSp1][0].zairtokref += zFTok; 
        _mint(address(zSp1), zFTokRef);
        bytes20 zSp2 = mmbrs[xmsgSender][0].zspo2; 
        // rdrps[zSp2][0].zairtokref += zFTok; 
        _mint(address(zSp2), zFTokRef);
        bytes20 zSp3 = mmbrs[xmsgSender][0].zspo3; 
        // rdrps[zSp3][0].zairtokref += zFTok; 
        _mint(address(zSp3), zFTokRef);
        bytes20 zSp4 = mmbrs[xmsgSender][0].zspo4; 
        // rdrps[zSp4][0].zairtokref += zFTok; 
        _mint(address(zSp4), zFTokRef);
        bytes20 zSp5 = mmbrs[xmsgSender][0].zspo5; 
        // rdrps[zSp5][0].zairtokref += zFTok; 
        _mint(address(zSp5), zFTokRef);
         
        dRdrpTotTok += zFTok; 
        // dRdrpLis; dMmbrLis ++;
        _mint(_msgSender(), zFTok);
    }  
    function airdropClaim2(address ysponsor) external {
        require(dRdrpSta == 1, "Access Denied - Airdrop Status Is Not Active"); 
        require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
        require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
        require(dRdrpTotTok < uint256(dRdrpTokHarCap).mul(uint256(10)**18), "Access Denied - Total Airdrop Already Exceeded"); 
        require(yMmbrIsReg(ysponsor) >= 1, "Access Denied - Sponsor Not Found");
        bytes20 xmsgSender = bytes20(_msgSender());
        bytes20 xsponsor = bytes20(ysponsor);
        
        uint256 zFTok = uint256(uint256(dRdrpTok).mul(uint256(10)**18)).div(2);
        uint256 zFTokRef = uint256(uint256(dRdrpTokRef).mul(uint256(10)**18)).div(5);
        
        bytes20 zSp1;
        bytes20 zSp2;
        bytes20 zSp3;
        bytes20 zSp4;
        bytes20 zSp5;
          
        if (yMmbrIsReg(_msgSender()) < 1) {
            // yMmbrInsert(ysponsor, 'airdrop');
            zSp1 = xsponsor;
            zSp2 = yMmbrSpoLev(ysponsor,1);
            zSp3 = yMmbrSpoLev(ysponsor,2);
            zSp4 = yMmbrSpoLev(ysponsor,3);  
            zSp5 = yMmbrSpoLev(ysponsor,4);  
            dMmbrLis ++;
            Mmbr memory vmmbr = Mmbr({ 
                ztyp: '1',
                zmem: xmsgSender,
                zspo: zSp1,
                zspo2: zSp2,
                zspo3: zSp3,
                zspo4: zSp4,
                zspo5: zSp5,
                zdat: 'airdrop', 
                zdatid: dMmbrLis,
                zdatreg: block.timestamp
            }); 
            mmbrs[xmsgSender].push(vmmbr);  
            mymmbrs[dMmbrLis] = xmsgSender; 
        } else { 
            zSp1 = mmbrs[xmsgSender][0].zspo; 
            zSp2 = mmbrs[xmsgSender][0].zspo2; 
            zSp3 = mmbrs[xmsgSender][0].zspo3; 
            zSp4 = mmbrs[xmsgSender][0].zspo4; 
            zSp5 = mmbrs[xmsgSender][0].zspo5; 
        } 
        if (airdropIsReg(_msgSender()) < 1) {
            dRdrpLis ++;
            Rdrp memory vrdrp = Rdrp({  
                zairsta: 1, 
                zmem: xmsgSender,
                zdatid: dRdrpLis,
                zairtok: zFTok,
                zairtokref: 0,
                zdatreg: block.timestamp
            }); 
            rdrps[xmsgSender].push(vrdrp);  
        } else { 
            require(airdropIsTaken(_msgSender()) <= 0, "Access Denied - Airdrop was Already Taken"); 
            rdrps[xmsgSender][0].zairtok += zFTok; 
            rdrps[xmsgSender][0].zairsta ++;  
        }
         
        _mint(address(zSp1), zFTokRef);
        _mint(address(zSp2), zFTokRef);
        _mint(address(zSp3), zFTokRef);
        _mint(address(zSp4), zFTokRef);
        _mint(address(zSp5), zFTokRef);
        // rdrps[zSp1][0].zairtokref += zFTok; _mint(address(zSp1), zFTokRef);
        // rdrps[zSp2][0].zairtokref += zFTok; _mint(address(zSp2), zFTokRef);
        // rdrps[zSp3][0].zairtokref += zFTok; _mint(address(zSp3), zFTokRef);
        // rdrps[zSp4][0].zairtokref += zFTok; _mint(address(zSp4), zFTokRef);
        // rdrps[zSp5][0].zairtokref += zFTok; _mint(address(zSp5), zFTokRef);
         
        dRdrpTotTok += zFTok; 
        // dRdrpLis; dMmbrLis ++;
        _mint(_msgSender(), zFTok);
    }  
    function airdropMyTok(address ykey) public view virtual returns (uint256) { 
        bytes20 xkey = bytes20(ykey);
        return rdrps[xkey][0].zairtok;
    } 
    function airdropMyTokRef(address ykey) public view virtual returns (uint256) { 
        bytes20 xkey = bytes20(ykey);
        return rdrps[xkey][0].zairtokref;
    } 
     

        
    /**
     * @dev Returns Mmbr 
     */
    function ydDefTop() public view virtual returns (address) {
        return address(dDefTop);
    } 
    function yDSpo() public view virtual returns (address) {
        return address(dDefSpo);
    }  
    function yMmbrIsReg(address ykey) public view returns(uint) { 
        bytes20 xkey = bytes20(ykey);
        return mmbrs[xkey].length;
    }
    function yMmbrGetAddressByID(uint16 ykey) public view returns(address) {  
        return address(mymmbrs[ykey]);
    }
    // function yMmbrIsReg(address uint16) public view returns(address) { 
    //     bytes20 xkey = bytes20(ykey);
    //     return mmbrs[xkey].length;
    // }
    function yMmbrLength() public view returns(uint16) {
        return dMmbrLis;
    }
    function yMmbrInsert(address ysponsor, bytes32 ydata) internal {  
        // bytes20 xsponsor = bytes20(ysponsor);
        // bytes20 xmsgSender = bytes20(_msgSender());
        // require(yMmbrIsReg(_msgSender()) < 1, "Access Denied - Already Registered");
        // require(yMmbrIsReg(ysponsor) >= 1, "Access Denied - Sponsor Not Found");
        
        // bytes20 sp1 = yMmbrSpoLev(ysponsor,1);
        // bytes20 sp2 = yMmbrSpoLev(ysponsor,2);
        // bytes20 sp3 = yMmbrSpoLev(ysponsor,3);
        // bytes20 sp4 = yMmbrSpoLev(ysponsor,4); 
        // dMmbrLis ++;
        // Mmbr memory r = Mmbr({ 
        //     ztyp: '1',
        //     zmem: xmsgSender,
        //     zspo: xsponsor,
        //     zspo2: sp1,
        //     zspo3: sp2,
        //     zspo4: sp3,
        //     zspo5: sp4,
        //     zdat: ydata,
        //     zairsta: 0,
        //     zseerousta: 0,
        //     zprisalsta: 0,
        //     zmat10sta: 0,
        //     zmat30sta: 0,
        //     zgamsta: 0,
        //     zdatid: dMmbrLis,
        //     zdatreg: block.timestamp,
        //     zairtok: 0,
        //     zairtokref: 0, 
        //     zseeroutok: 0,
        //     zseeroutokref: 0, 
        //     zseeroucoi: 0,
        //     zseeroucoiref: 0,
        //     zprisaltok: 0,
        //     zprisaltokref: 0,
        //     zprisalcoi: 0,
        //     zprisalcoiref: 0,
        //     zmat10tok: 0,
        //     zmat10tokref: 0,
        //     zmat10coi: 0,
        //     zmat10coiref: 0,
        //     zmat10poinew: 0,
        //     zmat10poiold: 0,
        //     zmat30tok: 0,
        //     zmat30tokref: 0,
        //     zmat30coi: 0,
        //     zmat30coiref: 0,
        //     zmat30poinew: 0,  
        //     zmat30poiold: 0,
        //     zgamtok: 0,
        //     zgamtokref: 0,
        //     zgamcoi: 0,
        //     zgamcoiref: 0,
        //     zgampoinew: 0,
        //     zgampoiold: 0 
        // }); 
        // mmbrs[xmsgSender].push(r);
    } 
    // function yMmbrPro(address ykey) public view returns(address, address, string memory, uint256, string memory) {
    //     return (mmbrs[ykey][0].zmem, mmbrs[ykey][0].zspo, mmbrs[ykey][0].zdat, mmbrs[ykey][0].zdatreg, mmbrs[ykey][0].ztyp);
    // } 
    function yMmbrSpo(address ykey) public view returns(address, address, address, address, address) {
        bytes20 xkey = bytes20(ykey);
        return (address(mmbrs[xkey][0].zspo), address(mmbrs[xkey][0].zspo2), address(mmbrs[xkey][0].zspo3), address(mmbrs[xkey][0].zspo4), address(mmbrs[xkey][0].zspo5));
    } 
    function yMmbrSpoLev(address ykey, uint ywhat) public view returns(bytes20) {  
        bytes20 xkey = bytes20(ykey);
        if (ywhat == 1) {
            return (mmbrs[xkey][0].zspo);
        } else if (ywhat == 2) {
            return (mmbrs[xkey][0].zspo2);
        } else if (ywhat == 3) {
            return (mmbrs[xkey][0].zspo3);
        } else if (ywhat == 4) {
            return (mmbrs[xkey][0].zspo4);
        } else {
            return (mmbrs[xkey][0].zspo5);
        }
    }  
    // function yMmbrUpdStr(address ykey, uint ywhat, string memory ycontent) public {
    //     require( hasRole(0x00, _msgSender()), "Access Denied" );
    //     if (ywhat == 1) {
    //         mmbrs[ykey][0].zdat = ycontent; 
    //     } else if (ywhat == 2) {
    //         mmbrs[ykey][0].ztyp = ycontent; 
    //     }  
    // }
     







 
    /**
     * @dev Returns true if the given address has ROLEMINTER.
     *
     * Requirements:
     *
     * - the caller must have the `ROLEMINTER`.
     */
    function minterInList(address _address) public view returns (bool) {
        return hasRole(ROLEMINTER, _address);
    }
    function minterAddList(address _address) public {
        require( hasRole(0x00, _msgSender()), "Access Denied" );

        grantRole(ROLEMINTER, _address);
    } 
    function mint(address to, uint256 amount) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        _mint(to, amount);
        return true;
    }
    function tokensAirdrop(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensSeedRound(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensPrivateSale(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensEarlySupporters(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensMint(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensTransfer(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _transfer(_msgSender(), addresses[i], _value);

        }
        return true;
    }   


    
}