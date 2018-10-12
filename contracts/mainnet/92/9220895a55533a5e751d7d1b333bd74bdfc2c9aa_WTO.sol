pragma solidity ^0.4.23;

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}

contract WTO is Pausable {
  using SafeMath for uint256;

  mapping (address => uint) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) public frozenAccount;

  event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
  event FrozenFunds(address target, bool frozen);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _supply)
  {
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply = _supply;
      balances[msg.sender] = totalSupply;
  }


  // Function to access name of token .
  function name() constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

  function freezeAccount(address target, bool freeze) onlyOwner public {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback)
  whenNotPaused
  returns (bool success)
  {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(!frozenAccount[msg.sender]);
    if(isContract(_to)) {
      require(balanceOf(msg.sender) >= _value);
        balances[_to] = balanceOf(_to).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}


  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data)
  whenNotPaused
  returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(!frozenAccount[msg.sender]);
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value)
  whenNotPaused
  returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(!frozenAccount[msg.sender]);
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(balanceOf(msg.sender) >= _value);
    require(!frozenAccount[msg.sender]);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(balanceOf(msg.sender) >= _value);
    require(!frozenAccount[msg.sender]);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
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
  function approve(address _spender, uint256 _value)
    public
    whenNotPaused
    returns (bool) {
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
    whenNotPaused
    returns (bool)
  {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
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
    whenNotPaused
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
  
    function distributeAirdrop(address[] addresses, uint256 amount) onlyOwner public returns (bool seccess) {
    require(amount > 0);
    require(addresses.length > 0);
    require(!frozenAccount[msg.sender]);

    uint256 totalAmount = amount.mul(addresses.length);
    require(balances[msg.sender] >= totalAmount);
    bytes memory empty;

    for (uint i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0));
      require(!frozenAccount[addresses[i]]);
      balances[addresses[i]] = balances[addresses[i]].add(amount);
      emit Transfer(msg.sender, addresses[i], amount, empty);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    
    return true;
  }

  function distributeAirdrop(address[] addresses, uint256[] amounts) public returns (bool) {
    require(addresses.length > 0);
    require(addresses.length == amounts.length);
    require(!frozenAccount[msg.sender]);

    uint256 totalAmount = 0;

    for(uint i = 0; i < addresses.length; i++){
      require(amounts[i] > 0);
      require(addresses[i] != address(0));
      require(!frozenAccount[addresses[i]]);

      totalAmount = totalAmount.add(amounts[i]);
    }
    require(balances[msg.sender] >= totalAmount);

    bytes memory empty;
    for (i = 0; i < addresses.length; i++) {
      balances[addresses[i]] = balances[addresses[i]].add(amounts[i]);
      emit Transfer(msg.sender, addresses[i], amounts[i], empty);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }
  
  /**
     * @dev Function to collect tokens from the list of addresses
     */
    function collectTokens(address[] addresses, uint256[] amounts) onlyOwner public returns (bool) {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);

        uint256 totalAmount = 0;
        bytes memory empty;
        
        for (uint j = 0; j < addresses.length; j++) {
            require(amounts[j] > 0);
            require(addresses[j] != address(0));
            require(!frozenAccount[addresses[j]]);
                    
            require(balances[addresses[j]] >= amounts[j]);
            balances[addresses[j]] = balances[addresses[j]].sub(amounts[j]);
            totalAmount = totalAmount.add(amounts[j]);
            emit Transfer(addresses[j], msg.sender, amounts[j], empty);
        }
        balances[msg.sender] = balances[msg.sender].add(totalAmount);
        return true;
    }
}