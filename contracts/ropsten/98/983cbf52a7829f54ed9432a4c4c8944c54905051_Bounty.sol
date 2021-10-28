/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity >=0.7.0 <0.9.0;

contract Bounty {
    
    
    constructor() payable {
        
    }
    
    
    function submitSolution(uint256 x) public{
        if(x**2 == 100) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    
}