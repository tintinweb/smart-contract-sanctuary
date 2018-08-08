pragma solidity ^0.4.18;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function () public payable {
    revert();
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

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  event SaleAgentUpdated(address currentSaleAgent);

  bool public mintingFinished = false;

  address public saleAgent;

  modifier notLocked() {
    require(msg.sender == owner || msg.sender == saleAgent || mintingFinished);
    _;
  }

  function setSaleAgent(address newSaleAgnet) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
    SaleAgentUpdated(saleAgent);
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(msg.sender == saleAgent && !mintingFinished);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked returns (bool) {
    return super.transferFrom(from, to, value);
  }
  
}

contract StagedCrowdsale is Pausable {

  using SafeMath for uint;

  //Structure of stage information 
  struct Stage {
    uint hardcap;
    uint price;
    uint invested;
    uint closed;
  }

  //start date of sale
  uint public start;

  //period in days of sale
  uint public period;

  //sale&#39;s hardcap
  uint public totalHardcap;
 
  //total invested so far in the sale in wei
  uint public totalInvested;

  //sale&#39;s softcap
  uint public softcap;

  //sale&#39;s stages
  Stage[] public stages;

  event MilestoneAdded(uint hardcap, uint price);

  modifier saleIsOn() {
    require(stages.length > 0 && now >= start && now < lastSaleDate());
    _;
  }

  modifier saleIsFinished() {
    require(totalInvested >= softcap || now > lastSaleDate());
    _;
  }
  
  modifier isUnderHardcap() {
    require(totalInvested <= totalHardcap);
    _;
  }

  modifier saleIsUnsuccessful() {
    require(totalInvested < softcap || now > lastSaleDate());
    _;
  }

  /**
    * counts current sale&#39;s stages
    */
  function stagesCount() public constant returns(uint) {
    return stages.length;
  }

  /**
    * sets softcap
    * @param newSoftcap new softcap
    */
  function setSoftcap(uint newSoftcap) public onlyOwner {
    require(newSoftcap > 0);
    softcap = newSoftcap.mul(1 ether);
  }

  /**
    * sets start date
    * @param newStart new softcap
    */
  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  /**
    * sets period of sale
    * @param newPeriod new period of sale
    */
  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  /**
    * adds stage to sale
    * @param hardcap stage&#39;s hardcap in ethers
    * @param price stage&#39;s price
    */
  function addStage(uint hardcap, uint price) public onlyOwner {
    require(hardcap > 0 && price > 0);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    stages.push(stage);
    totalHardcap = totalHardcap.add(stage.hardcap);
    MilestoneAdded(hardcap, price);
  }

  /**
    * removes stage from sale
    * @param number index of item to delete
    */
  function removeStage(uint8 number) public onlyOwner {
    require(number >= 0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);    
    delete stages[number];
    for (uint i = number; i < stages.length - 1; i++) {
      stages[i] = stages[i+1];
    }
    stages.length--;
  }

  /**
    * updates stage
    * @param number index of item to update
    * @param hardcap stage&#39;s hardcap in ethers
    * @param price stage&#39;s price
    */
  function changeStage(uint8 number, uint hardcap, uint price) public onlyOwner {
    require(number >= 0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);    
    stage.hardcap = hardcap.mul(1 ether);
    stage.price = price;
    totalHardcap = totalHardcap.add(stage.hardcap);    
  }

  /**
    * inserts stage
    * @param numberAfter index to insert
    * @param hardcap stage&#39;s hardcap in ethers
    * @param price stage&#39;s price
    */
  function insertStage(uint8 numberAfter, uint hardcap, uint price) public onlyOwner {
    require(numberAfter < stages.length);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    totalHardcap = totalHardcap.add(stage.hardcap);
    stages.length++;
    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }
    stages[numberAfter + 1] = stage;
  }

  /**
    * deletes all stages
    */
  function clearStages() public onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    totalHardcap = 0;
  }

  /**
    * calculates last sale date
    */
  function lastSaleDate() public constant returns(uint) {
    return start + period * 1 days;
  }  

  /**
    * returns index of current stage
    */
  function currentStage() public saleIsOn isUnderHardcap constant returns(uint) {
    for(uint i = 0; i < stages.length; i++) {
      if(stages[i].closed == 0) {
        return i;
      }
    }
    revert();
  }

}

