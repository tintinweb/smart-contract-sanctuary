// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function allowance(address owner, address spender) public view returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
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
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Capped.sol

pragma solidity ^0.5.0;


/**
 * @dev Extension of {ERC20Mintable} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
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
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/TokenVesting.sol

// Token Vesting Contract
// Copyright (C) 2019  NYM Technologies SA
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.17;





/**
 * @title Nym Token Vesting Contract
 * @notice Contract to manage the vesting of tokens and their release for a given set of beneficiaries.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Address of the token contract used in the vesting
  address internal mTokenContract;
  // Number of release periods
  uint256 internal mPeriodsCount;
  // Amount of vested tokens overall
  uint256 internal mTotalVested;
  // Amount of tokens currently vested (which have not been released)
  uint256 internal mCurrentVested;
  // Indicates if beneficiaries are locked (true) or can still be modified (false)
  bool internal mBeneficiariesLocked;
  // Indicates if the vested tokens are locked (true) or can still be withdrawn (false)
  bool internal mTokensLocked;
  // List of release dates for each period in order
  uint256[] internal mReleaseDates;

  // Period count mapped to release timestamp
  mapping(uint256 => uint256) internal mVestReleaseDate;
  // Beneficiary mapped to per period release amount
  mapping(address => uint256) internal mVestReleaseAmount;
  // Already executed claims
  mapping(address => mapping(uint256 => bool)) internal mVestingClaims;

  /**
   * @notice Indicate the addition of a new beneficiary to the vesting
   * @param beneficiary Address of the new beneficiary
   * @param releaseAmount Number of tokens to be release at each period for the beneficiary
   */
  event BeneficiaryAdded(address indexed beneficiary, uint256 releaseAmount);
  /**
   * @notice Indicate the removal of an existing beneficiary to the vesting
   * @param beneficiary Address of the former beneficiary
   * @param releaseAmount Number of tokens which would have been released at each period for the beneficiary
   */
  event BeneficiaryRemoved(address indexed beneficiary, uint256 releaseAmount);
  /**
   * @notice Indicate the claim of tokens by a beneficiary
   * @param owner Address of the beneficiary which now the owner of the tokens
   * @param amount Number of tokens claimed this instance by the beneficiary
   */
  event TokensClaimed(address indexed owner, uint256 amount);

  /**
   * @notice Constructor to create a vesting schedule for a given token
   * @param _tokenContract Address of the token used for the vesting
   * @param _releaseDates List of timestamps representing the release time of each vesting period
   */
  constructor(address _tokenContract, uint256[] memory _releaseDates) public {
    require(_releaseDates.length > 0, "There must be at least 1 release date");
    require(_releaseDates[0] > block.timestamp + 3600, "Release dates must be at least 1h the future");

    mTokenContract = _tokenContract;
    mPeriodsCount = _releaseDates.length;

    mVestReleaseDate[0] = _releaseDates[0];
    for (uint256 i = 1; i < _releaseDates.length; i++) {
      require(
        _releaseDates[i] > _releaseDates[i - 1],
        "Release dates should be in strictly ascending order"
      );
      mVestReleaseDate[i] = _releaseDates[i];
    }
    mReleaseDates = _releaseDates;
    mTotalVested = 0;
    mCurrentVested = 0;
    mBeneficiariesLocked = false;
    mTokensLocked = false;
  }

  /**
   * @notice Token contract used in the vesting
   * @return Address of the token contract
   */
  function tokenContract() external view returns (address) {
    return mTokenContract;
  }

  /**
   * @notice Number of release periods
   * @return Number of release periods
   */
  function periodsCount() external view returns (uint256) {
    return mPeriodsCount;
  }

  /**
   * @notice Quantity of vested tokens overall
   * @return Amount of vested tokens
   */
  function totalVested() external view returns (uint256) {
    return mTotalVested;
  }

  /**
   * @notice Quantity of tokens currently vested (which have not been released)
   * @return Amount of currently vested tokens
   */
  function currentVested() external view returns (uint256) {
    return mCurrentVested;
  }

  /**
   * @notice Indicates if beneficiaries are locked or can still be modified
   * @return True if beneficiaries are locked, false if they are unlocked
   */
  function beneficiariesLocked() external view returns (bool) {
    return mBeneficiariesLocked;
  }

  /**
   * @notice Indicates if the vested tokens are locked or can still be withdrawn
   * @return True if tokens are locked, false if they are unlocked
   */
  function tokensLocked() external view returns (bool) {
    return mTokensLocked;
  }

  /**
   * @notice List of release dates for each period in order
   * @return Array of release dates, as number of seconds since January 1, 1970, 00:00:00 UTC
   */
  function releaseDates() external view returns (uint256[] memory) {
    return mReleaseDates;
  }

  /**
   * @notice Get the release date of a period
   * @param _period Period number (zero-based indexing)
   * @return Release date as a timestamp
   */
  function releaseDate(uint256 _period) external view returns (uint256) {
    return mVestReleaseDate[_period];
  }

  /**
   * @notice Get the amount released per period for the given beneficiary
   * @param _beneficiary Address of the beneficiary
   * @return Amount of tokens released for the beneficiary for each period
   */
  function releaseAmount(address _beneficiary) external view returns (uint256) {
    return mVestReleaseAmount[_beneficiary];
  }

  /**
   * @notice Get the release status for a given beneficiary and period
   * @param _beneficiary Address of the beneficiary
   * @param _period Period number (zero-based indexing)
   * @return True if the tokens were claimed by the beneficiary, false otherwise
   */
  function isReleased(address _beneficiary, uint256 _period) external view returns (bool) {
    return mVestingClaims[_beneficiary][_period];
  }

  /**
   * @notice Locks beneficiaries in place
   * @dev Once this function is called, beneficiaries cannot be added or removed. This cannot be undone.
   * This function can only be called once. It must be called before calling the lockTokens() function,
   * and before the first release period.
   */
  function lockBeneficiaries() external onlyOwner {
    require(!mBeneficiariesLocked, "Already locked");
    require(block.timestamp < mReleaseDates[0], "Cannot lock beneficiaries late");
    require(mTotalVested > 0, "No beneficiaries present");
    mBeneficiariesLocked = true;
  }

  /**
   * @notice Locks vested tokens in the contract
   * @dev Once this function is called, the amount of vested tokens cannot be transferred. This cannot be undone.
   * This function can only be called once. It must be called after calling the lockTokens() function,
   * and before the first release period. Excess tokens can be withdrawn at any time. The contract must have a balance
   * of at least as much as totalVested for this function to succeed.
   */
  function lockTokens() external onlyOwner {
    require(!mTokensLocked, "Already locked");
    require(mBeneficiariesLocked, "Beneficiaries are not locked");
    require(block.timestamp < mReleaseDates[0], "Cannot lock tokens late");
    uint256 balance = IERC20(mTokenContract).balanceOf(address(this));
    require(balance >= mTotalVested, "Balance must equal to or greater than the total vested amount");
    mCurrentVested = mTotalVested;
    mTokensLocked = true;
  }

  /**
   * @notice Add a beneficiary
   * @param _beneficiary The address who will eventually receive the tokens
   * @param _releaseAmount The amount of tokens released for each period, which can be claimed by the beneficiary
   * @dev This function will revert if called after startVesting() was called
   */
  function addBeneficiary(address _beneficiary, uint256 _releaseAmount) external onlyOwner {
    require(_beneficiary != address(0), "Beneficiary cannot be the zero-address");
    require(_beneficiary != address(this), "Beneficiary cannot be this vesting contract");
    require(_beneficiary != mTokenContract, "Beneficiary cannot be the token contract");
    require(mVestReleaseAmount[_beneficiary] == 0, "Beneficiary already exists");
    require(_releaseAmount != 0, "Vesting amount cannot be zero");
    require(!mBeneficiariesLocked, "Beneficiaries locked, cannot be added");

    mVestReleaseAmount[_beneficiary] = _releaseAmount;
    mTotalVested = mTotalVested.add(_releaseAmount.mul(mPeriodsCount));

    emit BeneficiaryAdded(_beneficiary, _releaseAmount);
  }

  /**
  * @notice Remove a beneficiary
  * @param _beneficiary The address of the beneficiary to remove
  * @dev This function will revert if called after startVesting() was called
  */
  function removeBeneficiary(address _beneficiary) external onlyOwner {
    require(_beneficiary != address(0), "Beneficiary cannot be the zero-address");
    require(_beneficiary != address(this), "Beneficiary cannot be this vesting contract");
    require(_beneficiary != mTokenContract, "Beneficiary cannot be the token contract");
    require(mVestReleaseAmount[_beneficiary] != 0, "Not a beneficiary");
    require(!mBeneficiariesLocked, "Beneficiaries locked, cannot be removed");

    uint256 beneficiaryReleaseAmount = mVestReleaseAmount[_beneficiary];
    mTotalVested = mTotalVested.sub(beneficiaryReleaseAmount.mul(mPeriodsCount));
    mVestReleaseAmount[_beneficiary] = 0;

    emit BeneficiaryRemoved(_beneficiary, beneficiaryReleaseAmount);
  }

  /**
   * @notice Allows the owner to withdraw uncommitted tokens (anything in excess of currentVested)
   * @param _amount Amount to withdraw
   */
  function withdraw(uint256 _amount) external onlyOwner {
    uint256 balance = IERC20(mTokenContract).balanceOf(address(this));
    uint256 freeBalance = balance.sub(mCurrentVested);
    require(_amount <= freeBalance, "Insufficient balance of non-vested tokens");
    IERC20(mTokenContract).safeTransfer(owner(), _amount);
  }

  /**
   * @notice Withdraw other tokens the contract may hold, such as tokens from airdrops
   * @param _tokenContract Address of the token contract to transfer
   * @param _dumpSite Address where to dump the tokens
   * @param _amount Amount of tokens to drain
   */
  function withdrawNonTokens(address _tokenContract, address _dumpSite, uint256 _amount) external onlyOwner {
    require(_tokenContract != mTokenContract, "Cannot withdraw vested tokens");
    IERC20(_tokenContract).safeTransfer(_dumpSite, _amount);
  }

  /**
   * @notice Withdraw any ether this contract may hold
   * @param _dumpSite Address where to transfer the ether
   * @param _amount Amount to transfer, in wei
   */
  function withdrawETH(address payable _dumpSite, uint256 _amount) external onlyOwner {
    _dumpSite.transfer(_amount);
  }

  /**
   * @notice Claim and transfer tokens on behalf of a beneficiary
   * @param _beneficiary Address of the beneficiary (which will receive the tokens)
   * @param _period Period number (zero-based indexing) for which to claim the tokens
   */
  function adminSendTokens(address _beneficiary, uint256 _period) external onlyOwner {
    processTokenClaim(_beneficiary, _period);
  }

  /**
   * @notice Directly claim tokens as a beneficiary from the contract
   * @param _period Period number (zero-based indexing) for which to claim the tokens
   */
  function claimTokens(uint256 _period) external {
    processTokenClaim(msg.sender, _period);
  }

  /**
   * @notice Process a claim to send tokens to the given beneficiary for the given period.
   * @param _beneficiary The address for which to process the claim
   * @param _period The period of the claim to process
   * @dev Internal function to be used every time a claim needs to be processed.
   * The lockBeneficiaries() & lockTokens() functions must be called once first for claims to be processed.
   * Only tokensLocked is checked, not beneficiariesLocked as for tokensLocked to be true, beneficiariesLocked also
   * has to be true.
   */
  function processTokenClaim(address _beneficiary, uint256 _period) internal {
    require(mTokensLocked, "Vesting has not started");
    require(mVestReleaseDate[_period] > 0, "Period does not exist");
    require(
      mVestReleaseDate[_period] < block.timestamp,
      "Release date of given period has not been reached yet."
      );
    require(mVestingClaims[_beneficiary][_period] == false, "Vesting has already been claimed");

    mVestingClaims[_beneficiary][_period] = true;

    mCurrentVested = mCurrentVested.sub(mVestReleaseAmount[_beneficiary]);
    IERC20(mTokenContract).safeTransfer(_beneficiary, mVestReleaseAmount[_beneficiary]);

    emit TokensClaimed(_beneficiary, mVestReleaseAmount[_beneficiary]);
  }

}

