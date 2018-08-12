pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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

contract INAToken is StandardToken, Ownable {
  string constant public name = "INA Coin";
  string constant public symbol = "INA";
  uint8 constant public decimals = 18;
  bool public isLocked = true;

  uint256 public constant initialToken = 2 * (10 ** uint256(8 + decimals));
  uint256 public constant SaleToken    = initialToken * 85 / 100; // 85%
  uint256 public constant team1Token   = initialToken * 375 / 10000; // 3.75%
  uint256 public constant team2Token   = initialToken * 375 / 10000; // 3.75%
  uint256 public constant team3Token   = initialToken * 375 / 10000; // 3.75%
  uint256 public constant team4Token   = initialToken * 375 / 10000; // 3.75%
  
  address public INAWallet;
  address public privateSale1Address;
  address public privateSale2Address;
  address public team1Address;       
  address public team2Address;       
  address public team3Address;       
  address public team4Address;      

    uint256 public constant privateSale1LockEndTime = 1533363000;
    uint256 public constant privateSale2LockEndTime = 1533363300;
    uint256 public constant team1LockEndTime = 1533362400;
    uint256 public constant team2LockEndTime = 1533363600;
    uint256 public constant team3LockEndTime = 1533366000;
    uint256 public constant team4LockEndTime = 1533369600;

  mapping(address => bool) lockAddresses;

  constructor(address _INAWallet, address _privateSale1Address, address _privateSale2Address, address _team1Address, address _team2Address, address _team3Address, address _team4Address) public {
    INAWallet           = _INAWallet;
    privateSale1Address = _privateSale1Address;
    privateSale2Address = _privateSale2Address;
    team1Address        = _team1Address;       
    team2Address        = _team2Address;       
    team3Address        = _team3Address;        
    team4Address        = _team4Address;       

    totalSupply_ = initialToken;

    // The public sale token will be manually transferred to crowdsale contract from INAWallet 
    // The private sale token will be manually transferred to privateSale1Address & privateSale2Address from INAWallet
    balances[INAWallet]           = SaleToken;
    balances[team1Address]        = team1Token;
    balances[team2Address]        = team2Token;
    balances[team3Address]        = team3Token;
    balances[team4Address]        = team4Token;

    emit Transfer(address(0), INAWallet, SaleToken);
    emit Transfer(address(0), team1Address, team1Token);
    emit Transfer(address(0), team2Address, team2Token);
    emit Transfer(address(0), team3Address, team3Token);
    emit Transfer(address(0), team4Address, team4Token);

    lockAddresses[privateSale1Address] = true;
    lockAddresses[privateSale2Address] = true;
    lockAddresses[team1Address]        = true;
    lockAddresses[team2Address]        = true;
    lockAddresses[team3Address]        = true;
    lockAddresses[team4Address]        = true;
  }

  // should be called by INACrowdsale when crowdSale is finished
  function unlockPublic() public onlyOwner {
      isLocked = false;
  }

  function unlockPrivate() public onlyOwner {
    if (lockAddresses[privateSale1Address] && now >= privateSale1LockEndTime)
      lockAddresses[privateSale1Address] = false;
    if (lockAddresses[privateSale2Address] && now >= privateSale2LockEndTime)
      lockAddresses[privateSale2Address] = false;
    if (lockAddresses[team1Address] && now >= team1LockEndTime)
      lockAddresses[team1Address] = false;
    if (lockAddresses[team2Address] && now >= team2LockEndTime)
      lockAddresses[team2Address] = false;
    if (lockAddresses[team3Address] && now >= team3LockEndTime)
      lockAddresses[team3Address] = false;
    if (lockAddresses[team4Address] && now >= team4LockEndTime)
      lockAddresses[team4Address] = false;
  }

  modifier transferable(address _addr) {
    require(!isLocked || msg.sender == owner);
    require(!lockAddresses[_addr]);
    _;
  }

  function transfer(address _to, uint256 _value) transferable(msg.sender) public returns (bool) {
      return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) transferable(msg.sender) public returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }
}