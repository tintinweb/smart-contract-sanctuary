/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity ^0.4.23;


/**
 * @title Standard ERC20 token
  */
  // safemath librarry is used to perform math operations with getting errors
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


  
// ERC20 that is a token standard
contract ERC20Basic {
    // check total supply
  function totalSupply() public view returns (uint256);
  // check balance of a address
  function balanceOf(address who) public view returns (uint256);
  // this function is used to trasfer tokens
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    // 18 decimals
    // 100 tokens = 1000000000000000000000
  uint256 public decimals;
  // When you want to transfer token from someone else's account then we use transferfrom function
function transferFrom(address from, address to, uint256 value)
    public returns (bool);
    
    // used for the permission
  function allowance(address owner, address spender)
    public view returns (uint256);


//check status
  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  

  
  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
      // checking to to address is not zero
    require(_to != address(0));
    // the sender have enough balance to transfer or not
    require(_value <= balances[msg.sender]);

    //deducting the balance
    balances[msg.sender] = balances[msg.sender].sub(_value);
    
    //sending the balance
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
contract StandardToken is ERC20, BasicToken {

// Add allowance will be recorded over here, so who can tranfer toekn on behalf of someone
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
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
  
  // increase the value of how much someone can tranfer on his behalf
  
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
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

}

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

contract Token is StandardToken, Ownable {

//used for time lock


  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 _totalSupply;
  address public owner;
    
    
  function pow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(base);
            return z;
        }
    }

    //transfrom needs permission
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0), "Address cant be zero");
    require(_value <= balances[_from], "Not Enough Balance");
    require(_value <= allowed[_from][msg.sender] , "Not Allowed");
    
    //getting 1% of transaction
    uint deduction_amount = _value.div(100);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value.sub(deduction_amount));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value.sub(deduction_amount));
    
     //transfering 1% to owner
    balances[owner] += deduction_amount;
    
    emit Transfer(_from, owner, deduction_amount);
    emit Transfer(_from, _to, _value);
    return true;
  }

  constructor( )
  public
  {
    owner = msg.sender;
    name = "FDN Token";
    symbol = "FDNT";
    decimals = 18;
    totalSupply_ = uint(60000000).mul(pow(10, decimals));
   
    balances[msg.sender] = totalSupply_;

  }

    //transfer doesnot need permission
  function transfer(
    address _to,
    uint256 _value
  )
  public
  returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    //getting 1% of transaction
    uint deduction_amount = _value.div(100);
    
    balances[owner] += deduction_amount;
    
    //subtract from senders balance
    balances[msg.sender] = balances[msg.sender].sub(_value);
    //add to the recivers balance
    balances[_to] = balances[_to].add(_value.sub(deduction_amount));
    
    //transfering 1% to owner
    balances[owner] += deduction_amount;
    
    
    //emit transfer event
    
    emit Transfer(msg.sender, owner, deduction_amount);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


}