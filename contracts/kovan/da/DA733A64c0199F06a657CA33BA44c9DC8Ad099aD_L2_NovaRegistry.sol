// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "ovm-safeerc20/OVM_SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";

contract L2_NovaRegistry is ReentrancyGuard, OVM_CrossDomainEnabled {
    using OVM_SafeERC20 for IERC20;

    /// @notice The minimum delay between when `cancel` and `withdraw` can be called.
    uint256 public constant MIN_CANCEL_SECONDS = 300;

    /// @notice The ERC20 users must use to pay for the L1 gas usage of request.
    IERC20 public immutable ETH;

    /// @notice The address of the only contract authorized to make cross domain calls to `execCompleted`.
    address public L1_NovaExecutionManagerAddress;

    /// @param _ETH An ERC20 ETH you would like users to pay for gas with.
    /// @param _messenger The L2 xDomainMessenger contract you want to use to recieve messages.
    constructor(address _ETH, address _messenger) OVM_CrossDomainEnabled(_messenger) {
        ETH = IERC20(_ETH);
    }

    /// @notice Can only be called once. Authorizes the `_L1_NovaExecutionManagerAddress` to make cross domain calls to `execCompleted`.
    /// @param _L1_NovaExecutionManagerAddress The address to be authorized to make cross domain calls to `execCompleted`.
    function connectExecutionManager(address _L1_NovaExecutionManagerAddress) external {
        require(L1_NovaExecutionManagerAddress == address(0), "ALREADY_INITIALIZED");
        L1_NovaExecutionManagerAddress = _L1_NovaExecutionManagerAddress;
    }

    /// @notice Emitted when `cancel` is called.
    /// @param timestamp When the cancel will set into effect and the creator will be able to withdraw.
    event Cancel(bytes32 indexed execHash, uint256 timestamp);

    /// @notice Emitted when `withdraw` is called.
    event Withdraw(bytes32 indexed execHash);

    /// @notice Emitted when `requestExec` is called.
    event Request(bytes32 indexed execHash, address indexed strategy);

    /// @notice Emitted when `bumpGas` is called.
    /// @param newExecHash The execHash of the resubmitted request (copy of its uncle with an updated gasPrice).
    /// @param timestamp When the uncled request (`execHash`) will have its tokens transfered to the resubmitted request (`newExecHash`).
    event BumpGas(bytes32 indexed execHash, bytes32 indexed newExecHash, uint256 timestamp);

    /// @notice Emitted when `execCompleted` is called.
    event ExecCompleted(
        bytes32 indexed execHash,
        address indexed executor,
        address indexed rewardRecipient,
        uint256 gasUsed,
        bool reverted
    );

    struct InputToken {
        IERC20 l2Token;
        address l1Token;
        uint256 amount;
    }

    struct Bounty {
        IERC20 token;
        uint256 amount;
    }

    /// @dev The most recent nonce assigned to an execution request.
    uint72 private systemNonce;

    /// @dev Maps execHashes to the creator of each request.
    mapping(bytes32 => address) private requestCreators;
    /// @dev Maps execHashes to the nonce of each request.
    /// @dev This is just for convience, does not need to be on-chain.
    mapping(bytes32 => uint72) private requestNonces;
    /// @dev Maps execHashes to the address of the strategy associated with the request.
    mapping(bytes32 => address) private requestStrategies;
    /// @dev Maps execHashes to the calldata associated with the request.
    mapping(bytes32 => bytes) private requestCalldatas;
    /// @dev Maps execHashes to the gas limit a bot should use to execute the request.
    mapping(bytes32 => uint64) private requestGasLimits;
    /// @dev Maps execHashes to the gas price a bot must use to execute the request.
    mapping(bytes32 => uint256) private requestGasPrices;
    /// @dev Maps execHashes to the 'bounty' tokens a bot will recieve for executing the request.
    mapping(bytes32 => Bounty[]) private requestBounties;
    /// @dev Maps execHashes to the input tokens a bot must have to execute the request.
    mapping(bytes32 => InputToken[]) private requestInputTokens;

    /// @dev Maps execHashes to a timestamp representing when the request has/will have its tokens removed (via bumpGas/withdraw/execCompleted).
    /// @dev If the request has had its tokens removed via withdraw or execCompleted it will have a timestamp of 1.
    /// @dev If the request will have its tokens removed in the future (via bumpGas) it will be a standard timestamp.
    mapping(bytes32 => uint256) private requestTokenRemovalTimestamps;

    /// @dev Maps execHashes to a timestamp representing when the request is fully canceled and the creator can withdraw their bounties/inputs.
    /// @dev Bots should not attempt to execute a request if the current time has passed its cancel timestamp.
    mapping(bytes32 => uint256) private requestCancelTimestamps;

    /// @dev Maps execHashes which represent resubmitted requests (via bumpGas) to their corresponding "uncled" request's execHash.
    /// @dev An uncled request is a request that has had its tokens removed via `bumpGas` in favor of a resubmitted request generated in the transaction.
    mapping(bytes32 => bytes32) private uncles;

    /// @notice Returns all relevant data about a specific request.
    function getRequestData(bytes32 execHash)
        external
        view
        returns (
            // General request data:
            address strategy,
            bytes memory l1calldata,
            uint64 gasLimit,
            uint256 gasPrice,
            InputToken[] memory inputTokens,
            Bounty[] memory bounties,
            // Other data:
            uint72 nonce,
            address creator,
            bytes32 uncle,
            // Can be fetched via `isExecutable`:
            bool executable,
            uint256 changeTimestamp
        )
    {
        strategy = requestStrategies[execHash];
        l1calldata = requestCalldatas[execHash];
        gasLimit = requestGasLimits[execHash];
        gasPrice = requestGasPrices[execHash];
        inputTokens = requestInputTokens[execHash];
        bounties = requestBounties[execHash];
        nonce = requestNonces[execHash];
        creator = requestCreators[execHash];
        uncle = uncles[execHash];

        (executable, changeTimestamp) = isExecutable(execHash);
    }

    /// @param strategy The address of the "strategy" contract on L1 a bot should call with `calldata`.
    /// @param l1calldata The abi encoded calldata a bot should call the `strategy` with on L1.
    /// @param gasLimit The gas limit a bot should use on L1.
    /// @param gasPrice The gas price a bot should use on L1.
    /// @param inputTokens An array of token amounts that a bot will need on L1 to execute the request (`l1Token`s) along with the equivalent tokens that will be returned on L2 (`l2Token`s). `inputTokens` will not be awarded if the `strategy` reverts on L1.
    /// @param bounties An array of tokens that will be awarded to the bot who executes the request. Only 50% of the bounty will be paid to the bot if the `strategy` reverts on L1.
    function requestExec(
        address strategy,
        bytes calldata l1calldata,
        uint64 gasLimit,
        uint256 gasPrice,
        InputToken[] calldata inputTokens,
        Bounty[] calldata bounties
    ) public nonReentrant returns (bytes32 execHash) {
        systemNonce += 1;
        execHash = keccak256(abi.encodePacked(systemNonce, strategy, l1calldata, gasPrice));

        requestCreators[execHash] = msg.sender;
        requestStrategies[execHash] = strategy;
        requestCalldatas[execHash] = l1calldata;
        requestGasLimits[execHash] = gasLimit;
        requestGasPrices[execHash] = gasPrice;
        // This is just for convience, does not need to be on-chain.
        requestNonces[execHash] = systemNonce;

        // Transfer in ETH to pay for max gas usage.
        ETH.safeTransferFrom(msg.sender, address(this), gasPrice * gasLimit);

        // Transfer input tokens in that the msg.sender has approved.
        for (uint256 i = 0; i < inputTokens.length; i++) {
            inputTokens[i].l2Token.safeTransferFrom(msg.sender, address(this), inputTokens[i].amount);

            // Copy over this index to the requestInputTokens mapping (we can't just put a calldata/memory array directly into storage so we have to go index by index).
            requestInputTokens[execHash][i] = inputTokens[i];
        }

        // Transfer bounties in that the msg.sender has approved.
        for (uint256 i = 0; i < bounties.length; i++) {
            bounties[i].token.safeTransferFrom(msg.sender, address(this), bounties[i].amount);

            // Copy over this index to the requestBounties mapping (we can't just put a calldata/memory array directly into storage so we have to go index by index).
            requestBounties[execHash][i] = bounties[i];
        }

        emit Request(execHash, strategy);
    }

    /// @notice Calls `requestExec` with all relevant parameters along with calling `cancel` with the `autoCancelDelay` argument.
    /// @dev See `requestExec` and `cancel` for more information.
    function requestExecWithTimeout(
        address strategy,
        bytes calldata l1calldata,
        uint64 gasLimit,
        uint256 gasPrice,
        InputToken[] calldata inputTokens,
        Bounty[] calldata bounties,
        uint256 autoCancelDelay
    ) external returns (bytes32 execHash) {
        execHash = requestExec(strategy, l1calldata, gasLimit, gasPrice, inputTokens, bounties);

        cancel(execHash, autoCancelDelay);
    }

    /// @notice Cancels a request with a delay. Once the delay has passed anyone may call `withdraw` on behalf of the user to recieve their bounties/input tokens back.
    /// @notice msg.sender must be the creator of the request associated with the `execHash`.
    /// @param execHash The unique hash of the request to cancel.
    /// @param withdrawDelaySeconds The delay in seconds until the creator can withdraw their tokens. Must be greater than or equal to `MIN_CANCEL_SECONDS`.
    function cancel(bytes32 execHash, uint256 withdrawDelaySeconds) public {
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");
        require(requestCancelTimestamps[execHash] == 0, "ALREADY_CANCELED");
        require(requestCreators[execHash] == msg.sender, "NOT_CREATOR");
        require(withdrawDelaySeconds >= MIN_CANCEL_SECONDS, "DELAY_TOO_SMALL");

        // Set the delay timestamp to int(current timestamp + the delay)
        uint256 timestamp = block.timestamp + withdrawDelaySeconds;
        requestCancelTimestamps[execHash] = timestamp;

        emit Cancel(execHash, timestamp);
    }

    /// @notice Withdraws tokens (input/gas/bounties) from a canceled strategy.
    /// @notice The creator of the request associated with `execHash` must call `cancel` and wait the `withdrawDelaySeconds` they specified before calling `withdraw`.
    /// @notice Anyone may call this method on behalf of another user but the tokens will still go the creator of the request associated with the `execHash`.
    /// @param execHash The unique hash of the request to withdraw from.
    function withdraw(bytes32 execHash) external nonReentrant {
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");
        (bool canceled, ) = isCanceled(execHash);
        require(canceled, "NOT_CANCELED");

        address creator = requestCreators[execHash];
        InputToken[] memory inputTokens = requestInputTokens[execHash];
        Bounty[] memory bounties = requestBounties[execHash];

        // Store that the request has had its tokens removed.
        requestTokenRemovalTimestamps[execHash] = 1;

        // Transfer the ETH which would have been used for gas back to the creator.
        ETH.transfer(creator, requestGasPrices[execHash] * requestGasLimits[execHash]);

        // Transfer input tokens back to the creator.
        for (uint256 i = 0; i < inputTokens.length; i++) {
            inputTokens[i].l2Token.safeTransfer(creator, inputTokens[i].amount);
        }
        // Transfer bounties back to the creator.
        for (uint256 i = 0; i < bounties.length; i++) {
            bounties[i].token.safeTransfer(creator, bounties[i].amount);
        }

        emit Withdraw(execHash);
    }

    /// @notice Resubmit a request with a higher gas price.
    /// @notice This will "uncle" the `execHash` which means after `MIN_CANCEL_SECONDS` it will be disabled and the `newExecHash` will be enabled.
    /// @notice msg.sender must be the creator of the request associated with the `execHash`.
    /// @param execHash The execHash of the request you wish to resubmit with a higher gas price.
    /// @param gasPrice The updated gas price to use for the resubmitted request.
    function bumpGas(bytes32 execHash, uint256 gasPrice) external returns (bytes32 newExecHash) {
        (bool executable, ) = isExecutable(execHash);
        require(executable, "NOT_EXECUTABLE");
        uint256 previousGasPrice = requestGasPrices[execHash];
        require(requestCreators[execHash] == msg.sender, "NOT_CREATOR");
        require(gasPrice > previousGasPrice, "LESS_THAN_PREVIOUS_GAS_PRICE");

        // Generate a new execHash for the resubmitted request.
        systemNonce += 1;
        newExecHash = keccak256(
            abi.encodePacked(systemNonce, requestStrategies[execHash], requestCalldatas[execHash], gasPrice)
        );

        uint64 gasLimit = requestGasLimits[execHash];

        // Fill out data for the resubmitted request.
        requestStrategies[newExecHash] = requestStrategies[execHash];
        requestCalldatas[newExecHash] = requestCalldatas[execHash];
        requestGasLimits[newExecHash] = gasLimit;
        requestGasPrices[newExecHash] = gasPrice;
        requestNonces[execHash] = systemNonce;
        requestCreators[newExecHash] = msg.sender;

        // Map the resubmitted request to its uncle.
        uncles[newExecHash] = execHash;

        // Set the uncled request to expire in MIN_CANCEL_SECONDS.
        uint256 switchTimestamp = MIN_CANCEL_SECONDS + block.timestamp;
        requestTokenRemovalTimestamps[execHash] = switchTimestamp;

        // Transfer in additional ETH to pay for the new gas limit.
        ETH.safeTransferFrom(msg.sender, address(this), (gasPrice - previousGasPrice) * gasLimit);

        emit BumpGas(execHash, newExecHash, switchTimestamp);
    }

    function execCompleted(
        bytes32 execHash,
        address executor,
        address rewardRecipient,
        uint64 gasUsed,
        bool reverted
    ) external nonReentrant onlyFromCrossDomainAccount(L1_NovaExecutionManagerAddress) {
        (bool executable, ) = isExecutable(execHash);
        require(executable, "NOT_EXECUTABLE");

        // Store that the request has had its tokens removed.
        requestTokenRemovalTimestamps[execHash] = 1;

        InputToken[] memory inputTokens = requestInputTokens[execHash];
        Bounty[] memory bounties = requestBounties[execHash];

        // Transfer the ETH used for gas to the rewardRecipient.
        ETH.transfer(
            rewardRecipient,
            requestGasPrices[execHash] *
                (
                    // Don't give them any more ETH than the gas limit
                    gasUsed > requestGasLimits[execHash] ? requestGasLimits[execHash] : gasUsed
                )
        );

        // Only transfer input tokens if the request didn't revert.
        if (!reverted) {
            // Transfer input tokens to the rewardRecipient.
            for (uint256 i = 0; i < inputTokens.length; i++) {
                inputTokens[i].l2Token.safeTransfer(rewardRecipient, inputTokens[i].amount);
            }

            // Transfer full bounty back to the rewardRecipient.
            for (uint256 i = 0; i < bounties.length; i++) {
                bounties[i].token.safeTransfer(rewardRecipient, bounties[i].amount);
            }
        } else {
            address creator = requestCreators[execHash];

            // Transfer input tokens back to the creator.
            for (uint256 i = 0; i < inputTokens.length; i++) {
                inputTokens[i].l2Token.safeTransfer(creator, inputTokens[i].amount);
            }

            // Transfer 70% of the bounty to the rewardRecipient and 30% back to the creator.
            for (uint256 i = 0; i < bounties.length; i++) {
                IERC20 token = bounties[i].token;
                uint256 bountyFullAmount = bounties[i].amount;
                uint256 recipientAmount = (bountyFullAmount * 7) / 10;

                token.safeTransfer(
                    rewardRecipient,
                    // 70% goes to the rewardRecipient:
                    recipientAmount
                );

                token.safeTransfer(
                    creator,
                    // Remainder goes to the creator:
                    bountyFullAmount - recipientAmount
                );
            }
        }

        emit ExecCompleted(execHash, executor, rewardRecipient, gasUsed, reverted);
    }

    /// @notice Returns if the request is executable along with a timestamp of when that may change.
    /// @return executable A boolean indicating if the request is executable.
    /// @return changeTimestamp A timestamp indicating when the request might switch from being executable to unexecutable (or vice-versa). Will be 0 if there is no change expected. It will be a timestamp if the request will be enabled soon (it's a resubmitted version of an uncled request) or the request is being canceled soon.
    function isExecutable(bytes32 execHash) public view returns (bool executable, uint256 changeTimestamp) {
        if (requestCreators[execHash] == address(0)) {
            // This isn't a valid execHash!
            executable = false;
            changeTimestamp = 0;
        } else {
            (bool tokensRemoved, uint256 tokensRemovedChangeTimestamp) = areTokensRemoved(execHash);
            (bool canceled, uint256 canceledChangeTimestamp) = isCanceled(execHash);

            executable = !tokensRemoved && !canceled;

            // One or both of these values will be 0 so we can just add them.
            changeTimestamp = canceledChangeTimestamp + tokensRemovedChangeTimestamp;
        }
    }

    /// @notice Checks if the request is currently canceled along with a timestamp of when it may be canceled.
    /// @return tokensRemoved A boolean indicating if the request has been canceled.
    /// @return changeTimestamp A timestamp indicating when the request might have its tokens removed or added. Will be 0 if there is no removal/addition expected. It will be a timestamp if the request will have its tokens added soon (it's a resubmitted version of an uncled request).
    function areTokensRemoved(bytes32 execHash) public view returns (bool tokensRemoved, uint256 changeTimestamp) {
        uint256 removalTimestamp = requestTokenRemovalTimestamps[execHash];

        if (removalTimestamp == 0) {
            bytes32 uncle = uncles[execHash];

            // Check if this request is a resubmitted version of an uncled request.
            if (uncle.length == 0) {
                // This is a normal request, so we know tokens have/will not been removed.
                tokensRemoved = false;
                changeTimestamp = 0;
            } else {
                // This is a resubmitted version of a uncled request, so we have to check if the uncle has had its tokens removed,
                // if so, this request has its tokens.
                uint256 uncleDeathTimestamp = requestTokenRemovalTimestamps[uncle];

                if (uncleDeathTimestamp == 1) {
                    // The uncle request has had its tokens removed early.
                    tokensRemoved = true;
                    changeTimestamp = 0;
                } else {
                    // The uncled request may still be waiting for its tokens to be removed.
                    tokensRemoved = block.timestamp < uncleDeathTimestamp; // Tokens are removed for a resubmitted request if the uncled request has not had its tokens removed yet.
                    changeTimestamp = tokensRemoved
                        ? uncleDeathTimestamp // Return a timestamp if the request is still waiting to have tokens added.
                        : 0;
                }
            }
        } else {
            // Tokens have/will be removed.
            tokensRemoved = block.timestamp >= removalTimestamp; // Tokens are removed if the current timestamp is greater than the removal timestamp.
            changeTimestamp = tokensRemoved ? 0 : removalTimestamp; // Return a timestamp if the tokens have not been removed yet.
        }
    }

    /// @notice Checks if the request is currently canceled along with a timestamp of when it may be canceled.
    /// @return canceled A boolean indicating if the request has been canceled.
    /// @return changeTimestamp A timestamp indicating when the request might be canceled. Will be 0 if there is no cancel expected. It will be a timestamp if a cancel has been requested.
    function isCanceled(bytes32 execHash) public view returns (bool canceled, uint256 changeTimestamp) {
        uint256 cancelTimestamp = requestCancelTimestamps[execHash];

        if (cancelTimestamp == 0) {
            // There has been no cancel attempt.
            canceled = false;
            changeTimestamp = 0;
        } else {
            // There has been a cancel attempt.
            canceled = block.timestamp >= cancelTimestamp;
            changeTimestamp = canceled ? 0 : cancelTimestamp;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./OVM_Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library OVM_SafeERC20 {
    using SafeMath for uint256;
    using OVM_Address for address;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
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

        bytes memory returndata =
            address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
pragma solidity >0.5.0 <0.8.0;
/* Interface Imports */
import { iAbs_BaseCrossDomainMessenger } from "../../iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

/**
 * @title OVM_CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {
    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * @notice Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(
        address _sourceDomainAccount
    ) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Gets the messenger, usually from storage.  This function is exposed in case a child contract needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns(
            iAbs_BaseCrossDomainMessenger
        )
    {
        return iAbs_BaseCrossDomainMessenger(messenger);
    }

    /**
     * @notice Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _data The data to send to the target (usually calldata to a function with `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        bytes memory _data,
        uint32 _gasLimit
    ) internal {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _data, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library OVM_Address {
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iAbs_BaseCrossDomainMessenger
 */
interface iAbs_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/
    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);

    /**********************
     * Contract Variables *
     **********************/
    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

