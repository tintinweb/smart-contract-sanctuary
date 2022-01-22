/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.7 <0.9.0;

contract Guess {
    uint constant minNumber = 1;
    uint constant maxNumber = 10;

    uint constant hashParts = 5;
    uint constant maxHash = 2 ** 64 / hashParts - 1;
    uint entropy;

    struct Player {
        address addr;
        string nickname;
        uint8 number;
    }
    Player[] players;
    Player[] winners;

    function play(string memory nickname, uint8 number) public {
        require(number >= minNumber && number <= maxNumber);
        players.push(Player(msg.sender, nickname, number));
        uint hash = uint(keccak256(abi.encode(block.number - 1,
                                         msg.sender, nickname, number))) % maxHash;
        entropy += hash;
        if (players.length == hashParts) {
            game();
        }
    }

    function game() internal {
        delete winners;
        uint number = entropy % maxNumber + minNumber;

        for (uint i = 0; i < players.length; ++i) {
            if (players[i].number == number) {
                winners.push(players[i]);
            }
        }
        delete players;
    }

    function getWinners() public view returns(Player[] memory) {
        return winners;
    }
}