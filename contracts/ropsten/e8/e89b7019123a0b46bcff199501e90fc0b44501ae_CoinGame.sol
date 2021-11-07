/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract CoinGame
{
    mapping(address => uint8)players;
    address owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    // сохраняем адрес игрока, его результат и сумму выигрыша/проигрыша
    event roundResult(address playerAddress, string result, uint value);
    // сохраняем количество переведённых на контракт средств
    // и адрес с которого совершён перевод
    event received(address, uint);
    
    // модификатор, проверяющий, что функция вызывана владельцем контракта
    modifier onlyOwner(address _adr){
        require(_adr == owner);
        _;
    }
    
    // функция для приёма эфира
    receive() external payable {
        // Это вызов ивента - дешёвая операция, она умещается в 2300 газа
        emit received(msg.sender, msg.value);
    }
    
    // функция принимает ставку игрока и "подбрасывает" монетку
    function throwCoin (uint _coin)public payable{
        // проверка, что ставка сделана правильно
        require(_coin == 1 || _coin == 2);
        // проверка, что средств в контракте достаточно для выплаты награды
        require(msg.value * 2 <= address(this).balance);
        // рассчитываем хеш блока
        uint hashBlock = uint(blockhash(block.number - 1));
        // рассчитываем хеш адреса
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        // рассчитываем хеш ставки игрока
        uint hashCoin = uint(keccak256(abi.encode(_coin)));
        // рассчитываем результат броска монетки
        // берём числа не целиком, чтобы избежать ошибки переполнения
        uint8 result = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000))) % 2 + 1);
        
        // в зависимости от выигрыша или проигрыша
        // отправляем или нет эфир игроку и делаем разные записи в журнал
        if (result == _coin){
            payable(msg.sender).transfer(msg.value * 2);
            players[msg.sender] = 1;
            emit roundResult(msg.sender, "Won", msg.value);
        }
        else{
            players[msg.sender] = 2;
            emit roundResult(msg.sender, "Lose", msg.value);
        }
    }
    
    // выводим результат игры для игрока по его адресу
    function resultOfGame()public view returns(string memory){
        if (players[msg.sender] == 2){
            return "You lose";
        }
        else if (players[msg.sender] == 1){
            return "You won";
        }
        else{
            return "You didn't play";
        }
    }
    
    // функция проверки средств на контракте
    function getBalance()public view onlyOwner(msg.sender) returns(uint){
        return address(this).balance;
    }
    
    // функция вывода средств с контракта
    function withdraw()public onlyOwner(msg.sender){
        payable(owner).transfer(address(this).balance);
    }
}