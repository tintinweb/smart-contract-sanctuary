/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    
    function testCallswapExactETHForTokens(address payable _addr, uint amountOutMin, address[] calldata path, address to, uint deadline) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("swapExactETHForTokens(uint,address[] , address, uint)", amountOutMin, path,to,deadline)
        );

        emit Response(success, data);
    }

}