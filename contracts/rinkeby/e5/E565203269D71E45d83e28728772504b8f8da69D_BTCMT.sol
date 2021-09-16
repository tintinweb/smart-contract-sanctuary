// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        require(account != address(0), "ERC20: mint to the zero address");

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

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

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
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IBTCMT.sol";

contract BTCMT is ERC20Burnable, AccessControl, IBTCMT {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant _ROUND_LEN = 604800;
    uint256 private constant _NUMBER_OF_ROUNDS = 500;

    mapping (address => mapping (address => uint256)) public lockedAllowances;
    mapping (address => uint256) public index;
    mapping (address => TimeAndAmount[]) public allMints;

    uint256 private _lockedTotalSupply;
    mapping (address => uint256) private _lockedAmounts;
    mapping (address => bool) private _farms;

    struct TimeAndAmount {
        uint256 time;
        uint256 total;
        uint256 alreadyUnlocked;
        uint256 transferredAsLocked;
    }
 
    constructor() ERC20("Minto Bitcoin Hashrate Token", "BTCMT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function balanceOfSum (address account) external override view returns (uint256) {
        return super.balanceOf(account) + _lockedAmounts[account];
    }

    function balanceOfLocked (address account) external view returns (uint256) {
        return _lockedAmounts[account] - _vision(account);
    }

    function allMintsLength (address account) external view returns (uint256) {
        return allMints[account].length;
    }

    function addFarm (address farm) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(farm != address(0), "Cannot set zero address as farm");
        _farms[farm] = true;
        emit FarmStatusChanged(farm, true);
    }

    function removeFarm (address farm) onlyRole(DEFAULT_ADMIN_ROLE) external {
        _farms[farm] = false;
        emit FarmStatusChanged(farm, false);
    }

    function mintLocked (address to, uint256 amount, uint256 timeInWeeks) onlyRole(MINTER_ROLE) external {
        require(to != address(0), "Cannot mint to zero address");
        require(timeInWeeks <= _NUMBER_OF_ROUNDS, "Cannot set this time to unlock");
        if (timeInWeeks == 0) {
            _mint(to, amount);
        }
        else {
            _lockedTotalSupply += amount;
            _lockedAmounts[to] += amount;
            uint256 totalToMint = (amount * _NUMBER_OF_ROUNDS) / timeInWeeks;
            allMints[to].push (TimeAndAmount(block.timestamp, totalToMint, 0, totalToMint - amount));
            emit TransferLocked(address(0), to, amount);
        }
    }

    function burnLocked (uint256 amount) external {
        _burnLocked(_msgSender(), amount);
    }

    function burnFromLocked (address from, uint256 amount) external {
        require(lockedAllowances[from][_msgSender()] >= amount, "Not enough locked token allowance");
        _approveLocked(from, _msgSender(), lockedAllowances[from][_msgSender()] - amount);
        _burnLocked(from, amount);
    }

    function approveLocked (address to, uint256 amount) external {
        _approveLocked(_msgSender(), to, amount);
    }

    function increaseLockedAllowance (address to, uint256 amount) external {
        _approveLocked(_msgSender(), to, lockedAllowances[_msgSender()][to] + amount);
    }

    function decreaseLockedAllowance (address to, uint256 amount) external {
        require(lockedAllowances[_msgSender()][to] >= amount, "Allowance would be below zero");
        _approveLocked(_msgSender(), to, lockedAllowances[_msgSender()][to] - amount);
    }

    function transferLocked (address to, uint256 amount) external {
        require(!(_farms[to]), "Cannot transfer to farm");
        _transferLocked(_msgSender(), to, amount);
    }

    function transferFromLocked (address from, address to, uint256 amount) external {
        require(!(_farms[to]), "Cannot transfer to farm");
        require(lockedAllowances[from][_msgSender()] >= amount, "Not enough locked token allowance");
        _approveLocked(from, _msgSender(), lockedAllowances[from][_msgSender()] - amount);
        _transferLocked(from, to, amount);
    }

    function transferFarm (address to, uint256 amountLocked, uint256 amountUnlocked, uint256[] calldata farmIndexes) external override returns (uint256[] memory) {
        address from = _msgSender();
        require(_farms[from], "Sender is not a farm");
        _transfer(from, to, amountUnlocked);
        uint256[] memory newIndexes = _transferLockedForFarm(from, to, amountLocked, farmIndexes);
        if (_lockedAmounts[to] > 0) {
            unlock(to, 0);
        }
        return newIndexes;
    }

    function transferFromFarm (address from, uint256 amountLocked, uint256 amountUnlocked) external override returns (uint256[] memory) {
        address to = _msgSender();
        require(_farms[to], "Sender is not a farm");
        require(lockedAllowances[from][to] >= amountLocked, "Not enough locked token allowance");
        _approveLocked(from, to, lockedAllowances[from][to] - amountLocked);
        uint256 len = allMints[to].length;
        _transferLocked(from, to, amountLocked);
        uint256[] memory m = new uint256[](allMints[to].length - len);
        for (uint256 i = len; i < allMints[to].length; i++) {
            m[i - len] = i;
        }
        transferFrom(from, to, amountUnlocked);
        return (m);
    }

    function totalSupply() public view override(ERC20,IERC20) returns (uint256) {
        return super.totalSupply() + _lockedTotalSupply;
    }

    function balanceOf (address account) public view override(ERC20,IERC20) returns (uint256) {
        return super.balanceOf(account) + _vision(account);
    }

    function unlock (address who, uint256 numberOfBlocks) public {
        require(!(_farms[who]), "Cannot unlock farm");
        require(_lockedAmounts[who] > 0, "No tokens locked");
        uint256 l = allMints[who].length;
        uint256 i = index[who];
        require(i + numberOfBlocks <= l, "Cannot unlock this many blocks, exceeds length");
        uint256 toUnlockTotal = 0;
        if (numberOfBlocks == 0 ) {
            numberOfBlocks = l;
        }
        else {
            numberOfBlocks += i;
        }
        for (i; i < numberOfBlocks; i++) {
            uint256 _total = allMints[who][i].total;
            uint256 _alreadyUnlocked = allMints[who][i].alreadyUnlocked;
            uint256 _transferredAsLocked = allMints[who][i].transferredAsLocked;
            if ( (_alreadyUnlocked + _transferredAsLocked >= _total) && index[who] == i) {
                index[who] = i+1;
                delete allMints[who][i];
            }
            else {
                uint256 rounds = ((block.timestamp - allMints[who][i].time) / _ROUND_LEN);
                if(rounds > 0) {
                    uint256 toUnlock = _total * rounds / _NUMBER_OF_ROUNDS;
                    if (_alreadyUnlocked < toUnlock) {
                        toUnlock = toUnlock - _alreadyUnlocked;
                    }
                    else {
                        toUnlock = 0;
                    }
                    if (toUnlock > 0) {
                        uint256 allowed = _total - (_transferredAsLocked + _alreadyUnlocked);
                        if (allowed > 0) {
                            if (toUnlock > allowed){
                                toUnlock = allowed;
                            }
                            allMints[who][i].alreadyUnlocked = _alreadyUnlocked + toUnlock;
                            toUnlockTotal += toUnlock;
                            if ( (allMints[who][i].alreadyUnlocked + _transferredAsLocked >= _total) && index[who] == i){
                                index[who] = i+1;
                                delete allMints[who][i];
                            }
                        }
                    }
                }
            }
        }
        _lockedAmounts[who] -= toUnlockTotal;
        _lockedTotalSupply -= toUnlockTotal;
        emit TransferLocked(who, address(0), toUnlockTotal);
        _mint(who, toUnlockTotal);
    }

    function _beforeTokenTransfer (address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0) && !(_farms[from]) && !(_farms[to]) && super.balanceOf(from) < amount && _lockedAmounts[from] > 0) {
            unlock(from, 0);
        }
    }

    function _vision (address who) private view returns (uint256) {
        uint256 toUnlockTotal = 0;
        for (uint256 i = index[who]; i < allMints[who].length; i++) {
            uint256 _total = allMints[who][i].total;
            uint256 _alreadyUnlocked = allMints[who][i].alreadyUnlocked;
            uint256 _transferredAsLocked = allMints[who][i].transferredAsLocked;
            uint256 rounds = ((block.timestamp - allMints[who][i].time) / _ROUND_LEN);
            if(rounds > 0) {
                uint256 toUnlock = _total * rounds / _NUMBER_OF_ROUNDS;
                if (_alreadyUnlocked < toUnlock) {
                    toUnlock = toUnlock - _alreadyUnlocked;
                }
                else {
                    toUnlock = 0;
                }
                if (toUnlock > 0) {
                    uint256 allowed = _total - (_transferredAsLocked + _alreadyUnlocked);
                    if (allowed > 0) {
                        if (toUnlock > allowed){
                            toUnlock = allowed;
                        }
                        toUnlockTotal += toUnlock;
                    }
                }
            }
        }
        return toUnlockTotal;
    }

    function _burnLocked (address from, uint256 amount) private {
        require(from != address(0), "Cannot burn from zero address");
        unlock(from, 0);
        require(_lockedAmounts[from] >= amount, "Not enough locked token to burn");
        _burnLoop(from, address(0), amount);
    }

    function _approveLocked (address from, address to, uint256 amount) private {
        require(from != address(0), "Cannot approve from zero address");
        require(to != address(0), "Cannot approve to zero address");
        lockedAllowances[from][to] = amount;
        emit ApprovalLocked(from, to, amount);
    }

    function _transferLocked (address from, address to, uint256 amount) private {
        uint256[] memory indexes = new uint256[](0);
        _transferLockedForFarm(from, to, amount, indexes);
    }

    function _transferLockedForFarm (address from, address to, uint256 amount, uint256[] memory indexes) private returns (uint256[] memory newIndexes) {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");
        if (!(_farms[from]) && _lockedAmounts[from] > 0){
            unlock(from, 0);
        }
        require(_lockedAmounts[from] >= amount, "Not enough locked token to transfer");
        if (_farms[from]) {
            newIndexes = _burnLoopForFarm(from, to, amount, indexes);
            return newIndexes;
        }
        else {
            _burnLoop(from, to, amount);
        }
    }

    function _burnLoop (address from, address to, uint256 amount) private {
        uint256[] memory indexes = new uint256[](0);
        _burnLoopForFarm(from, to, amount, indexes);
    }

    function _burnLoopForFarm (address from, address to, uint256 amount, uint256[] memory indexes) private returns (uint256[] memory newIndexes){
        _lockedAmounts[from] -= amount;
        if (to == address(0)) {
            _lockedTotalSupply -= amount;
        }
        else {
            _lockedAmounts[to] += amount;
        }
        emit TransferLocked(from, to, amount);
        bool farmWithdrawal = false;
        uint256 i;
        if (_farms[from]) {
            farmWithdrawal = true;
        }
        if (farmWithdrawal) {
            i = indexes.length;
        }
        else {
            i = allMints[from].length;
        }
        for (i; i > 0; i--) {
            if (amount > 0) {
                uint256 _time;
                uint256 _total;
                uint256 _alreadyUnlocked;
                uint256 _transferredAsLocked;
                uint256 avaliable;
                if (farmWithdrawal) {
                    _time = allMints[from][indexes[i-1]].time;
                    _total = allMints[from][indexes[i-1]].total;
                    _alreadyUnlocked = allMints[from][indexes[i-1]].alreadyUnlocked;
                    _transferredAsLocked = allMints[from][indexes[i-1]].transferredAsLocked;
                    avaliable = _total - (_alreadyUnlocked + _transferredAsLocked);
                }
                else {
                    _time = allMints[from][i-1].time;
                    _total = allMints[from][i-1].total;
                    _alreadyUnlocked = allMints[from][i-1].alreadyUnlocked;
                    _transferredAsLocked = allMints[from][i-1].transferredAsLocked;
                    avaliable = _total - (_alreadyUnlocked + _transferredAsLocked);
                }
                if (avaliable > 0) {
                    uint256 toTransfer;
                    if (avaliable > amount) {
                        toTransfer = amount;
                    }
                    else {
                        toTransfer = avaliable;
                    }
                    amount -= toTransfer;
                    if (to != address(0)) {
                        allMints[to].push (TimeAndAmount (_time, _total, _alreadyUnlocked + (avaliable - toTransfer), _transferredAsLocked));
                    }
                    if (farmWithdrawal) {
                        allMints[from][indexes[i-1]].transferredAsLocked = _transferredAsLocked + toTransfer;
                    }
                    else {
                        allMints[from][i-1].transferredAsLocked = _transferredAsLocked + toTransfer;
                    }
                }
            }
        }
        if (farmWithdrawal) {
            uint256 l = indexes.length;
            newIndexes = new uint256[](l);
            if (l > 0) {
                uint256 indexu = 0;
                for (i=0; i < l; i++) {
                    if ((allMints[from][indexes[i]].alreadyUnlocked + allMints[from][indexes[i]].transferredAsLocked) >= allMints[from][indexes[i]].total) {
                        delete allMints[from][indexes[i]];
                    }
                    else {
                        newIndexes[indexu]=indexes[i];
                        indexu++;
                    }
                }
                uint256 toReduce = l - indexu;
                assembly { mstore(newIndexes, sub(mload(newIndexes), toReduce)) }
            }
            return newIndexes;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBTCMT is IERC20 {

    event FarmStatusChanged (address indexed farm, bool isFarmNow);

    event TransferLocked (address indexed from, address indexed to, uint256 amount);

    event ApprovalLocked (address indexed owner, address indexed spender, uint256 amount);

    function balanceOfSum (address account) external view returns (uint256);

    function transferFarm (address to, uint256 amountLocked, uint256 amountUnlocked, uint256[] calldata farmIndexes) external returns (uint256[] memory);

    function transferFromFarm (address from, uint256 amountLocked, uint256 amountUnlocked) external returns (uint256[] memory);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}