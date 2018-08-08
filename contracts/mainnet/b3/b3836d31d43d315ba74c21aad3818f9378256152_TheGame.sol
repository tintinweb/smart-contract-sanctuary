pragma solidity ^0.4.18;

/**
* Ponzi Trust Pyramid Game Smart Contracts 
* Code is published on https://github.com/PonziTrust/PyramidGame
* Ponzi Trust https://ponzitrust.com/
*/

// contract to store all info about players 
contract PlayersStorage {
  struct Player {
    uint256 input; 
    uint256 timestamp;
    bool exist;
  }
  mapping (address => Player) private m_players;
  address private m_owner;
    
  modifier onlyOwner() {
    require(msg.sender == m_owner);
    _;
  }
  
  function PlayersStorage() public {
    m_owner = msg.sender;  
  }

  // http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function 
  // Contracts that receive Ether directly (without a function call, i.e. using send 
  // or transfer) but do not define a fallback function throw an exception, 
  // sending back the Ether (this was different before Solidity v0.4.0).
  // function() payable { revert(); }


  /**
  * @dev Try create new player in storage.
  * @param addr Adrress of player.
  * @param input Input of player.
  * @param timestamp Timestamp of player.
  */
  function newPlayer(address addr, uint256 input, uint256 timestamp) 
    public 
    onlyOwner() 
    returns(bool)
  {
    if (m_players[addr].exist) {
      return false;
    }
    m_players[addr].input = input;
    m_players[addr].timestamp = timestamp;
    m_players[addr].exist = true;
    return true;
  }
  
  /**
  * @dev Delet specified player from storage.
  * @param addr Adrress of specified player.
  */
  function deletePlayer(address addr) public onlyOwner() {
    delete m_players[addr];
  }
  
  /**
  * @dev Get info about specified player.
  * @param addr Adrress of specified player.
  * @return input Input of specified player.
  * @return timestamp Timestamp of specified player.
  * @return exist Whether specified player in storage or not.
  */
  function playerInfo(address addr) 
    public
    view
    onlyOwner() 
    returns(uint256 input, uint256 timestamp, bool exist) 
  {
    input = m_players[addr].input;
    timestamp = m_players[addr].timestamp;
    exist = m_players[addr].exist;
  }
  
  /**
  * @dev Get input of specified player.
  * @param addr Adrress of specified player.
  * @return input Input of specified player.
  */
  function playerInput(address addr) 
    public
    view
    onlyOwner() 
    returns(uint256 input) 
  {
    input = m_players[addr].input;
  }
  
  /**
  * @dev Get whether specified player in storage or not.
  * @param addr Adrress of specified player.
  * @return exist Whether specified player in storage or not.
  */
  function playerExist(address addr) 
    public
    view
    onlyOwner() 
    returns(bool exist) 
  {
    exist = m_players[addr].exist;
  }
  
  /**
  * @dev Get Timestamp of specified player.
  * @param addr Adrress of specified player.
  * @return timestamp Timestamp of specified player.
  */
  function playerTimestamp(address addr) 
    public
    view
    onlyOwner() 
    returns(uint256 timestamp) 
  {
    timestamp = m_players[addr].timestamp;
  }
  
  /**
  * @dev Try set input of specified player.
  * @param addr Adrress of specified player.
  * @param newInput New input of specified player.
  * @return  Whether successful or not.
  */
  function playerSetInput(address addr, uint256 newInput)
    public
    onlyOwner()
    returns(bool) 
  {
    if (!m_players[addr].exist) {
      return false;
    }
    m_players[addr].input = newInput;
    return true;
  }
  
  /**
  * @dev Do selfdestruct.
  */
  function kill() public onlyOwner() {
    selfdestruct(m_owner);
  }
}


// see: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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


// see: https://github.com/ethereum/EIPs/issues/677
contract ERC677Recipient {
  function tokenFallback(address from, uint256 amount, bytes data) public returns (bool success);
} 


