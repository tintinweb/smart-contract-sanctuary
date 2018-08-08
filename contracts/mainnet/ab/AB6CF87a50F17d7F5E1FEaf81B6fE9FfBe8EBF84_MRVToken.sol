pragma solidity ^0.4.11;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/** 
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="99ebfcf4faf6d9ab">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is Ownable {

 /** 
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    throw;
  }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param tokenAddr address The address of the token contract
   */
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

/** 
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d8aabdb5bbb798ea">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * MRV token, distributed by crowdsale. Token and crowdsale functionality are unified in a single
 * contract, to make clear and restrict the conditions under which tokens can be created or destroyed.
 * Derived from OpenZeppelin CrowdsaleToken template.
 *
 * Key Crowdsale Facts:
 * 
 * * MRV tokens will be sold at a rate of 5,000 per ETH.
 *
 * * All MRV token sales are final. No refunds can be issued by the contract.
 *
 * * Unless adjusted later by the crowdsale operator, up to 100 million tokens will be available.
 *
 * * An additional 5,000 tokens are reserved. 
 *
 * * Participate in the crowdsale by sending ETH to this contract, when the crowdsale is open.
 *
 * * Sending more ETH than required to purchase all the remaining tokens will fail.
 *
 * * Timers can be set to allow anyone to open/close the crowdsale at the proper time. The crowdsale
 *   operator reserves the right to set, unset, and reset these timers at any time, for any reason,
 *   and without notice.
 *
 * * The operator of the crowdsale has the ability to manually open it and close it, and reserves
 *   the right to do so at any time, for any reason, and without notice.
 *
 * * The crowdsale cannot be reopened, and no tokens can be created, after the crowdsale closes.
 *
 * * The crowdsale operator reserves the right to adjust the decimal places of the MRV token at
 *   any time after the crowdsale closes, for any reason, and without notice. MRV tokens are
 *   initially divisible to 18 decimal places.
 *
 * * The crowdsale operator reserves the right to not open or close the crowdsale, not set the
 *   open or close timer, and generally refrain from doing things that the contract would otherwise
 *   authorize them to do.
 *
 * * The crowdsale operator reserves the right to claim and keep any ETH or tokens that end up in
 *   the contract&#39;s account. During normal crowdsale operation, ETH is not stored in the contract&#39;s
 *   account, and is instead sent directly to the beneficiary.
 */
