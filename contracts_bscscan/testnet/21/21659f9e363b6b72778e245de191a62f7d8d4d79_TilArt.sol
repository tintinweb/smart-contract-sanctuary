/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-02
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
  //token屬於誰的
  function transfer(address _to, uint256 _tokenId) public;
  //一次給一個
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
  
  modifier onlySender(address _from) 
  {
      require(msg.sender == _from);
      _;
      
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




contract TilArt is  ERC721,Ownable {

  using SafeMath for uint;
    string public name_ = "TilArtToken";

  constructor() public {
    
  }

  struct number {
    uint rightdown; 
    uint rightup; //乳暈大小(1:XXS 2:XS 3:S 4:M 5:L 6:XL 7:XXL)
    uint leftup; //罩杯(1:A 2:B 3:C 4:D 5:E 6:F 7:G 8:H)
    uint leftdown; //胸型(1:Asymmetric 2:Athletic 3:East West 4:Relaxed 5:Bell Shape 6:Slender 7:Side Set 8:Round 9:Tear Drop)
    //參考:https://www.seventeen.com/health/sex-health/g23725507/different-boob-types-shapes/?slide=9
  }

  number[] public numbers;
  string public symbol_ = "tilart";
  
  mapping (uint => address) private animalToOwner; //每隻動物都有一個獨一無二的編號，呼叫此mapping，得到相對應的主人
  mapping (address => uint) ownerAnimalCount; //回傳某帳號底下的動物數量
  mapping (uint => address) animalApprovals; //和 ERC721 一樣，是否同意被轉走

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(uint _tokenId, bytes32 dna,uint8 star, uint16 roletype);
  
  uint nonce = 0;
  
  function name() external view returns (string) {
        return name_;
  }

  function symbol() external view returns (string) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {
    return numbers.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerAnimalCount[_owner]; // 此方法只是顯示某帳號 餘額
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return animalToOwner[_tokenId]; // 此方法只是顯示某動物 擁有者
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != animalToOwner[_tokenId[i]]){
            return false;   //給予一連串動物，判斷使用者是不是都是同一人
        }
    }
    
    return true;
  }
  

  function getBoobsByOwner(address _owner) external view returns(uint[]) { //此方法回傳所有帳戶內的"動物ID"
    uint[] memory result = new uint[](ownerAnimalCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < numbers.length; i++) {
      if (animalToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  function transfer(address _to, uint256 _tokenId) public {
    //TO DO 請使用require判斷要轉的動物id是不是轉移者的
    require(animalToOwner[_tokenId] == msg.sender);
    
    
    //增加受贈者的擁有動物數量
    //減少轉出者的擁有動物數量
    ownerAnimalCount[_to]++;
    ownerAnimalCount[msg.sender]--;
    
    //動物所有權轉移
    animalToOwner[_tokenId] = _to;
    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(animalToOwner[_tokenId] == msg.sender);
    
    animalApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external  {
    // Safety check to prevent against an unexpected 0x0 default.
    require(msg.sender == _to);//(不確定是否需要本人接收)
    require(animalApprovals[_tokenId] == _to);
    
    animalApprovals[_tokenId] = 0x0;
    ownerAnimalCount[_to]++;
    ownerAnimalCount[msg.sender]--;
    emit Transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(animalToOwner[_tokenId] == msg.sender);
    
    address owner = ownerOf(_tokenId);

    ownerAnimalCount[msg.sender]++;
    ownerAnimalCount[owner]--;
    animalToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }
  
  //亂數產生
    function random(uint range) private returns(uint){
         bytes32 result = keccak256(abi.encodePacked(abi.encodePacked(now, msg.sender, nonce)));
         nonce++;
         if(nonce>2**10)
         nonce = 0;
         return uint(result) % range + 1;
    }
  
  function createBoobs() public payable returns(bool) {

       uint price = 1 * 10**17;
       
      
      //退錢機制
      require(msg.value >= price);
      //大於price要退錢
      uint refund =  msg.value.sub(price);
      if(refund>0)
      {
         require(refund <= owner.balance);
         msg.sender.transfer(refund);
      }
       
       
      //TO DO 
      //動手玩創意，可以限制每次建立動物需要花費多少ETH
      
      uint Random_num1 = random(1000);
      uint Random_num2 = random(1000);
      uint Random_num3 = random(1000);
      uint Random_num4 = random(1000);

      uint id = numbers.push(number(uint(Random_num1), uint(Random_num2), uint(Random_num3), uint(Random_num4))) - 1;
      //push: Dynamic storage arrays and bytes (not string) have a member function called push that can be used to append an element at the end of the array. 
      //The function returns the new length.
      animalToOwner[id] = msg.sender;
      ownerAnimalCount[msg.sender]++;
      
      
      return true;
 
  }
  
  function transferETH2owner() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}