pragma solidity ^0.4.24;

contract Balance {
    
function balanceOfSC() public 
 returns(uint256) {
    return address(this).balance;
}
}