// SPDX-License-Identifier: Mixed...
pragma solidity ^0.8.0;

/// @title v1ContractData
/// @notice If you know a smarter way I could have done this feel free to email me
/// @author Sterling Crispin <[email protected]>

// I neglected to write accessors for upgrades available and used
// so I had to scrape my own metadata and put them here for v1 to v2 transfers
library v1ContractData {
    function GetUpgradeIdx() external pure returns (uint16[56] memory){
        uint16[56] memory idx = [7,13,18,31,35,61,65,71,76,83,131,140,158,169,180,182,194,200,202,206,207,213,215,234,243,252,258,272,277,282,283,305,320,322,323,324,332,337,349,357,371,384,387,389,399,400,410,411,434,435,445,453,456,470,475,476];
        return idx;
    }
    function GetUpgradeVal() external pure returns (uint8[56] memory){
        uint8[56] memory val = [1,1,3,1,3,4,1,3,2,3,2,3,4,4,2,2,1,1,1,1,4,2,3,4,4,4,4,4,1,3,3,3,1,2,3,2,4,4,1,4,4,1,4,4,1,2,4,3,2,4,2,1,3,1,1,3];
        return val;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}