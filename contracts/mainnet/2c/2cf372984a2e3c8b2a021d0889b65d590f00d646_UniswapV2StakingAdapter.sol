{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/uniswap/UniswapV2StakingAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\nimport { ERC20 } from \"../../ERC20.sol\";\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\n\n\n/**\n * @dev StakingRewards contract interface.\n * Only the functions required for UniswapV2StakingAdapter contract are added.\n * The StakingRewards contract is available here\n * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.\n */\ninterface StakingRewards {\n    function earned(address) external view returns (uint256);\n}\n\n\n/**\n * @title Adapter for Uniswap V2 staking.\n * @dev Implementation of ProtocolAdapter interface.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract UniswapV2StakingAdapter is ProtocolAdapter {\n\n    string public constant override adapterType = \"Asset\";\n\n    string public constant override tokenType = \"ERC20\";\n\n    address internal constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;\n\n    address internal constant UNI_V2_WBTC_WETH = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;\n    address internal constant UNI_V2_WETH_USDT = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;\n    address internal constant UNI_V2_USDC_WETH = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;\n    address internal constant UNI_V2_DAI_WETH = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;\n\n    address internal constant UNI_V2_WBTC_WETH_POOL = 0xCA35e32e7926b96A9988f61d510E038108d8068e;\n    address internal constant UNI_V2_WETH_USDT_POOL = 0x6C3e4cb2E96B01F4b866965A91ed4437839A121a;\n    address internal constant UNI_V2_USDC_WETH_POOL = 0x7FBa4B8Dc5E7616e59622806932DBea72537A56b;\n    address internal constant UNI_V2_DAI_WETH_POOL = 0xa1484C3aa22a66C62b77E0AE78E15258bd0cB711;\n\n    /**\n     * @return Amount of staked tokens / rewards earned after staking for a given account.\n     * @dev Implementation of ProtocolAdapter interface function.\n     */\n    function getBalance(address token, address account) external view override returns (uint256) {\n        if (token == UNI) {\n            uint256 totalRewards = 0;\n\n            totalRewards += StakingRewards(UNI_V2_WBTC_WETH_POOL).earned(account);\n            totalRewards += StakingRewards(UNI_V2_WETH_USDT_POOL).earned(account);\n            totalRewards += StakingRewards(UNI_V2_USDC_WETH_POOL).earned(account);\n            totalRewards += StakingRewards(UNI_V2_DAI_WETH_POOL).earned(account);\n\n            return totalRewards;\n        } else if (token == UNI_V2_WBTC_WETH) {\n            return ERC20(UNI_V2_WBTC_WETH_POOL).balanceOf(account);\n        } else if (token == UNI_V2_WETH_USDT) {\n            return ERC20(UNI_V2_WETH_USDT_POOL).balanceOf(account);\n        } else if (token == UNI_V2_USDC_WETH) {\n            return ERC20(UNI_V2_USDC_WETH_POOL).balanceOf(account);\n        } else if (token == UNI_V2_DAI_WETH) {\n            return ERC20(UNI_V2_DAI_WETH_POOL).balanceOf(account);\n        } else {\n            return 0;\n        }\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/ERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\ninterface ERC20 {\n    function approve(address, uint256) external returns (bool);\n    function transfer(address, uint256) external returns (bool);\n    function transferFrom(address, address, uint256) external returns (bool);\n    function name() external view returns (string memory);\n    function symbol() external view returns (string memory);\n    function decimals() external view returns (uint8);\n    function totalSupply() external view returns (uint256);\n    function balanceOf(address) external view returns (uint256);\n}\n"
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