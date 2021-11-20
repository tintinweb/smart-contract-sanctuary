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

pragma solidity 0.8.4;

interface ITransferRules {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    function detectTransferRestriction(
        address token,
        address from,
        address to,
        uint256 value
    ) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    function messageForTransferRestriction(uint8 restrictionCode)
        external
        view
        returns (string memory);

    function checkSuccess(uint8 restrictionCode) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ITransferRules.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Restricted Token
/// @author CoMakery, Inc.
/// @notice An ERC-20 token with ERC-1404 transfer restrictions for managing security tokens, etc.
contract RestrictedToken is ERC20, AccessControl {
  uint8 public _decimals;
  ITransferRules public transferRules;

  bytes32 private constant CONTRACT_ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
  bytes32 private constant TRANSFER_ADMIN_ROLE = keccak256("TRANSFER_ADMIN");
  bytes32 private constant WALLETS_ADMIN_ROLE = keccak256("WALLET_ADMIN");
  bytes32 private constant RESERVE_ADMIN_ROLE = keccak256("RESERVE_ADMIN");

  uint256 public maxTotalSupply;
  uint256 public contractAdminCount;

  struct LockUntil {
      uint256 timestamp; // unix timestamp to lock funds until
      uint256 minBalance; // minimal balance that has to remain at the address until the timestamp
  }

  // Transfer restriction "eternal storage" mappings that can be used by future TransferRules contract upgrades
  // They are accessed through getter and setter methods
  mapping(address => uint256) private _maxBalances;
  mapping(address => LockUntil[]) private _locksUntil;
  mapping(address => uint256) private _transferGroups; // restricted groups like Reg D Accredited US, Reg CF Unaccredited US and Reg S Foreign
  mapping(uint256 => mapping(uint256 => uint256)) private _allowGroupTransfers; // approve transfers between groups: from => to => TimeLockUntil
  mapping(address => bool) private _frozenAddresses;

  bool public isPaused = false;

  uint256 public constant MAX_UINT256 = ((2 ** 255 - 1) * 2) + 1; // get max uint256 without overflow
  uint256 public constant MAX_TIMELOCKS = 32; // maximum supported number of token timelocks

  event RoleChange(address indexed grantor, address indexed grantee, string role, bool indexed status);
  event AddressMaxBalance(address indexed admin, address indexed addr, uint256 indexed value);
  event AddressTimeLockAdded(address indexed admin, address indexed addr, uint256 indexed timestamp, uint256 value);
  event AddressTimeLockRemoved(address indexed admin, address indexed addr, uint256 indexed timestamp, uint256 unlockedValue);
  event AddressTimeLockExpired(address indexed addr, uint256 indexed timestamp, uint256 unlockedValue);
  event AddressTransferGroup(address indexed admin, address indexed addr, uint256 indexed value);
  event AddressFrozen(address indexed admin, address indexed addr, bool indexed status);
  event AllowGroupTransfer(address indexed admin, uint256 indexed fromGroup, uint256 indexed toGroup, uint256 lockedUntil);

  event Pause(address admin, bool status);
  event Upgrade(address admin, address oldRules, address newRules);

  constructor(
    address transferRules_,
    address contractAdmin_,
    address tokenReserveAdmin_,
    string memory symbol_,
    string memory name_,
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 maxTotalSupply_
  ) ERC20(name_, symbol_) {
    require(transferRules_ != address(0), "Transfer rules address cannot be 0x0");
    require(contractAdmin_ != address(0), "Token owner address cannot be 0x0");
    require(tokenReserveAdmin_ != address(0), "Token reserve admin address cannot be 0x0");

    // Transfer rules can be swapped out for a new contract inheriting from the ITransferRules interface
    // The "eternal storage" for rule data stays in this RestrictedToken contract for use by TransferRules contract upgrades
    transferRules = ITransferRules(transferRules_);
    _decimals = decimals_;
    maxTotalSupply = maxTotalSupply_;

    _setupRole(CONTRACT_ADMIN_ROLE, contractAdmin_);
    _setupRole(RESERVE_ADMIN_ROLE, tokenReserveAdmin_);
    contractAdminCount = 1;

    _mint(tokenReserveAdmin_, totalSupply_);
  }

  modifier onlyContractAdmin() {
    require(hasRole(CONTRACT_ADMIN_ROLE, msg.sender), "DOES NOT HAVE CONTRACT ADMIN ROLE");
    _;
  }

   modifier onlyTransferAdmin() {
    require(hasRole(TRANSFER_ADMIN_ROLE, msg.sender), "DOES NOT HAVE TRANSFER ADMIN ROLE");
    _;
  }

   modifier onlyWalletsAdmin() {
    require(hasRole(WALLETS_ADMIN_ROLE, msg.sender), "DOES NOT HAVE WALLETS ADMIN ROLE");
    _;
  }

   modifier onlyReserveAdmin() {
    require(hasRole(RESERVE_ADMIN_ROLE, msg.sender), "DOES NOT HAVE RESERVE ADMIN ROLE");
    _;
  }

  modifier onlyWalletsAdminOrReserveAdmin() {
    require((hasRole(WALLETS_ADMIN_ROLE, msg.sender) || hasRole(RESERVE_ADMIN_ROLE, msg.sender)),
    "DOES NOT HAVE WALLETS ADMIN OR RESERVE ADMIN ROLE");
    _;
  }

  modifier validAddress(address addr) {
    require(addr != address(0), "Address cannot be 0x0");
    _;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /// @dev Authorizes an address holder to write transfer restriction rules
  /// @param addr The address to grant transfer admin rights to
  function grantTransferAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    grantRole(TRANSFER_ADMIN_ROLE, addr);
    emit RoleChange(msg.sender, addr, "TransferAdmin", true);
  }

  /// @dev Revokes authorization to write transfer restriction rules
  /// @param addr The address to grant transfer admin rights to
  function revokeTransferAdmin(address addr) external validAddress(addr) onlyContractAdmin  {
    revokeRole(TRANSFER_ADMIN_ROLE, addr);
    emit RoleChange(msg.sender, addr, "TransferAdmin", false);
  }

  /// @dev Checks if an address is an authorized transfer admin.
  /// @param addr The address to check for transfer admin privileges.
  /// @return hasPermission returns true if the address has transfer admin permission and false if not.
  function checkTransferAdmin(address addr) external view returns(bool hasPermission) {
    return hasRole(TRANSFER_ADMIN_ROLE, addr);
  }

  /// @dev Authorizes an address holder to grant and revoke rights and restrictions for \
  ///      individual wallets, including assignment into groups.
  /// @param addr The address to grant wallets admin rights to
  function grantWalletsAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    grantRole(WALLETS_ADMIN_ROLE, addr);
    emit RoleChange(msg.sender, addr, "WalletsAdmin", true);
  }

