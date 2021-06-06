/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TokenERC20 {
    string public name;         // Возвращает имя токена    
    string public symbol;       // Возвращает символ токена (обозначение или короткое название)
    uint8 public decimals = 0;  // Возвращает количество знаков после запятой, которое использует токен
                                // было 18; // Для простоты отображения результатов будем применять 0 знаков после запятой, т.е. поработаем с целыми значениями...
    uint256 public totalSupply; // Возвращает общее количество токенов

    mapping (address => uint256) public balanceOf;  // Возвращает баланс аккаунта для заданного адреса
    mapping (address => mapping (address => uint256)) public allowance; // Возвращает сумму, которую первый адресат разрешает снять со счета второму адресату. Снимать можно частями

    // Событие информирующее об успешном переводе токенов
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Событие информирующее об успешном предоставлении права на перевод токенов
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        uint256 initialSupply,      // Всего токенов
        string memory tokenName,    // Наименование
        string memory tokenSymbol   // Обозначение
    ) {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
    }

    // Внутренняя функция: перевод с _from на _to заданного в _value количества токенов
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0), "Sender can't transfer currency to null address");
        // Check if the sender has enough
        require(balanceOf[_from] >= _value, "Sender have no enough currency");
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to], "You sent too much currency");
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    // Перевести с адреса вызывающего (msg.sender) на адрес _to заданного в _value количества токенов
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    // Перевести с адреса _from на адрес _to заданного в _value количества токенов
    // при этом вызывающему (msg.sender) должно быть разрешено переводить с _from значение не менее чем указано в _value
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Sender didn't approved such amount of currency");     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Вызывающий (msg.sender) предоставляет право _spender переводить со своего счета сумму не более _value токенов
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}