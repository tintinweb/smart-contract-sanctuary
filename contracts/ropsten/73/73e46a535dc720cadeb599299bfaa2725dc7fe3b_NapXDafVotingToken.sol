pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract NapXDafVotingToken is StandardToken {
  string public name = &#39;NapXDafToken&#39;;
  string public token = &#39;DAF&#39;;
  uint8 public decimals = 0;
  uint public INITIAL_SUPPLY = 1000000;

  mapping(address=>bool) public delegatinglist;

  address napXAdministrator;
  //EVENTS
  event tokenOverriden(address investor, uint decimalTokenAmount);
  event receivedEther(address sender, uint amount);
  event Authorized(address candidate, uint timestamp);
  event Revoked(address candidate, uint timestamp);

  function isEqualLength(address[] x, uint[] y) pure internal returns (bool) { return x.length == y.length; }

  modifier onlySameLengthArray(address[] x, uint[] y) {
      require(isEqualLength(x,y));
      _;
  }

  modifier onlyAdministrator(){
      require(msg.sender == napXAdministrator);
      _;
  }

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    napXAdministrator = msg.sender;
    balances[napXAdministrator] = INITIAL_SUPPLY;
    delegatinglist[msg.sender] = true;
  }

  function transferAdministratorship(address newAdministrator)
  onlyAdministrator
  public
  {
    napXAdministrator = newAdministrator;
  }

  function authorize(address candidate) public onlyAdministrator {
      delegatinglist[candidate] = true;
      emit Authorized(candidate, now);
  }

  // also if not in the list..
  function revoke(address candidate) public onlyAdministrator {
      delegatinglist[candidate] = false;
      emit Revoked(candidate, now);
  }

  function authorizeMany(address[50] candidates) public onlyAdministrator {
      for(uint i = 0; i < candidates.length; i++) {
          authorize(candidates[i]);
      }
  }

  function isdelegatinglisted(address candidate) public view returns(bool) {
    return delegatinglist[candidate];
  }


  /**
   * ERC 20 Standard Token interface transfer function
   *
   * Prevent transfers until freeze period is over.
   *
   * Applicable tests:
   *
   * - Test restricted early transfer
   * - Test transfer after restricted period
   */
  function transfer(address _to, uint256 _value) public returns (bool success)  {
      require(isdelegatinglisted(msg.sender));
      return super.transfer(_to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool){
     require(isdelegatinglisted(msg.sender));
     return super.approve(_spender, _value);
  }

  // we here repopulate the greenlist using the historic commitments from www.napoleonx.ai website
  function overrideTokenHolders(address[] toOverride, uint[] decimalTokenAmount)
  public
  onlyAdministrator
  onlySameLengthArray(toOverride, decimalTokenAmount)
  {
      for (uint i = 0; i < toOverride.length; i++) {
      		uint previousAmount = balances[toOverride[i]];
      		balances[toOverride[i]] = decimalTokenAmount[i];
      		totalSupply_ = totalSupply_-previousAmount+decimalTokenAmount[i];
          emit tokenOverriden(toOverride[i], decimalTokenAmount[i]);
      }
  }

  // we here repopulate the greenlist using the historic commitments from www.napoleonx.ai website
  function overrideTokenHolder(address toOverride, uint decimalTokenAmount)
  public
  onlyAdministrator
  {
  		uint previousAmount = balances[toOverride];
  		balances[toOverride] = decimalTokenAmount;
  		totalSupply_ = totalSupply_-previousAmount+decimalTokenAmount;
      emit tokenOverriden(toOverride, decimalTokenAmount);
  }

  function resetContract()
  public
  onlyAdministrator
  {
    selfdestruct(napXAdministrator);
  }

}