/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

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


// File contracts/utils/Context.sol

pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/utils/Ownable.sol

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
}


// File contracts/utils/Address.sol

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File contracts/ERC20/SafeERC20.sol

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/SteakHouseV2.sol

pragma solidity ^0.8.0;



// SteakHouseV2 provides multi-token rewards for the farms of Stake Steak
// This contract is forked from Popsicle.finance which is a fork of SushiSwap's MasterChef Contract
// It intakes one token and allows the user to farm another token. Due to the crosschain nature of Stake Steak we've swapped reward per block
// to reward per second. Moreover, we've implemented safe transfer of reward instead of mint in Masterchef.
// Future is crosschain...

// The contract is ownable untill the DAO will be able to take over.
contract SteakHouseV2 is Ownable {
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256[] RewardDebt; // Reward debt. See explanation below.
        uint256[] RemainingRewards; // Reward Tokens that weren't distributed for user per pool.
        //
        // We do some fancy math here. Basically, any point in time, the amount of STEAK
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.AccRewardsPerShare[i]) - user.RewardDebt[i]
        //
        // Whenever a user deposits or withdraws Staked tokens to a pool. Here's what happens:
        //   1. The pool's `AccRewardsPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken; // Contract address of staked token
        uint256 stakingTokenTotalAmount; //Total amount of deposited tokens
        uint32 lastRewardTime; // Last timestamp number that Rewards distribution occurs.
        uint256[] AccRewardsPerShare; // Accumulated reward tokens per share, times 1e12. See below.
        uint256[] AllocPoints; // How many allocation points assigned to this pool. STEAK to distribute per second.
    }

    uint256 public depositFee = 5000; // Withdraw Fee

    uint256 public harvestFee = 100000; //Fee for claiming rewards

    address public harvestFeeReceiver; //harvestFeeReceiver is originally owner of the contract

    address public depositFeeReceiver; //depositFeeReceiver is originally owner of the contract

    IERC20[] public RewardTokens = new IERC20[](5);

    uint256[] public RewardsPerSecond = new uint256[](5);

    uint256[] public totalAllocPoints = new uint256[](5); // Total allocation points. Must be the sum of all allocation points in all pools.

    uint32 public immutable startTime; // The timestamp when Rewards farming starts.

    uint32 public endTime; // Time on which the reward calculation should end

    PoolInfo[] private poolInfo; // Info of each pool.

    mapping(uint256 => mapping(address => UserInfo)) private userInfo; // Info of each user that stakes tokens.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event FeeCollected(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20[] memory _RewardTokens,
        uint256[] memory _RewardsPerSecond,
        uint32 _startTime
    ) {
        require(_RewardTokens.length == 5 && _RewardsPerSecond.length == 5);
        RewardTokens = _RewardTokens;

        RewardsPerSecond = _RewardsPerSecond;
        startTime = _startTime;
        endTime = _startTime + 30 days;
        depositFeeReceiver = owner();
        harvestFeeReceiver = owner();
    }

    function changeEndTime(uint32 addSeconds) external onlyOwner {
        endTime += addSeconds;
    }

    // Owner can retreive excess/unclaimed STEAK 7 days after endtime
    // Owner can NOT withdraw any token other than STEAK
    function collect(uint256 _amount) external onlyOwner {
        require(block.timestamp >= endTime + 7 days, "too early to collect");
        for (uint16 i = 0; i <= RewardTokens.length; i++) {
            uint256 balance = RewardTokens[i].balanceOf(address(this));
            require(_amount <= balance, "withdrawing too much");
            RewardTokens[i].safeTransfer(owner(), _amount);
        }
    }

    // Changes Steak token reward per second. Use this function to moderate the `lockup amount`. Essentially this function changes the amount of the reward
    // which is entitled to the user for his token staking by the time the `endTime` is passed.
    //Good practice to update pools without messing up the contract
    function setRewardsPerSecond(
        uint256 _rewardsPerSecond,
        uint16 _rid,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        RewardsPerSecond[_rid] = _rewardsPerSecond;
    }

    // How many pools are in the contract
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 _pid) public view returns (PoolInfo memory) {
        return poolInfo[_pid];
    }

    function getUserInfo(uint256 _pid, address _user)
        public
        view
        returns (UserInfo memory)
    {
        return userInfo[_pid][_user];
    }

    // Add a new staking token to the pool. Can only be called by the owner.
    // VERY IMPORTANT NOTICE
    // ----------- DO NOT add the same staking token more than once. Rewards will be messed up if you do. -------------
    // Good practice to update pools without messing up the contract
    function add(
        uint256[] calldata _AllocPoints,
        IERC20 _stakingToken,
        bool _withUpdate
    ) external onlyOwner {
        require(_AllocPoints.length == 5);
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime =
            block.timestamp > startTime ? block.timestamp : startTime;
        for (uint256 i = 0; i < totalAllocPoints.length; i++) {
            totalAllocPoints[i] += _AllocPoints[i];
        }
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                stakingTokenTotalAmount: 0,
                lastRewardTime: uint32(lastRewardTime),
                AccRewardsPerShare: new uint256[](5),
                AllocPoints: _AllocPoints
            })
        );
    }

    // Update the given pool's allocation point per reward token. Can only be called by the owner.
    // Good practice to update pools without messing up the contract
    function set(
        uint256 _pid,
        uint256[] calldata _AllocPoints,
        bool _withUpdate
    ) external onlyOwner {
        require(_AllocPoints.length == 5);
        if (_withUpdate) {
            massUpdatePools();
        }
        for (uint16 i = 0; i < totalAllocPoints.length; i++) {
            totalAllocPoints[i] =
                totalAllocPoints[i] -
                poolInfo[_pid].AllocPoints[i] +
                _AllocPoints[i];
            poolInfo[_pid].AllocPoints[i] = _AllocPoints[i];
        }
    }

    function setDepositFee(uint256 _depositFee) external onlyOwner {
        require(_depositFee <= 50000);
        depositFee = _depositFee;
    }

    function setHarvestFee(uint256 _harvestFee) external onlyOwner {
        require(_harvestFee <= 500000);
        harvestFee = _harvestFee;
    }

    function setRewardTokens(IERC20[] calldata _RewardTokens)
        external
        onlyOwner
    {
        require(_RewardTokens.length == 5);
        RewardTokens = _RewardTokens;
    }

    function setHarvestFeeReceiver(address _harvestFeeReceiver)
        external
        onlyOwner
    {
        harvestFeeReceiver = _harvestFeeReceiver;
    }

    function setDepositFeeReceiver(address _depositFeeReceiver)
        external
        onlyOwner
    {
        depositFeeReceiver = _depositFeeReceiver;
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        _from = _from > startTime ? _from : startTime;
        if (_from > endTime || _to < startTime) {
            return 0;
        }
        if (_to > endTime) {
            return endTime - _from;
        }
        return _to - _from;
    }

    // View function to see pending rewards on frontend.
    function pendingRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256[] memory)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256[] memory AccRewardsPerShare = pool.AccRewardsPerShare;
        uint256[] memory PendingRewardTokens = new uint256[](5);

        if (
            block.timestamp > pool.lastRewardTime &&
            pool.stakingTokenTotalAmount != 0
        ) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardTime, block.timestamp);
            for (uint256 i = 0; i < RewardTokens.length; i++) {
                if (totalAllocPoints[i] != 0) {
                    uint256 reward =
                        (multiplier *
                            RewardsPerSecond[i] *
                            pool.AllocPoints[i]) / totalAllocPoints[i];
                    AccRewardsPerShare[i] +=
                        (reward * 1e12) /
                        pool.stakingTokenTotalAmount;
                }
            }
        }

        for (uint256 i = 0; i < RewardTokens.length; i++) {
            PendingRewardTokens[i] =
                (user.amount * AccRewardsPerShare[i]) /
                1e12 -
                user.RewardDebt[i] +
                user.RemainingRewards[i];
        }
        return PendingRewardTokens;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.stakingTokenTotalAmount == 0) {
            pool.lastRewardTime = uint32(block.timestamp);
            return;
        }
        uint256 multiplier =
            getMultiplier(pool.lastRewardTime, block.timestamp);
        for (uint256 i = 0; i < RewardTokens.length; i++) {
            if (totalAllocPoints[i] != 0) {
                uint256 reward =
                    (multiplier * RewardsPerSecond[i] * pool.AllocPoints[i]) /
                        totalAllocPoints[i];
                pool.AccRewardsPerShare[i] +=
                    (reward * 1e12) /
                    pool.stakingTokenTotalAmount;
                pool.lastRewardTime = uint32(block.timestamp);
            }
        }
    }

    // Deposit staking tokens to SteakHouse for rewards allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.RewardDebt.length == 0 && user.RemainingRewards.length == 0) {
            user.RewardDebt = new uint256[](5);
            user.RemainingRewards = new uint256[](5);
        }
        updatePool(_pid);
        if (user.amount > 0) {
            for (uint256 i = 0; i < RewardTokens.length; i++) {
                uint256 pending =
                    (user.amount * pool.AccRewardsPerShare[i]) /
                        1e12 -
                        user.RewardDebt[i] +
                        user.RemainingRewards[i];
                user.RemainingRewards[i] = safeRewardTransfer(
                    msg.sender,
                    pending,
                    i
                );
            }
        }
        uint256 pendingDepositFee;
        pendingDepositFee = (_amount * depositFee) / 1000000;
        pool.stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.stakingToken.safeTransfer(depositFeeReceiver, pendingDepositFee);
        uint256 amountToStake = _amount - pendingDepositFee;
        user.amount += amountToStake;
        pool.stakingTokenTotalAmount += amountToStake;
        user.RewardDebt = new uint256[](RewardTokens.length);
        for (uint256 i = 0; i < RewardTokens.length; i++) {
            user.RewardDebt[i] =
                (user.amount * pool.AccRewardsPerShare[i]) /
                1e12;
        }
        emit Deposit(msg.sender, _pid, amountToStake);
        emit FeeCollected(msg.sender, _pid, pendingDepositFee);
    }

    // Withdraw staked tokens from SteakHouse.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            "SteakHouse: amount to withdraw is greater than amount available"
        );
        updatePool(_pid);
        for (uint256 i = 0; i < RewardTokens.length; i++) {
            uint256 pending =
                (user.amount * pool.AccRewardsPerShare[i]) /
                    1e12 -
                    user.RewardDebt[i] +
                    user.RemainingRewards[i];
            user.RemainingRewards[i] = safeRewardTransfer(
                msg.sender,
                pending,
                i
            );
        }
        user.amount -= _amount;
        pool.stakingTokenTotalAmount -= _amount;
        for (uint256 i = 0; i < RewardTokens.length; i++) {
            user.RewardDebt[i] =
                (user.amount * pool.AccRewardsPerShare[i]) /
                1e12;
        }
        pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 userAmount = user.amount;
        user.amount = 0;
        user.RewardDebt = new uint256[](0);
        user.RemainingRewards = new uint256[](0);
        pool.stakingToken.safeTransfer(address(msg.sender), userAmount);
        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    // Safe reward token transfer function. Just in case if the pool does not have enough reward tokens,
    // The function returns the amount which is owed to the user
    function safeRewardTransfer(
        address _to,
        uint256 _amount,
        uint256 _rid
    ) internal returns (uint256) {
        uint256 rewardTokenBalance =
            RewardTokens[_rid].balanceOf(address(this));
        uint256 pendingHarvestFee = (_amount * harvestFee) / 1000000; //! 20% fee for harvesting rewards sent back token holders
        if (rewardTokenBalance == 0) {
            //save some gas fee
            return _amount;
        }
        if (_amount > rewardTokenBalance) {
            //save some gas fee
            pendingHarvestFee = (rewardTokenBalance * harvestFee) / 1000000;
            RewardTokens[_rid].safeTransfer(
                harvestFeeReceiver,
                pendingHarvestFee
            );
            RewardTokens[_rid].safeTransfer(
                _to,
                rewardTokenBalance - pendingHarvestFee
            );
            return _amount - rewardTokenBalance;
        }
        RewardTokens[_rid].safeTransfer(harvestFeeReceiver, pendingHarvestFee);
        RewardTokens[_rid].safeTransfer(_to, _amount - pendingHarvestFee);
        return 0;
    }
}