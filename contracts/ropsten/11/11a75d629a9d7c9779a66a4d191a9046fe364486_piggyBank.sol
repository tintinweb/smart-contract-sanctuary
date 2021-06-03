/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.24;
 
contract piggyBank {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function breakPiggyBank() {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
    function () payable {
        
    }
       
}