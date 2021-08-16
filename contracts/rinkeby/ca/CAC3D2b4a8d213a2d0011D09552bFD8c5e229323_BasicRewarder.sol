/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// Part: Address

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

// Part: IJellyAccessControls

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);

}

// Part: IJellyRewards

interface IJellyRewards {

    function setPoolContract(address _addr, uint256 _pool) external;
    function setRewards( 
        uint256[] memory rewardPeriods, 
        uint256[] memory amounts
    ) external;
    function setBonus(
        address pool,
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    ) external;
    function updateRewards() external returns(bool);
    function totalRewards() external view returns (uint256 rewards);
    function poolRewards(address _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
}

// Part: ITokenPool

interface ITokenPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function getStakedBalance(address _user) external view returns (uint256 balance);
    function stakedEthTotal() external  view returns (uint256);
    function stakedTokenTotal() external  view returns (uint256);

    function rewardsOwing(address _user) external view returns (uint256 rewards);


    function stake(uint256 _amount) external;
    function unstake(uint256 _amount) external;
    function claimRewards(address _user) external;
    function emergencyUnstake() external;
    function updateReward(address _user) external;

    /**
     * @notice Event emmited when a user has staked LPs.
     * @param owner Address of the staker.
     * @param amount Amount staked in LP tokens.
     */
    event Staked(address indexed owner, uint256 amount);

    /**
     * @notice Event emitted when a user has unstaked LPs.
     * @param owner Address of the unstaker.
     * @param amount Amount unstaked in LP tokens.
     */
    event Unstaked(address indexed owner, uint256 amount);

}

// Part: OZIERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZIERC20 {
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

