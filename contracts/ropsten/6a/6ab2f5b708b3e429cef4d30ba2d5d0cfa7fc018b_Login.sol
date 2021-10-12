/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Login{

    address[] addressList;

    struct User{
        string username;
        string info;
    }

    mapping(address => User) public addrToUser;
    mapping(string => address) public userToAddr;

    event SignIn(address indexed userAddress, string username);
    event SetInfo(address indexed userAddress, string info);

    function signIn(
        string memory _username,
        string memory _info
        ) public {
        require(bytes(addrToUser[msg.sender].username).length == 0, "user has signed in before");
        addressList.push(msg.sender);
        setUserName(_username);
        if(bytes(_info).length != 0) {setInfo(_info);}
    }

    function setUserName(string memory _username) internal {
        require(userToAddr[_username] == address(0), "this username has been used before");
        require(bytes(_username).length > 0, "set a username");
        addrToUser[msg.sender].username = _username;
        userToAddr[_username] = msg.sender;
        emit SignIn(msg.sender, _username);
    }

    function setInfo(string memory info) public {
        require(bytes(addrToUser[msg.sender].username).length != 0, "you have to sign in first");
        require(bytes(info).length != 0, "empty info");
        addrToUser[msg.sender].info = info;
        emit SetInfo(msg.sender, info);
    }

    function userInfo(address userAddr) public view returns(
        string memory username,
        string memory info
    ) {
        return(
            addrToUser[userAddr].username,
            addrToUser[userAddr].info
        );
    }
}