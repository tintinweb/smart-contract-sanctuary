// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface iOVM_L1ETHGateway {
    function donateETH()
    external
    payable;
}

contract MigrateETH {
    function migrateEth(address _to) public {
        require(msg.sender == 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A);
        uint256 balance = address(this).balance;
        iOVM_L1ETHGateway(_to).donateETH{value:balance}();
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