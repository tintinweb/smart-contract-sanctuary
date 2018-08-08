pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
/*  
/* authors rainy@livestar.com/fanny.zheng@livestar.com
/*                 
/* ==================================================================== */
contract GameConfig {
  using SafeMath for SafeMath;
  address public owner;

  /**event**/
  event newCard(uint256 cardId,uint256 baseCoinCost,uint256 coinCostIncreaseHalf,uint256 ethCost,uint256 baseCoinProduction);
  event newBattleCard(uint256 cardId,uint256 baseCoinCost,uint256 coinCostIncreaseHalf,uint256 ethCost,uint256 attackValue,uint256 defenseValue,uint256 coinStealingCapacity);
  event newUpgradeCard(uint256 upgradecardId, uint256 coinCost, uint256 ethCost, uint256 upgradeClass, uint256 cardId, uint256 upgradeValue);
  
  struct Card {
    uint256 cardId;
    uint256 baseCoinCost;
    uint256 coinCostIncreaseHalf; // Halfed to make maths slightly less (cancels a 2 out)
    uint256 ethCost;
    uint256 baseCoinProduction;
    bool unitSellable; // Rare units (from raffle) not sellable
  }


  struct BattleCard {
    uint256 cardId;
    uint256 baseCoinCost;
    uint256 coinCostIncreaseHalf; // Halfed to make maths slightly less (cancels a 2 out)
    uint256 ethCost;
    uint256 attackValue;
    uint256 defenseValue;
    uint256 coinStealingCapacity;
    bool unitSellable; // Rare units (from raffle) not sellable
  }
  
  struct UpgradeCard {
    uint256 upgradecardId;
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 cardId;
    uint256 upgradeValue;
  }
  
  /** mapping**/
  mapping(uint256 => Card) private cardInfo;  //normal card
  mapping(uint256 => BattleCard) private battlecardInfo;  //battle card
  mapping(uint256 => UpgradeCard) private upgradeInfo;  //upgrade card
     
  uint256 public currNumOfCards = 9;  
  uint256 public currNumOfBattleCards = 6;  
  uint256 public currNumOfUpgrades; 

  uint256 PLATPrice = 65000;
  string versionNo;
 
  // Constructor 
  function GameConfig() public {
    owner = msg.sender;
    versionNo = "20180706";
    cardInfo[1] = Card(1, 0, 10, 0, 2, true);
    cardInfo[2] = Card(2, 100, 50, 0, 5, true);
    cardInfo[3] = Card(3, 0, 0, 0.01 ether, 100, true);
    cardInfo[4] = Card(4, 200, 100, 0, 10,  true);
    cardInfo[5] = Card(5, 500, 250, 0, 20,  true);
    cardInfo[6] = Card(6, 1000, 500, 0, 40, true);
    cardInfo[7] = Card(7, 0, 1000, 0.05 ether, 500, true);
    cardInfo[8] = Card(8, 1500, 750, 0, 60,  true);
    cardInfo[9] = Card(9, 0, 0, 0.99 ether, 5500, false);

    battlecardInfo[40] = BattleCard(40, 50, 25, 0,  10, 10, 10000, true);
    battlecardInfo[41] = BattleCard(41, 100, 50, 0,  1, 25, 500, true);
    battlecardInfo[42] = BattleCard(42, 0, 0, 0.01 ether,  200, 10, 50000, true);
    battlecardInfo[43] = BattleCard(43, 250, 125, 0, 25, 1, 15000, true);
    battlecardInfo[44] = BattleCard(44, 500, 250, 0, 20, 40, 5000, true);
    battlecardInfo[45] = BattleCard(45, 0, 2500, 0.02 ether, 0, 0, 100000, true);

    //InitUpgradeCard();
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setPLATPrice(uint256 price) external onlyOwner {
    PLATPrice = price;
  }
  function getPLATPrice() external view returns (uint256) {
    return PLATPrice;
  }
  function getVersion() external view returns(string) {
    return versionNo;
  }

  function InitUpgradeCard() external onlyOwner {
  //upgradecardId,coinCost,ethCost,upgradeClass,cardId,upgradeValue;
    CreateUpgradeCards(1,500,0,0,1,1);
    CreateUpgradeCards(2 ,0,0.02 ether,1,1,1);
    CreateUpgradeCards(3,0,0.1 ether,8,1,999);
    CreateUpgradeCards(4,0,0.02 ether,0,2,2);
    CreateUpgradeCards(5,5000,0,1,2,5);
    CreateUpgradeCards(6,0,0.1 ether,8,2,999);
    CreateUpgradeCards(7,5000,0,0,3,5);
    CreateUpgradeCards(8,0,0.1 ether,1,3,5);
    CreateUpgradeCards(9,5000000,0,8,3,999);
    CreateUpgradeCards(10,0,0.02 ether,0,4,4);
    CreateUpgradeCards(11,10000,0,1,4,5);
    CreateUpgradeCards(12,0,0.1 ether,8,4,999);
    CreateUpgradeCards(13,15000,0,0,5,6);
    CreateUpgradeCards(14,0,0.25 ether,1,5,5);
    CreateUpgradeCards(15,0,0.1 ether,8,5,999);
    CreateUpgradeCards(16,0,0.02 ether,0,6,8);
    CreateUpgradeCards(17,30000,0,1,6,5);
    CreateUpgradeCards(18,0,0.1 ether,8,6,999);
    CreateUpgradeCards(19,35000,0,0,7,25);
    CreateUpgradeCards(20,0,0.05 ether,1,7,5);
    CreateUpgradeCards(21,5000000,0,8,7,999);
    CreateUpgradeCards(22,0,0.02 ether,0,8,10);
    CreateUpgradeCards(23,75000,0,1,8,5);
    CreateUpgradeCards(24,0,0.1 ether,8,8,999);

    //for battle cards
    CreateUpgradeCards(25,1000,0,2,40,5);                 
    CreateUpgradeCards(26,2500,0,4,40,5);       
    CreateUpgradeCards(27,50000000,0,8,40,999); 
    CreateUpgradeCards(28,2500,0,4,41,5);       
    CreateUpgradeCards(29,5000,0,5,41,5);       
    CreateUpgradeCards(30,50000000,0,8,41,999); 
    CreateUpgradeCards(31,5000,0,2,42,10);      
    CreateUpgradeCards(32,7500,0,3,42,5);       
    CreateUpgradeCards(33,5000000,0,8,42,999);  
    CreateUpgradeCards(34,7500,0,2,43,5);       
    CreateUpgradeCards(35,10000,0,6,43,1000);   
    CreateUpgradeCards(36,50000000,0,8,43,999); 
    CreateUpgradeCards(37,10000,0,3,44,5);      
    CreateUpgradeCards(38,15000,0,5,44,5);      
    CreateUpgradeCards(39,50000000,0,8,44,999); 
    CreateUpgradeCards(40,25000,0,6,45,10000);  
    CreateUpgradeCards(41,50000,0,7,45,5);      
    CreateUpgradeCards(42,5000000,0,8,45,999); 
  } 

  function CreateBattleCards(uint256 _cardId, uint256 _baseCoinCost, uint256 _coinCostIncreaseHalf, uint256 _ethCost, uint _attackValue, uint256 _defenseValue, uint256 _coinStealingCapacity, bool _unitSellable) public onlyOwner {
    BattleCard memory _battlecard = BattleCard({
      cardId: _cardId,
      baseCoinCost: _baseCoinCost,
      coinCostIncreaseHalf: _coinCostIncreaseHalf,
      ethCost: _ethCost,
      attackValue: _attackValue,
      defenseValue: _defenseValue,
      coinStealingCapacity: _coinStealingCapacity,
      unitSellable: _unitSellable
    });
    battlecardInfo[_cardId] = _battlecard;
    currNumOfBattleCards = SafeMath.add(currNumOfBattleCards,1);
    newBattleCard(_cardId,_baseCoinCost,_coinCostIncreaseHalf,_ethCost,_attackValue,_defenseValue,_coinStealingCapacity);
    
  }

  function CreateCards(uint256 _cardId, uint256 _baseCoinCost, uint256 _coinCostIncreaseHalf, uint256 _ethCost, uint256 _baseCoinProduction, bool _unitSellable) public onlyOwner {
    Card memory _card = Card({
      cardId: _cardId,
      baseCoinCost: _baseCoinCost,
      coinCostIncreaseHalf: _coinCostIncreaseHalf,
      ethCost: _ethCost,
      baseCoinProduction: _baseCoinProduction,
      unitSellable: _unitSellable
    });
    cardInfo[_cardId] = _card;
    currNumOfCards = SafeMath.add(currNumOfCards,1);
    newCard(_cardId,_baseCoinCost,_coinCostIncreaseHalf,_ethCost,_baseCoinProduction);
  }

  function CreateUpgradeCards(uint256 _upgradecardId, uint256 _coinCost, uint256 _ethCost, uint256 _upgradeClass, uint256 _cardId, uint256 _upgradeValue) public onlyOwner {
    UpgradeCard memory _upgradecard = UpgradeCard({
      upgradecardId: _upgradecardId,
      coinCost: _coinCost,
      ethCost: _ethCost,
      upgradeClass: _upgradeClass,
      cardId: _cardId,
      upgradeValue: _upgradeValue
    });
    upgradeInfo[_upgradecardId] = _upgradecard;
    currNumOfUpgrades = SafeMath.add(currNumOfUpgrades,1);
    newUpgradeCard(_upgradecardId,_coinCost,_ethCost,_upgradeClass,_cardId,_upgradeValue); 
  }
  
  function getCostForCards(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256) {
    uint256 icount = existing;
    if (amount == 1) { 
      if (existing == 0) {  
        return cardInfo[cardId].baseCoinCost; 
      } else {
        return cardInfo[cardId].baseCoinCost + (existing * cardInfo[cardId].coinCostIncreaseHalf * 2);
            }
    } else if (amount > 1) { 
      uint256 existingCost;
      if (existing > 0) {
        existingCost = (cardInfo[cardId].baseCoinCost * existing) + (existing * (existing - 1) * cardInfo[cardId].coinCostIncreaseHalf);
      }
      icount = SafeMath.add(existing,amount);  
      uint256 newCost = SafeMath.add(SafeMath.mul(cardInfo[cardId].baseCoinCost, icount), SafeMath.mul(SafeMath.mul(icount, (icount - 1)), cardInfo[cardId].coinCostIncreaseHalf));
      return newCost - existingCost;
      }
  }

  function getCostForBattleCards(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256) {
    uint256 icount = existing;
    if (amount == 1) { 
      if (existing == 0) {  
        return battlecardInfo[cardId].baseCoinCost; 
      } else {
        return battlecardInfo[cardId].baseCoinCost + (existing * battlecardInfo[cardId].coinCostIncreaseHalf * 2);
            }
    } else if (amount > 1) {
      uint256 existingCost;
      if (existing > 0) {
        existingCost = (battlecardInfo[cardId].baseCoinCost * existing) + (existing * (existing - 1) * battlecardInfo[cardId].coinCostIncreaseHalf);
      }
      icount = SafeMath.add(existing,amount);  
      uint256 newCost = SafeMath.add(SafeMath.mul(battlecardInfo[cardId].baseCoinCost, icount), SafeMath.mul(SafeMath.mul(icount, (icount - 1)), battlecardInfo[cardId].coinCostIncreaseHalf));
      return newCost - existingCost;
    }
  }

  function getCostForUprade(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256) {
    if (amount == 1) { 
      if (existing == 0) {  
        return upgradeInfo[cardId].coinCost; 
      } else if (existing == 1 || existing == 4){
        return 0;
      }else if (existing == 2) {
        return upgradeInfo[cardId].coinCost * 50; 
    }else if (existing == 3) {
      return upgradeInfo[cardId].coinCost * 50 * 40; 
    }else if (existing == 5) {
      return upgradeInfo[cardId].coinCost * 50 * 40 * 30; 
    }
  }
  }

  function getWeakenedDefensePower(uint256 defendingPower) external pure returns (uint256) {
    return SafeMath.div(defendingPower,2);
  }
 
    /// @notice get the production card&#39;s ether cost
  function unitEthCost(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].ethCost;
  }

    /// @notice get the battle card&#39;s ether cost
  function unitBattleEthCost(uint256 cardId) external constant returns (uint256) {
    return battlecardInfo[cardId].ethCost;
  }
  /// @notice get the battle card&#39;s plat cost
  function unitBattlePLATCost(uint256 cardId) external constant returns (uint256) {
    return SafeMath.mul(battlecardInfo[cardId].ethCost,PLATPrice);
  }

    /// @notice normal production plat value
  function unitPLATCost(uint256 cardId) external constant returns (uint256) {
    return SafeMath.mul(cardInfo[cardId].ethCost,PLATPrice);
  }

  function unitCoinProduction(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].baseCoinProduction;
  }

  function unitAttack(uint256 cardId) external constant returns (uint256) {
    return battlecardInfo[cardId].attackValue;
  }
    
  function unitDefense(uint256 cardId) external constant returns (uint256) {
    return battlecardInfo[cardId].defenseValue;
  }

  function unitStealingCapacity(uint256 cardId) external constant returns (uint256) {
    return battlecardInfo[cardId].coinStealingCapacity;
  }
  
  function productionCardIdRange() external constant returns (uint256, uint256) {
    return (1, currNumOfCards);
  }

  function battleCardIdRange() external constant returns (uint256, uint256) {
    uint256 battleMax = SafeMath.add(39,currNumOfBattleCards);
    return (40, battleMax);
  }

  function upgradeIdRange() external constant returns (uint256, uint256) {
    return (1, currNumOfUpgrades);
  }
 
  function getcurrNumOfCards() external view returns (uint256) {
    return currNumOfCards;
  }

  function getcurrNumOfUpgrades() external view returns (uint256) {
    return currNumOfUpgrades;
  }
  // get the detail info of card 
  function getCardsInfo(uint256 cardId) external constant returns (
    uint256 baseCoinCost,
    uint256 coinCostIncreaseHalf,
    uint256 ethCost, 
    uint256 baseCoinProduction,
    uint256 platCost, 
    bool  unitSellable
  ) {
    baseCoinCost = cardInfo[cardId].baseCoinCost;
    coinCostIncreaseHalf = cardInfo[cardId].coinCostIncreaseHalf;
    ethCost = cardInfo[cardId].ethCost;
    baseCoinProduction = cardInfo[cardId].baseCoinProduction;
    platCost = SafeMath.mul(ethCost,PLATPrice);
    unitSellable = cardInfo[cardId].unitSellable;
  }
  //for production card
  function getCardInfo(uint256 cardId, uint256 existing, uint256 amount) external view returns 
  (uint256, uint256, uint256, uint256, bool) {
    return (cardInfo[cardId].cardId, 
    cardInfo[cardId].baseCoinProduction, 
    getCostForCards(cardId, existing, amount), 
    SafeMath.mul(cardInfo[cardId].ethCost, amount),
    cardInfo[cardId].unitSellable);
  }

   //for battle card
  function getBattleCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns 
  (uint256, uint256, uint256, bool) {
    return (battlecardInfo[cardId].cardId, 
    getCostForBattleCards(cardId, existing, amount), 
    SafeMath.mul(battlecardInfo[cardId].ethCost, amount),
    battlecardInfo[cardId].unitSellable);
  }

  //Battle Cards
  function getBattleCardsInfo(uint256 cardId) external constant returns (
    uint256 baseCoinCost,
    uint256 coinCostIncreaseHalf,
    uint256 ethCost, 
    uint256 attackValue,
    uint256 defenseValue,
    uint256 coinStealingCapacity,
    uint256 platCost,
    bool  unitSellable
  ) {
    baseCoinCost = battlecardInfo[cardId].baseCoinCost;
    coinCostIncreaseHalf = battlecardInfo[cardId].coinCostIncreaseHalf;
    ethCost = battlecardInfo[cardId].ethCost;
    attackValue = battlecardInfo[cardId].attackValue;
    defenseValue = battlecardInfo[cardId].defenseValue;
    coinStealingCapacity = battlecardInfo[cardId].coinStealingCapacity;
    platCost = SafeMath.mul(ethCost,PLATPrice);
    unitSellable = battlecardInfo[cardId].unitSellable;
  }

  function getUpgradeInfo(uint256 upgradeId) external constant returns (uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue,
    uint256 platCost) {
    
    coinCost = upgradeInfo[upgradeId].coinCost;
    ethCost = upgradeInfo[upgradeId].ethCost;
    upgradeClass = upgradeInfo[upgradeId].upgradeClass;
    cardId = upgradeInfo[upgradeId].cardId;
    upgradeValue = upgradeInfo[upgradeId].upgradeValue;
    platCost = SafeMath.mul(ethCost,PLATPrice);
  }
    //upgrade cards
  function getUpgradeCardsInfo(uint256 upgradecardId, uint256 existing) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue,
    uint256 platCost
    ) {
    coinCost = upgradeInfo[upgradecardId].coinCost;
    ethCost = upgradeInfo[upgradecardId].ethCost;
    upgradeClass = upgradeInfo[upgradecardId].upgradeClass;
    cardId = upgradeInfo[upgradecardId].cardId;
    if (upgradeClass==8) {
      upgradeValue = upgradeInfo[upgradecardId].upgradeValue;
      if (ethCost>0) {
        if (existing==1) {
          ethCost = 0.2 ether;
        } else if (existing==2) {
          ethCost = 0.5 ether;
        }
      } else {
        bool bf = false;
        if (upgradecardId == 27 || upgradecardId==30 || upgradecardId==36) { 
          bf = true;
        }
        if (bf == true) {
          if (existing==1) {
            coinCost = 0;
            ethCost = 0.1 ether;
          } else if (existing==2) {
            coinCost = 0;
            ethCost = 0.1 ether;
          }
        }else{
          if (existing==1) {
            coinCost = coinCost * 10;
          } else if (existing==2) {
            coinCost = coinCost * 100;
          }
        }
      }

      if (existing ==1) {
        upgradeValue = 9999;
      }else if (existing==2){
        upgradeValue = 99999;
      }
    } else {
      uint8 uflag;
      if (coinCost >0 ) {
        if (upgradeClass ==0 || upgradeClass ==1 || upgradeClass == 3) {
          uflag = 1;
        } else if (upgradeClass==2 || upgradeClass == 4 || upgradeClass==5 || upgradeClass==7) {
          uflag = 2;
        }
      }
   
      if (coinCost>0 && existing>=1) {
        coinCost = getCostForUprade(upgradecardId, existing, 1);
      }
      if (ethCost>0) {
        if (upgradecardId == 2) {
          if (existing>=1) { 
            ethCost = SafeMath.mul(ethCost,2);
          } 
        } 
      } else {
        if ((existing ==1 || existing ==4)) {
          if (ethCost<=0) {                                                                                                                                                                                                                                                                                                                                                                                                                                                 
            ethCost = 0.1 ether;
            coinCost = 0;
        }
      }
    }
      upgradeValue = upgradeInfo[upgradecardId].upgradeValue;
      if (ethCost>0) {
        if (uflag==1) {
          upgradeValue = upgradeInfo[upgradecardId].upgradeValue * 2;
        } else if (uflag==2) {
          upgradeValue = upgradeInfo[upgradecardId].upgradeValue * 4;
        } else {
          if (upgradeClass == 6){
            if (upgradecardId == 27){
              upgradeValue = upgradeInfo[upgradecardId].upgradeValue * 5;
            } else if (upgradecardId == 40) {
              upgradeValue = upgradeInfo[upgradecardId].upgradeValue * 3;
            }
          }
        }
      }
    }
    platCost = SafeMath.mul(ethCost,PLATPrice);

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