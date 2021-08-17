/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.5.0;

contract crackdamageidentication{
   function crackwidthidentication(uint8 environmentlevel,bool isprefabricated,string memory properties,uint16 crackwidth)public pure returns(string memory,uint16,string memory,uint16,bool,string memory) {
   uint16 crackwidthlimit;
   string memory properties1='reinforced concrete';
   string memory properties2='prestressed concrete';
   string memory properties3='other special 1';
   string memory properties4='other special 2';
    if (isprefabricated==false){
        if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties1))){  
            if (environmentlevel==1){
            crackwidthlimit=300;
            }
            else if((environmentlevel==2)||(environmentlevel==3)||(environmentlevel==4)||(environmentlevel==5)){
            crackwidthlimit=200; 
            }
        }
        else if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties2))){
            if (environmentlevel==1){
            crackwidthlimit=200;
            }
            else if(environmentlevel==2){
            crackwidthlimit=100;
            }
        }
        else if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties3))){
            if (environmentlevel==1){
            crackwidthlimit=200;
            }
        }
        else if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties4))){
            if (environmentlevel==1){
            crackwidthlimit=300;
            }    
        }
        else{
            
        }
      } 
    else{
        if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties1))){  
            if (environmentlevel==1){
            crackwidthlimit=200;
            }
            else if((environmentlevel==2)||(environmentlevel==3)||(environmentlevel==4)||(environmentlevel==5)){
            crackwidthlimit=150;
            }
        }
        else if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties2))){
            if (environmentlevel==1){
            crackwidthlimit=150;
            }
            else if(environmentlevel==2){
            crackwidthlimit=70;
            }
        }
        else if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties3))){
            if (environmentlevel==1){
            crackwidthlimit=150;
            }
        }
        else if (keccak256(abi.encodePacked(properties))==keccak256(abi.encodePacked(properties4))){
            if (environmentlevel==1){
            crackwidthlimit=200;
            }    
        }
        else{
            
        }
    }
       if(crackwidth <= crackwidthlimit){
           return ("crackwidth:",crackwidth,"crackwidthlimit:",crackwidthlimit,true,"The width of this crack meets the specification requirements");
       }
       else{
           return("crackwidth:",crackwidth,"crackwidthlimit:",crackwidthlimit,false,"The width of this crack doesn't meet the specification requirements");
       }
   }
}