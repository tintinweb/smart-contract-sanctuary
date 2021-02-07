/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// File: ../triton/crypto/Triton.sol

//                      ▄▄                            
// ███▀▀██▀▀███         ██   ██                       
// █▀   ██   ▀█              ██                       
//      ██    ▀███▄███▀███ ██████  ▄██▀██▄▀████████▄  
//      ██      ██▀ ▀▀  ██   ██   ██▀   ▀██ ██    ██  
//      ██      ██      ██   ██   ██     ██ ██    ██  
//      ██      ██      ██   ██   ██▄   ▄██ ██    ██  
//    ▄████▄  ▄████▄  ▄████▄ ▀████ ▀█████▀▄████  ████▄
                                                   
                                                   

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
    modifier onlyOwner() virtual {
        require(_owner == _msgSender(), "Ownable: caller is not owner");
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


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

pragma solidity ^0.6.12;

contract LockWallet {
    constructor() public {
    }
}

contract Balancer {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable _uniswapV2Router;
    TRITON private _tokenContract;
    
    constructor(TRITON tokenContract, IUniswapV2Router02 uniswapV2Router) public {
        _tokenContract =tokenContract;
        _uniswapV2Router = uniswapV2Router;
    }
    
    receive() external payable {}
    
    function rebalance() external returns (uint256) { 
        swapEthForTokens(address(this).balance);
    }

    function swapEthForTokens(uint256 EthAmount) private {
        address[] memory uniswapPairPath = new address[](2);
        uniswapPairPath[0] = _uniswapV2Router.WETH();
        uniswapPairPath[1] = address(_tokenContract);

        _uniswapV2Router
            .swapExactETHForTokensSupportingFeeOnTransferTokens{value: EthAmount}(
                0,
                uniswapPairPath,
                address(this),
                block.timestamp
            );
    }
}

contract Swaper {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable _uniswapV2Router;
    TRITON private _tokenContract;
    
    constructor(TRITON tokenContract, IUniswapV2Router02 uniswapV2Router) public {
        _tokenContract = tokenContract;
        _uniswapV2Router = uniswapV2Router;
    }
    
    function swapTokens(address pairTokenAddress, uint256 tokenAmount) external {
        uint256 initialPairTokenBalance = IERC20(pairTokenAddress).balanceOf(address(this));
        swapTokensForTokens(pairTokenAddress, tokenAmount);
        uint256 newPairTokenBalance = IERC20(pairTokenAddress).balanceOf(address(this)).sub(initialPairTokenBalance);
        IERC20(pairTokenAddress).transfer(address(_tokenContract), newPairTokenBalance);
    }
    
    function swapTokensForTokens(address pairTokenAddress, uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(_tokenContract);
        path[1] = pairTokenAddress;

        _tokenContract.approve(address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of pair token
            path,
            address(this),
            block.timestamp
        );
    }
}

contract TRITON is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public immutable _uniswapV2Router;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address public _lockWallet;
    uint256 public _initialLockAmount;
    address public _uniswapETHPool;

    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000e9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _tFeeTotal;
    uint256 public _tBurnTotal;

    string private _name = 'Triton Governance';
    string private _symbol = 'TRITON';
    uint8 private _decimals = 9;
    
    uint256 public _feeDecimals = 1;
    uint256 public _taxFee = 0;
    uint256 public _lockFee = 0;
    uint256 public _maxTxAmount = 100e9;
    uint256 public _minTokensBeforeSwap = 1e9;
    uint256 public _minInterestForReward = 1e6;
    uint256 private _autoSwapCallerFee = 2e7;
    
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public tradingEnabled;
    bool public tritonActivated; 
    
    address private currentPairTokenAddress;
    address private currentPoolAddress;
    
    uint256 private _liquidityRemoveFee = 0;
    uint256 private _conchCallerFee = 0;
    uint256 private _minTokenForConch = 10e9;
    uint256 private _lastConch;
    uint256 private _conchInterval = 60 seconds;
    uint256 private _randNonce = 0;
    

    event FeeDecimalsUpdated(uint256 taxFeeDecimals);
    event TaxFeeUpdated(uint256 taxFee);
    event LockFeeUpdated(uint256 lockFee);
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event WhitelistUpdated(address indexed pairTokenAddress);
    event TradingEnabled();
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        address indexed pairTokenAddress,
        uint256 tokensSwapped,
        uint256 pairTokenReceived,
        uint256 tokensIntoLiqudity
    );
    event Rebalance(uint256 tokenBurnt);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event AutoSwapCallerFeeUpdated(uint256 autoSwapCallerFee);
    event MinInterestForRewardUpdated(uint256 minInterestForReward);
    event LiquidityRemoveFeeUpdated(uint256 liquidityRemoveFee);
    event ConchCallerFeeUpdated(uint256 rebalnaceCallerFee);
    event MinTokenForConchUpdated(uint256 minRebalanceAmount);
    event ConchIntervalUpdated(uint256 rebalanceInterval);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    Balancer public balancer;
    Swaper public swaper;

    constructor (IUniswapV2Router02 uniswapV2Router, uint256 initialLockAmount) public {
        _lastConch = now;
        
        _uniswapV2Router = uniswapV2Router;
        _lockWallet = address(new LockWallet());
        _initialLockAmount = initialLockAmount;
        
        balancer = new Balancer(this, uniswapV2Router);
        swaper = new Swaper(this, uniswapV2Router);
        
        currentPoolAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        currentPairTokenAddress = uniswapV2Router.WETH();
        _uniswapETHPool = currentPoolAddress;
        
        updateSwapAndLiquifyEnabled(false);
        
        _rOwned[_msgSender()] = reflectionFromToken(_tTotal.sub(_initialLockAmount), false);
        _rOwned[_lockWallet] = reflectionFromToken(_initialLockAmount, false);
        
        emit Transfer(address(0), _msgSender(), _tTotal.sub(_initialLockAmount));
        emit Transfer(address(0), _lockWallet, _initialLockAmount);
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    
    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Triton: Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
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
        require(rAmount <= _rTotal, "Triton: Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'Triton: We can not exclude Uniswap router.');
        require(account != address(this), 'Triton: We can not exclude contract self.');
        require(account != _lockWallet, 'Triton: We can not exclude reweard wallet.');
        require(!_isExcluded[account], "Triton: Account is already excluded");
        
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Triton: Account is already included");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Triton: approve from the zero address");
        require(spender != address(0), "Triton: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Triton: transfer from the zero address");
        require(recipient != address(0), "Triton: transfer to the zero address");
        require(amount > 0, "Triton: Transfer amount must be greater than zero");
        
        if(sender != owner() && recipient != owner() && !inSwapAndLiquify) {
            require(amount <= _maxTxAmount, "Triton: Transfer amount exceeds the maxTxAmount.");
            if((_msgSender() == currentPoolAddress || _msgSender() == address(_uniswapV2Router)) && !tradingEnabled)
                require(false, "Triton: trading is disabled.");
        }
        
        if(!inSwapAndLiquify) {
            uint256 lockedBalanceForPool = balanceOf(address(this));
            bool overMinTokenBalance = lockedBalanceForPool >= _minTokensBeforeSwap;
            if (
                overMinTokenBalance &&
                msg.sender != currentPoolAddress &&
                swapAndLiquifyEnabled
            ) {
                if(currentPairTokenAddress == _uniswapV2Router.WETH())
                    swapAndLiquifyForEth(lockedBalanceForPool);
                else
                    swapAndLiquifyForTokens(currentPairTokenAddress, lockedBalanceForPool);
            }
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

    }
    
    receive() external payable {}
    
    function swapAndLiquifyForEth(uint256 lockedBalanceForPool) private lockTheSwap {
        // split the contract balance except swapCallerFee into halves
        uint256 lockedForSwap = lockedBalanceForPool.sub(_autoSwapCallerFee);
        uint256 half = lockedForSwap.div(2);
        uint256 otherHalf = lockedForSwap.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidityForEth(otherHalf, newBalance);
        
        emit SwapAndLiquify(_uniswapV2Router.WETH(), half, newBalance, otherHalf);
        
        _transfer(address(this), tx.origin, _autoSwapCallerFee);
        
        _sendRewardInterestToPool();
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityForEth(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    function swapAndLiquifyForTokens(address pairTokenAddress, uint256 lockedBalanceForPool) private lockTheSwap {
        // split the contract balance except swapCallerFee into halves
        uint256 lockedForSwap = lockedBalanceForPool.sub(_autoSwapCallerFee);
        uint256 half = lockedForSwap.div(2);
        uint256 otherHalf = lockedForSwap.sub(half);
        
        _transfer(address(this), address(swaper), half);
        
        uint256 initialPairTokenBalance = IERC20(pairTokenAddress).balanceOf(address(this));
        
        // swap tokens for pairToken
        swaper.swapTokens(pairTokenAddress, half);
        
        uint256 newPairTokenBalance = IERC20(pairTokenAddress).balanceOf(address(this)).sub(initialPairTokenBalance);

        // add liquidity to uniswap
        addLiquidityForTokens(pairTokenAddress, otherHalf, newPairTokenBalance);
        
        emit SwapAndLiquify(pairTokenAddress, half, newPairTokenBalance, otherHalf);
        
        _transfer(address(this), tx.origin, _autoSwapCallerFee);
        
        _sendRewardInterestToPool();
    }

    function addLiquidityForTokens(address pairTokenAddress, uint256 tokenAmount, uint256 pairTokenAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        IERC20(pairTokenAddress).approve(address(_uniswapV2Router), pairTokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidity(
            address(this),
            pairTokenAddress,
            tokenAmount,
            pairTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function conch() public lockTheSwap {
        require(balanceOf(_msgSender()) >= _minTokenForConch, "Triton: You have not enough Triton to ");
        require(now > _lastConch + _conchInterval, 'Triton: Too Soon.');
        
        _lastConch = now;

        uint256 amountToRemove = IERC20(_uniswapETHPool).balanceOf(address(this)).mul(_liquidityRemoveFee).div(100);

        removeLiquidityETH(amountToRemove);
        balancer.rebalance();

        uint256 tNewTokenBalance = balanceOf(address(balancer));
        uint256 tRewardForCaller = tNewTokenBalance.mul(_conchCallerFee).div(100);
        uint256 tBurn = tNewTokenBalance.sub(tRewardForCaller);
        
        uint256 currentRate =  _getRate();
        uint256 rBurn =  tBurn.mul(currentRate);
        
        _rOwned[_msgSender()] = _rOwned[_msgSender()].add(tRewardForCaller.mul(currentRate));
        _rOwned[address(balancer)] = 0;
        
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
        _rTotal = _rTotal.sub(rBurn);

        emit Transfer(address(balancer), _msgSender(), tRewardForCaller);
        emit Transfer(address(balancer), address(0), tBurn);
        emit Rebalance(tBurn);
    }
    
    function removeLiquidityETH(uint256 lpAmount) private returns(uint ETHAmount) {
        IERC20(_uniswapETHPool).approve(address(_uniswapV2Router), lpAmount);
        (ETHAmount) = _uniswapV2Router
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                lpAmount,
                0,
                0,
                address(balancer),
                block.timestamp
            );
    }

    function _sendRewardInterestToPool() private {
        uint256 tRewardInterest = balanceOf(_lockWallet).sub(_initialLockAmount);
        if(tRewardInterest > _minInterestForReward) {
            uint256 rRewardInterest = reflectionFromToken(tRewardInterest, false);
            _rOwned[currentPoolAddress] = _rOwned[currentPoolAddress].add(rRewardInterest);
            _rOwned[_lockWallet] = _rOwned[_lockWallet].sub(rRewardInterest);
            emit Transfer(_lockWallet, currentPoolAddress, tRewardInterest);
            IUniswapV2Pair(currentPoolAddress).sync();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLock) = _getValues(tAmount);
        uint256 rLock =  tLock.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if(inSwapAndLiquify) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        } else {
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLock);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, address(this), tLock);
            emit Transfer(sender, recipient, tTransferAmount);
        }
        
        if(tritonActivated) {
            _setTaxFee(randMod(50));
            _setLockFee(randMod(25));
            _setConchCallerFee(randMod(10));
            _setLiquidityRemoveFee(randMod(10));
            _setConchInterval(randMod(3600));
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLock) = _getValues(tAmount);
        uint256 rLock =  tLock.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if(inSwapAndLiquify) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        } else {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLock);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, address(this), tLock);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLock) = _getValues(tAmount);
        uint256 rLock =  tLock.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if(inSwapAndLiquify) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        } else {
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
            _rOwned[address(this)] = _rOwned[address(this)].add(rLock);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, address(this), tLock);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLock) = _getValues(tAmount);
        uint256 rLock =  tLock.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if(inSwapAndLiquify) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        }
        else {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
            _rOwned[address(this)] = _rOwned[address(this)].add(rLock);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, address(this), tLock);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLock) = _getTValues(tAmount, _taxFee, _lockFee, _feeDecimals);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLock, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLock);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 lockFee, uint256 feeDecimals) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(10**(feeDecimals + 2));
        uint256 tLockFee = tAmount.mul(lockFee).div(10**(feeDecimals + 2));
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLockFee);
        return (tTransferAmount, tFee, tLockFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLock, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLock = tLock.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLock);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() public view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() public view returns(uint256, uint256) {
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
    
    function getCurrentPoolAddress() public view returns(address) {
        return currentPoolAddress;
    }
    
    function getCurrentPairTokenAddress() public view returns(address) {
        return currentPairTokenAddress;
    }

    function getLiquidityRemoveFee() public view returns(uint256) {
        return _liquidityRemoveFee;
    }
    
    function getConchCallerFee() public view returns(uint256) {
        return _conchCallerFee;
    }
    
    function getMinTokenForConch() public view returns(uint256) {
        return _minTokenForConch;
    }
    
    function getLastConch() public view returns(uint256) {
        return _lastConch;
    }
    
    function getConchInterval() public view returns(uint256) {
        return _conchInterval;
    }
    
    function _setFeeDecimals(uint256 feeDecimals) external onlyOwner() {
        require(feeDecimals >= 0 && feeDecimals <= 2, 'Triton: fee decimals should be in 0 - 2');
        _feeDecimals = feeDecimals;
        emit FeeDecimalsUpdated(feeDecimals);
    }
    
    function _setTaxFee(uint256 taxFee) private {
        require(taxFee >= 1  && taxFee <= 5 * 10 ** _feeDecimals, 'Triton: taxFee should be in 1 - 50');
        _taxFee = taxFee;
        emit TaxFeeUpdated(taxFee);
    }
    
    function _setLockFee(uint256 lockFee) private {
        require(lockFee >= 1 && lockFee <= 5 * 10 ** _feeDecimals, 'Triton: lockFee should be in 1 - 25');
        _lockFee = lockFee;
        emit LockFeeUpdated(lockFee);
    }
    
    function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount >= 500e9 , 'Triton: maxTxAmount should be greater than 500e9');
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(maxTxAmount);
    }
    
    function _setMinTokensBeforeSwap(uint256 minTokensBeforeSwap) external onlyOwner() {
        require(minTokensBeforeSwap >= 5e7 && minTokensBeforeSwap <= 25e9 , 'Triton: minTokenBeforeSwap should be in 5e7 - 25e9');
        require(minTokensBeforeSwap > _autoSwapCallerFee , 'Triton: minTokenBeforeSwap should be greater than autoSwapCallerFee');
        _minTokensBeforeSwap = minTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(minTokensBeforeSwap);
    }
    
    function _setAutoSwapCallerFee(uint256 autoSwapCallerFee) external onlyOwner() {
        require(autoSwapCallerFee >= 1e6, 'Triton: autoSwapCallerFee should be greater than 1e6');
        _autoSwapCallerFee = autoSwapCallerFee;
        emit AutoSwapCallerFeeUpdated(autoSwapCallerFee);
    }
    
    function _setMinInterestForReward(uint256 minInterestForReward) external onlyOwner() {
        _minInterestForReward = minInterestForReward;
        emit MinInterestForRewardUpdated(minInterestForReward);
    }
    
    function _setLiquidityRemoveFee(uint256 liquidityRemoveFee) private {
        require(liquidityRemoveFee >= 1 && liquidityRemoveFee <= 10 , 'Triton: liquidityRemoveFee should be in 1 - 10');
        _liquidityRemoveFee = liquidityRemoveFee;
        emit LiquidityRemoveFeeUpdated(liquidityRemoveFee);
    }
    
    function _setConchCallerFee(uint256 conchCallerFee) private {
        require(conchCallerFee >= 1 && conchCallerFee <= 20 , 'Triton: conchCallerFee should be in 1 - 20');
        _conchCallerFee = conchCallerFee;
        emit ConchCallerFeeUpdated(conchCallerFee);
    }
    
    function _setMinTokenForConch(uint256 minTokenForConch) public onlyOwner() {
        _minTokenForConch = minTokenForConch;
        emit MinTokenForConchUpdated(minTokenForConch);
    }
    
    function _setConchInterval(uint256 conchInterval) private {
        require(conchInterval >= 1 && conchInterval <= 3600 , 'Triton: conchInterval should be between 1 second and 1 hour');
        _conchInterval = conchInterval;
        emit ConchIntervalUpdated(conchInterval);
    }
    
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function _updateWhitelist(address poolAddress, address pairTokenAddress) public onlyOwner() {
        require(poolAddress != address(0), "Triton: Pool address is zero.");
        require(pairTokenAddress != address(0), "Triton: Pair token address is zero.");
        require(pairTokenAddress != address(this), "Triton: Pair token address self address.");
        require(pairTokenAddress != currentPairTokenAddress, "Triton: Pair token address is same as current one.");
        
        currentPoolAddress = poolAddress;
        currentPairTokenAddress = pairTokenAddress;
        
        emit WhitelistUpdated(pairTokenAddress);
    }

    function _enableTrading() external onlyOwner() {
        tradingEnabled = true;
        TradingEnabled();
    }

    //once Triton is activated it can not be deactivated 
    function activateTriton() external onlyOwner() {
        tritonActivated = true;
    }

   function randMod(uint _modulus) private returns(uint) { 
        _randNonce++;
        uint256 randOutputBetweenZeroAndModulus = uint(keccak256(abi.encodePacked(now, msg.sender, _randNonce)))% _modulus;
        randOutputBetweenZeroAndModulus++;
        return randOutputBetweenZeroAndModulus; 
    }

    
}