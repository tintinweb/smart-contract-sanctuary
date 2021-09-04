// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IPayableGovernance {
  function receiveEther() external payable returns (bool);
}

contract GasCompensationVault {
  address private constant GovernanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;

  modifier onlyGovernance() {
    require(msg.sender == GovernanceAddress, "only gov");
    _;
  }

  function compensateGas(address recipient, uint256 amount) external onlyGovernance {
    if(address(this).balance == 0) return;
    require(
      (amount > address(this).balance) ? payable(recipient).send(address(this).balance) : payable(recipient).send(amount),
      "compensation failed"
    );
  }

  function withdrawToGovernance(uint256 amount) external onlyGovernance {
    IPayableGovernance(payable(GovernanceAddress)).receiveEther{
      value: (amount > address(this).balance) ? address(this).balance : amount
    }();
  }

  receive() external payable {}

  function getBasefee() external view returns (uint256) {
    return block.basefee;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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