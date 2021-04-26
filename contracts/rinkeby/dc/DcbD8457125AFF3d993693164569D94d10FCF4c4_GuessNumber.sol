/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.4.17;

contract GuessNumber{
    uint num = 13;
    
    function changeNumber(uint _newNum) external {
        num = _newNum;
    }
    
    function getNum() view external returns(uint){
        return num;
    }
}