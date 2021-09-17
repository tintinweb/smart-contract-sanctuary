/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

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

contract TreatDaoContract is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    string private _name = "TREAT";
    string private _symbol = "TREAT";
    uint8 private _decimals = 18;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    bytes4[] public _NTFs;
    address[] public _included;
    mapping (address => bool) public _isIncludedForFee;
    
    //uint256 totalSupply_ = 125 * 10**6 * 10**18;
    uint256 private _tTotal = 125 * 10**6 * 10**18;
    
    uint256 public _taxFee = 100;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 100;
    uint256 private _previousLiquidityFee = _liquidityFee;

    address payable public treatTreasuryAddress;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public pancakeRouter;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 125 * 10**6 * 10**18;
    uint256 private numTokensSellToAddToLiquidity = 7340 * 5  * 10**18;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event RouterChanged(address newRouter);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor(address payable _pancakeRouter, address payable _TreatTreasuryAddress) public {
        balances[_msgSender()] = _tTotal;
        pancakeRouter = _pancakeRouter;
        treatTreasuryAddress = _TreatTreasuryAddress;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(pancakeRouter);
        //v2 pancake router 0x10ed43c718714eb63d5aa57b78b54704e256024e
        //v1 router 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //include pancake in fee
        _isIncludedForFee[pancakeRouter] = true;
        _included.push(pancakeRouter);
        
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
        return balances[account];
    }
    
    //function balanceOf(address tokenOwner) public view returns (uint) {
    //    return balances[tokenOwner];
    //}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    //function transfer(address receiver, uint numTokens) public returns (bool) {
    //    require(numTokens <= balances[msg.sender]);
    //    balances[msg.sender] = balances[msg.sender].sub(numTokens);
    //    balances[receiver] = balances[receiver].add(numTokens);
    //    emit Transfer(msg.sender, receiver, numTokens);
    //    return true;
    //}

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    //function allowance(address owner, address delegate) public view returns (uint) {
    //    return allowed[owner][delegate];
    //}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //function approve(address delegate, uint numTokens) public returns (bool) {
    //    allowed[msg.sender][delegate] = numTokens;
    //    emit Approval(msg.sender, delegate, numTokens);
    //    return true;
    //}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    //function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
    //    require(numTokens <= balances[owner]);    
    //    require(numTokens <= allowed[owner][msg.sender]);
    //
    //    balances[owner] = balances[owner].sub(numTokens);
    //    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    //    balances[buyer] = balances[buyer].add(numTokens);
    //    emit Transfer(owner, buyer, numTokens);
    //    return true;
    //}

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        for(uint256 i=0; i < _included.length; i++) {
            if(_included[i] == account) {
                _included[i] = _included[_included.length - 1];
                _included.pop();
                _isIncludedForFee[account] = false;
            }
        }
    }
    
    function includeInFee(address account) public onlyOwner {
        for(uint256 i=0; i<_included.length; i++) {
            require(_included[i] != account, "address tracked already");
        }
        _isIncludedForFee[account] = true;
        _included.push(account);
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
   
   //percent to two decimal precision so 100% = 10000
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function _sendFee(uint256 tFee) private {
        (bool success, ) = address(treatTreasuryAddress).call.value(tFee)("");
        require(success, "Transfer failed.");
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        balances[address(this)] = balances[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**4
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
        return !_isIncludedForFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function fb() public pure returns (bytes4) {
        return (bytes4(msg.data[0]) | bytes4(msg.data[1]) >> 8 |
            bytes4(msg.data[2]) >> 16 | bytes4(msg.data[3]) >> 24);
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

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        
        //if any account belongs to _isIncludedForFee account then add the fee
        if(_isIncludedForFee[from] || _isIncludedForFee[to]){
            takeFee = true;
            //if bytes4(msg.data) is a addliquidity or remove liquidity we remove the tax
            for (uint256 i=0; i < _NTFs.length; i++) {
                if(fb() == _NTFs[i]) {
                    takeFee = false;
                }
            }
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(half);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
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
        
        /*if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }*/
        _transferTreats(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }

    //transfer function
    function _transferTreats(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        balances[sender] = balances[sender].sub(tAmount);
        balances[recipient] = balances[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        _sendFee(tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*//taxed address to taxed address, may never fire or double fire...investigate more with 1inch
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        balances[sender] = balances[sender].sub(tAmount);
        balances[recipient] = balances[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        balances[sender] = balances[sender].sub(tAmount);
        balances[recipient] = balances[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        balances[sender] = balances[sender].sub(tAmount);
        balances[recipient] = balances[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        balances[sender] = balances[sender].sub(tAmount);
        balances[recipient] = balances[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }*/

    function setRouter(address _pancakeRouter) public onlyOwner {
        pancakeRouter = _pancakeRouter;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_pancakeRouter);
        emit RouterChanged(_pancakeRouter);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) public onlyOwner {
        require(_numTokensSellToAddToLiquidity > 10**16, "cannot set too low or to 0");
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }
    
    function harvestTreats(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    function withdraw(address _tokenAddress, address payable _to) onlyOwner public {
        uint balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_to, balance);
    }
    
    function treasury(address payable _treatTreasuryAddress) public onlyOwner {
        require(_treatTreasuryAddress != address(0), "cannot switch treasury to the zero address");
        treatTreasuryAddress = _treatTreasuryAddress;
    }

    function addNTF(bytes4 _ntfToAdd) public onlyOwner {
        for (uint256 i=0; i<_NTFs.length; i++) {
            require(_NTFs[i] != _ntfToAdd, "ntf being tracked already");
        }
            _NTFs.push(_ntfToAdd);
    }

    function removeNTF(bytes4 _ntfToRemove) public onlyOwner {
        for (uint256 i=0; i<_NTFs.length; i++) {
            if(_NTFs[i] == _ntfToRemove) {
                _NTFs[i] = _NTFs[_NTFs.length - 1];
                _NTFs.pop();
            }
        }
    }

}

/*

 SSSSSSSSSSSSS2Z ,,, ,..:  : :.  7  ,:.., i  ,, i. :..,  ,  i  :,  7   r  :  . , iriiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSSZi  . : :  i .   r  :,  . ,. .: .r .r ,,, ,.:. ,,  i,  7   i  , .  :riiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSSZ  . ,   i  . .:  :i  i...  i  r  r  : .,  :  r  i:  r  .r  ,  ..  ,riiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSS27,     .  , .. ,,  i  .. i  r, :. :.., , , i  .:  :.  i   :  ,    .7iiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSSS2Z88B87i,        :  .,.:  i  ,: ,. , ,.,  :  r. ::  i. .i  ..  .   7iiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSSSSXSXXS2ZZ8B827r7:,   .  .   i  , ,: . .. : :.  i  ,.  ,   :        7iiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSSSSXSXXXXXXXXSSS22287irrriiii:,,,,.., ,,.   ,  ,   .                 riiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSXSSXXXXXXXXXXXXXXXXSi,::::iiirrrii::, XXXXXX777X77i::::riirXXZBBBBB8rriiiiiiiiiiiiiiiiii
 SSSSSSSSSSSSXXSXXXXXXXXXXXXXXXXSr,:iiiiiiiiii::,, :7rirririiiii2BBBBBBBBBBB8822Zr:iiiiiiiiiiiiiiiiii
 SSSSSSSSSSXXXXXXXXXXXXXXXXXXXXXXX,:iiii:iiiii:::,..7iiriiirii:r88888ZZ88888ZZZ22X:iiiiiiiiiii:iiiiii
 SSSSSSSSSSSSXXXXSXXXXXXXXXXXXXXXX,iiii:iiiiii:::,, 7rriiiiiiii:288ZZZ8888888Z222X,iiiiiiiiiiiiiiiiii
 SSSSSSSSSSSXSXXXXXXXXXXXXXXXX777X:7XXSXXX77ri::,:, rriiiiiiiii,S2ZZ88ZZZ88888ZZ22,:iiiiiiiiiiiiiiiii
 SSSSSSSSXSSSSXXXXXXXXXXXXXXX77XXXrS2222222SSX7r:,, irriiiiiiii,X22ZZZ88Z88B88ZZ22::iiiiiiiiiiiiiiiii
 SSSSSSSSXXSXXXXXXXXXXXXXXX7XX7777i2ZZZZZZZZZ22X7i, ,riiiiiiiii,rZZZZZ8ZZZZB8ZZ222i:iiiiiiiiiiiiiiiii
 SSSSSSSSXSSXSXXXXXXXXXXXXXXX77777rX22Z2ZZZZZZ22SXi,:riiiiiiiii::Z22ZZ8ZZZZ8BZZ222i,:::::iiiiiiiiiiii
 SSSSSSXXSXXXXXXXXXXXXXXXXXXX77777r72ZZZZZZZZZZZ22X:,riiiiiiiii:,82ZZZZZZZZ8B82222r,iiiiiii::::::::::
 SSSSSSSXSXXXXXXXXXXXXXXX7777777777rS2ZZZ2ZZZZZZZ22i,iiiriiiiiii,22ZZZZ8ZZZ8BZ22227,iiiiiiiiiiiiiiiii
 SXSSSSSSSSXXXXXXXXXXXXX77777777777iS22ZZZ2ZZZZZZ22i:r:::iiiiiii,S22ZZZZZZZ8BZZZ227,iiiiiiiiiiiiiiiii
 SXSSSSXSXXXXXXXXXXXXXXXXX777777777i7Z222Z2ZZZZZZ2Z::iiiiiiii:::,rZZ2ZZ8ZZ88BZ22227,iiiiiiiiiiiiiiiii
 SSSSSXSSXXXXXXXXXXXX7X777777777777ri2222ZZZZZZZZ22:iiiiiiiiiiii:,2Z2ZZZZZZ8B8ZZ22X,iiiiiiiiiiiiiiiii
 SSSXSSXXXXXXXXXXXXXX7XXX77777777777i2Z222ZZZZZZZZ2::iiiiiiiiiiii,XZZZZZZZ8BBZZZ227,:iiiiiiiiiiiiiiii
 SSXSXSXXXXXXXXXXXXXX7X7777777777777r72222222ZZZ222i:iiiiiiiiiiii::ZZZZZZZZ888ZZ227,::::::::::::i:i:i
 SXSSXXXXXXXXXXXXXXXX777777777777777riSZ22ZZZZZZZ22r:iiiiiiiiiiiii.S2ZZZZZZ8B8ZZ227,:iiiiiiiii:ii:iii
 SSSXXXSXXXXXXXXXXXXXX777777777777rrri72Z2ZZZ2ZZZ2S7:iiiiiiiiiiiii,:ZZZZZZZ88ZZZZ27,iiiiiiiiiiiiii:ii
 XXSXXXXXXXXXXXXXXXXXXX777777777777rrriS22ZZZ2ZZZZ2X:iiiiiiiiiiiii:.SZZZZZZ888ZZ227,::iiiiiiiiiiiiiii
 XSXXXXXXXXXXXXXXXXXXXX777777777777rrri7Z88BB888ZSXr:iiiiiiiiiiiiii,iZ2ZZZZ8B8ZZ2ZX,:i:iiiiii:iiii::i
 XXXXXXXXXXXXXXXXXX777777777777777r7rrirSX77XXXXSSSS7iiiiiiiiiiiiii:,SZZZ8BBBBBB8Z7,::i:iiiii:iiii:ii
 XXXXXXXXXXXXXXX77XXXX77777777777rrrrrr7S7i.         iiiiiiiiiiiii::,rZ2SSXXXXXXSXr,::i:iiiii:iiii:ii
 XXXXXXXXXXXXXXXXX77777777777777rr7r7rri.:XZBBBBZ2S7r:iiiiiiiiiiiiii::22Sri,..,,iX27::iiiiii::i:ii:ii
 XXXXXXXXXXXXXXXXXX7777777777777rr7rrrrrSr,      .,,::iiiiiiiiiiiiii:ii  iS2B8ZS7:  :iiiiiii::i:ii:ii
 XXXXXXXXXXXXXXXXX7777777777777777rrrrrr:r7XXSX7777rriiiiiiiiiiiiiiii:7B8r,     i72i::ii::iii:ii:i:ii
 XXXXXXXXXXXXXXX7777777777777777rrrrrrrri7777X7XXXXXS7iiiiiiiiiiiiiii:, ,7S2222X7i ,i:iii:iiiiiiii:ii
 XXXXXXXXXXXXXXX77777777777777777rrrrrrrir88BB8Z22S7r,:iiiiiiiiiiiiii::22777rr7rr7ii::ii:::iiiiiii:ii
 XXXXXXXXXXXXX7777777777777rrr7rrrrrrrrrri:        ..,iriiiiiiiiii:iii,7SZ8BBBBBZS::i:iii:ii::::i::ii
 XXXXX7XXXXXXX777777777777777rrrrrrrrrrrrri7SSX7777rr: .riiii:iiiiiiii:28r.     ,7:i::ii:iiiiiiiiiiii
 XX7777777777777777777777777777rrrrrrrriiri            X::riiiiiiiiiii:, rXSSSXXr :i:iiiiiiiiiiiiiiii
 X7XXXX77777777777777777r77rrrrrrrrrrrrirr::7S2Z888ZZSS7  .rriiiiiiiii:ir,      ,,ii::ii:iiiiiiiiiiii
 X7777X77777777777777777r77rrrrrrrrrrrrrrrrS7ri:,,,.        ri:iiiiiii:  iXSZ2Xr.  i:::iiiiiiiiiiiiii
 XXXXXX7XXXXX77777777777777rrrrrrrrrriiiii.        ..iX:     riiiiiiiiiSBX7:::i7287ii:iiiiiiiiiiiiiii
 XXXXXXXXXXX77777777777777rrrrrrrrriiiiiiiiZ22Z2SSXSSS7  ..  :riiiiiiii:    ,.    .:riiiiiiiiiiiiiiir
 XXXXXXXXXXXXXXXXX77777777777rrrrrrrrriiir:ZXXXXX7r7S2        riiiiii:, X882SS2Z2r  iiiiiiiiiiiiiiiir
 XXXXXXXXXXXXXXXXXXX77777777777rrrr77rrrrrirr7SSS22SX:   .   iiiiiiii:S8XX28BBBB87.::iiiiiiiiiiirrrrr
 XXXXXXXXXXXXXXXXXXXXXXXXXXX7777777777rrri7i:,         .   ,riiiiiiiii,2B8i      i2Ziiiiiiiiiiiirrrrr
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXX77XX7777777X2S222S2S2S. .. ,i7riiiiriir7,:  i28BB82Xi :iiiiiiiiirrrrrrr
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXSr:iir7XXSS.   i  irrrrrrrrrrX: 882227rr72Z2:riiiiiirirrrrrrr
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXSZ.    .,,,   ,7X ,77r7777X7X7X7 X2i:  .   .r:iriiiiirrrrrrrr7
 XXXXXXXXXXXXXSXXXXXXXXXXXXXXXXXXXXXXS22   .,,.  .  ,7r7.:7777XXXXXXXX2, :. ...       riiiiirrrrrrrr7
 XXXXXXXXXXXXXSXXXXXXXXXXXXXXXXXXXSXS27 rSSri,.:, . riir,ir777XXXSXXXXX2:  . :r7X7ri.  riiirrrrrrr777
 XSSSSSSSSXXXXXXXSXXXXXXXXXXXXXXXSXSZ7,BBBBB887  . ri::::r,,,,,:ir77XXXSZ  X8BBBBBBBBBr:rrirrrrr77777
 XXXXXXXXXXXXXSSSSXXXXXXXSSSSSSS2Z8ZX.     Z    . .r:::::r.,,:ir7XXXXXXX27,BB87r, .  . ,r7rrrr77777XX
 SSSSSSSSSSSSSXSSSSSSSSSSXXXS288Si    ...      .: :,..,i  r2Z22SSSSSXXXXSZ.     .   ...,,r77777777XXX
 SSSSSSSSSSSSSSSSSSSSSSSSSSSZX.    ..,,,....,..   .:rX22SS2SSSSXSSSSSSXXS2S ..... .  ....:XX77XXXXXXX
 SSSSSSSSSSSSSSSSSSSSSSSSSXSX                    r8Z2SSSSSXXXXXXXXXXXSSSSSZ,,,...          XXXXXXXXXX
 SSSSSSSSSSSSSSSSSSSSSSSSSSS2r      .,::ii7XS28B8ZSXXSXSSSSSSSXSSSSSSSXXX777           ,i7SSSSSXSSSXX
 SSSSSSSSSSSSSSSSSSSSSSSSSSSS28BBBB8888ZZZZ22SSSSSXSXXXSSSSSSSSSSSXXXXXSXX7r    . ,irr7SSSSXSXXSXXSSS
 SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSXSSS7X77rrr  i::,::r7XSSSXXSSSS
 SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSXXXSSX7i:,:  ,::::,,:r7SSSSSSSS
 SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSXSSS7:       .......i7XSSSSSS
 SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS222S7r:,...,i7S22SSSSSSSS
 SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS222ZZ8ZZZ2Z2SSSSSSSSSS
 SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSm0f
 
*/