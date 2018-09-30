pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event PausePublic(bool newState);
  event PauseOwnerAdmin(bool newState);

  bool public pausedPublic = true;
  bool public pausedOwnerAdmin = false;

  address public admin;

  /**
   * @dev Modifier to make a function callable based on pause states.
   */
  modifier whenNotPaused() {
    if(pausedPublic) {
      if(!pausedOwnerAdmin) {
        require(msg.sender == admin || msg.sender == owner);
      } else {
        revert();
      }
    }
    _;
  }

  /**
   * @dev called by the owner to set new pause flags
   * pausedPublic can&#39;t be false while pausedOwnerAdmin is true
   */
  function pause(bool newPausedPublic, bool newPausedOwnerAdmin) onlyOwner public {
    require(!(newPausedPublic == false && newPausedOwnerAdmin == true));

    pausedPublic = newPausedPublic;
    pausedOwnerAdmin = newPausedOwnerAdmin;

    PausePublic(newPausedPublic);
    PauseOwnerAdmin(newPausedOwnerAdmin);
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract ZilliqaToken is PausableToken {
    string  public  constant name = "Zilliqa";
    string  public  constant symbol = "ZIL";
    uint8   public  constant decimals = 12;

    modifier validDestination( address to )
    {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    function ZilliqaToken( address _admin, uint _totalTokenAmount ) 
    {
        // assign the admin account
        admin = _admin;

        // assign the total tokens to zilliqa
        totalSupply = _totalTokenAmount;
        balances[msg.sender] = _totalTokenAmount;
        Transfer(address(0x0), msg.sender, _totalTokenAmount);
    }

    function transfer(address _to, uint _value) validDestination(_to) returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) validDestination(_to) returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) returns (bool) 
    {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        // owner can drain tokens that are sent here by mistake
        token.transfer( owner, amount );
    }

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    function changeAdmin(address newAdmin) onlyOwner {
        // owner can re-assign the admin
        AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library NewSafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title TelExchange
 * @dev The main contract of the project.
 */
  /**
    * @title TelExchange
    * @dev Контракт проекта;
    */

    
contract Name {
    // Connecting SafeMath for safe calculations.
      // Подключает библиотеку безопасных вычислений к контракту.
    using NewSafeMath for uint;

    // A variable for address of the owner;
      // Переменная для хранения адреса владельца контракта;
    address owner;
    // A variable for address of the ERC20 token;
      // Переменная для хранения адреса владельца контракта;
    ZilliqaToken public token; // 
    // A variable for decimals of the token;
      // Переменная для количества знаков после запятой у токена;
    uint private decimals;

    // A variable for storing deposits of investors.
      // Переменная для хранения записей о сумме инвестиций инвесторов.
    mapping (address => uint) deposit;
    // A variable for storing amount of withdrawn money of investors.
      // Переменная для хранения записей о сумме снятых средств.
    mapping (address => uint) withdrawn;
    // A variable for storing reference point to count available money to withdraw.
      // Переменная для хранения времени отчета для инвесторов.
    mapping (address => uint) lastTimeWithdraw;

    // A constructor function for the contract. It used single time as contract is deployed.
      // Единоразовая функция вызываемая при деплое контракта.
    function Name() public { 
        // Sets an owner for the contract;
          // Устанавливает владельца контракта;
        owner = msg.sender;
        // Sets an ERC20 token for the contract;
          // Устанавливает ERC20 токен;
        token = ZilliqaToken(0x9de76932550fb143abf2af063afee83e2075e25d); 
        // Sets a decimals of the ERC20 token;
          // Устанавливает количество знаков после запятой;
        decimals = 12; 
    }

    // A function for transferring ownership of the contract (available only for the owner).
      // Функция для переноса права владения контракта (доступна только для владельца).
    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner);
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    // A function for getting key info for investors.
      // Функция для вызова ключевой информации для инвестора.
    function getInfo(address _address) public view returns(uint Deposit, uint Withdrawn, uint AmountToWithdraw) {

        // 1) Amount of invested tokens;
          // 1) Сумма вложенных токенов;
        Deposit = deposit[_address].div(10**decimals);
        // 2) Amount of withdrawn tokens;
          // 3) Сумма снятых средств;
        Withdrawn = withdrawn[_address].div(10**decimals);
        // 3) Amount of tokens which is available to withdraw;
        // Formula without SafeMath: ((Current Time - Reference Point) - ((Current Time - Reference Point) % 1 period)) * (Deposit / 25) / decimals / 1 period
          // 4) Сумма токенов доступных к выводу;
          // Формула без библиотеки безопасных вычислений: ((Текущее время - Отчетное время) - ((Текущее время - Отчетное время) % 1 period)) * (Сумма депозита / 25) / decimals / 1 period
        AmountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[_address]).sub((block.timestamp.sub(lastTimeWithdraw[_address])).mod(1 days))).mul(deposit[_address].div(25)).div(10**decimals).div(1 days);
    }

    // A "fallback" function. It is automatically being called when anybody sends money to the contract. Function simply calls the "invest" function.
      // Функция автоматически вызываемая при получении средств контрактом;
    function() external payable {

        // If the value of sent ETH is equal to 0, function &#39;withdraw&#39; is called;
          // Если было отправлено 0 эфиров вызывается функция Снятия доступных средств;
        if (msg.value == 0) {
            withdraw();
            return;
        }
        // Otherwise function throws an error and doesn&#39;t accept ETH;
          // Если были отправлены эфиры то функция отменяется и средства возвращаются отправителю;
        revert();
    }

    // A function which accepts tokens of investors.
      // Функция для перевода токенов на контракт.
    function invest(uint _value) external {

        // Transfers approved ERC20 tokens from investors address;
          // Переводит одобренные к выводу токены ERC20 на данный контракт;
        token.transferFrom(msg.sender, address(this), _value);
        // Transfers a fee to the owner of the contract. The fee is 5% of the deposit (or Deposit / 20)
          // Переводит комиссию владельцу (5%);
        token.transfer(owner, _value.div(20));

        // The special algorithm for investors who increases their deposits:
          // Специальный алгоритм для инвесторов увеличивающих их вклад;
        if (deposit[msg.sender] > 0) {
            // Amount of tokens which is available to withdraw;
            // Formula without SafeMath: ((Current Time - Reference Point) - ((Current Time - Reference Point) % 1 period)) * (Deposit / 25) / 1 period
              // Расчет количества токенов доступных к выводу;
              // Формула без библиотеки безопасных вычислений: ((Текущее время - Отчетное время) - ((Текущее время - Отчетное время) % 1 period)) * (Сумма депозита / 25) / 1 period
            uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].div(25)).div(1 days);
            // The additional algorithm for investors who need to withdraw available dividends:
              // Дополнительный алгоритм для инвесторов которые имеют средства к снятию;
            if (amountToWithdraw != 0) {
                // Increasing the withdrawn tokens by the investor.
                  // Увеличение количества выведенных средств инвестором;
                withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
                // Transferring available dividends to the investor.
                  // Перевод доступных к выводу средств на кошелек инвестора;
                token.transfer(msg.sender, amountToWithdraw);
            }
            // Setting the reference point to the current time.
              // Установка нового отчетного времени для инвестора;
            lastTimeWithdraw[msg.sender] = block.timestamp;
            // Increasing of the deposit of the investor.
              // Увеличение Суммы депозита инвестора;
            deposit[msg.sender] = deposit[msg.sender].add(_value);
            // End of the function for investors who increases their deposits.
              // Конец функции для инвесторов увеличивающих свои депозиты;
            return;
        }
        // The algorithm for new investors:
        // Setting the reference point to the current time.
          // Алгоритм для новых инвесторов:
          // Установка нового отчетного времени для инвестора;
        lastTimeWithdraw[msg.sender] = block.timestamp;
        // Storing the amount of the deposit for new investors.
        // Установка суммы внесенного депозита;
        deposit[msg.sender] = (_value);
    }

    // A function for getting available dividends of the investor.
      // Функция для вывода средств доступных к снятию;
    function withdraw() public {

        // Amount of tokens which is available to withdraw.
        // Formula without SafeMath: ((Current Time - Reference Point) - ((Current Time - Reference Point) % 1 period)) * (Deposit / 25) / 1 period
          // Расчет количества токенов доступных к выводу;
          // Формула без библиотеки безопасных вычислений: ((Текущее время - Отчетное время) - ((Текущее время - Отчетное время) % 1 period)) * (Сумма депозита / 25) / 1 period
        uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].div(25)).div(1 days);
        // Reverting the whole function for investors who got nothing to withdraw yet.
          // В случае если к выводу нет средств то функция отменяется;
        if (amountToWithdraw == 0) {
            revert();
        }
        // Increasing the withdrawn tokens by the investor.
          // Увеличение количества выведенных средств инвестором;
        withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
        // Updating the reference point.
        // Formula without SafeMath: Current Time - ((Current Time - Previous Reference Point) % 1 period)
          // Обновление отчетного времени инвестора;
          // Формула без библиотеки безопасных вычислений: Текущее время - ((Текущее время - Предыдущее отчетное время) % 1 period)
        lastTimeWithdraw[msg.sender] = block.timestamp.sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days));
        // Transferring the available dividends to the investor.
          // Перевод выведенных средств;
        token.transfer(msg.sender, amountToWithdraw);
    }
}