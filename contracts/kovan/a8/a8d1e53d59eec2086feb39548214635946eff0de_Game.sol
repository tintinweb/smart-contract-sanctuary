/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity 0.6.0;

contract Game {
    uint8 ROCK = 0;
    uint8 PAPER = 1;
    uint8 SCISSORS = 2;

    mapping(address => uint8) public choices;

    function play(uint8 choice) external {
        require(choice == ROCK || choice == PAPER || choice == SCISSORS);
        require(choices[msg.sender] == 0);
        choices[msg.sender] = choice;
    }

    function evaluate(address alice, address bob)
        external
        view
        returns (address)
    {
        if (choices[alice] == choices[bob]) {
            return address(0);
        }

        if (choices[alice] == ROCK && choices[bob] == PAPER) {
            return bob;
        } else if (choices[bob] == ROCK && choices[alice] == PAPER) {
            return alice;
        } else if (choices[alice] == SCISSORS && choices[bob] == PAPER) {
            return alice;
        } else if (choices[bob] == SCISSORS && choices[alice] == PAPER) {
            return bob;
        } else if (choices[alice] == ROCK && choices[bob] == SCISSORS) {
            return alice;
        } else if (choices[bob] == ROCK && choices[alice] == SCISSORS) {
            return bob;
        }
    }
}