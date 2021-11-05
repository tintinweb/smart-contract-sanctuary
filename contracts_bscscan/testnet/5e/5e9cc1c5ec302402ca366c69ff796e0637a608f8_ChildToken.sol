pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./Token.sol";
import "./AccessControlRci.sol";

contract ChildToken is AccessControlRci, Token {

    address public childChainManagerProxy;

    constructor(string memory name, string memory symbol, address childChainManagerProxy_) Token(name, symbol, 0)
    {
        _initializeRciAdmin();
        childChainManagerProxy = childChainManagerProxy_;
    }

    function updateChildChainManager(address newChildChainManagerProxy)
    external onlyAdmin
    {
        require(newChildChainManagerProxy != address(0), "ChildToken - updateChildChainManager: Cannot set childChainManagerProxy to 0.");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    function deposit(address user, bytes calldata depositData)
    external
    {
        require(msg.sender == childChainManagerProxy, "ChildToken - deposit : Caller is not childChainManagerProxy.");

        uint256 amount = abi.decode(depositData, (uint256));

        // `amount` token getting minted here & equal amount got locked in RootChainManager
        ERC20._mint(user, amount);
    }

    function withdraw(uint256 amount)
    external
    {
        ERC20._burn(msg.sender, amount);
    }

    function burn(uint256 amount)
    public override
    {
        revert("Burning can only be done on the main Ethereum network. Please transfer your tokens over and burn from there.");
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./standard/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "./AccessControlRci.sol";
import "./../interfaces/ICompetition.sol";

contract Token is AccessControlRci, ERC20PresetFixedSupply
{
    mapping (address => bool) private _authorizedCompetitions;

    event CompetitionAuthorized(address indexed competitionAddress);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_)
    ERC20PresetFixedSupply(name_, symbol_, initialSupply_, msg.sender)
    {
        _initializeRciAdmin();
    }

    function increaseStake(address target, uint256 amountToken)
    public
    returns (bool success)
    {
        require(_authorizedCompetitions[target], "Token - increaseStake: This competition is not authorized.");
        uint256 senderBal = _balances[msg.sender];
        uint256 senderStake = ICompetition(target).getStake(msg.sender);

        ICompetition(target).increaseStake(msg.sender, amountToken);
        transfer(target, amountToken);

        require((senderBal - _balances[msg.sender]) == amountToken, "Token - increaseStake: Sender final balance incorrect.");
        require((ICompetition(target).getStake(msg.sender) - senderStake) == amountToken, "Token - increaseStake: Sender final stake incorrect.");

        success = true;
    }

    function decreaseStake(address target, uint256 amountToken)
    public
    returns (bool success)
    {
        require(_authorizedCompetitions[target], "Token - decreaseStake: This competition is not authorized.");
        uint256 senderBal = _balances[msg.sender];
        uint256 senderStake = ICompetition(target).getStake(msg.sender);

        ICompetition(target).decreaseStake(msg.sender, amountToken);

        require((_balances[msg.sender] - senderBal) == amountToken, "Token - decreaseStake: Sender final balance incorrect.");
        require(senderStake - (ICompetition(target).getStake(msg.sender)) == amountToken, "Token - decreaseStake: Sender final stake incorrect.");

        success = true;
    }

    function setStake(address target, uint256 amountToken)
    external
    returns (bool success)
    {
        require(_authorizedCompetitions[target], "Token - setStake: This competition is not authorized.");
        uint256 currentStake = ICompetition(target).getStake(msg.sender);
        require(currentStake != amountToken, "Token - setStake: Your stake is already set to this amount.");
        if (amountToken > currentStake){
            increaseStake(target, amountToken - currentStake);
        } else{
            decreaseStake(target, currentStake - amountToken);
        }
        success = true;
    }

    function getStake(address target, address staker)
    external view
    returns (uint256 stake)
    {
        require(_authorizedCompetitions[target], "Token - getStake: This competition is not authorized.");
        stake = ICompetition(target).getStake(staker);
    }


    function authorizeCompetition(address competitionAddress)
    external
    onlyAdmin
    {
        require(competitionAddress != address(0), "Token - authorizeCompetition: Cannot authorize 0 address.");
        _authorizedCompetitions[competitionAddress] = true;

        emit CompetitionAuthorized(competitionAddress);
    }

    function competitionIsAuthorized(address competitionAddress)
    external view
    returns (bool authorized)
    {
        authorized = _authorizedCompetitions[competitionAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) internal _balances;

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
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import './standard/access/AccessControl.sol';

abstract contract AccessControlRci is AccessControl{
    bytes32 public constant RCI_MAIN_ADMIN = keccak256('RCI_MAIN_ADMIN');
    bytes32 public constant RCI_CHILD_ADMIN = keccak256('RCI_CHILD_ADMIN');

    modifier onlyMainAdmin()
    {
        require(hasRole(RCI_MAIN_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    modifier onlyAdmin()
    {
        require(hasRole(RCI_CHILD_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    function _initializeRciAdmin()
    internal
    {
        _setupRole(RCI_MAIN_ADMIN, msg.sender);
        _setRoleAdmin(RCI_MAIN_ADMIN, RCI_MAIN_ADMIN);

        _setupRole(RCI_CHILD_ADMIN, msg.sender);
        _setRoleAdmin(RCI_CHILD_ADMIN, RCI_MAIN_ADMIN);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

interface ICompetition{


    /**
    PARTICIPANT WRITE METHODS
    **/

    /**
    * @dev Called by anyone ONLY VIA THE ERC20 TOKEN CONTRACT to increase their stake.
    * @param staker The address of the staker that wants to increase their stake.
    * @param amountToken The amount to add to their stake.
    * @return success True if the operation completed successfully.
    **/
    function increaseStake(address staker, uint256 amountToken) external returns (bool success);

    /**
    * @dev Called by anyone ONLY VIA THE ERC20 TOKEN CONTRACT to decrease their stake.
    * @param staker The address of the staker that wants to withdraw their stake.
    * @param amountToken Number of tokens to withdraw.
    * @return success True if the operation completed successfully.
    **/
    function decreaseStake(address staker, uint256 amountToken) external returns (bool success);

    /**
    * @dev Called by participant to make a new prediction submission for the current challenge.
    * @dev Will be successful if the participant's stake is above the staking threshold.
    * @param submissionHash IPFS reference hash of submission. This is the IPFS CID less the 1220 prefix.
    * @return challengeNumber Challenge that this submission was made for.
    **/
    function submitNewPredictions(bytes32 submissionHash) external returns (uint32 challengeNumber);

    /**
    * @dev Called by participant to modify prediction submission for the current challenge.
    * @param oldSubmissionHash IPFS reference hash of previous submission. This is the IPFS CID less the 1220 prefix.
    * @param newSubmissionHash IPFS reference hash of new submission. This is the IPFS CID less the 1220 prefix.
    * @return challengeNumber Challenge that this submission was made for.
    **/
    function updateSubmission(bytes32 oldSubmissionHash, bytes32 newSubmissionHash) external returns (uint32 challengeNumber);

    /**
    ORGANIZER WRITE METHODS
    **/

    /**
    * @dev Called only by authorized admin to update the current broadcast message.
    * @param newMessage New broadcast message.
    * @return success True if the operation completed successfully.
    **/
    function updateMessage(string calldata newMessage) external  returns (bool success);

    /**
    * @dev Called only by authorized admin to update one of the deadlines for this challenge.
    * @param challengeNumber Challenge to perform the update for.
    * @param index Deadline index to update.
    * @param timestamp Deadline timestamp in milliseconds.
    * @return success True if the operation completed successfully.
    **/
    function updateDeadlines(uint32 challengeNumber, uint256 index, uint256 timestamp) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the minimum amount required in the competition rewards pool to open a new challenge.
    * @param newThreshold New minimum amount for opening new challenge.
    * @return success True if the operation completed successfully.
    **/
    function updateRewardsThreshold(uint256 newThreshold) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the minimum stake amount required to take part in the competition.
    * @param newStakeThreshold New stake threshold amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateStakeThreshold(uint256 newStakeThreshold) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the percentage of the competition rewards pool allocated to the challenge rewards budget.
    * @param newPercentage New percentage amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateChallengeRewardsPercentageInWei(uint256 newPercentage) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the percentage of the competition rewards pool allocated to the tournament rewards budget.
    * @param newPercentage New percentage amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateTournamentRewardsPercentageInWei(uint256 newPercentage) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the private key for this challenge. This should be done at the end of the challenge.
    * @param challengeNumber Challenge to perform the update for.
    * @param newKeyHash IPFS reference cid where private key is stored.
    * @return success True if the operation completed successfully.
    **/
    function updatePrivateKey(uint32 challengeNumber, bytes32 newKeyHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to start allowing staking for a new challenge.
    * @param datasetHash IPFS reference hash where dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param keyHash IPFS reference hash where the key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param submissionCloseDeadline Timestamp of the time where submissions will be closed.
    * @param nextChallengeDeadline Timestamp where ths challenge will be closed and the next challenge opened.
    * @return success True if the operation completed successfully.
    **/
    function openChallenge(bytes32 datasetHash, bytes32 keyHash, uint256 submissionCloseDeadline, uint256 nextChallengeDeadline) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the dataset of a particular challenge.
    * @param oldDatasetHash IPFS reference hash where previous dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param newDatasetHash IPFS reference hash where new dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateDataset(bytes32 oldDatasetHash, bytes32 newDatasetHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the key of a particular challenge.
    * @param oldKeyHash IPFS reference hash where previous key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param newKeyHash IPFS reference hash where new key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateKey(bytes32 oldKeyHash, bytes32 newKeyHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to stop allowing submissions for a particular challenge.
    * @return success True if the operation completed successfully.
    **/
    function closeSubmission() external returns (bool success);

    /**
    * @dev Called only by authorized admin to submit the IPFS reference for the results of a particular challenge.
    * @param resultsHash IPFS reference hash where results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function submitResults(bytes32 resultsHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the results of the current challenge.
    * @param oldResultsHash IPFS reference hash where previous results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @param newResultsHash IPFS reference hash where new results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateResults(bytes32 oldResultsHash, bytes32 newResultsHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to move rewards from the competition pool to the winners' competition internal balances based on results from the current challenge.
    * @dev Note that the size of the array parameters passed in to this function is limited by the block gas limit.
    * @dev This function allows for the payout to be split into chunks by calling it repeatedly.
    * @param submitters List of addresses that made submissions for the challenge.
    * @param stakingRewards List of corresponding amount of tokens in wei given to each submitter for the staking rewards portion.
    * @param challengeRewards List of corresponding amount of tokens in wei won by each submitter for the challenge rewards portion.
    * @param tournamentRewards List of corresponding amount of tokens in wei won by each submitter for the tournament rewards portion.
    * @return success True if operation completes successfully.
    **/
    function payRewards(address[] calldata submitters, uint256[] calldata stakingRewards, uint256[] calldata challengeRewards, uint256[] calldata tournamentRewards) external returns (bool success);

    /**
    * @dev Provides the same function as above but allows for challenge number to be specified.
    * @dev Note that the size of the array parameters passed in to this function is limited by the block gas limit.
    * @dev This function allows for the update to be split into chunks by calling it repeatedly.
    * @param challengeNumber Challenge to make updates for.
    * @param participants List of participants' addresses.
    * @param challengeScores List of corresponding challenge scores.
    * @param tournamentScores List of corresponding tournament scores.
    * @return success True if operation completes successfully.
    **/
    function updateChallengeAndTournamentScores(uint32 challengeNumber, address[] calldata participants, uint256[] calldata challengeScores, uint256[] calldata tournamentScores) external returns (bool success);

    /**
    * @dev Called only by authorized admin to do a batch update of an additional information item for a list of participants for a given challenge.
    * @param challengeNumber Challenge to update information for.
    * @param participants List of participant' addresses.
    * @param itemNumber Item to update for.
    * @param values List of corresponding values to store.
    * @return success True if operation completes successfully.
    **/
    function updateInformationBatch(uint32 challengeNumber, address[] calldata participants, uint256 itemNumber, uint[] calldata values) external returns (bool success);

    /**
    * @dev Called only by an authorized admin to advance to the next phase.
    * @dev Due to the block gas limit rewards payments may need to be split up into multiple function calls.
    * @dev In other words, payStakingRewards and payChallengeAndTournamentRewards may need to be called multiple times to complete all required payments.
    * @dev This function is used to advance to phase 3 after staking rewards payments have complemted or to phase 4 after challenge and tournament rewards payments have completed.
    * @param phase The phase to advance to.
    * @return success True if the operation completed successfully.
    **/
    function advanceToPhase(uint8 phase) external returns (bool success);

    /**
    * @dev Called only by an authorized admin, to move any tokens sent to this contract without using the 'sponsor' or 'setStake'/'increaseStake' methods into the competition pool.
    * @return success True if the operation completed successfully.
    **/
    function moveRemainderToPool() external returns (bool success);

    /**
    READ METHODS
    **/

    /**
    * @dev Called by anyone to check minimum amount required to open a new challenge.
    * @return challengeRewardsThreshold Amount of tokens in wei the competition pool must contain to open a new challenge.
    **/
    function getRewardsThreshold() view external returns (uint256 challengeRewardsThreshold);

    /**
    * @dev Called by anyone to check amount pooled into this contract.
    * @return competitionPool Amount of tokens in the competition pool in wei.
    **/
    function getCompetitionPool() view external returns (uint256 competitionPool);

    /**
    * @dev Called by anyone to check the current total amount staked.
    * @return currentTotalStaked Amount of tokens currently staked in wei.
    **/
    function getCurrentTotalStaked() view external returns (uint256 currentTotalStaked);

    /**
    * @dev Called by anyone to check the staking rewards budget allocation for the current challenge.
    * @return currentStakingRewardsBudget Budget for staking rewards in wei.
    **/
    function getCurrentStakingRewardsBudget() view external returns (uint256 currentStakingRewardsBudget);

    /**
    * @dev Called by anyone to check the challenge rewards budget for the current challenge.
    * @return currentChallengeRewardsBudget Budget for challenge rewards payment in wei.
    **/
    function getCurrentChallengeRewardsBudget() view external returns (uint256 currentChallengeRewardsBudget);

    /**
    * @dev Called by anyone to check the tournament rewards budget for the current challenge.
    * @return currentTournamentRewardsBudget Budget for tournament rewards payment in wei.
    **/
    function getCurrentTournamentRewardsBudget() view external returns (uint256 currentTournamentRewardsBudget);

    /**
    * @dev Called by anyone to check the percentage of the total competition reward pool allocated for the challenge reward for this challenge.
    * @return challengeRewardsPercentageInWei Percentage for challenge reward budget in wei.
    **/
    function getChallengeRewardsPercentageInWei() view external returns (uint256 challengeRewardsPercentageInWei);

    /**
    * @dev Called by anyone to check the percentage of the total competition reward pool allocated for the tournament reward for this challenge.
    * @return tournamentRewardsPercentageInWei Percentage for tournament reward budget in wei.
    **/
    function getTournamentRewardsPercentageInWei() view external returns (uint256 tournamentRewardsPercentageInWei);

    /**
    * @dev Called by anyone to get the number of the latest challenge.
    * @dev As the challenge number begins from 1, this is also the total number of challenges created in this competition.
    * @return latestChallengeNumber Latest challenge created.
    **/
    function getLatestChallengeNumber() view external returns (uint32 latestChallengeNumber);

    /**
    * @dev Called by anyone to obtain the dataset hash for this particular challenge.
    * @param challengeNumber The challenge to get the dataset hash of.
    * @return dataset IPFS hash where the dataset of this particular challenge is stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getDatasetHash(uint32 challengeNumber) view external returns (bytes32 dataset);

    /**
    * @dev Called by anyone to obtain the results hash for this particular challenge.
    * @param challengeNumber The challenge to get the results hash of.
    * @return results IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getResultsHash(uint32 challengeNumber) view external returns (bytes32 results);

    /**
    * @dev Called by anyone to obtain the key hash for this particular challenge.
    * @param challengeNumber The challenge to get the key hash of.
    * @return key IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getKeyHash(uint32 challengeNumber) view external returns (bytes32 key);

    /**
    * @dev Called by anyone to obtain the private key hash for this particular challenge.
    * @param challengeNumber The challenge to get the key hash of.
    * @return privateKey IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getPrivateKeyHash(uint32 challengeNumber) view external returns (bytes32 privateKey);

    /**
    * @dev Called by anyone to obtain the number of submissions made for this particular challenge.
    * @param challengeNumber The challenge to get the submission counter of.
    * @return submissionCounter Number of submissions made.
    **/
    function getSubmissionCounter(uint32 challengeNumber) view external returns (uint256 submissionCounter);

    /**
    * @dev Called by anyone to obtain the list of submitters for this particular challenge.
    * @dev Submitters refer to participants that have made submissions for this particular challenge.
    * @param challengeNumber The challenge to get the submitters list of.
    * @param startIndex The challenge to get the submitters list of.
    * @param endIndex The challenge to get the submitters list of.
    * @return List of submitter addresses.
    **/
    function getSubmitters(uint32 challengeNumber, uint256 startIndex, uint256 endIndex) view external returns (address[] memory);

    /**
    * @dev Called by anyone to obtain the phase number for this particular challenge.
    * @param challengeNumber The challenge to get the phase of.
    * @return phase The phase that this challenge is in.
    **/
    function getPhase(uint32 challengeNumber) view external returns (uint8 phase);

    /**
    * @dev Called by anyone to obtain the minimum amount of stake required to participate in the competition.
    * @return stakeThreshold Minimum stake amount in wei.
    **/
    function getStakeThreshold() view external returns (uint256 stakeThreshold);

    /**
    * @dev Called by anyone to obtain the stake amount in wei of a particular address.
    * @param participant Address to query token balance of.
    * @return stake Token balance of given address in wei.
    **/
    function getStake(address participant) view external returns (uint256 stake);

    /**
    * @dev Called by anyone to obtain the smart contract address of the ERC20 token used in this competition.
    * @return tokenAddress ERC20 Token smart contract address.
    **/
    function getTokenAddress() view external returns (address tokenAddress);

    /**
    * @dev Called by anyone to get submission hash of a participant for a challenge.
    * @param challengeNumber Challenge index to check on.
    * @param participant Address of participant to check on.
    * @return submissionHash IPFS reference hash of participant's prediction submission for this challenge. This is the IPFS CID less the 1220 prefix.
    **/
    function getSubmission(uint32 challengeNumber, address participant) view external returns (bytes32 submissionHash);

    /**
    * @dev Called by anyone to check the stakes locked for this participant in a particular challenge.
    * @param challengeNumber Challenge to get the stakes locked of.
    * @param participant Address of participant to check on.
    * @return staked Amount of tokens locked for this challenge for this participant.
    **/
    function getStakedAmountForChallenge(uint32 challengeNumber, address participant) view external returns (uint256 staked);

    /**
    * @dev Called by anyone to check the staking rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the staking rewards given of.
    * @param participant Address of participant to check on.
    * @return stakingRewards Amount of staking rewards given to this participant for this challenge.
    **/
    function getStakingRewards(uint32 challengeNumber, address participant) view external returns (uint256 stakingRewards);

    /**
    * @dev Called by anyone to check the challenge rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the challenge rewards given of.
    * @param participant Address of participant to check on.
    * @return challengeRewards Amount of challenge rewards given to this participant for this challenge.
    **/
    function getChallengeRewards(uint32 challengeNumber, address participant) view external returns (uint256 challengeRewards);

    /**
    * @dev Called by anyone to check the tournament rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the tournament rewards given of.
    * @param participant Address of participant to check on.
    * @return tournamentRewards Amount of tournament rewards given to this participant for this challenge.
    **/
    function getTournamentRewards(uint32 challengeNumber, address participant) view external returns (uint256 tournamentRewards);

    /**
    * @dev Called by anyone to check the overall rewards (staking + challenge + tournament rewards) given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the overall rewards given of.
    * @param participant Address of participant to check on.
    * @return overallRewards Amount of overall rewards given to this participant for this challenge.
    **/
    function getOverallRewards(uint32 challengeNumber, address participant) view external returns (uint256 overallRewards);

    /**
    * @dev Called by anyone to check get the challenge score of this participant for this challenge.
    * @param challengeNumber Challenge to get the participant's challenge score of.
    * @param participant Address of participant to check on.
    * @return challengeScores The challenge score of this participant for this challenge.
    **/
    function getChallengeScores(uint32 challengeNumber, address participant) view external returns (uint256 challengeScores);

    /**
    * @dev Called by anyone to check get the tournament score of this participant for this challenge.
    * @param challengeNumber Challenge to get the participant's tournament score of..
    * @param participant Address of participant to check on.
    * @return tournamentScores The tournament score of this participant for this challenge.
    **/
    function getTournamentScores(uint32 challengeNumber, address participant) view external returns (uint256 tournamentScores);

    /**
    * @dev Called by anyone to check the additional information for this participant in a particular challenge.
    * @param challengeNumber Challenge to get the additional information of.
    * @param participant Address of participant to check on.
    * @param itemNumber Additional information item to check on.
    * @return value Value of this additional information item for this participant for this challenge.
    **/
    function getInformation(uint32 challengeNumber, address participant, uint256 itemNumber) view external returns (uint value);

    /**
    * @dev Called by anyone to retrieve one of the deadlines for this challenge.
    * @param challengeNumber Challenge to get the deadline of.
    * @param index Index of the deadline to retrieve.
    * @return deadline Deadline in milliseconds.
    **/
    function getDeadlines(uint32 challengeNumber, uint256 index)
    external view returns (uint256 deadline);

    /**
    * @dev Called by anyone to check the amount of tokens that have been sent to this contract but are not recorded as a stake or as part of the competition rewards pool.
    * @return remainder The amount of tokens held by this contract that are not recorded as a stake or as part of the competition rewards pool.
    **/
    function getRemainder() external view returns (uint256 remainder);

    /**
    * @dev Called by anyone to get the current broadcast message.
    * @return message Current message being broadcasted.
    **/
    function getMessage() external returns (string memory message);

    /**
    METHODS CALLABLE BY BOTH ADMIN AND PARTICIPANTS.
    **/

    /**
    * @dev Called by a sponsor to send tokens to the contract's competition pool. This pool is used for payouts to challenge winners.
    * @dev This performs an ERC20 transfer so the msg sender will need to grant approval to this contract before calling this function.
    * @param amountToken The amount to send to the the competition pool.
    * @return success True if the operation completed successfully.
    **/
    function sponsor(uint256 amountToken) external returns (bool success);

    /**
    EVENTS
    **/

    event StakeIncreased(address indexed sender, uint256 indexed amount);

    event StakeDecreased(address indexed sender, uint256 indexed amount);

    event SubmissionUpdated(uint32 indexed challengeNumber, address indexed participantAddress, bytes32 indexed newSubmissionHash);

    event MessageUpdated();

    event RewardsThresholdUpdated(uint256 indexed newRewardsThreshold);

    event StakeThresholdUpdated(uint256 indexed newStakeThreshold);

    event ChallengeRewardsPercentageInWeiUpdated(uint256 indexed newPercentage);

    event TournamentRewardsPercentageInWeiUpdated(uint256 indexed newPercentage);

    event PrivateKeyUpdated(bytes32 indexed newPrivateKeyHash);

    event ChallengeOpened(uint32 indexed challengeNumber);

    event DatasetUpdated(uint32 indexed challengeNumber, bytes32 indexed oldDatasetHash, bytes32 indexed newDatasetHash);

    event KeyUpdated(uint32 indexed challengeNumber, bytes32 indexed oldKeyHash, bytes32 indexed newKeyHash);

    event SubmissionClosed(uint32 indexed challengeNumber);

    event ResultsUpdated(uint32 indexed challengeNumber, bytes32 indexed oldResultsHash, bytes32 indexed newResultsHash);

    event RewardsPayment(uint32 challengeNumber, address indexed submitter, uint256 stakingReward, uint256 indexed challengeReward, uint256 indexed tournamentReward);

    event TotalRewardsPaid(uint32 challengeNumber, uint256 indexed totalStakingAmount, uint256 indexed totalChallengeAmount, uint256 indexed totalTournamentAmount);

    event ChallengeAndTournamentScoresUpdated(uint32 indexed challengeNumber);

    event BatchInformationUpdated(uint32 indexed challengeNumber, uint256 indexed itemNumber);

    event RemainderMovedToPool(uint256 indexed remainder);

    event Sponsor(address indexed sponsorAddress, uint256 indexed sponsorAmount, uint256 indexed poolTotal);
}