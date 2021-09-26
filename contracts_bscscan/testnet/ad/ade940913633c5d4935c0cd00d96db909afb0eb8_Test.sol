/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Test {

   address payable public withdrawAddress = 0x28be98909a21e0D04072Cba788fF8Fe7dF76fa2c;
   address public owner;

   constructor() public payable {
     owner = msg.sender;
   }

   function totalBalance() external view returns(uint) {
     //return address(owner).balance;
     return payable(address(this)).balance;
   }

   function withdrawFunds() external withdrawAddressOnly() {
     msg.sender.transfer(this.totalBalance());
   }

   modifier withdrawAddressOnly() {
     require(msg.sender == withdrawAddress, 'only withdrawer can call this');
   _;
   }
}