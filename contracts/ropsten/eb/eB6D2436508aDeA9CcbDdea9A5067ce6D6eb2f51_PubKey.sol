// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PubKey {

    string[] public nodeKeys;
    string[] public pubAddrs;
    string[] public signs;

    event AddAddr(string addr);
    event SubmitSign(string addr);

    function addNodeKey(string[] memory keys) public {
        for (uint i; i < keys.length; i++) {
            nodeKeys.push(keys[i]);
        }
    }

    function addPubAddrs(string memory addr) public {
        pubAddrs.push(addr);
        emit AddAddr(addr);
    }

    function submitSign(string memory sign) public {
        signs.push(sign);
        emit SubmitSign(sign);
    }
    
}

