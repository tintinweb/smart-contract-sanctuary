/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract UNIcalldatamaker {


    address swaprouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address uniswapv2router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function UniCalldirect(bytes memory inputdata) public payable {
        (bool success, bytes memory data) = uniswapv2router02.call{value: msg.value}(inputdata);
    }
    
    function forswapExactETHForTokens(uint amountOutMin, address[] calldata path) public payable {
    uint deadline = block.timestamp + 1 days;
     bytes memory bytesdata = abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)",amountOutMin,path,msg.sender,deadline);
     UniCalldirect(bytesdata);
    }

}