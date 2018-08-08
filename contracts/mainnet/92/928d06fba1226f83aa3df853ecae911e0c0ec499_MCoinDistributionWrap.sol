pragma solidity ^0.4.24;


/** 
* MonetaryCoin Distribution 
* full source code:
* https://github.com/Monetary-Foundation/MonetaryCoin
*/

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}



/**
 * @title MineableToken
 * @dev ERC20 Token with Pos mining.
 * The blockReward_ is controlled by a GDP oracle tied to the national identity or currency union identity of the subject MonetaryCoin.
 * This type of mining will be used during both the initial distribution period and when GDP growth is positive.
 * For mining during negative growth period please refer to MineableM5Token.sol. 
 * Unlike standard erc20 token, the totalSupply is sum(all user balances) + totalStake instead of sum(all user balances).
*/
contract MineableToken is MintableToken { 
  event Commit(address indexed from, uint value,uint atStake, int onBlockReward);
  event Withdraw(address indexed from, uint reward, uint commitment);

  uint256 totalStake_ = 0;
  int256 blockReward_;         //could be positive or negative according to GDP

  struct Commitment {
    uint256 value;             // value commited to mining
    uint256 onBlockNumber;     // commitment done on block
    uint256 atStake;           // stake during commitment
    int256 onBlockReward;
  }

  mapping( address => Commitment ) miners;

  /**
  * @dev commit _value for minning
  * @notice the _value will be substructed from user balance and added to the stake.
  * if user previously commited, add to an existing commitment. 
  * this is done by calling withdraw() then commit back previous commit + reward + new commit 
  * @param _value The amount to be commited.
  * @return the commit value: _value OR prevCommit + reward + _value
  */
  function commit(uint256 _value) public returns (uint256 commitmentValue) {
    require(0 < _value);
    require(_value <= balances[msg.sender]);
    
    commitmentValue = _value;
    uint256 prevCommit = miners[msg.sender].value;
    //In case user already commited, withdraw and recommit 
    // new commitment value: prevCommit + reward + _value
    if (0 < prevCommit) {
      // withdraw Will revert if reward is negative
      uint256 prevReward;
      (prevReward, prevCommit) = withdraw();
      commitmentValue = prevReward.add(prevCommit).add(_value);
    }

    // sub will revert if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(commitmentValue);
    emit Transfer(msg.sender, address(0), commitmentValue);

    totalStake_ = totalStake_.add(commitmentValue);

    miners[msg.sender] = Commitment(
      commitmentValue, // Commitment.value
      block.number, // onBlockNumber
      totalStake_, // atStake = current stake + commitments value
      blockReward_ // onBlockReward
      );
    
    emit Commit(msg.sender, commitmentValue, totalStake_, blockReward_); // solium-disable-line

    return commitmentValue;
  }

  /**
  * @dev withdraw reward
  * @return {
    "uint256 reward": the new supply
    "uint256 commitmentValue": the commitment to be returned
    }
  */
  function withdraw() public returns (uint256 reward, uint256 commitmentValue) {
    require(miners[msg.sender].value > 0); 

    //will revert if reward is negative:
    reward = getReward(msg.sender);

    Commitment storage commitment = miners[msg.sender];
    commitmentValue = commitment.value;

    uint256 withdrawnSum = commitmentValue.add(reward);
    
    totalStake_ = totalStake_.sub(commitmentValue);
    totalSupply_ = totalSupply_.add(reward);
    
    balances[msg.sender] = balances[msg.sender].add(withdrawnSum);
    emit Transfer(address(0), msg.sender, commitmentValue.add(reward));
    
    delete miners[msg.sender];
    
    emit Withdraw(msg.sender, reward, commitmentValue);  // solium-disable-line
    return (reward, commitmentValue);
  }

  /**
  * @dev Calculate the reward if withdraw() happans on this block
  * @notice The reward is calculated by the formula:
  * (numberOfBlocks) * (effectiveBlockReward) * (commitment.value) / (effectiveStake) 
  * effectiveBlockReward is the average between the block reward during commit and the block reward during the call
  * effectiveStake is the average between the stake during the commit and the stake during call (liniar aproximation)
  * @return An uint256 representing the reward amount
  */ 
  function getReward(address _miner) public view returns (uint256) {
    if (miners[_miner].value == 0) {
      return 0;
    }

    Commitment storage commitment = miners[_miner];

    int256 averageBlockReward = signedAverage(commitment.onBlockReward, blockReward_);
    
    require(0 <= averageBlockReward);
    
    uint256 effectiveBlockReward = uint256(averageBlockReward);
    
    uint256 effectiveStake = average(commitment.atStake, totalStake_);
    
    uint256 numberOfBlocks = block.number.sub(commitment.onBlockNumber);

    uint256 miningReward = numberOfBlocks.mul(effectiveBlockReward).mul(commitment.value).div(effectiveStake);
       
    return miningReward;
  }

  /**
  * @dev Calculate the average of two integer numbers 
  * @notice 1.5 will be rounded toward zero
  * @return An uint256 representing integer average
  */
  function average(uint256 a, uint256 b) public pure returns (uint256) {
    return a.add(b).div(2);
  }

  /**
  * @dev Calculate the average of two signed integers numbers 
  * @notice 1.5 will be toward zero
  * @return An int256 representing integer average
  */
  function signedAverage(int256 a, int256 b) public pure returns (int256) {
    int256 ans = a + b;

    if (a > 0 && b > 0 && ans <= 0) {
      require(false);
    }
    if (a < 0 && b < 0 && ans >= 0) {
      require(false);
    }

    return ans / 2;
  }

  /**
  * @dev Gets the commitment of the specified address.
  * @param _miner The address to query the the commitment Of
  * @return the amount commited.
  */
  function commitmentOf(address _miner) public view returns (uint256) {
    return miners[_miner].value;
  }

  /**
  * @dev Gets the all fields for the commitment of the specified address.
  * @param _miner The address to query the the commitment Of
  * @return {
    "uint256 value": the amount commited.
    "uint256 onBlockNumber": block number of commitment.
    "uint256 atStake": stake when commited.
    "int256 onBlockReward": block reward when commited.
    }
  */
  function getCommitment(address _miner) public view 
  returns (
    uint256 value,             // value commited to mining
    uint256 onBlockNumber,     // commited on block
    uint256 atStake,           // stake during commit
    int256 onBlockReward       // block reward during commit
    ) 
  {
    value = miners[_miner].value;
    onBlockNumber = miners[_miner].onBlockNumber;
    atStake = miners[_miner].atStake;
    onBlockReward = miners[_miner].onBlockReward;
  }

  /**
  * @dev the total stake
  * @return the total stake
  */
  function totalStake() public view returns (uint256) {
    return totalStake_;
  }

  /**
  * @dev the block reward
  * @return the current block reward
  */
  function blockReward() public view returns (int256) {
    return blockReward_;
  }
}


