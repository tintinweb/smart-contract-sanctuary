/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/GSN/Context.sol



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

// File: contracts/Pausable.sol



pragma solidity 0.6.12;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 */
contract Pausable is Context {
    event Paused(address account);
    event Shutdown(address account);
    event Unpaused(address account);
    event Open(address account);

    bool public paused;
    bool public stopEverything;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!stopEverything, "Pausable: shutdown");
        _;
    }

    modifier whenShutdown() {
        require(stopEverything, "Pausable: not shutdown");
        _;
    }

    /// @dev Pause contract operations, if contract is not paused.
    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /// @dev Unpause contract operations, allow only if contract is paused and not shutdown.
    function _unpause() internal virtual whenPaused whenNotShutdown {
        paused = false;
        emit Unpaused(_msgSender());
    }

    /// @dev Shutdown contract operations, if not already shutdown.
    function _shutdown() internal virtual whenNotShutdown {
        stopEverything = true;
        paused = true;
        emit Shutdown(_msgSender());
    }

    /// @dev Open contract operations, if contract is in shutdown state
    function _open() internal virtual whenShutdown {
        stopEverything = false;
        emit Open(_msgSender());
    }
}

// File: contracts/interfaces/compound/ICompound.sol



pragma solidity 0.6.12;

interface CToken {
    function accrueInterest() external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable; // For ETH

    function mint(uint256 mintAmount) external returns (uint256); // For ERC20

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address user, uint256 amount) external returns (bool);

    function transferFrom(
        address owner,
        address user,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
}

interface Comptroller {
    function claimComp(address holder, address[] memory) external;

    function compAccrued(address holder) external view returns (uint256);
}

// File: contracts/interfaces/vesper/IController.sol



pragma solidity 0.6.12;

interface IController {
    function aaveReferralCode() external view returns (uint16);

    function feeCollector(address) external view returns (address);

    function founderFee() external view returns (uint256);

    function founderVault() external view returns (address);

    function interestFee(address) external view returns (uint256);

    function isPool(address) external view returns (bool);

    function pools() external view returns (address);

    function strategy(address) external view returns (address);

    function rebalanceFriction(address) external view returns (uint256);

    function poolRewards(address) external view returns (address);

    function treasuryPool() external view returns (address);

    function uniswapRouter() external view returns (address);

    function withdrawFee(address) external view returns (uint256);
}

// File: contracts/interfaces/vesper/IStrategy.sol



pragma solidity 0.6.12;

interface IStrategy {
    function rebalance() external;

    function deposit(uint256 amount) external;

    function beforeWithdraw() external;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function isUpgradable() external view returns (bool);

    function isReservedToken(address _token) external view returns (bool);

    function token() external view returns (address);

    function pool() external view returns (address);

    function totalLocked() external view returns (uint256);

    //Lifecycle functions
    function pause() external;

    function unpause() external;
}

// File: contracts/interfaces/vesper/IVesperPool.sol



pragma solidity 0.6.12;


interface IVesperPool is IERC20 {
    function approveToken() external;

    function deposit() external payable;

    function deposit(uint256) external;

    function multiTransfer(uint256[] memory) external returns (bool);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function rebalance() external;

    function resetApproval() external;

    function sweepErc20(address) external;

    function withdraw(uint256) external;

    function withdrawETH(uint256) external;

    function withdrawByStrategy(uint256) external;

    function feeCollector() external view returns (address);

    function getPricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function tokensHere() external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);
}

// File: contracts/interfaces/uniswap/IUniswapV2Router01.sol



pragma solidity 0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/interfaces/uniswap/IUniswapV2Router02.sol



pragma solidity 0.6.12;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/strategies/CompoundStrategy.sol



pragma solidity 0.6.12;










