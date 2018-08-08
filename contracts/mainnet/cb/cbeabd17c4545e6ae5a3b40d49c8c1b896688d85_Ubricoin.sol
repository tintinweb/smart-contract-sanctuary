pragma solidity 0.4.24;

contract Ownable {
    address public owner=0x28970854Bfa61C0d6fE56Cc9daAAe5271CEaEC09;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor()public {
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
        owner = newOwner;
    }

}
contract PricingStrategy {

  /** Interface declaration. */
  function isPricingStrategy() public pure  returns (bool) {
    return true;
  }

  /** Self check if all references are correctly set.
   *
   * Checks that pricing strategy matches crowdsale parameters.
   */
  function isSane() public pure returns (bool) {
    return true;
  }

  /**
   * @dev Pricing tells if this is a presale purchase or not.
     @param purchaser Address of the purchaser
     @return False by default, true if a presale purchaser
   */
  function isPresalePurchase(address purchaser) public pure returns (bool) {
    return false;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction send in as wei
   * @param tokensSold - how much tokens have been sold this far
   * @param weiRaised - how much money has been raised this far in the main token sale - this number excludes presale
   * @param msgSender - who is the investor of this transaction
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public pure returns (uint tokenAmount){
      
  }
  
}
contract FinalizeAgent {

  function isFinalizeAgent() public pure returns(bool) {
    return true;
  }

  /** Return true if we can run finalizeCrowdsale() properly.
   *
   * This is a safety check function that doesn&#39;t allow crowdsale to begin
   * unless the finalizer has been set up properly.
   */
  function isSane() public pure returns (bool){
      return true;
}
  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() pure public{
     
  }
  

}
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract UbricoinPresale {

    /*/
     *  Token state
    /*/

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0; // amount of tokens already sold
    

    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager=0xAC762012330350DDd97Cc64B133536F8E32193a8;

    // Gathered funds can be withdrawn only to escrow&#39;s address.
    address public escrow=0x28970854Bfa61C0d6fE56Cc9daAAe5271CEaEC09;

    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager=0x9888375f4663891770DaaaF9286d97d44FeFC82E;

    mapping (address => uint256) private balance;


    modifier onlyTokenManager()     { if(msg.sender != tokenManager) revert(); _; }
    modifier onlyCrowdsaleManager() { if(msg.sender != crowdsaleManager) revert(); _; }


    /*/
     *  Events
    /*/

    event LogBuy(address indexed owner, uint256 value);
    event LogBurn(address indexed owner, uint256 value);
    event LogPhaseSwitch(Phase newPhase);


    /*/
     *  Public functions
    /*/

 
    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
        // Available only during migration phase
        if(currentPhase != Phase.Migrating) revert();

        uint256 tokens = balance[_owner];
        if(tokens == 0) revert();
        balance[_owner] = 0;
        
        emit LogBurn(_owner, tokens);

        // Automatically switch phase when migration is done.
       
    }

    /*/
     *  Administrative functions
    /*/

    function setPresalePhase(Phase _nextPhase) public
        onlyTokenManager
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                // switch to migration phase only if crowdsale manager is set
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                // switch to migrated only if everyting is migrated
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        if(!canSwitchPhase) revert();
        currentPhase = _nextPhase;
        emit LogPhaseSwitch(_nextPhase); 
           
    }


    function withdrawEther() public
        onlyTokenManager
    {
        // Available at any phase.
        if(address(this).balance > 0) {
            if(!escrow.send(address(this).balance)) revert();
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
        // You can&#39;t change crowdsale contract when migration is in progress.
        if(currentPhase == Phase.Migrating) revert();
        crowdsaleManager = _mgr;
    }
}
contract Haltable is Ownable  {
    
  bool public halted;
  
   modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}
