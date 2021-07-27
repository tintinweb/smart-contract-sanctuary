/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity 0.7.4;


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

abstract contract Ownable is Context {
    address private _owner;

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        address sender = _msgSender();
        require(authorized[sender] || sender == owner(), "must have privileges");
        _;
    }

    function addAuthorized(address account) onlyOwner public returns (bool) {
        require(account != address(0), "must not be the zero address");
        authorized[account] = true;
        return true;
    }
    function removeAuthorized(address account) onlyOwner public returns (bool) {
        require(account != address(0), "must not be the zero address");
        require(account != _msgSender(), "must not be the owner");
        authorized[account] = false;
        return true;
    }
}

contract Reflective is IERC20, Authorizable {
    using SafeMath for uint256;
    using Address for address;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    address payable public constant reserve = payable(0x28DF4808FD9aa4dedc9b5f73141Fd0Df79c2542a); 

    mapping (address => bool) private _isBlacklisted;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    address[] private _excluded;
    address   private _star;
    
    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _DENOMINATOR = 100;
    uint256 private constant _PRECISION = 100;

    uint256 private constant _tTotal = 1000000000000 * 10**8;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;

    string  private constant _NAME = "SURGE";
    string  private constant _SYMBOL = "SURGE";
    uint8   private constant _DECIMALS = 8;

    uint256 private _taxFee = 1;
    uint256 private _reserveFee = 2;
    uint256 private _swapFee = 13;
    
    uint256 private _maxTxAmount = 5000000000 * 10**8;

    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousSwapFee = _swapFee;

    uint256 private _minimumAccumulationForBooster = 300000000 * 10**8; 
    uint256 private _minimumAccumulationForLiquidity = 250000000 * 10**8;
    
    uint256 private _boosterCeiling = 1 * 10**18;
    uint256 private _boosterFloor   = 1 * 10**18;
    uint256 private _boosterDivisor = 100;
    
    uint256 private _boosterRequisite;

    bool private _inSwapAndLiquify;
    bool private _swapAndLiquifyEnabled;
    bool private _swapAndBoosterEnabled;
    bool private _maxTxEnabled;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndBoosterEnabledUpdated(bool enabled);
    
    event SwapETHForTokens(uint256 amountIn,address[] path);
    event SwapTokensForETH(uint256 amountIn,address[] path);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity);
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    function excludeBlacklist(address account) external onlyAuthorized {
        _isBlacklisted[account] = false;
    }
    function includeBlacklist(address account) external onlyAuthorized {
        _isBlacklisted[account] = true;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyAuthorized {
        require(taxFee <= 10, 
        "must not exceed 10 percent");
        
        _taxFee = taxFee;
    }
    function setSwapFeePercent(uint256 swapFee) external onlyAuthorized {
        require(swapFee <= 20, 
        "must not exceed 20 percent");
        
        _swapFee = swapFee;
    }
    function setReserveFeePercent(uint256 reserveFee) external onlyAuthorized {
        require(reserveFee <= 10, 
        "must not exceed 10 percent");
        
        _reserveFee = reserveFee;
    }

    function setStar(address star) external onlyAuthorized {
        _star = star;
    }
    function setMaxTx(uint256 maxTxAmount) external onlyAuthorized {
        _maxTxAmount = maxTxAmount;
    }
    function setMaxTxEnabled(bool state) external onlyAuthorized {
        _maxTxEnabled = state;
    }
    
    function setSwapAndLiquifyEnabled(bool state) external onlyAuthorized {
        _swapAndLiquifyEnabled = state;
        emit SwapAndLiquifyEnabledUpdated(state);
    }
    function setSwapAndBoostereEnabled(bool state) external onlyAuthorized {
        _swapAndBoosterEnabled = state;
        emit SwapAndBoosterEnabledUpdated(state);
    }

    function setMinimumAccumulationForBooster(uint256 min) external onlyAuthorized {
        _minimumAccumulationForBooster = min;
    }
    function setMinimumAccumulationForLiquidity(uint256 min) external onlyAuthorized {
        _minimumAccumulationForLiquidity = min;
    }
        
    function setBoosterCeiling(uint256 ceiling) external onlyAuthorized {
        _boosterCeiling = ceiling * 10**18;
    }
    function setBoosterFloor(uint256 floor) external onlyAuthorized {
        _boosterFloor = floor * 10**18;
    }
    function setBoosterRequisite(uint256 amount) external onlyAuthorized {
        _boosterRequisite = amount;
    }
    function setBoosterDivisor(uint256 divisor) external onlyAuthorized {
        _boosterDivisor = divisor;
    }

    function excludeFromReward(address account) external onlyAuthorized {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyAuthorized {
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
    
    function getTaxFee() external view returns (uint256) {
        return _taxFee;
    }   
    function getReserveFee() external view returns (uint256) {
        return _reserveFee;
    }   
    function getSwapFees() external view returns (uint256) {
        return _swapFee;
    }   
    function getMaxTx() external view returns (uint256) {
        return _maxTxAmount;
    }   
    
    function getBoosterSizeValue() external view returns (uint256) {
        uint256 balance = address(this).balance;
        
        if (balance > _boosterFloor) {
            if (balance > _boosterCeiling) { 
                return _boosterCeiling.div(_boosterDivisor);
            } else {  
                return balance.div(_boosterDivisor); 
            }
        } else {
            return 0;
        }
    }
    function getBoosterSizePercent() external view returns (uint256) {
        return (_DENOMINATOR.mul(_PRECISION)).div(_boosterDivisor);
    }
    function getBoosterFloor() external view returns (uint256) {
        return _boosterFloor;
    }   
    function getBoosterCeiling() external view returns (uint256) {
        return _boosterCeiling;
    }   
    function getBoosterDivisor() external view returns (uint256) {
        return _boosterDivisor;
    }   
    function getBoosterRequisite() external view returns (uint256) {
        return _boosterRequisite;
    }   
    function getBoosterReserve() external view returns (uint256) {
        return address(this).balance;
    }  
    
    function isLiquificationEnabled() external view returns (bool) {
        return _swapAndLiquifyEnabled;
    }   
    function isBoosterEnabled() external view returns (bool) {
        return _swapAndBoosterEnabled;
    }   
    function isMaxTxEnabled() external view returns (bool) {
        return _maxTxEnabled;
    }  
    
    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }  
    
    function excludeFromFee(address account) external onlyAuthorized {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) external onlyAuthorized {
        _isExcludedFromFee[account] = false;
    }

    function name() external view returns (string memory) {
        return _NAME;
    }
    function symbol() external view returns (string memory) {
        return _SYMBOL;
    }
    function decimals() external view returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external view override returns (uint256) {
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
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function transferBatch(address[] calldata recipients, uint256[] calldata amounts) external returns (bool) {
        require(recipients.length == amounts.length, 
        "Must be matching argument lengths");
        
        uint256 length = recipients.length;
        
        for (uint i = 0; i < length; i++) {
            require(transfer(recipients[i], amounts[i]));
        }
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function getMinimumAccumulationForBooster() external view returns (uint256) {
        return _minimumAccumulationForBooster;
    }
    function getMinimumAccumulationForLiquidity() external view returns (uint256) {
        return _minimumAccumulationForLiquidity;
    }

    function isOverBoosterRequisite(uint256 amount) public view returns (bool) {
        return amount >= _boosterRequisite; 
    }
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
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
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(!_isBlacklisted[from], "must not be blacklisted");
        require(!_isBlacklisted[to], "must not be blacklisted");

        
        if (_maxTxEnabled) {
                require(amount <= _maxTxAmount, 
                    "transfer amount exceeds the maximum tx amount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= (_minimumAccumulationForLiquidity.add(_minimumAccumulationForBooster));
        
        if(contractTokenBalance >= _maxTxAmount) 
            { contractTokenBalance = _maxTxAmount; }

        if (!_inSwapAndLiquify && _swapAndLiquifyEnabled && to == uniswapV2Pair) {
            
            if (overMinimumTokenBalance) {
                contractTokenBalance = _minimumAccumulationForBooster;
                _swapTokens(contractTokenBalance);   
                
                contractTokenBalance = _minimumAccumulationForLiquidity;
                _swapAndLiquify(contractTokenBalance);
            }
            
            uint256 balance = address(this).balance;
            
            if (_swapAndBoosterEnabled && balance > _boosterFloor && isOverBoosterRequisite(amount)) {
                
                if (balance > _boosterCeiling)
                    balance = _boosterCeiling;
                
                _swapAndBoost(balance.div(_boosterDivisor));
            }
        }
        
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function _swapAndBoost(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            _swapETHForTokens(amount);
        }
    }
    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function _swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        
        uint256 reserveFee = (transferredBalance.mul(_reserveFee)).div(100);
        _transferReserve(reserve, reserveFee);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    function _swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            _star, 
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            _removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            _restoreAllFee();
    }
    
    function _transferReserve(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSwap) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTokensForSwappingFees(tSwap);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSwap) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeTokensForSwappingFees(tSwap);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSwap) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeTokensForSwappingFees(tSwap);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSwap) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeTokensForSwappingFees(tSwap);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _takeTokensForSwappingFees(uint256 tSwap) private {
        uint256 currentRate =  _getRate();
        uint256 rSwap = tSwap.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rSwap);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tSwap);
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    function _removeAllFee() private {
        if(_taxFee == 0 && _swapFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousSwapFee = _swapFee;
        
        _taxFee = 0;
        _swapFee = 0;
    }
    function _restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _swapFee = _previousSwapFee;
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
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tSwap) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tSwap, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tSwap);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tSwap = _calculateSwapFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tSwap);
        return (tTransferAmount, tFee, tSwap);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tSwap, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rSwap = tSwap.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rSwap);
        return (rAmount, rTransferAmount, rFee);
    }
    
    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    function _calculateSwapFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_swapFee).div(
            10**2
        );
    }
    
}

