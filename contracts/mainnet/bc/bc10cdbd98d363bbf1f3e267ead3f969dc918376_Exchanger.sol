/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data);
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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




contract ERC223Token is ERC223Interface {
    using SafeMath for uint;

    mapping(address => uint) balances; // List of user balances.
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value, empty);
    }

    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}


contract PajCoin223 is ERC223Token {

    string public constant name = &quot;PajCoin&quot;;
    bytes32 public constant symbol = &quot;PJC&quot;;
    uint8 public constant decimals = 18;

    function PajCoin223() public {
        bytes memory empty;
        totalSupply = 150000000e18;
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply, empty);
    }
}



contract Exchanger is ERC223ReceivingContract, Ownable {

    uint public rate = 30*1000000000;
    uint public fee = 100000*3e9;

    PajCoin223 public token = PajCoin223(0x1a85180ce3012e7715b913dd585afdf1a10f3025);

    // event DataEvent(string comment);
    event DataEvent(uint value, string comment);
    // event DataEvent(bytes32 value, string comment);
    // event DataEvent(bool value, string comment);
    // event DataEvent(address addr, string comment);

    // структ с юзером и суммой, которую он переслал
    struct Deal {
        address user;
        uint money;
    }
    // очередь &quot;забронированных&quot; переводов на покупку токенов
    mapping(uint => Deal) ethSended;
    mapping(uint => Deal) coinSended;

    // Счетчик людей, &quot;забронировавших&quot; токены.
    // &quot;Бронирование&quot; значит, что человек прислал деньги на покупку, но курс еще
    // не установлен. Соответственно, перевод средств добавляется в очередь и при
    // следующем обновлении курса будет обработан
    uint ethSendedNumber = 0;
    uint coinSendedNumber = 0;

    modifier allDealsArePaid {
        require(ethSendedNumber == 0);
        require(coinSendedNumber == 0);
        _;
    }

    event LogPriceUpdated(uint price);

    function Exchanger() public payable {
        updater = msg.sender;
    }

    function needUpdate() public view returns (bool) {
        return ethSendedNumber + coinSendedNumber > 0;
    }



    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private reentrancy_lock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }

    /**
     * @dev An account that commands to change a rate
     */
    address updater;

    modifier onlyUpdater() {
        require(msg.sender == updater);
        _;
    }

    function setUpdater(address _updater) public onlyOwner() {
        updater = _updater;
    }

    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

    function setToken(address addr) public onlyOwner {
        token = PajCoin223(addr);
    }

    function getEth(uint amount) public onlyOwner allDealsArePaid {
        owner.transfer(amount);
    }

    function getTokens(uint amount) public onlyOwner allDealsArePaid {
        token.transfer(owner, amount);
    }

    function() public payable {
        if (msg.sender != owner) {
            require(fee <= msg.value);
            DataEvent(msg.value, &quot;Someone sent ether: amount&quot;);
            ethSended[ethSendedNumber++] = Deal({user: msg.sender, money: msg.value});
        }
    }

    function tokenFallback(address _from, uint _value, bytes _data) {
        // DataEvent(msg.sender, &quot;from&quot;);

        require(msg.sender == address(token));
        if (_from != owner) {
            require(fee <= _value * 1e9 / rate);
            DataEvent(_value, &quot;Someone sent coin: amount&quot;);
            coinSended[coinSendedNumber++] = Deal({user: _from, money: _value});
        }
    }

    function updateRate(uint _rate) public onlyUpdater nonReentrant{

        rate = _rate;
        LogPriceUpdated(rate);

        uint personalFee = fee / (ethSendedNumber + coinSendedNumber);
        DataEvent(personalFee, &quot;Personal fee&quot;);

        proceedEtherDeals(personalFee);
        proceedTokenDeals(personalFee);

    }

    function proceedEtherDeals(uint personalFee) internal {
        for (uint8 i = 0; i < ethSendedNumber; i++) {
            address user = ethSended[i].user;
            DataEvent(ethSended[i].money, &quot;Someone sent ether: amount&quot;);
            DataEvent(personalFee, &quot;Fee: amount&quot;);
            uint money = ethSended[i].money - personalFee;

            DataEvent(money, &quot;Discounted amount: amount&quot;);
            uint value = money * rate / 1e9;
            DataEvent(value, &quot;Ether to tokens: amount&quot;);
            if (money < 0) {
                // Скинуто эфира меньше, чем комиссия
            } else if (token.balanceOf(this) < value) {
                DataEvent(token.balanceOf(this), &quot;Not enough tokens: owner balance&quot;);
                // Вернуть деньги, если токенов не осталось
                user.transfer(money);
            } else {
                token.transfer(user, value);
                DataEvent(value, &quot;Tokens were sent to customer: amount&quot;);
            }
        }
        ethSendedNumber = 0;
    }

    function proceedTokenDeals(uint personalFee) internal {
        for (uint8 j = 0; j < coinSendedNumber; j++) {
            address user = coinSended[j].user;
            uint coin = coinSended[j].money;

            DataEvent(coin, &quot;Someone sent tokens: amount&quot;);
            DataEvent(coin * 1e9 / rate, &quot;Tokens to ether: amount&quot;);
            uint value = coin * 1e9 / rate - personalFee;
            DataEvent(personalFee, &quot;Fee: amount&quot;);
            DataEvent(value, &quot;Tokens to discounted ether: amount&quot;);

            if (value < 0) {
                // Скинуто токенов меньше, чем комиссия
            } else if (this.balance < value) {
                // Вернуть токены, если денег не осталось
                DataEvent(this.balance, &quot;Not enough ether: contract balance&quot;);

                token.transfer(user, coin);
            } else {
                user.transfer(value);
                DataEvent(value, &quot;Ether was sent to customer: amount&quot;);
            }
        }
        coinSendedNumber = 0;
    }
}