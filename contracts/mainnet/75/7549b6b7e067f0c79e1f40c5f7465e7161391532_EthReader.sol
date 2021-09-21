// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

/**
@dev OVERALL NOTE:
* This contract is used by Subgraph to get the ETH balance of an account
  It can also be treated as an on-chain ERC20 that will return an account's ETH balance in balanceOf
*/

contract EthReader {
    uint8 public immutable decimals = 18;
    string public name = "ETH Reader";
    string public symbol = "ETH-READER";
    uint256 public immutable totalSupply = 120e6 ether;

    function balanceOf(address user) external view returns (uint256 balance) {
        balance = user.balance;
    }

    function allowance(address, address) external view returns (uint256 result) {
        result = 0;
    }
}

{
  "optimizer": {
    "enabled": true,
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