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
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
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
    emit Transfer(msg.sender, _to, _value);
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
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
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


/**
 * @title The GainmersTOKEN contract
 * @dev The GainmersTOKEN Token inherite from StandardToken and Ownable by Zeppelin
 * @author Gainmers.Teamdev
 */
contract GainmersTOKEN is StandardToken, Ownable {
    string  public  constant name = "Gain Token";
    string  public  constant symbol = "GMR";
    uint8   public  constant decimals = 18;

    uint256 public  totalSupply;
    uint    public  transferableStartTime;
    address public  tokenSaleContract;
   

    modifier onlyWhenTransferEnabled() 
    {
        if ( now < transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) 
    {
        require(to != address(this));
        _;
    }

    modifier onlySaleContract()
    {
        require(msg.sender == tokenSaleContract);
        _;
    }

    function GainmersTOKEN(
        uint tokenTotalAmount, 
        uint _transferableStartTime, 
        address _admin) public 
    {
        
        totalSupply = tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        transferableStartTime = _transferableStartTime;
        tokenSaleContract = msg.sender;

        transferOwnership(_admin); 

    }

    /**
     * @dev override transfer token for a specified address to add onlyWhenTransferEnabled and validDestination
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev override transferFrom token for a specified address to add onlyWhenTransferEnabled and validDestination
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    /**
     * @dev burn tokens
     * @param _value The amount to be burned.
     * @return always true (necessary in case of override)
     */
    function burn(uint _value) 
        public
        onlyWhenTransferEnabled
        onlyOwner
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    /**
     * @dev burn tokens in the behalf of someone
     * @param _from The address of the owner of the token.
     * @param _value The amount to be burned.
     * @return always true (necessary in case of override)
     */
    function burnFrom(address _from, uint256 _value) 
        public
        onlyWhenTransferEnabled
        onlyOwner
        returns(bool) 
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

    /** 
    *If the event SaleSoldout is called this function enables earlier tokens transfer
    */
    function enableTransferEarlier ()
        public
        onlySaleContract
    {
        transferableStartTime = now + 2 days;
    }


    /**
     * @dev transfer to owner any tokens send by mistake on this contracts
     * @param token The address of the token to transfer.
     * @param amount The amount to be transfered.
     */
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }

}

/**
 * @title ModifiedCrowdsale
 * @dev ModifiedCrowdsale is based in Crowdsale. Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override 
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
 
contract ModifiedCrowdsale {
    using SafeMath for uint256;

    // The token being sold
    StandardToken public token; 

    //Start and end timestamps where investments are allowed 
    uint256 public startTime;
    uint256 public endTime;

     // how many token units a buyer gets per wei
    uint256 public rate;

    // address where crowdsale funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    //Event trigger if the Crowdsale reaches the hardcap
     event TokenSaleSoldOut();
    /**
    * @param _startTime StartTime for the token crowdsale
    * @param _endTime EndTime for the token crowdsale     
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be forwarded to
    */
    function ModifiedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public  {
        
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        
        token = createTokenContract(); 
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() 
        internal 
        returns(StandardToken) 
    {
        return new StandardToken();
    }

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _beneficiary) public   payable {
        require(validPurchase());
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        tokens += getBonus(tokens);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        require(token.transfer(_beneficiary, tokens)); 
        emit TokenPurchase(_beneficiary, weiAmount, tokens);

        forwardFunds();

        postBuyTokens();
    }

    // Action after buying tokens
    function postBuyTokens () internal  
    {emit TokenSaleSoldOut();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() 
       internal 
    {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase()  internal  view
        returns(bool) 
    {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool nonInvalidAccount = msg.sender != 0;
        return withinPeriod && nonZeroPurchase && nonInvalidAccount;
    }

    // @return true if crowdsale event has ended
    function hasEnded() 
        public 
        constant 
        returns(bool) 
    {
        return now > endTime;
    }


    /**
      * @dev Get the bonus based on the buy time 
      * @return the number of bonus token
    */
    function getBonus(uint256 _tokens) internal view returns (uint256 bonus) {
        require(_tokens != 0);
        if (startTime <= now && now < startTime + 7 days ) {
            return _tokens.div(5);
        } else if (startTime + 7 days <= now && now < startTime + 14 days ) {
            return _tokens.div(10);
        } else if (startTime + 14 days <= now && now < startTime + 21 days ) {
            return _tokens.div(20);
        }

        return 0;
    }
}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is ModifiedCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  // Request Modification : delete constant because needed in son contract
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}



