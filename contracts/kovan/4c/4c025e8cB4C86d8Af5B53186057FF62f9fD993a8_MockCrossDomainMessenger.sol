// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

contract MockCrossDomainMessenger {
    struct xDomainMessage {
        address _target;
        bytes _message;
        uint32 _gasLimit;
        address sender;
    }

    xDomainMessage currentMessage;

    function xDomainMessageSender() external view returns (address) {
        return currentMessage.sender;
    }

    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external {
        uint256 startingGas = gasleft();
        currentMessage = xDomainMessage(_target, _message, _gasLimit, msg.sender);

        // Mimic enqueue gas burn (https://github.com/ethereum-optimism/optimism/blob/master/packages/contracts/contracts/optimistic-ethereum/OVM/chain/OVM_CanonicalTransactionChain.sol) + sendMessage overhead.
        uint256 gasToConsume = (_gasLimit / 32) + 74000;
        uint256 i;
        while (startingGas - gasleft() < gasToConsume) {
            i++;
        }
    }

    function relayCurrentMessage() external {
        (bool success, bytes memory result) = currentMessage._target.call(currentMessage._message);

        require(success, _getRevertMsg(result));
        delete currentMessage;
    }

    function _getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}