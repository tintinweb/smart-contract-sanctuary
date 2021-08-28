pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./Utils.sol";

contract MyContract {
    using Utils for UtilType;
    UtilType state;

    function foo(uint256 extra) public {
        state.addExtra(extra);
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./UtilType.sol";

library Utils {
    function addExtra(UtilType storage state, uint256 extra) external {
        state.var1 += extra;
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

struct UtilType {
    uint256 var1;
    bool var2;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "contracts/Utils.sol": {
      "Utils": "0x0b77b37e46ce7e1ab5946ef94f2b052b0a6e5862"
    }
  }
}