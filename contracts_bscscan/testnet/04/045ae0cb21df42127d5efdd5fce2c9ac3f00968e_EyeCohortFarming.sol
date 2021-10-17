/**
 *Submitted for verification at BscScan.com on 2021-10-16
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

    /*
     * rewardIndex keeps track of the total amount of rewards to be distributed for
     * each supplied unit of 'stakedToken' tokens. When used together with supplierIndex,
     * the total amount of rewards to be paid out to individual users can be calculated
     * when the user claims their rewards.
     *
     * Consider the following:
     *
     * At contract deployment, the contract has a zero 'stakedToken' balance. Immediately, a new
     * user, User A, deposits 1000 'stakedToken' tokens, thus increasing the total supply to
     * 1000 'stakedToken'. After 60 seconds, a second user, User B, deposits an additional 500 'stakedToken',
     * increasing the total supplied amount to 1500 'stakedToken'.
     *
     * Because all balance-changing contract calls, as well as those changing the reward
     * speeds, must invoke the accrueRewards function, these deposit calls trigger the
     * function too. The accrueRewards function considers the reward speed (denoted in
     * reward tokens per second), the reward and supplier reward indexes, and the supply
     * balance to calculate the accrued rewards.
     *
     * When User A deposits their tokens, rewards are yet to be accrued due to previous
     * inactivity; the elapsed time since the previous, non-existent, reward-accruing
     * contract call is zero, thus having a reward accrual period of zero. The block
     * time of the deposit transaction is saved in the contract to indicate last
     * activity time.
     *
     * When User B deposits their tokens, 60 seconds has elapsed since the previous
     * call to the accrueRewards function, indicated by the difference of the current
     * block time and the last activity time. In other words, up till the time of
     * User B's deposit, the contract has had a 60 second accrual period for the total
     * amount of 1000 'stakedToken' tokens at the set reward speed. Assuming a reward speed of
     * 5 tokens per second (denoted 5 T/s), the accrueRewards function calculates the
     * accrued reward per supplied unit of 'stakedToken' tokens for the elapsed time period.
     * This works out to ((5 T/s) / 1000 'stakedToken') * 60 s = 0.3 T/'stakedToken' during the 60 second
     * period. At this point, the global reward index variable is updated, increasing
     * its value by 0.3 T/'stakedToken', and the reward accrual block timestamp,
     * initialised in the previous step, is updated.
     *
     * After 90 seconds of the contract deployment, User A decides to claim their accrued
     * rewards. Claiming affects token balances, thus requiring an invocation of the
     * accrueRewards function. This time, the accrual period is 30 seconds (90 s - 60 s),
     * for which the reward accrued per unit of 'stakedToken' is ((5 T/s) / 1500 'stakedToken') * 30 s = 0.1 T/'stakedToken'.
     * The reward index is updated to 0.4 T/'stakedToken' (0.3 T/'stakedToken' + 0.1 T/'stakedToken') and the reward
     * accrual block timestamp is set to the current block time.
     *
     * After the reward accrual, User A's rewards are claimed by transferring the correct
     * amount of T tokens from the contract to User A. Because User A has not claimed any
     * rewards yet, their supplier index is zero, the initial value determined by the
     * global reward index at the time of the user's first deposit. The amount of accrued
     * rewards is determined by the difference between the global reward index and the
     * user's own supplier index; essentially, this value represents the amount of
     * T tokens that have been accrued per supplied 'stakedToken' during the time since the user's
     * last claim. User A has a supply balance of 1000 'stakedToken', thus having an unclaimed
     * token amount of (0.4 T/'stakedToken' - 0 T/'stakedToken') * 1000 'stakedToken' = 400 T. This amount is
     * transferred to User A, and their supplier index is set to the current global reward
     * index to indicate that all previous rewards have been accrued.
     *
     * If User B was to claim their rewards at the same time, the calculation would take
     * the form of (0.4 T/'stakedToken' - 0.3 T/'stakedToken') * 500 'stakedToken' = 50 T. As expected, the total amount
     * of accrued reward (5 T/s * 90 s = 450 T) equals to the sum of the rewards paid
     * out to both User A and User B (400 T + 50 T = 450 T).
     *
     * This method of reward accrual is used to minimise the contract call complexity.
     * If a global mapping of users to their accrued rewards was implemented instead of
     * the index calculations, each function call invoking the accrueRewards function
     * would become immensely more expensive due to having to update the rewards for each
     * user. In contrast, the index approach allows the update of only a single user
     * while still keeping track of the other's rewards.
     *
     * Because rewards can be paid in multiple assets, reward indexes, reward supplier
     * indexes, and reward speeds depend on the StakingReward token.
     */

