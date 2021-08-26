// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {PokeMeReady} from "./PokeMeReady.sol";

contract Counter is PokeMeReady {
    uint256 public count;
    uint256 public lastExecuted;

    // solhint-disable-next-line no-empty-blocks
    constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

    // solhint-disable not-rely-on-time
    function increaseCount(uint256 amount) external onlyPokeMe {
        require(
            ((block.timestamp - lastExecuted) > 180),
            "Counter: increaseCount: Time not elapsed"
        );

        count += amount;
        lastExecuted = block.timestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract PokeMeReady {
    address payable public immutable pokeMe;

    constructor(address payable _pokeMe) {
        pokeMe = _pokeMe;
    }

    modifier onlyPokeMe() {
        require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
        _;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
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