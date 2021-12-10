/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
*
                          ██████████    
                        ██░░▓▓░░▓▓██    
                      ██░░    ▓▓▓▓██    
                  ████░░░░██░░  ▓▓██    
                ██░░░░  ██░░██░░░░██       ███████╗░█████╗░██████╗░███╗░░██╗██████╗░░█████╗░██╗░░░██╗
      ██████████░░      ░░██░░░░██         ██╔════╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔══██╗╚██╗░██╔╝
        ██▓▓██░░      ░░░░░░░░██           █████╗░░███████║██████╔╝██╔██╗██║██████╔╝███████║░╚████╔╝░
          ██░░░░██████░░░░░░██             ██╔══╝░░██╔══██║██╔══██╗██║╚████║██╔═══╝░██╔══██║░░╚██╔╝░░
          ██░░░░██████░░░░░░██             ███████╗██║░░██║██║░░██║██║░╚███║██║░░░░░██║░░██║░░░██║░░░
            ████▓▓████░░░░██               ╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░
        ░░░░  ████  ░░░░██              
        ░░      ██▓▓▓▓████              
        ░░    ░░  ████▓▓██              
      ░░  ░░░░░░      ████              
      ░░░░              ██              
                                        
               
*   EarnPay: an EarnHub Protocol powered payment rewards token featuring built-in payment rewards gamification.
*   (protocol codebase credit: woofydev - EarnHubBSC)
*
*   Additions by $horty
*   Whale Timer Fee Multiplier/Transfer Fee/Merchant Fee/Payment Reward Pool Gamification (MegaPay, BuyBoost, Space Dust)/Reflection Switching/Custom Paying Settings
*/
interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minPeriodCustom, uint256 _minDistribution, uint256 _minDistributionCustom, uint256 _defaultThreshold, uint256 _rotatingThreshold) external;
    function setShare(address shareholder, uint256 amount, bool distributeEarnings, bool _enabledCustomRewards) external;
    function deposit(bool depositDefault) external payable;
    function process(uint256 gas) external;
    function processManually(bool _enabledCustomRewards) external;
}

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    bool    private _isLocked;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _isLocked = false;
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
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(!_isLocked, "Contract locked, wait until unlocked");
        require(newOwner != address(0), "new owner is the 0 address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        _isLocked=true;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(_owner != msg.sender, "Contract is already unlocked");
        require(block.timestamp > _lockTime , "Contract is locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
        _isLocked=false;
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


// Original dividend protocol credit goes to Woofydev with EarnHubBSC
// EarnPay customization includes dual reward pools utilizing the same distributor with space dust 
contract DividendDistributor is IDividendDistributor {
    
    using SafeMath for uint256;
    using Address for address;
    // EarnPay Contract
    address _token;
    // Share of the SafeEarn/EarnHub Pie
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // Share of the Rotating Token Pie
    struct ShareCustom {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // safeearn contract address
    address public TOK = 0x6E2c3779b281d0449009f08a3373d3e873aCd532;
    address public TOK2 = 0xA402623160045d64c41C0dB9Eda1255F2aB60c0E;
    // bnb address
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    // custom token shareholder fields
    address[] shareholdersCustom;
    mapping (address => uint256) shareholderIndexesCustom;
    mapping (address => uint256) shareholderClaimsCustom;
    mapping (address => ShareCustom) public sharesCustom;
    // shares math and fields
    uint256 public          totalShares;
    uint256 public          totalDividends;
    uint256 public          totalDistributed;
    uint256 public          dividendsPerShare;
    uint256 public          totalSharesCustom;
    uint256 public          totalDividendsCustom;
    uint256 public          totalDistributedCustom;
    uint256 public          dividendsPerShareCustom;
    uint256 public          dividendsPerShareAccuracyFactor = 10 ** 36;
    // dust math
    uint256 public          rewardDustDivider = 10;
    uint256 public          rewardDustMultiplier = 1;
    uint256 public          rewardRateDivider = 2;
    uint256 public          rewardRateMultiplier = 1;
    uint256 public          rotatingDust;
    uint256 public          defaultDust;
    uint256 public          rotatingThreshold = 0;
    uint256 public          defaultThreshold = 0;
    // distributes every hour
    uint256 public          minPeriod = 1 hours;
    uint256 public          minPeriodCustom = 1 hours;
    // 1 Million SafeEarn/EarnHub Minimum Distribution
    uint256 public          minDistribution = 1 * (10 ** 15);
    uint256 public          minDistributionCustom = 1 * (10 ** 15);
    // current index in shareholder array 
    uint256 currentIndex;
    uint256 currentIndexCustom;
    bool    rotateProcess = true;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //testnet
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minPeriodCustom, uint256 _minDistribution, uint256 _minDistributionCustom, uint256 _defaultThreshold, uint256 _rotatingThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minPeriodCustom = _minPeriodCustom;
        minDistribution = _minDistribution;
        minDistributionCustom = _minDistributionCustom;
        rotatingThreshold = _rotatingThreshold;
        defaultThreshold = _defaultThreshold;
    }

    function setShare(address shareholder, uint256 amount, bool distributeEarnings, bool _enabledCustomRewards) external override onlyToken {
        /*
        if(distributeEarnings && (sharesCustom[shareholder].amount > 0 || shares[shareholder].amount > 0)){
            distributeDividend(shareholder, _enabledCustomRewards) {} catch {}
        }*/
        if(distributeEarnings && (_enabledCustomRewards ?  sharesCustom[shareholder].amount > 0 : shares[shareholder].amount > 0)){
            distributeDividend(shareholder, _enabledCustomRewards);
        }
        if(_enabledCustomRewards) {
            if(amount > 0 && sharesCustom[shareholder].amount == 0){
                addShareholder(shareholder, _enabledCustomRewards);
            }else if(amount == 0 && sharesCustom[shareholder].amount > 0){
                removeShareholder(shareholder, _enabledCustomRewards);
            }

            totalSharesCustom = totalSharesCustom.sub(sharesCustom[shareholder].amount).add(amount);
            sharesCustom[shareholder].amount = amount;
            sharesCustom[shareholder].totalExcluded = getCumulativeDividends(sharesCustom[shareholder].amount, _enabledCustomRewards);
        }
        else {
            if(amount > 0 && shares[shareholder].amount == 0){
                addShareholder(shareholder, _enabledCustomRewards);
            }else if(amount == 0 && shares[shareholder].amount > 0){
                removeShareholder(shareholder, _enabledCustomRewards);
            }

            totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
            shares[shareholder].amount = amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, _enabledCustomRewards);
        }
    }
    
    function deposit(bool depositDefault) external payable override onlyToken {
        address TOKEN = depositDefault ?  TOK : TOK2;
        uint256 _balanceBefore = IERC20(TOKEN).balanceOf(address(this));
        buyDepositTokens(TOKEN);
        uint256 amount = IERC20(TOKEN).balanceOf(address(this)).sub(_balanceBefore);
        uint256 allocation = amount.div(rewardDustDivider).mul(rewardDustMultiplier);
        amount = amount.sub(allocation);
        if(depositDefault) {
            defaultDust = defaultDust.add(allocation);
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
        else {
            rotatingDust = rotatingDust.add(allocation);
            totalDividendsCustom = totalDividendsCustom.add(amount);
            dividendsPerShareCustom = dividendsPerShareCustom.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalSharesCustom));
        }
    }

    function buyDepositTokens(address contractAddress) internal {

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(contractAddress);

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp.add(30)
        ) {} catch {}

    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount;
        rotateProcess = !rotateProcess;
        if(rotateProcess) {
            shareholderCount = shareholdersCustom.length;

            if(shareholderCount == 0) { return; }
            uint256 gasUsed = 0;
            uint256 iterations = 0;
            uint256 gasLeft = gasleft();
            while(gasUsed < gas && iterations < shareholderCount) {
                if(currentIndexCustom >= shareholderCount){
                    currentIndexCustom = 0;
                }

                if(shouldDistribute(shareholdersCustom[currentIndexCustom], true)){
                    distributeDividend(shareholdersCustom[currentIndexCustom], true);
                }

                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndexCustom++;
                iterations++;
            }
        }
        else {
            shareholderCount = shareholders.length;

            if(shareholderCount == 0) { return; }
            uint256 gasUsed = 0;
            uint256 iterations = 0;
            uint256 gasLeft = gasleft();
            while(gasUsed < gas && iterations < shareholderCount) {
                if(currentIndex >= shareholderCount){
                    currentIndex = 0;
                }

                if(shouldDistribute(shareholders[currentIndex], false)){
                    distributeDividend(shareholders[currentIndex], false);
                }

                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndex++;
                iterations++;
            }
        }
    }
    
    function processManually(bool _enabledCustomRewards) external override onlyToken {
        uint256 shareholderCount;
        uint256 iterations = 0;
        if(_enabledCustomRewards) {
            shareholderCount = shareholdersCustom.length;
        
            if(shareholderCount == 0) { return; }

            currentIndexCustom = 0;

            while(iterations < shareholderCount) {
                if(currentIndexCustom >= shareholderCount){
                    currentIndexCustom = 0;
                }

                if(shouldDistribute(shareholdersCustom[currentIndexCustom], true)){
                    distributeDividend(shareholdersCustom[currentIndexCustom], true);
                }
                currentIndexCustom++;
                iterations++;
            }
        }
        else {
            shareholderCount = shareholders.length;
            
            if(shareholderCount == 0) { return; }

            currentIndex = 0;

            while(iterations < shareholderCount) {
                if(currentIndex >= shareholderCount){
                    currentIndex = 0;
                }

                if(shouldDistribute(shareholders[currentIndex], false)){
                    distributeDividend(shareholders[currentIndex], false);
                }
                currentIndex++;
                iterations++;
            }
        }
    }

    function shouldDistribute(address shareholder, bool _enabledCustomRewards) internal view returns (bool) {
        if(_enabledCustomRewards) {
            return shareholderClaimsCustom[shareholder] + minPeriodCustom < block.timestamp
            && getUnpaidEarnings(shareholder, _enabledCustomRewards) > minDistributionCustom;
        }
        else {
            return shareholderClaims[shareholder] + minPeriod < block.timestamp
            && getUnpaidEarnings(shareholder, _enabledCustomRewards) > minDistribution;
        }
    }

    function distributeDividend(address shareholder, bool _enabledCustomRewards) internal {
        uint256 amount = getUnpaidEarnings(shareholder, _enabledCustomRewards);
        if(_enabledCustomRewards){
            if(sharesCustom[shareholder].amount == 0){ return; }

            if(amount > 0){
                totalDistributedCustom = totalDistributedCustom.add(amount);
                IERC20(TOK2).transfer(shareholder, amount);
                shareholderClaimsCustom[shareholder] = block.timestamp;
                sharesCustom[shareholder].totalRealised = sharesCustom[shareholder].totalRealised.add(amount);
                sharesCustom[shareholder].totalExcluded = getCumulativeDividends(sharesCustom[shareholder].amount, _enabledCustomRewards);
            }
        }
        else {
            if(shares[shareholder].amount == 0){ return; }

            if(amount > 0){
                totalDistributed = totalDistributed.add(amount);
                IERC20(TOK).transfer(shareholder, amount);
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, _enabledCustomRewards);
            }
        }
    }

    function claimDividend(bool _enabledCustomRewards, address holder) external {
        if(_enabledCustomRewards)
            require(shareholderClaimsCustom[holder] + minPeriodCustom < block.timestamp, 'Must wait claim period to claim dividend!');
        else
            require(shareholderClaims[holder] + minPeriod < block.timestamp, 'Must wait claim period to claim dividend!');
        distributeDividend(holder, _enabledCustomRewards);
    }

    function getUnpaidEarnings(address shareholder, bool _enabledCustomRewards) public view returns (uint256) {
        if(_enabledCustomRewards){
            if(sharesCustom[shareholder].amount == 0){ return 0; }

            uint256 shareholderTotalDividendsCustom = getCumulativeDividends(sharesCustom[shareholder].amount, _enabledCustomRewards);
            uint256 shareholderTotalExcludedCustom = sharesCustom[shareholder].totalExcluded;

            if(shareholderTotalDividendsCustom <= shareholderTotalExcludedCustom){ return 0; }

            return shareholderTotalDividendsCustom.sub(shareholderTotalExcludedCustom);
        }
        else {
            if(shares[shareholder].amount == 0){ return 0; }

            uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount, _enabledCustomRewards);
            uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

            if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

            return shareholderTotalDividends.sub(shareholderTotalExcluded);
        }
    }

    function getTotalEarnings(address shareholder) public view returns (uint256, uint256) {
        return (shares[shareholder].totalRealised, sharesCustom[shareholder].totalRealised);
    }

    function getCumulativeDividends(uint256 share, bool _enabledCustomRewards) internal view returns (uint256) {
        if(_enabledCustomRewards){
            return share.mul(dividendsPerShareCustom).div(dividendsPerShareAccuracyFactor);
        }
        else {
            return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
        }
    }

    function addShareholder(address shareholder, bool _enabledCustomRewards) internal {
        if(_enabledCustomRewards) {
            shareholderIndexesCustom[shareholder] = shareholdersCustom.length;
            shareholdersCustom.push(shareholder);
        }
        else {
            shareholderIndexes[shareholder] = shareholders.length;
            shareholders.push(shareholder);
        }
    }

    function removeShareholder(address shareholder, bool _enabledCustomRewards) internal {
        if(_enabledCustomRewards) {
            shareholdersCustom[shareholderIndexesCustom[shareholder]] = shareholdersCustom[shareholdersCustom.length-1];
            shareholderIndexesCustom[shareholdersCustom[shareholdersCustom.length-1]] = shareholderIndexesCustom[shareholder];
            shareholdersCustom.pop();
            delete shareholderIndexesCustom[shareholder];
        }
        else {
            shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
            shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
            shareholders.pop();
            delete shareholderIndexes[shareholder];
        }
    }
    
    function setTokenAddress(address nToken) external onlyToken {
        //IERC20(TOK).transfer(msg.sender, defaultDust);
        IERC20(TOK).transfer(msg.sender, IERC20(TOK).balanceOf(address(this)));
        defaultDust = 0;
        TOK = nToken;
    }

    function setCustomTokenAddress(address nToken) external onlyToken {
        //IERC20(TOK2).transfer(msg.sender, rotatingDust);
        IERC20(TOK2).transfer(msg.sender, IERC20(TOK2).balanceOf(address(this)));
        rotatingDust = 0;
        TOK2 = nToken;
    }

    function setDustDividers(uint256 _rewardDustDivider, uint256 _rewardDustMultiplier, uint256 _rewardRateDivider, uint256 _rewardRateMultiplier) external onlyToken {
        rewardDustDivider = _rewardDustDivider;
        rewardDustMultiplier = _rewardDustMultiplier;
        rewardRateDivider = _rewardRateDivider;
        rewardRateMultiplier = _rewardRateMultiplier;
    }
    /*
    function transferRewardDust(address winner) external onlyToken {
        uint256 rewardAmount;
        if(rotatingDust>rotatingThreshold)
        {
            rewardAmount = rotatingDust.div(rewardRateDivider).mul(rewardRateMultiplier);
            IERC20(TOK2).transfer(winner, rewardAmount);
            rotatingDust = rotatingDust.sub(rewardAmount);
        }
        if(defaultDust>defaultThreshold)
        {
            rewardAmount = defaultDust.div(rewardRateDivider).mul(rewardRateMultiplier);
            IERC20(TOK).transfer(winner, rewardAmount);
            defaultDust = defaultDust.sub(rewardAmount);
        }
    }
    */
    function transferAndBurnRewardDust(address winner) external onlyToken returns (uint256,uint256){
        uint256 rewardAmount=0;
        uint256 rewardAmountRotating=0;
        //uint256 burningDust;
        //address DEAD = 0x000000000000000000000000000000000000dEaD;
        if(rotatingDust>rotatingThreshold)
        {
            rewardAmountRotating = rotatingDust.div(rewardRateDivider).mul(rewardRateMultiplier);
            IERC20(TOK2).transfer(winner, rewardAmountRotating); 
            rotatingDust = rotatingDust.sub(rewardAmountRotating);
            //burningDust = rotatingDust.div(rewardRateDivider).mul(rewardRateMultiplier); 
            //IERC20(TOK2).transfer(DEAD, burningDust); 
            //rotatingDust = rotatingDust.sub(burningDust);
        }
        if(defaultDust>defaultThreshold)
        {
            rewardAmount = defaultDust.div(rewardRateDivider).mul(rewardRateMultiplier);
            IERC20(TOK).transfer(winner, rewardAmount);
            defaultDust = defaultDust.sub(rewardAmount);
            //burningDust = defaultDust.div(rewardRateDivider).mul(rewardRateMultiplier);
            //IERC20(TOK).transfer(DEAD, burningDust); 
            //defaultDust = defaultDust.sub(burningDust);
        }
        return (rewardAmount, rewardAmountRotating);
    }

    receive() external payable { }

}

