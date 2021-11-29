/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT
// Version: 1.0.0
pragma solidity 0.8.10;

// Version: 1.0.0





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

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

/**
 * @notice Windmill_Power is the ERC20 token (PWR) representing
 * a share of the fund in the Windmill_Fund contract.
 *
 * There is a primary market that value PWR in the form of
 * mint and burn by the Windmill_Fund contract.
 * In exchange of depositing or withdrawing BUSD from the fund,
 * PWR token are minted to or burned from the user address.
 * The minting/burning value of PWR only depends on the total supply
 * in BUSD in the fund related to the total supply of PWR.
 * This mean that PWR will gain primary value only via
 * Windmill traders performance
 *
 * Also, as PWR is an ERC20 token, it can be freely traded, so secondary
 * markets can exist.
 */
contract Windmill_Power is ERC20, AccessControlEnumerable {
    /**
     * DAO_ROLE is able to grant and revoke roles. It can be used when the DAO
     * vote to change some contracts of Windmill.
     *
     * MINTER_ROLE is able to mint PWR to an address.
     *
     * BURNER_ROLE is able to burn PWR from an address.
     *
     * MOVER_ROLE is able to transfer PWR from an address to another.
     */

    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MOVER_ROLE = keccak256("MOVER_ROLE");

    constructor() ERC20("Windmill_Power", "PWR") {
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
        _setRoleAdmin(MINTER_ROLE, DAO_ROLE);
        _setRoleAdmin(BURNER_ROLE, DAO_ROLE);
        _setRoleAdmin(MOVER_ROLE, DAO_ROLE);
        _setupRole(DAO_ROLE, msg.sender);
    }

    /**
     * @notice Allow the Windmill_Fund to mint PWR for an address

     * Windmill_Fund can use this method to buy PWR in exchange of BUSD
     * This do not change the PWR price because there is the corresponding amount of BUSD
     * that have been added to the fund.
     *
     * Windmill_Competition, Windmill_stacking and Windmill_Royalties can alsoo mint PWR
     * for their usage (competition and stacking reward, royalties).
     * These minting will decrease the value of PWR from the Windmill_Fund contract.
     */
    function mintTo(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice Allow the Windmill_Fund to burn PWR from an address
     * in exchange of withdrawing BUSD from the fund to the address.

     * When Windmill_Fund use this method, this do not change the PWR price
     * because there is the right amount of BUSD that have been removed
     * from the fund.
     */
    function burnFrom(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    /**
     * @notice Allow the Windmill_Fund to transfert PWR from an address
     * to a trade contract

     * Windmill_Stacking and Windmill_Trade_Manager use this method to lock the PWR from
     * direct withdraw. There is two main reason for this to happen :
     *
     * - PWR are locked from user to Windmill_Trade contract by Windmill_Trade_Manager
     * contract when starting a new trade. The corresponding BUSD from Windmill_Fund are also
     * allocated to the trade. These locked PWR are returned at the end of the trade.
     *
     * - PWR are stacked by the user in Windmill_Stacking. These PWR are returned
     * at the end of the stacking period. Note that returned PWR can be still
     * locked in a trade, that will be returned at the end of trade.
     */
    function transferFromTo(address from, address to, uint256 amount) external onlyRole(MOVER_ROLE) {
        _transfer(from, to, amount);
    }
}// Version: 1.0.0



interface IPancakeRouter01 {
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

interface PancakeRouter is IPancakeRouter01 {
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

/**
 * @notice Windmill_Fund is the contract that store and manage the BUSD used for
 * Windmill activities.
 *
 * The features of this contract are :
 * - Mint/burn PWR in exchange of depositing/withdrawing BUSD.
 * - Send BUSD to a Windmill_Contract trade.
 */
contract Windmill_Fund is AccessControlEnumerable {
    /**
     * DAO_ROLE is able to grant and revoke roles. It can be used when the DAO
     * vote to change some contracts of Windmill.
     */
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    IERC20 public BUSDToken;
    IERC20 public WBNBToken;
    Windmill_Power public PWRToken;
    PancakeRouter public pancakeRouter;

    address payable DAOAddr;
    address payable immutable thisAddr;

    constructor() {
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
        _setupRole(DAO_ROLE, msg.sender);
        thisAddr = payable(this);
    }

    function setPancakeRouter(PancakeRouter addr) external onlyRole(DAO_ROLE){
        pancakeRouter = addr;
    }

    function setWBNBToken(IERC20 token) external onlyRole(DAO_ROLE){
        WBNBToken = token;
    }

    function setDAOAddr(address payable addr) external onlyRole(DAO_ROLE){
        DAOAddr = addr;
    }

    /**
     * Update the address of the BUSD token.
     */
    function setBUSDToken(IERC20 token) external onlyRole(DAO_ROLE){
        BUSDToken = token;
    }

    /**
     * Update the address of the PWR token.
     */
    function setPWRToken(Windmill_Power token) external onlyRole(DAO_ROLE){
        PWRToken = token;
    }

    /**
     * Transfer the BUSD of this contract when the DAO
     * change the Windmill_Fund contract.
     */
    function migrateFunds(address newfund) external onlyRole(DAO_ROLE){
        uint256 balance = BUSDToken.balanceOf(thisAddr);
        BUSDToken.transfer(newfund, balance);
    }

    receive() external payable {}

    function getBNBForGasRefund(uint256 amountBNB) external onlyRole(DAO_ROLE){
        address[] memory path = new  address[](2);
        path[0] = address(BUSDToken);
        path[1] = address(WBNBToken);

        uint256 amountBUSD = pancakeRouter.getAmountsIn(amountBNB, path)[0] * 105/100;

        require(BUSDToken.balanceOf(thisAddr) >= amountBUSD, "Windmill_Fund: BUSD reserve too small");

        BUSDToken.approve(address(pancakeRouter), amountBUSD);
        pancakeRouter.swapTokensForExactETH(amountBNB, amountBUSD, path, thisAddr, block.timestamp);

        DAOAddr.transfer(amountBNB);
    }

    /**
     * Compute the BUSD hold buy Windmill contracts.
     */
    function getFundBUSD() public view returns (uint256){
        uint256 nbBUSD = BUSDToken.balanceOf(thisAddr);

        return nbBUSD;
    }

    /**
     * Compute the PWR total supply.
     */
    function getTotalPWR() public view returns (uint256){
        return PWRToken.totalSupply();
    }

    /**
     * Compute The number of PWR that corresponds to "amountBUSD" BUSD.
     */
    function getPWRAmountFromBUSD(uint256 amountBUSD) public view returns (uint256){
        uint256 nbBUSD = getFundBUSD();
        uint256 PWRSupply = getTotalPWR();

        uint256 nbPWRToGet = amountBUSD;
        if (PWRSupply > 0 && nbBUSD > 0){
            nbPWRToGet = amountBUSD * PWRSupply / nbBUSD;
        }

        return nbPWRToGet;
    }

    /**
     * Compute The number of BUSD that corresponds to "amountPWR" PWR.
     */
    function getBUSDAmountFromPWR(uint256 amountPWR) public view returns (uint256){
        uint256 nbBUSD = getFundBUSD();
        uint256 PWRSupply = getTotalPWR();

        uint256 nbBUSDToGet = 0;
        if (PWRSupply > 0 && nbBUSD > 0){
            nbBUSDToGet = amountPWR * nbBUSD / PWRSupply;
        }

        return nbBUSDToGet;
    }

    /**
     * Allow an address to buy PWR at the contract price for "amountBUSD" BUSD.
     * Node that the address must approve the transfer before calling this function.
     */
    function buyPWR(uint256 amountBUSD) external{
        require(BUSDToken.balanceOf(msg.sender) >= amountBUSD, "Windmill_Fund: Not enough BUSD");

        uint256 nbPWRToMint = getPWRAmountFromBUSD(amountBUSD);

        require(nbPWRToMint > 0, "Windmill_Fund: Too small amount of BUSD sent");

        BUSDToken.transferFrom(msg.sender, thisAddr, amountBUSD);
        PWRToken.mintTo(msg.sender, nbPWRToMint);
    }

    /**
     * Allow an address to sell "amountPWR" PWR at the contract price for BUSD.
     */
    function sellPWR(uint256 amountPWR) external{
        require(PWRToken.balanceOf(msg.sender) >= amountPWR, "Windmill_Fund: Not enough PWR");

        uint256 nbBUSDTowithdraw = getBUSDAmountFromPWR(amountPWR);

        require(nbBUSDTowithdraw > 0, "Windmill_Fund: Too small amount of PWR sent");

        PWRToken.burnFrom(msg.sender, amountPWR);
        BUSDToken.transfer(msg.sender, nbBUSDTowithdraw);
    }

}// Version: 1.0.0



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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Gas_Refundable is ReentrancyGuard{

    mapping(address=>uint256) internal _refundUsedGas;
    uint256 public refundGasDefaultPrice;
    uint256 public refundBNBMin;
    uint256 public refundBNBBonusRatioNumerator;
    uint256 public refundBNBBonusRatioDenominator;

    constructor() {
        refundGasDefaultPrice = 5 gwei;
        refundBNBMin = 1e8 gwei;
        refundBNBBonusRatioNumerator = 120;
        refundBNBBonusRatioDenominator = 100;
    }

    modifier gasRefundable() {
        uint256 gas1 = gasleft();
        _;
        uint256 gas2 = gasleft();

        uint256 nbBNB = (gas1 - gas2 + 21000 + 7680) * refundGasDefaultPrice;
        _refundUsedGas[msg.sender] += nbBNB;
    }

    function getRefundableGas(address addr) public view returns (uint256){
        return _refundUsedGas[addr] * refundBNBBonusRatioNumerator / refundBNBBonusRatioDenominator;
    }

    function refundGas() external nonReentrant{
        uint256 BNBToRefund = getRefundableGas(msg.sender);

        require(BNBToRefund >= refundBNBMin, "Gas_Refundable: Too small amount to refund");

        beforeRefundGas(BNBToRefund);

        _refundUsedGas[msg.sender] = 0;
        address payable sender = payable(msg.sender);
        sender.transfer(BNBToRefund);
    }

    function beforeRefundGas(uint256 BNBToRefund) internal virtual{}
}




/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @notice Windmill_DAO is the contract that manage de DAO of Windmill.
 *
 * It can modify all the parameters of Windmill, and update the Windmill contracts
 */
contract Windmill_DAO is Ownable, Gas_Refundable {
    /**
     * @notice Define an address capability about the DAO
     *
     * level -> Determines what the address is able to
     * - 0 (anonymous) -> This address can only buy, sell and stake PWR
     * - 1 (junior trader) -> This address can also make trade with limited sizing
     * - 2 (senior trader) -> This address can also make trade with full sizing
     * - 3 (governor) -> This address can also make proposals on the DAO
     *
     * nbProposalsDone -> How many proposals have been made in the lastProposalCycle cycle
     * lastProposalCycle -> Last cycle where the address have made a proposal
     */
    struct DAOLevel{
        uint256 lastProposalCycle;
        uint8 level;
        uint16 nbProposalsDone;
    }

    /**
     * @notice Define a proposal.
     *
     * id -> Identifiant of the proposal
     * paramsUint256 -> parameter of type uint256 associated with the proposal
     * paramsAddress -> parameter of type address associated with the proposal
     * - 0 -> Change the number of proposals per user per cycle
     *      (uint256) [1, 100] -> Number of proposals
     * - 1 -> Change the duration of vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 2 -> Change the quorum
     *      (uint256) [1, 100] -> Number of vote
     * - 3 -> Change the max number of open proposals
     *      (uint256) [10, 1000] -> Number of open proposals
     * - 4 -> Change the vote majority percent
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 5 -> Change the duration of a super vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 6 -> Change the quorum of a super vote
     *      (uint256) [1, 100] -> Number of vote
     * - 7 -> Change the vote majority percent of a super vote
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 8 -> promote a vote to super status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 9 -> demote a vote from super status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 10 -> Update the Windmill_Fund contract
     *      (address) -> New fund contract (DAO_ROLE must have been set correctly)
     * - 11 -> Update the PancakeRouter contract
     *      (address) -> New PancakeRouter contract
     * - 12 -> Change the cycle duration
     *      (uint256) [201600 (7 days), 10512000 (1 year)] -> Number of block
     * - 13 -> Change the gas refund price
     *      (uint256) [0, 100000000000 (100 gwei)] -> Gas price in Wei
     * - 14 -> Change the refund minimum BNB quantity
     *      (uint256) [0, inf] -> Minimum BNB quantity to refund
     * - 15 -> Change the refund bonus
     *      (uint256) [100, 200] -> 100 + Percent of bonus
     * - 16 -> Promote a user to junior trader (set it level 1 if <1) - It cannot demote a user
     *      (address) -> user address
     * - 17 -> Promote a user to senior trader (set it level 2 if <2) - It cannot demote a user
     *      (address) -> user address
     * - 18 -> Promote a user to governor (set it level 3)
     *      (address) -> user address
     * - 19 -> Demote user privilege (set it level 0)
     *      (address) -> user address
     *
     * startBlock -> Voting is allowed since this block number
     * endBlock -> Voting is terminated since this block number
     * nbYesVotes -> Number of yes vote
     * nbNoVotes -> Number of no vote
     * done -> Proposal is closed
     *
     * status -> Proposal status
     * - 0: Vote period not terminated
     * - 1: Not applied because quorum is not reached
     * - 2: Not applies because "no" majority
     * - 3: Applied
     */
    struct Proposal{
        uint256 paramsUint256;
        address paramsAddress;
        uint256 startBlock;
        uint256 endBlock;
        uint64 nbYesVotes;
        uint64 nbNoVotes;
        uint16 id;
        uint16 status;
        bool done;
    }

    uint256 public constant nbProposals = 20;

    bool[nbProposals] public isProposalSuper;

    Windmill_Power public PWRToken;
    Windmill_Fund public fund;

    IERC20 public BUSDToken;
    IERC20 public WBNBToken;

    PancakeRouter public pancakeRouter;

    address payable immutable thisAddr;

    mapping(address => DAOLevel) public users;

    uint256 public cycleDurationNbBlock;
    uint256 public currentCycle;
    uint256 public currentCycleEndBlock;
    uint256 public nbProposalPerUserPerCycle;

    uint256 public voteBlockDuration;
    uint256 public superVoteBlockDuration;

    uint256 public quorum;
    uint256 public superQuorum;

    uint256 public voteMajorityPercent;
    uint256 public superVoteMajorityPercent;

    /**
     * @notice Used for security, to avoid max gaz error when updating
     */
    uint256 public maxNbOpenProposals;

    /**
     * @notice When a proposal is sent, it is added to "openProposals".
     *
     * "openProposalIds" keep a track of open proposals to avoid
     * a full scan of proposals array when updating.
     */
    Proposal[] public proposals;
    uint256[] public openProposalIds;


    /**
     * @notice Keep track of address votes
     */
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    constructor(){
        currentCycle = 0;
        nbProposalPerUserPerCycle = 3;
        maxNbOpenProposals = 100;

        voteBlockDuration = 3;
        quorum = 4;
        voteMajorityPercent = 50;

        superVoteBlockDuration = 3;
        superQuorum = 4;
        superVoteMajorityPercent = 80;

        cycleDurationNbBlock = 10;
        currentCycleEndBlock = block.number + cycleDurationNbBlock;

        for(uint i=0; i<nbProposals; i++){
            isProposalSuper[i] = true;
        }
         isProposalSuper[16] = false;
         isProposalSuper[17] = false;

        thisAddr = payable(address(this));
    }

    /**
     * @notice Set the address of the PWR token (used only at DAO contract initialization).
     */
    function setPWRToken(Windmill_Power _PWRToken) external onlyOwner{
        PWRToken = _PWRToken;
    }

    /**
     * @notice Set the address of the BUSD token (used only at DAO contract initialization).
     */
    function setBUSDToken(IERC20 _BUSDToken) external onlyOwner{
        BUSDToken = _BUSDToken;
    }

    /**
     * @notice Set the address of the Windmill_Fund contract (used only at DAO contract initialization).
     */
    function setFundAddress(Windmill_Fund _fund) external onlyOwner{
        fund = _fund;
    }


    function setPancakeRouter(PancakeRouter addr) external onlyOwner{
        pancakeRouter = addr;
    }

    function setWBNBToken(IERC20 token) external onlyOwner{
        WBNBToken = token;
    }

    /**
     * @notice Add a user with capability on the DAO (used only at DAO contract initialization).
     */
    function addUser(address addr, uint8 level) external onlyOwner{
        require(level <= 3, "Windmill_DAO: the max level is 3");

        DAOLevel storage user = users[addr];
        user.level = level;
    }


    /**
     * @notice Update the address of the Windmill_Fund contract.
     *
     * The following migration is done :
     * - The new Windmill_Fund is initialized with right values
     * - The other Windmill contracts are linked to the new Windmill_Fund
     * - then BUSD migration is done.
     * Note that Windmill_DAO must be DAO_ROLE of the new Windmill_Fund before
     * calling this function.
     */
    function updateFundAddress(Windmill_Fund _fund) internal{
        //Change the storage variable
        Windmill_Fund oldFund = fund;
        fund = _fund;

        //Initialize the new Windmill_Fund
        fund.setBUSDToken(BUSDToken);
        fund.setPWRToken(PWRToken);
        fund.setDAOAddr(thisAddr);
        fund.setWBNBToken(WBNBToken);
        fund.setPancakeRouter(pancakeRouter);


        //Migrate the roles of PWRToken
        address oldFundAddr = address(oldFund);
        address fundAddr = address(fund);

        PWRToken.revokeRole(PWRToken.MINTER_ROLE(), oldFundAddr);
        PWRToken.revokeRole(PWRToken.BURNER_ROLE(), oldFundAddr);
        PWRToken.grantRole(PWRToken.MINTER_ROLE(), fundAddr);
        PWRToken.grantRole(PWRToken.BURNER_ROLE(), fundAddr);

        //Migrate the BUSD from the old to the new Windmill_Fund
        oldFund.migrateFunds(fundAddr);
    }

    function updatePancakeRouterAddress(PancakeRouter _router) internal{
        pancakeRouter = _router;
        fund.setPancakeRouter(_router);
    }

    modifier onlyGovernor(){
        require(users[msg.sender].level == 3, "Windmill_DAO: Only governor are allowed to call this function.");
        _;
    }

    /**
     * @notice Compute the number of digits in an uint256 number.
     *
     * Node that if number = 0, it returns 0.
     */
    function numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    /**
     * @notice Get the number of votes for an address.
     *
     * The number of vote is rounded down log10 of 10^3 times the address
     * part of the PWR total supply.
     *
     * This means only address >= 0.1% of the supply will be able to vote.
     *
     * An address can have from 1 to 4 votes, depending on its PWR.
     */

    function getVotes(address addr) public view returns (uint8){
        if (users[addr].level < 3){
            return 0;
        }

        uint256 balance = PWRToken.balanceOf(addr);

        if (balance == 0){
            return 0;
        }

        uint256 PWRSupply = PWRToken.totalSupply();
        uint256 fraction = ((10**3) * (balance)) / PWRSupply;
        uint8 nbVotes = numDigits(fraction);

        return nbVotes;
    }

    /**
     * @notice Get the number of remaining proposals for an address
     */
    function getRemainingProposals(address addr) public view returns (uint256){
        DAOLevel storage user = users[addr];

        if (user.level < 3){
            return 0;
        }

        if (currentCycle > user.lastProposalCycle){
            return nbProposalPerUserPerCycle;
        }

        return nbProposalPerUserPerCycle - user.nbProposalsDone;
    }


    /**
     * @notice Submit a new proposal then vote yes
     */
    function submitProposal(uint16 id, uint256 paramsUint256, address paramsAddress) external onlyGovernor{
        require(openProposalIds.length < maxNbOpenProposals, "Windmill_DAO: Max number of open proposals reached");
        require(id < nbProposals, "Windmill_DAO: This is not a valid proposal id");
        require(getRemainingProposals(msg.sender) > 0, "Windmill_DAO: No remaining proposals for this address");

        Proposal memory proposal;
        proposal.id = id;
        proposal.paramsUint256 = paramsUint256;
        proposal.paramsAddress = paramsAddress;
        proposal.startBlock = block.number;
        if (isProposalSuper[id]){
            proposal.endBlock = block.number + superVoteBlockDuration;
        }else{
            proposal.endBlock = block.number + voteBlockDuration;
        }

        require(checkProposalParameters(proposal), "Windmill_DAO: Error in parameters");

        DAOLevel storage user = users[msg.sender];

        if (user.lastProposalCycle == currentCycle){
            user.nbProposalsDone += 1;
        }else{
            user.nbProposalsDone = 1;
            user.lastProposalCycle = currentCycle;
        }

        openProposalIds.push(proposals.length);
        proposals.push(proposal);

        vote(proposals.length-1, true);
    }

    function vote(uint256 id, bool isYes) public onlyGovernor{
        uint8 nbVotes = getVotes(msg.sender);
        require(nbVotes>0, "Windmill_DAO: There is 0 vote for this address");


        require(id < proposals.length, "Windmill_DAO: Proposal does not exist");
        Proposal storage proposal = proposals[id];

        require(!hasVoted[msg.sender][id], "Windmill_DAO: address have already voted");

        require(block.number >= proposal.startBlock, "Windmill_DAO: Proposal is not opened to vote");
        require(block.number < proposal.endBlock, "Windmill_DAO: Proposal is closed to vote");

        hasVoted[msg.sender][id] = true;

        if (isYes){
            proposal.nbYesVotes += nbVotes;
        }else{
            proposal.nbNoVotes += nbVotes;
        }
    }

    function updateProposalNeeded(Proposal storage proposal) internal view returns (bool){
        if (block.number >= proposal.endBlock && !proposal.done){
            return true;
        }
        return false;
    }

    function updateDAONeeded() public view returns (bool){
        for (uint256 i=0; i<openProposalIds.length; ++i){
            Proposal storage proposal = proposals[openProposalIds[i]];
            if (updateProposalNeeded(proposal)){
                return true;
            }
        }
        return false;
    }

    function updateCycleNeeded() public view returns (bool){
        return (block.number >= currentCycleEndBlock);
    }

    function updateProposal(Proposal storage proposal, bool isSuper) internal returns (bool){
        if (updateProposalNeeded(proposal)){
            uint256 totalVotes = proposal.nbYesVotes+proposal.nbNoVotes;
            uint256 percentYes = (100*proposal.nbYesVotes)/totalVotes;

            if (isSuper){
                if (percentYes > superVoteMajorityPercent){
                    if (totalVotes >= superQuorum){
                        applyProposal(proposal);
                        proposal.status = 3;
                    }else{
                        proposal.status = 1;
                    }
                }else{
                    proposal.status = 2;
                }
            }else{
                if (percentYes > voteMajorityPercent){
                    if (totalVotes >= quorum){
                        applyProposal(proposal);
                        proposal.status = 3;
                    }else{
                        proposal.status = 1;
                    }
                }else{
                    proposal.status = 2;
                }
            }
            proposal.done = true;

            return true;
        }

        return false;
    }

    function updateOneCycle() external onlyGovernor{
        require(updateCycleNeeded(), "Windmill_DAO: A cycle update is not required.");
        _updateOneCycle();
    }

    function _updateOneCycle() internal{
        currentCycle += 1;
        currentCycleEndBlock += cycleDurationNbBlock;
    }

    function updateCycle() external onlyGovernor gasRefundable{
        require(updateCycleNeeded(), "Windmill_DAO: A cycle update is not required. Gas will not be refunded.");

        do{
            _updateOneCycle();
        }while(updateCycleNeeded());
    }

    function updateOneDAO(uint256 i) external onlyGovernor{
        require(i < openProposalIds.length, "Windmill_DAO: Wrong open proposal id.");
        _updateOneDAO(i);
    }

    function _updateOneDAO(uint256 i) internal{
        uint256 proposalI = openProposalIds[i];
        bool isSuper = isProposalSuper[proposalI];
        Proposal storage proposal = proposals[proposalI];
        if (updateProposal(proposal, isSuper)){
            if (i < openProposalIds.length-1){
                openProposalIds[i] = openProposalIds[openProposalIds.length-1];
            }
            openProposalIds.pop();
        }
    }

    function updateDAO() external onlyGovernor gasRefundable{
        require(updateDAONeeded(), "Windmill_DAO: A DAO update is not required. Gas will not be refunded.");

        uint256 i = openProposalIds.length;
        while(i>0){
            i--;
            _updateOneDAO(i);
        }
    }

    receive() external payable {}

    function beforeRefundGas(uint256 BNBToRefund) internal override{
        fund.getBNBForGasRefund(BNBToRefund);
    }

    function applyProposal(Proposal storage proposal) internal{
        if (proposal.id == 0){
            nbProposalPerUserPerCycle = proposal.paramsUint256;
        }else if(proposal.id == 1){
            voteBlockDuration = proposal.paramsUint256;
        }else if (proposal.id == 2){
            quorum = proposal.paramsUint256;
        }else if (proposal.id == 3){
            maxNbOpenProposals = proposal.paramsUint256;
        }else if (proposal.id == 4){
            voteMajorityPercent = proposal.paramsUint256;
        }else if (proposal.id == 5){
            superVoteBlockDuration = proposal.paramsUint256;
        }else if (proposal.id == 6){
            superQuorum = proposal.paramsUint256;
        }else if (proposal.id == 7){
            superVoteMajorityPercent = proposal.paramsUint256;
        }else if (proposal.id == 8){
            isProposalSuper[proposal.paramsUint256] = true;
        }else if (proposal.id == 9){
            isProposalSuper[proposal.paramsUint256] = false;
        }else if (proposal.id == 10){
            updateFundAddress(Windmill_Fund(payable(proposal.paramsAddress)));
        }else if (proposal.id == 11){
            updatePancakeRouterAddress(PancakeRouter(payable(proposal.paramsAddress)));
        }else if (proposal.id == 12){
            cycleDurationNbBlock = proposal.paramsUint256;
        }else if (proposal.id == 13){
            refundGasDefaultPrice = proposal.paramsUint256;
        }else if (proposal.id == 14){
            refundBNBMin = proposal.paramsUint256;
        }else if (proposal.id == 15){
            refundBNBBonusRatioNumerator = proposal.paramsUint256;
        }else if (proposal.id == 16){
            if (users[proposal.paramsAddress].level < 1){
                users[proposal.paramsAddress].level = 1;
            }
        }else if (proposal.id == 17){
            if (users[proposal.paramsAddress].level < 2){
                users[proposal.paramsAddress].level = 2;
            }
        }else if (proposal.id == 18){
            users[proposal.paramsAddress].level = 3;
        }else if (proposal.id == 19){
            users[proposal.paramsAddress].level = 0;
        }
    }

    function checkProposalParameters(Proposal memory proposal) internal view returns (bool){
        if (proposal.id == 0){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 1
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 1){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 864000){
                return false;
            }
        }else if (proposal.id == 2){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 1
                || proposal.paramsUint256 > 10){
                return false;
            }
        }else if (proposal.id == 3){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 10
                || proposal.paramsUint256 > 1000){
                return false;
            }
        }else if (proposal.id == 4){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 50
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 5){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 864000){
                return false;
            }
        }else if (proposal.id == 6){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 1
                || proposal.paramsUint256 > 10){
                return false;
            }
        }else if (proposal.id == 7){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 50
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 8){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 0
                || proposal.paramsUint256 >= nbProposals){
                return false;
            }
        }else if (proposal.id == 9){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 0
                || proposal.paramsUint256 >= nbProposals){
                return false;
            }
        }else if (proposal.id == 10){
            Windmill_Fund newFund = Windmill_Fund(payable(proposal.paramsAddress));
            if (   proposal.paramsUint256 != 0
                || !newFund.hasRole(newFund.DAO_ROLE(), thisAddr)){
                return false;
            }
        }else if (proposal.id == 11){
            if (proposal.paramsUint256 != 0){
                return false;
            }
        }else if (proposal.id == 12){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 201600
                || proposal.paramsUint256 > 10512000){
                return false;
            }
        }else if (proposal.id == 13){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 > 100000000000){
                return false;
            }
        }else if (proposal.id == 14){
            if (   proposal.paramsAddress != address(0x0)){
                return false;
            }
        }else if (proposal.id == 15){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 100
                || proposal.paramsUint256 > 200){
                return false;
            }
        }else if (proposal.id == 16){
            if (   proposal.paramsAddress == address(0x0)
                || users[proposal.paramsAddress].level>=1){
                return false;
            }
        }else if (proposal.id == 17){
            if (   proposal.paramsAddress == address(0x0)
                || users[proposal.paramsAddress].level>=2){
                return false;
            }
        }else if (proposal.id == 18){
            if (   proposal.paramsAddress == address(0x0)){
                return false;
            }
        }else if (proposal.id == 19){
            if (   proposal.paramsAddress == address(0x0)){
                return false;
            }
        }
        return true;
    }
}