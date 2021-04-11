/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

pragma solidity ^0.8.1;

contract InterviewQuestion {
    address payable signaler;
    uint  signalBlock;
    
    constructor() payable {
        
    }
    
    function signal() external returns (uint) {
        signaler = payable(msg.sender);
        signalBlock = block.number;
        
        return signalBlock;
    }

    function claim() external returns (bool) {
        require(signaler == msg.sender, "wrong sender");
        require(signalBlock == block.number, "wrong block");
        
        return signaler.send(address(this).balance);
    }
}