  /// @dev Revokes authorization to grant and revoke rights and restrictions for \
  ///      individual wallets, including assignment into groups.
  /// @param addr The address to revoke wallets admin rights from.
  function revokeWalletsAdmin(address addr) external validAddress(addr) onlyContractAdmin  {
    revokeRole(WALLETS_ADMIN_ROLE, addr);
    emit RoleChange(msg.sender, addr, "WalletsAdmin", false);
  }

  /// @dev Checks if an address is an authorized wallets admin.
  /// @param addr The address to check for wallets admin privileges.
  /// @return hasPermission returns true if the address has wallets admin permission and false if not.
  function checkWalletsAdmin(address addr) external view returns(bool hasPermission) {
    return hasRole(WALLETS_ADMIN_ROLE, addr);
  }

  /// @dev Authorizes an address holder to mint and burn tokens, and to freeze individual addresses
  /// @param addr The address to grant reserve admin rights to.
  function grantReserveAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    grantRole(RESERVE_ADMIN_ROLE, addr);
    emit RoleChange(msg.sender, addr, "ReserveAdmin", true);
  }

  /// @dev Revokes authorization to mint and burn tokens, and to freeze individual addresses
  /// @param addr The address to revoke reserve admin rights from.
  function revokeReserveAdmin(address addr) external validAddress(addr) onlyContractAdmin  {
    revokeRole(RESERVE_ADMIN_ROLE, addr);
    emit RoleChange(msg.sender, addr, "ReserveAdmin", false);
  }

  /// @dev Checks if an address is an authorized reserve admin.
  /// @param addr The address to check for reserve admin privileges.
  /// @return hasPermission returns true if the address has reserve admin permission and false if not.
  function checkReserveAdmin(address addr) external view returns(bool hasPermission) {
    return hasRole(RESERVE_ADMIN_ROLE, addr);
  }

  /// @dev Authorizes an address holder to be a contract admin. Contract admins grant privileges to accounts.
  /// Contract admins can mint/burn tokens and freeze accounts.
  /// @param addr The address to grant transfer admin rights to.
  function grantContractAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    grantRole(CONTRACT_ADMIN_ROLE, addr);
    contractAdminCount += 1;
    emit RoleChange(msg.sender, addr, "ContractAdmin", true);
  }

  /// @dev Revokes authorization as a contract admin.
  /// The contract requires there is at least 1 Contract Admin to avoid locking the Contract Admin functionality.
  /// @param addr The address to remove contract admin rights from
  function revokeContractAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    require(contractAdminCount > 1, "Must have at least one contract admin");
    revokeRole(CONTRACT_ADMIN_ROLE, addr);
    contractAdminCount -= 1;
    emit RoleChange(msg.sender, addr, "ContractAdmin", false);
  }

  /// @dev Checks if an address is an authorized contract admin.
  /// @param addr The address to check for contract admin privileges.
  /// @return hasPermission returns true if the address has contract admin permission and false if not.
  function checkContractAdmin(address addr) external view returns(bool hasPermission) {
    return hasRole(CONTRACT_ADMIN_ROLE, addr);
  }

  /// @dev Enforces transfer restrictions managed using the ERC-1404 standard functions.
  /// The TransferRules contract defines what the rules are. The data inputs to those rules remains in the RestrictedToken contract.
  /// TransferRules is a separate contract so its logic can be upgraded.
  /// @param from The address the tokens are transferred from
  /// @param to The address the tokens would be transferred to
  /// @param value the quantity of tokens to be transferred
  function enforceTransferRestrictions(address from, address to, uint256 value) private view {
    uint8 restrictionCode = detectTransferRestriction(from, to, value);
    require(transferRules.checkSuccess(restrictionCode), messageForTransferRestriction(restrictionCode));
  }

  /// @dev Calls the TransferRules detectTransferRetriction function to determine if tokens can be transferred.
  /// detectTransferRestriction returns a status code.
  /// @param from The address the tokens are transferred from
  /// @param to The address the tokens would be transferred to
  /// @param value The quantity of tokens to be transferred
  function detectTransferRestriction(address from, address to, uint256 value) public view returns(uint8) {
    return transferRules.detectTransferRestriction(address(this), from, to, value);
  }

  /// @dev Calls TransferRules to lookup a human readable error message that goes with an error code.
  /// @param restrictionCode is an error code to lookup an error code for
  function messageForTransferRestriction(uint8 restrictionCode) public view returns(string memory) {
    return transferRules.messageForTransferRestriction(restrictionCode);
  }

  /// @dev Sets the maximum number of tokens an address will be allowed to hold.
  /// Addresses can hold 0 tokens by default.
  /// @param addr The address to restrict
  /// @param updatedValue the maximum number of tokens the address can hold
  function setMaxBalance(address addr, uint256 updatedValue) public validAddress(addr) onlyWalletsAdmin {
    _maxBalances[addr] = updatedValue;
    emit AddressMaxBalance(msg.sender, addr, updatedValue);
  }

  /// @dev Gets the maximum number of tokens an address is allowed to hold
  /// @param addr The address to check restrictions for
  function getMaxBalance(address addr) external view returns(uint256) {
    return _maxBalances[addr];
  }

  /// @dev Lock the minimum amount of tokens in the address from being transfered until the specified time
  /// @param addr The address to restrict
  /// @param timestamp The time the tokens will be locked until as a Unix timetsamp.
  /// Unix timestamp is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  /// @param minBalance Tokens reserved in the wallet until the specified time. Reservations are exclusive
  function addLockUntil(address addr, uint256 timestamp, uint256 minBalance) public validAddress(addr) onlyWalletsAdmin {
    require(timestamp > block.timestamp, "Lock timestamp cannot be in the past");
    require(minBalance > 0, "Locked balance cannot be zero");

    cleanupTimelocks(addr);

    require(_locksUntil[addr].length < MAX_TIMELOCKS, "Timelock limit exceeded, cannot add more");

    bool timestampFound = false;

    for (uint256 i=0; i < _locksUntil[addr].length; i++) {
      if (_locksUntil[addr][i].timestamp == timestamp) {
        _locksUntil[addr][i].minBalance += minBalance;
        timestampFound = true;
      }
    }

    if (!timestampFound) {
        _locksUntil[addr].push(LockUntil(timestamp, minBalance));
    }

    emit AddressTimeLockAdded(msg.sender, addr, timestamp, minBalance);
  }

  /// @dev A convenience method to remove an addresses timelock, looking one up by timestamp.
  /// @param addr The address to remove the timelock for.
  /// @param timestamp The timestamp for which the timelock has to be removed.
  function removeLockUntilTimestampLookup(address addr, uint256 timestamp) external validAddress(addr) onlyWalletsAdmin {
    uint256 index = findTimelockIndex(addr, timestamp);
    uint256 tokensUnlocked = _locksUntil[addr][index].minBalance;

    _deleteTimelock(addr, index);

    emit AddressTimeLockRemoved(msg.sender, addr, timestamp, tokensUnlocked);
  }

  /// @dev A convenience method to remove an addresses timelock, looking one up by its index on the list.
  /// @param addr The address to remove the timelock for.
  /// @param index The index at which the timelock has to be removed.
  function removeLockUntilIndexLookup(address addr, uint256 index) external validAddress(addr) onlyWalletsAdmin {
    require(_locksUntil[addr].length > index, "Timelock index outside range");

    uint256 timestamp = _locksUntil[addr][index].timestamp;
    uint256 tokensUnlocked = _locksUntil[addr][index].minBalance;

    _deleteTimelock(addr, index);

    emit AddressTimeLockRemoved(msg.sender, addr, timestamp, tokensUnlocked);
  }


  /// @dev Check the total amount of timelocks issued for an address
  /// @param addr The address to check
  /// @return locksTotal The time the address will be locked until.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  function getTotalLocksUntil(address addr) public view returns (uint256 locksTotal) {
    return _locksUntil[addr].length;
  }

  /// @dev Check a particular timelock issued for an address, by index
  /// @param addr The address to check
  /// @param index the index at which the lock is checked
  /// @return lockedUntil The timestamp for the selected lock.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  /// @return balanceLocked The balance reserved by the selected lock.
  function getLockUntilIndexLookup(address addr, uint256 index) public view returns(uint256 lockedUntil, uint256 balanceLocked) {
    require(index < _locksUntil[addr].length, "Index too big, no lock at that index.");

    return (_locksUntil[addr][index].timestamp, _locksUntil[addr][index].minBalance);
  }

  /// @dev Check a particular timelock issued for an address, by timestamp
  /// @param addr The address to check
  /// @param timestamp The particular timestamp to look up
  /// @return lockedUntil The timestamp for the selected lock.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  /// @return balanceLocked The balance reserved by the selected lock.
  function getLockUntilTimestampLookup(address addr, uint256 timestamp) public view returns(uint256 lockedUntil, uint256 balanceLocked) {
    return getLockUntilIndexLookup(addr, findTimelockIndex(addr, timestamp));
  }

  /// @dev Check total balance locked at the given timestamp, across all applicable locks
  /// @param addr The address to check
  /// @param timestamp The timestamp to check the total locks at
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  /// @return balanceLocked The combined amount of tokens reserved until the timestamp.
  function getLockUntilAtTimestamp(address addr, uint256 timestamp) public view returns(uint256 balanceLocked) {
    uint256 totalLocked = 0;

    for (uint256 i=0; i<_locksUntil[addr].length; i++) {
        if (_locksUntil[addr][i].timestamp > timestamp) {
            totalLocked += _locksUntil[addr][i].minBalance;
        }
    }

    return totalLocked;
  }

  /// @dev Checks how many tokens are locked at the time of the request
  /// @param addr The address to check
  /// @return balanceLocked The number of tokens that cannot be accessed now
  function getCurrentlyLockedBalance(address addr) public view returns (uint256 balanceLocked) {
    return getLockUntilAtTimestamp(addr, block.timestamp);
  }

  /// @dev Checks how many tokens are available to move at the time of the request
  /// @param addr The address to check
  /// @return balanceUnlocked The number of tokens that can be accessed now
  function getCurrentlyUnlockedBalance(address addr) external view returns (uint256 balanceUnlocked) {
    uint256 lockedNow = getCurrentlyLockedBalance(addr);

    return balanceOf(addr) - lockedNow;
  }

  /// @dev Set the one group that the address belongs to, such as a US Reg CF investor group.
  /// @param addr The address to set the group for.
  /// @param groupID The uint256 numeric ID of the group.
  function setTransferGroup(address addr, uint256 groupID) public validAddress(addr) onlyWalletsAdmin {
    _transferGroups[addr] = groupID;
    emit AddressTransferGroup(msg.sender, addr, groupID);
  }

  /// @dev Gets the transfer group the address belongs to. The default group is 0.
  /// @param addr The address to check.
  /// @return groupID The group id of the address.
  function getTransferGroup(address addr) external view returns(uint256 groupID) {
    return _transferGroups[addr];
  }

  /// @dev Freezes or unfreezes an address.
  /// Tokens in a frozen address cannot be transferred from until the address is unfrozen.
  /// @param addr The address to be frozen.
  /// @param status The frozenAddress status of the address. True means frozen false means not frozen.
  function freeze(address addr, bool status) public validAddress(addr) onlyWalletsAdminOrReserveAdmin {
    _frozenAddresses[addr] = status;
    emit AddressFrozen(msg.sender, addr, status);
  }

  /// @dev Checks the status of an address to see if its frozen
  /// @param addr The address to check
  /// @return status Returns true if the address is frozen and false if its not frozen.
  function getFrozenStatus(address addr) external view returns(bool status) {
    return _frozenAddresses[addr];
  }

  /// @dev A convenience method for updating the transfer group, lock until, max balance, and freeze status.
  /// The convenience method also helps to reduce gas costs.
  /// @param addr The address to set permissions for.
  /// @param groupID The ID of the address
  /// @param timeLockUntil The unix timestamp that the address should be locked until. Use 0 if it's not locked.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  /// @param lockedBalanceUntil The amount of tokens to be reserved until the timelock expires. Reservation is exclusive.
  /// @param maxBalance Is the maximum number of tokens the account can hold.
  /// @param status The frozenAddress status of the address. True means frozen false means not frozen.
  function setAddressPermissions(address addr, uint256 groupID, uint256 timeLockUntil, uint256 lockedBalanceUntil,
    uint256 maxBalance, bool status) public validAddress(addr) onlyWalletsAdmin {
    setTransferGroup(addr, groupID);
    if (timeLockUntil > 0) {
        addLockUntil(addr, timeLockUntil, lockedBalanceUntil);
    }
    setMaxBalance(addr, maxBalance);
    freeze(addr, status);
  }

  /// @dev Sets an allowed transfer from a group to another group beginning at a specific time.
  /// There is only one definitive rule per from and to group.
  /// @param from The group the transfer is coming from.
  /// @param to The group the transfer is going to.
  /// @param lockedUntil The unix timestamp that the transfer is locked until. 0 is a special number. 0 means the transfer is not allowed.
  /// This is because in the smart contract mapping all pairs are implicitly defined with a default lockedUntil value of 0.
  /// But no transfers should be authorized until explicitly allowed. Thus 0 must mean no transfer is allowed.
  function setAllowGroupTransfer(uint256 from, uint256 to, uint256 lockedUntil) external onlyTransferAdmin {
    _allowGroupTransfers[from][to] = lockedUntil;
    emit AllowGroupTransfer(msg.sender, from, to, lockedUntil);
  }

  /// @dev Checks to see when a transfer between two addresses would be allowed.
  /// @param from The address the transfer is coming from
  /// @param to The address the transfer is going to
  /// @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  function getAllowTransferTime(address from, address to) external view returns(uint timestamp) {
    return _allowGroupTransfers[_transferGroups[from]][_transferGroups[to]];
  }

  /// @dev Checks to see when a transfer between two groups would be allowed.
  /// @param from The group id the transfer is coming from
  /// @param to The group id the transfer is going to
  /// @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  function getAllowGroupTransferTime(uint from, uint to) external view returns(uint timestamp) {
    return _allowGroupTransfers[from][to];
  }

  /// @dev Destroys tokens and removes them from the total supply. Can only be called by an address with a Reserve Admin role.
  /// @param from The address to destroy the tokens from.
  /// @param value The number of tokens to destroy from the address.
  function burn(address from, uint256 value) external validAddress(from) onlyReserveAdmin {
    require(value <= balanceOf(from), "Insufficent tokens to burn");
    _burn(from, value);
  }

  /// @dev Allows the reserve admin to create new tokens in a specified address.
  /// The total number of tokens cannot exceed the maxTotalSupply (the "Hard Cap").
  /// @param to The addres to mint tokens into.
  /// @param value The number of tokens to mint.
  function mint(address to, uint256 value) external validAddress(to) onlyReserveAdmin  {
    require(totalSupply() + value <= maxTotalSupply, "Cannot mint more than the max total supply");
    _mint(to, value);
  }

  /// @dev Allows the contract admin to pause transfers.
  function pause() external onlyContractAdmin() {
    isPaused = true;
    emit Pause(msg.sender, true);
  }

  /// @dev Allows the contract admin to unpause transfers.
  function unpause() external onlyContractAdmin() {
    isPaused = false;
    emit Pause(msg.sender, false);
  }

  /// @dev Allows the contrac admin to upgrade the transfer rules.
  /// The upgraded transfer rules must implement the ITransferRules interface which conforms to the ERC-1404 token standard.
  /// @param newTransferRules The address of the deployed TransferRules contract.
  function upgradeTransferRules(ITransferRules newTransferRules) external onlyTransferAdmin {
    require(address(newTransferRules) != address(0x0), "Address cannot be 0x0");
    address oldRules = address(transferRules);
    transferRules = newTransferRules;
    emit Upgrade(msg.sender, oldRules, address(newTransferRules));
  }

  function transfer(address to, uint256 value)
    public
    override
    validAddress(to)
    returns(bool success)
  {
    require(value <= balanceOf(msg.sender), "Insufficent tokens");
    cleanupTimelocks(msg.sender);
    enforceTransferRestrictions(msg.sender, to, value);
    super.transfer(to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value)
    public
    override validAddress(from)
    validAddress(to)
    returns(bool success)
  {
    require(value <= allowance(from, to), "The approved allowance is lower than the transfer amount");
    require(value <= balanceOf(from), "Insufficent tokens");
    cleanupTimelocks(from);
    enforceTransferRestrictions(from, to, value);
    super.transferFrom(from, to, value);
    return true;
  }

  function safeApprove(address spender, uint256 value) public {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require((value == 0) || (allowance(address(msg.sender), spender) == 0),
        "Cannot approve from non-zero to non-zero allowance"
    );
    approve(spender, value);
  }


  // TIMELOCK UTILITY FUNCTIONS

  /// @dev Locates an index of a particular timelock for a user, by timestamp. Reverts if unable.
  /// @param addr Address for which the timelocks are being searched.
  /// @param timestamp Timestamp at which the required timelock resides.
  /// @return index The index of the timelock in the mapping for that address.
  function findTimelockIndex(address addr, uint256 timestamp) private view returns (uint256 index) {
    for (uint256 i=0; i <_locksUntil[addr].length; i++) {
      if (_locksUntil[addr][i].timestamp == timestamp) {
        return i;
      }
    }

    revert("Coundn't find an index by timestamp: no lock with that timestamp.");
  }

  /// @dev Removes expired timelocks for a user (therefore unlocking the tokens).
  /// @param addr Address for which the timelocks are being cleaned up.
  function cleanupTimelocks(address addr) public {
    // Since we delete efficiently (by moving the last element to replace the one being deleted),
    // we clean up right to left, emitting events and mutating the list on the go.
    // 1. Go right to left
    // 2. If the timelock we're looking at is expired, 
    // -- emit an expiration event before we overwrite the data
    // -- overwrite the element with the last one on the list
    // -- pop the list.
    // 3. Until beginning is reached.

    uint256 totalLocks = getTotalLocksUntil(addr);

    for (uint256 i=0; i < totalLocks; i++) {
        uint256 curInd = totalLocks - 1 - i;
        if (_locksUntil[addr][curInd].timestamp <= block.timestamp) {

          emit AddressTimeLockExpired(
            addr, 
            _locksUntil[addr][curInd].timestamp, 
            _locksUntil[addr][curInd].minBalance
          );

          _deleteTimelock(addr, curInd);
        }
    }
  }

  /// @dev Deletes a timelock given an address and an index. Mutates the list, breaks ordering, 
  // doesn't emit events. Reverts if inputs are wrong.
  /// @param addr Address for which the timelock is being removed.
  /// @param index Index for the timelock being removed.
  function _deleteTimelock(address addr, uint256 index) private {
    require(_locksUntil[addr].length > index, "Timelock index outside range");

    uint256 totalLocks = getTotalLocksUntil(addr);

    // If the element we plan to remove is not the last on the list, we copy the last element over it
    // After that check, we delete the last element
    if (index < totalLocks - 1) {
        _locksUntil[addr][index] = _locksUntil[addr][totalLocks - 1];
    }

    _locksUntil[addr].pop();
  }
}