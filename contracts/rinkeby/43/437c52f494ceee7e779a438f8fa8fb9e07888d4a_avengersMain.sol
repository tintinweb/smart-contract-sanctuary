/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.4.19;

//此合約為 hahow 零基礎邁向區塊鏈工程師：Solidity 智能合約 課程 作業二範 ERC721 範本智能合約

//做作業前，請同學先把功能掃過一次

//做作業方式：
//老師已經完成合約75%，剩下關鍵的方法需要各位同學自行填空，發揮創意。

//做作業關鍵：
//1. 先搞懂ERC721與ERC20的差異，你就會搞懂這些功能為什麼要這樣設計
//2. 請直接搜尋 TO DO 找出要完成的地方


//erc721的介面
contract ERC721 {

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
}

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  constructor() public {
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
    require(owner != newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract avengersMain is  ERC721,Ownable {

  using SafeMath for uint256;
  string private name_ = "AvengersToken";
  uint nonce = 0;

  struct avenger {
    bytes32 hash;
    uint8 role; //角色 (Captain America、Iron Man、Hulk、Thor、Black Widow、Hawkeye、Loki)
    uint8 star; //星級 (1~6)
    uint8 level; //等級 (1~20)
  }

  avenger[] public avengers;
  string private symbol_ = "AVG";

  mapping (uint => address) public avengerToOwner; //每隻復仇者都有一個獨一無二的編號，呼叫此mapping，得到相對應的主人
  mapping (address => uint) public ownerAvengerCount; //回傳某帳號底下的復仇者數量
  mapping (uint => address) public avengerApprovals; //和 ERC721 一樣，是否同意被轉走

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(uint _tokenId, bytes32 dna,uint8 star, uint16 roletype);

  function name() external view returns (string) {
        return name_;
  }

  function symbol() external view returns (string) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {
    return avengers.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerAvengerCount[_owner]; // 此方法只是顯示某帳號 餘額
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return avengerToOwner[_tokenId]; // 此方法只是顯示某復仇者的擁有者
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != avengerToOwner[_tokenId[i]]){
            return false;   //給予一連串復仇者，判斷使用者是不是都是同一人
        }
    }
    
    return true;
  }
  
  function roleMapping(uint8 role) private pure returns(string) {
    if(role == 1)
      return "Captain America";
    else if(role == 2)
      return "Iron Man";
    else if(role == 3)
      return "Hulk";
    else if(role == 4)
      return "Thor";
    else if(role == 5)
      return "Black Widow";
    else if(role == 6)
      return "Hawkeye";
    else if(role == 7)
      return "Loki";
    else
      return "Unknown";
  } 

  function seeAvengerProfile(uint256 _tokenId) public view returns (bytes32 hash,string roleName, uint8 star, uint8 level) {
    return (avengers[_tokenId].hash,roleMapping(avengers[_tokenId].role),avengers[_tokenId].star,avengers[_tokenId].level);
  }

  function seeAvengerHash(uint256 _tokenId) public view returns (bytes32 hash) {
    return avengers[_tokenId].hash;
  }

  function seeAvengerRole(uint256 _tokenId) public view returns (uint8 role, string roleName) {
    return (avengers[_tokenId].role,roleMapping(avengers[_tokenId].role));
  }

  function seeAvengerStar(uint256 _tokenId) public view returns (uint8 star) {
    return avengers[_tokenId].star;
  }
  
  function seeAvengerLevel(uint256 _tokenId) public view returns (uint8 level) {
    return avengers[_tokenId].level;
  }

  function getAvengerByOwner(address _owner) external view returns(uint[]) { //此方法回傳所有帳戶內的"復仇者ID"
    uint[] memory result = new uint[](ownerAvengerCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < avengers.length; i++) {
      if (avengerToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  function getAvengerCountByOwner(address _owner) external view returns(uint) { //此方法回傳所有帳戶內復仇者數量
    return ownerAvengerCount[_owner];
  }

  function transfer(address _to, uint256 _tokenId) public {
    require(avengerToOwner[_tokenId] == msg.sender);

    ownerAvengerCount[msg.sender] = ownerAvengerCount[msg.sender].sub(1);
    ownerAvengerCount[_to] = ownerAvengerCount[_to].add(1);
    avengerToOwner[_tokenId] = _to;

    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(avengerToOwner[_tokenId] == msg.sender);
    
    avengerApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // Safety check to prevent against an unexpected 0x0 default.
    require(avengerToOwner[_tokenId] == _from);
    require(avengerApprovals[_tokenId] == _to);
    
    avengerApprovals[_tokenId] = address(0);
    ownerAvengerCount[_from] = ownerAvengerCount[_from].sub(1);
    ownerAvengerCount[_to] = ownerAvengerCount[_to].add(1);
    avengerToOwner[_tokenId] = _to;
    
    emit Transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(avengerToOwner[_tokenId] == msg.sender);
    
    address owner = ownerOf(_tokenId);

    ownerAvengerCount[msg.sender] = ownerAvengerCount[msg.sender].add(1);
    ownerAvengerCount[owner] = ownerAvengerCount[owner].sub(1);
    avengerToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }
  
  function createAvenger() public payable returns(uint256 tokenId) {
	require(msg.value == 0.1 ether, "Each avenger costs 0.1 ether!");

    bytes32 hash;
    uint role;
    uint star;
    uint level;
    uint rand;
   
    //TO DO 
    //使用亂數來產生hash, role, star, level
    //動手玩創意，可以限制每次建立復仇者需要花費多少ETH
    hash = keccak256(abi.encodePacked(nonce,block.timestamp));
    nonce += ((uint(hash) % 5) + 1);

    role = (uint(keccak256(abi.encodePacked(nonce,hash))) % 7) + 1;
    nonce += role;

    rand = uint(keccak256(abi.encodePacked(nonce,hash))) % 100;
    if(rand < 40) star = 1;
    else if(rand < 70) star = 2;
    else if(rand < 90) star = 3;
    else if(rand < 95) star = 4;
    else if(rand < 98) star = 5;
    else if(rand < 100) star = 6;
    else star = 1;
    nonce += star;

    rand = uint(keccak256(abi.encodePacked(nonce,hash))) % 100;
    if(rand < 10) level = 1;
    else if(rand < 20) level = 2;
    else if(rand < 30) level = 3;
    else if(rand < 40) level = 4;
    else if(rand < 50) level = 5;
    else if(rand < 55) level = 6;
    else if(rand < 60) level = 7;
    else if(rand < 65) level = 8;
    else if(rand < 70) level = 9;
    else if(rand < 75) level = 10;
    else if(rand < 78) level = 11;
    else if(rand < 81) level = 12;
    else if(rand < 84) level = 13;
    else if(rand < 87) level = 14;
    else if(rand < 90) level = 15;
    else if(rand < 92) level = 16;
    else if(rand < 94) level = 17;
    else if(rand < 96) level = 18;
    else if(rand < 98) level = 19;
    else if(rand < 100) level = 20;
    else star = 1;
    nonce++;

    uint id = avengers.push(avenger(hash, uint8(role), uint8(star), uint8(level))) - 1;
    avengerToOwner[id] = msg.sender;
    ownerAvengerCount[msg.sender]++;
    return id;
  }
  
}