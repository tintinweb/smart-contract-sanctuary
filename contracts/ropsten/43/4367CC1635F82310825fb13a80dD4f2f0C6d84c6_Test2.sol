/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test2 {

    event L(address indexed sender, uint256 indexed a);

    function f1(uint a) public  pure returns (uint){

        uint b = 1;
        while(true){
            // emit L(msg.sender,a);
            b++;
        }

        return a;
       
    }
    function f2(uint a) public returns (uint){
        // f1();
        return a;
    }
    function f3(uint a) public pure returns (uint){
        uint i = 0;
        uint c = 0;
        while( i < a ){
            c++;
            i++;
        }
        return c;
    }
}