pragma solidity 0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
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
  * @title ForeignToken
  * @dev Enables smart contract to hold and send other ERC20 tokens.
  */
contract ForeignToken {
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
}

  contract Eurno is ERC20Basic, Ownable, ForeignToken {
    using SafeMath for uint256;

    string public constant name = "Eurno";
    string public constant symbol = "ENO";
    uint public constant decimals = 8;
    uint256 public totalSupply = 28e14;
    uint256 internal functAttempts;

    event Transfer(address indexed _from, address indexed _to, uint256 _value); // Define the transfer event
    event Burn(address indexed burner, uint256 value);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;
   
    /**
     * @dev modifier to limit the number of times a function can be called to once. 
     */
    modifier onlyOnce(){
        require(functAttempts <= 0);
        _;
    }

  /**
  * @dev Constructor function to start the Eurno token chain.
  * Transfer&#39;s the owner&#39;s wallet with the development fund of 5 million tokens.
  */
  constructor() public {
    balances[msg.sender] = balances[msg.sender].add(totalSupply); // Update balances on the Ledger.
    emit Transfer(this, owner, totalSupply); // Transfer owner 5 mil dev fund.
  }
  
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }

  /**
  * @dev transfer token for a specified address.
  * 
  * Using onlyPayloadSize to prevent short address attack
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  /**
   * @dev Allows the owner of the contract to distribute to other contracts. 
   * Used, for example, to distribute the airdrop balance to the airdrop contract.
   * 
   * @param _to is the address of the contract.
   * @param _value is the amount of ENO to send to it.
   */
  function distAirdrop(address _to, uint256 _value) onlyOwner onlyOnce public returns (bool) {
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    functAttempts = 1;
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
  
  /**
   * @dev Function to withdraw foreign tokens stored in this contract.
   * 
   * @param _tokenContract is the smart contract address of the token to be withdrawn.
   */ 
  function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
    ForeignToken token = ForeignToken(_tokenContract);
    uint256 amount = token.balanceOf(address(this));
    return token.transfer(owner, amount);
    }

  /**
   * @dev Fallback function to allow the contract to accept Eth donations.
   */
  function() public payable {
  }
  
  /**
   * @dev Function to allow contract owner to withdraw Ethereum deposited to the Eurno contract.
   */
  function withdraw() onlyOwner public {
    uint256 etherBalance = address(this).balance;
    owner.transfer(etherBalance);
    }
    
  /**
   * @dev Burns a specific amount of tokens. Can only be called by contract owner.
   * 
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) onlyOwner public {
    _burn(msg.sender, _value);
  }
  
  /**
   * @dev actual function to burn tokens.
   * 
   * @param _who is the address of the person burning tokens.
   * @param _value is the number of tokens burned.
   */
  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

}