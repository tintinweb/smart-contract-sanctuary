// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface MockVRFConsumer {
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

contract MockVRFCoordinator {
  function fulfillRandomness(address vrfConsumer, uint256 randomness) external {
    MockVRFConsumer(vrfConsumer).rawFulfillRandomness(bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), randomness);
  }
}

