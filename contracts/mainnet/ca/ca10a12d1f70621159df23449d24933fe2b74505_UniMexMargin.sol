/**
 *Submitted for verification at Etherscan.io on 2020-12-22
*/

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Uniswap.sol


pragma solidity 0.6.12;


interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 r0, uint112 r1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address a, address b) external view returns (address p);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UV2: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UV2: ZERO_ADDRESS');
    }
    
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UV2: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UV2: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

// File: contracts/IUniMexFactory.sol


pragma solidity 0.6.12;

interface IUniMexFactory {
  function getPool(address) external returns(address);
  function getMaxLeverage(address) external returns(uint256);
  function margin() external returns (address);
  function utilizationScaled(address token) external pure returns(uint256);
}

// File: contracts/UniMexMargin.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;






interface IUniMexStaking {
    function distribute(uint256 _amount) external;
}

interface IUniMexPool {
    function borrow(uint256 _amount) external;
    function distribute(uint256 _amount) external;
    function repay(uint256 _amount) external returns (bool);
}

contract UniMexMargin is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address private WETH_ADDRESS;
    IERC20 public WETH;
    uint256 public constant mag = 1e18;
    // uint256 public constant margin_call = 25 * 1e16;
    uint256 public constant LIQUIDATION_BONUS = 9 * 1e16;
    
    struct Position {
        bytes32 id;
        address token;
        address owner;
        uint256 owed;
        uint256 input;
        uint256 commitment;
        uint256 leverage;
        uint256 startTimestamp;
        bool isClosed;
        bool isShort;
    }
    
    mapping(bytes32 => Position) public positionInfo;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public escrow;
    
    uint256 public delay;

    IUniMexStaking public staking;
    IUniMexFactory public unimex_factory;
    IUniswapV2Factory public uniswap_factory;
    IUniswapV2Router02 public uniswap_router;
    
    event OnOpenPosition(
        address indexed sender,
        bytes32 positionId,
        bool isShort,
        address indexed token
    );
    
    event OnClosePosition(
        address indexed sender,
        bytes32 positionId,
        bool isShort,
        address indexed token
    );
    
    //to prevent flashloans
    modifier isHuman() {
        require(msg.sender == tx.origin);
        _;
    }

    constructor(
        address _staking,
        address _factory,
        address _weth,
        address _uniswap_factory,
        address _uniswap_router
    ) public {
        staking = IUniMexStaking(_staking);
        unimex_factory = IUniMexFactory(_factory);
        WETH_ADDRESS = _weth;
        WETH = IERC20(_weth);
        uniswap_factory = IUniswapV2Factory(_uniswap_factory);
        uniswap_router = IUniswapV2Router02(_uniswap_router);
    }

    function setDelay(uint256 _delay) external onlyOwner {
        delay = _delay;
    }

    function deposit(uint256 _amount) public {
        WETH.safeTransferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
    }

    function withdraw(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        WETH.safeTransfer(msg.sender, _amount);
    }

    function transferUserToEscrow(address from, address to, uint256 amount) private {
        require(balanceOf[from] >= amount);
        balanceOf[from] = balanceOf[from].sub(amount);
        escrow[to] = escrow[to].add(amount);
    }

    function transferEscrowToUser(address from, address to, uint256 amount) private {
        require(escrow[from] >= amount);
        escrow[from] = escrow[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function transferToUser(address to, uint256 amount) private {
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function getPositionId(
        address maker,
        address token,
        uint256 amount,
        uint256 leverage,
        uint256 date
    ) private pure returns (bytes32 positionId) {
        //date acts as a nonce
        positionId = keccak256(
            abi.encodePacked(maker, token, amount, leverage, date)
        );
    }

    function calculateConvertedValue(address baseToken, address quoteToken, uint256 amount) private view returns (uint256) {
        address token0;
        address token1;
        (token0, token1) = UniswapV2Library.sortTokens(baseToken, quoteToken);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswap_factory.getPair(token0, token1));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 value;
        if (token1 == baseToken) {
            value = UniswapV2Library.getAmountOut(amount, reserve1, reserve0);
        } else {
            value = UniswapV2Library.getAmountOut(amount, reserve0, reserve1);
        }
        return value;
    }

    function swapTokens(address baseToken, address quoteToken, uint256 input, uint256 slippage) private returns (uint256 swap) {
        IERC20(baseToken).approve(address(uniswap_router), input);
        address[] memory path = new address[](2);
        path[0] = baseToken;
        path[1] = quoteToken;
        uint256 deadline = block.timestamp.add(delay);
        uint256 output = calculateConvertedValue(baseToken, quoteToken, input);
        uint256 outputWithSlippage = (output.sub(((output.mul(slippage)).div(mag))));
        uint256 balanceBefore = IERC20(quoteToken).balanceOf(address(this));

        IUniswapV2Router02(uniswap_router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                input,
                outputWithSlippage,
                path,
                address(this),
                deadline
            );
            
        uint256 balanceAfter = IERC20(quoteToken).balanceOf(address(this));
        swap = balanceAfter.sub(balanceBefore);

        require(swap > 0, "FAILED_SWAP");
    }

    function getCommitment(uint256 _amount, uint scaledLeverage) private pure returns (uint256 commitment) {
        commitment = (_amount.mul(mag)).div(scaledLeverage);
    }

    function transferFees(uint256 fees, address pool) private {
        uint256 halfFees = fees.div(2);

        // Pool fees
        WETH.approve(pool, halfFees);	
        IUniMexPool(pool).distribute(halfFees);	

        // Staking Fees
        WETH.approve(address(staking), fees.sub(halfFees));
        staking.distribute(fees.sub(halfFees));
    }

    function transferToPool(address pool, address token, uint256 amount) private {
        IERC20(token).approve(pool, amount);
        IUniMexPool(pool).repay(amount);
    }

    function _openPosition(address token, uint256 amount, uint256 scaledLeverage, uint256 slippage, bool isShort) private {
        require(amount > 0, "AMOUNT_ZERO");
        address pool = unimex_factory.getPool(address(isShort ? IERC20(token) : WETH));

        require(pool != address(0), "POOL_DOES_NOT_EXIST");
        require(scaledLeverage <= unimex_factory.getMaxLeverage(token).mul(mag), "LEVERAGE_EXCEEDS_MAX");
        require(scaledLeverage >= mag, "LEVERAGE_BELOW_1");

        uint amountInWeth = isShort ? calculateConvertedValue(token, WETH_ADDRESS, amount) : amount;
        uint256 commitment = getCommitment(amountInWeth, scaledLeverage);
        require(balanceOf[msg.sender] >= commitment, "NO_BALANCE");
        
        IUniMexPool(pool).borrow(amount);

        uint256 swap;
        
        {
            (address baseToken, address quoteToken) = isShort ? (token, WETH_ADDRESS) : (WETH_ADDRESS, token);
            swap = swapTokens(baseToken, quoteToken, amount, slippage);
        }

        uint256 fees = (swap.mul(8)).div(1000);	

        swap = swap.sub(fees); // swap minus fees

        if(!isShort) {
            fees = swapTokens(token, WETH_ADDRESS, fees, slippage); // convert fees to ETH
        }

        transferFees(fees, pool);

        transferUserToEscrow(msg.sender, msg.sender, commitment.add(LIQUIDATION_BONUS));

        bytes32 positionId = getPositionId(
            msg.sender,
            token,
            amount,
            scaledLeverage,
            block.timestamp
        );

        Position memory position = Position({
            owed: amount,
            input: swap,
            commitment: commitment,	
            owner: msg.sender,	
            startTimestamp: block.timestamp,
            isShort: isShort,
            isClosed: false,	
            leverage: scaledLeverage,
            token: token,
            id: positionId
        });
        
        positionInfo[position.id] = position;

        emit OnOpenPosition(msg.sender, position.id, isShort, token);
    }

    //slippage is a percentage x 1e18
    function openShortPosition(address token, uint256 amount, uint256 leverage, uint256 slippage) public isHuman {
        _openPosition(token, amount, leverage, slippage, true);
    }

    function openLongPosition(address token, uint256 amount, uint256 leverage, uint256 slippage) public isHuman {
        _openPosition(token, amount, leverage, slippage, false);
    }

    function _closeShort(Position storage position, uint256 slippage) private {

        uint256 input = position.input;
        uint256 owed = position.owed;
        uint256 commitment = position.commitment;

        address pool = unimex_factory.getPool(position.token);

        uint256 swap = swapTokens(WETH_ADDRESS, position.token, input, slippage);
        require(swap >= owed.mul(input).div(input.add(commitment)), "LIQUIDATE_ONLY");

        bool isProfit = owed < swap;
        uint256 amount;

        if(isProfit) {
            uint256 profitInTokens = swap.sub(owed);
            amount = swapTokens(position.token, WETH_ADDRESS, profitInTokens, slippage); //profit in eth
        } else {
            uint256 commitmentInTokens = swapTokens(WETH_ADDRESS, position.token, commitment, slippage);
            amount = swapTokens(position.token, WETH_ADDRESS, commitmentInTokens.sub(owed.sub(swap)), slippage); //return to user's balance
        }

        uint256 fees = (amount.mul(8e15)).div(1e18);

        transferToPool(pool, position.token, owed);

        transferFees(fees, pool);

        transferEscrowToUser(position.owner, isProfit ? position.owner : address(0x0), commitment);
        transferEscrowToUser(position.owner, position.owner, LIQUIDATION_BONUS);
        transferToUser(position.owner, amount.sub(fees));
        
        position.isClosed = true;
        emit OnClosePosition(msg.sender, position.id, true, position.token);
    }

    function _closeLong(Position storage position, uint256 slippage) private {
        uint256 input = position.input;
        uint256 owed = position.owed;
        address pool = unimex_factory.getPool(WETH_ADDRESS);

        uint256 swap = swapTokens(position.token, WETH_ADDRESS, input, slippage);
        require(swap >= owed.sub(position.commitment), "LIQUIDATE_ONLY");

        uint256 commitment = position.commitment;

        bool isProfit = swap >= owed;

        uint256 amount = isProfit ? swap.sub(owed) : commitment.sub(owed.sub(swap));

        uint256 fees = (amount.mul(8e15)).div(1e18);

        transferToPool(pool, WETH_ADDRESS, owed);

        transferFees(fees, pool);

        transferEscrowToUser(position.owner, isProfit ? position.owner : address(0x0), commitment);
        transferEscrowToUser(position.owner, position.owner, LIQUIDATION_BONUS);

        transferToUser(position.owner, amount.sub(fees));

        position.isClosed = true;
        emit OnClosePosition(msg.sender, position.id, false, position.token);
    }

    function closePosition(bytes32 positionId, uint256 slippage) external isHuman {
        Position storage position = positionInfo[positionId];
        require(position.isClosed == false, "CLOSED_POSITION");
        require(msg.sender == position.owner, "BORROWER_ONLY");
        if(position.isShort) {
            _closeShort(position, slippage);
        }else{
            _closeLong(position, slippage);
        }
    }
    function liquidatePosition(bytes32 positionId, uint256 slippage) external isHuman {
        Position storage position = positionInfo[positionId];
        require(position.isClosed == false, "CLOSED_POSITION");
        bool isShort = position.isShort;
        (address baseToken, address quoteToken) = isShort ? (position.token, WETH_ADDRESS) : (WETH_ADDRESS, position.token);

        uint256 input = position.input;
        uint256 owed = position.owed;

        if(isShort) {
            uint256 value = calculateConvertedValue(WETH_ADDRESS, position.token, input);
            require(value < owed.mul(input).div(input.add(position.commitment)), "CANNOT_LIQUIDATE");
        } else {
            uint256 value = calculateConvertedValue(position.token, WETH_ADDRESS, input);
            require(value < owed.sub(position.commitment), "CANNOT_LIQUIDATE");
        }

        address pool = unimex_factory.getPool(baseToken);

        uint256 swap = swapTokens(quoteToken, baseToken, input, slippage);

        uint256 commitment = isShort ? swapTokens(WETH_ADDRESS, position.token, position.commitment, slippage) : position.commitment;
        
        transferToPool(pool, baseToken, swap.add(commitment));

        transferEscrowToUser(position.owner, address(0x0), position.commitment.add(LIQUIDATION_BONUS));

        position.isClosed = true;
        
        emit OnClosePosition(msg.sender, position.id, isShort, position.token);
        WETH.safeTransfer(msg.sender, LIQUIDATION_BONUS);
    }
}