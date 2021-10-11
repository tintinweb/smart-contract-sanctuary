/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Login{

    address[] addressList;

    struct User{
        string username;
        string phoneNumber;
        string email;
        string location;
    }

    mapping(address => User) public addrToUser;
    mapping(string => address) public userToAddr;

    event SignIn(address indexed userAddress, string username);

    function signIn(
        string memory _username,
        string memory _phoneNumber,
        string memory _email, 
        string memory _location
        ) public {
        require(bytes(addrToUser[msg.sender].username).length == 0, "user has signed in before");
        addressList.push(msg.sender);
        setUserName(_username);
        setInfo(_phoneNumber, _email, _location);
        emit SignIn(msg.sender, _username);
    }

    function setInfo(
        string memory phoneNumber_,
        string memory email_, 
        string memory location_
    ) public {
        require(bytes(addrToUser[msg.sender].username).length != 0, "you have to sign in first");
        if(bytes(phoneNumber_).length > 0) {setPhoneNumber(phoneNumber_);}
        if(bytes(email_).length > 0) {setEmail(email_);}
        if(bytes(location_).length > 0) {setLocation(location_);}
    }

    function userInfo(address userAddr) public view returns(
        string memory username,
        string memory phoneNumber,
        string memory email,
        string memory location
    ) {
        return(
            addrToUser[userAddr].username,
            addrToUser[userAddr].phoneNumber,
            addrToUser[userAddr].email,
            addrToUser[userAddr].location
        );
    }


    function setUserName(string memory _username) internal {
        require(userToAddr[_username] == address(0), "this username has been used before");
        require(bytes(_username).length > 0, "set a username");
        addrToUser[msg.sender].username = _username;
        userToAddr[_username] = msg.sender;
    }

    function setPhoneNumber(string memory _phoneNumber) internal {
        require(bytes(_phoneNumber).length > 0, "set a phone number");
        addrToUser[msg.sender].phoneNumber = _phoneNumber;
    }

    function setEmail(string memory _email) internal {
        require(bytes(_email).length > 0, "set an email");
        addrToUser[msg.sender].email = _email;
    }

    function setLocation(string memory _location) internal {
        require(bytes(_location).length > 0, "set a location");
        addrToUser[msg.sender].location = _location;
    }
}