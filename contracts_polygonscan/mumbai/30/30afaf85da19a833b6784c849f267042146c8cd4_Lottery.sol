/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

contract Lottery {

    address payable manager;

    mapping(address => uint) public lastRoll;
    uint nonce;
    
    constructor() {
        manager = payable(msg.sender);
    }

    function _roll() private returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.timestamp, block.difficulty)));
        nonce++;
        return 1 + rand % 6;
    }

    function outcome(uint result) public pure returns (uint) {
        if (result < 7) {
            return 1; // SEVEN DOWN
        } else if (result == 7) {
            return 2; // LUCKY SEVEN
        } else {
            return 3; // SEVEN UP
        }
    }

    function lastOutcome(address addr) public view returns (uint) {
        uint roll = lastRoll[addr];
        if (roll == 0) {
            return 0; // Not participated yet!
        }

        return outcome(roll);
    }
    
    function play(uint chosen) public payable {

        require(chosen >= 1 && chosen <= 3, "you can only chose either of 1,2,3");
        require(msg.value > 0 && msg.value <= 50 ether, "bet should be non-zero and not more than 50");

        uint result = _roll() + _roll();
        uint out = outcome(result);

        lastRoll[msg.sender] = result;
        if(out != chosen) {
            return; // "Uh-oh! You lost."
        }

        uint256 payout = 2 * msg.value;
        if (out == 2) {
            payout = 5 * msg.value;
        }

        require(payout <= balance(), "contract doesn't have enough balance!");
        payable(msg.sender).transfer(payout);
    }

    function withdraw() public restricted payable {
        manager.transfer(address(this).balance);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
}