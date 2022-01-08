/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity ^0.4.24;

contract InfoContract {
    string name;
    uint age;

    function setInfo(string _name, uint _age) public {
        name = _name;
        age = _age;
    }

    function getInfo() public view returns(string, uint) {
        return (name, age);
    }
}