/**
 * @title GainmersSALE
 * @dev 
 * GainmersSALE inherits form the Ownable and CappedCrowdsale,
 *
 * @author Gainmers.Teamdev
 */
contract GainmersSALE is Ownable, CappedCrowdsale {
    
    //Total supply of the GainmersTOKEN
    uint public constant TotalTOkenSupply = 100000000;

    //Hardcap of the ICO in wei
    uint private constant Hardcap = 30000 ether;

    //Exchange rate EHT/ GMR token
    uint private constant RateExchange = 1660;

   

    /**Initial distribution of the Tokens*/

    // Token initialy distributed for the team management and developer incentives (10%)
    address public constant TeamWallet = 0x6009267Cb183AEC8842cb1d020410f172dD2d50F;
    uint public constant TeamWalletAmount = 10000000e18; 
    
     // Token initialy distributed for the Advisors and sponsors (10%)
    address public constant TeamAdvisorsWallet = 0x3925848aF4388a3c10cd73F3529159de5f0C686c;
    uint public constant AdvisorsAmount = 10000000e18;
    
     // Token initially distribuded for future invesment rounds and prizes in the plataform (15%)
    address public constant 
    ReinvestWallet = 0x1cc1Bf6D3100Ce4EE3a398bEdE33A7e3a42225D7;
    uint public constant ReinvestAmount = 15000000e18;

     // Token initialy distributed for  Bounty Campaing (5%)
    address public constant BountyCampaingWallet = 0xD36FcA0DAd25554922d860dA18Ac47e4F9513672
    ;
    uint public constant BountyAmount = 5000000e18;

    

    //Period after the sale for the token to be transferable
    uint public constant AfterSaleTransferableTime = 2 days;


    function GainmersSALE(uint256 _startTime, uint256 _endTime) public
      CappedCrowdsale(Hardcap)
      ModifiedCrowdsale(_startTime,
                         _endTime, 
                         RateExchange, 
                         TeamWallet)
    {
        
        token.transfer(TeamWallet, TeamWalletAmount);
        token.transfer(TeamAdvisorsWallet, AdvisorsAmount);
        token.transfer(ReinvestWallet, ReinvestAmount);
        token.transfer(BountyCampaingWallet, BountyAmount);


        
    }

    /**
     * @dev Handles the creation of the GainmersTOKEN
     * @return the  StandardToken 
     */
    function createTokenContract () 
      internal 
      returns(StandardToken) 
    {
        return new GainmersTOKEN(TotalTOkenSupply,
         endTime.add(AfterSaleTransferableTime),
        TeamWallet);
    }



    /**
     * @dev Drain the remaining tokens of the crowdsale to the TeamWallet account
     * @dev Only for owner
     * @return the StandardToken 
     */
    function drainRemainingToken () 
      public
      onlyOwner
    {
        require(hasEnded());
        token.transfer(TeamWallet, token.balanceOf(this));
    }


    /** 
    * @dev Allows the early transfer of tokens if the ICO end before the end date
    */

    function postBuyTokens ()  internal {
        if ( weiRaised >= Hardcap ) {  
            GainmersTOKEN gainmersToken = GainmersTOKEN (token);
            gainmersToken.enableTransferEarlier();
            emit TokenSaleSoldOut();
        }
    }
}