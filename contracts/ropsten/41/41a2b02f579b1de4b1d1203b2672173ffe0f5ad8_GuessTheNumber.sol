/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract GuessTheNumber 
{
    // Переменная для накопления энтропии
    uint entropy = 0;
    
    // структура для хранения информации об игроке
    struct player{
        address playerAddress;
        string playerName;
        uint8 number;
    }
    
    // массив игроков, которые сейчас в игре
    player[] players;
    // массив игроков - победителей последней игры
    player[] winners;
    
    // функция для загадывания игроком числа
    function playGuessingGame (string memory _playerName, uint8 _number)public{
        // добавляем игрока в массив игроков текущей игры
        players.push(player(msg.sender, _playerName, _number));
        // рассчитываем хеш блок
        uint hashBlock = uint(blockhash(block.number - 1));
        // рассчитываем хеш от имени игрока
        uint hashName = uint(keccak256(bytes(_playerName)));
        // рассчитываем хеш от числа, загаданного игроком
        uint hashNumber = uint(keccak256(abi.encode(_number)));
        // накапливаем энтропию
        entropy += (hashBlock % 1000 + hashName % 1000 + hashNumber % 1000);
        // если в игре собралось 5 игроков
        if(players.length == 5){
            // запускаем игру!
            game();
        }
    }
    
    // сама игра
    function game()private{
        // удаляем победителей предыдущего раунда
        delete winners;
        // генерируем случайное число из накопленной энтропии
        uint8 number = uint8(entropy % 10 + 1);
        // проходим по массиву игроков
        for(uint8 i = 0; i < 5; i++){
            // если загаданное число совпало с сгенерированным
            if(players[i].number == number){
                // добавляем игрока в массив победителей
                winners.push(players[i]);
            }
        }
        // делитаем массив игроков - игра готова к новому раунду
        delete players;
    }
    
    // вывод списка победителей
    function getWinners()public view returns(player[] memory){
        return winners;
    }
}