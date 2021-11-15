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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT

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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RangeToken.sol";
import "./AppToken.sol";
import "./SyntheticToken.sol";

/**
 * @title app funding contracts deployer and manager
 * @author Eric Nordelo
 */
contract AppFundingManager is AccessControl, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _appIds;

    uint256 public constant PRECISION = 1000000;
    bytes32 public constant ADMIN = keccak256("admin");

    address public immutable withdrawManagerAddress;
    address public immutable rangeTokenImplementationAddress;
    address public immutable syntheticTokenImplementationAddress;
    address public immutable appTokenImplementationAddress;

    mapping(uint256 => App) private _apps;
    mapping(uint256 => address[]) private _appOwners;

    event CreateApp(
        uint256 id,
        address appTokenAddress,
        address syntheticTokenAddress,
        address rangeTokenAddress
    );

    /**
     * @notice assign the default roles
     * @param _withdrawManagerAddress implementation to clone
     * @param _rangeTokenImplementationAddress implementation to clone
     * @param _syntheticTokenImplementationAddress implementation to clone
     * @param _appTokenImplementationAddress implementation to clone
     */
    constructor(
        address _withdrawManagerAddress,
        address _rangeTokenImplementationAddress,
        address _syntheticTokenImplementationAddress,
        address _appTokenImplementationAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);

        withdrawManagerAddress = _withdrawManagerAddress;
        rangeTokenImplementationAddress = _rangeTokenImplementationAddress;
        syntheticTokenImplementationAddress = _syntheticTokenImplementationAddress;
        appTokenImplementationAddress = _appTokenImplementationAddress;
    }

    /**
     * @notice allows admins to pause the contract
     */
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    /**
     * @notice allows admins to unpause the contract
     */
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    /**
     * @notice deploys tokens for this app funding
     */
    function initializeAppFunding(
        AppFundingData calldata appData,
        string calldata appTokenName,
        string calldata appTokenSymbol,
        string calldata ipfsHashForLogo
    ) external whenNotPaused {
        require(appData.owners.length > 0, "No owners");
        require(appData.t >= block.timestamp, "Invalid unlock date"); // solhint-disable-line

        _appIds.increment();
        uint256 appId = _appIds.current();
        uint256 launchingDate = appData.t;

        // deploys a minimal proxy contract from implementation
        address newRangeToken = Clones.clone(rangeTokenImplementationAddress);
        RangeToken(newRangeToken).initialize("Privi Range Token", "pRT", appData, withdrawManagerAddress);

        address newSyntheticToken = Clones.clone(syntheticTokenImplementationAddress);
        SyntheticToken(newSyntheticToken).initialize(
            "Privi Synthetic Token",
            "pST",
            appData,
            withdrawManagerAddress
        );

        address newAppToken = Clones.clone(appTokenImplementationAddress);
        AppToken(newAppToken).initialize(appTokenName, appTokenSymbol, ipfsHashForLogo, appId, launchingDate);

        _apps[appId] = App({
            fundingTokenAddress: appData.fundingToken,
            appTokenAddress: newAppToken,
            syntheticTokenAddress: newSyntheticToken,
            rangeTokenAddress: newRangeToken
        });

        _appOwners[appId] = appData.owners;

        emit CreateApp(appId, newAppToken, newSyntheticToken, newRangeToken);
    }

    /**
     * @notice getter for the owners of an app
     */
    function getOwnersOf(uint256 _appId) external view returns (address[] memory) {
        require(_apps[_appId].appTokenAddress != address(0), "Unexistent app");
        return _appOwners[_appId];
    }

    /**
     * @param _owner The address of the owner to look for
     * @param _appId The id of the app
     * @return The index and the owners count
     */
    function getOwnerIndexAndOwnersCount(address _owner, uint256 _appId)
        external
        view
        returns (int256, uint256)
    {
        require(_apps[_appId].appTokenAddress != address(0), "Unexistent app");

        uint256 count = _appOwners[_appId].length;
        for (uint256 i = 0; i < count; i++) {
            if (_appOwners[_appId][i] == _owner) {
                return (int256(i), count);
            }
        }
        return (-1, count);
    }

    /**
     * @notice helper for app tokens claims
     */
    function convertTokens(uint256 _appId, address _holder) external returns (uint256) {
        App memory app = getApp(_appId);

        // solhint-disable-next-line
        require(RangeToken(app.rangeTokenAddress).maturityDate() <= block.timestamp, "Invalid date");

        // only the app token contract of the app can call this helper
        require(app.appTokenAddress == msg.sender, "Invalid call");

        uint256 holderSyntheticBalance = SyntheticToken(app.syntheticTokenAddress).balanceOf(_holder);
        (uint256 holderRangeTokenBalance, uint256 payout) = RangeToken(app.rangeTokenAddress)
            .balanceAndPayoutOf(_holder);

        // the payout comes multiplied for the precision
        uint256 holderBalance = holderSyntheticBalance + ((holderRangeTokenBalance * payout) / PRECISION);

        require(holderBalance > 0, "No tokens to claim");

        // make the convertion
        if (holderSyntheticBalance > 0) {
            SyntheticToken(app.syntheticTokenAddress).burn(_holder, holderSyntheticBalance);
        }
        if (holderRangeTokenBalance > 0) {
            RangeToken(app.rangeTokenAddress).burn(_holder, holderRangeTokenBalance);
        }
        AppToken(app.appTokenAddress).mint(_holder, holderBalance);

        return holderBalance;
    }

    /**
     * @notice getter for apps
     * @param _appId the id of the app to get
     */
    function getApp(uint256 _appId) public view returns (App memory) {
        require(_apps[_appId].appTokenAddress != address(0), "Unexistent app");
        return _apps[_appId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./AppFundingManager.sol";

/**
 * @notice implementation of the erc20 token for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract AppToken is ERC20, AccessControl, Initializable {
    string private _proxiedName;
    string private _proxiedSymbol;

    address private _appFundingManagerAddress;

    uint256 public appId;
    uint256 public appTokenLaunchingDate;
    string public logoIPFSHash;

    event ClaimTokens(address indexed holder, uint256 balance);

    // solhint-disable-next-line
    constructor() ERC20("Privi APP Token", "pAT") {}

    /**
     * @notice initializes the minimal proxy clone
     */
    function initialize(
        string calldata proxiedName,
        string calldata proxiedSymbol,
        string calldata _ipfsHashForLogo,
        uint256 _appId,
        uint256 _appTokenLaunchingDate
    ) external initializer {
        _proxiedName = proxiedName;
        _proxiedSymbol = proxiedSymbol;
        appTokenLaunchingDate = _appTokenLaunchingDate;

        logoIPFSHash = _ipfsHashForLogo;
        appId = _appId;

        // de initializer must be the app funding manager contract
        _appFundingManagerAddress = msg.sender;

        // the contract should start paused to avoid claims
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice allows an investor to convert the synthetic and range tokens in app tokens
     */
    function claim() external {
        // solhint-disable-next-line
        require(appTokenLaunchingDate <= block.timestamp, "Launching date not reached yet");
        uint256 balanceAdded = AppFundingManager(_appFundingManagerAddress).convertTokens(appId, msg.sender);
        emit ClaimTokens(msg.sender, balanceAdded);
    }

    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }

    /**
     * @notice allows app funding manager to mint tokens
     */
    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface to allow withdraw to accounts
 * @author Eric Nordelo
 */
interface IWithdrawable {
    /**
     * @dev transfer the amount of selected tokens to address
     */
    function withdrawTo(
        address account,
        uint256 amount,
        address token
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IWithdrawable.sol";
import "./Structs.sol";

/**
 * @notice implementation of the erc20 token for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract RangeToken is ERC20, AccessControl, Initializable, IWithdrawable {
    uint256 public constant PRECISION = 1000000;
    uint256 private constant PRICE_PRECISION = 1000;
    bytes32 public constant WITHDRAW_MANAGER = keccak256("withdraw_manager");

    address private _fundingToken;

    uint256 private _rMin;
    uint256 private _rMax;
    uint256 private _s;
    uint256 private _x;
    uint256 private _y;

    string private _proxiedName;
    string private _proxiedSymbol;

    FundingRoundsData[] private _fundingRoundsData;

    uint256 public maturityDate; // dte of maturity of the options

    // this value should be set by oracles
    uint256 public estimatedPriceAtMaturityDate;

    // solhint-disable-next-line
    constructor() ERC20("Privi Range Token Implementation", "pRTI") {}

    /**
     * @notice initializes the minimal proxy clone
     * @dev ! INSERTING AN ARRAY OF STRUCTS, VERY EXPENSIVE!!!
     * @param _name the name of the token
     * @param _symbol the symbol of the token
     * @param _appData the app data
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        AppFundingData calldata _appData,
        address _withdrawManagerAddress
    ) external initializer {
        _proxiedName = _name;
        _proxiedSymbol = _symbol;

        _fundingToken = _appData.fundingToken;

        // initialize variables
        _s = _appData.s;
        _rMin = _appData.rMin;
        _rMax = _appData.rMax;
        estimatedPriceAtMaturityDate = _appData.rMax;
        _x = _appData.x;
        _y = _appData.y;

        maturityDate = _appData.maturity;

        // TODO: check the interval with the black scholes function

        require(_appData.fundingRangeRoundsData.length > 0, "Invalid rounds count");
        for (uint256 i; i < _appData.fundingRangeRoundsData.length - 1; i++) {
            require(_appData.fundingRangeRoundsData[i].mintedTokens == 0, "Invalid data");
            require(
                _appData.fundingRangeRoundsData[i + 1].tokenPrice >=
                    _appData.fundingRangeRoundsData[i].tokenPrice,
                "Invalid distribution"
            );
            _fundingRoundsData.push(_appData.fundingRangeRoundsData[i]);
        }
        require(
            _appData.fundingRangeRoundsData[_appData.fundingRangeRoundsData.length - 1].mintedTokens == 0,
            "Invalid data"
        );
        _fundingRoundsData.push(_appData.fundingRangeRoundsData[_appData.fundingRangeRoundsData.length - 1]);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAW_MANAGER, _withdrawManagerAddress);
    }

    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }

    /**
     * @notice allows app funding manager to burn tokens
     */
    function burn(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(to, amount);
    }

    /**
     * @notice transfer the amount of selected tokens to address
     */
    function withdrawTo(
        address account,
        uint256 amount,
        address token
    ) external override onlyRole(WITHDRAW_MANAGER) returns (bool) {
        uint256 balance = ERC20(token).balanceOf(address(this));
        require(balance >= amount, "Insuficient funds");
        return (ERC20(token).transfer(account, amount));
    }

    /**
     * @notice returns the estimated payout at the time
     * @dev the actual value should be divided by precision
     */
    function currentEstimatedPayout() public view returns (uint256) {
        if (estimatedPriceAtMaturityDate < _rMin) {
            return (_s * PRECISION) / _rMin;
        } else if (estimatedPriceAtMaturityDate > _rMax) {
            return (_s * PRECISION) / _rMax;
        } else {
            return (_s * PRECISION) / estimatedPriceAtMaturityDate;
        }
    }

    /**
     * @notice returns the balance and the payout at the time
     */
    function balanceAndPayoutOf(address _holder) external view returns (uint256 balance, uint256 payout) {
        balance = balanceOf(_holder);
        payout = currentEstimatedPayout();
    }

    /**
     * @notice get current price of the tokens
     * @dev the return value should be divided by PRICE_PRECISION
     */
    function getTokenPrice() external view returns (uint256) {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        // the index is the id minus 1
        return _fundingRoundsData[_roundId - 1].tokenPrice;
    }

    /**
     * @notice returns the index of the active round or zero if there is none
     */
    function getRoundNumber() public view returns (uint256) {
        // solhint-disable-next-line
        uint256 currentTime = block.timestamp;
        if (
            currentTime < _fundingRoundsData[0].openingTime ||
            currentTime >
            _fundingRoundsData[_fundingRoundsData.length - 1].openingTime +
                _fundingRoundsData[_fundingRoundsData.length - 1].durationTime *
                1 days
        ) {
            return 0;
        }
        for (uint256 i; i < _fundingRoundsData.length; i++) {
            if (
                currentTime >= _fundingRoundsData[i].openingTime &&
                currentTime < _fundingRoundsData[i].openingTime + _fundingRoundsData[i].durationTime * 1 days
            ) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * @dev allow to investors buy range tokens specifiying the amount of range tokens
     * @param _amount allow to the investors that buy range token specifying the amount
     */
    function buyTokensByAmountToGet(uint256 _amount) external {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;
        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokenToBeSold,
            "All tokens sold"
        );
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokenToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );

        uint256 _amountToPay = (_amount * _fundingRoundsData[_roundIndex].tokenPrice) / PRICE_PRECISION;

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(_fundingToken).transferFrom(msg.sender, address(this), _amountToPay);
        // solhint-disable-next-line
        require(result);
    }

    /**
     * @dev allow to investors buy range tokens specifiying the amount of pay tokens
     * @param _amountToPay allow to the investors that buy range token specifying the amount of pay token
     */
    function buyTokensByAmountToPay(uint256 _amountToPay) external {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;
        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokenToBeSold,
            "All tokens sold"
        );
        uint256 _amount = (_amountToPay * PRICE_PRECISION) / _fundingRoundsData[_roundIndex].tokenPrice;
        require(_amount > 0, "Insuficient amount to pay");
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokenToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(_fundingToken).transferFrom(msg.sender, address(this), _amountToPay);
        // solhint-disable-next-line
        require(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct App {
    address fundingTokenAddress;
    address appTokenAddress;
    address syntheticTokenAddress;
    address rangeTokenAddress;
}

struct AppFundingData {
    address fundingToken;
    uint256 s;
    uint256 rMin;
    uint256 rMax;
    uint256 x;
    uint256 y;
    uint256 t;
    uint256 maturity;
    address[] owners;
    FundingRoundsData[] fundingRangeRoundsData;
    FundingRoundsData[] fundingSyntheticRoundsData;
}

struct FundingRoundsData {
    uint64 openingTime;
    uint64 durationTime;
    uint128 tokenPrice;
    uint256 capTokenToBeSold;
    uint256 mintedTokens;
}

struct WithdrawProposal {
    uint128 positiveVotesCount;
    uint128 negativeVotesCount;
    address recipient;
    uint64 minApprovals;
    uint64 maxDenials;
    uint64 date;
    uint64 duration;
    uint256 amount;
    uint256 appId;
    bool fromRangeTokenContract;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IWithdrawable.sol";
import "./Structs.sol";

/**
 * @notice implementation of the erc20 token for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract SyntheticToken is ERC20, AccessControl, Initializable, IWithdrawable {
    uint256 public constant PRECISION = 1000000;
    uint256 private constant PRICE_PRECISION = 1000;
    bytes32 public constant WITHDRAW_MANAGER = keccak256("withdraw_manager");

    string private _proxiedName;
    string private _proxiedSymbol;

    FundingRoundsData[] private _fundingRoundsData;

    address public fundingToken;

    // solhint-disable-next-line
    constructor() ERC20("Privi Synthetic Token", "pST") {}

    /**
     * @notice initializes minimal proxy clone
     */
    function initialize(
        string calldata proxiedName,
        string calldata proxiedSymbol,
        AppFundingData calldata _appData,
        address _withdrawManagerAddress
    ) external initializer {
        _proxiedName = proxiedName;
        _proxiedSymbol = proxiedSymbol;
        fundingToken = _appData.fundingToken;

        require(_appData.fundingSyntheticRoundsData.length > 0, "Invalid rounds count");
        for (uint256 i; i < _appData.fundingSyntheticRoundsData.length; i++) {
            require(_appData.fundingSyntheticRoundsData[i].mintedTokens == 0, "Invalid data");
            require(_appData.fundingSyntheticRoundsData[i].tokenPrice < _appData.s, "Invalid distribution");
            _fundingRoundsData.push(_appData.fundingSyntheticRoundsData[i]);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAW_MANAGER, _withdrawManagerAddress);
    }

    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }

    function getRoundNumber() public view returns (uint256) {
        // solhint-disable-next-line
        uint256 currentTime = block.timestamp;
        if (
            currentTime < _fundingRoundsData[0].openingTime ||
            currentTime >
            _fundingRoundsData[_fundingRoundsData.length - 1].openingTime +
                _fundingRoundsData[_fundingRoundsData.length - 1].durationTime *
                1 days
        ) {
            return 0;
        }
        for (uint256 i; i < _fundingRoundsData.length; i++) {
            if (
                currentTime >= _fundingRoundsData[i].openingTime &&
                currentTime < _fundingRoundsData[i].openingTime + _fundingRoundsData[i].durationTime * 1 days
            ) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * @notice transfer the amount of selected tokens to address
     */
    function withdrawTo(
        address account,
        uint256 amount,
        address token
    ) external override onlyRole(WITHDRAW_MANAGER) returns (bool) {
        uint256 balance = ERC20(token).balanceOf(address(this));
        require(balance >= amount, "Insuficient funds");
        return (ERC20(token).transfer(account, amount));
    }

    /**
     * @notice allows app funding manager to burn tokens
     */
    function burn(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(to, amount);
    }

    /**
     * @notice get current price of the tokens
     * @dev this return value should be divided by PRICE_PRECISION
     */
    function getTokenPrice() external view returns (uint256) {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        // the index is the id minus 1
        return _fundingRoundsData[_roundId - 1].tokenPrice;
    }

    /**
     * @notice allows investors to buy synthetic tokens specifiying the amount to get
     * @param _amount the amount to get
     */
    function buyTokensByAmountToGet(uint256 _amount) external {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;

        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokenToBeSold,
            "All tokens sold"
        );
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokenToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );
        require(_amount > 0, "Invalid amount");

        uint256 _amountToPay = (_amount * _fundingRoundsData[_roundIndex].tokenPrice) / PRICE_PRECISION;

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(fundingToken).transferFrom(msg.sender, address(this), _amountToPay);
        // solhint-disable-next-line
        require(result);
    }

    /**
     * @notice allows investors to buy synthetic tokens specifiying the amount to pay
     * @param _amountToPay the amount to pay
     */
    function buyTokensByAmountToPay(uint256 _amountToPay) external {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;

        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokenToBeSold,
            "All tokens sold"
        );
        uint256 _amount = (_amountToPay * PRICE_PRECISION) / _fundingRoundsData[_roundIndex].tokenPrice;
        require(_amount > 0, "Insuficient amount");
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokenToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(fundingToken).transferFrom(msg.sender, address(this), _amountToPay);
        // solhint-disable-next-line
        require(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./AppFundingManager.sol";
import "./IWithdrawable.sol";
import "./Structs.sol";

/**
 * @title manager for withdrawals
 * @author Eric Nordelo
 * @notice manages the withdrawals proposals and the multisig logic
 */
contract WithdrawManager is AccessControl, Initializable {
    using Counters for Counters.Counter;

    Counters.Counter private _withdrawProposalIds;

    uint64 private constant PROPOSAL_DURATION = 1 weeks;

    address public appFundingManagerAddress;

    // map from Id to WithdrawProposal
    mapping(uint256 => WithdrawProposal) private _withdrawProposals;
    // stores a mapping of owners and if already voted by proposalId
    mapping(uint256 => mapping(address => bool)) private _withdrawProposalsVoted;

    event DirectWithdraw(uint256 indexed tokenFundingId, address indexed recipient, uint256 amount);
    event CreateWithdrawProposal(
        uint256 indexed appId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );
    event ApproveWithdrawProposal(
        uint256 indexed appId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );
    event DenyWithdrawProposal(
        uint256 indexed appId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );
    event VoteWithdrawProposal(address indexed voter, uint256 indexed appId, uint256 indexed proposalId);
    event ExpireWithdrawProposal(
        uint256 indexed appId,
        address indexed recipient,
        uint256 amount,
        uint256 indexed proposalId
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice sets the addresses to support integration
     * @param _appFundingManagerAddress the address of the Privi NFT contract
     */
    function initialize(address _appFundingManagerAddress) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        appFundingManagerAddress = _appFundingManagerAddress;
    }

    /**
     * @notice direct withdraw when there is only one owner
     * @param _recipient the recipient of the transfer
     * @param _appId the token funding id
     * @param _amount the amount of the app tokens to withdraw
     * @param _fromRangeTokenContract selects which contract should be extracted from
     */
    function withdrawTo(
        address _recipient,
        uint256 _appId,
        uint256 _amount,
        bool _fromRangeTokenContract
    ) external {
        (int256 index, uint256 ownersCount) = AppFundingManager(appFundingManagerAddress)
            .getOwnerIndexAndOwnersCount(msg.sender, _appId);

        require(index >= 0, "Invalid requester");
        require(ownersCount == 1, "Multiple owners, voting is needed");

        App memory app = AppFundingManager(appFundingManagerAddress).getApp(_appId);

        // make the transfer
        address contractAddress = _fromRangeTokenContract ? app.rangeTokenAddress : app.syntheticTokenAddress;

        require(
            IWithdrawable(contractAddress).withdrawTo(_recipient, _amount, app.fundingTokenAddress),
            "Error at transfer"
        );

        emit DirectWithdraw(_appId, _recipient, _amount);
    }

    /**
     * @notice create a proposal for withdraw funds
     * @param _recipient the recipient of the transfer
     * @param _appId the app id
     * @param _amount the amount of the funding token to withdraw
     */
    function createWithdrawProposal(
        address _recipient,
        uint256 _appId,
        uint256 _amount,
        bool _fromRangeTokenContract
    ) external {
        _withdrawProposalIds.increment();

        uint256 proposalId = _withdrawProposalIds.current();

        (int256 index, uint256 ownersCount) = AppFundingManager(appFundingManagerAddress)
            .getOwnerIndexAndOwnersCount(msg.sender, _appId);
        require(index >= 0, "Invalid requester");
        require(ownersCount > 1, "Only one owner, voting is not needed");

        WithdrawProposal memory _withdrawProposal = WithdrawProposal({
            minApprovals: uint64(ownersCount),
            maxDenials: 1,
            positiveVotesCount: 0,
            negativeVotesCount: 0,
            appId: _appId,
            recipient: _recipient,
            amount: _amount,
            date: uint64(block.timestamp), // solhint-disable-line
            duration: PROPOSAL_DURATION,
            fromRangeTokenContract: _fromRangeTokenContract
        });

        // save the proposal for voting
        _withdrawProposals[proposalId] = _withdrawProposal;

        emit CreateWithdrawProposal(_appId, _recipient, _amount, proposalId);
    }

    /**
     * @notice allows owners to vote withdraw proposals for pods
     * @param _proposalId the id of the withdraw proposal
     * @param _vote the actual vote: true or false
     */
    function voteWithdrawProposal(uint256 _proposalId, bool _vote) external {
        require(_withdrawProposals[_proposalId].minApprovals != 0, "Unexistent proposal");

        WithdrawProposal memory withdrawProposal = _withdrawProposals[_proposalId];

        (int256 index, ) = AppFundingManager(appFundingManagerAddress).getOwnerIndexAndOwnersCount(
            msg.sender,
            withdrawProposal.appId
        );

        require(index >= 0, "Invalid owner");

        require(!_withdrawProposalsVoted[_proposalId][msg.sender], "Owner already voted");

        _withdrawProposalsVoted[_proposalId][msg.sender] = true;

        // check if expired
        // solhint-disable-next-line
        if (withdrawProposal.date + withdrawProposal.duration < block.timestamp) {
            // delete the recover gas
            delete _withdrawProposals[_proposalId];
            emit ExpireWithdrawProposal(
                withdrawProposal.appId,
                withdrawProposal.recipient,
                withdrawProposal.amount,
                _proposalId
            );
        } else {
            // if the vote is positive
            if (_vote) {
                // if is the last vote to approve
                if (withdrawProposal.positiveVotesCount + 1 == withdrawProposal.minApprovals) {
                    delete _withdrawProposals[_proposalId];

                    App memory app = AppFundingManager(appFundingManagerAddress).getApp(
                        withdrawProposal.appId
                    );

                    // make the transfer
                    address contractAddress = withdrawProposal.fromRangeTokenContract
                        ? app.rangeTokenAddress
                        : app.syntheticTokenAddress;

                    require(
                        IWithdrawable(contractAddress).withdrawTo(
                            withdrawProposal.recipient,
                            withdrawProposal.amount,
                            app.fundingTokenAddress
                        ),
                        "Error at transfer"
                    );

                    emit ApproveWithdrawProposal(
                        withdrawProposal.appId,
                        withdrawProposal.recipient,
                        withdrawProposal.amount,
                        _proposalId
                    );
                } else {
                    // update the proposal and emit the event
                    _withdrawProposals[_proposalId].positiveVotesCount++;
                    emit VoteWithdrawProposal(msg.sender, withdrawProposal.appId, _proposalId);
                }
            }
            // if the vote is negative
            else {
                // if is the last vote to deny
                if (withdrawProposal.negativeVotesCount + 1 == withdrawProposal.maxDenials) {
                    // delete the proposal and emit the event
                    delete _withdrawProposals[_proposalId];
                    emit DenyWithdrawProposal(
                        withdrawProposal.appId,
                        withdrawProposal.recipient,
                        withdrawProposal.amount,
                        _proposalId
                    );
                } else {
                    // update the proposal and emit the event
                    _withdrawProposals[_proposalId].negativeVotesCount++;
                    emit VoteWithdrawProposal(msg.sender, withdrawProposal.appId, _proposalId);
                }
            }
        }
    }

    /**
     * @notice proposal struct getter
     * @param _proposalId The id of the withdraw proposal
     * @return the WithdrawProposal object
     */
    function getUpdateMediaProposal(uint256 _proposalId) external view returns (WithdrawProposal memory) {
        WithdrawProposal memory withdrawProposal = _withdrawProposals[_proposalId];
        require(withdrawProposal.minApprovals != 0, "Unexistent proposal");
        return withdrawProposal;
    }
}

