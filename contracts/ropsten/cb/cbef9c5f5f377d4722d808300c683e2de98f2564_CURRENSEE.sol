pragma solidity 0.4.19;

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
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  //balance in each address account
  mapping(address => uint256) balances;
  
  //address where those funds are sent which are meant for reinvestment
  address reinvestmentAddress;
  address currenseeFoundationAddress;
  
  //percent quotient and percent dividend are used to calculate the percentage of fees
  uint percentQuotient;
  uint percentDividend;
  
  //the fees deducted from each transaction is further divided into funds for owner and funds for reinvestment
  uint ownerPercentageFromFees;
  uint reinvestmentPercentageFromFees;
  uint currenseeFoundationPercentageFromFees;
  
  
  //the maximum amount of fees in tokens that can be deducted
  uint feesMaxUptoCoin;
  
  //the tokens sent to reinvestment address till date
  //would show the correct number even if the reinvestment address changes after contract is deployed
  uint public tokensSentToReinvestmentAddress;
  
  //the number of tokens used for reinvestment
  uint public tokensUsedForReinvestment;
  
   
  //the end date of ico after which the users can move their tokens
  uint public icoEndDate;
  
  //set the address of ico
  address public icoAddress;
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _amount The amount to be transferred.
  */
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);

    if (msg.sender!=owner && msg.sender!= icoAddress)
        require(now>=icoEndDate);
        
    uint tokensFee = _amount.mul(percentQuotient);
    tokensFee = tokensFee.div(percentDividend);
    
    //if the fees turns out to be more than the max number allowed, we will set it to the max number
    if (tokensFee > feesMaxUptoCoin)
    {
        tokensFee = feesMaxUptoCoin;
    }
    uint tokensToBeSent = _amount.sub(tokensFee);
    redistributeFees(tokensFee);
    // SafeMath.sub will throw if there is not enough balance.
   
    balances[_to] = balances[_to].add(tokensToBeSent);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    
    
    Transfer(msg.sender, _to, _amount);
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
   * The redistribution function to split the fees between owner and reinvestment address
   **/ 
  function redistributeFees(uint tokensForOwner) internal
  {
      uint ownerPercent = tokensForOwner.mul(ownerPercentageFromFees).div(100);
      uint reinvestmentPercent = tokensForOwner.mul(reinvestmentPercentageFromFees).div(100);
      uint foundationPercent = tokensForOwner.mul(currenseeFoundationPercentageFromFees).div(100);
      balances[owner] = balances[owner].add(ownerPercent);
      balances[reinvestmentAddress] = balances[reinvestmentAddress].add(reinvestmentPercent); 
      balances[currenseeFoundationAddress] = balances[currenseeFoundationAddress].add(foundationPercent);
      tokensSentToReinvestmentAddress = tokensSentToReinvestmentAddress.add(reinvestmentPercent);
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

    if (msg.sender!=owner && msg.sender!= icoAddress)
        require(now>=icoEndDate);
        
    uint tokensFee = _amount.mul(percentQuotient);
   tokensFee = tokensFee.div(percentDividend);
   if (tokensFee > feesMaxUptoCoin)
    {
        tokensFee = feesMaxUptoCoin;
    }
    uint tokensToBeSent = _amount.sub(tokensFee);
    redistributeFees(tokensFee);
    // SafeMath.sub will throw if there is not enough balance.
   
    balances[_to] = balances[_to].add(tokensToBeSent);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    Transfer(_from, _to, _amount);
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
    Approval(msg.sender, _spender, _amount);
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
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public onlyOwner{
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }
}

/**
 * The contract that has the setter functions for all the major variables used in the contract
 * This contract allows to change the percentages, fees etc
 * All setters can only be called by the owner of the contract
 **/ 
