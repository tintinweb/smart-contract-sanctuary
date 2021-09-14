/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

contract EventTesting {
    event JustBytes (
        bytes _myBytes
    );
    
    event JustString (
        string _myString
    );
    
    event JustBytes32 (
        bytes32 _myBytes32
    );
    
    event JustBytesIndexed (
        bytes indexed _myBytes
    );
    
    event JustBytes32Indexed (
        bytes indexed _myBytes
    );
    
    event BytesAndBytes32Indexed (
        bytes _myBytes,
        bytes32 indexed _myBytes32
    );
    
    function emitJustBytes(bytes calldata _myBytes) public {
        emit JustBytes(_myBytes);
    }
    
    function emitJustString(string calldata _myString) public {
        emit JustString(_myString);
    }
    
    function emitJustBytes32(bytes32 _myBytes32) public {
        emit JustBytes32(_myBytes32);
    }
    
    function emitJustBytesIndexed(bytes calldata _myBytes) public {
        emit JustBytesIndexed(_myBytes);
    }
    
    function emitJustBytes32Indexed(bytes calldata _myBytes) public {
        emit JustBytes32Indexed(_myBytes);
    }
    
    function emitBytesAndBytes32Indexed(bytes calldata _myBytes, bytes32 _myBytes32) public {
        emit BytesAndBytes32Indexed(_myBytes, _myBytes32);
    }
}