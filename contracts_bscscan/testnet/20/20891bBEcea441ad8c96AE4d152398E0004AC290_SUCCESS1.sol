/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
 
/*
    #Lottery features:
        5% fee auto add to the liquidity pool
        2% fee auto distribute to all holders
        2% marketing wallet
        7% distributed for lottery - daily(15%), weekly(35%), monthly(50%)
*/
 
 
pragma solidity ^0.6.12;
interface IBEP20 {
 
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
    function _msgSender() internal view virtual returns (address payable) {
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
    constructor () internal {
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
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
 
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
 
// pragma solidity >=0.5.0;
 
interface IPancakeV2Factory {
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
 
interface IPancakeV2Pair {
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
 
interface IPancakeV2Router01 {
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
 
interface IPancakeV2Router02 is IPancakeV2Router01 {
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
 
interface CakeSyrupPool {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
}
 
contract SUCCESS1 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
 
    mapping (address => bool) private _isExcludedFromFee;
 
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
 
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000 * 10**9;
    uint256 private _tTotalToBurn = 0;
 
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tMarketingTotal;
 
    string private _name = "SUSS1";
    string private _symbol = "SUSS1";
    uint8 private _decimals = 9;
 
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
 
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;
 
    uint256 public _marketingFee = 2;
    uint256 public _lotteryFee = 7; //daily(15%), weekly(35%), monthly(50%)
 
    uint256 public dailyGatherAwardInTokenTier1 = 0;
    uint256 public dailyGatherAwardInTokenTier2 = 0;
    uint256 public dailyGatherAwardInTokenTier3 = 0;
 
    uint256 public _currentTier1LotteryAwardBNB = 0; //Monthly
    uint256 public _currentTier2LotteryAwardBNB = 0; //Weekly
    uint256 public _currentTier3LotteryAwardBNB = 0; //Daily
 
    uint256 public _marketingNLotteryFee = _marketingFee + _lotteryFee;
    uint256 private _previousMarketingNLotteryFee = _marketingNLotteryFee;
 
    address public maketingWallet;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
 
    //Main
    //uint256 public timeHour = 60 * 60;
    //uint256 public timeDay = 24 * 60 * 60;
    //uint256 public timeWeek = 7 * 24 * 60 * 60;
    //uint256 public timeMonth = 304* 24 * 60 * 6;
 
    //Test
    uint256 public timeHour = 60 * 60;  // 1h
    uint256 public timeDay = 20 * 60;   // 20min
    uint256 public timeWeek = 45 * 60;  // 45min
    uint256 public timeMonth = 60 * 60; // 1h
 
 
    uint256 public totalWeeklyBurnToken = 0;
    uint256 public lastTimeWeeklyBurn = 0;
 
    bool public lotteryStarted = false;
    
    
    uint256 public tier1Threshold = 10000000000 * 10**9;
    uint256 public tier2Threshold = 4000000000 * 10**9;
    uint256 public tier3Threshold = 1000000000 * 10**9;
    address[] public tier1Cadidates;
    address[] public tier2Cadidates;
    address[] public tier3Cadidates;
    mapping (address => uint256) public tier1TimeStamp;
    mapping (address => uint256) public tier2TimeStamp;
    mapping (address => uint256) public tier3TimeStamp;
 
    //Main
    //uint256 public tier1QualifiedTime = 336; // 14 days
    //uint256 public tier2QualifiedTime = 144; // 6 days
    //uint256 public tier3QualifiedTime = 48; // 2 days
 
    // Test
    uint256 public tier1QualifiedTime = 1; // 60 min
    uint256 public tier2QualifiedTime = 1; // 20 min
    uint256 public tier3QualifiedTime = 1; // 5 min
 
 
    address public lastTier1Winner;
    address public lastTier2Winner;
    address public lastTier3Winner;
 
    uint256 public lastTier1Award;
    uint256 public lastTier2Award;
    uint256 public lastTier3Award;
 
    uint256 public checkpointTier1;
    uint256 public checkpointTier2;
    uint256 public checkpointTier3;
 
    uint256 public lastTimeHavestCake = 0;
 
    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;
 
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
 
    uint256 public _maxTxAmount = 10000000000000 * 10**9;
    uint256 public thresholdForAddingLiquidity = 100000000000 * 10**9;
    uint256 public currentTokenForAddingLiquidity = 0;
 
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
 
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
 
    constructor () public {
        //IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwap: Router v2
        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // PancakeSwap: Router Testnet
 
         // Create a pancake pair for this new token
        pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
 
        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router;
 
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        //_isExcludedFromFee[address(pancakeV2Router)] = true;
        //_isExcludedFromFee[address(pancakeV2Pair)] = true;
 
        maketingWallet = owner();
        _isExcludedFromFee[maketingWallet] = true;
 
        _tTotalToBurn = _tTotal.div(100).mul(35);
        _rOwned[owner()] = _rTotal.div(100).mul(65);
        _rOwned[address(this)] = _rTotal.div(100).mul(35);
 
        updateTierForRecipient(owner());
        updateTierForRecipient(address(this));
 
        emit Transfer(address(0), owner(), _tTotal.div(100).mul(60));
        emit Transfer(address(0), address(this), _tTotalToBurn);
 
        checkpointTier1 = block.timestamp.div(timeMonth);
        checkpointTier2 = block.timestamp.div(timeWeek);
        checkpointTier3 = block.timestamp.div(timeDay);
 
        lastTimeHavestCake = block.timestamp.div(timeWeek);
 
        excludeFromReward(burnWallet);
        excludeFromReward(pancakeV2Pair);
    }
 
    function setNewPancakeRouterAddress(address newRouter) public onlyOwner() {
        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(newRouter);
         // Create a pancake pair for this new token
        pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
 
        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router;
    }
 
    function name() public view returns (string memory) {
        return _name;
    }
 
    function symbol() public view returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
 
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
 
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
 
    function totalMarketingFee() public view returns (uint256) {
        return _tMarketingTotal;
    }
 
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
 
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
 
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
 
    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
 
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
 
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketingNLotteryFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        updateTierForSender(sender);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        updateTierForRecipient(recipient); 
        _takeLiquidity(tLiquidity);
        _takeMarketingNLotteryFee(tMarketingNLotteryFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
 
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
 
    function setFeePercent(uint256 taxFee,uint256 liquidityFee,uint256 marketingFee) external onlyOwner() {
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
        _marketingNLotteryFee = _marketingFee + _liquidityFee;
    }
 
 
 
    function setLotteryFeePercent(uint256 lotteryFee) external onlyOwner() {
        _lotteryFee = lotteryFee;
        _marketingNLotteryFee = _marketingFee + _liquidityFee;
    }
 
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
 
    function setmaketingWallet(address _maketingWallet) public onlyOwner {
        maketingWallet = _maketingWallet;
        _isExcludedFromFee[maketingWallet] = true;
     }
 
    function setLotteryStarted(bool start) public onlyOwner {
        lotteryStarted = start;
    }
 
     //to recieve ETH from pancakeV2Router when swaping
    receive() external payable {}
 
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketingNLotteryFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketingNLotteryFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketingNLotteryFee);
    }
 
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketingNLotteryFee = calMarketingNLotteryFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketingNLotteryFee);
        return (tTransferAmount, tFee, tLiquidity, tMarketingNLotteryFee);
    }
 
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketingNLotteryFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketingNLotteryFee = tMarketingNLotteryFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketingNLotteryFee);
        return (rAmount, rTransferAmount, rFee);
    }
 
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
 
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
 
    function _takeLiquidity(uint256 tLiquidity) private {
        if(tLiquidity > 0){
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
 
            currentTokenForAddingLiquidity = currentTokenForAddingLiquidity.add(tLiquidity);
            emit Transfer(msg.sender, address(this), tLiquidity);
        }
    }
 
    function _takeMarketingNLotteryFee(uint256 tMarketingNLotteryFee) private {
        if(tMarketingNLotteryFee > 0){ // Fee is zero when transferring from excluded wallet
            uint256 currentRate =  _getRate();
 
            uint256 tMarketing = tMarketingNLotteryFee.mul(_marketingFee).div(_marketingNLotteryFee);
            uint256 tLottery = tMarketingNLotteryFee.mul(_lotteryFee).div(_marketingNLotteryFee);
 
            //MarketingFee
            _rOwned[maketingWallet] = _rOwned[maketingWallet].add(tMarketing.mul(currentRate));
            if(_isExcluded[maketingWallet]){
                _tOwned[maketingWallet] = _tOwned[maketingWallet].add(tMarketing);
            }
            emit Transfer(msg.sender, address(maketingWallet), tMarketing);
 
            //LotteryFee is kept in token-contract
            _rOwned[address(this)] = _rOwned[address(this)].add(tLottery.mul(currentRate));
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLottery);
            emit Transfer(msg.sender, address(this), tLottery);
 
            dailyGatherAwardInTokenTier3 = dailyGatherAwardInTokenTier3.add(tLottery.mul(15).div(100));
            dailyGatherAwardInTokenTier2 = dailyGatherAwardInTokenTier2.add(tLottery.mul(35).div(100));
            dailyGatherAwardInTokenTier1 = dailyGatherAwardInTokenTier1.add(tLottery.mul(50).div(100));
        }
 
    }
 
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
 
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
 
