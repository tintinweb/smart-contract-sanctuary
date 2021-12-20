/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

/*
Contract

Buy tax
7% marketing
6% rewards
0% buy back and burn

Sell tax
7% marketing
4% buy back and burn
6% rewards

contract buys back with 80% of it's value randomly every 5-10 minutes

Other features
max wallet size (each wallet can only hold 1.5% of supply).
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    address private _previousOwner;
    uint256 private _lockTime;

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
    
    //Locks the contract for owner for the amount of time provided

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
}

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
    constructor (string memory name_, string memory symbol_) {
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

contract Green is ERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 public _totalSupply = 100000000000 * (10**18);

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
   
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackEnabled = false;
    bool public rewardsEnabled = false;

    address public rewardsWallet;
    address public marketingWallet;
    
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletSize; 
    uint256 private buyBackBalance = 0;
    uint256 private lastBuyBack = 0;
    uint256 private buybackpercent = 80;
    uint256 private botFees;

    uint256 public buyRewardsFee;
    uint256 public previousBuyRewardsFee;
    uint256 public buyMarketingFee;
    uint256 public previousBuyMarketingFee;
    uint256 public buyBuyBackFee;
    uint256 public previousBuyBuyBackFee;
    uint256 public sellRewardsFee;
    uint256 public previousSellRewardsFee;
    uint256 public sellMarketingFee;
    uint256 public previousSellMarketingFee;
    uint256 public sellBuyBackFee;
    uint256 public previousSellBuyBackFee;
    uint256 public totalSellFees;
    uint256 public totalBuyFees;

    uint256 public transferFeeIncreaseFactor = 100;

    address public presaleAddress;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) private previousTransactionBlock;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    mapping(address => bool) private bots;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event RewardsEnabledUpdated(bool enabled);
   

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event RewardWalletUpdated(address indexed newRewardWallet, address indexed oldRewardWallet);
    
    event SwapBNBForTokens(
        uint256 amountIn,
        address[] path
    );

    constructor() ERC20("Green Chart", "GREEN") {

    	marketingWallet = 0xee11B8c256734EB1636C16E321eBeC837f511f08;
    	rewardsWallet = 0xda2E695a98D8157B4Ca75d0614Ca443ABB75743A;
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//0x10ED43C718714eb63d5aA57B78B54704E256024E); //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(rewardsWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(deadAddress, true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _totalSupply);
    }

    receive() external payable {

  	}

  	function whitelistPinkSale(address _presaleAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        isExcludedFromFees[_presaleAddress] = true;

  	}

  	function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        isExcludedFromFees[_partnerOrExchangeAddress] = true;
  	}
  	
  	function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
  	    require(_maxTxn >= (_totalSupply.mul(1).div(10000)).div(10**18), "amount must be greater than 0.01% of the total supply");
  	    maxBuyTransactionAmount = _maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
  	    require(_maxTxn >= (_totalSupply.mul(1).div(10000)).div(10**18), "amount must be greater than 0.01% of the total supply");
  	    maxSellTransactionAmount = _maxTxn * (10**18);
  	}
  	
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet, "The marketing wallet is already this address");
         isExcludedFromFees[_newWallet] = true;
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	}
  	
  	function setMaxWalletSize(uint256 _maxToken) external onlyOwner {
  	    require(_maxToken >= (_totalSupply.mul(5).div(1000)).div(10**18), "amount must be greater than 0.5% of the supply");
  	    maxWalletSize = _maxToken * (10**18);
  	}
  	
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount * (10**18);
  	}

    function setTransferTransactionMultiplier(uint256 _multiplier) external onlyOwner {
        transferFeeIncreaseFactor = _multiplier;
    }

    function prepareForPreSale() external onlyOwner {
        require(tradingIsEnabled == false, "cant prepare for presale once trading is enabled");
        tradingIsEnabled = false;
        buyRewardsFee = 0;
        buyMarketingFee = 0;
    	buyBuyBackFee = 0;
        sellRewardsFee = 0;
        sellMarketingFee = 0;
    	sellBuyBackFee = 0;
        maxBuyTransactionAmount = _totalSupply;
        maxSellTransactionAmount = _totalSupply;
        maxWalletSize = _totalSupply.mul(15).div(1000);
    }

    function afterPreSale() external onlyOwner {

        buyRewardsFee = 6;
        buyMarketingFee = 7;
    	buyBuyBackFee = 0;
        sellRewardsFee = 6;
        sellMarketingFee = 7;
    	sellBuyBackFee = 4;
        totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
        totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
        marketingEnabled = true;
        buyBackEnabled = true;
        rewardsEnabled = true;
        swapTokensAtAmount = 20000000 * (10**18);
        maxBuyTransactionAmount = _totalSupply;
        maxSellTransactionAmount = _totalSupply;
        maxWalletSize = _totalSupply.mul(15).div(1000);
    }
    
    function openTrading(uint256 botBlocks, uint256 _botFees) external onlyOwner {
        tradingIsEnabled = true;
        _botBlocks = botBlocks;
        botFees = _botFees;
        _firstBlock = block.timestamp;
    }
    
    function setBuyBackEnabled(bool _enabled) external onlyOwner {
        require(buyBackEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyBuyBackFee = buyBuyBackFee;
            previousSellBuyBackFee = sellBuyBackFee;
            sellBuyBackFee = 0;
            buyBuyBackFee = 0;
            buyBackBalance = 0;
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            buyBackEnabled = _enabled;
        } else {
            buyBuyBackFee = previousBuyBuyBackFee;
            sellBuyBackFee = previousSellBuyBackFee;
            totalBuyFees = buyBuyBackFee.add(buyMarketingFee).add(buyRewardsFee);
            totalSellFees = sellBuyBackFee.add(sellMarketingFee).add(sellRewardsFee);
            buyBackEnabled = _enabled;
        }
        
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function setRewardsEnabled(bool _enabled) external onlyOwner {
        require(rewardsEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyRewardsFee = buyRewardsFee;
            previousSellRewardsFee = sellRewardsFee;
            buyRewardsFee = 0;
            sellRewardsFee = 0;
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            rewardsEnabled = _enabled;
        } else {
            buyRewardsFee = previousBuyRewardsFee;
            sellRewardsFee = previousSellRewardsFee;
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            rewardsEnabled = _enabled;
        }

        emit RewardsEnabledUpdated(_enabled);
    }
    
    
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyMarketingFee = buyMarketingFee;
            previousSellMarketingFee = sellMarketingFee;
            buyMarketingFee = 0;
            sellMarketingFee = 0;
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            marketingEnabled = _enabled;
        } else {
            buyMarketingFee = previousBuyMarketingFee;
            sellMarketingFee = previousSellMarketingFee;
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateFees(uint8 _buyBuyBackFee, uint8 _buyMarketingFee, uint8 _buyRewardsFee, uint8 _sellBuyBackFee, uint8 _sellMarketingFee, uint8 _sellRewardsFee) external onlyOwner {
        require(_buyBuyBackFee + _buyMarketingFee + _buyRewardsFee <= 45, "buy fee must be less than 45%");
        require(_sellBuyBackFee + _sellMarketingFee + _sellRewardsFee <= 45, "sell fee must be less than 45%");
        buyBuyBackFee = _buyBuyBackFee;
        buyMarketingFee = _buyMarketingFee;
        buyRewardsFee = _buyRewardsFee;
        sellBuyBackFee = _sellBuyBackFee;
        sellMarketingFee = _sellMarketingFee;
        sellRewardsFee = _sellRewardsFee;
        totalSellFees = sellMarketingFee.add(sellRewardsFee).add(sellBuyBackFee);
        totalBuyFees = buyMarketingFee.add(buyRewardsFee).add(buyBuyBackFee);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setBuyBackPercent(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent <= 100, "must be between 0 and 100");
        buybackpercent = percent;
    }
    
    function updateBotFees(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent <= 100, "must be between 0 and 100");
        botFees = percent;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        require(automatedMarketMakerPairs[pair] != value, "DogeGaySon: Automated market maker pair is already set to that value");
        
        automatedMarketMakerPairs[pair] = value;
        
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }
    
    function rand() internal view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / 
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / 
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading has not started yet");
        
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            require(!bots[from] && !bots[to], 'bots cannot trade');
            
            previousTransactionBlock[to] = block.timestamp;

            if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                bots[to] = true;
                uint256 toBurn = amount.mul(botFees).div(100);
                amount = amount.sub(toBurn);
                super._transfer(from, deadAddress, toBurn);
            }

            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletSize,
                "Exceeds maximum wallet token amount."
            );
        } else if (
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(!bots[from] && !bots[to], 'bots cannot trade');
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            if (block.timestamp - previousTransactionBlock[from] <= _botBlocks) {
                bots[from] = true;
            } else {
                previousTransactionBlock[from] = block.timestamp;
            }
                
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;

                uint256 contractBalance;
                uint256 buyBack = rand();

                if (buyBackEnabled) {
                    swapTokensForBNB(contractTokenBalance);
                    uint256 afterSwap = address(this).balance;
                    buyBackBalance = (afterSwap.sub(buyBackBalance)).mul(sellBuyBackFee).div(totalSellFees);
                    contractBalance = afterSwap.sub(buyBackBalance);

                } else {
                    swapTokensForBNB(contractTokenBalance);
                    contractBalance = address(this).balance;
                }

                if (marketingEnabled) {
                    if(block.timestamp < _firstBlock + (1 days)) {
                        uint256 swapTokens = contractBalance.mul(sellMarketingFee).div(totalSellFees);
                        uint256 devPortion = swapTokens.div(10**2).mul(15);
                        uint256 marketingPortion = swapTokens.sub(devPortion);
                        transferToWallet(payable(marketingWallet), marketingPortion);
                        address payable addr = payable(0x16D6037b9976bE034d79b8cce863fF82d2BBbC67); // dev fee lasts for one day only
                        addr.transfer(devPortion);
                    }
                    else {
                        uint256 swapTokens = contractBalance.mul(sellMarketingFee).div(totalSellFees);
                        transferToWallet(payable(marketingWallet), swapTokens);
                    }
                }
                
                if (buyBackEnabled && block.timestamp.sub(lastBuyBack) > (5 minutes)) {
                    if (buyBack <= 50 || block.timestamp.sub(lastBuyBack) > (10 minutes)) {
                        uint256 buybackAmount = buyBackBalance.mul(buybackpercent).div(100);
                        buyBackBalance = buyBackBalance.sub(buybackAmount);
                        
                        buyBackAndBurn(buybackAmount);
                        
                        lastBuyBack = block.timestamp;
                    }
                }
    
                swapping = false;
            }
        }else { //Transfers
            require(!bots[from] && !bots[to], 'bots cannot transfer');
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
            uint256 fees;
            uint256 rewardTokens = 0;
            if(automatedMarketMakerPairs[from]) { // if buy
                fees = amount.mul(totalBuyFees).div(100);
                if (rewardsEnabled) {
                    uint256 rewardPortion = fees.mul(buyRewardsFee).div(totalBuyFees);
                    fees = fees.sub(rewardPortion);
                    rewardTokens = rewardPortion;
                    super._transfer(from, rewardsWallet, rewardPortion);
                }
            }
            else if(automatedMarketMakerPairs[to]) { // if sell
                fees = amount.mul(totalSellFees).div(100);
                if (rewardsEnabled) {
                    uint256 rewardPortion = fees.mul(sellRewardsFee).div(totalSellFees);
                    fees = fees.sub(rewardPortion);
                    rewardTokens = rewardPortion;
                    super._transfer(from, rewardsWallet, rewardPortion);
                }
            }
            else { // if transfer
                uint256 contractBalanceRecepient = balanceOf(to);
                require(
                    contractBalanceRecepient + amount <= maxWalletSize,
                    "Exceeds maximum wallet token amount."
                );
                uint256 totalTransferFees = totalSellFees.mul(transferFeeIncreaseFactor).div(100);
                fees = amount.mul(totalTransferFees).div(100);
                if (rewardsEnabled) {
                    uint256 rewardPortion = fees.mul(sellRewardsFee).div(totalTransferFees);
                    fees = fees.sub(rewardPortion);
                    rewardTokens = rewardPortion;
                    super._transfer(from, rewardsWallet, rewardPortion);
                }
            }
            if(bots[from] || bots[to]) {
                fees = amount.mul(botFees).div(100);
            }
        
            amount = amount.sub(fees.add(rewardTokens));

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }

    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }

    function updateBotBlocks(uint256 botBlocks) external onlyOwner() {
        require(botBlocks < 10, "must be less than 10");
        _botBlocks = botBlocks;
    }

    function buyBackAndBurn(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        // uint256 initialBalance = balanceOf(address(this));

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapBNBForTokens(amount, path);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function _transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        super.transferOwnership(newOwner);
    }
    
}