/**
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

/** 
 * Contract: EarnPay 
 *  EarnPay: an EarnHub Protocol based payment rewards token featuring a built-in payment reward gamifacation.
 *  (protocol codebase credit: woofydev - EarnHubBSC)
 *  EarnPay Team Contribution: Whale Timer/Fee Multiplier//Transfer Fee/Merchant Fee/Payment Reward Pool Gamification/Default Reflection Switching/Custom Pay Settings
 *  Buyback & Burn have been adjusted to kick off only during Buys/Sells to minimize wallet-wallet gas transfer fees. 
 *  Whale timer limits buyback & burn on sell to prevent high slippage issues
 *  Includes the ability to convert the token to a basic token without having to exempt everyone. This is for emergency use.
 *
 *  This contract awards daily to holders in their choice of available tokens, weighted by how much you hold in addition to switching to a rotating pool

                          ██████████    
                        ██░░▓▓░░▓▓██    
                      ██░░    ▓▓▓▓██    
                  ████░░░░██░░  ▓▓██    
                ██░░░░  ██░░██░░░░██       ███████╗░█████╗░██████╗░███╗░░██╗██████╗░░█████╗░██╗░░░██╗
      ██████████░░      ░░██░░░░██         ██╔════╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔══██╗╚██╗░██╔╝
        ██▓▓██░░      ░░░░░░░░██           █████╗░░███████║██████╔╝██╔██╗██║██████╔╝███████║░╚████╔╝░
          ██░░░░██████░░░░░░██             ██╔══╝░░██╔══██║██╔══██╗██║╚████║██╔═══╝░██╔══██║░░╚██╔╝░░
          ██░░░░██████░░░░░░██             ███████╗██║░░██║██║░░██║██║░╚███║██║░░░░░██║░░██║░░░██║░░░
            ████▓▓████░░░░██               ╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░
        ░░░░  ████  ░░░░██              
        ░░      ██▓▓▓▓████              
        ░░    ░░  ████▓▓██              
      ░░  ░░░░░░      ████              
      ░░░░              ██              
                                        
                                        
 *   EarnPay: A payment rewards token featuring built-in dividend payouts & payment rewards gamification.
 *   Reflecting in EarnHub/Affinity
 *  
 *  Buy Fee:            10%
 *  Sell Fee:           20%
 *  Whale Timer Fee:    30%
 *  Transfer Fee:        1%
 *  Merchant Pay Fee:   0.5%
 * 
 *  Standard Sell Fee Breakdown:
 *  Rewards:.................................17%                       
 *      -13% EarnHub/Affinity Distribution
 *      -4% Native Reward Gamification
 *  Buyback: Burn & Auto Liquidity...........1.5% 
 *  Token Sustainability/Marketing...........1.5%
 *
 */
