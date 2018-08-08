pragma solidity ^0.4.15;

contract AccessControlled {
  address public owner = msg.sender;
  
  /**
   * @dev Throws if called by any account other than the argument. 
   */
  modifier onlyBy(address _account)
  {
    require(msg.sender == _account);
    _;
  }
  
  /**
   * @dev Throws if called by any account other than either of the two arguments. 
   */
  modifier onlyByOr(address _account1, address _account2)
  {
    require(msg.sender == _account1 || msg.sender == _account2);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract TarynToken is AccessControlled {
  using SafeMath for uint256;

  string public constant name     = "TarynToken";
  string public constant symbol   = "TA";
  uint8  public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 0;
  uint256 public totalSupply;

  mapping(address => uint256) balances;
  mapping(uint256 => address) public addresses;
  mapping(address => uint256) public indexes;
  //index starts at 1 so that first item has index of 1, which differentiates
  //it from non-existing items with values of 0. 
  uint public index = 1;
  
  /**
   * @dev Contructor that gives msg.sender all of existing tokens. FIXME: this is simply for initial testing.
   */
  function TarynToken() public {
    totalSupply = INITIAL_SUPPLY;
  }
  
  event Mint(address indexed to, uint256 amount);

  function mint(address _to, uint256 _amount) onlyOwner public returns (bool){
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    addToAddresses(_to);
    Mint(_to, _amount);
    return true;
  }
  
  function addToAddresses(address _address) private {
      if (indexes[_address] == 0) {
        addresses[index] = _address;
        indexes[_address] = index;
        index++;
     }
  }
  
  event Distribute(address owner, uint256 balance, uint256 value, uint ind);

  function distribute() payable public returns(bool){
   for (uint i = 1; i < index; i++) {
     uint256 balance = balances[addresses[i]];
     uint256 giveAmount = balance.mul(msg.value).div(totalSupply);
     Distribute(addresses[i], balance, giveAmount, i);
     addresses[i].transfer(giveAmount);
   }
   return true;
  }
  
  function isRegistered(address _address) private constant returns (bool) {
      return (indexes[_address] != 0);
  }
  // Basics

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    addToAddresses(_to);
    return true;
  }
  

  event Transfer(address indexed from, address indexed to, uint256 value);
  
  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of. 
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  
  // Allowances

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
  
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
  
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
  
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
  
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
    /*
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until 
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
  function increaseApproval (address _spender, uint _addedValue) 
    public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
  function decreaseApproval (address _spender, uint _subtractedValue) 
    public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}