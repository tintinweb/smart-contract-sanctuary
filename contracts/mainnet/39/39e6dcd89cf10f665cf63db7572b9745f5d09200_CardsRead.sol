pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
/*  
/* authors rainy@livestar.com/fanny.zheng@livestar.com
/*                 
/* ==================================================================== */
interface CardsInterface {
  function getJadeProduction(address player) external constant returns (uint256);
  function getOwnedCount(address player, uint256 cardId) external view returns (uint256);
  function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256);
  function getUintCoinProduction(address _address, uint256 cardId) external view returns (uint256);
  function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitAttackIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitAttackMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitDefenseIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitDefenseMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitJadeStealingIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitJadeStealingMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitsProduction(address player, uint256 cardId, uint256 amount) external constant returns (uint256);
  function getTotalEtherPool(uint8 itype) external view returns (uint256);
  function coinBalanceOf(address player,uint8 itype) external constant returns(uint256);
  function balanceOf(address player) public constant returns(uint256);
   function getPlayersBattleStats(address player) public constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower,
    uint256 battlePower);
  function getTotalJadeProduction() external view returns (uint256);
  function getNextSnapshotTime() external view returns(uint256);
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

contract CardsRead {
  using SafeMath for SafeMath;

  CardsInterface public cards;
  GameConfigInterface public schema;
  address owner;
  

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function CardsRead() public {
    owner = msg.sender;
  }
    //setting configuration
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

     //setting configuration
  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

  // get normal cardlist;
  function getNormalCardList(address _owner) external view returns(uint256[],uint256[]){
    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.productionCardIdRange(); 
    uint256 len = SafeMath.add(SafeMath.sub(endId,startId),1);
    uint256[] memory itemId = new uint256[](len);
    uint256[] memory itemNumber = new uint256[](len);

    uint256 i;
    while (startId <= endId) {
      itemId[i] = startId;
      itemNumber[i] = cards.getOwnedCount(_owner,startId);
      i++;
      startId++;
      }   
    return (itemId, itemNumber);
  }

  // get normal cardlist;
  function getBattleCardList(address _owner) external view returns(uint256[],uint256[]){
    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.battleCardIdRange();
    uint256 len = SafeMath.add(SafeMath.sub(endId,startId),1);
    uint256[] memory itemId = new uint256[](len);
    uint256[] memory itemNumber = new uint256[](len);

    uint256 i;
    while (startId <= endId) {
      itemId[i] = startId;
      itemNumber[i] = cards.getOwnedCount(_owner,startId);
      i++;
      startId++;
      }   
    return (itemId, itemNumber);
  }

  // get upgrade cardlist;
  function getUpgradeCardList(address _owner) external view returns(uint256[],uint256[]){
    uint256 startId;
    uint256 endId;
    (startId, endId) = schema.upgradeIdRange();
    uint256 len = SafeMath.add(SafeMath.sub(endId,startId),1);
    uint256[] memory itemId = new uint256[](len);
    uint256[] memory itemNumber = new uint256[](len);

    uint256 i;
    while (startId <= endId) {
      itemId[i] = startId;
      itemNumber[i] = cards.getUpgradesOwned(_owner,startId);
      i++;
      startId++;
      }   
    return (itemId, itemNumber);
  }

    //get up value
  function getUpgradeValue(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external view returns (
    uint256 productionGain ,uint256 preValue,uint256 afterValue) {
    if (cards.getOwnedCount(player,unitId) == 0) {
      if (upgradeClass == 0) {
        productionGain = upgradeValue * 10;
        preValue = schema.unitCoinProduction(unitId);
        afterValue   = preValue + productionGain;
      } else if (upgradeClass == 1){
        productionGain = upgradeValue * schema.unitCoinProduction(unitId);
        preValue = schema.unitCoinProduction(unitId);
        afterValue   = preValue + productionGain;
      } 
    }else { // >= 1
      if (upgradeClass == 0) {
        productionGain = (cards.getOwnedCount(player,unitId) * upgradeValue * (10 + cards.getUnitCoinProductionMultiplier(player,unitId)));
        preValue = cards.getUintCoinProduction(player,unitId);
        afterValue   = preValue + productionGain;
     } else if (upgradeClass == 1) {
        productionGain = (cards.getOwnedCount(player,unitId) * upgradeValue * (schema.unitCoinProduction(unitId) + cards.getUnitCoinProductionIncreases(player,unitId)));
        preValue = cards.getUintCoinProduction(player,unitId);
        afterValue   = preValue + productionGain;
     }
    }
  }

 // To display on website
  function getGameInfo() external view returns (uint256,  uint256, uint256, uint256, uint256, uint256, uint256[], uint256[], uint256[]){  
    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.productionCardIdRange();
    uint256 len = SafeMath.add(SafeMath.sub(endId,startId),1); 
    uint256[] memory units = new uint256[](len);
        
    uint256 i;
    while (startId <= endId) {
      units[i] = cards.getOwnedCount(msg.sender,startId);
      i++;
      startId++;
    }
      
    (startId,endId) = schema.battleCardIdRange();
    len = SafeMath.add(SafeMath.sub(endId,startId),1);
    uint256[] memory battles = new uint256[](len);
    
    i=0; //reset for battle cards
    while (startId <= endId) {
      battles[i] = cards.getOwnedCount(msg.sender,startId);
      i++;
      startId++;
    }
        
    // Reset for upgrades
    i = 0;
    (startId, endId) = schema.upgradeIdRange();
    len = SafeMath.add(SafeMath.sub(endId,startId),1);
    uint256[] memory upgrades = new uint256[](len);

    while (startId <= endId) {
      upgrades[i] = cards.getUpgradesOwned(msg.sender,startId);
      i++;
      startId++;
    }
    return (
    cards.getTotalEtherPool(1), 
    cards.getJadeProduction(msg.sender),
    cards.balanceOf(msg.sender), 
    cards.coinBalanceOf(msg.sender,1),
    cards.getTotalJadeProduction(),
    cards.getNextSnapshotTime(), 
    units, battles,upgrades
    );
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