contract Erpay is IERC20, Context, Ownable, TokenRecover {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeMath for uint;
    using Address for address;
    
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //testnet

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    
    address public interfaceAddress; //custom fee available for interfacing address

    string  constant _name = "ErPay";
    string  constant _symbol = "ERPAY";
    uint8   constant _decimals = 9;
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(200);           // 0.5% or 5 Billion
    // balances
    mapping (address => uint256) _balances; 
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) _buyBonusEarnings;
    mapping (address => uint256) _megaPayEarnings;
    mapping (address => uint256) public spaceDustEarnings;
    mapping (address => uint) public boostRewardIndex;
    // registered merchant
    mapping (address => bool) isMerchant;
    // exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    //toggles
    mapping (address => bool) enabledTransferDividends;            // "disabled" by default
    mapping (address => bool) disabledTransferEarnings;            // "enabled" by default
    mapping (address => bool) enabledCustomRewards;                // "disabled" by default
    mapping (address => bool) disabledRewardDust;                  // "enabled" be default
    // anti-whale settings 
    uint256 public whaleSellThreshold = 1 * 10**9 * 10**9;         // 1 billion
    uint    public whaleSellTimer     = 259200;                    // 72 hours/3 days at Launch
    mapping (address => uint256) public lastSellAmount;
    mapping (address => uint) public _timeSinceFirstSell;
    uint8   public whaleFeeMultiplier          = 3;
    uint8   public whaleFeeDivider             = 2;
    // fees
    uint256 public liquidityFee                 = 75;
    uint256 public buybackFee                   = 75;
    uint256 public reflectionFee                = 1300;
    uint256 public sustainingFee                = 150;
    uint256 public rocketPoolFee                = 400;
    // total fees
    uint256 totalFeeSells                       = 2000;
    uint256 totalFeeBuys                        = 1000;
    uint256 totalFeeTransfers                   = 100;
    uint256 totalFeeTransfersMerchant           = 50;
    uint256 interfaceFee                        = 250;
    uint256 feeDenominator                      = 10000;

    // megapay pool
    bool    public  enableRocketPools             = true;                // Enabled on deployment
    bool    public  bonusContributionBuys         = true;                // Enabled on deployment - Allows Buys to Contribute to the Bonus Buy
    uint256 public  megaPay                       = 0;                   // How many reflections are in the megapay pool
    uint256 public  buyBoost                      = 0;                   // How many reflections are in the bonus pool
    uint    public  megaPayChance                 = 20;                  // 2% chance of winning
    uint    public  megaPayTransferChance         = 5;                   // 0.5% chance of winning
    uint    public  bonusChance                   = 125;                 // 12.5% chance of winning at buy
    uint    public  rewardIndex                   = 4;                   // Every 4th buy kick in chance buy boost chance multiplier;
    uint    public  rewardIndexMult               = 3;
    uint    public  rewardIndex2                  = 8;                   // Must be > than rewardIndex always
    uint    public  rewardIndex2Mult              = 5;
    uint256 public  megaPayThreshold              = 10 * 10**6 * 10**9;  // initial 10 million tokens required to be in the pool before megapay pool can be triggered
    uint256 public  megaPayMinimumSpend           = 1 * 10**6 * 10**9;   // initial 1 million tokens required to buy before megapay pool can be triggered
    uint256 public  megaPayMinimumTransfer        = 1 * 10**6 * 10**9;   // initial 1 million tokens required to transfer before before megapay pool can be triggered
    uint256 public  megaPayMinimumHODL            = 10 * 10**6 * 10**9;  // initial 10 million tokens required to HODL before megapay pool can be triggered
    uint256 public  chanceMultiplierBuyThreshold  = 50 * 10**6 * 10**9;  // initially set to 90 days of holding
    address public  previousWinner;
    uint256 public  previousWonAmount;
    uint    public  previousWinTime;
    address public  previousBoostWinner;
    uint    public  lastRoll;
    uint256 private _nonce;
    // space dust --- enabled by megapay
    uint256 public  blackHoleMinimum                = 1 * 10**5 * 10**9;   // initial 100K tokens required to claim space dust through sending to blackhole
    uint256 public  blackHoleMinimumMP              = 10 * 10**5 * 10**9;  // initial 1M tokens required to burn to roll for megabuy & megapay
    uint    public  bHchanceMultiplier              = 2;                   // Set to 2x to start
    uint256 public  spaceDust                       = 0;                   // How many reflections are in the dust pool
    uint256 public  spaceDustBurned                 = 0;                   // Tracks space dust burned through black hole
    uint    public  spaceDustRateDivider            = 2;                   // Initially set to reward half the bonus allocation
    uint    public  spaceDustRateMultiplier         = 1;
    uint    public  earnPayDustDivider              = 2;                   // Initially set to take the buy bonus allocation
    uint    public  earnPayDustMultiplier           = 1;                   
    // sustaining wallet & auto LP receiver
    address public sustainingFeeReceiver = 0x41c91157dDbC39178c8034Aba9F835AC812AB188;
    address public autoLiquidityReceiver;
    // target liquidity is 12%
    uint256 targetLiquidity = 12;
    uint256 targetLiquidityDenominator = 100;
    // Pancakeswap V2 Router
    IUniswapV2Router02 public router;
    address public pair;
    // buy back data
    bool public autoBuybackEnabled = false;
    uint256 autoBuybackAccumulator = 0; // Tracks how many tokens have been bought back AND burned from circulation
    uint256 autoBuybackAmount = 1 * 10**18;
    uint256 autoBuybackBlockPeriod = 3600; // 1 hour
    uint256 autoBuybackBlockLast = block.number;
    // gas for distributor
    DividendDistributor distributor;
    uint256 distributorGas = 500000;
    uint256 customTokenRewardBalance = 0; // Tracks EarnPay reflections that will be converted to custom token
    uint256 tokenRewardBalance       = 0; // Tracks EarnPay reflections that will be converted to default token
    // in charge of swapping from EarnPay -> BNB to fund EarnPay reflections + sustaining
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(1000); // 0.1% or 1 Billion to start
    // true if our threshold decreases with circulating supply
    bool basicTransfers = false;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    // Uniswap Router V2
    address private _dexRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //testnet

    // false if we should disable auto liquidity pairing for any reason
    bool public shouldPairLiquidity = true;
    uint256 public reverseRugAccumulator = 0;
    
    
    constructor () {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> EarnPay
        pair = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // Wrapped BNB Address used for trading on PCS
        WBNB = router.WETH();
        // our dividend Distributor
        distributor = new DividendDistributor(_dexRouter);
        // exempt deployer/sustaining from fees
        isFeeExempt[msg.sender] = true;
        isFeeExempt[sustainingFeeReceiver] = true;
        // exempt deployer/sustaining from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[sustainingFeeReceiver] = true;
        isTxLimitExempt[address(this)] = true;
        // exempt this contract, the LP, and OUR burn wallet from receiving SafeEarn/EarnHub Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[msg.sender] = true; // remove before mainnet deployment
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        autoLiquidityReceiver = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function internalApprove(address spender, uint256 amount) internal returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // during internal or interface triggered swaps perform a basic transfer
        if(inSwap || recipient == interfaceAddress || sender == interfaceAddress || basicTransfers){ return _basicTransfer(sender, recipient, amount); }

        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        
        // MEGAPAY POOL MECHANISM
        // pool threshold & minimum required to spend for award are updated to always be relative to % of circulating supply
        bool    _isBuy             = (sender == pair);
        bool    _isSell            = (recipient == pair);
        bool    _isTransfer        = !(_isBuy || _isSell); 

        /*
            █▀█ █▀█ █▀▀ █▄▀ █▀▀ ▀█▀   █▀█ █▀█ █▀█ █░░ █▀
            █▀▄ █▄█ █▄▄ █░█ ██▄ ░█░   █▀▀ █▄█ █▄█ █▄▄ ▄█
        */
        //If the transaction is a buy or transfer, then we roll to see if we award any extra tokens from the Rocket Pools
        if(enableRocketPools &&  ((!isDividendExempt[recipient] && (amount >= megaPayMinimumSpend && _isBuy)) || (!isDividendExempt[sender] && (amount >= megaPayMinimumTransfer && _isTransfer && _balances[sender] >= megaPayMinimumHODL)))){
    
            uint256 poolReward = calculatePoolReward(_isTransfer, 1); //calculates pool reward based on the buy or wallet-wallet transfer chance
            if (_isBuy){
                if (poolReward > 0) {
                    rocketPoolTransfer(recipient, poolReward, true); 
                }
                uint256 chance_multiplier;
                if(boostRewardIndex[recipient] == rewardIndex)
                    chance_multiplier = rewardIndexMult;
                else 
                    chance_multiplier = boostRewardIndex[recipient] >= rewardIndex2 ? rewardIndex2Mult : 1;
                if(amount >= chanceMultiplierBuyThreshold){
                    boostRewardIndex[recipient] = boostRewardIndex[recipient] >= rewardIndex2 ? 0 : boostRewardIndex[recipient].add(1);
                }
                if (buyBoost > 0 && (random() <= bonusChance.mul(chance_multiplier))) {
                    rocketPoolTransfer(recipient, buyBoost, false); //Awards bonus pool from last sells if won
                }
            }
            if (_isTransfer){
                if (poolReward > 0) {
                    rocketPoolTransfer(sender, poolReward, true);
                }
                if (!disabledRewardDust[sender] && spaceDust > 0) {
                    uint256 dustAllocation = spaceDust.div(spaceDustRateDivider).mul(spaceDustRateMultiplier);
                    _balances[sender] = _balances[sender].add(dustAllocation);
                    spaceDustEarnings[sender] = spaceDustEarnings[sender].add(dustAllocation);
                    emit DustTransfer(sender, spaceDust, block.timestamp);
                    emit Transfer(address(this), sender, spaceDust);
                    spaceDust = spaceDust.sub(dustAllocation);
                    //distributor.transferRewardDust(sender);
                }
            }
        } 

        uint256 amountReceived;
        // limit gas consumption by splitting up operations
        // limit buyback & swapback during whale timer sell to prevent high slippage
        if(_isTransfer){
            amountReceived = handleTransferBody(sender, recipient, amount);
            if(enabledTransferDividends[sender]){
                tryToProcess();
            }
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } //Are we about to enter a whale sell in amount sold? To avoid high slippage errors, we skip buyback & swapback
        else if(lastSellAmount[sender].add(amount) > whaleSellThreshold && _isSell) {
            amountReceived = handleTransferBody(sender, recipient, amount);
            tryToProcess();
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } //Should SwapBack (swaps EARNPAY for BNB)?
        else if(shouldSwapBack()) { 
            swapBack();
        } //Should AutoBuyBack (buy & burn)?
        else if(!inSwap && autoBuybackEnabled && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number && address(this).balance >= autoBuybackAmount) {
            //Trigger Autobuyback 
            buyTokens(autoBuybackAmount, DEAD);
            autoBuybackBlockLast = block.number;
            autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount); 
        } //process as normal
        amountReceived = handleTransferBody(sender, recipient, amount);
        tryToProcess();
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    /** Takes Associated Fees and sets holders' new Share for the SafeEarn/EarnHub Distributor */
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        if(basicTransfers)
        {
            _balances[recipient] = _balances[recipient].add(amount);
            return amount;
        }
        uint256 amountReceived = !isFeeExempt[sender] ? takeFee(sender, recipient, amount) : amount; // !isFeeExempt[sender] == should take fee?
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // If this is a transfer, set to triggerDividends based on user. Default to true for buy/sell
        bool triggerDividends = !(sender == pair || recipient == pair) ? !disabledTransferEarnings[sender] : true;
        if(!isDividendExempt[sender]){
            try distributor.setShare(sender, _balances[sender], triggerDividends, enabledCustomRewards[sender]) {} catch {} 
        }
        if(!isDividendExempt[recipient]){
            try distributor.setShare(recipient, _balances[recipient], triggerDividends, enabledCustomRewards[recipient]) {} catch {} 
        }

        return amountReceived;
    }
    /** Basic Transfer with no swaps for BNB -> EarnPay or EarnPay -> BNB or Fees taken - Converts the token to a basic Token*/
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        handleTransferBody(sender, recipient, amount);
        return true;
    }
    /** Tries to process */
    function tryToProcess() internal {
        uint256 gasToUse = distributorGas > gasleft() ? gasleft().mul(3).div(4) : distributorGas;
        try distributor.process(gasToUse) {} catch {}
    }
    /** Takes Tax Fee (10% buys , 1% transfers, 20% on sells, 30% Whale Timer Tax) and delegate reflection pool allocations and store remaining fees in contract */
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(sender, receiver, amount)).div(feeDenominator);
        uint256 _finalFeeAmount = feeAmount;
        if(enableRocketPools) {
            uint256 poolAllocation = feeAmount.mul(rocketPoolFee).div(totalFeeSells); //calculates fees to allocate towards reflection pool
            bool conditionsMet = bonusContributionBuys ? (receiver == pair || sender == pair) : (receiver == pair); 
            uint256 _buyBonusAdd = conditionsMet ? poolAllocation.div(2) : 0; //if it's a sell allocate 1/2 of the pool allocation for the buy bonus
            uint256 _newAllocation = _buyBonusAdd.div(earnPayDustDivider).mul(earnPayDustMultiplier);
            buyBoost = buyBoost.add(_newAllocation);
            spaceDust = spaceDust.add(_buyBonusAdd.sub(_newAllocation));
            megaPay = megaPay.add(poolAllocation.sub(_buyBonusAdd)); //transfer pool allocations to reflection pool
            _finalFeeAmount = feeAmount.sub(poolAllocation);
        }

        //If it's a buy/sell, split the fee for dividend allocation between both pools. During a transfer allocate to only the holder reward pool
        if(sender == pair || receiver == pair){
            uint256 fee_alloc = _finalFeeAmount.div(2);
            customTokenRewardBalance = customTokenRewardBalance.add(fee_alloc);//remove pool allocations from total fee amount & add to custom + default token balance
            tokenRewardBalance = tokenRewardBalance.add(_finalFeeAmount.sub(fee_alloc));
        }
        else {
            if(enabledCustomRewards[sender]) { customTokenRewardBalance = customTokenRewardBalance.add(_finalFeeAmount);//remove pool allocations from total fee amount & add to custom token balance
            }
            else { tokenRewardBalance = tokenRewardBalance.add(_finalFeeAmount);
            }
        }
        _balances[address(this)] = _balances[address(this)].add(_finalFeeAmount); //remove pool allocations from total fee amount & add to contract balance
        //subtract total fee amount (including pool allocations)
        return amount.sub(feeAmount);
    }
    function getTotalFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        //Determine if we are 1. Transferring or 2. Selling or 3. Are you interfacing with a swapper contract. Otherwise assign the buy Fee as the default fee
        if(!(sender == pair || receiver == pair)){
            return (isMerchant[sender] || isMerchant[receiver]) ? totalFeeTransfersMerchant : totalFeeTransfers;
        } //checks if we're selling
        if(receiver == pair){ 
            // We will assume that the normal sell tax rate will apply
            uint256 fee = totalFeeSells;
            // Get the time difference in seconds between now and the first sell
            uint delta = block.timestamp.sub(_timeSinceFirstSell[sender]);
            // Get the new total to see if it has spilled over the threshold
            uint256 newTotal = lastSellAmount[sender].add(amount);
            /*
                                
                █░█░█ █░█ ▄▀█ █░░ █▀▀   ▀█▀ █ █▀▄▀█ █▀▀ █▀█
                ▀▄▀▄▀ █▀█ █▀█ █▄▄ ██▄   ░█░ █ █░▀░█ ██▄ █▀▄
            */
            // If a known wallet started their selling within the whale sell timer window, check if they're trying to spill over the threshold
            // If they are then increase the tax amount
            if (delta > 0 && delta < whaleSellTimer && _timeSinceFirstSell[sender] != 0) {
                if (newTotal > whaleSellThreshold) {
                    fee = fee.mul(whaleFeeMultiplier).div(whaleFeeDivider); 
                }
                lastSellAmount[sender] = newTotal;
            } else if (_timeSinceFirstSell[sender] == 0 && newTotal > whaleSellThreshold) {
                fee = fee.mul(whaleFeeMultiplier).div(whaleFeeDivider);
                lastSellAmount[sender] = newTotal;
            } else {
                // Otherwise we reset their sold amount and timer
                _timeSinceFirstSell[sender] = block.timestamp;
                lastSellAmount[sender] = amount;
            }
            return fee; }
        if(receiver == interfaceAddress || sender == interfaceAddress)
        {
            return interfaceFee;
        }
        return totalFeeBuys;
    }

    /** True if we should swap from EarnPay => BNB, only swapsback during buy/sell to save transfer gas fees */
    function shouldSwapBack() internal view returns (bool) {
        bool tokenThresholdMet = (_balances[address(this)].sub(tokenRewardBalance) >= swapThreshold) || (_balances[address(this)].sub(customTokenRewardBalance) >= swapThreshold);
        return !inSwap
        && swapEnabled
        && tokenThresholdMet;
    }
    /**
     *  Swaps EarnPay for BNB if threshold is reached and the swap is enabled
     *  Uses BNB retrieved to:
     *      fuel the contract for buy/burns
     *      provide distributor with BNB for SafeEarn/EarnHub
     *      send to sustaining wallet
     *      add liquidity if liquidity is low
     */
    function swapBack() internal swapping {
        
        // check if we need to add liquidity
        uint256 _totalFeeSells = totalFeeSells.sub(rocketPoolFee);
        uint256 dynamicLiquidityFee = (isOverLiquified(targetLiquidity, targetLiquidityDenominator) || !shouldPairLiquidity)? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(_totalFeeSells).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
        bool swapDefault = _balances[address(this)].sub(customTokenRewardBalance) >= swapThreshold; //determine who met threshold during swapback check
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {
            if(swapDefault){ tokenRewardBalance = tokenRewardBalance.sub(amountToSwap); }
            else { customTokenRewardBalance = customTokenRewardBalance.sub(amountToSwap);}

        } catch{}
        // how much BNB did we swap?
        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        // total amount of BNB to allocate
        uint256 totalBNBFee = _totalFeeSells.sub(dynamicLiquidityFee.div(2));
        // how much bnb is sent to liquidity, reflections, and sustaining
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBSustaining = amountBNB.mul(sustainingFee).div(totalBNBFee);
        // deposit BNB for reflections and sustaining
        transferToDistributorAndSustaining(amountBNBReflection, amountBNBSustaining, swapDefault);
        
        // add liquidity to liquidity pair as needed and send to the liquidity address
        if(amountToLiquify > 0 && shouldPairLiquidity ){
            try router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            ) {
                if(swapDefault){ tokenRewardBalance = tokenRewardBalance.sub(amountToLiquify); }
                else { customTokenRewardBalance = customTokenRewardBalance.sub(amountToLiquify);}
            } catch {}
        }
    }
    /** Transfers BNB to EarnHub Distributor and Sustaining Wallet */
    /** If sustaining wallet is disabled, sustaining fee will go towards distributor for dividend reflections */
    function transferToDistributorAndSustaining(uint256 distributorBNB, uint256 sustainingBNB, bool swapDefault) internal {
            bool successful;
            try distributor.deposit{value: distributorBNB}(swapDefault) {} catch {}
            (successful,) = payable(sustainingFeeReceiver).call{value: sustainingBNB, gas: 30000}("");
    }
    
    /**
     * Buys EarnPay with bnb in the contract and then sends to the dead wallet
     */ 
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp.add(30)
        );
    }
    
    /** 0 = process manually | 1 = process with standard gas | Above 1 = process with custom gas limit */
    function manuallyProcessDividends(uint256 distributorGasFee, bool _processDefault) external {
        if (distributorGasFee == 0) {
            try distributor.processManually(_processDefault) {} catch {}
        } else if (distributorGasFee == 1) {
            try distributor.process(distributorGas) {} catch {}
        } else {
            try distributor.process(distributorGasFee) {} catch {}
        }
    }
    
    function setInterface(address _interface, uint256 _interfaceFee) external onlyOwner {
        interfaceAddress = _interface;
        isDividendExempt[interfaceAddress] = true;
        interfaceFee = _interfaceFee;
    }

    //designed to skip mechanisms in the event of the contract reverting
    function setBasicTransfers(bool _enableBasicTransfers) external onlyOwner {
        basicTransfers = _enableBasicTransfers;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function getExemptions(address holder) external view returns (bool, bool, bool, bool) {
        return (isFeeExempt[holder], isDividendExempt[holder], isTxLimitExempt[holder], isMerchant[holder]);
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _sustainingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        sustainingFeeReceiver = _sustainingFeeReceiver;
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setSwapBackSettings(bool _swapEnabled, uint256 _swapThreshold, bool shouldAutomateLiquidity) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
        shouldPairLiquidity = shouldAutomateLiquidity;
    }

    function setTargetLiquidity(uint256 _targetLiquidity, uint256 _targetLiquidityDenominator) external onlyOwner {
        targetLiquidity = _targetLiquidity;
        targetLiquidityDenominator = _targetLiquidityDenominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minPeriodCustom, uint256 _minDistribution, uint256 _minDistributionCustom, uint256 _defaultThreshold, uint256 _rotatingThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minPeriodCustom, _minDistribution, _minDistributionCustom, _defaultThreshold, _rotatingThreshold);
    }

    function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas < 10000000);
        distributorGas = gas;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2500);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair && holder != DEAD);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0, true, true); //ensures both Custom Rewards & Default Rewards are disabled
            distributor.setShare(holder, 0, true, false); //ensures both Custom Rewards & Default Rewards are disabled
        }
        else {
            distributor.setShare(holder, _balances[holder], true, enabledCustomRewards[holder]);
        }
    }
    /**
     * Buy and Burn EarnPay with bnb stored in contract
     */
    function triggerEarnPayBuyback(uint256 amount) external onlyOwner {
        buyTokens(amount, DEAD);
    }
    /** Sets Various Fees */
    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _sustainingFee, uint256 _rocketPoolFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        sustainingFee = _sustainingFee;
        rocketPoolFee = _rocketPoolFee;
        totalFeeSells = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_sustainingFee).add(_rocketPoolFee);
        feeDenominator = _feeDenominator;
        require(totalFeeSells < feeDenominator/2);
    }
    function setOtherFees(uint256 _buyFee, uint256 _transferFee, uint256 _merchantFee) external onlyOwner {
        totalFeeBuys = _buyFee;
        totalFeeTransfers = _transferFee;
        totalFeeTransfersMerchant = _merchantFee;
    }
    function setDexRouter(address nRouter) external onlyOwner{
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
        _allowances[address(this)][address(router)] = _totalSupply;
    }

    function setBuyBoostRewardMultipliers(uint _rewardIndex, uint _rewardIndexMult, uint _rewardIndex2, uint _rewardIndex2Mult, uint256 _chanceMultiplierBuyThreshold) external onlyOwner {
        rewardIndex = _rewardIndex;
        rewardIndexMult = _rewardIndexMult;
        rewardIndex2 = _rewardIndex2;
        rewardIndex2Mult = _rewardIndex2Mult;
        chanceMultiplierBuyThreshold = _chanceMultiplierBuyThreshold;
    }
    
    function setTokenContractAddress(address _nToken, bool _processManually) external onlyOwner {
        if(_processManually)
            distributor.processManually(false);
        distributor.setTokenAddress(_nToken);
        emit SwappedTokenAddresses(_nToken);
    }

    function setTokenContractAddressRotating(address _nToken, bool _processManually) external onlyOwner {
        if(_processManually)
            distributor.processManually(true);
        distributor.setCustomTokenAddress(_nToken);
        emit SwappedTokenAddresses(_nToken);
    }


    function isCustomTokenEnabled(address holder) external view returns (bool)
    {
        return enabledCustomRewards[holder];
    }
    function switchReflections() external {
        require(!isDividendExempt[msg.sender], 'address dividend exempt');

        if(!enabledCustomRewards[msg.sender]) {
            enabledCustomRewards[msg.sender] = true;
            try distributor.setShare(msg.sender, 0, true, false) { //pay dividends then remove from regular shareholder list
				distributor.setShare(msg.sender,_balances[msg.sender], false, true); //adds to custom token shareholder list
			}
			catch {
				distributor.setShare(msg.sender, 0, false, false);  //if balance owed reverts due to contract changing, do not try to process dividends
				distributor.setShare(msg.sender,_balances[msg.sender], false, true); //adds to custom token shareholder list
			}
        }
        else {
            enabledCustomRewards[msg.sender] = false;
            try distributor.setShare(msg.sender, 0, true, true) { //pay dividends then remove from custom token shareholder list
				distributor.setShare(msg.sender,_balances[msg.sender], false, false); //adds to regular shareholder list
			}
			catch {
				distributor.setShare(msg.sender, 0, false, true); //if balance owed reverts due to contract changing, do not try to process dividends
				distributor.setShare(msg.sender,_balances[msg.sender], false, false); //adds to regular shareholder list
			}
        }
    }

    function getBalances() public view returns(uint256, uint256, uint256, uint256){
        return (address(this).balance, _balances[address(this)], tokenRewardBalance, customTokenRewardBalance);
    }
    
    /** Returns the Circulating Supply of EarnPay ( supply not owned by Burn Wallet ) */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply()) > target;
    }
    
    function getDistributorAddress() external view returns (address) {
        return address(distributor);
    }
    
    function togglePaySettings(uint _option) external {
        //toggle Transfer Dividends
        if(_option == 1){
            enabledTransferDividends[msg.sender] = !enabledTransferDividends[msg.sender];
        }
        //toggle Transfer Earnings
        if(_option == 2){
            disabledTransferEarnings[msg.sender] = !disabledTransferEarnings[msg.sender];
        }
        //toggle Dust Rewards
        if(_option == 3){
            disabledRewardDust[msg.sender] = !disabledRewardDust[msg.sender];
        }
    }
    function getTransferSettings(address holder) external view returns (bool, bool, bool) {
        return (enabledTransferDividends[holder],!disabledTransferEarnings[holder], !disabledRewardDust[holder]);
    }
    function claimEarnings() external returns (bool) {
        distributor.claimDividend(enabledCustomRewards[msg.sender], msg.sender);
        return true;
    }
    //meant to handle resetting shares if holder address reverts at claiming after switching contracts. If it does not revert, it will distribute dividends to avoid loss of shares.
    function emergencyResetShares() external {
        try distributor.setShare(msg.sender, _balances[msg.sender], true, enabledCustomRewards[msg.sender]) {}
        catch {distributor.setShare(msg.sender, _balances[msg.sender], false, enabledCustomRewards[msg.sender]);} 
    }
    function manualSwapBack() external {
        if(shouldSwapBack()) { 
            swapBack();
            if(!isDividendExempt[msg.sender] && _balances[msg.sender] >= megaPayThreshold)
                boostRewardIndex[msg.sender] = boostRewardIndex[msg.sender].add(1);
        }
    }
    function getUnpaidReflections(address holder) external view returns (uint256) {
        return distributor.getUnpaidEarnings(holder, enabledCustomRewards[msg.sender]);
    }
    function getUserReflectionsEarnedAndWinnings(address holder) external view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 DefaultTotalRealised, uint256 RotatingTotalRealised) = distributor.getTotalEarnings(holder);
        return  (DefaultTotalRealised, RotatingTotalRealised,_buyBonusEarnings[holder], _megaPayEarnings[holder], spaceDustEarnings[holder]);
    }
    function setIsMerchant(address holder, bool isRegisteredMerchant) external onlyOwner {
        isMerchant[holder] = isRegisteredMerchant;
    }





