/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity >0.4.22 < 0.8.10;
contract tokentest{

   address owner;
   string name;
   bool visible;
   uint16 count;

   constructor()public{
       owner=msg.sender;
       }
     function changeName(string memory _name) public returns(string memory){
      if(msg.sender==owner){
       name=_name;
       return "success";
      }else{
          return "access denied";
        }  
    }
    function showName() view public returns(string memory){
        return name;
    }
    
    
    }