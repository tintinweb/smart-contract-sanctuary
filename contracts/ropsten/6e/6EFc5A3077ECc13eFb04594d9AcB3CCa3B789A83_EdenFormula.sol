// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/VotingPowerFormula.sol";

/**
 * @title EdenFormula
 * @dev Convert EDEN to voting power
 */
contract EdenFormula is VotingPowerFormula {
    /**
     * @notice Convert EDEN amount to voting power
     * @dev Always converts 1-1
     * @param amount token amount
     * @return voting power amount
     */
    function convertTokensToVotingPower(uint256 amount) external pure override returns (uint256) {
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract VotingPowerFormula {
   function convertTokensToVotingPower(uint256 amount) external view virtual returns (uint256);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
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