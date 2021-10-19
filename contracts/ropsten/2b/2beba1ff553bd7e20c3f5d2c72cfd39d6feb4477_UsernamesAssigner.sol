/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract UsernamesAssigner {

    mapping(string => address) public usernames;

    /**
     * @dev Store value in variable
     * @param newUsername value to store
     */
    function store(string calldata newUsername) public {
        address userAddress = usernames[newUsername];
        require(
            userAddress == address(0),
            "Username already exists."
        );
        usernames[newUsername] = msg.sender;
    }

    /**
     * @dev Return value 
     * @return value of 'address'
     */
    function retrieve(string calldata username) public view returns (address){
        address userAddress = usernames[username];
        require(
            userAddress != address(0),
            "Username is not registered."
        );
        return userAddress;
    }
}