/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract testStringToBytes{

    event TestString(string testString);
    event TestBytes(bytes textBytes);
    event TestBytes8(bytes8 textBytes8);
    event TestBytes4(bytes4 textBytes4);

    function testString(string memory text) public returns(string memory) {
        emit TestString(text);
        return text;
    }

    function testBytes(string memory text) public returns(bytes memory) {
        bytes memory textBytes = bytes(text);
        emit TestBytes(textBytes);
        return textBytes;
    }

    function testBytes8(string memory text) public returns(bytes8) {
        bytes8 textBytes8 = bytes8(bytes(text));
        emit TestBytes8(textBytes8);
        return textBytes8;
    }

    function testBytes4(string memory text) public returns(bytes4) {
        bytes4 textBytes4 = bytes4(bytes(text));
        emit TestBytes4(textBytes4);
        return textBytes4;
    }
}