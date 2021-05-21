/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//Younwoo Noh

pragma solidity 0.8.0;

contract Likelion_17_2 {
    uint balance = 0;
    
    function pay() public payable {
        balance += msg.value;
    }
    
    function getBalance() public view returns(uint256) {
        return balance;
    }
    
    function returnbalace() public view returns(uint) {
        return address(this).balance;
    }
}