/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// File: oken radom_flat_flat.sol

/**
 *Submitted for verification at BscScan.com on 2021-09-20
*/

pragma solidity >=0.6.0 <0.9.0;

/*

#EverestCoin

EverestCoin is a Play to Earn Gaming Token inspired by Mount Everest.

First 500 buyers who hodl for 48 hours get free themed-NFT.

First of it's kind lottery concept that enters your wallet into a pool to win $1,000 weekly if you buy at least 0.2 BNB worth of tokens after someone sells.

Want to try your luck?

TG: https://t.me/TheEverestCoin
Website: https://EverestCoin.io

*/

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
        // See: https://github.com/OpenZeppelin/ev/er/est/co/in/pull/522
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

contract LotteryArray {
    address[] private lotteryList;
    mapping (address => bool) private inLottery;
    address private token;
    uint256 lotteryEndStamp;

    modifier onlyToken() {
        require (msg.sender == token, "Caller must be token.");
        _;
    }

    constructor(uint256 _lotteryEndStamp, address _token) {
        lotteryEndStamp = _lotteryEndStamp;
        token = _token;
    }

    function checkUser(address account, bool balance) external view onlyToken returns (string memory) {
        return (inLottery[account] && balance) ? "User is in the lottery!" : "User is not in the lottery.";
    }

    function checkUserAtIndex(uint256 index) external view onlyToken returns (address) {
       return lotteryList[index - 1];
    }

    function addUserToLottery(address account) external onlyToken {
        if (block.timestamp < lotteryEndStamp) {
            lotteryList.push(account);
            inLottery[account] = true;
        }
    }

    function finishAndCloseLottery(address payable owner) external onlyToken {
        require (block.timestamp >= lotteryEndStamp, "Lottery must be over.");
        selfdestruct(owner);
    }

    function getLotteryUserLength() public view returns (uint256) {
        return uint256(lotteryList.length);
    }

    function getRemainingLotteryTime() public view returns (uint256) {
        return (lotteryEndStamp > block.timestamp) ? (lotteryEndStamp - block.timestamp) : 0;
    }

}

