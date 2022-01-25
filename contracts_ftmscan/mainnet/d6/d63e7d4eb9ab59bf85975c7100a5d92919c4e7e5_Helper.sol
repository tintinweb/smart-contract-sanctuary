/**
 *Submitted for verification at FtmScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICoffinBox {
  function setMasterContractApproval(
    address user,
    address masterContract,
    bool approved,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function deposit(
    address token,
    address from,
    address to,
    uint256 amount,
    uint256 share
  ) external payable; 
}

contract Helper {
  
  ICoffinBox public immutable coffinBox;

  constructor(ICoffinBox _coffinBox) public {
    coffinBox = _coffinBox;
  }

  function depositAndApprove(
    address user,
    address masterContract,
    bool approved,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable {
    
    coffinBox.deposit{value: msg.value}(address(0), address(this), msg.sender, msg.value, 0);
    coffinBox.setMasterContractApproval(user, masterContract, approved, v, r, s);

  }
  
}