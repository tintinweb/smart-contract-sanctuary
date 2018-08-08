pragma solidity 0.4.24;


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
  constructor () public {
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

    event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */

  function burn(uint256 _value) public {

    _burn(msg.sender, _value);

  }

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

/**
 * @title Mintable token
 * @dev ERC20 token, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    using SafeMath for uint256;

  mapping(address => uint256)public shares;
  
  address[] public beneficiaries;
 
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event BeneficiariesAdded();
  
  uint256 public lastMintingTime;
  uint256 public mintingStartTime = 1543622400;
  uint256 public mintingThreshold = 31536000;
  uint256 public lastMintedTokens = 91000000000000000;

  bool public mintingFinished = false;
  
  

  modifier canMint() {
    require(!mintingFinished);
    require(totalSupply < 910000000000000000);// Total minting has not yet been finished
    require(beneficiaries.length == 7);//Check beneficiaries has been added
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @return A boolean that indicates if the operation was successful.
   */

  function mint() hasMintPermission  canMint public  returns (bool){
    
    uint256 _amount = tokensToMint();
    
    totalSupply = totalSupply.add(_amount);
    
    
    for(uint8 i = 0; i<beneficiaries.length; i++){
        
        balances[beneficiaries[i]] = balances[beneficiaries[i]].add(_amount.mul(shares[beneficiaries[i]]).div(100));
        emit Mint(beneficiaries[i], _amount.mul(shares[beneficiaries[i]]).div(100));
        emit Transfer(address(0), beneficiaries[i], _amount.mul(shares[beneficiaries[i]]).div(100));
    }
    
    lastMintingTime = now;
    
   
     return true;
  }
  
  //Return how much tokens will be minted as per algorithm. Each year 10% tokens will be reduced
  function tokensToMint()private returns(uint256 _tokensToMint){
      
      uint8 tiersToBeMinted = currentTier() - getTierForLastMiniting();
      
      require(tiersToBeMinted>0);
      
      for(uint8 i = 0;i<tiersToBeMinted;i++){
          _tokensToMint = _tokensToMint.add(lastMintedTokens.sub(lastMintedTokens.mul(10).div(100)));
          lastMintedTokens = lastMintedTokens.sub(lastMintedTokens.mul(10).div(100));
      }
      
      return _tokensToMint;
      
  }
 
  function currentTier()private view returns(uint8 _tier) {
      
      uint256 currentTime = now;
      
      uint256 nextTierStartTime = mintingStartTime;
      
      while(nextTierStartTime < currentTime) {
          nextTierStartTime = nextTierStartTime.add(mintingThreshold);
          _tier++;
      }
      
      return _tier;
      
  }
  
  function getTierForLastMiniting()private view returns(uint8 _tier) {
      
       uint256 nextTierStartTime = mintingStartTime;
      
      while(nextTierStartTime < lastMintingTime) {
          nextTierStartTime = nextTierStartTime.add(mintingThreshold);
          _tier++;
      }
      
      return _tier;
      
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


function beneficiariesPercentage(address[] _beneficiaries, uint256[] percentages) onlyOwner external returns(bool){
   
    require(_beneficiaries.length == 7);
    require(percentages.length == 7);
    
    uint256 sumOfPercentages;
    
    if(beneficiaries.length>0) {
        
        for(uint8 j = 0;j<beneficiaries.length;j++) {
            
            shares[beneficiaries[j]] = 0;
            delete beneficiaries[j];
            
            
        }
        beneficiaries.length = 0;
        
    }

    for(uint8 i = 0; i < _beneficiaries.length; i++){

      require(_beneficiaries[i] != 0x0);
      require(percentages[i] > 0);
      beneficiaries.push(_beneficiaries[i]);
      
      shares[_beneficiaries[i]] = percentages[i];
      sumOfPercentages = sumOfPercentages.add(percentages[i]); 
     
    }

    require(sumOfPercentages == 100);
    emit BeneficiariesAdded();
    return true;
  } 
}

/**
 * @title ERA Swap Token 
 * @dev Token representing EST.
 */
 contract EraSwapToken is BurnableToken, MintableToken{
     string public name ;
     string public symbol ;
     uint8 public decimals = 8 ;
     
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
     constructor (
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