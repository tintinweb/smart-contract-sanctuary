/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_11 {

    string[] names = ["Ava", "Becky","Charlse","Devy","Elice","Fabian"];
    
    
    function pushStudent(string memory _name) public{
        
        if(names.length >= 10){
            names.push(_name);
        } 
    }
     
     function getSophia() public view returns(string memory){
        bytes32  _sophia = keccak256(abi.encodePacked("Sophia"));
         
         for(uint i = 0; i < names.length; i++){
             if(bytes32(keccak256(abi.encodePacked(names[i]))) == _sophia){
                 return("There exist Sophia");
             }
         }
         
         return("There are no Sophia");
     }
     
     function getNumStdent() public view returns(uint, uint){
         uint chuga = 10 - names.length;
         
         return(names.length, chuga);
     }   
        
    function getListStudent() public view returns(string[] memory){
        return names;
    }
    
    
}