/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract GuessTheNumber 
{
    // Переменная для накопления энтропии
    uint entropy = 0;
    // Номер раунда
    uint round = 1;
    // сумма всех ставок за раунд
    uint sumBet = 0;
    // минимальная ставка
    uint80 minBet;
    // максимальная ставка
    uint80 maxBet;
    // адрес хозяина контракта
    address owner;
    // структура для хранения информации об игроке
    struct player{
        address playerAddress;
        string playerName;
        string playerResult;
        uint8 number;
    }
    
    // массив игроков, которые сейчас в игре
    player[] players;
    // массив игроков - победителей последней игры
    player[] winners;
    
    // сохраняем количество переведённых на контракт средств
    // и адрес с которого совершён перевод
    event received(address, uint);
    // событие, сохранящее номер раунда и выигрышное число раунда
    event winNumberInRound(uint round, uint8 winNumber);
    // событие, сохраняющее номер раунда, адрес, имя и число игрока, а также информацю о его победе или поражении
    event playersInRound(uint round, address playerAddress, string playerName, uint8 number, string result, uint sum);
    
    // модификатор, проверяющий, что функция вызывана владельцем контракта
    modifier onlyOwner(address _adr){
        require(_adr == owner);
        _;
    }
    
    // модификатор, проверяющий, что функция вызывана владельцем контракта
    modifier roundNotStart(){
        require(players.length == 0);
        _;
    }
    
    // контструуктор утсанавливает максимальную и минимальную ставку и адрес хозянина
    constructor(uint80 _minBet, uint80 _maxBet){
        minBet = _minBet;
        maxBet = _maxBet;
        owner = msg.sender;
    }
    
    // функция для приёма эфира
    receive() external payable {
        // Это вызов ивента - дешёвая операция, она умещается в 2300 газа
        emit received(msg.sender, msg.value);
    }
    
    // функция для загадывания игроком числа
    function playGuessingGame (string memory _playerName, uint8 _number)public payable{
        require(minBet <= msg.value && msg.value <= maxBet);
        // проверяем, что передано правильное число
        require(1 <= _number && _number <= 10);
        // добавляем игрока в массив игроков текущей игры
        players.push(player(msg.sender, _playerName, "", _number));
        // суммируем ставки за раунда
        sumBet += msg.value;
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
        // вызываем событие и сохраняем информацию о номере раунда и выигрышном числе
        emit winNumberInRound(round, number);
        // проходим по массиву игроков и узнаем результат каждого
        for(uint8 i = 0; i < 5; i++){
            // если загаданное число совпало с сгенерированным
            if(players[i].number == number){
                // записываем результат игры для игрока
                players[i].playerResult = "Won in the round";
                // добавляем игрока в массив победителей
                winners.push(players[i]);
            }
            else{
                // записываем результат игры для игрока
                players[i].playerResult = "Lost in the round";
                emit playersInRound(round, players[i].playerAddress, players[i].playerName, players[i].number, players[i].playerResult, 0);
            }

        }
        // проходим по массиву победителей и раздаём призы
        for(uint8 i = 0; i < winners.length; i++){
            // делим между всеми игроками сумму выигрыша
            payable(winners[i].playerAddress).transfer(sumBet/winners.length);
            // сохраняем информацию о результатах игроках в раунде
            emit playersInRound(round, winners[i].playerAddress, winners[i].playerName, winners[i].number, winners[i].playerResult, sumBet/winners.length);
        }
        // обнуляем призовой фонд
        sumBet = 0;
        // делитаем массив игроков - игра готова к новому раунду
        delete players;
        // начинаем новый раунд!
        round += 1;
    }
    
    // вывод списка победителей
    function getWinners()public view returns(player[] memory){
        return winners;
    }
    
    // получение призового фонда раунда
    function getSumBet()public view returns(uint){
        return sumBet;
    }
    
    // получение минимальной и максимальной ставки раунда
    function getMinMaxBet()public view returns(uint80, uint80){
        return (minBet, maxBet);
    }
    
    // функция проверки средств на контракте
    function getBalance()public view onlyOwner(msg.sender) returns(uint){
        return address(this).balance;
    }
    
    // установка минимальной и максимальной ставки раунда
    function setBet(uint80 _minBet, uint80 _maxBet)public onlyOwner(msg.sender) roundNotStart{
        minBet = _minBet;
        maxBet = _maxBet;
    }
    
    // функция вывода части средств с контракта
    function withdraw(uint _amount)public onlyOwner(msg.sender) roundNotStart{
        payable(owner).transfer(_amount);
    }
    
    // функция вывода всех средств с контракта
    function withdrawAll()public onlyOwner(msg.sender) roundNotStart{
        payable(owner).transfer(address(this).balance);
    }
}