/*

        ░██╗░░░░░░░██╗██╗░░██╗░█████╗░██╗░░░░░███████╗  ████████╗██╗███╗░░░███╗███████╗██████╗░
        ░██║░░██╗░░██║██║░░██║██╔══██╗██║░░░░░██╔════╝  ╚══██╔══╝██║████╗░████║██╔════╝██╔══██╗
        ░╚██╗████╗██╔╝███████║███████║██║░░░░░█████╗░░  ░░░██║░░░██║██╔████╔██║█████╗░░██████╔╝
        ░░████╔═████║░██╔══██║██╔══██║██║░░░░░██╔══╝░░  ░░░██║░░░██║██║╚██╔╝██║██╔══╝░░██╔══██╗
        ░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║███████╗███████╗  ░░░██║░░░██║██║░╚═╝░██║███████╗██║░░██║
        ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝  ░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚═╝

*/
    function inWhaleTimer(address account) external view returns (bool, uint256, uint) {
        uint256 delta = block.timestamp.sub(_timeSinceFirstSell[account]);
        return ((delta > 0 && delta < whaleSellTimer && lastSellAmount[account] > whaleSellThreshold), lastSellAmount[account], _timeSinceFirstSell[account]);
    }
    function setWhaleSettings(uint256 _sellThreshold, uint _time, uint8 _feeMultiplier, uint8 _feeDivider) external onlyOwner {
        whaleSellThreshold = _sellThreshold;
        whaleSellTimer = _time;
        whaleFeeMultiplier = _feeMultiplier;
        whaleFeeDivider = _feeDivider;
    }

