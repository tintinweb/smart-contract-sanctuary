//SourceUnit: faucet2.sol

pragma solidity ^0.4.25;

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

contract Blacklist is Owned {
  mapping (address => bool) private blacklist;
  function isBlacklisted(address addr) public view returns (bool) {
    return blacklist[addr];
  }
  function setBlacklisted(address addr, bool bl) isOwner {
    blacklist[addr] = bl;
  }
}
contract Blacklistable is Owned {
  Blacklist list;
  modifier okay() {
    require(!list.isBlacklisted(msg.sender));
    _;
  }
  function setBlacklist(address addr) isOwner {
    list = Blacklist(addr);
  }
}

contract WorldWaterfall is Blacklistable {
  mapping (address => bool) public registered; // Is the user registered?
  mapping (address => address) public referrers; // Referrals
  mapping (address => uint) public balance;    // Currentl balance
  mapping (address => uint) public boosted;    // Total interest rate boost in TRX
  mapping (address => uint) public lastDrop;   // Last time at which drop was received
  mapping (address => uint) public lastInterest; // Last time at which interest was taken
  mapping (address => uint) public referrals; // Number of referrals obtained
  mapping (address => uint) public referralBonuses; // Total referral bonuses given
  uint public prizeFund;
  uint public prizeReserve;
  uint public dripsSinceLastPrize;
  uint public tokenId = 1002567;
  uint public reserved; // Amount reserved for balance, etc.
  uint public lastDrip; // When the last drip occurred
  uint public totalPlayers; // Total number of people who have registered
  int public totalGiven;    // Total withdrawn less total added
  uint public boostTotal;  // Total amount given to boost interest
  bool isPrizeAvailable;
  bytes32 public name;
  event Registered(address user);
  event WonPrize(address user);

  function updateName(bytes32 _name) isOwner {
    name = _name;
  }

  function myReferralCount() public view returns (uint) {
      return referrals[msg.sender];
  }

  function myReferralBonuses() public view returns (uint) {
      return referralBonuses[msg.sender];
  }

  // Update the balance of an address and add it to the reserved amount
  function _updateBalance(address addr, uint amount) private {
      balance[addr] += amount;
      reserved += amount;
  }

  // Return how long until the user can take another drop
  function secondsToNextDrip() public view returns (uint) {
      if (lastDrop[msg.sender] == 0) return 0;
      uint diff = ((now - lastDrop[msg.sender]) * 1 seconds);
      if (diff > 300) return 0;
      return 300 - diff;
  }

  // How long it's been since a user has taken a drop, which also counts as the size of the drip
  function secondsSinceLastDrip() public view returns (uint) {
      if (lastDrip == 0) return 0;
      return (now - lastDrip) * 1 seconds;
  }

  // To make this part more game like, the boost could be based on how much people have contributed in total. It would make it a competition.
  function boost() external payable okay {
    // The boost fee goes to the contract creator
    require(msg.value > 0, "You have to give TRX to boost.");
    require(registered[msg.sender], "You are not registered. To register, grab a drip from the faucet.");
    owner.transfer(msg.value); // We get the TRX, and the player gets a bonus!
    uint trx_value = msg.value;
    boosted[msg.sender] += trx_value;
    boostTotal += trx_value;
    // Increase the prize and prize pool by 10 times the amount of TRX used to boost
    prizeFund += 80 * trx_value;
    prizeReserve += 20 * trx_value;
  }

  function _doInterest() private {
    uint start = now;
    address user = msg.sender;
    if (lastInterest[user] == 0) {
      lastInterest[user] = start;
      return;
    }
    uint diff = (start - lastInterest[user]) * 1 seconds;
    uint boost_amt = _getBoost(user);
    _updateBalance(user, balance[user] * (10 + boost_amt) * diff / 31557600 / 100);
    lastInterest[user] = now;
  }

  function getMyBalance() public view returns (uint) {
      return balance[msg.sender];
  }

  // If a person wants to deposit funds to get interest, they can!
  function deposit() external payable okay {
    require(registered[msg.sender], "You are not registered. To register, grab a drip from the faucet.");
    require(msg.tokenid == tokenId, "You sent the wrong token.");
    uint amt = msg.tokenvalue;
    _updateBalance(msg.sender, amt);
    totalGiven = totalGiven - int(amt);
    _doInterest();
  }

  function getBoost() public view returns (uint) {
    return _getBoost(msg.sender);
  }

  // Increased max interest rate
  function _getBoost(address user) private returns (uint) {
    // Calculate boost percentage, up to 200 percentage points
    // User Contribution % : Bonus
    if (boosted[user] == 0) return 0;
    uint rat = boostTotal / boosted[user];
    if (rat == 0) return 0;
    uint diff = (boostTotal / boosted[user] - 1);
    if (diff > 200) return 0;
    return 200 - diff;
  }

  // Drip and at the same time calculate interest on stored funds
  // Adding some randomness would make it more game-like
  function drip() external okay {
      require(registered[msg.sender]);
      uint start = now; // Make sure interest, drip, and update all use the same time, since "now" can change during contract execution
      address user = msg.sender;

      // I use seconds to reduce rounding error. One thing to note is that this method updates the interest rate whenever a drip occurs.
      // What this situation means is that compounding occurs more frequently the more often the user ends up using the faucet.
      uint diff = (start - lastDrop[msg.sender]) * 1 seconds;

      // If the user hasn't gotten anything yet, lastDrop will be 0, which is a problem.
      if (lastDrop[msg.sender] == 0)
        diff = 301;

      require(diff > 300, "You have already gotten your drop for the alloted time!"); // Can only drip once every five minutes

      uint drop = 20000000;
      // Make sure that there was a drip!
      if (lastDrip != 0) drop = 10000000 * (start - lastDrip) * 1 seconds;

      _updateBalance(user, max(20000000, drop));
      lastDrop[user] = start;

      // Give the referrer a 50% bonus
      address ref = referrers[msg.sender];
      if (ref != 0x0) {
        uint bonus = max(20000000, drop);
        _updateBalance(ref , bonus);
        referralBonuses[ref] += bonus;
      }

      // Add to prize fund
      prizeFund += max(drop * 4 / 30, 60000000);
      prizeReserve += max(drop * 20 / 30, 30000000);

      dripsSinceLastPrize++;

      lastDrip = start;
  }

  function max(uint a, uint b) private pure returns (uint) {
      return a > b ? a : b;
  }

  function register(address referrerAddress) external payable okay {
      require(!registered[msg.sender]);
      require(msg.value == 1000000000 || (msg.tokenvalue == 100000000000 && msg.tokenid == tokenId)); // Require's a registration fee of 1000 TRX or 100,000 WRLD
      if (msg.value != 0)
        owner.transfer(1000000000);
      else
        owner.transferToken(100000000000, tokenId);
      _register(referrerAddress);
  }

  // Register the user in the database
  function _register(address referrerAddress) internal {
      if (!registered[msg.sender]) {
          require(referrerAddress != msg.sender);
          if (registered[referrerAddress]) {
              referrers[msg.sender] = referrerAddress;
              referrals[referrerAddress]++;
          }

          totalPlayers++;
          registered[msg.sender] = true;
          emit Registered(msg.sender);
      }
  }

  function isRegistered() public view returns (bool) {
      return registered[msg.sender];
  }

  // If the prize is up for grabs, give it!
  function getPrize() external okay {
    require(registered[msg.sender], "You are not registered. To register, grab a drip from the faucet.");
    if (this.checkPrizeAvailable() && prizeFund > 0)
      _getPrizeFund(msg.sender);
  }

  // If the current drips since last prize is less than 1,000 less twice the number of seconds since the last drip, give prize.
  function checkPrizeAvailable() external returns (bool) {
    if (isPrizeAvailable) return true;
    isPrizeAvailable = dripsSinceLastPrize > (1000 - 2 * ((now - lastDrip) * 1 seconds));
    return isPrizeAvailable;
  }

  // Return the available balance of WRLD, taking into account the amount that's reserved and in the prize pools
  function getAvailableBalance() public view returns (uint) {
    uint res = reserved + prizeFund + prizeReserve;
    uint bal = address(this).tokenBalance(tokenId);
    if (res > bal) return 0;
    return bal - res;
  }

  // Pull tokens from the contract
  function withdrawTokens() external {
      require(registered[msg.sender], "You are not registered. To register, grab a drip from the faucet.");
      uint amount = balance[msg.sender];
      // If there aren't enough tokens available, give what is available.
      uint max_amt = address(this).tokenBalance(tokenId);
      if (max_amt < amount)
        amount = max_amt;

      if (amount > 0) {
        balance[msg.sender] = balance[msg.sender] - amount;
        msg.sender.transferToken(amount, tokenId);
        reserved = reserved - amount;
        totalGiven += int(amount);
      }
  }

  function _getPrizeFund(address user) private {
      uint amount = prizeFund;
      isPrizeAvailable = false;
      prizeFund = prizeReserve;
      prizeReserve = 0;
      dripsSinceLastPrize = 0;
      _updateBalance(user, amount);
      emit WonPrize(user);
  }

  // Fallback function
  function () external payable {}

  // Functions to pull tokens and TRX that might accidentally be sent to the contract address. The only token that cannot be pulled, even by the contract creator, is WRLD.

  // Transfer all tron in the account into the contract creator's account
  function superWithdrawTRX() isOwner {
    msg.sender.transfer(address(this).balance);
  }

  // Transfer total amount of any token that might have accidentally been added to the contract, except WRLD so that the contract creator cannot pull WRLD from the game and kill it, under most conditions...
  function superWithdrawTRC(uint tid) isOwner {
    // If the contract is inactive for over ONE WEEK, then the parent address can withdraw WRLD!
    require(tid != tokenId || (now - lastDrip) * 1 seconds > 604800, "You canot withdraw WRLD!");
    msg.sender.transferToken(address(this).tokenBalance(tid), tid);
  }
}