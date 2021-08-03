/**
 * @title Details
 * @author Team 3301 <[email protected]>
 * @notice Shared library for Sygnum token details struct.
 */

pragma solidity ^0.6.2;

library Details {
    struct TokenDetails {
        string name;
        string symbol;
        uint8 decimals;
        bytes4 category;
        string class;
        address issuer;
        string tokenURI;
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}