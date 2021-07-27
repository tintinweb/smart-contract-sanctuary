/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity 0.8.6;

contract Test7 {
    
    constructor() payable {
        
    }
    
    function withdraw() public {
        require(address(this).balance >= 1 ether);
        payable(msg.sender).transfer(address(this).balance);
    } 
    
}