// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;
pragma experimental ABIEncoderV2;
 
contract BoxV3 {
    uint256 private value;
    string public name;
    Approval[] private approvals;
 
    constructor(){
        name = "My name is Neo!";
    }

    struct Approval {
        uint taskDate;
        string taskName;
    }

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
    event NameChanged(string newValue);
    event PaymentApproval(uint taskDate, string taskName);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    function setName(string memory _name) public {
        name = _name;
        emit NameChanged(name);
    }

    function approveTask(string memory _taskName) public {
        Approval memory newApproval = Approval({taskDate: block.timestamp, taskName: _taskName});
        approvals.push(newApproval);
        emit PaymentApproval(newApproval.taskDate, newApproval.taskName);
    }

    function getApprovedTasks() public view returns (Approval[] memory){
        return approvals;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}