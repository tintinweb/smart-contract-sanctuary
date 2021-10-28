/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity >=0.7.0 <0.9.0;

contract Bounty {
    
    
    constructor () payable {
        
    }
    
    function submitSolution(uint256 x) public {
        // check if x is indeed the solution
        // if so, send the caller all the ethers owned by the contract
        if(x**3 - 123123123*x**2 + 1237615237612*x - 152379053127176502276 == 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }   
    
}