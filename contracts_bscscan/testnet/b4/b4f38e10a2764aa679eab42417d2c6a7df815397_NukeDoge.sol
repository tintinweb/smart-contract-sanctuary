/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
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
 * @dev Module that provides a way of preventing transactions with excessive gas prices from being executed. Intended to prevent front running.
 */
abstract contract GasThrottled is Ownable {
    using SafeMath for uint256;
    
    bool private _gasThrottleEnabled = true;
    uint256 private _gasLimit = 10 * 10**9; // Gwei
    
    modifier gasThrottled() {
        if (_gasThrottleEnabled) {
            require(tx.gasprice <= _gasLimit, "GasThrottled: You cannot spend that much on gas.");
        }
        _;
    }
    
    function setGasThrottleState(bool state) external onlyOwner {
        _gasThrottleEnabled = state;
    }
    
    function setGasLimitGwei(uint256 gasLimit) external onlyOwner {
        require(gasLimit >= 6, "GasThrottled: cannot set gasLimit this low. The contract must remain usable.");
        _gasLimit = gasLimit * 10**9; // Gwei
    }
    
    function getGasLimitGwei() external view returns (uint256) {
        return _gasLimit.div(10**9);
    }
}

/**
 * @dev Token module that provides a way of preventing early dumping of a token.
 *
 * Tracks both 'fair' and 'dumped' tokens. Implementation details are up to the contract using this module, but generally speaking:
 *      Tokens purchased from an exchange are considered 'fair'.
 *      Tokens sold on an exchange are considered 'dumped'.
 *      Token transfers between wallets are counted as 'fair' for the sender and 'dumped' for the receiver to prevent circumvention.
 * 
 * When selling, the wallets 'fair' tokens are consumed until 0, at which point 'dumped' tokens begin accumulating.
 * In order for a transaction to succeed, this module requires that the total amount of 'dumped' tokens in the wallet performing the transaction does not exceed the "max dumpable tokens".
 * 
 * The value of "max dumpable tokens" is calculated using the seconds elapsed since the contract was activated, multiplied by _dumpRate. This means that the value increases over time.
 * 
 * This module is used via inheritence and provides the protectOutgoingTokens and protectIncomingTokens functions. Call these during transfers to ensure proper tracking and dump protection.
 * _registeredSenders is a mapping of addresses that will not trigger any tracking when they send tokens. Presale address(es) are intended to be registered here.
 * _excludedFromTracking is also a mapping of addresses. Liquidity pools are intended to be mapped here.
 */