contract Token is Reflective {
    using SafeMath for uint256;
    
    Outpost private _outpost;
    
    uint32  private constant _TERM      = 31536000 seconds;
    uint8   private constant _OFFSET    = 15 seconds;
    uint16  private constant _TERMINATE = 300 seconds;
    
    uint8   private constant _DENOMINATOR = 100;
    
    uint8   private _up = 8;
    uint8   private _cp = 25;
    uint8   private _rp = 4;
    
    uint256 private _COOLDOWN = 2700 seconds;
    uint256 private _mr = 500000000 * 10**8;
    
    uint256 private _genesis;
    bool    private _hp;

    uint256 private _unlockedLP;
    uint256 private _latest;
    
    event Surged(uint256 amount);
    event Rewarded(uint256 amount);
    
    constructor() {
        _hp = true;
        _genesis = _time();
        _unlockedLP = _genesis.add(_TERM);
    }

    receive () external payable {}
    
    function upsurge() external returns (bool) {
        require(balanceOf(_msgSender()) >= getMinimumRequisite(), 
        "must comply with minimum balance requirement");
        
        uint256 time = _time();
        uint256 clearance = getLatest().add(_COOLDOWN);
        
        require(time >= clearance, 
        "must wait for cooldown clearance");
        
        _latest = time;
        
        uint256 removeable = getCycledLP();
        
        _removeLP(removeable);
        IUniswapV2Pair(uniswapV2Pair).sync();
        
        uint surge = _outpost.recycle();

        emit Surged(surge);
        return true;
    }
 
    function unlockLP() external onlyAuthorized returns (bool) {
        require(_time() > _unlockedLP, 
        "must be in an unlockable state");
        
        uint256 amount = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).transfer(_msgSender(), amount);
        return true;
    }
    function unlockHP() external onlyAuthorized returns (bool) {
        require(_time() <= getGenesis().add(_TERMINATE), 
        "Must find a proper developer");
        
        _hp = false;
        return true;
    }
    
    function setOutpost(address payable outpost) external onlyAuthorized returns (bool) {
        _outpost = Outpost(outpost);
        return true;
    }
    function setMinimumRequisite(uint256 amount) external onlyAuthorized returns (bool) {
        _mr = amount;
        return true;
    }
    function setCooldown(uint256 cooldown) external onlyAuthorized returns (bool) {
        _COOLDOWN = cooldown;
        return true;
    }
    
    function setUP(uint8 amount) external onlyAuthorized returns (bool) {
        require(amount <= 10, 
        "must not exceed 10 percent");
        
        _up = amount;
        return true;
    }
    function setCP(uint8 amount) external onlyAuthorized returns (bool) {
        require(amount <= 100, //support for 0.X %, max of 1 %
        "must not exceed 10 percent");
        
        _cp = amount;
        return true;
    }
    function setRP(uint8 amount) external onlyAuthorized returns (bool) {
        require(amount <= 10, 
        "must not exceed 10 percent");
        
        _rp = amount;
        return true;
    }

    function getCooldown() external view returns (uint256) {
        return _COOLDOWN;
    }
    function getClearance() external view returns (uint256) {
        uint256 time = _time();
        uint256 latest = getLatest();
        uint256 next = latest.add(_COOLDOWN);
        if (next > time) { return next.sub(time); } else { return 0; }
    }
    
    function getUnlockedLPAt() external view returns (uint256) {
        return _unlockedLP;
    }

    function getLockedTokens() external view returns (uint256) {
        uint256 AMMBalance = balanceOf(uniswapV2Pair);
        
        uint256 LPTotal = IERC20(uniswapV2Pair).totalSupply();
        uint256 LPBalance = getLockedLP();
        uint256 LPTotalPercentage = LPBalance.mul(1e12).div(LPTotal);
        
        return AMMBalance.mul(LPTotalPercentage).div(1e12);
    }
    
    function getCycledLP() public view returns (uint256) {
        return (getRemoveableLP().mul(_up)).div(_DENOMINATOR);
    }
    function getLockedLP() public view returns (uint256) {
        return getRemoveableLP().add(getBurnedLP());
    }
    function getBurnedLP() public view returns (uint256) {
        return IERC20(uniswapV2Pair).balanceOf(address(0));
    }

    function getUP() external view returns (uint8) {
        return _up;
    }
    function getCP() external view returns (uint256) {
        return _cp;
    }
    function getRP() external view returns (uint8) {
        return _rp;
    }

    function getMinimumRequisite() public view returns (uint256) {
        return _mr;
    }
    function getLatest() public view returns (uint256) {
        return _latest;
    }
    function getGenesis() public view returns (uint256) {
        return _genesis;
    }
    function getHP() public view returns (bool) {
        return _hp;
    }

    function getRemoveableLP() private view returns (uint256) {
        return IERC20(uniswapV2Pair).balanceOf(_environment());
    }
    
    function _environment() private view returns (address) {
        return address(this);
    }
    function _time() private view returns (uint256) {
        return block.timestamp;
    }

    function _removeLP(uint256 amount) private returns (uint256) {
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), amount);
        
        (uint256 screwThisVariable) = IUniswapV2Router02(uniswapV2Router)
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                _environment(),
                amount,
                0,
                0,
                address(_outpost),
                _time() + _OFFSET);
    }
    
}

