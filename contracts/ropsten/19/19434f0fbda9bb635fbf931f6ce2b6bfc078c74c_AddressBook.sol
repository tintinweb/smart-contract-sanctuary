/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// contracts/AddressBook.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Address Book
 * @dev A simple address book
 */
contract AddressBook {
    mapping(address => string) public addressToName;
    mapping(string => address) public nameToAddress;

    /**
     * @dev Store username and address in the address book.
     * @param newUsername username you want to have
     */
    function store(string calldata newUsername) public {
        address userAddress = nameToAddress[newUsername];
        require(
            userAddress == address(0),
            "Username already exists."
        );
        string memory username = addressToName[msg.sender];
        bytes memory tempEmptyStringTest = bytes(username);
        require(
            tempEmptyStringTest.length == 0,
            "A username for this address already exists."
        );
        _store(newUsername, msg.sender);
    }
    
    /**
     * @dev Save username
     * @param username username to store
     * @param userAddress caller address
     */
    function _store(string calldata username, address userAddress) internal {
        nameToAddress[username] = userAddress;
        addressToName[userAddress] = username;
    }
    
    /**
     * @dev Replace username (allowed only by owner)
     * @param newUsername new username you want to have
     */
    function replace(string calldata newUsername) public {
        string memory oldUsername = addressToName[msg.sender];
        bytes memory tempEmptyStringTest = bytes(oldUsername);
        require(
            tempEmptyStringTest.length != 0,
            "This address is not registered."
        );
        address userAddress = nameToAddress[oldUsername];
        require(
            userAddress != address(0),
            "Username is not registered."
        );
        require(
            userAddress == msg.sender,
            "Only the owner can edit its username."
        );
        _store(newUsername, msg.sender);
    }
}