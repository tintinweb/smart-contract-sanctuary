/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.4.24;

contract IofoContract {
    string name;
    uint age;
    
    function setInfo(string _name, uint _age) public {
        name =  _name;
        age = _age;
    }
    
    function getInfo() public view returns(string,uint){
        return (name,age);
    }
}