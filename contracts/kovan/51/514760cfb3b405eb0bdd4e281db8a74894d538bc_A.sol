/**
 *Submitted for verification at Etherscan.io on 2021-11-03
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
        
        bytes memory c = "0x725";
        bytes memory d = "0x923";
        bytes memory x = abi.encode(a, b, c, d);
        
        temp = x;
    }
    
    function getArray1(bytes calldata data) external view returns (bytes memory) {
        uint[] memory x;
        uint[] memory y;
        bytes memory w;
        bytes memory p;
        
        (x, y, w, p) = abi.decode(temp, (uint[], uint[], bytes, bytes));
        return w;
    }
    
    function getArray2(bytes calldata data) external view returns (bytes memory) {
        uint[] memory x;
        uint[] memory y;
        bytes memory w;
        bytes memory p;
        
        (x, y, w, p) = abi.decode(data, (uint[], uint[], bytes, bytes));
        return w;
    }
    
}