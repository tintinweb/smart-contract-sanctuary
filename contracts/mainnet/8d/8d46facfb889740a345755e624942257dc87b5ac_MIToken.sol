pragma solidity ^0.4.18;

contract Owner {
    address public owner;
    //添加断路器
    bool public stopped = false;

    function Owner() internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
       require (msg.sender == owner);
       _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require (newOwner != 0x0);
        require (newOwner != owner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
    }

    function toggleContractActive() onlyOwner public {
        //可以预置改变状态的条件，如基于投票人数
        stopped = !stopped;
    }

    modifier stopInEmergency {
        require(stopped == false);
        _;
    }

    modifier onlyInEmergency {
        require(stopped == true);
        _;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract Mortal is Owner {
    //销毁合约
    function close() external onlyOwner {
        selfdestruct(owner);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Token is Owner, Mortal {
    using SafeMath for uint256;

    string public name; //代币名称
    string public symbol; //代币符号
    uint8 public decimals; //显示多少小数点
    uint256 public totalSupply; //总供应量

    //冻结的基金,解锁的数量根据时间动态计算出来
    struct Fund{
        uint amount;            //总冻结数量，固定值

        uint unlockStartTime;   //从什么时候开始解锁
        uint unlockInterval;    //每次解锁的周期，单位 秒
        uint unlockPercent;     //每次解锁的百分比 50 为50%

        bool isValue; // exist value
    }

    //所有的账户数据
    mapping (address => uint) public balances;
    //代理
    mapping(address => mapping(address => uint)) approved;

    //所有的账户冻结数据，时间，到期自动解冻，同时只支持一次冻结
    mapping (address => Fund) public frozenAccount;

    //事件日志
    event Transfer(address indexed from, address indexed to, uint value);
    event FrozenFunds(address indexed target, uint value, uint unlockStartTime, uint unlockIntervalUnit, uint unlockInterval, uint unlockPercent);
    event Approval(address indexed accountOwner, address indexed spender, uint256 value);

    /**
    *
    * Fix for the ERC20 short address attack
    *
    * http://vessenes.com/the-erc20-short-address-attack-explained/
    */
    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length == size + 4);
        _;
    }

    //冻结固定时间
    function freezeAccount(address target, uint value, uint unlockStartTime, uint unlockIntervalUnit, uint unlockInterval, uint unlockPercent) external onlyOwner freezeOutCheck(target, 0) {
        require (value > 0);
        require (frozenAccount[target].isValue == false);
        require (balances[msg.sender] >= value);
        require (unlockStartTime > now);
        require (unlockInterval > 0);
        require (unlockPercent > 0 && unlockPercent <= 100);

        uint unlockIntervalSecond = toSecond(unlockIntervalUnit, unlockInterval);

        frozenAccount[target] = Fund(value, unlockStartTime, unlockIntervalSecond, unlockPercent, true);
        emit FrozenFunds(target, value, unlockStartTime, unlockIntervalUnit, unlockInterval, unlockPercent);
    }

    //转账并冻结
    function transferAndFreeze(address target, uint256 value, uint unlockStartTime, uint unlockIntervalUnit, uint unlockInterval, uint unlockPercent) external onlyOwner freezeOutCheck(target, 0) {
        require (value > 0);
        require (frozenAccount[target].isValue == false);
        require (unlockStartTime > now);
        require (unlockInterval > 0);
        require (unlockPercent > 0 && unlockPercent <= 100);

        _transfer(msg.sender, target, value);

        uint unlockIntervalSecond = toSecond(unlockIntervalUnit, unlockInterval);
        frozenAccount[target] = Fund(value, unlockStartTime, unlockIntervalSecond, unlockPercent, true);
        emit FrozenFunds(target, value, unlockStartTime, unlockIntervalUnit, unlockInterval, unlockPercent);
    }

    //转换单位时间到秒
    function toSecond(uint unitType, uint value) internal pure returns (uint256 Seconds) {
        uint _seconds;
        if (unitType == 5){
            _seconds = value.mul(1 years);
        }else if(unitType == 4){
            _seconds = value.mul(1 days);
        }else if (unitType == 3){
            _seconds = value.mul(1 hours);
        }else if (unitType == 2){
            _seconds = value.mul(1 minutes);
        }else if (unitType == 1){
            _seconds = value;
        }else{
            revert();
        }
        return _seconds;
    }

    modifier freezeOutCheck(address sender, uint value) {
        require ( getAvailableBalance(sender) >= value);
        _;
    }

    //计算可用余额 去除冻结部分
    function getAvailableBalance(address sender) internal returns(uint balance) {
        if (frozenAccount[sender].isValue) {
            //未开始解锁
            if (now < frozenAccount[sender].unlockStartTime){
                return balances[sender] - frozenAccount[sender].amount;
            }else{
                //计算解锁了多少数量
                uint unlockPercent = ((now - frozenAccount[sender].unlockStartTime ) / frozenAccount[sender].unlockInterval + 1) * frozenAccount[sender].unlockPercent;
                if (unlockPercent > 100){
                    unlockPercent = 100;
                }

                //计算可用余额 = 总额 - 冻结总额
                assert(frozenAccount[sender].amount <= balances[sender]);
                uint available = balances[sender] - (100 - unlockPercent) * frozenAccount[sender].amount / 100;
                if ( unlockPercent >= 100){
                    //release
                    frozenAccount[sender].isValue = false;
                    delete frozenAccount[sender];
                }

                return available;
            }
        }
        return balances[sender];
    }

    function balanceOf(address sender) constant external returns (uint256 balance){
        return balances[sender];
    }

    /* 代币转移的函数 */
    function transfer(address to, uint256 value) external stopInEmergency onlyPayloadSize(2 * 32) {
        _transfer(msg.sender, to, value);
    }

    function _transfer(address _from, address _to, uint _value) internal freezeOutCheck(_from, _value) {
        require(_to != 0x0);
        require(_from != _to);
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    //设置代理交易
    //允许spender多次取出您的帐户，最高达value金额。value可以设置超过账户余额
    function approve(address spender, uint value) external returns (bool success) {
        approved[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    //返回spender仍然被允许从accountOwner提取的金额
    function allowance(address accountOwner, address spender) constant external returns (uint remaining) {
        return approved[accountOwner][spender];
    }

    //使用代理交易
    //0值的传输必须被视为正常传输并触发传输事件
    //代理交易不自动为对方补充gas
    function transferFrom(address from, address to, uint256 value) external stopInEmergency freezeOutCheck(from, value)  returns (bool success) {
        require(value > 0);
        require(value <= approved[from][msg.sender]);
        require(value <= balances[from]);

        approved[from][msg.sender] = approved[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
}

contract MigrationAgent {
  function migrateFrom(address from, uint256 value) public;
}

contract UpgradeableToken is Owner, Token {
  address public migrationAgent;

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed from, address indexed to, uint256 value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  // Migrate tokens to the new token contract
  function migrate() public {
    require(migrationAgent != 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = balances[msg.sender].sub(value);
    totalSupply = totalSupply.sub(value);
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
    emit Upgrade(msg.sender, migrationAgent, value);
  }

  function () public payable {
    require(migrationAgent != 0);
    require(balances[msg.sender] > 0);
    migrate();
    msg.sender.transfer(msg.value);
  }

  function setMigrationAgent(address _agent) onlyOwner external {
    migrationAgent = _agent;
    emit UpgradeAgentSet(_agent);
  }
}

contract MIToken is UpgradeableToken {

  function MIToken() public {
    name = "MI Token";
    symbol = "MI";
    decimals = 18;

    owner = msg.sender;
    uint initialSupply = 100000000;

    totalSupply = initialSupply * 10 ** uint256(decimals);
    require (totalSupply >= initialSupply);

    balances[msg.sender] = totalSupply;
    emit Transfer(0x0, msg.sender, totalSupply);
  }
  
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      
      emit Transfer(address(0), _to, _amount);
      return true;
  }
  
}