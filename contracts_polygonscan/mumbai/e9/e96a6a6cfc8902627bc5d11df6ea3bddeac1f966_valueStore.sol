/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract valueStore {
    string private storedValue;
    address private owner;
    mapping(address => bool) private permittedAddresses;

    modifier ifOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ifPermitted() {
        require(permittedAddresses[msg.sender]);
        _;
    }

    constructor() {
        owner = msg.sender;
        permittedAddresses[msg.sender] = true;
    }

    function givePermission(address _address) public ifOwner {
        permittedAddresses[_address] = true;
    }

    function takePermission(address _address) public ifOwner {
        permittedAddresses[_address] = false;
    }

    function storeValue(string memory _storedVal) public ifPermitted {
        storedValue = _storedVal;
    }

    function getValue() public view returns (string memory) {
        return storedValue;
    }
}