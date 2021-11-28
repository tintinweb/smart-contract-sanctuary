/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity ^0.8.0;

contract SayHello {
    mapping(address => string) public greetings;

    constructor(string memory someone) {
        string memory stringAddress = addressToString(msg.sender);
        string memory greeting = string(
            abi.encodePacked(stringAddress, " says hello to ", someone, "!!!")
        );
        greetings[msg.sender] = greeting;
    }

    function sayHelloTo(string memory someone) public returns (string memory) {
        string memory stringAddress = addressToString(msg.sender);
        string memory greeting = string(
            abi.encodePacked(stringAddress, " says hello to ", someone, "!!!")
        );
        greetings[msg.sender] = greeting;

        return greeting;
    }

    // hack to parse Address to String
    function addressToString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}