/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract Caller {
    event Response(bool success, bytes data);

    // 嘗試呼叫 41. foo
    function testCallFoo(address payable _addr) public payable {
        // call 除了發送 ehter 外, 也可以指定它的交易 gas 數
        (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 5000}(
            abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
        );

        emit Response(success, data);
    }

    // 嘗試呼叫 41. 部存在的函數, 此舉會調用 fallback 函數
    function testCallDoesNotExist(address _addr) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("doesNotExist()")
        );

        emit Response(success, data);
    }
}