/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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
     * d-og-e c+lo_wn
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
        // See:
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

interface IDEXRouter {
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

// interface ICashier {
//     function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection) external;
//     function setShare(address shareholder, uint256 amount) external;
//     function deposit() external payable;
//     function process(uint256 gas) external;
//     function giveMeWelfarePlease(address hobo) external;
//     function getTotalDistributed() external view returns(uint256);
//     function getShareholderInfo(address shareholder) external view returns(uint256,uint256,uint256,uint256);
// }


contract Cashier {
    using SafeMath for uint256;
    
    address _token;


    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[5] tokens = [0x8a9424745056Eb399FD19a0EC26A14316684e274,0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,
                        0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684,0x8BaBbB98678facC7342735486C851ABD7A0d17Ca,
                        0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7]; // Binance pegged tokens
    uint256 twoDays = 60 * 60;
    uint256 timeCount = 0;
    uint256 lastTimeStamp = block.timestamp;
    

    IDEXRouter router; // Router
    //IDexRouter router2; // Router for token 2

    address[] shareholders;
    address private owner = msg.sender;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 18;
    uint256 public minPeriod = 5 * 60;
    uint256 public minReflection = 1000000 * (10 ** 9);
    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setToken(address token) public  {
        require(msg.sender == owner,"Not allowed");
        _token = token;
    }

    function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection) external onlyToken {
        minPeriod = _minPeriod;
        minReflection = _minReflection;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function swapToken(IERC20 token, uint256 bnb) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnb}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function deposit() external  payable onlyToken {
        totalDividends = totalDividends + msg.value;
        dividendsPerShare += dividendsPerShareAccuracyFactor * msg.value / totalShares;
    }

    function process(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minReflection;
    }
    
    function selectCount() internal returns(uint256){
        uint256 currentTime = block.timestamp.div(twoDays);
        if (currentTime > lastTimeStamp.div(twoDays)){
            timeCount += 1;
            
            if(timeCount >= tokens.length){
                timeCount = 0;
            }
            lastTimeStamp = block.timestamp;
            
        }
        return timeCount;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            
            // Swap half stored BNB for token 1 and send the acquired tokens to shareholder
            uint256 tokenNum = selectCount();
            IERC20 t1 = IERC20(tokens[tokenNum]);
            uint256 token1Before = t1.balanceOf(address(this));
            swapToken(t1,amount);
            t1.transfer(shareholder, t1.balanceOf(address(this)) - token1Before);

            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function giveMeWelfarePlease(address hobo) external onlyToken {
        distributeDividend(hobo);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }
    
    function getShareholderInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256) {
        return (
            totalShares,
            totalDistributed,
            shares[shareholder].amount,
            shares[shareholder].totalRealised
        );
    }
    
    function getTotalDistributed() external view returns(uint256){
        return totalDistributed;
    }
    
    function setRouter(IDEXRouter _router) external {
        require(msg.sender == owner,"Not allowed");
        router = _router;
    }


    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}


abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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


