/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

pragma solidity ^0.4.24;

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

contract ClassFactory {
    address[] public newContracts;
    event classAddress(address addr);
    function createContract(string _className,string _place, string _skill ,uint8 _passStandard, uint8 _academicCredit ) public {
        address newContract = new Class(_className, _place, _skill , _passStandard, _academicCredit);
        newContracts.push(newContract);
        emit classAddress(newContract);
    } 
}

contract Class is Ownable {
    
    string public className;
    string public place;
    string public skill; 
    uint8 public passStandard;
    uint8 public academicCredit; 
    
    struct student{
         string name;
         uint8 score;
    }
    
    mapping(address => student) public adrTostudent;  
    
    constructor (string _className,string _place, string _skill ,uint8 _passStandard, uint8 _academicCredit ) public {
        className = _className;    
        place = _place;    
        skill = _skill;      
        passStandard = _passStandard;     
        academicCredit = _academicCredit; 
        //owner is not only deployer but a teacher.
        owner = tx.origin;
    }
    
    function studentEnrollClass(address studentAddress, string Name) public {
        adrTostudent[studentAddress] = student(Name,0);
    }
    
    function passFail()private pure returns(string){
        return "您尚未通過課程標準";
    }
    
    function pass(address sName, uint8 sco) public returns(string) {
        require(owner == msg.sender);
        uint8 NowScore = adrTostudent[sName].score = sco;
        
        if(NowScore >= passStandard){
            //呼叫鑄造代幣 
        }else{
            return passFail();
        }
    }
  
}