pragma solidity ^0.4.10;

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract ArpachainToken is ERC20 {
  using SafeMath for uint;
     
    string internal _name;
    string internal _symbol;
    uint8 public decimals = 6;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    constructor() public {
      _symbol = "OCT";
      _name = "OC Test";
      _totalSupply = 10 * 1000000;
      balances[msg.sender] = _totalSupply;
      emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string) {
      return _name;
    }

    function symbol() public view returns (string) {
      return _symbol;
    }
    
    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
      require(_to != address(0));
      require(_value <= balances[_from]);
      require(_value > 0);
      require(balances[_to] + _value > balances[_to]);
     
      uint256 previousBalances = balances[_from] + balances[_to];
      balances[_from] = SafeMath.sub(balances[_from], _value);
      balances[_to] = SafeMath.add(balances[_to], _value);
      emit Transfer(_from, _to, _value);
      assert(balances[_from] + balances[_to] == previousBalances);
    }

   function transfer(address _to, uint256 _value) public returns (bool) {
     _transfer(msg.sender, _to, _value);
     return true;
   }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
   }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_value <= allowed[_from][msg.sender]);
      _transfer(_from, _to, _value);
      allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
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

  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function increaseTotalSupply(uint256 _addedValue) public returns (bool) {
    _totalSupply = SafeMath.add(_totalSupply, _addedValue);
    balances[msg.sender] = SafeMath.add(balances[msg.sender], _addedValue);
    emit Transfer(address(0), msg.sender, _addedValue);
    return true;
  }

}