pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
/*  
/* authors rainy@livestar.com/Jony.Fu@livestar.com
/*                 
/* ==================================================================== */
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /*
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

contract AccessAdmin is Ownable {

  /// @dev Admin Address
  mapping (address => bool) adminContracts;

  /// @dev Trust contract
  mapping (address => bool) actionContracts;

  function setAdminContract(address _addr, bool _useful) public onlyOwner {
    require(_addr != address(0));
    adminContracts[_addr] = _useful;
  }

  modifier onlyAdmin {
    require(adminContracts[msg.sender]); 
    _;
  }

  function setActionContract(address _actionAddr, bool _useful) public onlyAdmin {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }
}

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract JadeCoin is ERC20, AccessAdmin {
  using SafeMath for SafeMath;
  string public constant name  = "MAGICACADEMY JADE";
  string public constant symbol = "Jade";
  uint8 public constant decimals = 0;
  uint256 public roughSupply;
  uint256 public totalJadeProduction;

  uint256[] public totalJadeProductionSnapshots; // The total goo production for each prior day past
     
  uint256 public nextSnapshotTime;
  uint256 public researchDivPercent = 10;

  // Balances for each player
  mapping(address => uint256) public jadeBalance;
  mapping(address => mapping(uint8 => uint256)) public coinBalance;
  mapping(uint8 => uint256) totalEtherPool; //Total Pool
  
  mapping(address => mapping(uint256 => uint256)) public jadeProductionSnapshots; // Store player&#39;s jade production for given day (snapshot)
 
  mapping(address => mapping(uint256 => bool)) private jadeProductionZeroedSnapshots; // This isn&#39;t great but we need know difference between 0 production and an unused/inactive day.
    
  mapping(address => uint256) public lastJadeSaveTime; // Seconds (last time player claimed their produced jade)
  mapping(address => uint256) public lastJadeProductionUpdate; // Days (last snapshot player updated their production)
  mapping(address => uint256) private lastJadeResearchFundClaim; // Days (snapshot number)
  
  mapping(address => uint256) private lastJadeDepositFundClaim; // Days (snapshot number)
  uint256[] private allocatedJadeResearchSnapshots; // Div pot #1 (research eth allocated to each prior day past)

  // Mapping of approved ERC20 transfers (by player)
  mapping(address => mapping(address => uint256)) private allowed;

  event ReferalGain(address player, address referal, uint256 amount);

  // Constructor
  function JadeCoin() public {
  }

  function() external payable {
    totalEtherPool[1] += msg.value;
  }

  // Incase community prefers goo deposit payments over production %, can be tweaked for balance
  function tweakDailyDividends(uint256 newResearchPercent) external {
    require(msg.sender == owner);
    require(newResearchPercent > 0 && newResearchPercent <= 10);
        
    researchDivPercent = newResearchPercent;
  }

  function totalSupply() public constant returns(uint256) {
    return roughSupply; // Stored jade (rough supply as it ignores earned/unclaimed jade)
  }
  /// balance of jade in-game
  function balanceOf(address player) public constant returns(uint256) {
    return SafeMath.add(jadeBalance[player],balanceOfUnclaimed(player));
  }

  /// unclaimed jade
  function balanceOfUnclaimed(address player) public constant returns (uint256) {
    uint256 lSave = lastJadeSaveTime[player];
    if (lSave > 0 && lSave < block.timestamp) { 
      return SafeMath.mul(getJadeProduction(player),SafeMath.div(SafeMath.sub(block.timestamp,lSave),100));
    }
    return 0;
  }

  /// production/s
  function getJadeProduction(address player) public constant returns (uint256){
    return jadeProductionSnapshots[player][lastJadeProductionUpdate[player]];
  }

  /// return totalJadeProduction/s
  function getTotalJadeProduction() external view returns (uint256) {
    return totalJadeProduction;
  }

  function getlastJadeProductionUpdate(address player) public view returns (uint256) {
    return lastJadeProductionUpdate[player];
  }
    /// increase prodution 
  function increasePlayersJadeProduction(address player, uint256 increase) public onlyAccess {
    jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length] = SafeMath.add(getJadeProduction(player),increase);
    lastJadeProductionUpdate[player] = allocatedJadeResearchSnapshots.length;
    totalJadeProduction = SafeMath.add(totalJadeProduction,increase);
  }

  /// reduce production  20180702
  function reducePlayersJadeProduction(address player, uint256 decrease) public onlyAccess {
    uint256 previousProduction = getJadeProduction(player);
    uint256 newProduction = SafeMath.sub(previousProduction, decrease);

    if (newProduction == 0) { 
      jadeProductionZeroedSnapshots[player][allocatedJadeResearchSnapshots.length] = true;
      delete jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length]; // 0
    } else {
      jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length] = newProduction;
    }   
    lastJadeProductionUpdate[player] = allocatedJadeResearchSnapshots.length;
    totalJadeProduction = SafeMath.sub(totalJadeProduction,decrease);
  }

  /// update player&#39;s jade balance
  function updatePlayersCoin(address player) internal {
    uint256 coinGain = balanceOfUnclaimed(player);
    lastJadeSaveTime[player] = block.timestamp;
    roughSupply = SafeMath.add(roughSupply,coinGain);  
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);  
  }

  /// update player&#39;s jade balance
  function updatePlayersCoinByOut(address player) external onlyAccess {
    uint256 coinGain = balanceOfUnclaimed(player);
    lastJadeSaveTime[player] = block.timestamp;
    roughSupply = SafeMath.add(roughSupply,coinGain);  
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);  
  }
  /// transfer
  function transfer(address recipient, uint256 amount) public returns (bool) {
    updatePlayersCoin(msg.sender);
    require(amount <= jadeBalance[msg.sender]);
    jadeBalance[msg.sender] = SafeMath.sub(jadeBalance[msg.sender],amount);
    jadeBalance[recipient] = SafeMath.add(jadeBalance[recipient],amount);
    //event
    Transfer(msg.sender, recipient, amount);
    return true;
  }
  /// transferfrom
  function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
    updatePlayersCoin(player);
    require(amount <= allowed[player][msg.sender] && amount <= jadeBalance[player]);
        
    jadeBalance[player] = SafeMath.sub(jadeBalance[player],amount); 
    jadeBalance[recipient] = SafeMath.add(jadeBalance[recipient],amount); 
    allowed[player][msg.sender] = SafeMath.sub(allowed[player][msg.sender],amount); 
        
    Transfer(player, recipient, amount);  
    return true;
  }
  
  function approve(address approvee, uint256 amount) public returns (bool) {
    allowed[msg.sender][approvee] = amount;  
    Approval(msg.sender, approvee, amount);
    return true;
  }
  
  function allowance(address player, address approvee) public constant returns(uint256) {
    return allowed[player][approvee];  
  }
  
  /// update Jade via purchase
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) public onlyAccess {
    uint256 unclaimedJade = balanceOfUnclaimed(player);
        
    if (purchaseCost > unclaimedJade) {
      uint256 jadeDecrease = SafeMath.sub(purchaseCost, unclaimedJade);
      require(jadeBalance[player] >= jadeDecrease);
      roughSupply = SafeMath.sub(roughSupply,jadeDecrease);
      jadeBalance[player] = SafeMath.sub(jadeBalance[player],jadeDecrease);
    } else {
      uint256 jadeGain = SafeMath.sub(unclaimedJade,purchaseCost);
      roughSupply = SafeMath.add(roughSupply,jadeGain);
      jadeBalance[player] = SafeMath.add(jadeBalance[player],jadeGain);
    }
        
    lastJadeSaveTime[player] = block.timestamp;
  }

  function JadeCoinMining(address _addr, uint256 _amount) external onlyAdmin {
    roughSupply = SafeMath.add(roughSupply,_amount);
    jadeBalance[_addr] = SafeMath.add(jadeBalance[_addr],_amount);
  }

  function setRoughSupply(uint256 iroughSupply) external onlyAccess {
    roughSupply = SafeMath.add(roughSupply,iroughSupply);
  }
  /// balance of coin  in-game
  function coinBalanceOf(address player,uint8 itype) external constant returns(uint256) {
    return coinBalance[player][itype];
  }

  function setJadeCoin(address player, uint256 coin, bool iflag) external onlyAccess {
    if (iflag) {
      jadeBalance[player] = SafeMath.add(jadeBalance[player],coin);
    } else if (!iflag) {
      jadeBalance[player] = SafeMath.sub(jadeBalance[player],coin);
    }
  }
  
  function setCoinBalance(address player, uint256 eth, uint8 itype, bool iflag) external onlyAccess {
    if (iflag) {
      coinBalance[player][itype] = SafeMath.add(coinBalance[player][itype],eth);
    } else if (!iflag) {
      coinBalance[player][itype] = SafeMath.sub(coinBalance[player][itype],eth);
    }
  }

  function setLastJadeSaveTime(address player) external onlyAccess {
    lastJadeSaveTime[player] = block.timestamp;
  }

  function setTotalEtherPool(uint256 inEth, uint8 itype, bool iflag) external onlyAccess {
    if (iflag) {
      totalEtherPool[itype] = SafeMath.add(totalEtherPool[itype],inEth);
     } else if (!iflag) {
      totalEtherPool[itype] = SafeMath.sub(totalEtherPool[itype],inEth);
    }
  }

  function getTotalEtherPool(uint8 itype) external view returns (uint256) {
    return totalEtherPool[itype];
  }

  function setJadeCoinZero(address player) external onlyAccess {
    jadeBalance[player]=0;
  }

  function getNextSnapshotTime() external view returns(uint256) {
    return nextSnapshotTime;
  }
  
  // To display on website
  function viewUnclaimedResearchDividends() external constant returns (uint256, uint256, uint256) {
    uint256 startSnapshot = lastJadeResearchFundClaim[msg.sender];
    uint256 latestSnapshot = allocatedJadeResearchSnapshots.length - 1; // No snapshots to begin with
        
    uint256 researchShare;
    uint256 previousProduction = jadeProductionSnapshots[msg.sender][lastJadeResearchFundClaim[msg.sender] - 1]; // Underflow won&#39;t be a problem as gooProductionSnapshots[][0xfffffffffffff] = 0;
    for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {     
    // Slightly complex things by accounting for days/snapshots when user made no tx&#39;s
      uint256 productionDuringSnapshot = jadeProductionSnapshots[msg.sender][i];
      bool soldAllProduction = jadeProductionZeroedSnapshots[msg.sender][i];
      if (productionDuringSnapshot == 0 && !soldAllProduction) {
        productionDuringSnapshot = previousProduction;
      } else {
        previousProduction = productionDuringSnapshot;
    }
            
      researchShare += (allocatedJadeResearchSnapshots[i] * productionDuringSnapshot) / totalJadeProductionSnapshots[i];
    }
    return (researchShare, startSnapshot, latestSnapshot);
  }
      
  function claimResearchDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) external {
    require(startSnapshot <= endSnapShot);
    require(startSnapshot >= lastJadeResearchFundClaim[msg.sender]);
    require(endSnapShot < allocatedJadeResearchSnapshots.length);
        
    uint256 researchShare;
    uint256 previousProduction = jadeProductionSnapshots[msg.sender][lastJadeResearchFundClaim[msg.sender] - 1]; // Underflow won&#39;t be a problem as gooProductionSnapshots[][0xffffffffff] = 0;
    for (uint256 i = startSnapshot; i <= endSnapShot; i++) {
            
    // Slightly complex things by accounting for days/snapshots when user made no tx&#39;s
      uint256 productionDuringSnapshot = jadeProductionSnapshots[msg.sender][i];
      bool soldAllProduction = jadeProductionZeroedSnapshots[msg.sender][i];
      if (productionDuringSnapshot == 0 && !soldAllProduction) {
        productionDuringSnapshot = previousProduction;
      } else {
        previousProduction = productionDuringSnapshot;
      }
            
      researchShare += (allocatedJadeResearchSnapshots[i] * productionDuringSnapshot) / totalJadeProductionSnapshots[i];
      }
        
        
    if (jadeProductionSnapshots[msg.sender][endSnapShot] == 0 && !jadeProductionZeroedSnapshots[msg.sender][endSnapShot] && previousProduction > 0) {
      jadeProductionSnapshots[msg.sender][endSnapShot] = previousProduction; // Checkpoint for next claim
    }
        
    lastJadeResearchFundClaim[msg.sender] = endSnapShot + 1;
        
    uint256 referalDivs;
    if (referer != address(0) && referer != msg.sender) {
      referalDivs = researchShare / 100; // 1%
      coinBalance[referer][1] += referalDivs;
      ReferalGain(referer, msg.sender, referalDivs);
    }
    coinBalance[msg.sender][1] += SafeMath.sub(researchShare,referalDivs);
  }    
    
  // Allocate pot divs for the day (00:00 cron job)
  function snapshotDailyGooResearchFunding() external onlyAdmin {
    uint256 todaysGooResearchFund = (totalEtherPool[1] * researchDivPercent) / 100; // 10% of pool daily
    totalEtherPool[1] -= todaysGooResearchFund;
        
    totalJadeProductionSnapshots.push(totalJadeProduction);
    allocatedJadeResearchSnapshots.push(todaysGooResearchFund);
    nextSnapshotTime = block.timestamp + 24 hours;
  }
}

interface GameConfigInterface {
  function productionCardIdRange() external constant returns (uint256, uint256);
  function battleCardIdRange() external constant returns (uint256, uint256);
  function upgradeIdRange() external constant returns (uint256, uint256);
  function unitCoinProduction(uint256 cardId) external constant returns (uint256);
  function unitAttack(uint256 cardId) external constant returns (uint256);
  function unitDefense(uint256 cardId) external constant returns (uint256);
  function unitStealingCapacity(uint256 cardId) external constant returns (uint256);
}

contract CardsBase is JadeCoin {

  function CardsBase() public {
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }
  // player  
  struct Player {
    address owneraddress;
  }

  Player[] players;
  bool gameStarted;
  
  GameConfigInterface public schema;

  // Stuff owned by each player
  mapping(address => mapping(uint256 => uint256)) public unitsOwned;  //number of normal card
  mapping(address => mapping(uint256 => uint256)) public upgradesOwned;  //Lv of upgrade card

  mapping(address => uint256) public uintsOwnerCount; // total number of cards
  mapping(address=> mapping(uint256 => uint256)) public uintProduction;  //card&#39;s production 

  // Rares & Upgrades (Increase unit&#39;s production / attack etc.)
  mapping(address => mapping(uint256 => uint256)) public unitCoinProductionIncreases; // Adds to the coin per second
  mapping(address => mapping(uint256 => uint256)) public unitCoinProductionMultiplier; // Multiplies the coin per second
  mapping(address => mapping(uint256 => uint256)) public unitAttackIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitAttackMultiplier;
  mapping(address => mapping(uint256 => uint256)) public unitDefenseIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitDefenseMultiplier;
  mapping(address => mapping(uint256 => uint256)) public unitJadeStealingIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitJadeStealingMultiplier;
  mapping(address => mapping(uint256 => uint256)) private unitMaxCap; // external cap

  //setting configuration
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

/// start game
  function beginGame(uint256 firstDivsTime) external payable onlyOwner {
    require(!gameStarted);
    gameStarted = true;
    nextSnapshotTime = firstDivsTime;
    totalEtherPool[1] = msg.value;  // Seed pot 
  }

  function endGame() external payable onlyOwner {
    require(gameStarted);
    gameStarted = false;
  }

  function getGameStarted() external constant returns (bool) {
    return gameStarted;
  }
  function AddPlayers(address _address) external onlyAccess { 
    Player memory _player= Player({
      owneraddress: _address
    });
    players.push(_player);
  }

  /// @notice ranking of production
  /// @notice rainysiu
  function getRanking() external view returns (address[], uint256[],uint256[]) {
    uint256 len = players.length;
    uint256[] memory arr = new uint256[](len);
    address[] memory arr_addr = new address[](len);
    uint256[] memory arr_def = new uint256[](len);
  
    uint counter =0;
    for (uint k=0;k<len; k++){
      arr[counter] =  getJadeProduction(players[k].owneraddress);
      arr_addr[counter] = players[k].owneraddress;
      (,arr_def[counter],,) = getPlayersBattleStats(players[k].owneraddress);
      counter++;
    }

    for(uint i=0;i<len-1;i++) {
      for(uint j=0;j<len-i-1;j++) {
        if(arr[j]<arr[j+1]) {
          uint256 temp = arr[j];
          address temp_addr = arr_addr[j];
          uint256 temp_def = arr_def[j];
          arr[j] = arr[j+1];
          arr[j+1] = temp;
          arr_addr[j] = arr_addr[j+1];
          arr_addr[j+1] = temp_addr;

          arr_def[j] = arr_def[j+1];
          arr_def[j+1] = temp_def;
        }
      }
    }
    return (arr_addr,arr,arr_def);
  }

  //total users
  function getTotalUsers()  external view returns (uint256) {
    return players.length;
  }
  function getMaxCap(address _addr,uint256 _cardId) external view returns (uint256) {
    return unitMaxCap[_addr][_cardId];
  }

  /// UnitsProuction
  function getUnitsProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return (amount * (schema.unitCoinProduction(unitId) + unitCoinProductionIncreases[player][unitId]) * (10 + unitCoinProductionMultiplier[player][unitId])); 
  } 

  /// one card&#39;s production
  function getUnitsInProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return SafeMath.div(SafeMath.mul(amount,uintProduction[player][unitId]),unitsOwned[player][unitId]);
  } 

  /// UnitsAttack
  function getUnitsAttack(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitAttack(unitId) + unitAttackIncreases[player][unitId]) * (10 + unitAttackMultiplier[player][unitId])) / 10;
  }
  /// UnitsDefense
  function getUnitsDefense(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitDefense(unitId) + unitDefenseIncreases[player][unitId]) * (10 + unitDefenseMultiplier[player][unitId])) / 10;
  }
  /// UnitsStealingCapacity
  function getUnitsStealingCapacity(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitStealingCapacity(unitId) + unitJadeStealingIncreases[player][unitId]) * (10 + unitJadeStealingMultiplier[player][unitId])) / 10;
  }
 
  // player&#39;s attacking & defending & stealing & battle power
  function getPlayersBattleStats(address player) public constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower,
    uint256 battlePower) {

    uint256 startId;
    uint256 endId;
    (startId, endId) = schema.battleCardIdRange();

    // Not ideal but will only be a small number of units (and saves gas when buying units)
    while (startId <= endId) {
      attackingPower = SafeMath.add(attackingPower,getUnitsAttack(player, startId, unitsOwned[player][startId]));
      stealingPower = SafeMath.add(stealingPower,getUnitsStealingCapacity(player, startId, unitsOwned[player][startId]));
      defendingPower = SafeMath.add(defendingPower,getUnitsDefense(player, startId, unitsOwned[player][startId]));
      battlePower = SafeMath.add(attackingPower,defendingPower); 
      startId++;
    }
  }

  // @nitice number of normal card
  function getOwnedCount(address player, uint256 cardId) external view returns (uint256) {
    return unitsOwned[player][cardId];
  }
  function setOwnedCount(address player, uint256 cardId, uint256 amount, bool iflag) external onlyAccess {
    if (iflag) {
      unitsOwned[player][cardId] = SafeMath.add(unitsOwned[player][cardId],amount);
     } else if (!iflag) {
      unitsOwned[player][cardId] = SafeMath.sub(unitsOwned[player][cardId],amount);
    }
  }

  // @notice Lv of upgrade card
  function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256) {
    return upgradesOwned[player][upgradeId];
  }
  //set upgrade
  function setUpgradesOwned(address player, uint256 upgradeId) external onlyAccess {
    upgradesOwned[player][upgradeId] = SafeMath.add(upgradesOwned[player][upgradeId],1);
  }

  function getUintsOwnerCount(address _address) external view returns (uint256) {
    return uintsOwnerCount[_address];
  }
  function setUintsOwnerCount(address _address, uint256 amount, bool iflag) external onlyAccess {
    if (iflag) {
      uintsOwnerCount[_address] = SafeMath.add(uintsOwnerCount[_address],amount);
    } else if (!iflag) {
      uintsOwnerCount[_address] = SafeMath.sub(uintsOwnerCount[_address],amount);
    }
  }

  function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitCoinProductionIncreases[_address][cardId];
  }

  function setUnitCoinProductionIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitCoinProductionIncreases[_address][cardId] = SafeMath.add(unitCoinProductionIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitCoinProductionIncreases[_address][cardId] = SafeMath.sub(unitCoinProductionIncreases[_address][cardId],iValue);
    }
  }

  function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitCoinProductionMultiplier[_address][cardId];
  }

  function setUnitCoinProductionMultiplier(address _address, uint256 cardId, uint256 iValue, bool iflag) external onlyAccess {
    if (iflag) {
      unitCoinProductionMultiplier[_address][cardId] = SafeMath.add(unitCoinProductionMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitCoinProductionMultiplier[_address][cardId] = SafeMath.sub(unitCoinProductionMultiplier[_address][cardId],iValue);
    }
  }

  function setUnitAttackIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitAttackIncreases[_address][cardId] = SafeMath.add(unitAttackIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitAttackIncreases[_address][cardId] = SafeMath.sub(unitAttackIncreases[_address][cardId],iValue);
    }
  }

  function getUnitAttackIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitAttackIncreases[_address][cardId];
  } 
  function setUnitAttackMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitAttackMultiplier[_address][cardId] = SafeMath.add(unitAttackMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitAttackMultiplier[_address][cardId] = SafeMath.sub(unitAttackMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitAttackMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitAttackMultiplier[_address][cardId];
  } 

  function setUnitDefenseIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitDefenseIncreases[_address][cardId] = SafeMath.add(unitDefenseIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitDefenseIncreases[_address][cardId] = SafeMath.sub(unitDefenseIncreases[_address][cardId],iValue);
    }
  }
  function getUnitDefenseIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitDefenseIncreases[_address][cardId];
  }
  function setunitDefenseMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitDefenseMultiplier[_address][cardId] = SafeMath.add(unitDefenseMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitDefenseMultiplier[_address][cardId] = SafeMath.sub(unitDefenseMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitDefenseMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitDefenseMultiplier[_address][cardId];
  }
  function setUnitJadeStealingIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitJadeStealingIncreases[_address][cardId] = SafeMath.add(unitJadeStealingIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitJadeStealingIncreases[_address][cardId] = SafeMath.sub(unitJadeStealingIncreases[_address][cardId],iValue);
    }
  }
  function getUnitJadeStealingIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitJadeStealingIncreases[_address][cardId];
  } 

  function setUnitJadeStealingMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitJadeStealingMultiplier[_address][cardId] = SafeMath.add(unitJadeStealingMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitJadeStealingMultiplier[_address][cardId] = SafeMath.sub(unitJadeStealingMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitJadeStealingMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitJadeStealingMultiplier[_address][cardId];
  } 

  function setUintCoinProduction(address _address, uint256 cardId, uint256 iValue, bool iflag) external onlyAccess {
    if (iflag) {
      uintProduction[_address][cardId] = SafeMath.add(uintProduction[_address][cardId],iValue);
     } else if (!iflag) {
      uintProduction[_address][cardId] = SafeMath.sub(uintProduction[_address][cardId],iValue);
    }
  }

  function getUintCoinProduction(address _address, uint256 cardId) external view returns (uint256) {
    return uintProduction[_address][cardId];
  }

  function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external onlyAccess {
    uint256 productionGain;
    if (upgradeClass == 0) {
      unitCoinProductionIncreases[player][unitId] += upgradeValue;
      productionGain = unitsOwned[player][unitId] * upgradeValue * (10 + unitCoinProductionMultiplier[player][unitId]);
      increasePlayersJadeProduction(player, productionGain);
    } else if (upgradeClass == 1) {
      unitCoinProductionMultiplier[player][unitId] += upgradeValue;
      productionGain = unitsOwned[player][unitId] * upgradeValue * (schema.unitCoinProduction(unitId) + unitCoinProductionIncreases[player][unitId]);
      increasePlayersJadeProduction(player, productionGain);
    } else if (upgradeClass == 2) {
      unitAttackIncreases[player][unitId] += upgradeValue;
    } else if (upgradeClass == 3) {
      unitAttackMultiplier[player][unitId] += upgradeValue;
    } else if (upgradeClass == 4) {
      unitDefenseIncreases[player][unitId] += upgradeValue;
    } else if (upgradeClass == 5) {
      unitDefenseMultiplier[player][unitId] += upgradeValue;
    } else if (upgradeClass == 6) {
      unitJadeStealingIncreases[player][unitId] += upgradeValue;
    } else if (upgradeClass == 7) {
      unitJadeStealingMultiplier[player][unitId] += upgradeValue;
    } else if (upgradeClass == 8) {
      unitMaxCap[player][unitId] = upgradeValue; // Housing upgrade (new capacity)
    }
  }
    
  function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external onlyAccess {
    uint256 productionLoss;
    if (upgradeClass == 0) {
      unitCoinProductionIncreases[player][unitId] -= upgradeValue;
      productionLoss = unitsOwned[player][unitId] * upgradeValue * (10 + unitCoinProductionMultiplier[player][unitId]);
      reducePlayersJadeProduction(player, productionLoss);
    } else if (upgradeClass == 1) {
      unitCoinProductionMultiplier[player][unitId] -= upgradeValue;
      productionLoss = unitsOwned[player][unitId] * upgradeValue * (schema.unitCoinProduction(unitId) + unitCoinProductionIncreases[player][unitId]);
      reducePlayersJadeProduction(player, productionLoss);
    } else if (upgradeClass == 2) {
      unitAttackIncreases[player][unitId] -= upgradeValue;
    } else if (upgradeClass == 3) {
      unitAttackMultiplier[player][unitId] -= upgradeValue;
    } else if (upgradeClass == 4) {
      unitDefenseIncreases[player][unitId] -= upgradeValue;
    } else if (upgradeClass == 5) {
      unitDefenseMultiplier[player][unitId] -= upgradeValue;
    } else if (upgradeClass == 6) {
      unitJadeStealingIncreases[player][unitId] -= upgradeValue;
    } else if (upgradeClass == 7) {
      unitJadeStealingMultiplier[player][unitId] -= upgradeValue;
    }
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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