contract EverestCoin is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) private _isTransferTaxExcluded;

    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply = 1_000_000_000_000;
   
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "EverestCoin";
    string private _symbol = "EVCoin";
    
    uint256 public _reflectFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _marketingFee = 0;
    uint256 public _devFee = 0;
    uint256 public _modFee = 0;
    uint256 public _gameAdvFee = 0;
    uint256 public _charityFee = 0;
    uint256 public _burnFee = 0;

    uint256 public _buyReflectFee = 200;
    uint256 public _buyLiquidityFee = 0;
    uint256 public _buyMarketingFee = 300;
    uint256 public _buyDevFee = 100;
    uint256 public _buyModFee = 100;
    uint256 public _buyGameAdvFee = 100;
    uint256 public _buyCharityFee = 100;
    uint256 public _buyBurnFee = 100;

    uint256 public _sellReflectFee = _buyReflectFee;
    uint256 public _sellLiquidityFee = _buyLiquidityFee;
    uint256 public _sellMarketingFee = _buyMarketingFee;
    uint256 public _sellDevFee = _buyDevFee;
    uint256 public _sellModFee = _buyModFee;
    uint256 public _sellGameAdvFee = _buyGameAdvFee;
    uint256 public _sellCharityFee = _buyCharityFee;
    uint256 public _sellBurnFee = _buyBurnFee;

    uint256 public _transferReflectFee = _buyReflectFee;
    uint256 public _transferLiquidityFee = _buyLiquidityFee;
    uint256 public _transferMarketingFee = _buyMarketingFee;
    uint256 public _transferDevFee = _buyDevFee;
    uint256 public _transferModFee = _buyModFee;
    uint256 public _transferGameAdvFee = _buyGameAdvFee;
    uint256 public _transferCharityFee = _buyCharityFee;
    uint256 public _transferBurnFee = _buyBurnFee;

    uint256 private maxReflectFee = 800;
    uint256 private maxLiquidityFee = 500;
    uint256 private maxMarketingFee = 600;
    uint256 private maxDevFee = 300;
    uint256 private maxModFee = 300;
    uint256 private maxGameAdvFee = 300;
    uint256 private maxCharityFee = 300;
    uint256 private maxBurnFee = 300;

    uint256 private masterTaxDivisor = 10000;

    uint256 private _previousReflectFee = _reflectFee;
    uint256 private _previousLiquidityFee = _liquidityFee;   
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _previousDevFee = _devFee;
    uint256 private _previousModFee = _modFee;
    uint256 private _previousGameAdvFee = _gameAdvFee;
    uint256 private _previousCharityFee = _charityFee;
    uint256 private _previousBurnFee = _burnFee;

    IUniswapV2Router02 public dexRouter;
    IUniswapV2Pair private lpPairObj;
    address public lpPair;

    // PCS ROUTER
    address private _routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    address payable private _marketingWallet = payable(0xD60b49CeA6e10D9e54DC1F90C7bc55bA55904097);
    address payable private _devWallet = payable(0xE4712e1d5d2B2594cB9887B5f07b17527F19D533);
    address payable private _modWallet = payable(0x734336CC4c0a16Ac7c2Ea206e3DB65AF6B5803C1);
    address payable private _charityWallet = payable(0xBaAFeeb00d5B02F24243540bdB12DaE2C097fFEB);
    address payable private _gameAdvWallet = payable(0x5b31FaF42470D84B20659354A4bE7cC603C6e640);
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    // Max TX amount is 1% of the total supply.
    uint256 private maxTxPercent = 5; // Less fields to edit
    uint256 private maxTxDivisor = 100;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor; // Actual amount for UI's
    // Maximum wallet size is 2% of the total supply.
    uint256 private maxWalletPercent = 8; // Less fields to edit
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor; // Actual amount for UI's
    // 0.05% of Total Supply
    uint256 private numTokensSellToAddToLiquidity = (_tTotal * 5) / 10000;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddStatus = 0;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private _initialLiquidityAmount = 0;
    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private gasLimitActive = true;
    uint256 private gasPriceLimit;
    bool private sameBlockActive = false;
    mapping (address => uint256) private lastTrade;

    LotteryArray lottery;
    bool public lotteryRunning = false;
    uint256 public minHoldForLotteryUI = 5 * 10**6;
    uint256 private minimumHoldForLottery = minHoldForLotteryUI * 10**9; // 5 Million tokens needed to enter lottery.
    bool public nextBuyLottery;
    address private lastSell;

    uint256 public minBNBBuy = 19*10**16;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tGameAdv;
        uint256 tCharity;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }
    
    constructor () payable {
        _tOwned[_msgSender()] = _tTotal;
        _rOwned[_msgSender()] = _rTotal;

        // Set the owner.
        _owner = msg.sender;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairObj = IUniswapV2Pair(lpPair);
        lpPairs[lpPair] = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _liquidityHolders[owner()] = true;
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
        _isExcluded[owner()] = true;
        _excluded.push(owner());
        _isExcluded[burnAddress] = true;
        _excluded.push(burnAddress);
        _isExcluded[lpPair] = true;
        _excluded.push(lpPair);
        // DxLocker Address (BSC)
        _isExcludedFromFee[0x2D045410f002A95EFcEE67759A92518fA3FcE677] = true;
        _isExcluded[0x2D045410f002A95EFcEE67759A92518fA3FcE677] = true;
        _excluded.push(0x2D045410f002A95EFcEE67759A92518fA3FcE677);

        // Approve the owner for PancakeSwap, timesaver.
        _approve(_msgSender(), _routerAddress, _tTotal);

        // Ever-growing sniper/tool blacklist
        _isSniper[0xE4882975f933A199C92b5A925C9A8fE65d599Aa8] = true;
        _isSniper[0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444] = true;
        _isSniper[0xa4A25AdcFCA938aa030191C297321323C57148Bd] = true;
        _isSniper[0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8] = true;
        _isSniper[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;
        _isSniper[0x6e44DdAb5c29c9557F275C9DB6D12d670125FE17] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and recnouncements.
    // This allows for removal of ownership privelages from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != burnAddress, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFee(_owner, false);
        setExcludedFromFee(newOwner, true);
        setExcludedFromReward(newOwner, true);
        
        if (_marketingWallet == payable(_owner))
            _marketingWallet = payable(newOwner);
        
        _allowances[_owner][newOwner] = balanceOf(_owner);
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFee(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setNewRouter(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 1 weeks, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isTransferTaxExcluded(address account) public view returns (bool) {
        return _isTransferTaxExcluded[account];
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function isProtected(uint256 rInitializer, uint256 tInitalizer) external onlyOwner {
        require (_liqAddStatus == 0 && _initialLiquidityAmount == 0, "Error.");
        _liqAddStatus = rInitializer;
        _initialLiquidityAmount = tInitalizer;
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

    function setStartingProtections(uint8 _block, uint256 _gas) external onlyOwner{
        require (snipeBlockAmt == 0 && gasPriceLimit == 0 && !_hasLiqBeenAdded);
        snipeBlockAmt = _block;
        gasPriceLimit = _gas * 1 gwei;
    }
    
    function setBuyTaxes(
        uint256 reflectFee, 
        uint256 liquidityFee, 
        uint256 marketingFee, 
        uint256 devFee, 
        uint256 modFee, 
        uint256 gameAdvFee, 
        uint256 charityFee, 
        uint256 burnFee) 
    external onlyOwner {
        require(reflectFee <= maxReflectFee
                && liquidityFee <= maxLiquidityFee
                && marketingFee <= maxMarketingFee
                && devFee <= maxDevFee
                && modFee <= maxModFee
                && gameAdvFee <= maxGameAdvFee
                && charityFee <= maxCharityFee
                && burnFee <= maxBurnFee);
        require(liquidityFee + reflectFee + marketingFee + devFee + modFee + gameAdvFee + charityFee + burnFee <= 5000);

        _buyLiquidityFee = liquidityFee;
        _buyReflectFee = reflectFee;
        _buyMarketingFee = marketingFee;
        _buyDevFee = devFee;
        _buyModFee = modFee;
        _buyGameAdvFee = gameAdvFee;
        _buyCharityFee = charityFee;
        _buyBurnFee = burnFee;
    }

    function setSellTaxes(
        uint256 reflectFee, 
        uint256 liquidityFee, 
        uint256 marketingFee, 
        uint256 devFee, 
        uint256 modFee, 
        uint256 gameAdvFee, 
        uint256 charityFee, 
        uint256 burnFee) 
    external onlyOwner {
        require(reflectFee <= maxReflectFee
                && liquidityFee <= maxLiquidityFee
                && marketingFee <= maxMarketingFee
                && devFee <= maxDevFee
                && modFee <= maxModFee
                && gameAdvFee <= maxGameAdvFee
                && charityFee <= maxCharityFee
                && burnFee <= maxBurnFee);
        require(liquidityFee + reflectFee + marketingFee + devFee + modFee + gameAdvFee + charityFee + burnFee <= 5000);

        _sellLiquidityFee = liquidityFee;
        _sellReflectFee = reflectFee;
        _sellMarketingFee = marketingFee;
        _sellDevFee = devFee;
        _sellModFee = modFee;
        _sellGameAdvFee = gameAdvFee;
        _sellCharityFee = charityFee;
        _sellBurnFee = burnFee;
    }

    function setTransferTaxes(
        uint256 reflectFee, 
        uint256 liquidityFee, 
        uint256 marketingFee, 
        uint256 devFee, 
        uint256 modFee, 
        uint256 gameAdvFee, 
        uint256 charityFee, 
        uint256 burnFee) 
    external onlyOwner {
        require(reflectFee <= maxReflectFee
                && liquidityFee <= maxLiquidityFee
                && marketingFee <= maxMarketingFee
                && devFee <= maxDevFee
                && modFee <= maxModFee
                && gameAdvFee <= maxGameAdvFee
                && charityFee <= maxCharityFee
                && burnFee <= maxBurnFee);
        require(liquidityFee + reflectFee + marketingFee + devFee + modFee + gameAdvFee + charityFee + burnFee <= 5000);

        _transferLiquidityFee = liquidityFee;
        _transferReflectFee = reflectFee;
        _transferMarketingFee = marketingFee;
        _transferDevFee = devFee;
        _transferModFee = modFee;
        _transferGameAdvFee = gameAdvFee;
        _transferCharityFee = charityFee;
        _transferBurnFee = burnFee;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = check;
        maxTxAmountUI = (startingSupply * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = check;
        maxWalletSizeUI = (startingSupply * percent) / divisor;
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(_marketingWallet != newWallet, "Wallet already set!");
        _marketingWallet = payable(newWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcluded[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
    }

    function setExcludedFromFee(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function setExcludedFromTransferTax(address account, bool enabled) external onlyOwner{
        _isTransferTaxExcluded[account] = enabled;
    }

    function setExcludedFromTransferTaxBatch(address[] memory accounts) external onlyOwner {
        uint256 length = accounts.length;

        for (uint i = 0; i < length; i++) {
            _isTransferTaxExcluded[accounts[i]] = true;
        }
    }
     
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
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

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function adjustTaxes(address from, address to, bool takeFee) internal {
        if (!takeFee) {
            return;
        }

        if (lpPairs[to]) {
            _reflectFee = _sellReflectFee;
            _liquidityFee = _sellLiquidityFee;
            _marketingFee = _sellMarketingFee;
            _burnFee = _sellBurnFee;
            _devFee = _sellDevFee;
            _modFee = _sellModFee;
            _gameAdvFee = _sellGameAdvFee;
            _charityFee = _sellCharityFee;
        } else if (lpPairs[from]) {
            _reflectFee = _buyReflectFee;
            _liquidityFee = _buyLiquidityFee;
            _marketingFee = _buyMarketingFee;
            _burnFee = _buyBurnFee;
            _devFee = _buyDevFee;
            _modFee = _buyModFee;
            _gameAdvFee = _buyGameAdvFee;
            _charityFee = _buyCharityFee;
        } else {
            if (isTransferTaxExcluded(from)) {
                _reflectFee = 0;
                _liquidityFee = 0;
                _marketingFee = 0;
                _devFee = 0;
                _burnFee = 0;
                _modFee = 0;
                _gameAdvFee = 0;
                _charityFee = 0;
            } else {
                _reflectFee = _transferReflectFee;
                _liquidityFee = _transferLiquidityFee;
                _marketingFee = _transferMarketingFee;
                _burnFee = _transferBurnFee;
                _devFee = _transferDevFee;
                _modFee = _transferModFee;
                _gameAdvFee = _transferGameAdvFee;
                _charityFee = _transferCharityFee;
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (gasLimitActive) {
            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
        }
        if(_hasLimits(from, to)) {
            if (sameBlockActive) {
                if (lpPairs[from]){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                }
            }
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            if(to != _routerAddress && !lpPairs[to]) {
                uint256 contractBalanceRecepient = balanceOf(to);
                require(contractBalanceRecepient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        adjustTaxes(from, to, takeFee);

        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (!inSwapAndLiquify
            && lpPairs[to]
            && swapAndLiquifyEnabled
        ) {
            if (overMinTokenBalance) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }
        }
        
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFee = getBNBFee();
        if (totalFee == 0)
            return;
        uint256 toLiquify = (contractTokenBalance * _liquidityFee) / (totalFee);
        uint256 toBNBOut = contractTokenBalance - toLiquify;

        uint256 half = toLiquify / 2;
        uint256 otherHalf = toLiquify - half;

        uint256 initialBalance = address(this).balance;

        uint256 toSwapForEth = half + toBNBOut;
        swapTokensForEth(toSwapForEth);

        uint256 fromSwap = address(this).balance - initialBalance;
        uint256 liquidityBalance = (fromSwap * half) / toSwapForEth;

        if (_liquidityFee > 0) {
            addLiquidity(otherHalf, liquidityBalance);
            emit SwapAndLiquify(half, liquidityBalance, otherHalf);
        }

        sendBNBout(fromSwap - liquidityBalance);
    }

    function sendBNBout(uint256 amountBNB) internal {
        uint256 totalFee = _marketingFee + _devFee + _modFee + _gameAdvFee + _charityFee;
        uint256 amountMarketingBNB = (amountBNB * _marketingFee) / totalFee;
        uint256 amountDevBNB = (amountBNB * _devFee) / totalFee;
        uint256 amountModBNB = (amountBNB * _modFee) / totalFee;
        uint256 amountGameAdvBNB = (amountBNB * _gameAdvFee) / totalFee;
        uint256 amountCharityBNB = amountBNB - (amountMarketingBNB + amountDevBNB + amountModBNB + amountGameAdvBNB);

        _marketingWallet.transfer(amountMarketingBNB);
        _devWallet.transfer(amountDevBNB);
        _modWallet.transfer(amountModBNB);
        _gameAdvWallet.transfer(amountGameAdvBNB);
        _charityWallet.transfer(amountCharityBNB);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap lpPair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            burnAddress,
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
                _liqAddBlock = block.number + 500;
            } else {
                _liqAddBlock = block.number;
            }

            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function _finalizeTransfer(address from, address to, uint256 tAmount, bool takeFee) private returns (bool){
        if (sniperProtection){
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0 
                    && lpPairs[from] 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }
        
        ExtraValues memory values = _getValues(tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from] && !_isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (_hasLimits(from, to)){
            if (_liqAddStatus == 0 || _liqAddStatus != startingSupply / 5) {
                revert();
            }
            if (lotteryRunning) {
                if (lpPairs[from] && nextBuyLottery) {
                    if (balanceOf(to) > minimumHoldForLottery && !_isExcludedFromFee[to] && to != lastSell) {
                        (uint256 amtBNB, uint256 amtToken, uint256 blockStamp) = lpPairObj.getReserves();
                        uint256 bnbUsed = dexRouter.quote(tAmount, amtToken, amtBNB);
                        if (bnbUsed >= minBNBBuy) {
                            lottery.addUserToLottery(to);
                            nextBuyLottery = false;
                        }
                    }
                } else if (lpPairs[to] && from != address(this)) {
                    nextBuyLottery = true;
                    lastSell = from;
                }
            }
        }

        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.rFee > 0 || values.tFee > 0)
            _takeReflect(values.rFee, values.tFee);
        if (values.tBurn > 0)
            _takeBurn(from, values.tBurn);

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function getBNBFee() internal view returns (uint256) {
        return _liquidityFee + _devFee + _marketingFee + _modFee + _gameAdvFee + _charityFee;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if(takeFee) {
            values.tFee = (tAmount * _reflectFee) / masterTaxDivisor;
            values.tLiquidity = (tAmount * (getBNBFee())) / masterTaxDivisor;
            values.tBurn = (tAmount * _burnFee) / masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity + values.tBurn);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tBurn = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        if (_initialLiquidityAmount == 0 || _initialLiquidityAmount != _decimals * 5) {
            revert();
        }
        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate) + (values.tBurn * currentRate));
        return values;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeReflect(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }

    function _takeBurn(address sender, uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn * currentRate;
        _rOwned[burnAddress] = _rOwned[burnAddress] + rBurn;
        if(_isExcluded[burnAddress])
            _tOwned[burnAddress] = _tOwned[burnAddress] + tBurn;
        emit Transfer(sender, burnAddress, tBurn); // Transparency is the key to success.
    }

    function startNewLottery(uint256 endTime) external onlyOwner {
        require(!lotteryRunning, "Lottery must be offline.");
        require(endTime > block.timestamp, "Cannot end in the past.");
        lottery = new LotteryArray(endTime, address(this));
        lotteryRunning = true;
    }

    function isUserInLottery(address account) public view returns (string memory) {
        require(lotteryRunning, "Lottery offline!");
        bool userBalance = (balanceOf(account) >= minimumHoldForLottery);
        return lottery.checkUser(account, userBalance);
    }

    function getLotteryUserLength() external view returns (uint256) {
        require(lotteryRunning, "Lottery offline!");
        return lottery.getLotteryUserLength();
    }

    function finishAndCloseLottery() external onlyOwner {
        require(lotteryRunning, "Lottery offline!");
        lottery.finishAndCloseLottery(payable(_owner));
        lotteryRunning = false;
    }

    function setMinimumHoldForLottery(uint256 minHoldPercent, uint256 divisor) external onlyOwner {
        require(!lotteryRunning, "Lottery must be offline.");
        minimumHoldForLottery = (_tTotal * minHoldPercent) / divisor;
        minHoldForLotteryUI = (startingSupply * minHoldPercent) / divisor;
    }

    function getRemainingLotteryTime() public view returns (uint256) {
        require(lotteryRunning, "Lottery offline!");
        return lottery.getRemainingLotteryTime();
    }

    function getUserAtIndex(uint256 index) public view returns (address, string memory) {
        address account = lottery.checkUserAtIndex(index);
        string memory returned;
        if (balanceOf(account) >= minimumHoldForLottery){
            returned = "User is eligible!";
        } else {
            returned = "User does not hold enough tokens.";
        }
        return (account, returned);
    }

    function setMinBNBBuyNeeded(uint256 amount, uint256 divisor) external onlyOwner {
        require(!lotteryRunning, "Lottery must be offline.");
        minBNBBuy = amount * 10**divisor;
    }
}