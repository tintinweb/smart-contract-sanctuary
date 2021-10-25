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
    
    
    function bar(uint yyy) public view returns (address[] memory) {
        
        address[] memory dd = new address[](3);
        dd[0] = msg.sender;
        return dd;
    }
}