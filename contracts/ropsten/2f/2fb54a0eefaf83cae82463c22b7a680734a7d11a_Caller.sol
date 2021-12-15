/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    address _addr1 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address _addr2 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    
    function testCallswapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr1.call{value: msg.value}(
            abi.encodeWithSignature("swapExactETHForTokens(uint,address[],address,uint)",amountOutMin,path,to,deadline)
        );

        emit Response(success, data);
    }
    

}