/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-05
*/

pragma solidity ^0.4.19;

//erc721 Interface
contract ERC721 {
//   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
//   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
//   function balanceOf(address _owner) public view returns (uint256 _balance);
//   function ownerOf(uint256 _tokenId) public view returns (address _owner);
//   function transfer(address _to, uint256 _tokenId) public;
//   function approve(address _to, uint256 _tokenId) public;
//   function takeOwnership(uint256 _tokenId) public;
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



contract PruduceLearningToken is  ERC721,Ownable {

  using SafeMath for uint256;

  struct learningToken {
    bytes32 tokenDna; //DNA
    address owner;
    string trueName;
    uint timeStamp;
    string place;
    string skill;
    uint8 learningCredit;
    uint score;
  }

  learningToken[] public learningTokens;

//   mapping (uint => address) public animalToOwner; //每隻動物都有一個獨一無二的編號，呼叫此mapping，得到相對應的主人
  mapping (address => uint)public ownerlearningTokenCount; //回傳某帳號底下的動物數量
//   mapping (uint => address) animalApprovals; //和 ERC20 一樣，是否同意被轉走

// //   event Transfer(address _from, address _to,uint _tokenId);
// //   event Approval(address _from, address _to,uint _tokenId);
//   event Take(address _to, address _from,uint _tokenId);
  event Create( 
    bytes32 tokenDna,
    address owner,
    string trueName,
    uint timeStamp,
    string place,
    string skill,
    uint8 learningCredit,
    uint score);

//   function balanceOf(address _owner) public view returns (uint256 _balance) {
//     return ownerAnimalCount[_owner]; // 此方法只是顯示某帳號 餘額
//   }

//   function ownerOf(uint256 _tokenId) public view returns (address _owner) {
//     return animalToOwner[_tokenId]; // 此方法只是顯示某動物 擁有者
//   }

//   function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
//     for(uint i=0;i<_tokenId.length;i++){
//         if(owner != animalToOwner[_tokenId[i]]){
//             return false;   //給予一連串動物，判斷使用者是不是都是同一人
//         }
//     }
    
//     return true;
//   }

//   function seeAnimalDna(uint256 _tokenId) public view returns (bytes32 dna) {
//     return learningToken[_tokenId].tokenDna;
//   }

//   function seeAnimalStar(uint256 _tokenId) public view returns (uint8 star) {
//     return learningToken[_tokenId].;
//   }
  
//   function seeAnimalRole(uint256 _tokenId) public view returns (uint16 roletype) {
//     return animals[_tokenId].roletype;
//   }

//   function getAnimalByOwner(address _owner) external view returns(uint[]) { //此方法回傳所有帳戶內的"動物ID"
//     uint[] memory result = new uint[](ownerAnimalCount[_owner]);
//     uint counter = 0;
//     for (uint i = 0; i < animals.length; i++) {
//       if (animalToOwner[i] == _owner) {
//         result[counter] = i;
//         counter++;
//       }
//     }
//     return result;
//   }

//   function transfer(address _to, uint256 _tokenId) public {
//     //TO DO 請使用require判斷要轉的動物id是不是轉移者的
//      require(animalToOwner[_tokenId] == msg.sender);
//     //增加受贈者的擁有動物數量
//      ownerAnimalCount[_to] = ownerAnimalCount[_to].add(1);
//     //減少轉出者的擁有動物數量
//      ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].sub(1);
//     //動物所有權轉移
//      animalToOwner[_tokenId] = _to;
    
//     emit Transfer(msg.sender, _to, _tokenId);
//   }

//   function approve(address _to, uint256 _tokenId) public {
//     require(animalToOwner[_tokenId] == msg.sender);
    
//     animalApprovals[_tokenId] = _to;
    
//     emit Approval(msg.sender, _to, _tokenId);
//   }

//   function takeOwnership(uint256 _tokenId) public {
//     require(animalToOwner[_tokenId] == msg.sender);
    
//     address owner = ownerOf(_tokenId);

//     ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].add(1);
//     ownerAnimalCount[owner] = ownerAnimalCount[owner].sub(1);
//     animalToOwner[_tokenId] = msg.sender;
    
//     emit Take(msg.sender, owner, _tokenId);
//   }
  function createLearingToken(address owner, string trueName, string place , string skill, uint8 learningCredit, uint score) public {
      
        bytes32 tokenDna; //DNA
        uint timeStamp = now ;
        
      //TO DO 
      //使用亂數來產生DNA
      tokenDna = keccak256(abi.encodePacked(msg.sender,now));
      
      uint id = learningTokens.push(learningToken(tokenDna, owner, trueName, timeStamp, place, skill, learningCredit, score)) - 1; //learningTokens.push() -->創造第一個 1-1=0
      learningTokens[id].owner = owner;
      ownerlearningTokenCount[msg.sender] = ownerlearningTokenCount[msg.sender].add(1);
      emit Create(tokenDna, owner, trueName, timeStamp, place, skill, learningCredit, score );
 
  }
  
  
  
}
pragma solidity ^0.4.26;

contract ClassFactory {
    
    address[] public newContracts;
    event classInfo(address addr, address teacher,  string _className,string _place, string _skill ,uint8 _passStandard, uint8 _academicCredit);
    function createContract(string _className,string _place, string _skill ,uint8 _passStandard, uint8 _academicCredit ) public {
        address newContract = new Class(_className, _place, _skill , _passStandard, _academicCredit);
        newContracts.push(newContract);
        emit classInfo(newContract, msg.sender, _className, _place, _skill , _passStandard, _academicCredit);
    } 
}

contract Class {
    
    string public className;
    string public place;
    string public skill; 
    uint8 public passStandard;
    uint8 public academicCredit; 
   address public teacherowner ;
   
    struct student{
         string name;
         uint8 score;
    }
    
    event studentEnroll(string Name ,string success);
    
    mapping(address => student) public adrTostudent;  
    
    constructor (string _className,string _place, string _skill ,uint8 _passStandard, uint8 _academicCredit ) public {
        className = _className;    
        place = _place;    
        skill = _skill;      
        passStandard = _passStandard;     
        academicCredit = _academicCredit; 
        //owner is not only deployer but a teacher.
        teacherowner = tx.origin;
    }
    
    function studentEnrollClass(address studentAddress, string Name) public {
        adrTostudent[studentAddress] = student(Name,0);
       
        emit studentEnroll(Name, "課程註冊成功");
    }
    
    function passFail()private pure returns(string){
        return "您尚未通過課程標準";
    }
    
    function pass(address sName, uint8 sco) public returns(string) {
        require(teacherowner == msg.sender);
        uint8 NowScore = adrTostudent[sName].score = sco;
        
        if(NowScore >= passStandard){
            //呼叫鑄造代幣 
        address T = 0xA831F4e5dC3dbF0e9ABA20d34C3468679205B10A;
        PruduceLearningToken LT =  PruduceLearningToken(T);
        LT.createLearingToken(sName, adrTostudent[sName].name,place ,skill, academicCredit,adrTostudent[sName].score);
        }else{
            return passFail();
        }
    }
  
}