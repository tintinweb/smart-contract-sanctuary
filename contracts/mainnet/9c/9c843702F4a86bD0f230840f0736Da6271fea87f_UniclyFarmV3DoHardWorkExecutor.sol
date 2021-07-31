// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUnicFarm {
    function pendingUnic(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
}

interface IV3 {
    function updatePool(uint256 _pid) external;
}

contract UniclyFarmV3DoHardWorkExecutor {

    address public constant V3 = address(0x07306aCcCB482C8619e7ed119dAA2BDF2b4389D0);
    address public constant UNIC_MASTERCHEF = address(0x4A25E4DF835B605A5848d2DB450fA600d96ee818);

    function doHardWork(uint256 threshold) external {
        for (uint256 _pid = 0; _pid < IUnicFarm(UNIC_MASTERCHEF).poolLength(); _pid++) {
            if (IUnicFarm(UNIC_MASTERCHEF).pendingUnic(_pid, V3) >= threshold) {
                IV3(V3).updatePool(_pid);
            }
        }
    }

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
  }
}