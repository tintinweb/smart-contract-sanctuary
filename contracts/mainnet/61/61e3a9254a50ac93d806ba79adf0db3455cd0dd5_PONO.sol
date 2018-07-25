pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev Based on: OpenZeppelin
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Ownable
 * @dev Contract provides ownership control
 * @dev Based on: OpenZeppelin
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




/**
 * @title ERC20Basic
 * @dev Basic ERC20 interface
 * @dev Based on: OpenZeppelin
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Full ERC20 interface
 * @dev Based on: OpenZeppelin
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * @dev Based on: OpenZeppelin
 */
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
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}



/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * @dev Based on: OpenZeppelin
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



/**
 * @title PONO
 * @dev Implementation of the PONO token.
 */
contract PONO is StandardToken, Ownable {
  string public name = &#39;PONO 21&#39;;
  string public symbol = &#39;PONO&#39;;
  uint public decimals = 18;
  uint public INITIAL_SUPPLY = 0;  // we&#39;re starting off with zero initial supply and will &#39;mint&#39; as needed

  // The following were created as arrays instead of mappings since the dapp requires access to all elements (a mapping doesn&#39;t allow access to its keys). Extra iteration gas costs are negligible due to the fact that delegates are usually very limited in number.
  address[] mintDelegates;   // accounts allowed to mint tokens
  address[] burnDelegates;   // accounts allowed to burn tokens

  // Events
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 value);
  event ApproveMintDelegate(address indexed mintDelegate);
  event RevokeMintDelegate(address indexed mintDelegate);
  event ApproveBurnDelegate(address indexed burnDelegate);
  event RevokeBurnDelegate(address indexed burnDelegate);


  // Constructor
  function PONO () public {
    totalSupply_ = INITIAL_SUPPLY;
  }


  /**
   * @dev Throws if called by any account other than an owner or a mint delegate.
   */
  modifier onlyOwnerOrMintDelegate() {
    bool allowedToMint = false;

    if(msg.sender==owner) {
      allowedToMint = true;
    }
    else {
      for(uint i=0; i<mintDelegates.length; i++) {
        if(mintDelegates[i]==msg.sender) {
          allowedToMint = true;
          break;
        }
      }
    }

    require(allowedToMint==true);
    _;
  }

  /**
   * @dev Throws if called by any account other than an owner or a burn delegate.
   */
  modifier onlyOwnerOrBurnDelegate() {
    bool allowedToBurn = false;

    if(msg.sender==owner) {
      allowedToBurn = true;
    }
    else {
      for(uint i=0; i<burnDelegates.length; i++) {
        if(burnDelegates[i]==msg.sender) {
          allowedToBurn = true;
          break;
        }
      }
    }

    require(allowedToBurn==true);
    _;
  }

  /**
   * @dev Return the array of mint delegates.
   */
  function getMintDelegates() public view returns (address[]) {
    return mintDelegates;
  }

  /**
   * @dev Return the array of burn delegates.
   */
  function getBurnDelegates() public view returns (address[]) {
    return burnDelegates;
  }

  /**
   * @dev Give a mint delegate permission to mint tokens.
   * @param _mintDelegate The account to be approved.
   */
  function approveMintDelegate(address _mintDelegate) onlyOwner public returns (bool) {
    bool delegateFound = false;
    for(uint i=0; i<mintDelegates.length; i++) {
      if(mintDelegates[i]==_mintDelegate) {
        delegateFound = true;
        break;
      }
    }

    if(!delegateFound) {
      mintDelegates.push(_mintDelegate);
    }

    ApproveMintDelegate(_mintDelegate);
    return true;
  }

  /**
   * @dev Revoke permission to mint tokens from a mint delegate.
   * @param _mintDelegate The account to be revoked.
   */
  function revokeMintDelegate(address _mintDelegate) onlyOwner public returns (bool) {
    uint length = mintDelegates.length;
    require(length > 0);

    address lastDelegate = mintDelegates[length-1];
    if(_mintDelegate == lastDelegate) {
      delete mintDelegates[length-1];
      mintDelegates.length--;
    }
    else {
      // Game plan: find the delegate, replace it with the very last item in the array, then delete the last item
      for(uint i=0; i<length; i++) {
        if(mintDelegates[i]==_mintDelegate) {
          mintDelegates[i] = lastDelegate;
          delete mintDelegates[length-1];
          mintDelegates.length--;
          break;
        }
      }
    }

    RevokeMintDelegate(_mintDelegate);
    return true;
  }

  /**
   * @dev Give a burn delegate permission to burn tokens.
   * @param _burnDelegate The account to be approved.
   */
  function approveBurnDelegate(address _burnDelegate) onlyOwner public returns (bool) {
    bool delegateFound = false;
    for(uint i=0; i<burnDelegates.length; i++) {
      if(burnDelegates[i]==_burnDelegate) {
        delegateFound = true;
        break;
      }
    }

    if(!delegateFound) {
      burnDelegates.push(_burnDelegate);
    }

    ApproveBurnDelegate(_burnDelegate);
    return true;
  }

  /**
   * @dev Revoke permission to burn tokens from a burn delegate.
   * @param _burnDelegate The account to be revoked.
   */
  function revokeBurnDelegate(address _burnDelegate) onlyOwner public returns (bool) {
    uint length = burnDelegates.length;
    require(length > 0);

    address lastDelegate = burnDelegates[length-1];
    if(_burnDelegate == lastDelegate) {
      delete burnDelegates[length-1];
      burnDelegates.length--;
    }
    else {
      // Game plan: find the delegate, replace it with the very last item in the array, then delete the last item
      for(uint i=0; i<length; i++) {
        if(burnDelegates[i]==_burnDelegate) {
          burnDelegates[i] = lastDelegate;
          delete burnDelegates[length-1];
          burnDelegates.length--;
          break;
        }
      }
    }

    RevokeBurnDelegate(_burnDelegate);
    return true;
  }


  /**
   * @dev Function to mint tokens and transfer them to contract owner&#39;s address
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 _amount) onlyOwnerOrMintDelegate public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[msg.sender] = balances[msg.sender].add(_amount);

    // Call events
    Mint(msg.sender, _amount);
    Transfer(address(0), msg.sender, _amount);

    return true;
  }

  /**
   * @dev Function to burn tokens
   * @param _value The amount of tokens to be burned.
   * @return A boolean that indicates if the operation was successful.
   */
  function burn(uint256 _value) onlyOwnerOrBurnDelegate public returns (bool) {
    require(_value <= balances[msg.sender]);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);

    // Call events
    Burn(burner, _value);
    Transfer(burner, address(0), _value);

    return true;
  }
}