pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract Exchangable {
  address public exchanger;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    exchanger = address(0);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyExchange() {
    require(msg.sender == exchanger);
    _;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract MintableToken is StandardToken, Ownable, Exchangable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[address(this)] = balances[address(this)].add(_amount);
    emit Mint(address(this), _amount);
    emit Transfer(address(0), address(this), _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

contract ZWCToken is MintableToken, PausableToken {
    string public constant name = "ZWCToken"; // solium-disable-line uppercase
    string public constant symbol = "ZWC"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    uint256 public constant INITIAL_SUPPLY = 2718281828 * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[address(this)] = INITIAL_SUPPLY;
        emit Transfer(0x0, address(this), INITIAL_SUPPLY);
    }

    /**
    * @dev Function to mint tokens
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
        return super.mint(_amount);
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint whenNotPaused public returns (bool) {
        return super.finishMinting();
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner whenNotPaused public {
        super.transferOwnership(newOwner);
    }

    function setExchanger(address _address)
        public
        onlyOwner
    {
        require(_address != address(0));
        exchanger = _address;
    }

    function safeExchange(address to_address, uint256 amount)
        public
        payable
        onlyExchange
        returns (bool)
    {
        require(to_address != address(0));
        require(amount <= balances[address(this)]);

        balances[address(this)] = balances[address(this)].sub(amount);
        balances[to_address] = balances[to_address].add(amount);
        emit Transfer(0x0, to_address, amount);
        return true;
    }

    /**
    * The fallback function.
    */
    function() payable public {
        revert();
    }
}

contract ZWExchange is Ownable {
    using SafeMath for uint256;

    /*
     *  Events
     */
    event EventAddToken(address indexed token_address,
                        uint256 token_rate,
                        bool token_enable,
                        uint256 token_daily_exchange_amount_wei);

    event EventUpdateTokenRate(address indexed token_address,
                        uint256 token_rate);

    event EventUpdateTokenDailyExchangeAmount(address indexed token_address,
                        uint256 token_daily_exchange_amount_wei);

    event EventTokenSwitch(address indexed token_address,
                        bool token_enable);

    event EventCreateExchange(address indexed creator,
                        address indexed zwc_address);

    event EventExchangeSwitch(bool enable);

    event EventExchangeTokenToZWCGetToken(address indexed src_address,
                                address indexed dst_address,
                                address indexed token_address,
                                uint256 token_amount_wei);

    event EventExchangeTokenToZWC(address indexed src_address,
                                address indexed dst_address,
                                address indexed token_address,
                                uint256 token_amount_wei,
                                uint256 zwc_amount_wei);

    // for debug
    event EventIsDailyUplimitReach(address indexed token_address,
                                    uint256 token_amount_wei,
                                    uint256 now,
                                    uint256 curr_day,
                                    uint256 latest_exchange_timestamp,
                                    uint256 latest_exchange_day,
                                    uint256 today_exchange_amount_wei,
                                    uint256 daily_exchange_amount_wei);

    event EventCalcZWCAmountByToken(address indexed token_address,
                                    uint256 token_amount_wei,
                                    uint256 rate,
                                    uint256 zwc_amount_wei);

    /*
     *  Constants
     */
    // (max_rate: zwc:token = 1 : 10 ** 8)
    // (min_rate: zwc:token = 10 ** 6 : 1)
    uint256 constant internal MAX_RATE_POWER = 8;    //token相对于zwc的汇率的最大幂数
    uint256 constant internal RATE_DECIMAL = 6;      //汇率的指数放大因子 (rate = real_rate * 10 ** 6)

    /*
     *  Storage
     */
    mapping (address => TokenInfo) public tokenMap;   //token信息列表
    mapping (address => bool) public tokenWhiteList;  //已注册的token名单
    uint256 public tokenCount;                        //已注册的token数量
    bool public exchangeEnable;                       //兑换功能全局开关
    ZWCToken public zwcToken;                 //ZWC token obj

    //token信息
    struct TokenInfo {
        // zwc与token之间的汇率：1 zwc = x token,
        // x的取值范围： 小于100000000 (10 ** 8 (MAX_RATE_POWER)), 大于0.000001 (10 ** -6)
        // rate >= 1, rate = x * (10 ** 6), reat需要放大的倍数(10 ** RATE_DECIMAL)
        uint256   rate;

        //是否可兑换
        bool      enable;

        //token每日全局兑换上限 (token兑出数量, token兑换成ZWC)
        uint256   daily_exchange_amount_wei;

        //最近一次兑换时间戳
        uint256   latest_exchange_timestamp;

        //当日已兑换数量
        uint256   today_exchange_amount_wei;
    }

    /*
     *  Modifiers
     */
    modifier notNullAddress(address _address) {
        require(_address != 0);
        _;
    }

    //token是否存在
    modifier tokenExists(address _address) {
        require(tokenWhiteList[_address]);
        _;
    }

    //token是否不存在
    modifier tokenNotExists(address _address) {
        require(!tokenWhiteList[_address]);
        _;
    }

    //token兑换开关检查
    modifier isTokenEnable(address _address) {
        require(tokenWhiteList[_address]);
        require(tokenMap[_address].enable);
        _;
    }

    //兑换总开关检查
    modifier isExchangeEnable() {
        require(exchangeEnable);
        _;
    }

    //汇率有效性检查
    modifier validRate(uint256 token_rate) {
        require((token_rate <= (10 ** (MAX_RATE_POWER + RATE_DECIMAL))) &&
                (token_rate >= 1));
        _;
    }

    /*
     * Public functions
     */
    //合约构造
    constructor(ZWCToken zwc_token)
      public
      notNullAddress(address(zwc_token))
    {
        tokenCount = 0;
        exchangeEnable = true;
        zwcToken = zwc_token;
        emit EventCreateExchange(msg.sender, address(zwc_token));
    }

    //设置兑换总开关
    function ExchangeSwitch(bool enable)
        public
        onlyOwner()
    {
        exchangeEnable = enable;
        emit EventExchangeSwitch(enable);
    }

    //添加token
    function AddToken(address token_address,
                    uint256 token_rate,
                    bool token_enable,
                    uint256 token_daily_exchange_amount_wei)
        public
        onlyOwner()
        notNullAddress(token_address)
        tokenNotExists(token_address)
        validRate(token_rate)
    {
        tokenMap[token_address] = TokenInfo({
            rate:                       token_rate,
            enable:                     token_enable,
            daily_exchange_amount_wei:  token_daily_exchange_amount_wei,
            latest_exchange_timestamp:  0,
            today_exchange_amount_wei:  0
        });

        tokenCount += 1;
        tokenWhiteList[token_address] = true;

        emit EventAddToken(token_address,
                            token_rate,
                            token_enable,
                            token_daily_exchange_amount_wei);
    }

    //更新token汇率
    function UpdateTokenRate(address token_address, uint256 token_rate)
        public
        onlyOwner()
        notNullAddress(token_address)
        tokenExists(token_address)
        validRate(token_rate)
    {
        tokenMap[token_address].rate = token_rate;
        emit EventUpdateTokenRate(token_address, token_rate);
    }

    //更新token每日兑换上限
    function UpdateTokenDailyExchangeAmount(address token_address,
                                            uint256 token_daily_exchange_amount_wei)
        public
        onlyOwner()
        notNullAddress(token_address)
        tokenExists(token_address)
    {
        tokenMap[token_address].daily_exchange_amount_wei = token_daily_exchange_amount_wei;
        emit EventUpdateTokenDailyExchangeAmount(token_address, token_daily_exchange_amount_wei);
    }

    //token兑换开关
    function TokenSwitch(address token_address,
                        bool enable)
        public
        onlyOwner()
        notNullAddress(token_address)
        tokenExists(token_address)
    {
        tokenMap[token_address].enable = enable;
        emit EventTokenSwitch(token_address, enable);
    }

    //token兑换成ZWC
    function ExchangeTokenToZWC(address token_address,
                                uint256 token_amount_wei)
        public
        payable
        notNullAddress(token_address)
        tokenExists(token_address)
        isExchangeEnable()
    {
        //检查当日兑换上限
        if (isDailyUplimitReach(token_address, token_amount_wei))
        {
            return;
        }

        //根据汇率计算token可以兑换的zwc数量
        // uint256 zwc_amount_wei = 1000000000000000000;
        uint256 zwc_amount_wei = calcZWCAmountByToken(token_address, token_amount_wei);
        if (zwc_amount_wei == 0)
        {
            emit EventExchangeTokenToZWC(msg.sender,
                                          owner,
                                          token_address,
                                          token_amount_wei,
                                          zwc_amount_wei);
            return;
        }

        //检查zwc合约中剩余的zwc数量是否足够
        require(zwcToken.balanceOf(address(zwcToken)) >= zwc_amount_wei);

        //检查用户剩余的token数量是否足够
        StandardToken erc20Token = StandardToken(token_address);
        require(erc20Token.balanceOf(msg.sender) >= token_amount_wei);

        //用户把自己的token转移到owner账户中, 之前需要用户先调用approve
        require(erc20Token.transferFrom(msg.sender, owner, token_amount_wei));
        emit EventExchangeTokenToZWCGetToken(msg.sender,
                                            owner,
                                            token_address,
                                            token_amount_wei);

        //把zwc转移到用户账户中
        require(zwcToken.safeExchange(msg.sender, zwc_amount_wei));
        emit EventExchangeTokenToZWC(msg.sender,
                                    address(zwcToken),
                                    token_address,
                                    token_amount_wei,
                                    zwc_amount_wei);

        tokenMap[token_address].latest_exchange_timestamp = now;
        tokenMap[token_address].today_exchange_amount_wei += token_amount_wei;
        return;
    }

    /*
     * Internal functions
     */
    function isDailyUplimitReach(address token_address,
                                uint256 token_amount_wei)
        internal
        notNullAddress(token_address)
        tokenExists(token_address)
        returns (bool)
    {
        uint256 today_exchange_amount_wei = tokenMap[token_address].today_exchange_amount_wei;
        uint256 daily_exchange_amount_wei = tokenMap[token_address].daily_exchange_amount_wei;
        uint256 latest_exchange_timestamp = tokenMap[token_address].latest_exchange_timestamp;

        //检查是否是当日
        uint256 curr_day = now / 86400;
        uint256 latest_exchange_day = latest_exchange_timestamp / 86400;

        emit EventIsDailyUplimitReach(token_address,
                                      token_amount_wei,
                                      now,
                                      curr_day,
                                      latest_exchange_timestamp,
                                      latest_exchange_day,
                                      today_exchange_amount_wei,
                                      daily_exchange_amount_wei);
        //当日
        if (curr_day == latest_exchange_day)
        {
            if (today_exchange_amount_wei + token_amount_wei > daily_exchange_amount_wei)
            {
                return true;
            }

            return false;
        }

        if (curr_day < latest_exchange_day)
        {
            return true;
        }

        if (curr_day > latest_exchange_day)
        {
            tokenMap[token_address].today_exchange_amount_wei = 0;
            return false;
        }

        return false;
    }

    //计算token能换成多少ZWC
    function calcZWCAmountByToken(address token_address,
                                  uint256 token_amount_wei)
        internal
        notNullAddress(token_address)
        tokenExists(token_address)
        returns (uint256)
    {
        uint256 rate = tokenMap[token_address].rate;
        uint256 zwc_amount_wei = token_amount_wei.mul(rate);

        zwc_amount_wei = zwc_amount_wei.div(10 ** RATE_DECIMAL);
        emit EventCalcZWCAmountByToken(token_address,
                                      token_amount_wei,
                                      rate,
                                      zwc_amount_wei);
        return zwc_amount_wei;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable
    {
        revert();
    }
}