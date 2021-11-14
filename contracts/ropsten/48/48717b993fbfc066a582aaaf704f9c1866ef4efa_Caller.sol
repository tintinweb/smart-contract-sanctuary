/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    
    function testCalltransferUniswapTokens(address _addr, address recipient, uint amount) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transfer(address, uint)", recipient, amount)
        );

        emit Response(success, data);
    }
    
    function testDelegateCalltransferUniswapTokens(address _addr, address recipient, uint amount) public {
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("transfer(address, uint)", recipient, amount)
        );

        emit Response(success, data);
    }
    

}