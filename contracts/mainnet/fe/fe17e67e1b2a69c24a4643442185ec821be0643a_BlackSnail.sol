pragma solidity ^0.4.8;
/*
AvatarNetwork Copyright
*/

/* Родительский контракт */
contract Owned {

    /* Адрес владельца контракта*/
    address owner;

    /* Конструктор контракта, вызывается при первом запуске */
    function Owned() {
        owner = msg.sender;
    }

    /* Изменить владельца контракта, newOwner - адрес нового владельца */
    function changeOwner(address newOwner) onlyowner {
        owner = newOwner;
    }

    /* Модификатор для ограничения доступа к функциям только для владельца */
    modifier onlyowner() {
        if (msg.sender==owner) _;
    }

    /* Удалить контракт */
    function kill() onlyowner {
        if (msg.sender == owner) suicide(owner);
    }
}

// Абстрактный контракт для токена стандарта ERC 20
// https://github.com/ethereum/EIPs/issues/20
contract Token is Owned {

    /// Общее кол-во токенов
    uint256 public totalSupply;

    /// @param _owner адрес, с которого будет получен баланс
    /// @return Баланс
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice Отправить кол-во `_value` токенов на адрес `_to` с адреса `msg.sender`
    /// @param _to Адрес получателя
    /// @param _value Кол-во токенов для отправки
    /// @return Была ли отправка успешной или нет
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice Отправить кол-во `_value` токенов на адрес `_to` с адреса `_from` при условии что это подтверждено отправителем `_from`
    /// @param _from Адрес отправителя
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice Вызывающий функции `msg.sender` подтверждает что с адреса `_spender` спишется `_value` токенов
    /// @param _spender Адрес аккаунта, с которого возможно списать токены
    /// @param _value Кол-во токенов к подтверждению для отправки
    /// @return Было ли подтверждение успешным или нет
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner Адрес аккаунта владеющего токенами
    /// @param _spender Адрес аккаунта, с которого возможно списать токены
    /// @return Кол-во оставшихся токенов разрешённых для отправки
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
Контракт реализует ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20Token is Token
{

    function transfer(address _to, uint256 _value) returns (bool success)
    {
        //По-умолчанию предполагается, что totalSupply не может быть больше (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
    {
        //По-умолчанию предполагается, что totalSupply не может быть больше (2^256 - 1).
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

/* Основной контракт токена, наследует ERC20Token */
contract BlackSnail is ERC20Token
{

    function ()
    {
        // Если кто то пытается отправить эфир на адрес контракта, то будет вызвана ошибка.
        throw;
    }

    /* Публичные переменные токена */
    string public name;                 // Название
    uint8 public decimals;              // Сколько десятичных знаков
    string public symbol;               // Идентификатор (трехбуквенный обычно)
    string public version = &#39;1.0&#39;;      // Версия

    function BlackSnail(
            uint256 _initialAmount,
            string _tokenName,
            uint8 _decimalUnits,
            string _tokenSymbol)
    {
        balances[msg.sender] = _initialAmount;  // Передача создателю всех выпущенных монет
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

}