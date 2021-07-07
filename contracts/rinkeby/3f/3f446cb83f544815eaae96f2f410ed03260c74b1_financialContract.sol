/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;

contract financialContract {
    uint256 balance = 80000;
    
    function checkBalance() public view returns(uint256) {
        return balance;
    }
    
    function deposit(uint256 _amount) public {
        balance = balance + _amount;
    }
}