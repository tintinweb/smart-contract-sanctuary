/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.9;

contract Game{
    uint public ans;
    bool private win;
    uint[10] private inputArray=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    
    struct Player {
        uint guess;
        uint A;
        uint B;
        uint win;
    }
    
    address public creater;
    mapping(address => Player) public players;
    
    constructor() {
        creater = msg.sender;
        ans = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 9000 + 1000;
    }
    
    modifier checkInputRange(uint _input) {
        require(
            (_input >= 1000 && _input < 10000),
            "Please enter 4-digit number."
        );
        _;
    }
    
    function regenerate() public {
        require(
            msg.sender == creater,
            "Only creater can regenerate."
        );
        ans = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 9000 + 1000;
        win = false;
    }
    
    function getA(address guesser) public view returns(uint) {
        return players[guesser].A;
    }
    
    function getB(address guesser) public view returns(uint) {
        return players[guesser].B;
    }
    
    function getWin(address guesser) public view returns(uint) {
        return players[guesser].win;
    }
    
    function guess(address guesser, uint input) public checkInputRange(input) {
        
        require(
            win == false,
            "Someone has find out the answer!"
        );
        
        players[guesser].guess++;
        players[guesser].A = 0;
        players[guesser].B = 0;
        for (uint i = 0; i < 10; i++) {
            inputArray[i] = 0;
        }
        
        if (input == ans) {
            players[guesser].A = 4;
            players[guesser].B = 0;
            players[guesser].win++;
            win = true;
            return;
        }
        
        uint tempi = input;
        uint tempa = ans;
        
        for (uint i = 4; i > 0; i--) {
            if (tempi / (10 ** (i-1)) == tempa / (10 ** (i-1)))
                players[guesser].A++;
            else
                inputArray[tempi / (10 ** (i-1))] += 1;
                
            tempi -= (tempi / (10 ** (i-1))) * (10 ** (i-1));
            tempa -= (tempa / (10 ** (i-1))) * (10 ** (i-1));
        }
        
        tempi = input;
        tempa = ans;
        
        for (uint i = 4; i > 0; i--) {
            if (tempi / (10 ** (i-1)) != tempa / (10 ** (i-1))) {
                if (inputArray[tempa / (10 ** (i-1))] > 0) {
                    inputArray[tempa / (10 ** (i-1))] -= 1;
                    players[guesser].B++;
                }
            }
            
            tempi -= (tempi / (10 ** (i-1))) * (10 ** (i-1));
            tempa -= (tempa / (10 ** (i-1))) * (10 ** (i-1));
        }
        
    }//guess
    
}