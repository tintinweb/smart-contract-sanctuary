//SourceUnit: WorldBurnerGame.sol

pragma solidity ^0.4.25;

// This is a simple competition game where people will burn WRLD.
// After a certain amount of time has passed, the game will end with the next burn and the person who has burned the most WRLD will receive the total amount of TRX held by the contract.
// The next version will burn rather than return WRLD and it would be nice if it could restart automatically. I could even add a fund booster by requiring a small amount of TRX (10 or so) to register.

// Require registration by paying a certain number of TRX. Part of that fee goes to the pool and part goes to us.

// Convert mappings to include maps to rounds so I can restart the game.

contract Owned {
  address public owner;
  address public oldOwner;
  uint public tokenId = 1002567;
  uint lastChangedOwnerAt;
  constructor() {
    owner = msg.sender;
    oldOwner = owner;
  }
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }
  modifier isOldOwner() {
    require(msg.sender == oldOwner);
    _;
  }
  modifier sameOwner() {
    address addr = msg.sender;
    // Ensure that the address is a contract
    uint size;
    assembly { size := extcodesize(addr) }
    require(size > 0);

    // Ensure that the contract's parent is
    Owned own = Owned(addr);
    require(own.owner() == owner);
     _;
  }
  // Be careful with this option!
  function changeOwner(address newOwner) isOwner {
    lastChangedOwnerAt = now;
    oldOwner = owner;
    owner = newOwner;
  }
  // Allow a revert to old owner ONLY IF it has been less than a day
  function revertOwner() isOldOwner {
    require(oldOwner != owner);
    require((now - lastChangedOwnerAt) * 1 seconds < 86400);
    owner = oldOwner;
  }
}

