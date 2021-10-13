/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Authentication{
    
    struct UserDetails{
        address UserAddress;
        string username;
        string password;
        bool isloggedin;
    }
    
    address public Owner;
    
    constructor(){
        Owner = msg.sender;
    }
    
    mapping(address => UserDetails) user;
    
    function Register(address _address, string memory _username, string memory _password) public notOwner payable returns(bool){
    require(user[_address].UserAddress == address(0));
    require(msg.value == 1 ether, "Send 1 ether");
    user[_address].UserAddress = _address;
    user[_address].username = _username;
    user[_address].password = _password;
    user[_address].isloggedin = false;
    return true;
    }
    
    modifier notOwner(){
        require(msg.sender != Owner);
        _;
    }
    
    function changePassword(address _address, string memory _username, string memory _password,string memory _newPassword) public returns(bool){
        require(keccak256(abi.encodePacked((user[_address].username))) == keccak256(abi.encodePacked((_username))) && keccak256(abi.encodePacked((user[_address].password))) == keccak256(abi.encodePacked((_password))),"Username or/and Password does not match in the system.");
        user[_address].password = _newPassword;
        return true;
    }
    
    function Login(address _address, string memory _username, string memory _password) public returns(bool){
        require(keccak256(abi.encodePacked((user[_address].password))) == keccak256(abi.encodePacked((_password))) && keccak256(abi.encodePacked((user[_address].username))) == keccak256(abi.encodePacked((_username))), "Oops! You are not a registered user");
        user[_address].isloggedin = true;
        return true;
    }
}