/*

        ██████╗░░█████╗░░█████╗░██╗░░██╗███████╗████████╗  ██████╗░░█████╗░░█████╗░██╗░░░░░░██████╗
        ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██╔════╝╚══██╔══╝  ██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔════╝
        ██████╔╝██║░░██║██║░░╚═╝█████═╝░█████╗░░░░░██║░░░  ██████╔╝██║░░██║██║░░██║██║░░░░░╚█████╗░
        ██╔══██╗██║░░██║██║░░██╗██╔═██╗░██╔══╝░░░░░██║░░░  ██╔═══╝░██║░░██║██║░░██║██║░░░░░░╚═══██╗
        ██║░░██║╚█████╔╝╚█████╔╝██║░╚██╗███████╗░░░██║░░░  ██║░░░░░╚█████╔╝╚█████╔╝███████╗██████╔╝
        ╚═╝░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚══════╝░░░╚═╝░░░  ╚═╝░░░░░░╚════╝░░╚════╝░╚══════╝╚═════╝░

*/


    function enableRocketPool(bool _enablePool, bool _enableContributionOnBuys) external onlyOwner {
        //Allows the contract owner to enable the reflection pool feature
        enableRocketPools = _enablePool;
        bonusContributionBuys = _enableContributionOnBuys;
    }

    //Calculates whether the reflection pool is awarded by rolling a random number
    function calculatePoolReward(bool _transferring, uint _chanceMultiplier) private returns (uint256) {
        // If the transfer is a buy or wallet-wallet transfer, and the reflection pool is above a certain token threshold, start to award it
        uint256 reward = 0;
        uint256 poolTokens = megaPay;
        uint _cPoolChance = _transferring ? megaPayTransferChance : megaPayChance;
        if (poolTokens >= megaPayThreshold) {
            // Generates a random number between 1 and 1000
            lastRoll = random(); 
            if(lastRoll <= _cPoolChance.mul(_chanceMultiplier)) {
                reward = poolTokens;
            }
        } 
        return reward;
    }
    function random() private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % 1000);
        r = r.add(1);
        _nonce++;
        return r;
    }

    function setDustDividers(uint256 _earnPayDustDivider, uint256 _earnPayDustMultiplier, uint256 _earnPayDustRateDivider, uint256 _earnPayDustRateMultiplier, uint256 _distributorDustDivider, uint256 _distributorDustMultiplier, uint256 _rewardRateDivider, uint256 _rewardRateMultiplier) external onlyOwner {
        require(_earnPayDustDivider > 0 && _earnPayDustRateDivider > 0 && _distributorDustDivider > 0 && _rewardRateDivider > 0, 'Divs must be > 0');
        require(_earnPayDustDivider >= _earnPayDustMultiplier && _earnPayDustRateDivider >= _earnPayDustRateMultiplier && _distributorDustDivider >= _distributorDustMultiplier && _rewardRateDivider >= _rewardRateMultiplier, 'Divider must be >= Multiplier');
        distributor.setDustDividers(_distributorDustDivider, _distributorDustMultiplier,  _rewardRateDivider, _rewardRateMultiplier);
        earnPayDustDivider = _earnPayDustDivider;
        earnPayDustMultiplier = _earnPayDustMultiplier;
        spaceDustRateDivider = _earnPayDustRateDivider;
        spaceDustRateMultiplier = _earnPayDustRateMultiplier;
    }

    function rocketPoolTransfer(address winner, uint256 rewardAmount, bool awardMega) internal {
        if(awardMega)
        {
            _balances[winner] = _balances[winner].add(rewardAmount);
            _megaPayEarnings[winner] = _megaPayEarnings[winner].add(rewardAmount);
            megaPay = 0;
            previousWinner = winner;
            previousWonAmount = rewardAmount;
            previousWinTime = block.timestamp;
            emit MegaPayAward(winner, rewardAmount, block.timestamp);
            emit Transfer(address(this), winner, rewardAmount);
        }
        else{
            _balances[winner] = _balances[winner].add(rewardAmount);
            _buyBonusEarnings[winner] = _buyBonusEarnings[winner].add(rewardAmount);
            buyBoost = 0;
            previousBoostWinner = winner;
            emit BonusBuyAward(winner, rewardAmount);
            emit Transfer(address(this), winner, rewardAmount);
        }
    }

    function setMegaPaySettings(uint256 _threshold, uint256 _minimumSpend, uint256 _minimumHODL, uint256 _minimumTransfer, uint _buyChance, uint _bonusChance, uint _walletToWalletChance) external onlyOwner {
        megaPayThreshold = _threshold;
        megaPayMinimumSpend = _minimumSpend;
        megaPayMinimumHODL = _minimumHODL;
        megaPayChance = _buyChance;
        bonusChance = _bonusChance;
        megaPayTransferChance = _walletToWalletChance;
        megaPayMinimumTransfer = _minimumTransfer;
    }
    function getMegaPaySettings() external view returns (uint256, uint256, uint256, uint256, uint, uint, uint) {
        return (megaPayThreshold, megaPayMinimumSpend, megaPayMinimumHODL, megaPayMinimumTransfer, megaPayChance, bonusChance, megaPayTransferChance);
    }
    function getUserQualifiesForMegaPay(address holder) external view returns (bool) {
        return  enableRocketPools && !isDividendExempt[holder] && (_balances[holder] >= megaPayMinimumHODL);
    }

