/**
 *Submitted for verification at Etherscan.io on 2021-10-01
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
    
    function CustomErrorWithParams() public {
        revert ErrorWithParams(1, "this is an error");
    }
    
    function NormalRevert() public {
        revert("test error string");
    }
}