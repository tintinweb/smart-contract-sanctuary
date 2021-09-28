/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Login{

    address[] addressList;

    mapping(address => string) public addrToUser;
    mapping(string => address) public userToAddr;

    event SignIn(address indexed userAddress, string username);

    function signIn(string memory _username) public {
        require(bytes(addrToUser[msg.sender]).length == 0, "user has signed in before");
        require(userToAddr[_username] == address(0), "this username has been used before");

        require(bytes(_username).length > 0, "set a username");

        addressList.push(msg.sender);
        addrToUser[msg.sender] = _username;
        userToAddr[_username] = msg.sender;

        emit SignIn(msg.sender, _username);
    }

    // function username(address userAddr) public view returns(string memory) {
    //     require(bytes(addrToUser[msg.sender]).length > 0, "user has not sign in yet");
    //     return addrToUser[userAddr];
    // }

}