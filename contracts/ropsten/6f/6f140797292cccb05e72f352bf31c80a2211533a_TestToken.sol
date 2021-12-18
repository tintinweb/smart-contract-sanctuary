/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
 
contract TestToken{
    // Здесь будет хранится адрес владельца контракта
    address owner;
    // Название токена
    string constant name = "TestToken";
    // Символическое обозначение токена
    string constant symbol = "TT";
    // Количество нулей в вашем токене, например в ETH 18 нулей, 1 ETH = 1 000 000 000 000 000 000 wei
    uint8 constant decimals = 3;
    // Всё количество выпущенных копеек токенов. Именно копеек, а не целых токенов
    uint totalSupply = 0;

    // Сколько и кому принадлежит копеек токенов
    mapping(address => uint) balances;
    // Словарь разрешений
    mapping(address => mapping(address => uint)) allowed;

    // Конструктор сохраняет адрес того, кто создал контракт в перменную owner
    // теперь это владелец токена
    constructor(){
        owner = msg.sender;
    }

    // События при трансфере токенов и изменении словаря разрешений
    event Transfer(address, address, uint);
    event Approval(address, address, uint);

    // Функция эмиссии
    // _to - на какой адрес 
    // _value - сколько зачислить токенов
    function mint(address _to, uint _value)public{
        // Проверка, что функцию вызывает хозяин контракта
        require(msg.sender == owner);
        // Изменяем общую эмиссию токенов
        totalSupply += _value;
        // Изменяем количество токенов на адресе
        balances[_to] += _value;
    }

    // Возвращает баланс адреса, вызвавшего эту функцию
    function balanceOf()public view returns(uint){
        return balances[msg.sender];
    }

    // Возвращает баланс адреса _adr
    function balanceOf(address _adr)public view returns(uint){
        return balances[_adr];
    }

    // Отправляет _value копеек токена на адрес _to
    function transfer(address _to, uint _value)public{
        // Проверяем, что у отправителя есть достаточное количество токенов
        require(balances[msg.sender] >= _value);
        // Уменьшаем баланс отправителя
        balances[msg.sender] -= _value;
        // Увеличиваем баланс получателя
        balances[_to] += _value;
        // Записываем событие
        emit Transfer(msg.sender, _to, _value);
    }

    // Отправляет _value копеек токена с адреса _from на адрес _to
    function transferFrom(address _from, address _to, uint _value)public{
        // Проверяем, что у отправителя есть достаточное количество токенов        
        require(balances[_from] >= _value);
        // Проверяем, что у msg.sender есть право потратить _value копеек токенов _from
        require(allowed[_from][msg.sender] >= _value);
        // Уменьшаем баланс отправителя        
        balances[_from] -= _value;
        // Увеличиваем баланс получателя
        balances[_to] += _value;
        // Уменьшаем количество токенов, которые разрешено тратить с адреса _from
        allowed[_from][msg.sender] -= _value;
        // Записываем события
        emit Transfer(_from, _to, _value);
        emit Approval(_from, _to, allowed[_from][msg.sender]);
    }

    // Создаёт разрешение на трансфер токенов с адреса
    function approve(address _spender, uint _value)public{
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    // Функция показыает какое количество токенов разрешено тратить тому или иному адресу
    function allownce(address _from, address _spender) public view returns(uint){
        return allowed[_from][_spender];
    }
}