// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract faFactory is Ownable {

  using SafeMath for uint256;
  using SafeMath32 for uint32;
  using SafeMath16 for uint16;

  event NewFA(uint16 faId, uint32 dna);

  uint16 FA_MAX_SUPPLY = 12125;
  uint16 numberOfFAminted = 0;
  
  uint32 [5] classIndex  = [0, 0, 0, 0, 0];
  
  uint8 dnaDigits = 6; //1 + fa (1-2425) + class (1-5)
  uint32 dnaModulus = uint32(10 ** dnaDigits);
  uint cooldownTime = 1 days;

  struct FA {
    uint32 dna;
    uint32 readyTime;
    uint32 winCount;
    uint32 lossCount;
    uint16 rarity;
    uint16 life;
    uint16 armour;
    uint16 attack;
    uint16 defence;
    uint16 magic;
    uint16 stamina;
    string color;
    string animation;
  }

  FA [] FAs;

  mapping (uint16 => address) public faToOwner;
  mapping (address => uint) ownerFACount;

  modifier validDna (uint32 _dna) {
    require(_dna.mod(dnaModulus) <= 124255);
    require(_dna.mod(dnaModulus-1) <= 24255);
    require(_dna.mod(dnaModulus-1).div(10) <= 2425);
    require(_dna.mod(10) > 0);
    require(_dna.mod(10) <= 5);
    _;
  }
    
  function _createFA(uint32 _dna, uint16 _rarity) private validDna(_dna) {
    FAs.push(FA(_dna, uint32(block.timestamp), 0, 0, _rarity, 10, 10, 10, 10, 10, 5, "lime", "floating"));  
    uint16 id = uint16(FAs.length).sub(1);
    faToOwner[id] = msg.sender;
    ownerFACount[msg.sender] = ownerFACount[msg.sender].add(1);
    emit NewFA(id, _dna);
  }

  function _generateRandomRarity() private view returns (uint16) {
    uint randRarity = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
    uint randRarity100 = randRarity.mod(100);
    uint16 _rarity = 0;
    
    if (randRarity100 < 70)
        _rarity = 1; //common - 70% probability
    if ((randRarity100 >= 70) && (randRarity100 < 85))
        _rarity = 2; //rare - 15% probability
    if ((randRarity100 >= 85) && (randRarity100 < 95))
        _rarity = 3; //epic - 10% probability
    if (randRarity100 >= 95)
        _rarity = 4; //legendary - 5% probability
        
    return _rarity;
  }

  function _makeFA(uint8 _class) public  {
    if (_class==1)
        require(classIndex[0]<2425);
    if (_class==2)
        require(classIndex[1]<2425);
    if (_class==3)
        require(classIndex[2]<2425);
    if (_class==4)
        require(classIndex[3]<2425);
    if (_class==5)
        require(classIndex[4]<2425);
    uint16 _rarity =  _generateRandomRarity();
    uint32 _dna = classIndex[_class].mul(10).add(100000).add(_class);
    _createFA(_dna, _rarity);
    classIndex[_class].add(1);
    numberOfFAminted.add(1);
  }
  

}