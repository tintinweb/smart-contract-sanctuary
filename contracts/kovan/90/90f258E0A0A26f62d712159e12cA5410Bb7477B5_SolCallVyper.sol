// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/ICurvePool.sol";
contract SolCallVyper { 
    address public curve;
    constructor(address _curve) { 
        curve = _curve;
    }

    function call(uint256[4] memory _param) external { 
        ICurvePool(curve).add_liquidity(_param, 10);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ICurvePool { 
    function add_liquidity(uint256[4] memory, uint256) external returns(uint256);
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