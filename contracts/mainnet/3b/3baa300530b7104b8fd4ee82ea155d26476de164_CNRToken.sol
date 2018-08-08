pragma solidity ^0.4.21;


contract Platform
{
    address public platform = 0x709a0A8deB88A2d19DAB2492F669ef26Fd176f6C;

    modifier onlyPlatform() {
        require(msg.sender == platform);
        _;
    }

    function isPlatform() public view returns (bool) {
        return platform == msg.sender;
    }
}


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract BeneficiaryInterface
{
    function getAvailableWithdrawInvestmentsForBeneficiary() public view returns (uint);
    function withdrawInvestmentsBeneficiary(address withdraw_address) public returns (bool);
}


//Интерфейс для ICO контрактов, чтобы те могли говорить CNRToken-у
//о том что ему перевели бабки
contract CNRAddBalanceInterface
{
    function addTokenBalance(address, uint) public;
}


//Интерфейс для фабрики, чтобы она могла добавлять токены
contract CNRAddTokenInterface
{
    function addTokenAddress(address) public;
}

//TODO: может сделать класс TokensCollection, куда вынести всю функциональность из  tokens_map, tokens_arr итд
contract CNRToken is ERC20, CNRAddBalanceInterface, CNRAddTokenInterface, Platform
{
    using SafeMath for uint256;


    //Токен  ERC20
    string public constant name = "ICO Constructor token";
    string public constant symbol = "CNR";
    uint256 public constant decimals = 18;


    //-------------------------ERC20 interface----------------------------------
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) balances;
    ////////////////////////////ERC20 interface/////////////////////////////////

    //Адрес гранд фабрики
    address public grand_factory = address(0);

    //Мапа и массив добавленнх токенов. Нулевой элемент  зарезервирован для
    //эфира. Остальные для токенов
    mapping(address => uint256) public  tokens_map;
    TokenInfo[] public                  tokens_arr;

    //Мапа с забранными сущностями (эфиром, токенами). (адрес кошелька клиента => (индекс токена => сколько уже забрал))
    //По индексу 0 - всегда эфир.
    mapping(address => mapping(uint => uint)) withdrawns;

    function CNRToken() public
    {
        totalSupply = 10*1000*1000*(10**decimals); // 10 mln
        balances[msg.sender] = totalSupply;

        //На нулевом индексе находится эфир
        tokens_arr.push(
            TokenInfo(
                address(0),
                0));
    }


    //Функция получения адресов всех добавленных токенов
    function getRegisteredTokens()
    public view
    returns (address[])
    {
        // ситуация, когда не добавлены токены. <= чтобы убрать пред mythril,
        // который не понимает что в конструкторе забит первый элемент
        if (tokens_arr.length <= 1)
            return;

        address[] memory token_addresses = new address[](tokens_arr.length-1);
        for (uint i = 1; i < tokens_arr.length; i++)
        {
            token_addresses[i-1] = tokens_arr[i].contract_address;
        }

        return token_addresses;
    }

    //Функиця получения данных о всех доступных доходах в ether со всех
    //зарегистрированных контрактов токенов. Чтобы воспользоваться этими
    //доходами нужно для кажжого токена вызвать takeICOInvestmentsEtherCommission
    function getAvailableEtherCommissions()
    public view
    returns(
        address[],
        uint[]
    )
    {
        // ситуация, когда не добавлены токены. <= чтобы убрать пред mythril,
        // который не понимает что в конструкторе забит первый элемент
        if (tokens_arr.length <= 1)
            return;

        address[] memory token_addresses = new address[](tokens_arr.length-1);
        uint[] memory available_withdraws = new uint[](tokens_arr.length-1);
        //Здесь должно быть от 1-го, потому что на 0-ом - эфир
        for (uint i = 1; i < tokens_arr.length; i++)
        {
            token_addresses[i-1] = tokens_arr[i].contract_address;
            available_withdraws[i-1] =
                BeneficiaryInterface(tokens_arr[i].contract_address).getAvailableWithdrawInvestmentsForBeneficiary();
        }

        return (token_addresses, available_withdraws);
    }


    //Функция, которую может дергнуть кто угодно, чтобы на данный  контракт были переведен
    //комиссии с инвестиций в эфире
    function takeICOInvestmentsEtherCommission(address ico_token_address)
    public
    {
        //Проверяем что ранее был! добавлен такой токен
        require(tokens_map[ico_token_address] != 0);

        //Узнаем сколько мы можем вывести бабла
        uint available_investments_commission =
            BeneficiaryInterface(ico_token_address).getAvailableWithdrawInvestmentsForBeneficiary();

        //Запоминаем что бабки забрали
        //запоминаем до перевода, так как потом дергаем external contract method
        tokens_arr[0].ever_added = tokens_arr[0].ever_added.add(available_investments_commission);

        //Переводим бабло на адрес этого контракта
        BeneficiaryInterface(ico_token_address).withdrawInvestmentsBeneficiary(
            address(this));
    }


    //Специально разрешаем получение бабла
    function()
    public payable
    {

    }


    //Метод установки адреса grandFactory, который будет использован
    function setGrandFactory(address _grand_factory)
    public
        onlyPlatform
    {
        //Проверяем чтобы адрес был передан нормальный
        require(_grand_factory != address(0));

        grand_factory = _grand_factory;
    }

    // баланс рассчитывается по формуле:
    // общее количество токенов контракта _token_address, которым владеет контракт CNR
    // умножаем на количество токенов CNR у _owner, делим на totalSupply (получаем долю)
    // и отнимаем уже выведенную _owner&#39;ом сумму токенов
    //Доступный к выводу баланс в токенах некоторого ICO
    function balanceOfToken(address _owner, address _token_address)
    public view
    returns (uint256 balance)
    {
        //Проверка наличия такого токена
        require(tokens_map[_token_address] != 0);

        uint idx = tokens_map[_token_address];
        balance =
            tokens_arr[idx].ever_added
            .mul(balances[_owner])
            .div(totalSupply)
            .sub(withdrawns[_owner][idx]);
        }

    // все как и в balanceOfToken, только используем 0 элемент в tokens_arr и withdrawns[_owner]
    //Доступный к выводу баланс в эфирах
    function balanceOfETH(address _owner)
    public view
    returns (uint256 balance)
    {
        balance =
            tokens_arr[0].ever_added
            .mul(balances[_owner])
            .div(totalSupply)
            .sub(withdrawns[_owner][0]);
    }

    //Функция перевода доступных токенов некоторого ICO на указанный кошелек
    function withdrawTokens(address _token_address, address _destination_address)
    public
    {
        //Проверка наличия такого токена
        require(tokens_map[_token_address] != 0);

        uint token_balance = balanceOfToken(msg.sender, _token_address);
        uint token_idx = tokens_map[_token_address];
        withdrawns[msg.sender][token_idx] = withdrawns[msg.sender][token_idx].add(token_balance);
        ERC20Basic(_token_address).transfer(_destination_address, token_balance);
    }

    //Функиця забирания доступного эфира на указанный кошелек
    function withdrawETH(address _destination_address)
    public
    {
        uint value_in_wei = balanceOfETH(msg.sender);
        withdrawns[msg.sender][0] = withdrawns[msg.sender][0].add(value_in_wei);
        _destination_address.transfer(value_in_wei);
    }


    //Данная функция дложна вызываться из контрактов-токенов, в тот момент когда бенефициару
    //(на контракт бенефициара) переводятся токены
    function addTokenBalance(address _token_contract, uint amount)
    public
    {
        //Проверяем что функция вызывается из ранее добавленноно! контракта токена
        require(tokens_map[msg.sender] != 0);

        //ДОбавление данных обо всех токенах, переведенных бенефициару
        tokens_arr[tokens_map[_token_contract]].ever_added = tokens_arr[tokens_map[_token_contract]].ever_added.add(amount);
    }

    //Функиця добавления нового токена. Данная функция должна вызываться
    //только GrandFactory при создании нового ICO токена
    function addTokenAddress(address ico_token_address)
    public
    {
        //Проверяем чтобы это был вызов из grand_factory
        require(grand_factory == msg.sender);

        //Проверяем что ранее не был доавлен такой токен
        require(tokens_map[ico_token_address] == 0);

        tokens_arr.push(
            TokenInfo(
                ico_token_address,
                0));
        tokens_map[ico_token_address] = tokens_arr.length - 1;
    }



    //------------------------------ERC20---------------------------------------

    //Баланс в токенах
    function balanceOf(address _owner)
    public view
    returns (uint256 balance)
    {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        //        uint withdraw_to_transfer = withdrawn[msg.sender] *  _value / balances[msg.sender];

        for (uint i = 0; i < tokens_arr.length; i++)
        {
            //Сколько забранных сущностей переместить на другой аккаунт
            uint withdraw_to_transfer = withdrawns[msg.sender][i].mul(_value).div(balances[msg.sender]);

            //Перводим забранный доход
            withdrawns[msg.sender][i] = withdrawns[msg.sender][i].sub(withdraw_to_transfer);
            withdrawns[_to][i] = withdrawns[_to][i].add(withdraw_to_transfer);
        }


        //Переводим токены
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);


        //Генерим событие
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        for (uint i = 0; i < tokens_arr.length; i++)
        {
            //Сколько забранных сущностей переместить на другой аккаунт
            uint withdraw_to_transfer = withdrawns[_from][i].mul(_value).div(balances[_from]);

            //Перводим забранный доход
            withdrawns[_from][i] = withdrawns[_from][i].sub(withdraw_to_transfer);
            withdrawns[_to][i] = withdrawns[_to][i].add(withdraw_to_transfer);
        }


        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);


        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    ///////////////////////////////////ERC20////////////////////////////////////

    struct TokenInfo
    {
        //Адрес контракта токена (может выплить потом?)
        address contract_address;

        //Весь доход, переведенный на адрес данного контракта вызовом
        //функции addTokenBalance
        uint256 ever_added;
    }
}