/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-120 ===

    STATUS: complete
    DEPLOYED AT: 0x...

    VULNERABILITY REPRODUCTION STEPS:
    1. Deploy contract with 2 ether
    2. Call guess()
    3. Mine as many blocks as needed for the blockhash to match


    NOTES:
    @source: https://capturetheether.com/challenges/lotteries/guess-the-random-number/
    @author: Steve Marx

    This vulnerability requires control over miners
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 answer;

    function GuessTheRandomNumberChallenge() public payable {
        require(msg.value == 1 ether);
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