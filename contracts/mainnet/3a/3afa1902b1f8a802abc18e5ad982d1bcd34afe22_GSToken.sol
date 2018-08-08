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
    uint256 c = a / b;
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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
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

contract GSToken is PausableToken {

    string  public name = "GrEARN&#39;s Token";
    string  public symbol = "GST";
    uint    public decimals = 18;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public frozenAccountTokens;
    
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed burner, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    constructor() public
    {
        totalSupply_ = 60 * 10 ** (uint256(decimals) + 8);
        balances[msg.sender] = totalSupply_;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(_value > 0);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);   
        totalSupply_ = SafeMath.sub(totalSupply_,_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[_from]);
        require(SafeMath.add(frozenAccountTokens[_from], _value) <= balances[_from]);

        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(SafeMath.add(frozenAccountTokens[msg.sender], _value) <= balances[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferAndFreezeTokens(address _to, uint256 _value) public onlyOwner returns (bool) {
        transfer(_to, _value);
        freezeAccountWithToken(_to, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function freezeAccountWithToken(address wallet, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[wallet] >= _value);
        require(_value > 0); 
        frozenAccountTokens[wallet] = SafeMath.add(frozenAccountTokens[wallet], _value);
        emit Freeze(wallet, _value);
        return true;
    }
    
    function unfreezeAccountWithToken(address wallet, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[wallet] >= _value);
        require(_value > 0); 
        frozenAccountTokens[wallet] = SafeMath.sub(frozenAccountTokens[wallet], _value);         
        emit Unfreeze(wallet, _value);
        return true;
    }

    function multisend(address[] dests, uint256[] values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            transferAndFreezeTokens(dests[i], values[i] * 10 ** 18);
            i += 1;
        }
        return(i);
    }
}