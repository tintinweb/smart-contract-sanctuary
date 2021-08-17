// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ICurve} from '../../Curves/ICurve.sol';

contract RecollateralDiscountCurve is ICurve {
    function getY(uint256 percent) external pure override returns (uint256) {
        if (percent <= 0) return 33; // In %.
        else if (percent > 0 && percent <= 10e16) return 30; // In %.
        else if (percent > 10e16 && percent <= 20e16) return 27; // In %.
        else if (percent > 20e16 && percent <= 30e16) return 24; // In %.
        else if (percent > 30e16 && percent <= 40e16) return 21; // In %.
        else if (percent > 40e16 && percent <= 50e16) return 18; // In %.
        else if (percent > 50e16 && percent <= 60e16) return 15; // In %.
        else if (percent > 60e16 && percent <= 70e16) return 12; // In %.
        else if (percent > 70e16 && percent <= 80e16) return 9; // In %.
        else if (percent > 80e16 && percent <= 90e16) return 6; // In %.
        else if (percent > 90e16 && percent <= 100e16) return 3; // In %.
        else return 0; // In %.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    function getY(uint256 x) external view returns (uint256);
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