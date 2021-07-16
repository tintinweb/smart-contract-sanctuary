//SourceUnit: WorldBurnerGame.sol

pragma solidity ^0.4.25;

// This is a simple competition game where people will burn WRLD.
// After a certain amount of time has passed, the game will end with the next burn and the person who has burned the most WRLD will receive the total amount of TRX held by the contract.
// The next version will burn rather than return WRLD and it would be nice if it could restart automatically. I could even add a fund booster by requiring a small amount of TRX (10 or so) to register.

// Require registration by paying a certain number of TRX. Part of that fee goes to the pool and part goes to us.

// Convert mappings to include maps to rounds so I can restart the game.
contract WorldBurnerGame {
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
  uint public gameLastsFor = 864000; // The game will last for 10 days
  uint public round;
  uint public buyIn;
  uint public totalWon;
  uint public totalBurned;

  constructor() public {
    parent = msg.sender;
    // I know. I don't need these because it defaults to zero, but for some reason I don't feel confident in trusting the default.
    // I also can't find solid documentation on whether things like "now" work when setting the variables at the very beginning, so...
    gameEndedAt = 0;
    gameStartedAt = 0;
    round = 0;
    buyIn = 5;
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

  function myBurnedAmount() public view returns (uint) {
    return burned[round][msg.sender];
  }

  // Returns how many seconds are left until the game ends
  function timeRemaining() public view returns (uint) {
    if (gameEndedAt != 0) return 0;
    if (gameStartedAt == 0) return gameLastsFor;
    uint diff = (now - gameStartedAt) * 1 seconds;
    return gameLastsFor - diff;
  }

  // Claim funds if the user is the last person to burn after the game ended. Allow the parent contract to reclaim TRX if the prize is not claimed within one week.
  bool checkClaim; // This should help prevent multiple claim attacks
  function claim() external {
    require(!checkClaim);
    checkClaim = true;
    // It should be fine to have a require here, because require will undo the state-change of checkClaim... I think.
    require(registered[round][msg.sender]);
    require(msg.sender == currentWinner);
    uint won = address(this).balance / 2;
    msg.sender.transfer(won); // Send half of the total balance to the winner
    totalWon += won;
    // Restart the game
    gameEndedAt = 0;
    totalPlayers = 0;
    gameStartedAt = 0;
    highestBurn = 0;
    currentWinner = 0x0;
    round++;
    buyIn += 5 * round;
    checkClaim = false;
  }

  function myReferralCount() public view returns (uint) {
      return referrals[msg.sender];
  }

  function myReferralBonus() public view returns (uint) {
      return referralBonuses[msg.sender];
  }

  function register(address referralAddress) external payable {
      require(!checkClaim, "A claim evaluation is occurring");
      require(!registered[round][msg.sender], "You are already registered.");
      // The fee is buyIn TRX, but you can't register so long as the game has ended. The first person to register for the round does not have to pay the buy-in!
      require((msg.value == buyIn * 1000000 || (msg.value == 0 && gameStartedAt == 0)) && gameEndedAt == 0);
      registered[round][msg.sender] = true;
      parent.transfer(buyIn * 1000000 / 20); // Send 5% of buy-in to the parent contract.

      // Give the referrer a bonus of 5% as well
      address ref = referralAddress;
      // Check if the person was referred during a previous round
      address old_ref = referrers[msg.sender];
      if (old_ref != 0x0) ref = old_ref;
      if (ref == 0x0 || !registered[round][ref])
        ref = currentWinner;
      if (ref != 0x0) {
        referrers[msg.sender] = ref;
        if (old_ref == 0)
          referrals[ref]++;
        ref.transfer(buyIn * 1000000 / 20);
        referralBonuses[ref] += buyIn * 1000000/ 20;
      }
      totalPlayers++;
      if (gameStartedAt == 0) gameStartedAt = now;
  }

  // Burn WRLD. The account with the highest burn at the end of the game wins!
  function burn() external payable {
    require(registered[round][msg.sender]);
    require(gameStartedAt != 0 && gameEndedAt == 0, "Sorry. The game has not started or has already ended.");
    require(msg.tokenvalue > 0 && msg.tokenid == tokenId, "Must send at least one WRLD.");

    // Check to see if the game has ended
    uint diff = (now - gameStartedAt) * 1 seconds;
    if (diff > gameLastsFor)
    {
      gameEndedAt = now;
    }

    uint amt = msg.tokenvalue + burned[round][msg.sender];
    burned[round][msg.sender] = amt;
    totalBurned += msg.tokenvalue;
    if (amt > highestBurn) {
      highestBurn = amt;
      currentWinner = msg.sender;
    }
  }
}