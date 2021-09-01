/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract ListDons {
    mapping (uint => address) public list;
    uint private count = 0;

    function toString(address _account) internal pure returns(string memory) {
        return toString(abi.encodePacked(_account));
    }

    function toString(uint256 _value) internal pure returns(string memory) {
        return toString(abi.encodePacked(_value));
    }

    function toString(bytes32 _value) internal pure returns(string memory) {
        return toString(abi.encodePacked(_value));
    }

    function toString(bytes memory _data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + _data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < _data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(_data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(_data[i] & 0x0f))];
        }
        return string(str);
    }

    function allDonatorsList() public view returns (string memory) {
        bytes memory b;
        b = abi.encodePacked("");
        for(uint i = 0 ; i<count; i++){
            b = abi.encodePacked(b, toString(list[i]));
            b = abi.encodePacked(b, " ");
        }
        string memory str = string(b);
        return str;
    }

    receive () external payable {
        list[count] = msg.sender;
        count++;
    }
}