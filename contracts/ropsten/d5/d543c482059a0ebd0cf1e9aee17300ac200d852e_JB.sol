pragma solidity ^0.4.24;
// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// ERC20 standard token
contract JB is StandardToken {
    address public admin; // 管理员
    string public name = "JB Token"; // 代币名称
    string public symbol = "JB"; // 代币符号
    uint8 public decimals = 18; // 代币精度
    uint256 public INITIAL_SUPPLY = 8000000000000000000000000000; // 总量80亿 *10^18
    // 同一个账户满足任意冻结条件均被冻结
    mapping (address => bool) public frozenAccount; //无限期冻结的账户
    mapping (address => uint256) public frozenTimestamp; // 有限期冻结的账户

    bool public exchangeFlag = true; // 代币兑换开启
    // 不满足条件或募集完成多出的eth均返回给原账户
    uint256 public minWei = 1;  //最低打 1 wei  1eth = 1*10^18 wei
    uint256 public maxWei = 20000000000000000000000; // 最多一次打 20000 eth
    uint256 public maxRaiseAmount = 20000000000000000000000; // 募集上限 20000 eth
    uint256 public raisedAmount = 0; // 已募集 0 eth
    uint256 public raiseRatio = 200000; // 兑换比例 1eth = 20万token
    // event 通知
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 构造函数
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        admin = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    // fallback 向合约地址转账 or 调用非合约函数触发
    // 代币自动兑换eth
    function()
    public payable {
        require(msg.value > 0);
        if (exchangeFlag) {
            if (msg.value >= minWei && msg.value <= maxWei){
                if (raisedAmount < maxRaiseAmount) {
                    uint256 valueNeed = msg.value;
                    raisedAmount = raisedAmount.add(msg.value);
                    if (raisedAmount > maxRaiseAmount) {
                        uint256 valueLeft = raisedAmount.sub(maxRaiseAmount);
                        valueNeed = msg.value.sub(valueLeft);
                        msg.sender.transfer(valueLeft);
                        raisedAmount = maxRaiseAmount;
                    }
                    if (raisedAmount >= maxRaiseAmount) {
                        exchangeFlag = false;
                    }
                    // 已处理过精度 *10^18
                    uint256 _value = valueNeed.mul(raiseRatio);

                    require(_value <= balances[admin]);
                    balances[admin] = balances[admin].sub(_value);
                    balances[msg.sender] = balances[msg.sender].add(_value);

                    emit Transfer(admin, msg.sender, _value);

                }
            } else {
                msg.sender.transfer(msg.value);
            }
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    /**
    * 修改管理员
    */
    function changeAdmin(
        address _newAdmin
    )
    public
    returns (bool)  {
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        balances[_newAdmin] = balances[_newAdmin].add(balances[admin]);
        balances[admin] = 0;
        admin = _newAdmin;
        return true;
    }
    /**
    * 增发
    */
    function generateToken(
        address _target,
        uint256 _amount
    )
    public
    returns (bool)  {
        require(msg.sender == admin);
        require(_target != address(0));
        balances[_target] = balances[_target].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        INITIAL_SUPPLY = totalSupply_;
        return true;
    }

    // 从合约提现
    // 只能提给管理员
    function withdraw (
        uint256 _amount
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        msg.sender.transfer(_amount);
        return true;
    }
    /**
    * 锁定账户
    */
    function freeze(
        address _target,
        bool _freeze
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }
    /**
    * 通过时间戳锁定账户
    */
    function freezeWithTimestamp(
        address _target,
        uint256 _timestamp
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }

    /**
        * 批量锁定账户
        */
    function multiFreeze(
        address[] _targets,
        bool[] _freezes
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }
    /**
            * 批量通过时间戳锁定账户
            */
    function multiFreezeWithTimestamp(
        address[] _targets,
        uint256[] _timestamps
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address _target = _targets[i];
            require(_target != address(0));
            uint256 _timestamp = _timestamps[i];
            frozenTimestamp[_target] = _timestamp;
        }
        return true;
    }
    /**
    * 批量转账
    */
    function multiTransfer(
        address[] _tos,
        uint256[] _values
    )
    public
    returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j = j.add(1)) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }
    /**
    * 从调用者转账至_to
    */
    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /*
    * 从调用者作为from代理将from账户中的token转账至to
    * 调用者在from的许可额度中必须>=value
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(!frozenAccount[_from]);
        require(now > frozenTimestamp[msg.sender]);
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
    * 调整转账代理方spender的代理的许可额度
    */
    function approve(
        address _spender,
        uint256 _value
    ) public
    returns (bool) {
        // 转账的时候会校验balances，该处require无意义
        // require(_value <= balances[msg.sender]);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
    * 增加转账代理方spender的代理的许可额度
    * 意义不大的function
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        // uint256 value_ = allowed[msg.sender][_spender].add(_addedValue);
        // require(value_ <= balances[msg.sender]);
        // allowed[msg.sender][_spender] = value_;

        // emit Approval(msg.sender, _spender, value_);
        return true;
    }
    /**
    * 减少转账代理方spender的代理的许可额度
    * 意义不大的function
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        // uint256 oldValue = allowed[msg.sender][_spender];
        // if (_subtractedValue > oldValue) {
        //    allowed[msg.sender][_spender] = 0;
        // } else {
        //    uint256 newValue = oldValue.sub(_subtractedValue);
        //    require(newValue <= balances[msg.sender]);
        //   allowed[msg.sender][_spender] = newValue;
        //}

        // emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    //********************************************************************************
    //查询账户是否存在锁定时间戳
    function getFrozenTimestamp(
        address _target
    )
    public view
    returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }
    //查询账户是否被锁定
    function getFrozenAccount(
        address _target
    )
    public view
    returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }
    //查询合约的余额
    function getBalance()
    public view
    returns (uint256) {
        return address(this).balance;
    }
    // 修改name
    function setName (
        string _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        name = _value;
        return true;
    }
    // 修改symbol
    function setSymbol (
        string _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        symbol = _value;
        return true;
    }

    // 修改募集flag
    function setExchangeFlag (
        bool _flag
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        exchangeFlag = _flag;
        return true;

    }
    // 修改单笔募集下限
    function setMinWei (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        minWei = _value;
        return true;

    }
    // 修改单笔募集上限
    function setMaxWei (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        maxWei = _value;
        return true;
    }
    // 修改总募集上限
    function setMaxRaiseAmount (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        maxRaiseAmount = _value;
        return true;
    }

    // 修改已募集数
    function setRaisedAmount (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        raisedAmount = _value;
        return true;
    }

    // 修改募集比例
    function setRaiseRatio (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        raiseRatio = _value;
        return true;
    }

    // 销毁合约
    function kill()
    public {
        require(msg.sender == admin);
        selfdestruct(admin);
    }

}