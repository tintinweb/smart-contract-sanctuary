/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Pay {
        
    mapping(address => uint256) private _matic;
    

    receive() external payable {}
  
  function sendMatic(uint256 amount) public payable {
      payable(address(this)).transfer(amount);
      _matic[msg.sender] += msg.value;
  }
  
  function getContractsBalance() public  view returns (uint256) {
      return address(this).balance;
  }
  
  function getMaticBalance() public view returns (uint256) {
      return _matic[msg.sender];
  }
  
  function transfer() public payable {
      payable(address(this)).transfer(msg.value);
      _matic[msg.sender] += msg.value;
  }
}