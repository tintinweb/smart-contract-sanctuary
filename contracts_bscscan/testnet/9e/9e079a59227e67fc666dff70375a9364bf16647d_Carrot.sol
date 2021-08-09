/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed
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
        return payable(msg.sender);
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
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract cannot be unlocked until the lock time is exceeded");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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


contract Carrot is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balance;
    mapping(address => uint256) private _reflectiveBalance;
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    
    address public _feeSetter;
    
    string private constant NAME = "Carrot";
    string private constant SYMBOL = "CRT";
    uint8 private constant DECIMALS = 18;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTAL_SUPPLY = 100000000 * 10**DECIMALS;
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private _reflectiveTotal = (MAX - (MAX % TOTAL_SUPPLY));
    
    address public _structureProviderWallet = 0x6BF8379058437ADCA9dB36C2022F3399491f071b;
    address public _freelancerWallet = 0xCeC6B69b43E7828195C182E5AD8344675CAb48D1;
    
    uint256 private _totalFeePermille = 100; //permille = divided by 1000, so this is 10%
    uint256 private _liquidityFeePermille = 400; //these are expressed as fractions of the total fee amount i.e. this is 40% of the 10% fee (so 4% of the overall transaction amount)
    uint256 private _holdersFeePermille = 200;
    uint256 private _structureFeePermille = 200;
    uint256 private _freelancerFeePermille = 200;
    uint256 private constant FEE_DIVISOR = 1000;
    
    IPancakeRouter02 public _pancakeV2Router;
    address public _pancakeV2Pair;
    
    bool private _lock;
    bool private _inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = true;
    
    bool private _enableFees = true; //no presale so fees enabled from the start
    uint256 public _maxTxAmount = 1000000 * 10**DECIMALS; //initialised to be 1% of total supply
    uint256 private constant MIN_CONTRACT_BALANCE_TO_ADD_LP = 30000 * 10**DECIMALS; //minimum amount needed in contract before it's transferred to LP
    
    event SwapAndLiquifyEnabledUpdated (bool enabled);
    event IncludedInFee (address indexed account);
    event ExcludedFromFee (address indexed account);
    event IncludedInReward (address indexed account);
    event ExcludedFromReward (address indexed account);
    event RouterAndLPPairAddressChanged (address indexed newRouterFactory, address indexed newPair);
    event FeePermillesUpdated (uint256 totalFeePermille, uint256 liquidityFeePermille, uint256 structureFeePermille, uint256 holdersFeePermille, uint256 freelancerFeePermille);
    event MaxTxAmtUpdated (uint256 maxTxAmount);
    event WalletUpdated (string walletName, address indexed walletAddress);
    event FeeSetterChanged (address indexed newFeeSetter);
    event FeeTransfer (uint256 amount);
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    modifier nonReentrant {
        require (!_lock, "Re-entrant call");
        _lock = true;
        _;
        _lock = false;
    }
    
    modifier onlyFeeSetter {
        require (_msgSender() == _feeSetter, "Only accessible by feeSetter");
        _;
    }
    
    constructor () {
        _feeSetter = _msgSender();
        _reflectiveBalance[_msgSender()] = _reflectiveTotal;
        
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E is the PCSv2 Router address - CHANGEME
        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 is the PCS testnet
        // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 is the address of https://pancake.kiemtienonline360.com/
        IPancakeRouter02 pancakeV2Router = IPancakeRouter02 (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a pancakeswap pair for this new token
        _pancakeV2Pair = IPancakeFactory(pancakeV2Router.factory()).createPair(address(this), pancakeV2Router.WETH());
        _pancakeV2Router = pancakeV2Router;
        
        //exclude this contract and contract wallets from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_structureProviderWallet] = true;
        _isExcludedFromFee[_freelancerWallet] = true;
        _isExcluded[_pancakeV2Pair] = true; //should stop skimming being successful
        _excluded.push(_pancakeV2Pair);
        
        emit Transfer (address(0), _msgSender(), TOTAL_SUPPLY);
    }
    
     // To receive BNB from pancakeV2Router when swapping
    receive() external payable {}
    
    // Change the feeSetter address - used for modifying elements of the tokenomics and whitelisting addresses when required (e.g. CEX listings)
    function setNewFeesetter (address feeSetter) external onlyFeeSetter {
        require (feeSetter != address(0), "FeeSetter cannot be the zero address");
        _feeSetter = feeSetter;
        _isExcludedFromFee[feeSetter] = true;
        emit FeeSetterChanged (feeSetter);
    }
    
    // Contract initialised with fees disabled to enable presale to take place. This should be called once any presale is finished to enable fee-taking on transfers
    function enableAllFees() external onlyFeeSetter {
        _enableFees = true;
        _swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyEnabledUpdated (true);
    }
    
    // Disable fee-taking and stop swapping contract tokens to add to liquidity
    function disableAllFees() external onlyFeeSetter {
        _enableFees = false;
        _swapAndLiquifyEnabled = false;
        emit SwapAndLiquifyEnabledUpdated (false);
    }
    
    // Allows excluding from fees, which means transfers from and to are not taxed. Will be used for market-making deposits to centralised exchanges.
    // We may also need to do this if UFO will be used to deposit in farms (ref. Cerberus etc.)
    function excludeFromFee(address account) external onlyFeeSetter {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee (account);
    }
    
    // Allow excluded accounts to be included again (accounts are by default included in fee-taking)
    function includeInFee(address account) external onlyFeeSetter {
        _isExcludedFromFee[account] = false;
        emit IncludedInFee (account);
    }
    
    // Allows us to exclude addresses from getting rewards - probably used with centralised exchanges and farms alongside fee exclusion
    function excludeFromReward (address account) external onlyFeeSetter {
        require(account != address(this), "Can't exclude the contract address");
        require(!_isExcluded[account], "Account is already excluded");
        
        if(_reflectiveBalance[account] > 0) {
            _balance[account] = _tokenFromReflection(_reflectiveBalance[account]);
        }
        
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludedFromReward (account);
    }

    // Allow excluded accounts to be included again (accounts are by default included in the rewards)
    function includeInReward(address account) external onlyFeeSetter {
        require(_isExcluded[account], "Account is already included");
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                emit IncludedInReward (account);
                break;
            }
        }
    }
    
    
    // Allows changing of the router address which is used to create the LP pair and add liquidity.
    // This is to prevent the issues seen by renounced contracts when pancake moved from v1 to v2
    function setRouterAddress (address newRouter) external onlyFeeSetter {
        require (newRouter != address(0), "Router cannot be set to the zero address");
        IPancakeRouter02 newpancakeV2Router = IPancakeRouter02(newRouter);
        address newpancakeV2Pair = IPancakeFactory(newpancakeV2Router.factory()).createPair(address(this), newpancakeV2Router.WETH());
        _pancakeV2Pair = newpancakeV2Pair;
        _pancakeV2Router = newpancakeV2Router;
        emit RouterAndLPPairAddressChanged (newpancakeV2Router.factory(), newpancakeV2Pair);
    }
    
    // Sets the amount per thousand (permille) of the total transaction fee to go to each area, this allows setting decimal percentages (e.g. 2.5%)
    function setFeePermilles (uint256 totalFeePermille, uint256 liquidityFeePermille, uint256 structureFeePermille, uint256 holdersFeePermille, uint256 freelancerFeePermille) external onlyFeeSetter {
        require (liquidityFeePermille.add(structureFeePermille).add(holdersFeePermille).add(freelancerFeePermille) == 1000, "Fee permilles must add up to 1000");
        _totalFeePermille = totalFeePermille;
        _liquidityFeePermille = liquidityFeePermille;
        _structureFeePermille = structureFeePermille;
        _holdersFeePermille = holdersFeePermille;
        _freelancerFeePermille = freelancerFeePermille;
        emit FeePermillesUpdated (totalFeePermille, liquidityFeePermille, structureFeePermille, holdersFeePermille, freelancerFeePermille);
    }
    
    // Sets the maximum transfer possible as a permille (per thousand, allows setting decimal perentages to 1 decimal place e.g. 2.5%) of total supply. Set to 100% by default
    function setMaxTxPermille (uint256 maxTxPermille) external onlyFeeSetter {
        uint256 maxTxAmount = TOTAL_SUPPLY.mul(maxTxPermille).div(1000);
        require (maxTxAmount > MIN_CONTRACT_BALANCE_TO_ADD_LP, "Tx amount must be greater than liquidity add minimum");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmtUpdated (maxTxAmount);
    }

    // Allows the structure provider wallet address to be changed
    function setStructureProviderWallet (address newWallet) external onlyFeeSetter {
        _structureProviderWallet = newWallet;
        _isExcludedFromFee[newWallet] = true;
        emit WalletUpdated ("Structure Provider", newWallet);
    }

    // Allows the freelancer wallet address to be changed
    function setFreelancerWallet (address newWallet) external onlyFeeSetter {
        _freelancerWallet = newWallet;
        _isExcludedFromFee[newWallet] = true;
        emit WalletUpdated ("Freelancer", newWallet);
    }
    
    // Help users who accidentally send other tokens to the contract address
    // Does not affect the proper running of the contract - UFO is specifically prevented from being withdrawn in this way
    function withdrawOtherTokens (address _token) external nonReentrant onlyFeeSetter {
        require (_token != address(this), "Can't withdraw UFO from contract");
        IBEP20 token = IBEP20(_token);
        uint tokenBalance = token.balanceOf (address(this));
        token.transfer (_feeSetter, tokenBalance);
    }
    
    // Help users who accidentally send BNB to the contract address - this only removes BNB that has been manually transferred to the contract address
    // BNB that is created as part of the liquidity provision process will be sent to the pancake pair address and so will not be affected by this action
    function withdrawExcessBNB() external nonReentrant onlyFeeSetter {
        uint256 contractBNBBalance = address(this).balance;
        
        if (contractBNBBalance > 0)
            payable(_feeSetter).sendValue(contractBNBBalance);
    }

    function approve (address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance (address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance (address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Can't decrease allowance below zero"));
        return true;
    }

    function transfer (address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function isExcludedFromFee (address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    // Returns balance with reflections unless the address is excluded from reflection rewards
    function balanceOf (address account) public view override returns (uint256) {
        if (_isExcluded[account]) 
            return _balance[account];
        
        return _tokenFromReflection(_reflectiveBalance[account]);
    }
    
    function allowance (address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    // Take fees to contract and return transferAmount and amount to reflect
    function _getTransferAmount (uint256 amount) private returns (uint256, uint256, uint256) {
        uint256 currentRate =  _getRate();
        
        if (!_enableFees) {
            return (amount, amount.mul(currentRate), 0);
        } else {
            // Calculate the fee, relction fee, and transfer amount in both normal and reflective space
            uint256 fee = amount.mul(_totalFeePermille).div(FEE_DIVISOR);
            uint256 transferAmount = amount.sub(fee);
            uint256 reflectiveTransferAmount = transferAmount.mul(currentRate);
            uint256 holdersFee = fee.mul(_holdersFeePermille).div(FEE_DIVISOR);
            uint256 reflectiveHoldersFee = holdersFee.mul(currentRate);
            // Calculate the freelancerFee and send to the wallet
            uint256 freelancerFee = fee.mul(_freelancerFeePermille).div(FEE_DIVISOR);
            _takeTokenFee (freelancerFee, _freelancerWallet, currentRate);
            // Calculate other fees (structure and lqiuidity, and send them to the conrtract address so they can be swapped into BNB later
            uint256 otherFees = fee.sub(holdersFee).sub(freelancerFee);
            _takeTokenFee (otherFees, address(this),currentRate);
            emit FeeTransfer (fee);
            return (transferAmount, reflectiveTransferAmount, reflectiveHoldersFee);
        }
    }

    // Transfer fee amounts to wallets
    function _takeTokenFee (uint256 fee, address recipient, uint256 currentRate) private {
        uint256 reflectiveFee = fee.mul(currentRate);
        _reflectiveBalance[recipient] = _reflectiveBalance[recipient].add(reflectiveFee);
        
        if(_isExcluded[recipient])
            _balance[recipient] = _balance[recipient].add(fee);
    }
    
    function _approve (address owner, address spender, uint256 amount) private {
        require (owner != address(0), "Can't approve from the zero address");
        require (spender != address(0), "Can't approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Transfer tokens, taking fees and adding liquidity if the contract balance is large enough (and it is a token sale)
    function _transfer (address from, address to, uint256 amount) private {
        require (from != address(0), "Can't transfer from the zero address");
        require (to != address(0), "Can't transfer to the zero address");
        require (amount > 0, "Transfer amount must be greater than zero");
        
        if (from != owner() && to != owner())
            require (amount <= _maxTxAmount, "Transfer amount exceeds the max Tx amount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= _maxTxAmount)
            contractTokenBalance = _maxTxAmount;
        
        // Check the token balance of this contract is over the min number we need to initiate a swap + liquidity lock
        // Check we're not already adding liquidity and don't take fees if sender is the pancake pair (i.e. someone is buying UFO).
        if (contractTokenBalance >= MIN_CONTRACT_BALANCE_TO_ADD_LP && !_inSwapAndLiquify && from != _pancakeV2Pair && _swapAndLiquifyEnabled)
            _takeBNBFees (contractTokenBalance);
        
        bool takeFee = true;
        
        // If any account belongs to an _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to])
            takeFee = false;
        
        _tokenTransfer (from, to, amount, takeFee);
    }

    // Swap half the tokens for BNB, add tokens + BNB to the LP and take fee/burn amounts to fee/burn wallets
    function _takeBNBFees (uint256 contractTokenBalance) private lockTheSwap {
        uint256 bnbDivisor = _liquidityFeePermille.add(_structureFeePermille);
        uint256 liquidityBalance = contractTokenBalance.mul(_liquidityFeePermille).div(bnbDivisor);
        uint256 structureBalance = contractTokenBalance.mul(_structureFeePermille).div(bnbDivisor);
        
        // Split the liquidity balance into halves
        uint256 half = liquidityBalance.div(2);
        uint256 otherHalf = liquidityBalance.sub(half);
       
        // Swap half + structure fee amounts for BNB
        uint256 bnbReceived = _swapTokensForBNB (half.add(structureBalance)); 

        // Add liquidity to pancake - we know this is too much BNB so expect some to be returned
        uint256 bnbRemainder = _addLiquidity (otherHalf, bnbReceived);
        
        // Send the remaining BNB to the structure provider payable wallet
        payable(_structureProviderWallet).sendValue(bnbRemainder);
    }

    // Swap to BNB and return how much BNB we swapped for
    function _swapTokensForBNB (uint256 tokenAmount) private returns (uint256) {
        // Get the contract's current BNB balance so we know how much BNB the swap creates, and don't include any BNB that has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        
        // Generate the pancake pair path of UFO -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeV2Router.WETH();


        _approve (address(this), address(_pancakeV2Router), tokenAmount);

        // Make the swap
        _pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
        
        // How much BNB did we just swap into?
        return address(this).balance.sub(initialBalance);
    }

    // Add token and BNB to LP, returning the amount of any unused BNB
    function _addLiquidity (uint256 tokenAmount, uint256 bnbAmount) private returns (uint256) {
        // Approve token transfer to cover all possible scenarios
        _approve (address(this), address(_pancakeV2Router), tokenAmount);

        // Add the liquidity
        (, uint256 amountBNBFromLiquidityTx, ) = _pancakeV2Router.addLiquidityETH {value: bnbAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _feeSetter,
            block.timestamp
        );
        
        return (bnbAmount - amountBNBFromLiquidityTx);
    }

    // Calculate fees and transfer tokens
    function _tokenTransfer (address sender, address recipient, uint256 amount, bool takeFee) private {
        bool tempFeeEnabled = _enableFees;
        
        if (!takeFee)
            _enableFees = false;
        
        (uint256 transferAmount, uint256 reflectiveTransferAmount, uint256 reflectionFee) = _getTransferAmount (amount);
        
        if (_isExcluded[sender])
            _balance[sender] = _balance[sender].sub(amount);
        
        if (_isExcluded[recipient])
            _balance[recipient] = _balance[recipient].add(transferAmount);
            
        _reflectiveBalance[sender] = _reflectiveBalance[sender].sub(amount.mul(_getRate()));
        _reflectiveBalance[recipient] = _reflectiveBalance[recipient].add(reflectiveTransferAmount);
        _reflectiveTotal = _reflectiveTotal.sub(reflectionFee);
        emit Transfer (sender, recipient, transferAmount);
        
        if (!takeFee)
            _enableFees = tempFeeEnabled;
    }
    
    // Return the number of "normal" tokens an account has based on their reflective balance
    function _tokenFromReflection (uint256 reflectiveAmount) private view returns (uint256) {
        require(reflectiveAmount <= _reflectiveTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return reflectiveAmount.div(currentRate);
    }

    // Get the current conversion rate from reflected token balance to "normal" token balance
    function _getRate() private view returns (uint256) {
        (uint256 reflectiveSupply, uint256 supply) = _getCurrentSupply();
        return reflectiveSupply.div(supply);
    }

    // Get current token totals from wallets included in reflection
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 reflectiveSupply = _reflectiveTotal;
        uint256 supply = TOTAL_SUPPLY;      
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectiveBalance[_excluded[i]] > reflectiveSupply || _balance[_excluded[i]] > supply) 
                return (_reflectiveTotal, TOTAL_SUPPLY);
            
            reflectiveSupply = reflectiveSupply.sub(_reflectiveBalance[_excluded[i]]);
            supply = supply.sub(_balance[_excluded[i]]);
        }
        
        if (reflectiveSupply < _reflectiveTotal.div(TOTAL_SUPPLY)) 
            return (_reflectiveTotal, TOTAL_SUPPLY);
            
        return (reflectiveSupply, supply);
    }
}