/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

/**
 *  Wankit
 *  
 *  Come with us to the moon!!
 *  
 *  Using their significant experience in both wanking and cryptocurrency, the Wankit team have created a deflationary token ($WNKT) which will be used to access exclusive adult content on the WANKITtv platform.
 *  WANKITtv gives unique adult experiences through the safety and anonymity of blockchain technology, rewards $WNKT holders through passive reflection and contributes to making the adult industry a safer place for all.
 *
 *  The token features:
 *   - Sliding scale, anti-whale fee structure - the bigger your wallet, the bigger the fee per transaction (don't worry, having a big, swinging, uh, wallet has other perks)
 *   - 34% of the fee is auto-added to the liquidity pool to create a continually rising price floor
 *   - 33% of the fee is auto-distributed to all holders
 *   - 11% of the fee goes to the marketing wallet - keeping those exchange listings and influencer partnerships coming
 *   - 11% of the fee goes to the platform development wallet - gives holders trust that the team will continue to invest in the product (and means the devs get pizza breaks in the LONG, HARD hours they spend looking at the sexiest adult models WNKT can buy)
 *   - 11% of the fee goes to the charity wallet - helping to support workers in the sex trade around the world
 *   - 45% burned at launch - with a large burn and reflection the circulating supply will keep decreasing, putting more positive pressure on the token price
 *   
 *   Join our TG: https://t.me/WankitCummunity
 *   Visit our website: www.wankit.tv
 */

pragma solidity ^0.8.1;
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


