// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        _approve(account, _msgSender(), currentAllowance - amount);
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
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC1363Receiver} from "../ERC/IERC1363Receiver.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {Master} from "../Master/Master.sol";
import {ListingGateway} from "../Gateway/ListingGateway.sol";
import {IDaiPermit} from "../ERC/IDaiPermit.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EIP712} from "../EIP/EIP712.sol";

contract Pool is IERC1363Receiver, Master {
    using SafeERC20 for ERC20;

    // State Variables
    ListingGateway private lg;
    address public devWallet;
    address public daiTokenAddr;
    address public usdtTokenAddr;
    address public usdcTokenAddr;
    bytes32 public DOMAIN_SEPARATOR;

    // Constants
    bytes4 internal constant _INTERFACE_ID_ERC1363_RECEIVER = 0x88a7ca5c;
    bytes32 private constant COIN_TYPE_HASH =
        keccak256(
            "CoinPricingInfo(string coinId,string coinSymbol,uint256 coinPrice,uint256 lastUpdatedAt)"
        );
    bytes32 private constant CREATE_COVER_REQUEST =
        keccak256("CREATE_COVER_REQUEST");
    bytes32 private constant CREATE_COVER_OFFER =
        keccak256("CREATE_COVER_OFFER");

    // Event
    event TokensReceived(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    constructor() {
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator("insured-finance", "v1");
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        infiToken = ERC20Burnable(cg.infiTokenAddr());
        lg = ListingGateway(cg.getLatestAddress("LG"));
        devWallet = cg.getLatestAddress("DW");
        daiTokenAddr = cg.getLatestAddress("DT");
        usdtTokenAddr = cg.getLatestAddress("UT");
        usdcTokenAddr = cg.getLatestAddress("UC");
    }

    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) public override returns (bytes4) {
        require(
            msg.sender == address(infiToken),
            "Pool : not from allowed address"
        ); // Only specific token accepted (on this case only INFI), temporarily disable
        emit TokensReceived(operator, from, value, data);

        (bytes32 payType, bytes memory payData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (payType == CREATE_COVER_REQUEST) {
            lg.createCoverRequest(from, value, payData);
        } else if (payType == CREATE_COVER_OFFER) {
            lg.createCoverOffer(from, value, payData);
        } else {
            revert("ERC1363Receiver: INVALID_PAY_TYPE");
        }

        return _INTERFACE_ID_ERC1363_RECEIVER;
    }

    function transferAndBurnInfi(uint256 listingFee) public onlyInternal {
        // Burn and Transfer Infi Token to dev wallet
        uint256 halfListingFee = listingFee / 2;
        if (listingFee % 2 == 1) {
            burnListingFee(halfListingFee); // burn half of listing fee
            infiToken.transfer(devWallet, (halfListingFee + 1)); // transfer to dev wallet + 1
        } else {
            burnListingFee(halfListingFee); // burn half of listing fee
            infiToken.transfer(devWallet, halfListingFee); // transfer to dev wallet
        }
    }

    /**
     * @dev Calculate listing fee (in infi token)
     * NOTE : This one need to take price from chainlink
     */
    function getListingFee(
        uint256 insuredSum,
        uint256 insuredSumCurrencyDecimal,
        uint256 feeCoinPrice
    ) public view returns (uint256) {
        uint256 feeCoinPriceDecimal = 6;
        uint256 insuredSumCurrencyDecimalOnCL = 4;
        uint256 insuredSumCurrencyPriceOnCL = 10000;
        uint256 infiTokenDecimal = infiToken.decimals();
        // uint insuredSumInUSD = insuredSum * insuredSumCurrencyPriceOnCL / 10**insuredSumCurrencyDecimalOnCL / 10**insuredSumCurrencyDecimal; // insuredSum in USD
        // uint insuredSumInInfi = insuredSumInUSD * 10**feeCoinPriceDecimal / feeCoinPrice;
        // uint listingFeeInInfi = insuredSumInInfi / 100;  // 1% of insured sum
        // 100_000_000 * 10_000 * 1_000_000 * 10**18 / 100_000 / 100 / 10_000 / 1_000_000

        return
            (insuredSum *
                insuredSumCurrencyPriceOnCL *
                10**feeCoinPriceDecimal *
                10**infiTokenDecimal) /
            feeCoinPrice /
            100 /
            10**insuredSumCurrencyDecimalOnCL /
            10**insuredSumCurrencyDecimal;
    }

    function burnListingFee(uint256 _amount) internal {
        infiToken.burn(_amount);
    }

    // NOTE : need to restricted
    function acceptAsset(
        address _from,
        CurrencyType _currentyType,
        uint256 _amount,
        bytes memory _premiumPermit
    ) public onlyInternal {
        if (_currentyType == CurrencyType.DAI) {
            DAIPermit memory permitData = abi.decode(
                _premiumPermit,
                (DAIPermit)
            );
            IDaiPermit(daiTokenAddr).permit(
                permitData.holder,
                permitData.spender,
                permitData.nonce,
                permitData.expiry,
                permitData.allowed,
                permitData.sigV,
                permitData.sigR,
                permitData.sigS
            );
            IDaiPermit(daiTokenAddr).transferFrom(
                _from,
                address(this),
                _amount
            );
        } else if (_currentyType == CurrencyType.USDT) {
            ERC20(usdtTokenAddr).safeTransferFrom(
                _from,
                address(this),
                _amount
            );
        } else if (_currentyType == CurrencyType.USDC) {
            // Approve
            EIP2612Permit memory permitData = abi.decode(
                _premiumPermit,
                (EIP2612Permit)
            );
            IERC20Permit(usdcTokenAddr).permit(
                permitData.owner,
                permitData.spender,
                permitData.value,
                permitData.deadline,
                permitData.sigV,
                permitData.sigR,
                permitData.sigS
            );
            // Transfer from member to smart contract
            IERC20(usdcTokenAddr).transferFrom(_from, address(this), _amount);
        }
    }

    // Note : need to restricted
    function transferAsset(
        address _to,
        CurrencyType _currentyType,
        uint256 _amount
    ) public onlyInternal {
        if (_currentyType == CurrencyType.DAI) {
            IERC20(daiTokenAddr).transfer(_to, _amount);
        } else if (_currentyType == CurrencyType.USDT) {
            ERC20(usdtTokenAddr).safeTransfer(_to, _amount);
        } else if (_currentyType == CurrencyType.USDC) {
            IERC20(usdcTokenAddr).transfer(_to, _amount);
        }
    }

    /**
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function verifyMessage(CoinPricingInfo memory coinPricing, address whose)
        public
        view
    {
        require(
            EIP712.recover(
                DOMAIN_SEPARATOR,
                coinPricing.sigV,
                coinPricing.sigR,
                coinPricing.sigS,
                hash(coinPricing)
            ) == whose,
            "Master: Signature not valid"
        );
    }

    function hash(CoinPricingInfo memory coinPricing)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                COIN_TYPE_HASH,
                keccak256(bytes(coinPricing.coinId)),
                keccak256(bytes(coinPricing.coinSymbol)),
                coinPricing.coinPrice,
                coinPricing.lastUpdatedAt
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract ClaimData is Master {
    // State variable
    // Claims
    Claim[] internal claims;
    mapping(uint256 => uint256[]) internal coverToClaims;
    mapping(uint256 => uint256) public claimToCover;
    mapping(uint256 => uint256) public coverToPayout;
    mapping(uint256 => mapping(uint80 => bool)) public coverToValidRoundId; // coverId => roundId -> true/false

    CollectiveClaim[] internal collectiveClaims;
    mapping(uint256 => uint256[]) internal requestToCollectiveClaims;
    mapping(uint256 => uint256) public collectiveClaimToRequest;
    // total payout from claim of offer cover,
    // it will record how much payout already done for cover offer
    mapping(uint256 => uint256) public offerIdToPayout;
    // it will record how much payout already done for cover request
    mapping(uint256 => uint256) public requestIdToPayout;
    mapping(CurrencyType => uint256) public totalExpiredPayout; // total amount of expired payout that owned by platform

    // Event
    event ClaimRaise(
        uint256 claimId,
        uint256 coverId,
        uint256 claimTime,
        address holder,
        uint80 roundId,
        uint256 roundTimestamp
    );
    event CollectiveClaimRaise(
        uint256 collectiveClaimId,
        uint256 requestId,
        uint256[] claimIds,
        uint256 claimTime,
        address holder,
        uint256 roundId,
        uint256 roundTimestamp
    );

    /**
    @dev Create a new Claim
    */
    function addClaim(
        uint256 _coverId,
        uint80 _roundId,
        uint256 _roundTimestamp,
        address _holder
    ) external onlyInternal returns (uint256) {
        // Store Data Claim
        claims.push(Claim(_roundId, block.timestamp, 0, ClaimState.MONITORING));
        uint256 claimId = claims.length - 1;
        coverToClaims[_coverId].push(claimId);
        claimToCover[claimId] = _coverId;
        // coverToPayout[_coverId] += _payout;

        // // add roundID as a valid claim on cover
        // if (_isClaimValid) {
        //     coverToValidRoundId[_coverId][_roundId] = true;
        // }

        // Emit event claim
        emit ClaimRaise(
            claimId,
            _coverId,
            block.timestamp,
            _holder,
            _roundId,
            _roundTimestamp
        );

        return claimId;
    }

    function setCoverToPayout(uint256 _coverId, uint256 _payout)
        public
        onlyInternal
    {
        coverToPayout[_coverId] += _payout;
    }

    function setOfferIdToPayout(uint256 _offerId, uint256 _payout)
        public
        onlyInternal
    {
        offerIdToPayout[_offerId] += _payout;
    }

    function setRequestIdToPayout(uint256 _requestId, uint256 _payout)
        public
        onlyInternal
    {
        requestIdToPayout[_requestId] += _payout;
    }

    function getCoverToClaimsLength(uint256 _coverId)
        external
        view
        returns (uint256)
    {
        return coverToClaims[_coverId].length;
    }

    function getCoverToClaims(uint256 _coverId)
        external
        view
        returns (uint256[] memory)
    {
        return coverToClaims[_coverId];
    }

    function getClaimById(uint256 _claimId)
        external
        view
        returns (Claim memory)
    {
        return claims[_claimId];
    }

    /**
    @return - false => roundId already used, true => roundId not yes used for claim in cover
    */
    function uniqueRoundId(uint256 _coverId, uint256 _roundId)
        external
        view
        returns (bool)
    {
        uint256[] memory claimIdList = coverToClaims[_coverId];

        for (uint256 i = 0; i < claimIdList.length; i++) {
            Claim memory claim = claims[claimIdList[i]];
            if (claim.roundId == _roundId) {
                return false;
            }
        }
        return true;
    }

    /**
    @return - false => there is no valid claim,  true => valid claom exists
    */
    function isValidClaimExists(uint256 _coverId) external view returns (bool) {
        uint256[] memory claimIdList = coverToClaims[_coverId];

        for (uint256 i = 0; i < claimIdList.length; i++) {
            Claim memory claim = claims[claimIdList[i]];
            if (claim.state == ClaimState.VALID) {
                return true;
            }
        }
        return false;
    }

    function isValidClaimExistOnRequest(uint256 _requestId)
        external
        view
        returns (bool)
    {
        uint256[] memory collectiveClaimIdList = requestToCollectiveClaims[
            _requestId
        ];

        for (uint256 i = 0; i < collectiveClaimIdList.length; i++) {
            CollectiveClaim memory collectiveClaim = collectiveClaims[
                collectiveClaimIdList[i]
            ];
            if (collectiveClaim.state == ClaimState.VALID) {
                return true;
            }
        }
        return false;
    }

    function updateClaimState(uint256 _claimId, ClaimState _state)
        external
        onlyInternal
    {
        Claim storage claim = claims[_claimId];
        claim.state = _state;
    }

    function addTotalExpiredPayout(CurrencyType _currencyType, uint256 _amount)
        external
        onlyInternal
    {
        totalExpiredPayout[_currencyType] += _amount;
    }

    function resetTotalExpiredPayout(CurrencyType _currencyType)
        external
        onlyInternal
    {
        totalExpiredPayout[_currencyType] = 0;
    }

    function addCollectiveClaim(
        uint256 _requestId,
        uint80 _roundId,
        uint256 _roundTimestamp,
        uint256[] memory _claimsIds,
        address _holder
    ) external onlyInternal returns (uint256) {
        collectiveClaims.push(
            CollectiveClaim(
                _roundId,
                block.timestamp,
                0,
                ClaimState.MONITORING,
                _claimsIds
            )
        );
        uint256 collectiveClaimId = collectiveClaims.length - 1;
        requestToCollectiveClaims[_requestId].push(collectiveClaimId);
        collectiveClaimToRequest[collectiveClaimId] = _requestId;

        emit CollectiveClaimRaise(
            collectiveClaimId,
            _requestId,
            _claimsIds,
            block.timestamp,
            _holder,
            _roundId,
            _roundTimestamp
        );
        return collectiveClaimId;
    }

    function getCollectiveClaimById(uint256 _collectiveClaimId)
        external
        view
        returns (CollectiveClaim memory)
    {
        return collectiveClaims[_collectiveClaimId];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract CoverData is Master {
    // State Variables
    InsuranceCover[] internal covers; // InsuranceCover.id
    mapping(address => uint256[]) internal holderToCovers;
    mapping(address => uint256[]) public funderToCovers;
    mapping(address => uint256[]) internal funderToRequestId;
    mapping(uint256 => uint256[]) internal offerIdToCovers;
    mapping(uint256 => uint256[]) public requestIdToCovers;
    mapping(uint256 => bool) public isPremiumCollected; //  coverId -> true/false
    mapping(uint256 => uint8) public coverIdToCoverMonths; // Only for Buy Cover / Take Offer
    mapping(uint256 => uint256) public insuranceCoverStartAt; // Only for Buy Cover / Take Offer
    CoverFunding[] internal coverFundings;
    mapping(uint256 => uint256[]) internal requestIdToCoverFundings;
    mapping(address => uint256[]) internal funderToCoverFundings;

    // Events
    event Cover(
        uint256 id,
        InsuranceCover cover,
        uint256 startAt,
        uint8 coverMonths,
        address funder
    );
    event Booking(uint256 id, CoverFunding coverFunding);
    event CoverPremiumCollected(uint256 coverId);

    // NOTE : need to update listingData.setPremiumCollected(coverId);
    function storeCoverByTakeOffer(
        InsuranceCover memory _cover,
        uint8 coverMonths,
        address _funder
    ) public onlyInternal {
        covers.push(_cover);
        uint256 coverId = covers.length - 1;
        offerIdToCovers[_cover.offerId].push(coverId);
        holderToCovers[_cover.holder].push(coverId);
        funderToCovers[_funder].push(coverId);
        coverIdToCoverMonths[coverId] = coverMonths;
        insuranceCoverStartAt[coverId] = block.timestamp;
        isPremiumCollected[coverId] = true;
        emit CoverPremiumCollected(coverId);
        emit Cover(coverId, _cover, block.timestamp, coverMonths, _funder);
    }

    function storeBookingByTakeRequest(CoverFunding memory _booking)
        public
        onlyInternal
    {
        coverFundings.push(_booking);
        uint256 coverFundingId = coverFundings.length - 1;
        requestIdToCoverFundings[_booking.requestId].push(coverFundingId);
        funderToCoverFundings[_booking.funder].push(coverFundingId);
        emit Booking(coverFundingId, _booking);
    }

    function storeCoverByTakeRequest(
        InsuranceCover memory _cover,
        uint8 coverMonths,
        address _funder
    ) public onlyInternal {
        covers.push(_cover);
        uint256 coverId = covers.length - 1;
        requestIdToCovers[_cover.requestId].push(coverId);
        holderToCovers[_cover.holder].push(coverId);
        funderToCovers[_funder].push(coverId);
        funderToRequestId[_funder].push(_cover.requestId);
        // Note : change
        emit Cover(coverId, _cover, 0, coverMonths, _funder);
    }

    function getCoverById(uint256 _coverId)
        public
        view
        returns (InsuranceCover memory cover)
    {
        cover = covers[_coverId];
    }

    function getBookingById(uint256 _bookingId)
        public
        view
        returns (CoverFunding memory coverFunding)
    {
        coverFunding = coverFundings[_bookingId];
    }

    /**
    @dev get cover months for cover that crated from take offer only
     */
    function getCoverMonths(uint256 _coverId) public view returns (uint8) {
        return coverIdToCoverMonths[_coverId];
    }

    function getCoversByOfferId(uint256 _coverOfferId)
        public
        view
        returns (uint256[] memory)
    {
        return offerIdToCovers[_coverOfferId];
    }

    function isFunderOfCover(address _funder, uint256 _coverId)
        public
        view
        returns (bool)
    {
        uint256[] memory listCoverIds = funderToCovers[_funder];
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            if (listCoverIds[i] == _coverId) {
                return true;
            }
        }
        return false;
    }

    function getFunderToCovers(address _funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToCovers[_funder];
    }

    function setPremiumCollected(uint256 _coverId) public onlyInternal {
        isPremiumCollected[_coverId] = true;
        emit CoverPremiumCollected(_coverId);
    }

    function getCoversByRequestId(uint256 _requestId)
        external
        view
        returns (uint256[] memory)
    {
        return requestIdToCovers[_requestId];
    }

    function getFunderToRequestId(address _funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToRequestId[_funder];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract ListingData is Master {
    // State Variable
    // Cover Request
    CoverRequest[] internal requests; // CoverRequest.id
    mapping(uint256 => uint256) public requestIdToInsuredSumTaken;
    mapping(address => uint256[]) internal buyerToRequests;
    mapping(string => uint256[]) internal coinIdToRequests;
    mapping(uint256 => uint256) public coverRequestFullyFundedAt;
    mapping(uint256 => bool) public requestIdToRefundPremium;
    mapping(uint256 => bool) public isDepositTakenBack; // coverId -> true/false
    // Cover Offer
    CoverOffer[] internal offers; // CoverOffer.id
    mapping(uint256 => uint256) public offerIdToInsuredSumTaken;
    mapping(address => uint256[]) internal funderToOffers;
    mapping(string => uint256[]) internal coinIdToOffers;
    mapping(uint256 => bool) public isDepositOfOfferTakenBack; // offer id => state of take back deposit

    // Event
    event CreateRequest(
        uint256 id,
        address indexed holder,
        CoverRequest request,
        CoinPricingInfo assetPricing,
        CoinPricingInfo feePricing
    );
    event CreateOffer(
        uint256 id,
        address indexed funder,
        CoverOffer coverOffer,
        CoinPricingInfo feePricing,
        CoinPricingInfo assetPricing,
        uint8 depositPeriod
    );
    event DepositOfOfferTakenBack(uint256 offerId, uint256[] coverIds);
    event DepositTakenBack(uint256 coverId);
    event RequestFullyFunded(uint256 requestId, uint256 fullyFundedAt);
    event PremiumRefunded(uint256 requestId);

    /**
    @dev Note : need to be restricted, only specific smart contract allowed
  */
    function storedRequest(
        CoverRequest memory _inputRequest,
        CoinPricingInfo memory _assetPricing,
        CoinPricingInfo memory _feePricing,
        address _member
    ) public onlyInternal {
        requests.push(_inputRequest);
        uint256 requestId = requests.length - 1;
        buyerToRequests[_member].push(requestId);
        coinIdToRequests[_inputRequest.coinId].push(requestId);
        requestIdToInsuredSumTaken[requestId] = 0; // set insured sum taken to 0 as iniitial
        emit CreateRequest(
            requestId,
            _member,
            _inputRequest,
            _assetPricing,
            _feePricing
        );
    }

    function getCoverRequestById(uint256 _cid)
        public
        view
        returns (CoverRequest memory coverRequest)
    {
        return requests[_cid];
    }

    function getCoverRequestsListByAddr(address _member)
        public
        view
        returns (uint256[] memory)
    {
        return buyerToRequests[_member];
    }

    function getCoverRequestLength() public view returns (uint256) {
        return requests.length;
    }

    function getCoverOfferLength() public view returns (uint256) {
        return offers.length;
    }

    // Note : need to be restricted
    function storedOffer(
        CoverOffer memory _inputOffer,
        CoinPricingInfo memory _feePricing,
        CoinPricingInfo memory _assetPricing,
        uint8 _depositPeriod,
        address _member
    ) public onlyInternal {
        offers.push(_inputOffer);
        uint256 offerId = offers.length - 1;
        funderToOffers[_member].push(offerId);
        coinIdToOffers[_inputOffer.coinId].push(offerId);
        offerIdToInsuredSumTaken[offerId] = 0; // set insured sum remaining to 0 as initial
        emit CreateOffer(
            offerId,
            _member,
            _inputOffer,
            _feePricing,
            _assetPricing,
            _depositPeriod
        );
    }

    function getCoverOfferById(uint256 _offerId)
        public
        view
        returns (CoverOffer memory coverOffer)
    {
        return offers[_offerId];
    }

    function getCoverOffersListByAddr(address _member)
        public
        view
        returns (uint256[] memory)
    {
        return funderToOffers[_member];
    }

    // Note : Need to restricted
    function updateOfferInsuredSumTaken(
        uint256 _offerId,
        uint256 _insuredSumTaken
    ) public onlyInternal {
        offerIdToInsuredSumTaken[_offerId] = _insuredSumTaken;
    }

    // Note : Need to restricted
    function updateRequestInsuredSumTaken(
        uint256 _requestId,
        uint256 _insuredSumTaken
    ) public onlyInternal {
        requestIdToInsuredSumTaken[_requestId] = _insuredSumTaken;
    }

    function isRequestReachTarget(uint256 _requestId)
        public
        view
        returns (bool)
    {
        CoverRequest memory request = requests[_requestId];
        return
            requestIdToInsuredSumTaken[_requestId] >= request.insuredSumTarget;
    }

    function isRequestFullyFunded(uint256 _requestId)
        public
        view
        returns (bool)
    {
        CoverRequest memory request = requests[_requestId];
        uint8 decimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );
        uint256 tolerance = 2 * (10**decimal);

        return
            (request.insuredSum - requestIdToInsuredSumTaken[_requestId]) <=
            tolerance;
    }

    function setCoverRequestFullyFundedAt(
        uint256 _requestId,
        uint256 _fullyFundedAt
    ) public onlyInternal {
        coverRequestFullyFundedAt[_requestId] = _fullyFundedAt;
        emit RequestFullyFunded(_requestId, _fullyFundedAt);
    }

    function setRequestIdToRefundPremium(uint256 _requestId)
        public
        onlyInternal
    {
        requestIdToRefundPremium[_requestId] = true;
        emit PremiumRefunded(_requestId);
    }

    function setDepositOfOfferTakenBack(
        uint256 _offerId,
        uint256[] memory _coverIds
    ) public onlyInternal {
        isDepositOfOfferTakenBack[_offerId] = true;
        emit DepositOfOfferTakenBack(_offerId, _coverIds);
    }

    function setIsDepositTakenBack(uint256 _coverId) public onlyInternal {
        isDepositTakenBack[_coverId] = true;
        emit DepositTakenBack(_coverId);
    }

    function getBuyerToRequests(address _holder)
        public
        view
        returns (uint256[] memory)
    {
        return buyerToRequests[_holder];
    }

    function getFunderToOffers(address _funder)
        public
        view
        returns (uint256[] memory)
    {
        return funderToOffers[_funder];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Master} from "../Master/Master.sol";

contract PlatformData is Master {
    // State variables
    Platform[] public platforms;
    Oracle[] public oracles;
    PriceFeed[] public usdPriceFeeds;
    Custodian[] public custodians;
    mapping(string => uint256[]) internal symbolToUsdPriceFeeds;

    // Event
    event NewPlatform(uint256 id, string name, string website);
    event NewOracle(uint256 id, string name, string website);
    event NewCustodian(uint256 id, string name, string website);
    event NewPriceFeed(
        string symbol,
        uint256 usdPriceFeedsId,
        uint256 oracleId,
        uint256 chainId,
        uint8 decimals,
        address proxyAddress
    );

    /**
    @dev Add New Platform
     */
    function addNewPlatform(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        // Store Data
        platforms.push(Platform(name, website));
        uint256 platformId = platforms.length - 1;
        emit NewPlatform(platformId, name, website);
    }

    /**
    @dev Add New Oracle
     */
    function addNewOracle(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        // Store Data
        oracles.push(Oracle(name, website));
        uint256 oracleId = oracles.length - 1;
        emit NewOracle(oracleId, name, website);
    }

    /**
    @dev Add New Custodians
     */
    function addNewCustodian(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        // Store Data
        custodians.push(Custodian(name, website));
        uint256 custodianId = custodians.length - 1;
        emit NewCustodian(custodianId, name, website);
    }

    /**
    @dev Add New Price Feed
     */
    function addNewPriceFeed(
        string calldata symbol,
        uint256 oracleId,
        uint256 chainId,
        uint8 decimals,
        address proxyAddress
    ) external {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        // Store Data
        usdPriceFeeds.push(
            PriceFeed(oracleId, chainId, decimals, proxyAddress)
        );
        uint256 usdPriceFeedsId = usdPriceFeeds.length - 1;
        symbolToUsdPriceFeeds[symbol].push(usdPriceFeedsId);
        emit NewPriceFeed(
            symbol,
            usdPriceFeedsId,
            oracleId,
            chainId,
            decimals,
            proxyAddress
        );
    }

    function getOraclePriceFeedAddress(string calldata symbol)
        external
        view
        returns (address)
    {
        uint256[] memory priceFeeds = symbolToUsdPriceFeeds[symbol];
        if (priceFeeds.length <= 0) {
            return address(0);
        } else {
            uint256 priceFeedId = priceFeeds[priceFeeds.length - 1];
            PriceFeed memory selectedPriceFeed = usdPriceFeeds[priceFeedId];
            return selectedPriceFeed.proxyAddress;
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import { ECRecover } from "./ECRecover.sol";

/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(address operator, address sender, uint256 amount, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {Master} from "../Master/Master.sol";
import {Pool} from "../Capital/Pool.sol";
import {ClaimHelper} from "./ClaimHelper.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ClaimGateway is Master {
    // State variables
    CoverGateway private coverGateway;
    ListingGateway private listingGateway;
    CoverData private coverData;
    ClaimData private claimData;
    ListingData private listingData;
    PlatformData private platformData;
    Pool private pool;
    ClaimHelper private claimHelper;
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant STABLECOINS_STANDARD_PRICE = 1;
    uint256 private constant MAX_DEVALUATION = 25; // in percentage
    uint256 public constant MONITORING_PERIOD = 72 hours;
    uint256 public constant MAX_PAYOUT_PERIOD = 30 days;
    uint256 private constant VALIDATION_PREVIOUS_PERIOD = 1 hours;

    event CollectPremium(
        uint256 requestId,
        uint256 coverId,
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event RefundPremium(
        uint256 requestId,
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event TakeBackDeposit(
        uint256 offerId,
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event RefundDeposit(
        uint256 requestId,
        uint256 coverId,
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );

    event ValidClaim(
        uint256 coverId,
        uint256 claimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );

    event InvalidClaim(uint256 coverId, uint256 claimId);

    // Dev withdraw expired payout
    event WithdrawExpiredPayout(
        address devWallet,
        uint8 currencyType,
        uint256 amount
    );

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        listingGateway = ListingGateway(cg.getLatestAddress("LG"));
        coverData = CoverData(cg.getLatestAddress("CD"));
        claimData = ClaimData(cg.getLatestAddress("CM"));
        listingData = ListingData(cg.getLatestAddress("LD"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
        pool = Pool(cg.getLatestAddress("PL"));
        claimHelper = ClaimHelper(cg.getLatestAddress("CH"));
    }

    /**
     * @dev
     * @param _coverId
     * @param _roundId number attribute from subgraph
     */
    function submitClaim(uint256 _coverId, uint80 _roundId) external {
        // msg.sender must cover's owner
        InsuranceCover memory cover = coverData.getCoverById(_coverId);
        require(cover.holder == msg.sender, "Claim Gateway: Not cover's owner");

        // get startAt & endAt of Cover
        uint256 startAt = coverGateway.getStartAt(_coverId);
        uint256 endAt = coverGateway.getEndAt(_coverId);

        // cover must start
        require(startAt != 0, "Claim Gateway: Cover not started yet");

        // cover must be still active
        require(
            startAt <= block.timestamp && block.timestamp <= endAt,
            "Claim Gateway: Cover is not active"
        );

        // make sure there is no valid claim
        require(
            !claimData.isValidClaimExists(_coverId),
            "Claim Gateway : Valid claim exists"
        );

        // Cannot use same roundId to submit claim on cover
        require(
            claimData.uniqueRoundId(_coverId, _roundId),
            "Claim Gateway: Cannot use same round id"
        );

        // Note : Limit only able to make 1 valid claim &$ cannot make multiple valid claim
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);

        // Price feed aggregator
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        // Call aggregator
        (, , , uint256 eventTimestamp, ) = priceFeed.getRoundData(_roundId);

        // NOTE : comment out when testing
        // validate timestamp of price feed, time of round id must in range of cover period
        require(
            startAt <= eventTimestamp && eventTimestamp <= endAt,
            "Claim Gateway: Invalid time of price feed"
        );

        // NOTE : comment out when testing
        // Check 1 hours before roundId, make sure the devaluation id valid
        require(
            claimHelper.isValidPastDevaluation(priceFeedAddr, _roundId),
            "Claim Gateway: Previous round not devaluation"
        );

        // add filing claim
        uint256 claimId = claimData.addClaim(
            _coverId,
            _roundId,
            eventTimestamp,
            msg.sender
        );

        // + 1 hours is a buffer time
        if ((eventTimestamp + MONITORING_PERIOD) + 1 hours <= block.timestamp) {
            // Check validity and make payout
            _checkValidityAndPayout(claimId, priceFeedAddr);
        }
    }

    function checkPayout(uint256 _claimId) external {
        uint256 coverId = claimData.claimToCover(_claimId);

        // make sure there is no valid claim
        require(
            !claimData.isValidClaimExists(coverId),
            "Claim Gateway : Valid claim exists"
        );

        Claim memory claim = claimData.getClaimById(_claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);

        // Price feed aggregator
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        // Call aggregator
        (, , uint256 startedAt, , ) = priceFeed.getRoundData(claim.roundId);

        require(
            ((startedAt + MONITORING_PERIOD) + 1 hours) < block.timestamp,
            "Claim Gateway: still on monitoring period"
        );

        require(
            block.timestamp <=
                (startedAt + MONITORING_PERIOD + MAX_PAYOUT_PERIOD),
            "Claim Gateway: passing payout period"
        );

        _checkValidityAndPayout(_claimId, priceFeedAddr);
    }

    function checkValidityAndPayout(uint256 _claimId, address _priceFeedAddr)
        external
        onlyInternal
    {
        _checkValidityAndPayout(_claimId, _priceFeedAddr);
    }

    function _checkValidityAndPayout(uint256 _claimId, address _priceFeedAddr)
        internal
    {
        Claim memory claim = claimData.getClaimById(_claimId);

        // For stablecoins devaluation will decided based on oracle
        (bool isClaimValid, uint256 assetPrice, uint8 decimals) = claimHelper
            .checkClaimForDevaluation(_priceFeedAddr, claim.roundId);

        // Get Cover id
        uint256 coverId = claimData.claimToCover(_claimId);

        if (isClaimValid) {
            uint256 payout = 0;
            // Calculate Payout
            InsuranceCover memory cover = coverData.getCoverById(coverId);
            payout = claimHelper.getPayout(cover, assetPrice, decimals);
            require(
                claimData.coverToPayout(coverId) + payout <= cover.insuredSum,
                "Claim Gateway: Insufficient funds"
            );

            // Set cover to payout
            claimData.setCoverToPayout(coverId, payout);

            // set state var for store payour per request/offer
            CurrencyType currency;
            if (cover.listingType == ListingType.OFFER) {
                // Get cover offer
                CoverOffer memory coverOffer = listingData.getCoverOfferById(
                    cover.offerId
                );
                currency = coverOffer.insuredSumCurrency;
                // Update total payout of offer cover
                claimData.setOfferIdToPayout(cover.offerId, payout);
            } else if (cover.listingType == ListingType.REQUEST) {
                // Get cover request
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                currency = coverRequest.insuredSumCurrency;
                // Update total payout of offer request
                claimData.setRequestIdToPayout(cover.requestId, payout);
            }
            // send payout
            pool.transferAsset(cover.holder, currency, payout);
            // update state of claim
            claimData.updateClaimState(_claimId, ClaimState.VALID);
            // emit event
            emit ValidClaim(coverId, _claimId, uint8(currency), payout);
        } else {
            // update state of claim
            claimData.updateClaimState(_claimId, ClaimState.INVALID);
            // emit event
            emit InvalidClaim(coverId, _claimId);
        }
    }

    /**
    @dev will only be able to call by funders of cover request
    to collect premium from holder
     */
    function collectPremiumOfRequestByFunder(uint256 _coverId) external {
        InsuranceCover memory cover = coverData.getCoverById(_coverId);
        // Make sure cover coming from provide request
        require(
            cover.listingType == ListingType.REQUEST,
            "Claim Gateway: Invalid cover"
        );
        // check if request is fully funded or (reach target and passing expired date)
        require(
            coverGateway.isRequestCoverSucceed(cover.requestId),
            "Claim Gateway: Cover not yet started"
        );

        // check if msg.sender is funder of cover
        require(
            coverData.isFunderOfCover(msg.sender, _coverId),
            "Claim Gateway: Not funder of cover"
        );

        // check if funder already collect premium for request
        require(
            !coverData.isPremiumCollected(_coverId),
            "Claim Gateway: Premium already collected"
        );

        // mark funder as premium collectors
        coverData.setPremiumCollected(_coverId);

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            cover.requestId
        );
        // calculate premium for funder
        // formula : (fund provide by funder / insured sum of request) * premium sum
        uint256 totalPremium = (cover.insuredSum * coverRequest.premiumSum) /
            coverRequest.insuredSum;

        // Calcuclate Premium for Provider/Funder (80%) and Dev (20%)
        uint256 premiumToProvider = (totalPremium * 8) / 10;
        uint256 premiumToDev = totalPremium - premiumToProvider;

        // Send 80% to Provider/Funder
        pool.transferAsset(
            msg.sender,
            coverRequest.premiumCurrency,
            premiumToProvider
        );
        // Send 20% to Dev wallet
        pool.transferAsset(
            coverGateway.devWallet(),
            coverRequest.premiumCurrency,
            premiumToDev
        );

        // trigger event
        emit CollectPremium(
            cover.requestId,
            _coverId,
            msg.sender,
            uint8(coverRequest.premiumCurrency),
            premiumToProvider
        );
    }

    /**
    @dev only be able to call by holder to refund premium on cover request
    */
    function refundPremium(uint256 _requestId) external {
        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            _requestId
        );

        // only creator of request
        require(
            coverRequest.holder == msg.sender,
            "Claim Gateway: Not creator of request"
        );

        // check if already refund premium
        require(
            !listingData.requestIdToRefundPremium(_requestId),
            "Claim Gateway: Premium already refunded"
        );

        // check whethers request if success or fail
        // if request success & fully funded (either FULL FUNDING or PARTIAL FUNDING)
        // only the remaining premiumSum can be withdrawn
        // if request success & partiallly funded & time passing expired listing
        // only the remaining premiumSum can be withdrawn
        // if request unsuccessful & time passing expired listing
        // withdrawn all premium sum
        uint256 premiumWithdrawn;
        if (coverGateway.isRequestCoverSucceed(_requestId)) {
            // withdraw remaining premium
            // formula : (remaining insured sum / insured sum of request) * premium sum
            premiumWithdrawn =
                ((coverRequest.insuredSum -
                    listingData.requestIdToInsuredSumTaken(_requestId)) *
                    coverRequest.premiumSum) /
                coverRequest.insuredSum;
        } else if (
            !listingData.isRequestReachTarget(_requestId) &&
            (block.timestamp > coverRequest.expiredAt)
        ) {
            // fail request, cover request creator will be able to refund all premium
            premiumWithdrawn = coverRequest.premiumSum;
        } else {
            // can be caused by request not fullfil criteria to start cover
            // and not yet reach expired time
            revert("Claim Gateway: Cannot refund premium right now");
        }

        if (premiumWithdrawn != 0) {
            // mark the request has been refunded
            listingData.setRequestIdToRefundPremium(_requestId);

            // transfer asset
            pool.transferAsset(
                msg.sender,
                coverRequest.premiumCurrency,
                premiumWithdrawn
            );

            // emit event
            emit RefundPremium(
                _requestId,
                msg.sender,
                uint8(coverRequest.premiumCurrency),
                premiumWithdrawn
            );
        } else {
            revert("Claim Gateway: Nothing to refund");
        }
    }

    /**
    @dev will be call by funder of offer cover
    will send back deposit that funder already spend for offer cover
    */
    function takeBackDepositOfCoverOffer(uint256 _offerId) external {
        CoverOffer memory coverOffer = listingData.getCoverOfferById(_offerId);
        // must call by funder/creator of offer cover
        require(
            msg.sender == coverOffer.funder,
            "Claim Gateway: Not creator of offer"
        );

        // current time must passing lockup period
        require(
            block.timestamp > coverOffer.expiredAt,
            "Claim Gateway: Not passing lockup period"
        );

        // check is there any cover that still depend on this one
        require(
            !coverGateway.isCoverActiveExists(_offerId),
            "Claim Gateway : There is any active cover"
        );

        // check is there any claim that still pending
        require(
            !claimHelper.isPendingClaimExistOnOffer(_offerId),
            "Claim Gateway: Pending claims exists"
        );

        // check if already take back deposit
        require(
            !listingData.isDepositOfOfferTakenBack(_offerId),
            "Claim Gateway: Deposit already taken"
        );

        // execute any pending claims
        require(
            !claimHelper.isExpiredPendingClaimExist(
                ListingType.OFFER,
                _offerId
            ),
            "Claim Gateway: Expired pending claims exists"
        );

        // check remaining deposit
        uint256 remainingDeposit = coverOffer.insuredSum -
            claimData.offerIdToPayout(_offerId);

        if (remainingDeposit > 0) {
            // mark deposit already taken
            listingData.setDepositOfOfferTakenBack(
                _offerId,
                coverData.getCoversByOfferId(_offerId)
            );

            // send remaining deposit
            pool.transferAsset(
                msg.sender,
                coverOffer.insuredSumCurrency,
                remainingDeposit
            );
            // emit event
            emit TakeBackDeposit(
                _offerId,
                msg.sender,
                uint8(coverOffer.insuredSumCurrency),
                remainingDeposit
            );
        } else {
            revert("Claim Gateway: No deposit left");
        }
    }

    /**
    @dev will be call by funder that provide a cover request
    will send back deposit that funder already spend for a cover request
    */
    function refundDepositOfProvideCover(uint256 _coverId) external {
        InsuranceCover memory cover = coverData.getCoverById(_coverId);
        // cover must be coming from provide request
        require(
            cover.listingType == ListingType.REQUEST,
            "Claim Gateway: Cover not valid"
        );
        // check if msg.sender is funders of request
        require(
            coverData.isFunderOfCover(msg.sender, _coverId),
            "Claim Gateway: Not funder of cover"
        );
        // check if already take back deposit
        require(
            !listingData.isDepositTakenBack(_coverId),
            "Claim Gateway: Deposit already taken back"
        );

        // check is there any pending claims
        require(
            !claimHelper.isPendingClaimExistOnCover(_coverId),
            "Claim Gateway: Pending claim exists"
        );

        require(
            !claimHelper.isExpiredPendingClaimExistOnCover(_coverId),
            "Claim Gateway: Expired Pending Claim Exists"
        );

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            cover.requestId
        );
        uint256 coverEndAt = coverGateway.getEndAt(_coverId);

        // Cover Request is fail when request not reaching target & already passing listing expired time
        bool isCoverRequestFail = !listingData.isRequestReachTarget(
            cover.requestId
        ) && (block.timestamp > coverRequest.expiredAt);

        // Remaining deposit
        uint256 remainingDeposit = cover.insuredSum -
            claimData.coverToPayout(_coverId);

        // If ( cover request succedd & cover already expired & there is remaining deposit )
        // or cover request fail
        // then able to refund all funding
        // Otherwise cannot do refund
        if (
            (coverGateway.isRequestCoverSucceed(cover.requestId) &&
                coverEndAt < block.timestamp &&
                (remainingDeposit > 0)) || isCoverRequestFail
        ) {
            // mark cover as desposit already taken back
            listingData.setIsDepositTakenBack(_coverId);

            // send deposit
            pool.transferAsset(
                msg.sender,
                coverRequest.insuredSumCurrency,
                remainingDeposit
            );

            // emit event
            emit RefundDeposit(
                cover.requestId,
                _coverId,
                msg.sender,
                uint8(coverRequest.insuredSumCurrency),
                remainingDeposit
            );
        } else {
            revert("Claim Gateway: Cannot refund deposit right now");
        }
    }

    function withdrawExpiredPayout() external {
        // Only dev wallet address can call function
        require(
            msg.sender == cg.getLatestAddress("DW"),
            "Claim Gateway: Not allowed"
        );

        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            uint256 amount = claimData.totalExpiredPayout(CurrencyType(j));
            if (amount > 0) {
                // Change the value
                claimData.resetTotalExpiredPayout(CurrencyType(j));
                // transfer
                pool.transferAsset(
                    cg.getLatestAddress("DW"),
                    CurrencyType(j),
                    amount
                );
                // Emit event
                emit WithdrawExpiredPayout(
                    cg.getLatestAddress("DW"),
                    uint8(CurrencyType(j)),
                    amount
                );
            }
        }
    }

    function validateAlPendingClaims(ListingType _listingType, address _funder)
        external
    {
        // get list of listing id
        uint256[] memory listingIds = (_listingType == ListingType.OFFER)
            ? listingData.getFunderToOffers(_funder)
            : coverData.getFunderToRequestId(_funder);

        // Loop and Validate expired pending claims on every listing id
        for (uint256 i = 0; i < listingIds.length; i++) {
            claimHelper.execExpiredPendingClaims(_listingType, listingIds[i]);
        }
    }

    function validatePendingClaims(ListingType _listingType, uint256 _listingId)
        external
    {
        // Validate expired pending claims
        claimHelper.execExpiredPendingClaims(_listingType, _listingId);
    }

    function validatePendingClaimsByCover(uint256 _coverId) external {
        // Get Cover
        InsuranceCover memory cover = coverData.getCoverById(_coverId);
        // Price feed aggregator address
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        // Validate expired pending claims
        claimHelper.execExpiredPendingClaimsByCoverId(priceFeedAddr, _coverId);
    }

    function validatePendingClaimsById(uint256 _claimId) external {
        // Validate expired pending claims
        claimHelper.checkValidity(_claimId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {Master} from "../Master/Master.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ClaimHelper is Master {
    // State variables
    CoverGateway private coverGateway;
    ListingGateway private listingGateway;
    CoverData private coverData;
    ClaimData private claimData;
    ListingData private listingData;
    PlatformData private platformData;
    Pool private pool;
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant STABLECOINS_STANDARD_PRICE = 1;
    uint256 private constant MAX_DEVALUATION = 25; // in percentage
    uint256 public constant MONITORING_PERIOD = 72 hours;
    uint256 private constant MAX_PAYOUT_PERIOD = 30 days;
    uint256 private constant VALIDATION_PREVIOUS_PERIOD = 1 hours;

    // Indicate there is a fund from expired claim payout that can be owned by platform
    event ExpiredValidClaim(
        uint256 coverId,
        uint256 claimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );

    // Indicate there the fund from expired claim payout still belongs to funder
    event ExpiredInvalidClaim(uint256 coverId, uint256 claimId);

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );

        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        listingGateway = ListingGateway(cg.getLatestAddress("LG"));
        coverData = CoverData(cg.getLatestAddress("CD"));
        claimData = ClaimData(cg.getLatestAddress("CM"));
        listingData = ListingData(cg.getLatestAddress("LD"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
        pool = Pool(cg.getLatestAddress("PL"));
    }

    function getPayout(
        InsuranceCover memory cover,
        uint256 assetPrice,
        uint8 decimals
    ) public view returns (uint256) {
        uint256 devaluationPerAsset = (STABLECOINS_STANDARD_PRICE *
            (10**decimals)) - uint256(assetPrice);

        // Get insured sum currency decimals
        CurrencyType insuredSumCurrency = (cover.listingType ==
            ListingType.REQUEST)
            ? listingData
                .getCoverRequestById(cover.requestId)
                .insuredSumCurrency
            : listingData.getCoverOfferById(cover.offerId).insuredSumCurrency;

        uint8 insuredSumCurrencyDecimals = cg.getCurrencyDecimal(
            uint8(insuredSumCurrency)
        );
        // Get payout in USD : insured sum * asset devaluation
        uint256 payoutInUSD = (cover.insuredSum * devaluationPerAsset) /
            (10**insuredSumCurrencyDecimals);
        // Convert payout in USD to insured sum currency
        uint256 payout = (payoutInUSD * (10**insuredSumCurrencyDecimals)) /
            assetPrice;

        return payout;
    }

    function getRoundId(uint16 _phase, uint64 _originalId)
        public
        pure
        returns (uint80)
    {
        return uint80((uint256(_phase) << PHASE_OFFSET) | _originalId);
    }

    function parseIds(uint256 _roundId) public pure returns (uint16, uint64) {
        uint16 phaseId = uint16(_roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(_roundId);

        return (phaseId, aggregatorRoundId);
    }

    function getMedian(address _priceFeedAddr, uint80 _startRoundId)
        public
        view
        returns (uint256, uint8)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddr);

        // Get Phase Id & start original round id
        (uint16 phaseId, uint64 startOriginalRoundId) = parseIds(_startRoundId);

        // Get Latest Round
        (, , uint256 timestampOfLatestRound, , ) = priceFeed.latestRoundData();

        // Get Event Round
        (, , uint256 timestampOfEvent, , ) = priceFeed.getRoundData(
            _startRoundId
        );

        require(
            timestampOfEvent + MONITORING_PERIOD < timestampOfLatestRound,
            "Claim Gateway: Must passing monitoring time"
        );

        // Initial Value
        uint64 currentOriginalRoundId = startOriginalRoundId;
        uint256[] memory priceArr = new uint256[](72 * 3);
        uint256[] memory timestampArr = new uint256[](72 * 3);
        uint256 startedAtTemp = timestampOfEvent;

        while (startedAtTemp <= timestampOfEvent + MONITORING_PERIOD) {
            // Get Price
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
                getRoundId(phaseId, currentOriginalRoundId)
            );

            require(timestamp > 0, "Claim Gateway: Round not complete");

            // update parameter value of loop
            startedAtTemp = timestamp;

            // Save value to array
            priceArr[(currentOriginalRoundId - startOriginalRoundId)] = uint256(
                price
            );
            timestampArr[
                (currentOriginalRoundId - startOriginalRoundId)
            ] = timestamp;

            // increment
            currentOriginalRoundId += 1;
        }

        // Initial Array for time diff
        uint256[] memory timeDiffArr = new uint256[](
            currentOriginalRoundId - startOriginalRoundId - 1
        );

        // Calculation for time different
        for (
            uint256 i = 0;
            i < (currentOriginalRoundId - startOriginalRoundId - 1);
            i++
        ) {
            if (i == 0) {
                timeDiffArr[0] = timestampArr[1] - timestampArr[0];
            } else if (
                i == (currentOriginalRoundId - startOriginalRoundId) - 2
            ) {
                timeDiffArr[i] =
                    (timestampOfEvent + MONITORING_PERIOD) -
                    timestampArr[i];
            } else {
                timeDiffArr[i] = timestampArr[i + 1] - timestampArr[i];
            }
        }

        // Sorting
        quickSort(
            priceArr,
            timeDiffArr,
            0,
            (int64(currentOriginalRoundId) - int64(startOriginalRoundId) - 2) // last index of array
        );

        // Find Median Price
        uint256 commulativeSum = timestampOfEvent;
        uint256 selectedIndex;
        for (uint256 i = 0; i < timeDiffArr.length; i++) {
            commulativeSum += timeDiffArr[i];
            if (
                commulativeSum >= (timestampOfEvent + (MONITORING_PERIOD / 2))
            ) {
                selectedIndex = i;
                break;
            }
        }

        return (priceArr[selectedIndex], priceFeed.decimals());
    }

    // Sorting Algorithm
    function quickSort(
        uint256[] memory arr,
        uint256[] memory arr2,
        int256 left,
        int256 right
    ) public view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                (arr2[uint256(i)], arr2[uint256(j)]) = (
                    arr2[uint256(j)],
                    arr2[uint256(i)]
                );
                i++;
                j--;
            }
        }

        if (left < j) quickSort(arr, arr2, left, j);
        if (i < right) quickSort(arr, arr2, i, right);
    }

    /**
     * @dev validate by looking at pricing in previous rounds that make up duration of 1 hour (VALIDATION_PREVIOUS_PERIOD)
     */
    function isValidPastDevaluation(address priceFeedAddr, uint80 _roundId)
        public
        view
        returns (bool isValidDevaluation)
    {
        isValidDevaluation = true;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Get Phase Id & start original round id
        (uint16 phaseId, uint64 originalRoundId) = parseIds(_roundId);
        // Call aggregator to Get Event Detail
        (, , uint256 eventStartedAt, , ) = priceFeed.getRoundData(_roundId);
        uint256 prevStartedAt = 0;

        do {
            // deduct originalRoundId every iteration
            originalRoundId -= 1;

            // Call aggregator to get price and time
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
                getRoundId(phaseId, originalRoundId)
            );
            prevStartedAt = timestamp;

            // check price, must below standard/below 1$
            // threshold is a price that indicates stablecoins are devalued
            uint256 threshold = ((100 - MAX_DEVALUATION) *
                (STABLECOINS_STANDARD_PRICE * (10**priceFeed.decimals()))) /
                100;

            // Mark as non devaluation is eq or bigger tha nthreshold
            if (uint256(price) >= threshold) {
                isValidDevaluation = false;
                break;
            }

            // Will loop until check last 1 hour price (VALIDATION_PREVIOUS_PERIOD)
        } while (prevStartedAt > eventStartedAt - VALIDATION_PREVIOUS_PERIOD);

        return isValidDevaluation;
    }

    // Need to be internal
    function execExpiredPendingClaims(ListingType _listingType, uint256 _id)
        public
        onlyInternal
    {
        // Price feed aggregator address
        string memory coinId = (_listingType == ListingType.REQUEST)
            ? listingData.getCoverRequestById(_id).coinId
            : listingData.getCoverOfferById(_id).coinId;
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(coinId);

        uint256[] memory coverIds = (_listingType == ListingType.REQUEST)
            ? coverData.getCoversByRequestId(_id)
            : coverData.getCoversByOfferId(_id);

        for (uint256 i = 0; i < coverIds.length; i++) {
            execExpiredPendingClaimsByCoverId(priceFeedAddr, coverIds[i]);
        }
    }

    function getPriceFeedAddress(InsuranceCover memory _cover)
        public
        view
        returns (address priceFeedAddr)
    {
        string memory coinId = (_cover.listingType == ListingType.REQUEST)
            ? listingData.getCoverRequestById(_cover.requestId).coinId
            : listingData.getCoverOfferById(_cover.offerId).coinId;
        priceFeedAddr = platformData.getOraclePriceFeedAddress(coinId);
    }

    function execExpiredPendingClaimsByCoverId(
        address _priceFeedAddr,
        uint256 _coverId
    ) public onlyInternal {
        uint256[] memory claimIds = claimData.getCoverToClaims(_coverId);

        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);
            if (claim.state == ClaimState.MONITORING) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(
                    _priceFeedAddr
                );
                (, , uint256 startedAt, , ) = priceFeed.getRoundData(
                    claim.roundId
                );
                if (
                    block.timestamp >
                    (startedAt + MONITORING_PERIOD + MAX_PAYOUT_PERIOD)
                ) {
                    _checkValidity(claimIds[j], _priceFeedAddr);
                }
            }
        }
    }

    function checkValidity(uint256 _claimId) external {
        uint256 coverId = claimData.claimToCover(_claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        // Price feed aggregator address
        address priceFeedAddr = getPriceFeedAddress(cover);

        _checkValidity(_claimId, priceFeedAddr);
    }

    function _checkValidity(uint256 _claimId, address _priceFeedAddr) internal {
        Claim memory claim = claimData.getClaimById(_claimId);

        // For stablecoins devaluation will decided based on oracle
        (
            bool isClaimValid,
            uint256 assetPrice,
            uint8 decimals
        ) = checkClaimForDevaluation(_priceFeedAddr, claim.roundId);

        uint256 coverId = claimData.claimToCover(_claimId);
        if (isClaimValid) {
            uint256 payout = 0;
            // Calculate Payout
            InsuranceCover memory cover = coverData.getCoverById(coverId);
            payout = getPayout(cover, assetPrice, decimals);
            require(
                claimData.coverToPayout(coverId) + payout <= cover.insuredSum,
                "Claim Gateway: Insufficient funds"
            );

            // Set cover to payout
            claimData.setCoverToPayout(coverId, payout);

            // set state var for store payour per request/offer
            CurrencyType currency;
            if (cover.listingType == ListingType.OFFER) {
                // Get cover offer
                CoverOffer memory coverOffer = listingData.getCoverOfferById(
                    cover.offerId
                );
                currency = coverOffer.insuredSumCurrency;
                // Update total payout of offer cover
                claimData.setOfferIdToPayout(cover.offerId, payout);
            } else if (cover.listingType == ListingType.REQUEST) {
                // Get cover request
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                currency = coverRequest.insuredSumCurrency;
                // Update total payout of offer request
                claimData.setRequestIdToPayout(cover.requestId, payout);
            }
            // update state of claim
            claimData.updateClaimState(
                _claimId,
                ClaimState.VALID_AFTER_EXPIRED
            );

            // Update total fund that can be owned by platform
            claimData.addTotalExpiredPayout(currency, payout);

            emit ExpiredValidClaim(coverId, _claimId, uint8(currency), payout);
        } else {
            // update state of claim
            claimData.updateClaimState(
                _claimId,
                ClaimState.INVALID_AFTER_EXPIRED
            );
            emit ExpiredInvalidClaim(coverId, _claimId);
        }
    }

    /**
     * @dev check if any pending claims exists in the payout period
     */
    function isPendingClaimExistOnOffer(uint256 _offerId)
        public
        view
        returns (bool statePendingClaimExists)
    {
        // get list id of cover
        uint256[] memory coverIds = coverData.getCoversByOfferId(_offerId);

        // Loop all cover on the offer
        for (uint256 i = 0; i < coverIds.length; i++) {
            if (isPendingClaimExistOnCover(coverIds[i])) {
                statePendingClaimExists = true;
                break;
            }
        }
    }

    /**
     * @dev check if any pending claim exists on cover , pending claim is a claim with state "Monitoring" and still on range of payout period
     */
    function isPendingClaimExistOnCover(uint256 _coverId)
        public
        view
        returns (bool statePendingClaimExists)
    {
        InsuranceCover memory cover = coverData.getCoverById(_coverId);
        address priceFeedAddr = getPriceFeedAddress(cover);

        // Price feed aggregator
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        uint256[] memory claimIds = claimData.getCoverToClaims(_coverId);

        // Loop all claim on the cover
        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);

            // check if any MONITORING claim and still on payout period
            // a.k.a check is there any claims that not yet trigger checkValidityAndPayout function
            if (claim.state == ClaimState.MONITORING) {
                // Call aggregator to get event tomestamp
                (, , , uint256 claimEventTimestamp, ) = priceFeed.getRoundData(
                    claim.roundId
                );

                if (
                    block.timestamp <=
                    (claimEventTimestamp +
                        MONITORING_PERIOD +
                        MAX_PAYOUT_PERIOD)
                ) {
                    statePendingClaimExists = true;
                    break;
                }
            }
        }
    }

    function isFunderHasExpiredPendingClaims(
        ListingType _listingType,
        address _funder
    ) public view returns (bool statePendingClaimExists) {
        uint256[] memory listingIds = (_listingType == ListingType.OFFER)
            ? listingData.getFunderToOffers(_funder)
            : coverData.getFunderToRequestId(_funder);

        // Loop all cover on the offer
        for (uint256 i = 0; i < listingIds.length; i++) {
            if (isExpiredPendingClaimExist(_listingType, listingIds[i])) {
                statePendingClaimExists = true;
                break;
            }
        }
    }

    function isExpiredPendingClaimExist(ListingType _listingType, uint256 _id)
        public
        view
        returns (bool statePendingClaimExists)
    {
        // get list id of cover
        uint256[] memory coverIds = _listingType == ListingType.OFFER
            ? coverData.getCoversByOfferId(_id)
            : coverData.getCoversByRequestId(_id);

        // Loop all cover on the offer
        for (uint256 i = 0; i < coverIds.length; i++) {
            if (isExpiredPendingClaimExistOnCover(coverIds[i])) {
                statePendingClaimExists = true;
                break;
            }
        }
    }

    /**
     * @dev check if any pending claim exists on cover after expired payout time, pending claim is a claim with state "Monitoring" and still on range of payout period
     */
    function isExpiredPendingClaimExistOnCover(uint256 _coverId)
        public
        view
        returns (bool stateExpiredPendingClaimExists)
    {
        InsuranceCover memory cover = coverData.getCoverById(_coverId);
        address priceFeedAddr = getPriceFeedAddress(cover);

        // Price feed aggregator
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        uint256[] memory claimIds = claimData.getCoverToClaims(_coverId);

        // Loop all claim on the cover
        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);

            // check if any MONITORING claim and still on payout period
            // a.k.a check is there any claims that not yet trigger checkValidityAndPayout function
            if (claim.state == ClaimState.MONITORING) {
                // Call aggregator to get event tomestamp
                (, , , uint256 claimEventTimestamp, ) = priceFeed.getRoundData(
                    claim.roundId
                );

                if (
                    block.timestamp >
                    (claimEventTimestamp +
                        MONITORING_PERIOD +
                        MAX_PAYOUT_PERIOD)
                ) {
                    stateExpiredPendingClaimExists = true;
                    break;
                }
            }
        }
    }

    /**
    @dev check validity of devaluation claim
    @return isValidClaim bool as state of valid claim
    @return assetPrice is devaluation price per asset
    @return decimals is decimals of price feed
     */
    function checkClaimForDevaluation(
        address _aggregatorAddress,
        uint80 _roundId
    )
        public
        view
        returns (
            bool isValidClaim,
            uint256 assetPrice,
            uint8 decimals
        )
    {
        // NOTE : comment out when testing
        // Devaluation
        // return (true, 750000, 6);
        // Non Devaluation
        // return (false, 1000000, 6);
        // Get median price and decimals
        (uint256 price, uint8 priceDecimals) = getMedian(
            _aggregatorAddress,
            _roundId
        );
        // threshold is a price that indicates stablecoins are devalued
        uint256 threshold = ((100 - MAX_DEVALUATION) *
            (STABLECOINS_STANDARD_PRICE * (10**priceDecimals))) / 100;
        // if price under threshold then its mark as devaluation
        // else mark as non-devaluation
        isValidClaim = price < threshold ? true : false;
        return (isValidClaim, price, priceDecimals);
    }

    function convertPrice(uint256[] memory withdrawable, uint256[] memory lock)
        public
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockInUSD,
            uint8 usdDecimals
        )
    {
        usdDecimals = 6;

        // Loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            uint8 assetDecimals = cg.getCurrencyDecimal(j);
            // Get latest price of stable coins
            string memory coinId = cg.getCurrencyName(j);
            address priceFeedAddr = platformData.getOraclePriceFeedAddress(
                coinId
            );
            AggregatorV3Interface priceFeed = AggregatorV3Interface(
                priceFeedAddr
            );
            (, int256 currentPrice, , , ) = priceFeed.latestRoundData();
            uint8 priceFeedDecimals = priceFeed.decimals();

            // Formula : total asset * price per asset from pricefeed * usd decimals / asset decimals / price feed decimal
            totalWithdrawInUSD += ((withdrawable[j] *
                uint256(currentPrice) *
                (10**usdDecimals)) /
                (10**assetDecimals) /
                (10**priceFeedDecimals));
            totalLockInUSD += ((lock[j] *
                uint256(currentPrice) *
                (10**usdDecimals)) /
                (10**assetDecimals) /
                (10**priceFeedDecimals));
        }

        return (totalWithdrawInUSD, totalLockInUSD, usdDecimals);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {CoverData} from "../Data/CoverData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {ClaimGateway} from "./ClaimGateway.sol";
