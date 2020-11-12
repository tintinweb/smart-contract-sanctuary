{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/dodo/DodoStakingAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\n\n\n/**\n * @dev DODOMine contract interface.\n * Only the functions required for DodoStakingAdapter contract are added.\n * The DODOMine contract is available here\n * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/token/DODOMine.sol.\n */\ninterface DODOMine {\n    function getUserLpBalance(address, address) external view returns (uint256);\n    function getAllPendingReward(address) external view returns (uint256);\n}\n\n\n/**\n * @title Adapter for DODO protocol.\n * @dev Implementation of ProtocolAdapter interface.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract DodoStakingAdapter is ProtocolAdapter {\n\n    string public constant override adapterType = \"Asset\";\n\n    string public constant override tokenType = \"ERC20\";\n\n    address internal constant DODO = 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd;\n    address internal constant DODO_MINE = 0xaeD7384F03844Af886b830862FF0a7AFce0a632C;\n\n    /**\n     * @return Amount of DODO rewards / DLP staked tokens for a given account.\n     * @dev Implementation of ProtocolAdapter interface function.\n     */\n    function getBalance(address token, address account) external view override returns (uint256) {\n        if (token == DODO) {\n            uint256 totalBalance = 0;\n\n            totalBalance += DODOMine(DODO_MINE).getAllPendingReward(account);\n            totalBalance += DODOMine(DODO_MINE).getUserLpBalance(token, account);\n\n            return totalBalance;\n        } else {\n            return DODOMine(DODO_MINE).getUserLpBalance(token, account);\n        }\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\n/**\n * @title Protocol adapter interface.\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ninterface ProtocolAdapter {\n\n    /**\n     * @dev MUST return \"Asset\" or \"Debt\".\n     * SHOULD be implemented by the public constant state variable.\n     */\n    function adapterType() external pure returns (string memory);\n\n    /**\n     * @dev MUST return token type (default is \"ERC20\").\n     * SHOULD be implemented by the public constant state variable.\n     */\n    function tokenType() external pure returns (string memory);\n\n    /**\n     * @dev MUST return amount of the given token locked on the protocol by the given account.\n     */\n    function getBalance(address token, address account) external view returns (uint256);\n}\n"
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