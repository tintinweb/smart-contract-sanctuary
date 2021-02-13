/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.6.0;

contract Mycontract{
    address  owner;
    
    constructor()public{
        owner=msg.sender;
    }
    
    modifier onlyOwner(){
        require(owner ==msg.sender,"You are not the owner");
        _;
    }
    
    modifier onlyAdmin(){
        require(verifiedAdmin() == true,"not accessible");
        _;
    }
    
   // mapping(address=> admin)adminverification;
    
    mapping(address => bool)adminverification;
    
    
    
    struct Name{
        uint age;
        string name;
        uint mark1;
        uint mark2;
        uint mark3;
        uint mark4;
    }
    mapping(address => Name)public names;
    
    
    function addAdmin(address _admin)public onlyOwner{
         adminverification[_admin] = true;
        
    }
    
    function verifiedAdmin() public view returns(bool){
        return adminverification[msg.sender];
        
        
    }

    
    
    
    function addName(uint age,string memory name,address add,uint mark1,uint mark2,uint mark3,uint mark4)public onlyAdmin{
        Name storage get = names[add];
        get.name = name;
        get.age = age;
        get.mark1=mark1;
        get.mark2=mark2;
        get.mark3=mark3;
        get.mark4=mark4;
        
    }
    
    
    function getname(address add)public view returns(uint,string memory,uint,uint,uint,uint){
        
      return (names[add].age,names[add].name,names[add].mark1,names[add].mark2,names[add].mark3,names[add].mark4);
       
     }
    
}