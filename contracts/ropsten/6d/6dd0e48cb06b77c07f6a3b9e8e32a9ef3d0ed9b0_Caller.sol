/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    
    function testCalltransferUniswapTokens(address _addr, address dst, uint rawAmount) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transfer(address, uint)", dst, rawAmount)
        );

        emit Response(success, data);
    }
    
    
    function testCalltransferFromUniswapTokens(address _addr, address src, address dst, uint rawAmount) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transfer(address, address, uint)", src, dst, rawAmount)
        );

        emit Response(success, data);
    }

}