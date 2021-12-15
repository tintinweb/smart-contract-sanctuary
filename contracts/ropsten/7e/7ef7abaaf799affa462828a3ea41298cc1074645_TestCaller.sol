/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract TestCaller {
    event Response(bool success, bytes data);

    address payable _addr1 = payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address payable _addr2 = payable(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    
    function makecalldata(uint amountOutMin, address[] calldata path, address to, uint deadline) public view returns(bytes memory){
        // You can send ether and specify a custom gas amount
        bytes memory data = abi.encodeWithSignature("swapExactETHForTokens(uint,address[],address,uint)",amountOutMin,path,to,deadline);
        return data;       
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