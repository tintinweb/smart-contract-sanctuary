{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/cream/CreamRegistry.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\n\n\n/**\n * @title Registry for Cream contracts.\n * @dev Implements the only function - getCToken(address).\n * @notice Call getCToken(token) function and get address\n * of CToken contract for the given token address.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract CreamRegistry {\n\n    mapping(address => address) internal cTokens;\n\n    constructor() public {\n        cTokens[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 0xD06527D5e56A3495252A528C4987003b712860eE;\n        cTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x797AAB1ce7c01eB727ab980762bA88e7133d2157;\n        cTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322;\n        cTokens[0xc00e94Cb662C3520282E6f5717214004A7f26888] = 0x19D1666f543D42ef17F66E376944A22aEa1a8E46;\n        cTokens[0xba100000625a3754423978a60c9317c58a424e3D] = 0xcE4Fe9b4b8Ff61949DCfeB7e03bc9FAca59D2Eb3;\n        cTokens[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = 0xCbaE0A83f4f9926997c8339545fb8eE32eDc6b76;\n        cTokens[0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8] = 0x9baF8a5236d44AC410c0186Fe39178d5AAD0Bb87;\n        cTokens[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0x697256CAA3cCaFD62BB6d3Aa1C7C5671786A5fD9;\n        cTokens[0x2ba592F78dB6436527729929AAf6c908497cB200] = 0x892B14321a4FCba80669aE30Bd0cd99a7ECF6aC0;\n        cTokens[0x80fB784B7eD66730e8b1DBd9820aFD29931aab03] = 0x8B86e0598616a8d4F1fdAE8b59E55FB5Bc33D0d6;\n        cTokens[0xD533a949740bb3306d119CC777fa900bA034cd52] = 0xc7Fd8Dcee4697ceef5a2fd4608a7BD6A94C77480;\n        cTokens[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0x17107f40d70f4470d20CB3f138a052cAE8EbD4bE;\n        cTokens[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = 0x1FF8CDB51219a8838b52E9cAc09b71e591BC998e;\n        cTokens[0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2] = 0x3623387773010d9214B10C551d6e7fc375D31F58;\n        cTokens[0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c] = 0x4EE15f44c6F0d8d1136c83EfD2e8E4AC768954c6;\n        cTokens[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = 0x338286C0BC081891A4Bda39C7667ae150bf5D206;\n        cTokens[0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9] = 0x10FDBD1e48eE2fD9336a482D746138AE19e649Db;\n        cTokens[0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7] = 0x01da76DEa59703578040012357b81ffE62015C2d;\n        cTokens[0x476c5E26a75bd202a9683ffD34359C0CC15be0fF] = 0xef58b2d5A1b8D3cDE67b8aB054dC5C831E9Bc025;\n    }\n\n    function getCToken(address token) external view returns (address) {\n        return cTokens[token];\n    }\n}\n"
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