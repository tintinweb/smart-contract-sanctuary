/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract SimpleCalculator {
    
    uint result;
    
    function add(uint256 num) public {
        result = result+num;
    }    
    
    function minus(uint256 num) public {
        result = result-num;
    }
        
    function times(uint256 num) public {
        result = result*num;
    }
    
        
    function devide(uint256 num) public {
        result = result/num;
    }
    
    function getResult() public view returns (uint) {
        return result;
    }
}