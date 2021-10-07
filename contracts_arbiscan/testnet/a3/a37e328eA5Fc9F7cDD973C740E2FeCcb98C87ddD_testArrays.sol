/**
 *Submitted for verification at arbiscan.io on 2021-10-06
*/

pragma solidity ^0.7.0;


contract testArrays {
    
    bool[] public b;
    
    function enterArrayOfBoolean(bool[] memory _a) public {
        for (uint8 i = 0; i < _a.length; i++) {
            b.push(_a[i]);
        }
    }
}