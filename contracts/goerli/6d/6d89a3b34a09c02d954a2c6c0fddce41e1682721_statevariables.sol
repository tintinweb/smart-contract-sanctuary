/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract statevariables{
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    receive() external payable{}
    fallback() external payable{}
    
    modifier check(uint amount){
        require(address(this).balance >= amount,"low balance");
        _;
    }
    
    function getEther(uint amount) public payable check(amount){
        msg.sender.transfer(amount* 1 ether);
    }
    


    
    
}