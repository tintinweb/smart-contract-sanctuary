pragma solidity ^0.4.24;

contract Token {

    /// Возвращает общее количество токенов
    function totalSupply() constant returns (uint256 supply) {}

    /// Параметры владельца. Адрес, с которого будут извлекаться токены.
    /// Возвращает текущий баланс.
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// Уведомляет об отправке `_value` токенов на адрес `_to` из `msg.sender`
    /// Параметр _to означает адрес получателя
    /// Параметр _value означает количество токенов, которые будут отправлены
    /// Возвращает информацию, была ли транзакция успешной или нет
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// Уведомляет об отправке `_value` токенов на адрес `_to` из `_from` при условии, что подтверждено `_from`
    /// Параметр _from означает адрес отправителя
    /// Параметр _to означает адрес получателя
    /// Параметр _value означает количество токенов, которые будут отправлены
    /// Возвращает информацию, была ли транзакция успешной или нет
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// Уведомляет `msg.sender` подтвердить `_addr` для отправки `_value` токенов
    /// Параметр _spender означает адрес счета, с которого можно отправлять токены
    /// Параметр _value означает количество токенов, которое разрешено отправить
    /// Возвращает информацию, была ли транзакция успешной или нет
    function approve(address _spender, uint256 _value) returns (bool success) {}
    
    /// Параметр _owner означает адрес владельца токенов
    /// Параметр _spender означает адрес счета, с которого можно отправлять токены
    /// Возвращает информацию об оставшемся количестве токенов, которое можно потратить
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {

        //По умолчанию предполагается, что totalSupply не может быть больше (2^256 - 1).
        //Если токен не содержит totalSupply и можно неограниченно выпускать токены, необходимо следить за переконвертацией токена.
        //Замените оператор if на this one.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        
                if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //Как и указано свыше, замените эту строку ниженаписанной, если желаете защитить контракт от переконвертированных токенов.  
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract RussianCash is StandardToken { // ПОДЛЕЖИТ ИЗМЕНЕНИЮ. Обновить название контракта.

    /* Публичные переменные токена */

    /*
    ВНИМАНИЕ:
    Нижеизложенные переменные ОПЦИОНАЛЬНЫ. Нет строгой необходимости их включать.
    
      Они позволяют кастомизировать контракт токена и не влияют на основные функции.
    Некоторые цифровые-кошельки/интерфейсы могут не поддерживать эти функции.
    */
    string public name;                   // Название токена
    uint8 public decimals;                // Как много показывать десятичных. По умолчание устанавливает значение, равное 18
    string public symbol;                 // Идентификатор: например SBX, XPR и т.д...
    string public version = &#39;H1.0&#39;; 
    uint256 public unitsOneEthCanBuy;     // Как много единиц вашего токена можно купить за 1 ETH?
    uint256 public totalEthInWei;         // WEI равняется минимальному значению ETH (эквивалентно центу в USD или сатоши в BTC). Здесь мы будем хранить все привлеченные ETH через ICO
    address public fundsWallet;           // Куда должны перенаправляться привлеченные ETH?

    // Это конструктор-функция, ее имя должно соответствовать вышенаписанному названию
    function RussianCash() {
        balances[msg.sender] = 1000000000000000000000000000;               // Предоставить создателю контракта все начальные токены. В нашем случае количество равно 1000000000. Если вы хотите, чтобы количество равнялось число X, а десятичные равнялись 5, установите следующее значение X * 100000. (ПОДЛЕЖИТ ИЗМЕНЕНИЮ)
        totalSupply = 1000000000000000000000000000;                        // Обновить общий выпуск (1000000000 для примера) (ПОДЛЕЖИТ ИЗМЕНЕНИЮ)
        name = "Russian Cash";                                   // Установить название токена для отображения на дисплее (ПОДЛЕЖИТ ИЗМЕНЕНИЮ)
        decimals = 18;                                               // Количество десятичных знаков после запятой для отображения на дисплее (ПОДЛЕЖИТ ИЗМЕНЕНИЮ)
        symbol = "RUS";                                             // Идентификатор токена для отображения на дисплее (ПОДЛЕЖИТ ИЗМЕНЕНИЮ)
        unitsOneEthCanBuy = 2500;                                      // Установить цену за единицу вашего токена для ICO (ПОДЛЕЖИТ ИЗМЕНЕНИЮ)
        fundsWallet = msg.sender;                                    // Владелец контракта получает ETH
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Передать сообщение блокчейн-сети

        //Отправить Ether в fundsWallet
        fundsWallet.transfer(msg.value);                               
    }

    /* Верификация и затем вызов контракта */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
       Approval(msg.sender, _spender, _value);

        //вызов функции receiveApproval в контракте, который вы хотите уведомить. Этот процесс по умолчанию создает подпись функции, но в нашем случае это не нужно включать в контракт.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //к этому моменту, вызов к функции должен пройти успешно. 
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}