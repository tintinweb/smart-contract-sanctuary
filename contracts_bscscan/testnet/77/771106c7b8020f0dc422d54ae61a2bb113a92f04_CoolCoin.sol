/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

// Указываем версию для компилятора
pragma solidity ^0.4.11;


// Инициализация контракта
contract CoolCoin {

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address from, address to, uint256 value);

    event Approval(address from, address to, uint256 value);


    function CoolCoin(){
        decimals = 0;
        totalSupply = 1000;


        // "Отправляем" все токены на баланс того, кто инициализировал создание контракта токена
        balanceOf[msg.sender] = totalSupply;

        // Указываем название токена
        name = "CoolCoin";
        // Указываем символ токена
        symbol = "CC";
    }

    // Внутренняя функция для перевода токенов
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;

        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public {
        require(_value <= allowance[_from][_to]);
        allowance[_from][_to] -= _value;
        _transfer(_from, _to, _value);
    }

    function approve(address _to, uint256 _value) public {
        allowance[msg.sender][_to] = _value;
        Approval(msg.sender, _to, _value);
    }
}