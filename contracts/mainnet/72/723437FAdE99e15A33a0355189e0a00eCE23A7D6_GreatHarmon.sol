pragma solidity ^0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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
 * An ideal or perfect society
 */
contract GreatHarmon is Ownable {

    using SafeMath for uint256;

    /* Initializes contract */
    function GreatHarmon() public {
        
    }

    //领取Basic income的冷却时间, 暂且设定为1天。
    uint public cooldownTime = 1 days;

    //basicIncome发放限制
    uint public basicIncomeLimit = 10000;

    //日常发放
    uint public dailySupply = 50;

    /**
     * @dev 分发基本收入
     */
    function getBasicIncome() public {
        Resident storage _resident = residents[idOf[msg.sender]-1];
        require(_isReady(_resident));
        require(_isUnderLimit());
        require(!frozenAccount[msg.sender]);  

        balanceOf[msg.sender] += dailySupply;

        totalSupply = totalSupply.add(dailySupply);

        _triggerCooldown(_resident);
        GetBasicIncome(idOf[msg.sender]-1, _resident.name, dailySupply, uint32(now));
        Transfer(address(this), msg.sender, dailySupply);
    }

    function _triggerCooldown(Resident storage _resident) internal {
        _resident.readyTime = uint32(now + cooldownTime);
    }

    /**
    * @dev BasicIncome 设定为每日领取一次。 领取之后，进入一天的冷却时间。
    * 这里检测是否在冷却周期内。
    */
    function _isReady(Resident storage _resident) internal view returns (bool) {
        return (_resident.readyTime <= now);
    }

    /**
    * @dev 分发基本收入之前，需检测是否符合发放规则。
    * 大同世界崇尚“按需索取”,贪婪获取是不应该的。
    * 此函数检测居民的当前ghCoin，如果大于系统设定的basicIncomeLimit，
    * 则不能再获取basicIncome。
    */
    function _isUnderLimit() internal view returns (bool) {
        return (balanceOf[msg.sender] <= basicIncomeLimit);
    }

    //居民加入事件
    event JoinGreatHarmon(uint id, string name, string identity, uint32 date);
    event GetBasicIncome(uint id, string name, uint supply, uint32 date);

    // 居民
    struct Resident {
        string name;      //姓名
        string identity;  //记录生日、性别等个人信息。类似身份证。
        uint32 prestige;  //声望值，大同世界中，鼓励人们“达则兼济天下”。做更多的好事。将提高声望值。
        uint32 joinDate;  //何时加入。
        uint32 readyTime; //"Basic income system" 的冷却时间。
    }

    Resident[] public residents;

    //存储居民id索引
    mapping (address => uint) public idOf;

    function getResidentNumber() external view returns(uint) {
        return residents.length;
    }

    /**
    * @dev 加入“大同世界”的唯一入口。
    * 加入“大同世界”的操作,除要消耗支付给以太坊矿工的gas,不需要再任何费用。
    * 但我知道有很多好心人,乐于奉献, 于是这里作为一个payable函数, 你可以再加入“大同世界”的时候,
    * 向这个理想丰满而美好的组织捐赠任意大小的ether,助它更好的成长。
    * @param _name 居民的显示名字
    * @param _identity 各种实名认证之后产生的身份唯一标识.
    * (目前只需传身份证号码，并且非常相信愿意加入“大同世界”的人的行为，没有做太多的认证,
    * 假设这项目有人看好,再做更复杂的认证)
    */
    function joinGreatHarmon(string _name, string _identity) public payable returns(uint) {
        //检测是否重复加入。
        require(idOf[msg.sender] == 0);
        if (msg.value > 0) {
            donateMap[msg.sender] += msg.value;
            Donate(msg.sender, _name, msg.value, "");
        }
        return _createResident(_name, _identity);
    }

    function _createResident(string _name, string _identity) internal returns(uint) {
        uint id = residents.push(Resident(_name, _identity, 0, uint32(now), uint32(now)));
        idOf[msg.sender] = id;
        JoinGreatHarmon(id, _name, _identity, uint32(now));
        getBasicIncome();
        return id;
    }

    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }

    function setCooldownTime(uint _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
    }

    function setBasicIncomeLimit(uint _basicIncomeLimit) external onlyOwner {
        basicIncomeLimit = _basicIncomeLimit;
    }

    function setDailySupply(uint _dailySupply) external onlyOwner {
        dailySupply = _dailySupply;
    }

    mapping (address => bool) public frozenAccount;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenAccount(address target, bool frozen);

    /// @notice `freeze? Prevent | Allow` `target` from get Basic Income
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) external onlyOwner {
        frozenAccount[target] = freeze;
        FrozenAccount(target, freeze);
    }

    mapping (address => uint) public donateMap;

    event Donate(address sender, string name, uint amount, string text);

    // accept ether donate
    function donate(string _text) payable public {
        if (msg.value > 0) {
            donateMap[msg.sender] += msg.value;
            Resident memory _resident = residents[idOf[msg.sender]-1];
            Donate(msg.sender, _resident.name, msg.value, _text);
        }
    }

    // token erc20
    // Public variables of the token
    string public name = "Great Harmon Coin";
    string public symbol = "GHC";
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply = 0;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) { 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
}