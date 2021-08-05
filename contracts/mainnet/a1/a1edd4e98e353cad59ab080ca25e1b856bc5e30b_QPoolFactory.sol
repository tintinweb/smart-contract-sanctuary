/**
 *Submitted for verification at Etherscan.io on 2020-12-21
*/

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: contracts/QPool.sol



pragma solidity ^ 0.6.6;




contract QPool {
    using SafeMath for uint256;

    address public creator;
    string public poolName;
    address[] private tokens;
    uint[] private amounts;
    address private uniswapFactoryAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;

    event TradeCompleted(uint256[] acquired);
    event DepositProcessed(uint256 amount);
    event WithdrawalProcessed(uint256 amount);

    constructor(
        string memory _poolName,
        address[] memory _tokens,
        uint[] memory _amounts,
        address _creator
    ) public {
        uint _total = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            _total += _amounts[i];
        }
        require(_total == 100);
        creator = _creator;
        poolName = _poolName;
        tokens = _tokens;
        amounts = _amounts;
        uniswapRouter = IUniswapV2Router02(uniswapFactoryAddress);
    }

    fallback() external payable {
        require(msg.sender == creator);
        require(msg.data.length == 0);
        processDeposit();
    }

    receive() external payable {
        require(msg.sender == creator);
        require(msg.data.length == 0);
        processDeposit();
    }

    function close() external {
        require(msg.sender == creator);
        withdrawEth(100);
        selfdestruct(msg.sender);
    }

    function processDeposit() public payable {
        require(msg.sender == creator);
        require(msg.value > 10000000000000000, "Minimum deposit amount is 0.01 ETH");
        address[] memory _path = new address[](2);
        _path[0] = uniswapRouter.WETH();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 time = now + 15 + i;
            _path[1] = tokens[i];
            uint256 _amountEth = msg.value.mul(amounts[i]).div(100);
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountEth, _path);
            uint256[] memory _output = uniswapRouter.swapExactETHForTokens.value(_expected[0])(_expected[1], _path, address(this), time);
            emit TradeCompleted(_output);
        }
        emit DepositProcessed(msg.value);
    }

    function withdrawEth(uint256 _percent) public {
        require(msg.sender == creator, "Only the creator can withdraw ETH.");
        require(_percent > 0 && _percent <= 100, "Percent must be between 0 and 100.");
        address[] memory _path = new address[](2);
        uint256 total = 0;
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 _token = IERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_percent).div(100);
            require(_amountOut > 0, "Amount out is 0.");
            require(_token.approve(address(uniswapRouter), _amountOut), "Approval failed");
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountOut, _path);
            require(_expected[1] > 1000000, "Amount is too small to transfer");
            uint256 _time = now + 15 + i;
            uint256[] memory _output = uniswapRouter.swapExactTokensForETH(_expected[0], _expected[1], _path, creator, _time);
            total += _output[1];
            emit TradeCompleted(_output);
        }
        emit WithdrawalProcessed(total);
    }

    function totalValue() public view returns (uint256) {
        uint256 _totalValue = 0;
        address[] memory _path = new address[](2);
        for (uint i = 0; i < tokens.length && i <= 5; i++) {
            IERC20 _token = IERC20(tokens[i]);
            uint256 _totalBalance = _token.balanceOf(address(this));
            if (_totalBalance == 0) return 0;
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _ethValue = uniswapRouter.getAmountsOut(_totalBalance, _path);
            _totalValue += _ethValue[1];
        }
        return _totalValue;
    }
    
    function withdrawTokens() public {
        require(msg.sender == creator, "Only the creator can withdraw tokens");
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 _token = IERC20(tokens[i]);
            uint256 _tokenBalance = _token.balanceOf(address(this));
            _token.transfer(creator, _tokenBalance);
        }
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getAmounts() public view returns (uint[] memory) {
        return amounts;
    }

    function isPublic() public pure returns (bool _isPublic) {
        return false;
    }

}

// File: @openzeppelin/contracts/GSN/Context.sol



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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



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
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol



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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



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

// File: contracts/QPoolPublic.sol



pragma solidity ^ 0.6.6;





