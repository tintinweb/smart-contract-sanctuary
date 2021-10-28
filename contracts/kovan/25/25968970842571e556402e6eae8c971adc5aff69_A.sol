/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract A {
    
    bytes public temp;
    
    address[] public tempAddresses;

    function foo() public {
        // uint256 a = 1;
        uint b = 2;
        uint[] memory a = new uint[](3);
        a[0] = 48;
        a[1] = 48;
        a[2] = 48;
        address[] memory c = new address[](3);
        address[] memory d = new address[](2);
        
        c[0] = msg.sender;
        d[1] = msg.sender;
        
        bytes memory x = abi.encode(a, b, c, d);
        
        temp = x;
    }
    
    
    function getArray(bytes memory yyy) public pure returns (uint[] memory) {
        uint256[] memory x;
        uint y;
        address[] memory z;
        address[] memory w;
        
        (x, y, z, w) = abi.decode(yyy, (uint256[], uint, address[], address[]));
        return x;
    }
    
    function getNumber(bytes memory yyy) public pure returns (uint) {
        uint256[] memory x;
        uint y;
        address[] memory z;
        address[] memory w;
        
        (x, y, z, w) = abi.decode(yyy, (uint256[], uint, address[], address[]));
        return y;
    }
}