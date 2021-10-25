/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract A {
    
    bytes public temp;
    
    address[] public tempAddresses;

    function foo() public {
        uint256 a = 1;
        uint8 b = 2;
        address[] memory c = new address[](3);
        address[] memory d = new address[](2);
        
        c[0] = msg.sender;
        d[1] = msg.sender;
        
        bytes memory x = abi.encode(a, b, c, d);
        
        temp = x;
    }
    
    
    function bar(uint yyy) public {
        (uint256 x, uint8 y, address[] memory z, address[] memory w) = abi.decode(temp, (uint256, uint8, address[], address[]));
    
        require(z[0] == msg.sender, "First array");
        require(w[1] == msg.sender, "Second array");
        
        tempAddresses = z;
    }
}