/// @title This strategy will deposit collateral token in Compound and earn interest.
abstract contract CompoundStrategy is IStrategy, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IController public immutable controller;
    IERC20 public immutable collateralToken;
    address public immutable override pool;
    uint256 public pendingFee;

    CToken internal immutable cToken;
    address internal immutable rewardToken;
    Comptroller internal immutable comptroller;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal exchangeRateStored;

    constructor(
        address _controller,
        address _pool,
        address _cToken,
        address _rewardToken,
        address _comptroller
    ) public {
        require(_controller != address(0), "Controller address is zero");
        require(_rewardToken != address(0), "RewardToken address is zero");
        require(IController(_controller).isPool(_pool), "Not a valid pool");
        controller = IController(_controller);
        pool = _pool;
        collateralToken = IERC20(IVesperPool(_pool).token());
        cToken = CToken(_cToken);
        rewardToken = _rewardToken;
        comptroller = Comptroller(_comptroller);
    }

    modifier live() {
        require(!paused || _msgSender() == address(controller), "Contract has paused");
        _;
    }

    modifier onlyAuthorized() {
        require(
            _msgSender() == address(controller) || _msgSender() == pool,
            "Caller is not authorized"
        );
        _;
    }

    modifier onlyController() {
        require(_msgSender() == address(controller), "Caller is not the controller");
        _;
    }

    modifier onlyPool() {
        require(_msgSender() == pool, "Caller is not pool");
        _;
    }

    function pause() external override onlyController {
        _pause();
    }

    function unpause() external override onlyController {
        _unpause();
    }

    /**
     * @notice Migrate tokens from pool to this address
     * @dev Any working Compound strategy has cTokens in strategy contract.
     * @dev There can be scenarios when pool already has cTokens and new
     * strategy will have to move those tokens from pool to self address.
     * @dev Only valid pool strategy is allowed to move tokens from pool.
     */
    function migrateIn() external onlyController {
        require(controller.isPool(pool), "not-a-valid-pool");
        require(controller.strategy(pool) == address(this), "not-a-valid-strategy");
        cToken.transferFrom(pool, address(this), cToken.balanceOf(pool));
    }

    /**
     * @notice Migrate tokens out to pool.
     * @dev There can be scenarios when we want to use new strategy without
     * calling withdrawAll(). We can achieve this by moving tokens in pool
     * and new strategy will take care from there.
     * @dev Pause this strategy, set pendingFee to zero and move tokens out.
     */
    function migrateOut() external onlyController {
        require(controller.isPool(pool), "not-a-valid-pool");
        _pause();
        pendingFee = 0;
        cToken.transfer(pool, cToken.balanceOf(address(this)));
    }

    /**
     * @notice Deposit all collateral token from pool into Compound.
     * Anyone can call it except when paused.
     */
    function depositAll() external live {
        deposit(collateralToken.balanceOf(pool));
    }

    /// @notice Vesper pools are using this function so it should exist in all strategies.
    //solhint-disable-next-line no-empty-blocks
    function beforeWithdraw() external override onlyPool {}

    /**
     * @dev Withdraw collateral token from Compound.
     * @param _amount Amount of collateral token
     */
    function withdraw(uint256 _amount) external override onlyAuthorized {
        _withdraw(_amount);
    }

    /**
     * @dev Withdraw all collateral from Compound and deposit into pool.
     * Controller only function, called when migrating strategy.
     */
    function withdrawAll() external override onlyController {
        _withdrawAll();
    }

    /**
     * @dev Calculate interest fee on earning from Compound and transfer fee to fee collector.
     * Deposit available collateral from pool into Compound.
     * Anyone can call it except when paused.
     */
    function rebalance() external override live {
        _rebalanceEarned();
        uint256 balance = collateralToken.balanceOf(pool);
        if (balance != 0) {
            _deposit(balance);
        }
    }

    /**
     * @notice Sweep given token to vesper pool
     * @dev Reserved tokens are not allowed to sweep.
     * @param _fromToken token address to sweep
     */
    function sweepErc20(address _fromToken) external {
        require(_fromToken != address(cToken) && _fromToken != rewardToken, "Not allowed to sweep");

        if (_fromToken == ETH) {
            payable(pool).transfer(address(this).balance);
        } else {
            uint256 amount = IERC20(_fromToken).balanceOf(address(this));
            IERC20(_fromToken).safeTransfer(pool, amount);
        }
    }

    /**
     * @notice Returns interest earned in COMP since last rebalance.
     * @dev Make sure to return value in collateral token and in order to do that
     * we are using Uniswap to get collateral amount for earned DAI.
     */
    function interestEarned() external view returns (uint256) {
        uint256 compAccrued = comptroller.compAccrued(address(this));
        if (compAccrued != 0) {
            IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(controller.uniswapRouter());
            address[] memory path = _getPath(rewardToken, address(collateralToken));
            return uniswapRouter.getAmountsOut(compAccrued, path)[path.length - 1];
        }
        return 0;
    }

    /// @notice Returns true if strategy can be upgraded.
    /// @dev If there are no cTokens in strategy then it is upgradable
    function isUpgradable() external view override returns (bool) {
        return cToken.balanceOf(address(this)) == 0;
    }

    /// @notice This method is deprecated and will be removed from Strategies in next release
    function isReservedToken(address _token) external view override returns (bool) {
        return _token == address(cToken) || _token == rewardToken;
    }

    /// @dev Returns address of Compound token correspond to collateral token
    function token() external view override returns (address) {
        return address(cToken);
    }

    /**
     * @notice Total collateral locked in Compound.
     * @dev This value will be used in pool share calculation, so true totalLocked
     * will be balance in Compound minus any pending fee to collect.
     * @return Return value will be in collateralToken defined decimal.
     */
    function totalLocked() external view override returns (uint256) {
        uint256 _totalCTokens = cToken.balanceOf(pool).add(cToken.balanceOf(address(this)));
        return _convertToCollateral(_totalCTokens).sub(_calculatePendingFee());
    }

    /**
     * @notice Deposit collateral token from pool into Compound.
     * @dev Update pendingFee before deposit. Anyone can call it except when paused.
     * @param _amount Amount of collateral token to deposit
     */
    function deposit(uint256 _amount) public override live {
        _updatePendingFee();
        _deposit(_amount);
    }

    /**
     * @dev Claim rewardToken and convert rewardToken into collateral token.
     * Calculate interest fee on earning from rewardToken and transfer balance minus
     * fee to pool.
     * @dev Transferring collateral to pool will increase pool share price.
     */
    function _claimComp() internal {
        address[] memory markets = new address[](1);
        markets[0] = address(cToken);
        comptroller.claimComp(address(this), markets);
        uint256 amt = IERC20(rewardToken).balanceOf(address(this));
        if (amt != 0) {
            IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(controller.uniswapRouter());
            address[] memory path = _getPath(rewardToken, address(collateralToken));
            uint256 amountOut = uniswapRouter.getAmountsOut(amt, path)[path.length - 1];
            if (amountOut != 0) {
                IERC20(rewardToken).safeApprove(address(uniswapRouter), 0);
                IERC20(rewardToken).safeApprove(address(uniswapRouter), amt);
                uniswapRouter.swapExactTokensForTokens(amt, 1, path, address(this), now + 30);
                uint256 _collateralEarned = collateralToken.balanceOf(address(this));
                uint256 _fee = _collateralEarned.mul(controller.interestFee(pool)).div(1e18);
                collateralToken.safeTransfer(pool, _collateralEarned.sub(_fee));
            }
        }
    }

    function _deposit(uint256 _amount) internal virtual {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        collateralToken.safeApprove(address(cToken), 0);
        collateralToken.safeApprove(address(cToken), _amount);
        require(cToken.mint(_amount) == 0, "deposit-failed");
    }

    /**
     * @dev Calculate interest fee earning and transfer it to fee collector.
     * RebalanceEarned completes in following steps,
     *      Claim rewardToken and earn fee.
     *      Update pending fee.
     *      Withdraw collateral equal to pendingFee from compound.
     *      Now we have collateral equal to pendingFee + fee earning from rewardToken.
     *      Deposit collateral in Pool and get shares.
     *      Transfer shares to feeCollector.
     */
    function _rebalanceEarned() internal {
        _claimComp();
        _updatePendingFee();
        // Read state variable once to save gas
        uint256 _pendingFee = pendingFee;
        uint256 _cTokenAmount = _convertToCToken(_pendingFee);
        if (_cTokenAmount != 0) {
            require(cToken.redeemUnderlying(_pendingFee) == 0, "rebalanceEarned::withdraw-failed");
            // Update state variable
            pendingFee = 0;
            _afterRedeem();
        }

        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            collateralToken.safeApprove(pool, 0);
            collateralToken.safeApprove(pool, _collateralBalance);
            IVesperPool(pool).deposit(_collateralBalance);
            uint256 _feeInShare = IERC20(pool).balanceOf(address(this));
            IERC20(pool).safeTransfer(controller.feeCollector(pool), _feeInShare);
        }
    }

    function _withdraw(uint256 _amount) internal {
        _updatePendingFee();
        require(cToken.redeemUnderlying(_amount) == 0, "withdraw-failed");
        _afterRedeem();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _withdrawAll() internal {
        pendingFee = 0;
        require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "withdraw-all-failed");
        _afterRedeem();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /// @dev Hook to call after collateral is redeemed from Compound
    /// @notice We did empty implementation as not all derived are going to implement it.
    //solhint-disable-next-line no-empty-blocks
    function _afterRedeem() internal virtual {}

    function _convertToCToken(uint256 _collateralAmount) internal view returns (uint256) {
        return _collateralAmount.mul(1e18).div(cToken.exchangeRateStored());
    }

    function _convertToCollateral(uint256 _cTokenAmount) internal view returns (uint256) {
        return _cTokenAmount.mul(cToken.exchangeRateStored()).div(1e18);
    }

    function _calculatePendingFee() internal view returns (uint256) {
        uint256 interest =
            cToken
                .exchangeRateStored()
                .sub(exchangeRateStored)
                .mul(cToken.balanceOf(address(this)))
                .div(1e18);
        uint256 fee = interest.mul(controller.interestFee(pool)).div(1e18);
        return pendingFee.add(fee);
    }

    function _updatePendingFee() internal {
        pendingFee = _calculatePendingFee();
        exchangeRateStored = cToken.exchangeRateStored();
    }

    function _getPath(address _from, address _to) internal pure returns (address[] memory) {
        address[] memory path;
        if (_from == WETH || _to == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }
        return path;
    }
}

// File: contracts/interfaces/token/IToken.sol



pragma solidity 0.6.12;

interface TokenLike {
    function approve(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}

// File: contracts/strategies/CompoundStrategyETH.sol



pragma solidity 0.6.12;



//solhint-disable no-empty-blocks
contract CompoundStrategyETH is CompoundStrategy {
    string public constant NAME = "Strategy-Compound-ETH";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        CompoundStrategy(
            _controller,
            _pool,
            0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5,
            0xc00e94Cb662C3520282E6f5717214004A7f26888,
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        )
    {}

    receive() external payable {
        require(msg.sender == address(cToken) || msg.sender == WETH, "Not allowed to send ether");
    }

    /// @dev Hool to call after collateral is redeemed from Compound
    function _afterRedeem() internal override {
        TokenLike(WETH).deposit{value: address(this).balance}();
    }

    function _deposit(uint256 _amount) internal override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        TokenLike(WETH).withdraw(_amount);
        cToken.mint{value: _amount}();
    }
}