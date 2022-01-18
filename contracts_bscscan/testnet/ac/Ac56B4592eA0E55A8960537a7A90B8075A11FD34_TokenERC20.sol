/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Общедоступные переменные маркера
    string public name;
    string public symbol;
    //uint8 public decimals = 18;
    uint8 public decimals;
    // 18 десятичных знаков-настоятельно рекомендуется использовать по умолчанию, избегая его изменения
    uint256 public totalSupply;

    // Здесь создается массив со всеми балансами
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Это создает публичное событя на blockchain, которые будут уведомлять клиентов
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Это уведомляет клиентов о сожженной сумме
    event Burn(address indexed from, uint256 value);

/** 
* Функция конструктора 
* 
* Инициализирует контракт с начальными маркерами поставок для создателя договора 
*/
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokendecimals) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Обновить общее предложение с десятичной суммой
        balanceOf[msg.sender] = totalSupply;                // Отдаем создателю все начальные маркеры
        name = tokenName;                                   // Задайте имя для отображения
        symbol = tokenSymbol;                               // Установить символ для отображения
        decimals = tokendecimals;
    }

/** 
* Внутренняя передача, только может быть вызвана этим контрактом 
*/
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

/** 
* Перенос маркеров 
* 
* Отправить маркеры "_value` на" _to` с вашего счета 
* 
* @param _to адрес получателя 
* @param _value сумма для отправки 
*/

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

/** 
* Перенос маркеров с другого адреса 
* 
* Отправьте маркеры ' _value` в `_to` от имени `_from` 
* 
* @param _from адрес отправителя 
* @param _to адрес получателя 
* @param _value сумма для отправки 
*/

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

/** 
* Установите норму для другого адреса 
* 
* Позволяет "_spender" тратить не более чем "_value" маркеры в вашем имени 
* 
* @param _spender адрес уполномоченного проводить 
* @param _value максимальная сумма, которую они могут потратить 
*/

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

/** 
* Установить разрешение на другой адрес и уведомить 
* 
* Позволяет _spender тратить не более `пределах _value` маркеры в вашем имени, а потом пинг договор об этом 
* 
* @param _spender адрес уполномоченного проводить 
* @param _value максимальная сумма, которую они могут потратить 
* @param _extraData некоторую дополнительную информацию, чтобы отправить утвержденному договору 
*/
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

/** 
* Уничтожение токенов 
* 
* Удалить мдокенов " _value` из системы необратимо 
* 
* @param _value количество токенов, чтобы сжечь 
*/
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Проверьте, достаточно ли у отправителя
        balanceOf[msg.sender] -= _value;            // Вычитать из отправителя
        totalSupply -= _value;                      // Обновления totalSupply
        Burn(msg.sender, _value);
        return true;
    }

/** 
* Уничтожение Токенов из другого аккаунта 
* 
* Удалить маркеры "_value" из системы необратимо от имени "_from". 
* 
* @param _from адрес отправителя * @парам пределах _value количество денег, чтобы сжечь 
*/
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Проверьте, достаточно ли целевого баланса
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Вычитать из основного баланса
        allowance[_from][msg.sender] -= _value;             // Вычитать из резерва отправителя
        totalSupply -= _value;                              // Обновление totalSupply
        Burn(_from, _value);
        return true;
    }
}