contract UpgradeableToken is BurnableToken {
    
    /**
     * @dev Set the percentage of the fee to be deducted on each transfer
     **/ 
    function setFee(uint _percentQuotient, uint _percentDividend) public onlyOwner
    {
        percentQuotient = _percentQuotient;
        percentDividend = _percentDividend;
    }
    
    /**
     * @dev Change the reinvestment address 
     **/
    function setReinvestmentAddress(address _reinvestment) public onlyOwner 
    {
        reinvestmentAddress = _reinvestment;
    }
    
     /**
     * @dev Change the currensee foundation address 
     **/
    function setCurrenseeFoundationAddress(address _currensee) public onlyOwner 
    {
        currenseeFoundationAddress = _currensee;
    }
    
    /**
     * @dev Send the number of tokens that have been used for reinvestment further
     * The sent number would be added to the previous state
     **/
    function setTokensUsedForReinvestment(uint _tokensUsed) public onlyOwner 
    {
        tokensUsedForReinvestment = tokensUsedForReinvestment.add(_tokensUsed);
    }
    
    /**
     * @dev Change how the fees of each transaction will be split between owner and reinvestment address
     **/
    function setFeesDistributionPercentages(uint _ownerFeesPercentage, uint _reinvestmentFeesPercentage, uint _currenseeFoundationPercentageFromFees) public onlyOwner 
    {
        require (_ownerFeesPercentage.add(_reinvestmentFeesPercentage.add(_currenseeFoundationPercentageFromFees)) == 100);
        ownerPercentageFromFees = _ownerFeesPercentage;
        reinvestmentPercentageFromFees = _reinvestmentFeesPercentage;
        currenseeFoundationPercentageFromFees = _currenseeFoundationPercentageFromFees;
    }
    
    /**
     * @dev Change the maximum tokens upto which fees can be charged
     **/
    function setFeesMaxUptoCoin(uint _coins) public onlyOwner 
    {
        require (_coins<totalSupply);
        feesMaxUptoCoin = _coins;
    }
}
/**
 * @title CURRENSEE Token
 * @dev Token representing CUR.
 */
 contract CURRENSEE is UpgradeableToken {
     string public name ;
     string public symbol ;
     uint8 public decimals = 18 ;
     
     /**
     *@dev users sending ether to this contract will be reverted. Any ether sent to the contract will be sent back to the caller
     */
     function ()public payable {
         revert();
     }
     
     /**
     * @dev Constructor function to initialize the initial supply of token to the creator of the contract
     */
    function CURRENSEE(address _ownerAddress, address _reinvestmentAddress, address _currenseeFoundationAddress) public {
         owner = _ownerAddress;
         reinvestmentAddress = _reinvestmentAddress;
         currenseeFoundationAddress = _currenseeFoundationAddress;
         totalSupply = 15000000;
         totalSupply = totalSupply.mul( 10 ** uint256(decimals)); //Update total supply with the decimal amount
         name = &quot;CURRENSEE&quot;;
         symbol = &quot;CUR&quot;;
         balances[_ownerAddress] = totalSupply;
         percentQuotient = 1;
         percentDividend = 100;
         
         ownerPercentageFromFees = 20;
         reinvestmentPercentageFromFees = 70;
         currenseeFoundationPercentageFromFees = 10;
         
         feesMaxUptoCoin = uint(1).mul(10**18);
         tokensSentToReinvestmentAddress = 0;
         //Emitting transfer event since assigning all tokens to the creator also corresponds to the transfer of tokens to the creator
         Transfer(address(0), msg.sender, totalSupply);
     }
     
     /**
     *@dev helper method to get token details, name, symbol and totalSupply in one go
     */
    function getTokenDetail() public view returns (string, string, uint256) {
	    return (name, symbol, totalSupply);
    }
    
    /**
     * Gets the grams of gold behind each token
     **/ 
    function getGoldBackedByEachToken() public constant returns (uint) 
    {
        uint basePrice = uint(1).mul(10**18);
        uint moreGold = tokensSentToReinvestmentAddress.mul(10**18);
        moreGold = moreGold.div(totalSupply);
        moreGold = moreGold.add(basePrice);
        return moreGold;
    }
      /**
     * Set the end date of ICO
     **/
     function setICOEndDate(uint timestamp) public onlyOwner 
     {
         icoEndDate = timestamp;
     }
     /**
      * Set the address of ICO
      **/
      function setICOAddress(address icoAddr) public onlyOwner 
      {
          icoAddress = icoAddr;
      }
 }