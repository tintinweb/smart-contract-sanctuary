{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/compound/CompoundRegistry.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\n\nimport { Ownable } from \"../../Ownable.sol\";\n\n\n/**\n * @title Registry for Compound contracts.\n * @dev Implements the only function - getCToken(address).\n * @notice Call getCToken(token) function and get address\n * of CToken contract for the given token address.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract CompoundRegistry is Ownable {\n\n    mapping(address => address) internal cTokens;\n\n    constructor() public {\n        cTokens[0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359] = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;\n        cTokens[0x1985365e9f78359a9B6AD760e32412f4a445E862] = 0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1;\n        cTokens[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;\n        cTokens[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;\n        cTokens[0x0D8775F648430679A709E98d2b0Cb6250d2887EF] = 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E;\n        cTokens[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;\n        cTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;\n        cTokens[0xE41d2489571d322189246DaFA5ebDe1F4699F498] = 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407;\n        cTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;\n        cTokens[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984] = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;\n    }\n\n    function getCToken(address token) external view returns (address) {\n        return cTokens[token];\n    }\n\n    function setCToken(address token, address cToken) external onlyOwner returns (address) {\n        return cTokens[token] = cToken;\n    }\n}\n"
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