// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUBI} from "./interfaces/IUBI.sol";

contract UbiBurner {
    event Burn(address token, uint256 amount);

    function burn(address _address, uint256 _amount) public {
      IUBI(_address).burn(_amount);
      emit Burn(_address, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IUBI {
    function burn(uint256 _amount) external;
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
  "libraries": {}
}