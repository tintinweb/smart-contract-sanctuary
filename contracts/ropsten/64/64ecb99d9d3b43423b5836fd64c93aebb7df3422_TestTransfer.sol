/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;

contract TestTransfer{
    
    
    
    function testTransfer(address token,address from,address to,int256 value) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}