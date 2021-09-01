// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract ETHBatchTransfer {
    function transfer(address[] memory recipient, uint256 amount)
        external
        payable
    {
        require(
            amount * recipient.length == msg.value,
            "Transfer: Amount error"
        );
        for (uint256 i; i < recipient.length; i++) {
            payable(recipient[i]).transfer(amount);
        }
    }

    function transferEthWithDifferentValue(
        address[] memory recipient,
        uint256[] memory amount
    ) external payable {
        uint256 sum;
        for (uint256 i; i < amount.length; i++) {
            sum += amount[i];
        }
        require(sum < msg.value, "Transfer: Amount error");
        for (uint256 i; i < recipient.length; i++) {
            payable(recipient[i]).transfer(amount[i]);
        }
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