contract WorldBurnerGame is Owned {
  address public parent;
  bytes32 public name;
  uint public tokenId = 1002567;
  mapping (uint => mapping (address => bool)) public registered;  // Did the person register for this round?
  mapping (uint => mapping (address => uint)) public burned;      // How much WRLD the given user has burned in the competition
  mapping (address => address) public referrers;                  // List of who referred whom. Referrals do not reset with each round.
  mapping (address => uint) public referralBonuses;               // Total referral bonuses given
  mapping (address => uint) public referrals;                     // Number of referrals obtained
  address public currentWinner;
  uint public highestBurn;
  uint public totalPlayers;
  uint public gameEndedAt;
  uint public gameStartedAt;
  uint public gameLastsFor = 86400; // Initially the game will last for one day
  uint public round;
  uint public buyIn;
  uint public totalWon;
  uint public totalBurned;
  event Registered(address user);
  event WonPrize(address user, uint amt);
  event NewHighest(address user, uint amt);
  event GameStarted();
  event GameEnded();
  bool paused;
  uint lastReclaim;

  constructor() public {
    parent = msg.sender;
    // I know. I don't need these because it defaults to zero, but for some reason I don't feel confident in trusting the default.
    // I also can't find solid documentation on whether things like "now" work when setting the variables at the very beginning, so...
    gameEndedAt = 0;
    gameStartedAt = 0;
    round = 0;
    buyIn = 5;
    lastReclaim = now;
  }

  function updateName(bytes32 _name) public {
    require(msg.sender == parent, "You are not allowed to change the name of this contract.");
    name = _name;
  }

  function checkRegistered() public view returns (bool) {
    return registered[round][msg.sender];
  }

  function prizePoolAmount() public view returns (uint) {
      return address(this).balance / 2;
  }

  function setPause(bool p) isOwner {
    paused = p;
  }

  function myBurnedAmount() public view returns (uint) {
    return burned[round][msg.sender];
  }

  // If the game is paused AND the round has ended, then withdraw funds. This protects from the game dying out and losing funds in the account.
  function withdrawBalance() isOwner {
    require(paused && (gameEndedAt != 0 || gameStartedAt == 0));
    msg.sender.transfer(address(this).balance);
  }

  // Do I really want to permanantly burn the tokens? Nah, not yet. Allow the tokens to be reclaimed at a maximum rate of 1% per month.
  function reclaimTokens() isOwner {
    require((now - lastReclaim) > 864000);
    msg.sender.transferToken(address(this).balance / 100, tokenId);
    lastReclaim = now;
  }
  // Returns how many seconds are left until the game ends
  function timeRemaining() public view returns (uint) {
    if (gameEndedAt != 0) return 0;
    if (gameStartedAt == 0) return gameLastsFor;
    uint diff = (now - gameStartedAt) * 1 seconds;
    return gameLastsFor - diff;
  }

  // Change this system to auto-claim and change the game so that it resets when the next person registers
  // Claim funds if the user is the last person to burn after the game ended. Allow the parent contract to reclaim TRX if the prize is not claimed within one week.
  bool private checkClaim;
  function claim() internal {
    assert(!checkClaim);
    checkClaim = true;
    assert(registered[round][msg.sender]);
    assert(gameEndedAt != 0);

    // Restart game for new round
    gameEndedAt = 0;
    totalPlayers = 0;
    gameStartedAt = 0;
    highestBurn = 0;
    currentWinner = 0x0;
    round++;
    buyIn += 5 * round;

    uint won = address(this).balance / 2;
    currentWinner.transfer(won); // Send half of the total balance to the winner
    totalWon += won;
    emit WonPrize(currentWinner, won);
    checkClaim = false;
  }

  function myReferralCount() public view returns (uint) {
      return referrals[msg.sender];
  }

  function myReferralBonus() public view returns (uint) {
      return referralBonuses[msg.sender];
  }

  function register(address referralAddress) external payable {
      require(!paused || gameStartedAt != 0);
      require(!checkClaim, "A claim evaluation is occurring.");
      require(!registered[round][msg.sender], "You are already registered.");
      // The fee is buyIn TRX, but you can't register so long as the game has ended. The first person to register for the round does not have to pay the buy-in!
      require(msg.value == buyIn * 1000000);
      registered[round][msg.sender] = true;
      parent.transfer(buyIn * 1000000 / 20); // Send 5% of buy-in to the parent contract.

      // Give the referrer a bonus of 5% as well
      address ref = referralAddress;
      // Check if the person was referred during a previous round
      address old_ref = referrers[msg.sender];
      if (old_ref != 0x0) ref = old_ref;
      if (ref == 0x0 || !registered[round][ref])
        ref = currentWinner;
      if (ref == msg.sender) ref = 0x0;
      if (ref != 0x0) {
        referrers[msg.sender] = ref;
        if (old_ref == 0)
          referrals[ref]++;
        ref.transfer(buyIn * 1000000 / 20);
        referralBonuses[ref] += buyIn * 1000000/ 20;
      }
      totalPlayers++;
      if (gameStartedAt == 0) {
        gameStartedAt = now;
        // Change length of the game for each new round
        gameLastsFor += 86400 * round; // Increase the length of the game by one day each round
        if (gameLastsFor > 2592000)
          gameLastsFor = 2592000; // Cap the length of a round at 30 days
        emit GameStarted();
      }
      emit Registered(msg.sender);
  }

  // Burn WRLD. The account with the highest burn at the end of the game wins!
  function burn() external payable returns (bool) {
    require(registered[round][msg.sender]);
    require(gameStartedAt != 0 && gameEndedAt == 0, "Sorry. The game has not started or has already ended.");
    require(msg.tokenvalue > 0 && msg.tokenid == tokenId, "Must send at least one WRLD.");

    // Check to see if the game has ended
    uint diff = (now - gameStartedAt) * 1 seconds;
    if (diff > gameLastsFor)
    {
      gameEndedAt = now;
      emit GameEnded();
      msg.sender.transferToken(msg.tokenvalue + 1000 * 1000000, tokenId);
      claim();
    } else {
      uint amt = msg.tokenvalue + burned[round][msg.sender];
      burned[round][msg.sender] = amt;
      totalBurned += msg.tokenvalue;
      if (amt > highestBurn) {
        highestBurn = amt;
        currentWinner = msg.sender;
        emit NewHighest(msg.sender, amt);
      }
    }
  }
}