/*
            
        ░██╗░░░░░░░██╗░█████╗░██████╗░███╗░░░███╗██╗░░██╗░█████╗░██╗░░░░░███████╗
        ░██║░░██╗░░██║██╔══██╗██╔══██╗████╗░████║██║░░██║██╔══██╗██║░░░░░██╔════╝
        ░╚██╗████╗██╔╝██║░░██║██████╔╝██╔████╔██║███████║██║░░██║██║░░░░░█████╗░░
        ░░████╔═████║░██║░░██║██╔══██╗██║╚██╔╝██║██╔══██║██║░░██║██║░░░░░██╔══╝░░
        ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║██║░╚═╝░██║██║░░██║╚█████╔╝███████╗███████╗
        ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚════╝░╚══════╝╚══════╝

        ░░██╗██████╗░███████╗██╗░░░██╗███████╗██████╗░░██████╗███████╗  ██████╗░██╗░░░██╗░██████╗░██╗░░
        ░██╔╝██╔══██╗██╔════╝██║░░░██║██╔════╝██╔══██╗██╔════╝██╔════╝  ██╔══██╗██║░░░██║██╔════╝░╚██╗░
        ██╔╝░██████╔╝█████╗░░╚██╗░██╔╝█████╗░░██████╔╝╚█████╗░█████╗░░  ██████╔╝██║░░░██║██║░░██╗░░╚██╗
        ╚██╗░██╔══██╗██╔══╝░░░╚████╔╝░██╔══╝░░██╔══██╗░╚═══██╗██╔══╝░░  ██╔══██╗██║░░░██║██║░░╚██╗░██╔╝
        ░╚██╗██║░░██║███████╗░░╚██╔╝░░███████╗██║░░██║██████╔╝███████╗  ██║░░██║╚██████╔╝╚██████╔╝██╔╝░
        ░░╚═╝╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚══════╝  ╚═╝░░╚═╝░╚═════╝░░╚═════╝░╚═╝░░

*/
    //allows the ability for devs/owners to send token directly to the reward pools for holders to claim 
    function wenReverseRug(uint256 megaPayAmount, uint256 buyBoostAmount, uint256 spaceDustAmount) external returns(bool){
        require(megaPayAmount > 0 || buyBoostAmount > 0 || spaceDustAmount > 0, 'Amnt needs to be > 0 for 1 field');
        require(_balances[msg.sender] >= megaPayAmount.add(buyBoostAmount).add(spaceDustAmount), 'user does not own enough tokens');
        _balances[msg.sender] = _balances[msg.sender].sub(megaPayAmount, 'cannot have neg tokens').sub(buyBoostAmount, 'cannot have neg tokens').sub(spaceDustAmount,'cannot have neg tokens');
        megaPay = megaPay.add(megaPayAmount);
        buyBoost = buyBoost.add(buyBoostAmount);
        spaceDust = spaceDust.add(spaceDustAmount); 
        reverseRugAccumulator = reverseRugAccumulator.add(megaPayAmount).add(buyBoostAmount).add(spaceDustAmount);
        emit WenReverseRug(msg.sender, megaPayAmount, buyBoostAmount, spaceDustAmount);
        return true;
    } 
    /*
    function reverseRug(uint256 tokenAmount) external returns(bool) {
        require(_balances[msg.sender] >= tokenAmount,'user does not own enough tokens');
        _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount, 'cannot have negative tokens');
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
        bool swapDefault = _balances[address(this)].sub(customTokenRewardBalance) >= swapThreshold; 
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{}
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        try distributor.deposit{value: amountBNB.div(2)}(swapDefault) {} catch {}
        try distributor.deposit{value: amountBNB.sub(amountBNB.div(2))}(!swapDefault) {} catch {}
        return true;
    }
    */


