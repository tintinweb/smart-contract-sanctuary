/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0

//pragma solidity >=0.7.0 <0.9.0;
pragma solidity 0.5.10;
/*Библиотека математики. Была в комплекте с примером кода контракта ERC20. */

library SafeMath 
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b > 0);
        uint256 c = a / b;
	    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b != 0);
        return a % b;
    }
}

/*Сам контракт. */

contract ERC20Standard 
{
	using SafeMath for uint256; // Использование библиотеки выше для типа uint256 (uint). 
	
	/*Поле "owner" имеет "payable", чтобы после уничтожения контракта нынешнему владельцу перевелись 
	  коины, которые имеются на адресе контракта. 
	  Другие поля "public", чтобы при создании токена в кошельке и копировании туда адреса контракта, 
	  необходимые поля заполнялись автоматически. */
	
	address payable owner; // Адрес владельца контракта.
	uint public totalSupply; // Общее количество токенов в контракте. 
	string public name; // Видимое имя контракта. 
	uint8 public decimals; // Делимость. 
	string public symbol; // Сокращённое имя токенов.
	string public version; // Версия контракта. 
	
	/*Далее - структура. В ней будут храниться адерса админов контракта. */
	/*
	struct admin
    {
        address temp; // Адрес. 
        bool isAdmin; // Если адрес админ, то это поле равно True. В противном случае False. 
    }*/
    
	//mapping (address => admin) admins; // "Массив админов".
	mapping (address => uint256) balances; // Массив балансов. 
	mapping (address => mapping (address => uint)) allowed; // Двумерный массив, кому с какого аккаунта можно тратить. 

    /*Этот модификатор шёл вместе с кодом контракта. */

	modifier onlyPayloadSize(uint size) 
	{
		assert(msg.data.length == size + 4);
		_;
	} 
	
	/*Ниже идут ивенты. Я добавил ивенты на события, которые на мой взгляд важны и было бы не
	  плохо их отслеживать. */
	
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event NewOwner(address indexed _oldOwner, address indexed _newOwner);
	//event NewAdmin(address indexed _newAdmin, bool _isAdmin);
	//event EmitTokens(address indexed, address indexed _to, uint _value);
	//event BurningTokens(address indexed _from, address indexed _to, uint _value);
	event BuyTokens(address indexed _who, uint _value);
	event Withdrawal(address indexed _who, address indexed _where, uint _value);
	
	/*Конструктор. Тут заполняются поля с информацией токена и назначается владелец. */
	
	constructor () public
	{
	    totalSupply = 0;
		name = "RI4I CAT";
		decimals = 8;
		symbol = "RI4I";
		version = "1.0";
		owner = msg.sender; // Назначаем создателя владельцем. 
		emit NewOwner(address(0), owner);
	}
	
	/*Функция возвращает баланс введённого адреса (кол-во наших токенов). */

	function balanceOf(address _owner) public view returns (uint) 
	{
		return balances[_owner];
	}
	
	/*Вызвавший функцию ниже указывает адрес и кол-во монет (кому и сколько перевести). 
	  Перевод происходит со счёта вызвавшего. */

	function transfer(address _to, uint _value) public onlyPayloadSize(2*32) 
	{
	    require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    emit Transfer(msg.sender, _to, _value);        
    }

    /*Аналогично функции выше, только можно тратить токены друга (если друг разрешил, конечно). */

	function transferFrom(address _from, address _to, uint _value) public 
	{
	    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    /*Разрешение кому-то тратить наши монетки, и сколько можно потратить наших монеток. */

	function approve(address _spender, uint _value) public 
	{
	    require(_value > 0, "Value < or = 0");
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}
	
	/*Остаток монеток, которые друг может потратить из тех, что мы ему выделили. */

	function allowance(address _spender, address _owner) public view returns (uint) 
	{
		return allowed[_owner][_spender];
	}
	
	/*Назначение нового владельца. */
	
	function setOwner(address payable _who) public
	{
	    require(msg.sender == owner, "You don't have permissions. ");
	    owner = _who;
	    emit NewOwner(msg.sender, owner);
	}
	
	/*Функция назначения администратора. Может использовать только владелец контракта. */
	/*
	function setAdmin(address _newAdmin, bool _status) public
    {
        require(msg.sender == owner, "You don't have permissions. "); // Если вызвавший не владелец, сообщаем ему об этом. 
        admins[_newAdmin].isAdmin = _status; // Иначе назначаем адрес админом. 
        emit NewAdmin(_newAdmin, _status); // Сохраняем в историю, чтобы было на всякий случай. 
    }*/
	
	/*Эмитация токенов на адрес. Могут делать только владельцы или админы. */
	
	/*
	function emitTokens(address _to, uint _value) public
	{
	    require(msg.sender == owner || admins[msg.sender].isAdmin, "You don't have permissions. ");
	    require(_value > 0, "Value < or = 0");
	    balances[_to] = balances[_to].add(_value);
	    totalSupply = totalSupply.add(_value);
	    emit EmitTokens(msg.sender, _to, _value); // "Документируем".
	}*/
	
	/*Зжигание токенов. Так же только для владельцев и админов. */
	
	/*
	function burningTokens(address _to, uint _value) public
	{
	    require(msg.sender == owner || admins[msg.sender].isAdmin, "You don't have permissions. ");
	    require(_value > 0, "Value < or = 0");
	    require(balances[msg.sender] >= _value, "User has insufficient tokens.");
	    balances[_to] = balances[_to].sub(_value);
	    totalSupply = totalSupply.sub(_value);
	    emit BurningTokens(msg.sender, _to, _value); // Записываем событие. 
	}*/
	
	/*Сжигание токенов обычными пользователями. Пользователя пишет сколько, и столько сжигается с его баланса. */
	
	function burning(uint _value) public
	{
	    require(balances[msg.sender] >= _value, "You have fewer tokens. ");
	    require(_value > 0, "Value < or = 0");
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    totalSupply = totalSupply.sub(_value);
	}
	
	/*Покупка токенов за коины. */
	
	function mint() payable external
	{
	    if (msg.value <= 0) revert();
	    balances[msg.sender] = balances[msg.sender].add(msg.value);
	    totalSupply = totalSupply.add(msg.value);
	    emit BuyTokens(msg.sender, msg.value); // Сохраняем действие. 
	}
	
	/*Вывод коинов с контракта на адрес. Доступно только владельцу. */
	
	function withdrawal(address payable _to, uint256 _value) external 
	{
	    require(msg.sender == owner, "You don't have permissions. ");
	    require(_value > 0, "Value < or = 0");
        _to.transfer(_value);
	    emit Withdrawal(msg.sender, _to, _value);
    }
    
    /*Возвращает кол-во коинов на балансе контракта. */
	
	function balanceContract() public view returns(uint)
	{
	    return address(this).balance;
	}
	
	/*Закрытие контракта. Все коины, которые имеются на счету контракта, переводятся 
	  нынешнему владельцу. */
	
	function kill() public
	{
	    require(msg.sender == owner, "You don't have permissions. ");
	    selfdestruct(owner);
	}
}