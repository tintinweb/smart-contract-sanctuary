pragma solidity ^0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
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

pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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


contract zombieToken {
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function transfer(address to, uint tokens) public returns (bool success);
  function buyCard(address from, uint256 value) public returns (bool success);
}

contract zombieMain {
  function createZombie(uint8 star,bytes32 dna,uint16 roletype,bool isFreeZombie,address player) public;
}

contract zombieCreator is Ownable {

  using SafeMath for uint256;

  event NewZombie(bytes32 dna, uint8 star,uint16 roletype, bool isfree);

  mapping (address => bool) isGetFreeZombie;

  uint createRandomZombie_EtherPrice = 0.01 ether;
  uint createRandomZombie_ZOBToken_smallpack = 100 * 10 ** 18;
  uint createRandomZombie_ZOBToken_goldpack = 400 * 10 ** 18;
  
  zombieMain c = zombieMain(0x58fd762F76D57C6fC2a480F6d26c1D03175AD64F);
  zombieToken t = zombieToken(0x2Bb48FE71ba5f73Ab1c2B9775cfe638400110d34);
  
  uint public FreeZombieCount = 999999;

  function isGetFreeZombiew(address _owner) public view returns (bool _getFreeZombie) {
    return isGetFreeZombie[_owner];
  }

  function createRandomZombie_ZOB_smallpack() public {

    require(t.buyCard(msg.sender, createRandomZombie_ZOBToken_smallpack));
    
    for(uint8 i = 0;i<3;i++){
       
       bytes32 dna;

       if(i == 0){
         dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
       } else if(i == 1){
         dna = keccak256(msg.sender, now, block.blockhash(block.number-1), "CryptoDeads DNA Seed", block.coinbase, block.difficulty);
       } else {
         dna = keccak256("CryptoDeads DNA Seed", now, block.difficulty, block.coinbase, block.blockhash(block.number-1), msg.sender);
       }

       uint star = uint(dna) % 1000 +1;
       uint roletype = 1;

       if(star<=700){
            star = 1;
            roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 3 + 1;
       }else if(star <= 980){
            star = 2;
            roletype = 4;
       }else{
            star = 3;
            roletype = uint(keccak256(block.blockhash(block.number-1), msg.sender, block.difficulty, block.coinbase, now)) % 3 + 5; 
       }

       c.createZombie(uint8(star),dna,uint16(roletype),false,msg.sender);
       NewZombie(dna,uint8(star),uint16(roletype),false);
    }
  }

  function createRandomZombie_ZOB_goldpack() public {

    require(t.buyCard(msg.sender, createRandomZombie_ZOBToken_goldpack));
    
    for(uint8 i = 0;i<3;i++){

       bytes32 dna;
       
       if(i == 0){
         dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
       } else if(i == 1){
         dna = keccak256(msg.sender, now, block.blockhash(block.number-1), "CryptoDeads DNA Seed", block.coinbase, block.difficulty);
       } else {
         dna = keccak256("CryptoDeads DNA Seed", now, block.difficulty, block.coinbase, block.blockhash(block.number-1), msg.sender);
       }

       uint star = uint(dna) % 1000 +1;
       uint roletype = 2;

       if(star<=700){
            star = 2;
            roletype = 4;
       }else if(star <= 950){
            star = 3;
            roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 3 + 5;
       }else{
            star = 4;
            roletype = uint(keccak256(block.blockhash(block.number-1), msg.sender, block.difficulty, block.coinbase, now)) % 3 + 9;
       }

       c.createZombie(uint8(star),dna,uint16(roletype),false,msg.sender);
       NewZombie(dna,uint8(star),uint16(roletype),false);
    }
  }

  function createRandomZombie_FreeZombie() public {
    require(!isGetFreeZombie[msg.sender]);
    require(FreeZombieCount>=1);

    uint ran = uint(keccak256(block.coinbase,block.difficulty,now, block.blockhash(block.number-1))) % 100 + 1;

    uint roletype = 1;
    uint8 star = 1;

    if(ran>=90){
      roletype = 4;
      star = 2;
    } else {
      roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 3 + 1;
    }
    
    bytes32 dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
    
    c.createZombie(star,dna,uint16(roletype),true,msg.sender);
    isGetFreeZombie[msg.sender] = true;
    FreeZombieCount--;

    NewZombie(dna,uint8(star),uint16(roletype),true);
  }
  
  function createRandomZombie_Ether() public payable{
    require(msg.value == createRandomZombie_EtherPrice);
    
    for(uint8 i = 0;i<3;i++){
       bytes32 dna;
       
       if(i == 0){
         dna = keccak256(block.blockhash(block.number-1), block.difficulty, block.coinbase, now, msg.sender, "CryptoDeads DNA Seed");
       } else if(i == 1){
         dna = keccak256(msg.sender, now, block.blockhash(block.number-1), "CryptoDeads DNA Seed", block.coinbase, block.difficulty);
       } else {
         dna = keccak256("CryptoDeads DNA Seed", now, block.difficulty, block.coinbase, block.blockhash(block.number-1), msg.sender);
       }

       uint star = uint(dna) % 1000 + 1;
       uint roletype = 4;

       if(star<=500){
            star = 2;
       }else if(star <= 850){
            star = 3;
            roletype = uint(keccak256(msg.sender ,block.blockhash(block.number-1), block.coinbase, now, block.difficulty)) % 4 + 5;
       }else{
            star = 4;
            roletype = uint(keccak256(block.blockhash(block.number-1), msg.sender, block.difficulty, block.coinbase, now)) % 4 + 9;
       } 

       c.createZombie(uint8(star),dna,uint16(roletype),false,msg.sender);
       
       NewZombie(dna,uint8(star),uint16(roletype),true);
    }
  }
  
  function changeFreeZombiewCount(uint16 _count) public onlyOwner {
      FreeZombieCount = _count;
  }
  
  function withdrawEther(uint _ether) public onlyOwner{
      msg.sender.transfer(_ether);
  }

  function withdrawZOB(uint _zob) public onlyOwner{
      t.transfer(msg.sender, _zob);
  }
}