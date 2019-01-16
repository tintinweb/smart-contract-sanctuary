pragma solidity ^0.4.19;
 
contract MrReaperToken {
/* This creates an array with all balances */
mapping (address => uint256) public balanceOf;
 
function MrReaperToken() {
balanceOf[msg.sender] = 21000000;
}
}