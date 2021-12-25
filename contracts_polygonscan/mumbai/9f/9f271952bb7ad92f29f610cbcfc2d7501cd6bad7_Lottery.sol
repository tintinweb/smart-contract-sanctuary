/**
 *Submitted for verification at polygonscan.com on 2021-12-24
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

contract Lottery {

    // contract owner
    address payable manager;

    // stores last roll result for a player
    mapping(address => uint[2]) public lastRoll;

    // used for random number generation
    uint64 nonce = 0;
    uint64 modulo = 100000007;

    // flag to pause game
    bool gameOn;
    
    constructor() {
        manager = payable(msg.sender);
        gameOn = true;
    }

    function _roll() private returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.timestamp, block.difficulty)));
        nonce= (nonce + uint64(block.timestamp))%100000007;
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

    function lastOutcome(address addr) public view returns (uint[2] memory) {
        uint[2] memory roll_values = lastRoll[addr];
        return roll_values;
    }
    

    function play(uint chosen) public payable {
        require(gameOn == true,"Game is currenty paused. Please wait till further notice");
        require(chosen >= 1 && chosen <= 3, "you can only chose either of 1,2,3");
        require(msg.value == 0.2 ether, "bet is only acceptable for 20 MATIC");
        require(msg.value <= 5 * balance(), "contract doesn't have enough balance!");

        uint[2] memory result_values;
        result_values[0] = _roll();
        result_values[1] = _roll();

        uint result = result_values[0] + result_values[1];
        uint out = outcome(result);
    
        lastRoll[msg.sender] = result_values;
        if(out != chosen) {
            return; // "Uh-oh! You lost."
        }

        uint256 payout = 2 * msg.value;
        if (out == 2) {
            payout = 5 * msg.value;
        }
        payable(msg.sender).transfer(payout);
    }

    function changeGameStatus(bool _gameOn) public restricted {
        gameOn = _gameOn;
    }

    function resetNonce(uint64 _nonce) public restricted {
        nonce = _nonce;
    }

    function resetModulo(uint64 _modulo) public restricted {
        modulo = _modulo;
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