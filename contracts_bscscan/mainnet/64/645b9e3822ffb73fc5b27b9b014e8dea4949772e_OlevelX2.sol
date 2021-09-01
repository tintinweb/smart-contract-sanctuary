/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

/**

*/
 
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function Z_transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
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


contract OlevelX2 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    address private _burnPool = 0x0000000000000000000000000000000000000000;

    address public _marketingWallet;
    address public _buybackWallet;
    address public _communityRewardsWallet;
    address public _migrationWallet;

   
    uint8 private _decimals = 7;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**_decimals; // 1 Trillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "OlevelX2";
    string private _symbol = "LX2";
    
    uint256 public _impact1 = 10;
    uint256 public _impact2 = 20;    

    uint256 public _taxFee = 1; // will change according to sell or buy function
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 8; // will change according to sell or buy function
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _buyLiquidityFee = 4;
    uint256 public _buyTaxFee = 1;
    uint256 public _sellLiquidityFeeA = 8;
    uint256 public _sellLiquidityFeeB = 16;
    uint256 public _sellTaxFeeA = 2;
    uint256 public _sellTaxFeeB = 4;
    uint256 public _transferLiquidityFee = 5;
    uint256 public _transferTaxFee = 0;
    uint256 public _exchangeLiquidityFee = 0;
    uint256 public _exchangeTaxFee = 0;
    uint256 public _marketingFee = 50;
    uint256 public _buybackFee = 50;


    uint256 public _maxSellAttempts = 4;

    uint256 public _sell_Window = 9000; 
    uint256 public _sell_InitialWait = 1800; 
    uint256 public _sell_FurtherWait = 1800;


    mapping(address => uint256) private buy_AllowedTime;
    mapping(address => uint256) private sell_AllowedTime;
    mapping(address => uint256) private firstsell;
    mapping(address => uint256) private sellnumber;
    mapping(address => uint256) private HodlingStartTime;
    mapping(address => bool) private _isBlacklisted;
    mapping(address => bool) private AllowedExchanges;
    mapping(address => uint256) private BridgeLiquidityFee;
    mapping(address => uint256) private BridgeTaxFee;
    mapping(address => bool) private AllowedBridges;


    bool private isTrade = true;
    bool private antiDumpEnabled = false;

    uint256 public _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
                
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    

    bool public feesEnabled = false;
    
    bool inSwapAndLiquify;
    bool public ProjectFundingEnabled = false;
    bool public tradingEnabled = false;
    uint256 private minTokensBeforeSwap = 30000000 * 10**_decimals; // 30m

    uint256 startDate;

    event ProjectFundingEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        address indexed address01,
		uint256 amount01,
		address indexed address02,
		uint256 amount02
    );
    event TokensSentToCommunityWallet (
			address indexed recipient,
			uint256  amount
	);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancake

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        startDate = block.timestamp + 20700;

        _marketingWallet = msg.sender;
        _communityRewardsWallet = msg.sender;
        _buybackWallet = msg.sender;
        _migrationWallet = msg.sender;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, address to) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount, to);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount, to);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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
        require(!_isBlacklisted[from], "Sender address is blacklisted");
		require(!_isBlacklisted[to], "Recipient address is blacklisted");
        
        if (from != owner() && !tradingEnabled) {
            require(tradingEnabled, "Trading is not enabled yet");
        }
        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            
            if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                require(amount <= _maxTxAmount, "Anti-dump enabled: Token amount exceeds the max amount.");
            }
            if (from == address(_migrationWallet) && balanceOf(to) == 0) {
                HodlingStartTime[to] = 1627855200;
            }
            if ( balanceOf(from) == 0 ) {
                HodlingStartTime[from] = block.timestamp;
            }
            if ( balanceOf(to) == 0 ) {
                 HodlingStartTime[to] = block.timestamp;
            }
            if (to != address(uniswapV2Router) && antiDumpEnabled) {
                require(amount <= _maxTxAmount, "Anti-dump enabled: Token amount exceeds the max amount.");
                require(buy_AllowedTime[to] < block.timestamp, "Anti-bots enabled: The waiting period is 1 minute");
                buy_AllowedTime[to] = block.timestamp + (1 minutes);
                isTrade = true;
                _liquidityFee = _buyLiquidityFee; 
                _taxFee = _buyTaxFee;
            }
            if (from != uniswapV2Pair && to != address(uniswapV2Pair) && antiDumpEnabled) {
                require(amount <= _maxTxAmount, "Anti-dump enabled: Token amount exceeds the max amount.");

                if (AllowedExchanges[from] || AllowedExchanges[to]) {
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = false;
                    _liquidityFee = _exchangeLiquidityFee; 
                    _taxFee = _exchangeTaxFee;
                }
                else if (AllowedBridges[from]) {
                        HodlingStartTime[from] = block.timestamp; 
                        isTrade = false;
                        _liquidityFee = BridgeLiquidityFee[from];
                        _taxFee = BridgeTaxFee[from];
                }
                else if (AllowedBridges[to]) {
                        HodlingStartTime[from] = block.timestamp;
                        isTrade = false;
                        _liquidityFee = BridgeLiquidityFee[to];
                        _taxFee = BridgeTaxFee[to];
                }
                else {
                        HodlingStartTime[from] = block.timestamp;
                        isTrade = false;
                        _liquidityFee = _transferLiquidityFee; 
                        _taxFee = _transferTaxFee;
                }
            }
            if (from != uniswapV2Pair && to == address(uniswapV2Pair) && antiDumpEnabled) {
                require(sell_AllowedTime[from] < block.timestamp);
                if(firstsell[from] + _sell_Window < block.timestamp){
                sellnumber[from] = 0;
                }

                if (sellnumber[from] == 0 && amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1));
                    sellnumber[from]++;
                    firstsell[from] = block.timestamp;
                    sell_AllowedTime[from] = block.timestamp + _sell_InitialWait;
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = true;
                    _liquidityFee = _sellLiquidityFeeA;
                    _taxFee = _sellTaxFeeA;
                }
                else if (sellnumber[from] == 0) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact2));
                    sellnumber[from]++;
                    firstsell[from] = block.timestamp;
                    sell_AllowedTime[from] = block.timestamp + _sell_FurtherWait;
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = true;
                    _liquidityFee = _sellLiquidityFeeB;
                    _taxFee = _sellTaxFeeB;
                }
                else if (sellnumber[from] < _maxSellAttempts && amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1)) { 
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1));
                    sellnumber[from]++;
                    sell_AllowedTime[from] = block.timestamp + _sell_InitialWait;
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = true;
                    _liquidityFee = _sellLiquidityFeeA;
                    _taxFee = _sellTaxFeeA; 
                }
                else if (sellnumber[from] < _maxSellAttempts) { 
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact2));
                    sellnumber[from]++;
                    sell_AllowedTime[from] = block.timestamp + _sell_FurtherWait;
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = true;
                    _liquidityFee = _sellLiquidityFeeB;
                    _taxFee = _sellTaxFeeB;
                }
                else if (sellnumber[from] == _maxSellAttempts && amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1));
                    sellnumber[from]++;
                    sell_AllowedTime[from] = firstsell[from] + _sell_Window;
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = true;
                    _liquidityFee = _sellLiquidityFeeA;
                    _taxFee = _sellTaxFeeA;
                }
                else if (sellnumber[from] == _maxSellAttempts) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact2));
                    sellnumber[from]++;
                    sell_AllowedTime[from] = firstsell[from] + _sell_Window;
                    HodlingStartTime[from] = block.timestamp;
                    isTrade = true;
                    _liquidityFee = _sellLiquidityFeeB;
                    _taxFee = _sellTaxFeeB;
                }   
                // setFee(sellnumber[from]);
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= _maxTxAmount)
        {
           contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            ProjectFundingEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesEnabled){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
        restoreAllFee;
    }
        function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        // check tokens in contract
        uint256 tokensbeforeSwap = contractTokenBalance;
        
        // swap tokens for BNB
        swapTokensForBNB(tokensbeforeSwap); // <- this breaks the BNB -> swap when swap+liquify is triggered
        
        uint256 BalanceBNB = address(this).balance;

        // calculate the percentages
        uint256 marketingBNB = BalanceBNB.div(100).mul(_marketingFee);
        uint256 buybackBNB = BalanceBNB.div(100).mul(_buybackFee);      

        //pay the marketing wallet
        payable(_marketingWallet).transfer(marketingBNB);

        //pay the buyback wallet
        payable(_buybackWallet).transfer(buybackBNB);

        emit SwapAndLiquify(tokensbeforeSwap, _marketingWallet, marketingBNB, _buybackWallet, buybackBNB);  

    }
    function swapTokensForBNB(uint256 tokenAmount) private {
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
            owner(),
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, recipient);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, recipient);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, recipient);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, recipient);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, address to) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, to);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, address to) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount, to);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
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
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        if (isTrade) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity); 
        } else {
            _rOwned[address(_communityRewardsWallet)] = _rOwned[address(_communityRewardsWallet)].add(rLiquidity);
            emit TokensSentToCommunityWallet (_communityRewardsWallet, rLiquidity);

            if(_isExcluded[address(_communityRewardsWallet)])
            _tOwned[address(_communityRewardsWallet)] = _tOwned[address(_communityRewardsWallet)].add(tLiquidity); 
            emit TokensSentToCommunityWallet (_communityRewardsWallet, tLiquidity);
        }
    }
    
    function calculateTaxFee(uint256 _amount, address to) private view returns (uint256) {
        if (startDate > block.timestamp || _taxFee == 0 || to != address(uniswapV2Pair)) {
            return _amount.mul(_taxFee).div(
                10**_decimals
            );
        }
        return _amount.mul(_taxFee).div(
            10**_decimals
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**_decimals
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function checkAntiDumpEnabled() public view returns (bool) {
    return antiDumpEnabled;
    }
    function A_setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() { 
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    emit MaxTxAmountUpdated(_maxTxAmount);
    }
    function E1_enableFees(bool truefalse) external onlyOwner() {
        feesEnabled = truefalse;
    }
    function E2_enable_ProjectFunding(bool truefalse) public onlyOwner {
        ProjectFundingEnabled = truefalse;
        emit ProjectFundingEnabledUpdated(truefalse);
    }
    function E3_enableAntiDump(bool onoff) external onlyOwner() {
        antiDumpEnabled = onoff;
    }
    function E4_enableTrading(bool truefalse) external onlyOwner() {
        tradingEnabled = truefalse;
    }
    function F01_setMarketingFee(uint256 marketingfee) external onlyOwner() {
        _marketingFee = marketingfee;
    }
    function F02_setBuyBackfee(uint256 buybackfee) external onlyOwner() {
        _buybackFee = buybackfee;
    }
    function F06_setBuyTaxfee(uint256 buyTaxFee) external onlyOwner() {
        _buyTaxFee = buyTaxFee;
    }
    function F07_setTaxFee(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    function F08_setProjectFee(uint256 ProjectFee) external onlyOwner() {
        _liquidityFee = ProjectFee;
    }
    function F09_setSellTaxFeeA(uint256 sellTaxFeeA) external onlyOwner() {
        _sellTaxFeeA = sellTaxFeeA;
    }
    function F10_setSellTaxFeeB(uint256 sellTaxFeeB) external onlyOwner() {
        _sellTaxFeeB = sellTaxFeeB;
    }
    function F11_setTransferTaxFee(uint256 transferTaxFee) external onlyOwner() {
        _transferTaxFee = transferTaxFee;
    }
    function F12_setBuyProjectFee(uint256 buyProjectFee) external onlyOwner() {
        _buyLiquidityFee = buyProjectFee;
    }
    function F13_setSellProjectFeeA(uint256 sellProjectFeeA) external onlyOwner() {
        _sellLiquidityFeeA = sellProjectFeeA;
    }
    function F14_setSellProjectFeeB(uint256 sellProjectFeeB) external onlyOwner() {
        _sellLiquidityFeeB = sellProjectFeeB;
    }
    function F15_setTransferProjectFee(uint256 transferProjectFee) external onlyOwner() {
        _transferLiquidityFee = transferProjectFee;
    }
    function F16_setExchangeTaxFee(uint256 exchangeTaxFee) external onlyOwner() {
        _exchangeTaxFee = exchangeTaxFee;
    }
    function F17_setExchangeProjectFee(uint256 exchangeProjectFee) external onlyOwner() {
        _exchangeLiquidityFee = exchangeProjectFee;
    }
    function I1_setImpact1(uint256 impact1) external onlyOwner {
        _impact1 = impact1;
    }
    function I2_setImpact2(uint256 impact2) external onlyOwner {
        _impact2 = impact2;
    }
    function I3_setMaxSellAttempts(uint256 maxSellAttempts) external onlyOwner() {
        _maxSellAttempts = maxSellAttempts;
    }
    function I4_setSellWindow(uint256 sell_Window) external onlyOwner() {
        _sell_Window = sell_Window;
    }
    function I5_setSellInitialWait(uint256 sell_InitialWait) external onlyOwner() {
        _sell_InitialWait = sell_InitialWait;
    }
    function I6_setSellFurtherWait(uint256 sell_FurtherWait) external onlyOwner() {
        _sell_FurtherWait = sell_FurtherWait;
    }
    function S01_includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function S02_excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function S03_includeInReward(address account) external onlyOwner() {
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
        function S04_excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function S05_addToBlacklist(address _address) public onlyOwner {
        require(!_isBlacklisted[_address], "Address is already blacklisted");
        _isBlacklisted[_address] = true;
    }
    function S06_removeFromBlacklist(address _address) public onlyOwner {
        require(_isBlacklisted[_address], "Address is already whitelisted");
        _isBlacklisted[_address] = false;
    }
    function S07_addAllowedExchange(address _address) public onlyOwner {
        require(!AllowedExchanges[_address], "Cannot add Exchange, it is already in the list");
        AllowedExchanges[_address] = true;
    }
    function S08_removeAllowedExchange(address _address) public onlyOwner {
        require(AllowedExchanges[_address], "Cannot remove Exchange, it is not in the list ");
        AllowedExchanges[_address] = false;
    }
    function S09_isAllowedExchange(address _address) public view returns(bool) {
        return AllowedExchanges[_address];
    }
    function S10_addBridge(address _address, bool Allowed_Bridges, uint256 liq_fee, uint256 tax_fee) public onlyOwner {
        AllowedBridges[_address] = Allowed_Bridges;
        BridgeLiquidityFee[_address] = liq_fee;
        BridgeTaxFee[_address] = tax_fee;
    }
    function S11_removeBridge(address _address) public onlyOwner {
        delete AllowedBridges[_address];
        delete BridgeLiquidityFee[_address];
        delete BridgeTaxFee[_address];
    }
    function W1_setMarketingWallet(address _address) public onlyOwner() {
        _marketingWallet = _address;
    }
    function W2_setBuybackWallet(address _address) public onlyOwner() {
        _buybackWallet = _address;
    }
    function W3_setCommunityrewardsWallet(address _address) public onlyOwner() {
        _communityRewardsWallet = _address;
    }
    function W3_setMigrationsWallet(address _address) public onlyOwner() {
        _migrationWallet = _address;
    }
    function getAllowedBridges(address _address) public view returns(bool) {
        return AllowedBridges[_address];
    }
    function getBridgeLiquidityFee(address _address) public view returns(uint256) {
        return BridgeLiquidityFee[_address];
    }
    function getBridgeTaxFee(address _address) public view returns(uint256) {
        return BridgeTaxFee[_address];
    }
    function get_HodlingUnixTimeAndDays(address account) public view returns(uint256, uint256) {
        uint256 HodlingInSecs = block.timestamp - HodlingStartTime[account];
        uint256 HodlingDays = HodlingInSecs / 1 days;
        return (HodlingInSecs, HodlingDays);
    }    
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}