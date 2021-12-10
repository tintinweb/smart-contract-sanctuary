/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract Identity
{
    string name;
    uint age;

    constructor() {
         name="Ajay";
         age=22;
    }
    function getName() view public returns(string memory)
    {
        return name;
    }
    function getAge() view public returns(uint)
    {
       return age; 
    }
}