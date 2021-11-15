// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@eth-optimism/contracts/iOVM/bridge/messaging/iOVM_CrossDomainMessenger.sol";

contract MockCrossDomainMessenger is iOVM_CrossDomainMessenger {
    address public latestTarget;
    bytes public latestMessage;
    uint32 public latestGasLimit;
    address public latestSender;

    function xDomainMessageSender() external view override returns (address) {
        return latestSender;
    }

    function sendMessageWithSender(
        address _target,
        bytes memory _message,
        uint32 _gasLimit,
        address _sender
    ) public {
        uint256 startingGas = gasleft();
        latestTarget = _target;
        latestMessage = _message;
        latestGasLimit = _gasLimit;
        latestSender = _sender;

        // Mimic enqueue gas burn (https://github.com/ethereum-optimism/optimism/blob/master/packages/contracts/contracts/optimistic-ethereum/OVM/chain/OVM_CanonicalTransactionChain.sol) + sendMessage overhead.
        uint256 gasToConsume = (_gasLimit / 32) + 74000;
        uint256 i;
        while (startingGas - gasleft() < gasToConsume) {
            i++;
        }
    }

    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external override {
        sendMessageWithSender(_target, _message, _gasLimit, msg.sender);
    }

    function relayCurrentMessage() external {
        (bool success, bytes memory result) = latestTarget.call(latestMessage);

        require(success, _getRevertMsg(result));
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_CrossDomainMessenger
 */
interface iOVM_CrossDomainMessenger {

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

