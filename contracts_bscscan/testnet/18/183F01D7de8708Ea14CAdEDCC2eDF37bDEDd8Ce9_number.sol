/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

pragma solidity ^0.5.6;


contract number{

    uint public Number;

    function setNumber(uint _number) public {
    Number = _number;
    }

    function getNumber() public view returns(uint){
    return Number;
    }


}