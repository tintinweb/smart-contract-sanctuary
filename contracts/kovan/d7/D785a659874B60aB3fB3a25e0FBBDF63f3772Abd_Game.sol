/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

/**@title rock paper scissors game. */
contract Game {
    
    //1. contract state which holds the last move
    // rock = 0 
    // paper = 1 
    // scissors = 2 
    
    uint public state = 0;

    event logOutcome(address, string, uint);
    // update event with move, player and result --> for subgraph development
    // idea: create a player entity in the subgraph which also marks his play history? and if he has peaked or not
    
    
    //1.5 for easy win
    function peakState() public view returns(uint) {
        return state;
    }
    
    function updateState(uint _move) private  {
        state = _move;
    }
    
    //2. contract function with "move" as input
    function playMove(uint _move) public returns(string memory) {
        if (state == _move) {

            emit logOutcome(msg.sender, "draw", _move);
        }
        else if (_move == 2 && state == 0) {
            updateState(_move);
            emit logOutcome(msg.sender, "you lose", _move);
        }
        else if (_move == 2 && state == 1) {
            updateState(_move);
            emit logOutcome(msg.sender, "you win", _move);
        }
        else if (_move == 1 && state == 0) {
            updateState(_move);
            emit logOutcome(msg.sender, "you win", _move);
        }
        else if (_move == 1 && state == 2) {
            updateState(_move);
            emit logOutcome(msg.sender, "you lose", _move);
        }
        else if (_move == 0 && state == 1) {
            updateState(_move);
            emit logOutcome(msg.sender, "you win", _move);
        }
        else  {
            updateState(_move);
            emit logOutcome(msg.sender, "you lose", _move);
        }
    }
        
    
    function returnNumber(string memory _random) public pure returns(string memory) {
        return _random;
    }
}