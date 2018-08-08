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


// This is an ERC-20 token contract based on Open Zepplin&#39;s StandardToken
// and MintableToken plus the ability to burn tokens.
//
// We had to copy over the code instead of inheriting because of changes
// to the modifier lists of some functions:
//   * transfer(), transferFrom() and approve() are not callable during
//     the minting period, only after MintingFinished()
//   * mint() can only be called by the minter who is not the owner
//     but the HoloTokenSale contract.
//
// Token can be burned by a special &#39;destroyer&#39; role that can only
// burn its tokens.
contract HoloToken is Ownable {
  string public constant name = "HoloToken";
  string public constant symbol = "HOT";
  uint8 public constant decimals = 18;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintingFinished();
  event Burn(uint256 amount);

  uint256 public totalSupply;


  //==================================================================================
  // Zeppelin BasicToken (plus modifier to not allow transfers during minting period):
  //==================================================================================

  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenMintingFinished returns (bool) {
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


  //=====================================================================================
  // Zeppelin StandardToken (plus modifier to not allow transfers during minting period):
  //=====================================================================================
  mapping (address => mapping (address => uint256)) public allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenMintingFinished returns (bool) {
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
  function approve(address _spender, uint256 _value) public whenMintingFinished returns (bool) {
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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


  //=====================================================================================
  // Minting:
  //=====================================================================================

  bool public mintingFinished = false;
  address public destroyer;
  address public minter;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier whenMintingFinished() {
    require(mintingFinished);
    _;
  }

  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }

  function mint(address _to, uint256 _amount) external onlyMinter canMint  returns (bool) {
    require(balances[_to] + _amount > balances[_to]); // Guard against overflow
    require(totalSupply + _amount > totalSupply);     // Guard against overflow  (this should never happen)
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() external onlyMinter returns (bool) {
    mintingFinished = true;
    MintingFinished();
    return true;
  }


  //=====================================================================================
  // Burning:
  //=====================================================================================


  modifier onlyDestroyer() {
     require(msg.sender == destroyer);
     _;
  }

  function setDestroyer(address _destroyer) external onlyOwner {
    destroyer = _destroyer;
  }

  function burn(uint256 _amount) external onlyDestroyer {
    require(balances[destroyer] >= _amount && _amount > 0);
    balances[destroyer] = balances[destroyer].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    Burn(_amount);
  }
}


// This contract holds a mapping of known funders with:
// * a boolean flag for whitelist status
// * number of reserved tokens for each day
contract HoloWhitelist is Ownable {
  address public updater;

  struct KnownFunder {
    bool whitelisted;
    mapping(uint => uint256) reservedTokensPerDay;
  }

  mapping(address => KnownFunder) public knownFunders;

  event Whitelisted(address[] funders);
  event ReservedTokensSet(uint day, address[] funders, uint256[] reservedTokens);

  modifier onlyUpdater {
    require(msg.sender == updater);
    _;
  }

  function HoloWhitelist() public {
    updater = msg.sender;
  }

  function setUpdater(address new_updater) external onlyOwner {
    updater = new_updater;
  }

  // Adds funders to the whitelist in batches.
  function whitelist(address[] funders) external onlyUpdater {
    for (uint i = 0; i < funders.length; i++) {
        knownFunders[funders[i]].whitelisted = true;
    }
    Whitelisted(funders);
  }

  // Removes funders from the whitelist in batches.
  function unwhitelist(address[] funders) external onlyUpdater {
    for (uint i = 0; i < funders.length; i++) {
        knownFunders[funders[i]].whitelisted = false;
    }
  }

  // Stores reserved tokens for several funders in a batch
  // but all for the same day.
  // * day is 0-based
  function setReservedTokens(uint day, address[] funders, uint256[] reservedTokens) external onlyUpdater {
    for (uint i = 0; i < funders.length; i++) {
        knownFunders[funders[i]].reservedTokensPerDay[day] = reservedTokens[i];
    }
    ReservedTokensSet(day, funders, reservedTokens);
  }

  // Used in HoloSale to check if funder is allowed
  function isWhitelisted(address funder) external view returns (bool) {
    return knownFunders[funder].whitelisted;
  }

  // Used in HoloSale to get reserved tokens per funder
  // and per day.
  // * day is 0-based
  function reservedTokens(address funder, uint day) external view returns (uint256) {
    return knownFunders[funder].reservedTokensPerDay[day];
  }


}


// This contract is a crowdsale based on Zeppelin&#39;s Crowdsale.sol but with
// several changes:
//   * the token contract as well as the supply contract get injected
//     with setTokenContract() and setSupplyContract()
//   * we have a dynamic token supply per day which we hold in the statsByDay
//   * once per day, the *updater* role runs the update function to make the
//     contract read the new supply and switch to the next day
//   * we have a minimum amount in ETH per transaction
//   * we have a maximum amount per transaction relative to the daily supply
//
//
contract HoloSale is Ownable, Pausable{
  using SafeMath for uint256;

  // Start and end block where purchases are allowed (both inclusive)
  uint256 public startBlock;
  uint256 public endBlock;
  // Factor between wei and full Holo tokens.
  // (i.e. a rate of 10^18 means one Holo per Ether)
  uint256 public rate;
  // Ratio of the current supply a transaction is allowed to by
  uint256 public maximumPercentageOfDaysSupply;
  // Minimum amount of wei a transaction has to send
  uint256 public minimumAmountWei;
  // address where funds are being send to on successful buy
  address public wallet;

  // The token being minted on sale
  HoloToken private tokenContract;
  // The contract to check beneficiaries&#39; address against
  // and to hold number of reserved tokens per day
  HoloWhitelist private whitelistContract;

  // The account that is allowed to call update()
  // which will happen once per day during the sale period
  address private updater;

  // Will be set to true by finalize()
  bool private finalized = false;

  uint256 public totalSupply;

  // For every day of the sale we store one instance of this struct
  struct Day {
    // The supply available to sell on this day
    uint256 supply;
    // The number of unreserved tokens sold on this day
    uint256 soldFromUnreserved;
    // Number of tokens reserved today
    uint256 reserved;
    // Number of reserved tokens sold today
    uint256 soldFromReserved;
    // We are storing how much fuel each user has bought per day
    // to be able to apply our relative cap per user per day
    // (i.e. nobody is allowed to buy more than 10% of each day&#39;s supply)
    mapping(address => uint256) fuelBoughtByAddress;
  }

  // Growing list of days
  Day[] public statsByDay;

  event CreditsCreated(address beneficiary, uint256 amountWei, uint256 amountHolos);
  event Update(uint256 newTotalSupply, uint256 reservedTokensNextDay);

  modifier onlyUpdater {
    require(msg.sender == updater);
    _;
  }

  // Converts wei to smallest fraction of Holo tokens.
  // &#39;rate&#39; is meant to give the factor between weis and full Holo tokens,
  // hence the division by 10^18.
  function holosForWei(uint256 amountWei) internal view returns (uint256) {
    return amountWei * rate / 1000000000000000000;
  }

  // Contstructor takes start and end block of the sale period,
  // the rate that defines how many full Holo token are being minted per wei
  // (since the Holo token has 18 decimals, 1000000000000000000 would mean that
  // one full Holo is minted per Ether),
  // minimum and maximum limits for incoming ETH transfers
  // and the wallet to which the Ethers are being transfered on updated()
  function HoloSale(
    uint256 _startBlock, uint256 _endBlock,
    uint256 _rate,
    uint256 _minimumAmountWei, uint256 _maximumPercentageOfDaysSupply,
    address _wallet) public
  {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_rate > 0);
    require(_wallet != 0x0);

    updater = msg.sender;
    startBlock = _startBlock;
    endBlock = _endBlock;
    rate = _rate;
    maximumPercentageOfDaysSupply = _maximumPercentageOfDaysSupply;
    minimumAmountWei = _minimumAmountWei;
    wallet = _wallet;
  }

  //---------------------------------------------------------------------------
  // Setters and Getters:
  //---------------------------------------------------------------------------

  function setUpdater(address _updater) external onlyOwner {
    updater = _updater;
  }

  function setTokenContract(HoloToken _tokenContract) external onlyOwner {
    tokenContract = _tokenContract;
  }

  function setWhitelistContract(HoloWhitelist _whitelistContract) external onlyOwner {
    whitelistContract = _whitelistContract;
  }

  function currentDay() public view returns (uint) {
    return statsByDay.length;
  }

  function todaysSupply() external view returns (uint) {
    return statsByDay[currentDay()-1].supply;
  }

  function todaySold() external view returns (uint) {
    return statsByDay[currentDay()-1].soldFromUnreserved + statsByDay[currentDay()-1].soldFromReserved;
  }

  function todayReserved() external view returns (uint) {
    return statsByDay[currentDay()-1].reserved;
  }

  function boughtToday(address beneficiary) external view returns (uint) {
    return statsByDay[currentDay()-1].fuelBoughtByAddress[beneficiary];
  }

  //---------------------------------------------------------------------------
  // Sending money / adding asks
  //---------------------------------------------------------------------------

  // Fallback function can be used to buy fuel
  function () public payable {
    buyFuel(msg.sender);
  }

  // Main function that checks all conditions and then mints fuel tokens
  // and transfers the ETH to our wallet
  function buyFuel(address beneficiary) public payable whenNotPaused{
    require(currentDay() > 0);
    require(whitelistContract.isWhitelisted(beneficiary));
    require(beneficiary != 0x0);
    require(withinPeriod());

    // Calculate how many Holos this transaction would buy
    uint256 amountOfHolosAsked = holosForWei(msg.value);

    // Get current day
    uint dayIndex = statsByDay.length-1;
    Day storage today = statsByDay[dayIndex];

    // Funders who took part in the crowdfund could have reserved tokens
    uint256 reservedHolos = whitelistContract.reservedTokens(beneficiary, dayIndex);
    // If they do, make sure to subtract what they bought already today
    uint256 alreadyBought = today.fuelBoughtByAddress[beneficiary];
    if(alreadyBought >= reservedHolos) {
      reservedHolos = 0;
    } else {
      reservedHolos = reservedHolos.sub(alreadyBought);
    }

    // Calculate if they asked more than they have reserved
    uint256 askedMoreThanReserved;
    uint256 useFromReserved;
    if(amountOfHolosAsked > reservedHolos) {
      askedMoreThanReserved = amountOfHolosAsked.sub(reservedHolos);
      useFromReserved = reservedHolos;
    } else {
      askedMoreThanReserved = 0;
      useFromReserved = amountOfHolosAsked;
    }

    if(reservedHolos == 0) {
      // If this transaction is not claiming reserved tokens
      // it has to be over the minimum.
      // (Reserved tokens must be claimable even if it would be just few)
      require(msg.value >= minimumAmountWei);
    }

    // The non-reserved tokens asked must not exceed the max-ratio
    // nor the available supply.
    require(lessThanMaxRatio(beneficiary, askedMoreThanReserved, today));
    require(lessThanSupply(askedMoreThanReserved, today));

    // Everything fine if we&#39;re here
    // Send ETH to our wallet
    wallet.transfer(msg.value);
    // Mint receipts
    tokenContract.mint(beneficiary, amountOfHolosAsked);
    // Log this sale
    today.soldFromUnreserved = today.soldFromUnreserved.add(askedMoreThanReserved);
    today.soldFromReserved = today.soldFromReserved.add(useFromReserved);
    today.fuelBoughtByAddress[beneficiary] = today.fuelBoughtByAddress[beneficiary].add(amountOfHolosAsked);
    CreditsCreated(beneficiary, msg.value, amountOfHolosAsked);
  }

  // Returns true if we are in the live period of the sale
  function withinPeriod() internal constant returns (bool) {
    uint256 current = block.number;
    return current >= startBlock && current <= endBlock;
  }

  // Returns true if amount + plus fuel bought today already is not above
  // the maximum share one could buy today
  function lessThanMaxRatio(address beneficiary, uint256 amount, Day storage today) internal view returns (bool) {
    uint256 boughtTodayBefore = today.fuelBoughtByAddress[beneficiary];
    return boughtTodayBefore.add(amount).mul(100).div(maximumPercentageOfDaysSupply) <= today.supply;
  }

  // Returns false if amount would buy more fuel than we can sell today
  function lessThanSupply(uint256 amount, Day today) internal pure returns (bool) {
    return today.soldFromUnreserved.add(amount) <= today.supply.sub(today.reserved);
  }

  //---------------------------------------------------------------------------
  // Update
  //---------------------------------------------------------------------------


  function update(uint256 newTotalSupply, uint256 reservedTokensNextDay) external onlyUpdater {
    totalSupply = newTotalSupply;
    // daysSupply is the amount of tokens (*10^18) that we can sell today
    uint256 daysSupply = newTotalSupply.sub(tokenContract.totalSupply());
    statsByDay.push(Day(daysSupply, 0, reservedTokensNextDay, 0));
    Update(newTotalSupply, reservedTokensNextDay);
  }

  //---------------------------------------------------------------------------
  // Finalize
  //---------------------------------------------------------------------------

  // Returns true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return block.number > endBlock;
  }

  // Mints a third of all tokens minted so far for the team.
  // => Team ends up with 25% of all tokens.
  // Also calls finishMinting() on the token contract which makes it
  // impossible to mint more.
  function finalize() external onlyOwner {
    require(!finalized);
    require(hasEnded());
    uint256 receiptsMinted = tokenContract.totalSupply();
    uint256 shareForTheTeam = receiptsMinted.div(3);
    tokenContract.mint(wallet, shareForTheTeam);
    tokenContract.finishMinting();
    finalized = true;
  }
}