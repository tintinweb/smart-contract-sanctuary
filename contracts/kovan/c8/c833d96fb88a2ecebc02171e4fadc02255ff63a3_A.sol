/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract A {
    
    bytes public temp;
    bytes public temp1;

    function foo() public {
        // uint256 a = 1;
        uint[] memory a = new uint[](2);
        a[0] = 20;
        a[1] = 20;
        uint[] memory b = new uint[](2);
        b[0] = 30;
        b[1] = 30;
        
        bytes memory x = abi.encode(a, b);
        
        temp = x;
    }
    
    function getArray1(bytes calldata data) external view returns (uint[] memory) {
        uint[] memory x;
        uint[] memory y;
        
        (x, y) = abi.decode(temp, (uint[], uint[]));
        return x;
    }
    
    function getArray2(bytes calldata data) external view returns (uint[] memory) {
        uint[] memory x;
        uint[] memory y;
        
        (x, y) = abi.decode(data, (uint[], uint[]));
        return x;
    }
    
}