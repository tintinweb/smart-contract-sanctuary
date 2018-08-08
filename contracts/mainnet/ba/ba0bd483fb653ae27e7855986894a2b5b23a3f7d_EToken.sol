pragma solidity ^0.4.18;



/**
 * @title ERC20
 * 
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);  
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256); 
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title Ownable && Mintable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * @dev Added mintOwner address how controls the minting
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public mintOwner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event MintOwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    mintOwner = msg.sender;
  }

  

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyMintOwner() {
    require(msg.sender == mintOwner);
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
   * @dev Allows the current owner to transfer mint control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferMintOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit MintOwnershipTransferred(mintOwner, newOwner);
    mintOwner = newOwner;
  }

}




/**
 *
 * @title Edge token
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *  
 *
 */
contract EdgeToken is ERC20, Ownable {
  using SafeMath for uint256;

  //Balances
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) internal allowed;

  //Minting
  event Mint(address indexed to, uint256 amount);
  event MintFinished(); 

  //If token is mintable
  bool public mintingFinished = false;

  //Total supply of tokens 
  uint256 totalSupply_ = 0;

  //Hardcap is 1,000,000,000 - One billion tokens
  uint256 hardCap_ = 1000000000000000000000000000;

  //Constructor
  constructor() public {
    
  }


  //Fix for the ERC20 short address attack.
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
   } 

 

  /**
   * @dev total number of tokens in existence
   */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
   * @dev allowed total number of tokens
   */
  function hardCap() public view returns (uint256) {
    return hardCap_;
  }
 
  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    return _transfer(msg.sender, _to, _value); 
  }


  /**
   * @dev Internal transfer, only can be called by this contract  
   * @param _from is msg.sender The address to transfer from.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function _transfer(address _from, address _to, uint _value) internal returns (bool){
      require(_to != address(0)); // Prevent transfer to 0x0 address.
      require(_value <= balances[msg.sender]);  // Check if the sender has enough      

      // SafeMath.sub will throw if there is not enough balance.
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {

    require(_to != address(0));                     // Prevent transfer to 0x0 address. Use burn() instead
    require(_value <= balances[_from]);             // Check if the sender has enough
    require(_value <= allowed[_from][msg.sender]);  // Check if the sender is allowed to send


    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }



  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spend.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

 

  /**
   *  MintableToken functionality
   */
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyMintOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= hardCap_);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount); 
    emit Transfer(address(0), _to, _amount);
    return true;
  }



  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }


  /**
   * @dev Owner can transfer other tokens that are sent here by mistake
   * 
   */
  function refundOtherTokens(address _recipient, ERC20 _token) public onlyOwner {
    require(_token != this);
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }

 
}

 
/**
 * @title EDGE token EDGE
 * 
 */
contract EToken is EdgeToken {
  string public constant name = "We Got Edge Token";  
  string public constant symbol = "EDGE";   
  uint8 public constant decimals = 18;  

}