contract CommonSale is StagedCrowdsale {

  //Our MYTC token
  MYTCToken public token;  

  //slave wallet percentage
  uint public slaveWalletPercent = 50;

  //total percent rate
  uint public percentRate = 100;

  //min investment value in wei
  uint public minInvestment;
  
  //bool to check if wallet is initialized
  bool public slaveWalletInitialized;

  //bool to check if wallet percentage is initialized
  bool public slaveWalletPercentInitialized;

  //master wallet address
  address public masterWallet;

  //slave wallet address
  address public slaveWallet;
  
  //Agent for direct minting
  address public directMintAgent;

  // How much ETH each address has invested in crowdsale
  mapping (address => uint256) public investedAmountOf;

  // How much tokens crowdsale has credited for each investor address
  mapping (address => uint256) public tokenAmountOf;

  // Crowdsale contributors
  mapping (uint => address) public contributors;

  // Crowdsale unique contributors number
  uint public uniqueContributors;  

  /**
      * event for token purchases logging
      * @param purchaser who paid for the tokens
      * @param value weis paid for purchase
      * @param purchaseDate time of log
      */
  event TokenPurchased(address indexed purchaser, uint256 value, uint256 purchaseDate);

  /**
      * event for token mint logging
      * @param to tokens destination
      * @param tokens minted
      * @param mintedDate time of log
      */
  event TokenMinted(address to, uint tokens, uint256 mintedDate);

  /**
      * event for token refund
      * @param investor refunded account address
      * @param amount weis refunded
      * @param returnDate time of log
      */
  event InvestmentReturned(address indexed investor, uint256 amount, uint256 returnDate);
  
  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }  

  /**
    * sets MYTC token
    * @param newToken new token
    */
  function setToken(address newToken) public onlyOwner {
    token = MYTCToken(newToken);
  }

  /**
    * sets minimum investement threshold
    * @param newMinInvestment new minimum investement threshold
    */
  function setMinInvestment(uint newMinInvestment) public onlyOwner {
    minInvestment = newMinInvestment;
  }  

  /**
    * sets master wallet address
    * @param newMasterWallet new master wallet address
    */
  function setMasterWallet(address newMasterWallet) public onlyOwner {
    masterWallet = newMasterWallet;
  }

  /**
    * sets slave wallet address
    * @param newSlaveWallet new slave wallet address
    */
  function setSlaveWallet(address newSlaveWallet) public onlyOwner {
    require(!slaveWalletInitialized);
    slaveWallet = newSlaveWallet;
    slaveWalletInitialized = true;
  }

  /**
    * sets slave wallet percentage
    * @param newSlaveWalletPercent new wallet percentage
    */
  function setSlaveWalletPercent(uint newSlaveWalletPercent) public onlyOwner {
    require(!slaveWalletPercentInitialized);
    slaveWalletPercent = newSlaveWalletPercent;
    slaveWalletPercentInitialized = true;
  }

  /**
    * sets direct mint agent
    * @param newDirectMintAgent new agent
    */
  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }  

  /**
    * mints directly from network
    * @param to invesyor&#39;s adress to transfer the minted tokens to
    * @param investedWei number of wei invested
    */
  function directMint(address to, uint investedWei) public onlyDirectMintAgentOrOwner saleIsOn {
    calculateAndMintTokens(to, investedWei);
    TokenPurchased(to, investedWei, now);
  }

  /**
    * splits investment into master and slave wallets for security reasons
    */
  function createTokens() public whenNotPaused payable {
    require(msg.value >= minInvestment);
    uint masterValue = msg.value.mul(percentRate.sub(slaveWalletPercent)).div(percentRate);
    uint slaveValue = msg.value.sub(masterValue);
    masterWallet.transfer(masterValue);
    slaveWallet.transfer(slaveValue);
    calculateAndMintTokens(msg.sender, msg.value);
    TokenPurchased(msg.sender, msg.value, now);
  }

  /**
    * Calculates and records contributions
    * @param to invesyor&#39;s adress to transfer the minted tokens to
    * @param weiInvested number of wei invested
    */
  function calculateAndMintTokens(address to, uint weiInvested) internal {
    //calculate number of tokens
    uint stageIndex = currentStage();
    Stage storage stage = stages[stageIndex];
    uint tokens = weiInvested.mul(stage.price);
    //if we have a new contributor
    if(investedAmountOf[msg.sender] == 0) {
        contributors[uniqueContributors] = msg.sender;
        uniqueContributors += 1;
    }
    //record contribution and tokens assigned
    investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(weiInvested);
    tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);
    //mint and update invested values
    mintTokens(to, tokens);
    totalInvested = totalInvested.add(weiInvested);
    stage.invested = stage.invested.add(weiInvested);
    //check if cap of staged is reached
    if(stage.invested >= stage.hardcap) {
      stage.closed = now;
    }
  }

  /**
    * Mint tokens
    * @param to adress destination to transfer the tokens to
    * @param tokens number of tokens to mint and transfer
    */
  function mintTokens(address to, uint tokens) internal {
    token.mint(this, tokens);
    token.transfer(to, tokens);
    TokenMinted(to, tokens, now);
  }

  /**
    * Payable function
    */
  function() external payable {
    createTokens();
  }
  
  /**
    * Function to retrieve and transfer back external tokens
    * @param anotherToken external token received
    * @param to address destination to transfer the token to
    */
  function retrieveExternalTokens(address anotherToken, address to) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

  /**
    * Function to refund funds if softcap is not reached and sale period is over 
    */
  function refund() public saleIsUnsuccessful {
    uint value = investedAmountOf[msg.sender];
    investedAmountOf[msg.sender] = 0;
    msg.sender.transfer(value);
    InvestmentReturned(msg.sender, value, now);
  }

}

