/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract GuessGame
{
    uint entropy = 0;
    struct Player
    {
        address addr;
        string nickname;
        uint8 number;
    }

    Player[] players;
    Player[] winners;

    function makeBet(string memory nickname, uint8 number) public
    {
        require((1 <= number) && (number <= 10));
        players.push(Player(msg.sender, nickname, number));

        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(bytes(nickname)));
        uint hashNumber = uint(keccak256(abi.encode()));
        entropy += hashBlock % 1000 + hashName % 1000 + hashNumber % 1000;

        if (players.length == 5)
        {
            game();
        }
    }

    function game() private
    {
        delete winners;
        uint8 winNumber = uint8(entropy % 10 + 1);
        for (uint8 i = 0; i < 5; ++i)
        {
            if (players[i].number == winNumber)
            {
                winners.push(players[i]);
            }
        }
        delete players;
    }

    function getWinners() public view returns(Player[] memory)
    {
        return winners;
    }
}