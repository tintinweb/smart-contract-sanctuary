/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-14
*/

pragma solidity ^0.6.12;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        assembly {codehash := extcodehash(account)}
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
        (bool success,) = recipient.call{value : amount}("");
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
     * - the calling contract must have an BNB balance of at least `value`.
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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
    modifier onlyOwner {
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
        require(now > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity =0.6.6;

interface IYuanSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IYuanSwapPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IYuanSwapRouter {
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
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract GemToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public _isExcludedToFee;
    mapping(address => address) public excludedRouter;//for solve: remove liquidity eth need pay twice tax
    bool public inSwap;
    uint256 private _tTotal = 100 * 10 ** 8 * 10 ** 18;
    uint256 private _tFeeTotal;//
    uint256 public _taxFeeTotal; //3%
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint256 public _taxFee = 35; //3.5%
    uint256 public _taxForMaginFee = 30;//3%
    uint256 public minExAmount = 10000e18;
    uint256  public maxTransferAmount = 10 * 10 ** 6 * 10 ** 18;
    bool public swapEnabled = true;

    IYuanSwapRouter public yuanSwapRouter;
    address public yuanBpSwapPair;
    address public yuanSwapFactory;
    address public _bpAddress;
    address public bpBuyBackToAddress;
    address public taxSwapToAddress;

    event ExcludeFromFee(address sender, address account);
    event IncludeFromFee(address sender, address account);
    event ExcludeToFee(address sender, address account);
    event IncludeToFee(address sender, address account);
    event SwapBNBAndBP(uint256 tokenAmount, uint256 exForBnbAmount, uint256 exForBPAmount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event AdminBNBRecovery(address tokenRecovered, uint256 amount);
    event BPToTaxSwapAddr(uint256, uint256);
    event BPSwapToBuyBackAddr(uint256, uint256);
    event SwapEnabledUpdated(bool enabled);
    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (string memory name, string memory symbol, address bpAddress, address _swapRouter) public {
        _name = name;
        _symbol = symbol;
        _bpAddress = bpAddress;
        // BSC MainNet
        IYuanSwapRouter _yuanSwapRouter = IYuanSwapRouter(_swapRouter);
        // Create a GemSwap pair for this new token
        yuanSwapFactory = _yuanSwapRouter.factory();
        yuanBpSwapPair = IYuanSwapFactory(yuanSwapFactory).createPair(address(this), bpAddress);
        // set the rest of the contract variables
        yuanSwapRouter = _yuanSwapRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        swapEnabled = false;
        taxSwapToAddress = address(0x183B50C5dA8c765a9b90cB366677a289704f7311);
        bpBuyBackToAddress = address(0x000000000000000000000000000000000000dEaD);

        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        excludedRouter[address(yuanSwapRouter)] = yuanSwapRouter.WETH();
        //pancakeswap router -> weth
        excludedRouter[0x10ED43C718714eb63d5aA57B78B54704E256024E] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
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
        return _tOwned[account];
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

    //total fee
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(msg.sender, account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeFromFee(msg.sender, account);
    }

    function excludeToFee(address account) public onlyOwner {
        _isExcludedToFee[account] = true;
        emit ExcludeToFee(msg.sender, account);
    }

    function includeToFee(address account) public onlyOwner {
        _isExcludedToFee[account] = false;
        emit IncludeToFee(msg.sender, account);
    }

    //modify tax fee
    function setTaxFeePercent(uint256 taxFee, uint256 taxForMaginFee) external onlyOwner {
        require(taxFee >= taxForMaginFee && taxFee > 0, 'FEE_AMOUNT_WRONG');
        _taxFee = taxFee;
        _taxForMaginFee = taxForMaginFee;
    }
    //modify swap min Ex Fee
    function setSwapMinExFee(uint256 _minExAmount) public onlyOwner {
        require(_minExAmount > 0, 'MUSt_BIGGER_THAN_ZERO');
        minExAmount = _minExAmount;
    }
    //modify transfer max amount
    function setTransferMaxAmount(uint256 _maxTransferAmount) public onlyOwner {
        require(_maxTransferAmount > 0, 'MUSt_BIGGER_THAN_ZERO');
        maxTransferAmount = _maxTransferAmount;
    }

    function setRouteAddr(address _yuanSwapRouter) public onlyOwner {
        require(_yuanSwapRouter != address(0), 'ZERO_ADDRESS');
        yuanSwapRouter = IYuanSwapRouter(_yuanSwapRouter);
    }
    function setBPTokenAddr(address bpAddress) public onlyOwner {
        require(bpAddress != address(0), 'ZERO_ADDRESS');
        _bpAddress = bpAddress;
    }
    //modify bp,bnb receive address
    function setBPAndBNBReceiveAddr(address _bpBuyBackToAddress, address _taxSwapToAddress) external onlyOwner {
        require(_bpBuyBackToAddress != address(0) && _taxSwapToAddress != address(0), 'ZERO_ADDRESS');
        bpBuyBackToAddress = _bpBuyBackToAddress;
        taxSwapToAddress = _taxSwapToAddress;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }
    //to recieve BNB from bakerySwapRouter when swaping
    receive() external payable {}


    function calculateTaxFee(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_taxFee).div(10 ** 3);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
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
        require(amount <= maxTransferAmount, 'TRANSFER_MORE_THAN_MAXAMOUNT');
        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount);
    }

    //for removeliqudityeth tax twice
    function isExcludedRouter(address sender, address recipient) public view returns (bool){
        if (excludedRouter[recipient] == address(0)) {
            return false;
        }
        address weth = excludedRouter[recipient];
        address pair = IYuanSwapFactory(IYuanSwapRouter(recipient).factory()).getPair(address(this), weth);
        if (sender == pair) {
            return true;
        }
        return false;
    }

    function setExcludedRouter(address router, address _weth) public onlyOwner {
        excludedRouter[router] = _weth;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (isExcludedRouter(sender, recipient)) {
            _transferFromExcluded(sender, recipient, amount);
        } else {
            if (!_isExcludedFromFee[sender]) {
                if (_isExcludedToFee[recipient]) {
                    _transferFromExcluded(sender, recipient, amount);
                } else {
                    _transferStandard(sender, recipient, amount);
                }
            } else {
                _transferFromExcluded(sender, recipient, amount);
            }
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 tTransferFee = tAmount.mul(_taxFee).div(10 ** 3);
        //3% 卖成BNB（税金)
        uint256 taxMarginFee = tAmount.mul(_taxForMaginFee).div(10 ** 3);
        uint256 tTransferAmount = tAmount.sub(tTransferFee);
        _tFeeTotal = _tFeeTotal.add(tTransferFee);
        _taxFeeTotal = _taxFeeTotal.add(taxMarginFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _tOwned[address(this)] = _tOwned[address(this)].add(tTransferFee);
        emit Transfer(sender, address(this), tTransferFee);

        if (swapEnabled && !inSwap && sender != yuanBpSwapPair && !isSwapRouterToPair(msg.sender, recipient)) {
            uint256 swapAmount = balanceOf(address(this));
            if (swapAmount >= minExAmount) {
                _swapEx(swapAmount);
            }
        }

        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);

    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _swapEx(uint256 swapAmount) private lockSwap {
        swapAmount = (swapAmount > maxTransferAmount) ? maxTransferAmount : swapAmount;
        //3%  fee
        uint256 exForTaxBpAmount = swapAmount.mul(_taxForMaginFee).div(_taxFee);
        if (exForTaxBpAmount > 0) {
            uint256 bpChange;
            uint256 bpBeforeBal = IERC20(_bpAddress).balanceOf(taxSwapToAddress);
            swapTokensForBP(exForTaxBpAmount, taxSwapToAddress);
            uint256 bpAfterBal = IERC20(_bpAddress).balanceOf(taxSwapToAddress);
            if (bpAfterBal > bpBeforeBal) {
                bpChange = bpAfterBal.sub(bpBeforeBal);
            }
            emit BPToTaxSwapAddr(exForTaxBpAmount, bpChange);
        }
        //0.5% buyback
        uint256 exForBPAmount = swapAmount.sub(exForTaxBpAmount);
        if (exForBPAmount > 0) {
            uint256 bpChange;
            uint256 bpBeforeBal = IERC20(_bpAddress).balanceOf(bpBuyBackToAddress);
            swapTokensForBP(exForBPAmount, bpBuyBackToAddress);
            uint256 bpAfterBal = IERC20(_bpAddress).balanceOf(bpBuyBackToAddress);
            if (bpAfterBal > bpBeforeBal) {
                bpChange = bpAfterBal.sub(bpBeforeBal);
            }
            emit BPSwapToBuyBackAddr(exForBPAmount, bpChange);
        }
        emit SwapBNBAndBP(swapAmount, exForTaxBpAmount, exForBPAmount);
    }

    function swapForAll(uint256 exAmount) public {
        require(swapEnabled ==true,'SWAP NOT ENABLE');
        //3% fee
        uint256 swapAmount;
        if (exAmount == 0) {
            swapAmount = (balanceOf(address(this)) > maxTransferAmount) ? maxTransferAmount : swapAmount;
        } else {
            swapAmount = exAmount;
        }
        uint256 exForTaxBpAmount = swapAmount.mul(_taxForMaginFee).div(_taxFee);
        if (exForTaxBpAmount > 0) {
            uint256 bpChange;
            uint256 bpBeforeBal = IERC20(_bpAddress).balanceOf(taxSwapToAddress);
            swapTokensForBP(exForTaxBpAmount, taxSwapToAddress);
            uint256 bpAfterBal = IERC20(_bpAddress).balanceOf(taxSwapToAddress);
            if (bpAfterBal > bpBeforeBal) {
                bpChange = bpAfterBal.sub(bpBeforeBal);
            }
            emit BPToTaxSwapAddr(exForTaxBpAmount, bpChange);
        }
        //0.5% buyback
        uint256 exForBPAmount = swapAmount.sub(exForTaxBpAmount);
        if (exForBPAmount > 0) {
            uint256 bpChange;
            uint256 bpBeforeBal = IERC20(_bpAddress).balanceOf(bpBuyBackToAddress);
            swapTokensForBP(exForBPAmount, bpBuyBackToAddress);
            uint256 bpAfterBal = IERC20(_bpAddress).balanceOf(bpBuyBackToAddress);
            if (bpAfterBal > bpBeforeBal) {
                bpChange = bpAfterBal.sub(bpBeforeBal);
            }
            emit BPSwapToBuyBackAddr(exForBPAmount, bpChange);
        }
        emit SwapBNBAndBP(swapAmount, exForTaxBpAmount, exForBPAmount);
    }

    function swapTokensForBP(uint256 tokenAmount, address swapToAddr) private {
        // generate the BakerySwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _bpAddress;
        _approve(address(this), address(yuanSwapRouter), tokenAmount);

        // make the swap
        yuanSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BP
            path,
            swapToAddr,
            block.timestamp
        );
    }

    function isSwapRouterToPair(address router, address pair) internal view returns (bool result){
        if (pair == yuanBpSwapPair && router == address(yuanSwapRouter)) {
            (uint112 _r0, uint112 _r1,) = IYuanSwapPair(pair).getReserves();
            address token0 = IYuanSwapPair(pair).token0();
            address token1 = IYuanSwapPair(pair).token1();

            if (token0 == address(this)) {
                uint token1AddrBal = IERC20(token1).balanceOf(pair);
                if (token1AddrBal > _r1) {
                    return true;
                }
            } else if (token1 == address(this)) {
                uint token0AddrBal = IERC20(token0).balanceOf(pair);
                if (token0AddrBal > _r0) {
                    return true;
                }
            }
        }
    }

    function withdrawBNB(address  payable _withdrawAddr, uint256 _amount) public onlyOwner {
        require(_withdrawAddr != address(0), 'zero address');
        require(_amount <= address(this).balance, 'error amount');
        _withdrawAddr.transfer(_amount);
        emit AdminBNBRecovery(_withdrawAddr, _amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(this), "zero token");
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}