{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/dodo/DodoTokenAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\nimport { ERC20 } from \"../../ERC20.sol\";\nimport { TokenMetadata, Component } from \"../../Structs.sol\";\nimport { TokenAdapter } from \"../TokenAdapter.sol\";\n\n\n/**\n * @dev DODOLpToken contract interface.\n * Only the functions required for DodoTokenAdapter contract are added.\n * The DODOLpToken contract is available here\n * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/impl/DODOLpToken.sol.\n */\ninterface DODOLpToken {\n    function _OWNER_() external view returns (address);\n    function originToken() external view returns (address);\n}\n\n\n/**\n * @dev DODO contract interface.\n * Only the functions required for DodoTokenAdapter contract are added.\n * The DODO contract is available here\n * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/dodo.sol.\n */\ninterface DODO {\n    function _BASE_TOKEN_() external view returns (address);\n    function _QUOTE_TOKEN_() external view returns (address);\n}\n\n\n/**\n * @title Token adapter for DODO pool tokens.\n * @dev Implementation of TokenAdapter interface.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract DodoTokenAdapter is TokenAdapter {\n\n    /**\n     * @return TokenMetadata struct with ERC20-style token info.\n     * @dev Implementation of TokenAdapter interface function.\n     */\n    function getMetadata(address token) external view override returns (TokenMetadata memory) {\n        return TokenMetadata({\n            token: token,\n            name: getPoolName(token),\n            symbol: \"DLP\",\n            decimals: ERC20(token).decimals()\n        });\n    }\n\n    /**\n     * @return Array of Component structs with underlying tokens rates for the given token.\n     * @dev Implementation of TokenAdapter interface function.\n     */\n    function getComponents(address token) external view override returns (Component[] memory) {\n        address[] memory tokens = new address[](2);\n        address dodo = DODOLpToken(token)._OWNER_();\n        tokens[0] = DODO(dodo)._BASE_TOKEN_();\n        tokens[1] = DODO(dodo)._QUOTE_TOKEN_();\n        uint256 totalSupply = ERC20(token).totalSupply();\n        Component[] memory underlyingTokens = new Component[](2);\n\n        for (uint256 i = 0; i < 2; i++) {\n            underlyingTokens[i] = Component({\n                token: tokens[i],\n                tokenType: \"ERC20\",\n                rate: ERC20(tokens[i]).balanceOf(dodo) * 1e18 / totalSupply\n            });\n        }\n\n        return underlyingTokens;\n    }\n\n    function getPoolName(address token) internal view returns (string memory) {\n        address dodo = DODOLpToken(token)._OWNER_();\n        return string(\n            abi.encodePacked(\n                getSymbol(DODO(dodo)._BASE_TOKEN_()),\n                \"/\",\n                getSymbol(DODO(dodo)._QUOTE_TOKEN_()),\n                \" Pool: \",\n                getSymbol(DODOLpToken(token).originToken())\n            )\n        );\n    }\n\n    function getSymbol(address token) internal view returns (string memory) {\n        (, bytes memory returnData) = token.staticcall(\n            abi.encodeWithSelector(ERC20(token).symbol.selector)\n        );\n\n        if (returnData.length == 32) {\n            return convertToString(abi.decode(returnData, (bytes32)));\n        } else {\n            return abi.decode(returnData, (string));\n        }\n    }\n\n    /**\n     * @dev Internal function to convert bytes32 to string and trim zeroes.\n     */\n    function convertToString(bytes32 data) internal pure returns (string memory) {\n        uint256 counter = 0;\n        bytes memory result;\n\n        for (uint256 i = 0; i < 32; i++) {\n            if (data[i] != bytes1(0)) {\n                counter++;\n            }\n        }\n\n        result = new bytes(counter);\n        counter = 0;\n        for (uint256 i = 0; i < 32; i++) {\n            if (data[i] != bytes1(0)) {\n                result[counter] = data[i];\n                counter++;\n            }\n        }\n\n        return string(result);\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/ERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\ninterface ERC20 {\n    function approve(address, uint256) external returns (bool);\n    function transfer(address, uint256) external returns (bool);\n    function transferFrom(address, address, uint256) external returns (bool);\n    function name() external view returns (string memory);\n    function symbol() external view returns (string memory);\n    function decimals() external view returns (uint8);\n    function totalSupply() external view returns (uint256);\n    function balanceOf(address) external view returns (uint256);\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/Structs.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\nstruct ProtocolBalance {\n    ProtocolMetadata metadata;\n    AdapterBalance[] adapterBalances;\n}\n\n\nstruct ProtocolMetadata {\n    string name;\n    string description;\n    string websiteURL;\n    string iconURL;\n    uint256 version;\n}\n\n\nstruct AdapterBalance {\n    AdapterMetadata metadata;\n    FullTokenBalance[] balances;\n}\n\n\nstruct AdapterMetadata {\n    address adapterAddress;\n    string adapterType; // \"Asset\", \"Debt\"\n}\n\n\n// token and its underlying tokens (if exist) balances\nstruct FullTokenBalance {\n    TokenBalance base;\n    TokenBalance[] underlying;\n}\n\n\nstruct TokenBalance {\n    TokenMetadata metadata;\n    uint256 amount;\n}\n\n\n// ERC20-style token metadata\n// 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE address is used for ETH\nstruct TokenMetadata {\n    address token;\n    string name;\n    string symbol;\n    uint8 decimals;\n}\n\n\nstruct Component {\n    address token;\n    string tokenType;  // \"ERC20\" by default\n    uint256 rate;  // price per full share (1e18)\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/TokenAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\nimport { TokenMetadata, Component } from \"../Structs.sol\";\n\n\n/**\n * @title Token adapter interface.\n * @dev getMetadata() and getComponents() functions MUST be implemented.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ninterface TokenAdapter {\n\n    /**\n     * @dev MUST return TokenMetadata struct with ERC20-style token info.\n     * struct TokenMetadata {\n     *     address token;\n     *     string name;\n     *     string symbol;\n     *     uint8 decimals;\n     * }\n     */\n    function getMetadata(address token) external view returns (TokenMetadata memory);\n\n    /**\n     * @dev MUST return array of Component structs with underlying tokens rates for the given token.\n     * struct Component {\n     *     address token;    // Address of token contract\n     *     string tokenType; // Token type (\"ERC20\" by default)\n     *     uint256 rate;     // Price per share (1e18)\n     * }\n     */\n    function getComponents(address token) external view returns (Component[] memory);\n}\n"
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