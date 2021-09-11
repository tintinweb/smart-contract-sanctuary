/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity >=0.6.0 <0.8.0;
// SPDX-License-Identifier: MIT

contract testStructs {
    
    struct data {
        uint256 number;
        string letter;
    }
    
    data[] dataarr;
    
    constructor() {
        
        dataarr.push(data(1,"a"));
        dataarr.push(data(2, "b"));
        
    }
    
    function viewLen() external view returns(uint256) {
        return dataarr.length;
    }
}