contract WhitelistedCrowdsale is Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }
  
  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) onlyOwner public  {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. 
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) onlyOwner public {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary)onlyOwner public {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  
}

   contract UbricoinCrowdsale is FinalizeAgent,WhitelistedCrowdsale {
    using SafeMath for uint256;
    address public beneficiary=0x28970854Bfa61C0d6fE56Cc9daAAe5271CEaEC09;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
       
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    uint256 public investorCount = 0;
    
    bool public requiredSignedAddress;
    bool public requireCustomerId;
    

    bool public paused = false;

    
    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    
    // A new investment was made
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount, uint256 customerId);

  // The rules were changed what kind of investments we accept
    event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);
    event Pause();
    event Unpause();
 
     
 
    modifier afterDeadline() { if (now >= deadline) _; }
    

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
     
    function invest(address ) public payable {
    if(requireCustomerId) revert(); // Crowdsale needs to track partipants for thank you email
    if(requiredSignedAddress) revert(); // Crowdsale allows only server-side signed participants
   
  }
     
    function investWithCustomerId(address , uint256 customerId) public payable {
    if(requiredSignedAddress) revert(); // Crowdsale allows only server-side signed participants
    if(customerId == 0)revert();  // UUIDv4 sanity check

  }
  
    function buyWithCustomerId(uint256 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }
     
     
    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

   

    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() afterDeadline public {
        if (!fundingGoalReached) {
            uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                emit FundTransfer(beneficiary,amountRaised,false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if  (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary,amountRaised,false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
    
     /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }

}
contract Upgradeable {
    mapping(bytes4=>uint32) _sizes;
    address _dest;

    /**
     * This function is called using delegatecall from the dispatcher when the
     * target contract is first initialized. It should use this opportunity to
     * insert any return data sizes in _sizes, and perform any other upgrades
     * necessary to change over from the old contract implementation (if any).
     * 
     * Implementers of this function should either perform strictly harmless,
     * idempotent operations like setting return sizes, or use some form of
     * access control, to prevent outside callers.
     */
    function initialize() public{
        
    }
    
    /**
     * Performs a handover to a new implementing contract.
     */
    function replace(address target) internal {
        _dest = target;
        require(target.delegatecall(bytes4(keccak256("initialize()"))));
    }
}
/**
 * The dispatcher is a minimal &#39;shim&#39; that dispatches calls to a targeted
 * contract. Calls are made using &#39;delegatecall&#39;, meaning all storage and value
 * is kept on the dispatcher. As a result, when the target is updated, the new
 * contract inherits all the stored data and value from the old contract.
 */
contract Dispatcher is Upgradeable {
    
    constructor (address target) public {
        replace(target);
    }
    
    function initialize() public {
        // Should only be called by on target contracts, not on the dispatcher
        revert();
    }

    function() public {
        uint len;
        address target;
        bytes4 sig;
        assembly { sig := calldataload(0) }
        len = _sizes[sig];
        target = _dest;
        
        bool ret;
        assembly {
            // return _dest.delegatecall(msg.data)
            calldatacopy(0x0, 0x0, calldatasize)
            ret:=delegatecall(sub(gas, 10000), target, 0x0, calldatasize, 0, len)
            return(0, len)
        }
        if (!ret) revert();
    }
}
contract Example is Upgradeable {
    uint _value;
    
    function initialize() public {
        _sizes[bytes4(keccak256("getUint()"))] = 32;
    }
    
    function getUint() public view returns (uint) {
        return _value;
    }
    
    function setUint(uint value) public {
        _value = value;
    }
}
interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)external;
    
}

 /**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ubricoin is UbricoinPresale,Ownable,Haltable, UbricoinCrowdsale,Upgradeable {
    
    using SafeMath for uint256;
    
    // Public variables of the token
    string public name =&#39;Ubricoin&#39;;
    string public symbol =&#39;UBN&#39;;
    string public version= "1.0";
    uint public decimals=18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint public totalSupply = 10000000000;
    uint256 public constant RATE = 1000;
    uint256 initialSupply;

    
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    
    uint256 public AVAILABLE_AIRDROP_SUPPLY = 100000000; // 100% Released at Token distribution
    uint256 public grandTotalClaimed = 1;
    uint256 public startTime;
    
    struct Allocation {
    uint8 AllocationSupply; // Type of allocation
    uint256 totalAllocated; // Total tokens allocated
    uint256 amountClaimed;  // Total tokens claimed
}
    
    
    mapping (address => Allocation) public allocations;

    // List of admins
    mapping (address => bool) public airdropAdmins;

    // Keeps track of whether or not an Ubricoin airdrop has been made to a particular address
    mapping (address => bool) public airdrops;

  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || airdropAdmins[msg.sender]);
    _;
}
    
    
    
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

        bytes32 public currentChallenge;                         // The coin starts with a challenge
        uint256 public timeOfLastProof;                             // Variable to keep track of when rewards were given
        uint256 public difficulty = 10**32;                         // Difficulty starts reasonably low

     
    function proofOfWork(uint256 nonce) public{
        bytes8 n = bytes8(keccak256(abi.encodePacked(nonce, currentChallenge)));    // Generate a random hash based on input
        require(n >= bytes8(difficulty));                   // Check if it&#39;s under the difficulty

        uint256 timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
        require(timeSinceLastProof >=  5 seconds);         // Rewards cannot be given too quickly
        balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;  // The reward to the winner grows by the minute

        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;  // Adjusts the difficulty

        timeOfLastProof = now;                              // Reset the counter
        currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1)));  // Save a hash that will be used as the next proof
    }


   function () payable public whenNotPaused {
        require(msg.value > 0);
        uint256 tokens = msg.value.mul(RATE);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        owner.transfer(msg.value);
}
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
     function transfer(address _to, uint256 _value) public {
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
	}
     
   function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balanceOf[tokenOwner];
        
}

   function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowance[tokenOwner][spender];
}
   
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
  
    function mintToken(address target, uint256 mintedAmount)private onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    function validPurchase() internal returns (bool) {
    bool lessThanMaxInvestment = msg.value <= 1000 ether; // change the value to whatever you need
    return validPurchase() && lessThanMaxInvestment;
}

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
   /**
    * @dev Add an airdrop admin
    */
  function setAirdropAdmin(address _admin, bool _isAdmin) public onlyOwner {
    airdropAdmins[_admin] = _isAdmin;
  }

  /**
    * @dev perform a transfer of allocations
    * @param _recipient is a list of recipients
    */
  function airdropTokens(address[] _recipient) public onlyOwnerOrAdmin {
    
    uint airdropped;
    for(uint256 i = 0; i< _recipient.length; i++)
    {
        if (!airdrops[_recipient[i]]) {
          airdrops[_recipient[i]] = true;
          Ubricoin.transfer(_recipient[i], 1 * decimals);
          airdropped = airdropped.add(1 * decimals);
        }
    }
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
    totalSupply = totalSupply.sub(airdropped);
    grandTotalClaimed = grandTotalClaimed.add(airdropped);
}
    
}