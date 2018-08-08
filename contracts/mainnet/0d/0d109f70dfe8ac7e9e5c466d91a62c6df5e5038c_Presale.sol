pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * Based on Ownable.sol from https://github.com/OpenZeppelin/zeppelin-solidity/tree/master
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
  function transferOwnership(address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0));
    owner = newOwner;
    OwnershipTransferred(owner, newOwner);
    return true;
  }

}


pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * Based on SafeMath.sol from https://github.com/OpenZeppelin/zeppelin-solidity/tree/master
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


pragma solidity ^0.4.18;


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


pragma solidity ^0.4.18;


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



pragma solidity ^0.4.18;

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  
  // mapping of addresses with according balances
  mapping(address => uint256) balances;

  uint256 public totalSupply;

  /**
  * @dev Gets the totalSupply.
  * @return An uint256 representing the total supply of tokens.
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply;
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

pragma solidity ^0.4.18;

/**
 * @title Custom ERC20 token
 *
 * @dev Implementation and upgraded version of the basic standard token.
 */
contract CustomToken is ERC20, BasicToken, Ownable {

  mapping (address => mapping (address => uint256)) internal allowed;

  // boolean if transfers can be done
  bool public enableTransfer = true;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenTransferEnabled() {
    require(enableTransfer);
    _;
  }

  event Burn(address indexed burner, uint256 value);
  event EnableTransfer(address indexed owner, uint256 timestamp);
  event DisableTransfer(address indexed owner, uint256 timestamp);

  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) whenTransferEnabled public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * The owner can transfer tokens at will. This to implement a reward pool contract in a later phase 
   * that will transfer tokens for rewarding.
   */
  function transferFrom(address _from, address _to, uint256 _value) whenTransferEnabled public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);


    if (msg.sender!=owner) {
      require(_value <= allowed[_from][msg.sender]);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
    }  else {
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
    }

    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) whenTransferEnabled public returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender,0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /* Approves and then calls the receiving contract */
  function approveAndCallAsContract(address _spender, uint256 _value, bytes _extraData) onlyOwner public returns (bool success) {
    // check if the _spender already has some amount approved else use increase approval.
    // maybe not for exchanges
    //require((_value == 0) || (allowed[this][_spender] == 0));

    allowed[this][_spender] = _value;
    Approval(this, _spender, _value);

    //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
    //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    //it is assumed when one does this that the call *should* succeed, otherwise one would use vanilla approve instead.
    require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), this, _value, this, _extraData));
    return true;
  }

  /* 
   * Approves and then calls the receiving contract 
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) whenTransferEnabled public returns (bool success) {
    // check if the _spender already has some amount approved else use increase approval.
    // maybe not for exchanges
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
    //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    //it is assumed when one does this that the call *should* succeed, otherwise one would use vanilla approve instead.
    require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
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
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) whenTransferEnabled public returns (bool) {
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
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) whenTransferEnabled public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(address _burner, uint256 _value) onlyOwner public returns (bool) {
    require(_value <= balances[_burner]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_burner] = balances[_burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_burner, _value);
    return true;
  }
   /**
   * @dev called by the owner to enable transfers
   */
  function enableTransfer() onlyOwner public returns (bool) {
    enableTransfer = true;
    EnableTransfer(owner, now);
    return true;
  }

  /**
   * @dev called by the owner to disable tranfers
   */
  function disableTransfer() onlyOwner whenTransferEnabled public returns (bool) {
    enableTransfer = false;
    DisableTransfer(owner, now);
    return true;
  }
}

pragma solidity ^0.4.18;

/**
 * @title Identify token
 * @dev ERC20 compliant token, where all tokens are pre-assigned to the token contract.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract Identify is CustomToken {

  string public constant name = "IDENTIFY";
  string public constant symbol = "IDF"; 
  uint8 public constant decimals = 6;

  uint256 public constant INITIAL_SUPPLY = 49253333333 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives the token contract all of initial tokens.
   */
  function Identify() public {
    totalSupply = INITIAL_SUPPLY;
    balances[this] = INITIAL_SUPPLY;
    Transfer(0x0, this, INITIAL_SUPPLY);
  }

}


pragma solidity ^0.4.18;

/**
 * @title Whitelist contract
 * @dev Participants for the presale and public sale must be 
 * registered in the whitelist. Admins can add and remove 
 * participants and other admins.
 */
