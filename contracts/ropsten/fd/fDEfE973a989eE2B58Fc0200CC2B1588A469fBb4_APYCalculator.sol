pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "./interfaces/IAPYCalculator.sol";

contract APYCalculator is IAPYCalculator {
    uint256 amount1;

    constructor(uint256 _amount) public {
        amount1 = _amount;
    }

    // returns the value of 3000$ of the given token for rASKO Farm reward calculations
    function valueOf3000(address token) public override returns(uint256 amount){
        return amount1;
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

interface IAPYCalculator {
    function valueOf3000(address token) external returns(uint256 amount);
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
  "libraries": {}
}