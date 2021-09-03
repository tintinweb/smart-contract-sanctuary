// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "../interfaces/IPriceOracle.sol";

contract OracleMock is IPriceOracle {
    uint256 public price;

    function getPrice() public view override returns(uint256) {
        return price;
    }

    function setPrice(uint256 val) public {
        price = val;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2
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