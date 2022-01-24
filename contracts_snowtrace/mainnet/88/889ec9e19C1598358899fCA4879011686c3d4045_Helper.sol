/**
 *Submitted for verification at snowtrace.io on 2022-01-24
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBentoBox {
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
  
  IBentoBox public immutable bentoBox;

  constructor(IBentoBox _bentoBox) public {
    bentoBox = _bentoBox;
  }

  function depositAndApprove(
    address user,
    address masterContract,
    bool approved,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable {
    
    bentoBox.deposit{value: msg.value}(address(0), address(this), msg.sender, msg.value, 0);
    
    bentoBox.setMasterContractApproval(user, masterContract, approved, v, r, s);

  }
  
}