contract Wankit is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;
    
    // We use the below to provide a simplified timelock scheme, instead of requiring a separate timelock contract
    // Separate contracts are complex to interact with and can cause undefined behaviour in the main contract if errors are made
    // Using the functionality below we still provide on-chain notifications about any major changes with a 12-hour window before they are enacted without the associated complexity and risks
    enum Functions { FEESETTER, ROUTER, MIN_MAX_FEE_BALANCE, FEE_FORMULA, FEE_PERC, MARKETING, PLATFORM, CHARITY, TIMELOCK }
    uint8 private constant TIMELOCKED = 0;
    uint8 private constant LIVE = 1;
    mapping (Functions => uint256) private _timelock;
    uint256[2] private _timelockDuration = [0, 2 minutes]; //CHANGEME, should be 12 hours
    uint256 private _pendingTimelockedChanges;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    address[2] private _feeSetter;
    
    string private constant _name = "Wankit";
    string private constant _symbol = "WNKT";
    uint8 private constant _decimals = 9;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address[2] private _marketingWallet;
    address[2] private _platformWallet;
    address[2] private _charityWallet;
    
    uint256[2] private _feeSecondOrderTerm = [0, 1];
    uint256[2] private _feeFirstOrderTerm = [0, 8 * 10**14];
    uint256[2] private _feeZerothOrderTerm = [0, 141 * 10**11];
    uint256[2] private _feeIntegerScalingFactor = [0, 10**16];
    
    uint256[2] private _liquidityFeePercentage = [0, 34];
    uint256[2] private _reflectionFeePercentage = [0, 33];
    uint256[2] private _marketingFeePercentage = [0, 11];
    uint256[2] private _charityFeePercentage = [0, 11];
    uint256[2] private _platformFeePercentage = [0, 11];

    IPancakeRouter02[2] public _pancakeswapV2Router;
    address public _pancakeswapV2Pair;
    
    bool private _lock;
    bool private _inSwapAndLiquify;
    bool private _swapAndLiquifyEnabled = true;
    
    bool private _enableFees = true; //enables fees being set by wallet size - disabled by calling disableAllFees()
    uint256[2] public _minFeeCeilingBalance = [0, 100000 * 10**_decimals]; //balance below which all Txes from the wallet address are taxed at the lowest rate
    uint256[2] public _maxFeeFloorBalance = [0, 1000000 * 10**_decimals]; //balance above which all Txes from the wallet address are taxed at the highest rate
    uint256 public _maxTxAmount = 1000000000 * 10**_decimals; //initialised to be disabled (set to total supply). Don't want this timelocked as will need to change quickly at DEX launch (low Tx initially to prevent easy presale dump and botting)
    uint256 private constant _numTokensSellToAddToLiquidity = 300000 * 10**_decimals; //minimum amount needed in contract before it's transferred to LP
    
    event MinTokensBeforeSwapUpdated (uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated (bool enabled);
    event IncludedInReward (address indexed account);
    event ExcludedFromReward (address indexed account);
    event IncludedInFee (address indexed account);
    event ExcludedFromFee (address indexed account);
    event RouterAndLPPairAddressChanged (address indexed newRouterFactory, address indexed newPair, bool changeEnacted, uint256 timestampToEnactChange);
    event MinMaxBalancesForFeeFormulaChanged (uint256 newMinFeeCeilingBalance, uint256 newMaxFeeFloorBalance, bool changeEnacted, uint256 timestampToEnactChange);
    event FeeFormulaUpdated (uint256 secondOrderTerm, uint256 firstOrderTerm, uint256 zerothOrderTerm, uint256 integerScalingFactor, bool changeEnacted, uint256 timestampToEnactChange);
    event FeePercentagesUpdated (uint256 reflectionFeePercentage, uint256 liquidityFeePercentage, uint256 marketingFeePercentage, uint256 charityFeePercentage, uint256 platformFeePercentage, bool changeEnacted, uint256 timestampToEnactChange);
    event MaxTxAmtUpdated (uint256 maxTxAmount);
    event WalletAddressUpdated (string walletName, address walletAddress, bool changeEnacted, uint256 timestampToEnactChange);
    event FeeTransfer (uint256 feeAmount);
    event FeeSetterChanged (address indexed newFeeSetter, bool changeEnacted, uint256 timestampToEnactChange);
    event AccidentallySentTokenWithdrawn (address indexed token, address indexed account, uint256 amount);
    event AccidentallySentBNBWithdrawn (address indexed account, uint256 amount);
    event TimelockChanged (uint256 numHours, bool changeEnacted, uint256 timestampToEnactChange);
    event TimelockChangesCancelled (Functions functionCancelled);
    event Debug (string debugText); //CHANGEME remove this
    
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
        require (_msgSender() == _feeSetter[LIVE], "Only accessible by feeSetter");
        _;
    }
    
    constructor (address marketingWallet, address platformWallet, address charityWallet) {
        _rOwned[_msgSender()] = _rTotal;
        _feeSetter[LIVE] = _msgSender();
        
        _marketingWallet[LIVE] = marketingWallet;
        _platformWallet[LIVE] = platformWallet;
        _charityWallet[LIVE] = charityWallet;
        
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E is the PCSv2 Router address CHANGEME
        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 is the PCS testnet
        // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 is the address of https://pancake.kiemtienonline360.com/
        IPancakeRouter02 pancakeswapV2Router = IPancakeRouter02 (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a pancakeswap pair for this new token
        _pancakeswapV2Pair = IPancakeFactory(pancakeswapV2Router.factory()).createPair(address(this), pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        _pancakeswapV2Router[LIVE] = pancakeswapV2Router;
        
        //exclude this contract and contract wallets from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet[LIVE]] = true;
        _isExcludedFromFee[_platformWallet[LIVE]] = true;
        _isExcludedFromFee[_charityWallet[LIVE]] = true;
        _isExcluded[_pancakeswapV2Pair] = true; //should stop skimming being successful
        _excluded.push(_pancakeswapV2Pair);
        
        emit Transfer (address(0), _msgSender(), _tTotal);
    }
    
     // To receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}
    
    // Change the feeSetter address - used for modifying elements of the tokenomics and whitelisting addresses when required (e.g. CEX listings)
    function setNewFeeSetter (address feeSetter) external onlyFeeSetter {
        require (feeSetter != address(0), "Can't set to the zero address");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.FEESETTER] = block.timestamp + _timelockDuration[LIVE];
        _feeSetter[TIMELOCKED] = feeSetter;
        _pendingTimelockedChanges += 1;
        emit FeeSetterChanged (feeSetter, false, _timelock[Functions.FEESETTER]);
    }
    
    // Change the timelock duration
    function setNewTimelock (uint256 numHours) external onlyFeeSetter {
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.TIMELOCK] = block.timestamp + _timelockDuration[LIVE];
        _timelockDuration[TIMELOCKED] = numHours * 1 hours;
        _pendingTimelockedChanges += 1;
        emit TimelockChanged (numHours, false, _timelock[Functions.TIMELOCK]);
    }
    
    // Cancel a pending change to a timelocked function
    function cancelTimelockedFunctionChange (Functions toCancel) external onlyFeeSetter {
        _timelock[toCancel] = 0;
        _pendingTimelockedChanges -= 1;
        emit TimelockChangesCancelled (toCancel);
    }
    
    // Contract initialised with fees disabled to enable presale to take place. This should be called once the presale is finished to enable fee-taking on transfers
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
    
    // Allows us to exclude addresses from getting rewards - probably used with centralised exchanges and farms alongside fee exclusion
    function excludeFromReward (address account) external onlyFeeSetter {
        require(account != address(this), "Can't exclude the contract address");
        require(!_isExcluded[account], "Account is already excluded");
        
        if(_rOwned[account] > 0) {
            _tOwned[account] = _tokenFromReflection(_rOwned[account]);
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
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                emit IncludedInReward (account);
                break;
            }
        }
    }
    
    // Allows excluding from fees, which means transfers from and to are not taxed. Will be used for market-making deposits to centralised exchanges.
    // We may also need to do this if WNKT will be used to deposit in farms (ref. Cerberus etc.)
    function excludeFromFee(address account) external onlyFeeSetter {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee (account);
    }
    
    // Allow excluded accounts to be included again (accounts are by default included in fee-taking)
    function includeInFee(address account) external onlyFeeSetter {
        _isExcludedFromFee[account] = false;
        emit IncludedInFee (account);
    }
    
    // Allows changing of the router address which is used to create the LP pair and add liquidity.
    // This is to prevent the issues seen by renounced contracts when PCS moved from v1 to v2
    function setRouterAddress (address newRouter) external onlyFeeSetter {
        require (newRouter != address(0), "Router cannot be set to the zero address");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.ROUTER] = block.timestamp + _timelockDuration[LIVE];
        IPancakeRouter02 newPancakeswapV2Router = IPancakeRouter02(newRouter);
        _pancakeswapV2Router[TIMELOCKED] = newPancakeswapV2Router;
        _pendingTimelockedChanges += 1;
        emit RouterAndLPPairAddressChanged (newPancakeswapV2Router.factory(), address(0), false, _timelock[Functions.ROUTER]);
    }
    
    // Allows modifying the minimum and maximum wallet balances where the fee formula starts to take effect.
    // Below the minimum balance fees are set to the minimum balance rate, above the maximum balance fees are capped at the maximum balance rate.
    function setMinMaxBalancesForFeeFormula (uint256 minFeeCeilingBalance, uint256 maxFeeFloorBalance) external onlyFeeSetter {
        require (maxFeeFloorBalance > minFeeCeilingBalance, "maxFeeFloorBalance must be greater than minFeeCeilingBalance");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.MIN_MAX_FEE_BALANCE] = block.timestamp + _timelockDuration[LIVE];
        _minFeeCeilingBalance[TIMELOCKED] = minFeeCeilingBalance;
        _maxFeeFloorBalance[TIMELOCKED] = maxFeeFloorBalance;
        _pendingTimelockedChanges += 1;
        emit MinMaxBalancesForFeeFormulaChanged (minFeeCeilingBalance, maxFeeFloorBalance, false,  _timelock[Functions.MIN_MAX_FEE_BALANCE]);
    }
    
    // Allows the fee formula that sets the rates between the minimum and maximum balances to be modified 
    function setFeeFormula (uint256 feeSecondOrderTerm, uint256 feeFirstOrderTerm, uint256 feeZerothOrderTerm, uint256 feeIntegerScalingFactor) external onlyFeeSetter {
        require (feeIntegerScalingFactor != 0, "feeIntegerScalingFactor cannot be zero");
        _timelock[Functions.FEE_FORMULA] = block.timestamp + _timelockDuration[LIVE];
        _feeSecondOrderTerm[TIMELOCKED] = feeSecondOrderTerm;
        _feeFirstOrderTerm[TIMELOCKED] = feeFirstOrderTerm;
        _feeZerothOrderTerm[TIMELOCKED] = feeZerothOrderTerm;
        _feeIntegerScalingFactor[TIMELOCKED] = feeIntegerScalingFactor;
        _pendingTimelockedChanges += 1;
        emit FeeFormulaUpdated (feeSecondOrderTerm, feeFirstOrderTerm, feeZerothOrderTerm, feeIntegerScalingFactor, false, _timelock[Functions.FEE_FORMULA]);
    }
    
    // Sets the percentages of the total transaction fee to go to each area
    function setFeePercentages (uint256 reflectionFeePercentage, uint256 liquidityFeePercentage, uint256 marketingFeePercentage, uint256 charityFeePercentage, uint256 platformFeePercentage) external onlyFeeSetter {
        require (reflectionFeePercentage.add(liquidityFeePercentage).add(marketingFeePercentage).add(charityFeePercentage).add(platformFeePercentage) == 100, "Fee percentages must add up to 100");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.FEE_PERC] = block.timestamp + _timelockDuration[LIVE];
        _reflectionFeePercentage[TIMELOCKED] = reflectionFeePercentage;
        _liquidityFeePercentage[TIMELOCKED] = liquidityFeePercentage;
        _marketingFeePercentage[TIMELOCKED] = marketingFeePercentage;
        _charityFeePercentage[TIMELOCKED] = charityFeePercentage;
        _platformFeePercentage[TIMELOCKED] = platformFeePercentage;
        _pendingTimelockedChanges += 1;
        emit FeePercentagesUpdated (reflectionFeePercentage, liquidityFeePercentage, marketingFeePercentage, charityFeePercentage, platformFeePercentage, false, _timelock[Functions.FEE_PERC]);
    }
    
    // Sets the maximum transfer possible as a percentage of total supply. Set to 100% by default
    // Allows a minimum Tx percentage of 0.1%
    function setMaxTxPercent (uint256 maxTxPercent) external onlyFeeSetter {
        require (maxTxPercent > 0, "Can't set to 0");
        require (maxTxPercent <= 1000, "Can't set to > 100%");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(1000);
        emit MaxTxAmtUpdated (_maxTxAmount);
    }

    // Allows the marketing wallet address to be changed
    function setMarketingWallet (address newWallet) external onlyFeeSetter {
        require (newWallet != address(0), "Can't set to zero address");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.MARKETING] = block.timestamp + _timelockDuration[LIVE];
        _marketingWallet[TIMELOCKED] = newWallet;
        _pendingTimelockedChanges += 1;
        emit WalletAddressUpdated ("Marketing", newWallet, false, _timelock[Functions.MARKETING]);
    }

    // Allows the platform development wallet address to be changed
    function setPlatformWallet (address newWallet) external onlyFeeSetter {
        require (newWallet != address(0), "Can't set to zero address");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.PLATFORM] = block.timestamp + _timelockDuration[LIVE];
        _platformWallet[TIMELOCKED] = newWallet;
        _pendingTimelockedChanges += 1;
        emit WalletAddressUpdated ("Platform", newWallet, false, _timelock[Functions.PLATFORM]);
    }


    // Allows the charity wallet address to be changed
    function setCharityWallet (address newWallet) external onlyFeeSetter {
        require (newWallet != address(0), "Can't set to zero address");
        // We don't care if the timelock countdown has already been started - this enables us to correct mistakes without neededing to cancel the change
        // Save the update, set the time the change will be made, and emit an event to say what change will be made when
        _timelock[Functions.CHARITY] = block.timestamp + _timelockDuration[LIVE];
        _charityWallet[TIMELOCKED] = newWallet;
        _pendingTimelockedChanges += 1;
        emit WalletAddressUpdated ("Charity", newWallet, false, _timelock[Functions.CHARITY]);
    }
    
    // Help users who accidentally send tokens to the contract address
    // Does not affect the proper running of the contract - WNKT is specifically prevented from being withdrawn in this way
    function withdrawOtherTokens (address _token, address _account) external nonReentrant onlyFeeSetter {
        require (_token != address(this), "Can't withdraw WNKT from contract");
        IBEP20 token = IBEP20(_token);
        uint tokenBalance = token.balanceOf (address(this));
        token.transfer (_account, tokenBalance);
        emit AccidentallySentTokenWithdrawn (_token, _account, tokenBalance);
    }
    
    // Help users who accidentally send BNB to the contract address - this only removes BNB that has been manually transferred to the contract address
    // BNB that is created as part of the liquidity provision process will be sent to the PCS pair address and so will not be affected by this action
    function withdrawExcessBNB (address _account) external nonReentrant onlyFeeSetter {
        uint256 contractBNBBalance = address(this).balance;
        
        if (contractBNBBalance > 0)
            payable(_account).sendValue(contractBNBBalance);
        
        emit AccidentallySentBNBWithdrawn (_account, contractBNBBalance);
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
    
    function getMarketingWallet() public view returns (address) {
        return _marketingWallet[LIVE];
    }
    
    function getPlatformWallet() public view returns (address) {
        return _platformWallet[LIVE];
    }
    
    function getCharityWallet() public view returns (address) {
        return _charityWallet[LIVE];
    }
    
    function getFeeSetter() public view returns (address) {
        return _feeSetter[LIVE];
    }
    
    function getTimelockDuration() public view returns (uint256) {
        return _timelockDuration[LIVE];
    }

    // Returns balance with reflections unless the address is excluded from reflection rewards
    function balanceOf (address account) public view override returns (uint256) {
        if (_isExcluded[account]) 
            return _tOwned[account];
        
        return _tokenFromReflection(_rOwned[account]);
    }
    
    function allowance (address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcludedFromReward (address account) public view returns (bool) {
        return _isExcluded[account];
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
    
    // Check whether any timelocked changes are waiting to take effect
    // Anyone can call this as it will only make changes if there's an approved change by feeSetter that has passed the timelock time
    function enactAvailableTimelockChanges() public {
        emit Debug("Trying timelock changes");
        _setNewFeeSetter();
        _setNewTimelock();
        _setRouterAddress();
        _setMinMaxBalancesForFeeFormula();
        _setFeeFormula();
        _setFeePercentages();
        _setMarketingWallet();
        _setPlatformWallet();
        _setCharityWallet();
    }

    // Calculate both the excluded and reflective amounts to transfer between wallets
    function _getValues (uint256 senderBalance, uint256 tAmount) private returns (uint256, uint256, uint256, uint256) {
        if (!_enableFees) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectionFee) = _getRValues (tAmount, 0, 0, _getRate());
            return (rAmount, rTransferAmount, rReflectionFee, tAmount);
        } else {
            if (senderBalance < _minFeeCeilingBalance[LIVE]) {
                senderBalance = _minFeeCeilingBalance[LIVE];
            } else if (senderBalance > _maxFeeFloorBalance[LIVE]) {
                senderBalance = _maxFeeFloorBalance[LIVE];
            }
            
            uint256 unscaledFeeLimit = _feeSecondOrderTerm[LIVE].mul(senderBalance).mul(senderBalance).add(_feeFirstOrderTerm[LIVE].mul(senderBalance)).add(_feeZerothOrderTerm[LIVE]);
            uint256 scaledTxTotalFee = unscaledFeeLimit.mul(tAmount).div(senderBalance).div(_feeIntegerScalingFactor[LIVE]);
            uint256 tTransferAmount = tAmount.sub(scaledTxTotalFee);
            uint256 tReflectionFee = scaledTxTotalFee.mul(_reflectionFeePercentage[LIVE]).div(100);
            uint256 tOtherFees = scaledTxTotalFee.sub(tReflectionFee);
            _takeTokenFee (tOtherFees);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectionFee) = _getRValues (tAmount, tReflectionFee, tOtherFees, _getRate());
            return (rAmount, rTransferAmount, rReflectionFee, tTransferAmount);
        }
    }

    // Transfer fee amounts to wallets
    function _takeTokenFee (uint256 tFee) private {
        address recipient = address(this);
        uint256 currentRate =  _getRate();
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[recipient] = _rOwned[recipient].add(rFee);
        
        if(_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(tFee);
            
        emit FeeTransfer (tFee);
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
        // Check we're not already adding liquidity and don't take fees if sender is the PCS pair (i.e. someone is buying WNKT).
        if (contractTokenBalance >= _numTokensSellToAddToLiquidity && !_inSwapAndLiquify && from != _pancakeswapV2Pair && _swapAndLiquifyEnabled)
            _takeBNBFees (contractTokenBalance);
        
        bool takeFee = true;
        
        // If any account belongs to an _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to])
            takeFee = false;
        
        _tokenTransfer (from, to, amount, takeFee);
    }

    // Swap half the tokens for BNB, add tokens + BNB to the LP and take fee amounts to fee wallets
    function _takeBNBFees (uint256 contractTokenBalance) private lockTheSwap {
        uint256 feeDivisor = _liquidityFeePercentage[LIVE].add(_marketingFeePercentage[LIVE]).add(_platformFeePercentage[LIVE]).add(_charityFeePercentage[LIVE]);
        uint256 liquidityBalance = contractTokenBalance.mul(_liquidityFeePercentage[LIVE]).div(feeDivisor);
        uint256 otherBalance = contractTokenBalance.sub(liquidityBalance);
        
        // Split the liquidity balance into halves
        uint256 half = liquidityBalance.div(2);
        uint256 otherHalf = liquidityBalance.sub(half);
       
       // Swap half + other fee amounts for BNB
        uint256 bnbReceived = _swapTokensForBNB (half.add(otherBalance)); 

        // Add liquidity to PCS - we know this is too much BNB so expect some to be returned
        uint256 bnbRemainder = _addLiquidity (otherHalf, bnbReceived);
        
        // Calculate the amount to distribute to each wallet and transfer it
        feeDivisor = feeDivisor.sub(_liquidityFeePercentage[LIVE]);
        uint256 marketingBalance = bnbRemainder.mul(_marketingFeePercentage[LIVE]).div(feeDivisor);
        uint256 charityBalance = bnbRemainder.mul(_charityFeePercentage[LIVE]).div(feeDivisor);
        uint256 platformBalance = bnbRemainder.sub(marketingBalance).sub(charityBalance);
        payable(_marketingWallet[LIVE]).sendValue(marketingBalance);
        payable(_charityWallet[LIVE]).sendValue(charityBalance);
        payable(_platformWallet[LIVE]).sendValue(platformBalance);
    }

    // Swap to BNB and return how much BNB we swapped for
    function _swapTokensForBNB (uint256 tokenAmount) private returns (uint256) {
        // Get the contract's current BNB balance so we know how much BNB the swap creates, and don't include any BNB that has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        
        // Generate the pancakeswap pair path of WNKT -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router[LIVE].WETH();

        _approve (address(this), address(_pancakeswapV2Router[LIVE]), tokenAmount);

        // Make the swap
        _pancakeswapV2Router[LIVE].swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        _approve (address(this), address(_pancakeswapV2Router[LIVE]), tokenAmount);

        // Add the liquidity
        (, uint256 amountBNBFromLiquidityTx, ) = _pancakeswapV2Router[LIVE].addLiquidityETH {value: bnbAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _feeSetter[LIVE],
            block.timestamp
        );
        
        return (bnbAmount - amountBNBFromLiquidityTx);
    }

    // Calculate fees and transfer tokens
    function _tokenTransfer (address sender, address recipient, uint256 tAmount, bool takeFee) private {
        bool tempFeeEnabled = _enableFees;
        uint256 balanceForFees = 0;
        
        if (!takeFee)
            _enableFees = false;
            
        // If buying, sender will be PCS pair, so tax based on recipient's wallet
        if (sender == _pancakeswapV2Pair)
            balanceForFees = balanceOf (recipient);
        else
            balanceForFees = balanceOf (sender);
            
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount) = _getValues (balanceForFees, tAmount);
        
        if (_isExcluded[sender])
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        
        if (_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee (rFee);
        emit Transfer (sender, recipient, tTransferAmount);
        
        if (!takeFee)
            _enableFees = tempFeeEnabled;
         
        // If there are pending changes under timelock then we want to make sure these are processed
        // This avoids the need to submit multiple transactions to confirm a change
        if (_pendingTimelockedChanges > 0)    
            enactAvailableTimelockChanges();
    }

    // Modifies global variables that control the reflection earned by all wallets
    function _reflectFee (uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);
    }
    
    // Set a new charity wallet once timelock has expired
    function _setCharityWallet() private {
        if (_timelock[Functions.CHARITY] != 0 && block.timestamp > _timelock[Functions.CHARITY]) {
            _timelock[Functions.CHARITY] = 0;
            address newWallet = _platformWallet[TIMELOCKED];
            _isExcludedFromFee[newWallet] = true;
            _pendingTimelockedChanges -= 1;
            emit WalletAddressUpdated ("Charity", newWallet, true, 0);
        }
    }
    
    // Set a new platform wallet once timelock has expired
    function _setPlatformWallet() private {
        if (_timelock[Functions.PLATFORM] != 0 && block.timestamp > _timelock[Functions.PLATFORM]) {
            _timelock[Functions.PLATFORM] = 0;
            address newWallet = _platformWallet[TIMELOCKED];
            _isExcludedFromFee[newWallet] = true;
            _pendingTimelockedChanges -= 1;
            emit WalletAddressUpdated ("Platform", newWallet, true, 0);
        }
    }
    
    // Set a new marketing wallet once timelock has expired
    function _setMarketingWallet() private {
        if (_timelock[Functions.MARKETING] != 0 && block.timestamp > _timelock[Functions.MARKETING]) {
            _timelock[Functions.MARKETING] = 0;
            address newWallet = _marketingWallet[TIMELOCKED];
            _isExcludedFromFee[newWallet] = true;
            _pendingTimelockedChanges -= 1;
            emit WalletAddressUpdated ("Marketing", newWallet, true, 0);
        }
    }
    
    // Change fee percentages once timelock has expired
    function _setFeePercentages() private {
        if (_timelock[Functions.FEE_PERC] != 0 && block.timestamp > _timelock[Functions.FEE_PERC]) {
            _timelock[Functions.FEE_PERC] = 0;
            uint256 reflectionFeePercentage = _reflectionFeePercentage[TIMELOCKED];
            uint256 liquidityFeePercentage = _liquidityFeePercentage[TIMELOCKED];
            uint256 marketingFeePercentage = _marketingFeePercentage[TIMELOCKED];
            uint256 charityFeePercentage = _charityFeePercentage[TIMELOCKED];
            uint256 platformFeePercentage = _platformFeePercentage[TIMELOCKED];
            _reflectionFeePercentage[LIVE] = reflectionFeePercentage;
            _liquidityFeePercentage[LIVE] = liquidityFeePercentage;
            _marketingFeePercentage[LIVE] = marketingFeePercentage;
            _charityFeePercentage[LIVE] = charityFeePercentage;
            _platformFeePercentage[LIVE] = platformFeePercentage;
            _pendingTimelockedChanges -= 1;
            emit FeePercentagesUpdated (reflectionFeePercentage, liquidityFeePercentage, marketingFeePercentage, charityFeePercentage, platformFeePercentage, true, 0);
        }
    }
    
    // Set a new fee formula once the timelock has expired
    function _setFeeFormula() private {
        if (_timelock[Functions.FEE_FORMULA] != 0 && block.timestamp > _timelock[Functions.FEE_FORMULA]) {
            _timelock[Functions.FEE_FORMULA] = 0;
            uint256 feeSecondOrderTerm = _feeSecondOrderTerm[TIMELOCKED];
            uint256 feeFirstOrderTerm = _feeFirstOrderTerm[TIMELOCKED];
            uint256 feeZerothOrderTerm = _feeZerothOrderTerm[TIMELOCKED];
            uint256 feeIntegerScalingFactor = _feeIntegerScalingFactor[TIMELOCKED];
            _feeSecondOrderTerm[LIVE] = feeSecondOrderTerm;
            _feeFirstOrderTerm[LIVE] = feeFirstOrderTerm;
            _feeZerothOrderTerm[LIVE] = feeZerothOrderTerm;
            _feeIntegerScalingFactor[LIVE] = feeIntegerScalingFactor;
            _timelock[Functions.FEE_FORMULA] = 0;
            _pendingTimelockedChanges -= 1;
            emit FeeFormulaUpdated (feeSecondOrderTerm, feeFirstOrderTerm, feeZerothOrderTerm, feeIntegerScalingFactor, true, 0);
        } 
    }
    
    // Change min/max fee limits once timelock has expired 
    function _setMinMaxBalancesForFeeFormula() private {
        if (_timelock[Functions.MIN_MAX_FEE_BALANCE] != 0 && block.timestamp > _timelock[Functions.MIN_MAX_FEE_BALANCE]) {
            _timelock[Functions.MIN_MAX_FEE_BALANCE] = 0;
            uint256 minFeeCeilingBalance = _minFeeCeilingBalance[TIMELOCKED];
            uint256 maxFeeFloorBalance = _maxFeeFloorBalance[TIMELOCKED];
            _minFeeCeilingBalance[LIVE] = minFeeCeilingBalance;
            _maxFeeFloorBalance[LIVE] = maxFeeFloorBalance;
            _pendingTimelockedChanges -= 1;
            emit MinMaxBalancesForFeeFormulaChanged (minFeeCeilingBalance, maxFeeFloorBalance, true,  0);
        }
     }
    
    //Set a new router and pair address once the timelock has expired
    function _setRouterAddress () private {
        if (_timelock[Functions.ROUTER] != 0 && block.timestamp > _timelock[Functions.ROUTER]) {
            _timelock[Functions.ROUTER] = 0;
            IPancakeRouter02 newPancakeswapV2Router = _pancakeswapV2Router[TIMELOCKED];
            address newPancakeswapV2Pair = IPancakeFactory(newPancakeswapV2Router.factory()).createPair(address(this), newPancakeswapV2Router.WETH());
            _pancakeswapV2Router[LIVE] = newPancakeswapV2Router;
            _pancakeswapV2Pair = newPancakeswapV2Pair;
            _isExcluded[newPancakeswapV2Pair] = true; //should stop skimming being successful
            _excluded.push(newPancakeswapV2Pair);
            _pendingTimelockedChanges -= 1;
            emit RouterAndLPPairAddressChanged (newPancakeswapV2Router.factory(), newPancakeswapV2Pair, true, 0);
        }
    }
    
    // Change the timelock duration once timelock has expired
    function _setNewTimelock() private {
        if (_timelock[Functions.TIMELOCK] != 0 && block.timestamp > _timelock[Functions.TIMELOCK]) {
            _timelock[Functions.TIMELOCK] = 0;
            uint256 numHours = _timelockDuration[TIMELOCKED];
            _timelockDuration[LIVE] = numHours;
            _pendingTimelockedChanges -= 1;
            emit TimelockChanged (numHours, true, 0);
        }
    }
    
    // Change the feeSetter address once timelock has expired
    function _setNewFeeSetter() private {
        if (_timelock[Functions.FEESETTER] != 0 && block.timestamp > _timelock[Functions.FEESETTER]) {
            _timelock[Functions.FEESETTER] = 0;
            address feeSetter = _feeSetter[TIMELOCKED];
            _feeSetter[LIVE] = feeSetter;
            _pendingTimelockedChanges -= 1;
            emit FeeSetterChanged (feeSetter, true, 0);
        }
    }
    
    // Return the number of "normal" tokens an account has based on their reflective balance
    function _tokenFromReflection (uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    // Get the current conversion rate from reflected token balance to "normal" token balance
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    // Get current token totals from wallets included in reflection
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) 
                return (_rTotal, _tTotal);
            
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        
        if (rSupply < _rTotal.div(_tTotal)) 
            return (_rTotal, _tTotal);
            
        return (rSupply, tSupply);
    }
    
    // Get transfer and fee amounts in reflectied token-space
    function _getRValues (uint256 tAmount, uint256 tReflectionFee, uint256 tOtherFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflectionFee = tReflectionFee.mul(currentRate);
        uint256 rOtherFees = tOtherFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflectionFee).sub(rOtherFees);
        return (rAmount, rTransferAmount, rReflectionFee);
    }
}