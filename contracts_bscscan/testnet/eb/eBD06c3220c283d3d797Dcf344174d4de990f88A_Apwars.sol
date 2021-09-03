/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Apwars {

    address public person;
    mapping(address => string) public personName;
    
    
    function getName(address account) public view returns (string memory)
    {
        return personName[account];
    }
    
    function setName(string memory name) public
    {
        require(stringToBytes32(name) != stringToBytes32("Rafael"), "Apwars:INVALID_NAME");
        personName[msg.sender] = name;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

}