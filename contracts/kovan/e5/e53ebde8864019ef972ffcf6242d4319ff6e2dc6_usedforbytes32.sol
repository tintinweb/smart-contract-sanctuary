/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract usedforbytes32  {
    


    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }

    }
    
    function doatest() public pure returns (int) {
        int value = int256(-1);

        return value;
    }

}