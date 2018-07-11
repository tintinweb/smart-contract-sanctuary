pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 public answer;
    uint public num;
    uint public now;

    function GuessTheRandomNumberChallenge() public payable {
        require(msg.value == 1 ether);
        num = block.number - 1;
        now = now;
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}