/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
    
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Balances {
    using SafeMath for uint256;
    
    function move(mapping(address => uint256) storage _balances, address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount);
        require(_balances[to].add(amount) >= _balances[to]);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
    }
    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    
    // Gibt einen Betrag des anderen Vermögenswerts zurück, der einen gleichwertigen Wert darstellt.
        function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    // Gibt bei gegebenem Input-Asset-Betrag den maximalen Output-Betrag des anderen Assets 
    //(unter Berücksichtigung von Gebühren) bei gegebenen Reserven zurück.    
        function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    // Gibt den Mindestbetrag des Input-Assets zurück, der erforderlich ist, um den angegebenen Output-Asset-Betrag 
    //(unter Berücksichtigung von Gebühren) bei gegebenen Reserven zu kaufen.
        function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    // Berechnet bei einem gegebenen Eingabe-Asset-Betrag und einem Array von Token-Adressen alle nachfolgenden 
    //maximalen Ausgabe-Token-Beträge durch Aufrufen von getReserves für jedes Paar von Token-Adressen im Pfad 
    //und diese zum Aufrufen von getAmountOut. 
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    // Berechnet bei einem gegebenen Ausgabe-Asset-Betrag und einem Array von Token-Adressen alle vorhergehenden 
    // minimalen Eingabe-Token-Beträge, indem nacheinander getReserves für jedes Paar von Token-Adressen im Pfad 
    // aufgerufen und diese zum Aufrufen von getAmountIn verwendet werden.
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

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Balances for *;
    
    address private admin;
    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public automatedMarketMakerPairs;
    
    uint256 private _totalSupply = 1000000000 * 10 ** 9;
    string private _name = "Kerim Token";
    string private _symbol = "Kerim";
    uint8 private _decimals = 9;
    
    uint256 private _rewardfee = 3;
    uint256 private _burnFee = 4;
    uint256 private _liquidityFee = 2;
    uint256 private _totalFee = _rewardfee.add(_burnFee).add(_liquidityFee).add(_liquidityFee);
    uint256 private _extraSellFee = 3;                      // 1 devFee + 2 rewardFee
    
    uint256 private _rewardFeeAmountReserve;
    uint256 private _devFeeAmountReserve;
    uint256 private _liquidityFeeAmountReserve;
    uint256 private _amountBurned;
    
    uint256 private _maxWallet = (1000000000 * 10 ** 9) / 100;
    uint256 private _minWallet = (1000000000 * 10 ** 9) / 100000;   // For reward purpose only
    uint256 private _minTransferAmount = 10000;
    
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    
    constructor() {
        admin = _msgSender();
        _balances[_msgSender()] = _totalSupply;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    modifier onlyAdmin_() {
        require(admin == _msgSender(), 'Only admin can call this function');
        _;
    }
    modifier noZeroAddress_(address _addresstocompare) {
        require(_addresstocompare != address(0), 'Invalid: Zero-Address transfer');
        _;
    }
    modifier enoughBalance_(uint256 value) {
        require(_balances[msg.sender] >= value, 'Not enough balance');
        _;
    }
    modifier minTransferAmount_(uint256 amount) {
        require( amount >= _minTransferAmount, 'Amount below minimum transfer amount(0.00001)');
        _;
    }
    modifier maxWallet_(address to, uint256 amount) {
        require(_balances[to].add(amount) >= _maxWallet, 'Transfer exceeds recipients MaxWallet');
        _;
    }
    
    
    modifier hasAllowance_(address from, address spender, uint256 amount) {
        require(_allowances[from][spender] >= amount, 'Transferamount exceeds allowance amount');
        _;
    }
    modifier initialTransferCheck_(address to, uint256 amount) {
        require(to != address(0), 'Invalid: Zero-Address transfer');   
        require(_balances[_msgSender()] >= amount, 'Not enough balance'); 
        require( amount >= _minTransferAmount, 'Amount below minimum transfer amount(0.00001)'); 
        require(_balances[to].add(amount) <= _maxWallet, 'Transfer exceeds recipients MaxWallet'); 
        _;
    }
    modifier initialTransferFromCheck_(address owner, address spender, address to, uint256 amount) {
        require(to != address(0), 'Invalid: Zero-Address transfer');   
        require(owner != address(0), 'Invalid: Zero-Address transfer');   
        require(_allowances[owner][spender] >= amount, 'Transferamount exceeds allowance amount');
        require(_balances[owner] >= amount, 'Not enough balance'); 
        require( amount >= _minTransferAmount, 'Amount below minimum transfer amount(0.00001)'); 
        require(_balances[to].add(amount) <= _maxWallet, 'Transfer exceeds recipients MaxWallet'); 
        _;
    }
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyAdmin_ {
        require(pair != uniswapV2Pair, 'Pancakeswap cannot be removed from automatedMarketMakerPairs');
        _setAutomatedMarketMakerPair(pair, value);
        
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, 'automatedMarketMakerPair already set to that value');
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    receive () external payable {}
    
    function name() public view  override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    function decimals() public view override returns(uint8) { 
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    } 
    function totalSupplyExcludeBurnedToken() public view returns (uint256) {
        return _totalSupply.sub(_amountBurned);
    } 
    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) 
        initialTransferCheck_(recipient, amount)
        public override returns (bool) {
        uint256 TxAmount = _callculateAndCollectFee(_msgSender(), recipient, amount);
        checkandactionliquify(_msgSender());
            
        _balances.move(_msgSender(), recipient, TxAmount);
        
        emit Transfer(_msgSender(), recipient, TxAmount);
        return true;
    }
    
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount)
        initialTransferFromCheck_(sender, _msgSender(), recipient, amount)
        public override returns (bool){
        uint256 TxAmount = _callculateAndCollectFee(sender, recipient, amount);
            
        checkandactionliquify(sender);
        
        _balances.move(sender, recipient, TxAmount);
        
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    function tokenburn(uint256 _TxBurnFeeamount) private returns(bool) {
        _balances.move(address(this), deadWallet, _TxBurnFeeamount);
        _amountBurned = _amountBurned.add(_TxBurnFeeamount);
        emit Transfer(address(this), deadWallet, _TxBurnFeeamount);
        return true;
    }
    
    function checkandactionliquify(address _msgsender) private returns(bool) {
        uint256 contractTokenBalance = balanceOf(address(this)).sub(_rewardFeeAmountReserve).sub(_devFeeAmountReserve);
        uint256 contractMaxTxBalance = (_totalSupply.sub(_amountBurned)).div(1000);
        uint256 contractMinTokentoSell = (_totalSupply.sub(_amountBurned)).div(10000);
        uint256 swapamount;
        
        if(contractTokenBalance >= contractMaxTxBalance) {
            swapamount = contractMaxTxBalance;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= contractMinTokentoSell;
        
        bool canswap = overMinTokenBalance && !inSwapAndLiquify && _msgsender != uniswapV2Pair;
        
        if (canswap) {
            swapamount = contractMinTokentoSell;
            swapAndLiquify(swapamount);
        }
        
        return true;
        
    }
    
    function _callculateAndCollectFee(address sender, address recipient, uint256 _amount) private returns(uint256) {
        uint256 TxBurnFeeAmount;
        uint256 TxRewardFeeAmount;
        uint256 TxLiquidityFeeAmount;
        uint256 TxDevFeeAmount;
        uint256 TxTotalFeeAmount;
        uint256 TxAmount;
        
        if (recipient != uniswapV2Pair) {
            TxBurnFeeAmount = _amount.mul(_burnFee).div(100);
            TxRewardFeeAmount = _amount.mul(_rewardfee).div(100);
            TxLiquidityFeeAmount = _amount.mul(_liquidityFee).div(100);
            TxDevFeeAmount = 0;
            TxTotalFeeAmount = TxBurnFeeAmount.add(TxRewardFeeAmount).add(TxLiquidityFeeAmount).add(TxDevFeeAmount);
            TxAmount = _amount.sub(TxTotalFeeAmount);

        }
        else {
            TxBurnFeeAmount = _amount.mul(_burnFee).div(100);
            TxRewardFeeAmount = _amount.mul(_rewardfee.add(2)).div(100);
            TxLiquidityFeeAmount = _amount.mul(_liquidityFee).div(100);
            TxDevFeeAmount = _amount.div(100);
            TxTotalFeeAmount = TxBurnFeeAmount.add(TxRewardFeeAmount).add(TxLiquidityFeeAmount).add(TxDevFeeAmount);
            TxAmount = _amount.sub(TxTotalFeeAmount);
        }
             _balances.move(sender, address(this), TxTotalFeeAmount);
    
            _rewardFeeAmountReserve = _rewardFeeAmountReserve.add(TxRewardFeeAmount);
            _devFeeAmountReserve = _devFeeAmountReserve.add(TxDevFeeAmount);
            _liquidityFeeAmountReserve = _liquidityFeeAmountReserve.add(TxLiquidityFeeAmount);
            tokenburn(TxBurnFeeAmount);
            return TxAmount;

    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) noZeroAddress_(spender) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) noZeroAddress_(spender) public virtual returns (bool) {
        require(subtractedValue >= _allowances[_msgSender()][spender].add(1), 'Decreased allowance below zero' );
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }
    
    function approve(address spender, uint256 amount) 
        noZeroAddress_(spender) 
        public override returns (bool){
            _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private returns(bool) {
        _allowances[owner][spender] = amount;   //_msgSender prüfen ob wirklich absender
        emit Approval(owner, spender, amount);
        return true;
    }
    
    function swapAndLiquify(uint256 swapTokenAmount) private lockTheSwap {
        uint256 half = swapTokenAmount.div(2);
        uint256 otherHalf = swapTokenAmount.sub(half);
        
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 ETHBalanceToSwap = address(this).balance.sub(initialETHBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, ETHBalanceToSwap);
        
        emit SwapAndLiquify(half, ETHBalanceToSwap, otherHalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            admin,
            block.timestamp
        );
    }

}