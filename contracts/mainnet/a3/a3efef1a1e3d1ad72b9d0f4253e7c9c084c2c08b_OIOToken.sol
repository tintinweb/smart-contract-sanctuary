pragma solidity ^0.4.18;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract ERC20Implementation is ERC20, BurnableToken, Ownable {

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



contract BasicFreezableToken is ERC20Implementation {

  address[] internal investors;
  mapping (address => bool) internal isInvestor;
  bool frozen;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!frozen);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

}

contract ERC20FreezableImplementation is BasicFreezableToken {

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!frozen);
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
    require(!frozen);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(!frozen);
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(!frozen);
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function freeze() onlyOwner public {
    frozen = true;
  }


  function unFreeze() onlyOwner public {
    frozen = false;
  }

}

contract OIOToken is ERC20FreezableImplementation {

  string public name;
  string public symbol;
  uint8 public decimals;
  
  
  constructor(address[] _investors, uint256[] _tokenAmount, uint256 _totalSupply, string _name, string _symbol, uint8 _decimals) public {
    require(_investors.length == _tokenAmount.length);

    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    
    uint256 dif = 0;
    totalSupply_ = _totalSupply;
    for (uint i=0; i<_investors.length; i++) {
      balances[_investors[i]] = balances[_investors[i]].add(_tokenAmount[i]);
      isInvestor[_investors[i]] = true;
      investors.push(_investors[i]);
      dif = dif.add(_tokenAmount[i]);
    }
    balances[msg.sender] = totalSupply_.sub(dif);
    isInvestor[msg.sender] = true;
    investors.push(msg.sender);
    frozen = false;
  }

  
  function transferBack(address _from, uint256 _tokenAmount) onlyOwner public {
    require(_from != address(0));
    require(_tokenAmount <= balances[_from]);
    
    balances[_from] = balances[_from].sub(_tokenAmount);
    balances[msg.sender] = balances[msg.sender].add(_tokenAmount);
    emit Transfer(_from, msg.sender, _tokenAmount);
  }

 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!frozen);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (!isInvestor[_to]) {
      isInvestor[_to] = true;
      investors.push(_to);
    }
    emit Transfer(_from, _to, _value);
    return true;
  }

 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!frozen);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (!isInvestor[_to]) {
      isInvestor[_to] = true;
      investors.push(_to);
    }
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function transferBulk(address[] _toAccounts, uint256[] _tokenAmount) onlyOwner public {
    require(_toAccounts.length == _tokenAmount.length);
    for(uint i=0; i<_toAccounts.length; i++) {
      balances[msg.sender] = balances[msg.sender].sub(_tokenAmount[i]); 
      balances[_toAccounts[i]] = balances[_toAccounts[i]].add(_tokenAmount[i]);
      if(!isInvestor[_toAccounts[i]]){
        isInvestor[_toAccounts[i]] = true;
        investors.push(_toAccounts[i]);
      }
    }
  }

  
  function getInvestorsAndTheirBalances() public view returns (address[], uint[]) {
      uint[] memory tempBalances = new uint[](investors.length);
      for(uint i=0; i<investors.length; i++) {
        tempBalances[i] = balances[investors[i]];
      }
       return (investors, tempBalances);
  }

}