contract EyeCohortFarming is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //contract address for token that users stake for rewards
    address public immutable stakedToken;
    //number of rewards tokens distributed to users
    uint256 public numberStakingRewards;
    // Sum of all supplied 'stakedToken' tokens
    uint256 public totalSupplies;
    //see explanation of accrualBlockTimestamp, rewardIndex, and supplierRewardIndex above
    uint256 public accrualBlockTimestamp;
    mapping(uint256 => uint256) public rewardIndex;
    mapping(address => mapping(uint256 => uint256)) public supplierRewardIndex; 
    // Supplied 'stakedToken' for each user
    mapping(address => uint256) public supplyAmount;
    // Addresses of the ERC20 reward tokens
    mapping(uint256 => address) public rewardTokenAddresses;
    // Reward accrual speeds per reward token as tokens per second
    mapping(uint256 => uint256) public rewardSpeeds;
    // Reward rewardPeriodFinishes per reward token as UTC timestamps
    mapping(uint256 => uint256) public rewardPeriodFinishes;
    // Unclaimed staking rewards per user and token
    mapping(address => mapping(uint256 => uint256)) public accruedReward;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    constructor(address _stakedToken, uint256 _numberStakingRewards, address[] memory _rewardTokens, uint256[] memory _rewardPeriodFinishes) {
        require(_stakedToken != address(0));
        require(_rewardTokens.length == _numberStakingRewards, "bad _rewardTokens input");
        require(_rewardPeriodFinishes.length == _numberStakingRewards, "bad _rewardPeriodFinishes input");
        stakedToken = _stakedToken;
        numberStakingRewards = _numberStakingRewards;
        for (uint256 i = 0; i < _numberStakingRewards; i++) {
            require(_rewardTokens[i] != address(0));
            require(_rewardPeriodFinishes[i] > block.timestamp, "cannot set rewards to finish in past");
            rewardTokenAddresses[i] = _rewardTokens[i];
            rewardPeriodFinishes[i] = _rewardPeriodFinishes[i];
        }
        accrualBlockTimestamp = block.timestamp;
    }

     /*
     * Get the current amount of available rewards for claiming.
     *
     * @param rewardToken Reward token whose claimable balance to query
     * @return Balance of claimable reward tokens
     */
    function getClaimableRewards(uint256 rewardTokenIndex) external view returns(uint256) {
        require(rewardTokenIndex <= numberStakingRewards, "Invalid reward token");
        uint256 rewardIndexDelta = rewardIndex[rewardTokenIndex] - (supplierRewardIndex[msg.sender][rewardTokenIndex]);
        uint256 claimableReward = ((rewardIndexDelta * supplyAmount[msg.sender]) / 1e36) + accruedReward[msg.sender][rewardTokenIndex];
        return claimableReward;
    }

    function lastTimeRewardApplicable(uint256 rewardTokenIndex) public view returns (uint256) {
        return min(block.timestamp, rewardPeriodFinishes[rewardTokenIndex]);
    }

    function deposit(uint256 amount) external nonReentrant {
        IERC20 token = IERC20(stakedToken);
        uint256 contractBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 depositedAmount = token.balanceOf(address(this)) - contractBalance;
        distributeReward(msg.sender);
        totalSupplies += depositedAmount;
        supplyAmount[msg.sender] += depositedAmount;
    }

    function withdraw(uint amount) public nonReentrant {
        require(amount <= supplyAmount[msg.sender], "Too large withdrawal");
        distributeReward(msg.sender);
        supplyAmount[msg.sender] -= amount;
        totalSupplies -= amount;
        IERC20 token = IERC20(stakedToken);
        token.safeTransfer(msg.sender, amount);
    }

    function exit() external nonReentrant {
        withdraw(supplyAmount[msg.sender]);
    }

    function claimRewards() external nonReentrant {
        distributeReward(msg.sender);
        for (uint256 i = 0; i < numberStakingRewards; i++) {
            uint256 amount = accruedReward[msg.sender][i];
            claimErc20(i, msg.sender, amount);
        }
    }

    function setRewardSpeed(uint256 rewardTokenIndex, uint256 speed) external onlyOwner {
        if (accrualBlockTimestamp != 0) {
            accrueReward();
        }
        rewardSpeeds[rewardTokenIndex] = speed;
    }

    function setRewardPeriodFinish(uint256 rewardTokenIndex, uint256 rewardPeriodFinish) external onlyOwner {
        require(rewardPeriodFinish > block.timestamp, "cannot set rewards to finish in past");
        rewardPeriodFinishes[rewardTokenIndex] = rewardPeriodFinish;
    }

    function addNewRewardToken(address rewardTokenAddress) external onlyOwner {
        require(rewardTokenAddress != address(0), "Cannot set zero address");
        numberStakingRewards += 1;
        rewardTokenAddresses[numberStakingRewards - 1] = rewardTokenAddress;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner nonReentrant {
        require(tokenAddress != address(stakedToken), "Cannot withdraw the staked token");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * Update reward accrual state.
     *
     * @dev accrueReward() must be called every time the token balances
     *      or reward speeds change
     */
    function accrueReward() internal {
        if (block.timestamp == accrualBlockTimestamp || totalSupplies == 0) {
            return;
        }
        for (uint256 i = 0; i < numberStakingRewards; i += 1) {
            uint256 rewardSpeed = rewardSpeeds[i];
            if (rewardSpeed == 0 || accrualBlockTimestamp >= rewardPeriodFinishes[i]) {
                continue;
            }
            uint256 blockTimestampDelta = (min(block.timestamp, rewardPeriodFinishes[i]) - accrualBlockTimestamp);
            uint256 accrued = (rewardSpeeds[i] * blockTimestampDelta);
            uint256 accruedPerStakedToken = (accrued * 1e36) / totalSupplies;
            rewardIndex[i] += accruedPerStakedToken;
        }
        accrualBlockTimestamp = block.timestamp;
    }

    /**
     * Calculate accrued rewards for a single account based on the reward indexes.
     *
     * @param recipient Account for which to calculate accrued rewards
     */
    function distributeReward(address recipient) internal {
        accrueReward();
        for (uint256 i = 0; i < numberStakingRewards; i += 1) {
            uint256 rewardIndexDelta = (rewardIndex[i] - supplierRewardIndex[recipient][i]);
            uint256 accruedAmount = (rewardIndexDelta * supplyAmount[recipient]) / 1e36;
            accruedReward[recipient][i] += accruedAmount;
            supplierRewardIndex[recipient][i] = rewardIndex[i];
        }
    }

    /**
     * Transfer ERC20 rewards from the contract to the reward recipient.
     *
     * @param rewardTokenIndex ERC20 reward token which is claimed
     * @param recipient Address, whose rewards are claimed
     * @param amount The amount of claimed reward
     */
    function claimErc20(uint256 rewardTokenIndex, address recipient, uint256 amount) internal {
        require(accruedReward[recipient][rewardTokenIndex] <= amount, "Not enough accrued rewards");
        IERC20 token = IERC20(rewardTokenAddresses[rewardTokenIndex]);
        accruedReward[recipient][rewardTokenIndex] -= amount;
        token.safeTransfer(recipient, amount);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}