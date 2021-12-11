/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Game
{
    struct player
    {
        address player;
        string name;
        uint8 number;
    }

    player[] players;
    player[] winners;

    event roundsEvent(uint round, uint winner);
    event playersEvent(uint round, address player_address, string player_name, uint8 number, string result);

    uint entropy;
    uint round;

    constructor()
    {
        round = 1;
    }

    function play(string calldata _name, uint8 _number) public
    {
        require(_number >= 1 && _number <= 10, "The number must be between 1 and 10");
        players.push(player(msg.sender, _name, _number));

        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(abi.encode(_name)));
        uint hashNumber = uint(keccak256(abi.encode(_number)));

        entropy += hashBlock % 1000 + hashName % 1000 + hashNumber % 1000;

        if (players.length >= 5)
            game();
    }

    function game() private
    {
        delete winners;

        uint8 result = uint8(entropy) % 10 + 1;
        emit roundsEvent(round, result);

        for (uint8 i = 0; i < 5; ++i)
        {
            if (players[i].number == result)
            {
                winners.push(players[i]);
                emit playersEvent(round, players[i].player, players[i].name, players[i].number, "Won in the round");
            }
            else
                emit playersEvent(round, players[i].player, players[i].name, players[i].number, "Lost in the round");
        }

        ++round;
        delete players;
    }

    function get_result() public view returns(player[] memory _winners)
    {
        return winners;
    }
}