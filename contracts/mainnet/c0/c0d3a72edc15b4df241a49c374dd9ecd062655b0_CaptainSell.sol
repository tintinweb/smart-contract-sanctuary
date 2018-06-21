pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The Priate Conquest Project.  All rights reserved.
/* 
/* https://www.pirateconquest.com One of the world&#39;s slg games of blockchain 
/*  
/* authors rainy@livestar.com/Jonny.Fu@livestar.com
/*                 
/* ==================================================================== */
interface CaptainTokenInterface {
  function CreateCaptainToken(address _owner,uint256 _price, uint32 _captainId, uint32 _color,uint32 _atk, uint32 _defense,uint32 _level,uint256 _exp) public;
}

interface CaptainGameConfigInterface {
  function getCardInfo(uint32 cardId) external constant returns (uint32,uint32,uint32, uint32,uint32,uint256,uint256);
  function getSellable(uint32 _captainId) external returns (bool);
}
contract CaptainSell {

  address devAddress;
  function CaptainSell() public {
    devAddress = msg.sender;
  }

  CaptainTokenInterface public captains;
  CaptainGameConfigInterface public config; 
  /// @dev The BuyToken event is fired whenever a token is sold.
  event BuyToken(uint256 tokenId, uint256 oldPrice, address prevOwner, address winner);
  
  //mapping
  mapping(uint32 => uint256) captainToCount; 
  /// @notice No tipping!
  /// @dev Reject all Ether from being sent here, unless it&#39;s from one of the
  ///  two auction contracts. (Hopefully, we can prevent user accidents.)
  function() external payable {
  }

  modifier onlyOwner() {
    require(msg.sender == devAddress);
    _;
  }

  //setting configuration
  function setGameConfigContract(address _address) external onlyOwner {
    config = CaptainGameConfigInterface(_address);
  }

  //setting configuration
  function setCaptainTokenContract(address _address) external onlyOwner {
    captains = CaptainTokenInterface(_address);
  }


  function prepurchase(uint32 _captainId) external payable {
    uint32 color;
    uint32 atk;
    uint32 defense;
    uint256 price;
    uint256 captainCount;
    uint256 SellCount = captainToCount[_captainId];
    (color,atk,,,defense,price,captainCount) = config.getCardInfo(_captainId);
    require(config.getSellable(_captainId) == true);
    SellCount += 1;
    require(SellCount<=captainCount);

    // Safety check to prevent against an unexpected 0x0 default.
    require(msg.sender != address(0));
    
    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= price);
    captains.CreateCaptainToken(msg.sender,price,_captainId,color,atk, defense,1,0);
    captainToCount[_captainId] = SellCount;

    //transfer
    devAddress.transfer(msg.value);
    //event 
    BuyToken(_captainId, price,address(this),msg.sender);
  }

  function getCaptainCount(uint32 _captainId) external constant returns (uint256) {
    return captainToCount[_captainId];
  }

  //@notice withraw all by dev
  function withdraw() external onlyOwner {
    require(this.balance>0);
    msg.sender.transfer(this.balance);
  }

}