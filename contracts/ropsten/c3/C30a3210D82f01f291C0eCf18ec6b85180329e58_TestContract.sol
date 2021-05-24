// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;


contract TestContract {

  struct ContractInfo1 {
      uint256 value11;
      uint256 value12;
  }
  struct ContractInfo2 {
      ContractInfo1 info1;
      uint256 value2;
  }

  ContractInfo2 contractInfo;

  constructor() {}

  function setData(ContractInfo2 calldata _newInfo) external {
    contractInfo = _newInfo;
  }

  function getData() external view returns (ContractInfo2 memory info2) {
    info2 = contractInfo;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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