contract DegenFund_test is IERC20 {
    using SafeMath for uint256;

    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExcluded;
    mapping (address => bool) _isDividendExcluded;

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;

    uint256 private constant startingSupply = 100_000_000_000; // 100 billion, underscores aid readability

    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * (10 ** _decimalsMul);

    string constant _name = "DegenFund";
    string constant _symbol = "DEGEN048";

    uint256 private _reflectionFee = 0; // Adjusted by buys and sells.
    uint256 private _liquidityFee = 0; // Adjusted by buys and sells.
    uint256 private _marketingFee = 0; // Adjusted by buys and sells.
    uint256 private _degenFee = 0; // Adjusted by buys and sells.
    uint256 private _totalFee = _liquidityFee + _reflectionFee + _marketingFee + _degenFee;
    uint256 public masterTaxDivisor = 10000;

    uint256 public _buyReflectionFee = 400;
    uint256 public _buyLiquidityFee = 200;
    uint256 public _buyMarketingFee = 400;
    uint256 public _buyDegenFee = 200;

    uint256 public _sellReflectionFee = 500;
    uint256 public _sellLiquidityFee = 400;
    uint256 public _sellMarketingFee = 500;
    uint256 public _sellDegenFee = 300;

    uint256 public maxReflectionFee = 1000;
    uint256 public maxLiquidityFee = 600;
    uint256 public maxMarketingFee = 1000;
    uint256 public maxDegenFee = 800;

    uint256 private previousReflectionFee = _reflectionFee;
    uint256 private previousLiquidityFee = _liquidityFee;
    uint256 private previousMarketingFee = _marketingFee;
    uint256 private previousDegenFee = _degenFee;

    uint256 private reflectionRatio = _sellReflectionFee;
    uint256 private liquidityRatio = _sellLiquidityFee;
    uint256 private marketingRatio = _sellMarketingFee;
    uint256 private degenRatio = _sellDegenFee;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // PCS ROUTER Mainnet
    address private _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    

    address private WBNB;
    //Set this
    address private ZERO = 0x0000000000000000000000000000000000000000;

    address payable private _marketingWallet; //Put your marketing address here
    address payable private _degenWallet;// Enter degen wallet here also

    // Max TX amount is 0.2% of the total supply.
    uint256 private maxTxPercent = 20; // Less fields to edit
    uint256 private maxTxDivisor = 1000;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor; // Actual amount for UI's
    // Maximum wallet size is 1.5% of the total supply.
    uint256 private maxWalletPercent = 10; // Less fields to edit
    uint256 private maxWalletDivisor = 1000;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor; // Actual amount for UI's

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;

    Cashier public reflector;
    uint256 reflectorGas = 500000;

    bool public swapAndLiquifyEnabled = false;
    bool public processReflect = true;
    uint256 private swapThreshold = _tTotal / 10000;
    uint256 private swapAmount = _maxTxAmount;
    bool private initialSubEnabled = false;
    bool inSwap;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private immutable snipeBlockAmt;
    uint256 public snipersCaught = 0;

        // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint32 public cooldownTimerInterval = 1 minutes;
    mapping (address => uint) private cooldownTimer;
    mapping (address => bool) isTimelockExempt;

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
    event SniperCaught(address sniperAddress);

    constructor (uint256 _snipeBlockAmt) payable {
        address msgSender = msg.sender;
        _tOwned[msgSender] = _tTotal;

        // Set the owner.
        _owner = msgSender;

        // Set the amount of blocks to count a sniper.
        snipeBlockAmt = _snipeBlockAmt;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        WBNB = dexRouter.WETH();

        reflector = new Cashier(_routerAddress);
        reflector.setToken(address(this));

        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[address(this)] = true;
        _isDividendExcluded[owner()] = true;
        _isDividendExcluded[lpPair] = true;
        _isDividendExcluded[address(this)] = true;
        _isDividendExcluded[ZERO] = true;
        // DxLocker Address (BSC)
        // _isFeeExcluded[0xfAEb76A74A43B8f6C9719A636a22CFA4faea7E71] = true;
        // _isDividendExcluded[0x2D045410f002A95EFcEE67759A92518fA3FcE677] = true;

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

    function setSniperProtectionEnabled(bool enabled) external onlyOwner() {
        require(enabled != sniperProtection, "Already set.");
        sniperProtection = enabled;
    }

    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function setDividendExcluded(address holder, bool enabled) public onlyOwner {
        require(holder != address(this) && holder != lpPair);
        _isDividendExcluded[holder] = enabled;
        if (enabled) {
            reflector.setShare(holder, 0);
        } else {
            reflector.setShare(holder, _tOwned[holder]);
        }
    }

    function setExcludeFromFees(address account, bool enabled) public onlyOwner {
        _isFeeExcluded[account] = enabled;
    }

    function setBuyTaxes(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee, uint256 degenFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectionFee
                && marketingFee <= maxMarketingFee
                && degenFee <= maxDegenFee);
        require(liquidityFee + reflectionFee + marketingFee + degenFee  <= 5000);
        _buyLiquidityFee = liquidityFee;
        _buyReflectionFee = reflectionFee;
        _buyMarketingFee = marketingFee;
        _buyDegenFee = degenFee;
    }

    function setSellTaxes(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee, uint256 degenFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectionFee
                && marketingFee <= maxMarketingFee
                && degenFee <= maxDegenFee);
        require(liquidityFee + reflectionFee + marketingFee + degenFee <= 5000);
        _sellLiquidityFee = liquidityFee;
        _sellReflectionFee = reflectionFee;
        _sellMarketingFee = marketingFee;
        _sellDegenFee = degenFee;
        }
    function setToken(address token) external onlyOwner{
        reflector.setToken(token);
    }

    function setRatios(uint256 reflection, uint256 liquidity, uint256 marketing, uint256 degen) external onlyOwner {
        reflectionRatio = reflection;
        liquidityRatio = liquidity;
        marketingRatio = marketing;
        degenRatio = degen;
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(_marketingWallet != newWallet, "Wallet already set!");
        _marketingWallet = payable(newWallet);
    }

    function setDegenWallet(address payable newWallet) external onlyOwner {
        require(_degenWallet != newWallet, "Wallet already set!");
        _degenWallet = payable(newWallet);
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
        return _tTotal - balanceOf(ZERO);
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

    function getUserInfo(address shareholder) external view returns (uint256,uint256,uint256,uint256) {
        return reflector.getShareholderInfo(shareholder);
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 10000); // Cannot set lower than 0.01%
        _maxTxAmount = _tTotal.mul(percent).div(divisor);
        maxTxAmountUI = startingSupply.mul(percent).div(divisor);
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 1000); // Cannot set lower than 0.1%
        _maxWalletSize = _tTotal.mul(percent).div(divisor);
        maxWalletSizeUI = startingSupply.mul(percent).div(divisor);
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion, "Function already used.");
        _liquidityHolders[router] = true;
        _liquidityHolders[presale] = true;
        presaleAddresses[router] = true;
        presaleAddresses[presale] = true;
        setDividendExcluded(router, true);
        setDividendExcluded(presale, true);
        setExcludeFromFees(router, true);
        setExcludeFromFees(presale, true);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if(_hasLimits(from, to)
            && to != _routerAddress 
            && to != lpPair
        ) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
        }

        bool takeFee = true;
        
        if(_isFeeExcluded[from] || _isFeeExcluded[to]){
            takeFee = false;
        }
         // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
        if (from == lpPair &&
            buyCooldownEnabled &&
            !isTimelockExempt[to]) {
            require(cooldownTimer[to] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[to] = block.timestamp + cooldownTimerInterval;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function adjustTaxes(address from) internal {
        if (from == lpPair) {
            _reflectionFee = _buyReflectionFee;
            _liquidityFee = _buyLiquidityFee;
            _marketingFee = _buyMarketingFee;
            _degenFee = _buyDegenFee;
        } else {
            _reflectionFee = _sellReflectionFee;
            _liquidityFee = _sellLiquidityFee;
            _marketingFee = _sellMarketingFee;
            _degenFee = _sellDegenFee;
        }
        _totalFee = getTotalFee();
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
            } else {
                if (_liqAddBlock > 0 
                    && from == lpPair 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                        return(false);
                    }
                }
            }
        }

        _tOwned[from] = _tOwned[from].sub(amount, "Insufficient Balance");

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        adjustTaxes(from);

        uint256 contractTokenBalance = _tOwned[address(this)];
        if(contractTokenBalance >= swapAmount)
            contractTokenBalance = swapAmount;

        if (!inSwap
            && from != lpPair
            && swapAndLiquifyEnabled
            && contractTokenBalance >= swapThreshold
            && !presaleAddresses[from]
            && !presaleAddresses[to]
        ) {
            swapBack(contractTokenBalance);
        }

        uint256 amountReceived = amount;

        if (takeFee) {
            amountReceived = takeTaxes(from, amount);
        }

        _tOwned[to] = _tOwned[to].add(amountReceived);

        if (processReflect)
            processTokenReflect(from, to);

        emit Transfer(from, to, amountReceived);
        return true;
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
            try reflector.setShare(from, _tOwned[from]) {} catch {}
        }
        if (!_isDividendExcluded[to]) {
            try reflector.setShare(to, _tOwned[to]) {} catch {}
        }
        try reflector.process(reflectorGas) {} catch {}
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _tOwned[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getTotalFee() public view returns (uint256) {
        return _reflectionFee + _liquidityFee + _marketingFee + _degenFee;
    }
    
    function setRouter(address _router) external onlyOwner{
        _routerAddress = _router;
        reflector.setRouter(IDEXRouter(_router));
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(_marketingWallet).transfer(amountBNB * amountPercentage / 100);
    }

    function takeTaxes(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * getTotalFee() / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }

    function swapBack(uint256 numTokensToSwap) internal swapping {
        uint256 swapTotalFee = reflectionRatio + liquidityRatio + marketingRatio + degenRatio;
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityRatio;
        uint256 amountToLiquify = numTokensToSwap * dynamicLiquidityFee / swapTotalFee / 2;
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
        uint256 totalBNBFee = swapTotalFee - (dynamicLiquidityFee / 2);
        uint256 amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / 2;
        uint256 amountBNBReflection = amountBNB * reflectionRatio / totalBNBFee;
        uint256 amountBNBMarketing = amountBNB - (amountBNBLiquidity + amountBNBReflection);
        transferBNBOut(amountBNBMarketing);

        if (amountToLiquify > 0) {
            dexRouter.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner(),
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        } else {
            // If we are not liquifying we add the bnb to busd buys.
            amountBNBReflection += amountBNBLiquidity;
        }

        try reflector.deposit{value: amountBNBReflection}() {} catch {}
    }

    function transferBNBOut(uint256 amount) internal {
        uint256 amountBNBMarketing = (amount * marketingRatio) / (marketingRatio + degenRatio);
        uint256 amountBNBDegen = amount - amountBNBMarketing;
        _marketingWallet.transfer(amountBNBMarketing);
        _degenWallet.transfer(amountBNBDegen);
    }

    function manualDepost() external onlyOwner() {
        try reflector.deposit{value: address(this).balance}() {} catch {}
    }
        // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            allowedPresaleExclusion = false;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }
}