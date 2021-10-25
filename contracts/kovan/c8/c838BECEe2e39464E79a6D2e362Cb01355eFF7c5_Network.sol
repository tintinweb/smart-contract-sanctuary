/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * Requirements:
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
     * Requirements:
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
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
}

// File: @openzeppelin\contracts\utils\Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
    constructor () internal {
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

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// File: contracts\utils\Governed.sol

pragma solidity >=0.6.0;


/**
 * @title Governed
 * @dev The Governable contract has an governor smart contract address, and provides basic authorization control
 * functions, this simplifies the implementation of "gov permissions".
 */
contract Governed {
    address public _proposedGovernor;
    address public _governor;
    event GovernorTransferred(address indexed previousGovernor, address indexed newGovernor);


    /**
    * @dev The Ownable constructor sets the original `governor` of the contract to the sender
    * account.
    */
    constructor() public {
        _governor = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the governor.
    */
    modifier onlyGovernor() {
        require(msg.sender == _governor);
        _;
    }

    function proposeGovernor(address proposedGovernor) public onlyGovernor {
        require(msg.sender != proposedGovernor);
        _proposedGovernor = proposedGovernor;
    }
    
    function claimGovernor() public{
        require(msg.sender == _proposedGovernor);
        emit GovernorTransferred(_governor, _proposedGovernor);
        _governor = _proposedGovernor;
        _proposedGovernor = address(0);
    }
 
}

// File: contracts\bepro\Network.sol

pragma solidity >=0.6.0;





/**
 * @dev Interface of the ERC20 standard + mint & burn
 */
interface _IERC20 is IERC20  {

    /**
    * @dev Mint Function
    */
    function mint(address account, uint256 amount) external;

    /**
    * @dev Burn Function
    */
    function burn(address account, uint256 amount) external;

    function decimals() external returns (uint256);
}


/**
 * @title Development Network Contract Autonomous Use
 */
contract Network is Pausable, Governed, ReentrancyGuard{
    using SafeMath for uint256;

    _IERC20 public settlerToken;
    _IERC20 public transactionToken;

    uint256 constant private year = 365 days;
    uint256 public incrementIssueID = 1;
    uint256 public closedIdsCount = 0;
    uint256 public totalStaked = 0;
    uint256 public mergeCreatorFeeShare = 3; // (%) - Share to go to the merge proposal creator
    uint256 public percentageNeededForDispute = 3; // (%) - Amount needed to approve a PR and distribute the rewards
    uint256 public disputableTime = 3 days;
    uint256 public redeemTime = 1 days;
    uint256 public oraclesStaked = 0;

    uint256 public COUNCIL_AMOUNT = 25000000*10**18; // 25M

    mapping(uint256 => Issue) public issues; /* Distribution object */
    mapping(string => uint256) public issuesCIDtoID; /* Distribution object */
    mapping(address => uint256[]) public myIssues; /* Address Based Subcription */

    mapping(address => Oracler) public oraclers; 
    address[] public oraclersArray; 


    struct MergeProposal {
        uint256 _id;
        uint256 creationDate;
        mapping(address => uint256) disputesForMergeByAddress; // Address -> oracles for that merge
        uint256 oracles; // Amount of oracles set
        uint256 disputes; // Amount of oracles set
        address[] prAddresses;
        uint256[] prAmounts;
        address proposalAddress;
    }

    struct Issue {
        uint256 _id;
        string cid;
        uint256 creationDate;
        uint256 tokensStaked;
        address issueGenerator;
        mapping(uint256 => MergeProposal) mergeProposals; // Id -> Merge Proposal
        uint256 mergeIDIncrement;
        bool finalized;
        bool recognizedAsFinished;
        bool canceled;
    }

    struct Oracler {
        uint256 oraclesDelegatedByOthers;
        mapping(address => uint256) oraclesDelegated;
        address[] delegatedOraclesAddresses;
        uint256 tokensLocked;
    }

    event OpenIssue(uint256 indexed id, address indexed opener, uint256 indexed amount);
    event RedeemIssue(uint256 indexed id);
    event MergeProposalCreated(uint256 indexed id, uint256 indexed mergeID, address indexed creator);
    event DisputeMerge(uint256 indexed id, uint256 indexed mergeID, uint256 oracles, address indexed disputer);
    event CloseIssue(uint256 indexed id, uint256 indexed mergeID);
    event RecognizedAsFinished(uint256 indexed id);

    constructor(address _settlerToken, address _transactionToken, address _governor) public { 
        settlerToken = _IERC20(_settlerToken);
        transactionToken = _IERC20(_transactionToken);
        _governor = _governor;
    }

    function lock(uint256 _tokenAmount) external {
        require(_tokenAmount > 0, "Token Amount has to be higher than 0");
        require(settlerToken.transferFrom(msg.sender, address(this), _tokenAmount), "Needs Allowance");

        if(oraclers[msg.sender].tokensLocked != 0){
            // Exists
            oraclers[msg.sender].oraclesDelegated[msg.sender] = oraclers[msg.sender].oraclesDelegated[msg.sender].add(_tokenAmount);
            oraclers[msg.sender].tokensLocked = oraclers[msg.sender].tokensLocked.add(_tokenAmount);
        }else{
            // Does not exist
            Oracler storage oracler = oraclers[msg.sender];
            oracler.tokensLocked = _tokenAmount;
            oracler.delegatedOraclesAddresses = [msg.sender];
            oracler.oraclesDelegated[msg.sender] = _tokenAmount;
            oraclersArray.push(msg.sender);
        }

        oraclesStaked = oraclesStaked.add(_tokenAmount);
    }

    function unlock(uint256 _tokenAmount, address _from) external nonReentrant{
        Oracler storage oracler = oraclers[msg.sender];
        require(oracler.tokensLocked >= _tokenAmount, "Has to have tokens to unlock");
        require(oracler.oraclesDelegated[_from] >= _tokenAmount, "From has to have enough tokens to unlock");

        oraclers[msg.sender].tokensLocked = oracler.tokensLocked.sub(_tokenAmount);
        oraclers[msg.sender].oraclesDelegated[_from] = oracler.oraclesDelegated[_from].sub(_tokenAmount);

        if(msg.sender != _from){
            oraclers[_from].oraclesDelegatedByOthers = oraclers[_from].oraclesDelegatedByOthers.sub(_tokenAmount);
        }

        require(settlerToken.transfer(msg.sender, _tokenAmount), "Transfer didnt work");
        oraclesStaked = oraclesStaked.sub(_tokenAmount);
    }

    function delegateOracles(uint256 _tokenAmount, address _delegatedTo) external {
        Oracler storage oracler = oraclers[msg.sender];

        require(_delegatedTo != address(0), "Cannot transfer to the zero address");
        require(_delegatedTo != msg.sender, "Cannot transfer to itself");

        require(oracler.tokensLocked >= _tokenAmount, "Has to have tokens to unlock");
        require(oracler.oraclesDelegated[msg.sender] >= _tokenAmount, "From has to have tokens to use to delegate");

        oraclers[msg.sender].oraclesDelegated[msg.sender] = oracler.oraclesDelegated[msg.sender].sub(_tokenAmount);
        oraclers[msg.sender].delegatedOraclesAddresses.push(_delegatedTo);
        oraclers[msg.sender].oraclesDelegated[_delegatedTo] = oracler.oraclesDelegated[_delegatedTo].add(_tokenAmount);
        //require(oraclers[_delegatedTo].tokensLocked != uint256(0), "Delegated to has to have oracled already");
        oraclers[_delegatedTo].oraclesDelegatedByOthers = oraclers[_delegatedTo].oraclesDelegatedByOthers.add(_tokenAmount);
    }

    function disputeMerge(uint256 _issueID, uint256 _mergeID) external {
        Issue memory issue = issues[_issueID];
        MergeProposal storage merge = issues[_issueID].mergeProposals[_mergeID];
        require(issue._id != 0, "Issue does not exist");
        require(issue.mergeIDIncrement >  _mergeID, "Merge Proposal does not exist");
        require(merge.disputesForMergeByAddress[msg.sender] == 0, "Has already oracled");

        uint256 oraclesToAdd = getOraclesByAddress(msg.sender);
        
        issues[_issueID].mergeProposals[_mergeID].disputes = merge.disputes.add(oraclesToAdd);
        issues[_issueID].mergeProposals[_mergeID].disputesForMergeByAddress[msg.sender] = oraclesToAdd;
        
        emit DisputeMerge(_issueID, _mergeID, oraclesToAdd, msg.sender);
    }

    function isIssueInDraft(uint256 _issueID) public view returns (bool){
        // Only if in the open window
        require(issues[_issueID].creationDate != 0, "Issue does not exist");
        return (block.timestamp <= issues[_issueID].creationDate.add(redeemTime));
    }

    function isMergeInDraft(uint256 _issueID, uint256 _mergeID) public returns (bool) {
        require(issues[_issueID].creationDate != 0, "Issue does not exist");
        require(issues[_issueID].mergeProposals[_mergeID].proposalAddress != address(0), "Merge does not exist");
        return (block.timestamp <= issues[_issueID].mergeProposals[_mergeID].creationDate.add(disputableTime));
    }

    function isMergeDisputed(uint256 _issueID, uint256 _mergeID) public returns (bool) {
        require(issues[_issueID].creationDate != 0, "Issue does not exist");
        require(issues[_issueID].mergeProposals[_mergeID].proposalAddress != address(0), "Merge does not exist");
        return (issues[_issueID].mergeProposals[_mergeID].disputes >= oraclesStaked.mul(percentageNeededForDispute).div(100));
    }

    /**
     * @dev open an Issue with transaction Tokens owned
     * 1st step
     */
    function openIssue(string calldata _cid, uint256 _tokenAmount) external whenNotPaused {
        // Open Issue
        Issue memory issue;
        issue._id = incrementIssueID;
        issue.cid = _cid;
        issue.tokensStaked = _tokenAmount;
        issue.issueGenerator = msg.sender;
        issue.creationDate = block.timestamp;
        issue.finalized = false;
        issues[incrementIssueID] = issue;
        issuesCIDtoID[_cid] = incrementIssueID;
        
        myIssues[msg.sender].push(incrementIssueID);
        totalStaked = totalStaked.add(_tokenAmount);
        incrementIssueID = incrementIssueID + 1;
        // Transfer Transaction Token
        require(transactionToken.transferFrom(msg.sender, address(this), _tokenAmount), "Needs Allowance");
    
        emit OpenIssue(issue._id, msg.sender, _tokenAmount);
    }

    function recognizeAsFinished(uint256 _issueId) external whenNotPaused {
        Issue storage issue = issues[_issueId];
        require(issue.issueGenerator == msg.sender, "Has to be the issue creator");
        require(!isIssueInDraft(_issueId), "Draft Issue Time has already passed");
        require(!issue.finalized, "Issue was already finalized");
        require(!issue.canceled, "Issue was already canceled");

        issues[_issueId].recognizedAsFinished = true;

        emit RecognizedAsFinished(_issueId);
    }

    function redeemIssue(uint256 _issueId) external whenNotPaused {
        Issue storage issue = issues[_issueId];
        require(issue.issueGenerator == msg.sender, "Has to be the issue creator");
        require(isIssueInDraft(_issueId), "Draft Issue Time has already passed");
        require(!issue.finalized, "Issue was already finalized");
        require(!issue.canceled, "Issue was already canceled");

        issues[_issueId].finalized = true;
        issues[_issueId].canceled = true;
        require(transactionToken.transfer(msg.sender, issue.tokensStaked), "Transfer not sucessful");

        emit RedeemIssue(_issueId);
    }

    /**
     * @dev update an Issue with transaction tokens owned
     * 2nd step  (optional)
     */
    function updateIssue(uint256 _issueId, uint256 _newTokenAmount) external whenNotPaused {
        require(issues[_issueId].tokensStaked != 0, "Issue has to exist");
        require(issues[_issueId].issueGenerator == msg.sender, "Has to be the issue creator");
        require(!issues[_issueId].finalized, "Issue was already finalized");
        require(!issues[_issueId].canceled, "Issue was already canceled");
        require(isIssueInDraft(_issueId), "Draft Issue Time has already passed");

        uint256 previousAmount = issues[_issueId].tokensStaked;
        // Update Issue
        issues[_issueId].tokensStaked = _newTokenAmount;
        // Lock Transaction Tokens
        if(_newTokenAmount > previousAmount){
            require(transactionToken.transferFrom(msg.sender, address(this), _newTokenAmount.sub(previousAmount)), "Needs Allowance");
            totalStaked = totalStaked.add(_newTokenAmount.sub(previousAmount));
        }else{
            totalStaked = totalStaked.sub(previousAmount.sub(_newTokenAmount));
            require(transactionToken.transfer(msg.sender, previousAmount.sub(_newTokenAmount)), "Transfer not sucessful");
        }
    }

   /**
     * @dev Owner finalizes the issue and distributes the transaction tokens or rejects the PR
     * @param _issueID issue id (mapping with github)
     * @param _prAddresses PR Address
     * @param _prAmounts PR Amounts
     */
    function proposeIssueMerge(uint256 _issueID, address[] calldata _prAddresses, uint256[] calldata _prAmounts) external whenNotPaused {

        Issue memory issue = issues[_issueID];
        require(issue._id != 0 , "Issue has to exist");
        require(issue.finalized == false, "Issue has to be opened");
        require(_prAmounts.length == _prAddresses.length, "Amounts has to equal addresses length");

        uint256 oracles = getOraclesByAddress(msg.sender);

        require(oracles >= COUNCIL_AMOUNT, "To propose merges the proposer has to be a Council (COUNCIL_AMOUNT)");

        MergeProposal memory mergeProposal;
        mergeProposal._id = issue.mergeIDIncrement;
        mergeProposal.prAmounts = _prAmounts;
        mergeProposal.prAddresses = _prAddresses;
        mergeProposal.proposalAddress = msg.sender;

        uint256 total = ((issues[_issueID].tokensStaked * (mergeCreatorFeeShare)) / 100); // Fee + Merge Creator Fee + 0

        for(uint i = 0; i < _prAddresses.length; i++){
            total = total.add((_prAmounts[i] * (100-mergeCreatorFeeShare)) / 100);
        }

        require(total == issues[_issueID].tokensStaked, "PrAmounts & TokensStaked dont match");

        issues[_issueID].mergeProposals[issue.mergeIDIncrement] = mergeProposal;
        issues[_issueID].mergeIDIncrement = issues[_issueID].mergeIDIncrement + 1;
        emit MergeProposalCreated(_issueID, mergeProposal._id, msg.sender);
    }


    /**
     * @dev Owner finalizes the issue and distributes the transaction tokens or rejects the PR
     * @param _issueID issue id (mapping with github)
     * @param _mergeID merge id 
     */
    function closeIssue(uint256 _issueID, uint256 _mergeID) external whenNotPaused {
        Issue memory issue = issues[_issueID];
        require(issue._id != 0 , "Issue has to exist");
        require(issue.finalized == false, "Issue has to be opened");
        require(issue.recognizedAsFinished, "Issue has to be recognized as finished by the creator or by the disputers");
        require(issue.mergeIDIncrement >  _mergeID, "Merge Proposal does not exist");
        require(!isIssueInDraft(_issueID), "Issue cant be in Draft Mode");
        require(!isMergeInDraft(_issueID, _mergeID), "Merge cant be in Draft Mode");
        require(!isMergeDisputed(_issueID, _mergeID), "Merge has been disputed");

        // Closes the issue
        issues[_issueID].finalized = true;
        MergeProposal memory merge = issues[_issueID].mergeProposals[_mergeID];

        // Merge Creator Transfer
        require(transactionToken.transfer(merge.proposalAddress, (issues[_issueID].tokensStaked * mergeCreatorFeeShare) / 100), "Has to transfer");
        
        // Generate Transaction Tokens
        for(uint i = 0; i < merge.prAddresses.length; i++){
            myIssues[merge.prAddresses[i]].push(_issueID);
            require(transactionToken.transfer(merge.prAddresses[i], (merge.prAmounts[i] * (100-mergeCreatorFeeShare)) / 100), "Has to transfer");
        }

        closedIdsCount = closedIdsCount.add(1);
        totalStaked = totalStaked.sub(issue.tokensStaked);
        emit CloseIssue(_issueID, _mergeID);
    }

    function getIssuesByAddress(address _address) public returns (uint256[] memory){
        return myIssues[_address];
    }

    function getOraclesByAddress(address _address) public returns (uint256){
        Oracler storage oracler = oraclers[_address];
        return oracler.oraclesDelegatedByOthers.add(oracler.oraclesDelegated[_address]);
    }

    function getOraclesSummary(address _address) public returns (uint256, uint256[] memory, address[] memory, uint256){
        Oracler storage oracler = oraclers[_address];

        uint256[] memory amounts = new uint256[](oracler.delegatedOraclesAddresses.length);
        address[] memory addresses = new address[](oracler.delegatedOraclesAddresses.length);

        for(uint i=0; i < oracler.delegatedOraclesAddresses.length; i++){
            addresses[i] = (oracler.delegatedOraclesAddresses[i]);
            amounts[i] = (oracler.oraclesDelegated[oracler.delegatedOraclesAddresses[i]]);
        }

        return (oracler.oraclesDelegatedByOthers, amounts, addresses, oracler.tokensLocked);
    }

    function getIssueByCID(string memory _issueCID) public returns (uint256, string memory, uint256, uint256, address, uint256, bool, bool, bool){
        Issue memory issue = issues[issuesCIDtoID[_issueCID]];
        return (issue._id, issue.cid, issue.creationDate, issue.tokensStaked, issue.issueGenerator, issue.mergeIDIncrement, issue.finalized, issue.canceled, issue.recognizedAsFinished);
    }
    
    function getIssueById(uint256 _issueID) public returns (uint256, string memory, uint256, uint256, address, uint256, bool, bool, bool){
        Issue memory issue = issues[_issueID];
        return (issue._id, issue.cid, issue.creationDate, issue.tokensStaked, issue.issueGenerator, issue.mergeIDIncrement, issue.finalized, issue.canceled, issue.recognizedAsFinished);
    }

    function getMergeById(uint256 _issueID, uint256 _mergeId) public returns (uint256, uint256, uint256, address[] memory, uint256[] memory, address){
        MergeProposal memory merge = issues[_issueID].mergeProposals[_mergeId];
        return (merge._id, merge.oracles, merge.disputes, merge.prAddresses, merge.prAmounts, merge.proposalAddress);
    }

    /**
     * @dev Change Merge Creator FeeShare
     */
    function changeMergeCreatorFeeShare(uint256 _mergeCreatorFeeShare) external onlyGovernor {
        require(_mergeCreatorFeeShare < 20, "Merge Share can´t be higher than 20");
        mergeCreatorFeeShare = _mergeCreatorFeeShare;
    }

    /**
     * @dev changePercentageNeededForDispute
     */
    function changePercentageNeededForDispute(uint256 _percentageNeededForDispute) external onlyGovernor {
        require(_percentageNeededForDispute < 15, "Dispute % Needed can´t be higher than 15");
        percentageNeededForDispute = _percentageNeededForDispute;
    }

     /**
     * @dev changedisputableTime
     */
    function changeDisputableTime(uint256 _disputableTime) external onlyGovernor {
        require(_disputableTime < 20 days, "Time has to be lower than 20 days");
        require(_disputableTime >= 1 minutes, "Time has to be higher than 1 minutes");
        disputableTime = _disputableTime;
    }

      /**
     * @dev changeRedeemTime
     */
    function changeRedeemTime(uint256 _redeemTime) external onlyGovernor {
        require(_redeemTime < 20 days, "Time has to be lower than 20 days");
        require(_redeemTime >= 1 minutes, "Time has to be higher than 1 minutes");
        redeemTime = _redeemTime;
    }

    /**
     * @dev changeTimeOpenForIssueApprove
    */
    function changeCOUNCIL_AMOUNT(uint256 _COUNCIL_AMOUNT) external onlyGovernor {
        require(_COUNCIL_AMOUNT > 100000*10**settlerToken.decimals(), "Council Amount has to higher than 100k");
        require(_COUNCIL_AMOUNT < 50000000*10**settlerToken.decimals(), "Council Amount has to lower than 50M");
        COUNCIL_AMOUNT = _COUNCIL_AMOUNT;
    }
}