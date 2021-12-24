/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Объявление контракта
contract Monetka
{
    
    mapping(address => uint8) players;

    function play_game(uint8 num) public
    {
        require(num == 1 || num == 2, "Invalid value");
        uint hashBlock = uint(blockhash(block.number));
        uint hashAdress = uint(keccak256(abi.encode(msg.sender)));
        uint hashCoin = uint(keccak256(abi.encode(num)));
        uint8 ans = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdress % 1000 + hashCoin % 1000)))% 2 + 1);

        if (ans == num)
        {
            players[msg.sender] = 1;
        }
        else
        {
            players[msg.sender] = 2;
        }


    }

    function game_result() public view returns(string memory)
    {
        if (players[msg.sender] == 0)
        {
            return "Didnt play";
        }
        if (players[msg.sender] == 1)
        {
            return "Win";
        }
        if (players[msg.sender] == 2)
        {
            return "Loose";
        }
    }
    
    
}