contract Whitelist is Ownable {
    using SafeMath for uint256;

    // a boolean to check if the presale is paused
    bool public paused = false;

    // the amount of participants in the whitelist
    uint256 public participantAmount;

    // mapping of participants
    mapping (address => bool) public isParticipant;
    
    // mapping of admins
    mapping (address => bool) public isAdmin;

    event AddParticipant(address _participant);
    event AddAdmin(address _admin, uint256 _timestamp);
    event RemoveParticipant(address _participant);
    event Paused(address _owner, uint256 _timestamp);
    event Resumed(address _owner, uint256 _timestamp);
  
    /**
    * event for claimed tokens logging
    * @param owner where tokens are sent to
    * @param claimtoken is the address of the ERC20 compliant token
    * @param amount amount of tokens sent back
    */
    event ClaimedTokens(address indexed owner, address claimtoken, uint amount);
  
    /**
     * modifier to check if the whitelist is not paused
     */
    modifier notPaused() {
        require(!paused);
        _;
    }

    /**
     * modifier to check the admin or owner runs this function
     */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || msg.sender == owner);
        _;
    }

    /**
     * fallback function to send the eth back to the sender
     */
    function () payable public {
        // give ETH back
        msg.sender.transfer(msg.value);
    }

    /**
     * constructor which adds the owner in the admin list
     */
    function Whitelist() public {
        require(addAdmin(msg.sender));
    }

    /**
     * @param _participant address of participant
     * @return true if the _participant is in the list
     */
    function isParticipant(address _participant) public view returns (bool) {
        require(address(_participant) != 0);
        return isParticipant[_participant];
    }

    /**
     * @param _participant address of participant
     * @return true if _participant is added successful
     */
    function addParticipant(address _participant) public notPaused onlyAdmin returns (bool) {
        require(address(_participant) != 0);
        require(isParticipant[_participant] == false);

        isParticipant[_participant] = true;
        participantAmount++;
        AddParticipant(_participant);
        return true;
    }

    /**
     * @param _participant address of participant
     * @return true if _participant is removed successful
     */
    function removeParticipant(address _participant) public onlyAdmin returns (bool) {
        require(address(_participant) != 0);
        require(isParticipant[_participant]);
        require(msg.sender != _participant);

        delete isParticipant[_participant];
        participantAmount--;
        RemoveParticipant(_participant);
        return true;
    }

    /**
     * @param _admin address of admin
     * @return true if _admin is added successful
     */
    function addAdmin(address _admin) public onlyAdmin returns (bool) {
        require(address(_admin) != 0);
        require(!isAdmin[_admin]);

        isAdmin[_admin] = true;
        AddAdmin(_admin, now);
        return true;
    }

    /**
     * @param _admin address of admin
     * @return true if _admin is removed successful
     */
    function removeAdmin(address _admin) public onlyAdmin returns (bool) {
        require(address(_admin) != 0);
        require(isAdmin[_admin]);
        require(msg.sender != _admin);

        delete isAdmin[_admin];
        return true;
    }

    /**
     * @notice Pauses the whitelist if there is any issue
     */
    function pauseWhitelist() public onlyAdmin returns (bool) {
        paused = true;
        Paused(msg.sender,now);
        return true;
    }

    /**
     * @notice resumes the whitelist if there is any issue
     */    
    function resumeWhitelist() public onlyAdmin returns (bool) {
        paused = false;
        Resumed(msg.sender,now);
        return true;
    }


    /**
     * @notice used to save gas
     */ 
    function addMultipleParticipants(address[] _participants ) public onlyAdmin returns (bool) {
        
        for ( uint i = 0; i < _participants.length; i++ ) {
            require(addParticipant(_participants[i]));
        }

        return true;
    }

    /**
     * @notice used to save gas. Backup function.
     */ 
    function addFiveParticipants(address participant1, address participant2, address participant3, address participant4, address participant5) public onlyAdmin returns (bool) {
        require(addParticipant(participant1));
        require(addParticipant(participant2));
        require(addParticipant(participant3));
        require(addParticipant(participant4));
        require(addParticipant(participant5));
        return true;
    }

    /**
     * @notice used to save gas. Backup function.
     */ 
    function addTenParticipants(address participant1, address participant2, address participant3, address participant4, address participant5,
     address participant6, address participant7, address participant8, address participant9, address participant10) public onlyAdmin returns (bool) 
     {
        require(addParticipant(participant1));
        require(addParticipant(participant2));
        require(addParticipant(participant3));
        require(addParticipant(participant4));
        require(addParticipant(participant5));
        require(addParticipant(participant6));
        require(addParticipant(participant7));
        require(addParticipant(participant8));
        require(addParticipant(participant9));
        require(addParticipant(participant10));
        return true;
    }

    /**
    * @notice This method can be used by the owner to extract mistakenly sent tokens to this contract.
    * @param _claimtoken The address of the token contract that you want to recover
    * set to 0 in case you want to extract ether.
    */
    function claimTokens(address _claimtoken) onlyAdmin public returns (bool) {
        if (_claimtoken == 0x0) {
            owner.transfer(this.balance);
            return true;
        }

        ERC20 claimtoken = ERC20(_claimtoken);
        uint balance = claimtoken.balanceOf(this);
        claimtoken.transfer(owner, balance);
        ClaimedTokens(_claimtoken, owner, balance);
        return true;
    }

}