contract WhiteListToken is CommonSale {

  mapping(address => bool)  public whiteList;

  modifier onlyIfWhitelisted() {
    require(whiteList[msg.sender]);
    _;
  }

  function addToWhiteList(address _address) public onlyDirectMintAgentOrOwner {
    whiteList[_address] = true;
  }

  function addAddressesToWhitelist(address[] _addresses) public onlyDirectMintAgentOrOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addToWhiteList(_addresses[i]);
    }
  }

  function deleteFromWhiteList(address _address) public onlyDirectMintAgentOrOwner {
    whiteList[_address] = false;
  }

  function deleteAddressesFromWhitelist(address[] _addresses) public onlyDirectMintAgentOrOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      deleteFromWhiteList(_addresses[i]);
    }
  }

}

contract MYTCToken is MintableToken {	
    
  //Token name
  string public constant name = "MYTC";
   
  //Token symbol
  string public constant symbol = "MYTC";
    
  //Token&#39;s number of decimals
  uint32 public constant decimals = 18;

  //Dictionary with locked accounts
  mapping (address => uint) public locked;

  /**
    * transfer for unlocked accounts
    */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(locked[msg.sender] < now);
    return super.transfer(_to, _value);
  }

  /**
    * transfer from for unlocked accounts
    */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(locked[_from] < now);
    return super.transferFrom(_from, _to, _value);
  }
  
  /**
    * locks an account for given a number of days
    * @param addr account address to be locked
    * @param periodInDays days to be locked
    */
  function lock(address addr, uint periodInDays) public {
    require(locked[addr] < now && (msg.sender == saleAgent || msg.sender == addr));
    locked[addr] = now + periodInDays * 1 days;
  }

}

contract PreTge is CommonSale {

  //TGE 
  Tge public tge;

  /**
      * event for PreTGE finalization logging
      * @param finalizer account who trigger finalization
      * @param saleEnded time of log
      */
  event PreTgeFinalized(address indexed finalizer, uint256 saleEnded);

  /**
    * sets TGE to pass agent when sale is finished
    * @param newMainsale adress of TGE contract
    */
  function setMainsale(address newMainsale) public onlyOwner {
    tge = Tge(newMainsale);
  }

  /**
    * sets TGE as new sale agent when sale is finished
    */
  function setTgeAsSaleAgent() public whenNotPaused saleIsFinished onlyOwner {
    token.setSaleAgent(tge);
    PreTgeFinalized(msg.sender, now);
  }
}


