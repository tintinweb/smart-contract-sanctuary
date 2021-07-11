/**
 *Submitted for verification at polygonscan.com on 2021-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract helloWorld {
    event Text(string str);

    string lastStr;
    address owner;

    modifier ownerOnly() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        lastStr = "";
        owner = msg.sender;
    }

    function send(string memory str) public returns (bool sufficient) {
        lastStr = str;
        emit Text(str);
        return true;
    }

    function geStr() public view returns (string memory str) {
        return lastStr;
    }

    function des() public ownerOnly {
        address payable test = payable(owner);
        selfdestruct(test);
    }
}