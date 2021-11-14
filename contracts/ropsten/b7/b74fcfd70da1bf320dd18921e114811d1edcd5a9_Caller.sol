/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {
    event Response(bool success, bytes data);

    
    function testCalltransferERC20Tokens(address _addr, address recipient, uint amount) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transfer(address,uint256)",recipient,amount)
        );

        emit Response(success, data);
    }
    
    function testDelegateCalltransferERC20Tokens(address _addr, address recipient, uint amount) public {
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("transfer(address,uint256)",recipient,amount)
        );
        emit Response(success, data);
    }
    
}