pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
/* https://staging.bitguild.com/game/magicacademy 
/* authors <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b3c1d2daddcaf3dfdac5d6c0c7d2c19dd0dcde">[email&#160;protected]</a>/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f492959a9a8dda8e9c919a93b4989d829187809586da979b99">[email&#160;protected]</a>
/*         <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a9dbc8c0c7d0e9cec4c8c0c587cac6c4">[email&#160;protected]</a>           
/* ==================================================================== */

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

contract OperAccess is Ownable {
  address tradeAddress;
  address platAddress;
  address attackAddress;
  address raffleAddress;
  address drawAddress;

  function setTradeAddress(address _address) external onlyOwner {
    require(_address != address(0));
    tradeAddress = _address;
  }

  function setPLATAddress(address _address) external onlyOwner {
    require(_address != address(0));
    platAddress = _address;
  }

  function setAttackAddress(address _address) external onlyOwner {
    require(_address != address(0));
    attackAddress = _address;
  }

  function setRaffleAddress(address _address) external onlyOwner {
    require(_address != address(0));
    raffleAddress = _address;
  }

  function setDrawAddress(address _address) external onlyOwner {
    require(_address != address(0));
    drawAddress = _address;
  }

  modifier onlyAccess() {
    require(msg.sender == tradeAddress || msg.sender == platAddress || msg.sender == attackAddress || msg.sender == raffleAddress || msg.sender == drawAddress);
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
// Jade - Crypto MagicAcacedy Game
// https://www.magicAcademy.io

contract JadeCoin is ERC20, OperAccess {
  using SafeMath for SafeMath;
  string public constant name  = "MAGICACADEMY JADE";
  string public constant symbol = "Jade";
  uint8 public constant decimals = 0;
  uint256 public roughSupply;
  uint256 public totalJadeProduction;

  uint256[] public totalJadeProductionSnapshots; // The total goo production for each prior day past
  uint256[] public allocatedJadeResearchSnapshots; // The research eth allocated to each prior day past

  // Balances for each player
  mapping(address => uint256) public jadeBalance;
  mapping(address => mapping(uint8 => uint256)) public coinBalance;
  mapping(uint256 => uint256) totalEtherPool; //Total Pool
  
  mapping(address => mapping(uint256 => uint256)) private jadeProductionSnapshots; // Store player&#39;s jade production for given day (snapshot)
  mapping(address => mapping(uint256 => bool)) private jadeProductionZeroedSnapshots; // This isn&#39;t great but we need know difference between 0 production and an unused/inactive day.
    
  mapping(address => uint256) public lastJadeSaveTime; // Seconds (last time player claimed their produced jade)
  mapping(address => uint256) public lastJadeProductionUpdate; // Days (last snapshot player updated their production)
  mapping(address => uint256) private lastJadeResearchFundClaim; // Days (snapshot number)
   
  // Mapping of approved ERC20 transfers (by player)
  mapping(address => mapping(address => uint256)) private allowed;
     
  // Constructor
  function JadeCoin() public {
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
      return SafeMath.mul(getJadeProduction(player),SafeMath.div(SafeMath.sub(block.timestamp,lSave),60));
    }
    return 0;
  }

  /// production/s
  function getJadeProduction(address player) public constant returns (uint256){
    return jadeProductionSnapshots[player][lastJadeProductionUpdate[player]];
  }

  function getlastJadeProductionUpdate(address player) public view returns (uint256) {
    return lastJadeProductionUpdate[player];
  }
    /// increase prodution 
  function increasePlayersJadeProduction(address player, uint256 increase) external onlyAccess {
    jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length] = SafeMath.add(getJadeProduction(player),increase);
    lastJadeProductionUpdate[player] = allocatedJadeResearchSnapshots.length;
    totalJadeProduction = SafeMath.add(totalJadeProduction,increase);
  }

  /// reduce production
  function reducePlayersJadeProduction(address player, uint256 decrease) external onlyAccess {
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
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) external onlyAccess {
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

  function JadeCoinMining(address _addr, uint256 _amount) external onlyOwner {
    roughSupply = SafeMath.add(roughSupply,_amount);
    jadeBalance[_addr] = SafeMath.add(jadeBalance[_addr],_amount);
  }

  function setRoughSupply(uint256 iroughSupply) external onlyAccess {
    roughSupply = SafeMath.add(roughSupply,iroughSupply);
  }
  /// balance of coin/eth  in-game
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

/// @notice define the players,cards,jadecoin
/// @author rainysiu <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d0a2b1b9bea990bcb9a6b5a3a4b1a2feb3bfbd">[email&#160;protected]</a>
/// @dev MagicAcademy Games 

contract CardsBase is JadeCoin {

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

  //setting configuration
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

  /// start game
  function beginGame() external onlyOwner {
    require(!gameStarted);
    gameStarted = true; 
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
  function getRanking() external view returns (address[], uint256[]) {
    uint256 len = players.length;
    uint256[] memory arr = new uint256[](len);
    address[] memory arr_addr = new address[](len);

    uint counter =0;
    for (uint k=0;k<len; k++){
      arr[counter] =  getJadeProduction(players[k].owneraddress);
      arr_addr[counter] = players[k].owneraddress;
      counter++;
    }

    for(uint i=0;i<len-1;i++) {
      for(uint j=0;j<len-i-1;j++) {
        if(arr[j]<arr[j+1]) {
          uint256 temp = arr[j];
          address temp_addr = arr_addr[j];
          arr[j] = arr[j+1];
          arr[j+1] = temp;
          arr_addr[j] = arr_addr[j+1];
          arr_addr[j+1] = temp_addr;
        }
      }
    }
    return (arr_addr,arr);
  }

  /// @notice battle power ranking
  function getAttackRanking() external view returns (address[], uint256[]) {
    uint256 len = players.length;
    uint256[] memory arr = new uint256[](len);
    address[] memory arr_addr = new address[](len);

    uint counter =0;
    for (uint k=0;k<len; k++){
      (,,,arr[counter]) = getPlayersBattleStats(players[k].owneraddress);
      arr_addr[counter] = players[k].owneraddress;
      counter++;
    }

    for(uint i=0;i<len-1;i++) {
      for(uint j=0;j<len-i-1;j++) {
        if(arr[j]<arr[j+1]) {
          uint256 temp = arr[j];
          address temp_addr = arr_addr[j];
          arr[j] = arr[j+1];
          arr[j+1] = temp;
          arr_addr[j] = arr_addr[j+1];
          arr_addr[j+1] = temp_addr;
        }
      }
    }
    return(arr_addr,arr);
  } 

  //total users
  function getTotalUsers()  external view returns (uint256) {
    return players.length;
  }
 
  /// UnitsProuction
  function getUnitsProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return (amount * (schema.unitCoinProduction(unitId) + unitCoinProductionIncreases[player][unitId]) * (10 + unitCoinProductionMultiplier[player][unitId])) / 10; 
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
}