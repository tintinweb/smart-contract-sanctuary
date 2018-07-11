pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The Priate Conquest Project.  All rights reserved.
/* 
/* https://www.pirateconquest.com One of the world&#39;s slg games of blockchain 
/*  
/* authors rainy@livestar.com/fanny.zheng@livestar.com
/*                 
/* ==================================================================== */
contract CaptainGameConfig {
  address owner;
  struct Card {
    uint32 cardId;
    uint32 color;
    uint32 atk;
    uint32 defense;
    uint32 stype;
    uint256 price;
  }

  /** mapping**/
  mapping(uint256 => Card) private cardInfo;  //normal card
  mapping(uint32 => uint256) public captainIndxToCount;
  mapping(uint32 => uint32) private calfactor;
  mapping(uint32 => bool) private unitSellable;

  function CaptainGameConfig() public {
    owner = msg.sender;
    cardInfo[1] = Card(1, 2, 2640, 960, 1, 0.475 ether);
    cardInfo[2] = Card(2, 1, 1625, 250, 2, 0.245 ether);
    cardInfo[3] = Card(3, 4, 6760, 1040, 2, 0.99 ether);
    cardInfo[4] = Card(4, 3, 2640, 2310, 3, 0.66 ether);
    cardInfo[5] = Card(5, 4, 4160, 3640, 3, 0.99 ether);
    cardInfo[6] = Card(6, 4, 5720, 2080, 1, 0.99 ether);
    cardInfo[7] = Card(7, 2, 3120, 480, 2, 0.475 ether);
    cardInfo[8] = Card(8, 3, 3630, 1320, 1, 0.66 ether);
    cardInfo[9] = Card(9, 1, 1625, 250, 2, 0.245 ether);

    captainIndxToCount[1] = 50; 
    captainIndxToCount[2] = 50;
    captainIndxToCount[3] = 30;
    captainIndxToCount[4] = 40;
    captainIndxToCount[5] = 30;
    captainIndxToCount[6] = 30;
    captainIndxToCount[7] = 40;
    captainIndxToCount[8] = 40;
    captainIndxToCount[9] = 60;

    calfactor[1] = 80; //for atk_min & atk_max calculate
    calfactor[2] = 85;
    calfactor[3] = 90;
    calfactor[4] = 95;

    unitSellable[2] = true;
    unitSellable[3] = true;
    unitSellable[4] = true;
    unitSellable[5] = true;
    unitSellable[6] = true;
    unitSellable[7] = true;
  }

  function getCardInfo(uint32 cardId) external constant returns (uint32,uint32,uint32,uint32,uint32,uint256,uint256) {
    return (
      cardInfo[cardId].color,
      cardInfo[cardId].atk, 
      cardInfo[cardId].atk*calfactor[cardInfo[cardId].color]/100,
      cardInfo[cardId].atk*(200-calfactor[cardInfo[cardId].color])/100,
      cardInfo[cardId].defense,
      cardInfo[cardId].price,
      captainIndxToCount[cardId]);
  }    


  function getCardType(uint32 cardId) external constant returns (uint32){
    return cardInfo[cardId].stype;
  }
  function addCard(uint32 id, uint32 color, uint32 atk,uint32 defense, uint32 stype, uint256 price) external {
    require(msg.sender == owner);
    cardInfo[id] = Card(id, color, atk, defense, stype, price);
  }
  
  function setCaptainIndexToCount(uint32 _id, uint256 _count) external {
    require(msg.sender == owner);
    captainIndxToCount[_id] = _count;
  }
  function getCaptainIndexToCount(uint32 _id) external constant returns (uint256) {
    return captainIndxToCount[_id];
  }

  function getCalFactor(uint32 _color) external constant returns (uint32) {
    return calfactor[_color];
  }
  function setCalFactor(uint32 _color, uint32 _factor) external {
    require(msg.sender == owner);
    calfactor[_color] = _factor;
  }

  function getSellable(uint32 _captainId) external constant returns (bool) {
    return unitSellable[_captainId];
  }

  function setSellable(uint32 _captainId,bool b) external {
    require(msg.sender == owner);
    unitSellable[_captainId] = b;
  }

  function getLevelConfig(uint32 cardId, uint32 level) external view returns (uint32 atk,uint32 defense,uint32 atk_min,uint32 atk_max) {
    atk = cardInfo[cardId].atk;
    defense = cardInfo[cardId].defense;
    if (level==2) {
      atk = atk * 150/100;
      defense = defense * 150/100;
    } else if (level>=3) {
      atk = atk * (level-1)*2 - atk * (level-2)* 150/100 - atk*50/100;
      defense = defense * (level-1)*2 - (level-2) * defense * 150/100 - defense*50/100;
    }
    atk_min = atk*calfactor[cardInfo[cardId].color]/100;
    atk_max = atk*(200-calfactor[cardInfo[cardId].color])/100;
  }  
}