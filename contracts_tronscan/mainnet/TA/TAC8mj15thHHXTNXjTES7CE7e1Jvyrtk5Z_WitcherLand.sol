//SourceUnit: WitcherLand.sol

pragma solidity >=0.5.4;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract GameConfig {

  
  uint256 public BOX_GAME_PROFITABILITY_INCREASING_TIME_INTERVAL = 1 minutes;

  uint256 public BOX_GAME_ADMIN_WITHDRAW_TIME_INTERVAL = 7 minutes; 

  
  uint256[4] public COOKING_TIME = [3 minutes, 6 minutes, 12 minutes, 18 minutes];

  
  uint256 public TIME_INTERVAL_BETWEEN_STIRRINGS = 1 minutes;
  uint256 public CRAFTING_ACCELERATION_TIME_INTERVAL = 1 minutes;

  
  uint256 public TIME_DAY = 1 minutes;

  
  uint256[4] public COOKING_PRICE = [1, 2, 3, 4];

  
  uint256[4] public POTION_UPGRADE_AMOUNTS = [10, 10, 5, 1000000];

  
  uint256[4] public MASTER_POINTS = [8, 16, 33, 50];

  
  uint256[4][5] public REFERRAL_PERCENTS = [
    [uint256(50), uint256(100), uint256(200), uint256(300)],
    [uint256(25),  uint256(50), uint256(100), uint256(150)],
    [uint256(10),  uint256(25),  uint256(50), uint256(100)],
    [ uint256(5),  uint256(10),  uint256(25),  uint256(50)],
    [ uint256(3),   uint256(5),  uint256(10),  uint256(25)]
  ];

  
  uint256[4][4] public PROFITABILITY = [
    [ 8000,  8500,  9000,  9000],
    [10000, 10000, 10000, 10000],
    [10400, 10900, 12000, 13200],
    [10600, 11400, 13000, 14800]
  ];

  
  uint256[4] public ADMIN_FEES = [170, 330, 670, 1000];
  uint256 public ADMIN_BOX_FEE = 100; 

  
  uint256 public constant AUTOREGULATION_PERCENT = 25; 
  uint256 public constant AUTOREGULATION_MASTER_POINTS = 230;
  uint256 public constant AUTOREGULATION_PROFITABILITY = 9000; 

  
  uint256 public constant AVATAR_PRICE = 200; 

  
  uint8[40] public ACHIEVEMENTS_POINTS = [ 
    2, 
    3, 
    1, 
    2, 
    3, 
    3, 
    3, 
    3, 
    1, 
    2, 
    2, 
    1, 
    2, 
    3, 
    1, 
    2, 
    3, 
    1, 
    2, 
    3, 
    3, 
    1, 
    2, 
    3, 
    3, 
    3, 
    1, 
    2, 
    3, 
    1, 
    2, 
    3, 
    1, 
    2, 
    3, 
    3, 
    1, 
    2, 
    3, 
    3  
  ];

  

}

