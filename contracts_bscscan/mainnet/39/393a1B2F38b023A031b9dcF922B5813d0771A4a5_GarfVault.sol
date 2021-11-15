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

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    constructor () {
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

    constructor () {
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
    function _transferWithoutBefore(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
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

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "./vault/GarfVaultStaking.sol";


contract GarfVault is GarfVaultStaking{
    using SafeMath for uint256;

    mapping (address=>address) public chainUp;
    mapping (address=>address[]) public chainDown;
    mapping (address=>uint256) public chainFollowsCount;
    mapping (address=>uint256) public chainReward;
    mapping (address=>uint256) public chainRewardClaimed;

    uint256 public totalRewardChainUp;
    uint256 public chainLookupDepth = 2;
    uint256 public constant NONCE=314*10**4;
    uint256[] public totalRewardChainUpHistory;

    constructor(address token_,address fomo_) GarfVaultBase(token_){
        fomoAddress = fomo_;
    }

    function resetTotalRewardChainUp() public onlyOwner{
        if (totalRewardChainUp>0){
            totalRewardChainUpHistory.push(totalRewardChainUp);
            totalRewardChainUp = 0;
        }
    }
    function getTotalChainUpReward()public view returns(uint256){
        uint256 total = totalRewardChainUp;
        for (uint256 ii=0;ii<totalRewardChainUpHistory.length;ii++){
            total+= totalRewardChainUpHistory[ii];
        }
        return total;
    }
    function getChainUpRewardHistoryLen()public view returns(uint256){
        return totalRewardChainUpHistory.length;
    }
    function setWithdrawCountDown(uint256 clamdown_) public onlyOwner{
        withdrawCountDown = clamdown_;
    }
    function ownerSetSettings(address token_,uint256 chainDepth_,uint256 placeHolder,address fomoAddress_) public onlyOwner{
        
    }
    function ownerSetVaultBasic(address token_,uint256 chainDepth_,address fomoAddress_) public onlyOwner{
        garfToken = IERC20(token_);
        chainLookupDepth = chainDepth_;
        fomoAddress = fomoAddress_;
    }
    
    function viewChainSplitWithTotal(address account,uint256 totalAmount)override public view returns(address[] memory,uint256[] memory){
        address up;
        uint256 consumed = 0;

        address addr = account;
        uint256 split = EXPAND_BASE;
        {
            for(uint256 depth = 0;depth<chainLookupDepth;depth++){
                up = chainUp[addr];
                if ( up==address(0) || up==addr) {
                    break;
                }
                consumed = consumed.add(split);
                addr = up;
                split = split.div(2);
            }
        }
        addr = account;
        split = EXPAND_BASE;
        address[] memory rtAddrs = new address[](chainLookupDepth);
        uint256[] memory rtAmounts = new uint256[](chainLookupDepth);

        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            uint256 amount = totalAmount.mul(split).div(consumed);
            rtAddrs[depth] = up;
            rtAmounts[depth] = amount;

            addr = up;
            split = split.div(2);
        }
        return (rtAddrs,rtAmounts);
    }

    function viewChainSplitWithInit(address account,uint256 initAmount)override public view returns(address[] memory,uint256[] memory,uint256){
        address addr = account;

        uint256 consumed = 0;
        uint256 split = initAmount;
        address up;
        address[] memory rtAddrs = new address[](chainLookupDepth);
        uint256[] memory rtAmounts = new uint256[](chainLookupDepth);

        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            rtAddrs[depth] = up;
            rtAmounts[depth] = split;
            consumed = consumed.add(split);
            
            addr = up;
            split = split.div(2);
        }
        return (rtAddrs,rtAmounts,consumed);
    }

    function viewChainSplitSum(address from,uint256 amount)public view returns(uint256){
        address addr = from;
        uint256 point = poolInfo[0].allocPoint;
        
        uint256 consumed = 0;
        uint256 split = amount.mul(point).div(totalAllocPoint);
        address up;
        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            consumed = consumed.add(split);
            addr = up;
            split = split.div(2);
        }
        return consumed;
    }

    /**
     * SELL FEE DISTRIBUTIONS
     *
     * Of the 3.0% reserved for REFERRAL REWARDS when a seller has a referrer,
     * 
     * 2.0% is distributed to its direct referrer, and 1.0% is distributed to its indirect referrer. This
     * is done by having split to have a value of 2% when a seller has a referrer. The remaining 1% goes to
     * the indirect referrer.
     *
     * Referral level is capped at 2. This is done by setting chainLookupDepth to 2.
     *
     * This function will return a "consumed" value of 0 when a seller has no referrer, such that no amount
     * of the sell fee is reserved as referral rewards.
     */
    function __chainSplitUpdate(address from,uint256 reward) internal returns(uint256){
        address addr = from;
        uint256 point = poolInfo[0].allocPoint;
        
        uint256 consumed = 0;
        uint256 split = reward.mul(point).div(totalAllocPoint);
        address up;
        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            chainReward[up] = chainReward[up].add(split);
            consumed = consumed.add(split);
            
            addr = up;
            split = split.div(2);
        }
        if (consumed>0){
            totalRewardChainUp = totalRewardChainUp.add(consumed);
        }
        return consumed;
    }

    /**
     * SELL FEE DISTRIBUTIONS
     *
     * As a core feature, OTO uses fees collected from sellers to incentivize HODLers who stake
     * to show long-term commitment and to reward referrers.
     *
     * A total of 4.5% of any sell amount is reserved for distribution here. (0.5% previously
     * reserved for CUMULATIVE LIQUIDITY, for a total of 5.0%)
     * 
     */
    function noticeRewardWithFrom(address from,uint256 reward)override external onlyGarf{
        //////////////
        // __chainSplitUpdate directs 3.0% of SELL FEE as either REFERRAL or STAKING REWARDS
        // See code there for details. 
        //////////////
        uint256 remain = __chainSplitUpdate(from,reward);
        //////////////
        // 1.5% reserved as STAKING REWARDS 
        //////////////
        remain = reward.sub(remain);

        uint256 nextStart = getNextSpanStart();
        uint256 accumulated = spanRewardInfo[nextStart].accReward;
        if (accumulated ==0){
            spanRewardInfo[nextStart].startBlock = nextStart;
            spanRewardInfo[nextStart].endBlock = nextStart.add(nextSpanBlock);
            startBlockList.push(nextStart);
        }
        
        uint256 amount = chainReward[address(this)];
        if (amount>0){
            spanRewardInfo[nextStart].accReward = accumulated.add(amount).add(remain);
            chainReward[address(this)] = 0;
        }else{
            spanRewardInfo[nextStart].accReward = accumulated.add(remain);
        }

    }
    function noticeRewardWithTo(address to,uint256 initReward)override external onlyGarf returns(uint256){
        address addr = to;

        uint256 consumed = 0;
        uint256 split = initReward;
        address up;
        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            chainReward[up] = chainReward[up].add(split);
            consumed = consumed.add(split);
            
            addr = up;
            split = split.div(2);
        }
        totalRewardChainUp = totalRewardChainUp.add(consumed);
        return consumed;
    }

    /**
     * BUY FEE DISTRIBUTIONS WITH REFERRER
     *
     * When a buyer has a referrer, 0.3% is the effective buy fee. Of the 0.3%, 0.2% is directed
     * to the direct referrer. This is done by having fullReward.mul(split).div(consumed) to return 2/3
     * of the value of fullReward. The remaining 0.1% is directed to the indirect referrer.
     *
     * Referral level is capped at 2. This is done by setting chainLookupDepth to 2.
     * 
     */
    function noticeFullRewardWithTo(address to,uint256 fullReward)override external onlyGarf{
        address up;
        uint256 consumed = 0;

        address addr = to;
        uint256 split = EXPAND_BASE;
        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            consumed = consumed.add(split);
            addr = up;
            split = split.div(2);
        }

        addr = to;
        split = EXPAND_BASE;
        for(uint256 depth = 0;depth<chainLookupDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                break;
            }
            uint256 amount = fullReward.mul(split).div(consumed);
            chainReward[up] = chainReward[up].add(amount);
            addr = up;
            split = split.div(2);
        }
        totalRewardChainUp = totalRewardChainUp.add(fullReward);
    }


    function claimReward(address account,uint256 _pid) public returns(uint256){
        require(account!=address(this),"recursive claim");
        if (_pid==0){
            uint256 amount = chainReward[account];
            if (amount>0){
                chainReward[account] = 0;
                chainRewardClaimed[account] = chainRewardClaimed[account].add(amount);
                safeRewardTransfer(account,amount,_pid);
            }
            return amount;
        }
        return __deposit(account, _pid, 0,false);
    }
    function claimMasterChainUpToStaking()public returns(uint256) {
        uint256 amount = chainReward[address(this)];
        if (amount>0){
            uint256 nextStart = getNextSpanStart();
            uint256 accumulated = spanRewardInfo[nextStart].accReward;
            if (accumulated ==0){
                spanRewardInfo[nextStart].startBlock = nextStart;
                spanRewardInfo[nextStart].endBlock = nextStart.add(nextSpanBlock);
                startBlockList.push(nextStart);
            }
            spanRewardInfo[nextStart].accReward = accumulated.add(amount);
            chainReward[address(this)] = 0;
        }
        return amount;
    }
    function pendingReward(uint256 _pid, address _user)override public view returns (uint256) {
        if (_pid==0){
            return chainReward[_user];
        }
        return super.pendingReward(_pid,_user);
    }
    function claimRewardAll(address account) public{
        for (uint256 ii=0;ii<poolInfo.length;ii++){
            claimReward(account, ii);
        }
    }


    function getFollowerLevel(address main,address account) public view returns(uint256){
        return getFollowerLevelWithMax(main,account,chainLookupDepth);
    }
    function getFollowerLevelWithMax(address main,address account,uint256 maxDepth) public view returns(uint256){
        address addr = account;
        address up;
        uint256 depth;
        for(depth = 0;depth<maxDepth;depth++){
            up = chainUp[addr];
            if ( up==address(0) || up==addr) {
                return 0;
            }
            if (up==main){
                return depth+1;
            }
            addr = up;
        }
        return 0;
    }
    function getAccountFollowersLen(address account)public view returns(uint256){
        return chainDown[account].length;
    }
    function getAccountFollowers(address account)public view returns(address[] memory){
        return chainDown[account];
    }
    function getAccountChainUp(address account)override public view returns(address){
        return chainUp[account];
    }
    function updateChainUp(address account,address up) override public onlyGarf returns(address) {
        address ori = chainUp[account];
        if (ori == address(0)){
            chainUp[account] = up;
            chainDown[up].push(account);
            chainFollowsCount[up] =chainFollowsCount[up]+1;
            return up;
        }
        return ori;
    }
    function resetChainUp(address account)override public onlyGarf {
        address ori = chainUp[account];
        if (ori!=address(0)){
            chainFollowsCount[ori] =chainFollowsCount[ori].sub(1);
        }
        chainUp[account] = address(0);
    }

}

// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../../3rdParty/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../../3rdParty/@openzeppelin/contracts/access/Ownable.sol";
import "../../3rdParty/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IGarfVault.sol";
import "../../3rdParty/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../3rdParty/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../3rdParty/@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract GarfVaultBase is IGarfVault,ERC20PresetMinterPauser,Ownable,ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public garfToken;
    address public fomoAddress;
    address public swapAddress;

    address public constant EMPTY_ADDRESS = address(0);
    uint256 public constant DEFAULT_CHAIN_POINT = 40;
    uint256 public constant DEFAULT_GARF_STAKING_POINT = 50;
    
    struct StakingInfo{
        uint256 amount;
        uint256 rewardDebt;
    }
    struct PoolInfo{
        IERC20  token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 alreadyMined;
        uint256 totalDepositAmount;
        uint256 alreadyClaimed;
    }
    address[] public garfList;
    mapping (address => uint256) private garfListMap;

    uint256 public totalAllocPoint;
    uint256 public normalPoolTotalPoint;
    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => StakingInfo)) public stakingInfo;

    struct RewardInfo{
        //[startBlock,endBlock)
        uint256 startBlock;
        uint256 endBlock;
        uint256 accReward;
        uint256 claimed;
    }
    mapping(uint256 => RewardInfo) public spanRewardInfo;
     //[start0,end0),[end0,end1),[end1,end2)...
    uint256[] public startBlockList;
    uint256 public nextSpanBlock = 28800;
    uint256 public constant EXPAND_BASE = 1e27;
    uint256 public alreadyMinedReward;
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    constructor(address token_) ERC20PresetMinterPauser("OTO STAKING REWARD", "OTO Reward Token") Ownable() {
       garfToken = IERC20(token_);
       _add(DEFAULT_CHAIN_POINT,EMPTY_ADDRESS,false); // Used for Referral Relationship
       _add(DEFAULT_GARF_STAKING_POINT,address(garfToken),false); // Used for Staking Rewards
       startBlock = block.number;
    }

    modifier onlyGarf{
        address sender = _msgSender();
        require(
            sender == address(garfToken) ||
            sender == fomoAddress ||
            sender == swapAddress ||
            garfListMap[sender]>0,
            "only garf can call"
        );
        _;
    }
    function viewGarfList()public view returns(address[] memory){
        return garfList;
    }
    function ownerAddGarfList(address white)public onlyOwner{
        _addAddressToListMap(white,garfListMap,garfList);
    }
    function ownerDelGarfList(address white)public onlyOwner{
        _delAddressFromListMap(white,garfListMap,garfList);
    }
    function _addAddressToListMap(address addr_,mapping(address=>uint256) storage map_,address[] storage list_) internal {
        if (map_[addr_]==0){
            list_.push(addr_);
            map_[addr_] = list_.length;
        }
    }
    function _delAddressFromListMap(address addr_,mapping(address=>uint256) storage map_,address[] storage list_) internal{
        uint256 len = map_[addr_];
        if (len > 0){
            uint256 index = len-1;
            if (len<list_.length){
                address last = list_[list_.length-1];
                list_[index] = last;
                map_[last] = len;
            }
            list_.pop();
            map_[addr_] = 0;
        }
    }

    function ownerSetAddress(address fomoAddress_,address swapAddress_) public onlyOwner{
        fomoAddress = fomoAddress_;
        swapAddress = swapAddress_;
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
        return 9;
    }
    /**
     * @dev Returns the bep token owner. conforms to IBEP20
     */
    function getOwner() external view returns (address){
        return owner();
    }
    function setGarfSwapAddress(address swap_) public onlyOwner{
        swapAddress = swap_;
    }
    function setStartBlock(uint256 startBlock_) external onlyOwner{
        startBlock = startBlock_;
    }
    function getCurrentSpanStart() public view returns (uint256){
        if (startBlockList.length>0){
            uint256 index = startBlockList.length;
            RewardInfo  memory info;
            do{ 
                index--;
                uint256 lastStart = startBlockList[index];
                info = spanRewardInfo[lastStart];
            }while(info.startBlock>block.number && index>0);
            if (info.startBlock<=block.number){
                return info.startBlock;
            }
        }
        return startBlock;
    }

    /**
     * STAKING REWARDS DISTRIBUTIONS
     *
     * OTO Staking Rewards are re-distributed with a staggered schedule. First, staking rewards 
     * and incubation profits are gathered for a span of 28,800 BSC blocks (about 24 hours). 
     * This is done by setting nextSpanBlock to 28,800.
     *
     * This gathered pool of rewards will then be evenly distributed out as staking rewards over the
     * next 28,800 blocks.
     */
    function getNextSpanStart()public view returns(uint256){
        if (startBlockList.length>0){
            uint256 lastStart = startBlockList[startBlockList.length-1];
            RewardInfo  memory info = spanRewardInfo[lastStart];
            if (info.startBlock>block.number){
                return info.startBlock;
            }
            if (info.endBlock > block.number){
                return info.endBlock;
            }else{
                return block.number.add(nextSpanBlock);
            }
            
        }
        return startBlock.add(nextSpanBlock);
    }
    function getStartBlockListLen() public view returns(uint256){
        return startBlockList.length;
    }
    function viewStartBlockList()public view returns(uint256[] memory){
        return startBlockList;
    }
    function changeNextSpanBlock(uint256 blockSpan_)public onlyOwner{
        require(blockSpan_>0);
        massUpdatePools();
        nextSpanBlock = blockSpan_;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function viewPoolInfo()public view returns(PoolInfo[] memory){
        return poolInfo;
    }
    function add(uint256 _allocPoint, address token_, bool _withUpdate) public onlyOwner {
        _add( _allocPoint,  token_,  _withUpdate);
    }
    function _add(uint256 _allocPoint, address token_, bool _withUpdate) internal {
        if(_withUpdate){
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        if (poolInfo.length>0){
            normalPoolTotalPoint = normalPoolTotalPoint.add(_allocPoint);
        }
        poolInfo.push(PoolInfo({
            token:IERC20(token_),
            allocPoint:_allocPoint,
            lastRewardBlock:lastRewardBlock,
            accRewardPerShare:0,
            alreadyMined:0,
            totalDepositAmount:0,
            alreadyClaimed:0
        }));
    }
    function massUpdatePoints(uint256[] memory pids,uint256[] memory ponits)public onlyOwner{
        uint256 len = pids.length;
        for (uint256 ii=0;ii<len;ii++){
            _set(pids[ii],ponits[ii],false);
        }
    }
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        _set(_pid,_allocPoint,_withUpdate);
    }
    function _set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            if (_pid!=0){
                normalPoolTotalPoint = normalPoolTotalPoint.sub(prevAllocPoint).add(_allocPoint);
            }
        }
    }
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * POOL UPDATE
     */
    function updatePool(uint256 _pid) public virtual {
        if (_pid==0) return;
        PoolInfo storage pool = poolInfo[_pid];
        uint256 stakingTokenSupply = pool.totalDepositAmount;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (stakingTokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 rewards = getMiningRewardFrom(pool.lastRewardBlock);
        uint256 miningReward = rewards.mul(pool.allocPoint).div(normalPoolTotalPoint);
        if (miningReward >0){
            pool.alreadyMined = pool.alreadyMined.add(miningReward);
            alreadyMinedReward = alreadyMinedReward.add(miningReward);
            pool.accRewardPerShare = pool.accRewardPerShare.add( 
                miningReward.mul(EXPAND_BASE).div(stakingTokenSupply) 
            );
        }
        pool.lastRewardBlock = block.number;
    }
    function getMiningRewardFromTo(uint256 from_,uint256 end) public virtual view returns(uint256){
        if (end<=from_) return 0;
        uint256 totalReward = 0;
        if (startBlockList.length>0){
            
            RewardInfo memory info;
            for (uint256 ii = startBlockList.length;ii>0;ii--){
                uint256 start = startBlockList[ii-1];
                if (start>=end){
                    continue;
                }
                info = spanRewardInfo[start];
                if (from_<=start){
                    if (end >= info.endBlock){
                        totalReward = totalReward.add(info.accReward);
                    }else{
                        uint256 mined = end.sub(info.startBlock).mul(info.accReward)
                            .div( info.endBlock.sub(info.startBlock) );
                        totalReward = totalReward.add(mined);
                    }
                }else{
                    if (info.endBlock<=from_){
                        break;
                    }
                    if (end >= info.endBlock){
                         uint256 mined = info.endBlock.sub(from_).mul(info.accReward)
                            .div( info.endBlock.sub(info.startBlock) );
                        totalReward = totalReward.add(mined);
                    }else{
                        uint256 mined = end.sub(from_).mul(info.accReward)
                            .div( info.endBlock.sub(info.startBlock) );
                        totalReward = totalReward.add(mined);
                    }
                    break;
                }
            }
        }
        return totalReward;
    }
    function getMiningRewardFrom(uint256 from_) public virtual view returns(uint256){
        return getMiningRewardFromTo(from_,block.number);
    }
    
}

