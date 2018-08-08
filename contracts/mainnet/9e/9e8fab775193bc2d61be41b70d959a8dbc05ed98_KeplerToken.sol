pragma solidity ^0.4.21;

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
    return a / b;
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

  function Ownable() public {
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

contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

}

contract Freezeable is Whitelist {
  mapping (address => bool) public frozenAccount;
  event FrozenFunds(address target, bool frozen);

  function freezeAccount(address target, bool freeze) onlyOwner public {
      frozenAccount[target] = freeze;
      emit FrozenFunds(target, freeze);
  }
}

contract Pausable is Freezeable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused || whitelist[msg.sender]);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {
  using SafeMath for uint256;

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

  contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
      require(!frozenAccount[msg.sender]);
      require(!frozenAccount[_to]);
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
      require(!frozenAccount[_from]);
      require(!frozenAccount[_to]);
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

  contract BurnableToken is PausableToken {

    event Burn(address indexed burner, uint256 value);

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
      _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
      require(_value <= balances[_who]);
      // no need to require value <= totalSupply, since that would imply the
      // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

      balances[_who] = balances[_who].sub(_value);
      totalSupply_ = totalSupply_.sub(_value);
      emit Burn(_who, _value);
      emit Transfer(_who, address(0), _value);
    }
  }



  contract KeplerToken is BurnableToken {

    string public constant name = "Kepler Token";
    string public constant symbol = "KEP";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

    function KeplerToken() public {
      totalSupply_ = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
      emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

  }