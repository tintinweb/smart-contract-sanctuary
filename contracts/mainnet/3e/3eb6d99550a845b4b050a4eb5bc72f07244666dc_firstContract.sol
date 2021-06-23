/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract firstContract {

  address payable public  owner;

  constructor() payable {
    require(msg.value > 0.0005 ether,'Not enough Ether');
    owner = payable(msg.sender);
    
  }

  modifier onlyOwner() {
    require(msg.sender == owner,'Only the contract owner can call this');
    _;
  }
  
  function balanceOf() public view returns(uint256) {
      return address(this).balance;
  }

  function withdraw() external onlyOwner  {
    
    return owner.transfer(address(this).balance);
    
  }

}