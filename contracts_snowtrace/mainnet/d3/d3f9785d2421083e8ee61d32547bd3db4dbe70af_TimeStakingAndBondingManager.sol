/**
 *Submitted for verification at snowtrace.io on 2021-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

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

interface IRewarder {
    function onPefiReward(uint256 pid, address user, address recipient, uint256 pefiAmount, uint256 newShareAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 pefiAmount) external view returns (address[] memory, uint256[] memory);
}

interface IIglooMaster {
    struct PoolInfo {
        IERC20 poolToken; // Address of LP token contract.
        IRewarder rewarder; // Address of rewarder for pool
        address strategy; // Address of strategy for pool
        uint256 allocPoint; // How many allocation points assigned to this pool. PEFIs to distribute per second.
        uint256 lastRewardTime; // Last block number that PEFIs distribution occurs.
        uint256 accPEFIPerShare; // Accumulated PEFIs per share, times ACC_PEFI_PRECISION. See below.
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
        uint256 totalShares; //total number of shares in the pool
        uint256 lpPerShare; //number of LP tokens per share, times ACC_PEFI_PRECISION
    }
    function pefi() external view returns (address);
    function startTime() external view returns (uint256);
    function dev() external view returns (address);
    function nest() external view returns (address);
    function nestAllocatorAddress() external view returns (address);
    function performanceFeeAddress() external view returns (address);
    function pefiEmissionPerSecond() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function devMintBips() external view returns (uint256);
    function nestMintBips() external view returns (uint256);
    function nestSplitBips() external view returns (uint256);
    function defaultIpefiDistributionBips() external view returns (uint256);
    function onlyApprovedContractOrEOAStatus() external view returns (bool);
    function PEFI_MAX_SUPPLY() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
    function userInfo(uint256 pid, address user) external returns (uint256 amount, uint256 rewardDebt);
    function poolExistence(address lpToken) external view returns (bool);
    function approvedContracts(address) external view returns (bool);
    function ipefiDistributionBipsSet(address) external view returns (bool);
    function deposits(uint256 pid, address user) external view returns (uint256);
    function withdrawals(uint256 pid, address user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function totalPendingPEFI(uint256 pid, address penguin) external view returns (uint256);
    function pendingPEFI(uint256 pid, address user) external view returns (uint256);
    function pendingIPEFI(uint256 pid, address user) external view returns (uint256);
    function pendingRewards(uint256 pid, address user) external view returns (uint256, uint256);
    function pendingTokens(uint256 pid, address user) external view 
        returns (address[] memory, uint256[] memory);
    function reward(uint256 _lastRewardTime, uint256 _currentTime) external view returns (uint256);
    function pefiPerYear() external view returns (uint256);
    function pefiPerYearToIgloo(uint256 pid) external view returns (uint256);
    function pefiPerYearToNest() external view returns (uint256);
    function nestAPY() external view returns (uint256);
    function totalShares(uint256 pid) external view returns (uint256);
    function totalLP(uint256 pid) external view returns (uint256);
    function userShares(uint256 pid, address user) external view returns (uint256);    
    function profitInLP(uint256 pid, address userAddress) external view returns (uint256);
    function ipefiDistributionBipsByUser(address user) external view returns (uint256);
    function updatePool(uint256 pid) external;
    function massUpdatePools() external;
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amountShares, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amountShares, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function setIpefiDistributionBips(uint256 _ipefiDistributionBips) external;
    function add(uint256 _allocPoint, uint16 _withdrawFeeBP, IERC20 _poolToken,
        bool _withUpdate, IRewarder _rewarder, address _strategy) external;
    function set(uint256 _pid, uint256 _allocPoint, uint16 _withdrawFeeBP,
        IRewarder _rewarder, bool _withUpdate, bool overwrite) external;
    function migrateStrategy(uint256 pid, address newStrategy) external;
    function setStrategy(uint256 pid, address newStrategy, bool transferOwnership, address newOwner) external;
    function manualMint(address dest, uint256 amount) external;
    function transferMinter(address newMinter) external;
    function setDev(address _dev) external;
    function setNest(address _nest) external;
    function setNestAllocatorAddress(address _nestAllocatorAddress) external;
    function setDevMintBips(uint256 _devMintBips) external;
    function setNestMintBips(uint256 _nestMintBips) external;
    function setNestSplitBips(uint256 _nestSplitBips) external;
    function setPefiEmission(uint256 newPefiEmissionPerSecond, bool withUpdate) external;
    function setDefaultIpefiDistributionBips(uint256 _defaultIpefiDistributionBips) external;
    function modifyApprovedContracts(address[] calldata contracts, bool[] calldata statuses) external;
    function setOnlyApprovedContractOrEOAStatus(bool newStatus) external;
    function inCaseTokensGetStuck(uint256 pid, IERC20 token, address to, uint256 amount) external;
    function setAllowances(uint256 pid) external;
    function revokeAllowance(uint256 pid, address token, address spender) external;
    function accountAddedLP(uint256 pid, uint256 amount) external;
}

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

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IRouter {
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin,
        uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityAVAX(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountAVAXMin, address to,
        uint256 deadline) external payable returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to,
        uint256 deadline) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityAVAX(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, address to,
        uint256 deadline) external returns (uint256 amountToken, uint256 amountAVAX);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin,
        address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityAVAXWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, address to,
        uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountToken, uint256 amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, 
        address to, uint256 deadline) external returns (uint256 amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, 
        uint256 amountAVAXMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountAVAX);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) 
        external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) 
        external returns (uint256[] memory amounts);
    function swapExactAVAXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) 
        external payable returns (uint256[] memory amounts);
    function swapTokensForExactAVAX(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) 
        external returns (uint256[] memory amounts);
    function swapExactTokensForAVAX(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) 
        external returns (uint256[] memory amounts);
    function swapAVAXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) 
        external payable returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path,
        address to, uint256 deadline ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) 
        external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to,
        uint256 deadline) external;
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
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

interface ITimeStaking {
    struct Epoch {
        uint256 number;
        uint256 distribute;
        uint32 length;
        uint32 endTime;
    }
    struct Claim {
        uint256 deposit;
        uint256 gons;
        uint256 expiry;
        bool lock; // prevents malicious delays
    }
    function Time() external view returns (address);
    function Memories() external view returns (address);
    function distributor() external view returns (address);
    function warmupContract() external view returns (address);

    function totalBonus() external view returns (uint256);
    function warmupPeriod() external view returns (uint256);
    function index() external view returns (uint256);
    function contractBalance() external view returns (uint256);

    function epoch() external view returns (Epoch memory);
    function warmupInfo(address) external view returns (Claim memory);

    function stake(uint256 _amount, address _recipient) external returns (bool);
    function claim (address _recipient) external;
    function forfeit() external;
    function toggleDepositLock() external;
    function unstake(uint256 _amount, bool _trigger) external;
    function rebase() external;
    function giveLockBonus(uint256 _amount) external;
    function returnLockBonus(uint256 _amount) external;
}

interface ITimeBondDepository {
    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
    }
    // Info for bond holder
    struct Bond {
        uint256 payout; // OHM remaining to be paid
        uint256 pricePaid; // In DAI, for front end viewing
        uint32 vesting; // Seconds left to vest
        uint32 lastTime; // Last interaction
    }
    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in seconds) between adjustments
        uint32 lastTime; // block when last adjustment made
    }
    function OHM() external view returns (address); //TIME 0xb54f16fB19478766A268F172C9480f8da1a7c9C3
    function principle() external view returns (address); //token paid, e.g. WAVAX 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
    function treasury() external view returns (address); //TimeTreasury 0x1c46450211CB2646cc1DA3c5242422967eD9e04c
    function DAO() external view returns (address);
    function staking() external view returns (address);
    function stakingHelper() external view returns (address);
    function useHelper() external view returns (bool);
    function terms() external view returns (Terms memory);
    function adjustment() external view returns (Adjust memory);
    function totalDebt() external view returns (uint256);
    function lastDecay() external view returns (uint32);
    function initializeBondTerms( 
        uint256 _controlVariable, 
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt,
        uint32 _vestingTerm
    ) external;
    function deposit( 
        uint256 _amount, 
        uint256 _maxPrice,
        address _depositor
    ) external payable returns (uint256);
    function redeem( address _recipient, bool _stake ) external returns (uint256);
    function maxPayout() external view returns (uint256);
    function payoutFor(uint256 _value) external view returns (uint256);
    function bondPrice() external view returns (uint256);
    function assetPrice() external view returns (int);
    function bondPriceInUSD() external view returns (uint256);
    function debtRatio() external view returns (uint256);
    function standardizedDebtRatio() external view returns (uint256);
    function currentDebt() external view returns (uint256);
    function debtDecay() external view returns (uint256);
    function percentVestedFor(address _depositor) external view returns (uint256);
    function pendingPayoutFor(address _depositor) external view returns (uint256);
    function bondInfo(address _depositor) external view returns (Bond memory);
}

interface ITimeTreasury {
    function valueOf( address _token, uint256 _amount ) external view returns ( uint256 value_ );
}

interface IMEMO {
    struct Rebase {
        uint epoch;
        uint rebase; // 18 decimals
        uint totalStakedBefore;
        uint totalStakedAfter;
        uint amountRebased;
        uint index;
        uint32 timeOccured;
    }
    function circulatingSupply() external view returns (uint256);
    function rebases(uint256) external view returns (Rebase memory);
    function balanceForGons(uint256 gons) external view returns (uint256);
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

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract Ownable {
    address internal _owner;
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

contract SingleUseTimeStakingDummy is Ownable {
    using SafeERC20 for IERC20;
    ITimeStaking constant public timeStaking = ITimeStaking(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    //amount of TIME used in deposit by dummy
    uint256 public immutable amountTime;

    constructor(uint256 _amountTime) {
        amountTime = _amountTime;
    }

    //lock deposits to prevent griefing
    function toggleDepositLock() external onlyOwner {
        timeStaking.toggleDepositLock();
    }
    //claim MEMO and transfer all MEMO back to contract owner
    function claim() external onlyOwner {
        timeStaking.claim(address(this));
        _recoverAllTokens(0x136Acd46C134E8269052c62A67042D6bDeDde3C9);
    }
    //forfeit gains for immediate TIME withdrawal, and transfer all TIME back to contract owner
    function forfeit() external onlyOwner {
        timeStaking.forfeit();
        _recoverAllTokens(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
    }
    //in case tokens somehow get stuck in this contract and need to be recovered
    function recoverERC20(address token, address dest) external onlyOwner {
        IERC20 coin = IERC20(token);
        uint256 tokenBalance = coin.balanceOf(address(this));
        if (tokenBalance > 0) {
            coin.safeTransfer(dest, tokenBalance);
        } 
    }
    //transfer contract balance of an ERC20 token to contract owner
    function _recoverAllTokens(address token) internal {
        IERC20 coin = IERC20(token);
        uint256 tokenBalance = coin.balanceOf(address(this));
        if (tokenBalance > 0) {
            coin.safeTransfer(owner(), tokenBalance);
        }   
    }
}

contract SingleUseTimeBondingDummy is Ownable {
    using SafeERC20 for IERC20;
    ITimeStaking constant public timeStaking = ITimeStaking(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    ITimeBondDepository public immutable timeBondDepository;
    IERC20 public immutable tokenToDeposit;
    //amount of TIME used in deposit by dummy
    uint256 public immutable amountTime;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    constructor(ITimeBondDepository _timeBondDepository, IERC20 _tokenToDeposit, uint256 _amountTime) {
        timeBondDepository = _timeBondDepository;
        tokenToDeposit = _tokenToDeposit;
        //approve timeBondDepository to transfer tokens
        _tokenToDeposit.approve(address(_timeBondDepository), MAX_UINT);
        amountTime = _amountTime;
    }
    function percentVested() external view returns (uint256) {
        return timeBondDepository.percentVestedFor(address(this));
    }
    //deposit 'amount' of tokenToDeposit in timeBondDepository
    function deposit(uint256 _amount) external onlyOwner {
        //NOTE: may not want to use MAX_UNIT for the 2nd, 'maxPrice' input variable in this call
        timeBondDepository.deposit(_amount, MAX_UINT, address(this));
    }
    function redeem() external onlyOwner {
        //send all available TIME to the owner of this contract. do not use staking helper feature, hence the 'false' input.
        timeBondDepository.redeem(address(this), false);
        _recoverAllTokens(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
    }
    //in case tokens somehow get stuck in this contract and need to be recovered
    function recoverERC20(address token, address dest) external onlyOwner {
        IERC20 coin = IERC20(token);
        uint256 tokenBalance = coin.balanceOf(address(this));
        if (tokenBalance > 0) {
            coin.safeTransfer(dest, tokenBalance);
        } 
    }
    //transfer contract balance of an ERC20 token to contract owner
    function _recoverAllTokens(address token) internal {
        IERC20 coin = IERC20(token);
        uint256 tokenBalance = coin.balanceOf(address(this));
        if (tokenBalance > 0) {
            coin.safeTransfer(owner(), tokenBalance);
        }   
    }
}

contract Managed {
    address private _manager;
    event ManagementTransferred(address indexed previousManager, address indexed newManager);
    constructor () {
        _manager = msg.sender;
        emit ManagementTransferred(address(0), msg.sender);
    }
    function manager() public view virtual returns (address) {
        return _manager;
    }
    modifier onlyManager() {
        require(manager() == msg.sender, "only manager");
        _;
    }
    function renounceManagement() public virtual onlyManager {
        emit ManagementTransferred(_manager, address(0));
        _manager = address(0);
    }
    function transferManagement(address newManager) public virtual onlyManager {
        require(newManager != address(0), "zero bad");
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

//owned by an IglooStrategy contract
contract IglooStrategyStorage is Ownable {
    //scaled up by ACC_PEFI_PRECISION
    uint256 public rewardTokensPerShare;
    uint256 internal constant ACC_PEFI_PRECISION = 1e18;

    //pending reward = (user.amount * rewardTokensPerShare) / ACC_PEFI_PRECISION - user.rewardDebt
    mapping(address => uint256) public rewardDebt;

    function increaseRewardDebt(address user, uint256 shareAmount) external onlyOwner {
        rewardDebt[user] += (rewardTokensPerShare * shareAmount) / ACC_PEFI_PRECISION;
    }

    function decreaseRewardDebt(address user, uint256 shareAmount) external onlyOwner {
        rewardDebt[user] -= (rewardTokensPerShare * shareAmount) / ACC_PEFI_PRECISION;
    }

    function setRewardDebt(address user, uint256 userShares) external onlyOwner {
        rewardDebt[user] = (rewardTokensPerShare * userShares) / ACC_PEFI_PRECISION;
    }

    function increaseRewardTokensPerShare(uint256 amount) external onlyOwner {
        rewardTokensPerShare += amount;
    }
}

//owned by IglooStrategyForTimeMemoMagic
contract TimeStakingAndBondingManager is Ownable, Managed {
    using SafeERC20 for IERC20;

    //list index of next stakingDummy contract to claim from
    uint256 public nextStakingDummyIndex;
    //list index of next bondingDummy contract to claim from
    uint256 public nextBondingDummyIndex;

    //time actively locked in staking for MEMO
    uint256 public timeInStaking;
    //time actively locked in staking for MEMO
    uint256 public timeInBonds;

    //list of all dummy contracts used for staking
    address[] public singleUseStakingDummies;
    //list of all dummy contracts used for bonding
    address[] public singleUseBondingDummies;

    //address of TimeStrategyHelper contract
    address public timeStrategyHelper;

    //max number of dummies to claim from in a single call
    uint256 public maxStakingClaimsInCall = 20;
    uint256 public maxBondingClaimsInCall = 20;

    ITimeStaking constant public timeStaking = ITimeStaking(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    ITimeBondDepository constant public avax_Depository = ITimeBondDepository(0xE02B1AA2c4BE73093BE79d763fdFFC0E3cf67318);
    ITimeBondDepository constant public timeAvaxJLP_Depository = ITimeBondDepository(0xc26850686ce755FFb8690EA156E5A6cf03DcBDE1);
    ITimeBondDepository constant public timeMimJLP_Depository = ITimeBondDepository(0xA184AE1A71EcAD20E822cB965b99c287590c4FFe);
    ITimeBondDepository constant public mim_Depository = ITimeBondDepository(0x694738E0A438d90487b4a549b201142c1a97B556);
    address constant public TIME = 0xb54f16fB19478766A268F172C9480f8da1a7c9C3;
    address constant public MEMO = 0x136Acd46C134E8269052c62A67042D6bDeDde3C9;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    //tracks all time profits
    uint256 public cumulativeProfits;

    uint256 internal constant MAX_BIPS = 10000;

    constructor(address _timeStrategyHelper){
        require(_timeStrategyHelper != address(0));
        timeStrategyHelper = _timeStrategyHelper;
        //approve timeStaking to transfer TIME and MEMO tokens
        IERC20(TIME).approve(address(timeStaking), MAX_UINT);
        IERC20(MEMO).approve(address(timeStaking), MAX_UINT);
        //approve timeBondDepositories to transfer their respective tokens
        IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7).approve(address(avax_Depository), MAX_UINT);
        IERC20(0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917).approve(address(timeAvaxJLP_Depository), MAX_UINT);
        IERC20(0x113f413371fC4CC4C9d6416cf1DE9dFd7BF747Df).approve(address(timeMimJLP_Depository), MAX_UINT);
        IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D).approve(address(mim_Depository), MAX_UINT);
    }

    //VIEW FUNCTIONS
    function numberSingleUseStakingDummies() external view returns (uint256) {
        return singleUseStakingDummies.length;
    }

    function numberSingleUseBondingDummies() external view returns (uint256) {
        return singleUseBondingDummies.length;
    }

    function totalTime() external view returns (uint256) {
        return IERC20(TIME).balanceOf(owner()) + IERC20(MEMO).balanceOf(owner()) + timeInStaking + timeInBonds;
    }

    //MANAGER-ONLY FUNCTIONS
    function forceClaimStakes() external onlyManager {
        _claimStakes();
    }

    function forceClaimSpecificStakes(uint256[] memory stakingDummyIndices) external onlyManager {
        uint256 memoBefore = IERC20(MEMO).balanceOf(address(this));
        uint256 timeStaked;
        for (uint256 i = 0; i < stakingDummyIndices.length; i++) {
            if (TimeStrategyHelper(timeStrategyHelper).canClaimStake(singleUseStakingDummies[stakingDummyIndices[i]])) {
                SingleUseTimeStakingDummy(singleUseStakingDummies[stakingDummyIndices[i]]).claim();
                timeStaked += SingleUseTimeStakingDummy(singleUseStakingDummies[stakingDummyIndices[i]]).amountTime();
            }
        }
        uint256 memoObtained = IERC20(MEMO).balanceOf(address(this)) - memoBefore;
        timeInStaking -= Math.min(timeInStaking, timeStaked);
        if (memoObtained > 0) {
            IERC20(MEMO).transfer(owner(), memoObtained);            
        }
    }

    function forceForfeitStakes(uint256[] memory stakingDummyIndices) external onlyManager {
        uint256 timeBalBefore = IERC20(TIME).balanceOf(address(this));
        for (uint256 i = 0; i < stakingDummyIndices.length; i++) {
            SingleUseTimeStakingDummy(singleUseStakingDummies[stakingDummyIndices[i]]).forfeit();
        }
        uint256 timeObtained = IERC20(TIME).balanceOf(address(this)) - timeBalBefore;
        timeInStaking -= Math.min(timeInStaking, timeObtained);
        if (timeObtained > 0) {
            IERC20(TIME).transfer(owner(), timeObtained);            
        }
    }

    function forceClaimBonds() external onlyManager {
        _claimBonds();
    }

    function forceClaimSpecificBonds(uint256[] memory bondingDummyIndices) external onlyManager {
        uint256 timeBefore = IERC20(TIME).balanceOf(address(this));
        uint256 timeStaked;
        for (uint256 i = 0; i < bondingDummyIndices.length; i++) {
            if (SingleUseTimeBondingDummy(singleUseBondingDummies[bondingDummyIndices[i]]).percentVested() >= MAX_BIPS) {
                SingleUseTimeBondingDummy(singleUseBondingDummies[i]).redeem();
                timeStaked += SingleUseTimeBondingDummy(singleUseBondingDummies[bondingDummyIndices[i]]).amountTime();
            }
        }
        uint256 timeObtained = IERC20(TIME).balanceOf(address(this)) - timeBefore;
        timeInBonds -= Math.min(timeInBonds, timeObtained);
        if (timeObtained > 0) {
            IERC20(TIME).transfer(owner(), timeObtained);            
        }
    }

    //to be used in cases where time has been otherwise claimed, so timeInStaking is not artificially inflated
    function forceReduceTimeInStaking(uint256 timeAmount) external onlyManager {
        timeInStaking -= timeAmount;
    }

    //to be used in cases where time has been otherwise claimed, so timeInBonds is not artificially inflated
    function forceReduceTimeInBonding(uint256 timeAmount) external onlyManager {
        timeInBonds -= timeAmount;
    }

    function setTimeStrategyHelper(address _timeStrategyHelper) external onlyManager {
        require(_timeStrategyHelper != address(0));
        timeStrategyHelper = _timeStrategyHelper;
    }

    function setMaxStakingClaimsInCall(uint256 newValue) external onlyManager {
        require(newValue <= 100, "sanity check");
        maxStakingClaimsInCall = newValue;
    }

    function setMaxBondingClaimsInCall(uint256 newValue) external onlyManager {
        require(newValue <= 100, "sanity check");
        maxBondingClaimsInCall = newValue;
    }

    //recover ERC20 from dummy. 'token' is not restricted, since the dummy will send the tokens to the *owner of this contract*, not to the manager
    function recoverERC20FromDummy(address dummy, address token) external onlyManager {
        SingleUseTimeStakingDummy(dummy).recoverERC20(token, owner());
    }

    //OWNER-ONLY FUNCTIONS
    //create new dummy and use it to stake '_amountTime' TIME tokens. lock deposits to prevent griefing
    function stake(uint256 _amountTime) external onlyOwner {
        SingleUseTimeStakingDummy singleUseStakingDummy = new SingleUseTimeStakingDummy(_amountTime);
        singleUseStakingDummies.push(address(singleUseStakingDummy));
        timeStaking.stake(_amountTime, address(singleUseStakingDummy));
        singleUseStakingDummy.toggleDepositLock();
        //add to total amount staked
        timeInStaking += _amountTime;
    }

    function createBond(uint256 _amountTokens, ITimeBondDepository timeBondDepository, IERC20 tokenToDeposit, uint256 _amountTime) external onlyOwner {
        SingleUseTimeBondingDummy singleUseBondingDummy = new SingleUseTimeBondingDummy(timeBondDepository, tokenToDeposit, _amountTime);
        singleUseBondingDummies.push(address(singleUseBondingDummy));
        tokenToDeposit.safeTransferFrom(owner(), address(singleUseBondingDummy), _amountTokens);
        singleUseBondingDummy.deposit(_amountTokens);
    }

    function claimStakes() external onlyOwner {
        _claimStakes();
    }

    //returns amount of time obtained
    function forfeitStakes(uint256 amountTimeDesired) external onlyOwner returns (uint256) {
        uint256 timeBalBefore = IERC20(TIME).balanceOf(address(this));
        uint256 i;
        while (i < maxStakingClaimsInCall && 
            (nextStakingDummyIndex + i < singleUseStakingDummies.length) && 
            (IERC20(TIME).balanceOf(address(this)) - timeBalBefore < amountTimeDesired)
            )
        {
            SingleUseTimeStakingDummy(singleUseStakingDummies[nextStakingDummyIndex + i]).forfeit();
            i += 1;
        }
        nextStakingDummyIndex += i;
        uint256 timeObtained = IERC20(TIME).balanceOf(address(this)) - timeBalBefore;
        timeInStaking -= Math.min(timeInStaking, timeObtained);
        if (timeObtained > 0) {
            IERC20(TIME).transfer(owner(), timeObtained);            
        }
        return timeObtained;
    }

    function claimBonds() external onlyOwner {
        _claimBonds();
    }

    //INTERNAL FUNCTIONS
    function _claimStakes() internal {
        uint256 memoBefore = IERC20(MEMO).balanceOf(address(this));
        uint256 i;
        uint256 timeStaked;
        while (i < maxStakingClaimsInCall && 
            (i + nextStakingDummyIndex < singleUseStakingDummies.length) && 
            TimeStrategyHelper(timeStrategyHelper).canClaimStake(singleUseStakingDummies[nextStakingDummyIndex + i])
            )
        {
            SingleUseTimeStakingDummy(singleUseStakingDummies[nextStakingDummyIndex + i]).claim();
            timeStaked += SingleUseTimeStakingDummy(singleUseStakingDummies[nextStakingDummyIndex + i]).amountTime();
            i += 1;
        }
        nextStakingDummyIndex += i;
        uint256 memoObtained = IERC20(MEMO).balanceOf(address(this)) - memoBefore;
        timeInStaking -= Math.min(timeInStaking, memoObtained);
        if (memoObtained > 0) {
            IERC20(MEMO).transfer(owner(), memoObtained);            
        }
    }

    function _claimBonds() internal {
        uint256 timeBefore = IERC20(TIME).balanceOf(address(this));
        uint256 i;
        uint256 timeStaked;
        bool continueLoop = true;
        while (i < maxStakingClaimsInCall && 
            (nextBondingDummyIndex + i < singleUseBondingDummies.length) &&
            continueLoop
            )
        {
            //skip any dummies without open bonds, and just increase the index i by 1
            if (TimeStrategyHelper(timeStrategyHelper).hasOpenBond(
                singleUseBondingDummies[nextBondingDummyIndex + i], 
                address(SingleUseTimeBondingDummy(singleUseBondingDummies[nextBondingDummyIndex + i]).timeBondDepository()))
                ) {
                //stop claiming if it would be incomplete amount, as this resets the vesting period
                if (SingleUseTimeBondingDummy(singleUseBondingDummies[nextBondingDummyIndex + i]).percentVested() < MAX_BIPS) {
                    continueLoop = false;
                } else {
                    SingleUseTimeBondingDummy(singleUseBondingDummies[nextBondingDummyIndex + i]).redeem();
                    timeStaked += SingleUseTimeBondingDummy(singleUseBondingDummies[nextBondingDummyIndex + i]).amountTime();
                }
            }
            i += 1;
        }
        nextBondingDummyIndex += i;
        uint256 timeObtained = IERC20(TIME).balanceOf(address(this)) - timeBefore;
        timeInBonds -= Math.min(timeInBonds, timeObtained);
        if (timeObtained > 0) {
            IERC20(TIME).transfer(owner(), timeObtained);            
        }
    }
}

contract IglooStrategyForTimeMemoMagic is Ownable, Managed {
    using SafeERC20 for IERC20;
    using Math for uint256;

    ITimeStaking constant public timeStaking = ITimeStaking(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    ITimeBondDepository constant public avax_Depository = ITimeBondDepository(0xE02B1AA2c4BE73093BE79d763fdFFC0E3cf67318);
    ITimeBondDepository constant public timeAvaxJLP_Depository = ITimeBondDepository(0xc26850686ce755FFb8690EA156E5A6cf03DcBDE1);
    ITimeBondDepository constant public timeMimJLP_Depository = ITimeBondDepository(0xA184AE1A71EcAD20E822cB965b99c287590c4FFe);
    ITimeBondDepository constant public mim_Depository = ITimeBondDepository(0x694738E0A438d90487b4a549b201142c1a97B556);
    address constant public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant public TIME_AVAX_JLP = 0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917;
    address constant public TIME_MIM_JLP = 0x113f413371fC4CC4C9d6416cf1DE9dFd7BF747Df;
    address constant public MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address constant public TIME = 0xb54f16fB19478766A268F172C9480f8da1a7c9C3;
    address constant public MEMO = 0x136Acd46C134E8269052c62A67042D6bDeDde3C9;

    //pid in iglooMaster
    uint256 public immutable pid;

    IglooStrategyStorage public immutable iglooStrategyStorage;
    //total harvested by the contract all time
    uint256 public totalHarvested;

    IRouter constant public joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    //total amount harvested by each user
    mapping(address => uint256) public harvested;

    //if true, default to bonding, otherwise default to staking
    bool public bondingPreferred;
    //if true and bonding is preferred, MEMO swapped to TIME in order to bond more. should only be true if bonding rates are significantly higher than staking rates
    bool public swapMemoToBond;
    //variable that tracks current best bonding strategy
    uint256 public currentBondingStrategy;

    //as a fraction of 1e18 (e.g. 5.7e16 is 5.7%) of total deposits
    uint256 public minTimeFractionAvailableForWithdraw;

    TimeStakingAndBondingManager public timeStakingAndBondingManager;

    //stored historic exchange rates and their timestamps, separated by ~24 hour intervals
    uint256 public rollingStartTimestamp;
    uint256 public numStoredExchangeRates;
    uint256[] public historicExchangeRates;
    uint256[] public historicTimestamps;

    IIglooMaster public immutable iglooMaster;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant ACC_PEFI_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;
    uint256 internal constant SECONDS_PER_DAY = 86400;

    //dummy token used for obtaining PEFI for rewards
    IERC20 public immutable dummyToken;

    //total shares in this pool
    uint256 public totalShares;
    //user shares in this pool
    mapping(address => uint256) public userShares;

    //iPEFI distributed to participants
    IERC20 public immutable rewardToken;

    //keeps contract from wasting resources staking or bonding tiny amounts
    uint256 public minAmountToStake = 0;
    uint256 public minAmountToBond = 0;
    //keeps contract from trying to bond too large an amount at once
    uint256 public maxAmountToBond = 100e9;

    //number of days to look back at exchange rate when crediting MEMO depositors. default is 0, max is 4
    uint256 public memoDepositBonusDays;

    //tracking for pending for delayed (i.e. non-instant) withdrawals
    uint256 public totalPendingWithdrawals;
    mapping(address => uint256) public withdrawalTimestamps;
    mapping(address => uint256) public pendingWithdrawals;

    //last stored value of totalTime
    uint256 public totalTimeStoredValue;
    //unwithdrawn profits
    uint256 public unwithdrawnPerformanceFees;
    //bips to charge on accumulated profits
    uint256 public performanceFeeBips = 1000;

    //parameters for auto-updating the strategy
    bool public autoUpdateStrategy;
    uint256 public timeToAutoCheck;
    uint256 public swapMemoToBondThreshold;

    event Harvest(address indexed user, uint256 harvestedAmount);
    event Deposit(address indexed user, uint256 depositedAmount, uint256 shareAmount);
    event Withdrawal(address indexed user, uint256 withdrawnAmount, uint256 shareAmount);
    event Earn(address indexed caller, uint256 indexed currentExchangeRate, uint256 indexed blockTimestamp, uint256 unwithdrawnPerformanceFees);

    modifier harvestAndCheckProfits() {
        _harvest();
        _checkProfits();
        _;
    }

    constructor(
        IIglooMaster _iglooMaster,
        uint256 _pid,
        IglooStrategyStorage _iglooStrategyStorage,
        TimeStakingAndBondingManager _timeStakingAndBondingManager,
        IERC20 _dummyToken,
        IERC20 _rewardToken
    ){
        iglooMaster = _iglooMaster;
        pid = _pid;
        iglooStrategyStorage = _iglooStrategyStorage;
        timeStakingAndBondingManager = _timeStakingAndBondingManager;
        //approve MEMO on time staking to allow this contract to convert MEMO => TIME as needed
        IERC20(MEMO).approve(address(timeStaking), MAX_UINT);
        //approve joeRouter to transfer time tokens, for use in swapping
        IERC20(TIME).approve(address(joeRouter), MAX_UINT);
        //approve timeStakingAndBondingManager to transfer all bondable tokens
        IERC20(WAVAX).approve(address(timeStakingAndBondingManager), MAX_UINT);
        IERC20(TIME_AVAX_JLP).approve(address(timeStakingAndBondingManager), MAX_UINT);
        IERC20(TIME_MIM_JLP).approve(address(timeStakingAndBondingManager), MAX_UINT);
        IERC20(MIM).approve(address(timeStakingAndBondingManager), MAX_UINT);
        //deposit dummy token in IglooMaster pool, and set distribution to be entirely in iPEFI
        dummyToken = _dummyToken;
        _dummyToken.approve(address(_iglooMaster), MAX_UINT);
        _iglooMaster.setIpefiDistributionBips(MAX_BIPS);
        rewardToken = _rewardToken;
        //store initial exchange rate of 1e18
        _dailyUpdate();
    }

    //VIEW FUNCTIONS
    //returns current exchange rate of shares to Time, **scaled up by 1e18**
    function currentExchangeRate() public view returns(uint256) {
        if(totalShares == 0) {
            return 1e18;
        } else {
            uint256 currentTotalTime = totalTime();
            uint256 adjustedAmount = currentTotalTime > unwithdrawnPerformanceFees ? currentTotalTime - unwithdrawnPerformanceFees : 0;
            uint256 profit = currentTotalTime > totalTimeStoredValue ? currentTotalTime - totalTimeStoredValue : 0;
            if (profit > 0) {
                uint256 performanceFee = (profit * performanceFeeBips) / MAX_BIPS;
                adjustedAmount = adjustedAmount > performanceFee ? adjustedAmount - performanceFee : 0;
            }
            return (adjustedAmount * 1e18) / totalShares;
        }
    }

    //returns most recent stored exchange rate and the time at which it was stored
    function getLatestStoredExchangeRate() public view returns(uint256, uint256) {
        return (historicExchangeRates[numStoredExchangeRates - 1], historicTimestamps[numStoredExchangeRates - 1]);
    }

    //returns last amount of stored exchange rate datas
    function getExchangeRateHistory(uint256 amount) public view returns(uint256[] memory, uint256[] memory) {
        uint256 endIndex = numStoredExchangeRates - 1;
        uint256 startIndex = (amount > endIndex) ? 0 : (endIndex - amount + 1);
        uint256 length = endIndex - startIndex + 1;
        uint256[] memory exchangeRates = new uint256[](length);
        uint256[] memory timestamps = new uint256[](length);
        for(uint256 i = startIndex; i <= endIndex; i++) {
            exchangeRates[i - startIndex] = historicExchangeRates[i];
            timestamps[i - startIndex] = historicTimestamps[i];            
        }
        return (exchangeRates, timestamps);
    }

    function timeSinceLastDailyUpdate() public view returns(uint256) {
        return (block.timestamp - rollingStartTimestamp);
    }

    function timeAvailableForWithdraw() public view returns (uint256) {
        return IERC20(TIME).balanceOf(address(this)) + IERC20(MEMO).balanceOf(address(this));
    }

    function minTimeAvailableForWithdraw() public view returns(uint256) {
        return (totalTime() * minTimeFractionAvailableForWithdraw) / 1e18 + totalPendingWithdrawals;
    }

    function totalTime() public view returns(uint256) {
        return timeStakingAndBondingManager.totalTime();
    }

    //gets amount of pending iPEFI for the user to harvest
    function pendingRewards(address user) external view returns (uint256) {
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare();
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user);
        uint256 multiplier =  rewardTokensPerShare;
        uint256 totalRewards = (userShares[user] * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        return userPendingRewards;
    }

    //gets amount of pending iPEFI for the contract to harvest
    function checkReward() public view returns (uint256) {
        return iglooMaster.pendingIPEFI(pid, address(this));
    }

    //find number of shares to issue for an amount of TIME
    function sharesFromAmount(uint256 amountTime) public view returns (uint256) {
        return _getSharesFromAmount(amountTime, currentExchangeRate());
    }

    //find number of shares to issue for an amount of MEMO
    function sharesFromMemoAmount(uint256 amountMemo) public view returns (uint256) {
        if (memoDepositBonusDays == 0) {
            return _getSharesFromAmount(amountMemo, currentExchangeRate());
        } else {
            uint256 exchangeRate = historicExchangeRates[historicExchangeRates.length - (memoDepositBonusDays + 1)];
            return _getSharesFromAmount(amountMemo, exchangeRate);            
        }
    }

    //find current value of shares
    function amountFromShares(uint256 amountShares) public view returns (uint256) {
        return _getAmountFromShares(amountShares, currentExchangeRate());
    }

    //find value of shares based on 5 days prior
    function instantWithdrawAmountFromShares(uint256 amountShares) public view returns (uint256) {
        if (numStoredExchangeRates < 5) {
            return amountShares;
        } else {
            uint256 pastExchangeRate = historicExchangeRates[numStoredExchangeRates - 5];
            return _getAmountFromShares(amountShares, pastExchangeRate);
        }
    }

    //EXTERNAL FUNCTIONS
    function earn() external {
        //restricted to EOAs to protect against sandwich attacks or similar exploits
        require(msg.sender == tx.origin, "EOAs only");
        //claiming both stakes and bonds should help maximize timeAvailableForWithdraw(), allowing staking + bonding more
        //claim stakes to get more MEMO
        _claimStakes();
        //claim bonds to get more TIME
        _claimBonds();
        if (autoUpdateStrategy) {
            uint256 bondingPayout;
            (currentBondingStrategy, bondingPayout) = TimeStrategyHelper(TimeStakingAndBondingManager(timeStakingAndBondingManager).timeStrategyHelper()).findBestBondingStrategy(timeToAutoCheck);
            uint256 stakingPayout = (timeToAutoCheck * TimeStrategyHelper(TimeStakingAndBondingManager(timeStakingAndBondingManager).timeStrategyHelper()).checkStakingReturn()) / 1e18;
            if (bondingPayout > stakingPayout) {
                bondingPreferred = true;
                if ((bondingPayout * 1e18) / stakingPayout > swapMemoToBondThreshold) {
                    swapMemoToBond = true;
                }
            } else {
                bondingPreferred = false;
                swapMemoToBond = false;
            }
        }
        //stake funds if it is the most profitable strategy
        if (!bondingPreferred) {
            _increaseStakingPosition();
        //bond tokens otherwise
        } else if(!swapMemoToBond) {
            _increaseBondingPosition();
        } else {
            uint256 timeAvail = timeAvailableForWithdraw();
            uint256 minTimeAvail = minTimeAvailableForWithdraw();
            if (timeAvail > minTimeAvail && timeAvail < maxAmountToBond) {
                uint256 memoInput = Math.min(timeAvail - minTimeAvail, maxAmountToBond - timeAvail);
                _convertMemoToTime(memoInput);
            }
            _increaseBondingPosition();
        }
        emit Earn(msg.sender, currentExchangeRate(), block.timestamp, unwithdrawnPerformanceFees);
    }

    function withdrawPerformanceFees() external harvestAndCheckProfits {
        uint256 amountToWithdraw = unwithdrawnPerformanceFees;
        unwithdrawnPerformanceFees = 0;
        _attemptWithdraw(iglooMaster.performanceFeeAddress(), amountToWithdraw);
    }

    function depositTime(uint256 amountTime) external harvestAndCheckProfits {
        if (amountTime > 0) {
            uint256 shares = sharesFromAmount(amountTime);
            iglooStrategyStorage.increaseRewardDebt(msg.sender, shares);
            totalShares += shares;            
            userShares[msg.sender] += shares;
            IERC20(TIME).transferFrom(msg.sender, address(this), amountTime);
            //set totalTimeStoredValue to avoid over-counting profits
            totalTimeStoredValue = totalTime();
            emit Deposit(msg.sender, amountTime, shares);
        }
    }

    function depositMemo(uint256 amountMemo) external harvestAndCheckProfits {
        if (amountMemo > 0) {
            uint256 shares = sharesFromMemoAmount(amountMemo);
            iglooStrategyStorage.setRewardDebt(msg.sender, shares);
            totalShares += shares;            
            userShares[msg.sender] += shares;
            IERC20(MEMO).transferFrom(msg.sender, address(this), amountMemo);
            //increase totalTimeStoredValue to avoid over-counting profits
            totalTimeStoredValue = totalTime();
            emit Deposit(msg.sender, amountMemo, shares);
        }
    }

    function instantWithdrawal(uint256 amountShares) external harvestAndCheckProfits {
        if (amountShares > 0) {
            uint256 amountTime = instantWithdrawAmountFromShares(amountShares);
            iglooStrategyStorage.decreaseRewardDebt(msg.sender, amountShares);
            totalShares -= amountShares;            
            userShares[msg.sender] -= amountShares;
            _attemptWithdraw(msg.sender, amountTime);
            //set totalTimeStoredValue to avoid under-counting profits
            totalTimeStoredValue = totalTime();
            emit Withdrawal(msg.sender, amountTime, amountShares);
        }
    }

    function requestWithdrawal(uint256 amountShares) external harvestAndCheckProfits {
        if (amountShares > 0) {
            withdrawalTimestamps[msg.sender] = block.timestamp + 5 days;
            uint256 amountTime = amountFromShares(amountShares);
            pendingWithdrawals[msg.sender] += amountTime;
            totalPendingWithdrawals += amountTime;
            iglooStrategyStorage.decreaseRewardDebt(msg.sender, amountShares);
            totalShares -= amountShares;
            userShares[msg.sender] -= amountShares;
            emit Withdrawal(msg.sender, amountTime, amountShares);
        }
    }

    function completeWithdrawal() external harvestAndCheckProfits {
        require(withdrawalTimestamps[msg.sender] <= block.timestamp, "withdrawal too early");
        uint256 amountToWithdraw = pendingWithdrawals[msg.sender];
        if (amountToWithdraw > 0) {
            pendingWithdrawals[msg.sender] = 0;
            totalPendingWithdrawals -= amountToWithdraw;
            _attemptWithdraw(msg.sender, amountToWithdraw);
            //set totalTimeStoredValue to avoid under-counting profits
            totalTimeStoredValue = totalTime();
        }
    }

    //OWNER-ONlY FUNCTIONS
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external onlyOwner {
        require(amount > 0, "no 0");
        require(address(token) != TIME, "no TIME");
        require(address(token) != MEMO, "no MEMO");
        token.safeTransfer(to, amount);
    }

    //for potential use in migration
    function transferOwnershipOfDummy(address dummy, address newOwner) external onlyOwner {
        SingleUseTimeStakingDummy(dummy).transferOwnership(newOwner);
    }

    function setTimeStakingAndBondingManager(TimeStakingAndBondingManager _timeStakingAndBondingManager) external onlyOwner {
        timeStakingAndBondingManager = _timeStakingAndBondingManager;
    }

    function withdrawDummyToken() external onlyOwner {
        iglooMaster.withdraw(pid, 1e18, owner());
    }

    function depositDummyToken() external onlyOwner {
        iglooMaster.deposit(pid, 1e18, address(this));
    }

    //MANAGER-ONLY FUNCTIONS
    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external onlyManager {
        require(newPerformanceFeeBips <= 1000, "input too high");
        performanceFeeBips = newPerformanceFeeBips;
    }

    function setMinTimeFractionAvailableForWithdraw(uint256 newValue) external onlyManager {
        require(newValue <= 1e18, "bad fraction");
        minTimeFractionAvailableForWithdraw = newValue;
    }

    function setMinAmountToStake(uint256 newValue) external onlyManager {
        minAmountToStake = newValue;
    }

    function setBondingLimits(uint256 newMin, uint256 newMax) external onlyManager {
        require(newMin < newMax, "bad inputs");
        minAmountToBond = newMin;
        maxAmountToBond = newMax;
    }

    function setMemoDepositBonusDays(uint256 newValue) external onlyManager {
        require(newValue <= 4 && newValue <= numStoredExchangeRates, "bad");
        memoDepositBonusDays = newValue;
    }

    function setBondingPreferred(bool newValue) external onlyManager {
        bondingPreferred = newValue;
    }

    function setSwapMemoToBond(bool newValue) external onlyManager {
        swapMemoToBond = newValue;
    }

    function setAutoUpdateParameters(bool _autoUpdateStrategy, uint256 _timeToAutoCheck, uint256 _swapMemoToBondThreshold) external onlyOwner {
        require(_swapMemoToBondThreshold >= 1e18, "sanity");
        autoUpdateStrategy = _autoUpdateStrategy;
        timeToAutoCheck = _timeToAutoCheck;
        swapMemoToBondThreshold = _swapMemoToBondThreshold;
    }

    //INTERNAL FUNCTIONS
    function _getSharesFromAmount(uint256 amountTime, uint256 exchangeRate) internal pure returns (uint256) {
        return (amountTime * 1e18) / exchangeRate;
    }

    function _getAmountFromShares(uint256 shares, uint256 exchangeRate) internal pure returns (uint256) {
        return (shares * exchangeRate) / 1e18;
    }

    function _convertMemoToTime(uint256 _amountMemo) internal {
        timeStaking.unstake(_amountMemo, true);
    }

    //create new dummy and use it to stake '_amountTime' TIME tokens. lock deposits to prevent griefing
    function _stake(uint256 _amountTime) internal {
        IERC20(TIME).transfer(address(timeStakingAndBondingManager), _amountTime);
        timeStakingAndBondingManager.stake(_amountTime);
    }

    function _createBond(uint256 _amountTokens, ITimeBondDepository timeBondDepository, IERC20 tokenToDeposit, uint256 amountTimeToBond) internal {
        timeStakingAndBondingManager.createBond(_amountTokens, timeBondDepository, tokenToDeposit, amountTimeToBond);
    }

    function _claimStakes() internal {
        timeStakingAndBondingManager.claimStakes();
    }
    
    function _forfeitStakes(uint256 amountTimeDesired) internal returns (uint256) {
        return (timeStakingAndBondingManager.forfeitStakes(amountTimeDesired));
    }

    function _claimBonds() internal {
        timeStakingAndBondingManager.claimBonds();
    }

    function _attemptWithdraw(address recipient, uint256 amountTime) internal {
        uint256 timeBal = IERC20(TIME).balanceOf(address(this));
        //if contract already has enough TIME, just send TIME
        if (amountTime <= timeBal) {
            IERC20(TIME).transfer(recipient, amountTime);
            return;
        //in case contract needs more TIME
        } else {
            //claim bonds to get more TIME
            _claimBonds();
            timeBal = IERC20(TIME).balanceOf(address(this));
            //now if contract has enough TIME, just send TIME
            if (amountTime <= timeBal) {
                IERC20(TIME).transfer(recipient, amountTime);
                return;
            //start considering swapping MEMO to TIME
            } else {
                uint256 memoBal = IERC20(MEMO).balanceOf(address(this));
                if (amountTime <= timeBal + memoBal) {
                    _convertMemoToTime(amountTime - timeBal);
                    IERC20(TIME).transfer(recipient, amountTime);
                    return;
                //check if claiming stakes earns enough extra MEMO to cover
                } else {
                    //claim stakes to get more MEMO
                    _claimStakes();
                    memoBal = IERC20(MEMO).balanceOf(address(this));
                    if (amountTime <= timeBal + memoBal) {
                        _convertMemoToTime(amountTime - timeBal);
                        IERC20(TIME).transfer(recipient, amountTime);
                        return;
                    } else {
                        //try claiming more bonds to get more TIME
                        if (timeStakingAndBondingManager.nextBondingDummyIndex() < timeStakingAndBondingManager.numberSingleUseBondingDummies() - 1) {
                            _claimBonds();
                            timeBal = IERC20(TIME).balanceOf(address(this));
                            if (amountTime <= timeBal) {
                                IERC20(TIME).transfer(recipient, amountTime);
                                return;
                            } else if (amountTime <= timeBal + memoBal) {
                                _convertMemoToTime(amountTime - timeBal);
                                IERC20(TIME).transfer(recipient, amountTime);
                                return;
                            }
                        }
                        //try claiming more stakes to get more MEMO
                        if (timeStakingAndBondingManager.nextStakingDummyIndex() < timeStakingAndBondingManager.numberSingleUseStakingDummies() - 1) {
                            _claimStakes();
                            memoBal = IERC20(MEMO).balanceOf(address(this));
                            if (amountTime <= timeBal + memoBal) {
                                _convertMemoToTime(amountTime - timeBal);
                                IERC20(TIME).transfer(recipient, amountTime);
                                return;
                            }
                        }
                        //try forfeiting stakes for TIME
                        uint256 amountTimeDesired = amountTime - (timeBal + memoBal);
                        uint256 timeObtained = _forfeitStakes(amountTimeDesired);
                        if (timeObtained >= amountTimeDesired) {
                            timeBal = IERC20(TIME).balanceOf(address(this));
                            if (amountTime <= timeBal) {
                                IERC20(TIME).transfer(recipient, amountTime);
                                return;
                            } else if (amountTime <= timeBal + memoBal) {
                                _convertMemoToTime(amountTime - timeBal);
                                IERC20(TIME).transfer(recipient, amountTime);
                                return;
                            }
                        }
                        revert("withdrawal is too large! contact PenguinFinance team!");
                    }
                }
            }
        }
    }

    //open a new bond position with the best strategy
    //swap TIME to token as needed, get the amount out, then _createBond(amountOut, timeBondDepository, tokenToDeposit)
    function _increaseBondingPosition() internal {
        uint256 timeToBond = IERC20(TIME).balanceOf(address(this));
        uint256 minAvailableForWithdraw = minTimeAvailableForWithdraw();
        timeToBond = timeToBond > minAvailableForWithdraw ? timeToBond - minAvailableForWithdraw : 0;
        if (timeToBond > minAmountToBond) {
            if (timeToBond > maxAmountToBond) {
                timeToBond = maxAmountToBond;
            }
            (currentBondingStrategy, ) = TimeStrategyHelper(TimeStakingAndBondingManager(timeStakingAndBondingManager).timeStrategyHelper()).findBestBondingStrategy(timeToBond);
            //bond using WAVAX
            if (currentBondingStrategy == 1) {
                address[] memory path = new address[](2);
                path[0] = TIME;
                path[1] = WAVAX; //WAVAX
                uint256[] memory amountsOut = joeRouter.swapExactTokensForTokens(timeToBond, 0, path, address(this), block.timestamp);
                uint256 wavaxOut = amountsOut[amountsOut.length - 1];
                _createBond(wavaxOut, avax_Depository, IERC20(WAVAX), timeToBond);
            //bond using MIM
            } else if (currentBondingStrategy == 2) {
                address[] memory path = new address[](2);
                path[0] = TIME;
                path[1] = MIM; //MIM
                uint256[] memory amountsOut = joeRouter.swapExactTokensForTokens(timeToBond, 0, path, address(this), block.timestamp);
                uint256 mimOut = amountsOut[amountsOut.length - 1];
                _createBond(mimOut, mim_Depository, IERC20(MIM), timeToBond);
            //bond using TIME/WAVAX JLP -- TIME_AVAX_JLP
            } else if (currentBondingStrategy == 3) {
                address[] memory path = new address[](2);
                path[0] = TIME;
                path[1] = WAVAX; //WAVAX
                uint256[] memory amountsOut = joeRouter.swapExactTokensForTokens(timeToBond / 2, 0, path, address(this), block.timestamp);
                uint256 wavaxOut = amountsOut[amountsOut.length - 1];
                ( , , uint256 liquidityOut) = joeRouter.addLiquidity(
                    WAVAX, TIME, wavaxOut, timeToBond / 2, 0, 0, address(this), block.timestamp
                );
                _createBond(liquidityOut, timeAvaxJLP_Depository, IERC20(TIME_AVAX_JLP), timeToBond);
            //bond using TIME/MIM JLP -- TIME_MIM_JLP
            } else if (currentBondingStrategy == 4) {
                address[] memory path = new address[](2);
                path[0] = TIME;
                path[1] = MIM; //MIM
                uint256[] memory amountsOut = joeRouter.swapExactTokensForTokens(timeToBond / 2, 0, path, address(this), block.timestamp);
                uint256 mimOut = amountsOut[amountsOut.length - 1];
                ( , , uint256 liquidityOut) = joeRouter.addLiquidity(
                    MIM, TIME, mimOut, timeToBond / 2, 0, 0, address(this), block.timestamp
                );
                _createBond(liquidityOut, timeMimJLP_Depository, IERC20(TIME_MIM_JLP), timeToBond);
            }            
        }
    }

    function _increaseStakingPosition() internal {
        uint256 timeToStake = IERC20(TIME).balanceOf(address(this));
        uint256 minAvailableForWithdraw = minTimeAvailableForWithdraw();
        uint256 memoBal = IERC20(MEMO).balanceOf(address(this));
        if (memoBal < minAvailableForWithdraw) {
            uint256 timeToKeep = minAvailableForWithdraw - memoBal;
            if (timeToKeep >= timeToStake) {
                return;
            } else {
                timeToStake -= timeToKeep;
            }
        }
        if (timeToStake > minAmountToStake) {
            _stake(timeToStake);
        }
    }

    function _harvest() internal {
        _claimRewards();
        _dailyUpdate();
        uint256 totalRewards = (userShares[msg.sender] * iglooStrategyStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(msg.sender);
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        iglooStrategyStorage.setRewardDebt(msg.sender, userShares[msg.sender]);
        if (userPendingRewards > 0) {
            totalHarvested += userPendingRewards;
            harvested[msg.sender] += userPendingRewards;
            emit Harvest(msg.sender, userPendingRewards);
            _safeRewardTokenTransfer(msg.sender, userPendingRewards);
        }
    }

    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards > 0 && totalShares > 0) {
            uint256 balanceBefore = rewardToken.balanceOf(address(this));
            iglooMaster.harvest(pid, address(this));
            uint256 balanceDiff = rewardToken.balanceOf(address(this)) - balanceBefore;
            iglooStrategyStorage.increaseRewardTokensPerShare((balanceDiff * ACC_PEFI_PRECISION) / totalShares);
        }
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address user, uint256 amount) internal {
        uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
        if (amount > rewardTokenBal) {
            rewardToken.safeTransfer(user, rewardTokenBal);
        } else {
            rewardToken.safeTransfer(user, amount);
        }
    }

    //stores the exchange rate if it's been a day or more since the last one was stored
    function _dailyUpdate() internal {
        if (timeSinceLastDailyUpdate() >= SECONDS_PER_DAY) {
            //update rolling data
            rollingStartTimestamp = block.timestamp;
            //store exchange rate and timestamp
            historicExchangeRates.push(currentExchangeRate());
            historicTimestamps.push(block.timestamp);
            numStoredExchangeRates += 1;
        }
    }

    //check for profits and store performance fees for withdrawal
    function _checkProfits() internal {
        uint256 currentTotalTime = totalTime();
        uint256 profit = currentTotalTime > totalTimeStoredValue ? currentTotalTime - totalTimeStoredValue : 0;
        if (profit > 0) {
            uint256 performanceFee = (profit * performanceFeeBips) / MAX_BIPS;
            unwithdrawnPerformanceFees += performanceFee;
            totalTimeStoredValue = currentTotalTime + profit - performanceFee;
        }
    }
}

contract TimeStrategyHelper is Ownable {
    ITimeBondDepository constant public avax_Depository = ITimeBondDepository(0xE02B1AA2c4BE73093BE79d763fdFFC0E3cf67318);
    ITimeBondDepository constant public timeAvaxJLP_Depository = ITimeBondDepository(0xc26850686ce755FFb8690EA156E5A6cf03DcBDE1);
    ITimeBondDepository constant public timeMimJLP_Depository = ITimeBondDepository(0xA184AE1A71EcAD20E822cB965b99c287590c4FFe);
    ITimeBondDepository constant public mim_Depository = ITimeBondDepository(0x694738E0A438d90487b4a549b201142c1a97B556);
    ITimeTreasury constant public timeTreasury = ITimeTreasury(0x1c46450211CB2646cc1DA3c5242422967eD9e04c);
    ITimeStaking constant public timeStaking = ITimeStaking(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    address constant public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant public TIME_AVAX_JLP = 0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917;
    address constant public TIME_MIM_JLP = 0x113f413371fC4CC4C9d6416cf1DE9dFd7BF747Df;
    address constant public MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address constant public TIME = 0xb54f16fB19478766A268F172C9480f8da1a7c9C3;
    address constant public MEMO = 0x136Acd46C134E8269052c62A67042D6bDeDde3C9;
    IRouter constant public joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    address constant public JOE_FACTORY = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;

    //VIEW FUNCTIONS
    //gives multiplier (times 1e18) of rebase for current epoch
    function checkPendingRebaseReturn() public view returns (uint256 multiplier) {
        ITimeStaking.Epoch memory stakingEpoch = timeStaking.epoch();
        uint256 rebaseAmount = stakingEpoch.distribute;
        uint256 memoTotalSupply = IERC20(MEMO).totalSupply();
        uint256 memoCirculatingSupply = IMEMO(MEMO).circulatingSupply();
        if (rebaseAmount == 0) {
            return 0;
        }
        if (memoCirculatingSupply > 0) {
            rebaseAmount = (rebaseAmount * memoTotalSupply) / memoCirculatingSupply;
        }
        uint256 newMemoSupply = memoTotalSupply + rebaseAmount;
        multiplier = (1e18 * newMemoSupply) / memoTotalSupply;
    }

    //gives multiplier (times 1e18) of rebase for previous epochs
    function checkHistoricRebaseReturn() public view returns (uint256 multiplier, uint256 timeElapsed) {
        ITimeStaking.Epoch memory stakingEpoch = timeStaking.epoch();
        //this is because the first stored epoch is epoch 70, and the current epoch is not yet stored
        uint256 maxEpochStored = (stakingEpoch.number - 71);
        //here we subtract 15, as epochs last 8 hours and staking takes 5 days
        IMEMO.Rebase memory pastRebase = IMEMO(MEMO).rebases(maxEpochStored - 15);
        IMEMO.Rebase memory lastestRebase = IMEMO(MEMO).rebases(maxEpochStored);
        multiplier = (lastestRebase.index * 1e18) / pastRebase.index;
        timeElapsed = (lastestRebase.timeOccured - pastRebase.timeOccured);
    }

    function checkStakingReturn() public view returns (uint256 multiplier) {
        (multiplier, ) = checkHistoricRebaseReturn();
    }

    //returns if 'staker' can claim from the timeStaking contract
    function canClaimStake(address staker) public view returns (bool) {
        ITimeStaking.Claim memory info = timeStaking.warmupInfo(staker);
        ITimeStaking.Epoch memory stakingEpoch = timeStaking.epoch();
        if (stakingEpoch.number >= info.expiry && info.expiry != 0) {
            return true;
        } else {
            return false;
        }
    }
    
    //returns if 'bonder' has an open bond in the 'timeBondDepository'
    function hasOpenBond(address bonder, address timeBondDepository) public view returns (bool) {
        ITimeBondDepository.Bond memory bond = ITimeBondDepository(timeBondDepository).bondInfo(bonder);
        uint256 payout = bond.payout;
        return (payout > 0);
    }

    function findWavaxOutFromTime(uint256 amountTimeIn) public view returns (uint256 wavaxOut) {
        address[] memory path = new address[](2);
        path[0] = TIME;
        path[1] = WAVAX;
        uint256[] memory amountsOut = joeRouter.getAmountsOut(amountTimeIn, path);
        wavaxOut = amountsOut[amountsOut.length - 1];
    }

    function findMimOutFromTime(uint256 amountTimeIn) public view returns (uint256 mimOut) {
        address[] memory path = new address[](2);
        path[0] = TIME;
        path[1] = MIM;
        uint256[] memory amountsOut = joeRouter.getAmountsOut(amountTimeIn, path);
        mimOut = amountsOut[amountsOut.length - 1];
    }

    function findTimeAvaxLiquidityFromTime(uint256 amountTimeIn) public view returns (uint256 liquidityOut) {
        uint256 wavaxOut = findWavaxOutFromTime(amountTimeIn / 2);
        liquidityOut = getLiquidityOutWithoutSorting(JOE_FACTORY, TIME_AVAX_JLP, wavaxOut, amountTimeIn / 2);
    }

    function findTimeMimLiquidityFromTime(uint256 amountTimeIn) public view returns (uint256 liquidityOut) {
        uint256 mimOut = findMimOutFromTime(amountTimeIn / 2);
        liquidityOut = getLiquidityOutWithoutSorting(JOE_FACTORY, TIME_MIM_JLP, mimOut, amountTimeIn / 2);
    }

    function findPayoutFromWavax(uint256 wavaxIn) public view returns (uint256 payout) {
        uint256 value = timeTreasury.valueOf(WAVAX, wavaxIn);
        payout = avax_Depository.payoutFor(value);
    }

    function findPayoutFromMim(uint256 mimIn) public view returns (uint256 payout) {
        uint256 value = timeTreasury.valueOf(MIM, mimIn);
        payout = mim_Depository.payoutFor(value);
    }

    function findPayoutFromTimeAvaxJLP(uint256 timeAvaxJLPIn) public view returns (uint256 payout) {
        uint256 value = timeTreasury.valueOf(TIME_AVAX_JLP, timeAvaxJLPIn);
        payout = timeAvaxJLP_Depository.payoutFor(value);
    }

    function findPayoutFromTimeMimJLP(uint256 timeMimJLPIn) public view returns (uint256 payout) {
        uint256 value = timeTreasury.valueOf(TIME_MIM_JLP, timeMimJLPIn);
        payout = timeMimJLP_Depository.payoutFor(value);
    }

    function findBestBondingStrategy(uint256 amountTimeIn) public view returns (uint256, uint256) {
        uint256 payoutFromWavax = findPayoutFromWavax(findWavaxOutFromTime(amountTimeIn));
        (uint256 bestStrategy, uint256 payoutOfStrategy) = (1, payoutFromWavax);
        uint256 payoutFromMim = findPayoutFromMim(findWavaxOutFromTime(amountTimeIn));
        if (payoutFromMim > payoutOfStrategy) {
            (bestStrategy, payoutOfStrategy) = (2, payoutFromMim);
        }
        uint256 payoutFromTimeAvaxJLP = findPayoutFromTimeAvaxJLP(findTimeAvaxLiquidityFromTime(amountTimeIn));
        if (payoutFromMim > payoutOfStrategy) {
            (bestStrategy, payoutOfStrategy) = (3, payoutFromTimeAvaxJLP);
        }
        uint256 payoutFromTimeMimJLP = findPayoutFromTimeMimJLP(findTimeMimLiquidityFromTime(amountTimeIn));
        if (payoutFromMim > payoutOfStrategy) {
            (bestStrategy, payoutOfStrategy) = (4, payoutFromTimeMimJLP);
        }
        return (bestStrategy, payoutOfStrategy);
    }

    //EXTERNAL FUNCTIONS
    //NOTE: TESTING ONLY
    uint256 public preferredStrategy;
    uint256 public timeInput;
    uint256 public expectedPayout;
    function storeBestStrategy(uint256 amountTimeIn) external onlyOwner {
        timeInput = amountTimeIn;
        (preferredStrategy, expectedPayout) = findBestBondingStrategy(amountTimeIn);
    }
    //NOTE: END TESTING FUNCTIONALITY

    //INTERNAL FUNCTIONS
    //works like getLiquidityOut, but does not check ordering or do sorting of tokens, and assumes pair address is known
    function getLiquidityOutWithoutSorting(address factory, address pair, uint256 amountADesired, uint256 amountBDesired) 
    internal view returns (uint256 liquidityOut) {
        (uint256 reserveA, uint256 reserveB,) = IUniswapV2Pair(pair).getReserves();
        uint256 amountA;
        uint256 amountB = quote(amountADesired, reserveA, reserveB);
        if (amountB <= amountBDesired) {
            amountA = amountADesired;
        } else {
            amountA = quote(amountBDesired, reserveB, reserveA);
            amountB = amountBDesired;
        }
        uint256 _totalSupply = IUniswapV2Pair(pair).totalSupply() + _mintFeeU256(reserveA, reserveB, factory, pair);
        liquidityOut = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
    }

    function _mintFeeU256(uint256 _reserve0, uint256 _reserve1, address factory, address pair) internal view returns (uint256) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = IUniswapV2Pair(pair).kLast(); // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(_reserve0 * _reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = IUniswapV2Pair(pair).totalSupply() * (rootK - rootKLast);
                    uint256 denominator = (rootK * 5) + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    return liquidity;
                }
            }
        }
        return 0;
    }

    //*with update* to no longer use SafeMath, since this is solidity >0.8.0
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }
}