contract Game is GameConfig, Ownable {
  using SafeMath for uint256;
  using Address for address payable;

  address payable public adminAddr; 
  address payable public defaultReferrerAddr = address(0x41cac64c1b9309bb0bc5c5e8bdb6be2b56cd6f4487);

  
  struct Potion {
    uint8 level; 
    uint256 amount; 
    uint256 lastStirringTime; 
    uint256 completionTime; 
    uint256 points; 

    uint256 totalCrafted; 
  }

  
  struct ReferralReward {
    uint8 level;
    uint256 reward;
  }

  
  struct Player {
    uint256 registrationTime;
    uint256 lastActivityTime;
    uint256 activityDaysInARow;
    string name;
    string avatar;

    uint256 boxGameBalance; 
    uint256 boxInitialProfitability; 
    uint256 boxProfit; 
    uint256 boxDepositTime; 

    address payable referrer; 
    address[] referrals; 
    mapping (address => ReferralReward) referralRewards; 

    Potion[4] potions; 
    Potion[4] potionsInCrafting; 
    Potion[] potionsOnUpgrade; 

    uint256 totalUpgrades; 
    bool[3] upgrades; 
    uint256 potionsSold; 

    uint256 totalStirrings; 

    TRXAccounting[2] trxAccounting; 

    bool[40] achievements; 
  }

  struct TRXAccounting {
    uint256 total; 
    uint256 crafting; 
    uint256 box; 
  }

  
  mapping (address => Player) public players;
  address[] public playersAddresses;
  uint256 public totalPlayers; 

  mapping (address => uint256) public rating;

  TRXAccounting totalInvested; 
  TRXAccounting totalWithdrawn; 
  uint256 totalReferralsWithdrawn; 

  uint256 maxContractBalance; 

  event GameStart(address indexed _playerAddr);

  event Deposit(address indexed _from, uint256 _amount);
  event CraftGameDeposit(address indexed _from, uint256 _amount);
  event BoxGameDeposit(address indexed _from, uint256 _amount);

  event Withdraw(address indexed _to, uint256 _amount);
  event CraftGameWithdraw(address indexed _to, uint256 _amount);
  event BoxGameWithdraw(address indexed _to, uint256 _amount);

  constructor() public {
    adminAddr = msg.sender;
  }

  
  function startGame(address payable _referrer) public {
    require(msg.sender != defaultReferrerAddr, "Default referrer can't be a player");
    Player storage player = players[msg.sender];
    if (player.registrationTime > 0) { 
      return;
    }

    address payable referrerAddr = _referrer;
    if (_referrer == address(0x0) || _referrer == msg.sender || players[_referrer].registrationTime == 0) {
      referrerAddr = defaultReferrerAddr;
    }

    player.referrer = referrerAddr;
    player.registrationTime = now;
    player.lastActivityTime = now;
    player.activityDaysInARow = 1;

    
    for (uint8 i = 0; i < 4; i++) {
      player.potions[i].level = i;
      player.potionsInCrafting[i].level = i;
    }

    Player storage referrer = players[referrerAddr];
    address payable ref = referrerAddr;
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      if (ref == address(0x0)) {
        break;
      }
      players[ref].referrals.push(msg.sender);
      players[ref].referralRewards[msg.sender].level = i;

      ref = players[ref].referrer;
    }

    
    if (!referrer.achievements[17] && referrer.referrals.length >= 1) {
      referrer.achievements[17] = true;
      rating[referrerAddr] = rating[referrerAddr].add(ACHIEVEMENTS_POINTS[17]);
    }
    if (!referrer.achievements[18] && referrer.referrals.length >= 10) {
      referrer.achievements[18] = true;
      rating[referrerAddr] = rating[referrerAddr].add(ACHIEVEMENTS_POINTS[18]);
    }
    if (!referrer.achievements[19] && referrer.referrals.length >= 25) {
      referrer.achievements[19] = true;
      rating[referrerAddr] = rating[referrerAddr].add(ACHIEVEMENTS_POINTS[19]);
    }
    if (!referrer.achievements[20] && referrer.referrals.length >= 100) {
      referrer.achievements[20] = true;
      rating[referrerAddr] = rating[referrerAddr].add(ACHIEVEMENTS_POINTS[20]);
    }
    updateAchievements(referrerAddr);

    totalPlayers = totalPlayers.add(1);
    playersAddresses.push(msg.sender);

    emit GameStart(msg.sender);
  }

  
  function setDefaultReferrerAddress(address payable _referrerAddr) public onlyOwner {
    require(_referrerAddr != address(0x0) && !_referrerAddr.isContract(), "Invalid referrer address");

    defaultReferrerAddr = _referrerAddr;
  }

  
  function setAdminAddress(address payable _adminAddr) public onlyOwner {
    require(_adminAddr != address(0x0) && !_adminAddr.isContract(), "Invalid admin address");

    adminAddr = _adminAddr;
  }

  
  function updateAchievements(address playerAddr) internal {
    Player storage player = players[playerAddr];

    uint256 totalAchievementsCollected = 0;
    for (uint8 i = 0; i < 40; i++) {
      if (player.achievements[i]) {
        totalAchievementsCollected++;
      }
    }

    if (!player.achievements[29] && totalAchievementsCollected >= 10) {
      player.achievements[29] = true;
      rating[playerAddr] = rating[playerAddr].add(ACHIEVEMENTS_POINTS[29]);
    }
    if (!player.achievements[30] && totalAchievementsCollected >= 20) {
      player.achievements[30] = true;
      rating[playerAddr] = rating[playerAddr].add(ACHIEVEMENTS_POINTS[30]);
    }
    if (!player.achievements[31] && totalAchievementsCollected >= 39) {
      player.achievements[31] = true;
      rating[playerAddr] = rating[playerAddr].add(ACHIEVEMENTS_POINTS[31]);
    }
  }

  
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256) {
    uint256 _days = timestamp.div(1 days);

    return (_days + 3) % 7;
  }

  
  function updateActivityAchievements(Player storage player) internal returns (bool) {
    uint256 prevActivityDay = getDayOfWeek(player.lastActivityTime);
    uint256 currentDay = getDayOfWeek(now);
    
    while (currentDay < prevActivityDay) {
      currentDay = currentDay.add(7);
    }

    if (currentDay.sub(prevActivityDay) == 1 && now.sub(player.lastActivityTime) <= 48 hours) {
      player.activityDaysInARow = player.activityDaysInARow.add(1);
    } else if (currentDay.sub(prevActivityDay) > 1 || now.sub(player.lastActivityTime) > 48 hours) {
      player.activityDaysInARow = 1;
    }

    player.lastActivityTime = now;

    
    bool newAchievements = false;

    
    if (player.activityDaysInARow >= 7) {
      if (!player.achievements[26] && player.activityDaysInARow >= 7) {
        player.achievements[26] = true; 
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[26]);
        newAchievements = true;
      }
      if (!player.achievements[27] && player.activityDaysInARow >= 14) {
        player.achievements[27] = true; 
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[27]);
        newAchievements = true;
      }
      if (!player.achievements[28] && player.activityDaysInARow >= 30) {
        player.achievements[28] = true; 
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[28]);
        newAchievements = true;
      }
    }

    
    uint256 timeInTheGame = now.sub(player.registrationTime);
    if (timeInTheGame >= 1 weeks) {
      if (!player.achievements[32] && timeInTheGame >= 1 weeks) {
        player.achievements[32] = true; 
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[32]);
        newAchievements = true;
      }
      if (!player.achievements[33] && timeInTheGame >= 30 days) {
        player.achievements[33] = true; 
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[33]);
        newAchievements = true;
      }
      if (!player.achievements[34] && timeInTheGame >= 60 days) {
        player.achievements[34] = true; 
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[34]);
        newAchievements = true;
      }
    }

    return newAchievements;
  }

}

