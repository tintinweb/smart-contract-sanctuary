/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// SPDX-License-Identifier: None

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
//pragma solidity >=0.8.9;

//pragma solidity >=0.5.0 <0.8.0;
pragma solidity >=0.8.11;

contract HelloWorld {
  string name = 'Celo';
  string[] public row;

  function getName() public view returns (string memory) {
    return name;
  }

  function setName(string calldata newName) external {
    name = newName;
  }

  function getRow() public view returns (string[] memory) {
    return row;
  }

  function pushToRow(string memory newValue) public {
    row.push(newValue);
  }
  
}