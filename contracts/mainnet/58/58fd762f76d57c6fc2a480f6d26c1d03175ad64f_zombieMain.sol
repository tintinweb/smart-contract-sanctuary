pragma solidity ^0.4.19;

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
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



contract zombieMain is  ERC721,Ownable {

  using SafeMath for uint256;

  struct Zombie {
    bytes32 dna;
    uint8 star;
    uint16 roletype;
    bool isFreeZombie;
  }

  Zombie[] public zombies;
  
  address public ZombiewCreator;

  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) ownerZombieCount;
  mapping (uint => address) zombieApprovals;

  event Transfer(address _from, address _to,uint _tokenId);
  event Approval(address _from, address _to,uint _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(uint _tokenId, bytes32 dna,uint8 star, uint16 roletype);

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerZombieCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return zombieToOwner[_tokenId];
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != zombieToOwner[_tokenId[i]]){
            return false;
        }
    }
    
    return true;
  }

  function seeZombieDna(uint256 _tokenId) public view returns (bytes32 dna) {
    return zombies[_tokenId].dna;
  }

  function seeZombieStar(uint256 _tokenId) public view returns (uint8 star) {
    return zombies[_tokenId].star;
  }
  
  function seeZombieRole(uint256 _tokenId) public view returns (uint16 roletype) {
    return zombies[_tokenId].roletype;
  }

  function getZombiesByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerZombieCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < zombies.length; i++) {
      if (zombieToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function transfer(address _to, uint256 _tokenId) public {
    require(zombieToOwner[_tokenId] == msg.sender);
    require(!zombies[_tokenId].isFreeZombie);
    
    ownerZombieCount[_to] = ownerZombieCount[_to].add(1);
    ownerZombieCount[msg.sender] =  ownerZombieCount[msg.sender].sub(1);
    zombieToOwner[_tokenId] = _to;
    
    Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(zombieToOwner[_tokenId] == msg.sender);
    require(!zombies[_tokenId].isFreeZombie);
    
    zombieApprovals[_tokenId] = _to;
    
    Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(zombieApprovals[_tokenId] == msg.sender);
    require(!zombies[_tokenId].isFreeZombie);
    
    address owner = ownerOf(_tokenId);

    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].add(1);
    ownerZombieCount[owner] = ownerZombieCount[owner].sub(1);
    zombieToOwner[_tokenId] = msg.sender;
    
    Take(msg.sender, owner, _tokenId);
  }
  
  function createZombie(uint8 star,bytes32 dna,uint16 roletype,bool isFreeZombie,address player) public {
      require(msg.sender == ZombiewCreator); // only creator can call
 
      uint id = zombies.push(Zombie(dna, star, roletype, isFreeZombie)) - 1;
      zombieToOwner[id] = player;
      ownerZombieCount[player]++;
      
      Create(id, dna, star, roletype);
  }
  
  function changeZombieCreator(address _zombiewCreator) public onlyOwner{
    ZombiewCreator = _zombiewCreator;
  }

  function getZombiesFullInfoByOwner(address _owner) external view returns(uint[] id,bytes32[] dna, uint8[] star,uint16[] roletype,bool[] isFreeZombie) {
   uint[]  memory idb = new uint[](ownerZombieCount[_owner]);
   bytes32[]  memory dnab = new bytes32[](ownerZombieCount[_owner]);
   uint8[]  memory starb = new uint8[](ownerZombieCount[_owner]);
   uint16[]  memory roletypeb = new uint16[](ownerZombieCount[_owner]);
   bool[]  memory isFreeZombieb = new bool[](ownerZombieCount[_owner]);
   uint counter = 0;
   for (uint i = 0; i < zombies.length; i++) {
     if (zombieToOwner[i] == _owner) {
       idb[counter] = i;
       dnab[counter] = zombies[i].dna;
       starb[counter] = zombies[i].star;
       roletypeb[counter] = zombies[i].roletype;
       isFreeZombieb[counter] = zombies[i].isFreeZombie;
       counter++;
     }
   }
   return (idb,dnab,starb,roletypeb,isFreeZombieb);
  }
}