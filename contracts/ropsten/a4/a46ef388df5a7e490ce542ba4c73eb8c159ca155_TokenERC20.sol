/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity 0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public _tokenPrice;
    uint256 public shareholdersBalance;
    mapping (address => bool) registeredShareholders;
    mapping (uint => address) shareholders;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

 
    event Burn(address indexed from, uint256 value);

    function Owned() public {
        owner = msg.sender;
    }


function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokendecimals, uint tokenPrice) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Обновить общее предложение с десятичной суммой
        balanceOf[msg.sender] = totalSupply;                // Отдаем создателю все начальные маркеры
        name = tokenName;                                   // Задайте имя для отображения
        symbol = tokenSymbol;                               // Установить символ для отображения
        decimals = tokendecimals;
        _tokenPrice = tokenPrice;
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Предотвращение передачи по адресу 0x0. Вместо этого используйте burn()
        require(balanceOf[_from] >= _value); // Проверка, достаточно ли у отправителя
        require(balanceOf[_to] + _value > balanceOf[_to]); // Проверка на переполнение
        uint previousBalances = balanceOf[_from] + balanceOf[_to]; // Сохранить для утверждения в будущем
        balanceOf[_from] -= _value; // Вычитать из отправителя
        balanceOf[_to] += _value; // Добавить то же самое к получателю
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); // Утверждает используются на использование статического анализа для поиска ошибок в коде. Они никогда не должны терпеть неудачу
    }


    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Проверьте, достаточно ли у отправителя
        balanceOf[msg.sender] -= _value;            // Вычитать из отправителя
        totalSupply -= _value;                      // Обновления totalSupply
        Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Проверьте, достаточно ли целевого баланса
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Вычитать из основного баланса
        allowance[_from][msg.sender] -= _value;             // Вычитать из резерва отправителя
        totalSupply -= _value;                              // Обновление totalSupply
        Burn(_from, _value);
        return true;
    }
function mint() payable external {
        require(msg.value > 0 && msg.value < _tokenPrice);
        var numTokens = msg.value / _tokenPrice;
        balanceOf[msg.sender] += numTokens;
        Transfer(0, msg.sender, numTokens);
        if (msg.sender != owner) {
            shareholdersBalance += numTokens;
        }
}
}