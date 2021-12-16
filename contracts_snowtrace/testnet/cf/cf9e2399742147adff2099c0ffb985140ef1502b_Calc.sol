/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract Calc{
        int private result;
        
        function add(int a ,int b) public returns (int){
            result = a + b;
            return result;
        }

        
        function dev(int a , int b) public returns (int){
            result = a - b;
            return result;
        }

        function mul(int a , int b) public returns(int){
            result = a * b;
            return result;
        }

        function min(int a , int b) public returns (int){
            result = a - b;
            return result;
        }

        function getResult() public view returns(int) {
            return result;
        }

}