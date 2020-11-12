{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/defi-sdk/contracts/adapters/bzx/BzxDebtAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\n\n\ninterface TheProtocol {\n    function getUserLoans(\n        address user,\n        uint256 start,\n        uint256 count,\n        LoanType loanType,\n        bool isLender,\n        bool unsafeOnly)\n        external\n        view\n        returns (LoanReturnData[] memory loansData);\n\n    function getActiveLoansCount()\n        external\n        view\n        returns (uint256);\n}\n\n\nenum LoanType {\n    All,\n    Margin,\n    NonMargin\n}\n\n\nstruct LoanReturnData {\n    bytes32 loanId;\n    uint96 endTimestamp;\n    address loanToken;\n    address collateralToken;\n    uint256 principal;\n    uint256 collateral;\n    uint256 interestOwedPerDay;\n    uint256 interestDepositRemaining;\n    uint256 startRate;\n    uint256 startMargin;\n    uint256 maintenanceMargin;\n    uint256 currentMargin;\n    uint256 maxLoanTerm;\n    uint256 maxLiquidatable;\n    uint256 maxSeizable;\n}\n \n\n/**\n * @title Debt adapter for bZx protocol.\n * @dev Implementation of ProtocolAdapter interface.\n * @author Roman Iftodi <romeo8881@gmail.com>\n */\ncontract BzxDebtAdapter is ProtocolAdapter {\n\n    address internal constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f;\n\n    string public constant override adapterType = \"Debt\";\n\n    string public constant override tokenType = \"ERC20\";\n\n    /**\n     * @return Amount of debt of the given account for the protocol.\n     * @dev Implementation of ProtocolAdapter interface function.\n     */\n    function getBalance(address token, address account) external view override returns (uint256) {\n        LoanReturnData[] memory loans;\n        loans = TheProtocol(bZxContract).getUserLoans(\n            account, \n            0, \n            TheProtocol(bZxContract).getActiveLoansCount(), \n            LoanType.All, \n            false, \n            false\n        );\n\n        uint256 principal = 0;\n        uint256 loanLenght = loans.length;\n        for(uint256 i = 0; i < loanLenght; i++) {\n            if (loans[i].loanToken == token) {\n                principal += loans[i].principal;\n            }\n        }\n        return principal;\n    }\n}\n"
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