/**
 *Submitted for verification at snowtrace.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IHauntedHouse {
    function boofi() external view returns (address);
    function strategyPool() external view returns (address);
}

//owned by the HauntedHouse contract
interface IBoofiStrategy {
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external;
    function setAllowances() external;
    function revokeAllowance(address token, address spender) external;
    function migrate(address newStrategy) external;
    function onMigration() external;
    function pendingTokens(address depositToken, address user, uint256 boofiAmount) external view returns (address[] memory, uint256[] memory);
    function transferOwnership(address newOwner) external;
}

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

interface IStakingRewards {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function stake(uint256 amount) external;
    function stakeWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}

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
    function userInfo(uint256 pid, address user) external returns (uint256 amount, uint256 rewardDebt);
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html
     * #use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode
     * #abi-encoding-and-decoding-functions[`abi.decode`].
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

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BoofiStrategyBase is IBoofiStrategy, Ownable {
    using SafeERC20 for IERC20;

    IHauntedHouse public immutable hauntedHouse;
    IERC20 public immutable depositToken;
    uint256 public performanceFeeBips = 10000;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant ACC_BOOFI_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken
        ){
        hauntedHouse = _hauntedHouse;
        depositToken = _depositToken;
        transferOwnership(address(_hauntedHouse));
    }

    //returns zero address and zero tokens since base strategy does not distribute rewards
    function pendingTokens(address, address, uint256) external view virtual override 
        returns (address[] memory, uint256[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(0);
        uint256[] memory _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = 0;
        return(_rewardTokens, _pendingAmounts);
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

    function setAllowances() external virtual override onlyOwner {
    }

    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external virtual override onlyOwner {
        IERC20(token).safeApprove(spender, 0);
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
}

contract BoofiStrategyForPangolinStaking is BoofiStrategyBase {
    using SafeERC20 for IERC20;

    IERC20 public constant rewardToken = IERC20(0x60781C2586D68229fde47564546784ab3fACA982); //PNG token
    IRouter public constant pangolinRouter = IRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    IStakingRewards public immutable stakingContract;
    //total harvested by the contract all time
    uint256 public totalHarvested;
    //swap path from Pangolin to Boofi
    address[] pathRewardToBoofi;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        IStakingRewards _stakingContract
        ) 
        BoofiStrategyBase(_hauntedHouse, _depositToken)
    {
        pathRewardToBoofi = new address[](3);
        pathRewardToBoofi[0] = 0x60781C2586D68229fde47564546784ab3fACA982; //PNG
        pathRewardToBoofi[0] = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;  //WAVAX
        pathRewardToBoofi[0] = _hauntedHouse.boofi();
        stakingContract = _stakingContract;
        _depositToken.safeApprove(address(_stakingContract), MAX_UINT);
        rewardToken.safeApprove(address(pangolinRouter), MAX_UINT);
    }

    //VIEW FUNCTIONS
    function checkReward() public view returns (uint256) {
        return stakingContract.earned(address(this));
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address, address, uint256 tokenAmount, uint256) external override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            stakingContract.stake(tokenAmount);
        }
    }

    function withdraw(address, address to, uint256 tokenAmount, uint256) external override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            stakingContract.withdraw(tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        uint256 toWithdraw = stakingContract.balanceOf(address(this));
        if (toWithdraw > 0) {
            stakingContract.withdraw(toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        uint256 rewardsToTransfer = rewardToken.balanceOf(address(this));
        if (rewardsToTransfer > 0) {
            rewardToken.safeTransfer(newStrategy, rewardsToTransfer);
        }
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        stakingContract.stake(toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(stakingContract), 0);
        depositToken.safeApprove(address(stakingContract), MAX_UINT);
        rewardToken.safeApprove(address(pangolinRouter), 0);
        rewardToken.safeApprove(address(pangolinRouter), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards > 0) {
            uint256 balanceBefore = rewardToken.balanceOf(address(this));
            stakingContract.getReward();
            uint256 balanceDiff = rewardToken.balanceOf(address(this)) - balanceBefore;
            totalHarvested += balanceDiff;
            _swapRewardForBoofi();
        }
    }

    function _swapRewardForBoofi() internal {
        uint256 amountIn = rewardToken.balanceOf(address(this));
        pangolinRouter.swapExactTokensForTokens(amountIn, 0, pathRewardToBoofi, hauntedHouse.strategyPool(), block.timestamp);
    }
}

contract BoofiStrategyForJoeStaking is BoofiStrategyBase {
    using SafeERC20 for IERC20;

    IERC20 public constant rewardToken = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd); //JOE token
    IRouter public constant joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IJoeChef public constant joeMasterChefV2 = IJoeChef(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    uint256 public immutable joePid;
    //total harvested by the contract all time
    uint256 public totalHarvested;
    //swap path from Joe to Boofi
    address[] pathRewardToBoofi;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        uint256 _joePid
        ) 
        BoofiStrategyBase(_hauntedHouse, _depositToken)
    {
        joePid = _joePid;
        pathRewardToBoofi = new address[](3);
        pathRewardToBoofi[0] = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd; //JOE
        pathRewardToBoofi[0] = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;  //WAVAX
        pathRewardToBoofi[0] = _hauntedHouse.boofi();
        _depositToken.safeApprove(address(joeMasterChefV2), MAX_UINT);
        rewardToken.safeApprove(address(joeRouter), MAX_UINT);
    }

    //VIEW FUNCTIONS
    function checkReward() public view returns (uint256) {
        (uint256 pendingJoe, , , ) = joeMasterChefV2.pendingTokens(joePid, address(this));
        return pendingJoe;
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address, address, uint256 tokenAmount, uint256) external override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            joeMasterChefV2.deposit(joePid, tokenAmount);
        }
    }

    function withdraw(address, address to, uint256 tokenAmount, uint256) external override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            joeMasterChefV2.withdraw(joePid, tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        (uint256 toWithdraw, ) = joeMasterChefV2.userInfo(joePid, address(this));
        if (toWithdraw > 0) {
            joeMasterChefV2.withdraw(joePid, toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        uint256 rewardsToTransfer = rewardToken.balanceOf(address(this));
        if (rewardsToTransfer > 0) {
            rewardToken.safeTransfer(newStrategy, rewardsToTransfer);
        }
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        joeMasterChefV2.deposit(joePid, toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(joeMasterChefV2), 0);
        depositToken.safeApprove(address(joeMasterChefV2), MAX_UINT);
        rewardToken.safeApprove(address(joeRouter), 0);
        rewardToken.safeApprove(address(joeRouter), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards > 0) {
            uint256 balanceBefore = rewardToken.balanceOf(address(this));
            joeMasterChefV2.deposit(joePid, 0);
            uint256 balanceDiff = rewardToken.balanceOf(address(this)) - balanceBefore;
            totalHarvested += balanceDiff;
            _swapRewardForBoofi();
        }
    }

    function _swapRewardForBoofi() internal {
        uint256 amountIn = rewardToken.balanceOf(address(this));
        joeRouter.swapExactTokensForTokens(amountIn, 0, pathRewardToBoofi, hauntedHouse.strategyPool(), block.timestamp);
    }
}