    function calMarketingNLotteryFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingNLotteryFee).div(
            10**2
        );
    }
 
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _marketingNLotteryFee == 0) return;
 
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingNLotteryFee = _marketingNLotteryFee;
 
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingNLotteryFee = 0;
    }
 
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingNLotteryFee = _previousMarketingNLotteryFee;
    }
 
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner() && from != address(this) && to != address(this))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
 
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));
 
        uint256 currentTokenForLiquidity = currentTokenForAddingLiquidity;
 
        if(currentTokenForLiquidity >= contractTokenBalance)
        {
            currentTokenForLiquidity = contractTokenBalance;
        }
 
        if(currentTokenForLiquidity >= _maxTxAmount)
        {
            currentTokenForLiquidity = _maxTxAmount;
        }
 
        bool overMinTokenBalance = currentTokenForLiquidity >= thresholdForAddingLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeV2Pair &&
            swapAndLiquifyEnabled
        ) {
            currentTokenForLiquidity = thresholdForAddingLiquidity;
            //add liquidity
            swapAndLiquify(currentTokenForLiquidity);
            //Calculate remaining Token for liquidity
            currentTokenForAddingLiquidity = currentTokenForAddingLiquidity.sub(currentTokenForLiquidity);
        }
 
        if(!inSwapAndLiquify ){
            if (lotteryStarted && block.timestamp.div(timeDay) > checkpointTier3  && dailyGatherAwardInTokenTier3 > 0 && from != pancakeV2Pair){
                //Convert award token daily, when lottery tier3 happen
                inSwapAndLiquify = true;
                uint256 totalDailyAwardToken = dailyGatherAwardInTokenTier3.add(dailyGatherAwardInTokenTier2).add(dailyGatherAwardInTokenTier1);
                uint256 initialBalance = address(this).balance;
                swapTokensForEth(totalDailyAwardToken);
                uint256 totalAwardBNB = address(this).balance.sub(initialBalance);

 
                _currentTier1LotteryAwardBNB = _currentTier1LotteryAwardBNB.add(totalAwardBNB.mul(dailyGatherAwardInTokenTier1).div(totalDailyAwardToken));
                _currentTier2LotteryAwardBNB = _currentTier2LotteryAwardBNB.add(totalAwardBNB.mul(dailyGatherAwardInTokenTier2).div(totalDailyAwardToken));
                _currentTier3LotteryAwardBNB = _currentTier3LotteryAwardBNB.add(totalAwardBNB.mul(dailyGatherAwardInTokenTier3).div(totalDailyAwardToken));
                dailyGatherAwardInTokenTier1 = 0;
                dailyGatherAwardInTokenTier2 = 0;
                dailyGatherAwardInTokenTier3 = 0;
 
                inSwapAndLiquify = false;
 
                loteryDraw(3);
            }else if (lotteryStarted && block.timestamp.div(timeWeek) > checkpointTier2  && _currentTier2LotteryAwardBNB > 0){
                loteryDraw(2);
            }else if (lotteryStarted && block.timestamp.div(timeMonth) > checkpointTier1 && _currentTier1LotteryAwardBNB > 0){
                loteryDraw(1);
             }else if(lotteryStarted && block.timestamp.div(timeWeek) > lastTimeHavestCake){
                havestCakeAndBuyBack();
            }
        }
 
        checkWeeklyBurning();
 
 
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
 
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
 
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
 
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
 
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
 
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
 
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
 
        // add liquidity to pancake
        addLiquidity(otherHalf, newBalance);
 
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );
        
    }
    
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        if ( tokenAmount > 0 ) {
            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(pancakeV2Router), tokenAmount);
    
            // add the liquidity
            pancakeV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp.add(300)
            );
        }
    }
 
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
 
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
 
        if(!takeFee)
            restoreAllFee();
    }
 
    function random(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                    block.number +
                    salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }
 
    function sendLotteryAward(address winner, uint256 tokenAmount, uint tier) private{
        investIntoCakePool(tokenAmount.mul(20).div(100));
        (payable(winner)).transfer(tokenAmount.mul(80).div(100));
        if(tier == 1){
            lastTier1Award = tokenAmount.mul(80).div(100);
        }else if(tier == 2){
            lastTier2Award = tokenAmount.mul(80).div(100);
        }else if(tier == 3){
            lastTier3Award = tokenAmount.mul(80).div(100);
        }
    }
 
    function loteryDraw(uint tier) private lockTheSwap{
        uint256 current = block.timestamp.div(timeHour);
        bool found = false;
        uint tryNo = 0;
 
        if(tier == 1){
            while(found == false){
                tryNo = tryNo + 1;
                if(tryNo >= 10) break;
                uint256 winnerIndex = random(0, tier1Cadidates.length - 1, current + tryNo);
                if (
                    tier1Cadidates[winnerIndex].isContract() != true &&
                    tier1Cadidates[winnerIndex] !=  address(this) &&
                    tier1Cadidates[winnerIndex] !=  burnWallet &&
                    current.sub(tier1TimeStamp[tier1Cadidates[winnerIndex]]) >= tier1QualifiedTime){
                    lastTier1Winner = tier1Cadidates[winnerIndex];
                    sendLotteryAward(lastTier1Winner, _currentTier1LotteryAwardBNB, 1);
                    _currentTier1LotteryAwardBNB = 0;
                    found = true;
                    checkpointTier1 = block.timestamp.div(timeMonth);
                }
            }
        }else if(tier == 2){
            while(found = false){
                tryNo = tryNo + 1;
                if(tryNo >= 10) break;
                uint256 winnerIndex = random(0, tier2Cadidates.length - 1, current + tryNo);
                if (
                    tier2Cadidates[winnerIndex].isContract() != true &&
                    tier2Cadidates[winnerIndex] !=  address(this) &&
                    tier2Cadidates[winnerIndex] !=  burnWallet &&
                    current.sub(tier2TimeStamp[tier2Cadidates[winnerIndex]]) >= tier2QualifiedTime){
                    lastTier2Winner = tier2Cadidates[winnerIndex];
                    sendLotteryAward(lastTier2Winner, _currentTier2LotteryAwardBNB, 2);
                    _currentTier2LotteryAwardBNB = 0;
                    found = true;
                    checkpointTier2 = block.timestamp.div(timeWeek);
                }
            }
        }else if(tier == 3){
            while(found == false){
                tryNo = tryNo + 1;
                if(tryNo >= 10) break;
                uint256 winnerIndex = random(0, tier3Cadidates.length - 1, current + tryNo);
                if (
                    tier3Cadidates[winnerIndex].isContract() != true &&
                    tier3Cadidates[winnerIndex] !=  address(this) &&
                    tier3Cadidates[winnerIndex] !=  burnWallet &&
                    current.sub(tier3TimeStamp[tier3Cadidates[winnerIndex]]) >= tier3QualifiedTime){
                    lastTier3Winner = tier3Cadidates[winnerIndex];
                    sendLotteryAward(lastTier3Winner, _currentTier3LotteryAwardBNB, 3);
                    _currentTier3LotteryAwardBNB = 0;
                    found = true;
                    checkpointTier3 = block.timestamp.div(timeDay);
                }
            }
        }
    }
 
    function updateTierForSender(address sender) private{
        uint256 balance = balanceOf(sender);
        if(balance >= tier1Threshold){
            // Previous  > Tier1, don't need to do anything
        }else if (balance >= tier2Threshold){
            //If it was tier1, remove tier1
            if(tier1TimeStamp[sender] != 0){
                tier1TimeStamp[sender] = 0;
                for (uint256 i = 0; i < tier1Cadidates.length; i++) {
                    if (tier1Cadidates[i] == sender) {
                        tier1Cadidates[i] = tier1Cadidates[tier1Cadidates.length - 1];
                        tier1Cadidates.pop();
                        break;
                    }
                }
            }
        }else if (balance >= tier3Threshold){
            //If it was tier1, remove tier1
            if(tier1TimeStamp[sender] != 0){
                tier1TimeStamp[sender] = 0;
                for (uint256 i = 0; i < tier1Cadidates.length; i++) {
                    if (tier1Cadidates[i] == sender) {
                        tier1Cadidates[i] = tier1Cadidates[tier1Cadidates.length - 1];
                        tier1Cadidates.pop();
                        break;
                    }
                }
            }
            //If it was tier2, remove tier2
            if(tier2TimeStamp[sender] != 0){
                tier2TimeStamp[sender] = 0;
                for (uint256 i = 0; i < tier2Cadidates.length; i++) {
                    if (tier2Cadidates[i] == sender) {
                        tier2Cadidates[i] = tier2Cadidates[tier2Cadidates.length - 1];
                        tier2Cadidates.pop();
                        break;
                    }
                }
            }
        }else {
            //If it was tier1, remove tier1
            if(tier1TimeStamp[sender] != 0){
                tier1TimeStamp[sender] = 0;
                for (uint256 i = 0; i < tier1Cadidates.length; i++) {
                    if (tier1Cadidates[i] == sender) {
                        tier1Cadidates[i] = tier1Cadidates[tier1Cadidates.length - 1];
                        tier1Cadidates.pop();
                        break;
                    }
                }
            }
            //If it was tier2, remove tier2
            if(tier2TimeStamp[sender] != 0){
                tier2TimeStamp[sender] = 0;
                for (uint256 i = 0; i < tier2Cadidates.length; i++) {
                    if (tier2Cadidates[i] == sender) {
                        tier2Cadidates[i] = tier2Cadidates[tier2Cadidates.length - 1];
                        tier2Cadidates.pop();
                        break;
                    }
                }
            }
            //If it was tier3, remove tier3
            if(tier3TimeStamp[sender] != 0){
                tier3TimeStamp[sender] = 0;
                for (uint256 i = 0; i < tier3Cadidates.length; i++) {
                    if (tier3Cadidates[i] == sender) {
                        tier3Cadidates[i] = tier3Cadidates[tier3Cadidates.length - 1];
                        tier3Cadidates.pop();
                        break;
                    }
                }
            }
        }
    }
 
    // Backup function to withdraw any other tokens which were sent to the contract.
    // Does not allow owner to withdraw CAKE or this token in order to prevent rogue activity.
    function backupWithdrawExtraTokens(address _token) external onlyOwner {
        require(_token != address(this), "Owner cannot withdraw this token");
        require(_token != address(cakeToken), "Owner cannot withdraw this token");
        uint256 _tokenBalance = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(msg.sender, _tokenBalance);
    }
 
    function updateTierForRecipient(address recipient) private {
        uint256 balance = balanceOf(recipient);
        if(balance < tier3Threshold){
            // Previous < Tier3, don't need to do anything
        }else if (balance < tier2Threshold){
            //If it wasnt tier3, add tier3
            if(tier3TimeStamp[recipient] == 0){
                tier3TimeStamp[recipient] = block.timestamp.div(timeHour);
                tier3Cadidates.push(recipient);
            }
        }else if (balance < tier1Threshold){
            //If it wasnt tier3, add tier3
            if(tier3TimeStamp[recipient] == 0){
                tier3TimeStamp[recipient] = block.timestamp.div(timeHour);
                tier3Cadidates.push(recipient);
            }
            //If it wasnt tier2, add tier2
            if(tier2TimeStamp[recipient] == 0){
                tier2TimeStamp[recipient] = block.timestamp.div(timeHour);
                tier2Cadidates.push(recipient);
            }
        }else {
            //If it wasnt tier3, add tier3
            if(tier3TimeStamp[recipient] == 0){
                tier3TimeStamp[recipient] = block.timestamp.div(timeHour);
                tier3Cadidates.push(recipient);
            }
            //If it wasnt tier2, add tier2
            if(tier2TimeStamp[recipient] == 0){
                tier2TimeStamp[recipient] = block.timestamp.div(timeHour);
                tier2Cadidates.push(recipient);
            }
            //If it wasnt tier1, add tier1
            if(tier1TimeStamp[recipient] == 0){
                tier1TimeStamp[recipient] = block.timestamp.div(timeHour);
                tier1Cadidates.push(recipient);
            }
        }
    }
 
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketingNLotteryFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        updateTierForSender(sender);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        updateTierForRecipient(recipient);
        _takeLiquidity(tLiquidity);
        _takeMarketingNLotteryFee(tMarketingNLotteryFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketingNLotteryFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        updateTierForSender(sender);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        updateTierForRecipient(recipient);
        _takeLiquidity(tLiquidity);
        _takeMarketingNLotteryFee(tMarketingNLotteryFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketingNLotteryFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        updateTierForSender(sender);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        updateTierForRecipient(recipient);
        _takeLiquidity(tLiquidity);        
        _takeMarketingNLotteryFee(tMarketingNLotteryFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function checkWeeklyBurning() private {
        if(totalWeeklyBurnToken < _tTotalToBurn){
            if((block.timestamp.div(timeWeek)) > lastTimeWeeklyBurn) {
                uint256 burn5Percent  =  _tTotal.mul(5).div(100);
                uint256 currentBalanceContract = balanceOf(address(this));
                if(burn5Percent > currentBalanceContract){
                    burn5Percent = currentBalanceContract;
                }
                if(burn5Percent.add(totalWeeklyBurnToken) > _tTotalToBurn){
                    burn5Percent = _tTotalToBurn - totalWeeklyBurnToken;
                }
                _tokenTransfer(address(this), burnWallet, burn5Percent, false);
                totalWeeklyBurnToken = totalWeeklyBurnToken.add(burn5Percent);
                lastTimeWeeklyBurn = block.timestamp.div(timeWeek);
            }
        }
    }
 
    /************* REINVEST CAKE TO BUYBACK **************/
    //Test net
    CakeSyrupPool public poolSyrupCake = CakeSyrupPool(0xD7475f8370E9db18E676e7d72666411761D607CD); //(0x94E7988417e1766eB26a04eC006368fC541E70AA);
    IBEP20 public cakeToken = IBEP20(0x1C09A135CC4705e6B6f3Eb79522C55FfC28b108F);
 
    //Main net
    //CakeSyrupPool public poolSyrupCake = CakeSyrupPool(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    //IBEP20 public cakeToken = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
 
    function swapCakeForEth(uint256 tokenAmount) private {
        if ( tokenAmount > 0 ) {
            // generate the pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(cakeToken);
            path[1] = pancakeV2Router.WETH();
    
            cakeToken.approve(address(pancakeV2Router), tokenAmount);
    
            // make the swap
            pancakeV2Router.swapExactTokensForETH(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp.add(600)
            );
        }
    }
 
    function swapETHForTokensAndBurn(uint256 amount) private {
        if ( amount > 0) {
            // generate the pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = pancakeV2Router.WETH();
            path[1] = address(this);
            
            // make the swap
            pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0, // accept any amount of Tokens
                path,
                burnWallet,
                block.timestamp.add(600)
            );
        }
    }
 
    function swapETHForCake(uint256 amount) private {
        if ( amount > 0 ) {
            // generate the pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = pancakeV2Router.WETH();
            path[1] = address(cakeToken);

            
            // make the swap
            pancakeV2Router.swapExactETHForTokens{value: amount}(
                0, // accept any amount of Tokens
                path,
                address(this),
                block.timestamp.add(600)
            );
        }
    }
 
    bool private investedCake = false;
    function investIntoCakePool(uint256 amount) private{
        if ( amount > 0 ) {
            swapETHForCake(amount);
            cakeToken.approve(address(poolSyrupCake), cakeToken.balanceOf(address(this)));
            poolSyrupCake.enterStaking(cakeToken.balanceOf(address(this)));
            investedCake = true;
        }
    }
 
    function havestCakeAndBuyBack() public lockTheSwap{
        if(investedCake){
             //Withdraw CAKE
             uint256 _cakeStakingBal;
             (_cakeStakingBal, ) = poolSyrupCake.userInfo(0, address(this));
            poolSyrupCake.leaveStaking(0); // functia retrage rewardurile
            uint256 initialBalance = address(this).balance; // trece
            swapCakeForEth(cakeToken.balanceOf(address(this)));
            uint256 buybackBalance = address(this).balance.sub(initialBalance); //trece
            swapETHForTokensAndBurn(buybackBalance);  //trece
            lastTimeHavestCake = block.timestamp.div(timeWeek); //trece
        } 
    }
 
    // Withdraws everything from CAKE pool, swaps to token and burns it
    function liquifyCakeAndBurn(address[] memory _pancakePath) external onlyOwner {
        // Withdraw CAKE
        uint256 _cakeStakingBal;
        (_cakeStakingBal, ) = poolSyrupCake.userInfo(0, address(this));
        poolSyrupCake.leaveStaking(_cakeStakingBal);
 
        // Get balances
        uint256 _tokenBefore = balanceOf(address(this));
        uint256 _cakeBalance = cakeToken.balanceOf(address(this));
 
        // SWAP CAKE to TOKEN
        cakeToken.approve(address(pancakeV2Router), 0);
        cakeToken.approve(address(pancakeV2Router), _cakeBalance);
        pancakeV2Router.swapExactTokensForTokens(
            _cakeBalance,
            0,
            _pancakePath,
            address(this),
            block.timestamp.add(3600)
        );
 
        // BURN TOKEN
        uint256 _tokenAfter = balanceOf(address(this));
        uint256 _burnAmount = _tokenAfter.sub(_tokenBefore);
        if(_burnAmount > 0) {
            _tokenTransfer(address(this), burnWallet, _burnAmount, false);
        }
    }
 
    function setTier1Threshold(uint256 t1,uint256 t2, uint256 t3) public onlyOwner {
        tier1Threshold = t1 * 10**9;
        tier2Threshold = t2 * 10**9;
        tier3Threshold = t3 * 10**9;
    }
 
    function setTierQualifiedTime(uint256 t1,uint256 t2, uint256 t3) public onlyOwner {
        tier1QualifiedTime = t1;
        tier2QualifiedTime = t2;
        tier3QualifiedTime = t3;
    }
}