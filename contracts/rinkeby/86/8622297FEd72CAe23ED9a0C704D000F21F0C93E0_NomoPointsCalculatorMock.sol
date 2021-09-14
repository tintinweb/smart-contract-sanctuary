// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract NomoPointsCalculatorMock {
    mapping(uint256 => uint256) points;

    constructor() {}

    function calculatePoints(uint256 _tokenId, uint256) external view returns (uint256) {
        return points[_tokenId];
    }

    function setPoints(uint256 _tokenId, uint256 _points) external {
        points[_tokenId] = _points;
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