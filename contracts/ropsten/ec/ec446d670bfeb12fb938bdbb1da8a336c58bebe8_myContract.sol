/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.8.1;

contract myContract{
    
    function receiveMoney() public payable {
        
    }
    
    function checkBalance() public view returns(uint) {
        return address(this).balance;
    }
    
}