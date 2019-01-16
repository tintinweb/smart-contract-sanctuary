pragma solidity ^0.4.19;
 
contract ReaperToken {
/* This creates an array with all balances */
mapping (address => uint256) public balanceOf;
 
    function ReaperToken() {
    balanceOf[msg.sender] = 66600000;
    }
}