contract Tge is WhiteListToken {

  //Team wallet address
  address public teamTokensWallet;
  
  //Bounty and advisors wallet address
  address public bountyTokensWallet;

  //Reserved tokens wallet address
  address public reservedTokensWallet;
  
  //Team percentage
  uint public teamTokensPercent;
  
  //Bounty and advisors percentage
  uint public bountyTokensPercent;

  //Reserved tokens percentage
  uint public reservedTokensPercent;
  
  //Lock period in days for team&#39;s wallet
  uint public lockPeriod;  

  //maximum amount of tokens ever minted
  uint public totalTokenSupply;

  /**
      * event for TGE finalization logging
      * @param finalizer account who trigger finalization
      * @param saleEnded time of log
      */
  event TgeFinalized(address indexed finalizer, uint256 saleEnded);

  /**
    * sets lock period in days for team&#39;s wallet
    * @param newLockPeriod new lock period in days
    */
  function setLockPeriod(uint newLockPeriod) public onlyOwner {
    lockPeriod = newLockPeriod;
  }

  /**
    * sets percentage for team&#39;s wallet
    * @param newTeamTokensPercent new percentage for team&#39;s wallet
    */
  function setTeamTokensPercent(uint newTeamTokensPercent) public onlyOwner {
    teamTokensPercent = newTeamTokensPercent;
  }

  /**
    * sets percentage for bounty&#39;s wallet
    * @param newBountyTokensPercent new percentage for bounty&#39;s wallet
    */
  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }

  /**
    * sets percentage for reserved wallet
    * @param newReservedTokensPercent new percentage for reserved wallet
    */
  function setReservedTokensPercent(uint newReservedTokensPercent) public onlyOwner {
    reservedTokensPercent = newReservedTokensPercent;
  }
  
  /**
    * sets max number of tokens to ever mint
    * @param newTotalTokenSupply max number of tokens (incl. 18 dec points)
    */
  function setTotalTokenSupply(uint newTotalTokenSupply) public onlyOwner {
    totalTokenSupply = newTotalTokenSupply;
  }

  /**
    * sets address for team&#39;s wallet
    * @param newTeamTokensWallet new address for team&#39;s wallet
    */
  function setTeamTokensWallet(address newTeamTokensWallet) public onlyOwner {
    teamTokensWallet = newTeamTokensWallet;
  }

  /**
    * sets address for bountys&#39;s wallet
    * @param newBountyTokensWallet new address for bountys&#39;s wallet
    */
  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

  /**
    * sets address for reserved wallet
    * @param newReservedTokensWallet new address for reserved wallet
    */
  function setReservedTokensWallet(address newReservedTokensWallet) public onlyOwner {
    reservedTokensWallet = newReservedTokensWallet;
  }

  /**
    * Mints remaining tokens and finishes minting when sale is successful
    * No further tokens will be minted ever
    */
  function endSale() public whenNotPaused saleIsFinished onlyOwner {    
    // uint remainingPercentage = bountyTokensPercent.add(teamTokensPercent).add(reservedTokensPercent);
    // uint tokensGenerated = token.totalSupply();

    uint foundersTokens = totalTokenSupply.mul(teamTokensPercent).div(percentRate);
    uint reservedTokens = totalTokenSupply.mul(reservedTokensPercent).div(percentRate);
    uint bountyTokens = totalTokenSupply.mul(bountyTokensPercent).div(percentRate); 
    mintTokens(reservedTokensWallet, reservedTokens);
    mintTokens(teamTokensWallet, foundersTokens);
    mintTokens(bountyTokensWallet, bountyTokens); 
    uint currentSupply = token.totalSupply();
    if (currentSupply < totalTokenSupply) {
      // send remaining tokens to reserved wallet
      mintTokens(reservedTokensWallet, totalTokenSupply.sub(currentSupply));
    }  
    token.lock(teamTokensWallet, lockPeriod);      
    token.finishMinting();
    TgeFinalized(msg.sender, now);
  }

    /**
    * Payable function
    */
  function() external onlyIfWhitelisted payable {
    require(now >= start && now < lastSaleDate());
    createTokens();
  }
}