contract CraftGame is Game {

  uint256[4] potions;

  event ReturnTheRest(address indexed _to, uint256 _amount);
  event WithdrawReferral(address indexed _to, uint256 indexed _refLevel, uint256 _amount);

  event UpgradePotion(address indexed playerAddr, uint8 indexed level, uint256 amount);
  event StirrPotionOnCrafting(address indexed playerAddr, uint8 indexed level);
  event StirrPotionOnUpgrade(address indexed playerAddr, uint8 indexed level);

  
  function craftPotion(uint8 level, uint256 amount) public payable {
    require(level >= 0 && level < 4, "Invalid level number");
    require(amount > 0, "Invalid potions amount");

    Player storage player = players[msg.sender];
    require(player.referrer != address(0x0), "Player is not registered in the game");
    require(player.potionsInCrafting[level].amount == 0, "You already have potions with the same level in the crafting queue");

    uint256 price = COOKING_PRICE[level].mul(amount).mul(10**6);
    require(msg.value >= price, "Not enough TRX for crafting");

    
    player.potionsInCrafting[level].amount = amount;
    player.potionsInCrafting[level].lastStirringTime = now;
    player.potionsInCrafting[level].completionTime = now + COOKING_TIME[level];

    player.trxAccounting[0].total = player.trxAccounting[0].total.add(msg.value);
    player.trxAccounting[0].crafting = player.trxAccounting[0].crafting.add(msg.value);
    totalInvested.total = totalInvested.total.add(msg.value);
    totalInvested.crafting = totalInvested.crafting.add(msg.value);
    maxContractBalance = address(this).balance > maxContractBalance ? address(this).balance : maxContractBalance;

    
    if (msg.value > price) {
      uint256 rest = msg.value.sub(price);
      address(msg.sender).transfer(rest);

      emit ReturnTheRest(msg.sender, rest);
    }

    
    address payable ref = player.referrer;
    uint256 referralReward;
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      if (ref == address(0x0)) { 
        break;
      }
      referralReward = price.mul(REFERRAL_PERCENTS[i][level]).div(10**4);

      
      players[ref].referralRewards[msg.sender].reward = players[ref].referralRewards[msg.sender].reward.add(referralReward);
      totalReferralsWithdrawn = totalReferralsWithdrawn.add(referralReward);

      ref.transfer(referralReward);
      emit WithdrawReferral(ref, i, referralReward);

      ref = players[ref].referrer;
    }

    emit Deposit(msg.sender, price);
    emit CraftGameDeposit(msg.sender, price);

    if (updateActivityAchievements(player)) {
      updateAchievements(msg.sender);
    }
  }

  
  function upgradePotion(uint8 level, uint256 amount) public {
    require(level > 0 && level < 4, "Invalid level number");

    Player storage player = players[msg.sender];
    require(player.potions[level - 1].amount >= POTION_UPGRADE_AMOUNTS[level - 1].mul(amount), "Not enough potion of the previous level");

    
    player.potionsOnUpgrade.push(Potion({
      level: level,
      amount: amount,
      completionTime: now + COOKING_TIME[level].sub(COOKING_TIME[level-1]).add(TIME_DAY),
      lastStirringTime: now,
      points: 0, 
      totalCrafted: 0 
    }));

    
    player.potions[level - 1].amount = player.potions[level - 1].amount.sub(POTION_UPGRADE_AMOUNTS[level - 1].mul(amount));

    emit UpgradePotion(msg.sender, level, amount);

    if (updateActivityAchievements(player)) {
      updateAchievements(msg.sender);
    }
  }

  
  function stirrPotionOnCrafting(uint8 level) public {
    require(level >= 0 && level < 4, "Invalid level number");

    Player storage player = players[msg.sender];
    require(player.potionsInCrafting[level].lastStirringTime.add(TIME_INTERVAL_BETWEEN_STIRRINGS) <= now, "You have stirred less than a day ago");

    
    checkPotionOnCrafting(player, level);

    require(player.potionsInCrafting[level].amount > 0, "No potions to stirr");

    player.potionsInCrafting[level].completionTime = player.potionsInCrafting[level].completionTime.sub(CRAFTING_ACCELERATION_TIME_INTERVAL);
    player.potionsInCrafting[level].lastStirringTime = now;
    checkPotionOnCrafting(player, level);

    emit StirrPotionOnCrafting(msg.sender, level);

    player.totalStirrings = player.totalStirrings.add(1);

    bool newAchievements = false;
    if (!player.achievements[35] && player.totalStirrings >= 24) {
      player.achievements[35] = true;
      newAchievements = true;

      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[35]);
    }

    newAchievements = updateActivityAchievements(player) || newAchievements;
    if (newAchievements) {
      updateAchievements(msg.sender);
    }
  }

  
  function stirrPotionOnUpgrade(uint256 index) public {
    Player storage player = players[msg.sender];
    require(index < player.potionsOnUpgrade.length, "Invalid upgrade slot index");
    require(player.potionsOnUpgrade[index].lastStirringTime.add(TIME_INTERVAL_BETWEEN_STIRRINGS) <= now, "You have stirred less than a day ago");

    
    if (checkPotionOnUpgrade(player, index)) {
      return;
    }

    require(player.potionsOnUpgrade[index].amount > 0, "No potions to stirr");

    player.potionsOnUpgrade[index].completionTime = player.potionsOnUpgrade[index].completionTime.sub(CRAFTING_ACCELERATION_TIME_INTERVAL);
    player.potionsOnUpgrade[index].lastStirringTime = now;
    emit StirrPotionOnUpgrade(msg.sender, player.potionsOnUpgrade[index].level);

    checkPotionOnUpgrade(player, index);

    player.totalStirrings = player.totalStirrings.add(1);

    bool newAchievements = false;
    if (!player.achievements[35] && player.totalStirrings >= 24) {
      player.achievements[35] = true;
      newAchievements = true;

      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[35]);
    }

    newAchievements = updateActivityAchievements(player) || newAchievements;
    if (newAchievements) {
      updateAchievements(msg.sender);
    }
  }

  
  function checkPotionOnCrafting(Player storage player, uint8 level) internal {
    if (player.potionsInCrafting[level].amount == 0 || player.potionsInCrafting[level].completionTime == 0) {
      return;
    }

    if (player.potionsInCrafting[level].completionTime <= now) {
      uint256 potionsCraftedAtOneTime = player.potionsInCrafting[level].amount;

      potions[level] = potions[level].add(player.potionsInCrafting[level].amount);

      player.potions[level].amount = player.potions[level].amount.add(player.potionsInCrafting[level].amount);
      player.potions[level].totalCrafted = player.potions[level].totalCrafted.add(player.potionsInCrafting[level].amount);
      player.potions[level].points = player.potions[level].points.add(MASTER_POINTS[level]);

      
      player.potions[level].completionTime = player.potions[level].completionTime.add(player.potionsInCrafting[level].amount);

      player.potionsInCrafting[level].amount = 0;
      player.potionsInCrafting[level].completionTime = 0;

      updateCraftingAchievements(player, potionsCraftedAtOneTime);
    }
  }

  
  function checkPotionsOnCrafting(Player storage player) internal {
    for (uint8 i = 0; i < 4; i++) {
      checkPotionOnCrafting(player, i);
    }
  }

  
  function checkPotionOnUpgrade(Player storage player, uint256 index) internal returns (bool) {
    require(index < player.potionsOnUpgrade.length, "Invalid potion on upgrade index");

    if (player.potionsOnUpgrade[index].completionTime > 0 && player.potionsOnUpgrade[index].completionTime <= now) {
      uint8 level = player.potionsOnUpgrade[index].level;
      uint256 amount = player.potionsOnUpgrade[index].amount;

      potions[level] = potions[level].add(amount);
      potions[level - 1] = potions[level - 1].sub(POTION_UPGRADE_AMOUNTS[level - 1].mul(amount));

      player.potions[level].amount = player.potions[level].amount.add(amount);

      
      player.potions[level].completionTime = player.potions[level].completionTime.add(amount);

      
      if (player.potionsOnUpgrade.length > 1) {
        player.potionsOnUpgrade[index] = player.potionsOnUpgrade[player.potionsOnUpgrade.length.sub(1)];
      }
      player.potionsOnUpgrade.length = player.potionsOnUpgrade.length.sub(1);

      player.totalUpgrades = player.totalUpgrades.add(amount);
      player.upgrades[level - 1] = true;
      updateUpgradeAchievements(player);

      return true;
    }

    return false;
  }

  
  function checkPotionsOnUpgrade(Player storage player) internal {
    uint256 limit = 10; 
    uint256 times = 0;
    uint256 i = 0;
    while (player.potionsOnUpgrade.length > 0 && i < player.potionsOnUpgrade.length && times < limit) {
      if (!checkPotionOnUpgrade(player, i)) {
        i++;
      }

      times++;
    }
  }

  
  function collectAllPotions() public {
    Player storage player = players[msg.sender];

    updateActivityAchievements(player);
    checkPotionsOnCrafting(player);
    checkPotionsOnUpgrade(player);
  }

  
  function updateCraftingAchievements(Player storage player, uint256 potionsCraftedAtOneTime) internal { 
    if (!player.achievements[2]) { 
      player.achievements[2] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[2]);
    }

    if (!player.achievements[3]) {
      uint256 totalPotions = 0;
      for (uint8 i = 0; i < 4; i++) {
        totalPotions = totalPotions.add(player.potions[i].totalCrafted);
      }

      if (totalPotions >= 50) {
        player.achievements[3] = true;
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[3]);
      }
    }

    if (!player.achievements[4]) {
      bool allPotionTypesCrafted = true;
      for (uint8 i = 0; i < 4 && allPotionTypesCrafted; i++) {
        allPotionTypesCrafted = allPotionTypesCrafted && (player.potions[i].totalCrafted > 0);
      }

      if (allPotionTypesCrafted) {
        player.achievements[4] = true;
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[4]);
      }
    }

    if (!player.achievements[5] && (player.achievements[3] && player.achievements[4])) {
      bool allPotionTypesMoreThan25 = true;
      for (uint8 i = 0; i < 4 && allPotionTypesMoreThan25; i++) {
        allPotionTypesMoreThan25 = allPotionTypesMoreThan25 && (player.potions[i].totalCrafted >= 25);
      }

      if (allPotionTypesMoreThan25) {
        player.achievements[5] = true;
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[5]);
      }
    }

    if (!player.achievements[6] && player.achievements[5]) {
      bool allPotionTypesMoreThan250 = true;
      for (uint8 i = 0; i < 4 && allPotionTypesMoreThan250; i++) {
        allPotionTypesMoreThan250 = allPotionTypesMoreThan250 && (player.potions[i].totalCrafted >= 250);
      }

      if (allPotionTypesMoreThan250) {
        player.achievements[6] = true;
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[6]);
      }
    }

    if (!player.achievements[7] && potionsCraftedAtOneTime >= 1000) {
      player.achievements[7] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[7]);
    }

    
    uint256 craftedPotionsTotalPrice = 0;
    for (uint8 i = 0; i < 4; i++) {
      if (player.potions[i].totalCrafted > 0) {
        craftedPotionsTotalPrice = craftedPotionsTotalPrice.add(COOKING_PRICE[i].mul(player.potions[i].totalCrafted));
      }
    }
    if (!player.achievements[14] && craftedPotionsTotalPrice >= 10000) {
      player.achievements[14] = true; 
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[14]);
    }
    if (!player.achievements[15] && craftedPotionsTotalPrice >= 100000) {
      player.achievements[15] = true; 
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[15]);
    }
    if (!player.achievements[16] && craftedPotionsTotalPrice >= 1000000) {
      player.achievements[16] = true; 
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[16]);
    }

    
    uint8 potionsWithMasterPointsMoreThan100 = 0;
    for (uint8 i = 0; i < 4; i++) {
      if (player.potions[i].points >= 100) {
        potionsWithMasterPointsMoreThan100++;
      }
    }
    for (uint8 i = 1; i <= 4; i++) {
      if (!player.achievements[35 + i] && potionsWithMasterPointsMoreThan100 >= i) {
        player.achievements[35 + i] = true;
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[35 + i]);
      }
    }

    updateAchievements(msg.sender);
  }

  
  function updateUpgradeAchievements(Player storage player) internal { 
    if (!player.achievements[8]) { 
      player.achievements[8] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[8]);
    }

    if (!player.achievements[9] && player.totalUpgrades >= 500) {
      player.achievements[9] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[9]);
    }

    if (!player.achievements[10]) {
      if (player.upgrades[0] && player.upgrades[1] && player.upgrades[2]) {
        player.achievements[10] = true;
        rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[10]);
      }
    }
    updateAchievements(msg.sender);
  }

  
  function sellPotion(uint8 level, uint256 amount) public {
    require(amount > 0, "You can't sell zero potions amount");
    require(level < 4, "Incorrect potion type level");

    Player storage player = players[msg.sender];
    require(player.registrationTime > 0, "The player should be registered in the game");

    
    checkPotionsOnCrafting(player);
    checkPotionsOnUpgrade(player);

    require(player.potions[level].amount >= amount, "Not enough potions to sell");

    uint256 profitability = getProfitability(msg.sender)[level];
    uint256 reward = COOKING_PRICE[level].mul(amount).mul(profitability).mul(100); 

    require(reward > 0, "The reward for potions sell should be greater than zero");

    uint256 adminFee = reward.mul(ADMIN_FEES[level]).div(10**4);

    require(reward.add(adminFee) <= address(this).balance, "Not enough TRX on the contract balance");

    player.potions[level].amount = player.potions[level].amount.sub(amount);

    potions[level] = potions[level].sub(amount);

    player.potionsSold = player.potionsSold.add(amount);
    if (!player.achievements[11] && player.potionsSold >= 50) {
      player.achievements[11] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[11]);
    }
    if (!player.achievements[12] && player.potionsSold >= 500) {
      player.achievements[12] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[12]);
    }
    if (!player.achievements[13] && player.potionsSold >= 5000) {
      player.achievements[13] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[13]);
    }

    updateActivityAchievements(player);
    updateAchievements(msg.sender);

    address(msg.sender).transfer(reward);
    totalWithdrawn.crafting = totalWithdrawn.crafting.add(reward);
    totalWithdrawn.total = totalWithdrawn.total.add(reward);
    player.trxAccounting[1].total = player.trxAccounting[1].total.add(reward);
    player.trxAccounting[1].crafting = player.trxAccounting[1].crafting.add(reward);

    address(adminAddr).transfer(adminFee);
    totalWithdrawn.crafting = totalWithdrawn.crafting.add(adminFee);
    totalWithdrawn.total = totalWithdrawn.total.add(adminFee);

    emit Withdraw(msg.sender, reward);
    emit Withdraw(adminAddr, adminFee);
    emit CraftGameWithdraw(msg.sender, reward);
  }

  
  function getPotionProfitability(Potion memory potion) internal pure returns (uint256) {
    uint256 masterPoints = potion.points;

    if (potion.level == 0) {
      if (masterPoints <= 8) return 7900;
      else if (masterPoints <= 16) return 8125;
      else if (masterPoints <= 24) return 8350;
      else if (masterPoints <= 32) return 8575;
      else if (masterPoints <= 40) return 8800;
      else if (masterPoints <= 48) return 9025;
      else if (masterPoints <= 56) return 9250;
      else if (masterPoints <= 64) return 9475;
      else if (masterPoints <= 72) return 9700;
      else if (masterPoints <= 80) return 9925;
      else if (masterPoints <= 88) return 10150;
      else if (masterPoints <= 96) return 10375;

      return 0;
    }

    if (potion.level == 1) {
      if (masterPoints <= 16) return 8000;
      else if (masterPoints <= 32) return 8500;
      else if (masterPoints <= 48) return 9000;
      else if (masterPoints <= 64) return 9500;
      else if (masterPoints <= 80) return 10000;
      else if (masterPoints <= 96) return 10500;

      return 0;
    }

    if (potion.level == 2) {
      if (masterPoints <= 33) return 8000;
      else if (masterPoints <= 66) return 9500;
      else if (masterPoints <= 99) return 11000;

      return 0;
    }

    if (potion.level == 3) {
      if (masterPoints <= 50) return 8500;
      else if (masterPoints <= 100) return 11500;

      return 0;
    }
  }

  
  function getProfitability(address playerAddr) public view returns (uint256[4] memory) {
    uint256[4] memory profitability;

    bool autoRegulation = ((maxContractBalance != 0) && (address(this).balance <= maxContractBalance.mul(AUTOREGULATION_PERCENT).div(100)));

    Player storage player = players[playerAddr];
    bool proportionalYield = false;
    for (uint8 i = 0; i < 4; i++) {
      profitability[i] = getPotionProfitability(player.potions[i]);
      if (autoRegulation && player.potions[i].points >= AUTOREGULATION_MASTER_POINTS) {
        profitability[i] = AUTOREGULATION_PROFITABILITY;
      }
      proportionalYield = proportionalYield || (profitability[i] == 0);
    }

    if (proportionalYield) {
      uint256[4] memory totalSpent;
      for (uint8 i = 0; i < 4; i++) {
        totalSpent[i] = potions[i].mul(COOKING_PRICE[i]);
      }

      
      uint256[4] memory proportionalProfitability;
      uint8 potionsLeft = 4;
      uint256 currentMax = 0;
      uint8 profitabilityLevel = 0;
      while (potionsLeft > 0) {
        uint8 index;
        if (currentMax == 0) {
          (currentMax, index) = getArrMax(totalSpent);
        } else {
          (currentMax, index) = getArrMaxWithBound(totalSpent, currentMax);
        }

        uint8[4] memory indexes;
        uint8 size = 0;
        (indexes, size) = getIndexes(totalSpent, currentMax);

        
        if (size > 1) {
          profitabilityLevel += (size - 1);
        }
        for (uint8 i = 0; i < size; i++) {
          proportionalProfitability[indexes[i]] = PROFITABILITY[profitabilityLevel][indexes[i]]; 
        }
        profitabilityLevel++;

        potionsLeft -= size;
      }

      
      for (uint8 i = 0; i < 4; i++) {
        if (profitability[i] == 0) {
          profitability[i] = proportionalProfitability[i];
        }
      }
    }

    return profitability;
  }

  
  function getArrMax(uint256[4] memory arr) internal pure returns (uint256, uint8) {
    uint256 max = 0;
    uint8 index;
    for (uint8 i = 0; i < 4; i++) {
      if (arr[i] > max) {
        max = arr[i];
        index = i;
      }
    }

    return (max, index);
  }

  
  function getArrMaxWithBound(uint256[4] memory arr, uint256 bound) internal pure returns (uint256, uint8) {
    uint256 max = 0;
    uint8 index;
    for (uint8 i = 0; i < 4; i++) {
      if (arr[i] > max && arr[i] < bound) {
        max = arr[i];
        index = i;
      }
    }

    return (max, index);
  }

  
  function getIndexes(uint256[4] memory arr, uint256 value) internal pure returns (uint8[4] memory, uint8) {
    uint8[4] memory indexes;
    uint8 size = 0;

    uint8 j = 0;
    for (uint8 i = 0; i < 4; i++) {
      if (arr[i] == value) {
        indexes[j++] = i;
        size++;
      }
    }

    return (indexes, size);
  }

}

