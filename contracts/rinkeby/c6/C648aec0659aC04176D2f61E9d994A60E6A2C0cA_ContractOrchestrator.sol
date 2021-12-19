// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Cookie.sol";

contract ContractOrchestrator {

  address[] public contracts;

  function getContractCount() public view returns(uint contractCount) {
    return contracts.length;
  }

  function newCookie() public payable returns(address newContract) {
    Cookie c = new Cookie();
    contracts.push(address(c));
    
    return address(c);
  }
}