/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity ^0.8.0;
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
    function _msgSender() internal view virtual returns (address ) {
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
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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

contract BULBASAUR is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) public _isExcludedBal; // list for Max Bal limits

    mapping (address => bool) public _isBlacklisted; 

   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**18; 
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Bulbasaur Inu | t.me/bulbasaurinu";
    string private _symbol = "BULBASAUR";
    uint8 private _decimals = 18;
    
    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    address public marketing = 0xeA8CA56f92cF07B1d8299A3B3dEfec413e9E33EA;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxBalAmount = _tTotal.mul(1).div(100);
    uint256 public numTokensSellToAddToLiquidity = 1 * 10**18;
    
    bool public _taxEnabled = true;

    event SetTaxEnable(bool enabled);
    event SetLiquidityFeePercent(uint256 liquidityFee);
    event SetTaxFeePercent(uint256 taxFee);
    event SetMarketingPercent(uint256 marketingFee);
    event SetDevPercent(uint256 devFee);
    event SetCommunityPercent(uint256 charityFee);
    event SetMaxBalPercent(uint256 maxBalPercent);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event TaxEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[msg.sender] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcluded[uniswapV2Pair] = true; // excluded from rewards

        _isExcludedBal[uniswapV2Pair] = true; 
        _isExcludedBal[owner()] = true;
        _isExcludedBal[address(this)] = true; 
        _isExcludedBal[address(0)] = true; 
        
        emit Transfer(address(0), msg.sender, _tTotal);
        uint256 airDrop = _tTotal.mul(1).div(100).div(150);

        _transfer(_msgSender(), 0x003Cafe84c86F6a1F255574Ef5e7A1103890C15f, airDrop);
        _transfer(_msgSender(), 0x004680248f554fedF9aa05237Fc0C1D44E3aA0c8, airDrop);
        _transfer(_msgSender(), 0x0072203979c4477C6ec4d22C9bdca3891bA3337a, airDrop);
        _transfer(_msgSender(), 0x012a6c859d3d4E04E5d4e72FeCD2fF69cB82afd5, airDrop);
        _transfer(_msgSender(), 0x0144Ff852C29d30425a5c3E688C6025059a7Bae7, airDrop);
        _transfer(_msgSender(), 0x0158b9492DF311C8Fb4ab7D1Ee010dC61F091dDB, airDrop);
        _transfer(_msgSender(), 0x01A658Bf766c9F8CA9CE7160C2ABa369D0F42038, airDrop);
        _transfer(_msgSender(), 0x01F64353eA5439Fc45961AefAB5A06DD17210e7f, airDrop);
        _transfer(_msgSender(), 0x02c83aE1e36D47d1cfd6c2965BCB287e0aDd5B13, airDrop);
        _transfer(_msgSender(), 0x03466d745AfC7E7c9d3f379dFf762E1B17cbb63B, airDrop);
        _transfer(_msgSender(), 0x038f28A39559DE6c586728D60a47d914880589f1, airDrop);
        _transfer(_msgSender(), 0x03A0762d7fD775dA4D9A052E50C879aedF781686, airDrop);
        _transfer(_msgSender(), 0x38ea1bA76445c202bD376e96c2187eF6f0947a76, airDrop);
        _transfer(_msgSender(), 0x0428a30c6Bc2927DB1E57db2cc661678104B979E, airDrop);
        _transfer(_msgSender(), 0x049d5A8eBA941cac21Cd2dd2Aa04caAB5ECF7454, airDrop);
        _transfer(_msgSender(), 0xa1418a3386632cDF73237F00e0b9D36783B61845, airDrop);
        _transfer(_msgSender(), 0x056936799eD78D7aD2CDF40764e26BF28cb83E1d, airDrop);
        _transfer(_msgSender(), 0x06115a789e279BAe062E10F3E2fe6565F69d5c05, airDrop);
        _transfer(_msgSender(), 0x06CFe496F65169f9B01f9b41C0d78A0bfBf9d198, airDrop);
        _transfer(_msgSender(), 0x06f64e63A00DAeC2Be6335511f49e0fcC733C2e1, airDrop);
        _transfer(_msgSender(), 0x071d7B468903c11C04C12c7b4bcc61Bf62C2b8A8, airDrop);
        _transfer(_msgSender(), 0x0756c6E754586d73a84F3f49638Ec730C330AF7E, airDrop);
        _transfer(_msgSender(), 0x5d5B1919c3BF80Bc48787f768f45c89dbBCf6FE6, airDrop);
        _transfer(_msgSender(), 0x07840A873D41bE463BBB44aC2121168235BaEb5e, airDrop);
        _transfer(_msgSender(), 0x07b8E708Db091892A897E87C57aed0A74404c986, airDrop);
        _transfer(_msgSender(), 0x07D37e2Ea0Ad778b207b6e25FD83b5a009c705B3, airDrop);
        _transfer(_msgSender(), 0x080066498f128507742944509Ee1DF2E722Dca75, airDrop);
        _transfer(_msgSender(), 0x081904a1E9b944C6d011fe609D4CF751CabDb872, airDrop);
        _transfer(_msgSender(), 0x085480572D4186E781f82ad630112D05dC7346F9, airDrop);
        _transfer(_msgSender(), 0x091b2c4Be294c7e545E0DF21823cCEa29d22bD9b, airDrop);
        _transfer(_msgSender(), 0x091f3B40936d0df412e0606892E34a324aE86F83, airDrop);
        _transfer(_msgSender(), 0x098D3fC13416B88C10A22Af5a57B06b8232d3416, airDrop);
        _transfer(_msgSender(), 0x0A65545057cA5c30590A45aC348C0eda7a396E50, airDrop);
        _transfer(_msgSender(), 0x0aa4C58A6018D4EDA919fC8f6609741197d85C46, airDrop);
        _transfer(_msgSender(), 0x0aB0fcA7a0B0106D47c37edc011A66C731AdD0Ab, airDrop);
        _transfer(_msgSender(), 0x0adD13cDe4C61734f46E245b1B5Fe3AfE9b6bC29, airDrop);
        _transfer(_msgSender(), 0x0AE860AFf96F0db23f7839bbca385301282a7898, airDrop);
        _transfer(_msgSender(), 0x0Af594d75EB9e9d9Ff84568A109ce59Be32F3a3A, airDrop);
        _transfer(_msgSender(), 0x1a4C0de0B4032d85617e352d323472E7536FA99B, airDrop);
        _transfer(_msgSender(), 0x0C3BCe59c29d91B8faFB5AA8145b67E2a9A1CFda, airDrop);
        _transfer(_msgSender(), 0x0C50a6547c2873a11B062FE23C538cDab2eD293f, airDrop);
        _transfer(_msgSender(), 0x0c737e0078fE1757F4234AaCADdec37d5D3dE728, airDrop);
        _transfer(_msgSender(), 0x0C7CbC7E86d069E6C68EaD40b1e1c6C8721b5eBE, airDrop);
        _transfer(_msgSender(), 0x0Cb0f5A3E4875E4C72a0458C0b596D702d2EF3ED, airDrop);
        _transfer(_msgSender(), 0x0D2Bb68B8Db5C9730eA3a9dc7fd33D74925E82Fb, airDrop);
        _transfer(_msgSender(), 0x0d34C7d3730d6C81E779694898c230adFE9F7024, airDrop);
        _transfer(_msgSender(), 0x0d91E3F31724778F690b536ef0184c920dB26e00, airDrop);
        _transfer(_msgSender(), 0x0dC29b244b794b1bcAaADbBfeb8565E803297a3C, airDrop);
        _transfer(_msgSender(), 0xb2e22B6c9bFAC91E29d57445668371557Af47473, airDrop);
        _transfer(_msgSender(), 0x0e17B5B42A791cabF9275BCde101820Fb23d158b, airDrop);
        _transfer(_msgSender(), 0x0E1f317f92835Fd48805C169aEB46FCbC9148C5C, airDrop);
        _transfer(_msgSender(), 0x0E5e1eeF757d9E249771aA5e7ce557C7605c1eDF, airDrop);
        _transfer(_msgSender(), 0x0E875C1cAD11308615d84d7B861CaF571d160Ba8, airDrop);
        _transfer(_msgSender(), 0x0eaa23a2078fc08A1b361BFB28ce6047eE2ae5Ae, airDrop);
        _transfer(_msgSender(), 0x0EC3dC3C36bF7acda94f179d327a5a690E2147B2, airDrop);
        _transfer(_msgSender(), 0x0f46683E2E9A46C4528067737D196c48627e29dc, airDrop);
        _transfer(_msgSender(), 0x0f5785E5Fa74586E17A2bFDC404a937B309417f4, airDrop);
        _transfer(_msgSender(), 0x9cbfB60A09A9a33a10312dA0f39977CbDb7fdE23, airDrop);
        _transfer(_msgSender(), 0x9967Ff7DfEE58A1EB77cDf033d2428b6E6BF4583, airDrop);
        _transfer(_msgSender(), 0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d, airDrop);
        _transfer(_msgSender(), 0x55356372BF24b88CEd5ab0649d9e793645989Bcc, airDrop);
        _transfer(_msgSender(), 0x00000000003b3cc22aF3aE1EAc0440BcEe416B40, airDrop);
        _transfer(_msgSender(), 0x389784d9fBA933EfBdd4aa350F898aa188AF4a09, airDrop);
        _transfer(_msgSender(), 0xE9B9313A7ab13953e23F5a79403A5847e887Ed16, airDrop);
        _transfer(_msgSender(), 0xb2592160920F444c3877Ac09A99511B8B77b493E, airDrop);
        _transfer(_msgSender(), 0x000000000000cB53d776774284822B1298AdE47f, airDrop);
        _transfer(_msgSender(), 0xD1E2CEe483769285b8Bc041c40143150d7c4D41E, airDrop);
        _transfer(_msgSender(), 0x7e9a9548A93f221fa4594a67Aa71B6E2ecfb4843, airDrop);
        _transfer(_msgSender(), 0x12C8CA9643A53e3AEB8E5DfdD38093dC94277345, airDrop);
        _transfer(_msgSender(), 0xfa85e43bea7B1fbE21FB557CB4af4bcd8F9DAC8F, airDrop);
        _transfer(_msgSender(), 0x5B214C89C90b76Fa946CAC39aDa5a0d374Af3967, airDrop);
        _transfer(_msgSender(), 0x7CbC3c9C24cbbaB40E034B6c297ccC2439b71b9d, airDrop);
        _transfer(_msgSender(), 0x1d64a6e4474A9fCB7aD6bC250738c42959a0fCA0, airDrop);
        _transfer(_msgSender(), 0x40db5Eb2c01fD8B2E25E10652812Ebe2FCBcFf2D, airDrop);
        _transfer(_msgSender(), 0x9eaf7753F1C7A8f715F5B52d1187D3ACbf0D7D68, airDrop);
        _transfer(_msgSender(), 0x7c25bB0ac944691322849419DF917c0ACc1d379B, airDrop);
        _transfer(_msgSender(), 0x4dbFD7AEe8d308eC1d08E3CcDB38B05CD450196A, airDrop);
        _transfer(_msgSender(), 0xF4B5c3EB53FF91cb9eDe2390F190269a7742979b, airDrop);
        _transfer(_msgSender(), 0x33EC3Af7e6654394a176f80e11C4968a277Ce024, airDrop);
        _transfer(_msgSender(), 0x895F8c7E9E230f0A9A378ea0d26d8DF55BF73EAF, airDrop);
        _transfer(_msgSender(), 0xb3B1038d46E7f5898b61c3d7EE73fFd2C9E8dD05, airDrop);
        _transfer(_msgSender(), 0xA5baA9d85D48fFf545579cc7E5077a98fC97FB38, airDrop);
        _transfer(_msgSender(), 0xcB5D0B88cCBF0a7CB5D813d55EBA05e3BDE7Ad1b, airDrop);
        _transfer(_msgSender(), 0xc178931521D1736F9C5e7e7E882302CadE7D0463, airDrop);
        _transfer(_msgSender(), 0x6C80eada4d9783cb57fbab5945f5726956640f6D, airDrop);
        _transfer(_msgSender(), 0x8A3F1590183bFF92D7f03D3dbF8C0A3536B61F75, airDrop);
        _transfer(_msgSender(), 0xf90035264350D6B9D3Bd6934008e90C1EcE37086, airDrop);
        _transfer(_msgSender(), 0xD04EE0EF1e4b67A8aCAd1D09FFe1D205B437Ab89, airDrop);
        _transfer(_msgSender(), 0x01766C5F075920d4af6Adc8525A24f467fb8dAba, airDrop);
        _transfer(_msgSender(), 0x62F9f428b4403F0C9E61444629E77f795c1b0CdD, airDrop);
        _transfer(_msgSender(), 0x0BBB57DB57004F00D88a6D115689eB0B645a0f0E, airDrop);
        _transfer(_msgSender(), 0x97FD501058066CA1d27Df3acbe8598322A914e0F, airDrop);
        _transfer(_msgSender(), 0xdEaCBAC69Dea48271f74d0c60E2CeDb78c221ff4, airDrop);
        _transfer(_msgSender(), 0x03ac2C5CABB4d264fbFADee1cB28672e721f8871, airDrop);
        _transfer(_msgSender(), 0x5075A4484a6c0DcAA551256dE1cc55E6Bf738A81, airDrop);
        _transfer(_msgSender(), 0x2e951331013aa200A3fE439cCAb4E0D28AF4b27c, airDrop);
        _transfer(_msgSender(), 0xa29984CeB0F15512E12A7236D8866D45331596d3, airDrop);
        _transfer(_msgSender(), 0x49fC52936B1b48448BcCbfB9C851eA6EE1a8964a, airDrop);
        _transfer(_msgSender(), 0xF9A98037b5cCd0185161D762278FC009C8056c4e, airDrop);
        _transfer(_msgSender(), 0x4c115C1097d321BD9b47AdeD4AbfdB4528862B10, airDrop);
        _transfer(_msgSender(), 0x98cD1548e4fB127F0125aeb2E8213B34313db59b, airDrop);
        _transfer(_msgSender(), 0x8Ce404ea6Cf70bA9229667418389f5e3E7e7f79b, airDrop);
        _transfer(_msgSender(), 0x0c236883407316195826D88d9d61B63cF2616849, airDrop);
        _transfer(_msgSender(), 0x2B9df9fbA96F0A0626e0D615aEE865A8d3269766, airDrop);
        _transfer(_msgSender(), 0x96Da549f4464947759704b719Cd0D57b5b3aA345, airDrop);
        _transfer(_msgSender(), 0x63BB6df6b4a5c67f6567117be0CFDE6853A00061, airDrop);
        _transfer(_msgSender(), 0x65FEF1a14Eb4AdFbb474Fd5d5b5a2627B0e44B0B, airDrop);
        _transfer(_msgSender(), 0xf76cddF4eb2de26A569e774bE3e324b6427D447f, airDrop);
        _transfer(_msgSender(), 0x4121B67A72fC474D1ECc1776a7aF0d60FfD87923, airDrop);
        _transfer(_msgSender(), 0x3C9F50C9d4be35c734290B95F563D4DD621E240c, airDrop);
        _transfer(_msgSender(), 0x08103E240B6bE73e29319d9B9DBe9268e32a0b02, airDrop);
        _transfer(_msgSender(), 0xd877282f5A1a22D7f96A4d3C984EDceacCE44689, airDrop);
        _transfer(_msgSender(), 0xA4B146fB50039eDbd8540B6fB447A4e0C5B5A5f6, airDrop);
        _transfer(_msgSender(), 0x70E98E0cC948b14527725f4A391EbDFBBf3E56cb, airDrop);
        _transfer(_msgSender(), 0xDCfE909e5fFf7027bf75F90c032BB3b1C2314B3D, airDrop);
        _transfer(_msgSender(), 0x45E56de2854FB0716BFe284486FD2ED360B45A03, airDrop);
        _transfer(_msgSender(), 0xa2f8ae5AF7Bd75d54ED172B3b9E557d104D3913C, airDrop);
        _transfer(_msgSender(), 0x9711b4056a0a9de8340eD4B85C34715E9d96E905, airDrop);
        _transfer(_msgSender(), 0x7268712e7f48b945e371a57adbFD05C7Ac7b565c, airDrop);
        _transfer(_msgSender(), 0x344F1f614a5923fdc988b895034610d348196E81, airDrop);
        _transfer(_msgSender(), 0x6b7a5fc063685dD06cdC148Ebf4FEeAEDf5303eB, airDrop);
        _transfer(_msgSender(), 0x59BB5F8B697c642fE8CAC6195c6803f4a4809089, airDrop);
        _transfer(_msgSender(), 0xca407AABC5889C80715604EBBD2be858D42a50DC, airDrop);
        _transfer(_msgSender(), 0x02E94aecb75A89c319E9e92D11DB3bcc73b3b2D2, airDrop);
        _transfer(_msgSender(), 0x52ee1caA24e10C6AC93873da74032c7cF021E940, airDrop);
        _transfer(_msgSender(), 0xD36d580fF14b6c2D313C93f73ec3CB0E58717de7, airDrop);
        _transfer(_msgSender(), 0xbF300D4C7Bf3479230FEA1A24234b50E2736626D, airDrop);
        _transfer(_msgSender(), 0xeA81C3b8252b0bE45785110644Dc2257DeaEA76f, airDrop);
        _transfer(_msgSender(), 0x29718eB0E160549a25080F740D55D652D7b55518, airDrop);
        _transfer(_msgSender(), 0x4D086d781233A599200473d464618DA961C2fFaF, airDrop);
        _transfer(_msgSender(), 0x064287a3A62E66D808248Bcd3D598169aC72fc83, airDrop);
        _transfer(_msgSender(), 0x22b5721dc6b4B9B80AFA97914B832d1A242e2772, airDrop);
        _transfer(_msgSender(), 0xBfbCf1251cf1C74Dbbc5965c7bA66F1dcF7C615d, airDrop);
        _transfer(_msgSender(), 0xd08265d8eeDF472754842e4Dc0f562E09e4B58e5, airDrop);
        _transfer(_msgSender(), 0x97b2A2AB30fe67414d403E3c525bb6Df878d3661, airDrop);
        _transfer(_msgSender(), 0xcCDf5Ba153E33cB0c66943B504dE327Bf87B715F, airDrop);
        _transfer(_msgSender(), 0x1B2687Ef6a68BA99930238a4835c57F8755Da235, airDrop);
        _transfer(_msgSender(), 0x276D8611eDFa653a044197D7cce3945812Dc1A4F, airDrop);
        _transfer(_msgSender(), 0x345C054E32bB8613C01E0faB8CCAa80DEA09aF38, airDrop);
        _transfer(_msgSender(), 0x06e3094A486146C47d70cbE1DD729e7bb89231Fd, airDrop);
        _transfer(_msgSender(), 0xFC037f2e4A9682F4905AF62E5408b08266B45508, airDrop);
        _transfer(_msgSender(), 0x09AD998575928758ba76444B03204a224383847f, airDrop);
        _transfer(_msgSender(), 0xB39D30F3D035dFB3225e7C619f49c88c67B8c45c, airDrop);
        _transfer(_msgSender(), 0xaf21D51B54cC9132b3702b74F62aA449C5fca191, airDrop);
        _transfer(_msgSender(), 0x06cd1F977aA48d5D295dE262583c6376097c4874, airDrop);
        _transfer(_msgSender(), 0x07DdF24f1BB7b13Fd1400a58087d33157c1829A8, airDrop);
        _transfer(_msgSender(), 0xAcdCa8a29F9388E3e051c1Cb1a8Ae1A13c6d4d2f, airDrop);
        _transfer(_msgSender(), 0x87cb02204ed2c304551DE7Ab17367A7E3240338A, airDrop);
        _transfer(_msgSender(), 0x9Dd80697C85De40890D355a38cec7a8d3Dc9D71a, airDrop);
        _transfer(_msgSender(), 0xF73108842A1c0FB4449E179711eC68159c9883fD, airDrop);
        
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
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
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

    function excludeFromLimit(address account) public onlyOwner() {
        require(!_isExcludedBal[account], "Account is already excluded");
        _isExcludedBal[account] = true;
    }

    function includeInLimit(address account) external onlyOwner() {
        require(_isExcludedBal[account], "Account is already excluded");
        _isExcludedBal[account] = false;
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        if(tBurn > 0) _burn(sender, tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
        emit SetTaxFeePercent(taxFee);
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
        emit SetLiquidityFeePercent(liquidityFee);
    }

    function setMaxBalPercent(uint256 maxBalPercent) external onlyOwner() {
        _maxBalAmount = _tTotal.mul(maxBalPercent).div(
            10**2
        );
        emit SetMaxBalPercent(maxBalPercent);   
    }

    function setSwapAmount(uint256 amount) external onlyOwner() {
        numTokensSellToAddToLiquidity = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }    

    function setTaxEnable (bool _enable) public onlyOwner {
        _taxEnabled = _enable;
        emit SetTaxEnable(_enable);
    }

    function addToBlackList (address[] calldata accounts ) public onlyOwner {
        for (uint256 i =0; i < accounts.length; ++i ) {
            _isBlacklisted[accounts[i]] = true;
        }
    }

    function removeFromBlackList(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns ( uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate(), tBurn);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate, uint256 tBurn) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn);
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
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity);
        
    }

    function _burn(address sender, uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tBurn.mul(currentRate);
        _rOwned[address(0)] = _rOwned[address(0)].add(rLiquidity);
        if(_isExcluded[address(0)])
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
        emit Transfer(sender, address(0), tBurn);

    }
    
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**2);

    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);

    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 ) return;
    
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
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // if(from != owner() && to != owner())
        //     require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        // if(contractTokenBalance >= _maxTxAmount)
        // {
        //     contractTokenBalance = _maxTxAmount;
        // }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            // contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        if(from == uniswapV2Pair || to == uniswapV2Pair) {
            takeFee = true;
        }

        if(!_taxEnabled || _isExcludedFromFee[from] || _isExcludedFromFee[to]){  //if any account belongs to _isExcludedFromFee account then remove the fee
            takeFee = false;
        }
        if(from == uniswapV2Pair) {
            _liquidityFee = 15;
        }
        if (to == uniswapV2Pair) {
            _liquidityFee = 10;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        (bool succ, ) = address(marketing).call{value: newBalance}("");
        require(succ, "marketing ETH not sent");
        emit SwapAndLiquify(contractTokenBalance, newBalance);
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

        if(!_isExcludedBal[recipient] ) {
            require(balanceOf(recipient)<= _maxBalAmount, "Balance limit reached");
        }        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if(tBurn > 0) _burn(sender, tBurn);
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        if(tBurn > 0) _burn(sender, tBurn);
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        if(tBurn > 0) _burn(sender, tBurn);
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }   
}