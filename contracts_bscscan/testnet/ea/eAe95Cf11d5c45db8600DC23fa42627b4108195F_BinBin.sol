/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BinBin {
    int private result;
    
    function add(int a, int b) public {
        result = a + b;
        }
        
    function min(int a, int b) public {
        result = a - b;
        }
        
    function mul(int a, int b) public {
        result = a * b;
        }
        
    function div(int a, int b) public {
        result = a / b;
        }

   
    }