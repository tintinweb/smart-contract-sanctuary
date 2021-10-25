/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract A {
    
    bytes public temp;

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
    
    
    function bar(bytes memory data) public view returns (uint256, uint8, address[] memory, address[] memory) {
        (uint256 x, uint8 y, address[] memory z, address[] memory w) = abi.decode(data, (uint256, uint8, address[], address[]));
    
        require(z[0] == msg.sender, "First array");
        require(w[1] == msg.sender, "Second array");
        
        return (x, y, z, w);
    }
}