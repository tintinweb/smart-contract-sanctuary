/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
contract Bank {
        
    mapping(address => uint256)  Pbalance;

 
 
    function deposit(uint256 amount) public payable {
        require(amount > 0 ,"MORE");
        Pbalance[msg.sender] += msg.value;
    }
   function withdraw(uint256 amount) public  {
        require(amount <= Pbalance[msg.sender],"SOME THINGS");
        payable(msg.sender).transfer(amount);
        Pbalance[msg.sender] -= amount;
    }
    
    // function check() public view returns(uint256 _balance,address _address){
    //     return (balance[receiver],receiver);
    // }
     function checksender() public view returns(uint256 _balance){
        return Pbalance[msg.sender];
    }
}