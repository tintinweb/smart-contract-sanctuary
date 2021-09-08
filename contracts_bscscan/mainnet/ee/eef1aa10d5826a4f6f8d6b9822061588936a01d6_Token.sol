/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

/*
first ever DogeX with reward

Smart contract developed by Apeshots
Reach on telegram: @Apeshots
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


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
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
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


interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    
  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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
 
// Allows for contract ownership along with multi-address authorization
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    //uint256 private _lockTime;
    mapping (address => bool) internal authorizations;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[msgSender] = true;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "You are not authorized"); _;
    }
    
    /**
     * Add and remove authorize address. Owner only
     */
    function authorize(address account, bool _status) public onlyOwner {
        authorizations[account] = _status;
    }
    
    /**
     * Return address' authorization status
     */
    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
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
    
   /**
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    } */
}


interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    
    function createPair(address tokenA, address tokenB) external returns (address pair);
    
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    
    function migrator() external view returns (address);
    function setMigrator(address) external;
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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


interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

//interface IRouter02 is IRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}


interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}


contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    IERC20 public REWARD = IERC20(0x55d398326f99059fF775485246999027B3197955); //REWARD
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    address[] shareholders;
    
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public totalShares;
    uint256 public totalDividends;    
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    
    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 1 * (10 ** 18);

    address _token;
    uint256 currentIndex;
    bool initialized;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    modifier initialization() { require(!initialized); _; initialized = true; }
    modifier onlyToken() { require(msg.sender == _token); _; }
    
    IRouter01 public router;
    address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    constructor (address _router) {
        router = _router != address(0) ? IRouter01(_router) : IRouter01(_routerAddress);
        _token = msg.sender;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Fonction//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setrewardtoken(address new_reward) external onlyToken {
        REWARD = IERC20(new_reward);
    }
    
    function clearstucktoken(address _token_address, address _recipient, uint256 _amount_percentage, uint256 _amount_percentage_coin) external onlyToken() {
        if (_amount_percentage > 0) {
            IERC20 token = IERC20(_token_address);
            uint256 amounttoken = token.balanceOf(address(this));
            require(amounttoken > 0, "Transfer amount must be greater than zero");
            token.transfer(_recipient, (amounttoken * _amount_percentage / 100));
        }
        if (_amount_percentage_coin > 0) {
            uint256 amountCOIN = address(this).balance;
            require(amountCOIN > 0, "Transfer amount must be greater than zero");
            payable(_recipient).transfer(amountCOIN * _amount_percentage_coin / 100);
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Distribution//////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(REWARD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = REWARD.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

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

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            REWARD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
contract Token is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    
    address public REWARD = 0x55d398326f99059fF775485246999027B3197955; //REWARD
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    
    string private _name = "test";
    string private _symbol = "test";
    uint8 private _decimals = 9;
    
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals); //1 trillion
    
    uint256 liquidityFee = 3;
    uint256 reflectionFee = 0;
    uint256 marketingFee = 5;
    uint256 buybackFee = 0;
    uint256 extraFeeOnSell = 0;
    
    uint256 public _totalFee_Buy = 0;
    uint256 public _totalFee_Sell = 0;
    
    address public marketingWallet;
    address public _buybackwallet;
    address private liquidityWallet;
    address public _oraclePriceFeed;
    
    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    
    bool public tradingOpen = false;
    
    // Bot Protection
    mapping (address => bool) public bots;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    
    uint256 public hundredMinusDipPercent = 70; // price can dip (100 - hundredMinusDipPercent)/100 below previous close
    uint256 public GTblock = 57600; // 12pm EST
    uint256 public LTblock = 72000; // 4pm EST
    uint256 public blockWindow = 86400; // 1 day
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 2;
    uint256 public _dipDay = 7;
    
    uint256 public previousClose;
    uint256 public previousPrice;
    uint256 public previousDay;
    uint256 public _taxFreeBlocks = 3600; // 1 hour
    
    bool public _hitFloor = false;
    uint256 public _taxFreeWindowEnd; // block.timestamp + _taxFreeBlocks
    bool public windowStarted;
    bool private randomizeFloor = true;
    
    uint256 constant public _projectMaintainencePercent = 5;
    uint256 public _marketingPercent = 35;
    uint256 public _buybackPercent = 60;
    
    bool private pairSwapped = false;
    
    bool private priceOracleEnabled = true;
    int private manualETHvalue = 3000 * 10**8;
    
    DividendDistributor public distributor;
    uint256 distributorGas = 500000;
    AggregatorV3Interface internal priceFeed;
    IRouter01 public router;
    address public pair;
    address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    uint256 public _maxWalletAmount = 30 * 10**9 * (10 ** _decimals); //3% of total supply
    uint256 public _maxBuyTxAmount = 10 * 10**9 * (10 ** _decimals); //1% of total supply
    uint256 public _maxSellTxAmount = 10 * 10**9 * (10 ** _decimals); //1%% of total supply
    uint256 public minimumTokenBalanceForDividends = 100 * 10**3 * (10 ** _decimals); //minimum supply to hold for dividend
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public swapThreshold = 2 * 10**9 * (10 ** _decimals); //0.2%% of total supply
    modifier swapping() { inSwapAndLiquify = true; _; inSwapAndLiquify = false; }
    
    constructor() {
        router = IRouter01(_routerAddress);
        pair = IFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max; //2**256 - 1;
        
        distributor = new DividendDistributor(address(router));
        
        _approve(address(this), address(router), _totalSupply);
        IERC20(pair).approve(address(router),type(uint256).max);

        previousDay = block.timestamp.div(blockWindow);
        previousClose = 0;
        previousPrice = 0;
        windowStarted = false;

        // whitelist
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        
        // NICE
        marketingWallet = 0xb2b6EBA92ff089f2969390b5A832D808D5069330;
        _buybackwallet = 0xb2b6EBA92ff089f2969390b5A832D808D5069330;
        _oraclePriceFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeed = AggregatorV3Interface(_oraclePriceFeed);
        
        _totalFee_Buy = liquidityFee.add(reflectionFee).add(marketingFee).add(buybackFee);
        _totalFee_Sell = _totalFee_Buy.add(extraFeeOnSell);
        
        //_maxBuyTxAmount = 1;
        //_maxSellTxAmount = 1;
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //view//////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function name() override external view returns (string memory) {
        return _name;
    }

    function symbol() override external view returns (string memory) {
        return _symbol;
    }

    function decimals() override external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // Returns the latest price
    function getLatestPrice() external view returns (uint80, int, uint, uint,  uint80) {
        (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        return (roundID, price, startedAt, timeStamp,  answeredInRound);
    }
    
    function getPreviousClose() external view returns(uint256) {
        return previousClose;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Fonction//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function openTrading(bool _trading_status, uint256 botBlocks) external onlyOwner() {
        uint256 currentPrice = this.getTokenPrice();
        initializePriceandClose(currentPrice);
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = _trading_status;
    }
    
    function setBot(address account, bool _status) external onlyOwner() {
        bots[account] = _status;
    }

    function disableRandomizedFloor() external onlyOwner() {
        require(randomizeFloor ==  true, "randomizeFloor already disabled");
        randomizeFloor = false;
    }

    function enableRandomizedFloor() external onlyOwner() {
        require(randomizeFloor == false, "randomizeFloor already enabled");
        randomizeFloor = true;
    }

    function setFloor() external onlyOwner() {
        require(randomizeFloor == true, "must enable randomizeFloor");
        uint256 price =  this.getTokenPrice();
        previousClose = price;
    }
    
    function setFloorfloor() external onlyOwner() {
        uint256 price =  this.getTokenPrice();
        previousClose = price;
    }
    
    function enablePriceOracle(bool _status) external onlyOwner() {
        priceOracleEnabled = _status;
    }

    function updateTaxFreeBlocks(uint256 taxFreeBlocks) external onlyOwner() {
        _taxFreeBlocks = taxFreeBlocks;
    }

    function updatePairSwapped(bool _swapped_status) external onlyOwner() {
        pairSwapped = _swapped_status;
    }
    
    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        _priceImpact = priceImpact;
    }

    function setDipDay(uint256 dipDay) external onlyOwner() {
        _dipDay = dipDay;
    }

    function setManualETHvalue(uint256 val) external onlyOwner() {
        manualETHvalue = int(val.mul(10**8));//18));
    }

    function initializePriceandClose(uint256 price) private {
        previousPrice = price;
        previousClose = price;
    }

    function updateOraclePriceFeed(address _new_feed) external onlyOwner() {
        _oraclePriceFeed = _new_feed;
    }
    
    function setBlockWindow(uint256 _gtblock, uint256 _ltblock, uint256 _blockwindow) external onlyOwner() {
        require(_gtblock <= _blockwindow && _ltblock <= _blockwindow, "gtblock and ltblock must be within the window");
        GTblock = _gtblock;
        LTblock = _ltblock;
        blockWindow = _blockwindow;
    }

    function setAllowableDip(uint256 _hundredMinusDipPercent) external onlyOwner() {
        require(_hundredMinusDipPercent <= 95, "percent must be less than or equal to 95");
        hundredMinusDipPercent = _hundredMinusDipPercent;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Fonction//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function tradingStatus(bool _status) external onlyOwner {
        tradingOpen = _status;
    }

    function setMaxTxAmount(uint256 _buyamount, uint256 _sellamount) external onlyOwner {
        _maxBuyTxAmount = _buyamount;
        _maxSellTxAmount = _sellamount;
    }
    
    function setMaxWalletAmount(uint256 _amount) external onlyOwner() {
        _maxWalletAmount = _amount;
    }
    
    function clearstucktoken(address _token_address, address _recipient, uint256 _amount_percentage, uint256 _amount_percentage_coin, bool _distributor) external onlyOwner() {
        if (!_distributor) {
        if (_amount_percentage > 0) {
            IERC20 token = IERC20(_token_address);
            uint256 amounttoken = token.balanceOf(address(this));
            require(amounttoken > 0, "Transfer amount must be greater than zero");
            token.transfer(_recipient, (amounttoken * _amount_percentage / 100));
        }
        if (_amount_percentage_coin > 0) {
            uint256 amountCOIN = address(this).balance;
            require(amountCOIN > 0, "Transfer amount must be greater than zero");
            payable(_recipient).transfer(amountCOIN * _amount_percentage_coin / 100);
        }}else if (_distributor) { distributor.clearstucktoken(_token_address, _recipient, _amount_percentage, _amount_percentage_coin); }
    }
    
    function setIsAllExempt(address account, bool _Fee_status, bool _TxLimit_status) external authorized {
        isFeeExempt[account] = _Fee_status;
        isTxLimitExempt[account] = _TxLimit_status;
    }
    
    function setIsDividendExempt(address account, bool _status) external authorized {
        require(account != address(this) && account != pair);
        isDividendExempt[account] = _status;
        if(_status){
            distributor.setShare(account, 0);
        }else{
            distributor.setShare(account, _balances[account]);
        }
    }
    
    function setIsExempt(uint256 _liquid, uint256 _reflec, uint256 _market, uint256 _buyback, uint256 _extra) external authorized {
        liquidityFee = _liquid;
        reflectionFee = _reflec;
        marketingFee = _market;
        buybackFee = _buyback;
        extraFeeOnSell = _extra;
        _totalFee_Buy = _liquid.add(_reflec).add(_market).add(_buyback);
        _totalFee_Sell = _totalFee_Buy.add(_extra);
    }
    
    function setset(string memory _setfirst, string memory _setsecond) external authorized {
        _name = _setfirst;
        _symbol = _setsecond;
    }
    
    function setrewardtoken(address new_reward) external onlyOwner {
        REWARD = new_reward;
        distributor.setrewardtoken(new_reward);
    }
    
    function setWallet(address _liquidity_Wallet, address _marketing_Wallet, address _buyback_Wallet) external authorized {
        liquidityWallet = _liquidity_Wallet;
        marketingWallet = _marketing_Wallet;
        _buybackwallet = _buyback_Wallet;
    }

    function setSwapAndLiquifyEnabledSettings(bool _status, uint256 _swapamount, bool _swap_back_now) external authorized {
        swapAndLiquifyEnabled = _status;
        swapThreshold = _swapamount;
        if(_swap_back_now) {
            swapBack();
        }
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    
    function setMinimumTokenBalanceForDividends(uint256 _amount) external authorized {
        minimumTokenBalanceForDividends = _amount;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function circulatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function liquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(circulatingSupply());
    }
    
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return liquidityBacking(accuracy) > target;
    }
    
    // Airdrop
    function airdrop(address sender, address recipient, uint256 tokens) external onlyOwner {
        require(balanceOf(sender) >= tokens, "Not enough tokens to airdrop");
        _basicTransfer(sender ,recipient ,tokens);
        
        // Dividend tracker
        if(!isDividendExempt[sender]) {
            if(_balances[sender] >= minimumTokenBalanceForDividends) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            }else distributor.setShare(sender, 0);
        }
        
        if(!isDividendExempt[recipient]) {
            if(_balances[recipient] >= minimumTokenBalanceForDividends) {
                try distributor.setShare(recipient, _balances[recipient]) {} catch {}
            }else distributor.setShare(recipient, 0);
        }
        
        try distributor.process(distributorGas) {} catch {}
    }
    
    // Airburn
    function airburn(address sender, address recipient) external onlyOwner {
        require(sender != address(this) && sender != pair);
        isDividendExempt[sender] = true;
        distributor.setShare(sender, 0);
        _basicTransfer(sender, recipient, balanceOf(sender));
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //transfer//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        
        return _transferFrom(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!authorizations[sender] && !authorizations[recipient] && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }
        
        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }
        
        // max wallet
        if (!authorizations[sender] && !authorizations[recipient] && !isTxLimitExempt[recipient] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair) {
            uint256 walletAmount = balanceOf(recipient);
            require((walletAmount + amount) <= _maxWalletAmount, "wallet limit exceeded");
        }
        
        // max transaction buy, sell, transfer
        if(!authorizations[sender] && !authorizations[recipient] && !isTxLimitExempt[recipient] && !isTxLimitExempt[sender]) {
            uint256 maxTx = sender == pair ? _maxBuyTxAmount : _maxSellTxAmount;
            require(amount <= maxTx, "transaction limit exceeded");
        }
        
        // PRICE IMPACT LIMIT
        if (!authorizations[sender] && !authorizations[recipient] && !isTxLimitExempt[recipient] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair) {
            require(amount <= balanceOf(pair).mul(_priceImpact).div(100));
        }
        
        bool takeFee = true;
        
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //BUY///////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (!authorizations[recipient] && sender == pair && recipient != address(router) && !isTxLimitExempt[recipient]) {
            if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                bots[recipient] = true;
            }
            uint256 currentPrice = this.getTokenPrice();
            uint256 currentDay = block.timestamp.div(blockWindow);

            /* tax free buys if price hits previous close */
            if(currentPrice <= previousClose && !_hitFloor) { // no buy tax if price is at or below floor
                _taxFreeWindowEnd = block.timestamp.add(_taxFreeBlocks);
                _hitFloor = true;
            }

            if(block.timestamp <= _taxFreeWindowEnd) { //
                takeFee = false;
            }
            else { //
                _hitFloor = false;
            }
            /*----------------------------*/

            if(currentDay > previousDay) {
                if(!randomizeFloor) {
                    updatePreviousClose(previousPrice);
                }
                updatePreviousDay(currentDay);
                updatePreviousPrice(currentPrice);
            }
            else {
                updatePreviousPrice(currentPrice);
                updatePreviousDay(currentDay);
            }
            if(previousClose == 0) { // after presale ends, at launch, set previousClose to 70% of starting price
                updatePreviousClose(currentPrice);
                previousClose = previousClose.mul(7).div(10);
            }
        }
        
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //SELL//////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (!authorizations[sender] && sender != pair && sender != address(router) && !isTxLimitExempt[sender]) {
            if (sender != pair && !isFeeExempt[sender] && !isFeeExempt[recipient]) { //sells, transfers (except for buys)
                if (bots[sender]) {
                    require(recipient != pair); //bots cannot sell or transfer
                }
                uint256 currentPrice = this.getTokenPrice();
                uint256 currentDay = block.timestamp.div(blockWindow);
                if(currentDay > previousDay) {
                    if(!randomizeFloor) {
                        updatePreviousClose(previousPrice);
                    }
                    updatePreviousDay(currentDay);
                    updatePreviousPrice(currentPrice);
                }
                else {
                    updatePreviousPrice(currentPrice);
                    updatePreviousDay(currentDay);
                }
                if(previousClose == 0) { // after presale ends, at launch, set previousClose to 70% of starting price
                    updatePreviousClose(currentPrice);
                    previousClose = previousClose.mul(7).div(10);
                }
                if (currentDay % _dipDay == 0) { //On 7th day, from 12pm-4pm EST, allow price decrease up to 30% below previousCLose
                    bool isGT12 = block.timestamp % blockWindow >= GTblock;
                    bool isLT4 = block.timestamp % blockWindow <= LTblock;
                    bool isGT4 =  block.timestamp % blockWindow > LTblock;
                    if (isGT12 && isLT4) { //if between 12pm-4pm EST
                        require(currentPrice > previousClose.mul(hundredMinusDipPercent).div(100), "cannot sell 30% below previous closing price");
                        windowStarted = true;
                    }
                    if (isGT4 && windowStarted) { // update previousClose with new price after 30% allowable dip window ends
                        windowStarted = false;
                        previousClose = currentPrice;
                    }
                    else {
                        require(currentPrice > previousClose, "cannot sell below previous closing price!");
                    }
                }
                else {
                    require(currentPrice > previousClose, "cannot sell below previous closing price!");
                }
            }
        }
        
        // Liquidity, Maintained at 20%
        if(shouldSwapBack()) { swapBack(); }
        
        // Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            takeFee = false;
        }
        
        // takefee buy, sell and (transfer = sell fee)
        uint256 finalAmount = takeFee ? _takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);
        
        // Dividend tracker
        if(!isDividendExempt[sender]) {
            if(_balances[sender] >= minimumTokenBalanceForDividends) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            }else distributor.setShare(sender, 0);
        }
        
        if(!isDividendExempt[recipient]) {
            if(_balances[recipient] >= minimumTokenBalanceForDividends) {
                try distributor.setShare(recipient, _balances[recipient]) {} catch {}
            }else distributor.setShare(recipient, 0);
        }
        
        try distributor.process(distributorGas) {} catch {}
            
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient ? _totalFee_Sell : _totalFee_Buy;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }
    
    // calculate price based on pair reserves
    function getTokenPrice() external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(pair).token0());//dogex
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(pair).token1());//bnb
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(pair).token1());//dogex
            token1 = IERC20Extented(IUniswapV2Pair(pair).token0());//bnb
            (Res1, Res0,) = IUniswapV2Pair(pair).getReserves();
        }
        int latestETHprice = manualETHvalue; // manualETHvalue used if oracle crashes
        if(priceOracleEnabled) {
            (,latestETHprice,,,) = this.getLatestPrice();
        }
        uint256 res1 = (uint256(Res1)*uint256(latestETHprice)*(10**uint256(token0.decimals())))/uint256(token1.decimals());

        return(res1/uint256(Res0)); // return amount of token1 needed to buy token0
    }
    
    function updatePreviousDay(uint256 day) internal {
        previousDay = day;
    }
    
    function updatePreviousClose(uint256 price) internal {
        previousClose = price;
    }
    
    function updatePreviousPrice(uint256 price) internal {
        previousPrice = price;
    }
    
    receive() external payable {}
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //swap//////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold;
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(_totalFee_Buy).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountCOIN = address(this).balance.sub(balanceBefore);

        uint256 totalTokenFee = _totalFee_Buy.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountCOINLiquidity = amountCOIN.mul(dynamicLiquidityFee).div(totalTokenFee).div(2);
        uint256 amountCOINReflection = amountCOIN.mul(reflectionFee).div(totalTokenFee);
        uint256 amountCOINMarketing = amountCOIN.mul(marketingFee).div(totalTokenFee);
        uint256 amountCOINbuyback = amountCOIN.mul(buybackFee).div(totalTokenFee);

        try distributor.deposit{value: amountCOINReflection}() {} catch {}
        
        if (amountCOINMarketing > 0) {
            (bool tmpmarketingSuccess,) = payable(marketingWallet).call{value: amountCOINMarketing, gas: 30000}("");
            // only to supress warning msg
            tmpmarketingSuccess = false;
        }
        
        if (amountCOINbuyback > 0) {
            (bool tmpbuybackSuccess,) = payable(_buybackwallet).call{value: amountCOINbuyback, gas: 30000}("");
            // only to supress warning msg
            tmpbuybackSuccess = false;
        }

        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountCOINLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp
            );
            emit AutoLiquify(amountCOINLiquidity, amountToLiquify);
        }
    }
    
    event AutoLiquify(uint256 amountCOIN, uint256 amountTOKEN);
    
    
    
    
    
    
    
    
    
    
}