/**
 * @title MCoinDistribution
 * @dev MCoinDistribution
 * MCoinDistribution is used to distribute a fixed amount of token per window of time.
 * Users may commit Ether to a window of their choice.
 * After a window closes, a user may withdraw their reward using the withdraw(uint256 window) function or use the withdrawAll() 
 * function to get tokens from all windows in a single transaction.
 * The amount of tokens allocated to a user for a given window equals (window allocation) * (user eth) / (total eth).
 * A user can get the details of the current window with the detailsOfWindow() function.
 * The first-period allocation is larger than second-period allocation (per window). 
 */
contract MCoinDistribution is Ownable {
  using SafeMath for uint256;

  event Commit(address indexed from, uint256 value, uint256 window);
  event Withdraw(address indexed from, uint256 value, uint256 window);
  event MoveFunds(uint256 value);

  MineableToken public MCoin;

  uint256 public firstPeriodWindows;
  uint256 public firstPeriodSupply;
 
  uint256 public secondPeriodWindows;
  uint256 public secondPeriodSupply;
  
  uint256 public totalWindows;  // firstPeriodWindows + secondPeriodSupply

  address public foundationWallet;

  uint256 public startTimestamp;
  uint256 public windowLength;         // in seconds

  mapping (uint256 => uint256) public totals;
  mapping (address => mapping (uint256 => uint256)) public commitment;
  
  constructor(
    uint256 _firstPeriodWindows,
    uint256 _firstPeriodSupply,
    uint256 _secondPeriodWindows,
    uint256 _secondPeriodSupply,
    address _foundationWallet,
    uint256 _startTimestamp,
    uint256 _windowLength
  ) public 
  {
    require(0 < _firstPeriodWindows);
    require(0 < _firstPeriodSupply);
    require(0 < _secondPeriodWindows);
    require(0 < _secondPeriodSupply);
    require(0 < _startTimestamp);
    require(0 < _windowLength);
    require(_foundationWallet != address(0));
    
    firstPeriodWindows = _firstPeriodWindows;
    firstPeriodSupply = _firstPeriodSupply;
    secondPeriodWindows = _secondPeriodWindows;
    secondPeriodSupply = _secondPeriodSupply;
    foundationWallet = _foundationWallet;
    startTimestamp = _startTimestamp;
    windowLength = _windowLength;

    totalWindows = firstPeriodWindows.add(secondPeriodWindows);
    require(currentWindow() == 0);
  }

  /**
   * @dev Commit used as a fallback
   */
  function () public payable {
    commit();
  }

  /**
  * @dev initiate the distribution
  * @param _MCoin the token to distribute
  */
  function init(MineableToken _MCoin) public onlyOwner {
    require(address(MCoin) == address(0));
    require(_MCoin.owner() == address(this));
    require(_MCoin.totalSupply() == 0);

    MCoin = _MCoin;
    MCoin.mint(address(this), firstPeriodSupply.add(secondPeriodSupply));
    MCoin.finishMinting();
  }

  /**
  * @dev return allocation for given window
  * @param window the desired window
  * @return the number of tokens to distribute in the given window
  */
  function allocationFor(uint256 window) view public returns (uint256) {
    require(window < totalWindows);
    
    return (window < firstPeriodWindows) 
      ? firstPeriodSupply.div(firstPeriodWindows) 
      : secondPeriodSupply.div(secondPeriodWindows);
  }

  /**
  * @dev Return the window number for given timestamp
  * @param timestamp 
  * @return number of the current window in [0,inf)
  * zero will be returned before distribution start and during the first window.
  */
  function windowOf(uint256 timestamp) view public returns (uint256) {
    return (startTimestamp < timestamp) 
      ? timestamp.sub(startTimestamp).div(windowLength) 
      : 0;
  }

  /**
  * @dev Return information about the selected window
  * @param window number: [0-totalWindows)
  * @return {
    "uint256 start": window start timestamp
    "uint256 end": window end timestamp
    "uint256 remainingTime": remaining time (sec), zero if ended
    "uint256 allocation": number of tokens to be distributed
    "uint256 totalEth": total eth commited this window
    "uint256 number": # of requested window
    }
  */
  function detailsOf(uint256 window) view public 
    returns (
      uint256 start,  // window start timestamp
      uint256 end,    // window end timestamp
      uint256 remainingTime, // remaining time (sec), zero if ended
      uint256 allocation,    // number of tokens to be distributed
      uint256 totalEth,      // total eth commited this window
      uint256 number         // # of requested window
    ) 
    {
    require(window < totalWindows);
    start = startTimestamp.add(windowLength.mul(window));
    end = start.add(windowLength);
    remainingTime = (block.timestamp < end) // solium-disable-line
      ? end.sub(block.timestamp)            // solium-disable-line
      : 0; 

    allocation = allocationFor(window);
    totalEth = totals[window];
    return (start, end, remainingTime, allocation, totalEth, window);
  }

  /**
  * @dev Return information for the current window
  * @return {
    "uint256 start": window start timestamp
    "uint256 end": window end timestamp
    "uint256 remainingTime": remaining time (sec), zero if ended
    "uint256 allocation": number of tokens to be distributed
    "uint256 totalEth": total eth commited this window
    "uint256 number": # of requested window
    }
  */
  function detailsOfWindow() view public
    returns (
      uint256 start,  // window start timestamp
      uint256 end,    // window end timestamp
      uint256 remainingTime, // remaining time (sec), zero if ended
      uint256 allocation,    // number of tokens to be distributed
      uint256 totalEth,      // total eth commited this window
      uint256 number         // current window
    )
  {
    return (detailsOf(currentWindow()));
  }

  /**
  * @dev return the number of the current window
  * @return the window, range: [0-totalWindows)
  */
  function currentWindow() view public returns (uint256) {
    return windowOf(block.timestamp); // solium-disable-line
  }

  /**
  * @dev commit funds for a given window
  * Tokens for commited window need to be withdrawn after
  * window closes using withdraw(uint256 window) function
  * first window: 0
  * last window: totalWindows - 1
  * @param window to commit [0-totalWindows)
  */
  function commitOn(uint256 window) public payable {
    // Distribution didn&#39;t ended
    require(currentWindow() < totalWindows);
    // Commit only for present or future windows
    require(currentWindow() <= window);
    // Don&#39;t commit after distribution is finished
    require(window < totalWindows);
    // Minimum commitment
    require(0.01 ether <= msg.value);

    // Add commitment for user on given window
    commitment[msg.sender][window] = commitment[msg.sender][window].add(msg.value);
    // Add to window total
    totals[window] = totals[window].add(msg.value);
    // Log
    emit Commit(msg.sender, msg.value, window);
  }

  /**
  * @dev commit funds for the current window
  */
  function commit() public payable {
    commitOn(currentWindow());
  }
  
  /**
  * @dev Withdraw tokens after the window has closed
  * @param window to withdraw 
  * @return the calculated number of tokens
  */
  function withdraw(uint256 window) public returns (uint256 reward) {
    // Requested window already been closed
    require(window < currentWindow());
    // The sender hasn&#39;t made a commitment for requested window
    if (commitment[msg.sender][window] == 0) {
      return 0;
    }

    // The Price for given window is allocation / total_commitment
    // uint256 price = allocationFor(window).div(totals[window]);
    // The reward is price * commitment
    // uint256 reward = price.mul(commitment[msg.sender][window]);
    
    // Same calculation optimized for accuracy (without the .div rounding for price calculation):
    reward = allocationFor(window).mul(commitment[msg.sender][window]).div(totals[window]);
    
    // Init the commitment
    commitment[msg.sender][window] = 0;
    // Transfer the tokens
    MCoin.transfer(msg.sender, reward);
    // Log
    emit Withdraw(msg.sender, reward, window);
    return reward;
  }

  /**
  * @dev get the reward from all closed windows
  */
  function withdrawAll() public {
    for (uint256 i = 0; i < currentWindow(); i++) {
      withdraw(i);
    }
  }

  /**
  * @dev returns a array which contains reward for every closed window
  * a convinience function to be called for updating a GUI. 
  * To get the reward tokens use withdrawAll(), which consumes less gas.
  * @return uint256[] rewards - the calculated number of tokens for every closed window
  */
  function getAllRewards() public view returns (uint256[]) {
    uint256[] memory rewards = new uint256[](totalWindows);
    // lastClosedWindow = min(currentWindow(),totalWindows);
    uint256 lastWindow = currentWindow() < totalWindows ? currentWindow() : totalWindows;
    for (uint256 i = 0; i < lastWindow; i++) {
      rewards[i] = withdraw(i);
    }
    return rewards;
  }

  /**
  * @dev returns a array filled with commitments of address for every window
  * a convinience function to be called for updating a GUI. 
  * @return uint256[] commitments - the commited Eth per window of a given address
  */
  function getCommitmentsOf(address from) public view returns (uint256[]) {
    uint256[] memory commitments = new uint256[](totalWindows);
    for (uint256 i = 0; i < totalWindows; i++) {
      commitments[i] = commitment[from][i];
    }
    return commitments;
  }

  /**
  * @dev returns a array filled with eth totals for every window
  * a convinience function to be called for updating a GUI. 
  * @return uint256[] ethTotals - the totals for commited Eth per window
  */
  function getTotals() public view returns (uint256[]) {
    uint256[] memory ethTotals = new uint256[](totalWindows);
    for (uint256 i = 0; i < totalWindows; i++) {
      ethTotals[i] = totals[i];
    }
    return ethTotals;
  }

  /**
  * @dev moves Eth to the foundation wallet.
  * @return the amount to be moved.
  */
  function moveFunds() public onlyOwner returns (uint256 value) {
    value = address(this).balance;
    require(0 < value);

    foundationWallet.transfer(value);
    
    emit MoveFunds(value);
    return value;
  }
}



