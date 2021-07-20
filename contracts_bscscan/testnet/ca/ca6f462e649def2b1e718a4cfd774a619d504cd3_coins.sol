/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
contract coins {
 address public minter;
 mapping (address=> uint )public balances;
 event sent(address from, address to, uint amount);
 error inSufficientBalances(uint requested,uint availableBalances);
 constructor ()  {
    minter = msg.sender; 
 }
 function mint(address receiver, uint amount) public {
    require (msg.sender == minter);
     balances[receiver] += amount;
 }
 
 
 function send(address receiver, uint amount)public payable{
     if (amount > balances[msg.sender])
     revert inSufficientBalances({
         requested: amount,
         availableBalances:  balances[msg.sender]
         });
         
     balances[msg.sender] -= amount;
     balances[receiver] += amount;
    emit sent(msg.sender, receiver, amount);
}
function f() public view returns(uint){
 return tx.gasprice;   
}
}