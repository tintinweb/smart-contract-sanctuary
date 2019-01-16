pragma solidity ^0.4.25;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
    uint256 c = a / b;
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

contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);


    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Platform
{
    address public platform = address(0);

    constructor()
    public
    {
        //Ставим платформу только если она НЕ! захардкожена
        if (platform == address (0))
        {
            platform = msg.sender;
        }
    }


    modifier onlyPlatform() {
        require(msg.sender == platform);
        _;
    }

    modifier onlyWhenPlatformIsTxOrigin() {
        require(tx.origin == platform);
        _;
    }

    function isPlatform() public view returns (bool) {
        return platform == msg.sender;
    }

    function setPlatform(address new_platform)
    public
        onlyPlatform
    {
        require(new_platform != address(0));

        platform = new_platform;
    }
}

contract CINStockToken is ERC20Basic {

    using SafeMath for uint256;


    //------------------------------INTERFACE-------------------------------------

    //Функция должна быть реализована у класса наследника чтобы избежать
    //добавления дохода до тех пор пока это не положено
    function checkCanAddStockProfit() internal view returns (bool);

    //Функция должна быть реализована у класса наследника чтобы
    //и вызываться через this.moveInvestmentsBaseCompany , чтобы при передаче токенов
    //происходило перераспределение инвестиций
    function moveInvestmentsBaseCompany(address, address, uint, uint) public;

    ////////////////////////////////INTERFACE//////////////////////////////////////

    //Балансы
    mapping (address => uint256) balances;

    //Мапа с забранными доходами
    mapping (address => uint256) withdrawn;

    uint public constant         decimals = 18;

    //общий распределяемый доход перечисленный на адрес контракта
    uint internal full_profit;

    //Общее количество забранных доходов
    uint internal full_withdrawn_profit;

    //Событие эмитируется когда кто то добавляет доход
    event profitAdded(uint value);

    //Событие эмитируется когда кто то забирает свою часть дохода
    event profitWithdrawn(address withdawer, uint value);


    //Добавить доход который будет распределен между акционерами
    function addStockProfitInternal(uint _value)
    internal
    {
        require(checkCanAddStockProfit());
        full_profit = full_profit.add(_value);
        emit profitAdded(_value);
    }

    //Весь доход добавленный за все время
    function fullProfit()
    public view
    returns (uint)
    {
        return full_profit;
    }

    //Весь доход забранный акционерами  за все время
    function fullWithdrawnProfit()
    public view
    returns (uint)
    {
        return full_withdrawn_profit;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        //Запрещаем переводить на контракт
        require(_to != address(this));

        //Перемещаем инвестиции
        this.moveInvestmentsBaseCompany(msg.sender, _to, _value, balances[msg.sender]);

        //Сколько забранного дохода переместить на другой аккаунт
        uint withdraw_to_transfer = withdrawn[msg.sender];
        withdraw_to_transfer = withdraw_to_transfer.mul(_value);
        withdraw_to_transfer = withdraw_to_transfer.div(balances[msg.sender]);

        //Переводим токены
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        //Перводим забранный доход
        withdrawn[msg.sender] = withdrawn[msg.sender].sub(withdraw_to_transfer);
        withdrawn[_to] = withdrawn[_to].add(withdraw_to_transfer);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    //Фуникция для осуществления возврата токенов со счета from на баланс контракта.
    //Вызывается только изнутри контракта!
    function returnTokensToContractFrom(address from)
    internal
    {
        uint balance = balances[from];
        balances[from] = balances[from].sub(balance);
        balances[this] = balances[this].add(balance);
    }

    //Получить доступное для вывода количество дохода (вызывается с профиля акционера)
    function getAvailableWithdrawProfitValue(address addr)
    public view
    returns (uint)
    {
        require(addr != address(0));
        require(addr != address(this));


        uint available_withdraw_wei = balances[addr];
        available_withdraw_wei = available_withdraw_wei.mul(full_profit);
        available_withdraw_wei = available_withdraw_wei.div(totalSupply.sub(balances[this]));
        available_withdraw_wei = available_withdraw_wei.sub(withdrawn[addr]);

        return available_withdraw_wei;
    }



    //Баланс в токенах конкретного акционера
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    //Баланс забранного дохода
    //#warning (возможно нужно сделать msg.sender)
    function withdrawnOf(address _owner) public constant returns (uint256) {
        return withdrawn[_owner];
    }
}


contract StandardCINStockToken is ERC20, CINStockToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        //Запрещаем переводить на контракт
        require(_to != address(this));

        //Перемещаем инвестиции
        this.moveInvestmentsBaseCompany( _from, _to, _value,balances[_from]);


        //Сколько забранного дохода переместить на другой аккаунт
        //withdraw_to_transfer = withdrawn[msg.sender] *   _value / balances[_from];
        uint withdraw_to_transfer = withdrawn[_from];
        withdraw_to_transfer = withdraw_to_transfer.mul(_value);
        withdraw_to_transfer = withdraw_to_transfer.div(balances[_from]);

        //Переводим токен
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        //Перводим забранный доход
        withdrawn[_from] = withdrawn[_from].sub(withdraw_to_transfer);
        withdrawn[_to] = withdrawn[_to].add(withdraw_to_transfer);


        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        //Запрещаем переводить на контракт
        require(_spender != address(this));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        //Запрещаем переводить на контракт
        require(_spender != address(this));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        //Запрещаем переводить на контракт
        require(_spender != address(this));

        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract DebugNow
{
    uint  public                            DEBUG_NOW;

    // Функция для дебага, позволяет устанавливать DEBUG_NOW
    function setDebugNow(uint epoch)
    public
    {
        DEBUG_NOW = epoch;
    }

    // Функция для дебага, используется ТОЛЬКО для получения значения DEBUG_NOW
    // не используется в контрактах, оставлена для совместимости с JS
    function getDebugNow()
    public view
    returns(uint)
    {
        return DEBUG_NOW;
    }

    // функция-обертка для получения текущего времени
    // теперь используется в контрактах везде, где нужно получить время
    function currentTime()
    public view
    returns(uint)
    {
        return DEBUG_NOW;
        // для перевода в боевой режим достаточно вернуть тут now
        // return now;
    }
}

contract OwnerInterface
{
    function canChangeOwnerParams() internal returns (bool);
    function canSetNewOwnerPercentage(uint percentage) internal returns (bool);
}

contract Owner is OwnerInterface, Platform
{
    address public owner = address(0);

    //Доля токенов владельца в эмиссии
    uint   public                   OWNER_TOKEN_PERCENTAGE = 0;
    //Количество инвестиций который забрал owner
    uint   internal              _all_investments_withdrawn_by_owner;

    constructor()
    public
    {
        require(OWNER_TOKEN_PERCENTAGE <= 100);

        //Ставим платформу только если она НЕ! захардкожена
        if (owner == address(0))
        {
            owner = msg.sender;
        }
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    function isOwner()
    public view returns (bool)
    {
        return owner == msg.sender;
    }

    //Функция установки владельца. Может быть вызвана только раз
    function setOwner(address new_owner)
        onlyPlatform
    public
    {
        require(new_owner != address(0));
        require(canChangeOwnerParams());

        owner = new_owner;
    }

    //Функция установки процента токенов, которые будут отданы владельцу
    //вызывать можно сколько угодно раз, но только во время инициализации
    function setOwnerTokenPercentage(uint new_percentage)
        onlyOwner
    public
    {
        require(canSetNewOwnerPercentage(new_percentage));
        OWNER_TOKEN_PERCENTAGE = new_percentage;
    }

    //Функция получения количества всех ЗАБРАННЫХ инвестиций заемщиком
    function getAllInvestmentsWithdrawnByOwner()
    public view
    returns (uint)
    {
        return _all_investments_withdrawn_by_owner;
    }
}


contract BeneficiaryInterface
{
    function getAvailableWithdrawInvestmentsForBeneficiary() public view returns (uint);
    function withdrawInvestmentsBeneficiary(address withdraw_address) public;
    function canChangeBeneficiaryParams() internal returns (bool);
}


contract Beneficiary is BeneficiaryInterface, Platform
{
    address public                  beneficiary = address(0);

    //Процент токенов который забирает контракт-токен площадки
    uint public                     BENEFICIARY_TOKEN_PERCENTAGE = 0;

    //Процент эфира, который забирает контракт-токен площадки
    uint public                     BENEFICIARY_INVESTMENTS_PERCENTAGE = 0;

    //Сколько  уже забрал бенефициар
    uint internal                   _all_investments_withdrawn_by_beneficiary = 0;


    constructor()
    public
    {
        require(BENEFICIARY_TOKEN_PERCENTAGE <= 100);
        require(BENEFICIARY_INVESTMENTS_PERCENTAGE <= 100);
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }

    //Функция получения количества всех ЗАБРАННЫХ инвестиций заемщиком
    function getAllInvestmentsWithdrawnByBeneficiary()
    public view
    returns (uint)
    {
        return _all_investments_withdrawn_by_beneficiary;
    }

    function setBeneficiary(address new_beneficiary)
    public
        onlyPlatform
    {
        require(new_beneficiary != address(0));
        require(canChangeBeneficiaryParams());

        beneficiary = new_beneficiary;
    }
}


contract BaseInvestmentCompany is  Beneficiary, DebugNow, Owner
{
    using SafeMath for uint256;

    //Токен  ERC20. Функциональность размещена здесь, чтобы не дублировать в каждом файле
    string public               name;
    string public               symbol;
    uint public constant        decimals = 18;

    uint8 public constant       MAX_NAME_LENGTH = 32;
    uint8 public constant       MAX_SYMBOL_LENGTH = 4;


    // количество wei в одном токене
    // (1 ETH = 1&#39;000&#39;000&#39;000&#39;000&#39;000&#39;000 wei)
    // (1 ERC20 Token = 1&#39;000&#39;000&#39;000&#39;000&#39;000&#39;000 wei)
    uint256 public constant     WEI_COUNT_IN_ONE_TOKEN = uint256(10) ** decimals;

    //Размер минимальной инвестиции
    uint   public               min_investment_size_in_wei = 0;


    //Все забранные назад инвестиции
    uint   internal              _all_investments_withdrawn_back;

    //Этапы
    Phase[] internal            _phases;


    //Флаг факта вызова функции, подтверждающей добавление фаз
    bool internal               _phases_committed;

    //Захардкоженные! ограничения на количества этапов
    uint public constant        MAX_PHASES_COUNT = 5;
    uint public constant        MAX_SUBPHASES_COUNT  = 5;


    //------------------------ Interface ---------------------------------------

    //Функиця забирания назад инвестиций для сфейленного или отмененного проекта
    //Реализация должна быть в классе наследнике, так же наследуемом от токена
    function withdrawMyInvestmentsBack() public;

    //Функция проверки возможности добавления этапа из класса наследника.
    //Реализует проверку со стороны наследника
    function checkCanAddPhaseDerived(Phase phase) internal view returns (bool);

    //Функция подтверждения фаз из класса наследника.
    //Реализует завершение инициализации класса наследника
    function commitPhasesDerived() internal;

    //Функция реализующая передачу инвестиций с контракта на некий адрес
    //Предназначена для вызова только! через this.transferFromContractTo
    function transferFromContractTo(address, uint) public;

    //Функция проверки инициализированности контракта. Сейчас реализуется в
    //классе наследнке для учета особенностей его инициализации. В ней ОБЯЗАТЕЛЬНО
    //должен проверяться флаг _phases_committed
    function isInitialized() public view returns (bool);

    //Функция получения баланса инвестиций контракта. В зависимости от
    //инвестируемой сущности работает по разному (ETH или ERC20)
    function getBalance() public view returns (uint);

    //Функция реализуемая у наследника, возвращающая тип контракта в виде строки
    function getContractType() public pure returns (string);
    ////////////////////////// Interface ///////////////////////////////////////


    //------------------------ Events -------------------------------------------

    //Событие когда owner забрал инвестиции
    event InvestmentsWithdrawnByOwner(address withdraw_address, uint value);

    //Событие когда инвестиция была сделана
    event InvestmentMade(address investor,  uint invest_value,  uint tokens_value);

    ////////////////////////// Events ///////////////////////////////////////////


    //Конструктор. Проверка констант
    constructor()
    public
    {
        require(BENEFICIARY_TOKEN_PERCENTAGE.add(OWNER_TOKEN_PERCENTAGE) <= 100);
    }


    // Fallback. Деньги на контракт можно ввести только через invest или addProfit
    function()
    public payable
    {
        revert();
    }

    function canChangeBeneficiaryParams() internal returns (bool)
    {
        return (state() == CompanyState.waiting_for_initialization);
    }

    function canChangeOwnerParams() internal returns (bool)
    {
        return (state() == CompanyState.waiting_for_initialization);
    }

    // можно поставить 0 или любое значение до 100 - BENEFICIARY_TOKEN_PERCENTAGE
    function canSetNewOwnerPercentage(uint percentage) internal returns (bool)
    {
        return (state() == CompanyState.waiting_for_initialization)
               &&
               (percentage.add(BENEFICIARY_TOKEN_PERCENTAGE) <= 100);
    }

    //------------------------Инициализация. Создание этапов. Задание имени и символа токена-------------------

    //Метод установки имени и символа токена
    function setTokenNameSymbol(
        string       token_name,
        string       token_symbol)
            onlyOwner
    public
    {
        require(state() == CompanyState.waiting_for_initialization);
        require(bytes(name).length==0 && bytes(symbol).length==0);
        require(bytes(token_name).length <= MAX_NAME_LENGTH);
        require(bytes(token_symbol).length <= MAX_SYMBOL_LENGTH);

        name = token_name;
        symbol = token_symbol;
    }

    //Функция добавления этапа. Должна быть вызвана между
    //setTokenNameSymbol и commitPhases
    function addPhase(
        uint32   start_time,
        uint[]   prices_in_wei,
        uint32[] prices_in_wei_ends,
        uint     phase_emission, // В штуках токенов (без центов)
        uint     min_tokens_to_sell // В штуках токенов (без центов)
    )
        onlyOwner
    public
    {
        require(state() == CompanyState.waiting_for_initialization);

        //Создаем этап из входящих данных
        Phase memory phase;
        phase.start_time =  start_time;
        phase.prices_in_wei = prices_in_wei;
        phase.prices_in_wei_ends = prices_in_wei_ends;
        phase.phase_emission = phase_emission.mul(WEI_COUNT_IN_ONE_TOKEN);
        phase.min_tokens_to_sell = min_tokens_to_sell.mul(WEI_COUNT_IN_ONE_TOKEN);

        //Проверяем возможность добавления фазы у базы и наследника
        require(checkCanAddPhaseBase(phase));
        require(checkCanAddPhaseDerived(phase));

        //Если проверки прошли - добавляем этап
        _phases.push(phase);
    }

    //Функция подтверждения этапов. Должна быть вызвана, иначе контракт
    //не перерейдет в состояние initialized
    function commitPhases()
        onlyOwner
    public
    {
        require(state() == CompanyState.waiting_for_initialization);
        require(_phases.length !=0);
        require(!_phases_committed);

        commitPhasesDerived();

        _phases_committed = true;
    }


    //Внутренняя функция проверки возможности добавления этапа
    function checkCanAddPhaseBase(Phase phase)
    internal view
    returns (bool)
    {
        //Проверка максимального количества этапов
        //вообще по идее должно быть _phases.length == MAX_PHASES_COUNT но для подстраховки >=
        if (_phases.length >= MAX_PHASES_COUNT)
        {
            return false;
        }

        //Для любого этапа заложено минимальное значение продаваемых токенов, ибо без него нету цели
        if (phase.min_tokens_to_sell == 0)
        {
            return false;
        }

        //Проверка чтобы массивы были непустые и соответствующих длин
        if (phase.prices_in_wei.length == 0 ||  phase.prices_in_wei.length != phase.prices_in_wei_ends.length)
        {
            return false;
        }

        //Проверка максимального количества скидочных этапов
        //вообще по идее должно быть phase.prices_in_wei.length == MAX_SUBPHASES_COUNT но для подстраховки >=
        if (phase.prices_in_wei.length >= MAX_SUBPHASES_COUNT )
        {
            return false;
        }

        //Проверка времени начала этапа - должно быть в будущем
        if (phase.start_time <= currentTime())
        {
            return false;
        }

        //Этапы должны добавляться последовательно, от меньшего по дате к позднему
        if (_phases.length > 0)
        {
            if (phase.start_time <= getEndTime())
            {
                return false;
            }
        }

        //Проверка содержания массивов
        uint32 last_date = phase.start_time;
        for (uint i=0; i < phase.prices_in_wei.length; i++)
        {
            //Проверка на наличие нолевых цен (щас недопустимо ибо не тестилось и не проверялось)
            if (phase.prices_in_wei[i] == 0)
            {
                return false;
            }

            //Даты окончания скидочных периодов должны возрастать
            if (phase.prices_in_wei_ends[i] <= last_date)
            {
                return false;
            }

            last_date = phase.prices_in_wei_ends[i];
        }

        //Проверка соответствия типов эмиссии (чтоы все этапы били или лимитированными, или нет)
        if (_phases.length > 0)
        {
            if ((_phases[_phases.length-1].phase_emission == 0 && phase.phase_emission > 0) ||
                (_phases[_phases.length-1].phase_emission  > 0 && phase.phase_emission == 0))
            {
                return false;
            }

        }

        //Проверка количеств токенов. Если эмиссия этапа ограничена, то количество токенов, доступных для продажи,
        //должно быть больше или равно минимальному количеству токенов для успешного завершения этапа
        //расчет реализует функция getAvailableTokensToSellTillPhaseIdxValue
        if (phase.phase_emission != 0)  //Это значит что тип эмиссии этапа - лимитированный
        {
            uint available_to_sell =
                phase.phase_emission
                    .mul(
                        uint256(100)
                        .sub(BENEFICIARY_TOKEN_PERCENTAGE)
                        .sub(OWNER_TOKEN_PERCENTAGE))
                    .div(100);

            if (available_to_sell < phase.min_tokens_to_sell)
            {
                return false;
            }
        }

        return true;
    }
    //////////////////////////Инициализация. Создание этапов. Задание имени и символа токена///////////////////



    //Функция проверки возможности инвестировани
    function checkCanInvestInternal(address investor, uint invest_value)
    internal view
    returns(bool)
    {
        return
            (investor != owner) &&
            (investor != platform) &&
            (invest_value >= min_investment_size_in_wei) &&
            (state() == CompanyState.collecting);
    }

    //Функция отмены кампании. Может быть отменена только до начала,
    //или во время сбора инвестиций
    function cancel()
    public
        onlyOwner
    {
        require((state() == CompanyState.initialized) || (state() == CompanyState.collecting));
        //Здесь ни один из этапов не failed и не cancelled
        for (uint i = 0; i < _phases.length; i++)
        {
            PhaseState p_state = getPhaseState(i);
            if (p_state == PhaseState.waiting_for_collecting || p_state == PhaseState.collecting)
            {
                _phases[i].cancelled = true;
            }
        }
    }

    //Получение текущего состояния кампании
    function state()
    public view
    returns (CompanyState)
    {
        //Если кампания не инициализирована
        if (!isInitialized())
        {
            return CompanyState.waiting_for_initialization;
        }

        // если есть хоть один отмененный этап - считаем кампанию отмененной
        for (uint i = 0; i < _phases.length; i++)
        {
            if (getPhaseState(i) == PhaseState.cancelled)
            {
                return CompanyState.cancelled;
            }
        }

        //Если компания (сбор средств) еще не началась
        if (currentTime() < getStartTime())
        {
            return CompanyState.initialized;
        }

        // сюда попадаем в двух случаях: если компания идет прямо сейчас, или если уже кончилась
        // в обеих ситуациях могут быть сфейленые этапы
        // если есть хоть один такой этап - сфейлим компанию
        for (i = 0; i < _phases.length; i++)
        {
            if (getPhaseState(i) == PhaseState.failed)
            {
                return CompanyState.collecting_failed;
            }
        }

        // Здесь кампания идет и не сфейлилась
        if (currentTime() >= getStartTime() &&
            currentTime() <= getEndTime())
        {
            return CompanyState.collecting;
        }

        // кампания закончилась и не сфейлилась. Здесь без условия выполяется currentTime()>end_time
        return CompanyState.collecting_succeed;
    }


    //Функиция получения текущего количества продаваемых токенов
    //на данном этапе last_phase_idx, за минусом уже проданных ранее
    function getAvailableTokensToSellTillPhaseIdxValue(
        uint last_phase_idx
    )
    public view
    returns (uint available_to_sell)
    {
        require(last_phase_idx < _phases.length);

        //Если вся камапания unlimited - возвращаем 0
        if (getEmissionType() == EmissionType.unlimited)
        {
            return 0;
        }

        for (uint i = 0; i <= last_phase_idx; i++)
        {
            available_to_sell = available_to_sell.add(getAvailableTokensToSellCurrentPhaseIdx(i));
        }
        return available_to_sell;
    }

    //Количество потенциально продаваемых токенов на данном этапе. Если проект нелимитированный
    //то функция вернет 0
    function getAvailableTokensToSellCurrentPhaseIdx(uint idx)
    public view
    returns(uint)
    {
        require(idx < _phases.length);

        //Если вся камапания unlimited - возвращаем для любого из этапов
        if (getEmissionType() == EmissionType.unlimited)
        {
            return 0;
        }

        return  _phases[idx].phase_emission
                    .mul(
                        uint256(100)
                        .sub(BENEFICIARY_TOKEN_PERCENTAGE)
                        .sub(OWNER_TOKEN_PERCENTAGE))
                    .div(100)
                    .sub(_phases[idx].tokens_sold);
    }


    //Функция получения количества этапов
    function getPhasesCount()
    public view
    returns (uint)
    {
        return _phases.length;
    }


    // Функиция получения массивов дат и цен
    function getPhasePricesPeriods(uint idx)
    public view
    returns (
        uint[] prices_in_wei,
        uint32[] prices_in_wei_ends)
    {
        require(idx < _phases.length);

        return (
            _phases[idx].prices_in_wei,
            _phases[idx].prices_in_wei_ends
        );
    }


    //Функция получения данных об этапе
    function getPhaseStatus(uint idx)
    public view
    returns (
        uint32, // start_time (время начала)
        uint32, // end_time (время конца)
        uint,   // min_tokens_to_sell (минимальное количество токенов, которые нужно продать для успешного завершения этапа)
        uint,   // tokens_sold (количество проданых токенов)
        uint,   // phase_emission (количество выпущенных токенов)
        uint,   // investments_collected (количество собранных ETH)
        uint    // available_to_sell (количество токенов, выпущенных в продажу: phase_emission минус комиссия площадки)
    )
    {
        require(idx < _phases.length);
        return (
            _phases[idx].start_time,
            _phases[idx].prices_in_wei_ends[_phases[idx].prices_in_wei_ends.length-1],
            _phases[idx].min_tokens_to_sell,
            _phases[idx].tokens_sold,
            _phases[idx].phase_emission,
            _phases[idx].investments_collected,
            getAvailableTokensToSellCurrentPhaseIdx(idx)
        );
    }

    //Функция получения данных об этапе
    function getPhaseState(uint idx)
    public view
    returns (PhaseState)
    {
        require(idx < _phases.length);

        //Отмена проверяется в первую очередь вне зависимости от времени
        if (_phases[idx].cancelled)
        {
            return PhaseState.cancelled;
        }

        //Если этап еще не начался по времени
        if (currentTime() < _phases[idx].start_time)
        {
            return PhaseState.waiting_for_collecting;
        }

        //Если этап идет сейчас
        if (currentTime() >= _phases[idx].start_time &&
            currentTime() <= _phases[idx].prices_in_wei_ends[_phases[idx].prices_in_wei_ends.length-1])
        {
            return PhaseState.collecting;
        }

        //Этап закончился. Здесь без условия выполяется currentTime() > _phases[idx].prices_in_wei_ends[_phases[idx].prices_in_wei_ends.length-1]
        if (_phases[idx].tokens_sold >= _phases[idx].min_tokens_to_sell)
            return PhaseState.succeed;

        return PhaseState.failed;
    }


    //Функция возвращает тип эмиссии кампании в зависимости от
    //компановки этапов
    function getEmissionType()
    public view
    returns (EmissionType)
    {
        if (_phases.length ==0)
        {
            return EmissionType.undefined;
        }

        //Возвращаем тип эмиссии первого этапа
        return getPhaseEmissionType(0);
    }


    //Возвращает тип эмиссии этапа
    function getPhaseEmissionType(uint idx)
    public view
    returns (EmissionType em_type)
    {
        require(idx < _phases.length);

        return _phases[idx].phase_emission == 0 ? EmissionType.unlimited : EmissionType.limited;
    }


    //Если возвращает (0,0,0) - то инвестирование невозможно
    //Так же возвраащает индексы текущего этапа и подэтапа. Действительны только если price != 0
    function getTokenPriceInWeiAndPhaseIdxs()
    public view
    returns (
        uint price,
        uint phase_idx,
        uint phase_sub_idx)
    {
        return getTokenPriceInWeiAndPhaseIdxsForDate(currentTime());
    }


    //Возвращает стоимость токена для даты. Если возвращает 0 - то инвестирование невозможно
    //Так же возвраащает индексы текущего этапа и подэтапа. Действительны только если price != 0
    function getTokenPriceInWeiAndPhaseIdxsForDate(uint date)
    public view
    returns (
        uint price,
        uint phase_idx,
        uint phase_sub_idx)
    {
        for (uint i = 0; i < _phases.length; i++)
        {
            uint32 stage_start_time = _phases[i].start_time;
            for (uint j = 0; j < _phases[i].prices_in_wei_ends.length; j++)
            {
                if (stage_start_time <= date &&
                    date < _phases[i].prices_in_wei_ends[j])
                        return (_phases[i].prices_in_wei[j], i, j);
                stage_start_time = _phases[i].prices_in_wei_ends[j];
            }
        }
        return (0, 0, 0);
    }

    //Функция получения количества всех СОБРАННЫХ инвестиций
    function getAllInvestmentsCollected()
    public view
    returns (uint all_investments_collected)
    {
        for (uint i = 0; i < _phases.length; i++)
            all_investments_collected = all_investments_collected.add(_phases[i].investments_collected);
        return all_investments_collected;
    }




    //Функция получения количества всех успешных инвестиций (инвестиций с успешно законченных этапов)
    function getAllSuccessInvestmentsCollected()
    public view
    returns (uint success_investments_collected)
    {
        for (uint i = 0; i < _phases.length; i++)
        {
            if (getPhaseState(i) == PhaseState.succeed)
            {
                success_investments_collected = success_investments_collected.add(_phases[i].investments_collected);
            }
        }
        return success_investments_collected;
    }


    //Функция получения количества всех неуспешных инвестиций (инвестиций с зафейленных этапов)
    function getAllFailedInvestmentsCollected()
    public view
    returns (uint failed_investments_collected)
    {
        for (uint i = 0; i < _phases.length; i++)
        {
            PhaseState p_state = getPhaseState(i);
            if (p_state == PhaseState.failed || p_state == PhaseState.cancelled)
            {
                failed_investments_collected =  failed_investments_collected.add(_phases[i].investments_collected);
            }
        }
        return failed_investments_collected;
    }



    //Функция получения количества всех ЗАБРАННЫХ инвестиций инветсорами
    function getAllInvestmentsWithdrawnBack()
    public view
    returns (uint)
    {
          return _all_investments_withdrawn_back;
    }


    //Функция получения количества всех ДОСТУПНЫХ ДЛЯ ЗАБИРАНИЯ инвестиций владельцем
    function getAvailableWithdrawInvestmentsForOwner()
    public view
    returns (uint)
    {
        return getAllSuccessInvestmentsCollected()
                    .mul(
                        uint256(100)
                        .sub(BENEFICIARY_INVESTMENTS_PERCENTAGE))
                    .div(100)
                    .sub(_all_investments_withdrawn_by_owner);
    }


    //Функция получения количества инвестиций доступных к возврату конкртеному инвестору
    //если какой то этап зафейлился
    function getAvailableInvestmentsBackValue(address addr)
    public view
    returns (uint investments_back_value)
    {
        require(addr != address(0));

        CompanyState c_state = state();


        if (c_state == CompanyState.collecting_failed || c_state == CompanyState.cancelled)
        {
            //#warning по идее мы можем иметь только 1 сфейленный этап
            //и по иддее можно брейкать цикл, но по факту я  не уверен,
            //потому надо убедиться или проверить
            for (uint i = 0; i < _phases.length; i++)
            {
                PhaseState p_state = getPhaseState(i);
                if (p_state == PhaseState.failed || p_state == PhaseState.cancelled)
                {
                    investments_back_value = investments_back_value.add(_phases[i].investments[addr]);
                }
            }

        }
    }


    //Функция получения количества всех ДОСТУПНЫХ ДЛЯ ЗАБИРАНИЯ инвестиций платформой
    function getAvailableWithdrawInvestmentsForBeneficiary()
    public view
    returns (uint)
    {
        return getAllSuccessInvestmentsCollected()
                .mul(BENEFICIARY_INVESTMENTS_PERCENTAGE)
                .div(100)
                .sub(_all_investments_withdrawn_by_beneficiary);
    }


    //Функия получения количества всех проданных токенов
    function getAllTokenSold()
    public view
    returns (uint all_tokens_sold)
    {
        for (uint i = 0; i < _phases.length; i++)
            all_tokens_sold = all_tokens_sold.add(_phases[i].tokens_sold);
    }


    //Возвращает время окончания сбора средств кампании
    function getEndTime()
    public view
    returns(uint)
    {
        require(_phases.length !=0);

        return _phases[_phases.length-1].prices_in_wei_ends[
            _phases[_phases.length-1].prices_in_wei_ends.length-1
        ];
    }


    //Возвращает время начала сбора средств кампании
    function getStartTime()
    public view
    returns(uint)
    {
        require(_phases.length !=0);

        return _phases[0].start_time;
    }



    //Функция вызываемая из контракта бенефициара для получения своих проценов от инвестиций
    //статус компании специально не проверяется, ибо getAvailableWithdrawInvestmentsForBeneficiary здесь
    function withdrawInvestmentsBeneficiary(address withdraw_address)
        onlyBeneficiary
    public
    {
        uint to_withdraw = getAvailableWithdrawInvestmentsForBeneficiary();
        if (to_withdraw != 0)
        {
            _all_investments_withdrawn_by_beneficiary = _all_investments_withdrawn_by_beneficiary.add(to_withdraw);
            this.transferFromContractTo(withdraw_address, to_withdraw);
        }
    }


    //Функция для перемещения количеств инвестиций в массиве _phases.investments
    //используется при передаче токенов проекта. Должна вызываться только путем создания
    //транзакции через this.moveInvestmentsBaseCompany из методов передачи токена!!!!
    function moveInvestmentsBaseCompany(
        address from, //Кто переводит токены
        address to,   //Кому переводятся токены
        uint value,   //Количество переводимых токенов
        uint balance  //Баланс адреса from в момент перевода токенов
    )
    public
    {
        require(msg.sender == address(this));
        require(isInitialized());
        require(value !=0);
        require(balance !=0);
        require(balance >= value);

        //Пока что двигаем ВСЕ! инвестиции, хотя по идее можно только для НЕ успешных этапов
        //в смысле тех, которые не success, а любые другие
        for (uint i = 0; i < _phases.length; i++)
        {
            uint investments_to_move_value = _phases[i].investments[from].mul(value).div(balance);
            _phases[i].investments[from] = _phases[i].investments[from].sub(investments_to_move_value);
            _phases[i].investments[to] = _phases[i].investments[to].add(investments_to_move_value);
        }
    }


    //Функция зануления данных об инвестициях. Используется
    //из метода withdrawMyInvestmentsBack
    function zeroInvestments() //msg.sender используется для обеспечения безопасности, чтобы никто не вызвал случайно ?
    internal
    {
        CompanyState c_state = state();
        require(c_state == CompanyState.collecting_failed || c_state == CompanyState.cancelled);

        for (uint i = 0; i < _phases.length; i++)
        {
            PhaseState p_state = getPhaseState(i);
            if (p_state == PhaseState.failed || p_state == PhaseState.cancelled )
            {
                _phases[i].investments[msg.sender] = 0;
            }
        }
    }


    struct Phase
    {
        //Время начала этапа
        uint32   start_time;

        //Набор цен в процессе этапа
        uint[]   prices_in_wei;

        //Время окончания действий цен
        uint32[] prices_in_wei_ends;

        //Мнимальное количевто токенов, которые надо продать на этом этапе
        uint     min_tokens_to_sell;

        //Текущее количество проданных токенов
        uint     tokens_sold;

        //Если задано, то эмиссия является лимитированной и
        //верхней границей является это значение
        uint     phase_emission;

        //Сколько собрано инвестиций в wei
        uint     investments_collected;

        //Инвестиции этапа в эфире
        mapping(address => uint256) investments;

        //Флаг отмены
        bool     cancelled;

    }


    enum CompanyState
    {
        undefined, // 0
        waiting_for_initialization, // 1
        initialized, // 2
        collecting, // 3
        collecting_succeed, // 4
        collecting_failed, // 5
        cancelled //6
    }


    enum PhaseState
    {
        undefined, // 0
        waiting_for_collecting, // 1
        collecting, // 2
        succeed, // 3
        failed,  // 4,
        cancelled //5
    }


    enum EmissionType
    {
        undefined, // 0
        limited, // 1
        unlimited // 2
    }
}

//TODO:  symbol и name перенести в токен ??










contract CINInvestmentCompanyInterface
{
    function invest_cin(address, uint) public;
    function add_profit(address, uint) public;
    function withdraw_profit(address) public;
}


contract CINInvestmentCompany is StandardCINStockToken, BaseInvestmentCompany, CINInvestmentCompanyInterface
{
    //Адрес контракта CIN токена
    address public                 _CIN_token_address;

    function getContractType() public pure returns (string)
    {
        return "CINCrowdInvestingLimited";
    }

    //Функция инициализированности, всегда динамическая, не забывать туда
    //добавлять параметра для других контрактов
    function isInitialized()
    public view
    returns (bool)
    {
        return (
            _phases_committed &&
             bytes(name).length != 0 &&
             bytes(symbol).length != 0 &&
             _CIN_token_address != address(0) &&
            owner != address(0) &&
            //Вроде как логическая импликация (если есть начисленные проценты то должен быть и бенефициар
            ((BENEFICIARY_TOKEN_PERCENTAGE == 0 && BENEFICIARY_INVESTMENTS_PERCENTAGE == 0)  || (beneficiary != address(0)))
        );
    }


    //Функция получения баланса контракта
    function getBalance()
    public view
    returns (uint)
    {
        return ERC20Basic(_CIN_token_address).balanceOf(address(this));
    }



    //Функция, позволяющая установить адрес токена CIN, использующегося
    //как внутренняя валюта
    function setCINTokenAddress(address cin_token_address)
    public
        onlyPlatform
    {
        require(state() == CompanyState.waiting_for_initialization);

        //Можно установить только 1 раз! Это для честности
        require(_CIN_token_address == address(0));

        //TODO: сюда бы добавить проверку интерфейса
        _CIN_token_address = cin_token_address;
    }


    //Метод передачи инвестиций со счета контракта на счет dest. Должен
    //вызываться только через this.transferFromContractTo
    function transferFromContractTo(address dest, uint value) public
    {
        //Только сам контракт или контракт токена CIN может дергать этот метод
        require(
            msg.sender == _CIN_token_address ||
            msg.sender == address(this));

        ERC20Basic(_CIN_token_address).transfer(dest, value);
    }


    function invest_cin(address _investor, uint _value)
    public
    {
        require(msg.sender == _CIN_token_address);
        require(checkCanInvestInternal(_investor, _value));

        uint token_price_in_wei;
        uint phase_idx;

        (token_price_in_wei, phase_idx, ) = getTokenPriceInWeiAndPhaseIdxsForDate(currentTime());

        //Проверяем что токены продаются по времени
        require(token_price_in_wei > 0);

        //Расчитываем сколько хочет
        uint user_wants =_value.mul(WEI_COUNT_IN_ONE_TOKEN).div(token_price_in_wei);

        //Если пользователь и если он хочет больше чем есть, откатываем транзакцию
        require(user_wants <= getAvailableTokensToSellTillPhaseIdxValue(phase_idx));

        //Переводим токены получателю
        balances[_investor] = balances[_investor].add(user_wants);
        balances[this] = balances[this].sub(user_wants);
        emit Transfer(this, _investor, user_wants);

        //Обновляем данные этапа
        _phases[phase_idx].tokens_sold = _phases[phase_idx].tokens_sold.add(user_wants);
        _phases[phase_idx].investments_collected = _phases[phase_idx].investments_collected.add(_value);
        _phases[phase_idx].investments[_investor] = _phases[phase_idx].investments[_investor].add(_value);

        //Создаем событие
        emit InvestmentMade(_investor, _value, user_wants);
    }


    //Функция из интерфейса StockToken
    function checkCanAddStockProfit()
    internal view
    returns (bool)
    {
        return (
            state() == CompanyState.collecting_succeed &&
            msg.sender == _CIN_token_address
        );
    }



    function checkCanAddPhaseDerived(Phase phase) internal view returns (bool)
    {
        //Для лимитированной эмиссии все этапы должны быть лимитированные.
        //CIN кампании всегда лимитированные
        if(phase.phase_emission == 0)
        {
            return false;
        }

        return true;
    }

    function commitPhasesDerived()
        onlyOwner
    internal
    {
        require(state() == CompanyState.waiting_for_initialization);

        //В случае лимитированной эмиссии делаем эмиссию сразу по завершении инициализации и
        //сразу отдаем площадке ее токены. Токены отданные площадке, не считаем проданными!
        for (uint i = 0; i < _phases.length; i++)
        {
            totalSupply = totalSupply.add(_phases[i].phase_emission);
        }

        uint beneficiary_token_benefit = totalSupply.mul(BENEFICIARY_TOKEN_PERCENTAGE).div(100);
        uint owner_token_benefit = totalSupply.mul(OWNER_TOKEN_PERCENTAGE).div(100);

        //Баланс контракта, откуда будут переводиться токены покупателям. Если токены передаются между этапами,
        //потому можно нормально их хранить на балансе контракта
        balances[this] = totalSupply.sub(beneficiary_token_benefit).sub(owner_token_benefit);
        balances[beneficiary] = beneficiary_token_benefit;
        balances[owner] = owner_token_benefit;

        //Отдаем токены (проверить порядок!)
        emit Transfer(address(0), this, totalSupply);

        if (beneficiary_token_benefit != 0)
        {
            emit Transfer(address(this), beneficiary, beneficiary_token_benefit);
        }

        if (owner_token_benefit != 0)
        {
            emit Transfer(address(this), owner, owner_token_benefit);
        }
    }


    //Функция вызываемая контрактом CIN, проксируемая из CINToken.addProfit
    //Добавление на контракт кампании дохода в токенах CIN
    function add_profit(address _sender,uint _value)
    public
    {
        require(state() == CompanyState.collecting_succeed);
        require(msg.sender == _CIN_token_address);
        require(_sender == owner);

        addStockProfitInternal(_value);
    }

    //Функция вызываемая контрактом CIN, проксируемая из CINToken.withdrawProfit
    //Добавление на контракт кампании дохода в токенах CIN
    function withdraw_profit(address dest_address)
    public
    {
        require(state() == CompanyState.collecting_succeed);
        require(msg.sender == _CIN_token_address);
        require(dest_address != address(0));

        uint profit_value = getAvailableWithdrawProfitValue(dest_address);
        if (profit_value != 0 )
        {
            full_withdrawn_profit = full_withdrawn_profit.add(profit_value);
            withdrawn[dest_address] = withdrawn[dest_address].add(profit_value);
            this.transferFromContractTo(dest_address, profit_value);
            emit profitWithdrawn(dest_address, profit_value);
        }

    }

    //Функция вызываемая владельцем для получения своих инвестиций
    function withdrawInvestmentsOwner(address withdraw_address)
        onlyOwner
    public
    {

        //WARNING: убедиться не опасно ли не проверять состояние кампании

        uint to_withdraw = getAvailableWithdrawInvestmentsForOwner();
        if (to_withdraw != 0)
        {
            _all_investments_withdrawn_by_owner = _all_investments_withdrawn_by_owner.add(to_withdraw);
            emit InvestmentsWithdrawnByOwner(withdraw_address, to_withdraw);
            this.transferFromContractTo(withdraw_address, to_withdraw);
        }
    }



    //Функция возвращения инвестиций инвестроам в случае если какой нибудь этап зафейлился
    function withdrawMyInvestmentsBack()
    public
    {
        CompanyState c_state = state();
        require(c_state == CompanyState.collecting_failed || c_state == CompanyState.cancelled);

        uint to_withdraw = getAvailableInvestmentsBackValue(msg.sender);

        if (to_withdraw != 0)
        {
            _all_investments_withdrawn_back = _all_investments_withdrawn_by_owner.add(to_withdraw);

            //Зануляем данные об инвестициях
            zeroInvestments();

            //Возвращаем токены с баланса пользователя на баланс контракта
            returnTokensToContractFrom(msg.sender);

            //Пересылаем бабки
            this.transferFromContractTo(msg.sender, to_withdraw);
        }
    }
}

contract CINToken is StandardToken, Platform
{
    //Токен  ERC20
    string public constant               symbol = "CIN";
    string public constant               name = "Cinemico official token";
    uint public constant                 decimals = 18;

    mapping(address => uint256) public  tokens_map;
    address[] public                    tokens_arr;


    event Burn(address burner, uint256 value);
//    event Mint(address dest_address, uint256 value);

    constructor()
    public
    {
        //Заглушка чтобы валидные индексы не были == 0 и можно было делать проверки
        //типа require(tokens_map[ico_token_address] == 0);
        tokens_arr.push(address(0));
    }


    //Функиця добавления нового токена. Вызывается площадкой
    function addICOToken(address ico_token_address)
    public
        onlyPlatform
    {
        require(ico_token_address != address(0));
        //Проверяем что ранее не был добавлен такой токен
        require(tokens_map[ico_token_address] == 0);

        tokens_arr.push(ico_token_address);
        tokens_map[ico_token_address] = tokens_arr.length - 1;
    }


     //Функиця добавления нового токена. Вызывается площадкой
    function createICOToken()
    public
        onlyPlatform
    {
        CINInvestmentCompany cinico_contract = new CINInvestmentCompany();
        tokens_arr.push(cinico_contract);
        tokens_map[cinico_contract] = tokens_arr.length - 1;
    }

    //Этот метод вызывает владелец токена, когда хочет получить
    //фиат за свои CINы
    function burn(uint256 value)
    public {
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
    }


    //Этот методы вызывается площадкой, когда ей принесли бабки
    function mint(address dest_address, uint value)
    public
        onlyPlatform
    {
        totalSupply = totalSupply.add(value);
        balances[dest_address] = balances[dest_address].add(value);
        emit Transfer(address(0), dest_address, value);
    }

    function invest(address ico_address, uint value)
    public
    {
        //Проверяем чтобы был достаточный баланс
        require( value <= balances[msg.sender]);

        //Проверяем что токен был добавлен
        require(tokens_map[ico_address] != 0);

        transfer(ico_address, value);

        CINInvestmentCompanyInterface(ico_address).invest_cin(msg.sender, value);

    }

    function addProfit(address ico_address, uint value)
    public
    {
        //Проверяем чтобы был достаточный баланс
        require(value <= balances[msg.sender]);

        //Проверяем что токен был добавлен
        require(tokens_map[ico_address] != 0);

        transfer(ico_address, value);

        CINInvestmentCompanyInterface(ico_address).add_profit(msg.sender, value);
    }

    function withdrawProfit(address ico_address)
    public
    {
        //Проверяем что токен был добавлен
        require(tokens_map[ico_address] != 0);

        CINInvestmentCompanyInterface(ico_address).withdraw_profit(msg.sender);
    }


}