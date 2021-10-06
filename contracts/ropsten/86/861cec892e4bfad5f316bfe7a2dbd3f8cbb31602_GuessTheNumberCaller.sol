/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.8.7;

interface GuessTheNumberInterface {
    
    function guess(uint8 n) external payable;
    
}

contract GuessTheNumberCaller {
    
    address guessTheNumberAddress = 0xB4addFF8f4fDDf78642fb981910C63a2eD8e34FC;
    GuessTheNumberInterface guessTheNumberInterface = GuessTheNumberInterface(guessTheNumberAddress);
    
    function guess() public payable {
        uint answer256 = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        uint8 answer8 = uint8(answer256);
        guessTheNumberInterface.guess{value: 1 ether}(answer8);
    }
    
    function guess1(bytes32 data) public pure returns(uint, uint8) {
        
        uint answer256 = uint(data);
        uint8 answer8 = uint8(answer256);
        return (answer256, answer8);
    }
    
}