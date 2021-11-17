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

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

struct Rewards {
    uint128 userRewardPerTokenPaid; // reward per token already paid
    uint128 rewardToPay; // stored amount of reward torken to pay
}

struct RewardToken {
    uint16 index; // index in rewardsTokensArray
    uint32 periodFinish; // time in seconds rewards will end
    uint32 lastUpdateTime; // last time reward info was updated
    uint128 rewardPerTokenStored; // reward per token
    uint128 rewardRate; // how many reward tokens to give out per second
    mapping(address => Rewards) rewards;
}

struct AppStorage {
    address rewardsDistribution;
    IERC20 stakingToken;
    address[] rewardTokensArray;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => RewardToken) rewardTokens;
}

// https://raw.githubusercontent.com/QuickSwap/megapool/main/contracts/MegaPool.sol
contract MegaPool {
    AppStorage internal s;

    constructor(address _rewardsDistribution, address _stakingToken) {
        s.stakingToken = IERC20(_stakingToken);
        s.rewardsDistribution = _rewardsDistribution;
    }

    function rewardsDistribution() external view returns (address) {
        return s.rewardsDistribution;
    }

    function transferRewardsDistribution(address _newRewardsDistribution)
        external
    {
        require(
            s.rewardsDistribution == msg.sender,
            "Transfer rewards distribution not authorized"
        );
        emit RewardsDistributionTransferred(
            s.rewardsDistribution,
            _newRewardsDistribution
        );
        s.rewardsDistribution = _newRewardsDistribution;
    }

    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = s.totalSupply;
    }

    function stakingToken() external view returns (address) {
        return address(s.stakingToken);
    }

    function rewardTokensArray()
        external
        view
        returns (address[] memory rewardTokens_)
    {
        return s.rewardTokensArray;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return s.balances[_account];
    }

    struct RewardTokenInfo {
        uint256 index; // index in rewardsTokensArray
        uint256 periodFinish; // rewards end at this time in seconds
        uint256 rewardRate; // how many reward tokens per second
        uint256 rewardPerTokenStored; // how many reward tokens per staked token stored
        uint256 lastUpdateTime; // last time tht rewar
    }

    function rewardTokenInfo(address _rewardToken)
        external
        view
        returns (RewardTokenInfo memory)
    {
        return
            RewardTokenInfo({
                index: s.rewardTokens[_rewardToken].index,
                periodFinish: s.rewardTokens[_rewardToken].periodFinish,
                rewardRate: s.rewardTokens[_rewardToken].rewardRate,
                rewardPerTokenStored: s
                    .rewardTokens[_rewardToken]
                    .rewardPerTokenStored,
                lastUpdateTime: s.rewardTokens[_rewardToken].lastUpdateTime
            });
    }

    function lastTimeRewardApplicable(address _rewardToken)
        internal
        view
        returns (uint256)
    {
        uint256 periodFinish = s.rewardTokens[_rewardToken].periodFinish;
        // return smaller time
        return block.timestamp > periodFinish ? periodFinish : block.timestamp;
    }

    // gets the amount of rew
    function rewardPerToken(address _rewardToken)
        internal
        view
        returns (uint256 rewardPerToken_, uint256 lastTimeRewardApplicable_)
    {
        RewardToken storage rewardToken = s.rewardTokens[_rewardToken];
        uint256 l_totalSupply = s.totalSupply;
        uint256 lastUpdateTime = rewardToken.lastUpdateTime;
        lastTimeRewardApplicable_ = lastTimeRewardApplicable(_rewardToken);
        if (lastUpdateTime == 0 || l_totalSupply == 0) {
            rewardPerToken_ = rewardToken.rewardPerTokenStored;
        } else {
            rewardPerToken_ =
                rewardToken.rewardPerTokenStored +
                ((lastTimeRewardApplicable_ - lastUpdateTime) *
                    rewardToken.rewardRate *
                    1e18) /
                l_totalSupply;
        }
    }

    // earned an not yet paid
    function earned(address _rewardToken, address _account)
        external
        view
        returns (uint256)
    {
        (uint256 l_rewardPerToken, ) = rewardPerToken(_rewardToken);
        return internalEarned(l_rewardPerToken, _rewardToken, _account);
    }

    function internalEarned(
        uint256 _rewardPerToken,
        address _rewardToken,
        address _account
    ) internal view returns (uint256) {
        RewardToken storage rewardToken = s.rewardTokens[_rewardToken];
        return
            (s.balances[_account] *
                (_rewardPerToken -
                    rewardToken.rewards[_account].userRewardPerTokenPaid)) /
            1e18 +
            rewardToken.rewards[_account].rewardToPay;
    }

    struct Earned {
        address rewardToken;
        uint256 earned;
    }

    function earned(address _account)
        external
        view
        returns (Earned[] memory earned_)
    {
        earned_ = new Earned[](s.rewardTokensArray.length);
        for (uint256 i; i < earned_.length; i++) {
            address rewardTokenAddress = s.rewardTokensArray[i];
            earned_[i].rewardToken = rewardTokenAddress;
            (uint256 l_rewardPerToken, ) = rewardPerToken(rewardTokenAddress);
            earned_[i].earned = internalEarned(
                l_rewardPerToken,
                rewardTokenAddress,
                _account
            );
        }
    }

    function stakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_amount > 0, "Cannot stake 0");
        updateRewardAll(msg.sender);
        IERC20 l_stakingToken = s.stakingToken;
        s.totalSupply += _amount;
        s.balances[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
        // permit
        IERC20Permit(address(l_stakingToken)).permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        SafeERC20.safeTransferFrom(
            l_stakingToken,
            msg.sender,
            address(this),
            _amount
        );
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        updateRewardAll(msg.sender);
        s.totalSupply += _amount;
        s.balances[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
        SafeERC20.safeTransferFrom(
            s.stakingToken,
            msg.sender,
            address(this),
            _amount
        );
    }

    function getRewards() public {
        uint256 length = s.rewardTokensArray.length;
        for (uint256 i; i < length; ) {
            address rewardTokenAddress = s.rewardTokensArray[i];
            uint256 rewardToPay = updateReward(rewardTokenAddress, msg.sender);
            RewardToken storage rewardToken = s.rewardTokens[
                rewardTokenAddress
            ];
            if (rewardToPay > 0) {
                rewardToken.rewards[msg.sender].rewardToPay = 0;
                emit RewardPaid(rewardTokenAddress, msg.sender, rewardToPay);
                SafeERC20.safeTransfer(
                    IERC20(rewardTokenAddress),
                    msg.sender,
                    rewardToPay
                );
            }
            unchecked {
                i++;
            }
        }
    }

    function getSpecificRewards(address[] calldata _rewardTokensArray)
        external
    {
        for (uint256 i; i < _rewardTokensArray.length; ) {
            address rewardTokenAddress = _rewardTokensArray[i];
            RewardToken storage rewardToken = s.rewardTokens[
                rewardTokenAddress
            ];
            uint256 index = rewardToken.index;
            require(
                s.rewardTokensArray[index] == rewardTokenAddress,
                "Reward token address does not exist"
            );
            uint256 rewardToPay = updateReward(rewardTokenAddress, msg.sender);
            if (rewardToPay > 0) {
                rewardToken.rewards[msg.sender].rewardToPay = 0;
                emit RewardPaid(rewardTokenAddress, msg.sender, rewardToPay);
                SafeERC20.safeTransfer(
                    IERC20(rewardTokenAddress),
                    msg.sender,
                    rewardToPay
                );
            }
            unchecked {
                i++;
            }
        }
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Cannot withdraw 0");
        uint256 balance = s.balances[msg.sender];
        require(_amount <= balance, "Can't withdraw more than staked");
        updateRewardAll(msg.sender);
        s.totalSupply -= _amount;
        s.balances[msg.sender] = balance - _amount;
        emit Withdrawn(msg.sender, _amount);
        SafeERC20.safeTransfer(s.stakingToken, msg.sender, _amount);
    }

    function withdrawAll() external {
        withdraw(s.balances[msg.sender]);
    }

    function exit() external {
        getRewards();
        uint256 amount = s.balances[msg.sender];
        s.totalSupply -= amount;
        s.balances[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
        SafeERC20.safeTransfer(s.stakingToken, msg.sender, amount);
    }

    function updateRewardAll(address _account) internal {
        uint256 length = s.rewardTokensArray.length;
        for (uint256 i; i < length; ) {
            address rewardTokenAddress = s.rewardTokensArray[i];
            updateReward(rewardTokenAddress, _account);
            unchecked {
                i++;
            }
        }
    }

    function updateReward(address _rewardToken, address _account)
        internal
        returns (uint256 rewardToPay_)
    {
        RewardToken storage rewardToken = s.rewardTokens[_rewardToken];
        (uint256 l_rewardPerToken, uint256 lastUpdateTime) = rewardPerToken(
            _rewardToken
        );
        rewardToken.rewardPerTokenStored = uint128(l_rewardPerToken);
        rewardToken.lastUpdateTime = uint32(lastUpdateTime);
        rewardToPay_ = internalEarned(l_rewardPerToken, _rewardToken, _account);
        rewardToken.rewards[_account].rewardToPay = uint128(rewardToPay_);
        rewardToken.rewards[_account].userRewardPerTokenPaid = uint128(
            l_rewardPerToken
        );
    }

    struct RewardTokenArgs {
        address rewardToken; // ERC20 address
        uint256 reward; // total reward amount
        uint256 rewardDuration; // how many seconds rewards are distributed
    }

    function notifyRewardAmount(RewardTokenArgs[] calldata _args) external {
        require(
            msg.sender == s.rewardsDistribution,
            "Caller is not RewardsDistribution"
        );
        require(
            s.rewardTokensArray.length + _args.length <= 200,
            "Too many reward tokens"
        );
        for (uint256 i; i < _args.length; ) {
            RewardTokenArgs calldata args = _args[i];
            RewardToken storage rewardToken = s.rewardTokens[args.rewardToken];
            uint256 oldPeriodFinish = rewardToken.periodFinish;
            require(
                block.timestamp + args.rewardDuration >= oldPeriodFinish,
                "Cannot reduce existing period"
            );
            uint256 rewardRate;
            if (block.timestamp >= oldPeriodFinish) {
                require(
                    args.reward <= type(uint128).max,
                    "Reward is too large"
                );
                rewardRate = args.reward / args.rewardDuration;
            } else {
                uint256 remaining = oldPeriodFinish - block.timestamp;
                uint256 leftover = remaining * rewardToken.rewardRate;
                uint256 reward = args.reward + leftover;
                require(reward <= type(uint128).max, "Reward is too large");
                rewardRate = reward / args.rewardDuration;
            }
            (uint256 l_rewardPerToken, ) = rewardPerToken(args.rewardToken);
            rewardToken.rewardPerTokenStored = uint128(l_rewardPerToken);
            uint256 periodFinish = block.timestamp + args.rewardDuration;
            if (oldPeriodFinish == 0) {
                rewardToken.index = uint16(s.rewardTokensArray.length);
                s.rewardTokensArray.push(args.rewardToken);
            }
            rewardToken.periodFinish = uint32(periodFinish);
            rewardToken.lastUpdateTime = uint32(block.timestamp);
            rewardToken.rewardRate = uint128(rewardRate);
            emit RewardAdded(args.rewardToken, args.reward, periodFinish);

            // Ensure the provided reward amount is not more than the balance in the contract.
            // This keeps the reward rate in the right range, preventing overflows due to
            // very high values of rewardRate in the earned and rewardsPerToken functions;
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            uint256 balance = IERC20(args.rewardToken).balanceOf(address(this));
            require(
                rewardRate <= balance / args.rewardDuration,
                "Provided reward not in contract"
            );
            unchecked {
                i++;
            }
        }
    }

    event RewardAdded(
        address indexed rewardToken,
        uint256 reward,
        uint256 periodFinish
    );
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed rewardToken,
        address indexed user,
        uint256 reward
    );
    event RewardsDistributionTransferred(
        address indexed oldRewardsDistribution,
        address indexed newRewardsDistribution
    );
}