/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.4.21;

contract LotteryChallenge {
    uint8 answer;

    constructor() public payable {
        require(msg.value == 1 ether);
        answer = uint8(keccak256(blockhash(block.number - 1), now));
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