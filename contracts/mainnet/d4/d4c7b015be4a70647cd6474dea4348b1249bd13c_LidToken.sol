/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity 0.5.16;

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
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }

    uint256[50] private ______gap;
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Initializable, Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    uint256[50] private ______gap;
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Initializable, Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    function initialize(address sender) public initializer {
        if (!isMinter(sender)) {
            _addMinter(sender);
        }
    }

    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

    uint256[50] private ______gap;
}

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is Initializable, ERC20, MinterRole {
    function initialize(address sender) public initializer {
        MinterRole.initialize(sender);
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount)
        public
        onlyMinter
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    uint256[50] private ______gap;
}

contract PauserRole is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(
            isPauser(_msgSender()),
            "PauserRole: caller does not have the Pauser role"
        );
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Initializable, Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    function initialize(address sender) public initializer {
        PauserRole.initialize(sender);

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
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[50] private ______gap;
}

/**
 * @title Pausable token
 * @dev ERC20 with pausable transfers and allowances.
 *
 * Useful if you want to stop trades until the end of a crowdsale, or have
 * an emergency switch for freezing all token transfers in the event of a large
 * bug.
 */
contract ERC20Pausable is Initializable, ERC20, Pausable {
    function initialize(address sender) public initializer {
        Pausable.initialize(sender);
    }

    function transfer(address to, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    uint256[50] private ______gap;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

interface ILidCertifiableToken {
    function activateTransfers() external;

    function activateTax() external;

    function mint(address account, uint256 amount) external returns (bool);

    function addMinter(address account) external;

    function renounceMinter() external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function isMinter(address account) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IStakeHandler {
    function handleStake(
        address staker,
        uint256 stakerDeltaValue,
        uint256 stakerFinalValue
    ) external;

    function handleUnstake(
        address staker,
        uint256 stakerDeltaValue,
        uint256 stakerFinalValue
    ) external;
}

contract LidStaking is Initializable, Ownable {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 internal constant DISTRIBUTION_MULTIPLIER = 2**64;

    uint256 public stakingTaxBP;
    uint256 public unstakingTaxBP;
    ILidCertifiableToken private lidToken;

    mapping(address => uint256) public stakeValue;
    mapping(address => int256) public stakerPayouts;

    uint256 public totalDistributions;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 public profitPerShare;
    uint256 private emptyStakeTokens; //These are tokens given to the contract when there are no stakers.

    IStakeHandler[] public stakeHandlers;
    uint256 public startTime;

    uint256 public registrationFeeWithReferrer;
    uint256 public registrationFeeWithoutReferrer;
    mapping(address => uint256) public accountReferrals;
    mapping(address => bool) public stakerIsRegistered;

    event OnDistribute(address sender, uint256 amountSent);
    event OnStake(address sender, uint256 amount, uint256 tax);
    event OnUnstake(address sender, uint256 amount, uint256 tax);
    event OnReinvest(address sender, uint256 amount, uint256 tax);
    event OnWithdraw(address sender, uint256 amount);

    modifier onlyLidToken {
        require(
            msg.sender == address(lidToken),
            "Can only be called by LidToken contract."
        );
        _;
    }

    modifier whenStakingActive {
        require(startTime != 0 && now > startTime, "Staking not yet started.");
        _;
    }

    function initialize(
        uint256 _stakingTaxBP,
        uint256 _ustakingTaxBP,
        uint256 _registrationFeeWithReferrer,
        uint256 _registrationFeeWithoutReferrer,
        address owner,
        ILidCertifiableToken _lidToken
    ) external initializer {
        Ownable.initialize(msg.sender);
        stakingTaxBP = _stakingTaxBP;
        unstakingTaxBP = _ustakingTaxBP;
        lidToken = _lidToken;
        registrationFeeWithReferrer = _registrationFeeWithReferrer;
        registrationFeeWithoutReferrer = _registrationFeeWithoutReferrer;
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function registerAndStake(uint256 amount) public {
        registerAndStake(amount, address(0x0));
    }

    function registerAndStake(uint256 amount, address referrer)
        public
        whenStakingActive
    {
        require(
            !stakerIsRegistered[msg.sender],
            "Staker must not be registered"
        );
        require(
            lidToken.balanceOf(msg.sender) >= amount,
            "Must have enough balance to stake amount"
        );
        uint256 finalAmount;
        if (address(0x0) == referrer) {
            //No referrer
            require(
                amount >= registrationFeeWithoutReferrer,
                "Must send at least enough LID to pay registration fee."
            );
            distribute(registrationFeeWithoutReferrer);
            finalAmount = amount.sub(registrationFeeWithoutReferrer);
        } else {
            //has referrer
            require(
                amount >= registrationFeeWithReferrer,
                "Must send at least enough LID to pay registration fee."
            );
            require(
                lidToken.transferFrom(
                    msg.sender,
                    referrer,
                    registrationFeeWithReferrer
                ),
                "Stake failed due to failed referral transfer."
            );
            accountReferrals[referrer] = accountReferrals[referrer].add(1);
            finalAmount = amount.sub(registrationFeeWithReferrer);
        }
        stakerIsRegistered[msg.sender] = true;
        stake(finalAmount);
    }

    function stake(uint256 amount) public whenStakingActive {
        require(
            stakerIsRegistered[msg.sender] == true,
            "Must be registered to stake."
        );
        require(amount >= 1e18, "Must stake at least one LID.");
        require(
            lidToken.balanceOf(msg.sender) >= amount,
            "Cannot stake more LID than you hold unstaked."
        );
        if (stakeValue[msg.sender] == 0) totalStakers = totalStakers.add(1);
        uint256 tax = _addStake(amount);
        require(
            lidToken.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );
        emit OnStake(msg.sender, amount, tax);
    }

    function unstake(uint256 amount) external whenStakingActive {
        require(amount >= 1e18, "Must unstake at least one LID.");
        require(
            stakeValue[msg.sender] >= amount,
            "Cannot unstake more LID than you have staked."
        );
        uint256 tax = findTaxAmount(amount, unstakingTaxBP);
        uint256 earnings = amount.sub(tax);
        if (stakeValue[msg.sender] == amount)
            totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].sub(amount);
        uint256 payout =
            profitPerShare.mul(amount).add(tax.mul(DISTRIBUTION_MULTIPLIER));
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] -
            uintToInt(payout);
        for (uint256 i = 0; i < stakeHandlers.length; i++) {
            stakeHandlers[i].handleUnstake(
                msg.sender,
                amount,
                stakeValue[msg.sender]
            );
        }
        _increaseProfitPerShare(tax);
        require(
            lidToken.transferFrom(address(this), msg.sender, earnings),
            "Unstake failed due to failed transfer."
        );
        emit OnUnstake(msg.sender, amount, tax);
    }

    function withdraw(uint256 amount) external whenStakingActive {
        require(
            dividendsOf(msg.sender) >= amount,
            "Cannot withdraw more dividends than you have earned."
        );
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            uintToInt(amount.mul(DISTRIBUTION_MULTIPLIER));
        lidToken.transfer(msg.sender, amount);
        emit OnWithdraw(msg.sender, amount);
    }

    function reinvest(uint256 amount) external whenStakingActive {
        require(
            dividendsOf(msg.sender) >= amount,
            "Cannot reinvest more dividends than you have earned."
        );
        uint256 payout = amount.mul(DISTRIBUTION_MULTIPLIER);
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            uintToInt(payout);
        uint256 tax = _addStake(amount);
        emit OnReinvest(msg.sender, amount, tax);
    }

    function distribute(uint256 amount) public {
        require(
            lidToken.balanceOf(msg.sender) >= amount,
            "Cannot distribute more LID than you hold unstaked."
        );
        totalDistributions = totalDistributions.add(amount);
        _increaseProfitPerShare(amount);
        require(
            lidToken.transferFrom(msg.sender, address(this), amount),
            "Distribution failed due to failed transfer."
        );
        emit OnDistribute(msg.sender, amount);
    }

    function handleTaxDistribution(uint256 amount) external onlyLidToken {
        totalDistributions = totalDistributions.add(amount);
        _increaseProfitPerShare(amount);
        emit OnDistribute(msg.sender, amount);
    }

    function dividendsOf(address staker) public view returns (uint256) {
        return
            uint256(
                uintToInt(profitPerShare.mul(stakeValue[staker])) -
                    stakerPayouts[staker]
            )
                .div(DISTRIBUTION_MULTIPLIER);
    }

    function findTaxAmount(uint256 value, uint256 taxBP)
        public
        pure
        returns (uint256)
    {
        return value.mulBP(taxBP);
    }

    function numberStakeHandlersRegistered() external view returns (uint256) {
        return stakeHandlers.length;
    }

    function registerStakeHandler(IStakeHandler sc) external onlyOwner {
        stakeHandlers.push(sc);
    }

    function unregisterStakeHandler(uint256 index) external onlyOwner {
        IStakeHandler sc = stakeHandlers[stakeHandlers.length - 1];
        stakeHandlers.pop();
        stakeHandlers[index] = sc;
    }

    function setStakingBP(uint256 valueBP) external onlyOwner {
        require(valueBP < 10000, "Tax connot be over 100% (10000 BP)");
        stakingTaxBP = valueBP;
    }

    function setUnstakingBP(uint256 valueBP) external onlyOwner {
        require(valueBP < 10000, "Tax connot be over 100% (10000 BP)");
        unstakingTaxBP = valueBP;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setRegistrationFees(
        uint256 valueWithReferrer,
        uint256 valueWithoutReferrer
    ) external onlyOwner {
        registrationFeeWithReferrer = valueWithReferrer;
        registrationFeeWithoutReferrer = valueWithoutReferrer;
    }

    function uintToInt(uint256 val) internal pure returns (int256) {
        if (val >= uint256(-1).div(2)) {
            require(false, "Overflow. Cannot convert uint to int.");
        } else {
            return int256(val);
        }
    }

    function _addStake(uint256 amount) internal returns (uint256 tax) {
        tax = findTaxAmount(amount, stakingTaxBP);
        uint256 stakeAmount = amount.sub(tax);
        totalStaked = totalStaked.add(stakeAmount);
        stakeValue[msg.sender] = stakeValue[msg.sender].add(stakeAmount);
        for (uint256 i = 0; i < stakeHandlers.length; i++) {
            stakeHandlers[i].handleStake(
                msg.sender,
                stakeAmount,
                stakeValue[msg.sender]
            );
        }
        uint256 payout = profitPerShare.mul(stakeAmount);
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            uintToInt(payout);
        _increaseProfitPerShare(tax);
    }

    function _increaseProfitPerShare(uint256 amount) internal {
        if (totalStaked != 0) {
            if (emptyStakeTokens != 0) {
                amount = amount.add(emptyStakeTokens);
                emptyStakeTokens = 0;
            }
            profitPerShare = profitPerShare.add(
                amount.mul(DISTRIBUTION_MULTIPLIER).div(totalStaked)
            );
        } else {
            emptyStakeTokens = emptyStakeTokens.add(amount);
        }
    }
}

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
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }

    uint256[50] private ______gap;
}

// File: contracts\uniswapV2Periphery\interfaces\IUniswapV2Router01.sol

pragma solidity =0.5.16;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract LidCertifiedPresaleTimer is Initializable, Ownable {
    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public baseTimer;
    uint256 public deltaTimer;

    function initialize(
        uint256 _startTime,
        uint256 _baseTimer,
        uint256 _deltaTimer,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);
        startTime = _startTime;
        baseTimer = _baseTimer;
        deltaTimer = _deltaTimer;
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function setStartTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function isStarted() external view returns (bool) {
        return (startTime != 0 && now > startTime);
    }

    function getEndTime(uint256 bal) external view returns (uint256) {
        uint256 multiplier = 0;
        if (bal <= 1000 ether) {
            multiplier = bal.div(100 ether);
        } else if (bal <= 10000 ether) {
            multiplier = bal.div(1000 ether).add(9);
        } else if (bal <= 100000 ether) {
            multiplier = bal.div(10000 ether).add(19);
        } else if (bal <= 1000000 ether) {
            multiplier = bal.div(100000 ether).add(29);
        } else if (bal <= 10000000 ether) {
            multiplier = bal.div(1000000 ether).add(39);
        } else if (bal <= 100000000 ether) {
            multiplier = bal.div(10000000 ether).add(49);
        }
        return startTime.add(baseTimer).add(deltaTimer.mul(multiplier));
    }
}

contract LidCertifiedPresale is Initializable, Ownable, ReentrancyGuard {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public maxBuyPerAddressBase;
    uint256 public maxBuyPerAddressBP;
    uint256 public maxBuyWithoutWhitelisting;

    uint256 public redeemBP;
    uint256 public redeemInterval;

    uint256 public referralBP;

    uint256 public uniswapEthBP;
    address payable[] public etherPools;
    uint256[] public etherPoolBPs;

    uint256 public uniswapTokenBP;
    uint256 public presaleTokenBP;
    address[] public tokenPools;
    uint256[] public tokenPoolBPs;

    uint256 public startingPrice;
    uint256 public multiplierPrice;

    bool public hasSentToUniswap;
    bool public hasIssuedTokens;
    bool public hasSentEther;

    uint256 public totalTokens;
    uint256 private totalEth;
    uint256 public finalEndTime;

    ILidCertifiableToken private token;
    IUniswapV2Router01 private uniswapRouter;
    LidCertifiedPresaleTimer private timer;

    mapping(address => uint256) public depositAccounts;
    mapping(address => uint256) public accountEarnedLid;
    mapping(address => uint256) public accountClaimedLid;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public earnedReferrals;

    uint256 public totalDepositors;
    mapping(address => uint256) public referralCounts;

    uint256 lidRepaired;
    bool pauseDeposit;

    mapping(address => bool) public isRepaired;

    modifier whenPresaleActive {
        require(timer.isStarted(), "Presale not yet started.");
        require(!_isPresaleEnded(), "Presale has ended.");
        _;
    }

    modifier whenPresaleFinished {
        require(timer.isStarted(), "Presale not yet started.");
        require(_isPresaleEnded(), "Presale has not yet ended.");
        _;
    }

    function initialize(
        uint256 _maxBuyPerAddressBase,
        uint256 _maxBuyPerAddressBP,
        uint256 _maxBuyWithoutWhitelisting,
        uint256 _redeemBP,
        uint256 _redeemInterval,
        uint256 _referralBP,
        uint256 _startingPrice,
        uint256 _multiplierPrice,
        address owner,
        LidCertifiedPresaleTimer _timer,
        ILidCertifiableToken _token
    ) external initializer {
        require(_token.isMinter(address(this)), "Presale SC must be minter.");
        Ownable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = _token;
        timer = _timer;

        maxBuyPerAddressBase = _maxBuyPerAddressBase;
        maxBuyPerAddressBP = _maxBuyPerAddressBP;
        maxBuyWithoutWhitelisting = _maxBuyWithoutWhitelisting;

        redeemBP = _redeemBP;

        referralBP = _referralBP;
        redeemInterval = _redeemInterval;

        startingPrice = _startingPrice;
        multiplierPrice = _multiplierPrice;

        uniswapRouter = IUniswapV2Router01(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function deposit() external payable {
        deposit(address(0x0));
    }

    function setEtherPools(
        address payable[] calldata _etherPools,
        uint256[] calldata _etherPoolBPs
    ) external onlyOwner {
        require(
            _etherPools.length == _etherPoolBPs.length,
            "Must have exactly one etherPool addresses for each BP."
        );
        delete etherPools;
        delete etherPoolBPs;
        uniswapEthBP = 7500; //75%
        for (uint256 i = 0; i < _etherPools.length; ++i) {
            etherPools.push(_etherPools[i]);
        }
        uint256 totalEtherPoolsBP = uniswapEthBP;
        for (uint256 i = 0; i < _etherPoolBPs.length; ++i) {
            etherPoolBPs.push(_etherPoolBPs[i]);
            totalEtherPoolsBP = totalEtherPoolsBP.add(_etherPoolBPs[i]);
        }
        require(
            totalEtherPoolsBP == 10000,
            "Must allocate exactly 100% (10000 BP) of ether to pools"
        );
    }

    function setTokenPools(
        address[] calldata _tokenPools,
        uint256[] calldata _tokenPoolBPs
    ) external onlyOwner {
        require(
            _tokenPools.length == _tokenPoolBPs.length,
            "Must have exactly one tokenPool addresses for each BP."
        );
        delete tokenPools;
        delete tokenPoolBPs;
        uniswapTokenBP = 1600;
        presaleTokenBP = 4000;
        for (uint256 i = 0; i < _tokenPools.length; ++i) {
            tokenPools.push(_tokenPools[i]);
        }
        uint256 totalTokenPoolBPs = uniswapTokenBP.add(presaleTokenBP);
        for (uint256 i = 0; i < _tokenPoolBPs.length; ++i) {
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(
            totalTokenPoolBPs == 10000,
            "Must allocate exactly 100% (10000 BP) of tokens to pools"
        );
    }

    function sendToUniswap() external whenPresaleFinished nonReentrant {
        require(etherPools.length > 0, "Must have set ether pools");
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToUniswap, "Has already sent to Uniswap.");
        finalEndTime = now;
        hasSentToUniswap = true;
        totalTokens = totalTokens.divBP(presaleTokenBP);
        uint256 uniswapTokens = totalTokens.mulBP(uniswapTokenBP);
        totalEth = address(this).balance;
        uint256 uniswapEth = totalEth.mulBP(uniswapEthBP);
        token.mint(address(this), uniswapTokens);
        token.activateTransfers();
        token.approve(address(uniswapRouter), uniswapTokens);
        uniswapRouter.addLiquidityETH.value(uniswapEth)(
            address(token),
            uniswapTokens,
            uniswapTokens,
            uniswapEth,
            address(0x000000000000000000000000000000000000dEaD),
            now
        );
    }

    function issueTokens() external whenPresaleFinished {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        for (uint256 i = 0; i < tokenPools.length; ++i) {
            token.mint(tokenPools[i], totalTokens.mulBP(tokenPoolBPs[i]));
        }
    }

    function sendEther() external whenPresaleFinished nonReentrant {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasSentEther, "Has already sent ether.");
        hasSentEther = true;
        for (uint256 i = 0; i < etherPools.length; ++i) {
            etherPools[i].transfer(totalEth.mulBP(etherPoolBPs[i]));
        }
        //remove dust
        if (address(this).balance > 0) {
            etherPools[0].transfer(address(this).balance);
        }
    }

    function emergencyEthWithdrawl()
        external
        whenPresaleFinished
        nonReentrant
        onlyOwner
    {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        msg.sender.transfer(address(this).balance);
    }

    function setDepositPause(bool val) external onlyOwner {
        pauseDeposit = val;
    }

    function setWhitelist(address account, bool value) external onlyOwner {
        whitelist[account] = value;
    }

    function setWhitelistForAll(address[] calldata account, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < account.length; i++) {
            whitelist[account[i]] = value;
        }
    }

    function redeem() external whenPresaleFinished {
        require(
            hasSentToUniswap,
            "Must have sent to Uniswap before any redeems."
        );
        uint256 claimable = calculateReedemable(msg.sender);
        accountClaimedLid[msg.sender] = accountClaimedLid[msg.sender].add(
            claimable
        );
        token.mint(msg.sender, claimable);
    }

    function deposit(address payable referrer)
        public
        payable
        whenPresaleActive
        nonReentrant
    {
        require(!pauseDeposit, "Deposits are paused.");
        if (whitelist[msg.sender]) {
            require(
                depositAccounts[msg.sender].add(msg.value) <=
                    getMaxWhitelistedDeposit(
                        address(this).balance.sub(msg.value)
                    ),
                "Deposit exceeds max buy per address for whitelisted addresses."
            );
        } else {
            require(
                depositAccounts[msg.sender].add(msg.value) <=
                    maxBuyWithoutWhitelisting,
                "Deposit exceeds max buy per address for non-whitelisted addresses."
            );
        }

        require(msg.value > 0.01 ether, "Must purchase at least 0.01 ether.");

        if (depositAccounts[msg.sender] == 0)
            totalDepositors = totalDepositors.add(1);

        uint256 depositVal = msg.value.subBP(referralBP);
        uint256 tokensToIssue =
            depositVal.mul(10**18).div(calculateRatePerEth());
        depositAccounts[msg.sender] = depositAccounts[msg.sender].add(
            depositVal
        );

        totalTokens = totalTokens.add(tokensToIssue);

        accountEarnedLid[msg.sender] = accountEarnedLid[msg.sender].add(
            tokensToIssue
        );

        if (referrer != address(0x0) && referrer != msg.sender) {
            uint256 referralValue = msg.value.sub(depositVal);
            earnedReferrals[referrer] = earnedReferrals[referrer].add(
                referralValue
            );
            referralCounts[referrer] = referralCounts[referrer].add(1);
            referrer.transfer(referralValue);
        }
    }

    function calculateReedemable(address account)
        public
        view
        returns (uint256)
    {
        if (finalEndTime == 0) return 0;
        uint256 earnedLid = accountEarnedLid[account];
        uint256 claimedLid = accountClaimedLid[account];
        uint256 cycles = now.sub(finalEndTime).div(redeemInterval).add(1);
        uint256 totalRedeemable = earnedLid.mulBP(redeemBP).mul(cycles);
        uint256 claimable;
        if (totalRedeemable >= earnedLid) {
            claimable = earnedLid.sub(claimedLid);
        } else {
            claimable = totalRedeemable.sub(claimedLid);
        }
        return claimable;
    }

    function calculateRatePerEth() public view returns (uint256) {
        return totalTokens.div(10**18).mul(multiplierPrice).add(startingPrice);
    }

    function getMaxWhitelistedDeposit(uint256 atTotalDeposited)
        public
        view
        returns (uint256)
    {
        return
            atTotalDeposited.mulBP(maxBuyPerAddressBP).add(
                maxBuyPerAddressBase
            );
    }

    function _isPresaleEnded() internal view returns (bool) {
        return (
            (timer.isStarted() &&
                (now > timer.getEndTime(address(this).balance)))
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.5.16;

// Copyright (C) udev 2020

interface IXEth {
    function deposit() external payable;

    function xlockerMint(uint256 wad, address dst) external;

    function withdraw(uint256 wad) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts\LidToken.sol

pragma solidity 0.5.16;

contract LidToken is
    Initializable,
    ERC20Burnable,
    ERC20Mintable,
    ERC20Pausable,
    ERC20Detailed,
    Ownable
{
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public taxBP;
    uint256 public daoTaxBP;
    address private daoFund;
    LidStaking private lidStaking;
    LidCertifiedPresale private lidPresale;

    bool public isTaxActive;
    bool public isTransfersActive;

    mapping(address => bool) private trustedContracts;
    mapping(address => bool) public taxExempt;
    mapping(address => bool) public fromOnlyTaxExempt;
    mapping(address => bool) public toOnlyTaxExempt;

    string private _name;

    modifier onlyPresaleContract() {
        require(
            msg.sender == address(lidPresale),
            "Can only be called by presale sc."
        );
        _;
    }

    function() external payable {}

    function initialize(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address owner,
        uint256 _taxBP,
        uint256 _daoTaxBP,
        address _daoFund,
        LidStaking _lidStaking,
        LidCertifiedPresale _lidPresale
    ) external initializer {
        taxBP = _taxBP;
        daoTaxBP = _daoTaxBP;

        Ownable.initialize(msg.sender);

        ERC20Detailed.initialize(name, symbol, decimals);

        ERC20Mintable.initialize(address(this));
        _removeMinter(address(this));
        _addMinter(owner);

        ERC20Pausable.initialize(address(this));
        _removePauser(address(this));
        _addPauser(owner);

        daoFund = _daoFund;
        lidStaking = _lidStaking;
        addTrustedContract(address(_lidStaking));
        addTrustedContract(address(_lidPresale));
        setTaxExemptStatus(address(_lidStaking), true);
        setTaxExemptStatus(address(_lidPresale), true);
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function refundToken(
        IERC20 token,
        address to,
        uint256 wad
    ) external onlyOwner {
        token.transfer(to, wad);
    }

    function xethLiqTransfer(
        IUniswapV2Router01 router,
        address pair,
        IXEth xeth,
        uint256 minWadExpected
    ) external onlyOwner {
        isTaxActive = false;
        uint256 lidLiqWad = balanceOf(pair).sub(1 ether);
        _transfer(pair, address(lidStaking), lidLiqWad);
        approve(address(router), lidLiqWad);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETH(
            lidLiqWad,
            minWadExpected,
            path,
            address(this),
            now
        );
        _transfer(pair, address(lidStaking), lidLiqWad);
        xeth.deposit.value(address(this).balance)();
        require(
            xeth.balanceOf(address(this)) >= minWadExpected,
            "Less xeth than expected."
        );

        router.addLiquidity(
            address(this),
            address(xeth),
            lidLiqWad,
            xeth.balanceOf(address(this)),
            lidLiqWad,
            xeth.balanceOf(address(this)),
            address(0x0),
            now
        );

        isTaxActive = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(isTransfersActive, "Transfers are currently locked.");
        (isTaxActive &&
            !taxExempt[msg.sender] &&
            !taxExempt[recipient] &&
            !toOnlyTaxExempt[recipient] &&
            !fromOnlyTaxExempt[msg.sender])
            ? _transferWithTax(msg.sender, recipient, amount)
            : _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(isTransfersActive, "Transfers are currently locked.");
        (isTaxActive &&
            !taxExempt[sender] &&
            !taxExempt[recipient] &&
            !toOnlyTaxExempt[recipient] &&
            !fromOnlyTaxExempt[sender])
            ? _transferWithTax(sender, recipient, amount)
            : _transfer(sender, recipient, amount);
        if (trustedContracts[msg.sender]) return true;
        approve(
            msg.sender,
            allowance(sender, msg.sender).sub(
                amount,
                "Transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function addTrustedContract(address contractAddress) public onlyOwner {
        trustedContracts[contractAddress] = true;
    }

    function setTaxExemptStatus(address account, bool status) public onlyOwner {
        taxExempt[account] = status;
    }

    function findTaxAmount(uint256 value)
        public
        view
        returns (uint256 tax, uint256 daoTax)
    {
        tax = value.mulBP(taxBP);
        daoTax = value.mulBP(daoTaxBP);
    }

    function _transferWithTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        (uint256 tax, uint256 daoTax) = findTaxAmount(amount);
        uint256 tokensToTransfer = amount.sub(tax).sub(daoTax);

        _transfer(sender, address(lidStaking), tax);
        _transfer(sender, address(daoFund), daoTax);
        _transfer(sender, recipient, tokensToTransfer);
        lidStaking.handleTaxDistribution(tax);
    }
}