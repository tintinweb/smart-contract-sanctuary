/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT AND GPLv2
// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity >=0.4.22 <0.9.0;
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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.4.22 <0.9.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: contracts/libs/ERC20.sol


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

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

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
    constructor (string memory name_, string memory symbol_)  {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: contracts/libs/ERC20Burnable.sol


pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

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
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/libs/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity ^0.7.6;

interface IUniswapV2Router01 {
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

// File: contracts/libs/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity ^0.7.6;


interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: contracts/libs/@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.7.6;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts/ERC20TokenPlus.sol


pragma solidity ^0.7.6;
pragma abicoder v2;


contract ERC20TokenPlus is Context, Ownable, ERC20, ERC20Burnable {


    event _Receive(address _sender, uint256 _amount);
    event Burn(address indexed account, uint256 amount);
    //    event Logg(address indexed _acct);

    using SafeMath for uint256;
    mapping(address => uint256) private _tokensOwned;

    string  constant  _tokenName = "Test Token";
    string  constant  _tokenSymbol = "TEST48";
    uint8   constant  _tokenDecimals = 8;
    uint256 constant  _tokenSupply = 100_000_000_000; // 100b

    address _owner;

    bool _isInitialized = false;

    //bool isLiquidityEnabled = false;

    bool isBurnEnabled = true;

    bool isMarketingFeeFundEnabled = true;

    bool isDevFundFeeEnabled = true;

    //uint256 liquidityFeeInPercent = 0;

    uint256 burnFeeInPercent = 5;
    uint256 burnFeeInPercentSell = 6;
    uint256 private _burnTokens;

    uint256 devFundFeeInPercent = 2;
    uint256 devFundFeeInPercentSell = 4;
    uint256 private _devTokens;

    uint256 marketingFundFeeInPercent = 3;
    uint256 marketingFundFeeInPercentSell = 5;

    bool private _disabledTaxes = false;
    uint256 private _marketingTokens;

    bool private _taxesEnabled = true;

    bool isSwapAndLiquifyLocked;

    mapping(address => bool) private accountsExcludedFromFees;

    IUniswapV2Router02 public  uniswapV2Router;

    address public  uniswapV2Pair;

    address payable devAndMarketingFundAddress;

    address liquidityOwnerAddress;

    //liquidity fund
    uint256 private totalAmountToLiquidify;
    uint256 private totalAmountForDevAndMarketing;

    //get chain id
    function getChainId() private pure returns (uint256) {
        uint256 id;
        assembly {id := chainid()}
        return id;
    }


    constructor() ERC20(_tokenName, _tokenSymbol) {

        _setupDecimals(_tokenDecimals);

        uint256 totalInitialSupply = _tokenSupply * (10 ** _tokenDecimals);

        _mint(_msgSender(), totalInitialSupply);


        //accountsExcludedFromFees[msg.sender] = true;

        devAndMarketingFundAddress = payable(msg.sender);

        accountsExcludedFromFees[address(this)] = true;
        accountsExcludedFromFees[owner()] = true;
        accountsExcludedFromFees[devAndMarketingFundAddress] = true;

        liquidityOwnerAddress = msg.sender;

        uint256 chainId = getChainId();

        if (chainId == 1 || chainId == 3 || chainId == 42) {//ethereum based chains (uniswap)

            uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        } else if (chainId == 97) {// bsc testnet pancake testnet

            uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        } else if (chainId == 56) {// bsc main net pancake mainnet

            uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        } else {
            revert("Unsupported chain Id");
        }

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }





    /**
     * get total amount to liquidity
     */
    function getTotalAmountsToLiquidify() public view returns (uint256) {
        return totalAmountToLiquidify;
    }

    /**
     * get totalAmountForDevAndMarketing
     */
    function getTotalAmountForDevAndMarketing() public view returns (uint256) {
        return totalAmountForDevAndMarketing;
    }


    //disable all fees
    function setEnableAllFees(bool _option) external onlyOwner {
        isDevFundFeeEnabled = _option;
        isBurnEnabled = _option;
        //isLiquidityEnabled = _option;
        isMarketingFeeFundEnabled = _option;
    }


    //set dev and marketing fund  wallet
    function setDevAndMarketingFundWallet(address payable _wallet) external onlyOwner {
        devAndMarketingFundAddress = _wallet;
    }

    /**
     * @dev toggle swap and add liquidity mode
     */
    modifier lockSwapAndLiquify {
        isSwapAndLiquifyLocked = true;
        _;
        isSwapAndLiquifyLocked = false;
    }


    function setV2UniswapRouter(address _uniswapV2Contract) public onlyOwner() {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Contract);
    }


    /**
    * @dev lets swap token for bnb
    */
    function swapTokenForBNB(uint256 _tokenAmount) private returns (uint256) {


        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        uint256 bnbCurrentBalance = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amoun
            path,
            address(this),
            (block.timestamp + 10)
        );

        return uint256(address(this).balance.sub(bnbCurrentBalance));
    } //end

    /**
    * @dev add liquidity
    */
    function _addLquidity(uint256 _tokenAmount, uint256 _amountInBNB) private {

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH { value : _amountInBNB} (
    address(this), //token contract address
    _tokenAmount, // token amount to add liquidity
    0, //amountTokenMin
    0, //amountETHMin
    liquidityOwnerAddress, //owner of the liquidity
    (block.timestamp + 15) //deadline
        );
    } //end add liquidity


    /**
     * @dev swap and add liquidity
     */
    function swapAndLiquify(uint256 _tokenAmount) private lockSwapAndLiquify {

        require(_tokenAmount > 0, "Amount cannot be 0");

        uint256 tokenAmountHalf = _tokenAmount.div(2);

        //lets swap to get some base asset
        uint256 swappedBNBAmount = swapTokenForBNB(tokenAmountHalf);

        _addLquidity(tokenAmountHalf, swappedBNBAmount);

    } //end


    /**
     * add lets add initial liquidity
     */
    function addInitialLiquidity(uint256 _tokenAmount) external payable onlyOwner lockSwapAndLiquify {

        require(!_isInitialized, "Method Alerady Initialised");
        require(msg.value > 0, "BNB amount should be greater than 0");
        require(_tokenAmount > 0, "_tokenAmount should be greater than 0");

        //excludeFromFees(_msgSender());

        require(address(this).send(msg.value), "Failed to transfer bnb to contract");

        //put token to contract
        super._transfer(_msgSender(), address(this), _tokenAmount);

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH { value : msg.value} (
    address(this), //token contract address
    _tokenAmount, // token amount we wish to provide liquidity for
    _tokenAmount, //amountTokenMin
    msg.value, //amountETHMin
    _msgSender(),
    (block.timestamp + 1000) //deadline
        );

        _isInitialized = true;
    } //end add liquidity


    function computePercent(uint256 _value) private pure returns (uint256) {
        return _value.mul(100);
    }

    /*
    function setEnableLiquidityFee(bool _option) public onlyOwner() {
        isLiquidityEnabled = _option;
    } */

    function setEnableBurn(bool _option) public onlyOwner() {
        isBurnEnabled = _option;
    }

    function setEnableDevFundFee(bool _option) public onlyOwner() {
        isDevFundFeeEnabled = _option;
    }

    function setEnableMarketingFundFee(bool _option) public onlyOwner() {
        isMarketingFeeFundEnabled = _option;
    }

    /*
    function setLiquidityFee(uint256 _value) public onlyOwner() {
        liquidityFeeInPercent = _value;
    }*/

    function setDevFundFee(uint256 _value) public onlyOwner() {
        devFundFeeInPercent = _value;
    }

    function setDevFundFeeSell(uint256 _value) public onlyOwner() {
        devFundFeeInPercentSell = _value;
    }

    function setBurnFee(uint256 _value) public onlyOwner() {
        burnFeeInPercent = _value;
    }

    function setBurnFeeSell(uint256 _value) public onlyOwner() {
        burnFeeInPercentSell = _value;
    }

    function setMarketingFundFee(uint256 _value) public onlyOwner() {
        marketingFundFeeInPercent = _value;
    }

    function setMarketingFundFeeSell(uint256 _value) public onlyOwner() {
        marketingFundFeeInPercentSell = _value;
    }


    function getTotalFee() public view returns (uint256){

        uint256 fee = 0;

        // if(isLiquidityEnabled){ fee += liquidityFeeInPercent; }
        if (isBurnEnabled) {fee += burnFeeInPercent;}
        if (isDevFundFeeEnabled) {fee += devFundFeeInPercent;}
        if (isMarketingFeeFundEnabled) {fee += marketingFundFeeInPercent;}

        return fee;
    }

    function excludeFromFees(address _account) public onlyOwner() returns (bool){
        accountsExcludedFromFees[_account] = true;
        return true;
    }

    function removeExcludedFromFees(address _account) public onlyOwner() returns (bool){
        delete accountsExcludedFromFees[_account];
        return true;
    }

    function isExcludedFromFees(address _account) public view returns (bool){
        return accountsExcludedFromFees[_account];
    }

    //function _doBurn(address _account )


    function _transfer(address from, address to, uint256 amount) override internal virtual
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(amount <= _tokensOwned[from], "Transfer amount would exceed balance");

        _tokensOwned[from] = _tokensOwned[from] - amount;

        uint256 remaining = amount;
        uint256 sellTax;
        uint256 buyTax;


//        if (_taxesEnabled && !accountsExcludedFromFees[from])
//        {
//            sellTax = remaining - _handleSellTax(remaining);
//            remaining = remaining - sellTax;
//        }
//
//        if (_taxesEnabled && !accountsExcludedFromFees[to])
//        {
//            buyTax = remaining - _handleBuyTax(remaining);
//            remaining = remaining - buyTax;
//        }
//
//        // Add the taxed tokens to the contract...
//        if ((!accountsExcludedFromFees[from] || !accountsExcludedFromFees[to]) && amount > remaining)
//        {
//            _tokensOwned[address(this)] = _tokensOwned[address(this)] + (amount - remaining);
//            //process burn
//            if (_burnTokens > 0 && isBurnEnabled) {
//                uint256 _amountToBurn = computePecentToAmount(_burnTokens, amount);
//                if (buyTax > 0) _doBurn(to, _amountToBurn);
//                if (sellTax > 0) _doBurn(from, _amountToBurn);
//            }
//            if (isMarketingFeeFundEnabled == true) {
//                isSwapAndLiquifyLocked = true;
//
//                uint256 swappedBNBAmount = swapTokenForBNB(remaining);
//
//                if (swappedBNBAmount > 0) {
////                    devAndMarketingFundAddress.call({value : swappedBNBAmount})("");
//                }
//                totalAmountForDevAndMarketing = totalAmountForDevAndMarketing.sub(remaining);
//
//                isSwapAndLiquifyLocked = false;
//            }
//
//            if (buyTax > 0) emit Transfer(to, address(this), buyTax);
//            if (sellTax > 0) emit Transfer(from, address(this), sellTax);
//        }

        // Give tokens to the new owner...
        _tokensOwned[to] = _tokensOwned[to] + remaining;
        emit Transfer(from, to, remaining);
    }

    function _handleBuyTax(uint256 starting) private returns (uint256)
    {
        uint256 remaining = starting;

        uint256 tax = (starting * marketingFundFeeInPercent) / 100;
        _marketingTokens = _marketingTokens + tax;
        remaining = remaining - tax;

        tax = (starting * devFundFeeInPercent) / 100;
        _devTokens = _devTokens + tax;
        remaining = remaining - tax;

        tax = (starting * burnFeeInPercent) / 100;
        _burnTokens = _burnTokens + tax;
        remaining = remaining - tax;

        return remaining;
    }

    function _handleSellTax(uint256 starting) private returns (uint256)
    {
        uint256 remaining = starting;

        uint256 tax = (starting * marketingFundFeeInPercentSell) / 100;
        _marketingTokens = _marketingTokens + tax;
        remaining = remaining - tax;

        tax = (starting * devFundFeeInPercentSell) / 100;
        _devTokens = _devTokens + tax;
        remaining = remaining - tax;

        tax = (starting * burnFeeInPercentSell) / 100;
        _burnTokens = _burnTokens + tax;
        remaining = remaining - tax;

        return remaining;
    }

    event TaxesEnabled(bool enabled);

    function takeTaxes(bool _enabled) external onlyOwner
    {
        _taxesEnabled = _enabled;
        emit TaxesEnabled(_taxesEnabled);
    }
    //    function _transfer(address sender, address recipient, uint256 amount) override internal virtual {
    //
    //
    //        require(amount > 0, "Amount cannot be less than 0");
    //        require(_balances[sender] >= amount, "Insufficient balance");
    //
    //        require(sender != address(0), "ERC20: transfer from the zero address");
    //        require(recipient != address(0), "ERC20: transfer to the zero address");
    //
    //        uint256 amountToTransfer = _preProcessTransfer(sender, recipient, amount);
    //
    //        _balances[sender] = _balances[sender].sub(amountToTransfer, "ERC20: transfer amount exceeds balance");
    //        _balances[recipient] = _balances[recipient].add(amountToTransfer);
    //
    //        emit Transfer(sender, recipient, amountToTransfer);
    //
    //    } //end fun

    /**
     * doBurn
     */
    function _doBurn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(account, amount);
    }

    function _preProcessTransfer(address sender, address recipient, uint256 amount) private returns (uint256) {

        if (isExcludedFromFees(sender) || isExcludedFromFees(recipient) || isSwapAndLiquifyLocked) {
            return amount;
        }

        //uint256 originalAmount = amount;

        //lets get totalTax to deduct
        uint256 totalFeeToDeduct = computePecentToAmount(getTotalFee(), amount);

        uint256 amountWithFee = amount.sub(totalFeeToDeduct);

        //process burn
        if (burnFeeInPercent > 0 && isBurnEnabled) {
            uint256 _amountToBurn = computePecentToAmount(burnFeeInPercent, amount);
            _doBurn(sender, _amountToBurn);
        }
        //end process burn

        uint256 _devMarketingLiquidityAmount;
        uint256 _devAndMarketingAmount;
        //uint256 _liquidityFeeAmount;

        /*if(isLiquidityEnabled && liquidityFeeInPercent > 0) {
            _liquidityFeeAmount = computePecentToAmount(liquidityFeeInPercent, amount);
            _devMarketingLiquidityAmount += _liquidityFeeAmount;
        }*/

        if (isDevFundFeeEnabled && devFundFeeInPercent > 0) {
            _devAndMarketingAmount = computePecentToAmount(devFundFeeInPercent, amount);
            _devMarketingLiquidityAmount += _devAndMarketingAmount;
        }

        if (isMarketingFeeFundEnabled && marketingFundFeeInPercent > 0) {
            uint256 marketingAmt = computePecentToAmount(marketingFundFeeInPercent, amount);
            _devAndMarketingAmount += marketingAmt;
            _devMarketingLiquidityAmount += marketingAmt;
        }

        if (_devMarketingLiquidityAmount > 0) {
            _balances[sender] = _balances[sender].sub(_devMarketingLiquidityAmount);
            _balances[address(this)] = _balances[address(this)].add(_devMarketingLiquidityAmount);
        }

        /*if(_liquidityFeeAmount > 0) {

            totalAmountToLiquidify = totalAmountToLiquidify + _liquidityFeeAmount;

            if(sender != uniswapV2Pair && totalAmountToLiquidify > 0) {

                //take snapshot
                uint256 amounToLiquidify = totalAmountToLiquidify;

                //lets swap and provide liquidity
                swapAndLiquify(amounToLiquidify);

                //lets
                totalAmountToLiquidify = totalAmountToLiquidify.sub(amounToLiquidify);
            } //end if

        } //end if
        */

        //if dev and marketing is there
        if (_devAndMarketingAmount > 0) {

            totalAmountForDevAndMarketing = totalAmountForDevAndMarketing.add(_devAndMarketingAmount);

            if (sender != uniswapV2Pair && totalAmountForDevAndMarketing > 0) {

                isSwapAndLiquifyLocked = true;

                uint256 _currentDevAndMarketingAmountSnapShot = totalAmountForDevAndMarketing;

                uint256 swappedBNBAmount = swapTokenForBNB(_currentDevAndMarketingAmountSnapShot);

                if (swappedBNBAmount > 0) {
//                    devAndMarketingFundAddress.call{value : swappedBNBAmount}("");
                }

                totalAmountForDevAndMarketing = totalAmountForDevAndMarketing.sub(_currentDevAndMarketingAmountSnapShot);

                isSwapAndLiquifyLocked = false;
            }
            //end if

        }
        //end if dev and marketing amt


        return amountWithFee;

    } //end fun


    function computePecentToAmount(uint256 percentageValue, uint256 amount) private pure returns (uint256) {
        return amount * (percentageValue.mul(100)) / 10_000;
    }

receive() external payable {
emit _Receive(msg.sender, msg.value);
}

fallback () external payable {}

}//end contract