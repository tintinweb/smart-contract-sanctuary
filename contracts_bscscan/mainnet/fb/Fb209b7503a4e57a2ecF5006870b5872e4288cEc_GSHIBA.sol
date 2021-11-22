/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

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
    function _msgSender() internal view virtual returns (address) {
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
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    //Locks the contract for owner for the amount of time provided
    function lockShortTime(uint256 time) public virtual onlyOwner {
        require(time < 7 * 24 *60 * 60 , "The contract locking time shall be less than 7 days");
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function lockLongTime(uint256 time) public virtual onlyOwner {
        require(time >= 7 * 24 *60 * 60 , "The contract locking time shall be greater than 7 days");
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
        _previousOwner = address(0);
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
contract GSHIBA is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public _isExcludedFromAntiWhale;
    mapping (address => bool) private _AddressExists;
    address[] private _addressList;
    address[] private _excluded;

    address payable private _ownerWallet;

    address payable private _txgoldWallet;
    address payable private _marketingWallet;
    address private _lottoPotAddress;
    address private _lottoWalletAddress;
    uint256 public _lastLottoWinnerAmount;
    uint256 public _totalLottoPrize;
    uint public _lottoDrawCount = 0;

    uint256 private _minLottoBalance = 1000000000 * 10**9;


    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    string private constant _name = "GameShiba";
    string private constant _symbol = "GSHIBA";
    uint8 private constant _decimals = 9;

    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 8;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _lottoFee = 0;
    uint256 private _previousLottoFee = _lottoFee;

    uint256 public _txgoldFee = 0;
    uint256 private _previousTxgoldFee = _txgoldFee;

    uint256 public _marketingFee = 0;
    uint256 private _previousMarketingFee = _marketingFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwapAndLiquidity;
    bool private inLotteryDraw;
    bool public swapAndLiquidityEnabled = true;
    bool public lottoEnabled = true;
    bool public _shouldSwapToBNB;

    uint256 public _maxTxAmount = 100000 * 10**12 * 10**9;
    uint256 private constant numTokensSellToAddToLiquidity = 200 * 10**12 * 10**9;
    uint256 public lotteryThreshold = 10 * 10**12 * 10**9;
    // anti whale
    bool    public _isAntiWhaleEnabled = true;
    uint256 public _antiWhaleThreshold = 1 * 10**15 * 10**9;

    struct TData {
        uint256 tAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tLotto;
        uint256 tTxgold;
        uint256 tMarketing;
        uint256 currentRate;
    }

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquidityEnabledUpdated(bool enabled);
    event SwapAndLiquidity(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event DrawLotto(uint256 amount, uint _lottoDrawCount);

    modifier lockTheSwap {
        inSwapAndLiquidity = true;
        _;
        inSwapAndLiquidity = false;
    }

    modifier lockTheLottery {
        inLotteryDraw = true;
        _;
        inLotteryDraw = false;
    }

    constructor () {
        _rOwned[owner()] = _rTotal;
        addAddress(owner());
        _lottoPotAddress = address(1);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _txgoldWallet = payable(owner());
           _marketingWallet = payable(owner());

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_lottoPotAddress] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromAntiWhale[owner()] = true;
        _isExcludedFromAntiWhale[_lottoPotAddress] = true;
        _isExcludedFromAntiWhale[address(this)] = true;
        _isExcludedFromAntiWhale[address(uniswapV2Router)] = true;
        _isExcludedFromAntiWhale[uniswapV2Pair] = true;

        _ownerWallet = payable(owner());
        _txgoldWallet = payable(owner());
        _marketingWallet = payable(owner());

        emit Transfer(address(0), owner(), _tTotal);
    }
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function minLottoBalance() public view returns (uint256) {
        return _minLottoBalance;
    }
    function currentLottoPool() public view returns (uint256) {
        return balanceOf(_lottoPotAddress);
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
    function isIncludeFromLotto(address account) public view returns (bool) {
        return _AddressExists[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is not excluded");
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto, uint256 tTxgold, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity, sender);
        _takeLotto(tLotto, sender);
        _takeTxgold(tTxgold, sender);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setUniswapRouter(address r) external onlyOwner {
        require(r != address(0), "GSHIBA: setUniswapRouter is a zero address");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(r);
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        require(p != address(0), "GSHIBA: setUniswapPair is a zero address");
        uniswapV2Pair = p;
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLottoFeePercent(uint256 lottoFee) external onlyOwner() {
        _lottoFee = lottoFee;
    }

    function setTxgoldFeePercent(uint256 txgoldFee) external onlyOwner() {
        _txgoldFee = txgoldFee;
    }
    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }

    function setshouldSwapToBNB(bool enabled) public onlyOwner() {
        _shouldSwapToBNB = enabled;
    }
    function setLottoEnabled(bool enabled) public onlyOwner() {
        lottoEnabled = enabled;
    }
    function setOwnerWalletAddress(address payable ownerWallet) public onlyOwner() {
        require(ownerWallet != address(0), "GSHIBA: setOwnerWalletAddress is a zero address");
        _ownerWallet = ownerWallet;
        _isExcludedFromFee[_ownerWallet] = true;
        _isExcludedFromAntiWhale[_ownerWallet] = true;
    }
    function setTxgoldAddress(address payable txgold) public onlyOwner() {
        require(txgold != address(0), "GSHIBA: setTxgoldAddress is a zero address");
        _txgoldWallet = txgold;
    }
    function setMarketingAddress(address payable marketing) public onlyOwner() {
        require(marketing != address(0), "GSHIBA: setMarketingAddress is a zero address");
        _marketingWallet = marketing;
    }
    function setMinLottoBalance(uint256 minBalance) public onlyOwner() {
        _minLottoBalance = minBalance;
    }
    function setLotteryThresHold(uint256 threshold) public onlyOwner() {
        lotteryThreshold = threshold;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    function setSwapAndLiquidityEnabled(bool _enabled) public onlyOwner {
        swapAndLiquidityEnabled = _enabled;
        emit SwapAndLiquidityEnabledUpdated(_enabled);
    }
    function setAntiWhaleEnabled(bool e) external onlyOwner {
        _isAntiWhaleEnabled = e;
    }
    function setAntiWhaleThreshold(uint256 amount) external onlyOwner {
        _antiWhaleThreshold = amount;
    }
    function setExcludedFromAntiWhale(address account, bool e) external onlyOwner {
        _isExcludedFromAntiWhale[account] = e;
    }

    function withDrawWBNB() public {
        require(_ownerWallet == _msgSender(), "GSHIBA: withDrawWBNB No permission");
        IBEP20 wbnb = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        if (wbnb.balanceOf(address(this)) > 0) {
            wbnb.transfer(_msgSender(), wbnb.balanceOf(address(this)));
        }
    }

    function withDrawUSDT() public {
        require(_ownerWallet == _msgSender(), "GSHIBA: withDrawUSDT No permission");
        IBEP20 usdt = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        if (usdt.balanceOf(address(this)) > 0) {
            usdt.transfer(_msgSender(), usdt.balanceOf(address(this)));
        }
    }

    function withDrawBUSD() public {
        require(_ownerWallet == _msgSender(), "GSHIBA: withDrawBUSD No permission");
        IBEP20 busd = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        if (busd.balanceOf(address(this)) > 0) {
            busd.transfer(_msgSender(), busd.balanceOf(address(this)));
        }
    }

    function withDraw() public {
        require(_ownerWallet == _msgSender(), "GSHIBA: withDraw No permission");
        if (address(this).balance > 0) {
            payable(_msgSender()).transfer(address(this).balance);
        }
    }

     //to receive ETH from uniswapV2Router when swaping
    receive() external payable {}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, TData memory data) = _getTValues(tAmount);
        data.tAmount = tAmount;
        data.currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(data);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, data.tFee, data.tLiquidity, data.tLotto, data.tTxgold, data.tMarketing);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, TData memory) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);

        uint256 tLotto = calculateLottoFee(tAmount);
        uint256 tTxgold = calculateTxgoldFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);

        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
                tTransferAmount = tTransferAmount.sub(tLotto);
                tTransferAmount = tTransferAmount.sub(tTxgold);
                tTransferAmount = tTransferAmount.sub(tMarketing);
        return (tTransferAmount, TData(0, tFee, tLiquidity, tLotto, tTxgold, tMarketing, 0));
    }
    function _getRValues(TData memory _data) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _data.tAmount.mul(_data.currentRate);
        uint256 rFee = _data.tFee.mul(_data.currentRate);
        uint256 rLiquidity = _data.tLiquidity.mul(_data.currentRate);
        uint256 rLotto = _data.tLotto.mul(_data.currentRate);
        uint256 rTxgold = _data.tTxgold.mul(_data.currentRate);
        uint256 rMarketing = _data.tMarketing.mul(_data.currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
                rTransferAmount = rTransferAmount.sub(rLotto);
                rTransferAmount = rTransferAmount.sub(rTxgold);
                rTransferAmount = rTransferAmount.sub(rMarketing);
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

    function addAddress(address adr) private {
        if(_AddressExists[adr])
            return;
        _AddressExists[adr] = true;
        _addressList.push(adr);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number)));
    }

    function lotterize() private view returns(address) {
        uint256 randomNumber = random().mod(_addressList.length);

        uint256 ownedAmount = _rOwned[_addressList[randomNumber]];

        if (ownedAmount >= _minLottoBalance) {
            return _addressList[randomNumber];
        }
        return _txgoldWallet;
    }

    function _takeLotto(uint256 tLotto, address from) private {
        if (tLotto == 0)
            return;

        uint256 currentRate =  _getRate();
        uint256 rLotto = tLotto.mul(currentRate);

        _rOwned[_lottoPotAddress] = _rOwned[_lottoPotAddress].add(rLotto);
        if(_isExcluded[_lottoPotAddress])
            _tOwned[_lottoPotAddress] = _tOwned[_lottoPotAddress].add(tLotto);

        emit Transfer(from, _lottoPotAddress, tLotto);
    }

    function drawLotto(uint256 amount) private lockTheLottery {
        _lottoWalletAddress = lotterize();
        _transfer(_lottoPotAddress, _lottoWalletAddress, amount);
        _lastLottoWinnerAmount = amount;
        _totalLottoPrize = _totalLottoPrize.add(amount);
        ++_lottoDrawCount;
        emit DrawLotto(amount, _lottoDrawCount);
    }

    function _takeTxgold(uint256 tTxgold, address from) private {
        if (tTxgold == 0)
            return;

        uint256 currentRate =  _getRate();
        uint256 rTxgold = tTxgold.mul(currentRate);

        if (_shouldSwapToBNB) {
            swapTokensForEth(rTxgold);
            _txgoldWallet.transfer(address(this).balance);
        } else {
            _rOwned[_txgoldWallet] = _rOwned[_txgoldWallet].add(rTxgold);
            if(_isExcluded[_txgoldWallet])
                _tOwned[_txgoldWallet] = _tOwned[_txgoldWallet].add(tTxgold);
        }

        emit Transfer(from, _txgoldWallet, tTxgold);
    }

    function _takeMarketing(uint256 tMarketing, address from) private {
        if (tMarketing == 0)
            return;

        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);

        if (_shouldSwapToBNB) {
            swapTokensForEth(rMarketing);
            _marketingWallet.transfer(address(this).balance);
        } else {
            _rOwned[_marketingWallet] = _rOwned[_marketingWallet].add(rMarketing);
            if(_isExcluded[_marketingWallet])
                _tOwned[_marketingWallet] = _tOwned[_marketingWallet].add(tMarketing);
        }

        emit Transfer(from, _marketingWallet, tMarketing);
    }

    function _takeLiquidity(uint256 tLiquidity, address from) private {
        if (tLiquidity == 0)
            return;
        
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);

        emit Transfer(from, address(this), tLiquidity);
    }


    function calculateLottoFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_lottoFee).div(
            10**2
        );
    }

    function calculateTxgoldFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_txgoldFee).div(
            10**2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
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

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _txgoldFee == 0 && _marketingFee == 0 && _lottoFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLottoFee = _lottoFee;
        _previousTxgoldFee = _txgoldFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _lottoFee = 0;
        _txgoldFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _lottoFee = _previousLottoFee;
        _txgoldFee = _previousTxgoldFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
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
        uint256 fromBalance = balanceOf(from);
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(fromBalance >= amount, "Token Balance is less than transfer amount");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        /*
            anti whale: when buying, check if sender balance will be greater than 1% of total supply
            if greater, throw error
        */
        if ( _isAntiWhaleEnabled && !_isExcludedFromAntiWhale[to] ) {
            if ( from == uniswapV2Pair || from == address(uniswapV2Router) ) {
                require(amount <= _antiWhaleThreshold, "Anti whale: can't buy more than the specified threshold");
                require(balanceOf(to).add(amount) <= _antiWhaleThreshold, "Anti whale: can't hold more than the specified threshold");
            }
        }
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & Liquidity if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance && !inSwapAndLiquidity &&    from != uniswapV2Pair && swapAndLiquidityEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquidity(contractTokenBalance);
        }

        // Process lotto draw
        uint256 lottoBalance = balanceOf(_lottoPotAddress);
        bool overMinLottoBalance = lottoBalance >= lotteryThreshold;
        if (
            overMinLottoBalance && !inSwapAndLiquidity && !inLotteryDraw && lottoEnabled
        ) {
            drawLotto(lottoBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        addAddress(from);
        addAddress(to);

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
    function swapAndLiquidity(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+Liquidity is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquidity(half, newBalance, otherHalf);
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
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _ownerWallet,
            block.timestamp
        );
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
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto, uint256 tTxgold, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity, sender);
        _takeLotto(tLotto, sender);
        _takeTxgold(tTxgold, sender);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto, uint256 tTxgold, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity, sender);
        _takeLotto(tLotto, sender);
        _takeTxgold(tTxgold, sender);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto, uint256 tTxgold, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity, sender);
        _takeLotto(tLotto, sender);
        _takeTxgold(tTxgold, sender);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}