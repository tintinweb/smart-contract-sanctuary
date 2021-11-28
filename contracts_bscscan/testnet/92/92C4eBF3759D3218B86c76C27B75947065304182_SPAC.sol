/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
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

    function getUnlockTime() public view returns (uint256) {
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

interface ILottery {
    function swap() external;
}


contract SPAC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee; //address excluded from fee
    address[] private _excludedFromFee;

    mapping (address => bool) private _isExcluded;  //address excluded from reward
    address[] private _excluded;
    address public _developer;
    address public _lottery;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 3 * 10**8 * 10**18;
    uint256 public _maxTxAmount = 3 * 10**8 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "SPAC";
    string private _symbol = "SPAC";
    uint8 private  _decimals = 18;

    uint256 public _taxFee = 0;       //
    uint256 public _referFee = 0;     //2%, 1%, 1% for 1/2/3 level referer, 1% for group leader
    uint256 public _developerFee = 0;  //fixed to 2%
    uint256 public _lotteryFee = 15;

    uint256 constant  ALLFEE_NUMBER = 4;
    uint256 constant  TAXFEE_INDEX = 0;
    uint256 constant  REFERFEE_INDEX = 1;
    uint256 constant  DEVELOPERFEE_INDEX = 2;
    uint256 constant  LOTTERYFEE_INDEX= 3;

    //in rValues and tValues array, amount, transferamount, fee, liquidity, dev, lottery are organized like below.
    uint256 constant AMOUNT_INDEX = 0;
    uint256 constant TRANSFERAMOUNT_INDEX = 1;
    uint256 constant TAX_INDEX = 2;
    uint256 constant REFER_INDEX = 3;
    uint256 constant DEVELOPER_INDEX = 4;
    uint256 constant LOTTERY_INDEX = 5;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public constant BLACKHOLE = 0x0000000000000000000000000000000000000001;
    IERC20 public usdt = IERC20(0x2d77975Be91442B123D27B5F2Bd731f9593FdA08); // bsc testnet IERC20(0x51657285b545F1D92D8AB80B6120498931cC9Dc7);  //bscmainnet IERC20(0x55d398326f99059fF775485246999027B3197955);

   uint256 constant REFER_DEPTH = 4;
    struct UserInfo {
        address father;
        address[] childs;
        uint256[REFER_DEPTH] referRewards;
    }
    address immutable public genesisAddress;
    mapping(address => UserInfo) public userInfo;
    uint256 public _numTokensToBeRefer = 10 * 10**18;
    uint256 public _extraFeeForNoRefer = 0; //2% extraFee
    uint256 public _groupLeaderSearchDepth = REFER_DEPTH;
    uint256 _groupLeaderIndex = REFER_DEPTH - 1;

    event Transfer(address indexed, address indexed, uint);
    event TakeDeveloper(address indexed, uint256);
    event TakeLottery(address indexed, uint256);
    event TakeReferRewards(address[REFER_DEPTH], uint256[REFER_DEPTH]);
    event RegisterRefer(address indexed, address indexed);


    constructor (address developer) public {
        _rOwned[_msgSender()] = _rTotal;
        _developer = developer;

        genesisAddress = _msgSender();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //bsc testnet 0xD99D1c33F9fC3444f8101754aBC46c52416550D1, bsc mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), address(usdt));

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner,  this contract, lotterytreasure and developer from fee
        _isExcludedFromFee[_msgSender()] = true;
        _excludedFromFee.push(_msgSender());

        _isExcludedFromFee[address(this)] = true;
        _excludedFromFee.push(address(this));

        _isExcludedFromFee[_developer] = true;
        _excludedFromFee.push(_developer);

        userInfo[_msgSender()].father = _msgSender();
        userInfo[BLACKHOLE].father = _msgSender();

        emit Transfer(address(0), _msgSender(), _tTotal);
    }


    function setDeveloper(address developer) public onlyOwner {
        includeInFee(_developer);
        _developer = developer;
        excludeFromFee(developer);
    }

    function setLottery(address lottery) public onlyOwner{
        if (_lottery != address(0)){
            includeInFee(_lottery);
        }

        if (!_isExcludedFromFee[lottery]){ //exclude lottery from fee if not excluded before
            excludeFromFee(lottery);
        }
        _lottery = lottery;
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function exluded(uint256 index) public view returns (address){
        return _excluded[index];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, bool hasRefer) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        uint256 extraFee  = 0;
        if (!hasRefer){
            extraFee = _extraFeeForNoRefer;
        }

        (uint256[6] memory rValues,)  = _getValues(tAmount, _getFeeRates(extraFee));

        if (!deductTransferFee) {
            uint256 rAmount = rValues[AMOUNT_INDEX];
            return rAmount;
        } else {
            uint256 rTransferAmount = rValues[TRANSFERAMOUNT_INDEX];
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
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

    function excludeFromFee(address account) public onlyOwner {
        require(!_isExcludedFromFee[account], "Account is already excluded");
        _isExcludedFromFee[account] = true;
        _excludedFromFee.push(account);
    }

    function includeInFee(address account) public onlyOwner {
        require(_isExcludedFromFee[account], "Account is already included");
        for (uint256 i; i < _excludedFromFee.length;i++){
            if (_excludedFromFee[i] == account){
                _isExcludedFromFee[account] = false;
                _excludedFromFee[i] = _excludedFromFee[_excludedFromFee.length - 1];
                _excludedFromFee.pop();
            }
        }
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee < 100, "taxFee >= 100");
        _taxFee = taxFee;
    }

    function setLotteryFeePercent(uint256 lotteryFee) external onlyOwner{
        require(lotteryFee < 100, "lotteryFee >= 100");
        _lotteryFee = lotteryFee;
    }

    function setReferFeePercent(uint256 referFee) external onlyOwner {
        require(referFee < 100, "referFee >= 100");
        _referFee = referFee;
    }


    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent <= 10000, "maxTxPercent > 10000");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }

    // function setNumTokensToBeGroupLeader(uint256 numTokensToBeGroupLeader) public onlyOwner{
    //     _numTokensToBeGroupLeader = numTokensToBeGroupLeader;
    // }

    function getValues(uint256 amount, bool hasRefer) public view returns (uint256[6] memory, uint256[6] memory){
        uint256 extraFee = 0;
        if (!hasRefer) {
            extraFee = _extraFeeForNoRefer;
        }
        return _getValues(amount, _getFeeRates(extraFee));
    }

    function lottery() public view returns (address){
        return _lottery;
    }

    function transferOwnership(address newOwner) override public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        includeInFee(owner());
        excludeFromFee(newOwner);
        super.transferOwnership(newOwner);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, uint256[ALLFEE_NUMBER] memory feeRates) private view returns (uint256[6] memory, uint256[6] memory) {
        uint256[6] memory tValues = _getTValues(tAmount, feeRates);
        uint256[6] memory rValues = _getRValues(tValues, _getRate());
        return (rValues, tValues);
    }

    function _getTValues(uint256 tAmount, uint256[ALLFEE_NUMBER] memory feeRates) private pure returns (uint256[6] memory) {
        uint256[6] memory tValues;
        tValues[0] = tAmount;
        tValues[2] = calculateTaxFee(tAmount, feeRates[TAXFEE_INDEX]);
        tValues[3] = calculateReferFee(tAmount, feeRates[REFERFEE_INDEX]);
        tValues[4] = calculateDeveloperFee(tAmount, feeRates[DEVELOPERFEE_INDEX]);
        tValues[5] = calculateLotteryFee(tAmount, feeRates[LOTTERYFEE_INDEX]);
        tValues[1] = tValues[0].sub(tValues[2]).sub(tValues[3]).sub(tValues[4]).sub(tValues[5]);
        return tValues;
    }


    function _getRValues(uint256[6] memory tValues, uint256 currentRate) private pure returns (uint256[6] memory) {
        uint[6] memory rValues;
        rValues[0] = tValues[0].mul(currentRate);
        rValues[2] = tValues[2].mul(currentRate);
        rValues[3] = tValues[3].mul(currentRate);
        rValues[4] = tValues[4].mul(currentRate);
        rValues[5] = tValues[5].mul(currentRate);
        rValues[1]  = rValues[0].sub(rValues[2]).sub(rValues[3]).sub(rValues[4]).sub(rValues[5]);
        return rValues;
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

    //@dev, distribute referwards, emit event
    function _takeReferRewards(address recipient, uint256 rReferReward, uint256 tReferReward) private {
    //    address[REFER_DEPTH] memory beneficiaries = [BLACKHOLE, BLACKHOLE, BLACKHOLE, BLACKHOLE];
    //    uint256[REFER_DEPTH] memory rewardPercents = [uint256(40), 20, 20, 20];
    //    uint256[REFER_DEPTH] memory tRewards;
    //    bool groupLeaderFound;

    //    if (tReferReward == 0){
    //        return;
    //    }

    //    address father = userInfo[recipient].father;
    //    for (uint256 i= 0; i < REFER_DEPTH - 1; i++){
    //        if (father == address(0) || father == genesisAddress){
    //            break;
    //        }

    //        beneficiaries[i] = father;
    //        if (!groupLeaderFound && balanceOf(father) >= _numTokensToBeGroupLeader){
    //            groupLeaderFound = true;
    //            beneficiaries[_groupLeaderIndex] = father;
    //        }
    //        father = userInfo[father].father;
    //    }

    //    //if not find groupleader in the nearest 3 level, search upto 10 level
    //    if (!groupLeaderFound) {
    //        father = userInfo[recipient].father;
    //        for (uint256 i= 0; i < _groupLeaderSearchDepth; i++){
    //            if (father == address(0) || father == genesisAddress){
    //                break;
    //            }

    //            if (balanceOf(father) >= _numTokensToBeGroupLeader){
    //                beneficiaries[_groupLeaderIndex] = father;
    //                break;
    //            }else{
    //                father = userInfo[father].father;
    //            }
    //        }
    //    }


    //    {
    //        uint256 tRemain = tReferReward;
    //        uint256 rRemain = rReferReward;

    //        //i = 0,1,2 only, not cover groupleader
    //        for (uint256 i= 0; i < REFER_DEPTH - 1; i++){
    //            uint256 rReward = rReferReward.mul(rewardPercents[i]).div(100);
    //            uint256 tReward = tReferReward.mul(rewardPercents[i]).div(100);
    //            tRewards[i]  = tReward;

    //            tRemain = tRemain - tReward;
    //            rRemain = rRemain - rReward;

    //            _rOwned[beneficiaries[i]] = _rOwned[beneficiaries[i]].add(rReward);
    //            if(_isExcluded[beneficiaries[i]])
    //                _tOwned[beneficiaries[i]] = _tOwned[beneficiaries[i]].add(tReward);

    //            userInfo[beneficiaries[i]].referRewards[i] = userInfo[beneficiaries[i]].referRewards[i].add(tRewards[i]);
    //        }

    //        // allocate all remain to the group leader
    //        _rOwned[beneficiaries[_groupLeaderIndex]] = _rOwned[beneficiaries[_groupLeaderIndex]].add(rRemain);
    //        if(_isExcluded[beneficiaries[_groupLeaderIndex]])
    //            _tOwned[beneficiaries[_groupLeaderIndex]] = _tOwned[beneficiaries[_groupLeaderIndex]].add(tRemain);

    //        userInfo[beneficiaries[_groupLeaderIndex]].referRewards[_groupLeaderIndex] = userInfo[beneficiaries[_groupLeaderIndex]].referRewards[_groupLeaderIndex].add(tRemain);
    //        tRewards[_groupLeaderIndex] = tRemain;

    //        emit TakeReferRewards(beneficiaries,tRewards);
    //    }
    }

    function _takeDeveloper(uint256 rDeveloper, uint256 tDeveloper) private {
        _rOwned[_developer] = _rOwned[_developer].add(rDeveloper);
        if(_isExcluded[_developer])
            _tOwned[_developer] = _tOwned[_developer].add(tDeveloper);
        emit TakeDeveloper(_developer, tDeveloper);
    }

    function _takeLottery(uint256 rLottery,uint256 tLottery) private {
        _rOwned[_lottery] = _rOwned[_lottery].add(rLottery);
        if(_isExcluded[_lottery])
            _tOwned[_lottery] = _tOwned[_lottery].add(tLottery);
        emit TakeLottery(_lottery, tLottery);
    }

    function calculateTaxFee(uint256 amount, uint256 taxFee) private pure returns (uint256) {
        return amount.mul(taxFee).div(
            10**2
        );
    }

    function calculateReferFee(uint256 amount, uint256 referFee) private pure returns (uint256) {
        return amount.mul(referFee).div(
            10**2
        );
    }

    function calculateDeveloperFee(uint256 amount, uint256 developerFee) private pure returns (uint256) {
        return amount.mul(developerFee).div(
            10**2
        );
    }

    function calculateLotteryFee(uint256 amount, uint256 lotteryFee) private pure returns (uint256) {
        return amount.mul(lotteryFee).div(
            10**2
        );
    }

    function _getFeeRates(uint256 extraFee) private view returns (uint256[ALLFEE_NUMBER] memory){
        uint256[ALLFEE_NUMBER] memory feeRates;
        feeRates = [_taxFee, _referFee, _developerFee, _lotteryFee+extraFee];
        return feeRates;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (_lottery != address(0)){
            //only participate lottery if buying from uniswap
//            if (takeFee && from == uniswapV2Pair) {
//                ILottery(_lottery).transferNotify(to, amount);
//            }

            if (from != uniswapV2Pair && from != _lottery) {
                ILottery(_lottery).swap();
            }
        }

        //register refer at the 1st token transfer which >= _numTokensToBeRefer
//        if (!from.isContract() && !to.isContract() && userInfo[to].father == address(0) && amount >= _numTokensToBeRefer){
//            _registerRefer(to, from);
//        }

        //transfer amount, it will take tax, refer, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        uint256[ALLFEE_NUMBER] memory feeRates;
        if (takeFee) {
//            uint256 extraFee = 0;
//            if (userInfo[recipient].father == address(0)){
//                extraFee = _extraFeeForNoRefer;
//            }
            feeRates = _getFeeRates(0);
        }

        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount,feeRates);
        }else if(!_isExcluded[sender] && _isExcluded[recipient]){
            _transferToExcluded(sender, recipient, amount, feeRates);
        }else if(_isExcluded[sender] && !_isExcluded[recipient]){
            _transferFromExcluded(sender, recipient, amount, feeRates);
        }else{
            _transferBothExcluded(sender, recipient, amount, feeRates);
        }
    }


    function _transferStandard(address sender, address recipient, uint256 amount, uint256[ALLFEE_NUMBER] memory feeRates) private {
        (uint256[6] memory rValues, uint256[6] memory tValues) = _getValues(amount, feeRates);
        {
            uint256 rAmount = rValues[AMOUNT_INDEX];
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
        }

        {
            uint256 rTransferAmount = rValues[TRANSFERAMOUNT_INDEX];
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        }

        {
            uint256 rReferReward = rValues[REFER_INDEX];
            uint256 tReferReward = tValues[REFER_INDEX];
            if (tReferReward != 0){
                _takeReferRewards(recipient, rReferReward, tReferReward);
            }
        }
        {
            uint256 rDeveloper = rValues[DEVELOPER_INDEX];
            uint256 tDeveloper = tValues[DEVELOPER_INDEX];
            if (tDeveloper != 0){
                _takeDeveloper(rDeveloper, tDeveloper);
            }
        }
        {
            uint256 rLottery = rValues[LOTTERY_INDEX];
            uint256 tLottery = tValues[LOTTERY_INDEX];
            if (tLottery != 0){
                _takeLottery(rLottery, tLottery);
            }
        }
        {
            uint256 rFee = rValues[TAX_INDEX];
            uint256 tFee = tValues[TAX_INDEX];
            if (tFee != 0){
                _reflectFee(rFee, tFee);
            }
        }

        uint256 tTransferAmount = tValues[TRANSFERAMOUNT_INDEX];
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 amount, uint256[ALLFEE_NUMBER] memory feeRates) private {
        (uint256[6] memory rValues, uint256[6] memory tValues) = _getValues(amount, feeRates);
        {
            uint256 rAmount = rValues[AMOUNT_INDEX];
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
        }

        {
            uint256 tTransferAmount = tValues[TRANSFERAMOUNT_INDEX];
            uint256 rTransferAmount = rValues[TRANSFERAMOUNT_INDEX];
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        }

        {
            uint256 rReferReward = rValues[REFER_INDEX];
            uint256 tReferReward = tValues[REFER_INDEX];
            if (tReferReward != 0){
                _takeReferRewards(recipient, rReferReward, tReferReward);
            }
        }
        {
            uint256 rDeveloper = rValues[DEVELOPER_INDEX];
            uint256 tDeveloper = tValues[DEVELOPER_INDEX];
            if (tDeveloper != 0){
                _takeDeveloper(rDeveloper, tDeveloper);
            }
        }
        {
            uint256 rLottery = rValues[LOTTERY_INDEX];
            uint256 tLottery = tValues[LOTTERY_INDEX];
            if (tLottery != 0){
                _takeLottery(rLottery, tLottery);
            }
        }
        {
            uint256 rFee = rValues[TAX_INDEX];
            uint256 tFee = tValues[TAX_INDEX];
            if (tFee != 0){
                _reflectFee(rFee, tFee);
            }
        }

        uint256 tTransferAmount = tValues[TRANSFERAMOUNT_INDEX];
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient,  uint256 amount, uint256[ALLFEE_NUMBER] memory feeRates) private {
        (uint256[6] memory rValues, uint256[6] memory tValues) = _getValues(amount, feeRates);
        {
            uint256 rAmount = rValues[AMOUNT_INDEX];
            _tOwned[sender] = _tOwned[sender].sub(amount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
        }

        {
            uint256 rTransferAmount = rValues[TRANSFERAMOUNT_INDEX];
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        }

        {
            uint256 rReferReward = rValues[REFER_INDEX];
            uint256 tReferReward = tValues[REFER_INDEX];
            if (tReferReward != 0){
                _takeReferRewards(recipient, rReferReward, tReferReward);
            }
        }
        {
            uint256 rDeveloper = rValues[DEVELOPER_INDEX];
            uint256 tDeveloper = tValues[DEVELOPER_INDEX];
            if (tDeveloper != 0){
                _takeDeveloper(rDeveloper, tDeveloper);
            }
        }
        {
            uint256 rLottery = rValues[LOTTERY_INDEX];
            uint256 tLottery = tValues[LOTTERY_INDEX];
            if (tLottery != 0){
                _takeLottery(rLottery, tLottery);
            }
        }
        {
            uint256 rFee = rValues[TAX_INDEX];
            uint256 tFee = tValues[TAX_INDEX];
            if (tFee != 0){
                _reflectFee(rFee, tFee);
            }
        }
        uint256 tTransferAmount = tValues[TRANSFERAMOUNT_INDEX];
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient,  uint256 amount, uint256[ALLFEE_NUMBER] memory feeRates) private {
        (uint256[6] memory rValues, uint256[6] memory tValues) = _getValues(amount, feeRates);
        {
            uint256 rAmount = rValues[AMOUNT_INDEX];
            _tOwned[sender] = _tOwned[sender].sub(amount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
        }
        {
            uint256 tTransferAmount = tValues[TRANSFERAMOUNT_INDEX];
            uint256 rTransferAmount = rValues[TRANSFERAMOUNT_INDEX];
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        }

        {
            uint256 rReferReward = rValues[REFER_INDEX];
            uint256 tReferReward = tValues[REFER_INDEX];
            if (tReferReward != 0){
                _takeReferRewards(recipient, rReferReward, tReferReward);
            }
        }
        {
            uint256 rDeveloper = rValues[DEVELOPER_INDEX];
            uint256 tDeveloper = tValues[DEVELOPER_INDEX];
            if (tDeveloper != 0){
                _takeDeveloper(rDeveloper, tDeveloper);
            }
        }
        {
            uint256 rLottery = rValues[LOTTERY_INDEX];
            uint256 tLottery = tValues[LOTTERY_INDEX];
            if (tLottery != 0){
                _takeLottery(rLottery, tLottery);
            }
        }
        {
            uint256 rFee = rValues[TAX_INDEX];
            uint256 tFee = tValues[TAX_INDEX];
            if (tFee != 0){
                _reflectFee(rFee, tFee);
            }
        }

        uint256 tTransferAmount = tValues[TRANSFERAMOUNT_INDEX];
        emit Transfer(sender, recipient, tTransferAmount);
    }


//    function registerRefer(address _refer) public returns (bool){
//        require(userInfo[_msgSender()].father == address(0), "already has refer");
//        require(_refer != address(0), "refer can not be address(0)");
//        return _registerRefer(_msgSender(), _refer);
//    }


//    function _registerRefer(address _account, address _refer) internal returns (bool){
//        require(userInfo[_refer].father != address(0) || _refer == owner() || _refer == genesisAddress, "refer does not exist");
//
//        if (userInfo[_account].father != address(0)){
//            return false;
//        }
//
//        UserInfo storage father = userInfo[_refer];
//        UserInfo storage user = userInfo[_account];
//
//        user.father = _refer;
//
//        father.childs.push(_account);
//        emit RegisterRefer(_account, _refer);
//        return true;
//    }

//    function setNumTokensToBeRefer(uint256 numTokensToBeRefer) public onlyOwner{
//        _numTokensToBeRefer = numTokensToBeRefer;
//    }

//    function setExtraFeePercent(uint256 extraFee) external onlyOwner{
//        require(extraFee < 10, "extraFee >= 10");
//        _extraFeeForNoRefer = extraFee;
//    }

//    function getRefer(address _account) public view returns (address){
//        return userInfo[_account].father;
//    }
//
//    function getChilds(address _account) public view returns (address[] memory){
//        return userInfo[_account].childs;
//    }
//
//    function getReferReward(address _account) public view returns(uint256[REFER_DEPTH] memory){
//        return (userInfo[_account].referRewards);
//    }

}