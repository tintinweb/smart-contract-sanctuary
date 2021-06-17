/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.8.0;

contract walletBalance {
    
    mapping (address=> uint) public balances;
    
    function updateBalance(uint newBalance) public {
        balances[msg.sender]=newBalance;
    }
}
contract updateContract{
    function updateBalance () public returns (uint){
        walletBalance walletbalance=new walletBalance();
        walletbalance.updateBalance(10);
        return walletbalance.balances(address(this));
    }
}