import {ClaimHelper} from "./ClaimHelper.sol";
import {Master} from "../Master/Master.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CollectiveClaimGateway is Master {
    // State variables
    CoverGateway private coverGateway;
    ListingGateway private listingGateway;
    ClaimGateway private claimGateway;
    CoverData private coverData;
    ClaimData private claimData;
    ListingData private listingData;
    PlatformData private platformData;
    ClaimHelper private claimHelper;
    Pool private pool;

    event CollectivePremium(
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event CollectiveRefundPremium(
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event CollectiveTakeBackDeposit(
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event CollectiveRefundDeposit(
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event ValidCollectiveClaim(
        uint256 requestId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );
        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        listingGateway = ListingGateway(cg.getLatestAddress("LG"));
        claimGateway = ClaimGateway(cg.getLatestAddress("CL"));
        coverData = CoverData(cg.getLatestAddress("CD"));
        claimData = ClaimData(cg.getLatestAddress("CM"));
        listingData = ListingData(cg.getLatestAddress("LD"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
        pool = Pool(cg.getLatestAddress("PL"));
        claimHelper = ClaimHelper(cg.getLatestAddress("CH"));
    }

    /**
     * @dev called by creater of request to make a claim
     */
    function collectiveSubmitClaim(uint256 _requestId, uint80 _roundId)
        external
    {
        // Make sure request is succedd request
        require(coverGateway.isRequestCoverSucceed(_requestId));

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            _requestId
        );
        // cover must be still active
        uint256 startAt = listingData.isRequestFullyFunded(_requestId)
            ? listingData.coverRequestFullyFundedAt(_requestId)
            : coverRequest.expiredAt;
        require(
            startAt <= block.timestamp &&
                block.timestamp <=
                (startAt + (coverRequest.coverMonths * 30 days)), // end at of request
            "Collective Claim Gateway: Cover is not active"
        );

        // Check request own by msg.sender
        require(
            coverRequest.holder == msg.sender,
            "Collective Claim Gateway: Not request's owner"
        );

        // Get list id of covers
        uint256[] memory listCoverIds = coverData.getCoversByRequestId(
            _requestId
        );

        // make sure there is no valid claim
        require(
            !claimData.isValidClaimExists(listCoverIds[0]),
            "Collective Claim Gateway : Valid claim exists"
        );

        // Cannot use same roundId to submit claim on cover
        require(
            claimData.uniqueRoundId(listCoverIds[0], _roundId),
            "Claim Gateway: Cannot use same round id"
        );

        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            listingData.getCoverRequestById(_requestId).coinId
        );

        // Call aggregator
        (, , , uint256 eventTimestamp, ) = AggregatorV3Interface(priceFeedAddr)
            .getRoundData(_roundId);

        // NOTE : comment out when testing
        // validate timestamp of price feed, time of round id must in range of cover period
        require(
            startAt <= eventTimestamp &&
                eventTimestamp <=
                (startAt + (coverRequest.coverMonths * 30 days)),
            "Claim Gateway: Invalid time of price feed"
        );

        // NOTE : comment out when testing
        // Check 1 hours before roundId, make sure the devaluation id valid
        require(
            claimHelper.isValidPastDevaluation(priceFeedAddr, _roundId),
            "Claim Gateway: Previous round not devaluation"
        );

        // Add filing claim
        uint256[] memory claimsIds = new uint256[](listCoverIds.length);

        // Loop each covers
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            // add filing claim
            uint256 claimId = claimData.addClaim(
                listCoverIds[i],
                _roundId,
                eventTimestamp,
                msg.sender
            );

            claimsIds[i] = claimId;
        }

        claimData.addCollectiveClaim(
            _requestId,
            _roundId,
            eventTimestamp,
            claimsIds,
            msg.sender
        );

        // + 1 hours is a buffer time
        if (
            (eventTimestamp + claimGateway.MONITORING_PERIOD()) + 1 hours <=
            block.timestamp
        ) {
            for (uint256 i = 0; i < claimsIds.length; i++) {
                // Check validity and make payout
                claimGateway.checkValidityAndPayout(
                    claimsIds[i],
                    priceFeedAddr
                );
            }
        }
    }

    /**
    @dev function called by funder that provide on success cover request
    function will send premium back to funder
    */
    function collectivePremiumForFunder() external {
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(msg.sender);

        // initialize variable for store total premium for each currency
        uint256[] memory totalPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // loop each cover
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);

            // only success request cover & premium which not yet collected will be count
            if (
                cover.listingType == ListingType.REQUEST &&
                coverGateway.isRequestCoverSucceed(cover.requestId) &&
                !coverData.isPremiumCollected(coverId)
            ) {
                // mark cover as premium collecter
                coverData.setPremiumCollected(coverId);

                // increase total premium based on currency type (premium currency)
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                totalPremium[uint8(coverRequest.premiumCurrency)] +=
                    (cover.insuredSum * coverRequest.premiumSum) /
                    coverRequest.insuredSum;
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (totalPremium[j] > 0) {
                // Calcuclate Premium for Provider/Funder (80%) and Dev (20%)
                uint256 premiumToProvider = (totalPremium[j] * 8) / 10;
                uint256 premiumToDev = totalPremium[j] - premiumToProvider;

                // Send 80% to Provider/Funder
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    premiumToProvider
                );

                // Send 20% to Dev wallet
                pool.transferAsset(
                    coverGateway.devWallet(),
                    CurrencyType(j),
                    premiumToDev
                );

                // trigger event
                emit CollectivePremium(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    premiumToProvider
                );
            }
        }
    }

    function getWithdrawablePremiumData(address _funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawablePremiumInUSD,
            uint256[] memory withdrawablePremiumList,
            uint8 usdDecimals
        )
    {
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(
            _funderAddr
        );

        // initialize variable for store total premium for each currency
        uint256[] memory totalPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // loop each cover
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);

            // only success request cover & premium which not yet collected will be count
            if (
                cover.listingType == ListingType.REQUEST &&
                coverGateway.isRequestCoverSucceed(cover.requestId) &&
                !coverData.isPremiumCollected(coverId)
            ) {
                // increase total premium based on currency type (premium currency)
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                totalPremium[uint8(coverRequest.premiumCurrency)] +=
                    (cover.insuredSum * coverRequest.premiumSum) /
                    coverRequest.insuredSum;
            }
        }

        (totalWithdrawablePremiumInUSD, , usdDecimals) = claimHelper
            .convertPrice(totalPremium, totalPremium);

        return (totalWithdrawablePremiumInUSD, totalPremium, usdDecimals);
    }

    /**
     * Note
     * @dev return total of premium and total of withdrawable premium
     * called by holder for refund premium from cover request
     */

    function getPremiumDataOfCoverRequest(address holderAddr)
        public
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockPremiumInUSD,
            uint256[] memory withdrawablePremiumList,
            uint8 usdDecimals
        )
    {
        uint256[] memory withdrawablePremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        uint256[] memory lockPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // get list of request id that created by holder
        uint256[] memory listRequestIds = listingData.getBuyerToRequests(
            holderAddr
        );

        for (uint256 i = 0; i < listRequestIds.length; i++) {
            uint256 requestId = listRequestIds[i];
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            bool isRequestCoverSuccedd = coverGateway.isRequestCoverSucceed(
                requestId
            );
            // fail request is request that not react target and already passing listing expired time
            bool isFailRequest = !listingData.isRequestReachTarget(requestId) &&
                (block.timestamp > coverRequest.expiredAt);

            if (!listingData.requestIdToRefundPremium(requestId)) {
                if (isRequestCoverSuccedd || isFailRequest) {
                    withdrawablePremium[
                        uint8(coverRequest.premiumCurrency)
                    ] += (
                        isFailRequest
                            ? coverRequest.premiumSum
                            : (((coverRequest.insuredSum -
                                listingData.requestIdToInsuredSumTaken(
                                    requestId
                                )) * coverRequest.premiumSum) /
                                coverRequest.insuredSum)
                    );
                } else {
                    lockPremium[
                        uint8(coverRequest.premiumCurrency)
                    ] += coverRequest.premiumSum;
                }
            }
        }

        (totalWithdrawInUSD, totalLockPremiumInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawablePremium, lockPremium);

        return (
            totalWithdrawInUSD,
            totalLockPremiumInUSD,
            withdrawablePremium,
            usdDecimals
        );
    }

    /**
    @dev function called by holder of failed cover request
    function will send premium back to holder
    */
    function collectiveRefundPremium() external {
        // get list of request id that created by holder
        uint256[] memory listRequestIds = listingData.getBuyerToRequests(
            msg.sender
        );
        uint256[] memory premiumWithdrawn = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        for (uint256 i = 0; i < listRequestIds.length; i++) {
            uint256 requestId = listRequestIds[i];
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            bool isRequestCoverSuccedd = coverGateway.isRequestCoverSucceed(
                requestId
            );

            // fail request is request that not react target and already passing listing expired time
            bool isFailRequest = !listingData.isRequestReachTarget(requestId) &&
                (block.timestamp > coverRequest.expiredAt);

            // only request that
            // not yet refunded & (succedd request or fail request)
            // will count
            if (
                coverRequest.holder == msg.sender &&
                !listingData.requestIdToRefundPremium(requestId) &&
                (isRequestCoverSuccedd || isFailRequest)
            ) {
                // if fail request
                // then increase by CoverRequest.premiumSum a.k.a refund all premium
                // if cover succedd
                // then using formula : (remaining insured sum / insured sum of request) * premium sum
                // a.k.a only refund remaining premim sum
                premiumWithdrawn[uint8(coverRequest.premiumCurrency)] += (
                    isFailRequest
                        ? coverRequest.premiumSum
                        : (((coverRequest.insuredSum -
                            listingData.requestIdToInsuredSumTaken(requestId)) *
                            coverRequest.premiumSum) / coverRequest.insuredSum)
                );

                // mark request as refunded
                listingData.setRequestIdToRefundPremium(requestId);
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (premiumWithdrawn[j] > 0) {
                // transfer asset
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    premiumWithdrawn[j]
                );

                // emit event
                emit CollectiveRefundPremium(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    premiumWithdrawn[j]
                );
            }
        }
    }

    /**
     * @dev return total of locked deposit and total of withdrawable deposit
     * called by funder
     */
    function getDepositDataOfOfferCover(address funderAddr)
        public
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockDepositInUSD,
            uint256[] memory withdrawableDepositList,
            uint8 usdDecimals
        )
    {
        uint256[] memory withdrawableDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        uint256[] memory lockDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // Get List Id of offers
        uint256[] memory listOfferIds = listingData.getFunderToOffers(
            funderAddr
        );

        for (uint256 i = 0; i < listOfferIds.length; i++) {
            // Get Offer Id
            uint256 offerId = listOfferIds[i];
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                offerId
            );

            if (!listingData.isDepositOfOfferTakenBack(offerId)) {
                if (
                    block.timestamp > coverOffer.expiredAt &&
                    !coverGateway.isCoverActiveExists(offerId) &&
                    !claimHelper.isPendingClaimExistOnOffer(offerId)
                ) {
                    // Get Withdrawable Deposit a.k.a deposit that not locked
                    // deduct by by payout
                    withdrawableDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                        coverOffer.insuredSum -
                        claimData.offerIdToPayout(offerId);
                } else {
                    // Get Lock Deposit deduct by by payout
                    lockDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                        coverOffer.insuredSum -
                        claimData.offerIdToPayout(offerId);
                }
            }
        }

        (totalWithdrawInUSD, totalLockDepositInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawableDeposit, lockDeposit);

        return (
            totalWithdrawInUSD,
            totalLockDepositInUSD,
            withdrawableDeposit,
            usdDecimals
        );
    }

    /**
     * @dev function called by funder which creator of cover offer
     * function will send back deposit to funder
     */
    function collectiveRefundDepositOfCoverOffer() external {
        require(
            !claimHelper.isFunderHasExpiredPendingClaims(
                ListingType.OFFER,
                msg.sender
            ),
            "Collective Claim gateway: Expired pending claim exists"
        );
        // get list offer id of funder
        uint256[] memory listOfferIds = listingData.getFunderToOffers(
            msg.sender
        );
        uint256[] memory remainingDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        for (uint256 i = 0; i < listOfferIds.length; i++) {
            uint256 offerId = listOfferIds[i];
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                offerId
            );

            // only cover offer that
            // passing listing expired time
            // & there is no active cover depend on the offer
            // & not yet take back deposit
            if (
                msg.sender == coverOffer.funder &&
                block.timestamp > coverOffer.expiredAt &&
                !coverGateway.isCoverActiveExists(offerId) &&
                !listingData.isDepositOfOfferTakenBack(offerId) &&
                !claimHelper.isPendingClaimExistOnOffer(offerId)
            ) {
                // increase total deposit based on currency type (premium currency)
                remainingDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                    coverOffer.insuredSum -
                    claimData.offerIdToPayout(offerId);

                // mark deposit already taken
                listingData.setDepositOfOfferTakenBack(
                    offerId,
                    coverData.getCoversByOfferId(offerId)
                );
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (remainingDeposit[j] > 0) {
                // send deposit
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    remainingDeposit[j]
                );
                // emit event
                emit CollectiveTakeBackDeposit(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    remainingDeposit[j]
                );
            }
        }
    }

    /**
     * @dev return total of locked deposit and total of withdrawable deposit
     * called by funder for refund deposit on provide cover request
     */
    function getDepositOfProvideCover(address funderAddr)
        public
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockDepositInUSD,
            uint256[] memory withdrawableDeposit,
            uint8 usdDecimals
        )
    {
        withdrawableDeposit = new uint256[](uint8(CurrencyType.END_ENUM));
        uint256[] memory lockDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );
        uint256[] memory listCoverIds = coverData.getFunderToCovers(funderAddr);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);
            if (
                cover.listingType == ListingType.REQUEST &&
                !listingData.isDepositTakenBack(coverId)
            ) {
                // get Cover Request data
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                // get expired time of cover
                uint256 coverEndAt = coverGateway.getEndAt(coverId);
                // Cover Request is fail when request not reaching target & already passing listing expired time
                bool isCoverRequestFail = !listingData.isRequestReachTarget(
                    cover.requestId
                ) && (block.timestamp > coverRequest.expiredAt);
                // Remaining deposit
                uint256 remainingDeposit = cover.insuredSum -
                    claimData.coverToPayout(coverId);

                if (
                    (coverGateway.isRequestCoverSucceed(cover.requestId) &&
                        coverEndAt < block.timestamp &&
                        !claimHelper.isPendingClaimExistOnCover(coverId) &&
                        (remainingDeposit > 0)) || isCoverRequestFail
                ) {
                    // Get withdrawable deposit
                    withdrawableDeposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;
                } else {
                    // Get Lock Deposit deduct by by payout
                    lockDeposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;
                }
            }
        }

        (totalWithdrawInUSD, totalLockDepositInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawableDeposit, lockDeposit);

        return (
            totalWithdrawInUSD,
            totalLockDepositInUSD,
            withdrawableDeposit,
            usdDecimals
        );
    }

    /**
    @dev function called by FUNDER which PROVIDE FUND for COVER REQUEST
    function will send back deposit to funder
    */
    function collectiveRefundDepositOfProvideRequest() external {
        require(
            !claimHelper.isFunderHasExpiredPendingClaims(
                ListingType.REQUEST,
                msg.sender
            ),
            "Collective Claim Gateway: Expired pending claim exists"
        );
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(msg.sender);
        uint256[] memory deposit = new uint256[](uint8(CurrencyType.END_ENUM));

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            InsuranceCover memory cover = coverData.getCoverById(
                listCoverIds[i]
            );
            if (cover.listingType == ListingType.REQUEST) {
                // get Cover Request data
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);

                // get expired time of cover
                uint256 coverEndAt = coverGateway.getEndAt(listCoverIds[i]);
                // Cover Request is fail when request not reaching target & already passing listing expired time
                bool isCoverRequestFail = !listingData.isRequestReachTarget(
                    cover.requestId
                ) && (block.timestamp > coverRequest.expiredAt);

                // Remaining deposit
                uint256 remainingDeposit = cover.insuredSum -
                    claimData.coverToPayout(listCoverIds[i]);

                // only cover that
                // not yet take deposit back
                // &
                // ((succedd cover request that passing expired cover time and doesnlt have valid claim) or fail request)
                if (
                    coverData.isFunderOfCover(msg.sender, listCoverIds[i]) &&
                    !listingData.isDepositTakenBack(listCoverIds[i]) &&
                    !claimHelper.isPendingClaimExistOnCover(listCoverIds[i]) &&
                    ((coverGateway.isRequestCoverSucceed(cover.requestId) &&
                        coverEndAt < block.timestamp &&
                        (remainingDeposit > 0)) || isCoverRequestFail)
                ) {
                    // increase total deposit based on currency type (premium currency)
                    deposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;

                    // mark cover as desposit already taken back
                    listingData.setIsDepositTakenBack(listCoverIds[i]);
                }
            }
        }

        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (deposit[j] > 0) {
                // send deposit
                pool.transferAsset(msg.sender, CurrencyType(j), deposit[j]);

                // emit event
                emit CollectiveRefundDeposit(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    deposit[j]
                );
            }
        }
    }

    function checkPayout(uint256 _collectiveClaimId) external {
        uint256 requestId = claimData.collectiveClaimToRequest(
            _collectiveClaimId
        );
        // make sure there is no valid claim
        require(
            !claimData.isValidClaimExistOnRequest(requestId),
            "Collective Claim Gateway : Valid claim exists"
        );

        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(_collectiveClaimId);
        // Price feed aggregator
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            listingData.getCoverRequestById(requestId).coinId
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Call aggregator
        (, , uint256 startedAt, , ) = priceFeed.getRoundData(
            collectiveClaim.roundId
        );
        require(
            ((startedAt + claimGateway.MONITORING_PERIOD()) + 1 hours) <
                block.timestamp,
            "Collective Claim Gateway: still on monitoring period"
        );

        // Check status of collective claim , must still on monitoring
        require(
            collectiveClaim.state == ClaimState.MONITORING,
            "Collective Claim Gateway : Already check payout"
        );

        require(
            block.timestamp <=
                (startedAt +
                    claimGateway.MONITORING_PERIOD() +
                    claimGateway.MAX_PAYOUT_PERIOD()),
            "Collective Claim Gateway: passing payout period"
        );
        for (uint256 i = 0; i < collectiveClaim.claimIds.length; i++) {
            // Check validity and make payout
            claimGateway.checkValidityAndPayout(
                collectiveClaim.claimIds[i],
                priceFeedAddr
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Master} from "../Master/Master.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {Pool} from "../Capital/Pool.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract CoverGateway is Master {
    // State variables
    CoverData private cd;
    ListingData private ld;
    Pool private pool;
    ListingGateway private lg;
    address public coinSigner;
    address public devWallet;

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );
        cd = CoverData(cg.getLatestAddress("CD"));
        ld = ListingData(cg.getLatestAddress("LD"));
        lg = ListingGateway(cg.getLatestAddress("LG"));
        pool = Pool(cg.getLatestAddress("PL"));
        coinSigner = cg.getLatestAddress("CS");
        devWallet = cg.getLatestAddress("DW");
        infiToken = ERC20Burnable(cg.infiTokenAddr());
    }

    function buyCover(BuyCover calldata _buyCover)
        external
        minimumBalance(msg.sender, 0)
    {
        // Get listing data
        CoverOffer memory offer = ld.getCoverOfferById(_buyCover.offerId);

        // Check if offer still valid
        require(
            block.timestamp <= offer.expiredAt,
            "Cover Gateway: Offer expired"
        );
        require(
            _buyCover.coverMonths >= offer.minCoverMonths,
            "Cover Gateway: Requested Cover month smaller than minimal cover month"
        );

        // Check if offer still be able to take (not biggetrthan offer.insuredSumRemaining)
        require(
            _buyCover.insuredSum <=
                (offer.insuredSum -
                    lg.getInsuredSumTakenOfCoverOffer(_buyCover.offerId)),
            "Cover Gateway: Remaining insured sum is insufficient"
        );

        // verify assetPriceInfo signature
        pool.verifyMessage(_buyCover.assetPricing, coinSigner);

        //  Validate insured sum
        uint256 calculationInsuredSum = ((_buyCover.coverQty *
            _buyCover.assetPricing.coinPrice) / (10**6)); // divide by 10**6 because was times by 10**6 (coinPrice)
        require(
            (_buyCover.insuredSum - calculationInsuredSum) <= 10**18,
            "Cover Gateway: Invalid insured sum"
        );

        // If full uptake
        if (offer.insuredSumRule == InsuredSumRule.FULL) {
            require(
                offer.insuredSum == _buyCover.insuredSum,
                "Cover Gateway: Must take full insured sum"
            );
        }

        // Collect Premium, Premium Currenty will follow CoverOffer.premiumCostPerMonth
        uint256 premiumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(offer.premiumCurrency)
        );
        uint256 totalPremium = (_buyCover.coverQty *
            offer.premiumCostPerMonth *
            _buyCover.coverMonths *
            (10**premiumCurrencyDecimal)) /
            (10**18) / // 18 is cover qty decimal
            (10**premiumCurrencyDecimal);

        pool.acceptAsset(
            msg.sender,
            offer.premiumCurrency,
            totalPremium,
            _buyCover.premiumPermit
        );

        // Transfer Premium to Provider (80%) and Dev (20%)
        uint256 premiumToProvider = (totalPremium * 8) / 10;
        uint256 premiumToDev = totalPremium - premiumToProvider;
        pool.transferAsset(
            offer.funder,
            offer.premiumCurrency,
            premiumToProvider
        ); // send premium to provider
        pool.transferAsset(devWallet, offer.premiumCurrency, premiumToDev); // send premium to devx

        // Deduct remaining insured sum
        uint256 insuredSumTaken = ld.offerIdToInsuredSumTaken(
            _buyCover.offerId
        ) + _buyCover.insuredSum;
        ld.updateOfferInsuredSumTaken(_buyCover.offerId, insuredSumTaken);

        // Stored Data
        uint8 coverMonths = _buyCover.coverMonths;
        InsuranceCover memory coverData;
        coverData.offerId = _buyCover.offerId;
        coverData.requestId = 0;
        coverData.listingType = ListingType.OFFER;
        coverData.holder = _buyCover.buyer;
        coverData.insuredSum = _buyCover.insuredSum;
        coverData.coverQty = _buyCover.coverQty;
        cd.storeCoverByTakeOffer(coverData, coverMonths, offer.funder);
    }

    function provideCover(ProvideCover calldata _provideCover)
        external
        minimumBalance(msg.sender, 0)
    {
        // Get listing data
        CoverRequest memory request = ld.getCoverRequestById(
            _provideCover.requestId
        );

        // Check if request still valid
        require(
            block.timestamp <= request.expiredAt,
            "Cover Gateway: Request expired"
        );

        require(
            !isRequestCoverSucceed(_provideCover.requestId),
            "Cover Gateway : Cover already started"
        );

        // Check if request still be able to take (not bigger than insuredSumRemaining)
        require(
            _provideCover.fundingSum <=
                (request.insuredSum -
                    ld.requestIdToInsuredSumTaken(_provideCover.requestId)),
            "Cover Gateway: Remaining insured sum is insufficient"
        );

        // verify assetPriceInfo signature
        pool.verifyMessage(_provideCover.assetPricing, coinSigner);

        // Collect Collateral
        CurrencyType insuredSumCurrency = request.insuredSumCurrency;
        pool.acceptAsset(
            msg.sender,
            insuredSumCurrency,
            _provideCover.fundingSum,
            _provideCover.assetPermit
        );

        // Deduct remaining insured sum
        uint256 insuredSumTaken = ld.requestIdToInsuredSumTaken(
            _provideCover.requestId
        ) + _provideCover.fundingSum;
        ld.updateRequestInsuredSumTaken(
            _provideCover.requestId,
            insuredSumTaken
        );

        //
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );

        // minimal deposit $1000
        require(
            _provideCover.fundingSum >= (10**insuredSumCurrencyDecimal),
            "Pool : Minimal Deposit $1000"
        );

        // Stored Data
        CoverFunding memory booking;
        booking.requestId = _provideCover.requestId;
        booking.funder = _provideCover.provider;
        booking.fundingSum = _provideCover.fundingSum;
        cd.storeBookingByTakeRequest(booking);

        // Set startAt as 0 to identified as cover not started
        InsuranceCover memory coverData;
        coverData.offerId = 0;
        coverData.requestId = _provideCover.requestId;
        coverData.listingType = ListingType.REQUEST;
        coverData.holder = request.holder;
        coverData.insuredSum = _provideCover.fundingSum;
        coverData.coverQty =
            _provideCover.fundingSum /
            _provideCover.assetPricing.coinPrice;
        cd.storeCoverByTakeRequest(
            coverData,
            request.coverMonths,
            _provideCover.provider
        );

        // either its full or partial funding, as long as its fully funded then start cover
        if (ld.isRequestFullyFunded(_provideCover.requestId)) {
            ld.setCoverRequestFullyFundedAt(
                _provideCover.requestId,
                block.timestamp
            );
        }
    }

    /**
    @dev get actual state of cover request
     */
    function isRequestCoverSucceed(uint256 _requestId)
        public
        view
        returns (bool state)
    {
        CoverRequest memory coverRequest = ld.getCoverRequestById(_requestId);

        if (
            ld.isRequestFullyFunded(_requestId) ||
            (coverRequest.insuredSumRule == InsuredSumRule.PARTIAL &&
                block.timestamp > coverRequest.expiredAt &&
                ld.isRequestReachTarget(_requestId))
        ) {
            state = true;
        } else {
            state = false;
        }
    }

    /**
    @dev calculate startAt for cover
    */
    function getStartAt(uint256 _coverId)
        public
        view
        returns (uint256 startAt)
    {
        InsuranceCover memory cover = cd.getCoverById(_coverId);

        if (cover.listingType == ListingType.REQUEST) {
            CoverRequest memory coverRequest = ld.getCoverRequestById(
                cover.requestId
            );

            if (ld.isRequestFullyFunded(cover.requestId)) {
                startAt = ld.coverRequestFullyFundedAt(cover.requestId);
            } else if (
                coverRequest.insuredSumRule == InsuredSumRule.PARTIAL &&
                block.timestamp > coverRequest.expiredAt &&
                ld.isRequestReachTarget(cover.requestId)
            ) {
                startAt = coverRequest.expiredAt;
            }
        } else if (cover.listingType == ListingType.OFFER) {
            startAt = cd.insuranceCoverStartAt(_coverId);
        }
    }

    /**
    @dev calculate endAt for cover
    */
    function getEndAt(uint256 _coverId) public view returns (uint256 endAt) {
        InsuranceCover memory cover = cd.getCoverById(_coverId);
        uint8 coverMonths;
        if (cover.listingType == ListingType.REQUEST) {
            CoverRequest memory coverRequest = ld.getCoverRequestById(
                cover.requestId
            );
            coverMonths = coverRequest.coverMonths;
        } else if (cover.listingType == ListingType.OFFER) {
            // CoverOffer memory coverOffer = ld.getCoverOfferById(cover.offerId);
            coverMonths = cd.getCoverMonths(_coverId);
        }
        return (getStartAt(_coverId) + (coverMonths * 30 days));
    }

    /**
    @dev for checking is still there any cover active on offer cover
    @return false = there is NO cover active on this offer, true = there is any cover active on this offer
     */
    function isCoverActiveExists(uint256 _offerId)
        external
        view
        returns (bool)
    {
        uint256[] memory coverIds = cd.getCoversByOfferId(_offerId);

        for (uint256 i = 0; i < coverIds.length; i++) {
            if (block.timestamp <= getEndAt(coverIds[i])) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ListingData} from "../Data/ListingData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {Master} from "../Master/Master.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {CoverData} from "../Data/CoverData.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ListingGateway is Master {
    CoverData private cd;
    ListingData private ld;
    ClaimData private claimData;
    CoverGateway private coverGateway;
    Pool private pool;
    address public coinSigner;

    /**
     @dev Tier system for check capability of member
     @param _from member's address
     @param _tokenAmount amount of infi token that transfered
     @param _insuredSum value of asset in USD
     @param _currencyType insuredsum's currency
     */
    modifier verifyMemberLevel(
        address _from,
        uint256 _tokenAmount,
        uint256 _insuredSum,
        CurrencyType _currencyType
    ) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(_currencyType)
        );

        if (_insuredSum <= (10000 * (10**insuredSumCurrencyDecimal))) {
            // Bronze
            require(
                tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
                "Pool: Member balance insufficient"
            );
        } else if (_insuredSum <= (50000 * (10**insuredSumCurrencyDecimal))) {
            // Silver
            require(
                tokenBeforeTransfer >= (10000 * (10**infiTokenDecimal)),
                "Pool: Member balance insufficient"
            );
        } else if (_insuredSum <= (100000 * (10**insuredSumCurrencyDecimal))) {
            // Gold
            require(
                tokenBeforeTransfer >= (25000 * (10**infiTokenDecimal)),
                "Pool: Member balance insufficient"
            );
        } else if (_insuredSum > (100000 * (10**insuredSumCurrencyDecimal))) {
            // Diamond
            require(
                tokenBeforeTransfer >= (50000 * (10**infiTokenDecimal)),
                "Pool: Member balance insufficient"
            );
        }

        _;
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Pool: Caller is not an admin"
        );
        ld = ListingData(cg.getLatestAddress("LD"));
        infiToken = ERC20Burnable(cg.infiTokenAddr());
        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        cd = CoverData(cg.getLatestAddress("CD"));
        pool = Pool(cg.getLatestAddress("PL"));
        coinSigner = cg.getLatestAddress("CS");
        claimData = ClaimData(cg.getLatestAddress("CM"));
    }

    function createCoverRequest(
        address _from,
        uint256 _value,
        bytes memory _payData
    ) public onlyInternal {
        CreateCoverRequestData memory payload = abi.decode(
            _payData,
            (CreateCoverRequestData)
        );

        require(
            payload.request.holder == _from,
            "Pool : holder must be sender"
        );

        require(
            payload.request.coverMonths >= 1 &&
                payload.request.coverMonths <= 12,
            "Pool : Cover period out of bound"
        ); // Validate Cover Period

        // verify expired at
        require(
            payload.request.expiredAt >= block.timestamp &&
                payload.request.expiredAt <= block.timestamp + (14 * 1 days),
            "Pool : expired at is invalid"
        );

        // Set Listing Fee
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(payload.request.insuredSumCurrency)
        );
        uint256 listingFee = pool.getListingFee(
            payload.request.insuredSum,
            insuredSumCurrencyDecimal,
            payload.feePricing.coinPrice
        );

        // Verify listing fee amount
        require(
            listingFee == _value,
            "Listing Gateway : transfered fee insufficient"
        );

        // Transfer 50% of listing fee to dev wallet and burn 50%
        pool.transferAndBurnInfi(listingFee);

        // Verify Coin Info Signature
        pool.verifyMessage(payload.assetPricing, coinSigner); // Validate signature Asset Price
        pool.verifyMessage(payload.feePricing, coinSigner); // Validate signature Fee Price

        // Transfer Premium to smart contract
        pool.acceptAsset(
            _from,
            payload.request.insuredSumCurrency,
            payload.request.premiumSum,
            payload.premiumPermit
        );

        // verify and stored data
        _createRequest(payload, _from, _value);
    }

    function _createRequest(
        CreateCoverRequestData memory _payload,
        address _from,
        uint256 _value
    )
        internal
        verifyMemberLevel(
            _from,
            _value,
            _payload.request.insuredSum,
            _payload.request.insuredSumCurrency
        )
    {
        // Set up value for Request Cover
        if (_payload.request.insuredSumRule == InsuredSumRule.FULL) {
            uint8 decimal = cg.getCurrencyDecimal(
                uint8(_payload.request.insuredSumCurrency)
            );
            uint256 tolerance = 2 * (10**decimal); // tolerance 2 tokens
            _payload.request.insuredSumTarget =
                _payload.request.insuredSum -
                tolerance;
        } else if (_payload.request.insuredSumRule == InsuredSumRule.PARTIAL) {
            _payload.request.insuredSumTarget = _payload.request.insuredSum / 4;
        }
        // Stored data listing
        ld.storedRequest(
            _payload.request,
            _payload.assetPricing,
            _payload.feePricing,
            _from
        );
    }

    function createCoverOffer(
        address _from,
        uint256 _value,
        bytes memory _payData
    ) public onlyInternal {
        CreateCoverOfferData memory payload = abi.decode(
            _payData,
            (CreateCoverOfferData)
        );

        // verify expired at
        require(
            payload.offer.expiredAt >= block.timestamp &&
                payload.offer.expiredAt <= (block.timestamp + (12 * 30 days)),
            "Pool : expired at is invalid"
        );

        // verify funder
        require(payload.offer.funder == _from, "Pool : funder must be sender");

        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(payload.offer.insuredSumCurrency)
        );

        // minimal deposit $1000
        require(
            payload.offer.insuredSum >= (10**insuredSumCurrencyDecimal),
            "Pool : Minimal Deposit $1000"
        );

        // Set Listing Fee
        uint256 listingFee = pool.getListingFee(
            payload.offer.insuredSum,
            insuredSumCurrencyDecimal,
            payload.feePricing.coinPrice
        );

        // Note : verify insured sum worth 1000$

        // Verify listing fee amount
        require(
            listingFee == _value,
            "Listing Gateway : transfered fee insufficient"
        );

        // Transfer 50% of listing fee to dev wallet and burn 50%
        pool.transferAndBurnInfi(listingFee);

        // Verify Coin Info Signature
        pool.verifyMessage(payload.feePricing, coinSigner); // Validate signature Fee Price
        pool.verifyMessage(payload.assetPricing, coinSigner); // Validate signature Asset Price

        // Transfer collateral to current smart contract
        pool.acceptAsset(
            _from,
            payload.offer.insuredSumCurrency,
            payload.offer.insuredSum,
            payload.fundingPermit
        );

        // verify and stored data
        _createOffer(payload, _from, _value);
    }

    function _createOffer(
        CreateCoverOfferData memory _payload,
        address _from,
        uint256 _value
    ) internal minimumBalance(_from, _value) {
        // Stored data listing
        ld.storedOffer(
            _payload.offer,
            _payload.feePricing,
            _payload.assetPricing,
            _payload.depositPeriod,
            _from
        );
    }

    /**
    @dev get list of id of active cover offer
     */
    function getListActiveCoverOffer()
        public
        view
        returns (uint256 listLength, uint256[] memory coverOfferIds)
    {
        // Because "push" is not available in uint256[] memory outside of storage
        // Need to create workaround for push to array
        uint256 coverOfferLength = ld.getCoverOfferLength();
        coverOfferIds = new uint256[](coverOfferLength);
        uint256 iteration = 0;

        for (uint256 i = 0; i < coverOfferLength; i++) {
            CoverOffer memory coverOffer = ld.getCoverOfferById(i);
            if (coverOffer.expiredAt >= block.timestamp) {
                coverOfferIds[iteration] = i;
                iteration = iteration + 1;
            }
        }

        return (iteration, coverOfferIds);
    }

    /**
    @dev get insured sum taken, return value will based on calculation of covers
     */
    function getInsuredSumTakenOfCoverOffer(uint256 _coverOfferId)
        public
        view
        returns (uint256 insuredSumTaken)
    {
        // CoverOffer memory coverOffer = ld.getCoverOfferById(_coverOfferId);
        uint256[] memory listCoverIds = cd.getCoversByOfferId(_coverOfferId);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            if (block.timestamp < coverGateway.getEndAt(listCoverIds[i])) {
                InsuranceCover memory cover = cd.getCoverById(listCoverIds[i]);
                // Cover still active
                insuredSumTaken += cover.insuredSum;
            } else {
                // Cover not active, check the payout for the cover
                insuredSumTaken += claimData.coverToPayout(listCoverIds[i]);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IConfig {
    function infiTokenAddr() external returns (address);

    function getLatestAddress(bytes2 _contractName)
        external
        returns (address payable contractAddress);

    function isInternal(address _add) external returns (bool);

    function getCurrencyDecimal(uint8 _currencyType)
        external
        view
        returns (uint8);

    function getCurrencyName(uint8 _currencyType)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IConfig} from "./IConfig.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Master {
    // Used publicly
    IConfig internal cg;
    ERC20Burnable internal infiToken;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    // Storage and Payload
    enum CoverType {
        SMART_PROTOCOL_FAILURE,
        STABLECOIN_DEVALUATION,
        CUSTODIAN_FAILURE,
        RUGPULL_LIQUIDITY_SCAM
    }
    enum CurrencyType {
        USDT,
        USDC,
        DAI,
        END_ENUM
    }
    enum InsuredSumRule {
        PARTIAL,
        FULL
    }
    enum ListingType {
        REQUEST,
        OFFER
    }

    enum ClaimState {
        MONITORING,
        INVALID,
        VALID,
        INVALID_AFTER_EXPIRED,
        VALID_AFTER_EXPIRED
    }

    mapping(CurrencyType => uint8) internal currencyDecimalsOnFeed; // insuredSumCurrencyDecimalOnCL
    mapping(CurrencyType => uint256) internal currencyPriceOnFeed; // insuredSumCurrencyPriceOnCL
    mapping(string => uint8) internal coinIdToDecimals;

    // For passing parameter and store state variables
    struct CoverRequest {
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint8 coverMonths; // represent month value 1-12
        uint256 insuredSum;
        uint256 insuredSumTarget; // if full funding : insuredSum - 2$
        CurrencyType insuredSumCurrency;
        uint256 premiumSum;
        CurrencyType premiumCurrency;
        uint256 expiredAt; // now + 14 days
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address holder; // may validate or not validate if same as msg.sender
    }

    // Payload : for CoverRequest when Create Request Listing
    // struct CreateCoverRequest {
    //   uint coverQty; // coverQty decimals depends on coinIdToDecimals mapping
    //   uint8 coverMonths; // represent month value 1-12
    //   uint insuredSum;

    //   // Note : can be change to remaining
    //   CurrencyType insuredSumCurrency;
    //   uint premiumSum;
    //   CurrencyType premiumCurrency;
    //   uint8 listingDay; // 7 - 14
    //   string coinId; // CoinGecko
    //   CoverLimit coverLimit;
    //   InsuredSumRule insuredSumRule;
    // }

    // For passing parameter and store state variables
    struct CoverOffer {
        uint8 minCoverMonths; // represent month value 1-12 (expiredAt + 1 month - now >= minCoverMonths)
        uint256 insuredSum;
        CurrencyType insuredSumCurrency;
        uint256 premiumCostPerMonth; // $0.02 per $1 insured per Month (2000) a.k.a Premium Cost Per month per asset
        CurrencyType premiumCurrency;
        // IMPORTANT: max date for buying cover = expiredAt + 1 month
        uint256 expiredAt; // despositEndDate - 14 days beforeDepositEndDate
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address funder; // may validate or not validate if same as msg.sender
    }

    // Payload : for CoverOffer when Create Offer Listing
    // struct CreateCoverOffer {
    //   uint8 depositPeriod;
    //   uint8 minCoverMonths; // represent month value 1-12 (expiredAt + 1 month - now >= minCoverMonths)
    //   uint insuredSum;
    //   CurrencyType insuredSumCurrency;
    //   uint premiumCostPerMonth; // $0.02 per $1 insured per Month (2000) a.k.a Premium Cost Per month per asset
    //   CurrencyType premiumCurrency;
    //   string coinId; // CoinGecko
    //   CoverLimit coverLimit;
    //   InsuredSumRule insuredSumRule;
    // }

    // Storage struct
    // Relationship: CoverCoverOffer ||--< Cover
    // Relationship: CoverRequest ||--< Cover
    // Relationship: One cover can have only one offer
    // Relationship: One cover can have only one request
    struct InsuranceCover {
        // type computed from (offerId != 0) or (requestId != 0)

        // If BuyCover (take offer)
        uint256 offerId; // from BuyCover.offerId
        // If CoverFunding (take request)
        uint256 requestId; // from CoverFunding.requestId
        // uint[] provideIds;

        ListingType listingType;
        // will validate claimSender
        address holder; // from BuyCover.buyer or CoverRequest.buyer
        // will validate maximum claimSum
        uint256 insuredSum; // from BuyCover.insuredSum or sum(CoverFunding.fundingSum)
        // will validate maximum claimQuantity
        uint256 coverQty; // from BuyCover.coverQty or CoverRequest.coverQty
    }

    // Storage: "Booking" object when take request
    // Relationship: CoverRequest ||--< CoverFunding
    struct CoverFunding {
        uint256 requestId;
        address funder;
        // insurance data:
        uint256 fundingSum; // part or portion of total insuredSum
    }

    // Payload: object when take offer
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct BuyCover {
        uint256 offerId;
        address buyer;
        // insurance data:
        uint8 coverMonths; // represent month value 1-12
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint256 insuredSum; // need validation : coverQty * assetPricing.coinPrice
        CoinPricingInfo assetPricing;
        bytes premiumPermit;
        // TODO: validate coverQty based on insuredSum
    }

    // Payload: object when take request
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct ProvideCover {
        uint256 requestId;
        address provider;
        // insurance data:
        uint256 fundingSum;
        CoinPricingInfo assetPricing;
        bytes assetPermit;
    }

    // For passing Coin and Listing Fee info, required for validation
    struct CoinPricingInfo {
        string coinId;
        string coinSymbol;
        uint256 coinPrice; // decimals 6
        uint256 lastUpdatedAt;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CoverLimit {
        CoverType coverType;
        uint256[] territoryIds; // Platform Id, Price Feed Id, Custodian Id , (Dex Pool Id not Yet implemented)
    }

    struct Platform {
        string name;
        string website;
    }

    struct Oracle {
        string name;
        string website;
    }

    struct PriceFeed {
        uint256 oracleId;
        uint256 chainId;
        uint8 decimals;
        address proxyAddress;
    }

    struct Custodian {
        string name;
        string website;
    }

    struct EIP2612Permit {
        address owner;
        uint256 value;
        address spender;
        uint256 deadline;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct DAIPermit {
        address holder;
        address spender;
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    // Parameters
    // struct PayloadParam {
    //   PayloadType payloadType;
    //   bytes payload;
    // }
    // struct EIP1363Data {
    //   bytes32 payType;
    //   bytes payData;
    // }

    struct CreateCoverRequestData {
        CoverRequest request; //
        CoinPricingInfo assetPricing; //
        CoinPricingInfo feePricing; //
        bytes premiumPermit; // for transfer DAI, USDT, USDC
    }

    struct CreateCoverOfferData {
        CoverOffer offer; //
        CoinPricingInfo assetPricing;
        uint8 depositPeriod;
        CoinPricingInfo feePricing; //
        bytes fundingPermit; // for transfer DAI, USDT, USDC
    }

    // Structs
    struct Claim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    struct CollectiveClaim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
        uint256[] claimIds;
    }

    // Modifier
    modifier onlyInternal() {
        require(
            cg.isInternal(msg.sender),
            "Master: Not allow to call this function"
        );
        _;
    }

    /**
    @dev Check balance of member/sender, minimal have 5000 Infi token. Used in Create Offer, Take Offer and Take Request
    @param _from member/sender's address
    @param _tokenAmount amount of token that used for create listing (will be 0 for take offer and take request)
     */
    modifier minimumBalance(address _from, uint256 _tokenAmount) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        require(
            tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
            "Pool: Member balance insufficient"
        );
        _;
    }

    /**
     * @dev change config contract address
     * @param _configAddress is the new address
     */
    function changeConfigAddress(address _configAddress) external {
        // Only admin allowed to call this function
        if (address(cg) != address(0)) {
            require(
                IAccessControl(address(cg)).hasRole(
                    DEFAULT_ADMIN_ROLE,
                    msg.sender
                ),
                "Pool: Caller is not an admin"
            );
        }
        // Change config address
        cg = IConfig(_configAddress);
    }
}