contract QPoolPublic is ERC20, ERC20Burnable, ReentrancyGuard {
    using SafeMath for uint256;

    string public poolName;
    address[] private tokens;
    uint256[] private amounts;
    address public creator;
    address private uniswapFactoryAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;
    
    address[] private depositors;
    mapping(address => uint) private deposits;
    
    event TradeCompleted(uint256[] acquired);
    event DepositProcessed(uint256 amount);
    event WithdrawalProcessed(uint256 amount);
    
    constructor (
        string memory _poolName,
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _creator
        ) ERC20 ("QPoolDepositToken", "QPDT") public {
            uint256 _total = 0;
            require(tokens.length <= 5 && tokens.length == amounts.length);
            for (uint256 i = 0; i < _amounts.length && i <= 5; i++) {
                _total += _amounts[i];
            }
            require(_total == 100);
            poolName = _poolName;
            tokens = _tokens;
            amounts = _amounts;
            creator = _creator;
            uniswapRouter = IUniswapV2Router02(uniswapFactoryAddress);
        }
    
    fallback() external payable nonReentrant {
        require(msg.data.length == 0);
        processDeposit();
    }

    receive() external payable nonReentrant {
        require(msg.data.length == 0);
        processDeposit();
    }

    function processDeposit() public payable nonReentrant {
        uint256 _newIssuance = calculateShare();
        if (deposits[msg.sender] == 0) addDepositor(msg.sender);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        require(makeExchange());
        _mint(msg.sender, _newIssuance);
        emit DepositProcessed(msg.value);
    }

    function makeExchange() private returns (bool) {
        address[] memory _path = new address[](2);
        for (uint256 i = 0; i < tokens.length && i<= 5; i++) {
            _path[0] = uniswapRouter.WETH();
            _path[1] = tokens[i];
            uint256 _time = now + 15 + i;
            uint256 _amountEth = msg.value.mul(amounts[i]).div(100);
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountEth, _path);
            uint256[] memory _output = uniswapRouter.swapExactETHForTokens.value(_expected[0])(_expected[1], _path, address(this), _time);
            emit TradeCompleted(_output);
        }
        return true;
    }

    function totalValue() public view returns (uint256) {
        uint256 _totalValue = 0;
        address[] memory _path = new address[](2);
        for (uint i = 0; i < tokens.length && i <= 5; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _totalBalance = _token.balanceOf(address(this));
            if (_totalBalance == 0) return 0;
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _ethValue = uniswapRouter.getAmountsOut(_totalBalance, _path);
            _totalValue += _ethValue[1];
        }
        return _totalValue;
    }

    function calculateShare() private view returns (uint256) {
        if (totalSupply() == 0) {
            return 1000000000000000000000;
        } else {
            uint256 _totalValue = totalValue();
            uint256 _tmp = 100;
            uint256 _poolShare = _tmp.mul(msg.value).div(_totalValue);
            uint256 _mintAmount = totalSupply().mul(_poolShare).div(100);
            return _mintAmount;
        }
    }
    
    function withdrawEth(uint256 _percent) public nonReentrant {
        require(_percent > 0);
        uint256 _userShare = balanceOf(msg.sender);
        uint256 _burnAmount = _userShare.mul(_percent).div(100);
        uint256 _tmp = 100;
        uint256 _poolShare = _tmp.mul(_userShare).div(totalSupply());
        require(balanceOf(msg.sender) >= _burnAmount);
        require(approve(address(this), _burnAmount));
        _burn(msg.sender, _burnAmount);
        deposits[msg.sender] = deposits[msg.sender].sub((deposits[msg.sender]).mul(_percent).div(100));
        if (deposits[msg.sender] == 0) removeDepositor(msg.sender);
        (bool success, uint256 total) = sellTokens(_poolShare, _percent);
        require(success);
        emit WithdrawalProcessed(total);
    }

    function sellTokens(uint256 _poolShare, uint256 _percent) private returns (bool, uint256) {
        uint256 total = 0;
        address[] memory _path = new address[](2);
        for (uint256 i = 0; i < tokens.length && i <= 5; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_poolShare).mul(_percent).div(10000);
            require(_amountOut > 0);
            require(_token.approve(address(uniswapRouter), _amountOut));
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountOut, _path);
            require(_expected[1] > 1000000);
            uint256 _time = now + 15 + i;
            uint256[] memory _output = uniswapRouter.swapExactTokensForETH(_expected[0], _expected[1], _path, msg.sender, _time);
            total += _output[1];
            emit TradeCompleted(_output);
        }
        return (true, total);
    }

    function withdrawTokens() public nonReentrant {
        uint256 _userShare = balanceOf(msg.sender);
        uint256 _poolShare = _userShare.div(totalSupply()).mul(100);
        _burn(msg.sender, _userShare);
        removeDepositor(msg.sender);
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_poolShare).div(100);
            require(_token.approve(msg.sender, _amountOut));
            require(_token.transfer(msg.sender, _amountOut));
        }
    }
    
    function isDepositor(address _address) public view returns (bool, uint256) {
        for (uint256 i = 0; i < depositors.length; i++) {
            if (_address == depositors[i]) return (true, i);
        }
        return (false, 0);
    }
        
    function totalDeposits() public view returns (uint256) {
        uint256 _totalDeposits = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            _totalDeposits = _totalDeposits.add(deposits[depositors[i]]);
        }
        return _totalDeposits;
    }
    
    function addDepositor(address _depositor) private {
        (bool _isDepositor, ) = isDepositor(_depositor);
        if(!_isDepositor) depositors.push(_depositor);
    }
    
    function removeDepositor(address _depositor) private {
        (bool _isDepositor, uint256 i) = isDepositor(_depositor);
        if (_isDepositor) {
            depositors[i] = depositors[depositors.length - 1];
            depositors.pop();
        }
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getAmounts() public view returns (uint[] memory) {
        return amounts;
    }

    function isPublic() public pure returns (bool _isPublic) {
        return true;
    }
}

// File: contracts/QPoolFactory.sol



pragma solidity ^ 0.6.6;



contract QPoolFactory {
    address[] private privatePools;
    address[] private publicPools;
    mapping(address => bool) private isPool;

    event PoolCreated(QPool pool);
    event PublicPoolCreated(QPoolPublic pool);

    function getPrivatePools() public view returns (address[] memory) {
        return privatePools;
    }

    function getPublicPools() public view returns (address[] memory) {
        return publicPools;
    }

    function checkPool(address _poolAddress) public view returns (bool) {
        return isPool[_poolAddress];
    }

    function newPool(string memory _name, address[] memory _tokens, uint[] memory _amounts)
    public returns (address) {
        QPool pool = new QPool(_name, _tokens, _amounts, msg.sender);
        emit PoolCreated(pool);
        privatePools.push(address(pool));
        isPool[address(pool)] = true;
        return address(pool);
    }

    function newPublicPool(string memory _name, address[] memory _tokens, uint[] memory _amounts)
    public returns (address) {
        QPoolPublic pool = new QPoolPublic(_name, _tokens, _amounts, msg.sender);
        emit PublicPoolCreated(pool);
        publicPools.push(address(pool));
        isPool[address(pool)] = true;
    }
}

// File: contracts/Migrations.sol


pragma solidity >=0.4.22 <0.8.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}