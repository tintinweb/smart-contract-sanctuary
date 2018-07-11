pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The Priate Conquest Project.  All rights reserved.
/* 
/* https://www.pirateconquest.com One of the world&#39;s slg games of blockchain 
/*  
/* authors rainy@livestar.com/Jonny.Fu@livestar.com
/*                 
/* ==================================================================== */
/// This Random is inspired by https://github.com/axiomzen/eth-random
contract Random {
    uint256 _seed;

    function _rand() internal returns (uint256) {
        _seed = uint256(keccak256(_seed, block.blockhash(block.number - 1), block.coinbase, block.difficulty));
        return _seed;
    }

    function _randBySeed(uint256 _outSeed) internal view returns (uint256) {
        return uint256(keccak256(_outSeed, block.blockhash(block.number - 1), block.coinbase, block.difficulty));
    }

    
    function _randByRange(uint256 _min, uint256 _max) internal returns (uint256) {
        if (_min >= _max) {
            return _min;
        }
        return (_rand() % (_max - _min +1)) + _min;
    }

    function _rankByNumber(uint256 _max) internal returns (uint256) {
        return _rand() % _max;
    }
    
}

interface CaptainTokenInterface {
  function CreateCaptainToken(address _owner,uint256 _price, uint32 _captainId, uint32 _color,uint32 _atk,uint32 _defense,uint32 _atk_min,uint32 _atk_max) public ;
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);
  function setTokenPrice(uint256 _tokenId, uint256 _price) external;
  function checkCaptain(address _owner,uint32 _captainId) external returns (bool);
  function setSelled(uint256 _tokenId, bool fsell) external;
}

interface CaptainGameConfigInterface {
  function getCardInfo(uint32 cardId) external constant returns (uint32,uint32,uint32, uint32,uint32,uint256,uint256);
  function getSellable(uint32 _captainId) external returns (bool);
  function getLevelConfig(uint32 cardId, uint32 level) external view returns (uint32 atk,uint32 defense,uint32 atk_min,uint32 atk_max);
}

contract CaptainPreSell is Random {
  using SafeMath for SafeMath;
  address devAddress;
  
  function CaptainPreSell() public {
    devAddress = msg.sender;
  }

  CaptainTokenInterface public captains;
  CaptainGameConfigInterface public config; 
  /// @dev The BuyToken event is fired whenever a token is sold.
  event BuyToken(uint256 tokenId, uint256 oldPrice, address prevOwner, address winner);
  
  //mapping
  mapping(uint32 => uint256) captainToCount;
  mapping(address => uint32[]) captainUserMap; 
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
    uint256 rdm = _randByRange(90,110) % 10000;
    // Safety check to prevent against an unexpected 0x0 default.
    require(msg.sender != address(0));
    require(!captains.checkCaptain(msg.sender,_captainId));
    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= price);
     //get the config
    uint32 atk_min;
    uint32 atk_max; 
    (,,atk_min,atk_max) = config.getLevelConfig(_captainId,1);
   
    atk_min = uint32(SafeMath.div(SafeMath.mul(uint256(atk_min),rdm),100));
    atk_max = uint32(SafeMath.div(SafeMath.mul(uint256(atk_max),rdm),100));
   
    price = SafeMath.div(SafeMath.mul(price,130),100);
    captains.CreateCaptainToken(msg.sender,price,_captainId,color,atk, defense,atk_min,atk_max);
  
    uint256 balance = captains.balanceOf(msg.sender);
    uint256 tokenId = captains.tokenOfOwnerByIndex(msg.sender,balance-1);
    captains.setTokenPrice(tokenId,price);
    //captains.setSelled(tokenId,true);
    captainToCount[_captainId] = SellCount;

    //transfer
    //devAddress.transfer(msg.value);
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

  function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
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

  function div32(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
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

  function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
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

  function add32(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}