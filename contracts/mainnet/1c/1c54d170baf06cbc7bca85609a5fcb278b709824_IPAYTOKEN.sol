pragma solidity ^0.4.11;

contract IPAYTOKEN {
  uint256 public totalSupply=300000000 * (10 ** decimals);
  string public name="Ipay";
  uint256 public decimals=18;
  string public symbol="IPAY";
  address public owner;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  struct BalanceLock{
    uint256 releaseTime;
    uint256 amount;
  }
  mapping (address => BalanceLock[]) balanceLocks;

  function IPAYTOKEN() public {
    owner = msg.sender;
    balances[msg.sender] = totalSupply;
  }

  //Fix for short address attack against ERC20
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  } 

  function grantStock(address _to,uint256 delayTime, uint256 amount) public {
    assert(amount >= 0);
    require(msg.sender == owner);

    balanceLocks[_to].push(BalanceLock(now+delayTime,amount));
  }

  function getStockTotal(address _owner) constant public returns (uint256) {
    uint256 result=0;

    BalanceLock[] _bs = balanceLocks[_owner];
    for(uint i = 0; i < _bs.length; i++){
      result += _bs[i].amount;
    }
    return result;
  }

  function getStockCount(address _owner) constant public returns (uint256) {
    return balanceLocks[_owner].length;
  }

  function getStockAmount(address _owner,uint256 _index) constant public returns (uint256) {
    return balanceLocks[_owner][_index].amount;
  }

  function getStockReleaseTime(address _owner,uint256 _index) constant public returns (uint256) {
    return balanceLocks[_owner][_index].releaseTime;
  }

  function balanceOf(address _owner) constant public returns (uint256) {
    uint256 balance = balances[_owner];

    BalanceLock[] _bs = balanceLocks[_owner];
    for(uint i = 0; i < _bs.length; i++){
      balance += _bs[i].amount;
    }
    return balance;
  }

  function transfer(address _recipient, uint256 _value) onlyPayloadSize(2*32) public {
    BalanceLock[] _bs = balanceLocks[msg.sender];
    for(uint i = 0; i < _bs.length; i++){
      if(now >= _bs[i].releaseTime){
        balances[msg.sender] += _bs[i].amount;
        delete _bs[i];
        for (uint j = i; j<_bs.length-1; j++) {
          _bs[j] = _bs[j+1];
        }
        _bs.length--;
        i--;
      }
    }

    require(balances[msg.sender] >= _value && _value > 0);
      balances[msg.sender] -= _value;
      balances[_recipient] += _value;
      emit Transfer(msg.sender, _recipient, _value);        
    }

  function transferFrom(address _from, address _to, uint256 _value) public {
    BalanceLock[] _bs = balanceLocks[msg.sender];
    for(uint i = 0; i < _bs.length; i++){
      if(now >= _bs[i].releaseTime){
        balances[msg.sender] += _bs[i].amount;
        delete _bs[i];
        for (uint j = i; j<_bs.length-1; j++) {
          _bs[j] = _bs[j+1];
        }
        _bs.length--;
        i--;
      }
    }

    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

  function approve(address _spender, uint256 _value) public {
    assert(_value >= 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant public returns (uint256) {
    return allowed[_owner][_spender];
  }

  function mint(uint256 amount) public {
    assert(amount >= 0);
    require(msg.sender == owner);
    balances[msg.sender] += amount;
    totalSupply += amount;
  }

  //Event which is triggered to log all transfers to this contract&#39;s event log
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
    );
    
  //Event which is triggered whenever an owner approves a new allowance for a spender.
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
    );

}