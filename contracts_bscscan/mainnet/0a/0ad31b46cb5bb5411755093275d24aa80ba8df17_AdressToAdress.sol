/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity >=0.7.0 <0.9.0;
// ----------------------------------------------------------------------------
// first smart contract of amael lavigne, big somthings started!
//
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
  contract AdressToAdress {
    
    mapping(address => uint) balances;
    
    function invest() external payable {
        balances[msg.sender] += msg.value;
        
    }
    
    function BalanceOf() external view returns(uint) {
        return address(this).balance;
    }
    
    
    function sendEther(address payable) external {
        msg.sender.transfer(10000000000000000 wei);
    }
}