contract BoxGame is CraftGame {

  
  uint256 public boxTotalBalance;

  
  uint256 public boxAdminLastWithdrawTime;

  function depositBoxBalance(address payable referrerAddr) public payable {
    require(msg.value > 0, "The deposit amount should be greater than 0");

    if (players[msg.sender].registrationTime == 0) { 
      startGame(referrerAddr);
    }

    depositBoxBalance();
  }

  
  function depositBoxBalance() public payable {
    require(msg.value > 0, "The deposit amount should be greater than 0");

    Player storage player = players[msg.sender];
    require(player.registrationTime > 0, "The player should be registered before");

    
    uint256 profit = getBoxProfit(player);
    if (profit > 0) {
      player.boxProfit = player.boxProfit.add(profit);
    }

    player.trxAccounting[0].total = player.trxAccounting[0].total.add(msg.value);
    player.trxAccounting[0].box = player.trxAccounting[0].box.add(msg.value);

    if (player.boxGameBalance == 0) {
      player.boxInitialProfitability = 1; 
    } else {
      if (getCurrentProfitability(msg.sender) > 3) {
        player.boxInitialProfitability = 3;
      }
    }
    player.boxGameBalance = player.boxGameBalance.add(msg.value);
    player.boxDepositTime = now;

    totalInvested.box = totalInvested.box.add(msg.value);
    totalInvested.total = totalInvested.total.add(msg.value);
    maxContractBalance = address(this).balance > maxContractBalance ? address(this).balance : maxContractBalance;

    boxTotalBalance = boxTotalBalance.add(msg.value);
    if (boxAdminLastWithdrawTime == 0) {
      boxAdminLastWithdrawTime = now;
    }

    emit Deposit(msg.sender, msg.value);
    emit BoxGameDeposit(msg.sender, msg.value);

    
    if (!player.achievements[21] && player.trxAccounting[0].box > 0) {
      player.achievements[21] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[21]);
    }
    if (!player.achievements[22] && player.trxAccounting[0].box >= 10000 * 10**6) {
      player.achievements[22] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[22]);
    }
    if (!player.achievements[23] && player.trxAccounting[0].box >= 100000 * 10**6) {
      player.achievements[23] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[23]);
    }
    if (!player.achievements[24] && player.trxAccounting[0].box >= 1000000 * 10**6) {
      player.achievements[24] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[24]);
    }
    if (!player.achievements[25] && player.trxAccounting[0].box >= 10000000 * 10**6) {
      player.achievements[25] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[25]);
    }

    collectAllPotions();

    
    updateAchievements(msg.sender);
  }

  
  function withdrawBoxBalance(uint256 amount) public {
    Player storage player = players[msg.sender];

    uint256 adminFee = boxTotalBalance.mul(ADMIN_BOX_FEE).div(10**4);

    require(amount.add(adminFee) <= address(this).balance, "Not enough TRX on the contract balance");

    
    player.boxProfit = player.boxProfit.add(getBoxProfit(player));

    require(player.boxGameBalance.add(player.boxProfit) >= amount, "Not enough TRX on the game balance");

    if (amount <= player.boxProfit) {
      player.boxProfit = player.boxProfit.sub(amount);
      player.boxInitialProfitability = getCurrentProfitability(msg.sender);
    } else {
      player.boxGameBalance = player.boxGameBalance.sub(amount.sub(player.boxProfit));
      boxTotalBalance = boxTotalBalance.sub(amount.sub(player.boxProfit));
      player.boxProfit = 0;

      player.boxInitialProfitability = 1; 
    }
    player.boxDepositTime = now;

    
    address(msg.sender).transfer(amount);
    emit Withdraw(msg.sender, amount);
    emit BoxGameWithdraw(msg.sender, amount);
    totalWithdrawn.box = totalWithdrawn.box.add(amount);
    totalWithdrawn.total = totalWithdrawn.total.add(amount);
    player.trxAccounting[1].total = player.trxAccounting[1].total.add(amount);
    player.trxAccounting[1].box = player.trxAccounting[1].box.add(amount);

    if (boxAdminLastWithdrawTime.add(BOX_GAME_ADMIN_WITHDRAW_TIME_INTERVAL) <= now) {
      boxAdminLastWithdrawTime = now;

      address(adminAddr).transfer(adminFee);
      emit Withdraw(adminAddr, adminFee);

      totalWithdrawn.box = totalWithdrawn.box.add(adminFee);
      totalWithdrawn.total = totalWithdrawn.total.add(adminFee);
    }

    if (updateActivityAchievements(player)) {
      updateAchievements(msg.sender);
    }
  }

  
  function getBoxProfit(Player storage player) internal view returns (uint256) {
    uint256 duration = (now - player.boxDepositTime).div(BOX_GAME_PROFITABILITY_INCREASING_TIME_INTERVAL);
    if (duration == 0) {
      return 0;
    }

    uint256 profit = 0;
    uint256 profitability = player.boxInitialProfitability;
    while (profitability < 5 && duration > 0) {
      profit = profit.add(player.boxGameBalance.mul(profitability).div(1000));

      profitability = profitability.add(1);
      duration = duration.sub(1);
    }

    if (duration > 0) {
      profit = profit.add(player.boxGameBalance.mul(duration).mul(5).div(1000));
    }

    return profit;
  }

  
  function getCurrentProfitability(address playerAddr) public view returns (uint256) {
    Player memory player = players[playerAddr];

    if (player.boxGameBalance == 0) { 
      return 1;
    }

    uint256 daysFromLastDeposit = (now - player.boxDepositTime).div(BOX_GAME_PROFITABILITY_INCREASING_TIME_INTERVAL);
    uint256 profitability = player.boxInitialProfitability + daysFromLastDeposit;
    if (profitability > 5) {
      return 5;
    }

    return profitability;
  }

  
  function getBoxGameProfit(address playerAddr) public view returns (uint256) {
    Player storage player = players[playerAddr];

    return player.boxProfit.add(getBoxProfit(player));
  }

}

