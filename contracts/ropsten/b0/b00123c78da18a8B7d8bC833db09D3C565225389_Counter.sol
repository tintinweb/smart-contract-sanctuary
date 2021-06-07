//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title A contract for boilerplating
/// @author Hardhat (and Alejo Amiras)
/// @notice You can use this contract for only the most basic tests
/// @dev This is just a try out
/// @custom:experimental This is an experimental contract.

contract Counter {

  event Worked(address _job, uint256 _credits, uint256 _remainingCredits);

  address public STATIC_JOB = address(0xe);
  mapping(address => uint256) public credits;

  constructor() {
    credits[STATIC_JOB] = 1000 ether;
  }

  function addCredits(address _job, uint256 _credits) public {
    credits[_job] += _credits;
  }

  function work(address _job, uint256 _credits) public {
    credits[_job] -= _credits;
    emit Worked(_job, _credits, credits[_job]);
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