/**
 * @title MCoinDistributionWrap
 * @dev MCoinDistribution wrapper contract.
 * This contracts wraps MCoinDistribution.sol and is used to create the distribution contract. 
 * See MCoinDistribution.sol for full distribution details.
 */
contract MCoinDistributionWrap is MCoinDistribution {
  using SafeMath for uint256;
  
  uint8 public constant decimals = 18;  // solium-disable-line uppercase

  constructor(
    uint256 firstPeriodWindows,
    uint256 firstPeriodSupply,
    uint256 secondPeriodWindows,
    uint256 secondPeriodSupply,
    address foundationWallet,
    uint256 startTime,
    uint256 windowLength
    )
    MCoinDistribution (
      firstPeriodWindows,              // uint _firstPeriodWindows
      toDecimals(firstPeriodSupply),   // uint _firstPeriodSupply,
      secondPeriodWindows,             // uint _secondPeriodDays,
      toDecimals(secondPeriodSupply),  // uint _secondPeriodSupply,
      foundationWallet,                // address _foundationMultiSig,
      startTime,                       // uint _startTime
      windowLength                     // uint _windowLength
    ) public 
  {}    

  function toDecimals(uint256 _value) pure internal returns (uint256) {
    return _value.mul(10 ** uint256(decimals));
  }
}