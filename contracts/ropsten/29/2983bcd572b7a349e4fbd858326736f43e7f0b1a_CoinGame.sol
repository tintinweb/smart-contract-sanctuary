/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract CoinGame
{
    mapping(address => uint8)players;
 
    // функция принимает ставку игрока и "подбрасывает" монетку
    function throwCoin (uint _coin)public{
        // проверка, что ставка сделана правильно
        require(_coin == 1 || _coin == 2);
        // рассчитываем хеш блока
        uint hashBlock = uint(blockhash(block.number - 1));
        // рассчитываем хеш адреса
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        // рассчитываем хеш ставки игрока
        uint hashCoin = uint(keccak256(abi.encode(_coin)));
        // рассчитываем результат броска монетки
        // берём числа не целиком, чтобы избежать ошибки переполнения
        uint8 result = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000))) % 2 + 1);
        
        // проверяем результат игры и записываем результат в словарик
        if(result == _coin){
            players[msg.sender] = 1;
        }
        else{
            players[msg.sender] = 2;           
        }

    }
    
    // выводим результат игры для игрока по его адресу
    function resultOfGame()public view returns(string memory){
        if (players[msg.sender] == 0){
            return "You didn't play";
        }
        if (players[msg.sender] == 1){
            return "You won";
        }
        if (players[msg.sender] == 2){
            return "You lose";
        }
    }
}