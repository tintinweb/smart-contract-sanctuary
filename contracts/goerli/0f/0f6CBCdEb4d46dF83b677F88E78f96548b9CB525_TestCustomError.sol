/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

error ErrorWithNoParams();
error ErrorWithParams(int x, string errorMessage);

contract TestCustomError {
    address payable owner = payable(msg.sender);

    function CustomErrorNoParams() public {
            revert ErrorWithNoParams();

    }
    
    function CustomErrorWithLongParams() public {
        revert ErrorWithParams(1, "this is a very loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo00000000000000000000000oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooonnnnnnnnnnnnnnnnnnnnnngggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg error");
    }
    
    function CustomErrorWithParams() public {
        revert ErrorWithParams(2, "custom error here");
    }
    
    function NormalRevert() public {
        revert("test error string");
    }
}