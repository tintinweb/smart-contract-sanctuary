pragma solidity ^0.4.4;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
} 

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool success)  {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of. 
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance)  {
        return balances[_owner];
    }
 
}
 
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is ERC20, BasicToken {
 
    mapping (address => mapping (address => uint256)) allowed;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)  {
        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool success)  {

        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifing the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
}
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable()  public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner  public {
        require(newOwner != address(0));      
        owner = newOwner;
    }
 
}
 
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 */
 
contract MintableToken is StandardToken, Ownable {
    
    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount); 
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public onlyOwner returns (bool)  {
        mintingFinished = true;
        MintFinished();
        return true;
    }
  
}


// Токен 
contract GWTToken is MintableToken {
    
    string public constant name = "Global Wind Token";
    
    string public constant symbol = "GWT";
    
    uint32 public constant decimals = 18; 

}

// Контракт краудсейла
contract GWTCrowdsale is Ownable {
    using SafeMath for uint;

    uint public supplyLimit;         // Лимит выпуска токенов

    address ethAddress;              // Адрес получателя эфира
    uint saleStartTimestamp;         // Таймштамп запуска контракта

    uint public currentStageNumber;  // Номер периода
    uint currentStageStartTimestamp; // Таймштамп старта периода
    uint currentStageEndTimestamp;   // Таймштамп окончания периода
    uint currentStagePeriodDays;     // Кол-во дней (в тестовом минут) проведения периода краудсейла
    uint public baseExchangeRate;    // Курс обмена на токены
    uint currentStageMultiplier;     // Множитель для разных этапов:     bcostReal = baseExchangeRate * currentStageMultiplier

    uint constant M = 1000000000000000000;  // 1 GWT = 10^18 GWTunits (wei)

    uint[] _percs = [40, 30, 25, 20, 15, 10, 5, 0, 0];  // Бонусные проценты
    uint[] _days  = [42, 1, 27, 1, 7, 7, 7, 14, 0];      // Продолжительность в днях

    // Лимиты на выпуск токенов
    uint PrivateSaleLimit = M.mul(420000000);
    uint PreSaleLimit = M.mul(1300000000);
    uint TokenSaleLimit = M.mul(8400000000);
    uint RetailLimit = M.mul(22490000000);

    // Курсы обмена токенов на эфир
    uint TokensaleRate = M.mul(160000);
    uint RetailRate = M.mul(16000);

    GWTToken public token = new GWTToken(); // Токен

    // Активен ли краудсейл
    modifier isActive() {
        require(isInActiveStage());
        _;
    }

    function isInActiveStage() private returns(bool) {
        if (currentStageNumber == 8) return true;
        if (now >= currentStageStartTimestamp && now <= currentStageEndTimestamp){
            return true;
        }else if (now < currentStageStartTimestamp) {
            return false;
        }else if (now > currentStageEndTimestamp){
            if (currentStageNumber == 0 || currentStageNumber == 2 || currentStageNumber == 7) return false;
            switchPeriod();
            // It is not possible for stage to be finished after straight the start
            // Also new set currentStageStartTimestamp and currentStageEndTimestamp should be valid by definition
            //return isInActiveStage();
            return true;
        }
        // That will never get reached
        return false;
    }

    // Перейти к следующему периоду
    function switchPeriod() private onlyOwner {
        if (currentStageNumber == 8) return;

        currentStageNumber++;
        currentStageStartTimestamp = currentStageEndTimestamp; // Запуск производится от конца прошлого периода, если нужно запустить с текущего момента поменяйте на now
        currentStagePeriodDays = _days[currentStageNumber];
        currentStageEndTimestamp = currentStageStartTimestamp + currentStagePeriodDays * 1 days;
        currentStageMultiplier = _percs[currentStageNumber];

        if(currentStageNumber == 0 ){
            supplyLimit = PrivateSaleLimit;
        } else if(currentStageNumber < 3){
            supplyLimit = PreSaleLimit;
        } else if(currentStageNumber < 8){
            supplyLimit = TokenSaleLimit;
        } else {
            // Base rate for phase 8 should update exchange rate
            baseExchangeRate = RetailRate;
            supplyLimit = RetailLimit;
        }
    }

    function setStage(uint _index) public onlyOwner {
        require(_index >= 0 && _index < 9);
        
        if (_index == 0) return startPrivateSale();
        currentStageNumber = _index - 1;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

    // Установить курс обмена
    function setRate(uint _rate) public onlyOwner {
        baseExchangeRate = _rate;
    }

    // Установить можитель
    function setBonus(uint _bonus) public onlyOwner {
        currentStageMultiplier = _bonus;
    }

    function setTokenOwner(address _newTokenOwner) public onlyOwner {
        token.transferOwnership(_newTokenOwner);
    }

    // Установить продолжительность текущего периода в днях
    function setPeriodLength(uint _length) public onlyOwner {
        // require(now < currentStageStartTimestamp + _length * 1 days);
        currentStagePeriodDays = _length;
        currentStageEndTimestamp = currentStageStartTimestamp + currentStagePeriodDays * 1 days;
    }

    // Изменить лимит выпуска токенов
    function modifySupplyLimit(uint _new) public onlyOwner {
        if (_new >= token.totalSupply()){
            supplyLimit = _new;
        }
    }

    // Выпустить токены на кошелек
    function mintFor(address _to, uint _val) public onlyOwner isActive payable {
        require(token.totalSupply() + _val <= supplyLimit);
        token.mint(_to, _val);
    }

    // Прекратить выпуск токенов
    // ВНИМАНИЕ! После вызова этой функции перезапуск будет невозможен!
    function closeMinting() public onlyOwner {
        token.finishMinting();
    }

    // Запуск прив. сейла
    function startPrivateSale() public onlyOwner {
        currentStageNumber = 0;
        currentStageStartTimestamp = now;
        currentStagePeriodDays = _days[0];
        currentStageMultiplier = _percs[0];
        supplyLimit = PrivateSaleLimit;
        currentStageEndTimestamp = currentStageStartTimestamp + currentStagePeriodDays * 1 days;
        baseExchangeRate = TokensaleRate;
    }

    function startPreSale() public onlyOwner {
        currentStageNumber = 0;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

    function startTokenSale() public onlyOwner {
        currentStageNumber = 2;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

    function endTokenSale() public onlyOwner {
        currentStageNumber = 7;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

    // 000000000000000000 - 18 нулей, добавить к сумме в целых GWT
    // Старт
    function GWTCrowdsale() public {
        // Init
        ethAddress = 0xB93B2be636e39340f074F0c7823427557941Be42;  // Записываем адрес, на который будет пересылаться эфир
        // ethAddress = 0x16a49c8af25b3c2ff315934bf38a4cf645813844; // Dev
        saleStartTimestamp = now;                                       // Записываем дату деплоя
        startPrivateSale();
    }

    function changeEthAddress(address _newAddress) public onlyOwner {
        ethAddress = _newAddress;
    }

    // Автоматическая покупка токенов
    function createTokens() public isActive payable {
        uint tokens = baseExchangeRate.mul(msg.value).div(1 ether); // Переводим ETH в GWT

        if (currentStageMultiplier > 0 && currentStageEndTimestamp > now) {            // Начисляем бонус
            tokens = tokens + tokens.div(100).mul(currentStageMultiplier);
        }
        // require(tokens > minLimit && tokens < buyLimit);
        require(token.totalSupply() + tokens <= supplyLimit);
        ethAddress.transfer(msg.value);   // переводим на основной кошелек
        token.mint(msg.sender, tokens); // Начисляем
    }

    // Если кто-то перевел эфир на контракт
    function() external payable {
        createTokens(); // Вызываем функцию начисления токенов
    }

}