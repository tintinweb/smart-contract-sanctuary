/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.4.24;

contract InfoContract {
    string name;
    uint age;
    
    function setInfo(string _name, uint _age) public {
        name = _name;
        age = _age;
    }
    
    function getInfo() view public returns(string, uint){
        return(name, age);
    }
}