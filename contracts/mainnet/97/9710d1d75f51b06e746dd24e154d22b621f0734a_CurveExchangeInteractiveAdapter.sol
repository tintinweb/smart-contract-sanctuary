{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/interactiveAdapters/curve/CurveExchangeInteractiveAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\npragma experimental ABIEncoderV2;\n\nimport { ERC20 } from \"../../shared/ERC20.sol\";\nimport { SafeERC20 } from \"../../shared/SafeERC20.sol\";\nimport { TokenAmount } from \"../../shared/Structs.sol\";\nimport { CurveExchangeAdapter } from \"../../adapters/curve/CurveExchangeAdapter.sol\";\nimport { InteractiveAdapter } from \"../InteractiveAdapter.sol\";\nimport { Stableswap } from \"../../interfaces/Stableswap.sol\";\n\n\n/**\n * @title Interactive adapter for Curve protocol (exchange).\n * @dev Implementation of CurveInteractiveAdapter abstract contract.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract CurveExchangeInteractiveAdapter is CurveExchangeAdapter, InteractiveAdapter  {\n    using SafeERC20 for ERC20;\n\n    /**\n     * @notice Exchanges tokens using the given swap contract.\n     * @param tokenAmounts Array with one element - TokenAmount struct with\n     * \"from\" token address, \"from\" token amount to be deposited, and amount type.\n     * @param data Token address to be exchanged to (ABI-encoded).\n     * @param data ABI-encoded additional parameters:\n     *     - toToken - destination token address (one of those used in swap).\n     *     - swap - swap address.\n     *     - i - input token index.\n     *     - j - destination token index.\n     * @dev Implementation of InteractiveAdapter function.\n     */\n    function deposit(\n        TokenAmount[] calldata tokenAmounts,\n        bytes calldata data\n    )\n        external\n        payable\n        override\n        returns (address[] memory tokensToBeWithdrawn)\n    {\n        require(tokenAmounts.length == 1, \"CEIA: should be 1 token\");\n\n        address token = tokenAmounts[0].token;\n        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);\n\n        (address toToken, address swap, int128 i, int128 j) = abi.decode(\n            data,\n            (address, address, int128, int128)\n        );\n\n        tokensToBeWithdrawn = new address[](1);\n        tokensToBeWithdrawn[0] = toToken;\n\n        uint256 allowance = ERC20(token).allowance(address(this), swap);\n        if (allowance < amount) {\n            if (allowance > 0) {\n                ERC20(token).safeApprove(swap, 0, \"CEIA[1]\");\n            }\n            ERC20(token).safeApprove(swap, type(uint256).max, \"CEIA[2]\");\n        }\n\n        // solhint-disable-next-line no-empty-blocks\n        try Stableswap(swap).exchange_underlying(i, j, amount, 0) {\n        } catch Error(string memory reason) {\n            revert(reason);\n        } catch {\n            revert(\"CEIA: deposit fail\");\n        }\n    }\n\n    /**\n     * @notice Withdraw functionality is not supported.\n     * @dev Implementation of InteractiveAdapter function.\n     */\n    function withdraw(\n        TokenAmount[] calldata,\n        bytes calldata\n    )\n        external\n        payable\n        override\n        returns (address[] memory)\n    {\n        revert(\"CEIA: no withdraw\");\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/shared/ERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\npragma experimental ABIEncoderV2;\n\n\ninterface ERC20 {\n    function approve(address, uint256) external returns (bool);\n    function transfer(address, uint256) external returns (bool);\n    function transferFrom(address, address, uint256) external returns (bool);\n    function name() external view returns (string memory);\n    function symbol() external view returns (string memory);\n    function decimals() external view returns (uint8);\n    function totalSupply() external view returns (uint256);\n    function balanceOf(address) external view returns (uint256);\n    function allowance(address, address) external view returns (uint256);\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/shared/SafeERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\n\nimport \"./ERC20.sol\";\n\n\n/**\n * @title SafeERC20\n * @dev Wrappers around ERC20 operations that throw on failure (when the token contract\n * returns false). Tokens that return no value (and instead revert or throw on failure)\n * are also supported, non-reverting calls are assumed to be successful.\n * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,\n * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.\n */\nlibrary SafeERC20 {\n\n    function safeTransfer(\n        ERC20 token,\n        address to,\n        uint256 value,\n        string memory location\n    )\n        internal\n    {\n        callOptionalReturn(\n            token,\n            abi.encodeWithSelector(\n                token.transfer.selector,\n                to,\n                value\n            ),\n            \"transfer\",\n            location\n        );\n    }\n\n    function safeTransferFrom(\n        ERC20 token,\n        address from,\n        address to,\n        uint256 value,\n        string memory location\n    )\n        internal\n    {\n        callOptionalReturn(\n            token,\n            abi.encodeWithSelector(\n                token.transferFrom.selector,\n                from,\n                to,\n                value\n            ),\n            \"transferFrom\",\n            location\n        );\n    }\n\n    function safeApprove(\n        ERC20 token,\n        address spender,\n        uint256 value,\n        string memory location\n    )\n        internal\n    {\n        require(\n            (value == 0) || (token.allowance(address(this), spender) == 0),\n            \"SafeERC20: bad approve call\"\n        );\n        callOptionalReturn(\n            token,\n            abi.encodeWithSelector(\n                token.approve.selector,\n                spender,\n                value\n            ),\n            \"approve\",\n            location\n        );\n    }\n\n    /**\n     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract),\n     * relaxing the requirement on the return value: the return value is optional\n     * (but if data is returned, it must not be false).\n     * @param token The token targeted by the call.\n     * @param data The call data (encoded using abi.encode or one of its variants).\n     * @param location Location of the call (for debug).\n     */\n    function callOptionalReturn(\n        ERC20 token,\n        bytes memory data,\n        string memory functionName,\n        string memory location\n    )\n        private\n    {\n        // We need to perform a low level call here, to bypass Solidity's return data size checking\n        // mechanism, since we're implementing it ourselves.\n\n        // We implement two-steps call as callee is a contract is a responsibility of a caller.\n        //  1. The call itself is made, and success asserted\n        //  2. The return value is decoded, which in turn checks the size of the returned data.\n\n        // solhint-disable-next-line avoid-low-level-calls\n        (bool success, bytes memory returndata) = address(token).call(data);\n        require(\n            success,\n            string(\n                abi.encodePacked(\n                    \"SafeERC20: \",\n                    functionName,\n                    \" failed in \",\n                    location\n                )\n            )\n        );\n\n        if (returndata.length > 0) { // Return data is optional\n            require(\n                abi.decode(returndata, (bool)),\n                string(\n                    abi.encodePacked(\n                        \"SafeERC20: \",\n                        functionName,\n                        \" returned false in \",\n                        location\n                    )\n                )\n            );\n        }\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/shared/Structs.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\npragma experimental ABIEncoderV2;\n\n\n// The struct consists of AbsoluteTokenAmount structs for\n// (base) token and its underlying tokens (if any).\nstruct FullAbsoluteTokenAmount {\n    AbsoluteTokenAmountMeta base;\n    AbsoluteTokenAmountMeta[] underlying;\n}\n\n\n// The struct consists of AbsoluteTokenAmount struct\n// with token address and absolute amount\n// and ERC20Metadata struct with ERC20-style metadata.\n// NOTE: 0xEeee...EEeE address is used for ETH.\nstruct AbsoluteTokenAmountMeta {\n    AbsoluteTokenAmount absoluteTokenAmount;\n    ERC20Metadata erc20metadata;\n}\n\n\n// The struct consists of ERC20-style token metadata.\nstruct ERC20Metadata {\n    string name;\n    string symbol;\n    uint8 decimals;\n}\n\n\n// The struct consists of protocol adapter's name\n// and array of AbsoluteTokenAmount structs\n// with token addresses and absolute amounts.\nstruct AdapterBalance {\n    bytes32 protocolAdapterName;\n    AbsoluteTokenAmount[] absoluteTokenAmounts;\n}\n\n\n// The struct consists of token address\n// and its absolute amount.\nstruct AbsoluteTokenAmount {\n    address token;\n    uint256 amount;\n}\n\n\n// The struct consists of token address,\n// and price per full share (1e18).\nstruct Component {\n    address token;\n    uint256 rate;\n}\n\n\n//=============================== Interactive Adapters Structs ====================================\n\n\nstruct TransactionData {\n    Action[] actions;\n    TokenAmount[] inputs;\n    Fee fee;\n    AbsoluteTokenAmount[] requiredOutputs;\n    uint256 nonce;\n}\n\n\nstruct Action {\n    bytes32 protocolAdapterName;\n    ActionType actionType;\n    TokenAmount[] tokenAmounts;\n    bytes data;\n}\n\n\nstruct TokenAmount {\n    address token;\n    uint256 amount;\n    AmountType amountType;\n}\n\n\nstruct Fee {\n    uint256 share;\n    address beneficiary;\n}\n\n\nenum ActionType { None, Deposit, Withdraw }\n\n\nenum AmountType { None, Relative, Absolute }\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/curve/CurveExchangeAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\npragma experimental ABIEncoderV2;\n\nimport { ERC20 } from \"../../shared/ERC20.sol\";\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\n\n\n/**\n * @title Adapter for Curve protocol (exchange).\n * @dev Implementation of ProtocolAdapter abstract contract.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract CurveExchangeAdapter is ProtocolAdapter {\n\n    /**\n     * @notice This function is unavailable for exchange adapter.\n     * @dev Implementation of ProtocolAdapter abstract contract function.\n     */\n    function getBalance(\n        address,\n        address\n    )\n        public\n        pure\n        override\n        returns (uint256)\n    {\n        revert(\"CEA: no balance\");\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\npragma experimental ABIEncoderV2;\n\n\n/**\n * @title Protocol adapter abstract contract.\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\nabstract contract ProtocolAdapter {\n\n    /**\n     * @dev MUST return amount and type of the given token\n     * locked on the protocol by the given account.\n     */\n    function getBalance(\n        address token,\n        address account\n    )\n        public\n        view\n        virtual\n        returns (uint256);\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/interactiveAdapters/InteractiveAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\npragma experimental ABIEncoderV2;\n\nimport { ProtocolAdapter } from \"../adapters/ProtocolAdapter.sol\";\nimport { TokenAmount, AmountType } from \"../shared/Structs.sol\";\nimport { ERC20 } from \"../shared/ERC20.sol\";\n\n\n/**\n * @title Base contract for interactive protocol adapters.\n * @dev deposit() and withdraw() functions MUST be implemented\n * as well as all the functions from ProtocolAdapter abstract contract.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\nabstract contract InteractiveAdapter is ProtocolAdapter {\n\n    uint256 internal constant DELIMITER = 1e18;\n    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;\n\n    /**\n     * @dev The function must deposit assets to the protocol.\n     * @return MUST return assets to be sent back to the `msg.sender`.\n     */\n    function deposit(\n        TokenAmount[] calldata tokenAmounts,\n        bytes calldata data\n    )\n        external\n        payable\n        virtual\n        returns (address[] memory);\n\n    /**\n     * @dev The function must withdraw assets from the protocol.\n     * @return MUST return assets to be sent back to the `msg.sender`.\n     */\n    function withdraw(\n        TokenAmount[] calldata tokenAmounts,\n        bytes calldata data\n    )\n        external\n        payable\n        virtual\n        returns (address[] memory);\n\n    function getAbsoluteAmountDeposit(\n        TokenAmount calldata tokenAmount\n    )\n        internal\n        view\n        virtual\n        returns (uint256)\n    {\n        address token = tokenAmount.token;\n        uint256 amount = tokenAmount.amount;\n        AmountType amountType = tokenAmount.amountType;\n\n        require(\n            amountType == AmountType.Relative || amountType == AmountType.Absolute,\n            \"IA: bad amount type\"\n        );\n        if (amountType == AmountType.Relative) {\n            require(amount <= DELIMITER, \"IA: bad amount\");\n\n            uint256 balance;\n            if (token == ETH) {\n                balance = address(this).balance;\n            } else {\n                balance = ERC20(token).balanceOf(address(this));\n            }\n\n            if (amount == DELIMITER) {\n                return balance;\n            } else {\n                return mul(balance, amount) / DELIMITER;\n            }\n        } else {\n            return amount;\n        }\n    }\n\n    function getAbsoluteAmountWithdraw(\n        TokenAmount calldata tokenAmount\n    )\n        internal\n        view\n        virtual\n        returns (uint256)\n    {\n        address token = tokenAmount.token;\n        uint256 amount = tokenAmount.amount;\n        AmountType amountType = tokenAmount.amountType;\n\n        require(\n            amountType == AmountType.Relative || amountType == AmountType.Absolute,\n            \"IA: bad amount type\"\n        );\n        if (amountType == AmountType.Relative) {\n            require(amount <= DELIMITER, \"IA: bad amount\");\n\n            uint256 balance = getBalance(token, address(this));\n            if (amount == DELIMITER) {\n                return balance;\n            } else {\n                return mul(balance, amount) / DELIMITER;\n            }\n        } else {\n            return amount;\n        }\n    }\n\n    function mul(\n        uint256 a,\n        uint256 b\n    )\n        internal\n        pure\n        returns (uint256)\n    {\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b, \"IA: mul overflow\");\n\n        return c;\n    }\n}\n"
    },
    "/Users/igor/job/dev/defi-sdk/contracts/interfaces/Stableswap.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n//\n// SPDX-License-Identifier: LGPL-3.0-only\n\npragma solidity 0.7.1;\n\n\n/**\n * @dev Stableswap contract interface.\n * The Stableswap contract is available here\n * github.com/curvefi/curve-contract/blob/compounded/vyper/stableswap.vy.\n */\ninterface Stableswap {\n    /* solhint-disable-next-line func-name-mixedcase */\n    function underlying_coins(int128) external view returns (address);\n    function exchange_underlying(int128, int128, uint256, uint256) external;\n    function get_dy_underlying(int128, int128, uint256) external view returns (uint256);\n    function coins(int128) external view returns (address);\n    function coins(uint256) external view returns (address);\n    function balances(int128) external view returns (uint256);\n    function balances(uint256) external view returns (uint256);\n}\n"
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