abstract contract DumpProtectedToken is Ownable {
    using SafeMath for uint256;
    uint256 private MAX = ~uint256(0);
    
    bool private _protectionActive = false; 
    bool private _protectionDisabled = false;
    uint256 private _activationTime;
    uint256 private _dumpRate = 10**5 * 10**9;
    
    mapping(address => uint256) _fairTokens;
    mapping(address => uint256) _dumpedTokens;
    
    mapping(address => bool) private _registeredSenders;
    mapping(address => bool) private _excludedFromTracking;
    
    constructor() internal {
        _registeredSenders[owner()] = true;
        _excludedFromTracking[owner()] = true;
        
        _registeredSenders[address(this)] = true;
        _excludedFromTracking[address(this)] = true;
    }
    
    function activateDumpProtection() public onlyOwner {
        require(!_protectionActive, "DumpProtectedToken: Protection has already been activated.");
        _activationTime = block.timestamp;
        _protectionActive = true;
    }

    /** 
     * @dev permanantly disables dump protection. After the launch period of a token is over, disabling dump protection is a good idea to save gas.
     */
    function disableDumpProtection() external onlyOwner {
        _protectionDisabled = false;
    }

    function setDumpRate(uint256 dumpRateTokensPerSecond) public onlyOwner {
        require(dumpRateTokensPerSecond > 10**5, "DumpProtectedToken: cannot set dump rate too low. Presalers must be able to sell in a timely manner.");
        _dumpRate = dumpRateTokensPerSecond.mul(10**9); // Hard coded for 9 decimals
    }
    
    function setRegisteredSenderForDumpTracking(address wallet, bool isRegistered) external {
        _registeredSenders[wallet] = isRegistered;
    }
    
    function setExcludedFromDumpTracking(address wallet, bool isExcluded) external {
        _excludedFromTracking[wallet] = isExcluded;
    }
    
    function isExcludedFromDumpTracking(address wallet) view public returns (bool) {
        return _excludedFromTracking[wallet];
    } 
    
    function isRegisterdSenderForDumpTracking(address wallet) view public returns (bool) {
        return _registeredSenders[wallet];
    } 
    
    function protectOutgoingTokens(address sender, uint256 amount) internal {
        if (_protectionActive && !_protectionDisabled && !_registeredSenders[sender] && !_excludedFromTracking[sender]) {
            amount = _removeFairTokens(sender, amount);
            _addDumpedTokens(sender, amount);
        }
    }
    
    function protectIncomingTokens(address sender, address receiver, uint256 amount) internal {
        if (_protectionActive && !_protectionDisabled && !_registeredSenders[sender] && !_excludedFromTracking[receiver]) {
            amount = _removeDumpedTokens(receiver, amount);
            _addFairTokens(receiver, amount);
        }
    }

    function _addFairTokens(address wallet, uint256 amount) private {
        _fairTokens[wallet] = _fairTokens[wallet].add(amount);
    }

    function _removeFairTokens(address wallet, uint256 amount) private returns (uint256) {
        uint tokens = _fairTokens[wallet];
        if (tokens < amount) {
            _fairTokens[wallet] = 0;
            return amount.sub(tokens);
        } else {
            _fairTokens[wallet] = tokens.sub(amount);
            return 0;
        }
    }

    function _addDumpedTokens(address wallet, uint256 amount) private {
        uint tokensDumped = _dumpedTokens[wallet].add(amount);
        require(tokensDumped <= maxDumpableTokens(), "DumpProtectedToken: This transaction puts you over the dumping limit. Please wait and try again later.");
        _dumpedTokens[wallet] = tokensDumped;
    }

    function _removeDumpedTokens(address wallet, uint256 amount) private returns (uint256) {
        uint tokens = _dumpedTokens[wallet];
        if (tokens < amount) {
            _dumpedTokens[wallet] = 0;
            return amount.sub(tokens);
        } else {
            _dumpedTokens[wallet] = tokens.sub(amount);
            return 0;
        }
    }
    
    function maxDumpableTokens() view public returns (uint256) {
        uint256 secondsSinceActivation = (block.timestamp).sub(_activationTime);
        (bool validMul, uint result) = secondsSinceActivation.tryMul(_dumpRate);
        if (validMul) {
            return result;
        }
        return MAX; // MAX uint
    }
}

