pragma solidity ^0.4.24;

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

contract Ownable {
  address public owner;

  event OwnershipTransferred( address indexed previousOwner,address indexed newOwner );

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

contract BC {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;
    uint256 public releaseTime;
    using SafeMath for uint256;

    constructor(string _name, string _symbol, uint8 _decimals,uint256 _initialSupply, uint256 _releaseTime) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    releaseTime = _releaseTime;
    initialSupply = _initialSupply;
    totalSupply = _initialSupply;  // Update total supply with the decimal amount
    balances[msg.sender] = initialSupply;
    }  
    mapping(address => uint256) internal balances;
}

contract ABC is BC, Ownable {
  using SafeMath for uint256;
  uint256 internal totalSupply_;
  mapping(address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) public frozenAccount;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed burner, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event FrozenFunds(address target, bool frozen);
    
    constructor (
        uint256 initialSupply,
        string name,
        string symbol,
        uint8 decimals,
        uint256 releaseTime
    ) BC(name, symbol, decimals, initialSupply, releaseTime ) public {balances[msg.sender] = initialSupply;}
    
    function approve(address _spender, uint256 _value) public onlyOwner returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function allowance( address _owner, address _spender ) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval( address _spender, uint256 _addedValue) public onlyOwner returns (bool)  {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
  
    function decreaseApproval( address _spender, uint256 _subtractedValue ) public onlyOwner returns (bool)  {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
  
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);               // Check if the sender has enough
        require (balances[_to].add(_value) >= balances[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balances[_from] = balances[_from].sub(_value);                         // Subtract from the sender
        balances[_to] = balances[_to].add(_value);                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(block.timestamp >= releaseTime);
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        require(!frozenAccount[msg.sender]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom( address _from, address _to, uint256 _value ) public  returns (bool)  {
        require(block.timestamp >= releaseTime);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

  
      /**
       * @dev Burns a specific amount of tokens.
       * @param _value The amount of token to be burned.
       */
      function burn(uint256 _value) public onlyOwner {
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
  
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] = balances[_from].sub(_value);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
    
    function distributeToken(address[] addresses, uint256[] _value) onlyOwner public {
        require (addresses.length == _value.length);
        for (uint i = 0; i < addresses.length; i++) {
        _transfer(msg.sender, addresses[i], _value[i]);
            //balances[owner] -= _value;
            //balances[addresses[i]] += _value;
            //Transfer(owner, addresses[i], _value);
        }
    }
    
}