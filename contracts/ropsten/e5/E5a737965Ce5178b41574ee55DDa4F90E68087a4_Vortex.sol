// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPortal.sol";

contract Portal is IPortal, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    struct User {
        uint256 balance;
        uint256[] userRewardPerTokenPaid;
        uint256[] rewards;
    }

    uint256 public endBlock;
    uint256 public rewardsDuration;
    uint256 public lastBlockUpdate;
    uint256 public totalStaked;

    uint256[] public rewardRate;
    uint256[] public totalRewards;
    uint256[] public rewardPerTokenSnapshot;
    uint256[] public distributedReward;
    uint256[] public totalRewardRatios;
    uint256[] public minimumRewardRate;

    uint256 public userStakeLimit;
    uint256 public contractStakeLimit;
    uint256 public distributionLimit;

    mapping(address => User) public users;
    mapping(address => uint256[]) public providerRewardRatios;

    IERC20Metadata[] public rewardsToken;
    IERC20Metadata public stakingToken;

    event Harvested(address recipient);
    event Withdrawn(address recipient, uint256 amount);
    event Staked(address staker, address recipient, uint256 amount);

    constructor(
        uint256 _endBlock,
        address[] memory _rewardsToken,
        uint256[] memory _minimumRewardRate,
        address _stakingToken,
        uint256 _stakeLimit,
        uint256 _contractStakeLimit,
        uint256 _distributionLimit
    ) {
        require(_endBlock > block.number, "Portal: The end block must be in the future.");
        require(_stakeLimit != 0, "Portal: Stake limit needs to be more than 0");
        require(_contractStakeLimit != 0, "Portal: Contract Stake limit needs to be more than 0");

        endBlock = _endBlock;
        stakingToken = IERC20Metadata(_stakingToken);
        minimumRewardRate = _minimumRewardRate;
        userStakeLimit = _stakeLimit;
        contractStakeLimit = _contractStakeLimit;
        distributionLimit = _distributionLimit;

        for (uint256 i = 0; i < _rewardsToken.length; i++) {
            rewardsToken.push(IERC20Metadata(_rewardsToken[i]));
            rewardRate.push(0);
            totalRewards.push(0);
            rewardPerTokenSnapshot.push(0);
            distributedReward.push(0);
            totalRewardRatios.push(0);
        }
    }

    function stake(uint256 amount, address recipient) external override nonReentrant {
        User storage user = users[recipient];

        uint256 rewardTokensLength = rewardsToken.length;
        for (uint256 i = user.rewards.length; i < rewardTokensLength; i++) {
            user.rewards.push(0);
            user.userRewardPerTokenPaid.push(0);
        }

        updateReward(user);
        require(amount > 0, "Portal: cannot stake 0");
        require(user.balance + amount <= userStakeLimit, "Portal: user stake limit exceeded");
        require(totalStaked + amount <= contractStakeLimit, "Portal: contract stake limit exceeded");
        totalStaked = totalStaked + amount;
        user.balance = user.balance + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, recipient, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        User storage user = users[msg.sender];
        updateReward(user);
        require(amount > 0, "Portal: cannot withdraw 0");
        require(amount <= user.balance, "Portal: withdraw amount exceeds available");
        totalStaked = totalStaked - amount;
        user.balance = user.balance - amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function harvest(address recipient) public nonReentrant {
        User storage user = users[recipient];
        updateReward(user);

        uint256 rewardTokensLength = rewardsToken.length;
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            uint256 reward = user.rewards[i];
            if (reward > 0) {
                user.rewards[i] = 0;
                rewardsToken[i].safeTransfer(recipient, reward);
            }
        }

        emit Harvested(recipient);
    }

    function harvest(uint256[] memory tokenIndices, address recipient) public nonReentrant {
        User storage user = users[recipient];
        updateReward(user);

        uint256 numberOfTokensForHarvesting = tokenIndices.length;
        for (uint256 i = 0; i < numberOfTokensForHarvesting; i++) {
            uint256 rewardIndex = tokenIndices[i];
            uint256 reward = user.rewards[rewardIndex];
            if (reward > 0) {
                user.rewards[rewardIndex] = 0;
                rewardsToken[rewardIndex].safeTransfer(recipient, reward);
            }
        }

        emit Harvested(recipient);
    }

    function exit() external {
        withdraw(users[msg.sender].balance);
        harvest(msg.sender);
    }

    function addReward(uint256[] memory rewards, uint256 newEndBlock) external nonReentrant {
        require(newEndBlock >= endBlock, "Portal: invalid end block");
        uint256 rewardTokensLength = rewardsToken.length;
        require(rewards.length == rewardsToken.length, "Portal: rewards length mismatch");

        User storage user = users[msg.sender];

        for (uint256 i = user.rewards.length; i < rewardTokensLength; i++) {
            user.rewards.push(0);
            user.userRewardPerTokenPaid.push(0);
        }

        uint256[] storage providerRatios = providerRewardRatios[msg.sender];
        for (uint256 i = providerRatios.length; i < rewardTokensLength; i++) {
            providerRatios.push(0);
        }

        updateReward(user);

        rewardsDuration = newEndBlock - block.number;

        for (uint256 i = 0; i < rewardTokensLength; i++) {
            uint256 remainingReward = 0;
            uint256 tokenMultiplier = getTokenMultiplier(i);

            if (totalRewards[i] > 0) {
                remainingReward = totalRewards[i] - totalEarned(i);
                rewardRate[i] = (rewards[i] + remainingReward) / rewardsDuration;
            } else {
                rewardRate[i] = rewards[i] / rewardsDuration;
            }

            require(minimumRewardRate[i] <= rewardRate[i], "Portal: invalid reward rate");
            uint256 newRewardRatio = remainingReward == 0 ? tokenMultiplier : (rewards[i] * tokenMultiplier) / remainingReward;
            providerRatios[i] = providerRatios[i] + newRewardRatio;
            totalRewardRatios[i] = totalRewardRatios[i] + providerRatios[i];
            rewardsToken[i].safeTransferFrom(msg.sender, address(this), rewards[i]);
            totalRewards[i] = totalRewards[i] + rewards[i];
        }

        lastBlockUpdate = block.number;
        endBlock = newEndBlock;
    }

    function removeReward() external nonReentrant {
        User storage user = users[msg.sender];
        uint256[] storage providerRatios = providerRewardRatios[msg.sender];

        updateReward(user);

        rewardsDuration = endBlock - block.number;

        uint256 rewardTokensLength = rewardsToken.length;
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            uint256 remainingReward = totalRewards[i] - totalEarned(i);
            uint256 providerPortion = (remainingReward * providerRatios[i]) / totalRewardRatios[i];
            totalRewardRatios[i] = totalRewardRatios[i] - providerRatios[i];
            providerRatios[i] = 0;
            totalRewards[i] = totalRewards[i] - providerPortion;
            rewardRate[i] = (remainingReward - providerPortion) / rewardsDuration;
            rewardsToken[i].safeTransfer(msg.sender, providerPortion);
        }

        lastBlockUpdate = block.number;
    }

    function migrate(uint256 _amount, address _portal) external nonReentrant {
        User storage user = users[msg.sender];
        require(user.balance >= _amount, "Portal: migrate amount exceeds balance");
        stakingToken.approve(_portal, _amount);
        IPortal(_portal).stake(_amount, msg.sender);
    }

    function rewardPerTokenStaked(uint256 tokenIndex) public view returns (uint256) {
        uint256 tokenMultiplier = getTokenMultiplier(tokenIndex);
        return
            totalStaked > distributionLimit
                ? rewardPerTokenSnapshot[tokenIndex] +
                    (((lastBlockRewardIsApplicable() - lastBlockUpdate) * rewardRate[tokenIndex] * tokenMultiplier) / totalStaked)
                : rewardPerTokenSnapshot[tokenIndex];
    }

    function earned(address account, uint256 tokenIndex) public view returns (uint256) {
        User memory user = users[account];
        uint256 tokenMultiplier = getTokenMultiplier(tokenIndex);
        return
            user.rewards[tokenIndex] +
            ((user.balance * (rewardPerTokenStaked(tokenIndex) - user.userRewardPerTokenPaid[tokenIndex])) / tokenMultiplier);
    }

    function getTokenMultiplier(uint256 tokenIndex) public view returns (uint256) {
        uint256 tokenDecimals = IERC20Metadata(rewardsToken[tokenIndex]).decimals();
        return 10**tokenDecimals;
    }

    function totalEarned(uint256 tokenIndex) public view returns (uint256) {
        uint256 tokenMultiplier = getTokenMultiplier(tokenIndex);
        return
            distributedReward[tokenIndex] +
            ((totalStaked * (rewardPerTokenStaked(tokenIndex) - rewardPerTokenSnapshot[tokenIndex])) / tokenMultiplier);
    }

    function lastBlockRewardIsApplicable() public view returns (uint256) {
        return block.number > endBlock ? endBlock : block.number;
    }

    function harvestForDuration(uint256 tokenIndex) public view returns (uint256) {
        return rewardRate[tokenIndex] * rewardsDuration;
    }

    function updateReward(User storage user) internal {
        uint256 _lastBlockRewardIsApplicable = lastBlockRewardIsApplicable();

        uint256 rewardTokensLength = rewardsToken.length;
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            uint256 _rewardPerTokenSnapshot = rewardPerTokenSnapshot[i];
            uint256 _tokenMultiplier = getTokenMultiplier(i);

            if (totalStaked > distributionLimit) {
                _rewardPerTokenSnapshot =
                    _rewardPerTokenSnapshot +
                    (((_lastBlockRewardIsApplicable - lastBlockUpdate) * rewardRate[i] * _tokenMultiplier) / totalStaked);
            }

            distributedReward[i] =
                distributedReward[i] +
                ((totalStaked * (_rewardPerTokenSnapshot - rewardPerTokenSnapshot[i])) / _tokenMultiplier);
            rewardPerTokenSnapshot[i] = _rewardPerTokenSnapshot;

            user.rewards[i] =
                user.rewards[i] +
                ((user.balance * (_rewardPerTokenSnapshot - user.userRewardPerTokenPaid[i])) / _tokenMultiplier);
            user.userRewardPerTokenPaid[i] = _rewardPerTokenSnapshot;
        }

        lastBlockUpdate = _lastBlockRewardIsApplicable;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Portal.sol";

contract Vortex {
    address[] public portals;
    event PortalCreated(string portal_name, address indexed creator);

    function createPortal(
        string memory _portalName,
        uint256 _endBlock,
        address[] memory _rewardsToken,
        uint256[] memory _minimumRewardRate,
        address _stakingToken,
        uint256 _stakeLimit,
        uint256 _contractStakeLimit,
        uint256 _distributionLimit
    ) external {
        Portal portal =
            new Portal(_endBlock, _rewardsToken, _minimumRewardRate, _stakingToken, _stakeLimit, _contractStakeLimit, _distributionLimit);

        portals.push(address(portal));
        emit PortalCreated(_portalName, msg.sender);
    }

    function allPortalsLength() external view returns (uint256) {
        return portals.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPortal {
    function stake(uint256 amount, address recipient) external;
}