/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

/**
 
   #BEE
   
   #LIQ+#RFI+#SHIB+#DOGE = #BEE
   #bbl features:
   3% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   I created a black hole so #Bee token will deflate itself in supply with every transaction
   50% Supply is burned at start.
   
 */

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address /*payable*/) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
contract Ownable is Context {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
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
    }
}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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


contract LEN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    //// ERC-20 init
    string private _name = "len38";
    string private _symbol = "le38"; //TODO
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9; // ~ 10^24
    address private _devAddress = 0x93e6e4B0f3b493A0415646F5Ca8f42b0634A8991; //TODO
    // tokens own
    mapping (address => uint256) private _tOwned;
    // allow owner to use spender's token
    mapping (address => mapping (address => uint256)) private _allowances;
    // max transaction amount
    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
   
    //// account exclusion
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;


    //// referral system
    mapping (address => address) private referrer;
    mapping (address => uint256) private totalReferredToken;
    uint256 private _level1MinReferredToken = 100 * 10**6 * 10**9;
    uint256 private _level2MinReferredToken = 200 * 10**6 * 10**9;
    uint256 private _level3MinReferredToken = 300 * 10**6 * 10**9;
    // thousandth
    uint256 public _referrerFee = 0;
    uint256 private _previousReferrerFee = _referrerFee;
    uint256 public _referreeFee = 0;
    uint256 private _previousReferreeFee = _referreeFee;
    uint256 public _referrerFeePony = 5;
    uint256 public _referrerFeeHorse = 10;
    uint256 public _referrerFeeFireHorse = 20;
    uint256 public _referrerFeeUnicorn = 40;
    uint256 public _referreeFeePony = 5;
    uint256 public _referreeFeeHorse = 10;
    event DevAndReferralFee(
        uint256 devFee,
        uint256 referrerFeePony,
        uint256 referrerFeeHorse,
        uint256 referrerFeeFireHorse,
        uint256 referrerFeeUnicorn,
        uint256 referreeFeePony,
        uint256 referreeFeeHorse
    );


    //// reflection system
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // ~10^77
    // reflection own
    mapping (address => uint256) private _rOwned;  

    //// TAX
    // total tax
    uint256 private _tFeeTotal;

    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
   
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _devFee = 5;
    uint256 private _previousDevFee = _devFee;


    //// liquidity pool
    uint256 private numTokensSellToAddToLiquidity = 0;
    uint256 public minReleaseTime = block.timestamp + 60 * 10;  //TODO: launch date + 1.5 years
    uint256[] public _lockedCommunityLiquidity;
    uint256[] public _releaseTime;  //lock 3 months from date of swap and liquify
    uint256 public _unlockedTotalCommunityLiquidity = 0;

    // pancakeswap liquidity pool init
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    // TODO: log for testing
    event AddLiquidity(
        uint256 amountToekn,
        uint256 amountETH,
        uint256 liquidity
    );
    event RemoveLiquidity(
        uint256 amountToken,
        uint256 amountETH
    );
    event SwapCheck (bool overMinTokenBalance, bool inSwap, bool enableSwap, bool checkAddress,  address _from, address pancakePair);
    event SwapStart (uint256 tokens);
    // enable pancakeswap liquidity pool
    bool public swapAndLiquifyEnabled = true;

   
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //TODO
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
       
        // exclude owner, dev wallet, and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
       
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // get dev address
    function devAddress() public view returns (address) {
        return _devAddress;
    }

    //// ERC-20
    // name of tokens
    function name() public view returns (string memory) {
        return _name;
    }
    // abbreviation of tokens
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    // unit of tokens
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    // total supply of tokens
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    // get tokens amount own by account
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    // transfer tokens from current address (contract writer) to recipient address
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    // approve/autorized spender to use current address's (contract writer) tokens
    // not requires current address to have number of autorized tokens
    function approve(address spender, uint256 amount) public override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }
    // return the total tokens the spender can spend from owner
    // not requires current own to have number of autorized tokens
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    // transfer from sender to recipient if _allowances[sender][contract writer] >= amount
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    // approve() enhancement
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
   

    //// main ERC-20 function
    // transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        // init
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(to != address(0), "ERC20: Transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        bool takeFee = true;

        // check fee
        if(from == uniswapV2Pair || to == uniswapV2Pair) {
            // limit transaction amount only on uniswap to prevent the drastic price impact
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        } else {
            // no fee between account
            takeFee = false;
        }
        // no fee if account is excluded
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        // swap and liquify
        // check contract whether token balacne is enough to swap and add it to liquidity
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        // TODO: can be removed?
        // if(contractTokenBalance >= _maxTxAmount)
        // {
        //     contractTokenBalance = _maxTxAmount;
        // }
        
        emit SwapCheck (
            overMinTokenBalance, inSwapAndLiquify, swapAndLiquifyEnabled, from != uniswapV2Pair, from, uniswapV2Pair
            );
        
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&  // pass if swap and liquify is locked by another contract. Avoid circular liquidity event
            from != uniswapV2Pair &&  // don't swap & liquify if sender is uniswap pair.
            swapAndLiquifyEnabled    
        ) {
            emit SwapStart(
                contractTokenBalance
            );
            //contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
       
        // transfer
        _tokenTransfer(from,to,amount,takeFee);
    }

    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        } else if(sender == uniswapV2Pair && referrer[recipient] != address(0)) {
            address referrerAddr = referrer[recipient];
            totalReferredToken[referrerAddr] = totalReferredToken[referrerAddr].add(amount); //TODO: consider total amount as part of calculation of rank
            customizeFeeForReferral(referrerAddr);
        }
       
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
       
        if(!takeFee) {
            restoreAllFee();
        } else if(sender == uniswapV2Pair && referrer[recipient] != address(0)) { //the sender has a referrer
            restoreForReferralFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private { //tAmount = 1000      1
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount); // 880, 50, 50, 20     0.88 0.05, 0.05, 0.02
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate()); // 1000*10^53, 880*10^53, 50*10^53     10, 8.8, 0.5
       
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);
        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferrerFee(tReferrer, referreeAddr);
            _takeReferreeFee(tReferree, referrer[referreeAddr]);
        }
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);          
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);

        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferrerFee(tReferrer, referreeAddr);
            _takeReferreeFee(tReferree, referrer[referreeAddr]);
        }

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);

        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferrerFee(tReferrer, referreeAddr);
            _takeReferreeFee(tReferree, referrer[referreeAddr]);
        }

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);

        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferrerFee(tReferrer, referrer[referreeAddr]);
            _takeReferreeFee(tReferree, referreeAddr);
        }

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // approve
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    //// Fee and Transfer Amount Calculation Helper
    // get transfer token amount and tax
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount); // 1000 * 5% = 50
        uint256 tLiquidity = calculateLiquidityFee(tAmount); // 1000 * 5% = 50
        uint256 tDev = calculateDevFee(tAmount); // 1000 * 2% = 20
        uint256 tReferrer = calculateReferrerFee(tAmount);
        uint256 tReferree = calculateReferreeFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
                tTransferAmount = tTransferAmount.sub(tLiquidity);
                tTransferAmount = tTransferAmount.sub(tDev);
                tTransferAmount = tTransferAmount.sub(tReferrer);
                tTransferAmount = tTransferAmount.sub(tReferree);
               
        return (tTransferAmount, tFee, tLiquidity, tDev, tReferrer, tReferree);
    }
    // get transfert reflection token amount and tax
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate); // 1000 * 10^53
        uint256 rFee = tFee.mul(currentRate); // 50 * 10^53
        uint256 rLiquidity = tLiquidity.mul(currentRate); // 50 * 10^53
        uint256 rDev = tDev.mul(currentRate); // 20 * 10^53
        uint256 rReferrer = tReferrer.mul(currentRate);
        uint256 rReferree = tReferree.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
                rTransferAmount = rTransferAmount.sub(rLiquidity);
                rTransferAmount = rTransferAmount.sub(rDev);
                rTransferAmount = rTransferAmount.sub(rReferrer);
                rTransferAmount = rTransferAmount.sub(rReferree);

        return (rAmount, rTransferAmount, rFee);
    }
    // referrer fee in token space (thousandth)
    function calculateReferrerFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_referrerFee).div(
            10**3
        );
    }
    // referree fee in token space (thousandth)
    function calculateReferreeFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_referreeFee).div(
            10**3
        );
    }
    // liquidity fee in token space
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    // reflection fee in token space
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    // dev & marketing fee in token space
    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(
            10**2
        );
    }
    // add liquidity fee to contract's balance  
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    // add dev/marketing fee to dev's balance  
    function _takeDevFee(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[_devAddress] = _rOwned[_devAddress].add(rDev);
        if(_isExcluded[_devAddress])
            _tOwned[_devAddress] = _tOwned[_devAddress].add(tDev);
    }
    // add referral fee to referrer's balance
    function _takeReferrerFee(uint256 tReferrer, address referrerAddr) private {
        uint256 currentRate =  _getRate();
        uint256 rReferrer = tReferrer.mul(currentRate);

        _rOwned[referrerAddr] = _rOwned[referrerAddr].add(rReferrer);
        if(_isExcluded[referrerAddr])
            _tOwned[referrerAddr] = _tOwned[referrerAddr].add(tReferrer);
    }
    // add referral fee to referee's balance
    function _takeReferreeFee(uint256 tReferree, address referreeAddr) private {
        uint256 currentRate =  _getRate();
        uint256 rReferree = tReferree.mul(currentRate);

        _rOwned[referreeAddr] = _rOwned[referreeAddr].add(rReferree);
        if(_isExcluded[referreeAddr])
            _tOwned[referreeAddr] = _tOwned[referreeAddr].add(tReferree);
    }
    // remove all fee before the transaction
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _devFee == 0) return;
       
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousDevFee = _devFee;
       
        _taxFee = 0;
        _liquidityFee = 0;
        _devFee = 0;
    }
    // restore fee after the transaction is completed if it's updated in this contract
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _devFee = _previousDevFee;
    }
    // restore referral fee after the transaction is completed if it's updated in this contract
    function restoreForReferralFee() private {
        _devFee = _previousDevFee;
        _referrerFee = _previousReferrerFee;
        _referreeFee = _previousReferreeFee;
    }
    // update the max transaction amount limit in pancakeswap
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }


    //// Reflection
    function get_rTotal() public view returns (uint256) {
        return _rTotal;
    }
    // TODO: reflection testing function?
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        (, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());

        if (!deductTransferFee) {
            return rAmount;
        } else {
            return rTransferAmount;
        }
    }
    // get current value of reflection tokens in len token space
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    // update reflection tokens space and total fee
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    // get current reflection ratio for mapping reflection tokens to len tokens
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply); //10^53
    }
    // get current supply for calculating reflection ratio
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal; //10^77
        uint256 tSupply = _tTotal; //10^25    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    // get current total reflection fee.
    // this fee should be distributed back to holders(include lquidity pool) fairly based on the amount of len tokens they are holding
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    // update reflection fee
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee < _taxFee, "New reflection fee must be less than current reflection fee");
        _taxFee = taxFee;
    }
    // // TODO: we shouldn't have this? no fee if I just want to transfer my tokens to you?
    // function deliver(uint256 tAmount) public {
    //     address sender = _msgSender();
    //     require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    //     (, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount);
    //     (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());

    //     _rOwned[sender] = _rOwned[sender].sub(rAmount);
    //     _rTotal = _rTotal.sub(rAmount);
    //     _tFeeTotal = _tFeeTotal.add(tAmount);
    // }


    //// Referral
    // Empower program ranking
    function customizeFeeForReferral(address referrerAddr) private {
        uint8 referrerLevel = getReferrerLevel(referrerAddr);
        // pass if no dev Fee
        if (_devFee == 0) return;

        _previousDevFee = _devFee; //should always be 5 which we originally set
        _previousReferrerFee = _referrerFee; //should always be 0
        _previousReferreeFee = _referreeFee; //should always be 0

        if(referrerLevel == 0) {
            _referrerFee = _referrerFeePony;
            _referreeFee = _referreeFeePony;
        } else if(referrerLevel == 1) {
            _referrerFee = _referrerFeeHorse;
            _referreeFee = _referreeFeeHorse;
        } else if(referrerLevel == 2) {
            _referrerFee = _referrerFeeFireHorse;
            _referreeFee = _referreeFeeHorse;
        } else if(referrerLevel == 3) {
            _referrerFee = _referrerFeeUnicorn;
            _referreeFee = _referreeFeeHorse;
        }
        _devFee = _devFee.sub(_referrerFee.div(10)).sub(_referreeFee.div(10));
    }
    // return current referrer level for calculating referel fee
    function getReferrerLevel(address account) public view returns(uint8) {
        uint256 currentTotalReferredToken = totalReferredToken[account];
        uint8 level = 0;

        if(currentTotalReferredToken >= _level3MinReferredToken) {
            level = 3;
        } else if(currentTotalReferredToken >= _level2MinReferredToken) {
            level = 2;
        } else if(currentTotalReferredToken >= _level1MinReferredToken) {
            level = 1;
        }

        return level;
    }
    // set referrer
    function setReferrer(address account) public {
        require(referrer[_msgSender()] == address(0), "Referrer existing");
        referrer[_msgSender()] = account;
    }
    // get current acount's referrer
    function getReferrer(address account) public view returns(address) {
        return referrer[account];
    }
    // get total hahataxi tokens from referral bonus
    function getTotalReferredToken(address account) public view returns(uint256) {
        return totalReferredToken[account];
    }
    // update dev pct (community driven)
    //  will reduce referral bonus if we update dev fee
    function setdevFeePercent(uint256 devFee) external onlyOwner() {
        require(devFee < _devFee, "New dev fee must be less than current dev fee");
        // update referral fee
        _referrerFeePony = _referrerFeePony.mul(devFee.div(_devFee));
        _referrerFeeHorse = _referrerFeeHorse.mul(devFee.div(_devFee));
        _referrerFeeFireHorse = _referrerFeeFireHorse.mul(devFee.div(_devFee));
        _referrerFeeUnicorn = _referrerFeeUnicorn.mul(devFee.div(_devFee));
        _referreeFeePony = _referreeFeePony.mul(devFee.div(_devFee));
        _referreeFeeHorse = _referreeFeeHorse.mul(devFee.div(_devFee));
        // update dev fee
        _devFee = devFee;
        emit DevAndReferralFee(_devFee, _referrerFeePony, _referrerFeeHorse, _referrerFeeFireHorse, _referrerFeeUnicorn, _referreeFeePony, _referreeFeeHorse);
    }


    //// Liquidity
    // to recieve BNB from pancakeswap when swapping
    receive() external payable {}
    // lock the swap and liquify to prevent circular liquidity event
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    // update liquidity pct (community driven)
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee < _liquidityFee, "New liquidity fee must be less than current liquidity fee");
        _liquidityFee = liquidityFee;
    }
    // enable swap and liquify
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    // main function of swap and liquify
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap half tokens for ETH and add to address(thit)
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // amount of ETH we just swap into this address
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
       
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    // swap half of hahataxi tokens to BNB
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
    // add BNB and hahataxi to liquidity pool
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uint256 amountToken;
        uint256 amountETH;
        uint256 liquidity;
        (amountToken, amountETH, liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), //TODO: send lp tokens to this contract
            block.timestamp
        );

        // save current liquidity amount
        _lockedCommunityLiquidity.push(liquidity);
        _releaseTime.push(block.timestamp + 60 * 10);  //TODO
        emit AddLiquidity(amountToken, amountETH, liquidity);
    }
    // remove BNB and hahataxi from liquidity pool with time lock
    // TODO: onlyOwner or onlyOwner()
    function removeLiquidity(uint256 liquidity) external onlyOwner() {
        require(liquidity <= _unlockedTotalCommunityLiquidity, "liquidity should be less than unlocked liquidity");
        require(block.timestamp > minReleaseTime, "release time is before current time");

        uint256 amountToken;
        uint256 amountETH;
        (amountToken, amountETH) = uniswapV2Router.removeLiquidityETH(
            address(this),
            liquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit RemoveLiquidity(amountToken, amountETH);
    }
    // update unlocked liquidity amount
    function releaseLiquidity() external onlyOwner() {
        uint256 newStart = 0;
        uint256 swap = 0;
        // update unlocked liquidity
        for (uint256 i = 0; i < _lockedCommunityLiquidity.length; i++) {
            if (block.timestamp >= _releaseTime[i]) {
                _unlockedTotalCommunityLiquidity += _lockedCommunityLiquidity[i];
            } else {
                if (i == 0) break;
                if (newStart == 0) newStart = i;
                _lockedCommunityLiquidity[swap] = _lockedCommunityLiquidity[i];
                _releaseTime[swap] = _lockedCommunityLiquidity[i];
                swap++;
            }
        }
        // update length
        for (uint256 i = 0; i < newStart; i++) {
            _lockedCommunityLiquidity.pop();
            _releaseTime.pop();
        }
    }
    // get unlocked community liquidity
    function unlockedTotalCommunityLiquidity() public view returns (uint256) {
        return _unlockedTotalCommunityLiquidity;
    }
    // testing
    function getContractTokenBalance() public view returns (uint256){
        return balanceOf(address(this));
    }
    function getContractBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }


    //// Account exclusion    
    // check whether account is excluded from reward
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    // exclude account from reward
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    // inlculde account from reward
    // TODO: why do we need a list of all excluded account if we have mapping of excluded accounts already.
    //  very inefficient way to include it again
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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
    // check whether account is excluded from fee
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    // exclude acount from fee
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    // include account from fee
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

}