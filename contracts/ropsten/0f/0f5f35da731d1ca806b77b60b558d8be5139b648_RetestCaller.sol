/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract RetestCaller {
    event Response(bool success, bytes data);

    address payable _addr1 = payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    
    function testCallswapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr1.call{value: msg.value}(
            abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)",amountOutMin,path,to,deadline)
        );

        emit Response(success, data);
    }

    function testCallswapExactETHForTokensdirect(bytes calldata inputdata) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr1.call{value: msg.value}(inputdata);

        emit Response(success, data);
    }

    function testCallswapExactETHForTokensdirect2(bytes memory inputdata) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr1.call{value: msg.value}(inputdata);

        emit Response(success, data);
    }


     // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function sendViaTransfer(address payable _to) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }
}