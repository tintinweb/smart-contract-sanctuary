/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// File: TestDecodingV1.sol

contract TestDecodingV1 {
    
    // Integers
    
    function testIntegerNoName(uint256) public {
        // pass
    }
    
    function testInteger(uint256 paramInteger) public {
        // pass
    }
    
    function testIntegerLongParameterName(uint256 paramLongName_abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789) public {
        // pass
    }
    
    function testInteger8(uint8 paramInteger16) public {
        // pass
    }
    
    function testInteger16(uint8 paramInteger16) public {
        // pass
    }
    
    // Bools
    
    function testBoolNoName(bool) public {
       // pass
    }
    
    function testBool(bool paramBool) public {
       // pass
    }
    
    // Bytes
    
    function testBytes32(bytes32 paramBytes32) public {
       // pass
    }
    
    function testBytes16(bytes32 paramBytes16) public {
       // pass
    }
    
    function testBytes(bytes memory paramBytes) public {
       // pass
    }
    
    // Address
    
    function testAddress(address paramAddress) public {
       // pass
    }
    
    // Arrays
    
    function testArrayInteger(uint256[] memory paramArrayInteger) public {
        // pass
    }
    
    function testArrayBool(bool[] memory paramArrayBool) public {
        // pass
    }
    
    function testArrayAddress(address[] memory paramArrayAddress) public {
        // pass
    }
    
    function testArrayBytes(bytes[] memory paramArrayBytes) public {
        // pass
    }
    
    function testArrayBytes32(bytes[] memory paramArrayBytes32) public {
        // pass
    }
    
    function testArrayNoName(uint256[] memory) public {
        // pass
    }
    
    // Nested Arrays
    
    function testNestedArrayInteger(uint256[][] memory paramNestedArrayInteger) public {
        // pass
    }
    
    function testNestedArrayBool4Levels(bool[][][][] memory paramNestedArrayBool) public {
        // pass
    }
    
    function testNestedArrayInteger10Levels(bool[][][][][][][][][][] memory paramNestedArrayBool) public {
        // pass
    }
    
    // Misc many params
    
    function testManyParams(uint256 p1, bool p2, bytes32 p3, address p4, bool[][] memory p5, bytes32[] memory p6, address[] memory p7) public {
        // pass
    }
    
    function testManyParamsNoName(uint256, bool, bytes32, address, uint256[] memory, bool[][] memory, bytes32[] memory, address[] memory) public {
        // pass
    }
    
    function testManyParamsMix(uint256 p1, bool, bytes32, address p4, uint256[] memory, bool[][] memory, bytes32[] memory p7, address[] memory p8) public {
        // pass
    }
}