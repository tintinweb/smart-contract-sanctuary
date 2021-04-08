/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity >=0.4.22 <0.6.0;

contract Test {
    
    constructor () public payable {
        
    }
    
    function withdraw() public payable {
        require(msg.value == 0.01 ether);
        msg.sender.transfer(1 ether);
    }
    
}