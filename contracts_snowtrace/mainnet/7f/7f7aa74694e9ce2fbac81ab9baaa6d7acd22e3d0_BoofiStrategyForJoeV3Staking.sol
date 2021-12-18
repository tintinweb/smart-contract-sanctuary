/**
 *Submitted for verification at snowtrace.io on 2021-12-18
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File contracts/interfaces/IJoeChef.sol
pragma solidity >=0.5.0;

interface IJoeChef {
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOEs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that JOEs distribution occurs.
        uint256 accJoePerShare; // Accumulated JOEs per share, times 1e12. See below.
        address rewarder;
    }
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function pendingTokens(uint256 _pid, address _user) external view
        returns (uint256 pendingJoe, address bonusTokenAddress,
            string memory bonusTokenSymbol, uint256 pendingBonusToken);
    function rewarderBonusTokenInfo(uint256 _pid) external view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
}


// File contracts/interfaces/IRouter.sol
pragma solidity >=0.5.0;

interface IRouter {
    function addLiquidity(
        address tokenA, address tokenB, uint amountADesired, uint amountBDesired, 
        uint amountAMin, uint amountBMin, address to, uint deadline)
        external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token, uint amountTokenDesired, uint amountTokenMin,
        uint amountAVAXMin, address to, uint deadline)
        external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin,
        address to, uint deadline)
        external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin,
        address to, uint deadline)
        external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s)
        external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token, uint liquidity, uint amountTokenMin,
        uint amountAVAXMin, address to, uint deadline)
        external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s)
        external returns (uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(
        uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapTokensForExactAVAX(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactTokensForAVAX(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapAVAXForExactTokens(
        uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
     uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
     uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}


// File contracts/interfaces/IWAVAX.sol
pragma solidity >=0.5.0;

interface IWAVAX {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}


// File contracts/interfaces/IBoofiStrategy.sol
pragma solidity >=0.5.0;

//owned by the HauntedHouse contract
interface IBoofiStrategy {
    //pending tokens for the user
    function pendingTokens(address user) external view returns(address[] memory tokens, uint256[] memory amounts);
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external;
    function migrate(address newStrategy) external;
    function onMigration() external;
    function transferOwnership(address newOwner) external;
    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external;
}


// File contracts/interfaces/IHauntedHouse.sol
pragma solidity >=0.5.0;

interface IHauntedHouse {
    struct TokenInfo {
        address rewarder; // Address of rewarder for token
        address strategy; // Address of strategy for token
        uint256 lastRewardTime; // Last time that BOOFI distribution occurred for this token
        uint256 lastCumulativeReward; // Value of cumulativeAvgZboofiPerWeightedDollar at last update
        uint256 storedPrice; // Latest value of token
        uint256 accZBOOFIPerShare; // Accumulated BOOFI per share, times ACC_BOOFI_PRECISION.
        uint256 totalShares; //total number of shares for the token
        uint256 totalTokens; //total number of tokens deposited
        uint128 multiplier; // multiplier for this token
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
    }
    function BOOFI() external view returns (address);
    function strategyPool() external view returns (address);
    function performanceFeeAddress() external view returns (address);
    function updatePrice(address token, uint256 newPrice) external;
    function updatePrices(address[] calldata tokens, uint256[] calldata newPrices) external;
    function tokenList() external view returns (address[] memory);
    function tokenParameters(address tokenAddress) external view returns (TokenInfo memory);
    function deposit(address token, uint256 amount, address to) external;
    function harvest(address token, address to) external;
    function withdraw(address token, uint256 amountShares, address to) external;
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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
    constructor() {
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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.0;


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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/BoofiStrategyBase.sol
pragma solidity ^0.8.6;




contract BoofiStrategyBase is IBoofiStrategy, Ownable {
    using SafeERC20 for IERC20;

    IHauntedHouse public immutable hauntedHouse;
    IERC20 public immutable depositToken;
    uint256 public performanceFeeBips = 3000;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant ACC_BOOFI_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken
        ){
        require(address(_hauntedHouse) != address(0) && address(_depositToken) != address(0),"zero bad");
        hauntedHouse = _hauntedHouse;
        depositToken = _depositToken;
        transferOwnership(address(_hauntedHouse));
    }

    function pendingTokens(address) external view virtual override returns(address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        return (tokens, amounts);
    }

    function deposit(address, address, uint256, uint256) external virtual override onlyOwner {
    }

    function withdraw(address, address to, uint256 tokenAmount, uint256) external virtual override onlyOwner {
        if (tokenAmount > 0) {
            depositToken.safeTransfer(to, tokenAmount);
        }
    }

    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external virtual override onlyOwner {
        require(amount > 0, "cannot recover 0 tokens");
        require(address(token) != address(depositToken), "cannot recover deposit token");
        token.safeTransfer(to, amount);
    }

    function migrate(address newStrategy) external virtual override onlyOwner {
        uint256 toTransfer = depositToken.balanceOf(address(this));
        depositToken.safeTransfer(newStrategy, toTransfer);
    }

    function onMigration() external virtual override onlyOwner {
    }

    function transferOwnership(address newOwner) public virtual override(Ownable, IBoofiStrategy) onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external virtual onlyOwner {
        require(newPerformanceFeeBips <= MAX_BIPS, "input too high");
        performanceFeeBips = newPerformanceFeeBips;
    }
}


// File contracts/TokenOrAvaxTransfer.sol
pragma solidity ^0.8.6;

abstract contract TokenOrAvaxTransfer {
    using SafeERC20 for IERC20;

    //placeholder address for native token (AVAX)
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _tokenOrAvaxTransfer(address token, address dest, uint256 amount) internal {
        if (amount > 0) {
            if (token == AVAX) {
                payable(dest).transfer(amount);
            } else {
                IERC20(token).safeTransfer(dest,amount);          
            }            
        }
    }

    function _checkBalance(address token) internal view returns (uint256) {
        if (token == AVAX) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}


// File contracts/BoofiStrategyForDexStakingMultiRewards.sol
pragma solidity ^0.8.6;





//base contract for staking in DEXes, for when the DEX offers multiple rewards, e.g. using a MasterChef with 'Rewarder'
abstract contract BoofiStrategyForDexStakingMultiRewards is BoofiStrategyBase, TokenOrAvaxTransfer {
    using SafeERC20 for IERC20;

    address internal constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    //DEX router
    IRouter public immutable ROUTER;
    //tokens rewarded by the DEX    
    uint256 public immutable NUMBER_REWARDS_TOKENS;
    address[] public REWARDS_TOKEN_ARRAY;
    //total REWARD_TOKENs harvested by the contract all time
    uint256[] public totalHarvested;
    //stored rewardTokens to be withdrawn to performanceFeeAdress of HauntedHouse
    uint256[] public storedPerformanceFees;
    //swap paths from REWARD_TOKENs to Boofi
    mapping(uint256 => address[]) public pathsRewardsToBoofi;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        IRouter _ROUTER,
        address[] memory _REWARDS_TOKEN_ARRAY
        ) 
        BoofiStrategyBase(_hauntedHouse, _depositToken)
    {
        uint256 numRewardTokens = _REWARDS_TOKEN_ARRAY.length;
        REWARDS_TOKEN_ARRAY = _REWARDS_TOKEN_ARRAY;
        NUMBER_REWARDS_TOKENS = numRewardTokens;
        storedPerformanceFees = new uint256[](numRewardTokens);
        totalHarvested = new uint256[](numRewardTokens);
        ROUTER = _ROUTER;
        for (uint256 i = 0; i < numRewardTokens; i++) {
            if (_REWARDS_TOKEN_ARRAY[i] != AVAX) {
                IERC20(_REWARDS_TOKEN_ARRAY[i]).safeApprove(address(ROUTER), MAX_UINT);                          
            } else {
                IERC20(WAVAX).safeApprove(address(ROUTER), MAX_UINT);
            }
        }
    }

    //VIEW FUNCTIONS
    //finds the pending rewards for the contract to claim
    function checkReward() public view virtual returns (uint256);

    //EXTERNAL FUNCTIONS
    //simple receive for accepting AVAX transfers
    receive() external payable {
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address, address, uint256 tokenAmount, uint256) external override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            _stake(tokenAmount);
        }
    }

    function withdraw(address, address to, uint256 tokenAmount, uint256) external override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            _withdraw(tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        uint256 toWithdraw = _checkDepositedBalance();
        if (toWithdraw > 0) {
            _withdraw(toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        uint256 toTransfer;
        for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS; i++) {
            toTransfer = _checkBalance(REWARDS_TOKEN_ARRAY[i]);
            _tokenOrAvaxTransfer(REWARDS_TOKEN_ARRAY[i], newStrategy, toTransfer);
        }
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        _stake(toStake);
    }

    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external virtual override onlyOwner {
        require(amount > 0, "cannot recover 0 tokens");
        require(address(token) != address(depositToken), "cannot recover deposit token");
        _tokenOrAvaxTransfer(address(token), to, amount);
    }
    
    function withdrawPerformanceFees() external {
        uint256 toTransfer;
        for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS; i++) {
            toTransfer = storedPerformanceFees[i];
            storedPerformanceFees[i] = 0;
            _tokenOrAvaxTransfer(REWARDS_TOKEN_ARRAY[i], hauntedHouse.performanceFeeAddress(), toTransfer);
        }
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards > 0) {
            uint256[] memory balancesBefore = new uint256[](NUMBER_REWARDS_TOKENS);
            for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS; i++) {
                balancesBefore[i] = _checkBalance(REWARDS_TOKEN_ARRAY[i]);
            }
            _getReward();
            uint256 balanceDiff;
            for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS; i++) {
                balanceDiff = _checkBalance(REWARDS_TOKEN_ARRAY[i]) - balancesBefore[i];
                if (balanceDiff > 0) {
                    totalHarvested[i] += balanceDiff;
                    _swapRewardForBoofi(i);
                }  
            }
        }
    }

    //swaps REWARDS_TOKEN_ARRAY[rewardTokenIndex] for BOOFI and sends the BOOFI to the strategyPool. a portion of REWARD_TOKENS may also be allocated to the Haunted House's performanceFeeAddress
    function _swapRewardForBoofi(uint256 rewardTokenIndex) internal {
        uint256 amountIn = _checkBalance(REWARDS_TOKEN_ARRAY[rewardTokenIndex]) - storedPerformanceFees[rewardTokenIndex];
        if (amountIn > 0) {
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (amountIn * performanceFeeBips) / MAX_BIPS;
                storedPerformanceFees[rewardTokenIndex] += performanceFee;
                amountIn -= performanceFee;
            }
            if (REWARDS_TOKEN_ARRAY[rewardTokenIndex] == AVAX) {
                IWAVAX(WAVAX).deposit{value: amountIn}();
            }
            ROUTER.swapExactTokensForTokens(amountIn, 0, pathsRewardsToBoofi[rewardTokenIndex], hauntedHouse.strategyPool(), block.timestamp);
        }
    }

    //stakes tokenAmount into farm
    function _stake(uint256 tokenAmount) internal virtual;

    //withdraws tokenAmount from farm
    function _withdraw(uint256 tokenAmount) internal virtual;

    //claims reward from the farm
    function _getReward() internal virtual;

    //checks how many depositTokens this contract has in the farm
    function _checkDepositedBalance() internal virtual returns (uint256);
}


// File contracts/BoofiStrategyForJoeV3Staking.sol
pragma solidity ^0.8.6;



contract BoofiStrategyForJoeV3Staking is BoofiStrategyForDexStakingMultiRewards {
    using SafeERC20 for IERC20;

    address internal constant JOE_TOKEN = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    IJoeChef public constant JOE_MASTERCHEF_V3 = IJoeChef(0x188bED1968b795d5c9022F6a0bb5931Ac4c18F00);
    IRouter public constant JOE_ROUTER = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    uint256 public immutable JOE_PID;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        uint256 _JOE_PID,
        address[] memory _REWARD_TOKENS_ARRAY
        )
        BoofiStrategyForDexStakingMultiRewards(
            _hauntedHouse,
            _depositToken,
            JOE_ROUTER,
            _REWARD_TOKENS_ARRAY
        )
    {
        require(_REWARD_TOKENS_ARRAY[0] == JOE_TOKEN, "first reward must be JOE");
        pathsRewardsToBoofi[0].push(JOE_TOKEN);
        pathsRewardsToBoofi[0].push(WAVAX);
        pathsRewardsToBoofi[0].push(_hauntedHouse.BOOFI());
        for (uint256 i = 1; i < _REWARD_TOKENS_ARRAY.length; i++) {
            if (_REWARD_TOKENS_ARRAY[i] != AVAX) {
                pathsRewardsToBoofi[i].push(_REWARD_TOKENS_ARRAY[i]);                
            }
            if (_REWARD_TOKENS_ARRAY[i] != WAVAX) {
                pathsRewardsToBoofi[i].push(WAVAX);
            }
            pathsRewardsToBoofi[i].push(_hauntedHouse.BOOFI());
        }
        JOE_PID = _JOE_PID;
        _depositToken.safeApprove(address(JOE_MASTERCHEF_V3), MAX_UINT);
    }
    //finds the pending rewards for the contract to claim
    function checkReward() public view override returns (uint256) {
        (uint256 pendingJoe, , , ) = JOE_MASTERCHEF_V3.pendingTokens(JOE_PID, address(this));
        return pendingJoe;
    }

    //stakes tokenAmount into farm
    function _stake(uint256 tokenAmount) internal override {
        JOE_MASTERCHEF_V3.deposit(JOE_PID, tokenAmount);
    }

    //withdraws tokenAmount from farm
    function _withdraw(uint256 tokenAmount) internal override {
        JOE_MASTERCHEF_V3.withdraw(JOE_PID, tokenAmount);
    }

    //claims reward from the farm
    function _getReward() internal override {
        JOE_MASTERCHEF_V3.deposit(JOE_PID, 0);
    }

    //checks how many depositTokens this contract has in the farm
    function _checkDepositedBalance() internal view override returns (uint256) {
        (uint256 depositedBalance, ) = JOE_MASTERCHEF_V3.userInfo(JOE_PID, address(this));
        return depositedBalance;
    }
}