/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract Demo{
    uint age;
    function setage(uint _age) public  returns(uint){
        age= _age;
        return age;
    }
    function getage() public view returns(uint) {
        return age;
    }

}