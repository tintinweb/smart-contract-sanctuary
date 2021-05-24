/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

//daehyukkim

pragma solidity 0.8.0;

contract class_15_1 {
    
    uint balance = 0;
    
    function pay100() public payable {
        
        balance += msg.value;
        
    }
    
    function pay500() public payable {
        
        balance += msg.value;
        
    }
    
    function pay1000() public payable {
        
        balance += msg.value;
        
    }
    
    function get2() public view returns(uint) {
        
        return address(this).balance;
        
    }
        
}