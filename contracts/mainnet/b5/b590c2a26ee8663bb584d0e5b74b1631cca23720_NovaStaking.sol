pragma solidity ^0.4.23;


// @title SafeMath
// @dev Math operations with safety checks that throw on error
library SafeMath {

  // @dev Multiplies two numbers, throws on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "mul failed");
    return c;
  }

  // @dev Integer division of two numbers, truncating the quotient.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub fail");
    return a - b;
  }

  // @dev Adds two numbers, throws on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "add fail");
    return c;
  }
}


// @title ERC20 interface
// @dev see https://github.com/ethereum/EIPs/issues/20
contract iERC20 {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}









// @title iNovaStaking
// @dev The interface for cross-contract calls to the Nova Staking contract
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract iNovaStaking {

  function balanceOf(address _owner) public view returns (uint256);
}



// @title iNovaGame
// @dev The interface for cross-contract calls to the Nova Game contract
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract iNovaGame {
  function isAdminForGame(uint _game, address account) external view returns(bool);

  // List of all games tracked by the Nova Game contract
  uint[] public games;
}







// @title NovaMasterAccess
// @dev NovaMasterAccess contract for controlling access to Nova Token contract functions
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract NovaMasterAccess {
  using SafeMath for uint256;

  event OwnershipTransferred(address previousOwner, address newOwner);
  event PromotedGame(uint game, bool isPromoted, string json);
  event SuppressedGame(uint game, bool isSuppressed);

  // Reference to the address of the Nova Token ERC20 contract
  iERC20 public nvtContract;

  // Reference to the address of the Nova Game contract
  iNovaGame public gameContract;

  // The Owner can perform all admin tasks.
  address public owner;

  // The Recovery account can change the Owner account.
  address public recoveryAddress;


  // @dev The original `owner` of the contract is the contract creator.
  constructor() 
    internal 
  {
    owner = msg.sender;
  }

  // @dev Access control modifier to limit access to the Owner account
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // @dev Access control modifier to limit access to the Recovery account
  modifier onlyRecovery() {
    require(msg.sender == recoveryAddress);
    _;
  }

  // @dev Assigns a new address to act as the Owner.
  // @notice Can only be called by the recovery account
  // @param _newOwner The address of the new Owner
  function setOwner(address _newOwner) 
    external 
    onlyRecovery 
  {
    require(_newOwner != address(0));
    require(_newOwner != recoveryAddress);

    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  // @dev Assigns a new address to act as the Recovery address.
  // @notice Can only be called by the Owner account
  // @param _newRecovery The address of the new Recovery account
  function setRecovery(address _newRecovery) 
    external 
    onlyOwner 
  {
    require(_newRecovery != address(0));
    require(_newRecovery != owner);

    recoveryAddress = _newRecovery;
  }

  // @dev Adds or removes a game from the list of promoted games
  // @param _game - the game to be promoted
  // @param _isPromoted - true for promoted, false for not
  // @param _json - A json string to be used to display promotional information
  function setPromotedGame(uint _game, bool _isPromoted, string _json)
    external
    onlyOwner
  {
    uint gameId = gameContract.games(_game);
    require(gameId == _game, "gameIds must match");
    emit PromotedGame(_game, _isPromoted, _isPromoted ? _json : "");
  }

  // @dev Adds or removes a game from the list of suppressed games.
  //   Suppressed games won&#39;t show up on the site, but can still be interacted with
  //   by users.
  // @param _game - the game to be promoted
  // @param _isSuppressed - true for suppressed, false for not
  function setSuppressedGame(uint _game, bool _isSuppressed)
    external
    onlyOwner
  {
    uint gameId = gameContract.games(_game);
    require(gameId == _game, "gameIds must match");
    emit SuppressedGame(_game, _isSuppressed);
  }
}



// @title ERC20 Sidechain manager imlpementation
// @dev Utility contract that manages Ethereum and ERC-20 tokens transferred in from the main chain
// @dev Can manage any number of tokens
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract NovaStakingBase is NovaMasterAccess, iNovaStaking {
  using SafeMath for uint256;

  uint public constant WEEK_ZERO_START = 1538352000; // 10/1/2018 @ 00:00:00
  uint public constant SECONDS_PER_WEEK = 604800;

  // The Nova Token balances of all games and users on the system
  mapping(address => uint) public balances;
  
  // The number of Nova Tokens stored as income each week
  mapping(uint => uint) public storedNVTbyWeek;

  // @dev Access control modifier to limit access to game admin accounts
  modifier onlyGameAdmin(uint _game) {
    require(gameContract.isAdminForGame(_game, msg.sender));
    _;
  }

  // @dev Used on deployment to link the Staking and Game contracts.
  // @param _gameContract - the address of a valid GameContract instance
  function linkContracts(address _gameContract)
    external
    onlyOwner
  {
    gameContract = iNovaGame(_gameContract);
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Balance(address account, uint256 value);
  event StoredNVT(uint week, uint stored);

  // @dev Gets the balance of the specified address.
  // @param _owner The address to query the the balance of.
  // @returns An uint256 representing the amount owned by the passed address.
  function balanceOf(address _owner) 
    public
    view
  returns (uint256) {
    return balances[_owner];
  }

  // Internal transfer of ERC20 tokens to complete payment of an auction.
  // @param _from The address which you want to send tokens from
  // @param _to The address which you want to transfer to
  // @param _value The amout of tokens to be transferred
  function _transfer(address _from, address _to, uint _value) 
    internal
  {
    require(_from != _to, "can&#39;t transfer to yourself");
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    emit Balance(_from, balances[_from]);
    emit Balance(_to, balances[_to]);
  }

  // @dev Gets the current week, as calculated by this smart contract
  // @returns uint - the current week
  function getCurrentWeek()
    external
    view
  returns(uint) {
    return _getCurrentWeek();
  }

  // @dev Internal function to calculate the current week
  // @returns uint - the current week
  function _getCurrentWeek()
    internal
    view
  returns(uint) {
    return (now - WEEK_ZERO_START) / SECONDS_PER_WEEK;
  }
}


// @title Nova Stake Management
// @dev NovaStakeManagement contract for managing stakes and game balances
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract NovaStakeManagement is NovaStakingBase {

  // Emitted whenever a user or game takes a payout from the system
  event Payout(address indexed staker, uint amount, uint endWeek);

  // Emitted whenever a user&#39;s stake is increased or decreased.
  event ChangeStake(uint week, uint indexed game, address indexed staker, uint prevStake, uint newStake,
    uint accountStake, uint gameStake, uint totalStake);

  // @dev Tracks current stake levels for all accounts and games.
  //   Tracks separately for accounts by game, accounts, games, and the total stake on the system
  // Mapping(Game => Mapping(Account => Stake))
  mapping(uint => mapping(address => uint)) public gameAccountStaked;
  // Mapping(Account => Stake)
  mapping(address => uint) public accountStaked;
  // Mapping(Game => Stake)
  mapping(uint => uint) public gameStaked;
  // Stake
  uint public totalStaked;

  // @dev Tracks stakes by week for accounts and games. Each is updated when a user changes their stake.
  //   These can be zero if they haven&#39;t been updated during the current week, so "zero"
  //     just means "look at the week before", as no stakes have been changed.
  //   When setting a stake to zero, the system records a "1". This is safe, because it&#39;s stored
  //     with 18 significant digits, and the calculation 
  // Mapping(Week => Mapping(Game => Mapping(Account => Stake)))
  mapping(uint => mapping(uint => mapping(address => uint))) public weekGameAccountStakes;
  // Mapping(Week => Mapping(Account => Stake))
  mapping(uint => mapping(address => uint)) public weekAccountStakes;
  // Mapping(Week => Mapping(Game => Stake))
  mapping(uint => mapping(uint => uint)) public weekGameStakes;
  // Mapping(Week => Stake)
  mapping(uint => uint) public weekTotalStakes;

  // The last week that an account took a payout. Used for calculating the remaining payout for the account
  mapping(address => uint) public lastPayoutWeekByAccount;
  // The last week that a game took a payout. Used for calculating the remaining payout for the game
  mapping(uint => uint) public lastPayoutWeekByGame;

  // Tracks the amount of income the system has taken in.
  // All income is paid out to games (50%) and stakers (50%)
  mapping(uint => uint) public weeklyIncome;

  constructor()
    public
  {
    weekTotalStakes[_getCurrentWeek() - 1] = 1;
  }


  // @dev Sets the sender&#39;s stake on a game to an amount.
  // @param _game - the game to increase or decrease the sender&#39;s stake on
  // @param _newStake - The new stake value. Can be an increase or decrease,
  //   but must be different than their current stake, and lower than their staking balance.
  function setStake(uint _game, uint _newStake)
    public
  {
    uint currentStake = gameAccountStaked[_game][msg.sender];
    if (currentStake < _newStake) {
      increaseStake(_game, _newStake - currentStake);
    } else 
    if (currentStake > _newStake) {
      decreaseStake(_game, currentStake - _newStake);

    }
  }

  // @dev Increases the sender&#39;s stake on a game by an amount.
  // @param _game - the game to increase the sender&#39;s stake on
  // @param _increase - The increase must be non-zero, and less than 
  //   or equal to the user&#39;s available staking balance
  function increaseStake(uint _game, uint _increase)
    public
  returns(uint newStake) {
    require(_increase > 0, "Must be a non-zero change");
    // Take the payment
    uint newBalance = balances[msg.sender].sub(_increase);
    balances[msg.sender] = newBalance;
    emit Balance(msg.sender, newBalance);

    uint prevStake = gameAccountStaked[_game][msg.sender];
    newStake = prevStake.add(_increase);
    uint gameStake = gameStaked[_game].add(_increase);
    uint accountStake = accountStaked[msg.sender].add(_increase);
    uint totalStake = totalStaked.add(_increase);

    _storeStakes(_game, msg.sender, prevStake, newStake, gameStake, accountStake, totalStake);
  }

  // @dev Decreases the sender&#39;s stake on a game by an amount.
  // @param _game - the game to decrease the sender&#39;s stake on
  // @param _decrease - The decrease must be non-zero, and less than or equal to the user&#39;s stake on the game
  function decreaseStake(uint _game, uint _decrease)
    public
  returns(uint newStake) {
    require(_decrease > 0, "Must be a non-zero change");
    uint newBalance = balances[msg.sender].add(_decrease);
    balances[msg.sender] = newBalance;
    emit Balance(msg.sender, newBalance);

    uint prevStake = gameAccountStaked[_game][msg.sender];
    newStake = prevStake.sub(_decrease);
    uint gameStake = gameStaked[_game].sub(_decrease);
    uint accountStake = accountStaked[msg.sender].sub(_decrease);
    uint totalStake = totalStaked.sub(_decrease);

    _storeStakes(_game, msg.sender, prevStake, newStake, gameStake, accountStake, totalStake);
  }

  // @dev Lets a  staker collect the current payout for all their stakes.
  // @param _numberOfWeeks - the number of weeks to collect. Set to 0 to collect all weeks.
  // @returns _payout - the total payout over all the collected weeks
  function collectPayout(uint _numberOfWeeks) 
    public
  returns(uint _payout) {
    uint startWeek = lastPayoutWeekByAccount[msg.sender];
    require(startWeek > 0, "must be a valid start week");
    uint endWeek = _getEndWeek(startWeek, _numberOfWeeks);
    require(startWeek < endWeek, "must be at least one week to pay out");
    
    uint lastWeekStake;
    for (uint i = startWeek; i < endWeek; i++) {
      // Get the stake for the week. Use the last week&#39;s stake if the stake hasn&#39;t changed
      uint weeklyStake = weekAccountStakes[i][msg.sender] == 0 
          ? lastWeekStake 
          : weekAccountStakes[i][msg.sender];
      lastWeekStake = weeklyStake;

      uint weekStake = _getWeekTotalStake(i);
      uint storedNVT = storedNVTbyWeek[i];
      uint weeklyPayout = storedNVT > 1 && weeklyStake > 1 && weekStake > 1 
        ? weeklyStake.mul(storedNVT) / weekStake / 2
        : 0;
      _payout = _payout.add(weeklyPayout);

    }
    // If the weekly stake for the end week is not set, set it to the
    //   last week&#39;s stake, to ensure we know what to pay out.
    // This works even if the end week is the current week; the value
    //   will be overwritten if necessary by future stake changes
    if(weekAccountStakes[endWeek][msg.sender] == 0) {
      weekAccountStakes[endWeek][msg.sender] = lastWeekStake;
    }
    // Always update the last payout week
    lastPayoutWeekByAccount[msg.sender] = endWeek;

    _transfer(address(this), msg.sender, _payout);
    emit Payout(msg.sender, _payout, endWeek);
  }

  // @dev Lets a game admin collect the current payout for their game.
  // @param _game - the game to collect
  // @param _numberOfWeeks - the number of weeks to collect. Set to 0 to collect all weeks.
  // @returns _payout - the total payout over all the collected weeks
  function collectGamePayout(uint _game, uint _numberOfWeeks)
    external
    onlyGameAdmin(_game)
  returns(uint _payout) {
    uint week = lastPayoutWeekByGame[_game];
    require(week > 0, "must be a valid start week");
    uint endWeek = _getEndWeek(week, _numberOfWeeks);
    require(week < endWeek, "must be at least one week to pay out");

    uint lastWeekStake;
    for (week; week < endWeek; week++) {
      // Get the stake for the week. Use the last week&#39;s stake if the stake hasn&#39;t changed
      uint weeklyStake = weekGameStakes[week][_game] == 0 
          ? lastWeekStake 
          : weekGameStakes[week][_game];
      lastWeekStake = weeklyStake;

      uint weekStake = _getWeekTotalStake(week);
      uint storedNVT = storedNVTbyWeek[week];
      uint weeklyPayout = storedNVT > 1 && weeklyStake > 1 && weekStake > 1 
        ? weeklyStake.mul(storedNVT) / weekStake / 2
        : 0;
      _payout = _payout.add(weeklyPayout);
    }
    // If the weekly stake for the end week is not set, set it to 
    //   the last week&#39;s stake, to ensure we know what to pay out
    //   This works even if the end week is the current week; the value
    //   will be overwritten if necessary by future stake changes
    if(weekGameStakes[endWeek][_game] == 0) {
      weekGameStakes[endWeek][_game] = lastWeekStake;
    }
    // Always update the last payout week
    lastPayoutWeekByGame[_game] = endWeek;

    _transfer(address(this), address(_game), _payout);
    emit Payout(address(_game), _payout, endWeek);
  }

  // @dev Internal function to calculate the game, account, and total stakes on a stake change
  // @param _game - the game to be staked on
  // @param _staker - the account doing the staking
  // @param _prevStake - the previous stake of the staker on that game
  // @param _newStake - the newly updated stake of the staker on that game
  // @param _gameStake - the new total stake for the game
  // @param _accountStake - the new total stake for the staker&#39;s account
  // @param _totalStake - the new total stake for the system as a whole
  function _storeStakes(uint _game, address _staker, uint _prevStake, uint _newStake,
    uint _gameStake, uint _accountStake, uint _totalStake)
    internal
  {
    uint _currentWeek = _getCurrentWeek();

    gameAccountStaked[_game][msg.sender] = _newStake;
    gameStaked[_game] = _gameStake;
    accountStaked[msg.sender] = _accountStake;
    totalStaked = _totalStake;
    
    // Each of these stores the weekly stake as "1" if it&#39;s been set to 0.
    // This tracks the difference between "not set this week" and "set to zero this week"
    weekGameAccountStakes[_currentWeek][_game][_staker] = _newStake > 0 ? _newStake : 1;
    weekAccountStakes[_currentWeek][_staker] = _accountStake > 0 ? _accountStake : 1;
    weekGameStakes[_currentWeek][_game] = _gameStake > 0 ? _gameStake : 1;
    weekTotalStakes[_currentWeek] = _totalStake > 0 ? _totalStake : 1;

    // Get the last payout week; set it to this week if there hasn&#39;t been a week.
    // This lets the user iterate payouts correctly.
    if(lastPayoutWeekByAccount[_staker] == 0) {
      lastPayoutWeekByAccount[_staker] = _currentWeek - 1;
      if (lastPayoutWeekByGame[_game] == 0) {
        lastPayoutWeekByGame[_game] = _currentWeek - 1;
      }
    }

    emit ChangeStake(_currentWeek, _game, _staker, _prevStake, _newStake, 
      _accountStake, _gameStake, _totalStake);
  }

  // @dev Internal function to get the total stake for a given week
  // @notice This updates the stored values for intervening weeks, 
  //   as that&#39;s more efficient at 100 or more users
  // @param _week - the week in which to calculate the total stake
  // @returns _stake - the total stake in that week
  function _getWeekTotalStake(uint _week)
    internal
  returns(uint _stake) {
    _stake = weekTotalStakes[_week];
    if(_stake == 0) {
      uint backWeek = _week;
      while(_stake == 0) {
        backWeek--;
        _stake = weekTotalStakes[backWeek];
      }
      weekTotalStakes[_week] = _stake;
    }
  }

  // @dev Internal function to get the end week based on start, number of weeks, and current week
  // @param _startWeek - the start of the range
  // @param _numberOfWeeks - the length of the range
  // @returns endWeek - either the current week, or the end of the range
  // @notice This throws if it tries to get a week range longer than the current week
  function _getEndWeek(uint _startWeek, uint _numberOfWeeks)
    internal
    view
  returns(uint endWeek) {
    uint _currentWeek = _getCurrentWeek();
    require(_startWeek < _currentWeek, "must get at least one week");
    endWeek = _numberOfWeeks == 0 ? _currentWeek : _startWeek + _numberOfWeeks;
    require(endWeek <= _currentWeek, "can&#39;t get more than the current week");
  }
}



// @title NovaToken ERC20 contract
// @dev ERC20 management contract, designed to make using ERC-20 tokens easier
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract NovaStaking is NovaStakeManagement {

  event Deposit(address account, uint256 amount, uint256 balance);
  event Withdrawal(address account, uint256 amount, uint256 balance);

  // @dev Constructor creates a reference to the NFT ownership contract
  //  and verifies the manager cut is in the valid range.
  // @param _nvtContract - address of the mainnet NovaToken contract
  constructor(iERC20 _nvtContract)
    public
  {
    nvtContract = _nvtContract;
  }

  // @dev Allows a user to deposit NVT through approveAndCall.
  // @notice Other methods of sending NVT to this contract will still work, but will result in you losing your NVT.
  // @param _sender is the original sender of the message
  // @param _amount is the amount of NVT that was approved
  // @param _contract is the contract that sent the approval; we check to be sure it&#39;s the NVT contract
  // @param _data is the data that is passed in along with the call. It&#39;s not used here
  function receiveApproval(address _sender, uint _amount, address _contract, bytes _data)
    public
  {
    require(_data.length == 0, "you must pass no data");
    require(_contract == address(nvtContract), "sending from a non-NVT contract is not allowed");

    // Track the transferred NVT
    uint newBalance = balances[_sender].add(_amount);
    balances[_sender] = newBalance;

    emit Balance(_sender, newBalance);
    emit Deposit(_sender, _amount, newBalance);

    // Transfer the NVT to this
    require(nvtContract.transferFrom(_sender, address(this), _amount), "must successfully transfer");
  }

  function receiveNVT(uint _amount, uint _week) 
    external
  {
    require(_week >= _getCurrentWeek(), "Current Week must be equal or greater");
    uint totalDonation = weeklyIncome[_week].add(_amount);
    weeklyIncome[_week] = totalDonation;

    uint stored = storedNVTbyWeek[_week].add(_amount);
    storedNVTbyWeek[_week] = stored;
    emit StoredNVT(_week, stored);
    // transfer the donation
    _transfer(msg.sender, address(this), _amount);
  }

  // @dev Allows a user to withdraw some or all of their NVT stored in this contract
  // @param _sender is the original sender of the message
  // @param _amount is the amount of NVT to be withdrawn. Withdraw(0) will withdraw all.
  // @returns true if successful, false if unsuccessful, but will most throw on most failures
  function withdraw(uint amount)
    external
  {
    uint withdrawalAmount = amount > 0 ? amount : balances[msg.sender];
    require(withdrawalAmount > 0, "Can&#39;t withdraw - zero balance");
    uint newBalance = balances[msg.sender].sub(withdrawalAmount);
    balances[msg.sender] = newBalance;
    emit Withdrawal(msg.sender, withdrawalAmount, newBalance);
    emit Balance(msg.sender, newBalance);
    nvtContract.transfer(msg.sender, withdrawalAmount);
  }

  // @dev Add more ERC-20 tokens to a game. Can be used to fund games with Nova Tokens for card creation
  // @param _game - the # of the game to add tokens to
  // @param _tokensToToAdd - the number of Nova Tokens to transfer from the calling account
  function addNVTtoGame(uint _game, uint _tokensToToAdd)
    external
    onlyGameAdmin(_game)
  {
    // Take the funding, and apply it to the GAME&#39;s address (a fake ETH address...)
    _transfer(msg.sender, address(_game), _tokensToToAdd);
  }

  // @dev Withdraw earned (or funded) Nova Tokens from a game.
  // @param _game - the # of the game to add tokens to
  // @param _tokensToWithdraw - the number of NVT to transfer from the game to the calling account
  function withdrawNVTfromGame(uint _game, uint _tokensToWithdraw)
    external
    onlyGameAdmin(_game)
  {
    // Take the NVT funds from the game, and apply them to the game admin&#39;s address
    _transfer(address(_game), msg.sender, _tokensToWithdraw);
  }
}