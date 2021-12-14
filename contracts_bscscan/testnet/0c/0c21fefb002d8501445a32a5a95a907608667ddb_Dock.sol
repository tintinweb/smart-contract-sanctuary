/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity ^0.4.18;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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


/*
 * DockToken is a standard ERC20 token with some additional functionalities:
 * - Transfers are only enabled after contract owner enables it (after the ICO)
 *
 * Note: Token Offering == Initial Coin Offering(ICO)
 */

contract Dock is StandardToken, Ownable {
    string public constant symbol = "DOCK";
    string public constant name = "DockToken";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant TOKEN_OFFERING_ALLOWANCE = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE = INITIAL_SUPPLY - TOKEN_OFFERING_ALLOWANCE;
    
    // Address of token admin
    address public adminAddr;

    // Address of token offering
	  address public tokenOfferingAddr;

    // Enable transfers after conclusion of token offering
    bool public transferEnabled = false;
    
    /**
     * Check if transfer is allowed
     *
     * Permissions:
     *                                                       Owner    Admin    OffeirngContract    Others
     * transfer (before transferEnabled is true)               x        x            x               x
     * transferFrom (before transferEnabled is true)           x        v            v               x
     * transfer/transferFrom after transferEnabled is true     v        x            x               v
     */
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled || msg.sender == adminAddr || msg.sender == tokenOfferingAddr);
        _;
    }

    /**
     * Check if token offering address is set or not
     */
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenOfferingAddr == address(0x0));
        _;
    }

    /**
     * Check if address is a valid destination to transfer tokens to
     * - must not be zero address
     * - must not be the token address
     * - must not be the owner's address
     * - must not be the admin's address
     * - must not be the token offering contract address
     */
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != owner);
        require(to != address(adminAddr));
        require(to != address(tokenOfferingAddr));
        _;
    }
    
    /**
     * Token contract constructor
     *
     * @param admin Address of admin account
     */
    function DockToken(address admin) public {
        totalSupply = INITIAL_SUPPLY;
        
        // Mint tokens
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        // Approve allowance for admin account
        adminAddr = admin;
        approve(adminAddr, ADMIN_ALLOWANCE);
    }

    /**
     * Set token offering to approve allowance for offering contract to distribute tokens
     *
     * @param offeringAddr Address of token offering contract
     * @param amountForSale Amount of tokens for sale, set 0 to max out
     */
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner onlyTokenOfferingAddrNotSet {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TOKEN_OFFERING_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_OFFERING_ALLOWANCE);

        approve(offeringAddr, amount);
        tokenOfferingAddr = offeringAddr;
    }
    
    /**
     * Enable transfers
     */
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

        // End the offering
        approve(tokenOfferingAddr, 0);
    }

    /**
     * Transfer from sender to another account
     *
     * @param to Destination address
     * @param value Amount of docks to send
     */
    function transfer(address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }
    
    /**
     * Transfer from `from` account to `to` account using allowance in `from` account to the sender
     *
     * @param from Origin address
     * @param to Destination address
     * @param value Amount of docks to send
     */
    function transferFrom(address from, address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
}

