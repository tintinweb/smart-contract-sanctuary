/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

contract A {
    function getResult() public pure returns(uint){
        uint x = 2;
        return x;
    }
    function getScore() public pure returns(bool){
        return(true);
    }
}
interface IA {
    function getResult() external pure returns(uint);
    function getScore() external pure returns(bool);
    function get() external pure returns(bool);
}

contract B{
     function setScore() external pure returns(uint){
         IA a = IA(0x12f68F7A118D56f4B9036A7958988060BaD92849);
         uint x = a.getResult();
         return x;
     }
}
contract C is A {
    function getEatting() external pure returns(bool){
        bool x;
        x = getScore();
        return x;
    }
}