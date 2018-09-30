pragma solidity ^0.4.24;

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

contract ERC20Basic {
  uint256 public totalSupply;
  uint8 public decimals;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

    // SafeMath.sub will throw if there is not enough balance.
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
      public
      returns (bool success) {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
      public
      returns (bool success) {
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

contract ExchangableToken is StandardToken {
    function TransferToken(address from_address, address to_address, uint256 amount)
        public
        returns (bool)
    {
        balances[from_address] = balances[from_address].sub(amount);
        balances[to_address] = balances[to_address].add(amount);
        emit Transfer(0x0, to_address, amount);
        return true;
    }
}

contract ZWExchange is ExchangableToken, Ownable {
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
    ExchangableToken public zwcToken;                 //ZWC token obj

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
                (token_rate >= (10 ** (0 + RATE_DECIMAL))));
        _;
    }

    /*
     * Public functions
     */
    //合约构造
    constructor(ExchangableToken zwc_token)
      public
      notNullAddress(address(zwc_token))
    {
        tokenCount = 0;
        exchangeEnable = true;

        // zwcToken = createTokenContract();
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
    function TokenSwitch(address token_address, bool enable)
        public
        onlyOwner()
        notNullAddress(token_address)
        tokenExists(token_address)
    {
        tokenMap[token_address].enable = enable;
        emit EventTokenSwitch(token_address, enable);
    }

    //token兑换成ZWC
    function ExchangeTokenToZWC(address token_address, uint256 token_amount_wei)
        public
        notNullAddress(token_address)
        tokenExists(token_address)
        isExchangeEnable()
    {
        //根据汇率计算token可以兑换的zwc数量
        uint256 zwc_amount_wei = calcZWCAmountByToken(token_address, token_amount_wei);
        if (zwc_amount_wei == 0)
        {
            emit EventExchangeTokenToZWC(msg.sender, owner, token_address, token_amount_wei, zwc_amount_wei);
            return;
        }

        //检查zwc合约中剩余的zwc数量是否足够
        require(zwcToken.balanceOf(address(zwcToken)) >= zwc_amount_wei);

        //检查用户剩余的token数量是否足够
        ExchangableToken otherToken = ExchangableToken(token_address);
        require(otherToken.balanceOf(msg.sender) >= token_amount_wei);

        //用户把自己的token转移到owner账户中, 之前需要用户先调用approve
        require(otherToken.transferFrom(msg.sender, owner, token_amount_wei));
        emit EventExchangeTokenToZWCGetToken(msg.sender, owner, token_address, token_amount_wei);

        //把zwc转移到用户账户中
        require(zwcToken.TransferToken(address(zwcToken), msg.sender, zwc_amount_wei));
        emit EventExchangeTokenToZWC(msg.sender, address(zwcToken), token_address, token_amount_wei, zwc_amount_wei);

        return;
    }

    /*
     * Internal functions
     */
    //计算token能换成多少ZWC
    function calcZWCAmountByToken(address token_address, uint256 token_amount_wei)
        internal
        view
        notNullAddress(token_address)
        tokenExists(token_address)
        returns (uint256)
    {
        uint256 rate = tokenMap[token_address].rate;

        uint256 token_amount = fromWei(token_address, token_amount_wei);
        uint256 zwc_amount = token_amount.mul(rate);

        uint256 zwc_amount_wei = toWei(address(zwcToken), zwc_amount);
        zwc_amount_wei = zwc_amount_wei.div(10 ** RATE_DECIMAL);

        return zwc_amount_wei;
    }

    function fromWei(address _address, uint256 _amount_wei)
        internal
        view
        returns (uint256)
    {
        ExchangableToken token = ExchangableToken(_address);
        uint256 token_decimals = uint256(token.decimals());
        uint256 amount = _amount_wei.div(token_decimals);
        return amount;
    }

    function toWei(address _address, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        ExchangableToken token = ExchangableToken(_address);
        uint256 token_decimals = uint256(token.decimals());
        uint256 amount_wei = _amount.mul(10 ** token_decimals);
        return amount_wei;
    }

    function createTokenContract()
      internal
      returns (ExchangableToken)
    {
        return new ExchangableToken();
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable
    {
        revert();
    }
}