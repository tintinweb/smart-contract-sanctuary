pragma solidity ^0.4.11;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function transferOwnership(address newOwner) onlyOwner public {
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
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }
  
}

contract Webrypto is BasicToken,Ownable {

   using SafeMath for uint256;
   
   string public constant name = &quot;Webrypto&quot;;
   string public constant symbol = &quot;WBT&quot;;
   uint256 public constant decimals = 18;
   uint256 public preIcoBuyPrice = 222222222222222;   // per token the price is 2.2222*10^-4 eth, this price is equivalent in wei
   uint256 public IcoPrice = 1000000000000000;
   uint256 public bonusPhase1 = 30;
   uint256 public bonusPhase2 = 20;
   uint256 public bonusPhase3 = 10;
   uint256 public TOKENS_SOLD;
  
   address public ethStore = 0x3e8B24DccA3DAd3A4427CC6B2fcc4E09079Ec0D8;
   uint256 public constant INITIAL_SUPPLY = 100000000;
   event Debug(string message, address addr, uint256 number);
   event log(string message, uint256 number);
   /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
   //TODO: Change the name of the constructor
    function Webrypto() public {
        owner = ethStore;
        totalSupply = INITIAL_SUPPLY;
        tokenBalances[ethStore] = INITIAL_SUPPLY * (10 ** uint256(decimals));   //Since we divided the token into 10^18 parts
        TOKENS_SOLD = 0;
    }
    
    
    // fallback function can be used to buy tokens
      function () public payable {
       // require(msg.sender != owner);   //owner should not be buying any tokens
        buy(msg.sender);
    }
    
    function calculateTokens(uint amt) internal returns (uint tokensYouCanGive, uint returnAmount) {
        uint bonus = 0;
        uint tokensRequired = 0;
        uint tokensWithoutBonus = 0;
        uint priceCharged = 0;
        
        //pre-ico phase
        if (TOKENS_SOLD <4500000)
        {
            tokensRequired = amt.div(preIcoBuyPrice);
            if (tokensRequired + TOKENS_SOLD > 4500000)
            {
                tokensYouCanGive = 4500000 - TOKENS_SOLD;
                returnAmount = tokensRequired - tokensYouCanGive;
                returnAmount = returnAmount.mul(preIcoBuyPrice);
                log(&quot;Tokens being bought exceed the limit of pre-ico. Returning remaining amount&quot;,returnAmount);
            }
            else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
            require (tokensYouCanGive + TOKENS_SOLD <= 4500000);
        }
        //ico phase 1 with 30% bonus
        else if (TOKENS_SOLD >=4500000 && TOKENS_SOLD <24000000)
        {
             tokensRequired = amt.div(IcoPrice);
             bonus = tokensRequired.mul(bonusPhase1);
             bonus = bonus.div(100);
             tokensRequired = tokensRequired.add(bonus);
             if (tokensRequired + TOKENS_SOLD > 24000000)
             {
                tokensYouCanGive = 24000000 - TOKENS_SOLD;
                tokensWithoutBonus = tokensYouCanGive.mul(10);
                tokensWithoutBonus = tokensWithoutBonus.div(13);
                
                priceCharged = tokensWithoutBonus.mul(IcoPrice); 
                returnAmount = amt - priceCharged;
                
                log(&quot;Tokens being bought exceed the limit of ico phase 1. Returning remaining amount&quot;,returnAmount);
             }
             else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
            require (tokensYouCanGive + TOKENS_SOLD <= 24000000);
        }
        //ico phase 2 with 20% bonus
        if (TOKENS_SOLD >=24000000 && TOKENS_SOLD <42000000)
        {
             tokensRequired = amt.div(IcoPrice);
             bonus = tokensRequired.mul(bonusPhase2);
             bonus = bonus.div(100);
             tokensRequired = tokensRequired.add(bonus);
             if (tokensRequired + TOKENS_SOLD > 42000000)
             {
                tokensYouCanGive = 42000000 - TOKENS_SOLD;
                tokensWithoutBonus = tokensYouCanGive.mul(10);
                tokensWithoutBonus = tokensWithoutBonus.div(13);
                
                priceCharged = tokensWithoutBonus.mul(IcoPrice); 
                returnAmount = amt - priceCharged;
                log(&quot;Tokens being bought exceed the limit of ico phase 2. Returning remaining amount&quot;,returnAmount);
             }
              else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
             require (tokensYouCanGive + TOKENS_SOLD <= 42000000);
        }
        //ico phase 3 with 10% bonus
        if (TOKENS_SOLD >=42000000 && TOKENS_SOLD <58500000)
        {
             tokensRequired = amt.div(IcoPrice);
             bonus = tokensRequired.mul(bonusPhase3);
             bonus = bonus.div(100);
             tokensRequired = tokensRequired.add(bonus);
              if (tokensRequired + TOKENS_SOLD > 58500000)
             {
                tokensYouCanGive = 58500000 - TOKENS_SOLD;
                tokensWithoutBonus = tokensYouCanGive.mul(10);
                tokensWithoutBonus = tokensWithoutBonus.div(13);
                
                priceCharged = tokensWithoutBonus.mul(IcoPrice); 
                returnAmount = amt - priceCharged;
                log(&quot;Tokens being bought exceed the limit of ico phase 3. Returning remaining amount&quot;,returnAmount);
             }
            else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
             require (tokensYouCanGive + TOKENS_SOLD <= 58500000);
        }
        if (TOKENS_SOLD == 58500000)
        {
            log(&quot;ICO has ended. All tokens sold.&quot;, 58500000);
            tokensYouCanGive = 0;
            returnAmount = amt;
        }
        require(TOKENS_SOLD <=58500000);
    }
    
    function buy(address beneficiary) payable public returns (uint tokens) {
        uint paymentToGiveBack = 0;
        (tokens,paymentToGiveBack) = calculateTokens(msg.value);
        
        TOKENS_SOLD += tokens;
        tokens = tokens * (10 ** uint256(decimals));
        
        require(tokenBalances[owner] >= tokens);               // checks if it has enough to sell
        
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(tokens);                  // adds the amount to buyer&#39;s balance
        tokenBalances[owner] = tokenBalances[owner].sub(tokens);                        // subtracts amount from seller&#39;s balance
        
        Transfer(owner, beneficiary, tokens);               // execute an event reflecting the change
    
        if (paymentToGiveBack >0)
        {
            beneficiary.transfer(paymentToGiveBack);
        }
    
        ethStore.transfer(msg.value - paymentToGiveBack);                       //send the eth to the address where eth should be collected
        
        return tokens;                                    // ends function and returns
    }
    
   function getTokenBalance(address yourAddress) constant public returns (uint256 balance) {
        return tokenBalances[yourAddress].div (10**decimals); // show token balance in full tokens not part
    }
}