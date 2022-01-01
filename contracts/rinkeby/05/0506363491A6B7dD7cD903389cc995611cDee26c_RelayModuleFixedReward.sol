// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/Safe.sol";

/// @title Relay Module with fixed Reward
/// @author Richard Meissner - @rmeissner
contract RelayModuleFixedReward {

    string public constant VERSION = "1.0.0";

    error RewardPaymentFailure();

    error RelayExecutionFailure();

    error InvalidRelayData();

    uint256 public immutable reward;
    bytes4 public immutable relayMethod;

    constructor(uint256 _reward, bytes4 _relayMethod) {
        reward = _reward;
        relayMethod = _relayMethod;
    }

    function relayTransaction(
        address relayTarget,
        bytes calldata relayData,
        address rewardReceiver
    ) public {
        // Transfer reward before execution to make sure that reward can be paid, revert otherwise
        if (!Safe(relayTarget).execTransactionFromModule(rewardReceiver, reward, "", 0)) revert RewardPaymentFailure();

        // Check relay data to avoid that module can be abused for arbitrary interactions
        if (bytes4(relayData[:4]) != relayMethod) revert InvalidRelayData();

        // Perform relay call and require success to avoid that user paid for failed transaction
        (bool success, ) = relayTarget.call(relayData);
        if (!success) revert RelayExecutionFailure();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface Safe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation
    ) external returns (bool success);

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);
}