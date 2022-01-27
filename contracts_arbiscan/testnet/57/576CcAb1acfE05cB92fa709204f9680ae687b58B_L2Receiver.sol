//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract L2Receiver {
    string private text;
    uint256 private num;

    constructor() {
        text = "Hello, world!";
        num = 10;
    }

    function getText() public view returns (string memory) {
        return text;
    }

    function getNum() public view returns (uint256) {
        return num;
    }

    function setText(string memory _text) public {
        text = _text;
    }

    function setNum(uint256 _num) public {
        num = _num;
    }
}