contract WitcherLand is CraftGame, BoxGame {

  event NameIsSet(address indexed _addr, string indexed _name);
  event AvatarBought(address indexed _addr);

  
  function getGameStats() public view returns (uint256, uint256[3] memory, uint256[3] memory, uint256) {
    return (
      totalPlayers,
      [totalInvested.total, totalInvested.crafting, totalInvested.box],
      [totalWithdrawn.total, totalWithdrawn.crafting, totalWithdrawn.box],
      totalReferralsWithdrawn
    );
  }

  
  function getPlayersStats() public view returns (address[] memory, uint256[] memory) {
    uint256[] memory referralsNumbers = new uint256[](totalPlayers);
    for (uint256 i = 0; i < totalPlayers; i++) {
      referralsNumbers[i] = players[playersAddresses[i]].referrals.length;
    }
    return (playersAddresses, referralsNumbers);
  }

  
  function getReferralsInfo() public view returns (address[] memory, uint256[] memory) {
    Player storage player = players[msg.sender];

    uint256[] memory investments = new uint256[](player.referrals.length);
    for (uint256 i = 0; i < player.referrals.length; i++) {
      investments[i] = players[player.referrals[i]].trxAccounting[0].total;
    }
    return (player.referrals, investments);
  }

  
  function getReferralsNumber(address _address) public view returns (uint256) {
    return players[_address].referrals.length;
  }

  
  function getReferralsNumbersList(address[] memory _addresses) public view returns (uint256[] memory) {
    uint256[] memory counters = new uint256[](_addresses.length);
    for (uint256 i = 0; i < _addresses.length; i++) {
      counters[i] = players[_addresses[i]].referrals.length;
    }

    return counters;
  }

  
  function getPlayerReferralsRewards(address _playerAddr) public view returns (address[] memory, uint256[] memory, uint8[] memory) {
    Player storage player = players[_playerAddr];

    uint256[] memory rewards = new uint256[](player.referrals.length);
    uint8[] memory levels = new uint8[](player.referrals.length);
    for (uint256 i = 0; i < player.referrals.length; i++) {
      rewards[i] = player.referralRewards[player.referrals[i]].reward;
      levels[i] = player.referralRewards[player.referrals[i]].level;
    }

    return (player.referrals, rewards, levels);
  }

  
  function getPlayerAccountingData(address _playerAddr) public view returns (uint256[] memory, uint256[] memory) {
    Player memory player = players[_playerAddr];

    uint256[] memory investments = new uint256[](3);
    uint256[] memory withdrawals = new uint256[](3);

    
    investments[0] = player.trxAccounting[0].total;
    investments[1] = player.trxAccounting[0].crafting;
    investments[2] = player.trxAccounting[0].box;

    
    withdrawals[0] = player.trxAccounting[1].total;
    withdrawals[1] = player.trxAccounting[1].crafting;
    withdrawals[2] = player.trxAccounting[1].box;

    return (investments, withdrawals);
  }

  
  function getPlayerCraftGameState(address _playerAddr) public view
    returns (uint8[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
  {
    Player memory player = players[_playerAddr];

    
    uint256 dataSize = player.potionsOnUpgrade.length.add(8);

    uint8[] memory levels = new uint8[](dataSize);
    uint256[] memory amounts = new uint256[](dataSize);
    uint256[] memory lastStirringTimes = new uint256[](dataSize);
    uint256[] memory completionTimes = new uint256[](dataSize);
    uint256[] memory points = new uint256[](4);

    
    for (uint8 i = 0; i < 4; i++) {
      
      levels[i] = player.potions[i].level;
      amounts[i] = player.potions[i].amount;
      completionTimes[i] = player.potions[i].completionTime;
      points[i] = player.potions[i].points;

      
      levels[i + 4] = player.potionsInCrafting[i].level;
      amounts[i + 4] = player.potionsInCrafting[i].amount;
      lastStirringTimes[i + 4] = player.potionsInCrafting[i].lastStirringTime;
      completionTimes[i + 4] = player.potionsInCrafting[i].completionTime;
    }

    
    for (uint256 i = 0; i < player.potionsOnUpgrade.length; i++) {
      levels[i + 8] = player.potionsOnUpgrade[i].level;
      amounts[i + 8] = player.potionsOnUpgrade[i].amount;
      lastStirringTimes[i + 8] = player.potionsOnUpgrade[i].lastStirringTime;
      completionTimes[i + 8] = player.potionsOnUpgrade[i].completionTime;
    }

    return (levels, amounts, lastStirringTimes, completionTimes, points);
  }

  
  function getPlayerBoxGameState(address _playerAddr) public view returns (uint256[] memory) {
    Player memory player = players[_playerAddr];

    uint256[] memory boxGameData = new uint256[](5);
    boxGameData[0] = player.boxGameBalance;
    boxGameData[1] = getBoxGameProfit(_playerAddr);
    boxGameData[2] = getCurrentProfitability(_playerAddr);
    boxGameData[3] = player.boxDepositTime;
    boxGameData[4] = player.boxInitialProfitability;

    return boxGameData;
  }

  
  function getPlayerAchievements(address _playerAddr) public view returns (bool[40] memory) {
    Player memory player = players[_playerAddr];

    return player.achievements;
  }

  
  function getPlayerAchievementsPoints(address _playerAddr) public view returns (uint8[] memory) {
    Player memory player = players[_playerAddr];
    uint8[] memory achievementsPoints = new uint8[](40);
    for (uint256 i = 0; i < 40; i++) {
      if (player.achievements[i]) {
        achievementsPoints[i] = ACHIEVEMENTS_POINTS[i];
      }
    }

    return achievementsPoints;
  }

  
  function getRating() public view returns (address[] memory, uint256[] memory) {
    uint256[] memory achievementsPoints = new uint256[](totalPlayers);
    for (uint256 i = 0; i < totalPlayers; i++) {
      achievementsPoints[i] = rating[playersAddresses[i]];
    }
    return (playersAddresses, achievementsPoints);
  }

  
  function getGlobalPotionsState() public view returns (uint256[4] memory) {
    return potions;
  }

  
  function setName(string memory _name) public {
    require(bytes(_name).length > 0 && bytes(_name).length <= 12, "Invalid player name");

    Player storage player = players[msg.sender];
    require(player.registrationTime > 0, "Player is not registered in the game");
    require(bytes(player.name).length == 0, "Player can set name only once");

    player.name = _name;
    if (!player.achievements[0]) {
      player.achievements[0] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[0]);
    }
    updateActivityAchievements(player);
    updateAchievements(msg.sender);

    emit NameIsSet(msg.sender, _name);
  }

  
  function buyAvatar(string memory url) public payable {
    Player storage player = players[msg.sender];
    require(player.registrationTime > 0, "Player is not registered in the game");

    uint256 price = (bytes(player.avatar).length > 0) ? AVATAR_PRICE.mul(10**6) : 0;
    require(msg.value >= price, "Not enough TRX to by an Avatar");
    
    if (msg.value > price) {
      uint256 rest = msg.value.sub(price);
      address(msg.sender).transfer(rest);

      emit ReturnTheRest(msg.sender, rest);
    }

    player.avatar = url;

    if (!player.achievements[1]) {
      player.achievements[1] = true;
      rating[msg.sender] = rating[msg.sender].add(ACHIEVEMENTS_POINTS[1]);
    }
    updateActivityAchievements(player);
    updateAchievements(msg.sender);

    emit AvatarBought(msg.sender);
  }

}