contract MRVToken is StandardToken, Ownable, HasNoTokens, HasNoContracts {

    // Token Parameters

    // From StandardToken we inherit balances and totalSupply.
    
    // What is the full name of the token?
    string public constant name = "Macroverse Token";
    // What is its suggested symbol?
    string public constant symbol = "MRV";
    // How many of the low base-10 digits are to the right of the decimal point?
    // Note that this is not constant! After the crowdsale, the contract owner can
    // adjust the decimal places, allowing for 10-to-1 splits and merges.
    uint8 public decimals;
    
    // Crowdsale Parameters
    
    // Where will funds collected during the crowdsale be sent?
    address beneficiary;
    // How many MRV can be sold in the crowdsale?
    uint public maxCrowdsaleSupplyInWholeTokens;
    // How many whole tokens are reserved for the beneficiary?
    uint public constant wholeTokensReserved = 5000;
    // How many tokens per ETH during the crowdsale?
    uint public constant wholeTokensPerEth = 5000;
    
    // Set to true when the crowdsale starts
    // Internal flag. Use isCrowdsaleActive instead().
    bool crowdsaleStarted;
    // Set to true when the crowdsale ends
    // Internal flag. Use isCrowdsaleActive instead().
    bool crowdsaleEnded;
    // We can also set some timers to open and close the crowdsale. 0 = timer is not set.
    // After this time, the crowdsale will open with a call to checkOpenTimer().
    uint public openTimer = 0;
    // After this time, no contributions will be accepted, and the crowdsale will close with a call to checkCloseTimer().
    uint public closeTimer = 0;
    
    ////////////
    // Constructor
    ////////////
    
    /**
    * Deploy a new MRVToken contract, paying crowdsale proceeds to the given address,
    * and awarding reserved tokens to the other given address.
    */
    function MRVToken(address sendProceedsTo, address sendTokensTo) {
        // Proceeds of the crowdsale go here.
        beneficiary = sendProceedsTo;
        
        // Start with 18 decimals, same as ETH
        decimals = 18;
        
        // Initially, the reserved tokens belong to the given address.
        totalSupply = wholeTokensReserved * 10 ** 18;
        balances[sendTokensTo] = totalSupply;
        
        // Initially the crowdsale has not yet started or ended.
        crowdsaleStarted = false;
        crowdsaleEnded = false;
        // Default to a max supply of 100 million tokens available.
        maxCrowdsaleSupplyInWholeTokens = 100000000;
    }
    
    ////////////
    // Fallback function
    ////////////
    
    /**
    * This is the MAIN CROWDSALE ENTRY POINT. You participate in the crowdsale by 
    * sending ETH to this contract. That calls this function, which credits tokens
    * to the address or contract that sent the ETH.
    *
    * Since MRV tokens are sold at a rate of more than one per ether, and since
    * they, like ETH, have 18 decimal places (at the time of sale), any fractional
    * amount of ETH should be handled safely.
    *
    * Note that all orders are fill-or-kill. If you send in more ether than there are
    * tokens remaining to be bought, your transaction will be rolled back and you will
    * get no tokens and waste your gas.
    */
    function() payable onlyDuringCrowdsale {
        createTokens(msg.sender);
    }
    
    ////////////
    // Events
    ////////////
    
    // Fired when the crowdsale is recorded as started.
    event CrowdsaleOpen(uint time);
    // Fired when someone contributes to the crowdsale and buys MRV
    event TokenPurchase(uint time, uint etherAmount, address from);
    // Fired when the crowdsale is recorded as ended.
    event CrowdsaleClose(uint time);
    // Fired when the decimal point moves
    event DecimalChange(uint8 newDecimals);
    
    ////////////
    // Modifiers (encoding important crowdsale logic)
    ////////////
    
    /**
     * Only allow some actions before the crowdsale closes, whether it&#39;s open or not.
     */
    modifier onlyBeforeClosed {
        checkCloseTimer();
        if (crowdsaleEnded) throw;
        _;
    }
    
    /**
     * Only allow some actions after the crowdsale is over.
     * Will set the crowdsale closed if it should be.
     */
    modifier onlyAfterClosed {
        checkCloseTimer();
        if (!crowdsaleEnded) throw;
        _;
    }
    
    /**
     * Only allow some actions before the crowdsale starts.
     */
    modifier onlyBeforeOpened {
        checkOpenTimer();
        if (crowdsaleStarted) throw;
        _;
    }
    
    /**
     * Only allow some actions while the crowdsale is active.
     * Will set the crowdsale open if it should be.
     */
    modifier onlyDuringCrowdsale {
        checkOpenTimer();
        checkCloseTimer();
        if (crowdsaleEnded) throw;
        if (!crowdsaleStarted) throw;
        _;
    }

    ////////////
    // Status and utility functions
    ////////////
    
    /**
     * Determine if the crowdsale should open by timer.
     */
    function openTimerElapsed() constant returns (bool) {
        return (openTimer != 0 && now > openTimer);
    }
    
    /**
     * Determine if the crowdsale should close by timer.
     */
    function closeTimerElapsed() constant returns (bool) {
        return (closeTimer != 0 && now > closeTimer);
    }
    
    /**
     * If the open timer has elapsed, start the crowdsale.
     * Can be called by people, but also gets called when people try to contribute.
     */
    function checkOpenTimer() {
        if (openTimerElapsed()) {
            crowdsaleStarted = true;
            openTimer = 0;
            CrowdsaleOpen(now);
        }
    }
    
    /**
     * If the close timer has elapsed, stop the crowdsale.
     */
    function checkCloseTimer() {
        if (closeTimerElapsed()) {
            crowdsaleEnded = true;
            closeTimer = 0;
            CrowdsaleClose(now);
        }
    }
    
    /**
     * Determine if the crowdsale is currently happening.
     */
    function isCrowdsaleActive() constant returns (bool) {
        // The crowdsale is happening if it is open or due to open, and it isn&#39;t closed or due to close.
        return ((crowdsaleStarted || openTimerElapsed()) && !(crowdsaleEnded || closeTimerElapsed()));
    }
    
    ////////////
    // Before the crowdsale: configuration
    ////////////
    
    /**
     * Before the crowdsale opens, the max token count can be configured.
     */
    function setMaxSupply(uint newMaxInWholeTokens) onlyOwner onlyBeforeOpened {
        maxCrowdsaleSupplyInWholeTokens = newMaxInWholeTokens;
    }
    
    /**
     * Allow the owner to start the crowdsale manually.
     */
    function openCrowdsale() onlyOwner onlyBeforeOpened {
        crowdsaleStarted = true;
        openTimer = 0;
        CrowdsaleOpen(now);
    }
    
    /**
     * Let the owner start the timer for the crowdsale start. Without further owner intervention,
     * anyone will be able to open the crowdsale when the timer expires.
     * Further calls will re-set the timer to count from the time the transaction is processed.
     * The timer can be re-set after it has tripped, unless someone has already opened the crowdsale.
     */
    function setCrowdsaleOpenTimerFor(uint minutesFromNow) onlyOwner onlyBeforeOpened {
        openTimer = now + minutesFromNow * 1 minutes;
    }
    
    /**
     * Let the owner stop the crowdsale open timer, as long as the crowdsale has not yet opened.
     */
    function clearCrowdsaleOpenTimer() onlyOwner onlyBeforeOpened {
        openTimer = 0;
    }
    
    /**
     * Let the owner start the timer for the crowdsale end. Counts from when the function is called,
     * *not* from the start of the crowdsale.
     * It is possible, but a bad idea, to set this before the open timer.
     */
    function setCrowdsaleCloseTimerFor(uint minutesFromNow) onlyOwner onlyBeforeClosed {
        closeTimer = now + minutesFromNow * 1 minutes;
    }
    
    /**
     * Let the owner stop the crowdsale close timer, as long as it has not yet expired.
     */
    function clearCrowdsaleCloseTimer() onlyOwner onlyBeforeClosed {
        closeTimer = 0;
    }
    
    
    ////////////
    // During the crowdsale
    ////////////
    
    /**
     * Create tokens for the given address, in response to a payment.
     * Cannot be called by outside callers; use the fallback function, which will create tokens for whoever pays it.
     */
    function createTokens(address recipient) internal onlyDuringCrowdsale {
        if (msg.value == 0) {
            throw;
        }

        uint tokens = msg.value.mul(wholeTokensPerEth); // Exploits the fact that we have 18 decimals, like ETH.
        
        var newTotalSupply = totalSupply.add(tokens);
        
        if (newTotalSupply > (wholeTokensReserved + maxCrowdsaleSupplyInWholeTokens) * 10 ** 18) {
            // This would be too many tokens issued.
            // Don&#39;t mess around with partial order fills.
            throw;
        }
        
        // Otherwise, we can fill the order entirely, so make the tokens and put them in the specified account.
        totalSupply = newTotalSupply;
        balances[recipient] = balances[recipient].add(tokens);
        
        // Announce the purchase
        TokenPurchase(now, msg.value, recipient);

        // Lastly (after all state changes), send the money to the crowdsale beneficiary.
        // This allows the crowdsale contract itself not to hold any ETH.
        // It also means that ALL SALES ARE FINAL!
        if (!beneficiary.send(msg.value)) {
            throw;
        }
    }
    
    /**
     * Allow the owner to end the crowdsale manually.
     */
    function closeCrowdsale() onlyOwner onlyDuringCrowdsale {
        crowdsaleEnded = true;
        closeTimer = 0;
        CrowdsaleClose(now);
    }  
    
    ////////////
    // After the crowdsale: token maintainance
    ////////////
    
    /**
     * When the crowdsale is finished, the contract owner may adjust the decimal places for display purposes.
     * This should work like a 10-to-1 split or reverse-split.
     * The point of this mechanism is to keep the individual MRV tokens from getting inconveniently valuable or cheap.
     * However, it relies on the contract owner taking the time to update the decimal place value.
     * Note that this changes the decimals IMMEDIATELY with NO NOTICE to users.
     */
    function setDecimals(uint8 newDecimals) onlyOwner onlyAfterClosed {
        decimals = newDecimals;
        // Announce the change
        DecimalChange(decimals);
    }
    
    /**
     * If Ether somehow manages to get into this contract, provide a way to get it out again.
     * During normal crowdsale operation, ETH is immediately forwarded to the beneficiary.
     */
    function reclaimEther() external onlyOwner {
        // Send the ETH. Make sure it worked.
        assert(owner.send(this.balance));
    }

}