// SPDX-License-Identifier: Apache
pragma solidity >=0.5.0;

interface IGarfVault {

    function noticeRewardWithFrom(address from,uint256 reward) external;
    function noticeRewardWithTo(address to,uint256 initReward) external returns(uint256);
    function noticeFullRewardWithTo(address to,uint256 reward)external;


    function viewChainSplitWithTotal(address account,uint256 totalAmount) external view returns(address[] memory,uint256[] memory);
    function viewChainSplitWithInit(address account,uint256 initAmount) external view returns(address[] memory,uint256[] memory,uint256);

    
    function getAccountChainUp(address account)external view returns(address);
    function updateChainUp(address account,address up) external returns(address) ;
    function resetChainUp(address account) external;
}

// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../base/GarfVaultBase.sol";

abstract contract GarfVaultStaking is GarfVaultBase{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public withdrawCountDown = 3*86400;
    struct PendingWithdraw{
        uint256 lastSubmit;
        uint256 pendingAmount;
    }
    mapping(uint256 => mapping(address => PendingWithdraw)) public pendingOutMap;

    function pendingReward(uint256 _pid, address _user)virtual public view returns (uint256) {
        if (startBlock==0){
            return 0;
        }
        PoolInfo storage pool = poolInfo[_pid];
        StakingInfo storage user = stakingInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 stakingTokenSupply = pool.totalDepositAmount;
        
        if (block.number > pool.lastRewardBlock && stakingTokenSupply != 0) {
            uint256 rewards = getMiningRewardFrom(pool.lastRewardBlock);
            uint256 miningReward = rewards.mul(pool.allocPoint).div(normalPoolTotalPoint);
            accRewardPerShare = accRewardPerShare.add(miningReward.mul(EXPAND_BASE).div(stakingTokenSupply));
        }
        return user.amount.mul(accRewardPerShare).div(EXPAND_BASE).sub(user.rewardDebt,"acc<rewardDebt");
    }

    function deposit(uint256 _pid, uint256 _amount) public virtual {
        if (_pid==0) return;
        __deposit(_msgSender(),_pid,_amount,false);
    }

    /**
     * STAKE OTO for STAKING REWARDS
     */
    function __deposit(address account,uint256 _pid, uint256 _amount,bool fromPending) nonReentrant internal virtual returns(uint256){
        PoolInfo storage pool = poolInfo[_pid];
        StakingInfo storage user = stakingInfo[_pid][account];
        updatePool(_pid);
        uint256 pending = 0;
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accRewardPerShare).div(EXPAND_BASE).sub(user.rewardDebt);
            if(pending > 0) {
                safeRewardTransfer(account, pending,_pid);
            }
        }
        if(_amount > 0) {
            if (!fromPending){
                pool.token.safeTransferFrom(address(account), address(this), _amount);
            }
            user.amount = user.amount.add(_amount);
            pool.totalDepositAmount = pool.totalDepositAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(EXPAND_BASE);
        emit Deposit(account, _pid, _amount);
        return pending;
    }
    function withdraw(uint256 _pid, uint256 _amount) public virtual {
        if (_pid==0) return;
        __withdraw(_msgSender(),_pid,_amount);
    }

    /**
     * PENDING UNSTAKE REQUESTS
     *
     * There is a wait period of 3 days for un-staking to clear. This is done by setting withdrawCountDown to 3*86400
     */
    function __withdraw(address account,uint256 _pid, uint256 _amount) nonReentrant internal virtual {
        PoolInfo storage pool = poolInfo[_pid];
        StakingInfo storage user = stakingInfo[_pid][account];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(EXPAND_BASE).sub(user.rewardDebt);
        if(pending > 0) {
            safeRewardTransfer(account, pending,_pid);
        }
        if(_amount > 0) {

            /**
             * AMOUNTS PENDING UNSTAKE INVALID FOR STAKING
             *
             * Amounts pending unstake are not valid for staking rewards calculation. This is done by substracting
             * these amounts from totalDepositAmount and from user.amount.
             */
            user.amount = user.amount.sub(_amount,"amt exceeds");
            pool.totalDepositAmount = pool.totalDepositAmount.sub(_amount,"amount exceeds remain");
            
            // safeTokenTransfer(pool.token,account,_amount);
            /**
             * UNSTAKE PERIOD RESET
             *
             * If you un-stake additional amounts while an un-staking request is pending, amounts from the two requests
             * will be combined and the 3-day wait period timer will reset based on the time of the last request.
             */
            pendingOutMap[_pid][account].lastSubmit = block.timestamp;
            pendingOutMap[_pid][account].pendingAmount = pendingOutMap[_pid][account].pendingAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(EXPAND_BASE);
        emit Withdraw(account, _pid, _amount);
    }

    function claimPendingWithdraw(uint256 _pid,uint256 amount_) public {
        if (_pid==0) return;
        __claimPendingWithdraw(_msgSender(), _pid,amount_);
    }
    function pushBackPending(uint256 _pid,uint256 amount_)public{
        if (_pid==0) return;
        __pushBackPendingWithdraw(_msgSender(),_pid,amount_);
    }

    function viewPendingWithdraw(uint256 _pid,address account) public view returns(PendingWithdraw memory){
        return pendingOutMap[_pid][account];
    }

     /**
     * CLAIM MATURED UNSTAKE REQUESTS
     *
     * When the wait period of 3 days for un-staking has matured, claim amounts to wallet here.
     */
    function __claimPendingWithdraw(address account,uint256 _pid,uint256 amount_) internal{
        PendingWithdraw storage pending = pendingOutMap[_pid][account];
        require (pending.lastSubmit.add(withdrawCountDown) < block.timestamp,"needs time to count down");
        PoolInfo memory pool = poolInfo[_pid];

        pending.pendingAmount = pending.pendingAmount.sub(amount_,"amount exceeds");
        safeTokenTransfer(pool.token,account,amount_);
    }
    function __pushBackPendingWithdraw(address account,uint256 _pid,uint256 amount_) internal {
        PendingWithdraw storage pending = pendingOutMap[_pid][account];
        pending.pendingAmount = pending.pendingAmount.sub(amount_,"amount exceeds");
        __deposit(account,_pid,amount_,true);
    }
    function emergencyWithdraw(uint256 _pid) public {
        if (_pid==0) return;
        PoolInfo storage pool = poolInfo[_pid];
        address account = _msgSender();
        StakingInfo storage staking = stakingInfo[_pid][account];
        uint256 amount = staking.amount;
        staking.amount = 0;
        
        // KEEP THE CODE IN THE FOLLOWING 2 LINES UNLESS YOU HAVE VERY GOOD REASON TO REMOVE
        // DON'T TRANSFER AMOUNTS OUT IMMEDIATELY

        pendingOutMap[_pid][account].lastSubmit = block.timestamp;
        pendingOutMap[_pid][account].pendingAmount = pendingOutMap[_pid][account].pendingAmount.add(amount);

        pool.totalDepositAmount = pool.totalDepositAmount.sub(amount,"amount exceeds remain");
        emit EmergencyWithdraw(account, _pid, amount);
    }

    function safeRewardTransfer(address _to,uint256 _amount,uint256 _pid) internal{
        poolInfo[_pid].alreadyClaimed = poolInfo[_pid].alreadyClaimed.add(_amount);
        safeTokenTransfer(garfToken, _to, _amount);
        _mint(_to, _amount);
    }

    function safeTokenTransfer(IERC20 token,address to_,uint256 amount_) internal{
        uint256 bal = token.balanceOf(address(this));
        if (amount_ > bal){
            token.safeTransfer(to_,bal);
        }else{
            token.safeTransfer(to_,amount_);
        }
    }
}

