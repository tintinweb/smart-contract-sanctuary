pragma solidity ^0.4.18;

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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


contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
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
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}


/**
  * @title  RateToken
  * @dev Rate Token Contract implementation 
*/
contract RateToken is Ownable {
    using SafeMath for uint256;
    //struct that holds values for specific discount
    struct Discount {
        //min number of tokens expected to be bought
        uint256 minTokens;
        //discount percentage
        uint256 percent;
    }
    //Discount per address
    mapping(address => Discount) private discounts;
    //Token conversion rate
    uint256 public rate;

   /**
    * @dev Event which is fired when Rate is set
    */
    event RateSet(uint256 rate);

   
    function RateToken(uint256 _initialRate) public {
        setRate(_initialRate);
    }

   /**
   * @dev Function that sets the conversion rate
   * @param _rateInWei The amount of rate to be set
    */
    function setRate(uint _rateInWei) onlyOwner public {
        require(_rateInWei > 0);
        rate = _rateInWei;
        RateSet(rate);
    }

   /**
   * @dev Function for adding discount for concrete buyer, only available for the owner.  
   * @param _buyer The address of the buyer.
   * @param _minTokens The amount of tokens.
   * @param _percent The amount of discount in percents.
   * @return A boolean that indicates if the operation was successful.
    */
    
    // NOTE FROM BLOCKERA - PERCENTAGE COULD BE UINT8 (0 - 255)
    function addDiscount(address _buyer, uint256 _minTokens, uint256 _percent) public onlyOwner returns (bool) { 
        require(_buyer != address(0));
        require(_minTokens > 0);
        require(_percent > 0);
        require(_percent < 100);
        Discount memory discount;
        discount.minTokens = _minTokens;
        discount.percent = _percent;
        discounts[_buyer] = discount;
        return true;
    }

   /**
   * @dev Function to remove discount.
   * @param _buyer The address to remove the discount from.
   * @return A boolean that indicates if the operation was successful.
   */
    function removeDiscount(address _buyer) public onlyOwner {
        require(_buyer != address(0));
        removeExistingDiscount(_buyer);
    }

    /**
    * @dev Public Function that calculates the amount in wei for specific number of tokens
    * @param _buyer address.
    * @param _tokens The amount of tokens.
    * @return uint256 the price for tokens in wei.
    */
    function calculateWeiNeeded(address _buyer, uint _tokens) public view returns (uint256) {
        require(_buyer != address(0));
        require(_tokens > 0);

        Discount memory discount = discounts[_buyer];
        require(_tokens >= discount.minTokens);
        if (discount.minTokens == 0) {
            return _tokens.div(rate);
        }

        uint256 costOfTokensNormally = _tokens.div(rate);
        return costOfTokensNormally.mul(100 - discount.percent).div(100);

    }
    
    /**
     * @dev Removes discount for concrete buyer.
     * @param _buyer the address for which the discount will be removed.
     */
    function removeExistingDiscount(address _buyer) internal {
        delete(discounts[_buyer]);
    }

    /**
    * @dev Function that converts wei into tokens.
    * @param _buyer address of the buyer.
    * @param _buyerAmountInWei amount of ether in wei. 
    * @return uint256 value of the calculated tokens.
    */
    function calculateTokens(address _buyer, uint256 _buyerAmountInWei) internal view returns (uint256) {
        Discount memory discount = discounts[_buyer];
        if (discount.minTokens == 0) {
            return _buyerAmountInWei.mul(rate);
        }

        uint256 normalTokens = _buyerAmountInWei.mul(rate);
        uint256 discountBonus = normalTokens.mul(discount.percent).div(100);
        uint256 tokens = normalTokens + discountBonus;
        require(tokens >= discount.minTokens);
        return tokens;
    }  
}



/**
 * @title Caerus token.
 * @dev Implementation of the Caerus token.
 */
