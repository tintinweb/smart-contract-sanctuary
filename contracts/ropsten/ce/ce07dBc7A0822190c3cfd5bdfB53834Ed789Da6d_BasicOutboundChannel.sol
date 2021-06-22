// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "./OutboundChannel.sol";

// BasicOutboundChannel is a basic channel that just sends messages with a nonce.
contract BasicOutboundChannel is OutboundChannel {

    uint64 public nonce;

    event Message(
        address source,
        uint64 nonce,
        bytes payload
    );

    /**
     * @dev Sends a message across the channel
     */
    function submit(address, bytes calldata payload) external override {
        nonce = nonce + 1;
        emit Message(msg.sender, nonce, payload);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

interface OutboundChannel {
    function submit(address origin, bytes calldata payload) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}