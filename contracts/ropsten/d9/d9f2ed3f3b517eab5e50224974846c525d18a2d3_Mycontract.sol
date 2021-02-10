/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.6.0;

contract Mycontract{
    
    struct Name{
        uint age;
        string name;
    }
    mapping(address => Name)public names;

    
    
    
    function addName(uint age,string memory name,address add)public{
        Name storage get = names[add];
        get.name = name;
        get.age = age;
    }
    
    function getname(address add)public view returns(uint){
        
    return names[add].age;
       
        

    }
    
}