contract DockCrowdsale is Pausable {
    using SafeMath for uint256;

     // Token to be sold
    Dock public token;

    // Start and end timestamps where contributions are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // Address where funds are collected
    address public beneficiary;

    // Price of the tokens as in tokens per ether
    uint256 public rate;

    // Amount of raised in Wei 
    uint256 public weiRaised;

    // Timelines for contribution limit policy
    uint256 public capReleaseTimestamp;

    uint256 public extraTime;

    // Whitelists of participant address
    mapping(address => bool) public whitelists;

    // Contributions in Wei for each participant
    mapping(address => uint256) public contributions;

    // Funding cap in ETH. 
    uint256 public constant FUNDING_ETH_HARD_CAP = 9123 * 1 ether;

    // Min contribution is 0.01 ether
    uint256 public minContribution = 10**16;

    // Max contribution is 1 ether
    uint256 public maxContribution = 10**18;

    //remainCap
    uint256 public remainCap;

    // The current stage of the offering
    Stages public stage;

    enum Stages { 
        Setup,
        OfferingStarted,
        OfferingEnded
    }

    event OfferingOpens(uint256 startTime, uint256 endTime);
    event OfferingCloses(uint256 endTime, uint256 totalWeiRaised);
    /**
     * Event for token purchase logging
     *
     * @param purchaser Who paid for the tokens
     * @param value Weis paid for purchase
     * @return amount Amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    /**
     * Modifier that requires certain stage before executing the main function body
     *
     * @param expectedStage Value that the current stage is required to match
     */
    modifier atStage(Stages expectedStage) {
        require(stage == expectedStage);
        _;
    }

    
    /**
     * The constructor of the contract.
     * @param dockToEtherRate Number of docks per ether
     * @param beneficiaryAddr Address where funds are collected
     */
    function DockCrowdsale(
        uint256 dockToEtherRate, 
        address beneficiaryAddr, 
        address tokenAddress
    ) public {
        require(dockToEtherRate > 0);
        require(beneficiaryAddr != address(0));
        require(tokenAddress != address(0));

        token = Dock(tokenAddress);
        rate = dockToEtherRate;
        beneficiary = beneficiaryAddr;
        stage = Stages.Setup;
    }

    /**
     * Fallback function can be used to buy tokens
     */
    function () public payable {
        buy();
    }

    /**
     * Withdraw available ethers into beneficiary account, serves as a safety, should never be needed
     */
    function ownerSafeWithdrawal() external onlyOwner {
        beneficiary.transfer(this.balance);
    }

    function updateRate(uint256 dockToEtherRate) public onlyOwner atStage(Stages.Setup) {
        rate = dockToEtherRate;
    }

    /**
     * Whitelist participant address 
     * 
     * 
     * @param users Array of addresses to be whitelisted
     */
    function whitelist(address[] users) public onlyOwner {
        for (uint32 i = 0; i < users.length; i++) {
            whitelists[users[i]] = true;
        }
    }
    function whitelistRemove(address user) public onlyOwner{
      require(whitelists[user]);
      whitelists[user] = false;
    }
    /**
     * Start the offering
     *
     * @param durationInSeconds Extra duration of the offering on top of the minimum 4 hours
     */
    function startOffering(uint256 durationInSeconds) public onlyOwner atStage(Stages.Setup) {
        stage = Stages.OfferingStarted;
        startTime = now;
        capReleaseTimestamp = startTime + 5 hours;
        extraTime = capReleaseTimestamp + 7 days;
        endTime = extraTime.add(durationInSeconds);
        OfferingOpens(startTime, endTime);
    }

    /**
     * End the offering
     */
    function endOffering() public onlyOwner atStage(Stages.OfferingStarted) {
        endOfferingImpl();
    }
    
  
    /**
     * Function to invest ether to buy tokens, can be called directly or called by the fallback function
     * Only whitelisted users can buy tokens.
     *
     * @return bool Return true if purchase succeeds, false otherwise
     */
    function buy() public payable whenNotPaused atStage(Stages.OfferingStarted) returns (bool) {
        if (whitelists[msg.sender]) {
              buyTokens();
              return true;
        }
        revert();
    }

    /**
     * Function that returns whether offering has ended
     * 
     * @return bool Return true if token offering has ended
     */
    function hasEnded() public view returns (bool) {
        return now > endTime || stage == Stages.OfferingEnded;
    }

    /**
     * Modifier that validates a purchase at a tier
     * All the following has to be met:
     * - current time within the offering period
     * - valid sender address and ether value greater than 0.1
     * - total Wei raised not greater than FUNDING_ETH_HARD_CAP
     * - contribution per perticipant within contribution limit
     *
     * 
     */
    modifier validPurchase() {
        require(now >= startTime && now <= endTime && stage == Stages.OfferingStarted);
        if(now > capReleaseTimestamp) {
          maxContribution = 9123 * 1 ether;
        }
        uint256 contributionInWei = msg.value;
        address participant = msg.sender; 


        require(contributionInWei <= maxContribution.sub(contributions[participant]));
        require(participant != address(0) && contributionInWei >= minContribution && contributionInWei <= maxContribution);
        require(weiRaised.add(contributionInWei) <= FUNDING_ETH_HARD_CAP);
        
        _;
    }


    function buyTokens() internal validPurchase {
      
        uint256 contributionInWei = msg.value;
        address participant = msg.sender;

        // Calculate token amount to be distributed
        uint256 tokens = contributionInWei.mul(rate);
        
        if (!token.transferFrom(token.owner(), participant, tokens)) {
            revert();
        }

        weiRaised = weiRaised.add(contributionInWei);
        contributions[participant] = contributions[participant].add(contributionInWei);

        remainCap = FUNDING_ETH_HARD_CAP.sub(weiRaised);

        
        // Check if the funding cap has been reached, end the offering if so
        if (weiRaised >= FUNDING_ETH_HARD_CAP) {
            endOfferingImpl();
        }
        
        // Transfer funds to beneficiary
        beneficiary.transfer(contributionInWei);
        TokenPurchase(msg.sender, contributionInWei, tokens);       
    }


    /**
     * End token offering by set the stage and endTime
     */
    function endOfferingImpl() internal {
        endTime = now;
        stage = Stages.OfferingEnded;
        OfferingCloses(endTime, weiRaised);
    }

    /**
     * Allocate tokens for presale participants before public offering, can only be executed at Stages.Setup stage.
     *
     * @param to Participant address to send docks to
     * @param tokens Amount of docks to be sent to parcitipant 
     */
    function allocateTokensBeforeOffering(address to, uint256 tokens) public onlyOwner atStage(Stages.Setup) returns (bool) {
        if (!token.transferFrom(token.owner(), to, tokens)) {
            revert();
        }
        return true;
    }
    
    /**
     * Bulk version of allocateTokensBeforeOffering
     */
    function batchAllocateTokensBeforeOffering(address[] toList, uint256[] tokensList) external onlyOwner  atStage(Stages.Setup)  returns (bool)  {
        require(toList.length == tokensList.length);

        for (uint32 i = 0; i < toList.length; i++) {
            allocateTokensBeforeOffering(toList[i], tokensList[i]);
        }
        return true;
    }

}