pragma solidity ^0.4.18;

/**
 * @title Presale
 * @dev Presale is a base contract for managing a token presale.
 * Presales have a start and end timestamps, where investors can make
 * token purchases and the presale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. Note that the presale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Presale is Ownable {
  using SafeMath for uint256;

  // token being sold
  Identify public token;
  // address of the token being sold
  address public tokenAddress;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are forwarded
  address public wallet;

  // whitelist contract
  Whitelist public whitelist;

  // how many token units a buyer gets per ETH
  uint256 public rate = 420000;

  // amount of raised money in wei
  uint256 public weiRaised;  
  
  // amount of tokens raised
  uint256 public tokenRaised;

  // parameters for the presale:
  // maximum of wei the presale wants to raise
  uint256 public capWEI;
  // maximum of tokens the presale wants to raise
  uint256 public capTokens;
  // bonus investors get in the presale - 25%
  uint256 public bonusPercentage = 125;
  // minimum amount of wei an investor needs to send in order to get tokens
  uint256 public minimumWEI;
  // maximum amount of wei an investor can send in order to get tokens
  uint256 public maximumWEI;
  // a boolean to check if the presale is paused
  bool public paused = false;
  // a boolean to check if the presale is finalized
  bool public isFinalized = false;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value WEIs paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  /**
   * event for claimed tokens logging
   * @param owner where tokens are sent to
   * @param claimtoken is the address of the ERC20 compliant token
   * @param amount amount of tokens sent back
   */
  event ClaimedTokens(address indexed owner, address claimtoken, uint amount);
  
  /**
   * event for pause logging
   * @param owner who invoked the pause function
   * @param timestamp when the pause function is invoked
   */
  event Paused(address indexed owner, uint256 timestamp);
  
  /**
   * event for resume logging
   * @param owner who invoked the resume function
   * @param timestamp when the resume function is invoked
   */
  event Resumed(address indexed owner, uint256 timestamp);

  /**
   * modifier to check if a participant is in the whitelist
   */
  modifier isInWhitelist(address beneficiary) {
    // first check if sender is in whitelist
    require(whitelist.isParticipant(beneficiary));
    _;
  }

  /**
   * modifier to check if the presale is not paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  /**
   * modifier to check if the presale is not finalized
   */
  modifier whenNotFinalized() {
    require(!isFinalized);
    _;
  }
  /**
   * modifier to check only multisigwallet can do this operation
   */
  modifier onlyMultisigWallet() {
    require(msg.sender == wallet);
    _;
  }


  /**
   * constructor for Presale
   * @param _startTime start timestamps where investments are allowed (inclusive)
   * @param _wallet address where funds are forwarded
   * @param _token address of the token being sold
   * @param _whitelist whitelist contract address
   * @param _capETH maximum of ETH the presale wants to raise
   * @param _capTokens maximum amount of tokens the presale wants to raise
   * @param _minimumETH minimum amount of ETH an investor needs to send in order to get tokens
   * @param _maximumETH maximum amount of ETH an investor can send in order to get tokens
   */
  function Presale(uint256 _startTime, address _wallet, address _token, address _whitelist, uint256 _capETH, uint256 _capTokens, uint256 _minimumETH, uint256 _maximumETH) public {
  
    require(_startTime >= now);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_whitelist != address(0));
    require(_capETH > 0);
    require(_capTokens > 0);
    require(_minimumETH > 0);
    require(_maximumETH > 0);

    startTime = _startTime;
    endTime = _startTime.add(19 weeks);
    wallet = _wallet;
    tokenAddress = _token;
    token = Identify(_token);
    whitelist = Whitelist(_whitelist);
    capWEI = _capETH * (10 ** uint256(18));
    capTokens = _capTokens * (10 ** uint256(6));
    minimumWEI = _minimumETH * (10 ** uint256(18));
    maximumWEI = _maximumETH * (10 ** uint256(18));
  }

  /**
   * fallback function can be used to buy tokens
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) isInWhitelist(beneficiary) whenNotPaused whenNotFinalized public payable returns (bool) {
    require(beneficiary != address(0));
    require(validPurchase());
    require(!hasEnded());
    require(!isContract(msg.sender));

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);
    require(tokenRaised.add(tokens) <= capTokens);
    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokenRaised = tokenRaised.add(tokens);

    require(token.transferFrom(tokenAddress, beneficiary, tokens));
    
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
    return true;
  }

  /**
   * @return true if crowdsale event has ended
   */
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= capWEI;
    bool capTokensReached = tokenRaised >= capTokens;
    bool ended = now > endTime;
    return (capReached || capTokensReached) || ended;
  }



  /**
   * calculate the amount of tokens a participant gets for a specific weiAmount
   * @return the token amount
   */
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    // wei has 18 decimals, our token has 6 decimals -> so need for convertion
    uint256 bonusIntegrated = weiAmount.div(1000000000000).mul(rate).mul(bonusPercentage).div(100);
    return bonusIntegrated;
  }

  /**
   * send ether to the fund collection wallet
   * @return true if successful
   */
  function forwardFunds() internal returns (bool) {
    wallet.transfer(msg.value);
    return true;
  }


  /**
   * @return true if the transaction can buy tokens
   */
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool underMaximumWEI = msg.value <= maximumWEI;
    bool withinCap = weiRaised.add(msg.value) <= capWEI;
    bool minimumWEIReached;
    // check to fill in last gap
    if ( capWEI.sub(weiRaised) < minimumWEI) {
      minimumWEIReached = true;
    } else {
      minimumWEIReached = msg.value >= minimumWEI;
    }
    return (withinPeriod && nonZeroPurchase) && (withinCap && (minimumWEIReached && underMaximumWEI));
  }

  /**
   * @dev Allows the multisigwallet to transfer control of the Identify Token to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnershipToken(address newOwner) onlyMultisigWallet public returns (bool) {
    require(token.transferOwnership(newOwner));
    return true;
  }

   /**
   * Overwrite method of Ownable
   * @dev Allows the multisigwallet to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyMultisigWallet public returns (bool) {
    require(newOwner != address(0));
    owner = newOwner;
    OwnershipTransferred(owner, newOwner);
    return true;
  }

   /**
   * @dev Finalize the presale.
   */  
   function finalize() onlyMultisigWallet whenNotFinalized public returns (bool) {
    require(hasEnded());

    // check if cap is reached
    if (!(capWEI == weiRaised)) {
      // calculate remaining tokens
      uint256 remainingTokens = capTokens.sub(tokenRaised);
      // burn remaining tokens
      require(token.burn(tokenAddress, remainingTokens));    
    }
    require(token.transferOwnership(wallet));
    isFinalized = true;
    return true;
  }

  ////////////////////////
  /// SAFETY FUNCTIONS ///
  ////////////////////////

  /**
   * @dev Internal function to determine if an address is a contract
   * @param _addr The address being queried
   * @return True if `_addr` is a contract
   */
  function isContract(address _addr) constant internal returns (bool) {
    if (_addr == 0) { 
      return false; 
    }
    uint256 size;
    assembly {
        size := extcodesize(_addr)
     }
    return (size > 0);
  }


  /**
   * @notice This method can be used by the owner to extract mistakenly sent tokens to this contract.
   * @param _claimtoken The address of the token contract that you want to recover
   * set to 0 in case you want to extract ether.
   */
  function claimTokens(address _claimtoken) onlyOwner public returns (bool) {
    if (_claimtoken == 0x0) {
      owner.transfer(this.balance);
      return true;
    }

    ERC20 claimtoken = ERC20(_claimtoken);
    uint balance = claimtoken.balanceOf(this);
    claimtoken.transfer(owner, balance);
    ClaimedTokens(_claimtoken, owner, balance);
    return true;
  }

  /**
   * @notice Pauses the presale if there is an issue
   */
  function pausePresale() onlyOwner public returns (bool) {
    paused = true;
    Paused(owner, now);
    return true;
  }

  /**
   * @notice Resumes the presale
   */  
  function resumePresale() onlyOwner public returns (bool) {
    paused = false;
    Resumed(owner, now);
    return true;
  }


}