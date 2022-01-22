/**
 *Submitted for verification at snowtrace.io on 2022-01-22
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
        IIglooStrategy strategy; // Address of strategy for pool
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
        bool _withUpdate, IRewarder _rewarder, IIglooStrategy _strategy) external;
    function set(uint256 _pid, uint256 _allocPoint, uint16 _withdrawFeeBP,
        IRewarder _rewarder, bool _withUpdate, bool overwrite) external;
    function migrateStrategy(uint256 pid, IIglooStrategy newStrategy) external;
    function setStrategy(uint256 pid, IIglooStrategy newStrategy, bool transferOwnership, address newOwner) external;
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

//owned by the IglooMaster contract
interface IIglooStrategy {
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external;
    function setAllowances() external;
    function revokeAllowance(address token, address spender) external;
    function migrate(address newStrategy) external;
    function onMigration() external;
    function pendingTokens(uint256 pid, address user, uint256 pefiAmount) external view returns (address[] memory, uint256[] memory);
    function transferOwnership(address newOwner) external;
    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external;
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
        IRewarder rewarder;
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

interface IBenQiStaking {
    function nofStakingRewards() external view returns(uint);
    function REWARD_AVAX() external view returns(uint);
    function REWARD_QI() external view returns(uint);
    // QI-AVAX PGL token contract address
    function pglTokenAddress() external view returns(address);
    // Addresses of the ERC20 reward tokens
    function rewardTokenAddresses(uint) external view returns(address);
    // Reward accrual speeds per reward token as tokens per second
    function rewardSpeeds(uint) external view returns(uint);
    // Unclaimed staking rewards per user and token
    function accruedReward(uint, uint) external view returns(uint);
    // Supplied PGL tokens per user
    function supplyAmount(address) external view returns(uint);
    // Sum of all supplied PGL tokens
    function totalSupplies() external view returns(uint);
    function rewardIndex(uint) external view returns(uint);
    function supplierRewardIndex(address, uint) external view returns(uint);
    function accrualBlockTimestamp() external view returns(uint);
    function deposit(uint pglAmount) external;
    function redeem(uint pglAmount) external;
    function claimRewards() external;
    function getClaimableRewards(uint rewardToken) external view returns(uint);
}

interface ILydiaChef {
    function lyd() external view returns (address);
    function electrum() external view returns (address);
    function lydPerSec() external view returns (uint256);
    function pendingLyd(uint256 _pid, address _user) external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (
        address lpToken,
        uint256 allocPoint,
        uint256 lastRewardTimestamp,
        uint256 accLydPerShare
    );
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 pid, address user) external returns (uint256 amount, uint256 rewardDebt);
}

interface ISushiMiniChef {
    function SUSHI() external view returns (address);
    function sushiPerSecond() external view returns (uint256);
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function lpToken(uint256 pid) external view returns (address);
    function rewarder(uint256 pid) external view returns (address);
    function poolInfo(uint256 pid) external view returns (
        uint128 accSushiPerShare,
        uint64 lastRewardTime,
        uint64 allocPoint
    );
    function deposit(uint256 _pid, uint256 _amount, address to) external;
    function withdraw(uint256 _pid, uint256 _amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 pid, address user) external returns (uint256 amount, int256 rewardDebt); 
}

interface IPangolinMiniChef {
    function REWARD() external view returns (address);
    function rewardPerSecond() external view returns (uint256);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function lpToken(uint256 pid) external view returns (address);
    function rewarder(uint256 pid) external view returns (address);
    function poolInfo(uint256 pid) external view returns (
        uint128 accSushiPerShare,
        uint64 lastRewardTime,
        uint64 allocPoint
    );
    function deposit(uint256 _pid, uint256 _amount, address to) external;
    function withdraw(uint256 _pid, uint256 _amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 pid, address user) external returns (uint256 amount, int256 rewardDebt); 
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

contract IglooStrategyBase is IIglooStrategy, Ownable {
    using SafeERC20 for IERC20;

    IIglooMaster public immutable iglooMaster;
    IERC20 public immutable depositToken;
    uint256 public performanceFeeBips = 1000;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant ACC_PEFI_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;

    constructor(
        IIglooMaster _iglooMaster,
        IERC20 _depositToken
        ){
        iglooMaster = _iglooMaster;
        depositToken = _depositToken;
        transferOwnership(address(_iglooMaster));
    }

    //returns zero address and zero tokens since base strategy does not distribute rewards
    function pendingTokens(uint256, address, uint256) external view virtual override 
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

    function transferOwnership(address newOwner) public virtual override(Ownable, IIglooStrategy) onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external virtual override onlyOwner {
        require(newPerformanceFeeBips <= MAX_BIPS, "input too high");
        performanceFeeBips = newPerformanceFeeBips;
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

contract IglooStrategyForPangolinStaking is IglooStrategyBase {
    using SafeERC20 for IERC20;

    IERC20 public constant rewardToken = IERC20(0x60781C2586D68229fde47564546784ab3fACA982); //PNG token
    IStakingRewards public immutable stakingContract;
    IglooStrategyStorage public immutable iglooStrategyStorage;
    uint256 public immutable pid;
    //total harvested by the contract all time
    uint256 public totalHarvested;

    //total amount harvested by each user
    mapping(address => uint256) public harvested;

    event Harvest(address indexed caller, address indexed to, uint256 harvestedAmount);

    constructor(
        IERC20 _depositToken,
        uint256 _pid,
        IStakingRewards _stakingContract,
        IglooStrategyStorage _iglooStrategyStorage
        ) 
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), _depositToken)
    {
        pid = _pid;
        stakingContract = _stakingContract;
        iglooStrategyStorage = _iglooStrategyStorage;
        _depositToken.safeApprove(address(_stakingContract), MAX_UINT);
    }

    //PUBLIC FUNCTIONS
    /**
    * @notice Reward token balance that can be claimed
    * @dev Staking rewards accrue to contract on each deposit/withdrawal
    * @return Unclaimed rewards
    */
    function checkReward() public view returns (uint256) {
        return stakingContract.earned(address(this));
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 unclaimedRewards = checkReward();
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare();
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        return (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        uint256[] memory _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = pendingRewards(user);
        return(_rewardTokens, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    function harvest() external {
        _claimRewards();
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            stakingContract.stake(tokenAmount);
        }
        if (shareAmount > 0) {
            iglooStrategyStorage.increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            stakingContract.withdraw(tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
        if (shareAmount > 0) {
            iglooStrategyStorage.decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        uint256 toWithdraw = stakingContract.balanceOf(address(this));
        if (toWithdraw > 0) {
            stakingContract.withdraw(toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        uint256 rewardsToTransfer = rewardToken.balanceOf(address(this));
        if (rewardsToTransfer > 0) {
            rewardToken.safeTransfer(newStrategy, rewardsToTransfer);
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        stakingContract.stake(toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(stakingContract), 0);
        depositToken.safeApprove(address(stakingContract), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        uint256 totalShares = iglooMaster.totalShares(pid);
        if (unclaimedRewards > 0 && totalShares > 0) {
            stakingContract.getReward();
            iglooStrategyStorage.increaseRewardTokensPerShare((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
    }

    function _harvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        uint256 totalRewards = (userShares * iglooStrategyStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller);
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        iglooStrategyStorage.setRewardDebt(caller, userShares);
        if (userPendingRewards > 0) {
            totalHarvested += userPendingRewards;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                _safeRewardTokenTransfer(iglooMaster.performanceFeeAddress(), performanceFee);
                userPendingRewards = userPendingRewards - performanceFee;
            }
            harvested[to] += userPendingRewards;
            emit Harvest(caller, to, userPendingRewards);
            _safeRewardTokenTransfer(to, userPendingRewards);
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
}

contract IglooStrategyForJoeStaking is IglooStrategyBase {
    using SafeERC20 for IERC20;

    IERC20 public constant rewardToken = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd); //JOE token
    IglooStrategyStorage public immutable iglooStrategyStorage;
    IJoeChef public constant joeMasterChefV2 = IJoeChef(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    uint256 public immutable pid;
    uint256 public immutable joePid;
    //total harvested by the contract all time
    uint256 public totalHarvested;

    //total amount harvested by each user
    mapping(address => uint256) public harvested;

    event Harvest(address indexed caller, address indexed to, uint256 harvestedAmount);

    constructor(
        IERC20 _depositToken,
        uint256 _pid,
        uint256 _joePid,
        IglooStrategyStorage _iglooStrategyStorage
        )
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), _depositToken)
    {
        pid = _pid;
        joePid = _joePid;
        iglooStrategyStorage = _iglooStrategyStorage;
        _depositToken.safeApprove(address(joeMasterChefV2), MAX_UINT);
    }

    //PUBLIC FUNCTIONS
    /**
    * @notice Reward token balance that can be claimed
    * @dev Staking rewards accrue to contract on each deposit/withdrawal
    * @return Unclaimed rewards
    */
    function checkReward() public view returns (uint256) {
        (uint256 pendingJoe, , , ) = joeMasterChefV2.pendingTokens(joePid, address(this));
        return pendingJoe;
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 unclaimedRewards = checkReward();
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare();
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        return (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        uint256[] memory _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = pendingRewards(user);
        return(_rewardTokens, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    function harvest() external {
        _claimRewards();
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            joeMasterChefV2.deposit(joePid, tokenAmount);
        }
        if (shareAmount > 0) {
            iglooStrategyStorage.increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            joeMasterChefV2.withdraw(joePid, tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
        if (shareAmount > 0) {
            iglooStrategyStorage.decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        (uint256 toWithdraw, ) = joeMasterChefV2.userInfo(joePid, address(this));
        if (toWithdraw > 0) {
            joeMasterChefV2.withdraw(joePid, toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        uint256 rewardsToTransfer = rewardToken.balanceOf(address(this));
        if (rewardsToTransfer > 0) {
            rewardToken.safeTransfer(newStrategy, rewardsToTransfer);
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        joeMasterChefV2.deposit(joePid, toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(joeMasterChefV2), 0);
        depositToken.safeApprove(address(joeMasterChefV2), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        uint256 totalShares = iglooMaster.totalShares(pid);
        if (unclaimedRewards > 0 && totalShares > 0) {
            joeMasterChefV2.deposit(joePid, 0);
            iglooStrategyStorage.increaseRewardTokensPerShare((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
    }

    function _harvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        uint256 totalRewards = (userShares * iglooStrategyStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller);
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        iglooStrategyStorage.setRewardDebt(caller, userShares);
        if (userPendingRewards > 0) {
            totalHarvested += userPendingRewards;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                _safeRewardTokenTransfer(iglooMaster.performanceFeeAddress(), performanceFee);
                userPendingRewards = userPendingRewards - performanceFee;
            }
            harvested[to] += userPendingRewards;
            emit Harvest(caller, to, userPendingRewards);
            _safeRewardTokenTransfer(to, userPendingRewards);
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
}

//owned by an IglooStrategy contract
contract IglooStrategyStorageMultiReward is Ownable {
    //scaled up by ACC_PEFI_PRECISION
    uint256 internal constant ACC_PEFI_PRECISION = 1e18;

    //pending reward = (user.amount * rewardTokensPerShare) / ACC_PEFI_PRECISION - rewardDebt[user][tokenAddress]
    mapping(address => uint256) public rewardTokensPerShare;
    //stored as rewardDebt[user][tokenAddress]
    mapping(address => mapping(address => uint256)) public rewardDebt;

    function increaseRewardDebt(address user, address token, uint256 shareAmount) external onlyOwner {
        rewardDebt[user][token] += (rewardTokensPerShare[token] * shareAmount) / ACC_PEFI_PRECISION;
    }

    function decreaseRewardDebt(address user, address token, uint256 shareAmount) external onlyOwner {
        rewardDebt[user][token] -= (rewardTokensPerShare[token] * shareAmount) / ACC_PEFI_PRECISION;
    }

    function setRewardDebt(address user, address token, uint256 userShares) external onlyOwner {
        rewardDebt[user][token] = (rewardTokensPerShare[token] * userShares) / ACC_PEFI_PRECISION;
    }

    function increaseRewardTokensPerShare(address token, uint256 amount) external onlyOwner {
        rewardTokensPerShare[token] += amount;
    }
}

contract IglooStrategyForBenQiStaking is IglooStrategyBase {
    using SafeERC20 for IERC20;

    address[] public rewardTokensArray;
    uint256 public constant numberRewardTokens = 2;
        
    IglooStrategyStorageMultiReward public immutable iglooStrategyStorage;
    //BenQi's PglStakingContractProxy
    IBenQiStaking public constant benqiStaking = IBenQiStaking(0x784DA19e61cf348a8c54547531795ECfee2AfFd1);
    uint256 public immutable pid;
    //placeholder address for native token (AVAX)
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //total of each token harvested by the contract all time
    mapping(address => uint256) public totalHarvested;
    //total amount harvested by each user of each token 
    mapping(address => mapping(address => uint256)) public harvested;

    event Harvest(address indexed caller, address indexed to, address indexed rewardToken, uint256 harvestedAmount);

    constructor(
        uint256 _pid,
        IglooStrategyStorageMultiReward _iglooStrategyStorage
        )
        //iglooMaster and Qi/AVAX PGL token address
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), IERC20(0xE530dC2095Ef5653205CF5ea79F8979a7028065c))
    {
        rewardTokensArray = new address[](numberRewardTokens);
        rewardTokensArray[0] = AVAX;
        rewardTokensArray[1] = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;
        pid = _pid;
        iglooStrategyStorage = _iglooStrategyStorage;
        IERC20(0xE530dC2095Ef5653205CF5ea79F8979a7028065c).safeApprove(address(benqiStaking), MAX_UINT);
    }

    //PUBLIC FUNCTIONS
    function checkReward(uint256 tokenIndex) public view returns (uint256) {
        uint256 amountPending = benqiStaking.getClaimableRewards(tokenIndex);
        return amountPending;
    }

    function pendingRewards(address user, uint256 rewardTokenIndex) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 totalShares = iglooMaster.totalShares(pid);
        address rewardToken = rewardTokensArray[rewardTokenIndex];
        uint256 unclaimedRewards = checkReward(rewardTokenIndex);
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare(rewardToken);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user, rewardToken);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        return (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _rewardTokens[i] = rewardTokensArray[i];
        }
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        uint256[] memory _pendingAmounts = new uint256[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _pendingAmounts[i] = pendingRewards(user, i);
        }
        return(rewardTokensArray, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    //simple function to receive AVAX transfers
    receive() external payable {}

    //harvest has been made onlyOwner for this igloo to avoid any possibility of reentrancy
    function harvest() external onlyOwner {
        _claimRewards();
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            benqiStaking.deposit(tokenAmount);
        }
        if (shareAmount > 0) {
            _increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            benqiStaking.redeem(tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
        if (shareAmount > 0) {
            _decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        uint256 toWithdraw = benqiStaking.supplyAmount(address(this));
        if (toWithdraw > 0) {
            benqiStaking.redeem(toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 rewardsToTransfer = _checkBalance(rewardToken);
            if (rewardsToTransfer > 0) {
                _safeRewardTokenTransfer(rewardToken, newStrategy, rewardsToTransfer);
            }
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        benqiStaking.deposit(toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(benqiStaking), 0);
        depositToken.safeApprove(address(benqiStaking), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256[] memory pendingAmounts = new uint256[](numberRewardTokens);
        bool updateAndClaim;
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            pendingAmounts[i] = checkReward(i);
            if (pendingAmounts[i] > 0) {
                updateAndClaim = true;
            }
        }
        if (updateAndClaim && totalShares > 0) {
            uint256[] memory balancesBefore = new uint256[](numberRewardTokens);
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                balancesBefore[i] = _checkBalance(rewardTokensArray[i]);
            }
            benqiStaking.claimRewards();
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                uint256 balanceDiff = _checkBalance(rewardTokensArray[i]) - balancesBefore[i];
                if (balanceDiff > 0) {
                    iglooStrategyStorage.increaseRewardTokensPerShare(rewardTokensArray[i], (balanceDiff * ACC_PEFI_PRECISION) / totalShares);
                }  
            }
        }
    }

    function _harvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 totalRewards = userShares * iglooStrategyStorage.rewardTokensPerShare(rewardToken) / ACC_PEFI_PRECISION;
            uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller, rewardToken);
            uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
            iglooStrategyStorage.setRewardDebt(caller, rewardToken, userShares);
            if (userPendingRewards > 0) {
                totalHarvested[rewardToken] += userPendingRewards;
                if (performanceFeeBips > 0) {
                    uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                    _safeRewardTokenTransfer(rewardToken, iglooMaster.performanceFeeAddress(), performanceFee);
                    userPendingRewards = userPendingRewards - performanceFee;
                }
                harvested[to][rewardToken] += userPendingRewards;
                emit Harvest(caller, to, rewardToken, userPendingRewards);
                _safeRewardTokenTransfer(rewardToken, to, userPendingRewards);
            }
        }
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address token, address user, uint256 amount) internal {
        if (token == AVAX) {
            uint256 avaxBalance = address(this).balance;
            if (amount > avaxBalance) {
                payable(user).transfer(avaxBalance);
            } else {
                payable(user).transfer(amount);
            }
        } else {
            IERC20 rewardToken = IERC20(token);
            uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
            if (amount > rewardTokenBal) {
                rewardToken.safeTransfer(user, rewardTokenBal);
            } else {
                rewardToken.safeTransfer(user, amount);
            }            
        }
    }

    function _decreaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.decreaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _increaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.increaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _setRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.setRewardDebt(user, rewardTokensArray[i], amountShares);
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

contract IglooStrategyForLydStaking is IglooStrategyBase {
    using SafeERC20 for IERC20;

    IERC20 public constant rewardToken = IERC20(0x4C9B4E1AC6F24CdE3660D5E4Ef1eBF77C710C084); //LYD token
    IglooStrategyStorage public immutable iglooStrategyStorage;
    ILydiaChef public constant lydMasterChef = ILydiaChef(0xFb26525B14048B7BB1F3794F6129176195Db7766);
    uint256 public immutable pid;
    uint256 public immutable lydPid;
    //total harvested by the contract all time
    uint256 public totalHarvested;

    //total amount harvested by each user
    mapping(address => uint256) public harvested;

    event Harvest(address indexed caller, address indexed to, uint256 harvestedAmount);

    constructor(
        IERC20 _depositToken,
        uint256 _pid,
        uint256 _lydPid,
        IglooStrategyStorage _iglooStrategyStorage
        )
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), _depositToken)
    {
        pid = _pid;
        lydPid = _lydPid;
        iglooStrategyStorage = _iglooStrategyStorage;
        _depositToken.safeApprove(address(lydMasterChef), MAX_UINT);
    }

    //PUBLIC FUNCTIONS
    /**
    * @notice Reward token balance that can be claimed
    * @dev Staking rewards accrue to contract on each deposit/withdrawal
    * @return Unclaimed rewards
    */
    function checkReward() public view returns (uint256) {
        uint256 pendingLyd = lydMasterChef.pendingLyd(lydPid, address(this));
        return pendingLyd;
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 unclaimedRewards = checkReward();
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare();
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        return (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        uint256[] memory _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = pendingRewards(user);
        return(_rewardTokens, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    function harvest() external {
        _claimRewards();
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            lydMasterChef.deposit(lydPid, tokenAmount);
        }
        if (shareAmount > 0) {
            iglooStrategyStorage.increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            lydMasterChef.withdraw(lydPid, tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
        if (shareAmount > 0) {
            iglooStrategyStorage.decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        (uint256 toWithdraw, ) = lydMasterChef.userInfo(lydPid, address(this));
        if (toWithdraw > 0) {
            lydMasterChef.withdraw(lydPid, toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        uint256 rewardsToTransfer = rewardToken.balanceOf(address(this));
        if (rewardsToTransfer > 0) {
            rewardToken.safeTransfer(newStrategy, rewardsToTransfer);
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        lydMasterChef.deposit(lydPid, toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(lydMasterChef), 0);
        depositToken.safeApprove(address(lydMasterChef), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        uint256 totalShares = iglooMaster.totalShares(pid);
        if (unclaimedRewards > 0 && totalShares > 0) {
            uint256 balanceBefore = rewardToken.balanceOf(address(this));
            lydMasterChef.deposit(lydPid, 0);
            uint256 balanceDiff = rewardToken.balanceOf(address(this)) - balanceBefore;
            iglooStrategyStorage.increaseRewardTokensPerShare((balanceDiff * ACC_PEFI_PRECISION) / totalShares);
        }
    }

    function _harvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        uint256 totalRewards = (userShares * iglooStrategyStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller);
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        iglooStrategyStorage.setRewardDebt(caller, userShares);
        if (userPendingRewards > 0) {
            totalHarvested += userPendingRewards;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                _safeRewardTokenTransfer(iglooMaster.performanceFeeAddress(), performanceFee);
                userPendingRewards = userPendingRewards - performanceFee;
            }
            harvested[to] += userPendingRewards;
            emit Harvest(caller, to, userPendingRewards);
            _safeRewardTokenTransfer(to, userPendingRewards);
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
}


contract IglooStrategyForSushiStaking is IglooStrategyBase {
    using SafeERC20 for IERC20;

    address[] public rewardTokensArray;
    uint256 public constant numberRewardTokens = 2;
        
    IglooStrategyStorageMultiReward public immutable iglooStrategyStorage;
    ISushiMiniChef public constant sushiMiniChef = ISushiMiniChef(0x0000000000000000000000000000000000000000);
    uint256 public immutable pid;
    uint256 public immutable sushiPid;
    //placeholder address for native token (AVAX)
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //total of each token harvested by the contract all time
    mapping(address => uint256) public totalHarvested;
    //total amount harvested by each user of each token 
    mapping(address => mapping(address => uint256)) public harvested;

    event Harvest(address indexed caller, address indexed to, address indexed rewardToken, uint256 harvestedAmount);

    constructor(
        uint256 _pid,
        uint256 _sushiPid,
        IglooStrategyStorageMultiReward _iglooStrategyStorage
        )
        //iglooMaster and PEFI/SUSHI.e SLP token address
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), IERC20(0x24F01f3dCdeE246567029Bce8830a866C9CD2b1e))
    {
        rewardTokensArray = new address[](numberRewardTokens);
        rewardTokensArray[0] = 0x24F01f3dCdeE246567029Bce8830a866C9CD2b1e; //SUSHI.e
        rewardTokensArray[1] = 0x0000000000000000000000000000000000000000;
        pid = _pid;
        sushiPid = _sushiPid;
        iglooStrategyStorage = _iglooStrategyStorage;
        IERC20(0x24F01f3dCdeE246567029Bce8830a866C9CD2b1e).safeApprove(address(sushiMiniChef), MAX_UINT);
    }

    //PUBLIC FUNCTIONS
    function checkReward() public view returns (uint256) {
        uint256 amountPending = sushiMiniChef.pendingSushi(sushiPid, address(this));
        return amountPending;
    }

    function checkRewarder(uint256 pendingSushi) public view returns (uint256) {
        address rewarder = sushiMiniChef.rewarder(sushiPid);
        if (rewarder != address(0)) {
            (,uint256[] memory pendingAmounts) = IRewarder(rewarder).pendingTokens(sushiPid, address(this), pendingSushi);
            return pendingAmounts[0];
        } else {
            return 0;
        }
    }

    function checkRewards() public view returns (uint256[] memory) {
        uint256[] memory pendingAmounts = new uint256[](2);
        uint256 pendingSushi = checkReward();
        pendingAmounts[0] = pendingSushi;
        pendingAmounts[1] = checkRewarder(pendingSushi);
        return pendingAmounts;
    }

    function pendingRewards(address user, uint256 rewardTokenIndex) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 totalShares = iglooMaster.totalShares(pid);
        address rewardToken = rewardTokensArray[rewardTokenIndex];
        uint256 unclaimedRewards;
        if (rewardTokenIndex == 0) {
            unclaimedRewards = checkReward();
        } else {
            unclaimedRewards = checkRewarder(checkReward());
        }
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare(rewardToken);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user, rewardToken);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        return (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _rewardTokens[i] = rewardTokensArray[i];
        }
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        uint256[] memory _pendingAmounts = new uint256[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _pendingAmounts[i] = pendingRewards(user, i);
        }
        return(rewardTokensArray, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    //simple function to receive AVAX transfers
    receive() external payable {}

    //harvest has been made onlyOwner for this igloo to avoid any possibility of reentrancy
    function harvest() external onlyOwner {
        _claimRewards();
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            sushiMiniChef.deposit(sushiPid, tokenAmount, address(this));
        }
        if (shareAmount > 0) {
            _increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            sushiMiniChef.withdraw(sushiPid, tokenAmount, address(this));
            depositToken.safeTransfer(to, tokenAmount);
        }
        if (shareAmount > 0) {
            _decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        (uint256 toWithdraw, ) = sushiMiniChef.userInfo(sushiPid, address(this));
        if (toWithdraw > 0) {
            sushiMiniChef.withdraw(sushiPid, toWithdraw, address(this));
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 rewardsToTransfer = _checkBalance(rewardToken);
            if (rewardsToTransfer > 0) {
                _safeRewardTokenTransfer(rewardToken, newStrategy, rewardsToTransfer);
            }
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        sushiMiniChef.deposit(sushiPid, toStake, address(this));
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(sushiMiniChef), 0);
        depositToken.safeApprove(address(sushiMiniChef), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256[] memory pendingAmounts = new uint256[](numberRewardTokens);
        bool updateAndClaim;
        pendingAmounts = checkRewards();
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            if (pendingAmounts[i] > 0) {
                updateAndClaim = true;
            }
        }
        if (updateAndClaim && totalShares > 0) {
            uint256[] memory balancesBefore = new uint256[](numberRewardTokens);
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                balancesBefore[i] = _checkBalance(rewardTokensArray[i]);
            }
            sushiMiniChef.harvest(sushiPid, address(this));
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                uint256 balanceDiff = _checkBalance(rewardTokensArray[i]) - balancesBefore[i];
                if (balanceDiff > 0) {
                    iglooStrategyStorage.increaseRewardTokensPerShare(rewardTokensArray[i], (balanceDiff * ACC_PEFI_PRECISION) / totalShares);
                }  
            }
        }
    }

    function _harvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 totalRewards = userShares * iglooStrategyStorage.rewardTokensPerShare(rewardToken) / ACC_PEFI_PRECISION;
            uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller, rewardToken);
            uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
            iglooStrategyStorage.setRewardDebt(caller, rewardToken, userShares);
            if (userPendingRewards > 0) {
                totalHarvested[rewardToken] += userPendingRewards;
                if (performanceFeeBips > 0) {
                    uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                    _safeRewardTokenTransfer(rewardToken, iglooMaster.performanceFeeAddress(), performanceFee);
                    userPendingRewards = userPendingRewards - performanceFee;
                }
                harvested[to][rewardToken] += userPendingRewards;
                emit Harvest(caller, to, rewardToken, userPendingRewards);
                _safeRewardTokenTransfer(rewardToken, to, userPendingRewards);
            }
        }
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address token, address user, uint256 amount) internal {
        if (token == AVAX) {
            uint256 avaxBalance = address(this).balance;
            if (amount > avaxBalance) {
                payable(user).transfer(avaxBalance);
            } else {
                payable(user).transfer(amount);
            }
        } else {
            IERC20 rewardToken = IERC20(token);
            uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
            if (amount > rewardTokenBal) {
                rewardToken.safeTransfer(user, rewardTokenBal);
            } else {
                rewardToken.safeTransfer(user, amount);
            }            
        }
    }

    function _decreaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.decreaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _increaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.increaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _setRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.setRewardDebt(user, rewardTokensArray[i], amountShares);
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

contract IglooStrategyForJoeStakingV3 is IglooStrategyBase {
    using SafeERC20 for IERC20;

    address[] public rewardTokensArray;
    uint256 public constant numberRewardTokens = 2;
    //placeholder address for native token (AVAX)
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //address of WAVAX, used by JOE to indicate usage of native AVAX
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    IglooStrategyStorageMultiReward public immutable iglooStrategyStorage;
    IJoeChef public constant joeMasterChefV3 = IJoeChef(0x188bED1968b795d5c9022F6a0bb5931Ac4c18F00);
    uint256 public immutable pid;
    uint256 public immutable joePid;
    //total of each token harvested by the contract all time
    mapping(address => uint256) public totalHarvested;
    //total amount harvested by each user of each token 
    mapping(address => mapping(address => uint256)) public harvested;

    //for igloos migrated from Joe's previous Masterchef
    IglooStrategyStorage public immutable previousIglooStorage;
    address public constant previousRewardToken = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd; //JOE token
    mapping(address => bool) public previousRewardsClaimed;

    event Harvest(address indexed caller, address indexed to, address indexed rewardToken, uint256 harvestedAmount);

    constructor(
        IERC20 _depositToken,
        uint256 _pid,
        uint256 _joePid,
        IglooStrategyStorageMultiReward _iglooStrategyStorage,
        IglooStrategyStorage _previousIglooStorage
        )
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), _depositToken)
    {
        pid = _pid;
        joePid = _joePid;
        iglooStrategyStorage = _iglooStrategyStorage;
        _depositToken.safeApprove(address(joeMasterChefV3), MAX_UINT);
        previousIglooStorage = _previousIglooStorage;
        rewardTokensArray = new address[](numberRewardTokens);
        rewardTokensArray[0] = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd; //JOE token
        rewardTokensArray[1] = AVAX; //native AVAX
    }

    //PUBLIC FUNCTIONS
    function checkReward(uint256 tokenIndex) public view returns (uint256) {
        if (tokenIndex == 0) {
            (uint256 pendingJoe, , , ) = joeMasterChefV3.pendingTokens(joePid, address(this));
            return pendingJoe;
        } else if (tokenIndex == 1) {
            (, address bonusTokenAddress, , uint256 pendingBonusToken) = joeMasterChefV3.pendingTokens(joePid, address(this));
            if (bonusTokenAddress == 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) {
                return pendingBonusToken;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function pendingRewards(address user, uint256 rewardTokenIndex) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 totalShares = iglooMaster.totalShares(pid);
        address rewardToken = rewardTokensArray[rewardTokenIndex];
        uint256 unclaimedRewards = checkReward(rewardTokenIndex);
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare(rewardToken);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user, rewardToken);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        uint256 pendingAmount = (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
        if (address(previousIglooStorage) != address(0) && !previousRewardsClaimed[user] && rewardTokenIndex == 0) {
            totalRewards = (userShares * previousIglooStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
            userRewardDebt = previousIglooStorage.rewardDebt(user);
            userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                userPendingRewards = userPendingRewards - performanceFee;
            }
            pendingAmount += userPendingRewards;
        }
        return pendingAmount;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _rewardTokens[i] = rewardTokensArray[i];
        }
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        uint256[] memory _pendingAmounts = new uint256[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _pendingAmounts[i] = pendingRewards(user, i);
        }
        return(rewardTokensArray, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    //simple function to receive AVAX transfers
    receive() external payable {}

    //harvest has been made onlyOwner for this igloo to avoid any possibility of reentrancy
    function harvest() external onlyOwner {
        _claimRewards();
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            joeMasterChefV3.deposit(joePid, tokenAmount);
        }
        if (shareAmount > 0) {
            _increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            joeMasterChefV3.withdraw(joePid, tokenAmount);
            depositToken.safeTransfer(to, tokenAmount);
        }
        if (shareAmount > 0) {
            _decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        (uint256 toWithdraw, ) = joeMasterChefV3.userInfo(joePid, address(this));
        if (toWithdraw > 0) {
            joeMasterChefV3.withdraw(joePid, toWithdraw);
            depositToken.safeTransfer(newStrategy, toWithdraw);
        }
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 rewardsToTransfer = _checkBalance(rewardToken);
            if (rewardsToTransfer > 0) {
                _safeRewardTokenTransfer(rewardToken, newStrategy, rewardsToTransfer);
            }
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        joeMasterChefV3.deposit(joePid, toStake);
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(joeMasterChefV3), 0);
        depositToken.safeApprove(address(joeMasterChefV3), MAX_UINT);
    }

    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external virtual override onlyOwner {
        require(amount > 0, "cannot recover 0 tokens");
        require(token != depositToken, "cannot recover deposit token");
        _safeRewardTokenTransfer(address(token), to, amount);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256[] memory pendingAmounts = new uint256[](numberRewardTokens);
        bool updateAndClaim;
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            pendingAmounts[i] = checkReward(i);
            if (pendingAmounts[i] > 0) {
                updateAndClaim = true;
            }
        }
        if (updateAndClaim && totalShares > 0) {
            uint256[] memory balancesBefore = new uint256[](numberRewardTokens);
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                balancesBefore[i] = _checkBalance(rewardTokensArray[i]);
            }
            joeMasterChefV3.deposit(joePid, 0);
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                uint256 balanceDiff = _checkBalance(rewardTokensArray[i]) - balancesBefore[i];
                if (balanceDiff > 0) {
                    iglooStrategyStorage.increaseRewardTokensPerShare(rewardTokensArray[i], (balanceDiff * ACC_PEFI_PRECISION) / totalShares);
                }  
            }
        }
    }

    function _harvest(address caller, address to) internal {
        //special harvest operation for one-time claiming of rewards from previous contract, used in case of migrations
        if (address(previousIglooStorage) != address(0) && !previousRewardsClaimed[caller]) {
            previousRewardsClaimed[caller] = true;
            _previousRewardsHarvest(caller, to);
        }
        //normal harvest operation
        uint256 userShares = iglooMaster.userShares(pid, caller);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 totalRewards = userShares * iglooStrategyStorage.rewardTokensPerShare(rewardToken) / ACC_PEFI_PRECISION;
            uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller, rewardToken);
            uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
            iglooStrategyStorage.setRewardDebt(caller, rewardToken, userShares);
            if (userPendingRewards > 0) {
                totalHarvested[rewardToken] += userPendingRewards;
                if (performanceFeeBips > 0) {
                    uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                    _safeRewardTokenTransfer(rewardToken, iglooMaster.performanceFeeAddress(), performanceFee);
                    userPendingRewards = userPendingRewards - performanceFee;
                }
                harvested[to][rewardToken] += userPendingRewards;
                emit Harvest(caller, to, rewardToken, userPendingRewards);
                _safeRewardTokenTransfer(rewardToken, to, userPendingRewards);
            }
        }
    }

    function _previousRewardsHarvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        uint256 totalRewards = (userShares * previousIglooStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
        uint256 userRewardDebt = previousIglooStorage.rewardDebt(caller);
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        previousIglooStorage.setRewardDebt(caller, userShares);
        if (userPendingRewards > 0) {
            totalHarvested[previousRewardToken] += userPendingRewards;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                _safeRewardTokenTransfer(previousRewardToken, iglooMaster.performanceFeeAddress(), performanceFee);
                userPendingRewards = userPendingRewards - performanceFee;
            }
            harvested[to][previousRewardToken] += userPendingRewards;
            emit Harvest(caller, to, previousRewardToken, userPendingRewards);
            _safeRewardTokenTransfer(previousRewardToken, to, userPendingRewards);
        }
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address token, address user, uint256 amount) internal {
        if (token == AVAX) {
            uint256 avaxBalance = address(this).balance;
            if (amount > avaxBalance) {
                payable(user).transfer(avaxBalance);
            } else {
                payable(user).transfer(amount);
            }
        } else {
            IERC20 rewardToken = IERC20(token);
            uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
            if (amount > rewardTokenBal) {
                rewardToken.safeTransfer(user, rewardTokenBal);
            } else {
                rewardToken.safeTransfer(user, amount);
            }            
        }
    }

    function _decreaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.decreaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _increaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.increaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _setRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.setRewardDebt(user, rewardTokensArray[i], amountShares);
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

contract IglooStrategyForPangolinMiniChefStaking is IglooStrategyBase {
    using SafeERC20 for IERC20;

    address[] public rewardTokensArray;
    uint256 public constant numberRewardTokens = 1;
    //placeholder address for native token (AVAX)
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IglooStrategyStorageMultiReward public immutable iglooStrategyStorage;
    IPangolinMiniChef public constant pangolinMiniChef = IPangolinMiniChef(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928);
    uint256 public immutable pid;
    uint256 public immutable pangolinPid;
    //total of each token harvested by the contract all time
    mapping(address => uint256) public totalHarvested;
    //total amount harvested by each user of each token 
    mapping(address => mapping(address => uint256)) public harvested;

    //for igloos migrated from Joe's previous Masterchef
    IglooStrategyStorage public immutable previousIglooStorage;
    address public constant previousRewardToken = 0x60781C2586D68229fde47564546784ab3fACA982; //PNG token
    mapping(address => bool) public previousRewardsClaimed;

    event Harvest(address indexed caller, address indexed to, address indexed rewardToken, uint256 harvestedAmount);

    constructor(
        IERC20 _depositToken,
        uint256 _pid,
        uint256 _pangolinPid,
        IglooStrategyStorageMultiReward _iglooStrategyStorage,
        IglooStrategyStorage _previousIglooStorage
        )
        IglooStrategyBase(IIglooMaster(0x256040dc7b3CECF73a759634fc68aA60EA0D68CB), _depositToken)
    {
        pid = _pid;
        pangolinPid = _pangolinPid;
        iglooStrategyStorage = _iglooStrategyStorage;
        _depositToken.safeApprove(address(pangolinMiniChef), MAX_UINT);
        previousIglooStorage = _previousIglooStorage;
        rewardTokensArray = new address[](numberRewardTokens);
        rewardTokensArray[0] = 0x60781C2586D68229fde47564546784ab3fACA982; //PNG token
    }

    //PUBLIC FUNCTIONS
    function checkReward(uint256 tokenIndex) public view returns (uint256) {
        if (tokenIndex == 0) {
            uint256 pendingPng = pangolinMiniChef.pendingReward(pangolinPid, address(this));
            return pendingPng;
        } else {
            return 0;
        }
    }

    function pendingRewards(address user, uint256 rewardTokenIndex) public view returns (uint256) {
        uint256 userShares = iglooMaster.userShares(pid, user);
        uint256 totalShares = iglooMaster.totalShares(pid);
        address rewardToken = rewardTokensArray[rewardTokenIndex];
        uint256 unclaimedRewards = checkReward(rewardTokenIndex);
        uint256 rewardTokensPerShare = iglooStrategyStorage.rewardTokensPerShare(rewardToken);
        uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(user, rewardToken);
        uint256 multiplier =  rewardTokensPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PEFI_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PEFI_PRECISION;
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        uint256 pendingAmount = (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;
        if (address(previousIglooStorage) != address(0) && !previousRewardsClaimed[user] && rewardTokenIndex == 0) {
            totalRewards = (userShares * previousIglooStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
            userRewardDebt = previousIglooStorage.rewardDebt(user);
            userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                userPendingRewards = userPendingRewards - performanceFee;
            }
            pendingAmount += userPendingRewards;
        }
        return pendingAmount;
    }

    function rewardTokens() external view virtual returns(address[] memory) {
        address[] memory _rewardTokens = new address[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _rewardTokens[i] = rewardTokensArray[i];
        }
        return(_rewardTokens);
    }

    function pendingTokens(uint256, address user, uint256) external view override
        returns (address[] memory, uint256[] memory) {
        uint256[] memory _pendingAmounts = new uint256[](numberRewardTokens);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            _pendingAmounts[i] = pendingRewards(user, i);
        }
        return(rewardTokensArray, _pendingAmounts);
    }

    //EXTERNAL FUNCTIONS
    //simple function to receive AVAX transfers
    receive() external payable {}

    //OWNER-ONlY FUNCTIONS
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            pangolinMiniChef.deposit(pangolinPid, tokenAmount, address(this));
        }
        if (shareAmount > 0) {
            _increaseRewardDebt(to, shareAmount);
        }
    }

    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external override onlyOwner {
        _claimRewards();
        _harvest(caller, to);
        if (tokenAmount > 0) {
            pangolinMiniChef.withdraw(pangolinPid, tokenAmount, to);
        }
        if (shareAmount > 0) {
            _decreaseRewardDebt(to, shareAmount);
        }
    }

    function migrate(address newStrategy) external override onlyOwner {
        _claimRewards();
        (uint256 toWithdraw, ) = pangolinMiniChef.userInfo(pangolinPid, address(this));
        if (toWithdraw > 0) {
            pangolinMiniChef.withdraw(pangolinPid, toWithdraw, newStrategy);
        }
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 rewardsToTransfer = _checkBalance(rewardToken);
            if (rewardsToTransfer > 0) {
                _safeRewardTokenTransfer(rewardToken, newStrategy, rewardsToTransfer);
            }
        }
        iglooStrategyStorage.transferOwnership(newStrategy);
    }

    function onMigration() external override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        pangolinMiniChef.deposit(pangolinPid, toStake, address(this));
    }

    function setAllowances() external override onlyOwner {
        depositToken.safeApprove(address(pangolinMiniChef), 0);
        depositToken.safeApprove(address(pangolinMiniChef), MAX_UINT);
    }

    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external virtual override onlyOwner {
        require(amount > 0, "cannot recover 0 tokens");
        require(token != depositToken, "cannot recover deposit token");
        _safeRewardTokenTransfer(address(token), to, amount);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 totalShares = iglooMaster.totalShares(pid);
        uint256[] memory pendingAmounts = new uint256[](numberRewardTokens);
        bool updateAndClaim;
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            pendingAmounts[i] = checkReward(i);
            if (pendingAmounts[i] > 0) {
                updateAndClaim = true;
            }
        }
        if (updateAndClaim && totalShares > 0) {
            uint256[] memory balancesBefore = new uint256[](numberRewardTokens);
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                balancesBefore[i] = _checkBalance(rewardTokensArray[i]);
            }
            pangolinMiniChef.harvest(pangolinPid, address(this));
            for (uint256 i = 0; i < numberRewardTokens; i++) {
                uint256 balanceDiff = _checkBalance(rewardTokensArray[i]) - balancesBefore[i];
                if (balanceDiff > 0) {
                    iglooStrategyStorage.increaseRewardTokensPerShare(rewardTokensArray[i], (balanceDiff * ACC_PEFI_PRECISION) / totalShares);
                }  
            }
        }
    }

    function _harvest(address caller, address to) internal {
        //special harvest operation for one-time claiming of rewards from previous contract, used in case of migrations
        if (address(previousIglooStorage) != address(0) && !previousRewardsClaimed[caller]) {
            previousRewardsClaimed[caller] = true;
            _previousRewardsHarvest(caller, to);
        }
        //normal harvest operation
        uint256 userShares = iglooMaster.userShares(pid, caller);
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            address rewardToken = rewardTokensArray[i];
            uint256 totalRewards = userShares * iglooStrategyStorage.rewardTokensPerShare(rewardToken) / ACC_PEFI_PRECISION;
            uint256 userRewardDebt = iglooStrategyStorage.rewardDebt(caller, rewardToken);
            uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
            iglooStrategyStorage.setRewardDebt(caller, rewardToken, userShares);
            if (userPendingRewards > 0) {
                totalHarvested[rewardToken] += userPendingRewards;
                if (performanceFeeBips > 0) {
                    uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                    _safeRewardTokenTransfer(rewardToken, iglooMaster.performanceFeeAddress(), performanceFee);
                    userPendingRewards = userPendingRewards - performanceFee;
                }
                harvested[to][rewardToken] += userPendingRewards;
                emit Harvest(caller, to, rewardToken, userPendingRewards);
                _safeRewardTokenTransfer(rewardToken, to, userPendingRewards);
            }
        }
    }

    function _previousRewardsHarvest(address caller, address to) internal {
        uint256 userShares = iglooMaster.userShares(pid, caller);
        uint256 totalRewards = (userShares * previousIglooStorage.rewardTokensPerShare()) / ACC_PEFI_PRECISION;
        uint256 userRewardDebt = previousIglooStorage.rewardDebt(caller);
        uint256 userPendingRewards = (totalRewards >= userRewardDebt) ?  (totalRewards - userRewardDebt) : 0;
        previousIglooStorage.setRewardDebt(caller, userShares);
        if (userPendingRewards > 0) {
            totalHarvested[previousRewardToken] += userPendingRewards;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                _safeRewardTokenTransfer(previousRewardToken, iglooMaster.performanceFeeAddress(), performanceFee);
                userPendingRewards = userPendingRewards - performanceFee;
            }
            harvested[to][previousRewardToken] += userPendingRewards;
            emit Harvest(caller, to, previousRewardToken, userPendingRewards);
            _safeRewardTokenTransfer(previousRewardToken, to, userPendingRewards);
        }
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address token, address user, uint256 amount) internal {
        if (token == AVAX) {
            uint256 avaxBalance = address(this).balance;
            if (amount > avaxBalance) {
                payable(user).transfer(avaxBalance);
            } else {
                payable(user).transfer(amount);
            }
        } else {
            IERC20 rewardToken = IERC20(token);
            uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
            if (amount > rewardTokenBal) {
                rewardToken.safeTransfer(user, rewardTokenBal);
            } else {
                rewardToken.safeTransfer(user, amount);
            }            
        }
    }

    function _decreaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.decreaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _increaseRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.increaseRewardDebt(user, rewardTokensArray[i], amountShares);
        }
    }

    function _setRewardDebt(address user, uint256 amountShares) internal {
        for (uint256 i = 0; i < numberRewardTokens; i++) {
            iglooStrategyStorage.setRewardDebt(user, rewardTokensArray[i], amountShares);
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