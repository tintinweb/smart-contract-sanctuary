// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 realmId) external view returns (address owner);

  function spendWealth(uint256 realmId, uint256 wealth) external;
}

contract Test {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);

  function spend(uint256 _realmId, uint256 _wealth) external {
    require(REALM.ownerOf(_realmId) == msg.sender);

    REALM.spendWealth(_realmId, _wealth);
  }
}

{
  "optimizer": {
    "enabled": true,
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