/**
 *Submitted for verification at Etherscan.io on 2021-09-28
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

// Part: BoringMath

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= type(uint16).max, "BoringMath: uint16 Overflow");
        c = uint16(a);
    }

}

// Part: BoringMath128

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// Part: BoringMath64

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// Part: Counters

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Part: IJellyAccessControls

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);

}

// Part: IJellyRewards

interface IJellyRewards {

    function setPoolContract(address _addr) external;
    // function setRewards( 
    //     uint256[] memory rewardPeriods, 
    //     uint256[] memory amounts
    // ) external;
    // function setBonus(
    //     uint256 poolId,
    //     uint256[] memory rewardPeriods,
    //     uint256[] memory amounts
    // ) external;
    function updateRewards() external returns(bool);
    function updateRewards(address _pool) external returns(bool);

    function totalRewards(address _poolAddress) external view returns (uint256 rewards);
    function totalRewards() external view returns (address[] memory, uint256[] memory);
    // function poolRewards(uint256 _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
    function poolRewards(address _pool, address _rewardToken, uint256 _from, uint256 _to) external view returns (uint256 rewards);

    function rewardTokens() external view returns (address[] memory rewards);
    function rewardTokens(address _pool) external view returns (address[] memory rewards);

}

// Part: ITokenPool

interface ITokenPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function getStakedBalance(address _user) external view returns (uint256 balance);
    function stakedEthTotal() external  view returns (uint256);
    function stakedTokenTotal() external  view returns (uint256);

    function rewardsOwing(address _user, address _rewardToken) external view returns (uint256 rewards);


    function poolTemplate() external view returns (uint256 poolTemplate);

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

// File: DoubleRewarder.sol

contract DoubleRewarder is IJellyRewards {

    using SafeERC20 for OZIERC20;
    // using SafeMath for uint256;
    using Counters for uint256;
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;

    IJellyAccessControls public accessControls;

    address public vault;

    uint256 constant POINT_MULTIPLIER = 1e18;

    // GP: TODO  this needs to be set in the constructor
    uint256 constant PERIOD_LENGTH = 14;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_PERIOD = PERIOD_LENGTH * SECONDS_PER_DAY;

    // period number => rewards
    // GP: Can be renamed just rewardspersecond for basic rewarder
    // uint256 public rewardsPerSecond;

    /// @notice Main market variables.
    /// GP: TODO check pool count and if it is used
    struct Rewards {
        uint64 startTime;
        uint64 endTime;
        // this can be dropped to 32
        uint64 rewardPoints;
        // only 18 rewards per second, will need to be increased to 98
        uint64 rewardsPerSecond;
    }
    mapping(address => Rewards) public rewardData;
    address[] public rewardTokenArray;

    // GP: this needs to be change to a mapping or arry for tokenID
    // Havent decided yet, important for adding new pools
    // GP and a way to keep track of the pool IDs and their tokens

    /// @notice Main market variables.
    /// GP: TODO check pool count and if it is used
    struct Pools {
        uint64 lastRewardTime;
        uint64 poolPoints;
    }
    mapping(address => Pools) public poolData;

    mapping(address => address[]) public poolRewardTokens;

    address[] public tokenPools;

    mapping(address => uint256) public tokenPoolToId;

    // /// @notice mapping of pool address and rewards paid
    mapping (address => mapping (address => uint256)) public poolRewardsPaid;

    event Recovered(address indexed token, uint256 amount);
    event TokenPoolAdded(address indexed tokenPoold);
    event SetPoolPoints(address poolAddress, uint256 poolPoints);


    /* ========== Admin Functions ========== */
    constructor(
        address _accessControls
    ) {
        accessControls = IJellyAccessControls(_accessControls);
    }


    function setPoolContract(address _tokenPool) external override {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.addPoolTemplate: Sender must be admin"   
        );
        require(tokenPoolToId[_tokenPool] == 0, "JellyRewards.addPoolTemplate: Template already Exists");
        tokenPools.push(_tokenPool);
        tokenPoolToId[_tokenPool] = ITokenPool(_tokenPool).poolTemplate();
        emit TokenPoolAdded(_tokenPool); 
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


    /// @notice Update the given pools allocation points 
    /// @param _poolAddress The address of the pool. See `poolData`.
    /// @param _poolPoints New AP of the pool.
    function setPoolPoints(address _poolAddress, uint256 _poolPoints) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.setRewards: Sender must be admin"
        );

        Pools storage _pool = poolData[_poolAddress];
        for (uint256 i = 0; i < poolRewardTokens[_poolAddress].length; i++) {
            address rewardAddress = poolRewardTokens[_poolAddress][i];
            rewardData[rewardAddress].rewardPoints = rewardData[rewardAddress].rewardPoints - _pool.poolPoints + BoringMath.to64(_poolPoints);
        }        

        /// GP: virtual check to avoid overflow
        _pool.poolPoints =  BoringMath.to64(_poolPoints);
        emit SetPoolPoints(_poolAddress, _poolPoints);
    }

    function addRewardsToPool(
        address _poolAddress,
        address _rewardAddress,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount

    ) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "addRewardsToPool: Sender must be admin"
        );
        require(
            _startTime != 0,
            "addRewardsToPool: Start time cannot be 0"
        );
        require(
            _duration != 0,
            "addRewardsToPool: Duration cannot be 0"
        );
        Pools memory _pool = poolData[_poolAddress];
        Rewards storage _reward = rewardData[_rewardAddress];

        for (uint256 i = 0; i < poolRewardTokens[_poolAddress].length; i++) {
            require(poolRewardTokens[_poolAddress][i] != _rewardAddress, "Reward address already added to pool");
        }
        poolRewardTokens[_poolAddress].push(_rewardAddress);

        // /// GP: Need to think about the pool points if already exists

        _reward.rewardPoints = _reward.rewardPoints + _pool.poolPoints;

        uint64 rewardRate = BoringMath.to64(_amount / _duration);

        // /// GP: Need to think about the starting and stopping of rewards for different tokens at different times.
        // if (block.timestamp >= periodFinish) {
        //     uint128 rewardRate = BoringMath.to128(_amount / _duration);
        // } else {
        //     uint _remaining = periodFinish - block.timestamp;
        //     uint _leftover = _remaining * rewardRate;
        //     rewardRate = (amount + _leftover) / DURATION;
        // }
        _reward.startTime = BoringMath.to64(_startTime);
        _reward.endTime = BoringMath.to64(_startTime + _duration);
        _reward.rewardsPerSecond = rewardRate;

        bool newReward = true;
        for (uint256 i = 0; i < poolRewardTokens[_poolAddress].length; i++) {
            if (poolRewardTokens[_poolAddress][i] == _rewardAddress) {         
                newReward == false;
            }
        }
        if (newReward) {
            rewardTokenArray.push(_rewardAddress);
        }

    }

    function rewardTokens() external override view returns (address[] memory) {
        return rewardTokenArray;
    }

    function rewardTokens(address _poolAddress) external override view returns (address[] memory) {
        return poolRewardTokens[_poolAddress];
    }

    /// @notice Calculate the current normalised weightings and update rewards
    /// @dev 
    function updateRewards(
    ) 
        external
        override
        returns(bool)
    {
        for (uint256 i = 0; i < tokenPools.length; i++) {
            updateRewards(tokenPools[i]);
        }
        return true;
    }


    /// @notice Calculate the current normalised weightings and update rewards
    /// @dev 
    function updateRewards(
        address _poolAddress
    ) 
        public
        override
        returns(bool)
    {
        Pools storage _pool = poolData[_poolAddress];

        if (block.timestamp <= uint256(_pool.lastRewardTime)) {
            return false;
        }

        uint256 m_net = ITokenPool(_poolAddress).stakedTokenTotal();

        /// @dev check that the staking pools have contributions, and rewards have started
        /// GP: This has the effect of reducing/delaying rewards if nothing is staked.
        if (m_net == 0) {
            _pool.lastRewardTime = BoringMath.to64(block.timestamp);
            return false;
        } else {
            uint256 rewards;
            bool exists;

            /// @dev add multiples of the week
            for (uint256 i = 0; i < poolRewardTokens[_poolAddress].length; i++) {
                /// GP: pool rewards already loops, can be refactored
                rewards = poolRewards(_poolAddress, poolRewardTokens[_poolAddress][i], uint256(_pool.lastRewardTime), block.timestamp);

                if ( rewards > 0 ) {
                    // poolRewardsPaid[_poolAddress][poolRewardTokens[_poolAddress][i]] += rewards;
                    OZIERC20(poolRewardTokens[_poolAddress][i]).safeTransferFrom(
                        vault,
                        _poolAddress, 
                        rewards
                    );
                }
            }
        }

        /// @dev update weighs between pools ( only if independent )
        _updateWeights();

        /// @dev update accumulated reward
        _pool.lastRewardTime = BoringMath.to64(block.timestamp);

        return true;
    }

    function poolRewards(address _poolAddress, address _rewardToken, uint256 _from, uint256 _to) public override view returns (uint256 rewards) {
        Pools memory _pool = poolData[_poolAddress];
        Rewards memory _rewards = rewardData[_rewardToken];

        if (_to <= uint256(_rewards.startTime) || _from > uint256(_rewards.endTime)) {
            return 0;
        }                 
        /// GP: Check that the maths doesnt leave dust
        if (_from < uint256(_rewards.startTime)) {
            _from = uint256(_rewards.startTime);
        }
        // Add the case when time has expired
        if (uint256(_rewards.endTime) <= _to) {
            _to = uint256(_rewards.endTime);
        }
        rewards = uint256(_rewards.rewardsPerSecond) * uint256( _rewards.rewardPoints / _pool.poolPoints) * (_to - _from );

    }

    /// @notice Gets the total rewards outstanding from last reward time
    function totalRewards() external override view returns (address[] memory, uint256[] memory) {
        // return totalRewards(rewardTokenArray[0]);     
        uint poolSize = tokenPools.length;
        address[] memory rTokens = new address[](poolSize);
        uint256[] memory rewards = new uint[](poolSize);

        for(uint8 i = 0; i < poolSize; i++) {
            rTokens[i] = tokenPools[i];
            rewards[i] = totalRewards(tokenPools[i]);
        }

        return (rTokens, rewards);

    }

    /// @notice Gets the total rewards outstanding from last reward time
    function totalRewards(address rewardToken) public override view returns (uint256) {
        uint256 poolRewardsCount = 0 ;

        /// @dev add multiples of the week
        for (uint256 i = 0; i < tokenPools.length; i++) {
            poolRewardsCount += poolRewards(tokenPools[i], rewardToken, uint256(poolData[tokenPools[i]].lastRewardTime), block.timestamp);
        }

        return poolRewardsCount;     
    }


    function _updateWeights()  internal {
        // GP: This is blank for non dynamic pools
    }


    /// @notice allows for the recovery of incorrect ERC20 tokens sent to contract
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        // Cannot recover rewards token
        // GP: Maybe you should be able to recove the rewards as this is the rewarder
        require(
            accessControls.hasAdminRole(msg.sender),
            "BasicRewarder.recoverERC20: Sender must be admin"
        );

        for (uint256 i = 0; i < rewardTokenArray.length; i++) {
            require(
                tokenAddress != address(rewardTokenArray[i]),
                "Cannot withdraw the rewards token"
            );
        }
        OZIERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }


}