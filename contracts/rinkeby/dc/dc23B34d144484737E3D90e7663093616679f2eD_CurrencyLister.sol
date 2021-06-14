pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only
struct TokenOptions {
        // Whether or not the token implements the ERC777 standard.
        bool isERC777;
        // Whether or not the token charges transfer fees
        bool hasTransferFee;
}

contract CurrencyLister {
    function listCurrency(address token, TokenOptions memory options) public {
    }
}

{
  "optimizer": {
    "enabled": false,
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