contract Outpost is Context {
    using SafeMath for uint256;   
    
    Token private _token;
    
    uint256 private constant _DENOMINATOR = 100;
    address payable private constant _RESERVE = 0x28DF4808FD9aa4dedc9b5f73141Fd0Df79c2542a;
    address public constant blackhole = 0x000000000000000000000000000000000000dEaD;
    
    constructor(address payable token) {
        _token = Token(token);
    }
    
    receive () external payable {}
    
    function recycle() external returns (uint256) { 
        require(_msgSender() == address(_token), 
        "must be called by the token");
        
        require(!_token.getHP(), 
        "must solve the problem on your own");
        
        address environment = _environment();
        _reposition(environment.balance);
        
        uint256 lockable = _token.balanceOf(environment);
        uint256 reward = ((lockable.mul(_token.getCP())).div(_DENOMINATOR)).div(_DENOMINATOR);
        uint256 burned = lockable.sub(reward);
        
        _token.transfer(tx.origin, reward);
        _token.transfer(blackhole, burned);
    
        return burned;
    }
    
    function _reposition(uint256 amount) private { 
        address[] memory uniswapPairPath = new address[](2);
        
        uniswapPairPath[0] = IUniswapV2Router02(_token.uniswapV2Router()).WETH();
        uniswapPairPath[1] = address(_token);
        
        uint256 rp = _token.getRP();
        uint256 reserve = (amount.mul(rp)).div(_DENOMINATOR);
        _RESERVE.transfer(reserve);
        
        _token.approve(address(_token.uniswapV2Router()), amount);
        
        IUniswapV2Router02(_token.uniswapV2Router())
        .swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount.sub(reserve)}(
                0,
                uniswapPairPath,
                _environment(),
                _time() 
                );
    }  
    function _environment() private view returns (address) {
        return address(this);
    }
    function _time() private view returns (uint256) {
        return block.timestamp;
    }
    
}