/*
            
        ██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗██╗░░██╗░█████╗░██╗░░░░░███████╗░██████╗
        ██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║░░██║██╔══██╗██║░░░░░██╔════╝██╔════╝
        ██████╦╝██║░░░░░███████║██║░░╚═╝█████═╝░███████║██║░░██║██║░░░░░█████╗░░╚█████╗░
        ██╔══██╗██║░░░░░██╔══██║██║░░██╗██╔═██╗░██╔══██║██║░░██║██║░░░░░██╔══╝░░░╚═══██╗
        ██████╦╝███████╗██║░░██║╚█████╔╝██║░╚██╗██║░░██║╚█████╔╝███████╗███████╗██████╔╝
        ╚═════╝░╚══════╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚══════╝╚══════╝╚═════╝░
*/
    function setBlackHole(uint256 _blackHoleMinimumSD, uint256 _blackHoleMinimumMP, uint _bHchanceMultiplier) external onlyOwner {
        blackHoleMinimum = _blackHoleMinimumSD;
        blackHoleMinimumMP = _blackHoleMinimumMP;
        bHchanceMultiplier = _bHchanceMultiplier;
        //emit SetBlackHole(_blackHoleMinimumSD, _blackHoleMinimumMP, _bHchanceMultiplier);
    }

    //Holder can claim space dust 
    function sendToBlackHole(uint256 tokenAmount, bool blackHoleMechanismChoice) external {
        require(!isDividendExempt[msg.sender] && enableRocketPools,'is exempt-disabled');
        require(_balances[msg.sender] >= tokenAmount && _balances[msg.sender] >=megaPayThreshold, 'user does not own enough tokens');
        uint256 amountReceived = !isFeeExempt[msg.sender] ? takeFee(pair, msg.sender, tokenAmount) : tokenAmount;
        _totalSupply = _totalSupply.sub(amountReceived, 'total supply cannot be neg');
        _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount, 'cannot have neg tokens');
        spaceDustBurned = spaceDustBurned.add(amountReceived);
        if(blackHoleMechanismChoice)
        {
            require(tokenAmount >= blackHoleMinimum, 'amnt not sufficient');
            require(!disabledRewardDust[msg.sender], 'reward dust not enabled');
            uint256 dustAllocation=0;
            if (spaceDust > 0) {
                        dustAllocation = spaceDust.div(spaceDustRateDivider).mul(spaceDustRateMultiplier);
                        _balances[msg.sender] = _balances[msg.sender].add(dustAllocation);
                        spaceDustEarnings[msg.sender] = spaceDustEarnings[msg.sender].add(dustAllocation);
                        emit DustTransfer(msg.sender, spaceDust, block.timestamp);
                        emit Transfer(address(this), msg.sender, spaceDust);
                        spaceDust = spaceDust.sub(dustAllocation);
                        try distributor.transferAndBurnRewardDust(msg.sender) {} catch {}
                        bool triggerDividends = !disabledTransferEarnings[msg.sender];
                        try distributor.setShare(msg.sender, _balances[msg.sender], triggerDividends, enabledCustomRewards[msg.sender]) {} catch {} 
            }
        }
        else{
            require(tokenAmount >= blackHoleMinimumMP, 'amnt not sufficient');
            uint256 chance_multiplier = boostRewardIndex[msg.sender] >= rewardIndex2 ? rewardIndex2Mult : 0;
            uint256 poolReward = calculatePoolReward(false, bHchanceMultiplier.add(chance_multiplier));
            if (poolReward > 0) {
                rocketPoolTransfer(msg.sender, poolReward, true); 
            }
            if (buyBoost > 0 && (random() <= bonusChance.mul(bHchanceMultiplier.add(chance_multiplier)))) {
                rocketPoolTransfer(msg.sender, buyBoost, false); //Awards bonus pool if won
            }
            boostRewardIndex[msg.sender] = boostRewardIndex[msg.sender].add(1);  
        }
        internalApprove(_dexRouter, _totalSupply);
        internalApprove(address(pair), _totalSupply);
        emit Transfer(msg.sender, address(0), amountReceived);
        emit SentToBlackHole(msg.sender, amountReceived);
    }
    /*
    function setDistributor(address payable newDistributor) external onlyOwner {
        require(newDistributor != address(distributor), 'Distributor already has this address');
        distributor = Distributor(newDistributor);
        //emit SwappedDistributor(newDistributor);
    }*/

    event SentToBlackHole(address sender, uint256 tokenAmount);
    event MegaPayAward(address winner, uint256 amount, uint time);
    event BonusBuyAward(address winner, uint256 amount);
    event DustTransfer(address winner, uint256 amount, uint time);
    event WenReverseRug(address sender, uint256 megaPayAmount, uint256 buyBoostAmount, uint256 spaceDustAmount);
    event SwappedTokenAddresses(address newToken);
   }