/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test123
{
    struct SimpleStruct
    {
        uint256 a;
    }
    
    struct ComplexStruct
    {
        uint256 a;
        string b;
        bool c;
        SimpleStruct[] simples;
    }
    
    function test() external pure returns(ComplexStruct[] memory result)
    {
        result = new ComplexStruct[](3);
        
        SimpleStruct[] memory a1 = new SimpleStruct[](1);
        a1[0] = SimpleStruct(1);
        result[0] = ComplexStruct(11, "2", true, a1);
        
        SimpleStruct[] memory a2 = new SimpleStruct[](2);
        a2[0] = SimpleStruct(2);
        a2[1] = SimpleStruct(3);
        result[1] = ComplexStruct(22, "3", false, a2);
        
        SimpleStruct[] memory a3 = new SimpleStruct[](3);
        a3[0] = SimpleStruct(4);
        a3[1] = SimpleStruct(5);
        a3[2] = SimpleStruct(6);
        result[2] = ComplexStruct(33, "4", true, a3);
    }
}