/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

// При необходимости все event можно вытянуть из смартконтракта и обработать

contract MSHPToken 
{
    // Здесь будет хранится адрес владельца контракта
    address owner;
    // Название токена
    string public constant name = "MSHPToken";
    // Символическое обозначение токена
    string public constant symbol = "MSHP";
    // Количество нулей в вашем токене, например в ETH 18 нулей, 1 ETH = 1 000 000 000 000 000 000 wei
    uint8 public constant decimals = 3;
    // Всё количество выпущенных токенов
    uint public totalSupply;
    
    // Сколько и кому принадлежит токенов
    mapping (address => uint) balances;
    // это маппинг разрешений пользоваться чужим кошельком
    mapping(address => mapping(address => uint)) public allowed;
    
    // События, чтобы выполнение этих действий добавлялось в блокчейн
    // И потом было легко парсить
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _from, address indexed _to, uint _value);
    
    // Конструктор сохраняет адрес того, кто создал контракт в перменную owner
    // теперь это владелец токена
    constructor()
    {
        owner = msg.sender;
    }
    
    // Модификатор - проверяет, что метод вызван хозяином токена
    modifier onlyOwner()
    {
    require(owner == msg.sender);
    _;
    }
    
    // Функция эмиссии
    // _to - на какой адрес 
    // _value - сколько зачислить токенов
    function mint(address _to, uint _value) onlyOwner public payable
    {
        // Проверка на переполение
        require(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        // Изменяем количество токенов на адресе
        balances[_to] += _value;
        // Изменяем общую эмиссию токенов
        totalSupply += _value;
    }
    
    // Показывает баланс адреса
    function balanceOf(address _owner) public view returns(uint)
    {
        return balances[_owner];
    }
    
    // Функция пересылки токенов
    function transfer(address _to, uint _value) public payable
    {
        // Проверяем, что у отправителя есть столько токенов и проверяем кошелёк получателя на переполнение
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        // Уменьшаем баланс отправителя
        balances[msg.sender] -= _value;
        // Увеличиваем баланс получателя
        balances[_to] += _value;
        // Записываем событие в блокчейн
        emit Transfer(msg.sender, _to, _value);
    }
    
    // Отправляет деньги с указанного адреса
    // нужна, чтобы смартконтракты умели отправлять токены в с адреса на адрес в логике их работы
    // Нужно чтобы только определённый человек(контракт) мог перевести токены с нашего кошелька
    function transferFrom(address _from, address _to, uint _value) public payable
    {
        // Проверяем, что у отправителя достаточно денег
        // Что нет переполнения
        // Что отправителю разрешено снимать деньги с этого адреса
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to] && allowed[_from][msg.sender] >= _value);
        // Уменьшаем баланс отправителя
        balances[_from] -= _value;
        // Увеличиваем баланс получателя
        balances[_to] += _value;
        // Уменьшаем количество токенов, которые разрешено тратить с этого адреса
        allowed[_from][msg.sender] -= _value;
        // Записываем событие в блокчейн
        emit Transfer(_from, _to, _value);
        // Фиксируем изменения в словаре разрешений
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
    }
    
    // Создаёт разрешение на снятие денег с адреса
    function approve(address _spender, uint _value) public payable
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    // Функция показыает какое количество денег разрешено снимать тому или иному адресу
    function allowance(address _owner, address _spender) public view returns(uint)
    {
        return allowed[_owner][_spender];
    }
}