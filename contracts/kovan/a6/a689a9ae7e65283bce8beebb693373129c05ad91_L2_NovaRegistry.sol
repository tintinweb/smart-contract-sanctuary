// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "ovm-safeerc20/OVM_SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";
import "./external/Multicall.sol";
import "./external/DSAuth.sol";
import "./external/LowGasSafeMath.sol";

import "./libraries/NovaExecHashLib.sol";

contract L2_NovaRegistry is DSAuth, OVM_CrossDomainEnabled, ReentrancyGuard, Multicall {
    using OVM_SafeERC20 for IERC20;
    using LowGasSafeMath for uint256;

    /*///////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The minimum delay between when `unlockTokens` and `withdrawTokens` can be called.
    uint256 public constant MIN_UNLOCK_DELAY_SECONDS = 300;

    /// @notice The ERC20 users must use to pay for the L1 gas usage of request.
    IERC20 public immutable ETH;

    /// @param _ETH An ERC20 ETH you would like users to pay for gas with.
    /// @param _messenger The L2 xDomainMessenger contract you want to use to recieve messages.
    constructor(address _ETH, address _messenger) OVM_CrossDomainEnabled(_messenger) {
        ETH = IERC20(_ETH);
    }

    /*///////////////////////////////////////////////////////////////
                    EXECUTION MANAGER ADDRESS STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the only contract authorized to make cross domain calls to `execCompleted`.
    address public L1_NovaExecutionManagerAddress;

    /// @notice Authorizes the `_L1_NovaExecutionManagerAddress` to make cross domain calls to `execCompleted`.
    /// @notice Each call to `connectExecutionManager` overrides the previous value, you cannot have multiple authorized execution managers at once.
    /// @param _L1_NovaExecutionManagerAddress The address to be authorized to make cross domain calls to `execCompleted`.
    function connectExecutionManager(address _L1_NovaExecutionManagerAddress) external auth {
        L1_NovaExecutionManagerAddress = _L1_NovaExecutionManagerAddress;
    }

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `requestExec` is called.
    /// @param nonce The nonce assigned to this request.
    event RequestExec(bytes32 indexed execHash, address indexed strategy, uint256 nonce);

    /// @notice Emitted when `execCompleted` is called.
    event ExecCompleted(bytes32 indexed execHash, address indexed rewardRecipient, bool reverted, uint256 gasUsed);

    /// @notice Emitted when `claim` is called.
    event ClaimInputTokens(bytes32 indexed execHash);

    /// @notice Emitted when `withdrawTokens` is called.
    event WithdrawTokens(bytes32 indexed execHash);

    /// @notice Emitted when `unlockTokens` is called.
    /// @param unlockTimestamp When the unlock will set into effect and the creator will be able to call `withdrawTokens`.
    event UnlockTokens(bytes32 indexed execHash, uint256 unlockTimestamp);

    /// @notice Emitted when `relockTokens` is called.
    event RelockTokens(bytes32 indexed execHash);

    /// @notice Emitted when `speedUpRequest` is called.
    /// @param newExecHash The execHash of the resubmitted request (copy of its uncle with an updated gasPrice).
    /// @param newNonce The nonce of the resubmitted request.
    /// @param changeTimestamp When the uncled request (`execHash`) will have its tokens transfered to the resubmitted request (`newExecHash`).
    event SpeedUpRequest(
        bytes32 indexed execHash,
        bytes32 indexed newExecHash,
        uint256 newNonce,
        uint256 changeTimestamp
    );

    /*///////////////////////////////////////////////////////////////
                       GLOBAL NONCE COUNTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The most recent nonce assigned to an execution request.
    uint256 public systemNonce;

    /*///////////////////////////////////////////////////////////////
                           PER REQUEST STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps execHashes to the creator of each request.
    mapping(bytes32 => address) public getRequestCreator;
    /// @notice Maps execHashes to the address of the strategy associated with the request.
    mapping(bytes32 => address) public getRequestStrategy;
    /// @notice Maps execHashes to the calldata associated with the request.
    mapping(bytes32 => bytes) public getRequestCalldata;
    /// @notice Maps execHashes to the gas limit a relayer should use to execute the request.
    mapping(bytes32 => uint64) public getRequestGasLimit;
    /// @notice Maps execHashes to the gas price a relayer must use to execute the request.
    mapping(bytes32 => uint256) public getRequestGasPrice;
    /// @notice Maps execHashes to the additional tip in wei relayers will receive for executing them.
    mapping(bytes32 => uint256) public getRequestTip;
    /// @notice Maps execHashes to the nonce of each request.
    /// @notice This is just for convenience, does not need to be on-chain.
    mapping(bytes32 => uint256) public getRequestNonce;

    /// @notice A token/amount pair that a relayer will need on L1 to execute the request (and will be returned to them on L2).
    /// @param l2Token The token on L2 to transfer to the relayer upon a successful execution.
    /// @param amount The amount of the `l2Token` to the relayer upon a successful execution (scaled by the `l2Token`'s decimals).
    /// @dev Relayers may have to reference a registry/list of some sort to determine the equivalent L1 token they will need.
    /// @dev The decimal scheme may not align between the L1 and L2 tokens, a relayer should check via off-chain logic.
    struct InputToken {
        IERC20 l2Token;
        uint256 amount;
    }

    /// @notice Maps execHashes to the input tokens a relayer must have to execute the request.
    mapping(bytes32 => InputToken[]) public requestInputTokens;

    function getRequestInputTokens(bytes32 execHash) external view returns (InputToken[] memory) {
        return requestInputTokens[execHash];
    }

    /*///////////////////////////////////////////////////////////////
                       INPUT TOKEN RECIPIENT STORAGE
    //////////////////////////////////////////////////////////////*/

    struct InputTokenRecipientData {
        address recipient;
        bool isClaimed;
    }

    /// @notice Maps execHashes to the address of the user who recieved the input tokens for executing or withdrawing the request.
    /// @notice Will be address(0) if no one has executed or withdrawn the request yet.
    mapping(bytes32 => InputTokenRecipientData) public getRequestInputTokenRecipient;

    /*///////////////////////////////////////////////////////////////
                              UNLOCK STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps execHashes to a timestamp representing when the request will have its tokens unlocked, meaning the creator can withdraw their bounties/inputs.
    /// @notice Will be 0 if no unlock has been scheduled.
    mapping(bytes32 => uint256) public getRequestUnlockTimestamp;

    /*///////////////////////////////////////////////////////////////
                              UNCLE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps execHashes which represent resubmitted requests (via speedUpRequest) to their corresponding "uncled" request's execHash.
    /// @notice An uncled request is a request that has had its tokens removed via `speedUpRequest` in favor of a resubmitted request generated in the transaction.
    /// @notice Will be bytes32("") if `speedUpRequest` has not been called with the `execHash`.
    mapping(bytes32 => bytes32) public getRequestUncle;

    /// @notice Maps execHashes to a timestamp representing when the request will be disabled and replaced by a re-submitted request with a higher gas price (via `speedUpRequest`).
    /// @notice Will be 0 if `speedUpRequest` has not been called with the `execHash`.
    mapping(bytes32 => uint256) public getRequestUncleDeathTimestamp;

    /*///////////////////////////////////////////////////////////////
                           STATEFUL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Request `strategy` to be executed with `l1calldata`.
    /// @notice The caller must approve `(gasPrice * gasLimit) + tip` of `ETH` before calling.
    /// @param strategy The address of the "strategy" contract on L1 a relayer should call with `calldata`.
    /// @param l1calldata The abi encoded calldata a relayer should call the `strategy` with on L1.
    /// @param gasLimit The gas limit a relayer should use on L1.
    /// @param gasPrice The gas price (in wei) a relayer should use on L1.
    /// @param tip The additional wei to pay as a tip for any relayer that executes this request.
    /// @param inputTokens An array of 5 or less token/amount pairs that a relayer will need on L1 to execute the request (and will be returned to them on L2). `inputTokens` will not be awarded if the `strategy` reverts on L1.
    /// @return execHash The "execHash" (unique identifier) for this request.
    function requestExec(
        address strategy,
        bytes calldata l1calldata,
        uint64 gasLimit,
        uint256 gasPrice,
        uint256 tip,
        InputToken[] calldata inputTokens
    ) public nonReentrant auth returns (bytes32 execHash) {
        // Do not allow more than 5 input tokens.
        require(inputTokens.length <= 5, "TOO_MANY_INPUTS");

        // Increment global nonce.
        systemNonce += 1;
        // Compute execHash for this request.
        execHash = NovaExecHashLib.compute({
            nonce: systemNonce,
            strategy: strategy,
            l1calldata: l1calldata,
            gasPrice: gasPrice
        });

        emit RequestExec(execHash, strategy, systemNonce);

        // Store all critical request data.
        getRequestCreator[execHash] = msg.sender;
        getRequestStrategy[execHash] = strategy;
        getRequestCalldata[execHash] = l1calldata;
        getRequestGasLimit[execHash] = gasLimit;
        getRequestGasPrice[execHash] = gasPrice;
        getRequestTip[execHash] = tip;
        // Storing the nonce is just for convenience; it does not need to be on-chain.
        getRequestNonce[execHash] = systemNonce;

        // Transfer in ETH to pay for max gas usage + tip.
        ETH.safeTransferFrom(msg.sender, address(this), (gasLimit * gasPrice) + tip);

        // Transfer input tokens in that the msg.sender has approved.
        for (uint256 i = 0; i < inputTokens.length; i++) {
            inputTokens[i].l2Token.safeTransferFrom(msg.sender, address(this), inputTokens[i].amount);

            // Copy over this index to the requestInputTokens mapping (we can't just put a calldata/memory array directly into storage so we have to go index by index).
            requestInputTokens[execHash].push(inputTokens[i]);
        }
    }

    /// @notice Calls `requestExec` with all relevant parameters along with calling `unlockTokens` with the `autoUnlockDelay` argument.
    /// @dev See `requestExec` and `unlockTokens` for more information.
    function requestExecWithTimeout(
        address strategy,
        bytes calldata l1calldata,
        uint64 gasLimit,
        uint256 gasPrice,
        uint256 tip,
        InputToken[] calldata inputTokens,
        uint256 autoUnlockDelay
    ) external returns (bytes32 execHash) {
        execHash = requestExec(strategy, l1calldata, gasLimit, gasPrice, tip, inputTokens);

        unlockTokens(execHash, autoUnlockDelay);
    }

    /// @notice Claims input tokens earned from executing a request.
    /// @notice Request creators must also call this function if their request reverted (as input tokens are not sent to relayers if the request reverts).
    /// @param execHash The hash of the executed request.
    function claimInputTokens(bytes32 execHash) external nonReentrant auth {
        InputTokenRecipientData memory inputTokenRecipientData = getRequestInputTokenRecipient[execHash];

        // Ensure that the tokens have not already been claimed.
        require(!inputTokenRecipientData.isClaimed, "ALREADY_CLAIMED");

        InputToken[] memory inputTokens = requestInputTokens[execHash];

        emit ClaimInputTokens(execHash);

        // Loop over each input token to transfer it to the recipient.
        for (uint256 i = 0; i < inputTokens.length; i++) {
            inputTokens[i].l2Token.transfer(inputTokenRecipientData.recipient, inputTokens[i].amount);
        }
    }

    /// @notice Unlocks a request's tokens with a delay. Once the delay has passed anyone may call `withdrawTokens` on behalf of the user to recieve their bounties/input tokens back.
    /// @notice msg.sender must be the creator of the request associated with the `execHash`.
    /// @param execHash The unique hash of the request to unlock.
    /// @param unlockDelaySeconds The delay in seconds until the creator can withdraw their tokens. Must be greater than or equal to `MIN_UNLOCK_DELAY_SECONDS`.
    function unlockTokens(bytes32 execHash, uint256 unlockDelaySeconds) public auth {
        // Ensure the request has not already had its tokens removed.
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");
        // Make sure that an unlock is not arleady scheduled.
        require(getRequestUnlockTimestamp[execHash] == 0, "UNLOCK_ALREADY_SCHEDULED");
        // Make sure the caller is the creator of the request.
        require(getRequestCreator[execHash] == msg.sender, "NOT_CREATOR");
        // Make sure the delay is greater than the minimum.
        require(unlockDelaySeconds >= MIN_UNLOCK_DELAY_SECONDS, "DELAY_TOO_SMALL");

        // Set the delay timestamp to (current timestamp + the delay)
        uint256 timestamp = block.timestamp.add(unlockDelaySeconds);
        getRequestUnlockTimestamp[execHash] = timestamp;

        emit UnlockTokens(execHash, timestamp);
    }

    /// @notice Cancels a scheduled unlock.
    /// @param execHash The unique hash of the request which has an unlock scheduled.
    function relockTokens(bytes32 execHash) external auth {
        // Ensure the request has not already had its tokens removed.
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");
        // Make sure the caller is the creator of the request.
        require(getRequestCreator[execHash] == msg.sender, "NOT_CREATOR");

        // Reset the unlock timestamp to 0.
        delete getRequestUnlockTimestamp[execHash];

        emit RelockTokens(execHash);
    }

    /// @notice Withdraws tokens (input/gas/bounties) from an unlocked request.
    /// @notice The creator of the request associated with `execHash` must call `unlockTokens` and wait the `unlockDelaySeconds` they specified before calling `withdrawTokens`.
    /// @notice Anyone may call this method on behalf of another user but the tokens will still go the creator of the request associated with the `execHash`.
    /// @param execHash The unique hash of the request to withdraw from.
    function withdrawTokens(bytes32 execHash) external nonReentrant auth {
        // Ensure that the tokens are unlocked.
        (bool tokensUnlocked, ) = areTokensUnlocked(execHash);
        require(tokensUnlocked, "NOT_UNLOCKED");
        // Ensure that the tokens have not already been removed.
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");

        emit WithdrawTokens(execHash);

        address creator = getRequestCreator[execHash];
        InputToken[] memory inputTokens = requestInputTokens[execHash];

        // Store that the request has had its tokens removed.
        getRequestInputTokenRecipient[execHash].isClaimed = true;

        // Transfer the ETH which would have been used for (gas + tip) back to the creator.
        ETH.transfer(creator, (getRequestGasPrice[execHash] * getRequestGasLimit[execHash]) + getRequestTip[execHash]);

        // Transfer input tokens back to the creator.
        for (uint256 i = 0; i < inputTokens.length; i++) {
            inputTokens[i].l2Token.transfer(creator, inputTokens[i].amount);
        }
    }

    /// @notice Resubmit a request with a higher gas price.
    /// @notice This will "uncle" the `execHash` which means after `MIN_UNLOCK_DELAY_SECONDS` it will be disabled and the `newExecHash` will be enabled.
    /// @notice msg.sender must be the creator of the request associated with the `execHash`.
    /// @param execHash The execHash of the request you wish to resubmit with a higher gas price.
    /// @param gasPrice The updated gas price to use for the resubmitted request.
    /// @return newExecHash The unique identifier for the resubmitted request.
    function speedUpRequest(bytes32 execHash, uint256 gasPrice) external auth returns (bytes32 newExecHash) {
        // Ensure that msg.sender is the creator of the request.
        require(getRequestCreator[execHash] == msg.sender, "NOT_CREATOR");
        // Ensure tokens have not already been removed.
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");

        // Get the previous gas price.
        uint256 previousGasPrice = getRequestGasPrice[execHash];

        // Ensure that the new gas price is greater than the previous.
        require(gasPrice > previousGasPrice, "LESS_THAN_PREVIOUS_GAS_PRICE");

        // Get the timestamp when the `execHash` would become uncled if this `speedUpRequest` call succeeds.
        uint256 switchTimestamp = MIN_UNLOCK_DELAY_SECONDS + block.timestamp;

        // Ensure that if there is a token unlock scheduled it would be after the switch.
        // Tokens cannot be withdrawn after the switch which is why it's safe if they unlock after.
        uint256 tokenUnlockTimestamp = getRequestUnlockTimestamp[execHash];
        require(tokenUnlockTimestamp == 0 || tokenUnlockTimestamp > block.timestamp, "UNLOCK_BEFORE_SWITCH");

        // Get more data about the previous request.
        address previousStrategy = getRequestStrategy[execHash];
        bytes memory previousCalldata = getRequestCalldata[execHash];
        uint64 previousGasLimit = getRequestGasLimit[execHash];

        // Generate a new execHash for the resubmitted request.
        systemNonce += 1;
        newExecHash = NovaExecHashLib.compute({
            nonce: systemNonce,
            strategy: previousStrategy,
            l1calldata: previousCalldata,
            gasPrice: gasPrice
        });

        // Fill out data for the resubmitted request.
        getRequestCreator[newExecHash] = msg.sender;
        getRequestStrategy[newExecHash] = previousStrategy;
        getRequestCalldata[newExecHash] = previousCalldata;
        getRequestGasLimit[newExecHash] = previousGasLimit;
        getRequestGasPrice[newExecHash] = gasPrice;
        // Storing the nonce is just for convenience; it does not need to be on-chain.
        getRequestNonce[execHash] = systemNonce;

        // Map the resubmitted request to its uncle.
        getRequestUncle[newExecHash] = execHash;

        // Set the uncled request to expire in MIN_UNLOCK_DELAY_SECONDS.
        getRequestUncleDeathTimestamp[execHash] = switchTimestamp;

        emit SpeedUpRequest(execHash, newExecHash, systemNonce, switchTimestamp);

        // Transfer in additional ETH to pay for the new gas limit.
        ETH.safeTransferFrom(msg.sender, address(this), (gasPrice - previousGasPrice) * previousGasLimit);
    }

    /*///////////////////////////////////////////////////////////////
                  CROSS DOMAIN MESSENGER ONLY FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @dev Distributes inputs/tips to the relayer as a result of a successful execution. Only the linked L1_NovaExecutionManager can call via the cross domain messenger.
    /// @param execHash The computed execHash of the execution.
    /// @param rewardRecipient The address the relayer specified to be the recipient of the tokens on L2.
    /// @param reverted If the strategy reverted on L1 during execution.
    /// @param gasUsed The amount of gas used by the execution tx on L1.
    function execCompleted(
        bytes32 execHash,
        address rewardRecipient,
        bool reverted,
        uint64 gasUsed
    ) external nonReentrant onlyFromCrossDomainAccount(L1_NovaExecutionManagerAddress) {
        // Ensure that the tokens have not already been removed.
        (bool tokensRemoved, ) = areTokensRemoved(execHash);
        require(!tokensRemoved, "TOKENS_REMOVED");

        uint256 gasLimit = getRequestGasLimit[execHash];
        uint256 gasPrice = getRequestGasPrice[execHash];
        uint256 tip = getRequestTip[execHash];
        address creator = getRequestCreator[execHash];

        // The amount of ETH to pay for the gas used (capped at the gas limit).
        uint256 gasPayment = gasPrice * (gasUsed > gasLimit ? gasLimit : gasUsed);
        // The amount of ETH to pay as the tip to the rewardRecepient.
        uint256 recipientTip = reverted ? (tip * 7) / 10 : tip;

        // Refund the creator any unused gas + refund some of the tip if reverted
        ETH.transfer(creator, ((gasLimit * gasPrice) - gasPayment) + (tip - recipientTip));
        // Pay the recipient the gas payment + the tip.
        ETH.transfer(rewardRecipient, gasPayment + recipientTip);

        // Give the proper input token recipient the ability to claim the tokens.
        getRequestInputTokenRecipient[execHash].recipient = reverted ? creator : rewardRecipient;

        emit ExecCompleted(execHash, rewardRecipient, reverted, gasUsed);
    }

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the request has had one of its tokens removed.
    /// @param execHash The request to check.
    /// @return tokensRemoved A boolean indicating if the request has had one of its tokens removed.
    /// @return changeTimestamp A timestamp indicating when the request might have one of its tokens removed or added. Will be 0 if there is no removal/addition expected. It will be a timestamp if the request will have its tokens added soon (it's a resubmitted version of an uncled request).
    function areTokensRemoved(bytes32 execHash) public view returns (bool tokensRemoved, uint256 changeTimestamp) {
        address inputTokenRecipient = getRequestInputTokenRecipient[execHash].recipient;

        if (inputTokenRecipient == address(0)) {
            // This request has not been executed and tokens have not been withdrawn,
            // but it may be a resubmitted request so we need to check its uncle to make sure it has not been executed and it has already died.
            bytes32 uncle = getRequestUncle[execHash];
            if (uncle == "") {
                // This is a normal request, so we know tokens have/will not been removed.
                tokensRemoved = false;
                changeTimestamp = 0;
            } else {
                // This is a resubmitted version of a uncled request, so we have to check if the uncle has "died" yet.
                uint256 uncleDeathTimestamp = getRequestUncleDeathTimestamp[uncle];

                tokensRemoved = uncleDeathTimestamp > block.timestamp; // Tokens are removed for a resubmitted request if the uncled request has not died yet.
                changeTimestamp = tokensRemoved
                    ? uncleDeathTimestamp // Return a timestamp if the request is still waiting to have tokens added.
                    : 0;
            }
        } else {
            // Request has been executed or tokens withdrawn.
            tokensRemoved = true;
            changeTimestamp = 0;
        }
    }

    /// @notice Checks if the request is scheduled to have its tokens unlocked.
    /// @param execHash The request to check.
    /// @return unlocked A boolean indicating if the request has had its tokens unlocked.
    /// @return changeTimestamp A timestamp indicating when the request might have its tokens unlocked. Will be 0 if there is no unlock is scheduled. It will be a timestamp if an unlock has been scheduled.
    function areTokensUnlocked(bytes32 execHash) public view returns (bool unlocked, uint256 changeTimestamp) {
        uint256 tokenUnlockTimestamp = getRequestUnlockTimestamp[execHash];

        if (tokenUnlockTimestamp == 0) {
            // There is no unlock scheduled.
            unlocked = false;
            changeTimestamp = 0;
        } else {
            // There has been an unlock scheduled/completed.
            unlocked = block.timestamp >= tokenUnlockTimestamp;
            changeTimestamp = unlocked ? 0 : tokenUnlockTimestamp;
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;


    /***************
     * Constructor *
     ***************/    

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
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
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used. 
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns (
            iAbs_BaseCrossDomainMessenger
        )
    {
        return iAbs_BaseCrossDomainMessenger(messenger);
    }

    /**
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _data The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        bytes memory _data,
        uint32 _gasLimit
    )
        internal
    {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _data, _gasLimit);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

/// @notice Enables calling multiple methods in a single call to the contract.
/// @author Modified from uniswap-v3-periphery (https://github.com/Uniswap/uniswap-v3-periphery).
abstract contract Multicall {
    /// @notice Call multiple functions in the current contract and return the data from all of them.
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @param revertOnFail If true, if a call reverts, this function will revert.
    /// @return results The results from each of the calls passed in via data, if the call reverted (and revertOnFail is true) then it will be the revert data.
    function multicall(bytes[] calldata data, bool revertOnFail) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    /// @notice Call multiple functions in the current contract.
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract.
    /// @param revertOnFail If true, if a call reverts, this function will revert.
    function lowGasMulticall(bytes[] calldata data, bool revertOnFail) external payable {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
        }
    }

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }
}

/// @notice Interface used by DAI/CHAI for permit.
/// @author uniswap-v3-periphery (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/external/IERC20PermitAllowed.sol).
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GNU-3
pragma solidity 0.7.6;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author DappHub (https://github.com/dapphub/ds-auth)
abstract contract DSAuth {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);

    DSAuthority public authority;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) external auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) external auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

interface DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Optimized overflow and underflow safe math operations.
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost.
/// @author Uniswap (https://github.com/Uniswap/uniswap-v3-core)
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

/// @notice Utility library to compute a Nova execHash from a nonce, strategy address, calldata and gas price.
library NovaExecHashLib {
    /// @dev Computes a Nova execHash from a nonce, strategy address, calldata and gas price.
    /// @return A Nova execHash.
    function compute(
        uint256 nonce,
        address strategy,
        bytes memory l1calldata,
        uint256 gasPrice
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nonce, strategy, l1calldata, gasPrice));
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

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    event FailedRelayedMessage(bytes32 msgHash);


    /*************
     * Variables *
     *************/

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