abstract contract PresalableToken is Ownable, IERC20 {
    
    address private _presaleManager;
    bool public _presaleStarted = false;
    bool public _presaleOver = false;
    bool private _presaleManagerTokensSent = false;

    event PresaleStarted(uint256 timestamp);
    event PresaleEnded(uint256 timestamp);

    /**
     * @dev Returns the address of the current presaleManager.
     */
    function presaleManager() external view returns (address) {
        return _presaleManager;
    }

    function setPresaleManager(address presaleManagerAddress) external virtual onlyOwner {
        _presaleManager = presaleManagerAddress;
    }

    /**
     * @dev Throws if called by any account/contract other than the chosen presale manager.
     */
    modifier onlyPresaleManager() {
        require(_presaleManager == _msgSender(), "PresalableToken: caller is not the presale manager");
        _;
    }
    
    function startPresale() external virtual onlyPresaleManager {
        _presaleStarted = true;
        emit PresaleStarted(block.timestamp);
    }
    
    function endPresale() external virtual onlyPresaleManager {
        require(_presaleStarted, "PresalableToken: the presale has not even started");
        _presaleOver = true;
        emit PresaleEnded(block.timestamp);
    }
    
    /**
     * @dev Throws if the presale is not complete.
     */
    modifier presaleIsComplete() {
        require(_presaleStarted, "PresalableToken: the presale has not started");
        require(_presaleOver, "PresalableToken: the presale is not over");
        _;
    }
    
    /**
     * @dev Throws if the presale is not started.
     */
    modifier presaleIsStarted() {
        require(_presaleStarted, "PresalableToken: the presale has not started");
        _;
    }
    
    function isPresaleStarted() view external returns (bool) {
        return _presaleStarted;
    }
    
    function isPresaleComplete() view external returns (bool) {
        return _presaleStarted && _presaleOver;
    }
    
    function sendTokensToPresaleBuyer(address recipient, uint256 amount) external onlyPresaleManager presaleIsComplete {
        _sendTokensToPresaleBuyer(recipient, amount);
    }
    function _sendTokensToPresaleBuyer(address recipient, uint256 amount) virtual internal;
    
    function retrieveRequiredPresaleTokens(uint256 tAmount) external onlyPresaleManager {
        require(_presaleStarted && !_presaleOver, "PresalableToken: presale must be active");
        require(!_presaleManagerTokensSent, "PresalableToken: presale manager already claimed its tokens");
        
        _presaleManagerTokensSent = true;
        _retrieveRequiredPresaleTokens(tAmount);
    }
    function _retrieveRequiredPresaleTokens(uint256 tAmount) virtual internal;
}

/*
   NukeDOGE - A Deflationary Token Funding Alternative and Sustainable Energy – Because Our Planet Matters.
   
   Telegram: https://https://t.me/NukeDoge
   Website: https://nukedoge.com
   Discord: https://discord.gg/JtTD9mU5uM
   
   Buy Fees:
        Total - 8%
            2% - Redist
            3% - Liquidity
            2% - Marketing
            1% - Charity
        
   Sell Fees:
        Total - 10%
            3% - Redist
            3% - Liquidity
            2% - Marketing
            2% - Charity

    Forked and substantially modified from SwiftInu
 */
