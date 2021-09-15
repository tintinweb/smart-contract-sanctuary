/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
//BOSON Labs.
pragma solidity >=0.6.0;


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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) public returns (bytes memory) {
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
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize () public virtual {
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
}



contract Initializable  {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
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


contract BkColl is Context, IBEP20, Ownable,Initializable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) public _rOwned;
    mapping (address => uint256) public _tOwned;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) private _boughtBlock;
    mapping (address => uint256) private bought;
    mapping (address => bool) public _isrewardExcluded;
    mapping (address => bool) public _greyListAccount;
    mapping(address => uint256) private blacklisted;
    mapping(address => uint256) private blacklistedtime;
    
    address[] public _rewardExcluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tTaxTotal;
    uint256 private _tBurnTotal;
    uint256 public _maxLiquidityAmount;
    string private constant  _name = 'BLCOLL';
    string private constant  _symbol = 'BKCOLL';
    uint8 private constant  _decimals = 9;
   
    address public treasuryaddress;
    address private burnVault;

    /**
     * cTaxFee -it used for storing taxfee.
     * cBurnFee -it used for storing BurnFee  
     * cTreasuryFee -it used for storing cTreasuryFee.
     * cLiquidityFee -it used for storing cLiquidityFee.
     **/
    struct BlackConfig { 
      uint128 cTaxFee;
      uint128 cBurnFee;
      uint128 cTreasuryFee;
      uint128 cLiquidityFee;
   }
    BlackConfig private _blackConfig;
    //_firstLockPeriod -denotes 12 hours locking period.
    uint128 constant private _firstLockPeriod =12 hours;
    //_firstLockPeriod -denotes 24 hours locking period.
    uint128 constant private _secondLockPeriod =24 hours;
  
    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled ;
    uint256 private numTokensSellToAddToLiquidity;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event NumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity);  
    event LiquidityFee(uint256 _liquidityFee);   
    event TreasuryFee(uint256 _treasuryFee); 
    event BurnFee(uint256 _burnFee);
    event TaxFee(uint256 _taxFee);
    event MaxLiquidityAmount(uint256 _maxLiquidityAmount);
    event GreyListUpdate(address __greyListAddress, bool __flag);
    event Withdraw(address _target,uint256 _amount);
    event UpdateTreasuryAddress(address newTreasuryAddress);
    event UpdateBurnVaultAddress(address newBurnVaultAddress);
    event UpdateStakingAddress(address newStakingAddress);
   
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
    
    //address[] public stakingAddress;
    mapping(address => bool) public stakingAddress;
    
      /*
	 * BLACK works by applying 10% transaction fee in which 4% is send  instantly to all token holders.
	 * and 4% is automatically burnt which continuously reduces the total supply of BLACK (BLACK).
     * and 1% is added in reserved wallet address.
     * and 1% is added in liquidity pool. 
    */
    function initialize() public override  initializer
    {
     Ownable.initialize();
    _blackConfig.cTaxFee=4;
    _blackConfig.cBurnFee=4;
    _blackConfig.cTreasuryFee=1;
    _blackConfig.cLiquidityFee=1;
     numTokensSellToAddToLiquidity = 20 * 10**3 * 10**9;
     _maxLiquidityAmount = 5 * 10**6 * 10**9;
     swapAndLiquifyEnabled = true;
    _tTotal =100 * 10**6 * 10**9;
    _rTotal = (MAX - (MAX % _tTotal));
    _rOwned[_msgSender()] = _rTotal;
     treasuryaddress =  address(0xb76C6232686ebF4894889832bEcB21AF5926E59b);  
     IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    //Create a uniswap pair for this new token
     uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    // set the rest of the contract variables
     uniswapV2Router = _uniswapV2Router;
     emit Transfer(address(0), _msgSender(), _tTotal);
    }
	/**
     * @dev Returns the name of the token.
     */
    function name() public pure  returns (string memory) {
        return _name;
    }
   /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
     /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
     /**
     * @dev Returns the totalSupply of the token.
     */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
     /**
     * account who The address to query.
     * The balance of the specified address.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isrewardExcluded[account]){
            return _tOwned[account];
        }
        return tokenFromBlack(_rOwned[account]);
    }
     /**
     *  Transfer tokens to a specified address.
     *  The address to transfer .
     *  The amount to be transferred.
     *  True on success, false otherwise.
     */ 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
     /**
     *  Function to check the amount of tokens that an owner has allowed to a spender to Spend.
     *  The owner address which owns the funds.
     *  The spender address which will spend the funds.
     *  Returns the number of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
 /**
     * Approve the spender address to spend the specified amount of tokens on behalf of
     * _msgSender(). This method is included for BEP20 compatibility.
     * spender address which will spend the funds.
     * value amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
   /**
     * Transfer tokens from one address to another.
     * sender address you want to send tokens from.
     * recipient address you want to transfer to.
     * value The amount of tokens to be transferred.
     */
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
     /**
     * Increase the amount of tokens that an owner has allowed to a spender.
     * spender address which will spend the funds.
     * addedValue amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    /**
     *  Decrease the amount of tokens that an owner has allowed to a spender.
     *  spender address which will spend the funds.
     *  subtractedValue amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
     /**
     * @dev Returns true if account address is added as rewardExcluded 
	 * rewardExcluded address which does not receive any reward instantly when Holders buy token.
     */
    function isrewardExcluded(address account) public view returns (bool) {
        return _isrewardExcluded[account];
    }
   
     /**
     * @dev Returns the totalTax of the token.
     */
    function totalTax() public view returns (uint256) {
        return _tTaxTotal;
    }
    /**
     * @dev Returns the totalBurn of the token.
     */
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    

    function blackFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromBlack(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total Tester3");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    //This function exclude given address in reward excluded addresses 
    function rewardexcludeAccount(address account) external onlyOwner() {
        require(!_isrewardExcluded[account], "Account is already excluded from rewards");
        if(_rOwned[account] > 0) {
            _tOwned[account] =tokenFromBlack(_rOwned[account]);
        }
        _isrewardExcluded[account] = true;
        _rewardExcluded.push(account);
    }
    //This function includes given address in reward included addresses 
    function rewardincludeAccount(address account) external onlyOwner() {
        require(_isrewardExcluded[account], "Account is already included for rewards");
        for (uint256 i = 0; i < _rewardExcluded.length; i++) {
            if (_rewardExcluded[i] == account) {
                _rewardExcluded[i] = _rewardExcluded[_rewardExcluded.length - 1];
                _tOwned[account] = 0;
                _isrewardExcluded[account] = false;
                _rewardExcluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   // This function changes the freezing period of account which was currently in locking state. 
   function _changeFreezeBlock(address account, uint256 _block) external onlyOwner() {
        _boughtBlock[account] = _block;
         blacklisted[account]=0;
        
    }
    //if sender is in frozen state,then this function returns epoch value remaining for the address for it to get unfrozen.
      function _secondsLeft(address sender) public view returns (uint256) {
        if(_isFrozen(sender)) {
            return (_boughtBlock[sender] - block.timestamp);
        }
        else {
            return 0;
        }
    }
    //checks the account is locked(true) or unlocked(false)
    function _isFrozen(address sender) public view returns (bool) {
        return _boughtBlock[sender] > block.timestamp;
    }
    
    function _blocksSinceBuy(address sender) public view returns (uint256) {
        // safe uint subtraction as will be zero at minimum
        return block.timestamp - _boughtBlock[sender];
    }
    
    /**
     *  Transfer BLACK tokens to a specified address.
     *  The address sender ,recipient to transfer .
     *  The amount to be transferred.
     */ 
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(sender != recipient, "BEP20: transfer to self");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isFrozen(sender) != true , "Current sender is in frozen state!");
        require( getGreyListinternal(sender) ==false,   "sender address  greylisted, no transactions are allowed with this account !");
        require( getGreyListinternal(recipient)==false, "recepient address is  greylisted, no transactions are allowed with this account !");
        
        uint256 maxTxAmount = balanceOf(sender)/100;
       
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 liquidityBalanceWithContract = balanceOf(address(this));
        //below if condition takes minimum of liquidityBalanceWithContract ,_maxLiquidityAmount 
        if(liquidityBalanceWithContract >= _maxLiquidityAmount)
        {      
          liquidityBalanceWithContract = _maxLiquidityAmount;
        }                                                       
        bool overMinTokenBalance =  liquidityBalanceWithContract >= numTokensSellToAddToLiquidity;
       
        if (overMinTokenBalance && !inSwapAndLiquify && sender != uniswapV2Pair && swapAndLiquifyEnabled) 
        {           
            //add liquidity
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }
       
			if (_isrewardExcluded[sender] && !_isrewardExcluded[recipient]) {
					 if(recipient  == uniswapV2Pair){ 
					      if(sender==address(this)||sender==owner())
					      {
				       	    _transferFromrewardExcluded(sender, recipient, amount);	
					      }
				       	  else{  
					         require(amount<= maxTxAmount , 'maxTxAmount should be less than or equals 1 % ');
						    _transferFromrewardExcludedPCS(sender,recipient,amount);
				           }
					 }
					 else if(stakingAddress[sender] == true){
					     _transferFromrewardExcludedPCS(sender,recipient,amount);
					 }
					 else
						_transferFromrewardExcluded(sender, recipient, amount);					
			} 
			else if (!_isrewardExcluded[sender] && _isrewardExcluded[recipient]) {
				
				    if((sender  == uniswapV2Pair)||(stakingAddress[recipient] == true))
				    {
				        _transferBothrewardExcludedPCS(sender,recipient,amount);
					
				    }
				    else if(recipient == burnVault){
				    	_transferTorewardExcluded(sender, recipient, amount);
				    }
					else{
					    require(amount<= maxTxAmount , 'maxTxAmount should be less than or equals 1 % ');
						_transferTorewardExcluded(sender, recipient, amount);      
					}
			} 
			else if (_isrewardExcluded[sender] && _isrewardExcluded[recipient]) {
			       if((stakingAddress[sender] == true) || (stakingAddress[recipient] == true)){
			            _transferBothrewardExcludedStaking(sender, recipient, amount);
			       }
			       else{
						_transferBothrewardExcluded(sender, recipient, amount);
			       }
			}
			else { // Transfer from normal wallet to normal wallet holder
			       if(recipient==uniswapV2Pair) {
			           require(amount<= maxTxAmount , 'maxTxAmount should be less than or equals 1 % ');
			       	  _transferTorewardExcludedPCS(sender,recipient,amount); 
			       	  _senderLock(sender,amount);
			           
			       } 
			       else if(sender==uniswapV2Pair){
			           _transferTorewardExcludedPCS(sender,recipient,amount); 
			       }
			       else  
			       {
				       require(amount<= maxTxAmount , 'maxTxAmount should be less than or equals 1 % ');
			    	   _transferStandard(sender,recipient,amount);
			    	   _senderLock(sender,amount);
			       }
			}
       
       
       
    }

 function swapAndLiquify(uint256 liquidityBalanceWithContract) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = liquidityBalanceWithContract.div(2);
        uint256 otherHalf = liquidityBalanceWithContract.sub(half);
        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for BNB
        swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into                
        uint256 newBalance = address(this).balance.sub(initialBalance);  
       
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wBNB
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
    
    function _senderLock (address sender,uint256 amount)private{
    //calculates percentage of token  holds in  sender balance  before transfer
     uint256 pointfive      =  5 * balanceOf(sender)/1000; 
     uint256 pointsevenfive = 75 * balanceOf(sender)/10000;
            if(amount < pointfive  ){
                  blacklisted[sender]=blacklisted[sender] + 1;
			      if(blacklisted[sender]==1)
				     blacklistedtime[sender]= block.timestamp; 
                  if(block.timestamp < blacklistedtime[sender] + _secondLockPeriod ){
                         if(blacklisted[sender] >= 2){  
                            _boughtBlock[sender] = block.timestamp + _secondLockPeriod ;
							blacklisted[sender]=0;
                          }
                   }else{
                          blacklisted[sender]=1;
                          blacklistedtime[sender]=block.timestamp; 
                   }
           
            }else if(amount >= pointfive && amount < pointsevenfive ){
                         _senderTimeLock(sender);
                        _boughtBlock[sender] = block.timestamp + _firstLockPeriod;
            }else if (amount >= pointsevenfive){
                         _senderTimeLock(sender);
			            _boughtBlock[sender] = block.timestamp + _secondLockPeriod ;
             }
       }
       
    /** This function _senderTimeLock checks the User if he has done only one transaction in last 24 hours.
     *  if current transfer is within 24hrs time from the previous transfer then it ensures blacklisted[sender]<=0
     *  else it unlocks the sender.
    */
    function _senderTimeLock (address sender)private{
                if(blacklisted[sender]<=2){
                        uint256 timeValue = block.timestamp - blacklistedtime[sender];
                        if(timeValue < _secondLockPeriod)
                            require(blacklisted[sender]<=0,"Current sender is in frozen state !");
                        else
                            blacklisted[sender] = 0;
                }
    }
        
        /**This function locks the sender address 
     * If sender transfers lessthan 0.5 % tokens for 2 times within 24 hours ,then sender account will be locked for 24 hours.
     * If Sender  transfers between 0.5 %  to 0.75 % of token balance ,then sender account will be locked for 12 hours. 
     * If Sender  transfers  0.75 % or morethan 0.75 % of token balance ,then sender account will be locked for 24 hours.
     **/
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
             uint256 treasuryamount = tAmount .mul(_blackConfig.cTreasuryFee).div(100);
            _tOwned[treasuryaddress] = _tOwned[treasuryaddress].add(treasuryamount);
             uint256 rBurn =  tBurn.mul(_getRate());
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
		    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		    
		     //calculates percentage of token holds in  recipient balance before transferring from sender
           uint256 pointfiverec= 5 * balanceOf(recipient)/1000; 
           uint256 pointsevenfiverec=75 * balanceOf(recipient)/10000;
		    
			if(tTransferAmount >= pointfiverec && tTransferAmount < pointsevenfiverec) {
					_boughtBlock[recipient] = block.timestamp + _firstLockPeriod ;
			}
			else if(tTransferAmount >=  pointsevenfiverec) {
					_boughtBlock[recipient] = block.timestamp + _secondLockPeriod ;
			}
		    _blackFee(rFee, rBurn, tFee, tBurn);
            _takeLiquidity(tLiquidity);
            emit Transfer(sender, recipient, tTransferAmount);
    }
       //This  function is called when token is transfered to reward excluded address.
    function _transferTorewardExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount); 
         emit Transfer(sender, recipient, tAmount);
    }
     //This  function is called when token is transfered to Pancakerouter address.
    function _transferTorewardExcludedPCS(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount , uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 treasuryamount = tAmount .mul(_blackConfig.cTreasuryFee).div(100);
        _tOwned[treasuryaddress] = _tOwned[treasuryaddress].add(treasuryamount);
        uint256 rBurn =  tBurn.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _blackFee(rFee, rBurn, tFee, tBurn);
        _takeLiquidity(tLiquidity);
         emit Transfer(sender, recipient, tTransferAmount);
    }
      //This  function is called when token is transferring from reward excluded address.
    function _transferFromrewardExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);  
        emit Transfer(sender, recipient, tAmount);
    }
     //This  function is called when token is transferring from Pancakerouter address.
     function _transferFromrewardExcludedPCS(address sender, address recipient, uint256 tAmount) private {
       (uint256 rAmount,uint256 rTransferAmount , uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 treasuryamount = tAmount .mul(_blackConfig.cTreasuryFee).div(100);
        _tOwned[treasuryaddress] = _tOwned[treasuryaddress].add(treasuryamount);
        uint256 rBurn =  tBurn.mul(_getRate());
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _blackFee(rFee, rBurn, tFee, tBurn);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    /**This  function is called when the sender or receiver is from Pancakerouter address,
       and both addresses are rewardexcluded.
     **/
    function _transferBothrewardExcludedPCS(address sender, address recipient, uint256 tAmount) private {
       (uint256 rAmount,uint256 rTransferAmount , uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 treasuryamount = tAmount .mul(_blackConfig.cTreasuryFee).div(100);
        _tOwned[treasuryaddress] = _tOwned[treasuryaddress].add(treasuryamount);
        uint256 rBurn =  tBurn.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);  
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _blackFee(rFee, rBurn, tFee, tBurn);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    
    //This  function is called when the sender and  receiver is from rewardexcluded address,
    function _transferBothrewardExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);        
        emit Transfer(sender, recipient, tAmount);
    }
     /**This  function is called when the sender or receiver is from Staking Contract  address,
       and both addresses are rewardexcluded.
     **/
    function _transferBothrewardExcludedStaking(address sender, address recipient, uint256 tAmount) private {
       (uint256 rAmount,uint256 rTransferAmount , uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 treasuryamount = tAmount .mul(_blackConfig.cTreasuryFee).div(100);
        _tOwned[treasuryaddress] = _tOwned[treasuryaddress].add(treasuryamount);
        uint256 rBurn =  tBurn.mul(_getRate());
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);  
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _blackFee(rFee, rBurn, tFee, tBurn);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _blackFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tTaxTotal = _tTaxTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
    }
    
    struct BValues {
        uint256 bTransferAmount;
        uint256 bFee;
        uint256 bBurn;
        uint256 bLiquidity;
        uint256 bTreasuryFee;
    }
    
    function _getValues(uint256 tAmount)private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (BValues memory tBValuesStruct) = _getTValues(tAmount, _blackConfig);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tBValuesStruct, tAmount);
        return (rAmount, rTransferAmount, rFee, tBValuesStruct.bTransferAmount, tBValuesStruct.bFee,tBValuesStruct.bBurn, tBValuesStruct.bLiquidity);
    }

    function _getTValues(uint256 tAmount, BlackConfig memory blackConfig) private pure returns (BValues memory) {
        uint256 tFee = tAmount.mul(blackConfig.cTaxFee).div(100);
        uint256 tLiquidity = calculateLiquidityFee(tAmount, blackConfig.cLiquidityFee);
        uint256 tBurn = tAmount.mul(blackConfig.cBurnFee).div(100);
        uint256 tTreasuryFee = tAmount.mul(blackConfig.cTreasuryFee).div(100);
        uint256 tTransactionAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity).sub(tTreasuryFee);
        BValues memory _bValues = BValues({bTransferAmount:tTransactionAmount, bFee:tFee, bBurn:tBurn, bLiquidity:tLiquidity, bTreasuryFee:tTreasuryFee});
        return _bValues;
    }
    
    function _getRValues(BValues memory _rBValues, uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = (tAmount).mul(currentRate);
        uint256 rFee = (_rBValues.bFee).mul(currentRate);
        uint256 rBurn = (_rBValues.bBurn).mul(currentRate);
        uint256 rLiquidity = (_rBValues.bLiquidity).mul(currentRate);
        uint256 rTreasuryFee =(_rBValues.bTreasuryFee).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rTreasuryFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _rewardExcluded.length; i++) {
            if (_rOwned[_rewardExcluded[i]] > rSupply || _tOwned[_rewardExcluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_rewardExcluded[i]]);
            tSupply = tSupply.sub(_tOwned[_rewardExcluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
   
   /**
     * @dev sets the TaxFee for the token.
     */
    function _setTaxFee(uint128 taxFee) external onlyOwner() {
        require(taxFee >= 1 && taxFee <= 10, 'taxFee should be in 1 - 10');
        _blackConfig.cTaxFee = taxFee;
        emit TaxFee(_blackConfig.cTaxFee);
    }
    
    /**
     * @dev Returns the TaxFee for the token.
     */
    function _getTaxFee() external view returns(uint256) {
        return _blackConfig.cTaxFee;
    }
    
      /**
     * @dev sets the BurnFee for the token from External.
     */
    function _setBurnFeeExternal(uint128 burnFee) external onlyOwner  {
        _blackConfig.cBurnFee = burnFee;
        emit BurnFee(_blackConfig.cBurnFee);
    }
     /**
     * @dev get the BurnFee for the token.
     */
    function _getBurnFee() external view returns(uint256) {
        return _blackConfig.cBurnFee;
    }
 
     /**
     * @dev sets the treasuryFee for the token.
     */
    function _setTreasuryFee(uint128 treasuryFee) external onlyOwner()  {
       _blackConfig.cTreasuryFee = treasuryFee;
        emit TreasuryFee(_blackConfig.cTreasuryFee);
    }
    
    /**
     * @dev Returns the TreasuryFee for the token.
     */
    function _getTreasuryFee() external view returns(uint256) {
        return _blackConfig.cTreasuryFee;
    }
     
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isrewardExcluded[address(this)])
          _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateLiquidityFee(uint256 _amount, uint256 liquidityFee) private pure returns (uint256) {
        return _amount.mul(liquidityFee).div(10**2);
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
        
    }
    
    /**
     * @dev Returns the SwapAndLiquifyEnabled .
     */
    function _getSwapAndLiquifyEnabled() external view returns(bool) {
        return  swapAndLiquifyEnabled;
    }
    
     /**
     * @dev   setLiquidityFee .
     */
     function setLiquidityFee(uint128 liquidityFee) external onlyOwner() {
       _blackConfig.cLiquidityFee = liquidityFee;
       emit LiquidityFee(_blackConfig.cLiquidityFee);
    }
    
     /**
     * @dev Returns the LiquidityFee for the token.
     */
    function _getLiquidityFee() external view returns(uint256) {
        return _blackConfig.cLiquidityFee;
    }
    
     /**
     * @dev   setnumTokensSellToAddToLiquidity .
     */
    function setnumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity)external onlyOwner(){
       numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
       emit NumTokensSellToAddToLiquidity(numTokensSellToAddToLiquidity);
   }
   
    /**
     * @dev Returns the numTokensSellToAddToLiquidity .
     */
    function _getnumTokensSellToAddToLiquidity() external view returns(uint256) {
        return  numTokensSellToAddToLiquidity;
     
    }
    
     /**
     * @dev  setGreyList .
     */
     function setGreyList(address gAddress, bool gFlag) external onlyOwner() {
        _greyListAccount[gAddress] = gFlag;
        emit GreyListUpdate(gAddress, _greyListAccount[gAddress]);
    }
    
     /**
     * @dev  getGreyListinternal .
     */
     function getGreyListinternal(address gAddress) internal view  returns (bool){
        return _greyListAccount[gAddress];
    }
    
     /**
     * @dev  getGreyList .
     */
     function getGreyList(address gAddress) public onlyOwner view returns (bool){
        return _greyListAccount[gAddress];
    }
    
    /*
    To withdraw BNB Balance from Contract address.
    */
    function withdraw(address payable _target,uint256 _amount)external  onlyOwner {
       require(address(this).balance > _amount,"Not enough BNB balance");
       _target.transfer(_amount);
       emit Withdraw(_target, _amount);
    }
   
    /**
     * @dev sets the treasuryaddress for the token.
     */
    function _setTreasuryAddress(address _treasuryaddress) external onlyOwner()  {
       treasuryaddress = _treasuryaddress;
       emit UpdateTreasuryAddress(treasuryaddress);
    }
     /**
     * @dev   setBurnVault .
     */
     function setBurnVault(address _burnVault) external onlyOwner() {
       burnVault = _burnVault;
       emit UpdateBurnVaultAddress(burnVault);
    }
    
     /**
     * @dev Returns the BurnVault address.
     */
    function _getBurnVault() external view returns(address) {
        return burnVault;
    }
     /**
     * @dev  setMaxLiquidityAmount .
     */
     function setMaxLiquidityAmount(uint256 maxTxPercent) external onlyOwner() {
        _maxLiquidityAmount = maxTxPercent;
        emit MaxLiquidityAmount(_maxLiquidityAmount);
    }
    /**
     * @dev   setStaking contract address .
     */
    function addStakingContract(address _StakingAddress) external onlyOwner() {
       stakingAddress[_StakingAddress] = true;
       emit UpdateStakingAddress(_StakingAddress);
    }
    /**
     * Remove staking contract addresses
     */
     function removeStakingContract(address _StakingAddress) external onlyOwner() {
       stakingAddress[_StakingAddress] = false;
    }
   
    
    //to receive BNB from uniswapV2Router when swapping
    receive() external payable {}
}