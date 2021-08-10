// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract RandomGenUtils {
    function randomGen(uint256 seed, uint256 max) internal view returns (uint256 randomNumber) {
        return (uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, block.difficulty, seed)
            )
        ) % max);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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