/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract GuessTheNumber 
{
    // Переменная для накопления энтропии
    uint entropy = 0;
    // Номер раунда
    uint round = 1;
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
    
    // событие, сохранящее номер раунда и выигрышное число раунда
    event winNumberInRound(uint round, uint8 winNumber);
    // событие, сохраняющее номер раунда, адрес, имя и число игрока, а также информацю о его победе или поражении
    event playersInRound(uint round, address playerAddress, string playerName, uint8 number, string result);
    
    // функция для загадывания игроком числа
    function playGuessingGame (string memory _playerName, uint8 _number)public{
        // проверяем, что передано правильное число
        require(1 <= _number && _number <= 10);
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
        // сюда записывается результат игрока
        string memory result;
        // генерируем случайное число из накопленной энтропии
        uint8 number = uint8(entropy % 10 + 1);
        // вызываем событие и сохраняем информацию о номере раунда и выигрышном числе
        emit winNumberInRound(round, number);
        // проходим по массиву игроков
        for(uint8 i = 0; i < 5; i++){
            // если загаданное число совпало с сгенерированным
            if(players[i].number == number){
                // добавляем игрока в массив победителей
                winners.push(players[i]);
                // игрок выиграл
                result = "Won in the round";
            }
            else{
                // игрок проиграл
                result = "Lost in the round";
            }
            // сохраняем информацию о результатах игроках в раунде
            emit playersInRound(round, players[i].playerAddress, players[i].playerName, players[i].number, result);
        }
        // делитаем массив игроков - игра готова к новому раунду
        delete players;
        // начинаем новый раунд!
        round += 1;
    }
    
    // вывод списка победителей
    function getWinners()public view returns(player[] memory){
        return winners;
    }
}