// Ponzi Token Minimal Interface
contract PonziTokenMinInterface {
  function balanceOf(address owner) public view returns(uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}


/**
* @dev TheGame contract implement ERC667 Recipient 
* see: https://github.com/ethereum/EIPs/issues/677) 
* and can receive token/ether only from Ponzi Token
* see: https://github.com/PonziTrust/Token).
*/
contract TheGame is ERC677Recipient {
  using SafeMath for uint256;

  enum State {
    NotActive, //NotActive
    Active     //Active
  }

  State private m_state;
  address private m_owner;
  uint256 private m_level;
  PlayersStorage private m_playersStorage;
  PonziTokenMinInterface private m_ponziToken;
  uint256 private m_interestRateNumerator;
  uint256 private constant INTEREST_RATE_DENOMINATOR = 1000;
  uint256 private m_creationTimestamp;
  uint256 private constant DURATION_TO_ACCESS_FOR_OWNER = 144 days;
  uint256 private constant COMPOUNDING_FREQ = 1 days;
  uint256 private constant DELAY_ON_EXIT = 100 hours;
  uint256 private constant DELAY_ON_NEW_LEVEL = 7 days;
  string private constant NOT_ACTIVE_STR = "NotActive";
  uint256 private constant PERCENT_TAX_ON_EXIT = 10;
  string private constant ACTIVE_STR = "Active";
  uint256 private constant PERCENT_REFERRAL_BOUNTY = 1;
  uint256 private m_levelStartupTimestamp;
  uint256 private m_ponziPriceInWei;
  address private m_priceSetter;

////////////////
// EVENTS
// 
  event NewPlayer(address indexed addr, uint256 input, uint256 when);
  event DeletePlayer(address indexed addr, uint256 when);
  event NewLevel(uint256 when, uint256 newLevel);
  event StateChanged(address indexed who, State newState);
  event PonziPriceChanged(address indexed who, uint256 newPrice);
  
////////////////
// MODIFIERS - Restricting Access and State Machine patterns
//
  modifier onlyOwner() {
    require(msg.sender == m_owner);
    _;
  }
  modifier onlyPonziToken() {
    require(msg.sender == address(m_ponziToken));
    _;
  }
  modifier atState(State state) {
    require(m_state == state);
    _;
  }
  
  modifier checkAccess() {
    require(m_state == State.NotActive  // solium-disable-line indentation, operator-whitespace
      || now.sub(m_creationTimestamp) <= DURATION_TO_ACCESS_FOR_OWNER); 
    _;
  }
  
  modifier isPlayer(address addr) {
    require(m_playersStorage.playerExist(addr));
    _;
  }
  
  modifier gameIsAvailable() {
    require(now >= m_levelStartupTimestamp.add(DELAY_ON_NEW_LEVEL));
    _;
  }

///////////////
// CONSTRUCTOR
//  
  /**
  * @dev Constructor PonziToken.
  */
  function TheGame(address ponziTokenAddr) public {
    require(ponziTokenAddr != address(0));
    m_ponziToken = PonziTokenMinInterface(ponziTokenAddr);
    m_owner = msg.sender;
    m_creationTimestamp = now;
    m_state = State.NotActive;
    m_level = 1;
    m_interestRateNumerator = calcInterestRateNumerator(m_level);
  }

  /**
  * @dev Fallback func can recive eth only from Ponzi token
  */
  function() public payable onlyPonziToken() {  }
  
  
  /**
  * Contract calc output of sender and transfer token/eth it to him. 
  * If token/ethnot enough on balance, then transfer all and gp to next level.
  * 
  * @dev Sender exit from the game. Sender must be player.
  */
  function exit() 
    external
    atState(State.Active) 
    gameIsAvailable()
    isPlayer(msg.sender) 
  {
    uint256 input;
    uint256 timestamp;
    timestamp = m_playersStorage.playerTimestamp(msg.sender);
    input = m_playersStorage.playerInput(msg.sender);
    
    // Check whether the player is DELAY_ON_EXIT hours in the game
    require(now >= timestamp.add(DELAY_ON_EXIT));
    
    // calc output
    uint256 outputInPonzi = calcOutput(input, now.sub(timestamp).div(COMPOUNDING_FREQ));
    
    assert(outputInPonzi > 0);
    
    // convert ponzi to eth
    uint256 outputInWei = ponziToWei(outputInPonzi, m_ponziPriceInWei);
    
    // set zero before sending to prevent Re-Entrancy 
    m_playersStorage.deletePlayer(msg.sender);
    
    if (m_ponziPriceInWei > 0 && address(this).balance >= outputInWei) {
      // if we have enough eth on address(this).balance 
      // send it to sender
      
      // WARNING
      // untrusted Transfer !!!
      uint256 oldBalance = address(this).balance;
      msg.sender.transfer(outputInWei);
      assert(address(this).balance.add(outputInWei) >= oldBalance);
      
    } else if (m_ponziToken.balanceOf(address(this)) >= outputInPonzi) {
      // else if we have enough ponzi on balance
      // send it to sender
      
      uint256 oldPonziBalance = m_ponziToken.balanceOf(address(this));
      assert(m_ponziToken.transfer(msg.sender, outputInPonzi));
      assert(m_ponziToken.balanceOf(address(this)).add(outputInPonzi) == oldPonziBalance);
    } else {
      // if we dont have nor eth, nor ponzi then transfer all avaliable ponzi to 
      // msg.sender and go to next Level
      assert(m_ponziToken.transfer(msg.sender, m_ponziToken.balanceOf(address(this))));
      assert(m_ponziToken.balanceOf(address(this)) == 0);
      nextLevel();
    }
  }
  
  /**
  * @dev Get info about specified player.
  * @param addr Adrress of specified player.
  * @return input Input of specified player.
  * @return timestamp Timestamp of specified player.
  * @return inGame Whether specified player in game or not.
  */
  function playerInfo(address addr) 
    public 
    view 
    atState(State.Active)
    gameIsAvailable()
    returns(uint256 input, uint256 timestamp, bool inGame) 
  {
    (input, timestamp, inGame) = m_playersStorage.playerInfo(addr);
  }
  
  /**
  * @dev Get possible output for specified player at now.
  * @param addr Adrress of specified player.
  * @return input Possible output for specified player at now.
  */
  function playerOutputAtNow(address addr) 
    public 
    view 
    atState(State.Active) 
    gameIsAvailable()
    returns(uint256 amount)
  {
    if (!m_playersStorage.playerExist(addr)) {
      return 0;
    }
    uint256 input = m_playersStorage.playerInput(addr);
    uint256 timestamp = m_playersStorage.playerTimestamp(addr);
    uint256 numberOfPayout = now.sub(timestamp).div(COMPOUNDING_FREQ);
    amount = calcOutput(input, numberOfPayout);
  }
  
  /**
  * @dev Get delay on opportunity to exit for specified player at now.
  * @param addr Adrress of specified player.
  * @return input Delay for specified player at now.
  */
  function playerDelayOnExit(address addr) 
    public 
    view 
    atState(State.Active) 
    gameIsAvailable()
    returns(uint256 delay) 
  {
    if (!m_playersStorage.playerExist(addr)) {
      return 0;
    }
    uint256 timestamp = m_playersStorage.playerTimestamp(msg.sender);
    if (now >= timestamp.add(DELAY_ON_EXIT)) {
      delay = 0;
    } else {
      delay = timestamp.add(DELAY_ON_EXIT).sub(now);
    }
  }
  
  /**
  * Sender try enter to the game.
  * 
  * @dev Sender enter to the game. Sender must not be player.
  * @param input Input of new player.
  * @param referralAddress The referral address.
  */
  function enter(uint256 input, address referralAddress) 
    external 
    atState(State.Active)
    gameIsAvailable()
  {
    require(m_ponziToken.transferFrom(msg.sender, address(this), input));
    require(newPlayer(msg.sender, input, referralAddress));
  }
  
  /**
  * @dev Address of the price setter.
  * @return Address of the price setter.
  */
  function priceSetter() external view returns(address) {
    return m_priceSetter;
  }
  

  /**
  * @dev Price of one Ponzi token in wei.
  * @return Price of one Ponzi token in wei.
  */
  function ponziPriceInWei() 
    external 
    view 
    atState(State.Active)  
    returns(uint256) 
  {
    return m_ponziPriceInWei;
  }
  
  /**
  * @dev Сompounding freq of the game. Olways 1 day.
  * @return Compounding freq of the game.
  */
  function compoundingFreq() 
    external 
    view 
    atState(State.Active) 
    returns(uint256) 
  {
    return COMPOUNDING_FREQ;
  }
  
  /**
  * @dev Interest rate  of the game as numerator/denominator.From 5% to 0.1%.
  * @return numerator Interest rate numerator of the game.
  * @return denominator Interest rate denominator of the game.
  */
  function interestRate() 
    external 
    view
    atState(State.Active)
    returns(uint256 numerator, uint256 denominator) 
  {
    numerator = m_interestRateNumerator;
    denominator = INTEREST_RATE_DENOMINATOR;
  }
  
  /**
  * @dev Level of the game.
  * @return Level of the game.
  */
  function level() 
    external 
    view 
    atState(State.Active)
    returns(uint256) 
  {
    return m_level;
  }
  
  /**
  * @dev Get contract work state.
  * @return Contract work state via string.
  */
  function state() external view returns(string) {
    if (m_state == State.NotActive) 
      return NOT_ACTIVE_STR;
    else
      return ACTIVE_STR;
  }
  
  /**
  * @dev Get timestamp of the level startup.
  * @return Timestamp of the level startup.
  */
  function levelStartupTimestamp() 
    external 
    view 
    atState(State.Active)
    returns(uint256) 
  {
    return m_levelStartupTimestamp;
  }
  
  /**
  * @dev Get amount of Ponzi tokens in the game.Ponzi tokens balanceOf the game.
  * @return Contract work state via string.
  */
  function totalPonziInGame() 
    external 
    view 
    returns(uint256) 
  {
    return m_ponziToken.balanceOf(address(this));
  }
  
  /**
  * @dev Get current delay on new level.
  * @return Current delay on new level.
  */
  function currentDelayOnNewLevel() 
    external 
    view 
    atState(State.Active)
    returns(uint256 delay) 
  {
    if (now >= m_levelStartupTimestamp.add(DELAY_ON_NEW_LEVEL)) {
      delay = 0;
    } else {
      delay = m_levelStartupTimestamp.add(DELAY_ON_NEW_LEVEL).sub(now);
    }  
  }

///////////////////
// ERC677 ERC677Recipient Methods
//
  /**
  * see: https://github.com/ethereum/EIPs/issues/677
  *
  * @dev ERC677 token fallback. Called when received Ponzi token
  * and sender try enter to the game.
  *
  * @param from Received tokens from the address.
  * @param amount Amount of recived tokens.
  * @param data Received extra data.
  * @return Whether successful entrance or not.
  */
  function tokenFallback(address from, uint256 amount, bytes data) 
    public
    atState(State.Active)
    gameIsAvailable()
    onlyPonziToken()
    returns (bool)
  {
    address referralAddress = bytesToAddress(data);
    require(newPlayer(from, amount, referralAddress));
    return true;
  }
  
  /**
  * @dev Set price of one Ponzi token in wei.
  * @param newPrice Price of one Ponzi token in wei.
  */ 
  function setPonziPriceinWei(uint256 newPrice) 
    public
    atState(State.Active)   
  {
    require(msg.sender == m_owner || msg.sender == m_priceSetter);
    m_ponziPriceInWei = newPrice;
    PonziPriceChanged(msg.sender, m_ponziPriceInWei);
  }
  
  /**
  * @dev Owner do disown.
  */ 
  function disown() public onlyOwner() atState(State.Active) {
    delete m_owner;
  }
  
  /**
  * @dev Set state of contract working.
  * @param newState String representation of new state.
  */ 
  function setState(string newState) public onlyOwner() checkAccess() {
    if (keccak256(newState) == keccak256(NOT_ACTIVE_STR)) {
      m_state = State.NotActive;
    } else if (keccak256(newState) == keccak256(ACTIVE_STR)) {
      if (address(m_playersStorage) == address(0)) 
        m_playersStorage = (new PlayersStorage());
      m_state = State.Active;
    } else {
      // if newState not valid string
      revert();
    }
    StateChanged(msg.sender, m_state);
  }

  /**
  * @dev Set the PriceSetter address, which has access to set one Ponzi 
  * token price in wei.
  * @param newPriceSetter The address of new PriceSetter.
  */
  function setPriceSetter(address newPriceSetter) 
    public 
    onlyOwner() 
    checkAccess()
    atState(State.Active) 
  {
    m_priceSetter = newPriceSetter;
  }
  
  /**
  * @dev Try create new player. 
  * @param addr Adrress of pretender player.
  * @param inputAmount Input tokens amount of pretender player.
  * @param referralAddr Referral address of pretender player.
  * @return Whether specified player in game or not.
  */
  function newPlayer(address addr, uint256 inputAmount, address referralAddr)
    private
    returns(bool)
  {
    uint256 input = inputAmount;
    // return false if player already in game or if input < 1000,
    // because calcOutput() use INTEREST_RATE_DENOMINATOR = 1000.
    // and input must div by INTEREST_RATE_DENOMINATOR, if 
    // input <1000 then dividing always equal 0.
    if (m_playersStorage.playerExist(addr) || input < 1000) 
      return false;
    
    // check if referralAddr is player
    if (m_playersStorage.playerExist(referralAddr)) {
      // transfer 1% input form addr to referralAddr :
      // newPlayerInput = input * (100-PERCENT_REFERRAL_BOUNTY) %;
      // referralInput  = (current referral input) + input * PERCENT_REFERRAL_BOUNTY %
      uint256 newPlayerInput = inputAmount.mul(uint256(100).sub(PERCENT_REFERRAL_BOUNTY)).div(100);
      uint256 referralInput = m_playersStorage.playerInput(referralAddr);
      referralInput = referralInput.add(inputAmount.sub(newPlayerInput));
      
      // try set input of referralAddr player
      assert(m_playersStorage.playerSetInput(referralAddr, referralInput));
      // if success, set input of new player = newPlayerInput
      input = newPlayerInput;
    }
    // try create new player
    assert(m_playersStorage.newPlayer(addr, input, now));
    NewPlayer(addr, input, now);
    return true;
  }
  
  /**
  * @dev Calc possibly output (compounding interest) for specified input and number of payout.
  * @param input Input amount.
  * @param numberOfPayout Number of payout.
  * @return Possibly output.
  */
  function calcOutput(uint256 input, uint256 numberOfPayout) 
    private
    view
    returns(uint256 output)
  {
    output = input;
    uint256 counter = numberOfPayout;
    // calc compound interest 
    while (counter > 0) {
      output = output.add(output.mul(m_interestRateNumerator).div(INTEREST_RATE_DENOMINATOR));
      counter = counter.sub(1);
    }
    // save tax % on exit; output = output * (100-tax) / 100;
    output = output.mul(uint256(100).sub(PERCENT_TAX_ON_EXIT)).div(100); 
  }
  
  /**
  * @dev The game go no next level. 
  */
  function nextLevel() private {
    m_playersStorage.kill();
    m_playersStorage = (new PlayersStorage());
    m_level = m_level.add(1);
    m_interestRateNumerator = calcInterestRateNumerator(m_level);
    m_levelStartupTimestamp = now;
    NewLevel(now, m_level);
  }
  
  /**
  * @dev Calc numerator of interest rate for specified level. 
  * @param newLevel Specified level.
  * @return Result numerator.
  */
  function calcInterestRateNumerator(uint256 newLevel) 
    internal 
    pure 
    returns(uint256 numerator) 
  {
    // constant INTEREST_RATE_DENOMINATOR = 1000
    // numerator we calc
    // 
    // level 1 : 5% interest rate = 50 / 1000    |
    // level 2 : 4% interest rate = 40 / 1000    |  first stage
    //        ...                                |
    // level 5 : 1% interest rate = 10 / 1000    |
    
    // level 6 : 0.9% interest rate = 9 / 1000   |  second stage
    // level 7 : 0.8% interest rate = 8 / 1000   |
    //        ...                                |
    // level 14 : 0.1% interest rate = 1 / 1000  |  
    
    // level >14 : 0.1% interest rate = 1 / 1000 |  third stage

    if (newLevel <= 5) {
      // first stage from 5% to 1%. numerator from 50 to 10
      numerator = uint256(6).sub(newLevel).mul(10);
    } else if ( newLevel >= 6 && newLevel <= 14) {
      // second stage from 0.9% to 0.1%. numerator from 9 to 1
      numerator = uint256(15).sub(newLevel);
    } else {
      // third stage 0.1%. numerator 1
      numerator = 1;
    }
  }
  
  /**
  * @dev Convert Ponzi token to wei.
  * @param tokensAmount Amout of tokens.
  * @param tokenPrice One token price in wei.
  * @return weiAmount Result of convertation. 
  */
  function ponziToWei(uint256 tokensAmount, uint256 tokenPrice) 
    internal
    pure
    returns(uint256 weiAmount)
  {
    weiAmount = tokensAmount.mul(tokenPrice); 
  } 

  /**
  * @dev Conver bytes data to address. 
  * @param source Bytes data.
  * @return Result address of convertation.
  */
  function bytesToAddress(bytes source) internal pure returns(address parsedReferer) {
    assembly {
      parsedReferer := mload(add(source,0x14))
    }
    return parsedReferer;
  }
}