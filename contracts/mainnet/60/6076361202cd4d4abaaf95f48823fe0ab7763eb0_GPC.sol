pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

contract GPC is StandardToken {

  address public administror;
  string public name = "Global-Pay Coin";
  string public symbol = "GPC";
  uint8 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 1000000000*10**18;
  mapping (address => uint256) public frozenAccount;
  bool public exchangeFlag = true;
  uint256 public minWei = 1;
  uint256 public maxWei = 200*10**18;
  uint256 public maxRaiseAmount = 2000*10**18;
  uint256 public raisedAmount = 0;
  uint256 public raiseRatio = 10000;

  // 事件
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed target, uint256 value);

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    administror = msg.sender;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  // 自动兑换
  function() public payable {
    require(msg.value > 0);
    if (exchangeFlag) {
      if (msg.value >= minWei && msg.value <= maxWei) {
        if (raisedAmount < maxRaiseAmount) {
          uint256 valueNeed = msg.value;
          raisedAmount = raisedAmount.add(msg.value);
          if (raisedAmount >= maxRaiseAmount) {
            exchangeFlag = false;
          }
          uint256 _value = valueNeed.mul(raiseRatio);
          require(balances[administror] >= _value);
          balances[administror] = balances[administror].sub(_value);
          balances[msg.sender] = balances[msg.sender].add(_value);
        }
      } else {
        msg.sender.transfer(msg.value);
      }
    } else {
      msg.sender.transfer(msg.value);
    }
  }

  // 提款
  function withdraw(uint256 _amount) public returns (bool) {
    require(msg.sender == administror);
    msg.sender.transfer(_amount);
    return true;
  }

  // 增发
  function SEOS(uint256 _amount) public returns (bool) {
    require(msg.sender == administror);
    balances[msg.sender] = balances[msg.sender].add(_amount);
    totalSupply_ = totalSupply_.add(_amount);
    INITIAL_SUPPLY = totalSupply_;
    return true;
  }

  // 锁定帐户
  function freezeAccount(address _target, uint _timestamp) public returns (bool) {
    require(msg.sender == administror);
    require(_target != address(0));
    frozenAccount[_target] = _timestamp;
    return true;
  }

  // 批量锁定帐户
  function multiFreezeAccount(address[] _targets, uint _timestamp) public returns (bool) {
    require(msg.sender == administror);
    uint256 len = _targets.length;
    require(len > 0);
    for (uint256 i = 0; i < len; i = i.add(1)) {
      address _target = _targets[i];
      require(_target != address(0));
      frozenAccount[_target] = _timestamp;
    }
    return true;
  }

  // 转帐
  function transfer(address _target, uint256 _amount) public returns (bool) {
    require(now > frozenAccount[msg.sender]);
    require(_target != address(0));
    require(balances[msg.sender] >= _amount);
    balances[_target] = balances[_target].add(_amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);

    emit Transfer(msg.sender, _target, _amount);

    return true;
  }

  // 批量转帐
  function multiTransfer(address[] _targets, uint256[] _amounts) public returns (bool) {
    require(now > frozenAccount[msg.sender]);
    uint256 len = _targets.length;
    require(len > 0);
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < len; i = i.add(1)) {
      totalAmount = totalAmount.add(_amounts[i]);
    }
    require(balances[msg.sender] >= totalAmount);
    for (uint256 j = 0; j < len; j = j.add(1)) {
      address _target = _targets[j];
      uint256 _amount = _amounts[j];
      require(_target != address(0));
      balances[_target] = balances[_target].add(_amount);
      balances[msg.sender] = balances[msg.sender].sub(_amount);

      emit Transfer(msg.sender, _target, _amount);
    }
  }

  // 燃烧
  function burn(address _target, uint256 _amount) public returns (bool) {
    require(msg.sender == administror);
    require(_target != address(0));
    require(balances[_target] >= _amount);
    balances[_target] = balances[_target].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
    INITIAL_SUPPLY = totalSupply_;

    emit Burn(_target, _amount);

    return true;
  }

  // 查询帐户是否被锁定
  function frozenOf(address _target) public view returns (uint256) {
    require(_target != address(0));
    return frozenAccount[_target];
  }

  // 修改是否开启兑换
  function setExchangeFlag(bool _flag) public returns (bool) {
    require(msg.sender == administror);
    exchangeFlag = _flag;
    return true;
  }

  // 修改总体募集上限
  function setMaxRaiseAmount(uint256 _amount) public returns (bool) {
    require(msg.sender == administror);
    maxRaiseAmount = _amount;
    return true;
  }

  // 修改兑换比例
  function setRaiseRatio(uint256 _ratio) public returns (bool) {
    require(msg.sender == administror);
    raiseRatio = _ratio;
    return true;
  }
}