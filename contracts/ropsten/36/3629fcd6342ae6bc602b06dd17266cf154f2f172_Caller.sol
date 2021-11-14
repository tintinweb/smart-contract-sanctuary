/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    
    function testCallswapExactETHForTokens(address payable _addr, uint amountOutMin, address path1,address path2, address to, uint deadline) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("swapExactETHForTokens(uint,address, address , address, uint)", amountOutMin, path1, path2,to,deadline)
        );

        emit Response(success, data);
    }

}