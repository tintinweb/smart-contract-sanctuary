/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.4.21;

contract GuessTheNewNumberChallenge {
    event AnswerEvent(uint8 answer);
    event GuessEvent(uint8 guess);

    function GuessTheNewNumberChallenge() public payable {
        require(msg.value == 1 wei);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 wei);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        emit AnswerEvent(answer);
        emit GuessEvent(n);
        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}