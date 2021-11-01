/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract A {
    
    bytes public temp;
    bytes public temp1;

    function foo() public {
        // uint256 a = 1;
        address a = msg.sender;
        address b = msg.sender;
        uint c = 20;
        
        bytes memory x = abi.encode(a, b, c);
        
        temp = x;
    }
    
    function getArray1(bytes calldata data) external view returns (address) {
        address x;
        address y;
        uint z;
        
        (x, y, z) = abi.decode(temp, (address, address, uint));
        return x;
    }
    
    function getArray2(bytes calldata data) external view returns (address) {
        address x;
        address y;
        uint z;
        
        (x, y, z) = abi.decode(data, (address, address, uint));
        return x;
    }
    
}