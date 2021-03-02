/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity  >= 0.5.0;

contract SafeMath {
    function SafeAdd(uint a, uint b) public pure returns (uint c){
        c=a+b;
        require(c>=a);
    }
    function SafeSub(uint a, uint b) public pure returns (uint c){
        c=a-b;
        require(a>=b);
    }
    function SafeMul(uint a, uint b) public pure returns (uint c){
        c=a*b;
        require(a==0 || c/a==b);
    }
    function SafeDiv(uint a, uint b) public pure returns (uint c){
        require(b > 0);
        c=a/b;
        //require(c>=a);
    }
    function SafeDivEucliedienne(uint a, uint b) public pure returns (uint c, uint d){
        require(b > 0);
        d=a%b;
        c=(a-d)/b;

    }
    function SafeMod(uint a, uint b) public pure returns (uint c){
        require(b > 0);
        c=a%b;
        //require(c>=0);
    }
}