// Part: SafeERC20

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
        OZIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        OZIERC20 token,
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
        OZIERC20 token,
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
        OZIERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        OZIERC20 token,
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
    function _callOptionalReturn(OZIERC20 token, bytes memory data) private {
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

// File: BasicRewarder.sol

contract BasicRewarder is IJellyRewards {

    using SafeERC20 for OZIERC20;

    address public rewardsToken;
    IJellyAccessControls public accessControls;

    // GP: this needs to be change to a mapping or arry for tokenID
    // Havent decided yet, important for adding new pools
    // GP and a way to keep track of the pool IDs and their tokens
    ITokenPool public tokenPool;
    address public vault;

    uint256 constant POINT_MULTIPLIER = 1e18;

    // GP: TODO  this needs to be set in the constructor
    uint256 constant PERIOD_LENGTH = 14;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_PERIOD = PERIOD_LENGTH * SECONDS_PER_DAY;

    // period number => rewards
    mapping (uint256 => uint256) public periodRewardsPerSecond;
    mapping (address => mapping(uint256 => uint256)) public periodBonusPerSecond;

    uint256 public startTime;
    uint256 public lastRewardTime;
    uint256 public poolCount;
    mapping (uint256 => uint256) public tokenRewardsPaid;

    /// @notice mapping of staking to pool address and its weight
    mapping (uint256 =>  mapping(address => uint256)) public periodWeightPoints;


    event Recovered(address indexed token, uint256 amount);

    /* ========== Admin Functions ========== */
    constructor(
        address _rewardsToken,
        address _accessControls,
        address _tokenPool,
        uint256 _startTime,
        uint256 _lastRewardTime
    )
        public
    {
        rewardsToken = _rewardsToken;
        accessControls = IJellyAccessControls(_accessControls);
        tokenPool = ITokenPool(_tokenPool);
        startTime = _startTime;
        lastRewardTime = _lastRewardTime;
    }


    /// @dev Setter functions for contract config
    function setStartTime(
        uint256 _startTime,
        uint256 _lastRewardTime
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setStartTime: Sender must be admin"
        );
        startTime = _startTime;
        lastRewardTime = _lastRewardTime;
    }

    // GP: TODO This needs to set the staking address, needs to be redone, think about when we have multiple pools
    // GP: poolID can be determinitsic or in the pool contract like templateID in Miso
    function setPoolContract(address _addr, uint256 _poolId) external override {

    }


    function setVault(
        address _addr
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setVault: Sender must be admin"
        );

        vault = _addr;
    }

    // GP: TODO This needs to set the staking address, needs to be redone, think about when we have multiple pools
    function setRewardsPaid(address _pool, uint256 _amount) external  {

    }


    /// @notice Set rewards distributed each week
    /// @dev this number is the total rewards that week with 18 decimals
    function setRewards(
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    )
        external
        override
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.setRewards: Sender must be admin"
        );
        uint256 numRewards = rewardPeriods.length;
        for (uint256 i = 0; i < numRewards; i++) {
            uint256 week = rewardPeriods[i];
            uint256 amount = amounts[i] * POINT_MULTIPLIER
                                        / SECONDS_PER_PERIOD
                                        / POINT_MULTIPLIER;
            periodRewardsPerSecond[week] = amount;
        }
    }

    // GP: TODO This needs to add to the bonus mapping
    function setBonus(
        address pool,
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    ) external override {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.setBonus: Sender must be admin"
        );
        uint256 numRewards = rewardPeriods.length;
        for (uint256 i = 0; i < numRewards; i++) {
            uint256 week = rewardPeriods[i];
            uint256 amount = amounts[i] * POINT_MULTIPLIER
                                        / SECONDS_PER_PERIOD
                                        / POINT_MULTIPLIER;
            periodBonusPerSecond[pool][week] = amount;
        }
    }

    /// @notice Calculate the current normalised weightings and update rewards
    /// @dev 
    function updateRewards() 
        external
        override
        returns(bool)
    {
        if (block.timestamp <= lastRewardTime) {
            return false;
        }

        // GP: TODO Loop through all the pools
        uint256 m_net = tokenPool.stakedTokenTotal();

        // GP: TODO add them all up, maybe in loop above

        uint256 net_total = m_net;
        /// @dev check that the staking pools have contributions, and rewards have started
        if (net_total == 0 || block.timestamp <= startTime) {
            lastRewardTime = block.timestamp;
            return false;
        }

        /// @dev update weighs between pools
        _updateWeights();
    
        // GP: TODO this is not right for multiple pools
        // GP: This should loop through all the pool IDs
        for (uint256 i = 0; i < poolCount; i++) {
            _updateTokenRewards(i);
        }

        /// @dev update accumulated reward
        lastRewardTime = block.timestamp;
        return true;
    }


    /// @notice Gets the total rewards outstanding from last reward time
    function totalRewards() external override view returns (uint256) {
        uint256 tokenRewardsCount = 0 ;

        /// @dev add multiples of the week
        for (uint256 i = 0; i < poolCount; i++) {
            tokenRewardsCount += tokenRewards(i, lastRewardTime, block.timestamp);
        }

        return tokenRewardsCount;     
    }


    /// @notice Return genesis rewards over the given _from to _to timestamp.
    /// @dev A fraction of the start, multiples of the middle weeks, fraction of the end

    /// GP: Add pool ID to query
    function tokenRewards(uint256 _pool, uint256 _from, uint256 _to) public view returns (uint256 rewards) {
        if (_to <= startTime) {
            return 0;
        }
        if (_from < startTime) {
            _from = startTime;
        }
        uint256 fromWeek = diffDays(startTime, _from) / 7;
        uint256 toWeek = diffDays(startTime, _to) / 7;

       if (fromWeek == toWeek) {
            return _rewardsFromPoints(periodRewardsPerSecond[fromWeek],
                                    _to - _from,
                                    periodWeightPoints[fromWeek][address(tokenPool)]) + periodBonusPerSecond[address(tokenPool)][fromWeek] * (_to - _from);
        }
        /// @dev First count remainer of first week 
        uint256 initialRemander = startTime + (fromWeek+1) * (SECONDS_PER_PERIOD) - _from;
        rewards = _rewardsFromPoints(periodRewardsPerSecond[fromWeek],
                                    initialRemander,
                                    periodWeightPoints[fromWeek][address(tokenPool)])
                        + periodBonusPerSecond[address(tokenPool)][fromWeek] * initialRemander;

        /// @dev add multiples of the week
        for (uint256 i = fromWeek+1; i < toWeek; i++) {
            rewards = rewards + _rewardsFromPoints(periodRewardsPerSecond[i],
                                    SECONDS_PER_PERIOD,
                                    periodWeightPoints[i][address(tokenPool)]) + periodBonusPerSecond[address(tokenPool)][i] * SECONDS_PER_PERIOD;
        }
        /// @dev Adds any remaining time in the most recent week till _to
        uint256 finalRemander = _to - (toWeek * SECONDS_PER_PERIOD + startTime);
        rewards = rewards + (_rewardsFromPoints(periodRewardsPerSecond[toWeek],
                                    finalRemander,
                                    periodWeightPoints[toWeek][address(tokenPool)])
                          + (periodBonusPerSecond[address(tokenPool)][toWeek]) * finalRemander);
        return rewards;
    }

    function _updateTokenRewards(
        uint256 poolId
    ) 
        internal
        returns(uint256 rewards)
    {
        rewards = tokenRewards(poolId, lastRewardTime, block.timestamp);
        if ( rewards > 0 ) {
            tokenRewardsPaid[poolId] += rewards;
            OZIERC20(rewardsToken).safeTransferFrom(
                vault, 
                address(tokenPool), 
                rewards
            );
        }
    }

    function _updateWeights(
    ) 
        internal
    {
        // GP: This is blank for basic pools
    }


    function _rewardsFromPoints(
        uint256 rate,
        uint256 duration, 
        uint256 weight
    ) 
        internal
        pure
        returns(uint256)
    {
        return rate * duration
             * weight
             / 1e18
             / POINT_MULTIPLIER;
    }


    // From BokkyPooBah's DateTime Library v1.01
    // https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function poolRewards(address _pool, uint256 _from, uint256 _to) external override view returns (uint256 rewards) {}



    /// @notice allows for the recovery of incorrect ERC20 tokens sent to contract
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        // Cannot recover the staking token or the rewards token
        require(
            accessControls.hasAdminRole(msg.sender),
            "BasicRewarder.recoverERC20: Sender must be admin"
        );
        require(
            tokenAddress != address(rewardsToken),
            "Cannot withdraw the rewards token"
        );
        OZIERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }


}