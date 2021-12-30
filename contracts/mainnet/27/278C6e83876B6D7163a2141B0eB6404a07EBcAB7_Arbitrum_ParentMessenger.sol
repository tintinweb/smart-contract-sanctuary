// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../insured-bridge/avm/Arbitrum_CrossDomainEnabled.sol";
import "../interfaces/ParentMessengerInterface.sol";
import "../interfaces/ParentMessengerConsumerInterface.sol";
import "./ParentMessengerBase.sol";
import "../../common/implementation/Lockable.sol";

/**
 * @notice Sends cross chain messages from Ethereum L1 to Arbitrum L2 network.
 * @dev This contract is ownable and should be owned by the DVM governor.
 */
contract Arbitrum_ParentMessenger is
    Arbitrum_CrossDomainEnabled,
    ParentMessengerInterface,
    ParentMessengerBase,
    Lockable
{
    event SetDefaultGasLimit(uint32 newDefaultGasLimit);
    event SetDefaultMaxSubmissionCost(uint256 newMaxSubmissionCost);
    event SetDefaultGasPrice(uint256 newDefaultGasPrice);
    event SetRefundL2Address(address newRefundL2Address);
    event MessageSentToChild(
        bytes data,
        address indexed targetSpoke,
        uint256 l1CallValue,
        uint32 gasLimit,
        uint256 gasPrice,
        uint256 maxSubmissionCost,
        address refundL2Address,
        address indexed childMessenger,
        uint256 sequenceNumber
    );
    event MessageReceivedFromChild(bytes data, address indexed childMessenger, address indexed targetHub);

    // Gas limit for immediate L2 execution attempt (can be estimated via NodeInterface.estimateRetryableTicket).
    // NodeInterface precompile interface exists at L2 address 0x00000000000000000000000000000000000000C8
    uint32 public defaultGasLimit = 5_000_000;

    // Amount of ETH allocated to pay for the base submission fee. The base submission fee is a parameter unique to
    // retryable transactions; the user is charged the base submission fee to cover the storage costs of keeping their
    // ticket’s calldata in the retry buffer. (current base submission fee is queryable via
    // ArbRetryableTx.getSubmissionPrice). ArbRetryableTicket precompile interface exists at L2 address
    // 0x000000000000000000000000000000000000006E.
    uint256 public defaultMaxSubmissionCost = 0.1e18;

    // L2 Gas price bid for immediate L2 execution attempt (queryable via standard eth*gasPrice RPC)
    uint256 public defaultGasPrice = 10e9; // 10 gWei

    // This address on L2 receives extra ETH that is left over after relaying a message via the inbox.
    address public refundL2Address;

    /**
     * @notice Construct the Optimism_ParentMessenger contract.
     * @param _inbox Contract that sends generalized messages to the Arbitrum chain.
     * @param _childChainId The chain id of the Optimism L2 network this messenger should connect to.
     **/
    constructor(address _inbox, uint256 _childChainId)
        Arbitrum_CrossDomainEnabled(_inbox)
        ParentMessengerBase(_childChainId)
    {
        refundL2Address = owner();
    }

    /**
     * @notice Changes the refund address on L2 that receives excess gas or the full msg.value if the retryable
     * ticket reverts.
     * @dev The caller of this function must be the owner, which should be set to the DVM governor.
     * @param newRefundl2Address the new refund address to set. This should be set to an L2 address that is trusted by
     * the owner as it can spend Arbitrum L2 refunds for excess gas when sending transactions on Arbitrum.
     */
    function setRefundL2Address(address newRefundl2Address) public onlyOwner nonReentrant() {
        refundL2Address = newRefundl2Address;
        emit SetRefundL2Address(refundL2Address);
    }

    /**
     * @notice Changes the default gas limit that is sent along with transactions to Arbitrum.
     * @dev The caller of this function must be the owner, which should be set to the DVM governor.
     * @param newDefaultGasLimit the new L2 gas limit to be set.
     */
    function setDefaultGasLimit(uint32 newDefaultGasLimit) public onlyOwner nonReentrant() {
        defaultGasLimit = newDefaultGasLimit;
        emit SetDefaultGasLimit(newDefaultGasLimit);
    }

    /**
     * @notice Changes the default gas price that is sent along with transactions to Arbitrum.
     * @dev The caller of this function must be the owner, which should be set to the DVM governor.
     * @param newDefaultGasPrice the new L2 gas price to be set.
     */
    function setDefaultGasPrice(uint256 newDefaultGasPrice) public onlyOwner nonReentrant() {
        defaultGasPrice = newDefaultGasPrice;
        emit SetDefaultGasPrice(newDefaultGasPrice);
    }

    /**
     * @notice Changes the default max submission cost that is sent along with transactions to Arbitrum.
     * @dev The caller of this function must be the owner, which should be set to the DVM governor.
     * @param newDefaultMaxSubmissionCost the new L2 max submission cost to be set.
     */
    function setDefaultMaxSubmissionCost(uint256 newDefaultMaxSubmissionCost) public onlyOwner nonReentrant() {
        defaultMaxSubmissionCost = newDefaultMaxSubmissionCost;
        emit SetDefaultMaxSubmissionCost(newDefaultMaxSubmissionCost);
    }

    /**
     * @notice Changes the address of the oracle spoke on L2 via the child messenger.
     * @dev The caller of this function must be the owner, which should be set to the DVM governor.
     * @dev This function will only succeed if this contract has enough ETH to cover the approximate L1 call value.
     * @param newOracleSpoke the new oracle spoke address set on L2.
     */
    function setChildOracleSpoke(address newOracleSpoke) public onlyOwner nonReentrant() {
        bytes memory dataSentToChild = abi.encodeWithSignature("setOracleSpoke(address)", newOracleSpoke);
        _sendMessageToChild(dataSentToChild, childMessenger);
    }

    /**
     * @notice Changes the address of the parent messenger on L2 via the child messenger.
     * @dev The caller of this function must be the owner, which should be set to the DVM governor.
     * @dev This function will only succeed if this contract has enough ETH to cover the approximate L1 call value.
     * @param newParentMessenger the new parent messenger contract to be set on L2.
     */
    function setChildParentMessenger(address newParentMessenger) public onlyOwner nonReentrant() {
        bytes memory dataSentToChild = abi.encodeWithSignature("setParentMessenger(address)", newParentMessenger);
        _sendMessageToChild(dataSentToChild, childMessenger);
    }

    /**
     * @notice Sends a message to the child messenger via the canonical message bridge.
     * @dev The caller must be the either the OracleHub or the GovernorHub. This is to send either a
     * price or initiate a governance action to the OracleSpoke or GovernorSpoke on the child network.
     * @dev The recipient of this message is the child messenger. The messenger must implement processMessageFromParent
     * which then forwards the data to the target either the OracleSpoke or the governorSpoke depending on the caller.
     * @dev This function will only succeed if this contract has enough ETH to cover the approximate L1 call value.
     * @param data data message sent to the child messenger. Should be an encoded function call or packed data.
     */
    function sendMessageToChild(bytes memory data) external override onlyHubContract() nonReentrant() {
        address target = msg.sender == oracleHub ? oracleSpoke : governorSpoke;
        bytes memory dataSentToChild =
            abi.encodeWithSignature("processMessageFromCrossChainParent(bytes,address)", data, target);
        _sendMessageToChild(dataSentToChild, target);
    }

    /**
     * @notice Process a received message from the child messenger via the canonical message bridge.
     * @dev The caller must be the the child messenger, sent over the canonical message bridge.
     * @dev Note that only the OracleHub can receive messages from the child messenger. Therefore we can always forward
     * these messages to this contract. The OracleHub must implement processMessageFromChild to handle this message.
     * @param data data message sent from the child messenger. Should be an encoded function call or packed data.
     */
    function processMessageFromCrossChainChild(bytes memory data)
        public
        onlyFromCrossDomainAccount(childMessenger)
        nonReentrant()
    {
        ParentMessengerConsumerInterface(oracleHub).processMessageFromChild(childChainId, data);
        emit MessageReceivedFromChild(data, childMessenger, oracleHub);
    }

    /**
     * @notice This function is expected to be queried by Hub contracts that need to determine how much ETH
     * to include in msg.value when calling `sendMessageToChild`.
     * @return Amount of msg.value to include to send cross-chain message.
     */
    function getL1CallValue()
        public
        view
        override(ParentMessengerBase, ParentMessengerInterface)
        nonReentrantView()
        returns (uint256)
    {
        return _getL1CallValue();
    }

    // We need to allow this contract to receive ETH, so that it can include some msg.value amount on external calls
    // to the `sendMessageToChild` function. We shouldn't expect the owner of this contract to send
    // ETH because the owner is intended to be a contract (e.g. the Governor) and we don't want to change the
    // Governor interface.
    fallback() external payable {}

    // Used to determine how much ETH to include in msg.value when calling admin functions like
    // `setChildParentMessenger` and sending messages across the bridge.
    function _getL1CallValue() internal view returns (uint256) {
        // This could overflow if these values are set too high, but since they are configurable by trusted owner
        // we won't catch this case.
        return defaultMaxSubmissionCost + defaultGasPrice * defaultGasLimit;
    }

    // This function will only succeed if this contract has enough ETH to cover the approximate L1 call value.
    function _sendMessageToChild(bytes memory data, address target) internal {
        uint256 requiredL1CallValue = _getL1CallValue();
        require(address(this).balance >= requiredL1CallValue, "Insufficient ETH balance");

        uint256 seqNumber =
            sendTxToL2NoAliassing(
                childMessenger,
                refundL2Address,
                requiredL1CallValue,
                defaultMaxSubmissionCost,
                defaultGasLimit,
                defaultGasPrice,
                data
            );
        emit MessageSentToChild(
            data,
            target,
            requiredL1CallValue,
            defaultGasLimit,
            defaultGasPrice,
            defaultMaxSubmissionCost,
            refundL2Address,
            childMessenger,
            seqNumber
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ParentMessengerInterface.sol";

abstract contract ParentMessengerBase is Ownable, ParentMessengerInterface {
    uint256 public childChainId;

    address public childMessenger;

    address public oracleHub;
    address public governorHub;

    address public oracleSpoke;
    address public governorSpoke;

    event SetChildMessenger(address indexed childMessenger);
    event SetOracleHub(address indexed oracleHub);
    event SetGovernorHub(address indexed governorHub);
    event SetOracleSpoke(address indexed oracleSpoke);
    event SetGovernorSpoke(address indexed governorSpoke);

    modifier onlyHubContract() {
        require(msg.sender == oracleHub || msg.sender == governorHub, "Only privileged caller");
        _;
    }

    /**
     * @notice Construct the ParentMessengerBase contract.
     * @param _childChainId The chain id of the L2 network this messenger should connect to.
     **/
    constructor(uint256 _childChainId) {
        childChainId = _childChainId;
    }

    /*******************
     *  OWNER METHODS  *
     *******************/

    /**
     * @notice Changes the stored address of the child messenger, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newChildMessenger address of the new child messenger, deployed on L2.
     */
    function setChildMessenger(address newChildMessenger) public onlyOwner {
        childMessenger = newChildMessenger;
        emit SetChildMessenger(childMessenger);
    }

    /**
     * @notice Changes the stored address of the Oracle hub, deployed on L1.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newOracleHub address of the new oracle hub, deployed on L1 Ethereum.
     */
    function setOracleHub(address newOracleHub) public onlyOwner {
        oracleHub = newOracleHub;
        emit SetOracleHub(oracleHub);
    }

    /**
     * @notice Changes the stored address of the Governor hub, deployed on L1.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newGovernorHub address of the new governor hub, deployed on L1 Ethereum.
     */
    function setGovernorHub(address newGovernorHub) public onlyOwner {
        governorHub = newGovernorHub;
        emit SetGovernorHub(governorHub);
    }

    /**
     * @notice Changes the stored address of the oracle spoke, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newOracleSpoke address of the new oracle spoke, deployed on L2.
     */
    function setOracleSpoke(address newOracleSpoke) public onlyOwner {
        oracleSpoke = newOracleSpoke;
        emit SetOracleSpoke(oracleSpoke);
    }

    /**
     * @notice Changes the stored address of the governor spoke, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newGovernorSpoke address of the new governor spoke, deployed on L2.
     */
    function setGovernorSpoke(address newGovernorSpoke) public onlyOwner {
        governorSpoke = newGovernorSpoke;
        emit SetGovernorSpoke(governorSpoke);
    }

    /**
     * @notice Returns the amount of ETH required for a caller to pass as msg.value when calling `sendMessageToChild`.
     * @return The amount of ETH required for a caller to pass as msg.value when calling `sendMessageToChild`.
     */
    function getL1CallValue() external view virtual override returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ParentMessengerConsumerInterface {
    // Function called on Oracle hub to pass in data send from L2, with chain ID.
    function processMessageFromChild(uint256 chainId, bytes memory data) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ParentMessengerInterface {
    // Should send cross-chain message to Child messenger contract or revert.
    function sendMessageToChild(bytes memory data) external;

    // Informs Hub how much msg.value they need to include to call `sendMessageToChild`.
    function getL1CallValue() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IBridge {
    function activeOutbox() external view returns (address);
}

interface iArbitrum_Inbox {
    // Retryable tickets are the Arbitrum protocol’s canonical method for passing generalized messages from Ethereum to
    // Arbitrum. A retryable ticket is an L2 message encoded and delivered by L1; if gas is provided, it will be executed
    // immediately. If no gas is provided or the execution reverts, it will be placed in the L2 retry buffer,
    // where any user can re-execute for some fixed period (roughly one week).
    // Retryable tickets are created by calling Inbox.createRetryableTicket.
    // More details here: https://developer.offchainlabs.com/docs/l1_l2_messages#ethereum-to-arbitrum-retryable-tickets
    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function bridge() external view returns (address);
}

// Copied logic from https://github.com/OffchainLabs/arbitrum-tutorials/blob/4761fa1ba1f1eca95e8c03f24f1442ed5aecd8bd/packages/arb-shared-dependencies/contracts/Outbox.sol
// with changes only to the solidity version.

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface iArbitrum_Outbox {
    function l2ToL1Sender() external view returns (address);
}

// Copied logic from https://github.com/makerdao/arbitrum-dai-bridge/blob/34acc39bc6f3a2da0a837ea3c5dbc634ec61c7de/contracts/l1/L1CrossDomainEnabled.sol
// with a change to the solidity version.
pragma solidity ^0.8.0;

import "../../external/avm/interfaces/iArbitrum_Inbox.sol";
import "../../external/avm/interfaces/iArbitrum_Outbox.sol";

abstract contract Arbitrum_CrossDomainEnabled {
    iArbitrum_Inbox public immutable inbox;

    /**
     * @param _inbox Contract that sends generalized messages to the Arbitrum chain.
     */
    constructor(address _inbox) {
        inbox = iArbitrum_Inbox(_inbox);
    }

    // More details about retryable ticket parameters here: https://developer.offchainlabs.com/docs/l1_l2_messages#parameters
    // This function will not apply aliassing to the `user` address on L2.
    // Note: If `l1CallValue > 0`, then this contract must contain at least that much ETH to send as msg.value to the
    // inbox.
    function sendTxToL2NoAliassing(
        address target, // Address where transaction will initiate on L2.
        address user, // Address where excess gas is credited on L2.
        uint256 l1CallValue, // msg.value deposited to `user` on L2.
        uint256 maxSubmissionCost, // Amount of ETH allocated to pay for base submission fee. The user is charged this
        // fee to cover the storage costs of keeping their retryable ticket's calldata in the retry buffer. This should
        // also cover the `l2CallValue`, but we set that to 0. This amount is proportional to the size of `data`.
        uint256 maxGas, // Gas limit for immediate L2 execution attempt.
        uint256 gasPriceBid, // L2 gas price bid for immediate L2 execution attempt.
        bytes memory data // ABI encoded data to send to target.
    ) internal returns (uint256) {
        // createRetryableTicket API: https://developer.offchainlabs.com/docs/sol_contract_docs/md_docs/arb-bridge-eth/bridge/inbox#createretryableticketaddress-destaddr-uint256-l2callvalue-uint256-maxsubmissioncost-address-excessfeerefundaddress-address-callvaluerefundaddress-uint256-maxgas-uint256-gaspricebid-bytes-data-%E2%86%92-uint256-external
        // - address destAddr: destination L2 contract address
        // - uint256 l2CallValue: call value for retryable L2 message
        // - uint256 maxSubmissionCost: Max gas deducted from user's L2 balance to cover base submission fee
        // - address excessFeeRefundAddress: maxgas x gasprice - execution cost gets credited here on L2
        // - address callValueRefundAddress: l2CallValue gets credited here on L2 if retryable txn times out or gets cancelled
        // - uint256 maxGas: Max gas deducted from user's L2 balance to cover L2 execution
        // - uint256 gasPriceBid: price bid for L2 execution
        // - bytes data: ABI encoded data of L2 message
        uint256 seqNum =
            inbox.createRetryableTicketNoRefundAliasRewrite{ value: l1CallValue }(
                target,
                0, // we always assume that l2CallValue = 0
                maxSubmissionCost,
                user,
                user,
                maxGas,
                gasPriceBid,
                data
            );
        return seqNum;
    }

    // Copied mostly from: https://github.com/makerdao/arbitrum-dai-bridge/blob/34acc39bc6f3a2da0a837ea3c5dbc634ec61c7de/contracts/l1/L1CrossDomainEnabled.sol#L31
    modifier onlyFromCrossDomainAccount(address l2Counterpart) {
        // a message coming from the counterpart gateway was executed by the bridge
        IBridge bridge = IBridge(inbox.bridge());
        require(msg.sender == address(bridge), "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = iArbitrum_Outbox(bridge.activeOutbox()).l2ToL1Sender();
        require(l2ToL1Sender == l2Counterpart, "ONLY_COUNTERPART_GATEWAY");
        _;
    }
}