// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Simple {
    int256 private _data;
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function get() public view returns (int256) {
        return _data;
    }

    function set(int256 val) public {
        _data = val;
    }

    function kill() public {
        require(msg.sender == _owner, "Not Owner");
        selfdestruct(payable(_owner));
    }
}

