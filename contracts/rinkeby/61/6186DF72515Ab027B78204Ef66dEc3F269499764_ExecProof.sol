/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExecProof {
  string[] private logs;

  function getExecProofs() public view returns (string[] memory) {
    return logs;
  }

  function addExecProof(string memory proof) public {
    // String should not be empty
    require(bytes(proof).length != 0, 'NULL STRING');
    // Add execution proof to state
    logs.push(proof);
  }
}