// File: contracts/NymToken.sol

// NYM Token Contract
// Copyright (C) 2019  NYM Technologies SA
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.5.17;




/**
 * @title Nym Token (NYM)
 * @notice Implementation of OpenZepplin's ERC20Capped and ERC20Detailed Token with custom burn.
 */
contract NymToken is ERC20Capped, ERC20Detailed {
    constructor ()
    public
    ERC20Capped(1000000000*10**18)
    ERC20Detailed("Nym Token", "NYMPH", 18)
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Overload OpenZepplin internal _transfer() function to add extra require statement preventing
     * transferring tokens to the contract address
     * @param _sender The senders address
     * @param _recipient The recipients address
     * @param _amount Amount of tokens to transfer (in wei units)
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Additional requirements:
     *
     * - `_recipient` cannot be the token contract address.
     */
    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_recipient != address(this), "NymToken: transfer to token contract address");
        super._transfer(_sender, _recipient, _amount);
    }

    /**
     * @notice Overload OpenZepplin internal _mint() function to add extra require statement preventing
     * minting tokens to the contract address
     * @param _account The address for which to mint tokens (must be MinterRolle)
     * @param _amount Amount of tokens to mint (in wei units)
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Additional requirements:
     *
     * - `_account` cannot be the token contract address.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(this), "NymToken: mint to token contract address");
        super._mint(_account, _amount);
    }

    /**
     * @notice Mint the necessary amount of tokens for a vesting contract.
     * @param _vestingContract Address fo the vesting contract for which to mint the tokens
     * @dev Only a minter can call this function. It must be called between locking the beneficiaries and the tokens.
     * If there are many vesting contracts and/or many beneficiaries with large vested amounts, which result overall
     * in a vested amount greater than the cap of the token, minting for vesting contracts may fail.
     * Checking currentVested is not needed as this function can only successfully be called between locking
     * beneficiaries and locking tokens. At this stage, currentVested is 0, and beneficiaries cannot withdraw any
     * tokens.
     */
    function mintForVesting(TokenVesting _vestingContract) public onlyMinter {
        require(_vestingContract.beneficiariesLocked(), "Beneficiaries are unlocked");
        require(!_vestingContract.tokensLocked(), "Tokens are locked");
        uint256 balance = balanceOf(address (_vestingContract));
        uint256 totalVested = _vestingContract.totalVested();
        uint256 mintAmount = totalVested.sub(balance);
        require(mintAmount > 0, "No vesting tokens to be minted");
        _mint(address(_vestingContract), mintAmount);
    }

    /**
     * @notice Burn the nessecary amount of tokens.
     * @param _amount Amount of tokens (in wei units)
     * @dev Destroys `amount` tokens from the caller. Only a minter can call this function.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _amount) public onlyMinter {
        _burn(msg.sender, _amount);
    }
}