pragma solidity 0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    /// Total amount of tokens
  uint256 public totalSupply;
  
  function balanceOf(address _owner) public view returns (uint256 balance);
  
  function transfer(address _to, uint256 _amount) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  
  function approve(address _spender, uint256 _amount) public returns (bool success);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  //balance in each address account
  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _amount The amount to be transferred.
  */
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
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
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {
  
  
  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to]);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _amount The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken, Ownable {

    //this will contain a list of addresses allowed to burn their tokens
    mapping(address=>bool)allowedBurners;
    
    event Burn(address indexed burner, uint256 value);
    
    event BurnerAdded(address indexed burner);
    
    event BurnerRemoved(address indexed burner);
    
    //check whether the burner is eligible burner
    modifier isBurner(address _burner){
        require(allowedBurners[_burner]);
        _;
    }
    
    /**
    *@dev Method to add eligible addresses in the list of burners. Since we need to burn all tokens left with the sales contract after the sale has ended. The sales contract should
    * be an eligible burner. The owner has to add the sales address in the eligible burner list.
    * @param _burner Address of the eligible burner
    */
    function addEligibleBurner(address _burner)public onlyOwner {
        
        require(_burner != address(0));
        allowedBurners[_burner] = true;
        emit BurnerAdded(_burner);
    }
    
     /**
    *@dev Method to remove addresses from the list of burners
    * @param _burner Address of the eligible burner to be removed
    */
    function removeEligibleBurner(address _burner)public onlyOwner isBurner(_burner) {
        
        allowedBurners[_burner] = false;
        emit BurnerRemoved(_burner);
    }
    
    /**
     * @dev Burns all tokens of the eligible burner
     */
    function burnAllTokens() public isBurner(msg.sender) {
        
        require(balances[msg.sender]>0);
        
        uint256 value = balances[msg.sender];
        
        totalSupply = totalSupply.sub(value);

        balances[msg.sender] = 0;
        
        emit Burn(msg.sender, value);
    }
}
/**
 * @title DRONE Token
 * @dev Token representing DRONE.
 */
 contract DroneToken is BurnableToken {
     string public name ;
     string public symbol ;
     uint8 public decimals = 0 ;
     
     /**
     *@dev users sending ether to this contract will be reverted. Any ether sent to the contract will be sent back to the caller
     */
     function ()public payable {
         revert();
     }
     
     /**
     * @dev Constructor function to initialize the initial supply of token to the creator of the contract
     * @param initialSupply The initial supply of tokens which will be fixed through out
     * @param tokenName The name of the token
     * @param tokenSymbol The symboll of the token
     */
     function DroneToken(
            uint256 initialSupply,
            string tokenName,
            string tokenSymbol
         ) public {
         totalSupply = initialSupply.mul( 10 ** uint256(decimals)); //Update total supply with the decimal amount
         name = tokenName;
         symbol = tokenSymbol;
         balances[msg.sender] = totalSupply;
         
         //Emitting transfer event since assigning all tokens to the creator also corresponds to the transfer of tokens to the creator
         emit Transfer(address(0), msg.sender, totalSupply);
     }
     
     /**
     *@dev helper method to get token details, name, symbol and totalSupply in one go
     */
    function getTokenDetail() public view returns (string, string, uint256) {
	    return (name, symbol, totalSupply);
    }
 }