contract NukeDoge is Context, PresalableToken, DumpProtectedToken, GasThrottled {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "NukeDOGE";
    string private _symbol = "TEST69";
    uint8 private _decimals = 9;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    //address payable public _marketingAddress = payable(0x65b3C3A153D7B7De5b086D1d56d0cF4B261355C8); // Mainnet
    //address payable public _charityAddress = payable(0x0ADab643d3B8A98BD1C24Ed8bfcd0129943e9233); // Mainnet
    
    address payable public _marketingAddress = payable(0x3A99f527CC1BAAC09244f152a690B08cCcc9feA9); // Testnet
    address payable public _charityAddress = payable(0x3A99f527CC1BAAC09244f152a690B08cCcc9feA9); // Testnet
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**12 * 10**9;
    
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 public _buyTaxFee = 2;
    uint256 public _sellTaxFee = 3;
    uint256 public _activeTaxFee = 0;
    
    uint256 public _buyLiquidityFee = 3;
    uint256 public _sellLiquidityFee = 3;
    uint256 public _activeLiquidityFee = 0;

    uint256 public _buyMarketingFee = 2;
    uint256 public _sellMarketingFee = 2;
    uint256 public _activeMarketingFee = 0;

    uint256 public _buyCharityFee = 1;
    uint256 public _sellCharityFee = 2;
    uint256 public _activeCharityFee = 0;

    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    
    bool _inProgressSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 10**12 * 10**9;
    uint256 public _minimumTokensRequiredForLiquify = 250 * 10**6 * 10**9;
    
    bool _useOwnerWalletForPresale = true;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        _inProgressSwapAndLiquify = true;
        _;
        _inProgressSwapAndLiquify = false;
    }
    
    // Allow receive of ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    constructor () public {
        // Pancake V1 - Testnet (Unofficial: https://pancake.kiemtienonline360.com/)
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        // Pancake V2 - Mainnet
        //IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
         // Create a uniswap pair for this new token
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _uniswapV2Router = uniswapV2Router;
        
        // Exclude addresses from fees
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_msgSender()] = true;
        
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }


    // Simple getter functions
    //
    function name() public view returns (string memory) {return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _tTotal; }
    function totalFees() public view returns (uint256) { return _tFeeTotal; }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account])
            return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    
    // Getters and Setters
    //
    function setBuyTaxFeePercent(uint256 buyTaxFee) external onlyOwner() {
        _buyTaxFee = buyTaxFee;
        _validateFees();
    }
    
    function setBuyLiquidityFeePercent(uint256 buyLiquidityFee) external onlyOwner() {
        _buyLiquidityFee = buyLiquidityFee;
        _validateFees();
    }
    
    function setBuyMarketingFeePercent(uint256 buyMarketingFee) external onlyOwner() {
        _buyMarketingFee = buyMarketingFee;
        _validateFees();
    }
    
    function setBuyCharityFeePercent(uint256 buyCharityFee) external onlyOwner() {
        _buyCharityFee = buyCharityFee;
        _validateFees();
    }
    
    function setSellTaxFeePercent(uint256 sellTaxFee) external onlyOwner() {
        _sellTaxFee = sellTaxFee;
        _validateFees();
    }
   
    function setSellLiquidityFeePercent(uint256 sellLiquidityFee) external onlyOwner() {
        _sellLiquidityFee = sellLiquidityFee;
        _validateFees();
    }
   
    function setSellMarketingFeePercent(uint256 sellMarketingFee) external onlyOwner() {
        _sellMarketingFee = sellMarketingFee;
        _validateFees();
    }
   
    function setSellCharityFeePercent(uint256 sellCharityFee) external onlyOwner() {
        _sellCharityFee = sellCharityFee;
        _validateFees();
    }
    
    function _validateFees() view private {
        require(_buyTaxFee.add(_buyLiquidityFee).add(_buyMarketingFee).add(_buyCharityFee) <= 15, "NukeDOGE: Fees cannot exceed 15%");
        require(_sellTaxFee.add(_sellLiquidityFee).add(_sellMarketingFee).add(_sellCharityFee) <= 15, "NukeDOGE: Fees cannot exceed 15%");
    }
 
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Max Transaction Percent cannot be set to 0. This would effectively lock the contract.");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
    }

    function setMinimumTokensToSwapAndLiquify(uint256 amount) public onlyOwner {
        _minimumTokensRequiredForLiquify = amount * 10**9;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        _swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function changeRouterVersion(address _router) public onlyOwner returns(address _pair) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_router);
        
        _pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist
            _pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        }
        _uniswapV2Pair = _pair;

        // Set the router of the contract variables
        _uniswapV2Router = uniswapV2Router;
    }
    
    
    // Allowance and approval
    //
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override gasThrottled returns (bool)  {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    // Transfers
    //
    function transfer(address recipient, uint256 amount) public override gasThrottled returns (bool)  {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override gasThrottled returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        _validateTransfer(sender, recipient, amount);

        if (!_inProgressSwapAndLiquify) {
            _attemptSwapAndLiquify(sender);
        }
        _tokenTransferWithNormalFees(sender, recipient, amount);
    }
    
    function _validateTransfer(address sender, address recipient, uint256 amount) view internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
    }

    function _tokenTransferWithNormalFees(address sender, address recipient, uint256 tAmount) private {
        updateActiveFee(sender, recipient);
        _tokenTransferInternal(sender, recipient, tAmount);
    }
    
    function _tokenTransferFeeless(address sender, address recipient, uint256 tAmount) private {
        removeAllFee();
        _tokenTransferInternal(sender, recipient, tAmount);
    }
    
    function _tokenTransferInternal(address sender, address recipient, uint256 tAmount) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, tAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, tAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, tAmount);
        } else {
            _transferStandard(sender, recipient, tAmount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeOtherFees(tOtherFees);
        _reflectFee(rFee, tFee);
        
        protectOutgoingTokens(sender, tAmount);
        protectIncomingTokens(sender, recipient, tTransferAmount);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeOtherFees(tOtherFees);
        _reflectFee(rFee, tFee);
        
        protectOutgoingTokens(sender, tAmount);
        protectIncomingTokens(sender, recipient, tTransferAmount);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeOtherFees(tOtherFees);
        _reflectFee(rFee, tFee);
        
        protectOutgoingTokens(sender, tAmount);
        protectIncomingTokens(sender, recipient, tTransferAmount);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeOtherFees(tOtherFees);
        _reflectFee(rFee, tFee);
        
        protectOutgoingTokens(sender, tAmount);
        protectIncomingTokens(sender, recipient, tTransferAmount);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        
        protectOutgoingTokens(sender, tAmount);
        
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function _sendTokensToPresaleBuyer(address recipient, uint256 tAmount) override internal onlyPresaleManager presaleIsComplete {
        address sender;
        if (_useOwnerWalletForPresale) {
            sender = owner();
        } else {
            sender = address(this);
        }
        _validateTransfer(sender, recipient, tAmount);
        _tokenTransferFeeless(sender, recipient, tAmount);
    }

    function _retrieveRequiredPresaleTokens(uint256 tAmount) override internal onlyPresaleManager presaleIsStarted {
        address sender;
        if (_useOwnerWalletForPresale) {
            sender = owner();
        } else {
            sender = address(this);
        }
        address recipient = _msgSender();
        _validateTransfer(sender, recipient, tAmount);
        _tokenTransferFeeless(sender, recipient, tAmount);
    }

    
    // Liquidity, marketing, and swaps
    //
    uint8 public _liquifyAction = 0; // Cycle through which wallet we attempt to liquify so no transaction is too large
    
    function _attemptSwapAndLiquify(address from) private lockTheSwap {
        bool exchangeHasToken = balanceOf(_uniswapV2Pair) > 0;
        if (!_swapAndLiquifyEnabled || !exchangeHasToken || from == _uniswapV2Pair) {
            return;
        }
        
        if (_liquifyAction == 0) {
            _handleLiquiditySwap();
            _liquifyAction++;
        } else if (_liquifyAction == 1) {
            _handleCharitySwap();
            _liquifyAction++;
        } else {
            _handleMarketingSwap();
            _liquifyAction = 0;
        }
    }
    
    function _handleLiquiditySwap() private {
        uint256 contractTokenBalance = _getTokenBalanceToSell(address(this));

        bool enoughTokensToSell = contractTokenBalance >= _minimumTokensRequiredForLiquify;
        if (enoughTokensToSell) {
            _swapAndLiquify(contractTokenBalance);
        }
    }
    
    function _handleCharitySwap() private {
        uint256 charityBalance = _getTokenBalanceToSell(_charityAddress);
        
        bool enoughTokensToSell = charityBalance >= _minimumTokensRequiredForLiquify;
        if (enoughTokensToSell) {
            _swapWalletTokensForEth(charityBalance, _charityAddress);
        }
    }
    
    function _handleMarketingSwap() private {
        uint256 marketingBalance = _getTokenBalanceToSell(_marketingAddress);
        
        bool enoughTokensToSell = marketingBalance >= _minimumTokensRequiredForLiquify;
        if (enoughTokensToSell) {
            _swapWalletTokensForEth(marketingBalance, _marketingAddress);
        }
    }
    
    function _getTokenBalanceToSell(address wallet) private view returns (uint256) {
        uint balance = balanceOf(wallet);
        if(balance >= _maxTxAmount)
        {
            balance = _maxTxAmount;
        }
        return balance;
    }
    
    function _swapWalletTokensForEth(uint256 tAmountToSell, address payable wallet) private {
        // charity/marketing ONLY
        if (wallet != _marketingAddress && wallet != _charityAddress) {
            // DO NOT SELL USER TOKENS
            return;
        }
        
        // Move tokens from wallet into contract
        _tokenTransferFeeless(wallet, address(this), tAmountToSell);
        
        uint256 ethReceived = _swapTokensForEthAndGetBalanceChange(tAmountToSell);
        
        //Send ETH back to the wallet
        transferToAddressEth(wallet, ethReceived);
    }
    
    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 ethReceived = _swapTokensForEthAndGetBalanceChange(half);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, ethReceived);
        emit SwapAndLiquify(half, ethReceived, otherHalf);
    }
    
    function _swapTokensForEthAndGetBalanceChange(uint256 tAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tAmount);
        // Return the difference in ETH, so any existing ETH balance of the contract is ignored.
        return address(this).balance.sub(initialBalance);
    }
    
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function _takeOtherFees(uint256 tOtherFees) private {
        if (tOtherFees == 0) {
            return;
        }
        
        uint256 feeDivisor = _activeCharityFee.add(_activeMarketingFee).add(_activeLiquidityFee);
        
        // Ugly math to determine each fee's amount.
        uint256 tCharity = _activeCharityFee.mul(100).div(feeDivisor).mul(tOtherFees).div(100);
        uint256 tMarketing = _activeMarketingFee.mul(100).div(feeDivisor).mul(tOtherFees).div(100);
        uint256 tLiquidity = tOtherFees.sub(tCharity).sub(tMarketing);
        
        uint256 currentRate =  _getRate();
        _takeFeeToAddress(address(this), tLiquidity, currentRate);
        _takeFeeToAddress(_charityAddress, tCharity, currentRate);
        _takeFeeToAddress(_marketingAddress, tMarketing, currentRate);
    }
    
    function _takeFeeToAddress(address feeTaker, uint256 tFee, uint256 currentRate) private {
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[feeTaker] = _rOwned[feeTaker].add(rFee);
        if(_isExcluded[feeTaker])
            _tOwned[feeTaker] = _tOwned[feeTaker].add(tFee);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function transferToAddressEth(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function isTransactionExcludedFromFees(address sender, address recipient) private view returns (bool) {
        return _isExcludedFromFee[sender] || _isExcludedFromFee[recipient];
    }

    function updateActiveFee(address sender, address recipient) private {
        bool takeFee = !isTransactionExcludedFromFees(sender, recipient);
        if (!takeFee) {
            removeAllFee();
        } else {
            if(sender == _uniswapV2Pair) {
                // Buy Fees
                _activeTaxFee = _buyTaxFee;
                _activeLiquidityFee = _buyLiquidityFee;
                _activeMarketingFee = _buyMarketingFee;
                _activeCharityFee = _buyCharityFee;
            } else {
                // General Fees
                _activeTaxFee = _sellTaxFee;
                _activeLiquidityFee = _sellLiquidityFee;
                _activeMarketingFee = _sellMarketingFee;
                _activeCharityFee = _sellCharityFee;
            }
        }
    }
    
    function removeAllFee() private {
        _activeTaxFee = 0;
        _activeLiquidityFee = 0;
        _activeMarketingFee = 0;
        _activeCharityFee = 0;
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
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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
        (uint256 tTransferAmount, uint256 tFee, uint256 tOtherFees) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tOtherFees, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tOtherFees);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tLiquidity = calculateFeeAmount(tAmount, _activeLiquidityFee);
        uint256 tMarketing = calculateFeeAmount(tAmount, _activeMarketingFee);
        uint256 tCharity = calculateFeeAmount(tAmount, _activeCharityFee);
        
        uint256 tOtherFees = tLiquidity.add(tMarketing).add(tCharity); // All non reflection fees combined (because of stack depth limits)
        
        uint256 tFee = calculateFeeAmount(tAmount, _activeTaxFee);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tOtherFees);
        return (tTransferAmount, tFee, tOtherFees);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tOtherFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rOtherFees = tOtherFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rOtherFees);
        return (rAmount, rTransferAmount, rFee);
    }
    
    function calculateFeeAmount(uint256 tAmount, uint256 feePercent) private pure returns (uint256) {
        return tAmount.mul(feePercent).div(100);
    }
}