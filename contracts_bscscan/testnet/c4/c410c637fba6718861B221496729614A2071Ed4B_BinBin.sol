/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BinBin {
    uint256 result;
    
    function add(uint256 a, uint256 b) public {
        result = a + b;
        }
        
    function min(uint256 a, uint256 b) public {
        result = a - b;
        }
        
    function mul(uint256 a, uint256 b) public {
        result = a * b;
        }
        
    function div(uint256 a, uint256 b) public {
        result = a / b;
        }

    function getResult() public view returns (uint256){
        return result;
        }
    }