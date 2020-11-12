{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/swerve/SwerveRegistry.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.6.5;\n\nimport { Ownable } from \"../../Ownable.sol\";\n\n\nstruct PoolInfo {\n    address swap;       // stableswap contract address.\n    uint256 totalCoins; // Number of coins used in stableswap contract.\n    string name;        // Pool name (\"... Pool\").\n}\n\n\n/**\n * @title Registry for Swerve contracts.\n * @dev Implements two getters - getSwapAndTotalCoins(address) and getName(address).\n * @notice Call getSwapAndTotalCoins(token) and getName(address) function and get address,\n * coins number, and name of stableswap contract for the given token address.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract SwerveRegistry is Ownable {\n\n    mapping (address => PoolInfo) internal poolInfo;\n\n    constructor() public {\n        poolInfo[0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059] = PoolInfo({\n            swap: 0x329239599afB305DA0A2eC69c58F8a6697F9F88d,\n            totalCoins: 4,\n            name: \"swUSD Pool\"\n        });\n    }\n\n    function setPoolInfo(\n        address token,\n        address swap,\n        uint256 totalCoins,\n        string calldata name\n    )\n        external\n        onlyOwner\n    {\n        poolInfo[token] = PoolInfo({\n            swap: swap,\n            totalCoins: totalCoins,\n            name: name\n        });\n    }\n\n    function getSwapAndTotalCoins(address token) external view returns (address, uint256) {\n        return (poolInfo[token].swap, poolInfo[token].totalCoins);\n    }\n\n    function getName(address token) external view returns (string memory) {\n        return poolInfo[token].name;\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/Ownable.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\nabstract contract Ownable {\n\n    modifier onlyOwner {\n        require(msg.sender == owner, \"O: onlyOwner function!\");\n        _;\n    }\n\n    address public owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @notice Initializes owner variable with msg.sender address.\n     */\n    constructor() internal {\n        owner = msg.sender;\n        emit OwnershipTransferred(address(0), msg.sender);\n    }\n\n    /**\n     * @notice Transfers ownership to the desired address.\n     * The function is callable only by the owner.\n     */\n    function transferOwnership(address _owner) external onlyOwner {\n        require(_owner != address(0), \"O: new owner is the zero address!\");\n        emit OwnershipTransferred(owner, _owner);\n        owner = _owner;\n    }\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 1000000
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
    "remappings": []
  }
}}