contract CaerusToken is RateToken, PausableToken, DetailedERC20 {
    mapping (address => uint256) public contributions;
    uint256 public tokenSold = 0; 
    uint256 public weiRaised = 0; 
    address transferAddress;
    
    mapping (address => TokenVesting) public vestedTokens;

    event TokensBought(address indexed buyer, uint256 tokens);
    event Contribution(address indexed buyer, uint256 amountInWei);
    event VestedTokenCreated(address indexed beneficiary, uint256 duration, uint256 tokens);
    event TokensSpent(address indexed tokensHolder, uint256 tokens);

    function CaerusToken(address _transferAddress, uint _initialRate) public RateToken(_initialRate) DetailedERC20("Caerus Token", "CAER", 18) {
        totalSupply_ = 73000000 * 10 ** 18;
        transferAddress = _transferAddress;
        balances[owner] = totalSupply_;
  	}
    /**
    * @dev Sets the address to transfer funds.
    * @param _transferAddress An address to transfer funds.
    */
    function setTransferAddress(address _transferAddress) onlyOwner public {
        transferAddress = _transferAddress;
    }
    /**
    * @dev Fallback function when receiving Ether.
    */
    function() payable public {
        buyTokens();
    }

    /**
    * @dev Allow addresses to buy tokens.
    */
    function buyTokens() payable public whenNotPaused {
        require(msg.value > 0);
        
        uint256 tokens = calculateTokens(msg.sender, msg.value);
        transferTokens(owner, msg.sender, tokens);

        markTokenSold(tokens);
        markContribution();
        removeExistingDiscount(msg.sender);
        transferAddress.transfer(msg.value);
        TokensBought(msg.sender, tokens);
    }

    /**
    * @dev Transfer tokens from owner to specific address, available only for the owner.
    * @param _to The address where tokens are transfered.
    * @param _tokens Amount of tokens that need to be transfered.
    * @return Boolean representing the successful execution of the function.
    */
    // Owner could use regular transfer method if they wanted to
    function markTransferTokens(address _to, uint256 _tokens) onlyOwner public returns (bool) {
        require(_to != address(0));

        transferTokens(owner, _to, _tokens);
        markTokenSold(_tokens);
        return true;
    }

    /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred.
   * @param _start time when vesting starts.
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest.
   * @param _duration duration in seconds of the period in which the tokens will vest.
   * @param _tokens Amount of tokens that need to be vested.
   * @return Boolean representing the successful execution of the function.
   */
    function createVestedToken(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _tokens) onlyOwner public returns (bool) {
        TokenVesting vestedToken = new TokenVesting(_beneficiary, _start, _cliff, _duration, false);
        vestedTokens[_beneficiary] = vestedToken;
        address vestedAddress = address(vestedToken);
        transferTokens(owner, vestedAddress, _tokens);
        VestedTokenCreated(_beneficiary, _duration, _tokens);
        return true;
    }

    /**
    * @dev Transfer tokens from address to owner address.
    * @param _tokens Amount of tokens that need to be transfered.
    * @return Boolean representing the successful execution of the function.
    */
    function spendToken(uint256 _tokens) public returns (bool) {
        transferTokens(msg.sender, owner, _tokens);
        TokensSpent(msg.sender, _tokens);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    * @return Boolean representing the successful execution of the function.
    */
    function approve(address _spender, uint _value) public returns (bool) {
        //  To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        return super.approve(_spender, _value);
    }

    /**
    * @dev Transfer tokens from one address to another.
    * @param _from The address which you want to send tokens from.
    * @param _to The address which you want to transfer to.
    * @param _tokens the amount of tokens to be transferred.
    */
    function transferTokens(address _from, address _to, uint256 _tokens) private {
        require(_tokens > 0);
        require(balances[_from] >= _tokens);
        
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        Transfer(_from, _to, _tokens);
    }

    /**
    * @dev Adds or updates contributions
    */
    function markContribution() private {
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        weiRaised = weiRaised.add(msg.value);
        Contribution(msg.sender, msg.value);
    }

    /**
    * @dev Increase token sold amount.
    * @param _tokens Amount of tokens that are sold.
    */
    function markTokenSold(uint256 _tokens) private {
        tokenSold = tokenSold.add(_tokens);
    }
    
    /**
    * @dev Owner can transfer out any accidentally sent Caerus tokens.
    * @param _tokenAddress The address which you want to send tokens from.
    * @param _tokens the amount of tokens to be transferred.
    */    
    function transferAnyCaerusToken(address _tokenAddress, uint _tokens) public onlyOwner returns (bool success) {
        transferTokens(_tokenAddress, owner, _tokens);
        return true;
    }
}