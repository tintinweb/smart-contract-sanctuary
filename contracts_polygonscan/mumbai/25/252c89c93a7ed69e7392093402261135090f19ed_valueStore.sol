/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

pragma solidity 0.8.7;
//SPDX-License-Identifier: MIT

contract valueStore {
    string private storedValue;
    address private owner;
    mapping (address => bool) private permittedAddresses;

    modifier ifOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        permittedAddresses[msg.sender] = true;
    }

    function checkPermission() public view returns (bool) {
        return permittedAddresses[msg.sender];
    }

    function givePermission(address _address) public ifOwner {
        permittedAddresses[_address] = true;
    }

    function storeValue(string memory _storedVal) public {
        if (checkPermission()) {
            storedValue = _storedVal;
        } else {
            revert("ValueStore/You don't have the permission to store a string.");
        }
    }
}