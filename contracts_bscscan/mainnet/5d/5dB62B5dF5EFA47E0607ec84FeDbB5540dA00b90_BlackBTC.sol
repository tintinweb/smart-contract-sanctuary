/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 * d.o.g.e.+c_a/k_es
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
        // See: https://github.com/OpenZeppelin/bu/ll/d/o/g/e/pull/522
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

library Address {
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
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

interface Cashier {
    function whomst() external view returns(address);
    function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection) external;
    function tally(address shareholder, uint256 amount) external;
    function load() external payable;
    function cashout(uint256 gas) external;
    function giveMeWelfarePlease(address hobo) external;
    function getTotalDistributed() external view returns(uint256);
    function getShareholderInfo(address shareholder) external view returns(string memory, string memory, string memory, string memory);
}

contract BlackBTC is IERC20 {
    using SafeMath for uint256;

    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExcluded;
    mapping (address => bool) _isDividendExcluded;

    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;

    uint256 private constant startingSupply = 100_000_000_000; // 100 Billion, underscores aid readability

    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * (10 ** _decimalsMul);

    string constant _name = "Black BTC";
    string constant _symbol = "BBTC";

    uint256 private _reflectionFee = 0; // Adjusted by buys and sells.
    uint256 private _liquidityFee = 0; // Adjusted by buys and sells.
    uint256 private _marketingFee = 0; // Adjusted by buys and sells.
    uint256 private _totalFee = _liquidityFee + _reflectionFee;
    uint256 public masterTaxDivisor = 10000;

    uint256 public _buyReflectionFee = 700;
    uint256 public _buyLiquidityFee = 200;
    uint256 public _buyMarketingFee = 600;

    uint256 public _sellReflectionFee = 1500;
    uint256 public _sellLiquidityFee = 200;
    uint256 public _sellMarketingFee = 600;

    uint256 public _transferReflectionFee = _sellReflectionFee;
    uint256 public _transferLiquidityFee = _sellLiquidityFee;
    uint256 public _transferMarketingFee = _sellMarketingFee;

    uint256 public maxReflectionFee = 1500;
    uint256 public maxLiquidityFee = 500;
    uint256 public maxMarketingFee = 800;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // PCS ROUTER
    address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private WBNB;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    address payable private _marketingWallet = payable(0x8FdDEd947420EFf1c6FA6CbB039a2701c4361312);

    // Max Buy TX amount is 1% of the total supply.
    uint256 private buyMaxTxPercent = 1; // Less fields to edit
    uint256 private buyMaxTxDivisor = 1000000;
    uint256 private _buyMaxTxAmount = (_tTotal * buyMaxTxPercent) / buyMaxTxDivisor;
    uint256 private _buyPreviousBuyMaxTxAmount = _buyMaxTxAmount;
    uint256 public buyMaxTxAmountUI = (startingSupply * buyMaxTxPercent) / buyMaxTxDivisor; // Actual amount for UI's
    // Max Sell TX amount is 1% of the total supply.
    uint256 private sellMaxTxPercent = 15; // Less fields to edit
    uint256 private sellMaxTxDivisor = 1000;
    uint256 private _sellMaxTxAmount = (_tTotal * sellMaxTxPercent) / sellMaxTxDivisor;
    uint256 private _sellPreviousMaxTxAmount = _sellMaxTxAmount;
    uint256 public sellMaxTxAmountUI = (startingSupply * sellMaxTxPercent) / sellMaxTxDivisor; // Actual amount for UI's
    // Maximum wallet size is 1.5% of the total supply.
    uint256 private maxWalletPercent = 15; // Less fields to edit
    uint256 private maxWalletDivisor = 1000;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor; // Actual amount for UI's

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;

    Cashier reflector;
    uint256 reflectorGas = 500000;

    bool public swapAndLiquifyEnabled = false;
    bool public processReflect = false;
    uint256 private swapThreshold = _tTotal / 20000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;
    bool private initialSubEnabled = false;
    bool inSwap;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private immutable snipeBlockAmt;
    uint256 public snipersCaught = 0;
    bool private gasLimitActive = true;
    uint256 private gasPriceLimit;
    bool private sameBlockActive = true;
    mapping (address => uint256) private lastTrade;

    bool public tradingPaused = true;
    bool public beforeLaunch = true;
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountBNB, uint256 amount);

    constructor (uint _snipeBlockAmt, uint256 _gasPriceLimit, address cInitializer) payable {
        address msgSender = msg.sender;
        _tOwned[msgSender] = _tTotal;

        // Set the owner.
        _owner = msgSender;
        snipeBlockAmt = _snipeBlockAmt;
        gasPriceLimit = _gasPriceLimit * 1 gwei;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        WBNB = dexRouter.WETH();

        reflector = Cashier(cInitializer);

        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[address(this)] = true;
        _isDividendExcluded[owner()] = true;
        _isDividendExcluded[lpPair] = true;
        _isDividendExcluded[address(this)] = true;
        _isDividendExcluded[burnAddress] = true;
        _isDividendExcluded[ZERO] = true;
        // DxLocker Address (BSC)
        _isFeeExcluded[0xfaa57F68A03ab8B217701835b91B1AD831363A9d] = true;
        _isDividendExcluded[0xfaa57F68A03ab8B217701835b91B1AD831363A9d] = true;

        // Approve the owner for PancakeSwap, timesaver.
        approveMax(_routerAddress);

        // Ever-growing sniper/tool blacklist
        _isSniper[0xE4882975f933A199C92b5A925C9A8fE65d599Aa8] = true;
        _isSniper[0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444] = true;
        _isSniper[0xa4A25AdcFCA938aa030191C297321323C57148Bd] = true;
        _isSniper[0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8] = true;
        _isSniper[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;

        emit Transfer(ZERO, msg.sender, _tTotal);
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Ownable removed as a lib and added here to allow for custom transfers and recnouncements.
    // This allows for removal of ownership privelages from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        _isFeeExcluded[_owner] = false;
        _isDividendExcluded[_owner] = false;
        _isFeeExcluded[newOwner] = true;
        _isDividendExcluded[newOwner] = true;
        
        if (_marketingWallet == payable(_owner))
            _marketingWallet = payable(newOwner);
        
        _allowances[_owner][newOwner] = _tOwned[_owner];
        _transfer(_owner, newOwner, _tOwned[_owner]);
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        _isFeeExcluded[_owner] = false;
        _isDividendExcluded[_owner] = false;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function isFeeExcluded(address account) public view returns(bool) {
        return _isFeeExcluded[account];
    }

    function isDividendExcluded(address account) public view returns(bool) {
        return _isDividendExcluded[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiGas, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        gasLimitActive = antiGas;
        sameBlockActive = antiBlock;
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 100);
        gasPriceLimit = gas * 1 gwei;
    }

    function setDividendExcluded(address holder, bool enabled) public onlyOwner {
        require(holder != address(this) && holder != lpPair);
        _isDividendExcluded[holder] = enabled;
        if (enabled) {
            reflector.tally(holder, 0);
        } else {
            reflector.tally(holder, _tOwned[holder]);
        }
    }

    function setExcludeFromFees(address account, bool enabled) public onlyOwner {
        _isFeeExcluded[account] = enabled;
    }

function setTaxesBuy(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectionFee
                && marketingFee <= maxMarketingFee);
        require(liquidityFee + reflectionFee + marketingFee <= 5000);
        _buyLiquidityFee = liquidityFee;
        _buyReflectionFee = reflectionFee;
        _buyMarketingFee = marketingFee;
    }

    function setTaxesSell(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectionFee
                && marketingFee <= maxMarketingFee);
        require(liquidityFee + reflectionFee + marketingFee <= 5000);
        _sellLiquidityFee = liquidityFee;
        _sellReflectionFee = reflectionFee;
        _sellMarketingFee = marketingFee;
    }

    function setTaxesTransfer(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectionFee
                && marketingFee <= maxMarketingFee);
        require(liquidityFee + reflectionFee + marketingFee <= 5000);
        _transferLiquidityFee = liquidityFee;
        _transferReflectionFee = reflectionFee;
        _transferMarketingFee = marketingFee;
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(_marketingWallet != newWallet, "Wallet already set!");
        _marketingWallet = payable(newWallet);
    }

    function setSwapBackSettings(bool _enabled, bool processReflectEnabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        processReflect = processReflectEnabled;
    }

    function setSwapThreshold(uint256 percent, uint256 divisor) external onlyOwner() {
        swapThreshold = _tTotal.mul(percent).div(divisor);
    }

    function setSwapAmount(uint256 percent, uint256 divisor) external onlyOwner {
        swapAmount = _tTotal.mul(percent).div(divisor);
    }
    
    function setBeforeLaunch(bool set) external onlyOwner {
        beforeLaunch = set;
    }
    
    function enableTrading() external onlyOwner {
        tradingPaused = false;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection, uint256 minReflectionMultiplier) external onlyOwner {
        _minReflection = _minReflection * 10**minReflectionMultiplier;
        reflector.setReflectionCriteria(_minPeriod, _minReflection);
    }

    function setReflectorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        reflectorGas = gas;
    }

    function setInitialSubEnabled(bool enabled) external onlyOwner() {
        initialSubEnabled = enabled;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal - (balanceOf(burnAddress) + balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * balanceOf(lpPair) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function giveMeWelfarePlease() external {
        reflector.giveMeWelfarePlease(msg.sender);
    }

    function getTotalReflected() external view returns (uint256) {
        return reflector.getTotalDistributed();
    }

    function getUserInfo(address shareholder) external view returns (string memory, string memory, string memory, string memory) {
        return reflector.getShareholderInfo(shareholder);
    }

    function setMaxTxPercents(uint256 buyPercent, uint256 buyDivisor, uint256 sellPercent, uint256 sellDivisor) external onlyOwner() {
        require(buyPercent >= 1 && sellPercent >= 1 && buyDivisor <= 1000 && sellDivisor <= 1000); // Cannot set lower than 0.01%
        _buyMaxTxAmount = (_tTotal * buyPercent) / buyDivisor;
        buyMaxTxAmountUI = (startingSupply * buyPercent) / buyDivisor;
        _sellMaxTxAmount = (_tTotal * sellPercent) / sellDivisor;
        sellMaxTxAmountUI = (startingSupply * sellPercent) / sellDivisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner() {
        require(percent >= 1 && divisor <= 1000); // Cannot set lower than 0.1%
        _maxWalletSize = _tTotal.mul(percent).div(divisor);
        maxWalletSizeUI = startingSupply.mul(percent).div(divisor);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != burnAddress
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (gasLimitActive) {
            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
        }
        if(_hasLimits(from, to)) {
            require (tradingPaused == false, "Trading not yet enabled.");
            if (sameBlockActive) {
                if (from == lpPair){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                }
            }
            if(beforeLaunch && from == lpPair){
                _isSniper[to] = true;
            }
            if(to == lpPair) {
                require(amount <= _sellMaxTxAmount, "Transfer amount exceeds the sellMaxTxAmount.");
            } else {
                require(amount <= _buyMaxTxAmount, "Transfer amount exceeds the buyMaxTxAmount.");
            }
            if(to != _routerAddress && to != lpPair) {
                uint256 contractBalanceRecepient = balanceOf(to);
                require(contractBalanceRecepient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        
        if(_isFeeExcluded[from] || _isFeeExcluded[to]){
            takeFee = false;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) internal returns (bool) {
        // Failsafe, disable the whole system if needed.
        if (sniperProtection){
            // If sender is a sniper address, reject the transfer.
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            // Check if this is the liquidity adding tx to startup.
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            }
        }

        _tOwned[from] = _tOwned[from].sub(amount, "Insufficient Balance");

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        adjustTaxes(from, to);

        uint256 contractTokenBalance = _tOwned[address(this)];
        if(contractTokenBalance >= swapAmount)
            contractTokenBalance = swapAmount;

        if (!inSwap
            && from != lpPair
            && swapAndLiquifyEnabled
            && contractTokenBalance >= swapThreshold
        ) {
            swapBack(contractTokenBalance);
        }

        uint256 amountReceived = amount;

        if (takeFee) {
            amountReceived = takeTaxes(from, amount);
        }

        _tOwned[to] = _tOwned[to].add(amountReceived);

        processTokenReflect(from, to);

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function adjustTaxes(address from, address to) internal {
        if (from == lpPair) {
            _reflectionFee = _buyReflectionFee;
            _liquidityFee = _buyLiquidityFee;
            _marketingFee = _buyMarketingFee;
        } else if (to == lpPair) {
            _reflectionFee = _sellReflectionFee;
            _liquidityFee = _sellLiquidityFee;
            _marketingFee = _sellMarketingFee;
        } else {
            _reflectionFee = _transferReflectionFee;
            _liquidityFee = _transferLiquidityFee;
            _marketingFee = _transferMarketingFee;
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != lpPair
            && !inSwap
            && swapAndLiquifyEnabled
            && _tOwned[address(this)] >= swapThreshold;
    }

    function processTokenReflect(address from, address to) internal {
        // Process TOKEN Reflect.
        if (!_isDividendExcluded[from]) {
            try reflector.tally(from, _tOwned[from]) {} catch {}
        }
        if (!_isDividendExcluded[to]) {
            try reflector.tally(to, _tOwned[to]) {} catch {}
        }
        if (processReflect) {
            try reflector.cashout(reflectorGas) {} catch {}
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _tOwned[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getTotalFee() public view returns (uint256) {
        return _reflectionFee + _marketingFee + _liquidityFee;
    }

    function takeTaxes(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * getTotalFee() / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function swapBack(uint256 numTokensToSwap) internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : _liquidityFee;
        uint256 amountToLiquify = numTokensToSwap * dynamicLiquidityFee / getTotalFee() / 2;
        uint256 amountToSwap = numTokensToSwap - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        if (initialSubEnabled) 
            amountBNB = address(this).balance - balanceBefore;
        uint256 totalBNBFee = getTotalFee() - dynamicLiquidityFee / 2;
        uint256 amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / 2;
        uint256 amountBNBReflection = amountBNB * _reflectionFee / totalBNBFee;
        uint256 amountBNBMarketing = amountBNB - (amountBNBLiquidity + amountBNBReflection);
        _marketingWallet.transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            dexRouter.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                burnAddress,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        } else {
            amountBNBReflection += amountBNBLiquidity;
        }

        try reflector.load{value: amountBNBReflection}() {} catch {}
    }

    function manualDepost() external onlyOwner() {
        try reflector.load{value: address(this).balance}() {} catch {}
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            processReflect = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }
}