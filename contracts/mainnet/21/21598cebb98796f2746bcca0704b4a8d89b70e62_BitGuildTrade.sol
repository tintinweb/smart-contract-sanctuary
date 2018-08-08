pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
/*  
/* authors rainy@livestar.com/fanny.zheng@livestar.com
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

interface BitGuildTokenInterface { // implements ERC20Interface
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface CardsInterface {
  function getGameStarted() external constant returns (bool);
  function getOwnedCount(address player, uint256 cardId) external view returns (uint256);
  function getMaxCap(address _addr,uint256 _cardId) external view returns (uint256);
  function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external;
  function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external;
  function balanceOf(address player) public constant returns(uint256);
  function coinBalanceOf(address player,uint8 itype) external constant returns(uint256);
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) external;
  function getUnitsProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256);
  function increasePlayersJadeProduction(address player, uint256 increase) public;
  function setUintCoinProduction(address _address, uint256 cardId, uint256 iValue, bool iflag) external;
  function getUintsOwnerCount(address _address) external view returns (uint256);
  function AddPlayers(address _address) external;
  function setUintsOwnerCount(address _address, uint256 amount, bool iflag) external;
  function setOwnedCount(address player, uint256 cardId, uint256 amount, bool iflag) external;
  function setCoinBalance(address player, uint256 eth, uint8 itype, bool iflag) external;
  function setTotalEtherPool(uint256 inEth, uint8 itype, bool iflag) external;
  function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256);
  function setUpgradesOwned(address player, uint256 upgradeId) external;
  function updatePlayersCoinByOut(address player) external;
  function balanceOfUnclaimed(address player) public constant returns (uint256);
  function setLastJadeSaveTime(address player) external;
  function setRoughSupply(uint256 iroughSupply) external;
  function setJadeCoin(address player, uint256 coin, bool iflag) external;
  function getUnitsInProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256);
  function reducePlayersJadeProduction(address player, uint256 decrease) public;
}
interface GameConfigInterface {
  function unitCoinProduction(uint256 cardId) external constant returns (uint256);
  function unitPLATCost(uint256 cardId) external constant returns (uint256);
  function getCostForCards(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256);
  function getCostForBattleCards(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256);
  function unitBattlePLATCost(uint256 cardId) external constant returns (uint256);
  function getUpgradeCardsInfo(uint256 upgradecardId,uint256 existing) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue,
    uint256 platCost
  );
 function getCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256, bool);
 function getBattleCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, bool);

}
interface RareInterface {
  function getRareItemsOwner(uint256 rareId) external view returns (address);
  function getRareItemsPrice(uint256 rareId) external view returns (uint256);
  function getRareItemsPLATPrice(uint256 rareId) external view returns (uint256);
   function getRarePLATInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  );
  function transferToken(address _from, address _to, uint256 _tokenId) external;
  function setRarePrice(uint256 _rareId, uint256 _price) external;
}

contract BitGuildTrade is AccessAdmin {
  BitGuildTokenInterface public tokenContract;
   //data contract
  CardsInterface public cards ;
  GameConfigInterface public schema;
  RareInterface public rare;

  
  function BitGuildTrade() public {
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }

  event UnitBought(address player, uint256 unitId, uint256 amount);
  event UpgradeCardBought(address player, uint256 upgradeId);
  event BuyRareCard(address player, address previous, uint256 rareId,uint256 iPrice);
  event UnitSold(address player, uint256 unitId, uint256 amount);

  mapping(address => mapping(uint256 => uint256)) unitsOwnedOfPLAT; //cards bought through plat
  function() external payable {
    revert();
  }
  function setBitGuildToken(address _tokenContract) external onlyOwner {
    tokenContract = BitGuildTokenInterface(_tokenContract);
  } 

  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

   //normal cards
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

  //rare cards
  function setRareAddress(address _address) external onlyOwner {
    rare = RareInterface(_address);
  }
  function kill() public onlyOwner {
    tokenContract.transferFrom(this, msg.sender, tokenContract.balanceOf(this));
    selfdestruct(msg.sender); //end execution, destroy current contract and send funds to a
  }  
  /// @notice Returns all the relevant information about a specific tokenId.
  /// val1:flag,val2:id,val3:amount
  function _getExtraParam(bytes _extraData) private pure returns(uint256 val1,uint256 val2,uint256 val3) {
    if (_extraData.length == 2) {
      val1 = uint256(_extraData[0]);
      val2 = uint256(_extraData[1]);
      val3 = 1; 
    } else if (_extraData.length == 3) {
      val1 = uint256(_extraData[0]);
      val2 = uint256(_extraData[1]);
      val3 = uint256(_extraData[2]);
    }  
  }
  
  function receiveApproval(address _player, uint256 _value, address _tokenContractAddr, bytes _extraData) external {
    require(msg.sender == _tokenContractAddr);
    require(_extraData.length >=1);
    require(tokenContract.transferFrom(_player, address(this), _value));
    uint256 flag;
    uint256 unitId;
    uint256 amount;
    (flag,unitId,amount) = _getExtraParam(_extraData);

    if (flag==1) {
      buyPLATCards(_player, _value, unitId, amount);  // 1-39
    } else if (flag==3) {
      buyUpgradeCard(_player, _value, unitId);  // >=1
    } else if (flag==4) {
      buyRareItem(_player, _value, unitId); //rarecard
    } 
  } 

  /// buy normal cards via jade
  function buyBasicCards(uint256 unitId, uint256 amount) external {
    require(cards.getGameStarted());
    require(amount>=1);
    uint256 existing = cards.getOwnedCount(msg.sender,unitId);
    uint256 total = SafeMath.add(existing, amount);
    if (total > 99) { // Default unit limit
      require(total <= cards.getMaxCap(msg.sender,unitId)); // Housing upgrades (allow more units)
    }

    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    if (unitId>=1 && unitId<=39) {    
      (, coinProduction, coinCost, ethCost,) = schema.getCardInfo(unitId, existing, amount);
    } else if (unitId>=40) {
      (, coinCost, ethCost,) = schema.getBattleCardInfo(unitId, existing, amount);
    }
    require(cards.balanceOf(msg.sender) >= coinCost);
    require(ethCost == 0); // Free ether unit
        
    // Update players jade 
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);
    ///****increase production***/
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(msg.sender,cards.getUnitsProduction(msg.sender, unitId, amount)); 
      cards.setUintCoinProduction(msg.sender,unitId,cards.getUnitsProduction(msg.sender, unitId, amount),true); 
    }
    //players
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }
    cards.setUintsOwnerCount(msg.sender,amount,true);
    cards.setOwnedCount(msg.sender,unitId,amount,true);
    
    UnitBought(msg.sender, unitId, amount);
  }

  function buyBasicCards_Migrate(address _addr, uint256 _unitId, uint256 _amount) external onlyAdmin {
    require(cards.getGameStarted());
    require(_amount>=1);
    uint256 existing = cards.getOwnedCount(_addr,_unitId);
    uint256 total = SafeMath.add(existing, _amount);
    if (total > 99) { // Default unit limit
      require(total <= cards.getMaxCap(_addr,_unitId)); // Housing upgrades (allow more units)
    }
    require (_unitId == 41);
    uint256 coinCost;
    uint256 ethCost;
    (, coinCost, ethCost,) = schema.getBattleCardInfo(_unitId, existing, _amount);
    //players
    if (cards.getUintsOwnerCount(_addr)<=0) {
      cards.AddPlayers(_addr);
    }
    cards.setUintsOwnerCount(_addr,_amount,true);
    cards.setOwnedCount(_addr,_unitId,_amount,true);
    
    UnitBought(_addr, _unitId, _amount);
  }

  function buyPLATCards(address _player, uint256 _platValue, uint256 _cardId, uint256 _amount) internal {
    require(cards.getGameStarted());
    require(_amount>=1);
    uint256 existing = cards.getOwnedCount(_player,_cardId);
    uint256 total = SafeMath.add(existing, _amount);
    if (total > 99) { // Default unit limit
      require(total <= cards.getMaxCap(msg.sender,_cardId)); // Housing upgrades (allow more units)
    }

    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;

    if (_cardId>=1 && _cardId<=39) {
      coinProduction = schema.unitCoinProduction(_cardId);
      coinCost = schema.getCostForCards(_cardId, existing, _amount);
      ethCost = SafeMath.mul(schema.unitPLATCost(_cardId),_amount);  // get platprice
    } else if (_cardId>=40) {
      coinCost = schema.getCostForBattleCards(_cardId, existing, _amount);
      ethCost = SafeMath.mul(schema.unitBattlePLATCost(_cardId),_amount);  // get platprice
    }

    require(ethCost>0);
    require(SafeMath.add(cards.coinBalanceOf(_player,1),_platValue) >= ethCost);
    require(cards.balanceOf(_player) >= coinCost);   

    // Update players jade  
    cards.updatePlayersCoinByPurchase(_player, coinCost);

    if (ethCost > _platValue) {
      cards.setCoinBalance(_player,SafeMath.sub(ethCost,_platValue),1,false);
    } else if (_platValue > ethCost) {
      // Store overbid in their balance
      cards.setCoinBalance(_player,SafeMath.sub(_platValue,ethCost),1,true);
    } 

    uint256 devFund = uint256(SafeMath.div(ethCost,20)); // 5% fee
    cards.setTotalEtherPool(uint256(SafeMath.div(ethCost,4)),1,true);  // 20% to pool
    cards.setCoinBalance(owner,devFund,1,true);  
    
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(_player, cards.getUnitsProduction(_player, _cardId, _amount)); 
      cards.setUintCoinProduction(_player,_cardId,cards.getUnitsProduction(_player, _cardId, _amount),true); 
    }
    
    if (cards.getUintsOwnerCount(_player)<=0) {
      cards.AddPlayers(_player);
    }
    cards.setUintsOwnerCount(_player,_amount, true);
    cards.setOwnedCount(_player,_cardId,_amount,true);
    unitsOwnedOfPLAT[_player][_cardId] = SafeMath.add(unitsOwnedOfPLAT[_player][_cardId],_amount);
    //event
    UnitBought(_player, _cardId, _amount);
  }

  /// buy upgrade cards with ether/Jade
  function buyUpgradeCard(uint256 upgradeId) external payable {
    require(cards.getGameStarted());
    require(upgradeId>=1);
    uint256 existing = cards.getUpgradesOwned(msg.sender,upgradeId);
    
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (coinCost, ethCost, upgradeClass, unitId, upgradeValue,) = schema.getUpgradeCardsInfo(upgradeId,existing);
    if (upgradeClass<8) {
      require(existing<=5); 
    } else {
      require(existing<=2); 
    }
    require (coinCost>0 && ethCost==0);
    require(cards.balanceOf(msg.sender) >= coinCost);  
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);

    cards.upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);  
    cards.setUpgradesOwned(msg.sender,upgradeId); //upgrade cards level

    UpgradeCardBought(msg.sender, upgradeId);
  }

  /// upgrade cards-- jade + plat
  function buyUpgradeCard(address _player, uint256 _platValue,uint256 _upgradeId) internal {
    require(cards.getGameStarted());
    require(_upgradeId>=1);
    uint256 existing = cards.getUpgradesOwned(_player,_upgradeId);
    require(existing<=5);  // v1 - v6
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    uint256 platCost;
    (coinCost, ethCost, upgradeClass, unitId, upgradeValue,platCost) = schema.getUpgradeCardsInfo(_upgradeId,existing);

    require(platCost>0);
    if (platCost > 0) {
      require(SafeMath.add(cards.coinBalanceOf(_player,1),_platValue) >= platCost); 

      if (platCost > _platValue) { // They can use their balance instead
        cards.setCoinBalance(_player, SafeMath.sub(platCost,_platValue),1,false);
      } else if (platCost < _platValue) {  
        cards.setCoinBalance(_player,SafeMath.sub(_platValue,platCost),1,true);
    } 
      // defund 5%，upgrade card can not be sold，
      uint256 devFund = uint256(SafeMath.div(platCost, 20)); // 5% fee on purchases (marketing, gameplay & maintenance)
      cards.setTotalEtherPool(SafeMath.sub(platCost,devFund),1,true); // Rest goes to div pool (Can&#39;t sell upgrades)
      cards.setCoinBalance(owner,devFund,1,true);  
    }
        
     // Update 
    require(cards.balanceOf(_player) >= coinCost);  
    cards.updatePlayersCoinByPurchase(_player, coinCost);
    
    //add weight
    cards.upgradeUnitMultipliers(_player, upgradeClass, unitId, upgradeValue);  
    cards.setUpgradesOwned(_player,_upgradeId); // upgrade level up

     //add user to userlist
    if (cards.getUintsOwnerCount(_player)<=0) {
      cards.AddPlayers(_player);
    }
 
    UpgradeCardBought(_player, _upgradeId);
  }


  // Allows someone to send ether and obtain the token
  function buyRareItem(address _player, uint256 _platValue,uint256 _rareId) internal {
    require(cards.getGameStarted());        
    address previousOwner = rare.getRareItemsOwner(_rareId);  // rare card
    require(previousOwner != 0);
    require(_player!=previousOwner);  // can not buy from itself
    
    uint256 ethCost = rare.getRareItemsPLATPrice(_rareId); // get plat cost
    uint256 totalCost = SafeMath.add(cards.coinBalanceOf(_player,1),_platValue);
    require(totalCost >= ethCost); 
    // We have to claim buyer/sellder&#39;s goo before updating their production values 
    cards.updatePlayersCoinByOut(_player);
    cards.updatePlayersCoinByOut(previousOwner);

    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (,,,,upgradeClass, unitId, upgradeValue) = rare.getRarePLATInfo(_rareId);
    
    // modify weight
    cards.upgradeUnitMultipliers(_player, upgradeClass, unitId, upgradeValue); 
    cards.removeUnitMultipliers(previousOwner, upgradeClass, unitId, upgradeValue); 

    // Splitbid/Overbid
    if (ethCost > _platValue) {
      cards.setCoinBalance(_player,SafeMath.sub(ethCost,_platValue),1,false);
    } else if (_platValue > ethCost) {
      // Store overbid in their balance
      cards.setCoinBalance(_player,SafeMath.sub(_platValue,ethCost),1,true);
    }  
    // Distribute ethCost  uint256 devFund = ethCost / 50; 
    uint256 devFund = uint256(SafeMath.div(ethCost, 20)); // 5% fee on purchases (marketing, gameplay & maintenance)  抽成2%
    uint256 dividends = uint256(SafeMath.div(ethCost,20)); // 5% goes to pool 

    cards.setTotalEtherPool(dividends,1,true);  // 5% to pool
    cards.setCoinBalance(owner,devFund,1,true);  // 5% fee
        
    // Transfer / update rare item
    rare.transferToken(previousOwner,_player,_rareId); 
    rare.setRarePrice(_rareId,SafeMath.div(SafeMath.mul(rare.getRareItemsPrice(_rareId),5),4));
    
    cards.setCoinBalance(previousOwner,SafeMath.sub(ethCost,SafeMath.add(dividends,devFund)),1,true);
    
    if (cards.getUintsOwnerCount(_player)<=0) {
      cards.AddPlayers(_player);
    }
   
    cards.setUintsOwnerCount(_player,1,true);
    cards.setUintsOwnerCount(previousOwner,1,true);

    //tell the world
    BuyRareCard(_player, previousOwner, _rareId, ethCost);
  }

  /// refunds 75% since no transfer between bitguild and player,no need to call approveAndCall
  function sellCards( uint256 _unitId, uint256 _amount) external {
    require(cards.getGameStarted());
    uint256 existing = cards.getOwnedCount(msg.sender,_unitId);
    require(existing >= _amount && _amount>0); 
    existing = SafeMath.sub(existing,_amount);
    uint256 coinChange;
    uint256 decreaseCoin;
    uint256 schemaUnitId;
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    bool sellable;
    if (_unitId>=40) { // upgrade card
      (schemaUnitId,coinCost,, sellable) = schema.getBattleCardInfo(_unitId, existing, _amount);
      ethCost = SafeMath.mul(schema.unitBattlePLATCost(_unitId),_amount);
    } else {
      (schemaUnitId, coinProduction, coinCost, , sellable) = schema.getCardInfo(_unitId, existing, _amount);
      ethCost = SafeMath.mul(schema.unitPLATCost(_unitId),_amount); // plat 
    }
    require(sellable);  // can be refunded
    if (ethCost>0) {
      require(unitsOwnedOfPLAT[msg.sender][_unitId]>=_amount);
    }
    if (coinCost>0) {
      coinChange = SafeMath.add(cards.balanceOfUnclaimed(msg.sender), SafeMath.div(SafeMath.mul(coinCost,70),100)); // Claim unsaved goo whilst here
    } else {
      coinChange = cards.balanceOfUnclaimed(msg.sender); 
    }

    cards.setLastJadeSaveTime(msg.sender); 
    cards.setRoughSupply(coinChange);  
    cards.setJadeCoin(msg.sender, coinChange, true); // refund 75% Jadecoin to player 

    decreaseCoin = cards.getUnitsInProduction(msg.sender, _unitId, _amount);
  
    if (coinProduction > 0) { 
      cards.reducePlayersJadeProduction(msg.sender, decreaseCoin);
      //update the speed of jade minning
      cards.setUintCoinProduction(msg.sender,_unitId,decreaseCoin,false); 
    }

    if (ethCost > 0) { // Premium units sell for 75% of buy cost
      cards.setCoinBalance(msg.sender,SafeMath.div(SafeMath.mul(ethCost,70),100),1,true);
    }

    cards.setOwnedCount(msg.sender,_unitId,_amount,false); 
    cards.setUintsOwnerCount(msg.sender,_amount,false);
    if (ethCost>0) {
      unitsOwnedOfPLAT[msg.sender][_unitId] = SafeMath.sub(unitsOwnedOfPLAT[msg.sender][_unitId],_amount);
    }
    //tell the world
    UnitSold(msg.sender, _unitId, _amount);
  }

  //@notice for player withdraw
  function withdrawEtherFromTrade(uint256 amount) external {
    require(amount <= cards.coinBalanceOf(msg.sender,1));
    cards.setCoinBalance(msg.sender,amount,1,false);
    tokenContract.transfer(msg.sender,amount);
  } 

  //@notice withraw all PLAT by dev
  function withdrawToken(uint256 amount) external onlyOwner {
    uint256 balance = tokenContract.balanceOf(this);
    require(balance > 0 && balance >= amount);
    tokenContract.transfer(msg.sender, amount);
  }

  function getCanSellUnit(address _address, uint256 unitId) external view returns (uint256) {
    return unitsOwnedOfPLAT[_address][unitId];
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