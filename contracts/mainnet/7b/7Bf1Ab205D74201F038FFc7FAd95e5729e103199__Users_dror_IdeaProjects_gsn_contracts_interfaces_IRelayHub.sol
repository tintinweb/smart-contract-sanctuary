// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./GsnTypes.sol";
import "./IStakeManager.sol";

interface IRelayHub {

    /// Emitted when a relay server registers or updates its details
    /// Looking at these events lets a client discover relay servers
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        string relayUrl);

    /// Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    // Emitted when an account withdraws funds from RelayHub.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    // Emitted when depositFor is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// Emitted when an attempt to relay a call fails and Paymaster does not accept the transaction.
    /// The actual relayed call was not executed, and the recipient not charged.
    /// @param reason contains a revert reason returned from preRelayedCall or forwarder.
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        address indexed from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason);

    // Emitted when a transaction is relayed. Note that the actual encoded function might be reverted: this will be
    // indicated in the status field.
    // Useful when monitoring a relay's operation and relayed calls to a contract.
    // Charge is the ether value deducted from the recipient's balance, paid to the relay's manager.
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        address indexed from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge);

    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    event Penalized(
        address indexed relayWorker,
        address sender,
        uint256 reward
    );

    /// Reason error codes for the TransactionRelayed event
    /// @param OK - the transaction was successfully relayed and execution successful - never included in the event
    /// @param RelayedCallFailed - the transaction was relayed, but the relayed call failed
    /// @param RejectedByPreRelayed - the transaction was not relayed due to preRelatedCall reverting
    /// @param RejectedByForwarder - the transaction was not relayed due to forwarder check (signature,nonce)
    /// @param PostRelayedFailed - the transaction was relayed and reverted due to postRelatedCall reverting
    /// @param PaymasterBalanceChanged - the transaction was relayed and reverted due to the paymaster balance change
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /// Add new worker addresses controlled by sender who must be a staked Relay Manager address.
    /// Emits a RelayWorkersAdded event.
    /// This function can be called multiple times, emitting new events
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external;

    // Balance management

    // Deposits ether for a contract, so that it can receive (and pay for) relayed transactions. Unused balance can only
    // be withdrawn by the contract itself, by calling withdraw.
    // Emits a Deposited event.
    function depositFor(address target) external payable;

    // Withdraws from an account's balance, sending it back to it. Relay managers call this to retrieve their revenue, and
    // contracts can also use it to reduce their funding.
    // Emits a Withdrawn event.
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying


    /// Relays a transaction. For this to succeed, multiple conditions must be met:
    ///  - Paymaster's "acceptRelayCall" method must succeed and not revert
    ///  - the sender must be a registered Relay Worker that the user signed
    ///  - the transaction's gas price must be equal or larger than the one that was signed by the sender
    ///  - the transaction must have enough gas to run all internal transactions if they use all gas available to them
    ///  - the Paymaster must have enough balance to pay the Relay Worker for the scenario when all gas is spent
    ///
    /// If all conditions are met, the call will be relayed and the recipient charged.
    ///
    /// Arguments:
    /// @param relayRequest - all details of the requested relayed call
    /// @param signature - client's EIP-712 signature over the relayRequest struct
    /// @param approvalData: dapp-specific data forwarded to preRelayedCall.
    ///        This value is *not* verified by the Hub. For example, it can be used to pass a signature to the Paymaster
    /// @param externalGasLimit - the value passed as gasLimit to the transaction.
    ///
    /// Emits a TransactionRelayed event.
    function relayCall(
        uint paymasterMaxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint externalGasLimit
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    function penalize(address relayWorker, address payable beneficiary) external;

    /// The fee is expressed as a base fee in wei plus percentage on actual charge.
    /// E.g. a value of 40 stands for a 40% fee, so the recipient will be
    /// charged for 1.4 times the spent amount.
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /* getters */

    /// Returns the stake manager of this RelayHub.
    function stakeManager() external view returns(IStakeManager);
    function penalizer() external view returns(address);

    /// Returns an account's deposits. It can be either a deposit of a paymaster, or a revenue of a relay manager.
    function balanceOf(address target) external view returns (uint256);

    // Minimum stake a relay can have. An attack to the network will never cost less than half this value.
    function minimumStake() external view returns (uint256);

    // Minimum unstake delay blocks of a relay manager's stake on the StakeManager
    function minimumUnstakeDelay() external view returns (uint256);

    // Maximum funds that can be deposited at once. Prevents user error by disallowing large deposits.
    function maximumRecipientDeposit() external view returns (uint256);

    //gas overhead to calculate gasUseWithoutPost
    function postOverhead() external view returns (uint256);

    // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
    function gasReserve() external view returns (uint256);

    // maximum number of worker account allowed per manager
    function maxWorkerCount() external view returns (uint256);

    function workerToManager(address worker) external view returns(address);

    function workerCount(address manager) external view returns(uint256);

    function isRelayManagerStaked(address relayManager) external view returns(bool);

    /**
    * @dev the total gas overhead of relayCall(), before the first gasleft() and after the last gasleft().
    * Assume that relay has non-zero balance (costs 15'000 more otherwise).
    */

    // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
    function gasOverhead() external view returns (uint256);

    function versionHub() external view returns (string memory);
}

