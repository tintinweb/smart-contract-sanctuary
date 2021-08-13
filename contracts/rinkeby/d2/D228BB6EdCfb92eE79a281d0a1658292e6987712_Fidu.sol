pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

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
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";
import "../Initializable.sol";

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
 * and pauser roles to aother accounts
 */
contract ERC20PresetMinterPauserUpgradeSafe is Initializable, ContextUpgradeSafe, AccessControlUpgradeSafe, ERC20BurnableUpgradeSafe, ERC20PausableUpgradeSafe {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    function initialize(string memory name, string memory symbol) public {
        __ERC20PresetMinterPauser_init(name, symbol);
    }

    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {


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
    function mint(address to, uint256 amount) public {
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
    function pause() public {
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
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20UpgradeSafe, ERC20PausableUpgradeSafe) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";
import "../../Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeSafe is Initializable, ContextUpgradeSafe, ERC20UpgradeSafe {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {


    }

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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";
import "../../Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeSafe is Initializable, ERC20UpgradeSafe, PausableUpgradeSafe {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {


    }

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

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
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

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
pragma solidity 0.6.12;

import "./IERC20withDec.sol";

interface ICUSDCContract is IERC20withDec {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function balanceOfUnderlying(address owner) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract ICreditDesk {
  uint256 public totalWritedowns;
  uint256 public totalLoansOutstanding;

  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit) external virtual;

  function createCreditLine(
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr
  ) public virtual returns (address);

  function drawdown(address creditLineAddress, uint256 amount) external virtual;

  function pay(address creditLineAddress, uint256 amount) external virtual;

  function assessCreditLine(address creditLineAddress) external virtual;

  function applyPayment(address creditLineAddress, uint256 amount) external virtual;

  function getNextPaymentAmount(address creditLineAddress, uint256 asOfBLock) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/*
Only addition is the `decimals` function, which we need, and which both our Fidu and USDC use, along with most ERC20's.
*/

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20 {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20withDec.sol";

interface IFidu is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract IPool {
  uint256 public sharePrice;

  function deposit(uint256 amount) external virtual;

  function withdraw(uint256 usdcAmount) external virtual;

  function withdrawInFidu(uint256 fiduAmount) external virtual;

  function collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) public virtual;

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool);

  function drawdown(address to, uint256 amount) public virtual returns (bool);

  function sweepToCompound() public virtual;

  function sweepFromCompound() public virtual;

  function distributeLosses(address creditlineAddress, int256 writedownDelta) external virtual;

  function assets() public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./PauserPausable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like ugpradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
  Initializable,
  AccessControlUpgradeSafe,
  PauserPausable,
  ReentrancyGuardUpgradeSafe
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  using SafeMath for uint256;
  // Pre-reserving a few slots in the base contract in case we need to add things in the future.
  // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
  // See OpenZeppelin's use of this pattern here:
  // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
  uint256[50] private __gap1;
  uint256[50] private __gap2;
  uint256[50] private __gap3;
  uint256[50] private __gap4;

  // solhint-disable-next-line func-name-mixedcase
  function __BaseUpgradeablePausable__init(address owner) public initializer {
    require(owner != address(0), "Owner cannot be the zero address");
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GoldfinchConfig.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IFidu.sol";
import "../../interfaces/ICreditDesk.sol";
import "../../interfaces/IERC20withDec.sol";
import "../../interfaces/ICUSDCContract.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigHelper {
  function getPool(GoldfinchConfig config) internal view returns (IPool) {
    return IPool(poolAddress(config));
  }

  function getUSDC(GoldfinchConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getCreditDesk(GoldfinchConfig config) internal view returns (ICreditDesk) {
    return ICreditDesk(creditDeskAddress(config));
  }

  function getFidu(GoldfinchConfig config) internal view returns (IFidu) {
    return IFidu(fiduAddress(config));
  }

  function getCUSDCContract(GoldfinchConfig config) internal view returns (ICUSDCContract) {
    return ICUSDCContract(cusdcContractAddress(config));
  }

  function oneInchAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.OneInch));
  }

  function trustedForwarderAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TrustedForwarder));
  }

  function configAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig));
  }

  function poolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Pool));
  }

  function creditDeskAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CreditDesk));
  }

  function fiduAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Fidu));
  }

  function cusdcContractAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CUSDCContract));
  }

  function usdcAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function reserveAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ProtocolAdmin));
  }

  function getReserveDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit,
    TotalFundsLimit,
    MaxUnderwriterLimit,
    ReserveDenominator,
    WithdrawFeeDenominator,
    LatenessGracePeriodInDays,
    LatenessMaxDays
  }
  enum Addresses {
    Pool,
    CreditLineImplementation,
    CreditLineFactory,
    CreditDesk,
    Fidu,
    USDC,
    TreasuryReserve,
    ProtocolAdmin,
    OneInch,
    TrustedForwarder,
    CUSDCContract,
    GoldfinchConfig
  }

  function getNumberName(uint256 number) public pure returns (string memory) {
    Numbers numberName = Numbers(number);
    if (Numbers.TransactionLimit == numberName) {
      return "TransactionLimit";
    }
    if (Numbers.TotalFundsLimit == numberName) {
      return "TotalFundsLimit";
    }
    if (Numbers.MaxUnderwriterLimit == numberName) {
      return "MaxUnderwriterLimit";
    }
    if (Numbers.ReserveDenominator == numberName) {
      return "ReserveDenominator";
    }
    if (Numbers.WithdrawFeeDenominator == numberName) {
      return "WithdrawFeeDenominator";
    }
    if (Numbers.LatenessGracePeriodInDays == numberName) {
      return "LatenessGracePeriodInDays";
    }
    if (Numbers.LatenessMaxDays == numberName) {
      return "LatenessMaxDays";
    }
    revert("Unknown value passed to getNumberName");
  }

  function getAddressName(uint256 addressKey) public pure returns (string memory) {
    Addresses addressName = Addresses(addressKey);
    if (Addresses.Pool == addressName) {
      return "Pool";
    }
    if (Addresses.CreditLineImplementation == addressName) {
      return "CreditLineImplementation";
    }
    if (Addresses.CreditLineFactory == addressName) {
      return "CreditLineFactory";
    }
    if (Addresses.CreditDesk == addressName) {
      return "CreditDesk";
    }
    if (Addresses.Fidu == addressName) {
      return "Fidu";
    }
    if (Addresses.USDC == addressName) {
      return "USDC";
    }
    if (Addresses.TreasuryReserve == addressName) {
      return "TreasuryReserve";
    }
    if (Addresses.ProtocolAdmin == addressName) {
      return "ProtocolAdmin";
    }
    if (Addresses.OneInch == addressName) {
      return "OneInch";
    }
    if (Addresses.TrustedForwarder == addressName) {
      return "TrustedForwarder";
    }
    if (Addresses.CUSDCContract == addressName) {
      return "CUSDCContract";
    }
    revert("Unknown value passed to getAddressName");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/presets/ERC20PresetMinterPauser.sol";
import "./ConfigHelper.sol";

/**
 * @title Fidu
 * @notice Fidu (symbol: FIDU) is Goldfinch's liquidity token, representing shares
 *  in the Pool. When you deposit, we mint a corresponding amount of Fidu, and when you withdraw, we
 *  burn Fidu. The share price of the Pool implicitly represents the "exchange rate" between Fidu
 *  and USDC (or whatever currencies the Pool may allow withdraws in during the future)
 * @author Goldfinch
 */

contract Fidu is ERC20PresetMinterPauserUpgradeSafe {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  // $1 threshold to handle potential rounding errors, from differing decimals on Fidu and USDC;
  uint256 public constant ASSET_LIABILITY_MATCH_THRESHOLD = 1e6;
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  /*
    We are using our own initializer function so we can set the owner by passing it in.
    I would override the regular "initializer" function, but I can't because it's not marked
    as "virtual" in the parent contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(
    address owner,
    string calldata name,
    string calldata symbol,
    GoldfinchConfig _config
  ) external initializer {
    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC20_init_unchained(name, symbol);

    __ERC20Burnable_init_unchained();
    __Pausable_init_unchained();
    __ERC20Pausable_init_unchained();

    config = _config;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
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
  function mintTo(address to, uint256 amount) public {
    require(canMint(amount), "Cannot mint: it would create an asset/liability mismatch");
    // This will lock the function down to only the minter
    super.mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have the MINTER_ROLE
   */
  function burnFrom(address from, uint256 amount) public override {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: Must have minter role to burn");
    require(canBurn(amount), "Cannot burn: it would create an asset/liability mismatch");
    _burn(from, amount);
  }

  // Internal functions

  // canMint assumes that the USDC that backs the new shares has already been sent to the Pool
  function canMint(uint256 newAmount) internal view returns (bool) {
    IPool pool = config.getPool();
    uint256 liabilities = totalSupply().add(newAmount).mul(pool.sharePrice()).div(fiduMantissa());
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 _assets = pool.assets();
    if (_assets >= liabilitiesInDollars) {
      return _assets.sub(liabilitiesInDollars) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    } else {
      return liabilitiesInDollars.sub(_assets) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    }
  }

  // canBurn assumes that the USDC that backed these shares has already been moved out the Pool
  function canBurn(uint256 amountToBurn) internal view returns (bool) {
    IPool pool = config.getPool();
    uint256 liabilities = totalSupply().sub(amountToBurn).mul(pool.sharePrice()).div(fiduMantissa());
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 _assets = pool.assets();
    if (_assets >= liabilitiesInDollars) {
      return _assets.sub(liabilitiesInDollars) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    } else {
      return liabilitiesInDollars.sub(_assets) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    }
  }

  function fiduToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }

  function updateGoldfinchConfig() external {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: Must have minter role to change config");
    config = GoldfinchConfig(config.configAddress());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseUpgradeablePausable.sol";
import "./ConfigOptions.sol";

/**
 * @title GoldfinchConfig
 * @notice This contract stores mappings of useful "protocol config state", giving a central place
 *  for all other contracts to access it. For example, the TransactionLimit, or the PoolAddress. These config vars
 *  are enumerated in the `ConfigOptions` library, and can only be changed by admins of the protocol.
 * @author Goldfinch
 */

contract GoldfinchConfig is BaseUpgradeablePausable {
  mapping(uint256 => address) public addresses;
  mapping(uint256 => uint256) public numbers;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);

  function initialize(address owner) public initializer {
    __BaseUpgradeablePausable__init(owner);
  }

  function setAddress(uint256 addressIndex, address newAddress) public onlyAdmin {
    require(addresses[addressIndex] == address(0), "Address has already been initialized");

    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  function setNumber(uint256 index, uint256 newNumber) public onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  function setTreasuryReserve(address newTreasuryReserve) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.TreasuryReserve);
    emit AddressUpdated(msg.sender, key, addresses[key], newTreasuryReserve);
    addresses[key] = newTreasuryReserve;
  }

  /*
    Using custom getters incase we want to change underlying implementation later,
    or add checks or validations later on.
  */
  function getAddress(uint256 addressKey) public view returns (address) {
    return addresses[addressKey];
  }

  function getNumber(uint256 number) public view returns (uint256) {
    return numbers[number];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

/**
 * @title PauserPausable
 * @notice Inheriting from OpenZeppelin's Pausable contract, this does small
 *  augmentations to make it work with a PAUSER_ROLE, leveraging the AccessControl contract.
 *  It is meant to be inherited.
 * @author Goldfinch
 */

contract PauserPausable is AccessControlUpgradeSafe, PausableUpgradeSafe {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __PauserPausable__init() public initializer {
    __Pausable_init_unchained();
  }

  /**
   * @dev Pauses all functions guarded by Pause
   *
   * See {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the PAUSER_ROLE.
   */

  function pause() public onlyPauserRole {
    _pause();
  }

  /**
   * @dev Unpauses the contract
   *
   * See {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the Pauser role
   */
  function unpause() public onlyPauserRole {
    _unpause();
  }

  modifier onlyPauserRole() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to perform this action");
    _;
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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