/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.4.0;
 

contract myToken{
    string a = "aaaaaa";
    function getname() view public returns(string){
      
         return a;
    }
    
    function setname(string newname) public{
        a=newname;
    }
}